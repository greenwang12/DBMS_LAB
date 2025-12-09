DROP DATABASE IF EXISTS company;
CREATE DATABASE company;
USE company;

CREATE TABLE IF NOT EXISTS Employee(
        ssn VARCHAR(35) PRIMARY KEY,
        name VARCHAR(35) NOT NULL,
        address VARCHAR(255) NOT NULL,
        sex VARCHAR(7) NOT NULL,
        salary INT NOT NULL,
        super_ssn VARCHAR(35),
        d_no INT,
        FOREIGN KEY (super_ssn) REFERENCES Employee(ssn) ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS Department(
        d_no INT PRIMARY KEY,
        dname VARCHAR(100) NOT NULL,
        mgr_ssn VARCHAR(35),
        mgr_start_date DATE,
        FOREIGN KEY (mgr_ssn) REFERENCES Employee(ssn) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS DLocation(
        d_no INT NOT NULL,
        d_loc VARCHAR(100) NOT NULL,
        FOREIGN KEY (d_no) REFERENCES Department(d_no) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS Project(
        p_no INT PRIMARY KEY,
        p_name VARCHAR(100) NOT NULL,
        p_loc VARCHAR(25) NOT NULL,
        d_no INT NOT NULL,
        FOREIGN KEY (d_no) REFERENCES Department(d_no) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS WorksOn(
        ssn VARCHAR(35) NOT NULL,
        p_no INT NOT NULL,
        hours INT NOT NULL DEFAULT 0,
        FOREIGN KEY (ssn) REFERENCES Employee(ssn) ON DELETE CASCADE,
        FOREIGN KEY (p_no) REFERENCES Project(p_no) ON DELETE CASCADE
);

INSERT INTO Employee VALUES
("01MS101", "Reen lee", "Altamount Road, Mumbai", "Female", 3700000, "01MS101", 5),
("01MS102", "Shelly Scott", "Delhi-NCR", "Female", 1700000, "01MS101", 2),
("02MS205", "Employee_3", "Pune, Maharashtra", "Male", 2000000, "01MS101", 4),
("02MS312", "Employee_4", "Hyderabad, Telangana", "Male", 2500000, "01MS102", 5),
("03MS401", "Employee_5", "JP Nagar, Bengaluru", "Female", 1900000, "01MS102", 1);

INSERT INTO Department VALUES
(001, "People & Culture", "01MS101", "2025-11-15"),
(002, "Product Quality", "01MS102", "2025-12-01"),
(003, "Cloud Infrastructure", "02MS205", "2025-10-30"),
(005, "Engineering & Development", "02MS312", "2025-09-22"),
(004, "Corporate Finance", "03MS401", "2025-10-12");

INSERT INTO DLocation VALUES
(001, "Manyata Tech Park, Bengaluru"),
(002, "DLF Cyber Hub, Gurugram"),
(003, "Olympia Tech Park, Chennai"),
(004, "One BKC, Mumbai"),
(005, "MSIDC, Hyderabad");

INSERT INTO Project VALUES
(278910, "System Performance Evaluation", "Mumbai, Maharashtra", 004),
(534892, "Next-Gen IoT Platform", "JP Nagar, Bengaluru", 001),
(453976, "Product Quality Enhancement", "Hyderabad, Telangana", 005),
(278346, "Operational Efficiency Optimization", "Gurugram, Delhi-NCR", 005),
(426791, "Global Market Expansion Strategy", "Whitefield, Bengaluru", 002);

INSERT INTO WorksOn VALUES
("01MS101", 278346, 5),
("01MS102", 426791, 6),
("02MS205", 534892, 3),
("02MS312", 278910, 3),
("03MS401", 453976, 6);

-- ADD FK FOR D_NO

ALTER TABLE Employee
ADD CONSTRAINT foreign_key_dno FOREIGN KEY (d_no)
REFERENCES Department(d_no)
ON DELETE CASCADE;

SELECT * FROM Department;
SELECT * FROM Employee;
SELECT * FROM DLocation;
SELECT * FROM Project;
SELECT * FROM WorksOn;

-- Find project numbers involving employees whose last name is 'Scott'
SELECT p.p_no, p.p_name, e.name
FROM Project p
JOIN Department d ON p.d_no = d.d_no
JOIN Employee e ON d.d_no = e.d_no
WHERE e.name LIKE '%Scott';

-- 10% raise for employees working on IoT project
SELECT w.ssn, e.name, e.salary AS old_salary, e.salary * 1.1 AS new_salary
FROM WorksOn w
JOIN Employee e ON w.ssn = e.ssn
WHERE w.p_no = (
    SELECT p_no FROM Project
    WHERE p_name LIKE '%Next-Gen IoT Platform%'
);

-- Salary stats for 'Corporate Finance' department
SELECT
    SUM(salary) AS sal_sum,
    MAX(salary) AS sal_max,
    MIN(salary) AS sal_min,
    AVG(salary) AS sal_avg
FROM Employee e
JOIN Department d ON e.d_no = d.d_no
WHERE d.dname = 'Corporate Finance';

-- Employees working on ALL projects controlled by department 1
SELECT e.ssn, e.name, e.d_no
FROM Employee e
WHERE NOT EXISTS (
    SELECT p_no FROM Project p
    WHERE p.d_no = 1
    AND p_no NOT IN (
        SELECT w.p_no FROM WorksOn w WHERE w.ssn = e.ssn
    )
);

-- Departments with >1 employees earning >600000
SELECT d.d_no, COUNT(*)
FROM Department d
JOIN Employee e ON e.d_no = d.d_no
WHERE e.salary > 600000
GROUP BY d.d_no
HAVING COUNT(*) > 1;

-- View: employee details (name, dept name, location)
CREATE VIEW emp_details AS
SELECT e.name, d.dname, dl.d_loc
FROM Employee e
JOIN Department d ON e.d_no = d.d_no
JOIN DLocation dl ON d.d_no = dl.d_no;

SELECT * FROM emp_details;

-- View: project details
CREATE VIEW ProjectDetails AS
SELECT p.p_name, p.p_loc, d.dname
FROM Project p
NATURAL JOIN Department d;

SELECT * FROM ProjectDetails;

-- Trigger 1:Auto-update manager start date
DELIMITER //
CREATE TRIGGER UpdateManagerStartDate
BEFORE INSERT ON Department
FOR EACH ROW
BEGIN
        SET NEW.mgr_start_date = CURDATE();
END;//
DELIMITER ;

-- Insert using existing employee to avoid FK error
INSERT INTO Department (d_no, dname, mgr_ssn)
VALUES (006, "R&D", "01MS101");

-- Trigger 2: Prevent project deletion when employees are assigned
DELIMITER //
CREATE TRIGGER PreventDelete
BEFORE DELETE ON Project
FOR EACH ROW
BEGIN
        IF EXISTS (SELECT * FROM WorksOn WHERE p_no = OLD.p_no) THEN
                SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'This project has an employee assigned';
        END IF;
END;//
DELIMITER ;

-- Test: THIS WILL ERROR (because employees exist on project 278346)
delete from Project where p_no = 278346;


