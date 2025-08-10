import admin from 'firebase-admin';

let initialized = false;

export const ensureAdmin = async () => {
  if (initialized) return;
  const credsJson = process.env.GOOGLE_APPLICATION_CREDENTIALS_JSON;
  if (credsJson) {
    const serviceAccount = JSON.parse(Buffer.from(credsJson, 'base64').toString('utf8'));
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
      storageBucket: process.env.FIREBASE_STORAGE_BUCKET
    });
  } else {
    admin.initializeApp({ storageBucket: process.env.FIREBASE_STORAGE_BUCKET });
  }
  initialized = true;
};

export const bucket = () => admin.storage().bucket();
export const db = admin.firestore();