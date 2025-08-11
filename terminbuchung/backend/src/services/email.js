import sgMail from '@sendgrid/mail';

const { SENDGRID_API_KEY } = process.env;
if (SENDGRID_API_KEY) {
  sgMail.setApiKey(SENDGRID_API_KEY);
}

export async function sendEmail({ to, subject, html }) {
  if (!SENDGRID_API_KEY) {
    console.log('[email] (dry-run) to=%s subject=%s', to, subject);
    return { dryRun: true };
  }
  const msg = { to, from: process.env.MAIL_FROM || 'noreply@meinetermine.de', subject, html };
  const resp = await sgMail.send(msg);
  return resp;
}