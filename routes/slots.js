const express = require('express');
const moment = require('moment');
const { pool } = require('../config/database');
const { getKundeFromSubdomain } = require('../middleware/auth');

const router = express.Router();

// Get available slots for a specific date
router.get('/', getKundeFromSubdomain, async (req, res) => {
  try {
    const { date } = req.query;
    const kundeId = req.kunde.id;

    if (!date) {
      return res.status(400).json({ error: 'Datum ist erforderlich' });
    }

    // Validate date format
    if (!moment(date, 'YYYY-MM-DD', true).isValid()) {
      return res.status(400).json({ error: 'Ungültiges Datumsformat' });
    }

    const requestedDate = moment(date);
    const today = moment().startOf('day');

    // Check if date is in the past
    if (requestedDate.isBefore(today)) {
      return res.status(400).json({ error: 'Datum liegt in der Vergangenheit' });
    }

    // Get working hours for the requested day
    const dayOfWeek = requestedDate.day();
    const workingHoursResult = await pool.query(
      'SELECT * FROM working_hours WHERE kunde_id = $1 AND day_of_week = $2 AND is_working_day = true',
      [kundeId, dayOfWeek]
    );

    if (workingHoursResult.rows.length === 0) {
      return res.json({ 
        date: date,
        available: false,
        message: 'An diesem Tag sind keine Termine möglich',
        slots: []
      });
    }

    const workingHours = workingHoursResult.rows[0];

    // Get break times for the day
    const breakTimesResult = await pool.query(
      'SELECT * FROM break_times WHERE kunde_id = $1 AND day_of_week = $2 ORDER BY start_time',
      [kundeId, dayOfWeek]
    );

    const breakTimes = breakTimesResult.rows;

    // Get buffer times
    const bufferTimesResult = await pool.query(
      'SELECT * FROM buffer_times WHERE kunde_id = $1',
      [kundeId]
    );

    const bufferTimes = bufferTimesResult.rows[0] || { before_appointment: 0, after_appointment: 0 };

    // Get existing appointments for the date
    const appointmentsResult = await pool.query(
      'SELECT appointment_time, duration FROM appointments WHERE kunde_id = $1 AND appointment_date = $2 AND status = $3',
      [kundeId, date, 'confirmed']
    );

    const existingAppointments = appointmentsResult.rows;

    // Generate time slots
    const slots = [];
    const slotDuration = 30; // Default 30 minutes
    let currentTime = moment(workingHours.start_time, 'HH:mm');
    const endTime = moment(workingHours.end_time, 'HH:mm');

    while (currentTime.isBefore(endTime)) {
      const timeString = currentTime.format('HH:mm');
      
      // Check if slot conflicts with break time
      let isBreakTime = false;
      for (const breakTime of breakTimes) {
        const breakStart = moment(breakTime.start_time, 'HH:mm');
        const breakEnd = moment(breakTime.end_time, 'HH:mm');
        if (currentTime.isBetween(breakStart, breakEnd, null, '[]')) {
          isBreakTime = true;
          break;
        }
      }

      if (!isBreakTime) {
        // Check if slot conflicts with existing appointments
        let isBooked = false;
        for (const appointment of existingAppointments) {
          const appointmentStart = moment(appointment.appointment_time, 'HH:mm');
          const appointmentEnd = moment(appointment.appointment_time, 'HH:mm').add(appointment.duration, 'minutes');
          
          const slotStart = currentTime.clone();
          const slotEnd = currentTime.clone().add(slotDuration, 'minutes');
          
          if (slotStart.isBetween(appointmentStart, appointmentEnd, null, '[]') ||
              slotEnd.isBetween(appointmentStart, appointmentEnd, null, '[]') ||
              (slotStart.isSameOrBefore(appointmentStart) && slotEnd.isSameOrAfter(appointmentEnd))) {
            isBooked = true;
            break;
          }
        }

        // Check buffer times
        let hasBufferConflict = false;
        if (bufferTimes.before_appointment > 0 || bufferTimes.after_appointment > 0) {
          for (const appointment of existingAppointments) {
            const appointmentStart = moment(appointment.appointment_time, 'HH:mm');
            const appointmentEnd = moment(appointment.appointment_time, 'HH:mm').add(appointment.duration, 'minutes');
            
            const slotStart = currentTime.clone();
            const slotEnd = currentTime.clone().add(slotDuration, 'minutes');
            
            // Check before buffer
            if (bufferTimes.before_appointment > 0) {
              const bufferStart = appointmentStart.clone().subtract(bufferTimes.before_appointment, 'minutes');
              if (slotEnd.isAfter(bufferStart) && slotStart.isBefore(appointmentStart)) {
                hasBufferConflict = true;
                break;
              }
            }
            
            // Check after buffer
            if (bufferTimes.after_appointment > 0) {
              const bufferEnd = appointmentEnd.clone().add(bufferTimes.after_appointment, 'minutes');
              if (slotStart.isBefore(bufferEnd) && slotEnd.isAfter(appointmentEnd)) {
                hasBufferConflict = true;
                break;
              }
            }
          }
        }

        if (!isBooked && !hasBufferConflict) {
          slots.push({
            time: timeString,
            available: true,
            status: 'free'
          });
        } else {
          slots.push({
            time: timeString,
            available: false,
            status: 'booked'
          });
        }
      }

      currentTime.add(slotDuration, 'minutes');
    }

    res.json({
      date: date,
      available: slots.some(slot => slot.available),
      workingHours: {
        start: workingHours.start_time,
        end: workingHours.end_time
      },
      slots: slots
    });

  } catch (error) {
    console.error('Get slots error:', error);
    res.status(500).json({ error: 'Fehler beim Abrufen der verfügbaren Termine' });
  }
});

// Get working hours for a kunde
router.get('/working-hours', getKundeFromSubdomain, async (req, res) => {
  try {
    const kundeId = req.kunde.id;

    const result = await pool.query(
      'SELECT * FROM working_hours WHERE kunde_id = $1 ORDER BY day_of_week, start_time',
      [kundeId]
    );

    const workingHours = result.rows.reduce((acc, row) => {
      const dayNames = ['Sonntag', 'Montag', 'Dienstag', 'Mittwoch', 'Donnerstag', 'Freitag', 'Samstag'];
      acc[dayNames[row.day_of_week]] = {
        isWorkingDay: row.is_working_day,
        startTime: row.start_time,
        endTime: row.end_time
      };
      return acc;
    }, {});

    res.json({ workingHours });

  } catch (error) {
    console.error('Get working hours error:', error);
    res.status(500).json({ error: 'Fehler beim Abrufen der Arbeitszeiten' });
  }
});

// Get break times for a kunde
router.get('/break-times', getKundeFromSubdomain, async (req, res) => {
  try {
    const kundeId = req.kunde.id;

    const result = await pool.query(
      'SELECT * FROM break_times WHERE kunde_id = $1 ORDER BY day_of_week, start_time',
      [kundeId]
    );

    const breakTimes = result.rows.reduce((acc, row) => {
      const dayNames = ['Sonntag', 'Montag', 'Dienstag', 'Mittwoch', 'Donnerstag', 'Freitag', 'Samstag'];
      if (!acc[dayNames[row.day_of_week]]) {
        acc[dayNames[row.day_of_week]] = [];
      }
      acc[dayNames[row.day_of_week]].push({
        startTime: row.start_time,
        endTime: row.end_time
      });
      return acc;
    }, {});

    res.json({ breakTimes });

  } catch (error) {
    console.error('Get break times error:', error);
    res.status(500).json({ error: 'Fehler beim Abrufen der Pausenzeiten' });
  }
});

// Get next available dates
router.get('/next-available', getKundeFromSubdomain, async (req, res) => {
  try {
    const kundeId = req.kunde.id;
    const { count = 7 } = req.query; // Default to 7 days

    const availableDates = [];
    let currentDate = moment().startOf('day');
    let foundCount = 0;

    while (foundCount < count && availableDates.length < 30) { // Max 30 days to prevent infinite loop
      const dayOfWeek = currentDate.day();
      
      // Check if it's a working day
      const workingHoursResult = await pool.query(
        'SELECT * FROM working_hours WHERE kunde_id = $1 AND day_of_week = $2 AND is_working_day = true',
        [kundeId, dayOfWeek]
      );

      if (workingHoursResult.rows.length > 0) {
        // Check if there are any available slots
        const appointmentsResult = await pool.query(
          'SELECT COUNT(*) FROM appointments WHERE kunde_id = $1 AND appointment_date = $2 AND status = $3',
          [kundeId, currentDate.format('YYYY-MM-DD'), 'confirmed']
        );

        const appointmentCount = parseInt(appointmentsResult.rows[0].count);
        
        // Simple heuristic: if less than 10 appointments, consider it available
        if (appointmentCount < 10) {
          availableDates.push({
            date: currentDate.format('YYYY-MM-DD'),
            dayName: currentDate.format('dddd'),
            available: true
          });
          foundCount++;
        }
      }

      currentDate.add(1, 'day');
    }

    res.json({ availableDates });

  } catch (error) {
    console.error('Get next available dates error:', error);
    res.status(500).json({ error: 'Fehler beim Abrufen der nächsten verfügbaren Termine' });
  }
});

module.exports = router;