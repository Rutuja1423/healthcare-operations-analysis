-- ============================================================
-- Healthcare Operations Analysis
-- 04: Conditional Analysis with CASE Statements (MySQL)
-- ============================================================

USE healthcare_ops_db;

-- ============================================================
-- ANALYSIS 1: Patient Stay Categories
-- Short Stay:  < 3 days
-- Medium Stay: 3–7 days
-- Long Stay:   > 7 days
-- ============================================================

-- How are patients distributed across stay duration categories?
SELECT 
    p.patient_id,
    p.patient_name,
    p.diagnosis,
    DATEDIFF(
        IFNULL(p.discharge_date, CURDATE()), 
        p.admission_date
    ) AS los_days,
    CASE 
        WHEN DATEDIFF(IFNULL(p.discharge_date, CURDATE()), p.admission_date) < 3 
            THEN 'Short Stay (< 3 days)'
        WHEN DATEDIFF(IFNULL(p.discharge_date, CURDATE()), p.admission_date) BETWEEN 3 AND 7 
            THEN 'Medium Stay (3-7 days)'
        ELSE 'Long Stay (> 7 days)'
    END AS stay_category
FROM patients p
WHERE p.discharge_date IS NULL 
   OR p.discharge_date >= p.admission_date
ORDER BY los_days DESC;

-- ============================================================
-- ANALYSIS 2: Stay Category Summary Statistics
-- ============================================================

-- What is the count and percentage of patients in each category?
SELECT 
    stay_category,
    patient_count,
    ROUND(patient_count * 100.0 / SUM(patient_count) OVER(), 1) AS percentage
FROM (
    SELECT 
        CASE 
            WHEN DATEDIFF(IFNULL(discharge_date, CURDATE()), admission_date) < 3 
                THEN 'Short Stay (< 3 days)'
            WHEN DATEDIFF(IFNULL(discharge_date, CURDATE()), admission_date) BETWEEN 3 AND 7 
                THEN 'Medium Stay (3-7 days)'
            ELSE 'Long Stay (> 7 days)'
        END AS stay_category,
        COUNT(*) AS patient_count
    FROM patients
    WHERE discharge_date IS NULL 
       OR discharge_date >= admission_date
    GROUP BY stay_category
) AS category_counts
ORDER BY patient_count DESC;

-- ============================================================
-- ANALYSIS 3: Billing Risk Classification
-- Low Risk:    Paid
-- Medium Risk: Partial
-- High Risk:   Pending
-- Critical:    Denied
-- ============================================================

-- How is billing distributed across risk categories?
SELECT 
    b.bill_id,
    b.patient_id,
    p.patient_name,
    b.amount,
    b.payment_status,
    CASE 
        WHEN b.payment_status = 'Paid'    THEN 'Low Risk'
        WHEN b.payment_status = 'Partial' THEN 'Medium Risk'
        WHEN b.payment_status = 'Pending' THEN 'High Risk'
        WHEN b.payment_status = 'Denied'  THEN 'Critical'
        ELSE 'Unknown'
    END AS risk_category,
    CASE 
        WHEN b.payment_status = 'Paid'    THEN 1
        WHEN b.payment_status = 'Partial' THEN 2
        WHEN b.payment_status = 'Pending' THEN 3
        WHEN b.payment_status = 'Denied'  THEN 4
        ELSE 5
    END AS risk_priority
FROM billing b
JOIN patients p ON b.patient_id = p.patient_id
ORDER BY risk_priority DESC, b.amount DESC;

-- ============================================================
-- ANALYSIS 4: Billing Risk Summary with Revenue at Risk
-- ============================================================

-- What is the total revenue exposure per risk category?
SELECT 
    CASE 
        WHEN payment_status = 'Paid'    THEN 'Low Risk'
        WHEN payment_status = 'Partial' THEN 'Medium Risk'
        WHEN payment_status = 'Pending' THEN 'High Risk'
        WHEN payment_status = 'Denied'  THEN 'Critical'
    END AS risk_category,
    COUNT(*) AS bill_count,
    SUM(amount) AS total_amount,
    ROUND(AVG(amount), 2) AS avg_amount,
    ROUND(SUM(amount) * 100.0 / (SELECT SUM(amount) FROM billing), 1) AS pct_of_total_revenue
FROM billing
GROUP BY risk_category
ORDER BY total_amount DESC;

-- ============================================================
-- ANALYSIS 5: Age Group Segmentation
-- Pediatric: 0–17 years
-- Adult:     18–64 years
-- Senior:    65+ years
-- ============================================================

-- What is the patient distribution by age group?
SELECT 
    CASE 
        WHEN age BETWEEN 0 AND 17  THEN 'Pediatric (0-17)'
        WHEN age BETWEEN 18 AND 64 THEN 'Adult (18-64)'
        ELSE 'Senior (65+)'
    END AS age_group,
    COUNT(*) AS patient_count,
    ROUND(AVG(
        DATEDIFF(IFNULL(discharge_date, CURDATE()), admission_date)
    ), 1) AS avg_los_days,
    GROUP_CONCAT(DISTINCT diagnosis ORDER BY diagnosis SEPARATOR ', ') AS common_diagnoses
FROM patients
WHERE discharge_date IS NULL 
   OR discharge_date >= admission_date
GROUP BY age_group
ORDER BY patient_count DESC;

-- ============================================================
-- ANALYSIS 6: Combined Patient Profile Classification
-- Multi-dimensional CASE combining stay, age, and billing risk
-- ============================================================

-- What is each patient's full risk and stay profile?
SELECT 
    p.patient_id,
    p.patient_name,
    p.age,
    CASE 
        WHEN p.age BETWEEN 0 AND 17  THEN 'Pediatric'
        WHEN p.age BETWEEN 18 AND 64 THEN 'Adult'
        ELSE 'Senior'
    END AS age_group,
    DATEDIFF(IFNULL(p.discharge_date, CURDATE()), p.admission_date) AS los_days,
    CASE 
        WHEN DATEDIFF(IFNULL(p.discharge_date, CURDATE()), p.admission_date) < 3 
            THEN 'Short'
        WHEN DATEDIFF(IFNULL(p.discharge_date, CURDATE()), p.admission_date) BETWEEN 3 AND 7 
            THEN 'Medium'
        ELSE 'Long'
    END AS stay_category,
    b.total_billed,
    b.primary_status,
    CASE 
        WHEN b.primary_status = 'Denied' THEN 'Critical Attention'
        WHEN b.primary_status = 'Pending' AND p.age >= 65 THEN 'High Priority'
        WHEN b.primary_status = 'Pending' THEN 'Follow Up'
        WHEN b.primary_status = 'Partial' THEN 'Collection Needed'
        ELSE 'Resolved'
    END AS action_required
FROM patients p
LEFT JOIN (
    SELECT 
        patient_id,
        SUM(amount) AS total_billed,
        -- Get the most common (worst) payment status per patient
        SUBSTRING_INDEX(
            GROUP_CONCAT(payment_status ORDER BY 
                CASE payment_status 
                    WHEN 'Denied' THEN 1 
                    WHEN 'Pending' THEN 2 
                    WHEN 'Partial' THEN 3 
                    ELSE 4 
                END
            ), ',', 1
        ) AS primary_status
    FROM billing
    GROUP BY patient_id
) b ON p.patient_id = b.patient_id
WHERE p.discharge_date IS NULL 
   OR p.discharge_date >= p.admission_date
ORDER BY 
    CASE 
        WHEN b.primary_status = 'Denied' THEN 1
        WHEN b.primary_status = 'Pending' THEN 2
        WHEN b.primary_status = 'Partial' THEN 3
        ELSE 4
    END,
    los_days DESC;
