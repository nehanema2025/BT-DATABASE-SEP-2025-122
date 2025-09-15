
-- trip_management.sql

-- Step 1: Create Database
CREATE DATABASE IF NOT EXISTS trip_management;
USE trip_management;

-- Step 2: Create Tables

CREATE TABLE Trip (
  trip_id INT PRIMARY KEY AUTO_INCREMENT,
  destination VARCHAR(50) NOT NULL,
  start_date DATE NOT NULL,
  end_date DATE NOT NULL CHECK (end_date > start_date),
  price DECIMAL(10,2) NOT NULL CHECK (price > 0),
  status ENUM('PLANNED','ONGOING','COMPLETED') DEFAULT 'PLANNED'
);

CREATE TABLE Customer (
  customer_id INT PRIMARY KEY AUTO_INCREMENT,
  name VARCHAR(50) NOT NULL,
  email VARCHAR(100) NOT NULL UNIQUE,
  phone VARCHAR(15) UNIQUE
);

CREATE TABLE Booking (
  booking_id INT PRIMARY KEY AUTO_INCREMENT,
  trip_id INT,
  customer_id INT,
  booking_date DATE NOT NULL,
  seats INT CHECK (seats > 0),
  FOREIGN KEY (trip_id) REFERENCES Trip(trip_id),
  FOREIGN KEY (customer_id) REFERENCES Customer(customer_id)
);

-- Step 3: Insert Dummy Data

INSERT INTO Trip (destination, start_date, end_date, price, status) VALUES
('Paris', '2025-10-01', '2025-10-10', 1500.00, 'PLANNED'),
('London', '2025-09-15', '2025-09-20', 1200.00, 'ONGOING'),
('New York', '2025-11-05', '2025-11-12', 2000.00, 'PLANNED'),
('Tokyo', '2025-12-01', '2025-12-08', 1800.00, 'PLANNED'),
('Sydney', '2025-10-20', '2025-10-30', 2500.00, 'ONGOING'),
('Dubai', '2025-09-25', '2025-09-30', 1100.00, 'PLANNED'),
('Rome', '2025-11-10', '2025-11-18', 1400.00, 'PLANNED'),
('Singapore', '2025-12-15', '2025-12-22', 1600.00, 'PLANNED'),
('Bangkok', '2025-09-28', '2025-10-04', 900.00, 'PLANNED'),
('Berlin', '2025-10-12', '2025-10-18', 1300.00, 'PLANNED');

INSERT INTO Customer (name, email, phone) VALUES
('Anmol', 'anmol@example.com', '9999999999'),
('Kumkum Paglu', 'kumkum@example.com', '8888888888'),
('Rahul', 'rahul@example.com', '7777777777'),
('Priya', 'priya@example.com', '6666666666'),
('Amit', 'amit@example.com', '5555555555'),
('Sneha', 'sneha@example.com', '4444444444'),
('Vikram', 'vikram@example.com', '3333333333'),
('Meera', 'meera@example.com', '2222222222'),
('Omprakash', 'omprakash@example.com', '1111111111'),
('Riya', 'riya@example.com', '1010101010');

INSERT INTO Booking (trip_id, customer_id, booking_date, seats) VALUES
(1, 1, '2025-09-05', 2),
(2, 2, '2025-09-06', 3),
(3, 3, '2025-09-07', 1),
(4, 4, '2025-09-08', 2),
(5, 5, '2025-09-09', 4),
(6, 6, '2025-09-10', 1),
(7, 7, '2025-09-11', 2),
(8, 8, '2025-09-12', 3),
(9, 9, '2025-09-13', 1),
(10, 10, '2025-09-14', 2);

-- Step 4: Queries

-- 1. Trips with price > 1000
SELECT * FROM Trip WHERE price > 1000;

-- 2. Customers who booked trips to Paris
SELECT DISTINCT C.*
FROM Customer C
JOIN Booking B ON C.customer_id = B.customer_id
JOIN Trip T ON B.trip_id = T.trip_id
WHERE T.destination = 'Paris';

-- 3. Bookings between 2 dates
SELECT * FROM Booking
WHERE booking_date BETWEEN '2025-09-01' AND '2025-09-30';

-- 4. Total bookings per trip
SELECT trip_id, COUNT(*) AS total_bookings
FROM Booking
GROUP BY trip_id;

-- 5. Trip with highest bookings
SELECT trip_id, COUNT(*) AS total_bookings
FROM Booking
GROUP BY trip_id
ORDER BY total_bookings DESC
LIMIT 1;

-- Step 5: Stored Procedures

DELIMITER //
CREATE PROCEDURE AddTrip(
  IN p_destination VARCHAR(50),
  IN p_start DATE,
  IN p_end DATE,
  IN p_price DECIMAL(10,2),
  IN p_status ENUM('PLANNED','ONGOING','COMPLETED')
)
BEGIN
  INSERT INTO Trip(destination, start_date, end_date, price, status)
  VALUES(p_destination, p_start, p_end, p_price, p_status);
END //
DELIMITER ;

DELIMITER //
CREATE PROCEDURE GetTripsByStatus(IN p_status ENUM('PLANNED','ONGOING','COMPLETED'))
BEGIN
  SELECT * FROM Trip WHERE status = p_status;
END //
DELIMITER ;

DELIMITER //
CREATE PROCEDURE BookTrip(IN p_customer INT, IN p_trip INT, IN p_seats INT)
BEGIN
  INSERT INTO Booking(trip_id, customer_id, booking_date, seats)
  VALUES(p_trip, p_customer, CURDATE(), p_seats);
END //
DELIMITER ;

DELIMITER //
CREATE PROCEDURE CancelBooking(IN p_booking_id INT)
BEGIN
  DELETE FROM Booking WHERE booking_id = p_booking_id;
END //
DELIMITER ;

-- Step 6: Functions

DELIMITER //
CREATE FUNCTION TripDuration(t_id INT)
RETURNS INT
DETERMINISTIC
BEGIN
  DECLARE days INT;
  SELECT DATEDIFF(end_date, start_date) INTO days
  FROM Trip WHERE trip_id = t_id;
  RETURN days;
END //
DELIMITER ;

DELIMITER //
CREATE FUNCTION TripRevenue(t_id INT)
RETURNS DECIMAL(10,2)
DETERMINISTIC
BEGIN
  DECLARE revenue DECIMAL(10,2);
  SELECT SUM(seats * price) INTO revenue
  FROM Booking B JOIN Trip T ON B.trip_id = T.trip_id
  WHERE T.trip_id = t_id;
  RETURN revenue;
END //
DELIMITER ;

-- Step 7: Triggers

DELIMITER //
CREATE TRIGGER PreventCompletedBooking
BEFORE INSERT ON Booking
FOR EACH ROW
BEGIN
  DECLARE trip_status ENUM('PLANNED','ONGOING','COMPLETED');
  SELECT status INTO trip_status FROM Trip WHERE trip_id = NEW.trip_id;
  IF trip_status = 'COMPLETED' THEN
    SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'Cannot book a completed trip';
  END IF;
END //
DELIMITER ;

CREATE TABLE IF NOT EXISTS BookingLog (
  log_id INT PRIMARY KEY AUTO_INCREMENT,
  booking_id INT,
  log_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

DELIMITER //
CREATE TRIGGER AfterBookingInsert
AFTER INSERT ON Booking
FOR EACH ROW
BEGIN
  INSERT INTO BookingLog (booking_id) VALUES (NEW.booking_id);
END //
DELIMITER ;
