-- ============================================================
-- ACQUERA YACHTING — DATA PLATFORM SCHEMA
-- Author: Data Platform & Analytics Analyst
-- Purpose: Centralised data warehouse for operational reporting
-- DB: PostgreSQL 15+
-- ============================================================

-- DROP ORDER (safe for re-runs)
DROP TABLE IF EXISTS financials CASCADE;
DROP TABLE IF EXISTS crew_assignments CASCADE;
DROP TABLE IF EXISTS bookings CASCADE;
DROP TABLE IF EXISTS clients CASCADE;
DROP TABLE IF EXISTS vessels CASCADE;
DROP TABLE IF EXISTS ports CASCADE;

-- ============================================================
-- DIM: PORTS
-- Reference table for departure/arrival locations
-- ============================================================
CREATE TABLE ports (
    port_id       SERIAL PRIMARY KEY,
    port_name     VARCHAR(100) NOT NULL,
    country       VARCHAR(100) NOT NULL,
    region        VARCHAR(100),  -- e.g. Adriatic, Tyrrhenian, Med
    is_home_base  BOOLEAN DEFAULT FALSE
);

-- ============================================================
-- DIM: VESSELS
-- Yacht fleet master data
-- ============================================================
CREATE TABLE vessels (
    vessel_id       SERIAL PRIMARY KEY,
    vessel_name     VARCHAR(150) NOT NULL,
    vessel_type     VARCHAR(50)  NOT NULL,  -- Sailboat, Motor Yacht, Catamaran, Gulet
    length_m        NUMERIC(5,1),
    capacity_pax    INT,                     -- Max passengers
    build_year      INT,
    home_port_id    INT REFERENCES ports(port_id),
    daily_rate_eur  NUMERIC(10,2),           -- Base charter rate per day
    status          VARCHAR(30) DEFAULT 'available',  -- available, maintenance, chartered
    created_at      TIMESTAMP DEFAULT NOW()
);

-- ============================================================
-- DIM: CLIENTS
-- Client/broker master data
-- ============================================================
CREATE TABLE clients (
    client_id       SERIAL PRIMARY KEY,
    full_name       VARCHAR(200) NOT NULL,
    email           VARCHAR(200),
    nationality     VARCHAR(100),
    client_type     VARCHAR(30),  -- individual, broker, corporate
    acquisition_channel VARCHAR(50), -- direct, referral, broker, online
    first_booking_date DATE,
    created_at      TIMESTAMP DEFAULT NOW()
);

-- ============================================================
-- FACT: BOOKINGS
-- Core transactional table — one row per charter booking
-- ============================================================
CREATE TABLE bookings (
    booking_id        SERIAL PRIMARY KEY,
    vessel_id         INT NOT NULL REFERENCES vessels(vessel_id),
    client_id         INT NOT NULL REFERENCES clients(client_id),
    departure_port_id INT REFERENCES ports(port_id),
    arrival_port_id   INT REFERENCES ports(port_id),
    booking_date      DATE NOT NULL,   -- when the booking was made
    charter_start     DATE NOT NULL,
    charter_end       DATE NOT NULL,
    num_passengers    INT,
    status            VARCHAR(30) DEFAULT 'confirmed', -- confirmed, completed, cancelled, pending
    total_price_eur   NUMERIC(12,2),
    discount_pct      NUMERIC(5,2) DEFAULT 0,
    notes             TEXT,
    created_at        TIMESTAMP DEFAULT NOW(),

    -- Derived constraint: end must be after start
    CONSTRAINT chk_dates CHECK (charter_end > charter_start),
    CONSTRAINT chk_passengers CHECK (num_passengers > 0)
);

-- ============================================================
-- FACT: FINANCIALS
-- Revenue and cost tracking per booking
-- ============================================================
CREATE TABLE financials (
    financial_id    SERIAL PRIMARY KEY,
    booking_id      INT NOT NULL REFERENCES bookings(booking_id),
    transaction_date DATE NOT NULL,
    revenue_eur     NUMERIC(12,2) DEFAULT 0,
    cost_eur        NUMERIC(12,2) DEFAULT 0,   -- fuel, crew, port fees, provisions
    commission_eur  NUMERIC(12,2) DEFAULT 0,   -- broker/agent commission
    payment_status  VARCHAR(30) DEFAULT 'pending',  -- pending, partial, paid, refunded
    payment_method  VARCHAR(50),  -- bank transfer, credit card, cash
    created_at      TIMESTAMP DEFAULT NOW()
);

-- ============================================================
-- BRIDGE: CREW ASSIGNMENTS
-- Links crew members to bookings (many crew per booking)
-- ============================================================
CREATE TABLE crew_assignments (
    assignment_id   SERIAL PRIMARY KEY,
    booking_id      INT NOT NULL REFERENCES bookings(booking_id),
    crew_name       VARCHAR(200) NOT NULL,
    role            VARCHAR(100),  -- Captain, First Mate, Chef, Hostess, Engineer
    day_rate_eur    NUMERIC(8,2),
    days_worked     INT,
    created_at      TIMESTAMP DEFAULT NOW()
);

-- ============================================================
-- INDEXES — performance for common query patterns
-- ============================================================
CREATE INDEX idx_bookings_vessel    ON bookings(vessel_id);
CREATE INDEX idx_bookings_client    ON bookings(client_id);
CREATE INDEX idx_bookings_dates     ON bookings(charter_start, charter_end);
CREATE INDEX idx_bookings_status    ON bookings(status);
CREATE INDEX idx_financials_booking ON financials(booking_id);
CREATE INDEX idx_financials_date    ON financials(transaction_date);
CREATE INDEX idx_crew_booking       ON crew_assignments(booking_id);

-- ============================================================
-- VIEWS — pre-built for dashboards and reporting
-- ============================================================

-- Master booking view (denormalised for BI tools)
CREATE OR REPLACE VIEW vw_bookings_master AS
SELECT
    b.booking_id,
    b.booking_date,
    b.charter_start,
    b.charter_end,
    (b.charter_end - b.charter_start) AS charter_days,
    b.status AS booking_status,
    b.num_passengers,
    b.total_price_eur,
    b.discount_pct,
    b.total_price_eur * (1 - COALESCE(b.discount_pct,0)/100) AS net_revenue_eur,

    v.vessel_name,
    v.vessel_type,
    v.length_m,
    v.capacity_pax,
    v.daily_rate_eur,

    c.full_name AS client_name,
    c.nationality AS client_nationality,
    c.client_type,
    c.acquisition_channel,

    dp.port_name AS departure_port,
    dp.country   AS departure_country,
    dp.region    AS departure_region,

    ap.port_name AS arrival_port,
    ap.country   AS arrival_country,

    EXTRACT(YEAR FROM b.charter_start)  AS charter_year,
    EXTRACT(MONTH FROM b.charter_start) AS charter_month,
    TO_CHAR(b.charter_start, 'YYYY-MM') AS charter_month_str,
    CASE EXTRACT(MONTH FROM b.charter_start)
        WHEN 6 THEN 'High Season'
        WHEN 7 THEN 'Peak Season'
        WHEN 8 THEN 'Peak Season'
        WHEN 9 THEN 'High Season'
        ELSE 'Low Season'
    END AS season

FROM bookings b
JOIN vessels  v  ON b.vessel_id = v.vessel_id
JOIN clients  c  ON b.client_id = c.client_id
LEFT JOIN ports dp ON b.departure_port_id = dp.port_id
LEFT JOIN ports ap ON b.arrival_port_id   = ap.port_id;

-- Financial P&L view per booking
CREATE OR REPLACE VIEW vw_booking_pnl AS
SELECT
    b.booking_id,
    b.charter_start,
    b.charter_end,
    v.vessel_name,
    c.full_name AS client_name,
    f.revenue_eur,
    f.cost_eur,
    f.commission_eur,
    COALESCE(crew.total_crew_cost, 0) AS crew_cost_eur,
    f.revenue_eur
        - f.cost_eur
        - f.commission_eur
        - COALESCE(crew.total_crew_cost, 0) AS gross_profit_eur,
    ROUND(
        (f.revenue_eur - f.cost_eur - f.commission_eur - COALESCE(crew.total_crew_cost,0))
        / NULLIF(f.revenue_eur, 0) * 100, 2
    ) AS gross_margin_pct,
    f.payment_status
FROM bookings b
JOIN vessels  v ON b.vessel_id = v.vessel_id
JOIN clients  c ON b.client_id = c.client_id
JOIN financials f ON b.booking_id = f.booking_id
LEFT JOIN (
    SELECT booking_id, SUM(day_rate_eur * days_worked) AS total_crew_cost
    FROM crew_assignments
    GROUP BY booking_id
) crew ON b.booking_id = crew.booking_id;
