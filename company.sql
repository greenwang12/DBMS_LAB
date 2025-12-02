drop database if exists company;
create database company;
use company;

create table if not exists Employee(
        ssn varchar(35) primary key,
        name varchar(35) not null,
        address varchar(255) not null,
        sex varchar(7) not null,
        salary int not null,
        super_ssn varchar(35),
        d_no int,
        foreign key (super_ssn) references Employee(ssn) on delete set null
);

create table if not exists Department(
        d_no int primary key,
        dname varchar(100) not null,
        mgr_ssn varchar(35),
        mgr_start_date date,
        foreign key (mgr_ssn) references Employee(ssn) on delete cascade
);

create table if not exists DLocation(
        d_no int not null,
        d_loc varchar(100) not null,
        foreign key (d_no) references Department(d_no) on delete cascade
);

create table if not exists Project(
        p_no int primary key,
        p_name varchar(25) not null,
        p_loc varchar(25) not null,
        d_no int not null,
        foreign key (d_no) references Department(d_no) on delete cascade
);

create table if not exists WorksOn(
        ssn varchar(35) not null,
        p_no int not null,
        hours int not null default 0,
        foreign key (ssn) references Employee(ssn) on delete cascade,
        foreign key (p_no) references Project(p_no) on delete cascade
);

INSERT INTO Employee VALUES
("01MS101", "Reen lee", "Altamount Road, Mumbai", "Female", 3700000, "01MS101", 5),
("01MS102", "Employee_2", "Delhi-NCR", "Female", 1700000, "01MS101", 2),
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
(278910, "System Testing", "Mumbai, Maharashtra", 004),
(534892, "IOT", "JP Nagar, Bengaluru", 001),
(453976, "Product Optimization", "Hyderabad, Telangana", 005),
(278346, "Yield Increase", "Gurugram, Delhi-NCR", 005),
(426791, "Product Refinement", "Whitefield, Bengaluru", 002);

INSERT INTO WorksOn VALUES
("01MS101", 278346, 5),
("01MS102", 426791, 6),
("02MS205", 534892, 3),
("02MS312", 278910, 3),
("03MS401", 453976, 6);

-- Alter table to add Foreign Key constraint
ALTER TABLE Employee 
ADD CONSTRAINT foreign_key_dno FOREIGN KEY (d_no) 
REFERENCES Department(d_no) 
ON DELETE CASCADE;

-- Select Queries to verify the updated data
SELECT * FROM Department;
SELECT * FROM Employee;
SELECT * FROM DLocation;
SELECT * FROM Project;
SELECT * FROM WorksOn;

-- Make a list of all project numbers for projects that involve an employee whose last name is ‘Scott’, either as a worker or as a manager of the department that controls the project.

select p_no,p_name,name from Project p, Employee e where p.d_no=e.d_no and e.name like "%Krishna";


-- Show the resulting salaries if every employee working on the ‘IoT’ project is given a 10 percent raise
select w.ssn,name,salary as old_salary,salary*1.1 as new_salary from WorksOn w join Employee e where w.ssn=e.ssn and w.p_no=(select p_no from Project where p_name="IOT") ;


-- Find the sum of the salaries of all employees of the ‘Accounts’ department, as well as the maximum salary, the minimum salary, and the average salary in this department
select sum(salary) as sal_sum, max(salary) as sal_max,min(salary) as sal_min,avg(salary) as sal_avg from Employee e join Department d on e.d_no=d.d_no where d.dname="Accounts";


-- Retrieve the name of each employee who works on all the projects controlled by department number 1 (use NOT EXISTS operator).
select Employee.ssn,name,d_no from Employee where not exists
    (select p_no from Project p where p.d_no=1 and p_no not in
        (select p_no from WorksOn w where w.ssn=Employee.ssn));


-- For each department that has more than one employees, retrieve the department number and the number of its employees who are making more than Rs. 6,00,000.
select d.d_no, count(*) from Department d join Employee e on e.d_no=d.d_no where salary>600000 group by d.d_no having count(*) >1;


-- Create a view that shows name, dept name and location of all employees
create view emp_details as
select name,dname,d_loc from Employee e join Department d on e.d_no=d.d_no join DLocation dl on d.d_no=dl.d_no;

select * from emp_details;

-- Create a view that shows project name, location and dept.
create view ProjectDetails as
select p_name, p_loc, dname
from Project p NATURAL JOIN Department d;

select * from ProjectDetails;

-- A trigger that automatically updates manager’s start date when he is assigned .

DELIMITER //
create trigger UpdateManagerStartDate
before insert on Department
for each row
BEGIN
        SET NEW.mgr_start_date=curdate();
END;//

DELIMITER ;

insert into Department (d_no, dname, mgr_ssn) values
(006,"R&D","01NB354"); -- This will automatically set mgr_start_date to today's date

-- Create a trigger that prevents a project from being deleted if it is currently being worked by any employee.

DELIMITER //
create trigger PreventDelete
before delete on Project
for each row
BEGIN
        IF EXISTS (select * from WorksOn where p_no=old.p_no) THEN
                signal sqlstate '45000' set message_text='This project has an employee assigned';
        END IF;
END; //

DELIMITER ;

delete from Project where p_no=241563; -- Will give error
