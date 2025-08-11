import 'dotenv/config';
import express from 'express';
import cors from 'cors';
import { sequelize } from './lib/db.js';
import { initModels } from './models/index.js';
import publicRouter from './routes/public.js';
import adminRouter from './routes/admin.js';

const app = express();
app.use(cors());
app.use(express.json());

app.get('/health', (_req, res) => {
  res.json({ ok: true });
});

app.use('/api', publicRouter);
app.use('/api', adminRouter);

const port = process.env.PORT || 4000;

async function start() {
  try {
    await sequelize.authenticate();
    initModels();
    // In MVP, sync models automatically
    await sequelize.sync();
    app.listen(port, () => {
      console.log(`Backend listening on http://localhost:${port}`);
    });
  } catch (error) {
    console.error('Failed to start server', error);
    process.exit(1);
  }
}

start();