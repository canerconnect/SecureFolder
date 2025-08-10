import admin from 'firebase-admin';

export const authMiddleware = async (req, res, next) => {
  try {
    const auth = req.headers.authorization || '';
    const token = auth.startsWith('Bearer ') ? auth.slice(7) : null;
    if (!token) return res.status(401).json({ error: 'missing_token' });
    const decoded = await admin.auth().verifyIdToken(token);
    req.user = { uid: decoded.uid };
    next();
  } catch (e) {
    return res.status(401).json({ error: 'invalid_token' });
  }
};

export const getUidFromRequest = (req) => req.user?.uid;