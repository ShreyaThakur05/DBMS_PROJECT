USE ms_booking;

-- 1) Simple: all movies with primary genres
SELECT m.title, GROUP_CONCAT(g.name ORDER BY g.name) AS genres
FROM movie m
LEFT JOIN movie_genre mg ON mg.movie_id=m.movie_id
LEFT JOIN genre g ON g.genre_id=mg.genre_id
GROUP BY m.movie_id, m.title;

-- 2) Shows today by theatre & screen
SELECT th.name AS theatre, sc.name AS screen, m.title, s.start_time
FROM showtime s
JOIN screen sc ON sc.screen_id=s.screen_id
JOIN theatre th ON th.theatre_id=sc.theatre_id
JOIN movie m ON m.movie_id=s.movie_id
WHERE DATE(s.start_time)=CURDATE()
ORDER BY th.name, sc.name, s.start_time;

-- 3) Seats available vs booked per show
SELECT s.show_id, m.title, COUNT(*) AS total,
SUM(ss.status='BOOKED') AS booked,
SUM(ss.status='AVAILABLE') AS available
FROM showtime s
JOIN movie m ON m.movie_id=s.movie_id
JOIN show_seat ss ON ss.show_id=s.show_id
GROUP BY s.show_id, m.title;

-- 4) Average ticket price per seat_type for a show
SELECT s.show_id, st.seat_type, ROUND(AVG(ss.price),2) AS avg_price
FROM showtime s
JOIN seat st ON st.screen_id=s.screen_id
JOIN show_seat ss ON ss.show_id=s.show_id AND ss.seat_id=st.seat_id
GROUP BY s.show_id, st.seat_type;

-- 5) Top movies by gross using view + window
SELECT title, gross,
       DENSE_RANK() OVER (ORDER BY gross DESC) AS rnk
FROM v_movie_performance
ORDER BY gross DESC;

-- 6) Users with > 1 booking
SELECT u.user_id, u.full_name, COUNT(b.booking_id) AS bookings
FROM user_account u
JOIN booking b ON b.user_id=u.user_id
GROUP BY u.user_id, u.full_name
HAVING COUNT(b.booking_id) > 1;

-- 7) Per-theatre KPI (view)
SELECT * FROM v_theatre_kpi ORDER BY seats_booked DESC;

-- 8) Next 24h shows in a city with available seats
SELECT th.name AS theatre, sc.name AS screen, m.title, s.start_time,
       SUM(ss.status='AVAILABLE') AS seats_left
FROM showtime s
JOIN screen sc ON sc.screen_id=s.screen_id
JOIN theatre th ON th.theatre_id=sc.theatre_id
JOIN movie m ON m.movie_id=s.movie_id
JOIN show_seat ss ON ss.show_id=s.show_id
WHERE th.city_id = (SELECT city_id FROM city WHERE name='Nagpur' LIMIT 1)
  AND s.start_time BETWEEN NOW() AND DATE_ADD(NOW(), INTERVAL 24 HOUR)
GROUP BY th.name, sc.name, m.title, s.start_time
HAVING seats_left > 0
ORDER BY s.start_time;

-- 9) Movie rating distribution (pivot-like)
SELECT m.title,
       SUM(r.rating BETWEEN 1 AND 3) AS low,
       SUM(r.rating BETWEEN 4 AND 6) AS mid,
       SUM(r.rating BETWEEN 7 AND 10) AS high
FROM movie m
LEFT JOIN review r ON r.movie_id=m.movie_id
GROUP BY m.movie_id, m.title;

-- 10) Seats not sold for a given show (anti-join)
--    Replace 1 with desired show_id
SELECT st.row_lbl, st.col_num
FROM seat st
JOIN showtime s ON s.screen_id=st.screen_id
LEFT JOIN ticket t ON t.show_id=s.show_id AND t.seat_id=st.seat_id
WHERE s.show_id=1 AND t.ticket_id IS NULL
ORDER BY st.row_lbl, st.col_num;

-- 11) Gross per movie per city (grouping sets style via rollup)
SELECT c.name AS city, m.title, SUM(t.price) AS gross
FROM ticket t
JOIN showtime s ON s.show_id=t.show_id
JOIN movie m ON m.movie_id=s.movie_id
JOIN screen sc ON sc.screen_id=s.screen_id
JOIN theatre th ON th.theatre_id=sc.theatre_id
JOIN city c ON c.city_id=th.city_id
GROUP BY c.name, m.title WITH ROLLUP;

-- 12) Rank theatres by occupancy% over last 7 days
WITH seat_stats AS (
  SELECT th.theatre_id, th.name,
         SUM(CASE WHEN ss.status='BOOKED' THEN 1 ELSE 0 END) AS booked,
         COUNT(*) AS total
  FROM showtime s
  JOIN screen sc ON sc.screen_id=s.screen_id
  JOIN theatre th ON th.theatre_id=sc.theatre_id
  JOIN show_seat ss ON ss.show_id=s.show_id
  WHERE s.start_time >= DATE_SUB(CURDATE(), INTERVAL 7 DAY)
  GROUP BY th.theatre_id, th.name
)
SELECT name,
       ROUND(100.0 * booked/NULLIF(total,0),2) AS occupancy_pct,
       RANK() OVER (ORDER BY 1.0*booked/NULLIF(total,0) DESC) AS rnk
FROM seat_stats;

-- 13) Most frequent collaborators for each movie (actors/directors)
SELECT m.title, p.full_name, mc.role
FROM movie m
JOIN movie_cast mc ON mc.movie_id=m.movie_id
JOIN person p ON p.person_id=mc.person_id
ORDER BY m.title, mc.role;

-- 14) Find shows overlapping on same screen (scheduling check)
SELECT s1.show_id AS a, s2.show_id AS b, sc.name AS screen
FROM showtime s1
JOIN showtime s2 ON s1.screen_id=s2.screen_id
JOIN screen sc ON sc.screen_id=s1.screen_id
WHERE s1.show_id < s2.show_id
  AND s1.start_time < DATE_ADD(s2.start_time, INTERVAL 3 HOUR) -- assume 3h block
  AND s2.start_time < DATE_ADD(s1.start_time, INTERVAL 3 HOUR);

-- 15) Customers who booked all shows of a movie at a theatre (relational division style)
WITH target AS (
  SELECT s.show_id
  FROM showtime s
  JOIN screen sc ON sc.screen_id=s.screen_id
  JOIN theatre th ON th.theatre_id=sc.theatre_id AND th.name='CineMax Nagpur'
  JOIN movie m ON m.movie_id=s.movie_id AND m.title='3 Idiots'
),
counts AS (
  SELECT b.user_id, COUNT(DISTINCT t.show_id) AS cnt
  FROM ticket t
  JOIN booking b ON b.booking_id=t.booking_id
  WHERE t.show_id IN (SELECT show_id FROM target)
  GROUP BY b.user_id
)
SELECT u.full_name
FROM counts c
JOIN user_account u ON u.user_id=c.user_id
WHERE c.cnt = (SELECT COUNT(*) FROM target);

-- 16) Window: best seat types by revenue per theatre
WITH rev AS (
  SELECT th.name AS theatre, st.seat_type, SUM(t.price) AS rev
  FROM ticket t
  JOIN showtime s ON s.show_id=t.show_id
  JOIN screen sc ON sc.screen_id=s.screen_id
  JOIN theatre th ON th.theatre_id=sc.theatre_id
  JOIN seat st ON st.seat_id=t.seat_id
  GROUP BY th.name, st.seat_type
)
SELECT theatre, seat_type, rev,
       DENSE_RANK() OVER (PARTITION BY theatre ORDER BY rev DESC) AS rnk
FROM rev
ORDER BY theatre, rnk;

-- 17) Users who reviewed without booking (data quality check)
SELECT r.user_id, u.full_name, r.movie_id
FROM review r
LEFT JOIN user_account u ON u.user_id=r.user_id
LEFT JOIN ticket t ON t.booking_id IN (SELECT booking_id FROM booking WHERE user_id=r.user_id)
                  AND t.show_id IN (SELECT show_id FROM showtime WHERE movie_id=r.movie_id)
WHERE t.ticket_id IS NULL;

-- 18) Revenue per day for last 14 days (time series)
SELECT DATE(p.paid_at) AS d, SUM(p.amount) AS revenue
FROM payment p
WHERE p.status='SUCCESS'
  AND p.paid_at >= DATE_SUB(CURDATE(), INTERVAL 14 DAY)
GROUP BY DATE(p.paid_at)
ORDER BY d;

-- 19) Recursive CTE: list next N shows per screen (sequence)
WITH RECURSIVE next_shows AS (
  SELECT screen_id, MIN(start_time) AS start_time
  FROM showtime
  GROUP BY screen_id
  UNION ALL
  SELECT ns.screen_id,
         (SELECT MIN(s2.start_time)
          FROM showtime s2
          WHERE s2.screen_id=ns.screen_id
            AND s2.start_time>ns.start_time)
  FROM next_shows ns
  WHERE ns.start_time IS NOT NULL
)
SELECT * FROM next_shows WHERE start_time IS NOT NULL ORDER BY screen_id, start_time LIMIT 50;

-- 20) Top 3 grossing movies per city (top-N per group)
WITH city_movie AS (
  SELECT c.name AS city, m.title, SUM(t.price) AS gross
  FROM ticket t
  JOIN showtime s ON s.show_id=t.show_id
  JOIN movie m ON m.movie_id=s.movie_id
  JOIN screen sc ON sc.screen_id=s.screen_id
  JOIN theatre th ON th.theatre_id=sc.theatre_id
  JOIN city c ON c.city_id=th.city_id
  GROUP BY c.name, m.title
)
SELECT city, title, gross
FROM (
  SELECT city, title, gross,
         ROW_NUMBER() OVER (PARTITION BY city ORDER BY gross DESC) AS rn
  FROM city_movie
) x
WHERE rn <= 3
ORDER BY city, gross DESC;
