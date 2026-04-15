const express = require('express');
const router  = express.Router();
const db      = require('../db');
const { auth } = require('../middleware/auth');

// POST /api/registrations — Register for an event
router.post('/', auth, async (req, res) => {
  const { event_id } = req.body;
  const user_id = req.user.user_id;
  if (!event_id) return res.status(400).json({ error: 'event_id required.' });

  try {
    // Check event capacity using aggregate subquery
    const [check] = await db.execute(`
      SELECT e.max_capacity, e.ticket_price, e.status,
             COUNT(r.reg_id) AS registered
      FROM events e
      LEFT JOIN registrations r ON e.event_id = r.event_id
      WHERE e.event_id = ?
      GROUP BY e.event_id
    `, [event_id]);

    if (!check.length) return res.status(404).json({ error: 'Event not found.' });
    const ev = check[0];
    if (ev.status !== 'upcoming') return res.status(400).json({ error: 'Event is not open for registration.' });
    if (ev.registered >= ev.max_capacity) return res.status(400).json({ error: 'Event is fully booked.' });

    // Get seat number
    const seat = ev.registered + 1;

    const [result] = await db.execute(
      `INSERT INTO registrations (event_id, user_id, amount_paid, seat_number, payment_status)
       VALUES (?, ?, ?, ?, ?)`,
      [event_id, user_id, ev.ticket_price, seat, ev.ticket_price > 0 ? 'pending' : 'paid']
    );
    res.status(201).json({ message: 'Registered successfully!', reg_id: result.insertId, seat_number: seat });
  } catch (err) {
    if (err.code === 'ER_DUP_ENTRY') return res.status(409).json({ error: 'Already registered for this event.' });
    res.status(500).json({ error: err.message });
  }
});

// GET /api/registrations/my — Current user's registrations (JOIN + VIEW)
router.get('/my', auth, async (req, res) => {
  try {
    const [rows] = await db.execute(
      `SELECT * FROM vw_registration_details WHERE attendee_email = ?`,
      [req.user.email]
    );
    res.json(rows);
  } catch (err) { res.status(500).json({ error: err.message }); }
});

// GET /api/registrations/all — All registrations (admin)
router.get('/all', auth, async (req, res) => {
  try {
    const [rows] = await db.execute('SELECT * FROM vw_registration_details ORDER BY registered_at DESC');
    res.json(rows);
  } catch (err) { res.status(500).json({ error: err.message }); }
});

// PUT /api/registrations/:id/pay — Mark as paid
router.put('/:id/pay', auth, async (req, res) => {
  try {
    await db.execute(
      `UPDATE registrations SET payment_status = 'paid' WHERE reg_id = ? AND user_id = ?`,
      [req.params.id, req.user.user_id]
    );
    res.json({ message: 'Payment confirmed.' });
  } catch (err) { res.status(500).json({ error: err.message }); }
});

// DELETE /api/registrations/:id — Cancel registration
router.delete('/:id', auth, async (req, res) => {
  try {
    await db.execute(
      'DELETE FROM registrations WHERE reg_id = ? AND user_id = ?',
      [req.params.id, req.user.user_id]
    );
    res.json({ message: 'Registration cancelled.' });
  } catch (err) { res.status(500).json({ error: err.message }); }
});

// POST /api/registrations/:reg_id/feedback — Submit feedback
router.post('/:reg_id/feedback', auth, async (req, res) => {
  const { rating, comments } = req.body;
  if (!rating) return res.status(400).json({ error: 'Rating required.' });

  try {
    // Get event_id from registration
    const [reg] = await db.execute(
      'SELECT event_id FROM registrations WHERE reg_id = ? AND user_id = ?',
      [req.params.reg_id, req.user.user_id]
    );
    if (!reg.length) return res.status(404).json({ error: 'Registration not found.' });

    await db.execute(
      'INSERT INTO feedback (event_id, user_id, rating, comments) VALUES (?, ?, ?, ?)',
      [reg[0].event_id, req.user.user_id, rating, comments || null]
    );
    res.status(201).json({ message: 'Feedback submitted.' });
  } catch (err) { res.status(500).json({ error: err.message }); }
});

module.exports = router;
