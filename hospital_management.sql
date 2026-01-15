-- =============================================
-- HOSPITAL MANAGEMENT SYSTEM (HMS)
-- Database: PostgreSQL
-- Full SQL Code (DDL + DML + Queries + Views + Triggers)
-- =============================================

-- 1. CREATE DATABASE
-- CREATE DATABASE hospital_management;
-- \c hospital_management;

-- =============================================
-- 2. TABLE CREATION (DDL)
-- =============================================

-- Department Table
CREATE TABLE department (
    dept_id SERIAL PRIMARY KEY,
    dept_name VARCHAR(100) NOT NULL UNIQUE
);

-- Doctor Table
CREATE TABLE doctor (
    doctor_id SERIAL PRIMARY KEY,
    doctor_name VARCHAR(100) NOT NULL,
    specialization VARCHAR(100),
    phone VARCHAR(15) UNIQUE,
    dept_id INT REFERENCES department(dept_id) ON DELETE SET NULL
);

-- Patient Table
CREATE TABLE patient (
    patient_id SERIAL PRIMARY KEY,
    patient_name VARCHAR(100) NOT NULL,
    age INT CHECK (age > 0),
    gender VARCHAR(10),
    phone VARCHAR(15) UNIQUE,
    address TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Appointment Table
CREATE TABLE appointment (
    appointment_id SERIAL PRIMARY KEY,
    patient_id INT REFERENCES patient(patient_id) ON DELETE CASCADE,
    doctor_id INT REFERENCES doctor(doctor_id) ON DELETE CASCADE,
    appointment_date DATE NOT NULL,
    status VARCHAR(20) DEFAULT 'Scheduled'
);

-- Treatment Table
CREATE TABLE treatment (
    treatment_id SERIAL PRIMARY KEY,
    appointment_id INT UNIQUE REFERENCES appointment(appointment_id) ON DELETE CASCADE,
    diagnosis TEXT,
    treatment_details TEXT,
    treatment_date DATE DEFAULT CURRENT_DATE
);

-- Bill Table
CREATE TABLE bill (
    bill_id SERIAL PRIMARY KEY,
    treatment_id INT REFERENCES treatment(treatment_id) ON DELETE CASCADE,
    amount NUMERIC(10,2) NOT NULL CHECK (amount >= 0),
    bill_date DATE DEFAULT CURRENT_DATE
);

-- Payment Table
CREATE TABLE payment (
    payment_id SERIAL PRIMARY KEY,
    bill_id INT REFERENCES bill(bill_id) ON DELETE CASCADE,
    payment_date DATE DEFAULT CURRENT_DATE,
    payment_mode VARCHAR(50),
    payment_status VARCHAR(20)
);

-- =============================================
-- 3. SAMPLE DATA INSERTION (DML)
-- =============================================

INSERT INTO department (dept_name) VALUES
('Cardiology'),
('Neurology'),
('Orthopedics'),
('General Medicine');

INSERT INTO doctor (doctor_name, specialization, phone, dept_id) VALUES
('Dr. Amit Sharma', 'Cardiologist', '9876543210', 1),
('Dr. Neha Patil', 'Neurologist', '9876543211', 2),
('Dr. Rahul Verma', 'Orthopedic', '9876543212', 3);

INSERT INTO patient (patient_name, age, gender, phone, address) VALUES
('Rohit Kumar', 30, 'Male', '9123456780', 'Nagpur'),
('Sneha Joshi', 25, 'Female', '9123456781', 'Pune'),
('Amit Singh', 40, 'Male', '9123456782', 'Mumbai');

INSERT INTO appointment (patient_id, doctor_id, appointment_date) VALUES
(1, 1, '2026-01-20'),
(2, 2, '2026-01-21'),
(3, 3, '2026-01-22');

INSERT INTO treatment (appointment_id, diagnosis, treatment_details) VALUES
(1, 'High BP', 'Medication prescribed'),
(2, 'Migraine', 'CT scan and medicines'),
(3, 'Fracture', 'X-ray and plaster');

INSERT INTO bill (treatment_id, amount) VALUES
(1, 2500.00),
(2, 3500.00),
(3, 5000.00);

INSERT INTO payment (bill_id, payment_mode, payment_status) VALUES
(1, 'Cash', 'Paid'),
(2, 'UPI', 'Paid'),
(3, 'Card', 'Pending');

-- =============================================
-- 4. INDEXES (PERFORMANCE)
-- =============================================

CREATE INDEX idx_patient_phone ON patient(phone);
CREATE INDEX idx_doctor_dept ON doctor(dept_id);
CREATE INDEX idx_appointment_date ON appointment(appointment_date);

-- =============================================
-- 5. VIEWS (REPORTING)
-- =============================================

-- View: Appointment Details
CREATE VIEW vw_appointment_details AS
SELECT a.appointment_id, p.patient_name, d.doctor_name, a.appointment_date, a.status
FROM appointment a
JOIN patient p ON a.patient_id = p.patient_id
JOIN doctor d ON a.doctor_id = d.doctor_id;

-- View: Revenue Report
CREATE VIEW vw_revenue_report AS
SELECT SUM(amount) AS total_revenue FROM bill;

-- =============================================
-- 6. STORED PROCEDURE (FUNCTION)
-- =============================================

CREATE OR REPLACE FUNCTION add_patient(
    p_name VARCHAR,
    p_age INT,
    p_gender VARCHAR,
    p_phone VARCHAR,
    p_address TEXT
)
RETURNS VOID AS $$
BEGIN
    INSERT INTO patient(patient_name, age, gender, phone, address)
    VALUES (p_name, p_age, p_gender, p_phone, p_address);
END;
$$ LANGUAGE plpgsql;

-- =============================================
-- 7. TRIGGER (AUDIT LOG)
-- =============================================

CREATE TABLE patient_log (
    log_id SERIAL PRIMARY KEY,
    patient_id INT,
    action VARCHAR(20),
    log_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE OR REPLACE FUNCTION log_patient_insert()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO patient_log(patient_id, action)
    VALUES (NEW.patient_id, 'INSERT');
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_patient_insert
AFTER INSERT ON patient
FOR EACH ROW
EXECUTE FUNCTION log_patient_insert();

-- =============================================
-- 8. IMPORTANT INTERVIEW QUERIES
-- =============================================

-- Doctor wise appointments
SELECT d.doctor_name, COUNT(a.appointment_id) AS total_appointments
FROM doctor d
LEFT JOIN appointment a ON d.doctor_id = a.doctor_id
GROUP BY d.doctor_name;

-- Department wise patient count
SELECT dept_name, COUNT(a.patient_id) AS patient_count
FROM department dp
JOIN doctor d ON dp.dept_id = d.dept_id
JOIN appointment a ON d.doctor_id = a.doctor_id
GROUP BY dept_name;

-- Pending payments
SELECT p.payment_id, b.amount, p.payment_status
FROM payment p
JOIN bill b ON p.bill_id = b.bill_id
WHERE p.payment_status = 'Pending';

-- =============================================
-- END OF PROJECT
-- =============================================
