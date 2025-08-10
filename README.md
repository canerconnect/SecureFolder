# SecureFolder - Sichere Dateiverwaltung für iOS & Android

Eine moderne mobile App für die sichere Speicherung und Synchronisation von Dateien mit End-to-End-Verschlüsselung, biometrischer Authentifizierung und Cloud-Backup.

## 🚀 Features

### 📱 Mobile App (Flutter)
- **iOS-Style Design** - Modernes, minimalistisches Design im Apple-Stil
- **Biometrische Authentifizierung** - Face ID, Fingerabdruck oder PIN
- **End-to-End-Verschlüsselung** - AES-256 Verschlüsselung für alle Dateien
- **Dateityp-Kategorien** - Fotos, Videos, Dokumente, Notizen, Sprachmemos
- **Cloud-Synchronisation** - Optional aktivierbar mit Firebase Storage
- **Offline-Modus** - Lokale sichere Speicherung auch ohne Internet
- **DSGVO-konform** - Datenschutz nach europäischen Standards

### 🔐 Sicherheitsfeatures
- **AES-256 Verschlüsselung** - Military-grade Sicherheit
- **Sichere Schlüsselverwaltung** - Flutter Secure Storage
- **Biometrische Authentifizierung** - Hardware-basierte Sicherheit
- **Dateiintegritätsprüfung** - SHA-256 Checksummen
- **Sichere Dateinamen** - Verschlüsselte Metadaten

### ☁️ Backend (Node.js + Firebase)
- **RESTful API** - Express.js Server mit Firebase Integration
- **Benutzerauthentifizierung** - Firebase Auth
- **Cloud Storage** - Firebase Storage für verschlüsselte Dateien
- **Firestore Database** - NoSQL Datenbank für Metadaten
- **Rate Limiting** - Schutz vor Missbrauch
- **Logging & Monitoring** - Winston Logger

## 🏗️ Technologie-Stack

### Frontend
- **Flutter** - Cross-platform mobile development
- **Provider** - State Management
- **Firebase SDK** - Authentication, Storage, Firestore
- **Local Auth** - Biometrische Authentifizierung
- **Flutter Secure Storage** - Sichere lokale Speicherung
- **Encrypt** - Verschlüsselungsbibliothek

### Backend
- **Node.js** - Server Runtime
- **Express.js** - Web Framework
- **Firebase Admin SDK** - Server-side Firebase Integration
- **Winston** - Logging
- **Helmet** - Security Headers
- **CORS** - Cross-Origin Resource Sharing

### Database & Storage
- **Firebase Firestore** - NoSQL Datenbank
- **Firebase Storage** - Cloud File Storage
- **Firebase Authentication** - Benutzerauthentifizierung

## 📦 Installation

### Voraussetzungen
- Flutter 3.10+ 
- Node.js 18+
- Firebase CLI
- Android Studio / Xcode

### Flutter App Setup

1. **Dependencies installieren**
```bash
flutter pub get
```

2. **Firebase Konfiguration**
```bash
# Firebase CLI installieren
npm install -g firebase-tools

# Firebase Projekt initialisieren
firebase login
flutterfire configure
```

3. **iOS Setup**
```bash
cd ios
pod install
```

4. **App starten**
```bash
flutter run
```

### Backend Setup

1. **Dependencies installieren**
```bash
cd backend
npm install
```

2. **Umgebungsvariablen**
```bash
cp .env.example .env
# .env mit Firebase Credentials ausfüllen
```

3. **Server starten**
```bash
npm run dev
```

## 🔧 Konfiguration

### Firebase Projekt Setup

1. **Firebase Console** → Neues Projekt erstellen
2. **Authentication** → Email/Password aktivieren
3. **Firestore** → Datenbank erstellen
4. **Storage** → Bucket erstellen
5. **Security Rules** → Regeln aus `firebase/` verwenden

### Umgebungsvariablen

```env
# Backend (.env)
FIREBASE_PRIVATE_KEY_ID=your_private_key_id
FIREBASE_PRIVATE_KEY=your_private_key
FIREBASE_CLIENT_EMAIL=your_client_email
FIREBASE_CLIENT_ID=your_client_id
NODE_ENV=development
PORT=3000
```

## 📱 App Struktur

```
lib/
├── main.dart                 # App Entry Point
├── models/                   # Datenmodelle
│   └── secure_file.dart     # SecureFile Model
├── providers/               # State Management
│   ├── auth_provider.dart   # Authentifizierung
│   ├── file_provider.dart   # Dateiverwaltung
│   └── biometric_provider.dart # Biometrie
├── services/                # Services
│   └── encryption_service.dart # Verschlüsselung
├── screens/                 # UI Screens
│   ├── auth/               # Authentifizierung
│   ├── home/               # Hauptscreens
│   ├── notes/              # Notizen
│   ├── audio/              # Sprachmemos
│   └── settings/           # Einstellungen
└── utils/                  # Utilities
    └── theme.dart          # iOS-Style Theme
```

## 🔒 Sicherheitskonzept

### Verschlüsselung
- **Client-side Encryption** - Dateien werden vor Upload verschlüsselt
- **AES-256-GCM** - Authenticated Encryption
- **Unique Keys** - Jeder Benutzer hat eigenen Verschlüsselungsschlüssel
- **Secure Key Storage** - Keys werden in Secure Enclave/Keystore gespeichert

### Authentifizierung
- **Multi-Factor** - Email/Password + Biometrie/PIN
- **Token-based** - Firebase JWT Tokens
- **Session Management** - Automatische Token-Erneuerung
- **Biometric Fallback** - PIN als Alternative zu Biometrie

### Datenschutz
- **DSGVO-konform** - Europäische Datenschutzstandards
- **Data Minimization** - Nur notwendige Daten werden gespeichert
- **Right to be Forgotten** - Vollständige Datenlöschung möglich
- **Transparent Logging** - Nachvollziehbare Aktionen

## 🚀 Deployment

### Flutter App

**Android:**
```bash
flutter build apk --release
# oder
flutter build appbundle --release
```

**iOS:**
```bash
flutter build ios --release
# Danach in Xcode Archive erstellen
```

### Backend

**Firebase Functions:**
```bash
firebase deploy --only functions
```

**Heroku:**
```bash
git push heroku main
```

## 📊 API Dokumentation

### Authentication
```
POST /api/auth/verify-token
Authorization: Bearer <firebase-token>
```

### Files
```
GET    /api/files          # Dateien auflisten
POST   /api/files          # Datei hochladen
GET    /api/files/:id      # Datei abrufen
DELETE /api/files/:id      # Datei löschen
```

### Users
```
GET    /api/users/profile  # Benutzerprofil
PUT    /api/users/profile  # Profil aktualisieren
DELETE /api/users/account  # Account löschen
```

## 🧪 Testing

### Flutter Tests
```bash
flutter test
```

### Backend Tests
```bash
npm test
```

## 📄 Lizenz

Dieses Projekt ist unter der MIT Lizenz veröffentlicht. Siehe [LICENSE](LICENSE) für Details.

## 🤝 Contributing

1. Fork das Repository
2. Feature Branch erstellen (`git checkout -b feature/amazing-feature`)
3. Änderungen committen (`git commit -m 'Add amazing feature'`)
4. Branch pushen (`git push origin feature/amazing-feature`)
5. Pull Request erstellen

## 📞 Support

Bei Fragen oder Problemen:
- Issue erstellen auf GitHub
- E-Mail an support@securefolder.app
- Dokumentation lesen

## 🔄 Roadmap

- [ ] **v1.1** - Dark Mode Support
- [ ] **v1.2** - Ordner-Organisation
- [ ] **v1.3** - Sharing Features
- [ ] **v1.4** - Backup/Restore
- [ ] **v2.0** - Desktop Apps (Windows/macOS/Linux)

---

**SecureFolder** - Sicher, Privat, Verschlüsselt 🔐