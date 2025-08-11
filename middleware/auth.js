const jwt = require('jsonwebtoken');
const { pool } = require('../config/database');

// Middleware to verify JWT token
const authenticateToken = async (req, res, next) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1]; // Bearer TOKEN

  if (!token) {
    return res.status(401).json({ error: 'Zugriffstoken fehlt' });
  }

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET || 'your-secret-key');
    
    // Get user info from database
    const result = await pool.query(
      'SELECT au.*, k.subdomain, k.name as kunde_name FROM admin_users au JOIN kunden k ON au.kunde_id = k.id WHERE au.id = $1 AND au.is_active = true',
      [decoded.userId]
    );

    if (result.rows.length === 0) {
      return res.status(401).json({ error: 'Ungültiger Token' });
    }

    req.user = result.rows[0];
    next();
  } catch (error) {
    if (error.name === 'TokenExpiredError') {
      return res.status(401).json({ error: 'Token abgelaufen' });
    }
    return res.status(403).json({ error: 'Ungültiger Token' });
  }
};

// Middleware to check if user has admin role
const requireAdmin = (req, res, next) => {
  if (req.user.role !== 'admin') {
    return res.status(403).json({ error: 'Admin-Berechtigung erforderlich' });
  }
  next();
};

// Middleware to get kunde from subdomain
const getKundeFromSubdomain = async (req, res, next) => {
  try {
    const host = req.get('host');
    let subdomain = null;

    // Extract subdomain from host
    if (host.includes('meinetermine.de')) {
      subdomain = host.split('.')[0];
    } else if (host.includes('localhost')) {
      // For development, use query parameter or header
      subdomain = req.query.subdomain || req.headers['x-subdomain'];
    }

    if (!subdomain) {
      return res.status(400).json({ error: 'Subdomain nicht gefunden' });
    }

    const result = await pool.query(
      'SELECT * FROM kunden WHERE subdomain = $1',
      [subdomain]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Kunde nicht gefunden' });
    }

    req.kunde = result.rows[0];
    next();
  } catch (error) {
    console.error('Fehler beim Abrufen der Kundendaten:', error);
    res.status(500).json({ error: 'Fehler beim Abrufen der Kundendaten' });
  }
};

// Middleware to validate appointment booking data
const validateBookingData = (req, res, next) => {
  const { name, email, datum, uhrzeit } = req.body;

  if (!name || !email || !datum || !uhrzeit) {
    return res.status(400).json({ 
      error: 'Alle Pflichtfelder müssen ausgefüllt werden' 
    });
  }

  // Validate email format
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  if (!emailRegex.test(email)) {
    return res.status(400).json({ 
      error: 'Ungültige E-Mail-Adresse' 
    });
  }

  // Validate date (must be in future)
  const appointmentDate = new Date(datum);
  const now = new Date();
  if (appointmentDate <= now) {
    return res.status(400).json({ 
      error: 'Termin muss in der Zukunft liegen' 
    });
  }

  next();
};

module.exports = {
  authenticateToken,
  requireAdmin,
  getKundeFromSubdomain,
  validateBookingData
};