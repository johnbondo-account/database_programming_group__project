-- ============================================================
-- FILE: insert_data.sql
-- PROJECT: Hospital Management System
-- DESCRIPTION: Inserts realistic sample data into all tables.
-- Run AFTER create_database.sql
-- ============================================================

USE hospital_db;

-- ============================================================
-- INSERT: departments (6 rows)
-- ============================================================
INSERT INTO departments (department_name, location, head_doctor) VALUES
('Cardiology',       'Block A, Floor 2', 'Dr. James Hartwell'),
('Neurology',        'Block B, Floor 3', 'Dr. Priya Sharma'),
('Orthopedics',      'Block A, Floor 1', 'Dr. Carlos Mendez'),
('Pediatrics',       'Block C, Floor 1', 'Dr. Emily Watson'),
('General Medicine', 'Block D, Floor 1', 'Dr. Samuel Osei'),
('Oncology',         'Block B, Floor 4', 'Dr. Linda Nguyen');

-- ============================================================
-- INSERT: doctors (12 rows)
-- ============================================================
INSERT INTO doctors (first_name, last_name, specialization, department_id, consultation_fee, hire_date) VALUES
('James',   'Hartwell',  'Interventional Cardiology', 1, 250.00, '2015-03-10'),
('Rachel',  'Bloom',     'Echocardiography',           1, 200.00, '2018-07-22'),
('Priya',   'Sharma',    'Stroke Neurology',           2, 230.00, '2014-01-15'),
('David',   'Okafor',    'Epilepsy',                   2, 210.00, '2019-09-01'),
('Carlos',  'Mendez',    'Joint Replacement',          3, 220.00, '2016-05-20'),
('Susan',   'Park',      'Sports Medicine',            3, 190.00, '2020-02-14'),
('Emily',   'Watson',    'Neonatology',                4, 180.00, '2013-11-30'),
('Kevin',   'Adeyemi',   'Pediatric Surgery',          4, 215.00, '2017-08-05'),
('Samuel',  'Osei',      'Internal Medicine',          5, 160.00, '2012-06-18'),
('Fatima',  'Al-Hassan', 'Family Medicine',            5, 150.00, '2021-03-25'),
('Linda',   'Nguyen',    'Medical Oncology',           6, 280.00, '2011-09-09'),
('Marcus',  'Reid',      'Radiation Oncology',         6, 270.00, '2016-12-01');

-- ============================================================
-- INSERT: patients (20 rows)
-- ============================================================
INSERT INTO patients (first_name, last_name, date_of_birth, gender, phone, blood_type) VALUES
('Alice',    'Thompson',  '1985-04-12', 'Female', '555-0101', 'A+'),
('Brian',    'Carter',    '1972-09-23', 'Male',   '555-0102', 'O+'),
('Clara',    'Diaz',      '1990-01-07', 'Female', '555-0103', 'B+'),
('Daniel',   'Nguyen',    '1965-11-30', 'Male',   '555-0104', 'AB+'),
('Eva',      'Kowalski',  '1998-06-15', 'Female', '555-0105', 'A-'),
('Frank',    'Obi',       '1980-03-28', 'Male',   '555-0106', 'O-'),
('Grace',    'Patel',     '2005-08-19', 'Female', '555-0107', 'B-'),
('Henry',    'Morrison',  '1955-12-05', 'Male',   '555-0108', 'AB-'),
('Irene',    'Santos',    '1993-07-22', 'Female', '555-0109', 'A+'),
('James',    'Owusu',     '1970-02-14', 'Male',   '555-0110', 'O+'),
('Karen',    'Lee',       '1988-10-31', 'Female', '555-0111', 'B+'),
('Liam',     'Fernandez', '2001-05-09', 'Male',   '555-0112', 'A+'),
('Maria',    'Johansson', '1975-03-17', 'Female', '555-0113', 'O+'),
('Nathan',   'Bakr',      '1962-08-25', 'Male',   '555-0114', 'AB+'),
('Olivia',   'Chen',      '1995-12-03', 'Female', '555-0115', 'A-'),
('Patrick',  'Nwosu',     '1983-06-11', 'Male',   '555-0116', 'B+'),
('Quinn',    'Larsson',   '2010-01-28', 'Female', '555-0117', 'O+'),
('Robert',   'Kimani',    '1950-09-14', 'Male',   '555-0118', 'A+'),
('Sophia',   'Müller',    '1992-04-06', 'Female', '555-0119', 'B-'),
('Thomas',   'Adebayo',   '1978-11-20', 'Male',   '555-0120', 'O+');

-- ============================================================
-- INSERT: appointments (40 rows)
-- Covers multiple months to enable trend analysis
-- ============================================================
INSERT INTO appointments (patient_id, doctor_id, appointment_date, diagnosis, bill_amount, status) VALUES
-- January 2024
( 1,  1, '2024-01-05', 'Hypertension',           320.00, 'Completed'),
( 2,  3, '2024-01-08', 'Migraine',                290.00, 'Completed'),
( 3,  9, '2024-01-10', 'Upper Respiratory Tract', 180.00, 'Completed'),
( 4,  5, '2024-01-12', 'Knee Osteoarthritis',     310.00, 'Completed'),
( 5,  7, '2024-01-15', 'Routine Checkup',         200.00, 'Completed'),
( 6, 11, '2024-01-18', 'Lung Cancer Follow-up',   350.00, 'Completed'),
( 7,  8, '2024-01-20', 'Appendicitis',            400.00, 'Completed'),
( 8,  2, '2024-01-22', 'Atrial Fibrillation',     280.00, 'No-Show'),
-- February 2024
( 9,  4, '2024-02-03', 'Epileptic Seizure',       260.00, 'Completed'),
(10,  6, '2024-02-05', 'Ligament Tear',           240.00, 'Completed'),
(11,  1, '2024-02-07', 'Coronary Artery Disease', 380.00, 'Completed'),
(12, 10, '2024-02-10', 'Flu',                     170.00, 'Completed'),
(13,  3, '2024-02-14', 'Parkinson Disease',       300.00, 'Completed'),
(14, 12, '2024-02-18', 'Prostate Cancer',         420.00, 'Completed'),
(15,  9, '2024-02-20', 'Diabetes Type 2',         190.00, 'Cancelled'),
(16,  5, '2024-02-22', 'Hip Fracture',            350.00, 'Completed'),
-- March 2024
(17,  7, '2024-03-01', 'Asthma',                  210.00, 'Completed'),
(18,  2, '2024-03-04', 'Heart Failure',           310.00, 'Completed'),
(19,  4, '2024-03-07', 'Multiple Sclerosis',      270.00, 'Completed'),
(20,  8, '2024-03-10', 'Hernia Repair',           390.00, 'Completed'),
( 1,  1, '2024-03-12', 'Hypertension Review',     300.00, 'Completed'),
( 2, 11, '2024-03-15', 'Breast Cancer Screening', 330.00, 'Completed'),
( 3,  6, '2024-03-18', 'Ankle Sprain',            200.00, 'No-Show'),
( 4,  3, '2024-03-20', 'Stroke Follow-up',        280.00, 'Completed'),
-- April 2024
( 5,  9, '2024-04-02', 'Anemia',                  175.00, 'Completed'),
( 6,  1, '2024-04-05', 'Chest Pain',              340.00, 'Completed'),
( 7, 10, '2024-04-08', 'Fever',                   160.00, 'Completed'),
( 8,  5, '2024-04-11', 'Spinal Stenosis',         360.00, 'Completed'),
( 9, 12, '2024-04-14', 'Colorectal Cancer',       450.00, 'Completed'),
(10,  2, '2024-04-17', 'Palpitations',            250.00, 'Completed'),
-- May 2024
(11,  4, '2024-05-02', 'Headache Cluster',        240.00, 'Completed'),
(12,  7, '2024-05-06', 'Growth Delay',            220.00, 'Completed'),
(13,  1, '2024-05-09', 'Angina',                  370.00, 'Completed'),
(14,  9, '2024-05-13', 'Hypertension',            180.00, 'Completed'),
(15,  3, '2024-05-16', 'Dementia',                290.00, 'Completed'),
(16, 11, '2024-05-20', 'Ovarian Cancer',          410.00, 'Completed'),
(17,  6, '2024-05-23', 'Rotator Cuff Tear',       230.00, 'Cancelled'),
(18,  8, '2024-05-27', 'Gallstones',              380.00, 'Completed'),
(19,  2, '2024-05-30', 'Arrhythmia',              270.00, 'Completed'),
(20,  5, '2024-05-31', 'Fracture Wrist',          320.00, 'Completed');
