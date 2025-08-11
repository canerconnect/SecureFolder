const { TWILIO_ACCOUNT_SID, TWILIO_AUTH_TOKEN, TWILIO_FROM } = process.env;
let twilioClient = null;
if (TWILIO_ACCOUNT_SID && TWILIO_AUTH_TOKEN) {
  const twilio = await import('twilio');
  twilioClient = twilio.default(TWILIO_ACCOUNT_SID, TWILIO_AUTH_TOKEN);
}

export async function sendSms({ to, body }) {
  if (!twilioClient) {
    console.log('[sms] (dry-run) to=%s body=%s', to, body);
    return { dryRun: true };
  }
  return twilioClient.messages.create({ from: TWILIO_FROM, to, body });
}