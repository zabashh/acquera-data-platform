-- ============================================================
-- ACQUERA YACHTING — SEED DATA
-- Realistic synthetic data for 2023–2024 operations
-- ============================================================

-- ============================================================
-- PORTS
-- ============================================================
INSERT INTO ports (port_name, country, region, is_home_base) VALUES
('Venice',          'Italy',      'Adriatic',      TRUE),
('Dubrovnik',       'Croatia',    'Adriatic',      FALSE),
('Split',           'Croatia',    'Adriatic',      FALSE),
('Hvar',            'Croatia',    'Adriatic',      FALSE),
('Kotor',           'Montenegro', 'Adriatic',      FALSE),
('Corfu',           'Greece',     'Ionian',        FALSE),
('Mykonos',         'Greece',     'Aegean',        FALSE),
('Santorini',       'Greece',     'Aegean',        FALSE),
('Portofino',       'Italy',      'Ligurian',      FALSE),
('Amalfi',          'Italy',      'Tyrrhenian',    FALSE),
('Palermo',         'Italy',      'Tyrrhenian',    FALSE),
('Ibiza',           'Spain',      'Balearic',      FALSE),
('Monaco',          'Monaco',     'Ligurian',      FALSE),
('Valletta',        'Malta',      'Central Med',   FALSE),
('Bodrum',          'Turkey',     'Aegean',        FALSE);

-- ============================================================
-- VESSELS
-- ============================================================
INSERT INTO vessels (vessel_name, vessel_type, length_m, capacity_pax, build_year, home_port_id, daily_rate_eur, status) VALUES
('Adriatic Star',   'Motor Yacht',   24.5, 10, 2018, 1, 4500.00, 'available'),
('Venezia Dream',   'Sailboat',      18.2,  8, 2015, 1, 2200.00, 'available'),
('Serenissima',     'Catamaran',     14.8,  8, 2020, 1, 2800.00, 'chartered'),
('Doge II',         'Motor Yacht',   32.0, 12, 2021, 1, 7500.00, 'available'),
('Laguna Blu',      'Gulet',         22.0, 10, 2016, 1, 3200.00, 'maintenance'),
('Tramontane',      'Sailboat',      15.5,  6, 2019, 9, 1900.00, 'available'),
('Poseidon X',      'Motor Yacht',   28.0, 10, 2022, 7, 6200.00, 'available'),
('Bora Wind',       'Catamaran',     13.5,  8, 2017, 2, 2400.00, 'available');

-- ============================================================
-- CLIENTS
-- ============================================================
INSERT INTO clients (full_name, email, nationality, client_type, acquisition_channel, first_booking_date) VALUES
('Marco Ferretti',          'mferretti@email.it',       'Italian',      'individual',  'direct',    '2022-06-10'),
('Sophie Müller',           'smuller@web.de',           'German',       'individual',  'online',    '2022-08-15'),
('James & Claire Thornton', 'jthornton@uk.com',         'British',      'individual',  'referral',  '2021-07-20'),
('Lux Charter Group',       'ops@luxcharter.com',       'Luxembourgish','broker',      'broker',    '2021-05-01'),
('Ivan Petrov',             'ipetrov@mail.ru',          'Russian',      'individual',  'direct',    '2023-04-18'),
('Martina Rossi',           'mrossi@studio.it',         'Italian',      'individual',  'referral',  '2022-09-01'),
('Nordic Voyages AB',       'bookings@nordicvoy.se',    'Swedish',      'broker',      'broker',    '2020-06-01'),
('Ahmed Al-Rashidi',        'ahmed.ar@gulf.ae',         'Emirati',      'individual',  'direct',    '2023-01-15'),
('Caroline Dubois',         'cdubois@france.fr',        'French',       'individual',  'online',    '2022-07-03'),
('Infinity Corporate Events','ceo@infinityevents.com',  'Swiss',        'corporate',   'broker',    '2023-03-10'),
('Takashi Yamamoto',        'tyamamoto@corp.jp',        'Japanese',     'individual',  'direct',    '2023-06-01'),
('Elena Vasquez',           'evasquez@correo.es',       'Spanish',      'individual',  'online',    '2022-08-22');

-- ============================================================
-- BOOKINGS
-- 2023 + 2024 seasons, varied statuses
-- ============================================================
INSERT INTO bookings (vessel_id, client_id, departure_port_id, arrival_port_id, booking_date, charter_start, charter_end, num_passengers, status, total_price_eur, discount_pct) VALUES
-- 2023 Season
(1, 1,  1, 2, '2023-03-15', '2023-06-01', '2023-06-08', 8,  'completed', 31500.00, 0),
(2, 2,  1, 4, '2023-04-01', '2023-06-10', '2023-06-17', 6,  'completed', 15400.00, 5),
(4, 4,  1, 6, '2023-02-20', '2023-07-01', '2023-07-10', 10, 'completed', 67500.00, 10),
(3, 3,  2, 8, '2023-04-10', '2023-07-15', '2023-07-22', 8,  'completed', 19600.00, 0),
(1, 7,  1, 7, '2023-05-01', '2023-08-01', '2023-08-08', 9,  'completed', 31500.00, 0),
(5, 5,  1, 5, '2023-05-15', '2023-08-10', '2023-08-17', 8,  'completed', 22400.00, 0),
(7, 8,  7, 8, '2023-06-01', '2023-08-20', '2023-08-30', 10, 'completed', 62000.00, 5),
(4, 10, 1, 9, '2023-06-20', '2023-09-01', '2023-09-07', 12, 'completed', 45000.00, 0),
(2, 6,  1, 3, '2023-07-01', '2023-09-10', '2023-09-14', 5,  'completed',  8800.00, 0),
(8, 9,  2, 6, '2023-07-15', '2023-09-20', '2023-09-27', 7,  'completed', 16800.00, 0),
(6, 11, 9, 12,'2023-08-01', '2023-10-05', '2023-10-10', 4,  'completed',  9500.00, 0),
(3, 12, 1, 10,'2023-08-15', '2023-10-15', '2023-10-20', 6,  'cancelled',     0.00, 0),

-- 2024 Season
(1, 2,  1, 4, '2024-02-10', '2024-06-01', '2024-06-08', 7,  'completed', 31500.00, 0),
(4, 4,  1, 7, '2024-02-20', '2024-06-15', '2024-06-25', 10, 'completed', 75000.00, 8),
(7, 8,  7, 15,'2024-03-01', '2024-07-01', '2024-07-11', 10, 'completed', 62000.00, 0),
(3, 3,  1, 6, '2024-03-15', '2024-07-10', '2024-07-17', 8,  'completed', 19600.00, 0),
(2, 1,  1, 3, '2024-04-01', '2024-07-20', '2024-07-25', 6,  'completed', 11000.00, 5),
(4, 10, 9, 13,'2024-04-20', '2024-08-01', '2024-08-10', 10, 'completed', 67500.00, 0),
(1, 7,  1, 8, '2024-05-01', '2024-08-10', '2024-08-20', 9,  'completed', 45000.00, 0),
(8, 9,  2, 7, '2024-05-10', '2024-08-25', '2024-09-01', 6,  'completed', 19200.00, 0),
(5, 5,  1, 5, '2024-05-20', '2024-09-01', '2024-09-08', 8,  'completed', 22400.00, 0),
(6, 11, 9, 12,'2024-06-01', '2024-09-15', '2024-09-22', 4,  'completed', 13300.00, 0),
(4, 4,  1, 14,'2024-06-15', '2024-10-01', '2024-10-08', 10, 'completed', 52500.00, 5),
(3, 12, 1, 10,'2024-07-01', '2024-10-10', '2024-10-15', 5,  'confirmed', 14000.00, 0),
(7, 8,  7, 6, '2024-08-01', '2024-11-01', '2024-11-07', 8,  'confirmed', 37200.00, 0),
(2, 6,  1, 4, '2024-09-01', '2024-11-15', '2024-11-20', 4,   'pending',  9900.00, 0);

-- ============================================================
-- FINANCIALS
-- ============================================================
INSERT INTO financials (booking_id, transaction_date, revenue_eur, cost_eur, commission_eur, payment_status, payment_method) VALUES
(1,  '2023-06-08', 31500.00, 6200.00, 0.00,    'paid',    'bank transfer'),
(2,  '2023-06-17', 14630.00, 4100.00, 770.00,  'paid',    'bank transfer'),
(3,  '2023-07-10', 60750.00, 9800.00, 6750.00, 'paid',    'bank transfer'),
(4,  '2023-07-22', 19600.00, 5200.00, 0.00,    'paid',    'credit card'),
(5,  '2023-08-08', 31500.00, 6500.00, 3150.00, 'paid',    'bank transfer'),
(6,  '2023-08-17', 22400.00, 7100.00, 0.00,    'paid',    'bank transfer'),
(7,  '2023-08-30', 58900.00, 11200.00,3100.00, 'paid',    'bank transfer'),
(8,  '2023-09-07', 45000.00, 8800.00, 0.00,    'paid',    'bank transfer'),
(9,  '2023-09-14',  8800.00, 2200.00, 0.00,    'paid',    'credit card'),
(10, '2023-09-27', 16800.00, 4400.00, 1680.00, 'paid',    'bank transfer'),
(11, '2023-10-10',  9500.00, 2800.00, 0.00,    'paid',    'cash'),
(12, '2023-10-20',     0.00,  500.00, 0.00,    'refunded','bank transfer'),
(13, '2024-06-08', 31500.00, 6300.00, 0.00,    'paid',    'bank transfer'),
(14, '2024-06-25', 69000.00, 10200.00,6000.00, 'paid',    'bank transfer'),
(15, '2024-07-11', 62000.00, 12400.00,3100.00, 'paid',    'bank transfer'),
(16, '2024-07-17', 19600.00, 5100.00, 0.00,    'paid',    'credit card'),
(17, '2024-07-25', 10450.00, 3200.00, 550.00,  'paid',    'bank transfer'),
(18, '2024-08-10', 67500.00, 9900.00, 0.00,    'paid',    'bank transfer'),
(19, '2024-08-20', 45000.00, 8500.00, 4500.00, 'paid',    'bank transfer'),
(20, '2024-09-01', 19200.00, 4800.00, 1920.00, 'paid',    'bank transfer'),
(21, '2024-09-08', 22400.00, 6900.00, 0.00,    'paid',    'bank transfer'),
(22, '2024-09-22', 13300.00, 3200.00, 0.00,    'paid',    'cash'),
(23, '2024-10-08', 49875.00, 9100.00, 2625.00, 'paid',    'bank transfer'),
(24, '2024-10-15', 14000.00, 3800.00, 0.00,    'partial', 'bank transfer'),
(25, '2024-11-07', 37200.00, 8200.00, 0.00,    'pending', 'bank transfer'),
(26, '2024-11-20',  9900.00, 2400.00, 0.00,    'pending', 'bank transfer');

-- ============================================================
-- CREW ASSIGNMENTS
-- ============================================================
INSERT INTO crew_assignments (booking_id, crew_name, role, day_rate_eur, days_worked) VALUES
-- Booking 1 (7 days, Motor Yacht)
(1, 'Luca Bianchi',    'Captain',      350, 7),
(1, 'Marco Vitale',    'First Mate',   220, 7),
(1, 'Anna Colombo',    'Hostess',      180, 7),

-- Booking 3 (9 days, large Motor Yacht - Lux Charter)
(3, 'Roberto Mancini', 'Captain',      400, 9),
(3, 'Giulia Esposito', 'Chef',         300, 9),
(3, 'Paolo Ferrari',   'Engineer',     280, 9),
(3, 'Sofia Ricci',     'Hostess',      200, 9),

-- Booking 4 (7 days, Catamaran)
(4, 'Thomas Baxter',   'Captain',      350, 7),
(4, 'Laura Neri',      'Hostess',      180, 7),

-- Booking 7 (10 days, Motor Yacht)
(7, 'Luca Bianchi',    'Captain',      350, 10),
(7, 'Elena Greco',     'Chef',         300, 10),
(7, 'Marco Vitale',    'First Mate',   220, 10),
(7, 'Anna Colombo',    'Hostess',      180, 10),

-- Booking 8 (6 days, Corporate)
(8, 'Roberto Mancini', 'Captain',      400, 6),
(8, 'Giulia Esposito', 'Chef',         300, 6),
(8, 'Paolo Ferrari',   'Engineer',     280, 6),
(8, 'Maria Conti',     'Hostess',      200, 6),
(8, 'Giovanni Luca',   'Hostess',      200, 6),

-- Booking 14 (10 days, 2024)
(14, 'Roberto Mancini','Captain',      400, 10),
(14, 'Giulia Esposito','Chef',         300, 10),
(14, 'Paolo Ferrari',  'Engineer',     280, 10),
(14, 'Sofia Ricci',    'Hostess',      200, 10),

-- Booking 15 (10 days)
(15, 'Luca Bianchi',   'Captain',      350, 10),
(15, 'Elena Greco',    'Chef',         300, 10),
(15, 'Marco Vitale',   'First Mate',   220, 10),

-- Booking 18 (9 days)
(18, 'Roberto Mancini','Captain',      400, 9),
(18, 'Giulia Esposito','Chef',         300, 9),
(18, 'Paolo Ferrari',  'Engineer',     280, 9),
(18, 'Maria Conti',    'Hostess',      200, 9),

-- Booking 19 (10 days)
(19, 'Luca Bianchi',   'Captain',      350, 10),
(19, 'Elena Greco',    'Chef',         300, 10),
(19, 'Anna Colombo',   'Hostess',      180, 10),
(19, 'Marco Vitale',   'First Mate',   220, 10);
