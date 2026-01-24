CREATE DATABASE hospital_db;
USE hospital_db;

CREATE TABLE patients (
    patient_id VARCHAR(10) PRIMARY KEY,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    gender CHAR(1),
    date_of_birth DATE,
    contact_number BIGINT,
    address VARCHAR(255),
    registration_date DATE,
    insurance_provider VARCHAR(100),
    insurance_number VARCHAR(50),
    email VARCHAR(100)
);
SELECT*FROM patients;

CREATE TABLE doctors (
    doctor_id VARCHAR(10) PRIMARY KEY,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    specialization VARCHAR(100),
    phone_number BIGINT,
    years_experience INT,
    hospital_branch VARCHAR(100),
    email VARCHAR(100)
);
SELECT*FROM doctors;

CREATE TABLE appointments (
    appointment_id VARCHAR(10) PRIMARY KEY,
    patient_id VARCHAR(10),
    doctor_id VARCHAR(10),
    appointment_date DATE,
    appointment_time TIME,
    reason_for_visit VARCHAR(255),
    status VARCHAR(20),
    FOREIGN KEY (patient_id) REFERENCES patients(patient_id),
    FOREIGN KEY (doctor_id) REFERENCES doctors(doctor_id)
);
SELECT*FROM appointments;

CREATE TABLE treatments (
    treatment_id VARCHAR(10) PRIMARY KEY,
    appointment_id VARCHAR(10),
    treatment_type VARCHAR(100),
    description VARCHAR(255),
    cost DECIMAL(10,2),
    treatment_date DATE,
    FOREIGN KEY (appointment_id) REFERENCES appointments(appointment_id)
);
SELECT*FROM treatments;

CREATE TABLE billing (
    bill_id VARCHAR(10) PRIMARY KEY,
    patient_id VARCHAR(10),
    treatment_id VARCHAR(10),
    bill_date DATE,
    amount DECIMAL(10,2),
    payment_method VARCHAR(50),
    payment_status VARCHAR(20),
    FOREIGN KEY (patient_id) REFERENCES patients(patient_id),
    FOREIGN KEY (treatment_id) REFERENCES treatments(treatment_id)
);
SELECT*FROM billing;

SELECT 
    d.first_name,
    d.last_name,
    d.specialization,
    COUNT(a.appointment_id) AS total_appointments
FROM doctors d
LEFT JOIN appointments a ON d.doctor_id = a.doctor_id
GROUP BY d.doctor_id
ORDER BY total_appointments DESC;

SELECT 
    DATE_FORMAT(bill_date, '%Y-%m') AS month,
    SUM(amount) AS total_revenue
FROM billing
GROUP BY month
ORDER BY month;

SELECT 
    p.first_name,
    p.last_name,
    COUNT(a.appointment_id) AS visit_count
FROM patients p
JOIN appointments a ON p.patient_id = a.patient_id
GROUP BY p.patient_id
HAVING visit_count > 1
ORDER BY visit_count DESC;

SELECT 
    treatment_type,
    COUNT(*) AS frequency
FROM treatments
GROUP BY treatment_type
ORDER BY frequency DESC;

SELECT 
    bill_id,
    patient_id,
    amount,
    payment_status
FROM billing
WHERE payment_status <> 'Paid';

SELECT 
    doctor_id,
    first_name,
    last_name,
    specialization,
    total_appointments,
    RANK() OVER (
        PARTITION BY specialization
        ORDER BY total_appointments DESC
    ) AS specialization_rank
FROM (
    SELECT 
        d.doctor_id,
        d.first_name,
        d.last_name,
        d.specialization,
        COUNT(a.appointment_id) AS total_appointments
    FROM doctors d
    LEFT JOIN appointments a 
        ON d.doctor_id = a.doctor_id
    GROUP BY d.doctor_id
) t;

WITH monthly_revenue AS (
    SELECT 
        DATE_FORMAT(bill_date, '%Y-%m') AS month,
        SUM(amount) AS revenue
    FROM billing
    GROUP BY month
)
SELECT
    month,
    revenue,
    revenue - LAG(revenue) OVER (ORDER BY month) AS revenue_change
FROM monthly_revenue;

WITH patient_visits AS (
    SELECT
        p.patient_id,
        p.first_name,
        p.last_name,
        COUNT(a.appointment_id) AS visit_count
    FROM patients p
    LEFT JOIN appointments a
        ON p.patient_id = a.patient_id
    GROUP BY p.patient_id
)
SELECT
    *,
    CASE
        WHEN visit_count = 1 THEN 'New Patient'
        WHEN visit_count BETWEEN 2 AND 4 THEN 'Regular Patient'
        ELSE 'High Frequency Patient'
    END AS patient_category
FROM patient_visits;

WITH doctor_revenue AS (
    SELECT
        d.doctor_id,
        d.first_name,
        d.last_name,
        SUM(b.amount) AS total_revenue
    FROM doctors d
    JOIN appointments a ON d.doctor_id = a.doctor_id
    JOIN treatments t ON a.appointment_id = t.appointment_id
    JOIN billing b ON t.treatment_id = b.treatment_id
    GROUP BY d.doctor_id
)
SELECT
    *,
    RANK() OVER (ORDER BY total_revenue DESC) AS revenue_rank
FROM doctor_revenue;

SELECT
    treatment_type,
    cost,
    AVG(cost) OVER (PARTITION BY treatment_type) AS avg_treatment_cost,
    cost - AVG(cost) OVER (PARTITION BY treatment_type) AS cost_difference
FROM treatments;

WITH appointment_stats AS (
    SELECT
        status,
        COUNT(*) AS count_status
    FROM appointments
    GROUP BY status
)
SELECT
    *,
    ROUND(
        count_status * 100.0 / SUM(count_status) OVER (),
        2
    ) AS percentage
FROM appointment_stats;

CREATE VIEW vw_doctor_utilization AS
SELECT 
    d.doctor_id,
    CONCAT(d.first_name, ' ', d.last_name) AS doctor_name,
    d.specialization,
    COUNT(a.appointment_id) AS total_appointments
FROM doctors d
LEFT JOIN appointments a 
ON d.doctor_id = a.doctor_id
GROUP BY d.doctor_id;

CREATE VIEW vw_monthly_revenue AS
SELECT 
    DATE_FORMAT(bill_date, '%Y-%m') AS month,
    SUM(amount) AS total_revenue
FROM billing
GROUP BY month;

CREATE VIEW vw_patient_visits AS
SELECT 
    p.patient_id,
    CONCAT(p.first_name, ' ', p.last_name) AS patient_name,
    COUNT(a.appointment_id) AS visit_count
FROM patients p
LEFT JOIN appointments a
ON p.patient_id = a.patient_id
GROUP BY p.patient_id;

CREATE VIEW vw_treatment_frequency AS
SELECT 
    treatment_type,
    COUNT(*) AS frequency
FROM treatments
GROUP BY treatment_type;

SELECT 
    CONCAT(d.first_name, ' ', d.last_name) AS doctor_name,
    d.specialization,
    COUNT(a.appointment_id) AS total_appointments
FROM doctors d
LEFT JOIN appointments a 
ON d.doctor_id = a.doctor_id
GROUP BY doctor_name, d.specialization;

SELECT 
    DATE_FORMAT(bill_date, '%Y-%m') AS month,
    SUM(amount) AS total_revenue
FROM billing
GROUP BY month;

SELECT 
    treatment_type,
    COUNT(*) AS frequency
FROM treatments
GROUP BY treatment_type;




