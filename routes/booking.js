const express = require('express');
const { v4: uuidv4 } = require('uuid');
const moment = require('moment');
const { pool } = require('../config/database');
const { getKundeFromSubdomain, validateBookingData, authenticateToken } = require('../middleware/auth');
const { sendBookingConfirmation, sendCancellationNotification } = require('../services/emailService');
const { sendSMSReminder } = require('../services/smsService');

const router = express.Router();

// Create new appointment
router.post('/', getKundeFromSubdomain, validateBookingData, async (req, res) => {
  try {
    const { name, email, telefon, datum, uhrzeit, bemerkung } = req.body;
    const kundeId = req.kunde.id;

    // Check if slot is available
    const slotCheck = await pool.query(
      `SELECT id FROM appointments 
       WHERE kunde_id = $1 
       AND appointment_date = $2 
       AND appointment_time = $3 
       AND status = 'confirmed'`,
      [kundeId, datum, uhrzeit]
    );

    if (slotCheck.rows.length > 0) {
      return res.status(409).json({ 
        error: 'Dieser Termin ist bereits belegt' 
      });
    }

    // Check if within working hours
    const dayOfWeek = moment(datum).day();
    const workingHoursResult = await pool.query(
      'SELECT * FROM working_hours WHERE kunde_id = $1 AND day_of_week = $2 AND is_working_day = true',
      [kundeId, dayOfWeek]
    );

    if (workingHoursResult.rows.length === 0) {
      return res.status(400).json({ 
        error: 'Termine können nur während der Arbeitszeiten gebucht werden' 
      });
    }

    const workingHours = workingHoursResult.rows[0];
    if (uhrzeit < workingHours.start_time || uhrzeit > workingHours.end_time) {
      return res.status(400).json({ 
        error: 'Termin liegt außerhalb der Arbeitszeiten' 
      });
    }

    // Check break times
    const breakTimeResult = await pool.query(
      'SELECT * FROM break_times WHERE kunde_id = $1 AND day_of_week = $2 AND $3 BETWEEN start_time AND end_time',
      [kundeId, dayOfWeek, uhrzeit]
    );

    if (breakTimeResult.rows.length > 0) {
      return res.status(400).json({ 
        error: 'Termin liegt in der Mittagspause' 
      });
    }

    // Create appointment
    const appointmentResult = await pool.query(
      `INSERT INTO appointments 
       (kunde_id, customer_name, customer_email, customer_telefon, appointment_date, appointment_time, bemerkung, cancellation_token)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
       RETURNING *`,
      [kundeId, name, email, telefon, datum, uhrzeit, bemerkung, uuidv4()]
    );

    const appointment = appointmentResult.rows[0];

    // Send confirmation email
    try {
      await sendBookingConfirmation(appointment, req.kunde);
    } catch (emailError) {
      console.error('Fehler beim Senden der Bestätigungs-E-Mail:', emailError);
      // Don't fail the booking if email fails
    }

    res.status(201).json({
      message: 'Termin erfolgreich gebucht',
      appointment: {
        id: appointment.id,
        date: appointment.appointment_date,
        time: appointment.appointment_time,
        cancellationToken: appointment.cancellation_token
      }
    });

  } catch (error) {
    console.error('Booking error:', error);
    res.status(500).json({ error: 'Fehler bei der Terminbuchung' });
  }
});

// Cancel appointment
router.delete('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const { token } = req.query;

    if (!token) {
      return res.status(400).json({ error: 'Stornierungstoken erforderlich' });
    }

    // Get appointment
    const appointmentResult = await pool.query(
      `SELECT a.*, k.name as kunde_name, k.email as kunde_email 
       FROM appointments a 
       JOIN kunden k ON a.kunde_id = k.id 
       WHERE a.id = $1 AND a.cancellation_token = $2 AND a.status = 'confirmed'`,
      [id, token]
    );

    if (appointmentResult.rows.length === 0) {
      return res.status(404).json({ error: 'Termin nicht gefunden oder bereits storniert' });
    }

    const appointment = appointmentResult.rows[0];

    // Check cancellation deadline
    const settingsResult = await pool.query(
      'SELECT cancellation_deadline_hours FROM settings WHERE kunde_id = $1',
      [appointment.kunde_id]
    );

    const cancellationDeadline = settingsResult.rows[0]?.cancellation_deadline_hours || 12;
    const appointmentDateTime = moment(`${appointment.appointment_date} ${appointment.appointment_time}`);
    const deadline = moment().add(cancellationDeadline, 'hours');

    if (appointmentDateTime.isBefore(deadline)) {
      return res.status(400).json({ 
        error: `Termin kann nur bis ${cancellationDeadline} Stunden vorher storniert werden` 
      });
    }

    // Cancel appointment
    await pool.query(
      'UPDATE appointments SET status = $1 WHERE id = $2',
      ['cancelled', id]
    );

    // Send cancellation notification to provider
    try {
      await sendCancellationNotification(appointment, req.kunde);
    } catch (emailError) {
      console.error('Fehler beim Senden der Stornierungsbenachrichtigung:', emailError);
    }

    res.json({ message: 'Termin erfolgreich storniert' });

  } catch (error) {
    console.error('Cancellation error:', error);
    res.status(500).json({ error: 'Fehler bei der Terminstornierung' });
  }
});

// Get appointment details
router.get('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const { token } = req.query;

    if (!token) {
      return res.status(400).json({ error: 'Token erforderlich' });
    }

    const result = await pool.query(
      `SELECT a.*, k.name as kunde_name 
       FROM appointments a 
       JOIN kunden k ON a.kunde_id = k.id 
       WHERE a.id = $1 AND a.cancellation_token = $2`,
      [id, token]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Termin nicht gefunden' });
    }

    res.json({ appointment: result.rows[0] });

  } catch (error) {
    console.error('Get appointment error:', error);
    res.status(500).json({ error: 'Fehler beim Abrufen der Termindaten' });
  }
});

// Admin: Get all appointments for a kunde
router.get('/admin/all', authenticateToken, async (req, res) => {
  try {
    const kundeId = req.user.kunde_id;
    const { date, status } = req.query;

    let query = `
      SELECT a.*, 
             k.name as kunde_name 
      FROM appointments a 
      JOIN kunden k ON a.kunde_id = k.id 
      WHERE a.kunde_id = $1
    `;
    
    const params = [kundeId];
    let paramCount = 1;

    if (date) {
      paramCount++;
      query += ` AND a.appointment_date = $${paramCount}`;
      params.push(date);
    }

    if (status) {
      paramCount++;
      query += ` AND a.status = $${paramCount}`;
      params.push(status);
    }

    query += ' ORDER BY a.appointment_date DESC, a.appointment_time ASC';

    const result = await pool.query(query, params);

    res.json({ appointments: result.rows });

  } catch (error) {
    console.error('Get appointments error:', error);
    res.status(500).json({ error: 'Fehler beim Abrufen der Termine' });
  }
});

// Admin: Update appointment
router.put('/admin/:id', authenticateToken, async (req, res) => {
  try {
    const { id } = req.params;
    const { status, bemerkung } = req.body;
    const kundeId = req.user.kunde_id;

    // Verify appointment belongs to user's kunde
    const appointmentCheck = await pool.query(
      'SELECT id FROM appointments WHERE id = $1 AND kunde_id = $2',
      [id, kundeId]
    );

    if (appointmentCheck.rows.length === 0) {
      return res.status(404).json({ error: 'Termin nicht gefunden' });
    }

    // Update appointment
    const result = await pool.query(
      'UPDATE appointments SET status = $1, bemerkung = $2 WHERE id = $3 RETURNING *',
      [status, bemerkung, id]
    );

    res.json({ 
      message: 'Termin erfolgreich aktualisiert',
      appointment: result.rows[0]
    });

  } catch (error) {
    console.error('Update appointment error:', error);
    res.status(500).json({ error: 'Fehler beim Aktualisieren des Termins' });
  }
});

// Admin: Delete appointment
router.delete('/admin/:id', authenticateToken, async (req, res) => {
  try {
    const { id } = req.params;
    const kundeId = req.user.kunde_id;

    // Verify appointment belongs to user's kunde
    const appointmentCheck = await pool.query(
      'SELECT id FROM appointments WHERE id = $1 AND kunde_id = $2',
      [id, kundeId]
    );

    if (appointmentCheck.rows.length === 0) {
      return res.status(404).json({ error: 'Termin nicht gefunden' });
    }

    // Delete appointment
    await pool.query('DELETE FROM appointments WHERE id = $1', [id]);

    res.json({ message: 'Termin erfolgreich gelöscht' });

  } catch (error) {
    console.error('Delete appointment error:', error);
    res.status(500).json({ error: 'Fehler beim Löschen des Termins' });
  }
});

module.exports = router;