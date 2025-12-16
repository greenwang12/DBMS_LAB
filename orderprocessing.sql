DROP DATABASE IF EXISTS order_processing;
CREATE DATABASE order_processing;
USE order_processing;

CREATE TABLE Customers (
  cust_id INT PRIMARY KEY,
  cname VARCHAR(35) NOT NULL,
  city VARCHAR(35) NOT NULL
);

CREATE TABLE Orders (
  order_id INT PRIMARY KEY,
  odate DATE NOT NULL,
  cust_id INT,
  order_amt INT DEFAULT 0,
  FOREIGN KEY (cust_id) REFERENCES Customers(cust_id) ON DELETE CASCADE
);

CREATE TABLE Items (
  item_id INT PRIMARY KEY,
  unitprice INT NOT NULL
);

CREATE TABLE OrderItems (
  order_id INT,
  item_id INT,
  qty INT NOT NULL,
  FOREIGN KEY (order_id) REFERENCES Orders(order_id) ON DELETE CASCADE,
  FOREIGN KEY (item_id) REFERENCES Items(item_id) ON DELETE CASCADE
);

CREATE TABLE Warehouses (
  warehouse_id INT PRIMARY KEY,
  city VARCHAR(35) NOT NULL
);

CREATE TABLE Shipments (
  order_id INT,
  warehouse_id INT,
  ship_date DATE NOT NULL,
  FOREIGN KEY (order_id) REFERENCES Orders(order_id) ON DELETE CASCADE,
  FOREIGN KEY (warehouse_id) REFERENCES Warehouses(warehouse_id) ON DELETE CASCADE
);

INSERT INTO Customers VALUES
(1,"Customer_1","Bengaluru"),
(2,"Customer_2","Hyderabad"),
(3,"Kumar","Mumbai"),
(4,"Customer_4","Delhi"),
(5,"Customer_5","Chennai");

INSERT INTO Orders VALUES
(1, "2025-01-14", 1, 2000),
(2, "2025-04-13", 2, 500),
(3, "2025-10-02", 3, 2500),
(4, "2025-05-12", 5, 1000),
(5, "2025-12-23", 4, 1200);

INSERT INTO Items VALUES
(1,400),(2,200),(3,1000),(4,100),(5,500);

INSERT INTO Warehouses VALUES
(1,"Bengaluru"),
(2,"Hyderabad"),
(3,"Mumbai"),
(4,"Delhi"),
(5,"Chennai");

INSERT INTO OrderItems VALUES
(1,1,5),
(2,5,1),
(3,5,5),
(4,3,1),
(5,4,12);

NSERT INTO Shipments VALUES
(1,2,"2025-01-18"),
(2,1,"2025-04-16"),
(3,4,"2025-06-10"),
(4,3,"2025-05-18"),
(5,5,"2025-12-26");

SELECT order_id, ship_date FROM Shipments WHERE warehouse_id=1;

SELECT order_id, warehouse_id
FROM Shipments
WHERE order_id IN (
  SELECT order_id FROM Orders
  WHERE cust_id = (SELECT cust_id FROM Customers WHERE cname="Kumar")
);

SELECT c.cname, COUNT(o.order_id) AS no_of_orders, AVG(o.order_amt) AS avg_order_amt
FROM Customers c JOIN Orders o ON c.cust_id=o.cust_id
GROUP BY c.cname;

DELETE FROM Orders
WHERE cust_id = (
  SELECT cust_id FROM Customers WHERE cname = "Kumar"
);
SELECT * FROM Orders;

SELECT * FROM Items
WHERE unitprice = (SELECT MAX(unitprice) FROM Items);

CREATE VIEW WarehouseWithKumarOrders AS
SELECT DISTINCT s.warehouse_id
FROM Shipments s
JOIN Orders o ON s.order_id=o.order_id
JOIN Customers c ON o.cust_id=c.cust_id
WHERE c.cname="Kumar";

DELIMITER //

CREATE TRIGGER UpdateOrderAmt
AFTER INSERT ON OrderItems
FOR EACH ROW
BEGIN
  UPDATE Orders
  SET order_amt = order_amt +
      (NEW.qty * (SELECT unitprice FROM Items WHERE item_id = NEW.item_id))
  WHERE order_id = NEW.order_id;
END//
INSERT INTO Orders VALUES (8, "2025-07-01", 4, 0);
INSERT INTO OrderItems VALUES (8, 1, 2);

SELECT * FROM Orders WHERE order_id = 8;

DELIMITER //

CREATE TRIGGER PreventWarehouseDelete
BEFORE DELETE ON Warehouses
FOR EACH ROW
BEGIN
  IF EXISTS (
    SELECT 1 FROM Shipments
    WHERE warehouse_id = OLD.warehouse_id
  ) THEN
    SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'Warehouse has pending shipments';
  END IF;
END//

SELECT * FROM ShipmentDatesFromWarehouse5;

DELIMITER ;

DELETE FROM Warehouses WHERE warehouse_id = 2;

CREATE OR REPLACE VIEW ShipmentDatesFromWarehouse5 AS
SELECT order_id, ship_date
FROM Shipments
WHERE warehouse_id = 5;

SELECT * FROM ShipmentDatesFromWarehouse5;
