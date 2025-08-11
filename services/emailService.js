const nodemailer = require('nodemailer');
const moment = require('moment');

// Email configuration
const transporter = nodemailer.createTransporter({
  host: process.env.SMTP_HOST || 'smtp.gmail.com',
  port: process.env.SMTP_PORT || 587,
  secure: false, // true for 465, false for other ports
  auth: {
    user: process.env.SMTP_USER || 'your-email@gmail.com',
    pass: process.env.SMTP_PASS || 'your-app-password'
  }
});

// Email templates
const emailTemplates = {
  bookingConfirmation: {
    subject: 'Terminbestätigung - {{kundeName}}',
    html: `
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Terminbestätigung</title>
        <style>
          body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
          .container { max-width: 600px; margin: 0 auto; padding: 20px; }
          .header { background-color: {{primaryColor}}; color: white; padding: 20px; text-align: center; border-radius: 8px 8px 0 0; }
          .content { background-color: #f9f9f9; padding: 20px; border-radius: 0 0 8px 8px; }
          .appointment-details { background-color: white; padding: 20px; margin: 20px 0; border-radius: 8px; border-left: 4px solid {{primaryColor}}; }
          .button { display: inline-block; padding: 12px 24px; background-color: {{primaryColor}}; color: white; text-decoration: none; border-radius: 6px; margin: 20px 0; }
          .footer { text-align: center; margin-top: 30px; color: #666; font-size: 14px; }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <h1>Terminbestätigung</h1>
          </div>
          <div class="content">
            <p>Hallo {{customerName}},</p>
            <p>Ihr Termin bei <strong>{{kundeName}}</strong> wurde erfolgreich bestätigt.</p>
            
            <div class="appointment-details">
              <h3>Termindetails:</h3>
              <p><strong>Datum:</strong> {{appointmentDate}}</p>
              <p><strong>Uhrzeit:</strong> {{appointmentTime}}</p>
              <p><strong>Adresse:</strong> {{kundeAddress}}</p>
            </div>
            
            <p>Bitte kommen Sie pünktlich zu Ihrem Termin.</p>
            
            <a href="{{cancellationUrl}}" class="button">Termin stornieren</a>
            
            <p><strong>Wichtiger Hinweis:</strong> Termine können bis zu {{cancellationDeadline}} Stunden vorher storniert werden.</p>
            
            <div class="footer">
              <p>Bei Fragen erreichen Sie uns unter: {{kundeEmail}}</p>
              <p>Diese E-Mail wurde automatisch generiert. Bitte antworten Sie nicht darauf.</p>
            </div>
          </div>
        </div>
      </body>
      </html>
    `
  },
  
  reminder: {
    subject: 'Erinnerung: Ihr Termin morgen - {{kundeName}}',
    html: `
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Terminerinnerung</title>
        <style>
          body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
          .container { max-width: 600px; margin: 0 auto; padding: 20px; }
          .header { background-color: {{primaryColor}}; color: white; padding: 20px; text-align: center; border-radius: 8px 8px 0 0; }
          .content { background-color: #f9f9f9; padding: 20px; border-radius: 0 0 8px 8px; }
          .appointment-details { background-color: white; padding: 20px; margin: 20px 0; border-radius: 8px; border-left: 4px solid {{primaryColor}}; }
          .footer { text-align: center; margin-top: 30px; color: #666; font-size: 14px; }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <h1>Terminerinnerung</h1>
          </div>
          <div class="content">
            <p>Hallo {{customerName}},</p>
            <p>Wir erinnern Sie an Ihren Termin morgen bei <strong>{{kundeName}}</strong>.</p>
            
            <div class="appointment-details">
              <h3>Termindetails:</h3>
              <p><strong>Datum:</strong> {{appointmentDate}}</p>
              <p><strong>Uhrzeit:</strong> {{appointmentTime}}</p>
              <p><strong>Adresse:</strong> {{kundeAddress}}</p>
            </div>
            
            <p>Bitte kommen Sie pünktlich zu Ihrem Termin.</p>
            
            <div class="footer">
              <p>Bei Fragen erreichen Sie uns unter: {{kundeEmail}}</p>
              <p>Diese E-Mail wurde automatisch generiert. Bitte antworten Sie nicht darauf.</p>
            </div>
          </div>
        </div>
      </body>
      </html>
    `
  },
  
  cancellationNotification: {
    subject: 'Terminstornierung - {{kundeName}}',
    html: `
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Terminstornierung</title>
        <style>
          body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
          .container { max-width: 600px; margin: 0 auto; padding: 20px; }
          .header { background-color: #dc3545; color: white; padding: 20px; text-align: center; border-radius: 8px 8px 0 0; }
          .content { background-color: #f9f9f9; padding: 20px; border-radius: 0 0 8px 8px; }
          .appointment-details { background-color: white; padding: 20px; margin: 20px 0; border-radius: 8px; border-left: 4px solid #dc3545; }
          .footer { text-align: center; margin-top: 30px; color: #666; font-size: 14px; }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <h1>Terminstornierung</h1>
          </div>
          <div class="content">
            <p>Ein Termin wurde storniert.</p>
            
            <div class="appointment-details">
              <h3>Stornierte Termindetails:</h3>
              <p><strong>Kunde:</strong> {{customerName}}</p>
              <p><strong>E-Mail:</strong> {{customerEmail}}</p>
              <p><strong>Telefon:</strong> {{customerPhone}}</p>
              <p><strong>Datum:</strong> {{appointmentDate}}</p>
              <p><strong>Uhrzeit:</strong> {{appointmentTime}}</p>
            </div>
            
            <div class="footer">
              <p>Diese E-Mail wurde automatisch generiert.</p>
            </div>
          </div>
        </div>
      </body>
      </html>
    `
  }
};

// Helper function to replace template variables
function replaceTemplateVariables(template, variables) {
  let result = template;
  for (const [key, value] of Object.entries(variables)) {
    const regex = new RegExp(`{{${key}}}`, 'g');
    result = result.replace(regex, value || '');
  }
  return result;
}

// Send booking confirmation email
async function sendBookingConfirmation(appointment, kunde) {
  try {
    const cancellationUrl = `${process.env.FRONTEND_URL || 'http://localhost:3000'}/cancel/${appointment.id}?token=${appointment.cancellation_token}`;
    
    const variables = {
      customerName: appointment.customer_name,
      kundeName: kunde.name,
      appointmentDate: moment(appointment.appointment_date).format('DD.MM.YYYY'),
      appointmentTime: appointment.appointment_time,
      kundeAddress: kunde.adresse || 'Adresse wird bei der Anmeldung bekanntgegeben',
      cancellationUrl: cancellationUrl,
      cancellationDeadline: '12', // This should come from settings
      primaryColor: kunde.primary_color || '#3B82F6',
      kundeEmail: kunde.email
    };

    const subject = replaceTemplateVariables(emailTemplates.bookingConfirmation.subject, variables);
    const html = replaceTemplateVariables(emailTemplates.bookingConfirmation.html, variables);

    const mailOptions = {
      from: process.env.SMTP_FROM || process.env.SMTP_USER,
      to: appointment.customer_email,
      subject: subject,
      html: html
    };

    const info = await transporter.sendMail(mailOptions);
    console.log('Booking confirmation email sent:', info.messageId);
    return info;

  } catch (error) {
    console.error('Error sending booking confirmation email:', error);
    throw error;
  }
}

// Send reminder email
async function sendReminder(appointment, kunde) {
  try {
    const variables = {
      customerName: appointment.customer_name,
      kundeName: kunde.name,
      appointmentDate: moment(appointment.appointment_date).format('DD.MM.YYYY'),
      appointmentTime: appointment.appointment_time,
      kundeAddress: kunde.adresse || 'Adresse wird bei der Anmeldung bekanntgegeben',
      primaryColor: kunde.primary_color || '#3B82F6',
      kundeEmail: kunde.email
    };

    const subject = replaceTemplateVariables(emailTemplates.reminder.subject, variables);
    const html = replaceTemplateVariables(emailTemplates.reminder.html, variables);

    const mailOptions = {
      from: process.env.SMTP_FROM || process.env.SMTP_USER,
      to: appointment.customer_email,
      subject: subject,
      html: html
    };

    const info = await transporter.sendMail(mailOptions);
    console.log('Reminder email sent:', info.messageId);
    return info;

  } catch (error) {
    console.error('Error sending reminder email:', error);
    throw error;
  }
}

// Send cancellation notification to provider
async function sendCancellationNotification(appointment, kunde) {
  try {
    const variables = {
      customerName: appointment.customer_name,
      customerEmail: appointment.customer_email,
      customerPhone: appointment.customer_telefon || 'Nicht angegeben',
      appointmentDate: moment(appointment.appointment_date).format('DD.MM.YYYY'),
      appointmentTime: appointment.appointment_time,
      kundeName: kunde.name
    };

    const subject = replaceTemplateVariables(emailTemplates.cancellationNotification.subject, variables);
    const html = replaceTemplateVariables(emailTemplates.cancellationNotification.html, variables);

    const mailOptions = {
      from: process.env.SMTP_FROM || process.env.SMTP_USER,
      to: kunde.email,
      subject: subject,
      html: html
    };

    const info = await transporter.sendMail(mailOptions);
    console.log('Cancellation notification email sent:', info.messageId);
    return info;

  } catch (error) {
    console.error('Error sending cancellation notification email:', error);
    throw error;
  }
}

// Send custom email
async function sendCustomEmail(to, subject, html, from = null) {
  try {
    const mailOptions = {
      from: from || process.env.SMTP_FROM || process.env.SMTP_USER,
      to: to,
      subject: subject,
      html: html
    };

    const info = await transporter.sendMail(mailOptions);
    console.log('Custom email sent:', info.messageId);
    return info;

  } catch (error) {
    console.error('Error sending custom email:', error);
    throw error;
  }
}

// Verify email configuration
async function verifyEmailConfig() {
  try {
    await transporter.verify();
    console.log('Email service is ready');
    return true;
  } catch (error) {
    console.error('Email service configuration error:', error);
    return false;
  }
}

module.exports = {
  sendBookingConfirmation,
  sendReminder,
  sendCancellationNotification,
  sendCustomEmail,
  verifyEmailConfig
};