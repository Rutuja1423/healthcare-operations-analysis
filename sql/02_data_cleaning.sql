-- ============================================================
-- Healthcare Operations Analysis
-- 02: Data Cleaning (MySQL)
-- ============================================================

USE healthcare_ops_db;

-- ============================================================
-- STEP 1: Identify records with NULL discharge dates
-- Business Context: These may be currently admitted patients
--                   or missing data entries.
-- ============================================================

-- How many patients have missing discharge dates?
SELECT 
    patient_id,
    patient_name,
    admission_date,
    discharge_date,
    diagnosis
FROM patients
WHERE discharge_date IS NULL;

-- Result: Patients 5, 18, 35, 42 have NULL discharge dates

-- ============================================================
-- STEP 2: Identify date inconsistencies
-- Rule: discharge_date must be >= admission_date
-- ============================================================

-- Which patients have discharge before admission (data entry errors)?
SELECT 
    patient_id,
    patient_name,
    admission_date,
    discharge_date,
    DATEDIFF(discharge_date, admission_date) AS computed_los,
    'ERROR: Discharge before admission' AS issue
FROM patients
WHERE discharge_date IS NOT NULL
  AND discharge_date < admission_date;

-- Result: Patients 10 and 28 have swapped dates

-- ============================================================
-- STEP 3: Fix swapped admission and discharge dates
-- Logic: If discharge < admission, swap the two values
-- ============================================================

UPDATE patients
SET 
    admission_date = discharge_date,
    discharge_date = admission_date
WHERE discharge_date IS NOT NULL
  AND discharge_date < admission_date;

-- Verify the fix
SELECT 
    patient_id,
    patient_name,
    admission_date,
    discharge_date,
    DATEDIFF(discharge_date, admission_date) AS los_days
FROM patients
WHERE patient_id IN (10, 28);

-- ============================================================
-- STEP 4: Handle NULL discharge dates for analysis
-- Strategy: For LOS calculations, use CURDATE() as a proxy
--           for patients still admitted. Flag them separately.
-- ============================================================

-- Create a cleaned view that handles NULL discharge dates
CREATE OR REPLACE VIEW vw_patients_cleaned AS
SELECT 
    patient_id,
    patient_name,
    admission_date,
    discharge_date,
    IFNULL(discharge_date, CURDATE()) AS effective_discharge_date,
    CASE 
        WHEN discharge_date IS NULL THEN 'Currently Admitted'
        ELSE 'Discharged'
    END AS patient_status,
    diagnosis,
    age,
    gender,
    DATEDIFF(IFNULL(discharge_date, CURDATE()), admission_date) AS length_of_stay
FROM patients
WHERE discharge_date IS NULL 
   OR discharge_date >= admission_date;

-- View the cleaned data
SELECT * FROM vw_patients_cleaned;

-- ============================================================
-- STEP 5: Data quality summary report
-- Provides a complete overview of data issues found and fixed
-- ============================================================

SELECT 
    'Total Patients' AS metric,
    COUNT(*) AS value
FROM patients

UNION ALL

SELECT 
    'NULL Discharge Dates (Still Admitted)',
    COUNT(*)
FROM patients 
WHERE discharge_date IS NULL

UNION ALL

SELECT 
    'Date Inconsistencies Fixed',
    COUNT(*)
FROM patients 
WHERE patient_id IN (10, 28)

UNION ALL

SELECT 
    'Clean Records',
    COUNT(*)
FROM patients 
WHERE discharge_date IS NOT NULL 
  AND discharge_date >= admission_date;

-- ============================================================
-- STEP 6: Validate age and gender fields
-- ============================================================

-- Check for invalid age values
SELECT 
    patient_id, 
    patient_name, 
    age
FROM patients
WHERE age < 0 OR age > 120 OR age IS NULL;

-- Check for invalid gender values
SELECT 
    patient_id, 
    patient_name, 
    gender
FROM patients
WHERE gender NOT IN ('M', 'F') OR gender IS NULL;

-- Result: No invalid age or gender values found in sample data
