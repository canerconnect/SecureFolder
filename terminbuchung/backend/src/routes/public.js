import express from 'express';
import { z } from 'zod';
import dayjs from 'dayjs';
import { Provider } from '../models/Provider.js';
import { Booking } from '../models/Booking.js';
import { generateSlotsForDate } from '../utils/slots.js';
import { sendEmail } from '../services/email.js';

const router = express.Router();

const bookingBodySchema = z.object({
  kundeId: z.string().uuid(),
  name: z.string().min(2),
  email: z.string().email(),
  telefon: z.string().optional(),
  datum: z.string().regex(/^\d{4}-\d{2}-\d{2}$/),
  uhrzeit: z.string().regex(/^\d{2}:\d{2}$/),
  bemerkung: z.string().optional(),
});

router.get('/slots', async (req, res) => {
  const schema = z.object({ kundeId: z.string().uuid(), date: z.string().regex(/^\d{4}-\d{2}-\d{2}$/) });
  const parsed = schema.safeParse(req.query);
  if (!parsed.success) return res.status(400).json({ error: 'Invalid params' });
  const { kundeId, date } = parsed.data;
  const provider = await Provider.findByPk(kundeId);
  if (!provider) return res.status(404).json({ error: 'Provider not found' });

  const dayStart = dayjs(date).startOf('day').toDate();
  const dayEnd = dayjs(date).endOf('day').toDate();
  const bookings = await Booking.findAll({
    where: { providerId: provider.id, startTime: { $gte: dayStart }, endTime: { $lte: dayEnd } },
    // sequelize v6 needs Op
  });
  // Fix Op usage
  const { Op } = await import('sequelize');
  const bookingsFixed = await Booking.findAll({
    where: { providerId: provider.id, startTime: { [Op.gte]: dayStart }, endTime: { [Op.lte]: dayEnd } },
    order: [['startTime', 'ASC']],
  });

  const slots = generateSlotsForDate(provider.settings, date, bookingsFixed.map((b) => b.toJSON()));
  res.json({ slots });
});

router.post('/booking', async (req, res) => {
  const parsed = bookingBodySchema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ error: 'Invalid body' });
  const { kundeId, name, email, telefon, datum, uhrzeit, bemerkung } = parsed.data;

  const provider = await Provider.findByPk(kundeId);
  if (!provider) return res.status(404).json({ error: 'Provider not found' });

  const start = dayjs(`${datum}T${uhrzeit}`);
  const end = start.add(provider.settings?.slotDurationMinutes || 30, 'minute');

  try {
    const booking = await Booking.create({
      providerId: provider.id,
      name,
      email,
      phone: telefon || null,
      startTime: start.toDate(),
      endTime: end.toDate(),
      comment: bemerkung || null,
      status: 'pending',
    });

    // Send confirmation email with token link (double opt-in)
    const baseUrl = process.env.PUBLIC_BASE_URL || 'http://localhost:5173';
    const confirmLink = `${baseUrl}/confirm?booking=${booking.id}&token=${booking.confirmationToken}`;
    const cancelLink = `${baseUrl}/cancel?booking=${booking.id}&token=${booking.cancellationToken}`;

    const subject = 'Terminbestätigung';
    const html = `<p>Hallo ${name},<br/>Ihr Termin am ${datum} um ${uhrzeit} wurde vorgemerkt.<br/>Bitte bestätigen Sie Ihre Buchung:<br/><a href='${confirmLink}'>Buchung bestätigen</a><br/><br/>Oder stornieren: <a href='${cancelLink}'>Termin stornieren</a></p>`;
    await sendEmail({ to: email, subject, html });

    res.status(201).json({ id: booking.id });
  } catch (err) {
    if (err?.name === 'SequelizeUniqueConstraintError') {
      return res.status(409).json({ error: 'Slot bereits belegt' });
    }
    console.error(err);
    return res.status(500).json({ error: 'Server error' });
  }
});

router.post('/booking/confirm', async (req, res) => {
  const schema = z.object({ booking: z.string().uuid(), token: z.string().uuid() });
  const parsed = schema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ error: 'Invalid body' });
  const { booking: bookingId, token } = parsed.data;
  const b = await Booking.findByPk(bookingId);
  if (!b || b.status === 'canceled') return res.status(404).json({ error: 'Not found' });
  if (b.confirmationToken !== token) return res.status(403).json({ error: 'Invalid token' });
  b.status = 'confirmed';
  b.confirmedAt = new Date();
  await b.save();
  res.json({ ok: true });
});

router.delete('/booking/:id', async (req, res) => {
  const id = req.params.id;
  const schema = z.object({ token: z.string().uuid() });
  const parsed = schema.safeParse(req.query);
  if (!parsed.success) return res.status(400).json({ error: 'Invalid token' });
  const { token } = parsed.data;
  const booking = await Booking.findByPk(id);
  if (!booking) return res.status(404).json({ error: 'Not found' });
  if (booking.cancellationToken !== token) return res.status(403).json({ error: 'Invalid token' });
  booking.status = 'canceled';
  booking.canceledAt = new Date();
  await booking.save();
  res.json({ ok: true });
});

export default router;