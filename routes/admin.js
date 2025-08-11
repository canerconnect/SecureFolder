const express = require('express');
const { pool } = require('../config/database');
const { authenticateToken, requireAdmin } = require('../middleware/auth');

const router = express.Router();

// All routes require authentication
router.use(authenticateToken);

// Get admin dashboard data
router.get('/dashboard', async (req, res) => {
  try {
    const kundeId = req.user.kunde_id;

    // Get today's appointments
    const today = new Date().toISOString().split('T')[0];
    const todayAppointments = await pool.query(
      `SELECT * FROM appointments 
       WHERE kunde_id = $1 AND appointment_date = $2 
       ORDER BY appointment_time`,
      [kundeId, today]
    );

    // Get upcoming appointments (next 7 days)
    const upcomingAppointments = await pool.query(
      `SELECT * FROM appointments 
       WHERE kunde_id = $1 AND appointment_date > $2 AND appointment_date <= $3 
       AND status = 'confirmed'
       ORDER BY appointment_date, appointment_time
       LIMIT 20`,
      [kundeId, today, new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString().split('T')[0]]
    );

    // Get statistics
    const stats = await pool.query(
      `SELECT 
         COUNT(*) as total_appointments,
         COUNT(CASE WHEN status = 'confirmed' THEN 1 END) as confirmed_appointments,
         COUNT(CASE WHEN status = 'cancelled' THEN 1 END) as cancelled_appointments,
         COUNT(CASE WHEN status = 'completed' THEN 1 END) as completed_appointments
       FROM appointments 
       WHERE kunde_id = $1 AND appointment_date >= $2`,
      [kundeId, new Date(Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString().split('T')[0]]
    );

    res.json({
      today: todayAppointments.rows,
      upcoming: upcomingAppointments.rows,
      statistics: stats.rows[0]
    });

  } catch (error) {
    console.error('Dashboard error:', error);
    res.status(500).json({ error: 'Fehler beim Abrufen der Dashboard-Daten' });
  }
});

// Get working hours
router.get('/working-hours', async (req, res) => {
  try {
    const kundeId = req.user.kunde_id;

    const result = await pool.query(
      'SELECT * FROM working_hours WHERE kunde_id = $1 ORDER BY day_of_week, start_time',
      [kundeId]
    );

    res.json({ workingHours: result.rows });

  } catch (error) {
    console.error('Get working hours error:', error);
    res.status(500).json({ error: 'Fehler beim Abrufen der Arbeitszeiten' });
  }
});

// Update working hours
router.put('/working-hours', requireAdmin, async (req, res) => {
  try {
    const kundeId = req.user.kunde_id;
    const { workingHours } = req.body;

    if (!Array.isArray(workingHours)) {
      return res.status(400).json({ error: 'Arbeitszeiten müssen als Array übermittelt werden' });
    }

    // Delete existing working hours
    await pool.query('DELETE FROM working_hours WHERE kunde_id = $1', [kundeId]);

    // Insert new working hours
    for (const wh of workingHours) {
      if (wh.isWorkingDay) {
        await pool.query(
          'INSERT INTO working_hours (kunde_id, day_of_week, start_time, end_time, is_working_day) VALUES ($1, $2, $3, $4, $5)',
          [kundeId, wh.dayOfWeek, wh.startTime, wh.endTime, wh.isWorkingDay]
        );
      }
    }

    res.json({ message: 'Arbeitszeiten erfolgreich aktualisiert' });

  } catch (error) {
    console.error('Update working hours error:', error);
    res.status(500).json({ error: 'Fehler beim Aktualisieren der Arbeitszeiten' });
  }
});

// Get break times
router.get('/break-times', async (req, res) => {
  try {
    const kundeId = req.user.kunde_id;

    const result = await pool.query(
      'SELECT * FROM break_times WHERE kunde_id = $1 ORDER BY day_of_week, start_time',
      [kundeId]
    );

    res.json({ breakTimes: result.rows });

  } catch (error) {
    console.error('Get break times error:', error);
    res.status(500).json({ error: 'Fehler beim Abrufen der Pausenzeiten' });
  }
});

// Update break times
router.put('/break-times', requireAdmin, async (req, res) => {
  try {
    const kundeId = req.user.kunde_id;
    const { breakTimes } = req.body;

    if (!Array.isArray(breakTimes)) {
      return res.status(400).json({ error: 'Pausenzeiten müssen als Array übermittelt werden' });
    }

    // Delete existing break times
    await pool.query('DELETE FROM break_times WHERE kunde_id = $1', [kundeId]);

    // Insert new break times
    for (const bt of breakTimes) {
      await pool.query(
        'INSERT INTO break_times (kunde_id, day_of_week, start_time, end_time) VALUES ($1, $2, $3, $4)',
        [kundeId, bt.dayOfWeek, bt.startTime, bt.endTime]
      );
    }

    res.json({ message: 'Pausenzeiten erfolgreich aktualisiert' });

  } catch (error) {
    console.error('Update break times error:', error);
    res.status(500).json({ error: 'Fehler beim Aktualisieren der Pausenzeiten' });
  }
});

// Get buffer times
router.get('/buffer-times', async (req, res) => {
  try {
    const kundeId = req.user.kunde_id;

    const result = await pool.query(
      'SELECT * FROM buffer_times WHERE kunde_id = $1',
      [kundeId]
    );

    res.json({ bufferTimes: result.rows[0] || { before_appointment: 0, after_appointment: 0 } });

  } catch (error) {
    console.error('Get buffer times error:', error);
    res.status(500).json({ error: 'Fehler beim Abrufen der Pufferzeiten' });
  }
});

// Update buffer times
router.put('/buffer-times', requireAdmin, async (req, res) => {
  try {
    const kundeId = req.user.kunde_id;
    const { beforeAppointment, afterAppointment } = req.body;

    // Upsert buffer times
    await pool.query(
      `INSERT INTO buffer_times (kunde_id, before_appointment, after_appointment) 
       VALUES ($1, $2, $3) 
       ON CONFLICT (kunde_id) 
       DO UPDATE SET before_appointment = $2, after_appointment = $3`,
      [kundeId, beforeAppointment || 0, afterAppointment || 0]
    );

    res.json({ message: 'Pufferzeiten erfolgreich aktualisiert' });

  } catch (error) {
    console.error('Update buffer times error:', error);
    res.status(500).json({ error: 'Fehler beim Aktualisieren der Pufferzeiten' });
  }
});

// Get settings
router.get('/settings', async (req, res) => {
  try {
    const kundeId = req.user.kunde_id;

    const result = await pool.query(
      'SELECT * FROM settings WHERE kunde_id = $1',
      [kundeId]
    );

    res.json({ settings: result.rows[0] || {} });

  } catch (error) {
    console.error('Get settings error:', error);
    res.status(500).json({ error: 'Fehler beim Abrufen der Einstellungen' });
  }
});

// Update settings
router.put('/settings', requireAdmin, async (req, res) => {
  try {
    const kundeId = req.user.kunde_id;
    const {
      smsReminders,
      emailReminders,
      reminderHours,
      cancellationDeadlineHours,
      maxAdvanceBookingDays,
      minAdvanceBookingHours
    } = req.body;

    // Upsert settings
    await pool.query(
      `INSERT INTO settings (
        kunde_id, sms_reminders, email_reminders, reminder_hours, 
        cancellation_deadline_hours, max_advance_booking_days, min_advance_booking_hours
      ) VALUES ($1, $2, $3, $4, $5, $6, $7)
      ON CONFLICT (kunde_id) 
      DO UPDATE SET 
        sms_reminders = $2, 
        email_reminders = $3, 
        reminder_hours = $4,
        cancellation_deadline_hours = $5,
        max_advance_booking_days = $6,
        min_advance_booking_hours = $7`,
      [
        kundeId,
        smsReminders,
        emailReminders,
        reminderHours || 24,
        cancellationDeadlineHours || 12,
        maxAdvanceBookingDays || 90,
        minAdvanceBookingHours || 2
      ]
    );

    res.json({ message: 'Einstellungen erfolgreich aktualisiert' });

  } catch (error) {
    console.error('Update settings error:', error);
    res.status(500).json({ error: 'Fehler beim Aktualisieren der Einstellungen' });
  }
});

// Get kunde profile
router.get('/profile', async (req, res) => {
  try {
    const kundeId = req.user.kunde_id;

    const result = await pool.query(
      'SELECT * FROM kunden WHERE id = $1',
      [kundeId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Kunde nicht gefunden' });
    }

    res.json({ kunde: result.rows[0] });

  } catch (error) {
    console.error('Get profile error:', error);
    res.status(500).json({ error: 'Fehler beim Abrufen des Profils' });
  }
});

// Update kunde profile
router.put('/profile', requireAdmin, async (req, res) => {
  try {
    const kundeId = req.user.kunde_id;
    const {
      name,
      email,
      telefon,
      adresse,
      branche,
      logoUrl,
      primaryColor,
      secondaryColor
    } = req.body;

    const result = await pool.query(
      `UPDATE kunden 
       SET name = $1, email = $2, telefon = $3, adresse = $4, 
           branche = $5, logo_url = $6, primary_color = $7, secondary_color = $8
       WHERE id = $9 
       RETURNING *`,
      [name, email, telefon, adresse, branche, logoUrl, primaryColor, secondaryColor, kundeId]
    );

    res.json({ 
      message: 'Profil erfolgreich aktualisiert',
      kunde: result.rows[0]
    });

  } catch (error) {
    console.error('Update profile error:', error);
    res.status(500).json({ error: 'Fehler beim Aktualisieren des Profils' });
  }
});

// Get appointment statistics
router.get('/statistics', async (req, res) => {
  try {
    const kundeId = req.user.kunde_id;
    const { period = 'month' } = req.query;

    let dateFilter;
    switch (period) {
      case 'week':
        dateFilter = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000);
        break;
      case 'month':
        dateFilter = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000);
        break;
      case 'year':
        dateFilter = new Date(Date.now() - 365 * 24 * 60 * 60 * 1000);
        break;
      default:
        dateFilter = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000);
    }

    const stats = await pool.query(
      `SELECT 
         DATE(appointment_date) as date,
         COUNT(*) as total,
         COUNT(CASE WHEN status = 'confirmed' THEN 1 END) as confirmed,
         COUNT(CASE WHEN status = 'cancelled' THEN 1 END) as cancelled,
         COUNT(CASE WHEN status = 'completed' THEN 1 END) as completed
       FROM appointments 
       WHERE kunde_id = $1 AND appointment_date >= $2
       GROUP BY DATE(appointment_date)
       ORDER BY date DESC`,
      [kundeId, dateFilter.toISOString().split('T')[0]]
    );

    res.json({ statistics: stats.rows });

  } catch (error) {
    console.error('Get statistics error:', error);
    res.status(500).json({ error: 'Fehler beim Abrufen der Statistiken' });
  }
});

module.exports = router;