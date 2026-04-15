const express = require('express');
const router  = express.Router();
const db      = require('../db');
const { auth, adminOnly } = require('../middleware/auth');

// GET /api/venues
router.get('/', async (req, res) => {
  try {
    const [rows] = await db.execute('SELECT * FROM venues ORDER BY city, name');
    res.json(rows);
  } catch (err) { res.status(500).json({ error: err.message }); }
});

// POST /api/venues
router.post('/', auth, adminOnly, async (req, res) => {
  const { name, location, capacity, city, contact } = req.body;
  try {
    const [result] = await db.execute(
      'INSERT INTO venues (name, location, capacity, city, contact) VALUES (?, ?, ?, ?, ?)',
      [name, location, capacity, city, contact || null]
    );
    res.status(201).json({ message: 'Venue added.', venue_id: result.insertId });
  } catch (err) { res.status(500).json({ error: err.message }); }
});

module.exports = router;
