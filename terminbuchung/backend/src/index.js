import 'dotenv/config';
import express from 'express';
import cors from 'cors';
import { sequelize } from './lib/db.js';
import { initModels } from './models/index.js';
import publicRouter from './routes/public.js';
import adminRouter from './routes/admin.js';
import dayjs from 'dayjs';
import { Booking } from './models/Booking.js';
import { Provider } from './models/Provider.js';
import { sendEmail } from './services/email.js';

const app = express();
app.use(cors());
app.use(express.json());

app.get('/health', (_req, res) => {
  res.json({ ok: true });
});

app.use('/api', publicRouter);
app.use('/api', adminRouter);

const port = process.env.PORT || 4000;

async function runReminderSweep() {
  const now = dayjs();
  const horizon = now.add(36, 'hour');
  const upcoming = await Booking.findAll({ where: { status: 'confirmed', reminderSentAt: null } });
  for (const b of upcoming) {
    const provider = await Provider.findByPk(b.providerId);
    const remCfg = provider.settings?.reminders || { enabled: false };
    if (!remCfg.enabled) continue;
    const hoursBefore = remCfg.hoursBefore ?? 24;
    const whenToSend = dayjs(b.startTime).subtract(hoursBefore, 'hour');
    if (whenToSend.isBefore(now) && dayjs(b.startTime).isBefore(horizon)) {
      try {
        if (remCfg.via?.includes('email')) {
          await sendEmail({ to: b.email, subject: 'Erinnerung: Termin', html: `<p>Hallo ${b.name},<br/>Erinnerung an Ihren Termin am ${dayjs(b.startTime).format('DD.MM.YYYY')} um ${dayjs(b.startTime).format('HH:mm')}.</p>` });
        }
        // SMS optional: use sendSms if configured
        b.reminderSentAt = new Date();
        await b.save();
      } catch (e) {
        console.error('Reminder error', e);
      }
    }
  }
}

async function start() {
  try {
    await sequelize.authenticate();
    initModels();
    await sequelize.sync();
    app.listen(port, () => {
      console.log(`Backend listening on http://localhost:${port}`);
    });
    // Run reminder sweep every 15 minutes
    setInterval(() => {
      runReminderSweep().catch((e) => console.error(e));
    }, 15 * 60 * 1000);
  } catch (error) {
    console.error('Failed to start server', error);
    process.exit(1);
  }
}

start();