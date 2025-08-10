# SecureFolder (Expo React Native)

- Frontend: Expo React Native
- Backend: Node.js + Express + Firebase Admin
- Cloud: Firebase Auth, Firestore, Storage

## Setup

1. Create a Firebase project and enable Auth (Email/Password), Firestore, and Storage.
2. Create a web app in Firebase and copy config. Set the following in `.env` for Expo (or use `app.json` env):

```
EXPO_PUBLIC_FIREBASE_API_KEY=... 
EXPO_PUBLIC_FIREBASE_AUTH_DOMAIN=...
EXPO_PUBLIC_FIREBASE_PROJECT_ID=...
EXPO_PUBLIC_FIREBASE_STORAGE_BUCKET=...
EXPO_PUBLIC_FIREBASE_MESSAGING_SENDER_ID=...
EXPO_PUBLIC_FIREBASE_APP_ID=...
EXPO_PUBLIC_API_BASE_URL=http://localhost:4000
```

3. Run frontend:

```
npm install
npm run start
```

4. Backend: copy `.env.example` to `.env` and fill values (service account). Then start:

```
cd ../securefolder-backend
npm install
npm run start
```

## Security
- Biometric unlock using LocalAuthentication.
- AES-256 client-side encryption for metadata and notes. Server-side optional AES-256-GCM for files.
- Auth via Firebase ID tokens; Storage and Firestore documents names do not contain plaintext user data.
- For GDPR: provide data export/delete endpoints (not implemented here), minimize data, and document processing.