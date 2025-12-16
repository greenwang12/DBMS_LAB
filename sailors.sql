DROP DATABASE IF EXISTS sailors;
CREATE DATABASE sailors;
USE sailors;

CREATE TABLE Sailors (
  sid INT PRIMARY KEY,
  sname VARCHAR(35) NOT NULL,
  rating FLOAT NOT NULL,
  age INT NOT NULL
);

CREATE TABLE Boat (
  bid INT PRIMARY KEY,
  bname VARCHAR(35) NOT NULL,
  color VARCHAR(25) NOT NULL
);

CREATE TABLE Reserves (
  sid INT NOT NULL,
  bid INT NOT NULL,
  sdate DATE NOT NULL,
  FOREIGN KEY (sid) REFERENCES Sailors(sid) ON DELETE CASCADE,
  FOREIGN KEY (bid) REFERENCES Boat(bid) ON DELETE CASCADE
);

INSERT INTO Sailors VALUES
(1,'Albert Storm',6.0,38),
(2,'Brian Cole',5.5,45),
(3,'Daniel Reed',8.5,22),
(4,'Stormy Blake',2.5,66),
(5,'Evan Miles',7.2,25);

INSERT INTO Boat VALUES
(1,'Sea_Star','Yellow'),
(2,'Wave_Rider','Black'),
(103,'Ocean_Bliss','White');

INSERT INTO Reserves VALUES
(1,103,'2025-01-15'),
(1,2,'2025-02-10'),
(2,1,'2025-03-05'),
(3,2,'2025-04-12'),
(5,103,'2025-05-20'),
(1,1,'2025-06-08');

-- Find the colours of the boats reserved by Albert
SELECT DISTINCT b.color
FROM Sailors s
JOIN Reserves r ON s.sid = r.sid
JOIN Boat b ON b.bid = r.bid
WHERE s.sname = 'Albert Storm';

-- Find all the sailor sids who have rating atleast 8 or reserved boat 103
SELECT sid FROM Sailors WHERE rating >= 8
UNION
SELECT sid FROM Reserves WHERE bid = 103;

-- Find the names of the sailor who have not reserved a boat whose name contains the string "storm". Order the name in the ascending order
SELECT DISTINCT s.sname
FROM Sailors s
LEFT JOIN Reserves r ON s.sid = r.sid
WHERE LOWER(s.sname) LIKE '%storm%'
ORDER BY s.sname;

-- Find the name of the sailors who have reserved all boats
SELECT s.sname
FROM Sailors s
WHERE NOT EXISTS (
  SELECT 1 FROM Boat b
  WHERE NOT EXISTS (
    SELECT 1 FROM Reserves r
    WHERE r.sid = s.sid AND r.bid = b.bid
  )
);

-- For each boat which was reserved by atleast 2 sailors with age >= 40, find the bid and average age of such sailors
SELECT r.bid, AVG(s.age) AS avg_age
FROM Sailors s
JOIN Reserves r ON s.sid = r.sid
WHERE s.age >= 40
GROUP BY r.bid
HAVING COUNT(DISTINCT s.sid) >= 2;

-- Find the name and age of the oldest sailor
SELECT sname, age
FROM Sailors
WHERE age = (SELECT MAX(age) FROM Sailors);

-- A view that shows names and ratings of all sailors sorted by rating in descending order
CREATE OR REPLACE VIEW NamesAndRating AS
SELECT sname, rating
FROM Sailors
ORDER BY rating DESC;

-- Create a view that shows the names of the sailors who have reserved a boat on a given date.
CREATE OR REPLACE VIEW SailorsWithReservation AS
SELECT DISTINCT s.sname
FROM Sailors s
JOIN Reserves r ON s.sid = r.sid
WHERE r.sdate = '2025-03-05';

-- Create a view that shows the names and colours of all the boats that have been reserved by a sailor with a specific rating.
CREATE OR REPLACE VIEW ReservedBoatsWithRatedSailor AS
SELECT DISTINCT b.bname, b.color
FROM Sailors s
JOIN Reserves r ON s.sid = r.sid
JOIN Boat b ON b.bid = r.bid
WHERE s.rating = 5.5;

SELECT * FROM ReservedBoatsWithRatedSailor;

-- Trigger that prevents boats from being deleted if they have active reservation
DELIMITER //
CREATE TRIGGER BlockBoatDelete
BEFORE DELETE ON Boat
FOR EACH ROW
BEGIN
  IF EXISTS (SELECT 1 FROM Reserves WHERE bid = OLD.bid) THEN
    SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'Boat is reserved and cannot be deleted';
  END IF;
END//
DELIMITER ;

delete from Boat where bid=103; -- This gives error since boat 103 is reserved

-- A trigger that prevents sailors with rating less than 3 from reserving a boat.
DELIMITER //
CREATE TRIGGER BlockLowRatingReservation
BEFORE INSERT ON Reserves
FOR EACH ROW
BEGIN
  IF EXISTS (
    SELECT 1 FROM Sailors
    WHERE sid = NEW.sid AND rating < 3
  ) THEN
    SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'Sailor rating less than 3';
  END IF;
END//
DELIMITER ;

-- A trigger that deletes all expired reservations.
CREATE TABLE TempTable (
  last_deleted_date DATE PRIMARY KEY
);

DELIMITER //
CREATE TRIGGER DeleteExpiredReservations
BEFORE INSERT ON TempTable
FOR EACH ROW
BEGIN
  DELETE FROM Reserves WHERE sdate < CURDATE();
END//
DELIMITER ;

