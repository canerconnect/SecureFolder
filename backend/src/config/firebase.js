const admin = require('firebase-admin');

// Firebase Admin SDK Initialisierung
const serviceAccount = {
  type: "service_account",
  project_id: process.env.FIREBASE_PROJECT_ID,
  private_key_id: process.env.FIREBASE_PRIVATE_KEY_ID,
  private_key: process.env.FIREBASE_PRIVATE_KEY.replace(/\\n/g, '\n'),
  client_email: process.env.FIREBASE_CLIENT_EMAIL,
  client_id: process.env.FIREBASE_CLIENT_ID,
  auth_uri: process.env.FIREBASE_AUTH_URI,
  token_uri: process.env.FIREBASE_TOKEN_URI,
  auth_provider_x509_cert_url: process.env.FIREBASE_AUTH_PROVIDER_X509_CERT_URL,
  client_x509_cert_url: process.env.FIREBASE_CLIENT_X509_CERT_URL
};

// Firebase Admin initialisieren
if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
    storageBucket: `${process.env.FIREBASE_PROJECT_ID}.appspot.com`,
    databaseURL: `https://${process.env.FIREBASE_PROJECT_ID}-default-rtdb.europe-west1.firebasedatabase.app`
  });
}

// Firebase Services exportieren
const auth = admin.auth();
const firestore = admin.firestore();
const storage = admin.storage();
const bucket = storage.bucket();

// Firestore Einstellungen
firestore.settings({
  ignoreUndefinedProperties: true,
  timestampsInSnapshots: true
});

module.exports = {
  admin,
  auth,
  firestore,
  storage,
  bucket
};