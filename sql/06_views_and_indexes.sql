-- ============================================================
-- Healthcare Operations Analysis
-- 06: Production Views & Performance Indexes (MySQL)
-- ============================================================

USE healthcare_ops_db;

-- ============================================================
-- VIEW 1: vw_patient_summary
-- Consolidated patient view with LOS and stay category
-- ============================================================

CREATE OR REPLACE VIEW vw_patient_summary AS
SELECT 
    p.patient_id,
    p.patient_name,
    p.age,
    p.gender,
    CASE 
        WHEN p.age BETWEEN 0 AND 17  THEN 'Pediatric'
        WHEN p.age BETWEEN 18 AND 64 THEN 'Adult'
        ELSE 'Senior'
    END AS age_group,
    p.admission_date,
    p.discharge_date,
    IFNULL(p.discharge_date, CURDATE()) AS effective_discharge,
    CASE 
        WHEN p.discharge_date IS NULL THEN 'Currently Admitted'
        ELSE 'Discharged'
    END AS patient_status,
    p.diagnosis,
    DATEDIFF(IFNULL(p.discharge_date, CURDATE()), p.admission_date) AS los_days,
    CASE 
        WHEN DATEDIFF(IFNULL(p.discharge_date, CURDATE()), p.admission_date) < 3 
            THEN 'Short Stay'
        WHEN DATEDIFF(IFNULL(p.discharge_date, CURDATE()), p.admission_date) BETWEEN 3 AND 7 
            THEN 'Medium Stay'
        ELSE 'Long Stay'
    END AS stay_category
FROM patients p
WHERE p.discharge_date IS NULL 
   OR p.discharge_date >= p.admission_date;

-- ============================================================
-- VIEW 2: vw_department_performance
-- Department-level KPIs for dashboard consumption
-- ============================================================

CREATE OR REPLACE VIEW vw_department_performance AS
SELECT 
    v.department,
    COUNT(DISTINCT v.patient_id) AS total_patients,
    COUNT(DISTINCT v.visit_id) AS total_visits,
    ROUND(AVG(
        DATEDIFF(IFNULL(p.discharge_date, CURDATE()), p.admission_date)
    ), 1) AS avg_los_days,
    ROUND(SUM(b.amount), 2) AS total_revenue,
    ROUND(SUM(b.amount) / COUNT(DISTINCT v.patient_id), 2) AS revenue_per_patient,
    SUM(CASE WHEN b.payment_status = 'Paid' THEN 1 ELSE 0 END) AS paid_bills,
    SUM(CASE WHEN b.payment_status IN ('Pending', 'Denied') THEN 1 ELSE 0 END) AS outstanding_bills,
    ROUND(
        SUM(CASE WHEN b.payment_status = 'Paid' THEN b.amount ELSE 0 END) * 100.0 
        / NULLIF(SUM(b.amount), 0),
        1
    ) AS collection_rate_pct
FROM visits v
JOIN patients p ON v.patient_id = p.patient_id
LEFT JOIN billing b ON v.patient_id = b.patient_id
WHERE (p.discharge_date IS NULL OR p.discharge_date >= p.admission_date)
  AND v.visit_date = p.admission_date
GROUP BY v.department;

-- ============================================================
-- VIEW 3: vw_billing_risk
-- Billing records enriched with risk classification
-- ============================================================

CREATE OR REPLACE VIEW vw_billing_risk AS
SELECT 
    b.bill_id,
    b.patient_id,
    p.patient_name,
    p.diagnosis,
    b.amount,
    b.payment_status,
    b.bill_date,
    CASE 
        WHEN b.payment_status = 'Paid'    THEN 'Low Risk'
        WHEN b.payment_status = 'Partial' THEN 'Medium Risk'
        WHEN b.payment_status = 'Pending' THEN 'High Risk'
        WHEN b.payment_status = 'Denied'  THEN 'Critical'
        ELSE 'Unknown'
    END AS risk_category,
    DATEDIFF(CURDATE(), b.bill_date) AS days_since_billed
FROM billing b
JOIN patients p ON b.patient_id = p.patient_id;

-- ============================================================
-- VIEW 4: vw_readmission_tracker
-- Identifies patients with visits within 30 days
-- ============================================================

CREATE OR REPLACE VIEW vw_readmission_tracker AS
WITH visit_sequence AS (
    SELECT 
        v.patient_id,
        p.patient_name,
        v.visit_date,
        v.department,
        LAG(v.visit_date) OVER (
            PARTITION BY v.patient_id 
            ORDER BY v.visit_date
        ) AS prev_visit_date
    FROM visits v
    JOIN patients p ON v.patient_id = p.patient_id
)
SELECT 
    patient_id,
    patient_name,
    prev_visit_date,
    visit_date AS return_visit_date,
    DATEDIFF(visit_date, prev_visit_date) AS days_gap,
    department,
    CASE 
        WHEN DATEDIFF(visit_date, prev_visit_date) <= 30 THEN 'Readmission'
        ELSE 'Scheduled Follow-up'
    END AS visit_type
FROM visit_sequence
WHERE prev_visit_date IS NOT NULL;

-- ============================================================
-- PERFORMANCE INDEXES
-- Optimize frequently used JOIN and WHERE conditions
-- ============================================================

-- Foreign key indexes
CREATE INDEX idx_visits_patient_id ON visits(patient_id);
CREATE INDEX idx_visits_doctor_id ON visits(doctor_id);
CREATE INDEX idx_billing_patient_id ON billing(patient_id);

-- Date-based query optimization
CREATE INDEX idx_patients_admission ON patients(admission_date);
CREATE INDEX idx_patients_discharge ON patients(discharge_date);
CREATE INDEX idx_visits_visit_date ON visits(visit_date);
CREATE INDEX idx_billing_bill_date ON billing(bill_date);

-- Composite indexes for common query patterns
CREATE INDEX idx_visits_patient_date ON visits(patient_id, visit_date);
CREATE INDEX idx_billing_status ON billing(payment_status, amount);

-- ============================================================
-- Verify all views work correctly
-- ============================================================

SELECT 'Patient Summary' AS view_name, COUNT(*) AS rows_returned 
FROM vw_patient_summary
UNION ALL
SELECT 'Department Performance', COUNT(*) FROM vw_department_performance
UNION ALL
SELECT 'Billing Risk', COUNT(*) FROM vw_billing_risk
UNION ALL
SELECT 'Readmission Tracker', COUNT(*) FROM vw_readmission_tracker;
