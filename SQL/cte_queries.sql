-- ============================================================
-- FILE: cte_queries.sql
-- PROJECT: Hospital Management System
-- DESCRIPTION: Demonstrates 5 CTE patterns with business context
-- ============================================================

USE hospital_db;

-- ============================================================
-- CTE 1: SIMPLE CTE
-- Business Question: Which patients have spent more than $500
--                    in total across all their appointments?
-- ============================================================

WITH patient_spending AS (
    -- Aggregate total billing per patient from the appointments table
    SELECT
        patient_id,
        SUM(bill_amount) AS total_spent,   -- Sum all bills for each patient
        COUNT(*)         AS visit_count    -- Count how many times they visited
    FROM appointments
    WHERE status = 'Completed'             -- Only count completed visits
    GROUP BY patient_id
)
-- Join the CTE result with patients to get readable names
SELECT
    p.patient_id,
    CONCAT(p.first_name, ' ', p.last_name) AS patient_name,
    ps.visit_count,
    ps.total_spent
FROM patient_spending ps
JOIN patients p ON p.patient_id = ps.patient_id
WHERE ps.total_spent > 500                 -- Filter high-value patients
ORDER BY ps.total_spent DESC;

/*
EXPLANATION:
  The CTE named patient_spending pre-calculates each patient's total
  spending and visit count. The outer query then joins this summary
  to the patients table to retrieve names. Without a CTE, this would
  require a subquery inside the FROM clause, making it harder to read.

BUSINESS VALUE:
  Identifies high-value patients for loyalty programs, priority
  scheduling, or targeted health management plans.

EXPECTED OUTPUT (sample):
  patient_id | patient_name     | visit_count | total_spent
  -----------|------------------|-------------|------------
  1          | Alice Thompson   | 3           | 920.00
  13         | Maria Johansson  | 2           | 570.00
  ...
*/


-- ============================================================
-- CTE 2: MULTIPLE CTEs
-- Business Question: Which doctors earn above-average revenue
--                    AND see above-average patient volume?
-- ============================================================

WITH doctor_revenue AS (
    -- CTE 1: Total revenue generated per doctor
    SELECT
        doctor_id,
        SUM(bill_amount)  AS total_revenue,
        COUNT(*)          AS total_appointments
    FROM appointments
    WHERE status = 'Completed'
    GROUP BY doctor_id
),
avg_benchmarks AS (
    -- CTE 2: Calculate the hospital-wide averages from CTE 1
    SELECT
        AVG(total_revenue)       AS avg_revenue,
        AVG(total_appointments)  AS avg_appointments
    FROM doctor_revenue
)
-- Final query: find doctors who beat BOTH averages
SELECT
    d.doctor_id,
    CONCAT(d.first_name, ' ', d.last_name) AS doctor_name,
    d.specialization,
    dr.total_revenue,
    dr.total_appointments,
    ROUND(ab.avg_revenue, 2)       AS hospital_avg_revenue,
    ROUND(ab.avg_appointments, 2)  AS hospital_avg_visits
FROM doctor_revenue dr
JOIN avg_benchmarks ab
    ON dr.total_revenue > ab.avg_revenue           -- Above average revenue
    AND dr.total_appointments > ab.avg_appointments -- Above average volume
JOIN doctors d ON d.doctor_id = dr.doctor_id
ORDER BY dr.total_revenue DESC;

/*
EXPLANATION:
  Two CTEs are chained: doctor_revenue computes per-doctor totals,
  then avg_benchmarks computes averages across those totals.
  The final SELECT cross-joins both CTEs (avg_benchmarks has one row)
  and filters doctors who exceed both thresholds.

BUSINESS VALUE:
  Pinpoints top-performing doctors for recognition, mentoring roles,
  or resource allocation decisions.

EXPECTED OUTPUT (sample):
  doctor_id | doctor_name      | specialization              | total_revenue | total_appointments
  ----------|------------------|-----------------------------|---------------|-------------------
  1         | James Hartwell   | Interventional Cardiology   | 1310.00       | 4
  ...
*/


-- ============================================================
-- CTE 3: RECURSIVE CTE
-- Business Scenario: Hospital has a management hierarchy.
--                    CEO → Department Heads → Senior Doctors → Doctors
-- ============================================================

-- First, create the hierarchy table (run once)
CREATE TABLE IF NOT EXISTS staff_hierarchy (
    staff_id    INT          NOT NULL,
    staff_name  VARCHAR(100) NOT NULL,
    role        VARCHAR(100) NOT NULL,
    manager_id  INT          NULL,   -- NULL means top of hierarchy
    CONSTRAINT pk_staff PRIMARY KEY (staff_id)
);

-- Insert hierarchy data
INSERT IGNORE INTO staff_hierarchy (staff_id, staff_name, role, manager_id) VALUES
(1,  'Dr. Margaret Cole',    'Chief Medical Officer',    NULL),
(2,  'Dr. James Hartwell',   'Head of Cardiology',       1),
(3,  'Dr. Priya Sharma',     'Head of Neurology',        1),
(4,  'Dr. Carlos Mendez',    'Head of Orthopedics',      1),
(5,  'Dr. Rachel Bloom',     'Senior Cardiologist',      2),
(6,  'Dr. David Okafor',     'Senior Neurologist',       3),
(7,  'Dr. Susan Park',       'Orthopedic Specialist',    4),
(8,  'Dr. Emily Watson',     'Head of Pediatrics',       1),
(9,  'Dr. Kevin Adeyemi',    'Pediatric Surgeon',        8),
(10, 'Dr. Samuel Osei',      'Head of General Medicine', 1),
(11, 'Dr. Fatima Al-Hassan', 'General Practitioner',     10);

-- Recursive CTE: traverse the hierarchy from the top down
WITH RECURSIVE org_chart AS (
    -- Anchor: start with the top-level manager (no manager_id)
    SELECT
        staff_id,
        staff_name,
        role,
        manager_id,
        0           AS depth,          -- Level 0 = top of hierarchy
        staff_name  AS hierarchy_path  -- Track the path taken
    FROM staff_hierarchy
    WHERE manager_id IS NULL

    UNION ALL

    -- Recursive member: join each staff member to their manager
    SELECT
        s.staff_id,
        s.staff_name,
        s.role,
        s.manager_id,
        oc.depth + 1,                                          -- Increment depth
        CONCAT(oc.hierarchy_path, ' → ', s.staff_name)        -- Build path string
    FROM staff_hierarchy s
    JOIN org_chart oc ON oc.staff_id = s.manager_id           -- Match to parent
)
SELECT
    CONCAT(REPEAT('    ', depth), staff_name) AS indented_name, -- Visual indent
    role,
    depth                                     AS hierarchy_level,
    hierarchy_path
FROM org_chart
ORDER BY hierarchy_path;

/*
EXPLANATION:
  A recursive CTE has two parts separated by UNION ALL:
  1. Anchor member — selects the root row (manager_id IS NULL).
  2. Recursive member — repeatedly joins staff to their manager
     until no more matches exist.
  The REPEAT() function indents names visually by hierarchy level.

BUSINESS VALUE:
  Allows HR to print org charts, identify reporting lines, calculate
  span of control, and plan succession without any application code.

EXPECTED OUTPUT (sample):
  indented_name                    | role                    | hierarchy_level
  ---------------------------------|-------------------------|----------------
  Dr. Margaret Cole                | Chief Medical Officer   | 0
      Dr. James Hartwell           | Head of Cardiology      | 1
          Dr. Rachel Bloom         | Senior Cardiologist     | 2
  ...
*/


-- ============================================================
-- CTE 4: CTE WITH AGGREGATION
-- Business Question: What is the monthly revenue trend,
--                    and which month performed best?
-- ============================================================

WITH monthly_revenue AS (
    -- Aggregate completed appointment revenue by month
    SELECT
        DATE_FORMAT(appointment_date, '%Y-%m') AS revenue_month,
        COUNT(*)                               AS total_appointments,
        SUM(bill_amount)                       AS monthly_revenue,
        AVG(bill_amount)                       AS avg_bill,
        MAX(bill_amount)                       AS highest_bill,
        MIN(bill_amount)                       AS lowest_bill
    FROM appointments
    WHERE status = 'Completed'
    GROUP BY DATE_FORMAT(appointment_date, '%Y-%m')
)
SELECT
    revenue_month,
    total_appointments,
    monthly_revenue,
    ROUND(avg_bill, 2)    AS avg_bill,
    highest_bill,
    lowest_bill,
    -- Flag the best performing month
    CASE
        WHEN monthly_revenue = (SELECT MAX(monthly_revenue) FROM monthly_revenue)
        THEN 'Best Month'
        ELSE ''
    END AS performance_flag
FROM monthly_revenue
ORDER BY revenue_month;

/*
EXPLANATION:
  The CTE groups appointments by year-month using DATE_FORMAT, then
  applies SUM, COUNT, AVG, MAX, MIN aggregations. The outer query
  adds a CASE expression that references the CTE again in a subquery
  to flag the best-performing month.

BUSINESS VALUE:
  Finance teams use monthly revenue trends to forecast budgets,
  identify seasonal demand spikes, and plan staffing levels.

EXPECTED OUTPUT (sample):
  revenue_month | total_appointments | monthly_revenue | avg_bill | performance_flag
  --------------|--------------------|-----------------|-----------|-----------------
  2024-01       | 7                  | 1850.00         | 264.29   |
  2024-02       | 7                  | 2070.00         | 295.71   |
  2024-03       | 7                  | 2060.00         | 294.29   |
  2024-04       | 6                  | 1735.00         | 289.17   |
  2024-05       | 8                  | 2310.00         | 288.75   | Best Month
*/


-- ============================================================
-- CTE 5: CTE COMBINED WITH JOIN
-- Business Question: For each department, show the top-earning
--                    doctor and their share of department revenue.
-- ============================================================

WITH doctor_totals AS (
    -- Step 1: Total revenue per doctor from completed appointments
    SELECT
        a.doctor_id,
        SUM(a.bill_amount) AS doctor_revenue
    FROM appointments a
    WHERE a.status = 'Completed'
    GROUP BY a.doctor_id
),
dept_totals AS (
    -- Step 2: Total revenue per department by joining doctors
    SELECT
        d.department_id,
        SUM(dt.doctor_revenue) AS dept_revenue
    FROM doctor_totals dt
    JOIN doctors d ON d.doctor_id = dt.doctor_id
    GROUP BY d.department_id
)
-- Step 3: Join everything together for the final report
SELECT
    dep.department_name,
    CONCAT(d.first_name, ' ', d.last_name) AS doctor_name,
    d.specialization,
    dt.doctor_revenue,
    dpt.dept_revenue,
    ROUND((dt.doctor_revenue / dpt.dept_revenue) * 100, 1) AS revenue_share_pct
FROM doctor_totals dt
JOIN doctors d       ON d.doctor_id       = dt.doctor_id
JOIN dept_totals dpt ON dpt.department_id = d.department_id
JOIN departments dep ON dep.department_id = d.department_id
ORDER BY dep.department_name, dt.doctor_revenue DESC;

/*
EXPLANATION:
  Three layers of logic are separated into two CTEs:
  - doctor_totals: per-doctor revenue
  - dept_totals: per-department revenue (built from doctor_totals)
  The final SELECT joins both CTEs with the doctors and departments
  tables to produce a clean, readable report.

BUSINESS VALUE:
  Department heads can see which doctors drive the most revenue
  and whether workload is distributed fairly across the team.

EXPECTED OUTPUT (sample):
  department_name | doctor_name      | specialization            | doctor_revenue | dept_revenue | revenue_share_pct
  ----------------|------------------|---------------------------|----------------|--------------|------------------
  Cardiology      | James Hartwell   | Interventional Cardiology | 1310.00        | 2120.00      | 61.8
  Cardiology      | Rachel Bloom     | Echocardiography          | 810.00         | 2120.00      | 38.2
  ...
*/
