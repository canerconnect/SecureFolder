# SecureFolder - Sichere Datei-App

Eine mobile App für iOS und Android, die es ermöglicht, Bilder, Videos, Notizen und Sprachmemos sicher in einem geschützten Bereich zu speichern und mit der Cloud zu synchronisieren.

## 🚀 Features

- **Sicherheit**: Biometrie (Face ID, Fingerabdruck, PIN) + Verschlüsselung
- **Dateitypen**: Fotos, Videos, Notizen, Sprachmemos
- **Speicher**: Lokaler sicherer Bereich + Cloud-Synchronisation
- **Design**: Minimalistisches iOS-ähnliches Design
- **DSGVO-konform**: Vollständige Datenschutz-Compliance

## 🛠️ Technologie-Stack

### Frontend
- **Flutter** - Cross-platform mobile development
- **Biometric Storage** - Sichere lokale Speicherung
- **Encryption** - AES-256 Verschlüsselung

### Backend
- **Node.js + Express** - REST API
- **Firebase Auth** - Authentifizierung
- **Firebase Storage** - Cloud-Speicher
- **Firebase Firestore** - Datenbank
- **JWT** - Session-Management

## 📱 Screenshots

Die App verfügt über:
- Login/Registrierung
- Hauptbildschirm mit Datei-Kategorien
- Sicheren Ordner mit Biometrie
- Upload-Funktionalität
- Cloud-Synchronisation

## 🚀 Installation

### Voraussetzungen
- Flutter SDK (3.0+)
- Node.js (18+)
- Firebase-Projekt
- Android Studio / Xcode

### Frontend Setup
```bash
cd frontend
flutter pub get
flutter run
```

### Backend Setup
```bash
cd backend
npm install
npm run dev
```

## 🔐 Sicherheit

- AES-256 Verschlüsselung für alle Dateien
- Biometrische Authentifizierung
- Sichere JWT-Token
- DSGVO-konforme Datenspeicherung

## 📄 Lizenz

MIT License
