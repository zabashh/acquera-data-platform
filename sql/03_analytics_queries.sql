-- ============================================================
-- ACQUERA YACHTING — CORE ANALYTICS QUERIES
-- These are the queries you'd write on the job (and in interviews)
-- ============================================================


-- ============================================================
-- SECTION 1: REVENUE & COMMERCIAL REPORTING
-- ============================================================

-- Q1: Total revenue by year and season
-- Purpose: High-level business performance overview
SELECT
    charter_year,
    season,
    COUNT(*)                        AS num_bookings,
    SUM(num_passengers)             AS total_pax,
    ROUND(SUM(net_revenue_eur), 2)  AS total_revenue_eur,
    ROUND(AVG(net_revenue_eur), 2)  AS avg_revenue_per_booking
FROM vw_bookings_master
WHERE booking_status = 'completed'
GROUP BY charter_year, season
ORDER BY charter_year, season;


-- Q2: Revenue by vessel — fleet performance ranking
-- Purpose: Which vessels generate most value?
SELECT
    vessel_name,
    vessel_type,
    COUNT(b.booking_id)                             AS total_bookings,
    SUM(b.charter_end - b.charter_start)            AS total_days_chartered,
    ROUND(SUM(f.revenue_eur), 2)                    AS total_revenue_eur,
    ROUND(AVG(f.revenue_eur), 2)                    AS avg_revenue_per_charter,
    ROUND(
        SUM(b.charter_end - b.charter_start) * 100.0
        / NULLIF(DATEDIFF_DAYS_IN_SEASON(v.vessel_id), 0),  -- % utilisation concept
        1
    )                                               AS approx_utilisation_pct
FROM vessels v
JOIN bookings b  ON v.vessel_id = b.vessel_id
JOIN financials f ON b.booking_id = f.booking_id
WHERE b.status = 'completed'
GROUP BY v.vessel_id, vessel_name, vessel_type
ORDER BY total_revenue_eur DESC;

-- Simpler version (PostgreSQL-compatible, no custom function):
SELECT
    v.vessel_name,
    v.vessel_type,
    v.daily_rate_eur,
    COUNT(b.booking_id)                          AS total_bookings,
    SUM(b.charter_end - b.charter_start)         AS total_days_chartered,
    ROUND(SUM(f.revenue_eur), 2)                 AS total_revenue_eur,
    ROUND(AVG(f.revenue_eur), 2)                 AS avg_revenue_per_charter,
    ROUND(SUM(f.revenue_eur) / NULLIF(SUM(b.charter_end - b.charter_start), 0), 2) AS actual_daily_yield_eur
FROM vessels v
JOIN bookings b  ON v.vessel_id = b.vessel_id AND b.status = 'completed'
JOIN financials f ON b.booking_id = f.booking_id
GROUP BY v.vessel_id, v.vessel_name, v.vessel_type, v.daily_rate_eur
ORDER BY total_revenue_eur DESC;


-- Q3: Month-over-month revenue trend (2023 vs 2024)
-- Purpose: Seasonality analysis and YoY growth
SELECT
    charter_month,
    TO_CHAR(TO_DATE(charter_month::TEXT, 'MM'), 'Month') AS month_name,
    SUM(CASE WHEN charter_year = 2023 THEN net_revenue_eur ELSE 0 END) AS revenue_2023,
    SUM(CASE WHEN charter_year = 2024 THEN net_revenue_eur ELSE 0 END) AS revenue_2024,
    ROUND(
        (SUM(CASE WHEN charter_year = 2024 THEN net_revenue_eur ELSE 0 END)
         - SUM(CASE WHEN charter_year = 2023 THEN net_revenue_eur ELSE 0 END))
        / NULLIF(SUM(CASE WHEN charter_year = 2023 THEN net_revenue_eur ELSE 0 END), 0) * 100,
        1
    ) AS yoy_growth_pct
FROM vw_bookings_master
WHERE booking_status = 'completed'
GROUP BY charter_month
ORDER BY charter_month;


-- Q4: Client value segmentation (RFM-lite)
-- Purpose: Who are the best clients? Repeat bookers vs one-offs?
SELECT
    c.full_name,
    c.client_type,
    c.acquisition_channel,
    c.nationality,
    COUNT(b.booking_id)                         AS total_bookings,
    MIN(b.charter_start)                        AS first_charter,
    MAX(b.charter_start)                        AS last_charter,
    ROUND(SUM(f.revenue_eur), 2)                AS lifetime_revenue_eur,
    ROUND(AVG(f.revenue_eur), 2)                AS avg_booking_value_eur,
    CASE
        WHEN COUNT(b.booking_id) >= 3 THEN 'VIP'
        WHEN COUNT(b.booking_id) = 2 THEN 'Repeat'
        ELSE 'One-time'
    END AS client_segment
FROM clients c
JOIN bookings b   ON c.client_id = b.client_id AND b.status = 'completed'
JOIN financials f ON b.booking_id = f.booking_id
GROUP BY c.client_id, c.full_name, c.client_type, c.acquisition_channel, c.nationality
ORDER BY lifetime_revenue_eur DESC;


-- ============================================================
-- SECTION 2: OPERATIONAL REPORTING
-- ============================================================

-- Q5: Fleet utilisation — days chartered vs available in season
-- Available season = June to September (122 days)
WITH season_days AS (
    SELECT
        v.vessel_id,
        v.vessel_name,
        v.status AS current_status,
        122 AS season_days_available  -- June-Sep
    FROM vessels v
),
chartered_days AS (
    SELECT
        b.vessel_id,
        SUM(b.charter_end - b.charter_start) AS days_chartered
    FROM bookings b
    WHERE b.status = 'completed'
      AND EXTRACT(YEAR FROM b.charter_start) = 2024
      AND b.charter_start >= '2024-06-01'
      AND b.charter_end   <= '2024-09-30'
    GROUP BY b.vessel_id
)
SELECT
    sd.vessel_name,
    sd.current_status,
    sd.season_days_available,
    COALESCE(cd.days_chartered, 0)                               AS days_chartered,
    ROUND(COALESCE(cd.days_chartered, 0) * 100.0 / sd.season_days_available, 1) AS utilisation_pct
FROM season_days sd
LEFT JOIN chartered_days cd ON sd.vessel_id = cd.vessel_id
ORDER BY utilisation_pct DESC;


-- Q6: Booking lead time analysis
-- Purpose: How far in advance do clients book? Useful for forecasting
SELECT
    v.vessel_type,
    ROUND(AVG(b.charter_start - b.booking_date), 0) AS avg_lead_days,
    MIN(b.charter_start - b.booking_date)            AS min_lead_days,
    MAX(b.charter_start - b.booking_date)            AS max_lead_days,
    COUNT(*)                                          AS num_bookings
FROM bookings b
JOIN vessels v ON b.vessel_id = v.vessel_id
WHERE b.status IN ('completed', 'confirmed')
GROUP BY v.vessel_type
ORDER BY avg_lead_days DESC;


-- Q7: Popular routes (departure → arrival port pairs)
SELECT
    dp.port_name AS departure_port,
    ap.port_name AS arrival_port,
    dp.country   AS from_country,
    ap.country   AS to_country,
    COUNT(*)     AS num_bookings,
    ROUND(AVG(f.revenue_eur), 2) AS avg_charter_revenue
FROM bookings b
JOIN ports dp ON b.departure_port_id = dp.port_id
JOIN ports ap ON b.arrival_port_id   = ap.port_id
JOIN financials f ON b.booking_id = f.booking_id
WHERE b.status = 'completed'
GROUP BY dp.port_name, ap.port_name, dp.country, ap.country
ORDER BY num_bookings DESC
LIMIT 10;


-- ============================================================
-- SECTION 3: FINANCIAL P&L ANALYSIS
-- ============================================================

-- Q8: Gross profit by booking (using the P&L view)
SELECT
    booking_id,
    charter_start,
    vessel_name,
    client_name,
    revenue_eur,
    cost_eur,
    commission_eur,
    crew_cost_eur,
    gross_profit_eur,
    gross_margin_pct,
    payment_status
FROM vw_booking_pnl
ORDER BY gross_profit_eur DESC;


-- Q9: Commission analysis — broker vs direct bookings
SELECT
    c.acquisition_channel,
    COUNT(b.booking_id)                     AS num_bookings,
    ROUND(SUM(f.revenue_eur), 2)            AS total_revenue_eur,
    ROUND(SUM(f.commission_eur), 2)         AS total_commission_eur,
    ROUND(AVG(f.commission_eur / NULLIF(f.revenue_eur, 0) * 100), 2) AS avg_commission_pct,
    ROUND(SUM(f.revenue_eur - f.commission_eur), 2) AS net_after_commission
FROM bookings b
JOIN clients c    ON b.client_id = c.client_id
JOIN financials f ON b.booking_id = f.booking_id
WHERE b.status = 'completed'
GROUP BY c.acquisition_channel
ORDER BY total_revenue_eur DESC;


-- Q10: Crew cost per booking (for margin management)
SELECT
    b.booking_id,
    v.vessel_name,
    b.charter_start,
    (b.charter_end - b.charter_start)           AS charter_days,
    COUNT(ca.assignment_id)                      AS crew_count,
    SUM(ca.day_rate_eur * ca.days_worked)        AS total_crew_cost_eur,
    f.revenue_eur,
    ROUND(
        SUM(ca.day_rate_eur * ca.days_worked) * 100.0 / NULLIF(f.revenue_eur, 0),
        2
    )                                            AS crew_cost_pct_of_revenue
FROM bookings b
JOIN vessels v         ON b.vessel_id = v.vessel_id
JOIN crew_assignments ca ON b.booking_id = ca.booking_id
JOIN financials f      ON b.booking_id = f.booking_id
WHERE b.status = 'completed'
GROUP BY b.booking_id, v.vessel_name, b.charter_start, b.charter_end, f.revenue_eur
ORDER BY crew_cost_pct_of_revenue DESC;


-- ============================================================
-- SECTION 4: WINDOW FUNCTIONS (shows advanced SQL skill)
-- ============================================================

-- Q11: Running revenue total by month (2024)
SELECT
    charter_month_str,
    ROUND(SUM(net_revenue_eur), 2)                   AS monthly_revenue,
    ROUND(SUM(SUM(net_revenue_eur)) OVER (
        ORDER BY charter_month_str
    ), 2)                                             AS running_total_eur,
    ROUND(AVG(SUM(net_revenue_eur)) OVER (
        ORDER BY charter_month_str
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ), 2)                                             AS rolling_3m_avg_eur
FROM vw_bookings_master
WHERE booking_status = 'completed'
  AND charter_year = 2024
GROUP BY charter_month_str
ORDER BY charter_month_str;


-- Q12: Vessel revenue rank within each vessel type
SELECT
    vessel_name,
    vessel_type,
    total_revenue_eur,
    RANK()     OVER (PARTITION BY vessel_type ORDER BY total_revenue_eur DESC) AS rank_in_type,
    ROUND(total_revenue_eur * 100.0 / SUM(total_revenue_eur) OVER (), 2)       AS pct_of_total_revenue
FROM (
    SELECT
        v.vessel_name,
        v.vessel_type,
        ROUND(SUM(f.revenue_eur), 2) AS total_revenue_eur
    FROM vessels v
    JOIN bookings b   ON v.vessel_id = b.vessel_id AND b.status = 'completed'
    JOIN financials f ON b.booking_id = f.booking_id
    GROUP BY v.vessel_id, v.vessel_name, v.vessel_type
) t
ORDER BY vessel_type, rank_in_type;


-- Q13: Identify clients who haven't booked in 12+ months (churn risk)
SELECT
    c.full_name,
    c.email,
    c.client_type,
    c.acquisition_channel,
    MAX(b.charter_end)                                   AS last_charter_end,
    CURRENT_DATE - MAX(b.charter_end)                    AS days_since_last_charter,
    COUNT(b.booking_id)                                   AS total_bookings_ever,
    ROUND(SUM(f.revenue_eur), 2)                         AS lifetime_revenue_eur
FROM clients c
JOIN bookings b   ON c.client_id = b.client_id AND b.status = 'completed'
JOIN financials f ON b.booking_id = f.booking_id
GROUP BY c.client_id, c.full_name, c.email, c.client_type, c.acquisition_channel
HAVING CURRENT_DATE - MAX(b.charter_end) > 365
ORDER BY lifetime_revenue_eur DESC;
