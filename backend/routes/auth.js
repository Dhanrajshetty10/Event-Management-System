const express = require('express');
const router  = express.Router();
const bcrypt  = require('bcryptjs');
const jwt     = require('jsonwebtoken');
const db      = require('../db');

// POST /api/auth/register
router.post('/register', async (req, res) => {
  const { name, email, phone, role, password } = req.body;
  if (!name || !email || !password) return res.status(400).json({ error: 'Name, email, password required.' });
console.log(name, email, phone, role, password);
  try {
    const hash = await bcrypt.hash(password, 10);
    const [result] = await db.execute(
      'INSERT INTO users (name, email, phone, role, password) VALUES (?, ?, ?, ?, ?)',
      [name, email, phone || null, role || 'attendee', hash]
    );
    console.log(result)
    res.status(201).json({ message: 'User registered.', user_id: result.insertId });
  } catch (err) {
    if (err.code === 'ER_DUP_ENTRY') return res.status(409).json({ error: 'Email already exists.' });
    res.status(500).json({ error: err.message });
  }
});

// POST /api/auth/login
router.post('/login', async (req, res) => {
  const { email, password } = req.body;
  if (!email || !password) return res.status(400).json({ error: 'Email and password required.' });

  try {
    const [rows] = await db.execute('SELECT * FROM users WHERE email = ?', [email]);
    console.log(rows);
    
    if (!rows.length) return res.status(401).json({ error: 'Invalid credentials.' });
    let match;
    const user = rows[0];
    if (email !== 'admin@event.com') {
      
       match = await bcrypt.compare(password, user.password);
    } else {
      
       match = password === user.password;  // temp, for testing
    }

    if (!match) return res.status(401).json({ error: 'Invalid credentials.' });

    const token = jwt.sign(
      { user_id: user.user_id, name: user.name, email: user.email, role: user.role },
      process.env.JWT_SECRET,
      { expiresIn: '24h' }
    );
    res.json({ token, user: { user_id: user.user_id, name: user.name, email: user.email, role: user.role } });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
