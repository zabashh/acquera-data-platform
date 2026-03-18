-- ============================================================
-- ACQUERA YACHTING — DATA QUALITY CHECKS
-- we usually Run these before any reporting cycle or after data ingestion
-- ============================================================


-- ============================================================
-- DQ-01: NULL CHECK — Critical fields must not be null
-- ============================================================
SELECT 'bookings.vessel_id'   AS check_name, COUNT(*) AS null_count FROM bookings WHERE vessel_id IS NULL
UNION ALL
SELECT 'bookings.client_id',    COUNT(*) FROM bookings WHERE client_id IS NULL
UNION ALL
SELECT 'bookings.charter_start',COUNT(*) FROM bookings WHERE charter_start IS NULL
UNION ALL
SELECT 'bookings.charter_end',  COUNT(*) FROM bookings WHERE charter_end IS NULL
UNION ALL
SELECT 'financials.revenue_eur',COUNT(*) FROM financials WHERE revenue_eur IS NULL
UNION ALL
SELECT 'clients.email',         COUNT(*) FROM clients WHERE email IS NULL
UNION ALL
SELECT 'vessels.daily_rate_eur',COUNT(*) FROM vessels WHERE daily_rate_eur IS NULL;

-- Expected: all counts = 0


-- ============================================================
-- DQ-02: DATE LOGIC — charter_end must be after charter_start
-- ============================================================
SELECT
    booking_id,
    charter_start,
    charter_end,
    charter_end - charter_start AS duration_days,
    'INVALID: end before or equal to start' AS issue
FROM bookings
WHERE charter_end <= charter_start;

-- Expected: 0 rows


-- ============================================================
-- DQ-03: REFERENTIAL INTEGRITY — orphaned records
-- ============================================================
-- Bookings pointing to non-existent vessels
SELECT b.booking_id, b.vessel_id, 'orphaned vessel_id' AS issue
FROM bookings b
LEFT JOIN vessels v ON b.vessel_id = v.vessel_id
WHERE v.vessel_id IS NULL;

-- Financials with no matching booking
SELECT f.financial_id, f.booking_id, 'orphaned booking_id in financials' AS issue
FROM financials f
LEFT JOIN bookings b ON f.booking_id = b.booking_id
WHERE b.booking_id IS NULL;

-- Crew assignments with no matching booking
SELECT ca.assignment_id, ca.booking_id, 'orphaned booking_id in crew_assignments' AS issue
FROM crew_assignments ca
LEFT JOIN bookings b ON ca.booking_id = b.booking_id
WHERE b.booking_id IS NULL;


-- ============================================================
-- DQ-04: BUSINESS LOGIC — passengers can't exceed vessel capacity
-- ============================================================
SELECT
    b.booking_id,
    v.vessel_name,
    v.capacity_pax,
    b.num_passengers,
    b.num_passengers - v.capacity_pax AS overbooked_by
FROM bookings b
JOIN vessels v ON b.vessel_id = v.vessel_id
WHERE b.num_passengers > v.capacity_pax;

-- Expected: 0 rows (a data quality failure here = serious ops risk)


-- ============================================================
-- DQ-05: DUPLICATE DETECTION — same vessel double-booked?
-- ============================================================
SELECT
    a.vessel_id,
    v.vessel_name,
    a.booking_id AS booking_a,
    b.booking_id AS booking_b,
    a.charter_start AS start_a,
    a.charter_end   AS end_a,
    b.charter_start AS start_b,
    b.charter_end   AS end_b,
    'OVERLAP DETECTED' AS issue
FROM bookings a
JOIN bookings b ON a.vessel_id = b.vessel_id
    AND a.booking_id < b.booking_id           -- avoid self-join duplicates
    AND a.status NOT IN ('cancelled')
    AND b.status NOT IN ('cancelled')
    AND a.charter_start < b.charter_end        -- overlap condition
    AND a.charter_end   > b.charter_start
JOIN vessels v ON a.vessel_id = v.vessel_id;

-- Expected: 0 rows — any result here is a critical ops issue


-- ============================================================
-- DQ-06: FINANCIAL CONSISTENCY — revenue should match booking price
-- ============================================================
SELECT
    b.booking_id,
    b.total_price_eur                                                AS booked_price,
    b.total_price_eur * (1 - COALESCE(b.discount_pct, 0) / 100)     AS expected_net_revenue,
    f.revenue_eur                                                    AS actual_revenue,
    ABS(b.total_price_eur * (1 - COALESCE(b.discount_pct, 0) / 100)
        - f.revenue_eur)                                             AS discrepancy_eur,
    'Revenue mismatch >100 EUR' AS issue
FROM bookings b
JOIN financials f ON b.booking_id = f.booking_id
WHERE b.status = 'completed'
  AND ABS(b.total_price_eur * (1 - COALESCE(b.discount_pct, 0) / 100) - f.revenue_eur) > 100;


-- ============================================================
-- DQ-07: COMPLETENESS — bookings without financials
-- ============================================================
SELECT
    b.booking_id,
    b.status,
    b.total_price_eur,
    b.charter_start,
    'Completed booking missing financial record' AS issue
FROM bookings b
LEFT JOIN financials f ON b.booking_id = f.booking_id
WHERE b.status = 'completed'
  AND f.financial_id IS NULL;

-- Expected: 0 rows for completed bookings


-- ============================================================
-- DQ-08: SUMMARY DASHBOARD — one-shot data health score
-- ============================================================
WITH checks AS (
    SELECT 'Date logic errors'      AS check_name, COUNT(*) AS failures FROM bookings WHERE charter_end <= charter_start
    UNION ALL
    SELECT 'Capacity violations',   COUNT(*) FROM bookings b JOIN vessels v ON b.vessel_id = v.vessel_id WHERE b.num_passengers > v.capacity_pax
    UNION ALL
    SELECT 'Missing financials',    COUNT(*) FROM bookings b LEFT JOIN financials f ON b.booking_id = f.booking_id WHERE b.status = 'completed' AND f.financial_id IS NULL
    UNION ALL
    SELECT 'Null vessel_id',        COUNT(*) FROM bookings WHERE vessel_id IS NULL
    UNION ALL
    SELECT 'Null client_id',        COUNT(*) FROM bookings WHERE client_id IS NULL
)
SELECT
    check_name,
    failures,
    CASE WHEN failures = 0 THEN '✓ PASS' ELSE '✗ FAIL' END AS status
FROM checks
ORDER BY failures DESC;
