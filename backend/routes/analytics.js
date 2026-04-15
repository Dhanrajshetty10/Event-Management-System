const express = require('express');
const router  = express.Router();
const db      = require('../db');
const { auth } = require('../middleware/auth');

// GET /api/analytics/dashboard — Full dashboard data
router.get('/dashboard', async (req, res) => {
  try {
    // 1. Overall summary (aggregate)
    const [summary] = await db.execute(`
      SELECT
        (SELECT COUNT(*) FROM events)                                      AS total_events,
        (SELECT COUNT(*) FROM registrations WHERE payment_status='paid')   AS paid_registrations,
        (SELECT IFNULL(SUM(amount_paid),0) FROM registrations WHERE payment_status='paid') AS total_revenue,
        (SELECT COUNT(*) FROM users WHERE role='attendee')                 AS total_attendees,
        (SELECT ROUND(AVG(rating),2) FROM feedback)                        AS overall_rating,
        (SELECT COUNT(*) FROM events WHERE status='upcoming')              AS upcoming_events
    `);

    // 2. Revenue per category (GROUP BY + aggregate)
    const [byCategory] = await db.execute(`
      SELECT
        e.category,
        COUNT(DISTINCT e.event_id)     AS events,
        COUNT(r.reg_id)                AS registrations,
        IFNULL(SUM(r.amount_paid), 0)  AS revenue,
        ROUND(AVG(f.rating), 2)        AS avg_rating
      FROM events e
      LEFT JOIN registrations r ON e.event_id = r.event_id AND r.payment_status = 'paid'
      LEFT JOIN feedback f       ON e.event_id = f.event_id
      GROUP BY e.category
      ORDER BY revenue DESC
    `);

    // 3. Top 5 events by registrations (JOIN + aggregate)
    const [topEvents] = await db.execute(`
      SELECT e.title, e.event_date, e.category,
             COUNT(r.reg_id) AS registrations,
             IFNULL(SUM(r.amount_paid), 0) AS revenue
      FROM events e
      LEFT JOIN registrations r ON e.event_id = r.event_id
      GROUP BY e.event_id, e.title, e.event_date, e.category
      ORDER BY registrations DESC
      LIMIT 5
    `);

    // 4. Monthly event count (aggregate + string function)
    const [monthly] = await db.execute(`
      SELECT
        DATE_FORMAT(event_date, '%Y-%m') AS month,
        COUNT(*) AS event_count,
        SUM(max_capacity) AS total_seats
      FROM events
      GROUP BY month
      ORDER BY month DESC
      LIMIT 12
    `);

    // 5. UNION — combined people involved across all events
    const [allParticipants] = await db.execute(`
      SELECT u.name, u.email, 'Organizer' AS role_type, e.title AS event
      FROM events e JOIN users u ON e.organizer_id = u.user_id
      UNION
      SELECT u.name, u.email, 'Attendee' AS role_type, e.title AS event
      FROM registrations r
      JOIN users  u ON r.user_id  = u.user_id
      JOIN events e ON r.event_id = e.event_id
      ORDER BY event, role_type
      LIMIT 50
    `);

    res.json({ summary: summary[0], byCategory, topEvents, monthly, allParticipants });
  } catch (err) { res.status(500).json({ error: err.message }); }
});

// GET /api/analytics/top-attendees — Uses vw_top_attendees VIEW
router.get('/top-attendees', auth, async (req, res) => {
  try {
    const [rows] = await db.execute('SELECT * FROM vw_top_attendees LIMIT 10');
    res.json(rows);
  } catch (err) { res.status(500).json({ error: err.message }); }
});

// GET /api/analytics/events-no-registration — SET operation (NOT IN)
router.get('/events-no-registration', auth, async (req, res) => {
  try {
    const [rows] = await db.execute(`
      SELECT e.event_id, e.title, e.event_date, e.category, e.status
      FROM events e
      WHERE e.event_id NOT IN (SELECT DISTINCT event_id FROM registrations)
    `);
    res.json(rows);
  } catch (err) { res.status(500).json({ error: err.message }); }
});

// GET /api/analytics/events-no-feedback — SET operation (NOT EXISTS)
router.get('/events-no-feedback', auth, async (req, res) => {
  try {
    const [rows] = await db.execute(`
      SELECT e.title, e.event_date, e.status
      FROM events e
      WHERE NOT EXISTS (SELECT 1 FROM feedback f WHERE f.event_id = e.event_id)
        AND e.status = 'completed'
    `);
    res.json(rows);
  } catch (err) { res.status(500).json({ error: err.message }); }
});

module.exports = router;
