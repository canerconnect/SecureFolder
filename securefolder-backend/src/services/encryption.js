import crypto from 'crypto';
import { Transform } from 'stream';

const isEnabled = () => process.env.ENCRYPTION_ENABLED === '1' && process.env.ENCRYPTION_SECRET_KEY;

const getKey = () => {
  const keyHex = process.env.ENCRYPTION_SECRET_KEY || '';
  return Buffer.from(keyHex.padEnd(64, '0').slice(0, 64), 'hex');
};

export const encryptBufferIfEnabled = async (buffer) => {
  if (!isEnabled()) return { data: buffer };
  const iv = crypto.randomBytes(12);
  const cipher = crypto.createCipheriv('aes-256-gcm', getKey(), iv);
  const enc = Buffer.concat([cipher.update(buffer), cipher.final()]);
  const tag = cipher.getAuthTag();
  return { data: Buffer.concat([iv, tag, enc]), iv: iv.toString('hex'), tag: tag.toString('hex') };
};

export const decryptStreamIfEnabled = (readable, ivHex, tagHex) => {
  if (!isEnabled()) return readable;
  const iv = Buffer.from(ivHex, 'hex');
  const tag = Buffer.from(tagHex, 'hex');
  let headerSent = false;
  const chunks = [];
  const pass = new Transform({
    transform(chunk, _enc, cb) {
      chunks.push(chunk);
      cb();
    },
    flush(cb) {
      const data = Buffer.concat(chunks);
      // our upload concatenated [iv, tag, enc]; when using stream path, we stored iv/tag in metadata and data is just enc
      const decipher = crypto.createDecipheriv('aes-256-gcm', getKey(), iv);
      decipher.setAuthTag(tag);
      const dec = Buffer.concat([decipher.update(data), decipher.final()]);
      this.push(dec);
      cb();
    }
  });
  readable.pipe(pass);
  return pass;
};