const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { pool } = require('../config/database');
const { authenticateToken, requireAdmin } = require('../middleware/auth');

const router = express.Router();

// Admin Login
router.post('/login', async (req, res) => {
  try {
    const { username, password, subdomain } = req.body;

    if (!username || !password || !subdomain) {
      return res.status(400).json({ 
        error: 'Benutzername, Passwort und Subdomain sind erforderlich' 
      });
    }

    // Get kunde by subdomain
    const kundeResult = await pool.query(
      'SELECT id, subdomain, name FROM kunden WHERE subdomain = $1',
      [subdomain]
    );

    if (kundeResult.rows.length === 0) {
      return res.status(404).json({ error: 'Kunde nicht gefunden' });
    }

    const kunde = kundeResult.rows[0];

    // Get admin user
    const userResult = await pool.query(
      'SELECT * FROM admin_users WHERE username = $1 AND kunde_id = $2 AND is_active = true',
      [username, kunde.id]
    );

    if (userResult.rows.length === 0) {
      return res.status(401).json({ error: 'Ungültige Anmeldedaten' });
    }

    const user = userResult.rows[0];

    // Check password
    const isValidPassword = await bcrypt.compare(password, user.password_hash);
    if (!isValidPassword) {
      return res.status(401).json({ error: 'Ungültige Anmeldedaten' });
    }

    // Update last login
    await pool.query(
      'UPDATE admin_users SET last_login = CURRENT_TIMESTAMP WHERE id = $1',
      [user.id]
    );

    // Generate JWT token
    const token = jwt.sign(
      { 
        userId: user.id, 
        kundeId: user.kunde_id,
        username: user.username,
        role: user.role 
      },
      process.env.JWT_SECRET || 'your-secret-key',
      { expiresIn: '24h' }
    );

    res.json({
      message: 'Erfolgreich angemeldet',
      token,
      user: {
        id: user.id,
        username: user.username,
        email: user.email,
        role: user.role,
        kunde: {
          id: kunde.id,
          subdomain: kunde.subdomain,
          name: kunde.name
        }
      }
    });

  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({ error: 'Fehler bei der Anmeldung' });
  }
});

// Get current user info
router.get('/me', authenticateToken, async (req, res) => {
  try {
    res.json({
      user: {
        id: req.user.id,
        username: req.user.username,
        email: req.user.email,
        role: req.user.role,
        kunde: {
          id: req.user.kunde_id,
          subdomain: req.user.subdomain,
          name: req.user.kunde_name
        }
      }
    });
  } catch (error) {
    console.error('Get user info error:', error);
    res.status(500).json({ error: 'Fehler beim Abrufen der Benutzerdaten' });
  }
});

// Change password
router.post('/change-password', authenticateToken, async (req, res) => {
  try {
    const { currentPassword, newPassword } = req.body;

    if (!currentPassword || !newPassword) {
      return res.status(400).json({ 
        error: 'Aktuelles und neues Passwort sind erforderlich' 
      });
    }

    if (newPassword.length < 8) {
      return res.status(400).json({ 
        error: 'Neues Passwort muss mindestens 8 Zeichen lang sein' 
      });
    }

    // Verify current password
    const userResult = await pool.query(
      'SELECT password_hash FROM admin_users WHERE id = $1',
      [req.user.id]
    );

    const isValidPassword = await bcrypt.compare(currentPassword, userResult.rows[0].password_hash);
    if (!isValidPassword) {
      return res.status(400).json({ error: 'Aktuelles Passwort ist falsch' });
    }

    // Hash new password
    const saltRounds = 12;
    const newPasswordHash = await bcrypt.hash(newPassword, saltRounds);

    // Update password
    await pool.query(
      'UPDATE admin_users SET password_hash = $1 WHERE id = $2',
      [newPasswordHash, req.user.id]
    );

    res.json({ message: 'Passwort erfolgreich geändert' });

  } catch (error) {
    console.error('Change password error:', error);
    res.status(500).json({ error: 'Fehler beim Ändern des Passworts' });
  }
});

// Logout (client-side token removal)
router.post('/logout', authenticateToken, (req, res) => {
  res.json({ message: 'Erfolgreich abgemeldet' });
});

// Create admin user (only for super admin)
router.post('/create-admin', authenticateToken, requireAdmin, async (req, res) => {
  try {
    const { username, password, email, kundeId } = req.body;

    if (!username || !password || !email || !kundeId) {
      return res.status(400).json({ 
        error: 'Alle Felder sind erforderlich' 
      });
    }

    // Check if username already exists
    const existingUser = await pool.query(
      'SELECT id FROM admin_users WHERE username = $1',
      [username]
    );

    if (existingUser.rows.length > 0) {
      return res.status(400).json({ error: 'Benutzername existiert bereits' });
    }

    // Hash password
    const saltRounds = 12;
    const passwordHash = await bcrypt.hash(password, saltRounds);

    // Create admin user
    const result = await pool.query(
      'INSERT INTO admin_users (username, password_hash, email, kunde_id, role) VALUES ($1, $2, $3, $4, $5) RETURNING id, username, email, role',
      [username, passwordHash, email, kundeId, 'admin']
    );

    res.status(201).json({
      message: 'Admin-Benutzer erfolgreich erstellt',
      user: result.rows[0]
    });

  } catch (error) {
    console.error('Create admin error:', error);
    res.status(500).json({ error: 'Fehler beim Erstellen des Admin-Benutzers' });
  }
});

module.exports = router;