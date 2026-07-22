-- ============================================================
-- FILE: window_functions.sql
-- PROJECT: Hospital Management System
-- DESCRIPTION: Demonstrates all required SQL Window Functions
-- ============================================================

USE hospital_db;

-- ============================================================
-- SECTION A: RANKING FUNCTIONS
-- ============================================================

-- ------------------------------------------------------------
-- A1: ROW_NUMBER()
-- Assigns a unique sequential number to each appointment
-- per doctor, ordered by bill amount descending.
-- Business Use: Identify each doctor's highest-billed appointment.
-- ------------------------------------------------------------
SELECT
    a.appointment_id,
    CONCAT(d.first_name, ' ', d.last_name)  AS doctor_name,
    CONCAT(p.first_name, ' ', p.last_name)  AS patient_name,
    a.appointment_date,
    a.bill_amount,
    ROW_NUMBER() OVER (
        PARTITION BY a.doctor_id             -- Restart count for each doctor
        ORDER BY a.bill_amount DESC          -- Highest bill gets number 1
    ) AS row_num
FROM appointments a
JOIN doctors  d ON d.doctor_id  = a.doctor_id
JOIN patients p ON p.patient_id = a.patient_id
WHERE a.status = 'Completed'
ORDER BY doctor_name, row_num;

/*
EXPLANATION:
  ROW_NUMBER() always produces unique numbers — no ties.
  PARTITION BY doctor_id means the counter resets for each doctor.
  Row 1 for each doctor is their most expensive appointment.

BUSINESS VALUE:
  Billing teams can quickly pull the top appointment per doctor
  for auditing or insurance claim prioritization.

EXPECTED OUTPUT (sample):
  appointment_id | doctor_name    | patient_name    | bill_amount | row_num
  ---------------|----------------|-----------------|-------------|--------
  26             | James Hartwell | Frank Obi       | 340.00      | 1
  21             | James Hartwell | Alice Thompson  | 300.00      | 2
  1              | James Hartwell | Alice Thompson  | 320.00      | 3
  ...
*/


-- ------------------------------------------------------------
-- A2: RANK()
-- Ranks doctors by total revenue. Tied doctors share the same
-- rank, and the next rank skips numbers (1,1,3...).
-- ------------------------------------------------------------
SELECT
    CONCAT(d.first_name, ' ', d.last_name) AS doctor_name,
    d.specialization,
    SUM(a.bill_amount)                     AS total_revenue,
    RANK() OVER (
        ORDER BY SUM(a.bill_amount) DESC   -- Highest revenue = rank 1
    ) AS revenue_rank
FROM appointments a
JOIN doctors d ON d.doctor_id = a.doctor_id
WHERE a.status = 'Completed'
GROUP BY a.doctor_id, d.first_name, d.last_name, d.specialization
ORDER BY revenue_rank;

/*
EXPLANATION:
  RANK() allows ties. If two doctors earn the same total, they both
  get rank 1 and the next doctor gets rank 3 (rank 2 is skipped).
  This is standard competition ranking (Olympic-style).

BUSINESS VALUE:
  Management can rank doctors by revenue contribution for
  performance reviews and bonus allocation.
*/


-- ------------------------------------------------------------
-- A3: DENSE_RANK()
-- Same as RANK() but no gaps in ranking numbers (1,1,2...).
-- ------------------------------------------------------------
SELECT
    CONCAT(d.first_name, ' ', d.last_name) AS doctor_name,
    dep.department_name,
    SUM(a.bill_amount)                     AS total_revenue,
    DENSE_RANK() OVER (
        PARTITION BY d.department_id        -- Rank within each department
        ORDER BY SUM(a.bill_amount) DESC
    ) AS dept_revenue_rank
FROM appointments a
JOIN doctors     d   ON d.doctor_id     = a.doctor_id
JOIN departments dep ON dep.department_id = d.department_id
WHERE a.status = 'Completed'
GROUP BY a.doctor_id, d.first_name, d.last_name, d.department_id, dep.department_name
ORDER BY dep.department_name, dept_revenue_rank;

/*
EXPLANATION:
  DENSE_RANK() with PARTITION BY department_id ranks doctors
  within their own department. No rank numbers are skipped.
  This is useful when you want clean sequential rankings per group.

BUSINESS VALUE:
  Department heads can see who is #1 in their department
  without being confused by skipped rank numbers.
*/


-- ------------------------------------------------------------
-- A4: PERCENT_RANK()
-- Shows each doctor's relative standing as a percentage (0 to 1).
-- ------------------------------------------------------------
SELECT
    CONCAT(d.first_name, ' ', d.last_name) AS doctor_name,
    SUM(a.bill_amount)                     AS total_revenue,
    ROUND(
        PERCENT_RANK() OVER (
            ORDER BY SUM(a.bill_amount)    -- Lower revenue = lower percentile
        ) * 100, 1
    )                                      AS percentile_rank
FROM appointments a
JOIN doctors d ON d.doctor_id = a.doctor_id
WHERE a.status = 'Completed'
GROUP BY a.doctor_id, d.first_name, d.last_name
ORDER BY percentile_rank DESC;

/*
EXPLANATION:
  PERCENT_RANK() = (rank - 1) / (total rows - 1).
  A value of 100 means the doctor is at the very top.
  A value of 0 means they are at the bottom.

BUSINESS VALUE:
  HR can identify doctors in the bottom 25th percentile for
  coaching, and top 10% for recognition awards.
*/


-- ============================================================
-- SECTION B: AGGREGATE WINDOW FUNCTIONS
-- ============================================================

-- ------------------------------------------------------------
-- B1: SUM() OVER() — Running total of revenue by date
-- ------------------------------------------------------------
SELECT
    a.appointment_date,
    a.bill_amount,
    SUM(a.bill_amount) OVER (
        ORDER BY a.appointment_date          -- Accumulate in date order
        ROWS BETWEEN UNBOUNDED PRECEDING     -- From the very first row
                 AND CURRENT ROW             -- Up to the current row
    ) AS running_total_revenue
FROM appointments a
WHERE a.status = 'Completed'
ORDER BY a.appointment_date;

/*
EXPLANATION:
  ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW defines the
  window frame — it grows with each row, creating a running total.
  Unlike GROUP BY, this keeps every individual row visible.

BUSINESS VALUE:
  Finance can track cumulative revenue against monthly targets
  in real time without losing row-level detail.
*/


-- ------------------------------------------------------------
-- B2: AVG() OVER() — Compare each bill to the doctor's average
-- ------------------------------------------------------------
SELECT
    CONCAT(d.first_name, ' ', d.last_name) AS doctor_name,
    a.appointment_date,
    a.diagnosis,
    a.bill_amount,
    ROUND(AVG(a.bill_amount) OVER (
        PARTITION BY a.doctor_id             -- Average per doctor
    ), 2)                                    AS doctor_avg_bill,
    ROUND(a.bill_amount - AVG(a.bill_amount) OVER (
        PARTITION BY a.doctor_id
    ), 2)                                    AS variance_from_avg
FROM appointments a
JOIN doctors d ON d.doctor_id = a.doctor_id
WHERE a.status = 'Completed'
ORDER BY doctor_name, a.appointment_date;

/*
EXPLANATION:
  AVG() OVER(PARTITION BY doctor_id) computes the average bill
  for each doctor across all their appointments, then attaches
  that average to every row. The variance column shows whether
  a specific appointment was above or below that doctor's norm.

BUSINESS VALUE:
  Billing auditors can flag unusually high or low charges
  compared to a doctor's own historical average.
*/


-- ------------------------------------------------------------
-- B3: MIN() and MAX() OVER() — Department billing range
-- ------------------------------------------------------------
SELECT
    dep.department_name,
    CONCAT(d.first_name, ' ', d.last_name) AS doctor_name,
    a.bill_amount,
    MIN(a.bill_amount) OVER (
        PARTITION BY d.department_id         -- Min bill in this department
    ) AS dept_min_bill,
    MAX(a.bill_amount) OVER (
        PARTITION BY d.department_id         -- Max bill in this department
    ) AS dept_max_bill
FROM appointments a
JOIN doctors     d   ON d.doctor_id       = a.doctor_id
JOIN departments dep ON dep.department_id = d.department_id
WHERE a.status = 'Completed'
ORDER BY dep.department_name, a.bill_amount;

/*
EXPLANATION:
  MIN() and MAX() OVER(PARTITION BY department_id) attach the
  department's billing range to every row without collapsing
  the data. Each row shows its own bill alongside the department
  floor and ceiling.

BUSINESS VALUE:
  Pricing committees can see the billing spread within each
  department to standardize fee structures.
*/


-- ============================================================
-- SECTION C: NAVIGATION FUNCTIONS
-- ============================================================

-- ------------------------------------------------------------
-- C1: LAG() — Compare each appointment bill to the previous one
-- for the same patient (month-over-month change)
-- ------------------------------------------------------------
SELECT
    CONCAT(p.first_name, ' ', p.last_name) AS patient_name,
    a.appointment_date,
    a.bill_amount,
    LAG(a.bill_amount) OVER (
        PARTITION BY a.patient_id            -- Look back within same patient
        ORDER BY a.appointment_date          -- In chronological order
    )                                        AS previous_bill,
    ROUND(
        a.bill_amount - LAG(a.bill_amount) OVER (
            PARTITION BY a.patient_id
            ORDER BY a.appointment_date
        ), 2
    )                                        AS bill_change
FROM appointments a
JOIN patients p ON p.patient_id = a.patient_id
WHERE a.status = 'Completed'
ORDER BY patient_name, a.appointment_date;

/*
EXPLANATION:
  LAG() looks at the previous row within the same partition.
  For the first appointment per patient, LAG() returns NULL
  because there is no prior row. bill_change shows whether
  the patient's cost went up or down since their last visit.

BUSINESS VALUE:
  Patient services can identify patients whose bills are
  consistently increasing, which may indicate worsening health
  or billing errors requiring review.
*/


-- ------------------------------------------------------------
-- C2: LEAD() — Preview the next appointment bill per patient
-- ------------------------------------------------------------
SELECT
    CONCAT(p.first_name, ' ', p.last_name) AS patient_name,
    a.appointment_date,
    a.bill_amount,
    LEAD(a.bill_amount) OVER (
        PARTITION BY a.patient_id
        ORDER BY a.appointment_date
    )                                       AS next_bill,
    LEAD(a.appointment_date) OVER (
        PARTITION BY a.patient_id
        ORDER BY a.appointment_date
    )                                       AS next_appointment_date
FROM appointments a
JOIN patients p ON p.patient_id = a.patient_id
WHERE a.status = 'Completed'
ORDER BY patient_name, a.appointment_date;

/*
EXPLANATION:
  LEAD() looks forward to the next row in the partition.
  For the last appointment per patient, LEAD() returns NULL.
  This shows what the patient's next visit will cost and when.

BUSINESS VALUE:
  Scheduling teams can proactively contact patients whose next
  appointment is approaching, improving attendance rates.
*/


-- ============================================================
-- SECTION D: DISTRIBUTION FUNCTIONS
-- ============================================================

-- ------------------------------------------------------------
-- D1: NTILE(4) — Divide doctors into revenue quartiles
-- ------------------------------------------------------------
SELECT
    CONCAT(d.first_name, ' ', d.last_name) AS doctor_name,
    d.specialization,
    SUM(a.bill_amount)                     AS total_revenue,
    NTILE(4) OVER (
        ORDER BY SUM(a.bill_amount) DESC   -- Split into 4 equal groups
    )                                      AS revenue_quartile
FROM appointments a
JOIN doctors d ON d.doctor_id = a.doctor_id
WHERE a.status = 'Completed'
GROUP BY a.doctor_id, d.first_name, d.last_name, d.specialization
ORDER BY revenue_quartile, total_revenue DESC;

/*
EXPLANATION:
  NTILE(4) divides all doctors into 4 equal-sized buckets.
  Quartile 1 = top 25% earners, Quartile 4 = bottom 25%.
  If the number of rows doesn't divide evenly, earlier buckets
  get one extra row.

BUSINESS VALUE:
  Management can apply different performance strategies per
  quartile: reward Q1, support Q4, and benchmark Q2/Q3.
*/


-- ------------------------------------------------------------
-- D2: CUME_DIST() — Cumulative distribution of bill amounts
-- ------------------------------------------------------------
SELECT
    a.appointment_id,
    CONCAT(d.first_name, ' ', d.last_name) AS doctor_name,
    a.bill_amount,
    ROUND(
        CUME_DIST() OVER (
            ORDER BY a.bill_amount           -- What fraction of bills are <= this?
        ) * 100, 1
    )                                        AS cumulative_pct
FROM appointments a
JOIN doctors d ON d.doctor_id = a.doctor_id
WHERE a.status = 'Completed'
ORDER BY a.bill_amount;

/*
EXPLANATION:
  CUME_DIST() = (number of rows with value <= current row) / total rows.
  A cumulative_pct of 80 means 80% of all appointments cost
  the same or less than this appointment.

BUSINESS VALUE:
  Finance can determine pricing thresholds — for example,
  "90% of our appointments cost less than $380" — to set
  insurance reimbursement caps or patient payment plans.
*/
