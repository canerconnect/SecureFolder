const cron = require('node-cron');
const moment = require('moment');
const { pool } = require('../config/database');
const emailService = require('./emailService');
const smsService = require('./smsService');

// Schedule reminder emails (run daily at 9:00 AM)
function scheduleReminderEmails() {
  cron.schedule('0 9 * * *', async () => {
    console.log('Running scheduled reminder emails...');
    try {
      await sendReminderEmails();
    } catch (error) {
      console.error('Error in scheduled reminder emails:', error);
    }
  });
}

// Schedule reminder SMS (run daily at 9:00 AM)
function scheduleReminderSMS() {
  cron.schedule('0 9 * * *', async () => {
    console.log('Running scheduled reminder SMS...');
    try {
      await sendReminderSMS();
    } catch (error) {
      console.error('Error in scheduled reminder SMS:', error);
    }
  });
}

// Schedule data cleanup (run daily at 2:00 AM)
function scheduleDataCleanup() {
  cron.schedule('0 2 * * *', async () => {
    console.log('Running scheduled data cleanup...');
    try {
      await cleanupExpiredData();
    } catch (error) {
      console.error('Error in scheduled data cleanup:', error);
    }
  });
}

// Send reminder emails for appointments tomorrow
async function sendReminderEmails() {
  try {
    const tomorrow = moment().add(1, 'day').format('YYYY-MM-DD');
    
    const query = `
      SELECT 
        a.*,
        k.name as kunde_name,
        k.email as kunde_email,
        k.adresse,
        k.primary_color,
        s.email_reminder_hours
      FROM appointments a
      JOIN kunden k ON a.kunde_id = k.id
      JOIN settings s ON a.kunde_id = s.kunde_id
      WHERE DATE(a.appointment_date) = $1 
        AND a.status = 'confirmed'
        AND s.email_reminder_enabled = true
        AND s.email_reminder_hours = 24
    `;
    
    const result = await pool.query(query, [tomorrow]);
    
    for (const appointment of result.rows) {
      try {
        const kunde = {
          name: appointment.kunde_name,
          email: appointment.kunde_email,
          adresse: appointment.adresse,
          primary_color: appointment.primary_color
        };
        
        await emailService.sendReminder(appointment, kunde);
        
        // Update appointment to mark reminder as sent
        await pool.query(
          'UPDATE appointments SET reminder_sent = true WHERE id = $1',
          [appointment.id]
        );
        
        console.log(`Reminder email sent for appointment ${appointment.id}`);
      } catch (error) {
        console.error(`Error sending reminder email for appointment ${appointment.id}:`, error);
      }
    }
    
    console.log(`Sent ${result.rows.length} reminder emails`);
  } catch (error) {
    console.error('Error sending reminder emails:', error);
    throw error;
  }
}

// Send reminder SMS for appointments tomorrow
async function sendReminderSMS() {
  try {
    const tomorrow = moment().add(1, 'day').format('YYYY-MM-DD');
    
    const query = `
      SELECT 
        a.*,
        k.name as kunde_name,
        k.telefon,
        s.sms_reminder_hours
      FROM appointments a
      JOIN kunden k ON a.kunde_id = k.id
      JOIN settings s ON a.kunde_id = s.kunde_id
      WHERE DATE(a.appointment_date) = $1 
        AND a.status = 'confirmed'
        AND s.sms_reminder_enabled = true
        AND s.sms_reminder_hours = 24
        AND a.customer_telefon IS NOT NULL
    `;
    
    const result = await pool.query(query, [tomorrow]);
    
    for (const appointment of result.rows) {
      try {
        const kunde = {
          name: appointment.kunde_name,
          telefon: appointment.telefon
        };
        
        await smsService.sendSMSReminder(appointment, kunde);
        
        // Update appointment to mark SMS reminder as sent
        await pool.query(
          'UPDATE appointments SET sms_reminder_sent = true WHERE id = $1',
          [appointment.id]
        );
        
        console.log(`Reminder SMS sent for appointment ${appointment.id}`);
      } catch (error) {
        console.error(`Error sending reminder SMS for appointment ${appointment.id}:`, error);
      }
    }
    
    console.log(`Sent ${result.rows.length} reminder SMS`);
  } catch (error) {
    console.error('Error sending reminder SMS:', error);
    throw error;
  }
}

// Clean up expired data
async function cleanupExpiredData() {
  try {
    // Clean up expired cancellation tokens (older than 30 days)
    const thirtyDaysAgo = moment().subtract(30, 'days').toDate();
    
    const result = await pool.query(
      'DELETE FROM appointments WHERE cancellation_token_expires < $1 AND status = "cancelled"',
      [thirtyDaysAgo]
    );
    
    console.log(`Cleaned up ${result.rowCount} expired cancelled appointments`);
    
    // Clean up old completed appointments (older than 2 years)
    const twoYearsAgo = moment().subtract(2, 'years').toDate();
    
    const completedResult = await pool.query(
      'DELETE FROM appointments WHERE appointment_date < $1 AND status = "completed"',
      [twoYearsAgo]
    );
    
    console.log(`Cleaned up ${completedResult.rowCount} old completed appointments`);
    
  } catch (error) {
    console.error('Error in data cleanup:', error);
    throw error;
  }
}

// Send immediate reminder for specific appointment
async function sendImmediateReminder(appointmentId) {
  try {
    const query = `
      SELECT 
        a.*,
        k.name as kunde_name,
        k.email as kunde_email,
        k.adresse,
        k.primary_color,
        k.telefon
      FROM appointments a
      JOIN kunden k ON a.kunde_id = k.id
      WHERE a.id = $1 AND a.status = 'confirmed'
    `;
    
    const result = await pool.query(query, [appointmentId]);
    
    if (result.rows.length === 0) {
      throw new Error('Appointment not found or not confirmed');
    }
    
    const appointment = result.rows[0];
    const kunde = {
      name: appointment.kunde_name,
      email: appointment.kunde_email,
      adresse: appointment.adresse,
      primary_color: appointment.primary_color,
      telefon: appointment.telefon
    };
    
    // Send email reminder
    await emailService.sendReminder(appointment, kunde);
    
    // Send SMS reminder if phone number exists
    if (appointment.customer_telefon) {
      await smsService.sendSMSReminder(appointment, kunde);
    }
    
    // Update appointment to mark reminders as sent
    await pool.query(
      'UPDATE appointments SET reminder_sent = true, sms_reminder_sent = true WHERE id = $1',
      [appointmentId]
    );
    
    console.log(`Immediate reminders sent for appointment ${appointmentId}`);
    return true;
    
  } catch (error) {
    console.error('Error sending immediate reminder:', error);
    throw error;
  }
}

// Start all scheduled tasks
function startScheduler() {
  console.log('Starting scheduler service...');
  
  scheduleReminderEmails();
  scheduleReminderSMS();
  scheduleDataCleanup();
  
  console.log('Scheduler service started');
}

// Stop all scheduled tasks
function stopScheduler() {
  console.log('Stopping scheduler service...');
  cron.getTasks().forEach(task => task.stop());
  console.log('Scheduler service stopped');
}

// Get scheduler status
function getSchedulerStatus() {
  const tasks = cron.getTasks();
  const status = {};
  
  for (const [name, task] of tasks.entries()) {
    status[name] = {
      running: task.running,
      nextRun: task.nextDate().toDate()
    };
  }
  
  return status;
}

module.exports = {
  startScheduler,
  stopScheduler,
  getSchedulerStatus,
  sendImmediateReminder,
  sendReminderEmails,
  sendReminderSMS,
  cleanupExpiredData
};