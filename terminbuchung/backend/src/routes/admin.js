import express from 'express';
import bcrypt from 'bcrypt';
import { z } from 'zod';
import { signJwt, requireAuth } from '../middleware/auth.js';
import { User } from '../models/User.js';
import { Booking } from '../models/Booking.js';
import { Provider } from '../models/Provider.js';
import { Op } from 'sequelize';
import dayjs from 'dayjs';

const router = express.Router();

router.post('/login', async (req, res) => {
  const schema = z.object({ username: z.string(), password: z.string() });
  const parsed = schema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ error: 'Invalid body' });
  const { username, password } = parsed.data;

  const user = await User.findOne({ where: { username } });
  if (!user) return res.status(401).json({ error: 'Invalid credentials' });
  const ok = await bcrypt.compare(password, user.passwordHash);
  if (!ok) return res.status(401).json({ error: 'Invalid credentials' });

  const token = signJwt({ userId: user.id, providerId: user.providerId, username: user.username });
  res.json({ token });
});

router.get('/bookings', requireAuth, async (req, res) => {
  const schema = z.object({ kundeId: z.string().uuid().optional(), from: z.string().optional(), to: z.string().optional(), status: z.enum(['pending','confirmed','canceled']).optional() });
  const parsed = schema.safeParse(req.query);
  if (!parsed.success) return res.status(400).json({ error: 'Invalid query' });
  const { kundeId, from, to, status } = parsed.data;
  const providerId = kundeId || req.user.providerId;
  const where = { providerId };
  if (from || to) {
    where.startTime = {};
    if (from) where.startTime[Op.gte] = new Date(from);
    if (to) where.startTime[Op.lte] = new Date(to);
  }
  if (status) where.status = status;
  const bookings = await Booking.findAll({ where, order: [['startTime', 'ASC']] });
  res.json({ bookings });
});

// Admin create manual booking
router.post('/bookings', requireAuth, async (req, res) => {
  const schema = z.object({ name: z.string().min(2), email: z.string().email(), phone: z.string().optional(), startTime: z.string(), durationMinutes: z.number().int().positive(), comment: z.string().optional() });
  const parsed = schema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ error: 'Invalid body' });
  const { name, email, phone, startTime, durationMinutes, comment } = parsed.data;
  const providerId = req.user.providerId;
  const start = dayjs(startTime);
  const end = start.add(durationMinutes, 'minute');
  try {
    const booking = await Booking.create({ providerId, name, email, phone: phone || null, startTime: start.toDate(), endTime: end.toDate(), comment: comment || null, status: 'confirmed', confirmedAt: new Date() });
    res.status(201).json({ booking });
  } catch (err) {
    if (err?.name === 'SequelizeUniqueConstraintError') return res.status(409).json({ error: 'Slot bereits belegt' });
    console.error(err);
    res.status(500).json({ error: 'Server error' });
  }
});

// Admin edit booking
router.patch('/bookings/:id', requireAuth, async (req, res) => {
  const schema = z.object({ name: z.string().min(2).optional(), email: z.string().email().optional(), phone: z.string().optional(), startTime: z.string().optional(), endTime: z.string().optional(), comment: z.string().optional(), status: z.enum(['pending','confirmed','canceled']).optional() });
  const parsed = schema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ error: 'Invalid body' });
  const booking = await Booking.findByPk(req.params.id);
  if (!booking || booking.providerId !== req.user.providerId) return res.status(404).json({ error: 'Not found' });
  Object.assign(booking, parsed.data);
  await booking.save();
  res.json({ booking });
});

// Admin delete booking
router.delete('/bookings/:id', requireAuth, async (req, res) => {
  const booking = await Booking.findByPk(req.params.id);
  if (!booking || booking.providerId !== req.user.providerId) return res.status(404).json({ error: 'Not found' });
  await booking.destroy();
  res.json({ ok: true });
});

// Provider settings
router.get('/settings', requireAuth, async (req, res) => {
  const provider = await Provider.findByPk(req.user.providerId);
  const { id, name, subdomain, color_primary, settings } = provider;
  res.json({ id, name, subdomain, color_primary, settings });
});

router.put('/settings', requireAuth, async (req, res) => {
  const schema = z.object({
    name: z.string().min(2).optional(),
    color_primary: z.string().optional(),
    settings: z.object({
      slotDurationMinutes: z.number().int().positive().max(480).optional(),
      bufferMinutes: z.number().int().min(0).max(120).optional(),
      workingHours: z.record(z.string(), z.array(z.tuple([z.string(), z.string()]))).optional(),
      reminders: z.object({ enabled: z.boolean(), hoursBefore: z.number().int().min(1).max(168), via: z.array(z.enum(['email','sms'])) }).optional(),
      cancellationDeadlineHours: z.number().int().min(0).max(168).optional(),
    }).partial().optional(),
  }).partial();
  const parsed = schema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ error: 'Invalid body' });
  const provider = await Provider.findByPk(req.user.providerId);
  if (parsed.data.name) provider.name = parsed.data.name;
  if (parsed.data.color_primary) provider.color_primary = parsed.data.color_primary;
  if (parsed.data.settings) provider.settings = { ...provider.settings, ...parsed.data.settings };
  await provider.save();
  res.json({ ok: true });
});

export default router;