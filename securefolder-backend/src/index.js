import 'dotenv/config';
import express from 'express';
import cors from 'cors';
import morgan from 'morgan';
import multer from 'multer';
import { v4 as uuidv4 } from 'uuid';
import { authMiddleware, getUidFromRequest } from './middleware/auth.js';
import { ensureAdmin, bucket, db } from './services/firebaseAdmin.js';
import { encryptBufferIfEnabled, decryptStreamIfEnabled } from './services/encryption.js';
import { Readable } from 'node:stream';

await ensureAdmin();

const app = express();
app.use(cors());
app.use(express.json());
app.use(morgan('dev'));

app.get('/health', (req, res) => res.json({ ok: true }));

const upload = multer({ storage: multer.memoryStorage(), limits: { fileSize: 1024 * 1024 * 128 } });

app.get('/files', authMiddleware, async (req, res) => {
  const uid = getUidFromRequest(req);
  const snap = await db.collection('users').doc(uid).collection('files').orderBy('createdAt', 'desc').get();
  const items = snap.docs.map(d => ({ id: d.id, ...d.data() }));
  res.json({ items });
});

app.post('/upload', authMiddleware, upload.single('file'), async (req, res, next) => {
  try {
    const uid = getUidFromRequest(req);
    const { type } = req.body; // image|video|audio|note
    if (!req.file && type !== 'note') return res.status(400).json({ error: 'file required' });

    let objectName = `users/${uid}/${uuidv4()}`;
    let sizeBytes = 0;

    if (type === 'note') {
      // optional: encrypt server-side text
      const buffer = Buffer.from(req.body.text || '', 'utf8');
      const enc = await encryptBufferIfEnabled(buffer);
      await bucket().file(objectName + '.note').save(enc.data, { metadata: { contentType: 'application/octet-stream', metadata: { iv: enc.iv ?? '', tag: enc.tag ?? '' } } });
      sizeBytes = enc.data.length;
      objectName += '.note';
    } else {
      const enc = await encryptBufferIfEnabled(req.file.buffer);
      await bucket().file(objectName).save(enc.data, { metadata: { contentType: req.file.mimetype, metadata: { iv: enc.iv ?? '', tag: enc.tag ?? '' } } });
      sizeBytes = enc.data.length;
    }

    const meta = {
      type,
      objectName,
      sizeBytes,
      createdAt: Date.now(),
      encrypted: process.env.ENCRYPTION_ENABLED === '1'
    };

    const ref = await db.collection('users').doc(uid).collection('files').add(meta);
    res.json({ id: ref.id, ...meta });
  } catch (e) {
    next(e);
  }
});

app.delete('/files/:id', authMiddleware, async (req, res, next) => {
  try {
    const uid = getUidFromRequest(req);
    const docRef = db.collection('users').doc(uid).collection('files').doc(req.params.id);
    const doc = await docRef.get();
    if (!doc.exists) return res.status(404).json({ error: 'not found' });
    const { objectName } = doc.data();
    await bucket().file(objectName).delete({ ignoreNotFound: true });
    await docRef.delete();
    res.json({ ok: true });
  } catch (e) {
    next(e);
  }
});

app.get('/files/:id/download', authMiddleware, async (req, res, next) => {
  try {
    const uid = getUidFromRequest(req);
    const docRef = db.collection('users').doc(uid).collection('files').doc(req.params.id);
    const d = await docRef.get();
    if (!d.exists) return res.status(404).json({ error: 'not found' });
    const { objectName } = d.data();
    const file = bucket().file(objectName);
    const [exists] = await file.exists();
    if (!exists) return res.status(404).json({ error: 'file missing' });

    const [meta] = await file.getMetadata();
    const stream = file.createReadStream();
    res.setHeader('Content-Type', meta.contentType || 'application/octet-stream');

    if (process.env.ENCRYPTION_ENABLED === '1') {
      const iv = meta.metadata?.iv;
      const tag = meta.metadata?.tag;
      if (!iv || !tag) return res.status(500).json({ error: 'missing encryption metadata' });
      decryptStreamIfEnabled(stream, iv, tag).pipe(res);
    } else {
      stream.pipe(res);
    }
  } catch (e) {
    next(e);
  }
});

app.use((err, req, res, next) => {
  console.error(err);
  res.status(500).json({ error: 'server_error', detail: err.message });
});

const port = process.env.PORT || 4000;
app.listen(port, () => console.log(`SecureFolder backend running on :${port}`));