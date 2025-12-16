DROP DATABASE IF EXISTS insurance;
CREATE DATABASE insurance;
USE insurance;

CREATE TABLE person (
  driver_id VARCHAR(255) NOT NULL,
  driver_name TEXT NOT NULL,
  address TEXT NOT NULL,
  PRIMARY KEY (driver_id)
);

CREATE TABLE car (
  reg_no VARCHAR(255) NOT NULL,
  model TEXT NOT NULL,
  c_year INTEGER,
  PRIMARY KEY (reg_no)
);

CREATE TABLE accident (
  report_no INTEGER NOT NULL,
  accident_date DATE,
  location TEXT,
  PRIMARY KEY (report_no)
);

CREATE TABLE owns (
  driver_id VARCHAR(255) NOT NULL,
  reg_no VARCHAR(255) NOT NULL,
  FOREIGN KEY (driver_id) REFERENCES person(driver_id) ON DELETE CASCADE,
  FOREIGN KEY (reg_no) REFERENCES car(reg_no) ON DELETE CASCADE
);

CREATE TABLE participated (
  driver_id VARCHAR(255) NOT NULL,
  reg_no VARCHAR(255) NOT NULL,
  report_no INTEGER NOT NULL,
  damage_amount FLOAT NOT NULL,
  FOREIGN KEY (driver_id) REFERENCES person(driver_id) ON DELETE CASCADE,
  FOREIGN KEY (reg_no) REFERENCES car(reg_no) ON DELETE CASCADE,
  FOREIGN KEY (report_no) REFERENCES accident(report_no)
);

INSERT INTO person VALUES
("K111","Kim Minsoo","Gangnam, Seoul"),
("K222","Lee Smith","Mapo, Seoul"),
("K333","Park Jiwon","Haeundae, Busan"),
("K444","Choi Yuna","Songdo, Incheon"),
("K555","Han Seojun","Suwon, Gyeonggi");

INSERT INTO car VALUES
("KR-11-SE-1111","Hyundai Avante",2020),
("KR-11-SE-2222","Mazda",2019),
("KR-26-BS-3333","Hyundai Tucson",2018),
("KR-28-IN-4444","Genesis G70",2021),
("KR-41-GG-5555","Kia Sportage",2017);

INSERT INTO accident VALUES
(70001,"2020-04-05","Gangnam, Seoul"),
(70002,"2019-12-16","Mapo, Seoul"),
(70003,"2020-05-14","Haeundae, Busan"),
(70004,"2019-08-30","Songdo, Incheon"),
(70005,"2021-01-21","Suwon, Gyeonggi"),
(70006,"2021-06-11","Gangnam, Seoul");

INSERT INTO owns VALUES
("K111","KR-11-SE-1111"),
("K222","KR-11-SE-2222"),
("K333","KR-26-BS-3333"),
("K444","KR-28-IN-4444"),
("K222","KR-41-GG-5555");

INSERT INTO participated VALUES
("K111","KR-11-SE-1111",70001,20000),
("K222","KR-11-SE-2222",70002,30000),
("K333","KR-26-BS-3333",70003,15000),
("K444","KR-28-IN-4444",70004,5000),
("K222","KR-41-GG-5555",70005,25000);

-- People who owned cars involved in accidents in 2021
SELECT COUNT(DISTINCT p.driver_id)
FROM participated p, accident a
WHERE p.report_no=a.report_no
AND a.accident_date LIKE '2021%';

-- Accidents involving cars belonging to Lee Smith
SELECT COUNT(DISTINCT a.report_no)
FROM accident a
WHERE EXISTS (
  SELECT *
  FROM person p, participated pt
  WHERE p.driver_id=pt.driver_id
  AND p.driver_name="Lee Smith"
  AND pt.report_no=a.report_no
);

-- Add new accident
INSERT INTO accident VALUES
(70007,"2024-04-05","Ilsan, Gyeonggi");

INSERT INTO participated VALUES
("K222","KR-28-IN-4444",70007,18000);

-- Delete Mazda belonging to Lee Smith
DELETE FROM car
WHERE model="Mazda"
AND reg_no IN (
  SELECT o.reg_no
  FROM person p, owns o
  WHERE p.driver_id=o.driver_id
  AND p.driver_name="Lee Smith"
);
SELECT * FROM car;

-- Update damage amount
UPDATE participated
SET damage_amount=10000
WHERE report_no=70005
AND reg_no="KR-41-GG-5555";

SELECT * FROM participated;

CREATE VIEW CarsInAccident AS
SELECT DISTINCT model, c_year
FROM car c, participated p
WHERE c.reg_no=p.reg_no;

SELECT * FROM CarsInAccident;

CREATE VIEW DriversWithCar AS
SELECT driver_name, address
FROM person p, owns o
WHERE p.driver_id=o.driver_id;

CREATE VIEW DriversWithAccidentInPlace AS
SELECT driver_name
FROM person p, accident a, participated pt
WHERE p.driver_id=pt.driver_id
AND a.report_no=pt.report_no
AND a.location="Gangnam, Seoul";


DELIMITER //
CREATE OR REPLACE TRIGGER PreventOwnership
BEFORE INSERT ON owns
FOR EACH ROW
BEGIN
  IF NEW.driver_id IN (
    SELECT driver_id
    FROM participated
    GROUP BY driver_id
    HAVING SUM(damage_amount) >= 50000
  ) THEN
    SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT='Damage Greater than ₩50,000';
  END IF;
END;//
DELIMITER ;

DELIMITER //
CREATE TRIGGER PreventParticipation
BEFORE INSERT ON participated
FOR EACH ROW
BEGIN
  IF 2 <= (
    SELECT COUNT(*)
    FROM participated
    WHERE driver_id=NEW.driver_id
  ) THEN
    SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT='Driver already in 2 accidents';
  END IF;
END;//
DELIMITER ;

INSERT INTO participated VALUES
("K222","KR-11-SE-1111",70006,12000);
