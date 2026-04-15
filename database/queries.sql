-- ============================================================
--  EVENT MANAGEMENT SYSTEM — ADVANCED SQL QUERIES
--  Covers: JOINs, UNION, SET ops, Aggregates, String funcs,
--          Advanced DML, Subqueries
-- ============================================================
USE event_management;

-- ============================================================
-- SECTION 1: JOINs
-- ============================================================

-- Q1. INNER JOIN — All registrations with event and user details
SELECT
    r.reg_id,
    u.name          AS attendee,
    e.title         AS event,
    e.event_date,
    r.payment_status,
    r.amount_paid
FROM registrations r
INNER JOIN users  u ON r.user_id  = u.user_id
INNER JOIN events e ON r.event_id = e.event_id;

-- Q2. LEFT JOIN — All events with their registration count (including events with 0 registrations)
SELECT
    e.title,
    e.event_date,
    e.category,
    COUNT(r.reg_id) AS total_registered
FROM events e
LEFT JOIN registrations r ON e.event_id = r.event_id
GROUP BY e.event_id, e.title, e.event_date, e.category
ORDER BY total_registered DESC;

-- Q3. LEFT JOIN — Events and their average feedback rating (NULL if no feedback)
SELECT
    e.title,
    e.event_date,
    ROUND(AVG(f.rating), 2)  AS avg_rating,
    COUNT(f.feedback_id)     AS feedback_count
FROM events e
LEFT JOIN feedback f ON e.event_id = f.event_id
GROUP BY e.event_id, e.title, e.event_date;

-- Q4. Multiple JOINs — Event with venue, organizer, speakers
SELECT
    e.title,
    e.event_date,
    v.name          AS venue,
    v.city,
    u.name          AS organizer,
    s.name          AS speaker,
    s.expertise
FROM events e
JOIN venues        v  ON e.venue_id    = v.venue_id
JOIN users         u  ON e.organizer_id = u.user_id
LEFT JOIN event_speakers es ON e.event_id  = es.event_id
LEFT JOIN speakers s  ON es.speaker_id = s.speaker_id
ORDER BY e.event_date;

-- Q5. SELF JOIN — Find users who attended the same event
SELECT
    u1.name AS attendee1,
    u2.name AS attendee2,
    e.title AS event
FROM registrations r1
JOIN registrations r2 ON r1.event_id = r2.event_id AND r1.user_id < r2.user_id
JOIN users  u1 ON r1.user_id  = u1.user_id
JOIN users  u2 ON r2.user_id  = u2.user_id
JOIN events e  ON r1.event_id = e.event_id;

-- Q6. RIGHT JOIN — All users and their events (if any)
SELECT
    u.name,
    u.email,
    u.role,
    e.title     AS event_title,
    e.event_date
FROM events e
RIGHT JOIN users u ON e.organizer_id = u.user_id;


-- ============================================================
-- SECTION 2: UNION & SET OPERATIONS
-- ============================================================

-- Q7. UNION — Combined list of all people involved (organizers + attendees) for a given event
SELECT u.name, u.email, 'Organizer' AS role
FROM events e
JOIN users u ON e.organizer_id = u.user_id
WHERE e.event_id = 1

UNION

SELECT u.name, u.email, 'Attendee' AS role
FROM registrations r
JOIN users u ON r.user_id = u.user_id
WHERE r.event_id = 1;

-- Q8. UNION ALL — All transactions (registrations + refunds combined)
SELECT user_id, event_id, amount_paid AS amount, 'payment'  AS type, registered_at AS tx_time
FROM registrations WHERE payment_status = 'paid'

UNION ALL

SELECT user_id, event_id, amount_paid AS amount, 'refund'   AS type, registered_at AS tx_time
FROM registrations WHERE payment_status = 'refunded';

-- Q9. Simulate INTERSECT — Users who are BOTH organizers AND attendees
SELECT u.user_id, u.name, u.email
FROM users u
WHERE u.user_id IN (SELECT DISTINCT organizer_id FROM events)
  AND u.user_id IN (SELECT DISTINCT user_id FROM registrations);

-- Q10. Simulate EXCEPT / MINUS — Events with NO registrations at all
SELECT e.event_id, e.title, e.event_date
FROM events e
WHERE e.event_id NOT IN (SELECT DISTINCT event_id FROM registrations);

-- Q11. UNION — Upcoming + Past events into a single timeline
SELECT title, event_date, 'Upcoming' AS timeline
FROM events WHERE event_date >= CURDATE()

UNION

SELECT title, event_date, 'Past' AS timeline
FROM events WHERE event_date < CURDATE()

ORDER BY event_date;


-- ============================================================
-- SECTION 3: AGGREGATE FUNCTIONS
-- ============================================================

-- Q12. Basic aggregates — Event revenue summary
SELECT
    COUNT(*)            AS total_events,
    SUM(ticket_price)   AS total_ticket_value,
    AVG(ticket_price)   AS avg_ticket_price,
    MAX(ticket_price)   AS most_expensive,
    MIN(ticket_price)   AS cheapest,
    MAX(max_capacity)   AS largest_event_capacity
FROM events;

-- Q13. GROUP BY + HAVING — Categories with more than 1 event
SELECT
    category,
    COUNT(*)            AS event_count,
    ROUND(AVG(ticket_price), 2) AS avg_price,
    SUM(max_capacity)   AS total_seats
FROM events
GROUP BY category
HAVING event_count > 1
ORDER BY event_count DESC;

-- Q14. Revenue per event using JOIN + GROUP BY
SELECT
    e.title,
    e.event_date,
    COUNT(r.reg_id)      AS registrations,
    SUM(r.amount_paid)   AS total_revenue,
    AVG(r.amount_paid)   AS avg_revenue
FROM events e
LEFT JOIN registrations r ON e.event_id = r.event_id AND r.payment_status = 'paid'
GROUP BY e.event_id, e.title, e.event_date
ORDER BY total_revenue DESC;

-- Q15. Feedback analysis
SELECT
    e.title,
    COUNT(f.feedback_id)     AS reviews,
    ROUND(AVG(f.rating), 1)  AS avg_rating,
    MIN(f.rating)            AS lowest,
    MAX(f.rating)            AS highest,
    SUM(CASE WHEN f.rating >= 4 THEN 1 ELSE 0 END) AS positive_reviews
FROM events e
LEFT JOIN feedback f ON e.event_id = f.event_id
GROUP BY e.event_id, e.title;


-- ============================================================
-- SECTION 4: STRING FUNCTIONS
-- ============================================================

-- Q16. String functions on user/event data
SELECT
    UPPER(name)                         AS name_upper,
    LOWER(email)                        AS email_lower,
    LENGTH(name)                        AS name_length,
    SUBSTRING(email, 1, LOCATE('@', email)-1) AS username,
    CONCAT(name, ' <', email, '>')      AS formatted_contact,
    TRIM(name)                          AS trimmed_name
FROM users;

-- Q17. String functions on events
SELECT
    title,
    UPPER(category)                     AS category_upper,
    CONCAT(event_date, ' at ', start_time) AS event_schedule,
    REPLACE(description, 'event', 'EVENT') AS highlighted_desc,
    CHAR_LENGTH(title)                  AS title_length,
    SUBSTR(title, 1, 20)               AS short_title
FROM events;

-- Q18. LIKE pattern matching — Search events by title keyword
SELECT title, event_date, category
FROM events
WHERE title LIKE '%tech%' OR title LIKE '%music%' OR description LIKE '%workshop%';


-- ============================================================
-- SECTION 5: ADVANCED DML
-- ============================================================

-- Q19. UPDATE with JOIN — Mark events as 'completed' if their date has passed
UPDATE events e
JOIN venues v ON e.venue_id = v.venue_id
SET e.status = 'completed'
WHERE e.event_date < CURDATE() AND e.status = 'upcoming';

-- Q20. UPDATE with subquery — Auto-fill seat numbers for registrations
UPDATE registrations r
SET seat_number = (
    SELECT COUNT(*) FROM (
        SELECT reg_id FROM registrations r2
        WHERE r2.event_id = r.event_id AND r2.reg_id <= r.reg_id
    ) AS sub
)
WHERE seat_number IS NULL;

-- Q21. DELETE with subquery — Remove cancelled events' registrations
DELETE FROM registrations
WHERE event_id IN (
    SELECT event_id FROM events WHERE status = 'cancelled'
);

-- Q22. INSERT ... SELECT — Copy attendees of one event to a log table (if log exists)
-- INSERT INTO event_audit_log (user_id, event_id, action, action_time)
-- SELECT user_id, event_id, 'registered', NOW() FROM registrations WHERE event_id = 1;

-- Q23. Conditional UPDATE using CASE
UPDATE registrations
SET payment_status = CASE
    WHEN amount_paid = 0        THEN 'pending'
    WHEN amount_paid > 0        THEN 'paid'
    ELSE 'pending'
END;


-- ============================================================
-- SECTION 6: SUBQUERIES
-- ============================================================

-- Q24. Subquery — Events with above-average ticket price
SELECT title, event_date, ticket_price
FROM events
WHERE ticket_price > (SELECT AVG(ticket_price) FROM events)
ORDER BY ticket_price DESC;

-- Q25. Correlated subquery — Users who have registered for more than 2 events
SELECT name, email
FROM users u
WHERE (SELECT COUNT(*) FROM registrations r WHERE r.user_id = u.user_id) > 2;

-- Q26. EXISTS subquery — Events that have at least one registration
SELECT title, event_date, status
FROM events e
WHERE EXISTS (
    SELECT 1 FROM registrations r WHERE r.event_id = e.event_id
);

-- Q27. NOT EXISTS — Events with no feedback yet
SELECT e.title, e.event_date
FROM events e
WHERE NOT EXISTS (
    SELECT 1 FROM feedback f WHERE f.event_id = e.event_id
);

-- Q28. Query using VIEW — Top 5 events by revenue (using vw_event_stats)
SELECT event_id, title, event_date, total_registrations, total_revenue, avg_rating
FROM vw_event_stats
ORDER BY total_revenue DESC
LIMIT 5;

-- Q29. Query using VIEW — Upcoming events with low seats
SELECT *
FROM vw_upcoming_events
ORDER BY event_date ASC;
