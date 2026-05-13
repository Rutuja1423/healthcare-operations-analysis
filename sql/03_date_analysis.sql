-- ============================================================
-- Healthcare Operations Analysis
-- 03: Date Arithmetic Analysis (MySQL)
-- ============================================================

USE healthcare_ops_db;

-- ============================================================
-- ANALYSIS 1: Length of Stay (LOS) per Patient
-- Formula: DATEDIFF(discharge_date, admission_date)
-- Uses cleaned data — NULL discharges replaced with CURDATE()
-- ============================================================

-- What is each patient's length of stay?
SELECT 
    p.patient_id,
    p.patient_name,
    p.admission_date,
    p.discharge_date,
    CASE 
        WHEN p.discharge_date IS NULL THEN 'Still Admitted'
        ELSE 'Discharged'
    END AS status,
    DATEDIFF(
        IFNULL(p.discharge_date, CURDATE()), 
        p.admission_date
    ) AS length_of_stay_days,
    p.diagnosis
FROM patients p
WHERE p.discharge_date IS NULL 
   OR p.discharge_date >= p.admission_date
ORDER BY length_of_stay_days DESC;

-- ============================================================
-- ANALYSIS 2: Average LOS per Department
-- Joins patients → visits → staff to get department info
-- ============================================================

-- What is the average length of stay by department?
SELECT 
    v.department,
    COUNT(DISTINCT p.patient_id) AS total_patients,
    ROUND(AVG(
        DATEDIFF(
            IFNULL(p.discharge_date, CURDATE()), 
            p.admission_date
        )
    ), 1) AS avg_los_days,
    MIN(DATEDIFF(
        IFNULL(p.discharge_date, CURDATE()), 
        p.admission_date
    )) AS min_los_days,
    MAX(DATEDIFF(
        IFNULL(p.discharge_date, CURDATE()), 
        p.admission_date
    )) AS max_los_days
FROM patients p
JOIN visits v ON p.patient_id = v.patient_id
    AND v.visit_date = p.admission_date
WHERE p.discharge_date IS NULL 
   OR p.discharge_date >= p.admission_date
GROUP BY v.department
ORDER BY avg_los_days DESC;

-- ============================================================
-- ANALYSIS 3: Time Between Visits for Repeat Patients
-- Uses LAG() window function to find inter-visit gaps
-- ============================================================

-- Which patients have multiple visits and what is the gap between visits?
WITH patient_visits AS (
    SELECT 
        v.patient_id,
        p.patient_name,
        v.visit_date,
        v.department,
        ROW_NUMBER() OVER (
            PARTITION BY v.patient_id 
            ORDER BY v.visit_date
        ) AS visit_number,
        LAG(v.visit_date) OVER (
            PARTITION BY v.patient_id 
            ORDER BY v.visit_date
        ) AS previous_visit_date
    FROM visits v
    JOIN patients p ON v.patient_id = p.patient_id
)
SELECT 
    patient_id,
    patient_name,
    visit_number,
    visit_date,
    previous_visit_date,
    DATEDIFF(visit_date, previous_visit_date) AS days_between_visits,
    department
FROM patient_visits
WHERE previous_visit_date IS NOT NULL
ORDER BY patient_id, visit_number;

-- ============================================================
-- ANALYSIS 4: Average Time Between Visits (Repeat Patients)
-- ============================================================

-- What is the average gap between repeat visits per patient?
WITH visit_gaps AS (
    SELECT 
        v.patient_id,
        p.patient_name,
        v.visit_date,
        LAG(v.visit_date) OVER (
            PARTITION BY v.patient_id 
            ORDER BY v.visit_date
        ) AS previous_visit_date
    FROM visits v
    JOIN patients p ON v.patient_id = p.patient_id
)
SELECT 
    patient_id,
    patient_name,
    COUNT(*) AS total_return_visits,
    ROUND(AVG(DATEDIFF(visit_date, previous_visit_date)), 1) AS avg_days_between_visits,
    MIN(DATEDIFF(visit_date, previous_visit_date)) AS min_gap_days,
    MAX(DATEDIFF(visit_date, previous_visit_date)) AS max_gap_days
FROM visit_gaps
WHERE previous_visit_date IS NOT NULL
GROUP BY patient_id, patient_name
ORDER BY total_return_visits DESC;

-- ============================================================
-- ANALYSIS 5: Monthly Admission & Discharge Trends
-- ============================================================

-- How do admissions trend month over month?
SELECT 
    DATE_FORMAT(admission_date, '%Y-%m') AS month,
    COUNT(*) AS total_admissions,
    SUM(CASE WHEN gender = 'M' THEN 1 ELSE 0 END) AS male_admissions,
    SUM(CASE WHEN gender = 'F' THEN 1 ELSE 0 END) AS female_admissions,
    ROUND(AVG(age), 1) AS avg_patient_age
FROM patients
GROUP BY DATE_FORMAT(admission_date, '%Y-%m')
ORDER BY month;

-- ============================================================
-- ANALYSIS 6: Diagnosis-wise Average LOS
-- Which diagnoses lead to longer hospital stays?
-- ============================================================

SELECT 
    diagnosis,
    COUNT(*) AS patient_count,
    ROUND(AVG(
        DATEDIFF(
            IFNULL(discharge_date, CURDATE()), 
            admission_date
        )
    ), 1) AS avg_los_days,
    ROUND(AVG(age), 0) AS avg_patient_age
FROM patients
WHERE discharge_date IS NULL 
   OR discharge_date >= admission_date
GROUP BY diagnosis
ORDER BY avg_los_days DESC;
