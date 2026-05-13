-- ============================================================
-- Healthcare Operations Analysis
-- 01: Schema Definition & Sample Data (MySQL)
-- Author: Healthcare Data Analyst
-- ============================================================

-- Create and use the database
CREATE DATABASE IF NOT EXISTS healthcare_ops_db;
USE healthcare_ops_db;

-- ============================================================
-- Drop existing tables (safe reset)
-- ============================================================
DROP TABLE IF EXISTS billing;
DROP TABLE IF EXISTS visits;
DROP TABLE IF EXISTS patients;
DROP TABLE IF EXISTS staff;

-- ============================================================
-- Table 1: staff
-- Stores doctor and department mapping
-- ============================================================
CREATE TABLE staff (
    doctor_id   INT PRIMARY KEY,
    doctor_name VARCHAR(100) NOT NULL,
    department  VARCHAR(50)  NOT NULL
);

-- ============================================================
-- Table 2: patients
-- Core patient demographics and admission details
-- Intentionally includes dirty data for cleaning exercises
-- ============================================================
CREATE TABLE patients (
    patient_id      INT PRIMARY KEY,
    patient_name    VARCHAR(100) NOT NULL,
    admission_date  DATE,
    discharge_date  DATE,
    diagnosis       VARCHAR(100),
    age             INT,
    gender          CHAR(1)
);

-- ============================================================
-- Table 3: visits
-- Tracks individual patient visits to departments
-- ============================================================
CREATE TABLE visits (
    visit_id    INT PRIMARY KEY,
    patient_id  INT NOT NULL,
    visit_date  DATE NOT NULL,
    department  VARCHAR(50),
    doctor_id   INT,
    FOREIGN KEY (patient_id) REFERENCES patients(patient_id),
    FOREIGN KEY (doctor_id)  REFERENCES staff(doctor_id)
);

-- ============================================================
-- Table 4: billing
-- Financial records per patient
-- ============================================================
CREATE TABLE billing (
    bill_id         INT PRIMARY KEY,
    patient_id      INT NOT NULL,
    amount          DECIMAL(10,2),
    payment_status  VARCHAR(20),
    bill_date       DATE,
    FOREIGN KEY (patient_id) REFERENCES patients(patient_id)
);

-- ============================================================
-- INSERT: staff (15 doctors across 6 departments)
-- ============================================================
INSERT INTO staff (doctor_id, doctor_name, department) VALUES
(1,  'Dr. Ananya Sharma',    'Cardiology'),
(2,  'Dr. Rajesh Patel',     'Cardiology'),
(3,  'Dr. Priya Mehta',      'Orthopedics'),
(4,  'Dr. Suresh Kumar',     'Orthopedics'),
(5,  'Dr. Neha Gupta',       'Neurology'),
(6,  'Dr. Vikram Singh',     'Neurology'),
(7,  'Dr. Kavita Rao',       'Pediatrics'),
(8,  'Dr. Arjun Desai',      'Pediatrics'),
(9,  'Dr. Meera Joshi',      'Emergency'),
(10, 'Dr. Amit Verma',       'Emergency'),
(11, 'Dr. Sneha Iyer',       'General Medicine'),
(12, 'Dr. Rohit Agarwal',    'General Medicine'),
(13, 'Dr. Deepa Nair',       'Cardiology'),
(14, 'Dr. Sanjay Mishra',    'Orthopedics'),
(15, 'Dr. Pooja Reddy',      'Emergency');

-- ============================================================
-- INSERT: patients (50 patients)
-- NOTE: Intentional dirty data included:
--   - Patient 5, 18, 35, 42: NULL discharge_date (still admitted)
--   - Patient 10, 28: discharge_date < admission_date (data error)
-- ============================================================
INSERT INTO patients (patient_id, patient_name, admission_date, discharge_date, diagnosis, age, gender) VALUES
(1,  'Aarav Kapoor',      '2024-01-05', '2024-01-07', 'Pneumonia',         34, 'M'),
(2,  'Diya Sharma',       '2024-01-08', '2024-01-15', 'Fracture',          28, 'F'),
(3,  'Vihaan Reddy',      '2024-01-10', '2024-01-12', 'Appendicitis',      45, 'M'),
(4,  'Isha Patel',        '2024-01-12', '2024-01-22', 'Heart Attack',      67, 'F'),
(5,  'Arjun Nair',        '2024-01-15', NULL,         'Stroke',            72, 'M'),
(6,  'Ananya Iyer',       '2024-01-18', '2024-01-19', 'Migraine',          29, 'F'),
(7,  'Reyansh Gupta',     '2024-01-20', '2024-01-28', 'Diabetes',          55, 'M'),
(8,  'Saanvi Joshi',      '2024-01-22', '2024-01-24', 'Asthma',            12, 'F'),
(9,  'Kabir Verma',       '2024-01-25', '2024-01-26', 'Food Poisoning',    38, 'M'),
(10, 'Myra Desai',        '2024-02-01', '2024-01-28', 'Fracture',          42, 'F'),
(11, 'Aditya Mehta',      '2024-02-03', '2024-02-10', 'Pneumonia',         60, 'M'),
(12, 'Riya Singh',        '2024-02-05', '2024-02-07', 'Appendicitis',      33, 'F'),
(13, 'Vivaan Kumar',      '2024-02-08', '2024-02-18', 'Heart Attack',      71, 'M'),
(14, 'Kiara Rao',         '2024-02-10', '2024-02-12', 'Migraine',          25, 'F'),
(15, 'Dhruv Agarwal',     '2024-02-12', '2024-02-14', 'Gastritis',         48, 'M'),
(16, 'Navya Mishra',      '2024-02-15', '2024-02-25', 'Fracture',          56, 'F'),
(17, 'Ishaan Nair',       '2024-02-18', '2024-02-20', 'Bronchitis',        40, 'M'),
(18, 'Anvi Kapoor',       '2024-02-20', NULL,         'Stroke',            78, 'F'),
(19, 'Shaurya Patel',     '2024-02-22', '2024-02-24', 'Pneumonia',         35, 'M'),
(20, 'Anika Sharma',      '2024-02-25', '2024-03-04', 'Diabetes',          62, 'F'),
(21, 'Atharv Reddy',      '2024-03-01', '2024-03-03', 'Food Poisoning',    27, 'M'),
(22, 'Pari Gupta',        '2024-03-03', '2024-03-05', 'Asthma',            15, 'F'),
(23, 'Advait Singh',      '2024-03-05', '2024-03-15', 'Heart Attack',      69, 'M'),
(24, 'Mira Joshi',        '2024-03-08', '2024-03-09', 'Migraine',          31, 'F'),
(25, 'Arnav Verma',       '2024-03-10', '2024-03-17', 'Fracture',          50, 'M'),
(26, 'Sara Desai',        '2024-03-12', '2024-03-14', 'Gastritis',         44, 'F'),
(27, 'Rudra Mehta',       '2024-03-15', '2024-03-18', 'Appendicitis',      37, 'M'),
(28, 'Amaira Kumar',      '2024-03-18', '2024-03-15', 'Bronchitis',        22, 'F'),
(29, 'Veer Rao',          '2024-03-20', '2024-03-22', 'Pneumonia',         58, 'M'),
(30, 'Zara Agarwal',      '2024-03-22', '2024-03-30', 'Diabetes',          65, 'F'),
(31, 'Aadhya Mishra',     '2024-04-01', '2024-04-03', 'Food Poisoning',    30, 'F'),
(32, 'Sai Nair',          '2024-04-03', '2024-04-13', 'Heart Attack',      74, 'M'),
(33, 'Pihu Kapoor',       '2024-04-05', '2024-04-07', 'Asthma',             9, 'F'),
(34, 'Aryan Patel',       '2024-04-08', '2024-04-09', 'Migraine',          26, 'M'),
(35, 'Tara Sharma',       '2024-04-10', NULL,         'Fracture',          47, 'F'),
(36, 'Kian Reddy',        '2024-04-12', '2024-04-19', 'Stroke',            80, 'M'),
(37, 'Nisha Gupta',       '2024-04-15', '2024-04-17', 'Gastritis',         39, 'F'),
(38, 'Dev Singh',         '2024-04-18', '2024-04-20', 'Bronchitis',        52, 'M'),
(39, 'Avni Joshi',        '2024-04-20', '2024-04-22', 'Pneumonia',         41, 'F'),
(40, 'Rohan Verma',       '2024-04-22', '2024-04-30', 'Diabetes',          68, 'M'),
(41, 'Ira Desai',         '2024-04-25', '2024-04-27', 'Appendicitis',      36, 'F'),
(42, 'Yash Mehta',        '2024-04-28', NULL,         'Heart Attack',      76, 'M'),
(43, 'Sia Kumar',         '2024-05-01', '2024-05-03', 'Food Poisoning',    24, 'F'),
(44, 'Aayan Rao',         '2024-05-03', '2024-05-05', 'Asthma',            11, 'M'),
(45, 'Rashi Agarwal',     '2024-05-05', '2024-05-12', 'Fracture',          53, 'F'),
(46, 'Neil Mishra',       '2024-05-08', '2024-05-10', 'Migraine',          32, 'M'),
(47, 'Disha Nair',        '2024-05-10', '2024-05-20', 'Stroke',            70, 'F'),
(48, 'Kabir Kapoor',      '2024-05-12', '2024-05-14', 'Gastritis',         46, 'M'),
(49, 'Aashi Patel',       '2024-05-15', '2024-05-17', 'Bronchitis',        43, 'F'),
(50, 'Vivek Sharma',      '2024-05-18', '2024-05-28', 'Heart Attack',      73, 'M');

-- ============================================================
-- INSERT: visits (80 visits — some patients have repeat visits)
-- ============================================================
INSERT INTO visits (visit_id, patient_id, visit_date, department, doctor_id) VALUES
(1001, 1,  '2024-01-05', 'General Medicine',  11),
(1002, 2,  '2024-01-08', 'Orthopedics',        3),
(1003, 3,  '2024-01-10', 'General Medicine',  12),
(1004, 4,  '2024-01-12', 'Cardiology',         1),
(1005, 5,  '2024-01-15', 'Neurology',          5),
(1006, 6,  '2024-01-18', 'Neurology',          6),
(1007, 7,  '2024-01-20', 'General Medicine',  11),
(1008, 8,  '2024-01-22', 'Pediatrics',         7),
(1009, 9,  '2024-01-25', 'Emergency',          9),
(1010, 10, '2024-02-01', 'Orthopedics',        4),
(1011, 11, '2024-02-03', 'General Medicine',  12),
(1012, 12, '2024-02-05', 'General Medicine',  11),
(1013, 13, '2024-02-08', 'Cardiology',         2),
(1014, 14, '2024-02-10', 'Neurology',          5),
(1015, 15, '2024-02-12', 'General Medicine',  12),
(1016, 16, '2024-02-15', 'Orthopedics',        3),
(1017, 17, '2024-02-18', 'General Medicine',  11),
(1018, 18, '2024-02-20', 'Neurology',          6),
(1019, 19, '2024-02-22', 'General Medicine',  12),
(1020, 20, '2024-02-25', 'General Medicine',  11),
(1021, 21, '2024-03-01', 'Emergency',          9),
(1022, 22, '2024-03-03', 'Pediatrics',         8),
(1023, 23, '2024-03-05', 'Cardiology',         1),
(1024, 24, '2024-03-08', 'Neurology',          5),
(1025, 25, '2024-03-10', 'Orthopedics',        4),
(1026, 26, '2024-03-12', 'General Medicine',  12),
(1027, 27, '2024-03-15', 'General Medicine',  11),
(1028, 28, '2024-03-18', 'General Medicine',  12),
(1029, 29, '2024-03-20', 'General Medicine',  11),
(1030, 30, '2024-03-22', 'General Medicine',  12),
(1031, 31, '2024-04-01', 'Emergency',         10),
(1032, 32, '2024-04-03', 'Cardiology',         2),
(1033, 33, '2024-04-05', 'Pediatrics',         7),
(1034, 34, '2024-04-08', 'Neurology',          6),
(1035, 35, '2024-04-10', 'Orthopedics',       14),
(1036, 36, '2024-04-12', 'Neurology',          5),
(1037, 37, '2024-04-15', 'General Medicine',  11),
(1038, 38, '2024-04-18', 'General Medicine',  12),
(1039, 39, '2024-04-20', 'General Medicine',  11),
(1040, 40, '2024-04-22', 'General Medicine',  12),
(1041, 41, '2024-04-25', 'General Medicine',  11),
(1042, 42, '2024-04-28', 'Cardiology',        13),
(1043, 43, '2024-05-01', 'Emergency',         15),
(1044, 44, '2024-05-03', 'Pediatrics',         8),
(1045, 45, '2024-05-05', 'Orthopedics',        3),
(1046, 46, '2024-05-08', 'Neurology',          6),
(1047, 47, '2024-05-10', 'Neurology',          5),
(1048, 48, '2024-05-12', 'General Medicine',  12),
(1049, 49, '2024-05-15', 'General Medicine',  11),
(1050, 50, '2024-05-18', 'Cardiology',         1),
-- Repeat visits (patients coming back for follow-ups)
(1051, 1,  '2024-02-10', 'General Medicine',  11),
(1052, 4,  '2024-02-15', 'Cardiology',         1),
(1053, 7,  '2024-03-05', 'General Medicine',  12),
(1054, 11, '2024-03-10', 'General Medicine',  11),
(1055, 13, '2024-03-20', 'Cardiology',         2),
(1056, 16, '2024-03-25', 'Orthopedics',        4),
(1057, 20, '2024-04-01', 'General Medicine',  12),
(1058, 23, '2024-04-10', 'Cardiology',        13),
(1059, 25, '2024-04-15', 'Orthopedics',        3),
(1060, 30, '2024-04-20', 'General Medicine',  11),
(1061, 32, '2024-05-01', 'Cardiology',         1),
(1062, 2,  '2024-03-01', 'Orthopedics',        3),
(1063, 9,  '2024-03-15', 'Emergency',         10),
(1064, 19, '2024-04-05', 'General Medicine',  11),
(1065, 29, '2024-04-25', 'General Medicine',  12),
(1066, 1,  '2024-03-15', 'General Medicine',  12),
(1067, 4,  '2024-03-20', 'Cardiology',         2),
(1068, 13, '2024-04-15', 'Cardiology',        13),
(1069, 23, '2024-05-05', 'Cardiology',         1),
(1070, 40, '2024-05-20', 'General Medicine',  11),
(1071, 8,  '2024-02-15', 'Pediatrics',         7),
(1072, 22, '2024-04-01', 'Pediatrics',         8),
(1073, 33, '2024-05-10', 'Pediatrics',         7),
(1074, 5,  '2024-02-20', 'Neurology',          6),
(1075, 36, '2024-05-15', 'Neurology',          5),
(1076, 10, '2024-03-05', 'Orthopedics',       14),
(1077, 45, '2024-05-25', 'Orthopedics',        4),
(1078, 21, '2024-04-10', 'Emergency',          9),
(1079, 31, '2024-05-05', 'Emergency',         15),
(1080, 43, '2024-05-20', 'Emergency',          9);

-- ============================================================
-- INSERT: billing (60 records with mixed payment statuses)
-- ============================================================
INSERT INTO billing (bill_id, patient_id, amount, payment_status, bill_date) VALUES
(2001, 1,  15000.00,  'Paid',     '2024-01-08'),
(2002, 2,  45000.00,  'Paid',     '2024-01-16'),
(2003, 3,  35000.00,  'Paid',     '2024-01-13'),
(2004, 4,  120000.00, 'Partial',  '2024-01-23'),
(2005, 5,  85000.00,  'Pending',  '2024-02-01'),
(2006, 6,  8000.00,   'Paid',     '2024-01-20'),
(2007, 7,  25000.00,  'Paid',     '2024-01-29'),
(2008, 8,  12000.00,  'Paid',     '2024-01-25'),
(2009, 9,  5000.00,   'Paid',     '2024-01-27'),
(2010, 10, 55000.00,  'Denied',   '2024-02-05'),
(2011, 11, 28000.00,  'Paid',     '2024-02-11'),
(2012, 12, 32000.00,  'Partial',  '2024-02-08'),
(2013, 13, 150000.00, 'Pending',  '2024-02-19'),
(2014, 14, 7500.00,   'Paid',     '2024-02-13'),
(2015, 15, 10000.00,  'Paid',     '2024-02-15'),
(2016, 16, 62000.00,  'Partial',  '2024-02-26'),
(2017, 17, 14000.00,  'Paid',     '2024-02-21'),
(2018, 18, 95000.00,  'Pending',  '2024-03-01'),
(2019, 19, 18000.00,  'Paid',     '2024-02-25'),
(2020, 20, 22000.00,  'Paid',     '2024-03-05'),
(2021, 21, 6000.00,   'Paid',     '2024-03-04'),
(2022, 22, 11000.00,  'Paid',     '2024-03-06'),
(2023, 23, 135000.00, 'Partial',  '2024-03-16'),
(2024, 24, 7000.00,   'Paid',     '2024-03-10'),
(2025, 25, 48000.00,  'Paid',     '2024-03-18'),
(2026, 26, 9500.00,   'Paid',     '2024-03-15'),
(2027, 27, 33000.00,  'Denied',   '2024-03-19'),
(2028, 28, 13000.00,  'Paid',     '2024-03-20'),
(2029, 29, 20000.00,  'Paid',     '2024-03-23'),
(2030, 30, 24000.00,  'Partial',  '2024-03-31'),
(2031, 31, 5500.00,   'Paid',     '2024-04-04'),
(2032, 32, 140000.00, 'Pending',  '2024-04-14'),
(2033, 33, 10000.00,  'Paid',     '2024-04-08'),
(2034, 34, 6500.00,   'Paid',     '2024-04-10'),
(2035, 35, 52000.00,  'Pending',  '2024-04-20'),
(2036, 36, 88000.00,  'Partial',  '2024-04-20'),
(2037, 37, 9000.00,   'Paid',     '2024-04-18'),
(2038, 38, 15000.00,  'Paid',     '2024-04-21'),
(2039, 39, 19000.00,  'Denied',   '2024-04-23'),
(2040, 40, 26000.00,  'Paid',     '2024-05-01'),
(2041, 41, 34000.00,  'Paid',     '2024-04-28'),
(2042, 42, 160000.00, 'Pending',  '2024-05-10'),
(2043, 43, 4500.00,   'Paid',     '2024-05-04'),
(2044, 44, 11500.00,  'Paid',     '2024-05-06'),
(2045, 45, 50000.00,  'Partial',  '2024-05-13'),
(2046, 46, 7200.00,   'Paid',     '2024-05-11'),
(2047, 47, 92000.00,  'Pending',  '2024-05-21'),
(2048, 48, 10500.00,  'Paid',     '2024-05-15'),
(2049, 49, 14500.00,  'Paid',     '2024-05-18'),
(2050, 50, 145000.00, 'Partial',  '2024-05-29'),
-- Follow-up billing for repeat visitors
(2051, 1,  3000.00,   'Paid',     '2024-02-11'),
(2052, 4,  25000.00,  'Paid',     '2024-02-16'),
(2053, 13, 30000.00,  'Partial',  '2024-03-21'),
(2054, 23, 28000.00,  'Paid',     '2024-04-11'),
(2055, 32, 22000.00,  'Pending',  '2024-05-02'),
(2056, 7,  5000.00,   'Paid',     '2024-03-06'),
(2057, 20, 8000.00,   'Paid',     '2024-04-02'),
(2058, 40, 12000.00,  'Denied',   '2024-05-21'),
(2059, 2,  8000.00,   'Paid',     '2024-03-02'),
(2060, 9,  4000.00,   'Paid',     '2024-03-16');

-- ============================================================
-- Verification: Quick row counts
-- ============================================================
SELECT 'staff' AS table_name, COUNT(*) AS row_count FROM staff
UNION ALL
SELECT 'patients', COUNT(*) FROM patients
UNION ALL
SELECT 'visits', COUNT(*) FROM visits
UNION ALL
SELECT 'billing', COUNT(*) FROM billing;
