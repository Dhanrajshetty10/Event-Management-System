const jwt = require('jsonwebtoken');

const auth = (req, res, next) => {
  const token = req.headers['authorization']?.split(' ')[1];
  if (!token) return res.status(401).json({ error: 'Access denied. No token.' });
  try {
    req.user = jwt.verify(token, process.env.JWT_SECRET);
    next();
  } catch {
    res.status(403).json({ error: 'Invalid or expired token.' });
  }
};

const adminOnly = (req, res, next) => {
  if (req.user.role !== 'admin') return res.status(403).json({ error: 'Admin access required.' });
  next();
};

const organizerOrAdmin = (req, res, next) => {
  if (!['admin', 'organizer'].includes(req.user.role))
    return res.status(403).json({ error: 'Organizer or Admin access required.' });
  next();
};

module.exports = { auth, adminOnly, organizerOrAdmin };
