
---

# 2) `movie_streaming.sql`  (Schema + minimal seed + routines)

```sql
-- =====================================================================
-- DB: Movie Streaming & Ticket Booking (MySQL 8+)
-- =====================================================================
DROP DATABASE IF EXISTS ms_booking;
CREATE DATABASE ms_booking CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_520_ci;
USE ms_booking;

-- -------------------------
-- Core reference tables
-- -------------------------
CREATE TABLE role (
  role_id     TINYINT PRIMARY KEY,
  role_name   VARCHAR(20) NOT NULL UNIQUE
);

INSERT INTO role VALUES (1,'CUSTOMER'),(2,'STAFF'),(3,'ADMIN');

CREATE TABLE city (
  city_id   BIGINT PRIMARY KEY AUTO_INCREMENT,
  name      VARCHAR(80) NOT NULL,
  state     VARCHAR(80),
  country   VARCHAR(80) DEFAULT 'India',
  UNIQUE KEY uq_city (name, COALESCE(state,''), country)
);

CREATE TABLE user_account (
  user_id      BIGINT PRIMARY KEY AUTO_INCREMENT,
  full_name    VARCHAR(120) NOT NULL,
  email        VARCHAR(160) NOT NULL UNIQUE,
  phone        VARCHAR(20),
  role_id      TINYINT NOT NULL,
  created_at   TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_user_role FOREIGN KEY (role_id) REFERENCES role(role_id)
);

-- -------------------------
-- Content metadata
-- -------------------------
CREATE TABLE genre (
  genre_id   BIGINT PRIMARY KEY AUTO_INCREMENT,
  name       VARCHAR(60) NOT NULL UNIQUE
);

CREATE TABLE movie (
  movie_id      BIGINT PRIMARY KEY AUTO_INCREMENT,
  title         VARCHAR(200) NOT NULL,
  release_date  DATE,
  duration_min  SMALLINT CHECK (duration_min > 0),
  language      VARCHAR(40),
  certificate   VARCHAR(10),          -- e.g., U/A, PG-13
  created_at    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE movie_genre (
  movie_id  BIGINT NOT NULL,
  genre_id  BIGINT NOT NULL,
  PRIMARY KEY (movie_id, genre_id),
  FOREIGN KEY (movie_id) REFERENCES movie(movie_id) ON DELETE CASCADE,
  FOREIGN KEY (genre_id) REFERENCES genre(genre_id) ON DELETE RESTRICT
);

CREATE TABLE person (
  person_id BIGINT PRIMARY KEY AUTO_INCREMENT,
  full_name VARCHAR(120) NOT NULL,
  bio       TEXT
);

CREATE TABLE movie_cast (
  movie_id  BIGINT NOT NULL,
  person_id BIGINT NOT NULL,
  role      ENUM('ACTOR','DIRECTOR','WRITER','MUSIC','OTHER') NOT NULL,
  PRIMARY KEY (movie_id, person_id, role),
  FOREIGN KEY (movie_id) REFERENCES movie(movie_id) ON DELETE CASCADE,
  FOREIGN KEY (person_id) REFERENCES person(person_id) ON DELETE RESTRICT
);

-- -------------------------
-- Exhibition / theatres
-- -------------------------
CREATE TABLE theatre (
  theatre_id BIGINT PRIMARY KEY AUTO_INCREMENT,
  name       VARCHAR(120) NOT NULL,
  city_id    BIGINT NOT NULL,
  address    VARCHAR(255),
  UNIQUE KEY uq_theatre (name, city_id),
  FOREIGN KEY (city_id) REFERENCES city(city_id)
);

CREATE TABLE screen (
  screen_id  BIGINT PRIMARY KEY AUTO_INCREMENT,
  theatre_id BIGINT NOT NULL,
  name       VARCHAR(40) NOT NULL,   -- e.g., Screen 1
  capacity   INT NOT NULL CHECK (capacity > 0),
  UNIQUE KEY uq_screen_name (theatre_id, name),
  FOREIGN KEY (theatre_id) REFERENCES theatre(theatre_id) ON DELETE CASCADE
);

CREATE TABLE seat (
  seat_id   BIGINT PRIMARY KEY AUTO_INCREMENT,
  screen_id BIGINT NOT NULL,
  row_lbl   CHAR(2) NOT NULL,         -- A, B, ...
  col_num   INT NOT NULL,
  seat_type ENUM('REGULAR','PREMIUM','RECLINER') NOT NULL DEFAULT 'REGULAR',
  UNIQUE KEY uq_seat (screen_id, row_lbl, col_num),
  FOREIGN KEY (screen_id) REFERENCES screen(screen_id) ON DELETE CASCADE
);

-- -------------------------
-- Shows & seat inventory
-- -------------------------
CREATE TABLE showtime (
  show_id     BIGINT PRIMARY KEY AUTO_INCREMENT,
  movie_id    BIGINT NOT NULL,
  screen_id   BIGINT NOT NULL,
  start_time  DATETIME NOT NULL,
  base_price  DECIMAL(10,2) NOT NULL CHECK (base_price >= 0),
  language    VARCHAR(40),
  format      ENUM('2D','3D','IMAX','4DX') DEFAULT '2D',
  UNIQUE KEY uq_show_unique (screen_id, start_time),
  FOREIGN KEY (movie_id) REFERENCES movie(movie_id) ON DELETE RESTRICT,
  FOREIGN KEY (screen_id) REFERENCES screen(screen_id) ON DELETE RESTRICT
);

CREATE TABLE show_seat (
  show_id    BIGINT NOT NULL,
  seat_id    BIGINT NOT NULL,
  price      DECIMAL(10,2) NOT NULL,
  status     ENUM('AVAILABLE','HELD','BOOKED') NOT NULL DEFAULT 'AVAILABLE',
  release_on DATETIME NULL,  -- when HELD seats auto-release
  PRIMARY KEY (show_id, seat_id),
  FOREIGN KEY (show_id) REFERENCES showtime(show_id) ON DELETE CASCADE,
  FOREIGN KEY (seat_id) REFERENCES seat(seat_id) ON DELETE CASCADE
);

-- -------------------------
-- Bookings, tickets, payments
-- -------------------------
CREATE TABLE booking (
  booking_id   BIGINT PRIMARY KEY AUTO_INCREMENT,
  user_id      BIGINT NOT NULL,
  show_id      BIGINT NOT NULL,
  status       ENUM('PENDING','CONFIRMED','CANCELLED') NOT NULL DEFAULT 'PENDING',
  created_at   TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  total_amount DECIMAL(10,2) NOT NULL DEFAULT 0,
  FOREIGN KEY (user_id) REFERENCES user_account(user_id),
  FOREIGN KEY (show_id) REFERENCES showtime(show_id)
);

CREATE TABLE ticket (
  ticket_id  BIGINT PRIMARY KEY AUTO_INCREMENT,
  booking_id BIGINT NOT NULL,
  show_id    BIGINT NOT NULL,
  seat_id    BIGINT NOT NULL,
  price      DECIMAL(10,2) NOT NULL,
  FOREIGN KEY (booking_id) REFERENCES booking(booking_id) ON DELETE CASCADE,
  FOREIGN KEY (show_id) REFERENCES showtime(show_id) ON DELETE CASCADE,
  FOREIGN KEY (seat_id) REFERENCES seat(seat_id) ON DELETE RESTRICT,
  UNIQUE KEY uq_ticket_once (show_id, seat_id)   -- enforce one ticket per seat per show
);

CREATE TABLE payment (
  payment_id   BIGINT PRIMARY KEY AUTO_INCREMENT,
  booking_id   BIGINT NOT NULL UNIQUE,
  amount       DECIMAL(10,2) NOT NULL CHECK (amount >= 0),
  method       ENUM('CARD','UPI','NETBANKING','WALLET') NOT NULL,
  status       ENUM('SUCCESS','FAILED','REFUNDED') NOT NULL,
  paid_at      DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (booking_id) REFERENCES booking(booking_id) ON DELETE CASCADE
);

CREATE TABLE review (
  review_id  BIGINT PRIMARY KEY AUTO_INCREMENT,
  user_id    BIGINT NOT NULL,
  movie_id   BIGINT NOT NULL,
  rating     TINYINT NOT NULL CHECK (rating BETWEEN 1 AND 10),
  comment    VARCHAR(600),
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uq_review_once (user_id, movie_id),
  FOREIGN KEY (user_id) REFERENCES user_account(user_id) ON DELETE CASCADE,
  FOREIGN KEY (movie_id) REFERENCES movie(movie_id) ON DELETE CASCADE
);

-- -------------------------
-- Indexing for performance
-- -------------------------
CREATE INDEX ix_show_movie ON showtime(movie_id);
CREATE INDEX ix_show_screen_start ON showtime(screen_id, start_time);
CREATE INDEX ix_showseat_status ON show_seat(show_id, status);
CREATE INDEX ix_booking_user ON booking(user_id, created_at);
CREATE INDEX ix_ticket_show ON ticket(show_id);
CREATE INDEX ix_payment_status ON payment(status);

-- -------------------------
-- Triggers
-- -------------------------

-- Keep booking.total_amount in sync with tickets
DELIMITER $$
CREATE TRIGGER trg_ticket_ai_sum
AFTER INSERT ON ticket
FOR EACH ROW
BEGIN
  UPDATE booking
  SET total_amount = total_amount + NEW.price
  WHERE booking_id = NEW.booking_id;
END$$

CREATE TRIGGER trg_ticket_ad_sum
AFTER DELETE ON ticket
FOR EACH ROW
BEGIN
  UPDATE booking
  SET total_amount = total_amount - OLD.price
  WHERE booking_id = OLD.booking_id;
END$$

-- Auto-change show_seat status when ticket issued
CREATE TRIGGER trg_ticket_ai_lockseat
AFTER INSERT ON ticket
FOR EACH ROW
BEGIN
  UPDATE show_seat
  SET status='BOOKED', release_on=NULL
  WHERE show_id = NEW.show_id AND seat_id = NEW.seat_id;
END$$

-- Auto-cancel booking if payment failed (demo)
CREATE TRIGGER trg_payment_ai_state
AFTER INSERT ON payment
FOR EACH ROW
BEGIN
  IF NEW.status = 'SUCCESS' THEN
    UPDATE booking SET status='CONFIRMED' WHERE booking_id=NEW.booking_id;
  ELSEIF NEW.status = 'FAILED' THEN
    UPDATE booking SET status='CANCELLED' WHERE booking_id=NEW.booking_id;
    -- release seats
    UPDATE show_seat ss
    JOIN ticket t ON t.booking_id = NEW.booking_id
                  AND ss.show_id = t.show_id AND ss.seat_id = t.seat_id
    SET ss.status='AVAILABLE', ss.release_on=NULL;
  END IF;
END$$
DELIMITER ;

-- -------------------------
-- Views
-- -------------------------
CREATE OR REPLACE VIEW v_movie_performance AS
SELECT
  m.movie_id,
  m.title,
  COUNT(DISTINCT s.show_id) AS shows,
  COUNT(t.ticket_id)        AS tickets_sold,
  COALESCE(SUM(t.price),0)  AS gross
FROM movie m
LEFT JOIN showtime s ON s.movie_id = m.movie_id
LEFT JOIN ticket t   ON t.show_id  = s.show_id
GROUP BY m.movie_id, m.title;

CREATE OR REPLACE VIEW v_theatre_kpi AS
SELECT
  th.theatre_id,
  th.name AS theatre_name,
  c.name  AS city_name,
  COUNT(DISTINCT sc.screen_id) AS screens,
  COUNT(DISTINCT s.show_id)    AS shows,
  SUM(CASE WHEN ss.status='BOOKED' THEN 1 ELSE 0 END) AS seats_booked,
  COUNT(ss.seat_id) AS seats_total
FROM theatre th
JOIN city c ON c.city_id = th.city_id
LEFT JOIN screen sc ON sc.theatre_id = th.theatre_id
LEFT JOIN showtime s ON s.screen_id = sc.screen_id
LEFT JOIN show_seat ss ON ss.show_id = s.show_id
GROUP BY th.theatre_id, th.name, c.name;

-- -------------------------
-- Stored function & procedure (transactional booking demo)
-- -------------------------
DELIMITER $$
CREATE FUNCTION fn_booking_amount(p_booking_id BIGINT)
RETURNS DECIMAL(10,2)
DETERMINISTIC
BEGIN
  DECLARE v DECIMAL(10,2);
  SELECT COALESCE(SUM(price),0) INTO v FROM ticket WHERE booking_id = p_booking_id;
  RETURN v;
END$$

-- Reserve & book seats atomically
CREATE PROCEDURE sp_book_tickets(
  IN p_user_id BIGINT,
  IN p_show_id BIGINT,
  IN p_seat_ids JSON,               -- e.g., '[101,102,103]'
  IN p_method ENUM('CARD','UPI','NETBANKING','WALLET')
)
BEGIN
  DECLARE v_booking_id BIGINT;
  DECLARE i INT DEFAULT 0;
  DECLARE n INT;

  START TRANSACTION;

  INSERT INTO booking(user_id, show_id, status, total_amount)
  VALUES (p_user_id, p_show_id, 'PENDING', 0);
  SET v_booking_id = LAST_INSERT_ID();

  SET n = JSON_LENGTH(p_seat_ids);
  WHILE i < n DO
    SET @sid = JSON_EXTRACT(p_seat_ids, CONCAT('$[', i, ']'));
    -- lock the row to prevent race
    SELECT status INTO @st FROM show_seat WHERE show_id=p_show_id AND seat_id=@sid FOR UPDATE;
    IF @st IS NULL OR @st = 'BOOKED' THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Seat not available';
    END IF;

    -- price to ticket
    SELECT price INTO @p FROM show_seat WHERE show_id=p_show_id AND seat_id=@sid;
    INSERT INTO ticket(booking_id, show_id, seat_id, price)
    VALUES (v_booking_id, p_show_id, @sid, @p);

    SET i = i + 1;
  END WHILE;

  -- Pay immediately (demo)
  INSERT INTO payment(booking_id, amount, method, status, paid_at)
  VALUES (v_booking_id, fn_booking_amount(v_booking_id), p_method, 'SUCCESS', NOW());

  COMMIT;
END$$
DELIMITER ;

-- -------------------------
-- Seed data (minimal but meaningful)
-- -------------------------
INSERT INTO city(name,state,country) VALUES
('Nagpur','Maharashtra','India'),
('Pune','Maharashtra','India');

INSERT INTO theatre(name, city_id, address) VALUES
('CineMax Nagpur', 1, 'Sitabuldi'),
('Regal Pune', 2, 'FC Road');

INSERT INTO screen(theatre_id,name,capacity) VALUES
(1,'Screen 1',100),(1,'Screen 2',80),(2,'Screen A',120);

-- seats (small grid for demo)
INSERT INTO seat(screen_id,row_lbl,col_num,seat_type)
SELECT s.screen_id,
       CHAR(64 + r) AS row_lbl,
       c AS col_num,
       CASE WHEN r<=1 THEN 'RECLINER' WHEN r<=2 THEN 'PREMIUM' ELSE 'REGULAR' END
FROM screen s
JOIN (SELECT 1 r UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4) r
JOIN (SELECT 1 c UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5) c;

INSERT INTO genre(name) VALUES ('Action'),('Drama'),('Comedy'),('Thriller');

INSERT INTO movie(title,release_date,duration_min,language,certificate) VALUES
('Edge of Tomorrow','2014-06-06',113,'English','U/A'),
('3 Idiots','2009-12-25',170,'Hindi','U/A');

INSERT INTO movie_genre(movie_id,genre_id) VALUES
(1,1),(1,4),(2,2),(2,3);

INSERT INTO person(full_name) VALUES ('Tom Cruise'),('Emily Blunt'),('Rajkumar Hirani');

INSERT INTO movie_cast(movie_id,person_id,role) VALUES
(1,1,'ACTOR'),(1,2,'ACTOR'),(2,3,'DIRECTOR');

-- Users
INSERT INTO user_account(full_name,email,phone,role_id) VALUES
('Shreya Deshmukh','shreya@example.com','9999999999',1),
('Cinema Manager','manager@cinemax.com','8888888888',2);

-- Shows (today/tomorrow for demo)
INSERT INTO showtime(movie_id,screen_id,start_time,base_price,language,format) VALUES
(1,1, DATE_ADD(CURDATE(), INTERVAL 18 HOUR), 250.00,'English','2D'),
(2,2, DATE_ADD(CURDATE(), INTERVAL 20 HOUR), 200.00,'Hindi','2D'),
(2,3, DATE_ADD(CURDATE(), INTERVAL 26 HOUR), 220.00,'Hindi','3D');

-- Populate show_seat from seats per show
INSERT INTO show_seat(show_id, seat_id, price, status)
SELECT s.show_id, st.seat_id,
       CASE st.seat_type WHEN 'RECLINER' THEN s.base_price*1.6
                         WHEN 'PREMIUM'  THEN s.base_price*1.3
                         ELSE s.base_price END AS price,
       'AVAILABLE'
FROM showtime s
JOIN seat st ON st.screen_id = s.screen_id;

-- Sample booking (1 seat)
CALL sp_book_tickets(1, 1, JSON_ARRAY(
  (SELECT seat_id FROM seat WHERE screen_id=1 AND row_lbl='A' AND col_num=1)
), 'UPI');

-- Sample review
INSERT INTO review(user_id,movie_id,rating,comment)
VALUES (1,1,9,'Great sci-fi action!');
