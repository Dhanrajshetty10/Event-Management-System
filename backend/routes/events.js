const express = require('express');
const router  = express.Router();
const db      = require('../db');
const { auth, organizerOrAdmin } = require('../middleware/auth');

// GET /api/events — All events using VIEW (JOIN-based)
router.get('/', async (req, res) => {
  try {
    const { category, city, status, search } = req.query;
    let sql = 'SELECT * FROM vw_event_details WHERE 1=1';
    const params = [];

    if (category) { sql += ' AND category = ?';            params.push(category); }
    if (city)     { sql += ' AND venue_city = ?';          params.push(city); }
    if (status)   { sql += ' AND status = ?';              params.push(status); }
    if (search)   { sql += ' AND title LIKE ?';            params.push(`%${search}%`); }

    sql += ' ORDER BY event_date ASC';
    const [rows] = await db.execute(sql, params);
    res.json(rows);
  } catch (err) { res.status(500).json({ error: err.message }); }
});

// GET /api/events/upcoming — Uses vw_upcoming_events VIEW
router.get('/upcoming', async (req, res) => {
  try {
    const [rows] = await db.execute('SELECT * FROM vw_upcoming_events ORDER BY event_date ASC');
    res.json(rows);
  } catch (err) { res.status(500).json({ error: err.message }); }
});

// GET /api/events/stats — Uses vw_event_stats VIEW (aggregate functions)
router.get('/stats', auth, async (req, res) => {
  try {
    const [rows] = await db.execute('SELECT * FROM vw_event_stats ORDER BY total_revenue DESC');
    res.json(rows);
  } catch (err) { res.status(500).json({ error: err.message }); }
});

// GET /api/events/summary — Dashboard aggregate summary
router.get('/summary', async (req, res) => {
  try {
    // Uses aggregate + JOIN
    const [summary] = await db.execute(`
      SELECT
        COUNT(DISTINCT e.event_id)     AS total_events,
        COUNT(DISTINCT r.reg_id)       AS total_registrations,
        SUM(r.amount_paid)             AS total_revenue,
        COUNT(DISTINCT v.venue_id)     AS total_venues,
        ROUND(AVG(f.rating), 2)        AS overall_avg_rating,
        COUNT(DISTINCT u.user_id)      AS total_users
      FROM events e
      LEFT JOIN registrations r ON e.event_id = r.event_id AND r.payment_status = 'paid'
      LEFT JOIN feedback f       ON e.event_id = f.event_id
      LEFT JOIN venues v         ON e.venue_id = v.venue_id
      LEFT JOIN users u          ON r.user_id  = u.user_id
    `);
    res.json(summary[0]);
  } catch (err) { res.status(500).json({ error: err.message }); }
});

// GET /api/events/by-category — Aggregate by category
router.get('/by-category', async (req, res) => {
  try {
    const [rows] = await db.execute(`
      SELECT
        category,
        COUNT(*)                  AS event_count,
        SUM(max_capacity)         AS total_seats,
        ROUND(AVG(ticket_price),2) AS avg_price
      FROM events
      GROUP BY category
      ORDER BY event_count DESC
    `);
    res.json(rows);
  } catch (err) { res.status(500).json({ error: err.message }); }
});

// GET /api/events/:id — Single event with full JOIN details + speakers
router.get('/:id', async (req, res) => {
  try {
    const { id } = req.params;

    // Event details via VIEW
    const [events] = await db.execute(
      'SELECT * FROM vw_event_details WHERE event_id = ?', [id]
    );
    if (!events.length) return res.status(404).json({ error: 'Event not found.' });

    // Speakers via JOIN
    const [speakers] = await db.execute(`
      SELECT s.name, s.bio, s.expertise, s.email
      FROM speakers s
      JOIN event_speakers es ON s.speaker_id = es.speaker_id
      WHERE es.event_id = ?
    `, [id]);

    // Registration count + stats via aggregate
    const [stats] = await db.execute(
      'SELECT * FROM vw_event_stats WHERE event_id = ?', [id]
    );

    res.json({ ...events[0], speakers, stats: stats[0] || null });
  } catch (err) { res.status(500).json({ error: err.message }); }
});

// POST /api/events — Create event
router.post('/', auth, organizerOrAdmin, async (req, res) => {
  const { title, description, event_date, start_time, end_time, venue_id,
          category, max_capacity, ticket_price } = req.body;

  if (!title || !event_date || !start_time || !end_time || !venue_id || !max_capacity)
    return res.status(400).json({ error: 'Required fields missing.' });

  try {
    const [result] = await db.execute(
      `INSERT INTO events (title, description, event_date, start_time, end_time,
        venue_id, organizer_id, category, max_capacity, ticket_price)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [title, description, event_date, start_time, end_time, venue_id,
       req.user.user_id, category || 'other', max_capacity, ticket_price || 0]
    );
    res.status(201).json({ message: 'Event created.', event_id: result.insertId });
  } catch (err) { res.status(500).json({ error: err.message }); }
});

// PUT /api/events/:id — Update event
router.put('/:id', auth, organizerOrAdmin, async (req, res) => {
  const { title, description, event_date, start_time, end_time,
          venue_id, category, max_capacity, ticket_price, status } = req.body;
  try {
    await db.execute(
      `UPDATE events SET title=?, description=?, event_date=?, start_time=?, end_time=?,
        venue_id=?, category=?, max_capacity=?, ticket_price=?, status=?
       WHERE event_id=?`,
      [title, description, event_date, start_time, end_time,
       venue_id, category, max_capacity, ticket_price, status, req.params.id]
    );
    res.json({ message: 'Event updated.' });
  } catch (err) { res.status(500).json({ error: err.message }); }
});

// DELETE /api/events/:id
router.delete('/:id', auth, organizerOrAdmin, async (req, res) => {
  try {
    await db.execute('DELETE FROM events WHERE event_id = ?', [req.params.id]);
    res.json({ message: 'Event deleted.' });
  } catch (err) { res.status(500).json({ error: err.message }); }
});

// GET /api/events/:id/attendees — All attendees of an event (JOIN)
router.get('/:id/attendees', auth, async (req, res) => {
  try {
    const [rows] = await db.execute(`
      SELECT u.user_id, u.name, u.email, r.payment_status, r.amount_paid, r.seat_number, r.registered_at
      FROM registrations r
      JOIN users u ON r.user_id = u.user_id
      WHERE r.event_id = ?
      ORDER BY r.registered_at ASC
    `, [req.params.id]);
    res.json(rows);
  } catch (err) { res.status(500).json({ error: err.message }); }
});

// GET /api/events/:id/feedback — Event feedback
router.get('/:id/feedback', async (req, res) => {
  try {
    const [rows] = await db.execute(`
      SELECT f.rating, f.comments, f.submitted_at, u.name AS reviewer
      FROM feedback f
      JOIN users u ON f.user_id = u.user_id
      WHERE f.event_id = ?
      ORDER BY f.submitted_at DESC
    `, [req.params.id]);
    res.json(rows);
  } catch (err) { res.status(500).json({ error: err.message }); }
});

module.exports = router;
