const twilio = require('twilio');
const moment = require('moment');

// Twilio configuration
const client = twilio(
  process.env.TWILIO_ACCOUNT_SID || 'your-account-sid',
  process.env.TWILIO_AUTH_TOKEN || 'your-auth-token'
);

const fromNumber = process.env.TWILIO_PHONE_NUMBER || '+1234567890';

// SMS templates
const smsTemplates = {
  reminder: {
    text: 'Erinnerung: Ihr Termin bei {{kundeName}} ist morgen um {{appointmentTime}} Uhr. Bitte kommen Sie pünktlich. Bei Fragen: {{kundePhone}}'
  },
  
  cancellation: {
    text: 'Ihr Termin bei {{kundeName}} für {{appointmentDate}} um {{appointmentTime}} Uhr wurde erfolgreich storniert.'
  },
  
  confirmation: {
    text: 'Terminbestätigung: {{appointmentDate}} um {{appointmentTime}} Uhr bei {{kundeName}}. Stornierung: {{cancellationUrl}}'
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

// Send SMS reminder
async function sendSMSReminder(appointment, kunde) {
  try {
    // Check if customer has provided a phone number
    if (!appointment.customer_telefon) {
      console.log('No phone number provided for appointment, skipping SMS reminder');
      return null;
    }

    const variables = {
      kundeName: kunde.name,
      appointmentTime: appointment.appointment_time,
      kundePhone: kunde.telefon || 'Nicht verfügbar'
    };

    const messageText = replaceTemplateVariables(smsTemplates.reminder.text, variables);

    const message = await client.messages.create({
      body: messageText,
      from: fromNumber,
      to: appointment.customer_telefon
    });

    console.log('SMS reminder sent:', message.sid);
    return message;

  } catch (error) {
    console.error('Error sending SMS reminder:', error);
    throw error;
  }
}

// Send SMS cancellation confirmation
async function sendSMSCancellation(appointment, kunde) {
  try {
    if (!appointment.customer_telefon) {
      console.log('No phone number provided for appointment, skipping SMS cancellation');
      return null;
    }

    const variables = {
      kundeName: kunde.name,
      appointmentDate: moment(appointment.appointment_date).format('DD.MM.YYYY'),
      appointmentTime: appointment.appointment_time
    };

    const messageText = replaceTemplateVariables(smsTemplates.cancellation.text, variables);

    const message = await client.messages.create({
      body: messageText,
      from: fromNumber,
      to: appointment.customer_telefon
    });

    console.log('SMS cancellation sent:', message.sid);
    return message;

  } catch (error) {
    console.error('Error sending SMS cancellation:', error);
    throw error;
  }
}

// Send SMS confirmation
async function sendSMSConfirmation(appointment, kunde) {
  try {
    if (!appointment.customer_telefon) {
      console.log('No phone number provided for appointment, skipping SMS confirmation');
      return null;
    }

    const cancellationUrl = `${process.env.FRONTEND_URL || 'http://localhost:3000'}/cancel/${appointment.id}?token=${appointment.cancellation_token}`;
    
    const variables = {
      appointmentDate: moment(appointment.appointment_date).format('DD.MM.YYYY'),
      appointmentTime: appointment.appointment_time,
      kundeName: kunde.name,
      cancellationUrl: cancellationUrl
    };

    const messageText = replaceTemplateVariables(smsTemplates.confirmation.text, variables);

    const message = await client.messages.create({
      body: messageText,
      from: fromNumber,
      to: appointment.customer_telefon
    });

    console.log('SMS confirmation sent:', message.sid);
    return message;

  } catch (error) {
    console.error('Error sending SMS confirmation:', error);
    throw error;
  }
}

// Send custom SMS
async function sendCustomSMS(to, message, from = null) {
  try {
    const messageObj = await client.messages.create({
      body: message,
      from: from || fromNumber,
      to: to
    });

    console.log('Custom SMS sent:', messageObj.sid);
    return messageObj;

  } catch (error) {
    console.error('Error sending custom SMS:', error);
    throw error;
  }
}

// Verify Twilio configuration
async function verifyTwilioConfig() {
  try {
    // Try to fetch account information to verify credentials
    const account = await client.api.accounts(process.env.TWILIO_ACCOUNT_SID).fetch();
    console.log('Twilio service is ready, account:', account.friendlyName);
    return true;
  } catch (error) {
    console.error('Twilio service configuration error:', error);
    return false;
  }
}

// Get account balance (useful for monitoring)
async function getAccountBalance() {
  try {
    const balance = await client.api.accounts(process.env.TWILIO_ACCOUNT_SID).balance.fetch();
    return {
      currency: balance.currency,
      balance: balance.balance,
      accountType: balance.accountType
    };
  } catch (error) {
    console.error('Error fetching account balance:', error);
    throw error;
  }
}

// Get message history for a specific number
async function getMessageHistory(phoneNumber, limit = 50) {
  try {
    const messages = await client.messages.list({
      to: phoneNumber,
      limit: limit
    });
    
    return messages.map(msg => ({
      sid: msg.sid,
      body: msg.body,
      from: msg.from,
      to: msg.to,
      status: msg.status,
      dateCreated: msg.dateCreated,
      dateSent: msg.dateSent
    }));
  } catch (error) {
    console.error('Error fetching message history:', error);
    throw error;
  }
}

module.exports = {
  sendSMSReminder,
  sendSMSCancellation,
  sendSMSConfirmation,
  sendCustomSMS,
  verifyTwilioConfig,
  getAccountBalance,
  getMessageHistory
};