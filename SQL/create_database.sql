-- ============================================================
-- FILE: create_database.sql
-- PROJECT: Hospital Management System
-- DESCRIPTION: Creates the database schema with all tables,
--              primary keys, foreign keys, and constraints.
-- DATABASE: MySQL 8.0+
-- ============================================================

-- Step 1: Create and select the database
CREATE DATABASE IF NOT EXISTS hospital_db;
USE hospital_db;

-- ============================================================
-- TABLE 1: departments
-- Stores hospital departments. Each doctor belongs to one department.
-- ============================================================
CREATE TABLE departments (
    department_id   INT             NOT NULL AUTO_INCREMENT,
    department_name VARCHAR(100)    NOT NULL,
    location        VARCHAR(100)    NOT NULL,
    head_doctor     VARCHAR(100)    NOT NULL,
    CONSTRAINT pk_departments PRIMARY KEY (department_id),
    CONSTRAINT uq_department_name UNIQUE (department_name)
);

-- ============================================================
-- TABLE 2: doctors
-- Stores doctor profiles. Each doctor belongs to one department.
-- ============================================================
CREATE TABLE doctors (
    doctor_id        INT             NOT NULL AUTO_INCREMENT,
    first_name       VARCHAR(50)     NOT NULL,
    last_name        VARCHAR(50)     NOT NULL,
    specialization   VARCHAR(100)    NOT NULL,
    department_id    INT             NOT NULL,
    consultation_fee DECIMAL(8,2)    NOT NULL,
    hire_date        DATE            NOT NULL,
    CONSTRAINT pk_doctors PRIMARY KEY (doctor_id),
    CONSTRAINT fk_doctors_department
        FOREIGN KEY (department_id) REFERENCES departments(department_id)
);

-- ============================================================
-- TABLE 3: patients
-- Stores patient demographics. Independent of doctors/departments.
-- ============================================================
CREATE TABLE patients (
    patient_id    INT          NOT NULL AUTO_INCREMENT,
    first_name    VARCHAR(50)  NOT NULL,
    last_name     VARCHAR(50)  NOT NULL,
    date_of_birth DATE         NOT NULL,
    gender        ENUM('Male','Female','Other') NOT NULL,
    phone         VARCHAR(20)  NOT NULL,
    blood_type    VARCHAR(5)   NOT NULL,
    CONSTRAINT pk_patients PRIMARY KEY (patient_id)
);

-- ============================================================
-- TABLE 4: appointments
-- Central fact table linking patients to doctors.
-- Records every visit, diagnosis, billing, and status.
-- ============================================================
CREATE TABLE appointments (
    appointment_id   INT             NOT NULL AUTO_INCREMENT,
    patient_id       INT             NOT NULL,
    doctor_id        INT             NOT NULL,
    appointment_date DATE            NOT NULL,
    diagnosis        VARCHAR(200)    NOT NULL,
    bill_amount      DECIMAL(10,2)   NOT NULL,
    status           ENUM('Completed','Cancelled','No-Show') NOT NULL DEFAULT 'Completed',
    CONSTRAINT pk_appointments PRIMARY KEY (appointment_id),
    CONSTRAINT fk_appointments_patient
        FOREIGN KEY (patient_id) REFERENCES patients(patient_id),
    CONSTRAINT fk_appointments_doctor
        FOREIGN KEY (doctor_id) REFERENCES doctors(doctor_id)
);
