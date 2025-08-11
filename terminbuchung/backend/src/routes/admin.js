import express from 'express';
import bcrypt from 'bcrypt';
import { z } from 'zod';
import { signJwt, requireAuth } from '../middleware/auth.js';
import { User } from '../models/User.js';
import { Booking } from '../models/Booking.js';
import { Op } from 'sequelize';

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
  const schema = z.object({ kundeId: z.string().uuid().optional(), from: z.string().optional(), to: z.string().optional() });
  const parsed = schema.safeParse(req.query);
  if (!parsed.success) return res.status(400).json({ error: 'Invalid query' });
  const { kundeId, from, to } = parsed.data;
  const providerId = kundeId || req.user.providerId;
  const where = { providerId };
  if (from || to) {
    where.startTime = {};
    if (from) where.startTime[Op.gte] = new Date(from);
    if (to) where.startTime[Op.lte] = new Date(to);
  }
  const bookings = await Booking.findAll({ where, order: [['startTime', 'ASC']] });
  res.json({ bookings });
});

export default router;