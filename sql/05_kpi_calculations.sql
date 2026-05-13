-- ============================================================
-- Healthcare Operations Analysis
-- 05: KPI Calculations (MySQL)
-- ============================================================

USE healthcare_ops_db;

-- ============================================================
-- KPI 1: Bed Occupancy Rate
-- Formula: (Total Patient-Days / Total Available Bed-Days) × 100
-- Assumption: 100 beds available, analysis period Jan–May 2024
-- ============================================================

-- What is the hospital's overall bed occupancy rate?
SELECT 
    SUM(DATEDIFF(
        LEAST(IFNULL(p.discharge_date, CURDATE()), '2024-05-31'),
        GREATEST(p.admission_date, '2024-01-01')
    )) AS total_patient_days,
    100 * DATEDIFF('2024-05-31', '2024-01-01') AS total_available_bed_days,
    ROUND(
        SUM(DATEDIFF(
            LEAST(IFNULL(p.discharge_date, CURDATE()), '2024-05-31'),
            GREATEST(p.admission_date, '2024-01-01')
        )) * 100.0 / (100 * DATEDIFF('2024-05-31', '2024-01-01')),
        2
    ) AS occupancy_rate_pct
FROM patients p
WHERE p.discharge_date IS NULL 
   OR p.discharge_date >= p.admission_date;

-- Monthly bed occupancy trend
SELECT 
    DATE_FORMAT(dates.month_start, '%Y-%m') AS month,
    COUNT(DISTINCT p.patient_id) AS patients_in_beds,
    ROUND(
        SUM(DATEDIFF(
            LEAST(IFNULL(p.discharge_date, CURDATE()), LAST_DAY(dates.month_start)),
            GREATEST(p.admission_date, dates.month_start)
        )) * 100.0 / (100 * DAY(LAST_DAY(dates.month_start))),
        2
    ) AS monthly_occupancy_pct
FROM (
    SELECT '2024-01-01' AS month_start UNION ALL
    SELECT '2024-02-01' UNION ALL
    SELECT '2024-03-01' UNION ALL
    SELECT '2024-04-01' UNION ALL
    SELECT '2024-05-01'
) dates
JOIN patients p ON p.admission_date <= LAST_DAY(dates.month_start)
    AND (p.discharge_date IS NULL OR p.discharge_date >= dates.month_start)
    AND (p.discharge_date IS NULL OR p.discharge_date >= p.admission_date)
GROUP BY dates.month_start
ORDER BY dates.month_start;

-- ============================================================
-- KPI 2: 30-Day Readmission Rate
-- A readmission = same patient admitted within 30 days
--                 of a previous discharge
-- ============================================================

-- Which patients were readmitted within 30 days?
WITH ordered_admissions AS (
    SELECT 
        patient_id,
        patient_name,
        admission_date,
        discharge_date,
        diagnosis,
        LAG(discharge_date) OVER (
            PARTITION BY patient_id 
            ORDER BY admission_date
        ) AS prev_discharge_date
    FROM patients
    WHERE discharge_date IS NOT NULL 
      AND discharge_date >= admission_date
)
SELECT 
    patient_id,
    patient_name,
    prev_discharge_date,
    admission_date AS readmission_date,
    DATEDIFF(admission_date, prev_discharge_date) AS days_to_readmission,
    diagnosis
FROM ordered_admissions
WHERE prev_discharge_date IS NOT NULL
  AND DATEDIFF(admission_date, prev_discharge_date) <= 30;

-- Overall 30-day readmission rate
WITH readmission_check AS (
    SELECT 
        v.patient_id,
        v.visit_date,
        LAG(v.visit_date) OVER (
            PARTITION BY v.patient_id 
            ORDER BY v.visit_date
        ) AS prev_visit_date,
        DATEDIFF(
            v.visit_date,
            LAG(v.visit_date) OVER (
                PARTITION BY v.patient_id 
                ORDER BY v.visit_date
            )
        ) AS days_since_last_visit
    FROM visits v
)
SELECT 
    COUNT(DISTINCT CASE 
        WHEN days_since_last_visit <= 30 THEN patient_id 
    END) AS readmitted_patients,
    (SELECT COUNT(DISTINCT patient_id) FROM visits) AS total_patients,
    ROUND(
        COUNT(DISTINCT CASE 
            WHEN days_since_last_visit <= 30 THEN patient_id 
        END) * 100.0 / (SELECT COUNT(DISTINCT patient_id) FROM visits),
        2
    ) AS readmission_rate_pct
FROM readmission_check;

-- Readmission rate by department
WITH dept_readmissions AS (
    SELECT 
        v.patient_id,
        v.department,
        v.visit_date,
        LAG(v.visit_date) OVER (
            PARTITION BY v.patient_id 
            ORDER BY v.visit_date
        ) AS prev_visit_date
    FROM visits v
)
SELECT 
    department,
    COUNT(DISTINCT patient_id) AS total_patients,
    COUNT(DISTINCT CASE 
        WHEN DATEDIFF(visit_date, prev_visit_date) <= 30 
        THEN patient_id 
    END) AS readmitted_patients,
    ROUND(
        COUNT(DISTINCT CASE 
            WHEN DATEDIFF(visit_date, prev_visit_date) <= 30 
            THEN patient_id 
        END) * 100.0 / COUNT(DISTINCT patient_id),
        2
    ) AS readmission_rate_pct
FROM dept_readmissions
GROUP BY department
ORDER BY readmission_rate_pct DESC;

-- ============================================================
-- KPI 3: Revenue per Patient
-- ============================================================

-- What is the average revenue per patient?
SELECT 
    COUNT(DISTINCT patient_id) AS total_patients,
    SUM(amount) AS total_revenue,
    ROUND(SUM(amount) / COUNT(DISTINCT patient_id), 2) AS revenue_per_patient
FROM billing;

-- Revenue per patient by department
SELECT 
    v.department,
    COUNT(DISTINCT b.patient_id) AS patients,
    SUM(b.amount) AS total_revenue,
    ROUND(SUM(b.amount) / COUNT(DISTINCT b.patient_id), 2) AS revenue_per_patient
FROM billing b
JOIN visits v ON b.patient_id = v.patient_id
    AND v.visit_date = (
        SELECT MIN(v2.visit_date) 
        FROM visits v2 
        WHERE v2.patient_id = b.patient_id
    )
GROUP BY v.department
ORDER BY revenue_per_patient DESC;

-- ============================================================
-- KPI 4: Collection Rate
-- Formula: (Paid Amount / Total Billed) × 100
-- ============================================================

-- What percentage of billed amount has been collected?
SELECT 
    SUM(amount) AS total_billed,
    SUM(CASE WHEN payment_status = 'Paid' THEN amount ELSE 0 END) AS total_collected,
    SUM(CASE WHEN payment_status IN ('Pending', 'Denied') THEN amount ELSE 0 END) AS outstanding,
    ROUND(
        SUM(CASE WHEN payment_status = 'Paid' THEN amount ELSE 0 END) * 100.0 
        / SUM(amount), 
        2
    ) AS collection_rate_pct
FROM billing;

-- ============================================================
-- KPI 5: Doctor Workload & Productivity
-- ============================================================

-- How many patients does each doctor handle?
SELECT 
    s.doctor_id,
    s.doctor_name,
    s.department,
    COUNT(DISTINCT v.visit_id) AS total_visits,
    COUNT(DISTINCT v.patient_id) AS unique_patients,
    ROUND(
        COUNT(DISTINCT v.visit_id) * 1.0 / 
        DATEDIFF('2024-05-31', '2024-01-01') * 30,
        1
    ) AS avg_visits_per_month
FROM staff s
LEFT JOIN visits v ON s.doctor_id = v.doctor_id
GROUP BY s.doctor_id, s.doctor_name, s.department
ORDER BY total_visits DESC;

-- ============================================================
-- KPI SUMMARY DASHBOARD
-- All key metrics in a single output
-- ============================================================

SELECT 'Total Patients' AS kpi, 
    CAST(COUNT(*) AS CHAR) AS value 
FROM patients

UNION ALL
SELECT 'Avg Length of Stay (days)', 
    CAST(ROUND(AVG(DATEDIFF(IFNULL(discharge_date, CURDATE()), admission_date)), 1) AS CHAR)
FROM patients 
WHERE discharge_date IS NULL OR discharge_date >= admission_date

UNION ALL
SELECT 'Total Revenue (INR)', 
    CAST(FORMAT(SUM(amount), 0) AS CHAR) 
FROM billing

UNION ALL
SELECT 'Revenue per Patient (INR)', 
    CAST(FORMAT(ROUND(SUM(amount) / COUNT(DISTINCT patient_id), 0), 0) AS CHAR) 
FROM billing

UNION ALL
SELECT 'Collection Rate (%)', 
    CAST(ROUND(SUM(CASE WHEN payment_status = 'Paid' THEN amount ELSE 0 END) * 100.0 / SUM(amount), 1) AS CHAR)
FROM billing

UNION ALL
SELECT 'Total Visits', 
    CAST(COUNT(*) AS CHAR) 
FROM visits

UNION ALL
SELECT 'Repeat Visit Patients', 
    CAST(COUNT(*) AS CHAR)
FROM (
    SELECT patient_id 
    FROM visits 
    GROUP BY patient_id 
    HAVING COUNT(*) > 1
) AS repeats;
