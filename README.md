# Online-Terminbuchung (Online Appointment Booking System)

Ein modernes Terminbuchungssystem mit Multi-Tenant-Architektur, das es verschiedenen Anbietern (Ärzte, Anwälte, etc.) ermöglicht, über eigene Subdomains Termine zu verwalten.

## Features

### Endbenutzer (Patienten/Kunden)
- 📅 Kalenderansicht mit verfügbaren Terminen
- 🟢 Freie Termine (grün) und 🔴 gebuchte Termine (rot)
- 📝 Terminbuchung mit Name, E-Mail, Telefon und optionalen Bemerkungen
- 📧 E-Mail-Bestätigung mit Stornierungslink
- 🔔 Konfigurierbare E-Mail- und SMS-Erinnerungen
- ❌ Terminstornierung über sicheren Token-basierten Link

### Anbieter (z.B. Arztpraxis)
- 🔐 Sicheres Admin-Login
- 📊 Dashboard mit Terminübersicht
- ⚙️ Konfigurierbare Arbeitszeiten, Pausen und Pufferzeiten
- 📅 Manuelles Hinzufügen/Bearbeiten/Löschen von Terminen
- 🔄 Echtzeit-Blockierung für gleichzeitige Buchungen
- 📧 E-Mail-Benachrichtigungen bei Stornierungen
- 📊 Statistiken und Berichte

### Technische Features
- 🌐 Multi-Tenant-Architektur mit Subdomains
- 🔒 DSGVO-konform mit EU-Hosting
- 🛡️ TLS-Verschlüsselung (HTTPS)
- 🔐 Sichere Passwort-Hashing (bcrypt)
- 📱 Responsive Design (Mobile First)
- 🎨 Konfigurierbare Farben pro Anbieter

## Technologie-Stack

- **Backend**: Node.js mit Express.js
- **Datenbank**: PostgreSQL
- **Frontend**: React.js (geplant)
- **E-Mail**: Nodemailer
- **SMS**: Twilio
- **Authentifizierung**: JWT
- **Styling**: Tailwind CSS (geplant)

## Installation

### Voraussetzungen

- Node.js >= 18.0.0
- PostgreSQL >= 12
- npm oder yarn

### 1. Repository klonen

```bash
git clone <repository-url>
cd online-terminbuchung
```

### 2. Dependencies installieren

```bash
npm install
```

### 3. Umgebungsvariablen konfigurieren

```bash
cp .env.example .env
```

Bearbeiten Sie die `.env` Datei mit Ihren Konfigurationswerten:

```env
# Datenbank
DB_HOST=localhost
DB_PORT=5432
DB_NAME=terminbuchung
DB_USER=postgres
DB_PASSWORD=ihr-passwort

# JWT
JWT_SECRET=ihr-super-geheimer-jwt-schlüssel

# E-Mail (SMTP)
SMTP_HOST=smtp.gmail.com
SMTP_USER=ihre-email@gmail.com
SMTP_PASS=ihr-app-passwort

# SMS (Twilio)
TWILIO_ACCOUNT_SID=ihre-twilio-sid
TWILIO_AUTH_TOKEN=ihr-twilio-token
TWILIO_PHONE_NUMBER=+49123456789
```

### 4. Datenbank einrichten

```bash
# PostgreSQL-Datenbank erstellen
createdb terminbuchung

# Schema ausführen
psql -d terminbuchung -f db/schema.sql
```

### 5. Anwendung starten

```bash
# Entwicklung
npm run dev

# Produktion
npm start
```

Die Anwendung läuft dann auf `http://localhost:5000`

## Datenbank-Schema

Das System verwendet folgende Haupttabellen:

- **`kunden`**: Anbieter-Informationen (Subdomain, Name, Kontakt)
- **`admin_users`**: Admin-Benutzer für jeden Anbieter
- **`working_hours`**: Konfigurierbare Arbeitszeiten
- **`break_times`**: Konfigurierbare Pausenzeiten
- **`buffer_times`**: Pufferzeiten vor/nach Terminen
- **`appointments`**: Terminbuchungen mit Kundeninformationen
- **`settings`**: Verschiedene Einstellungen pro Anbieter

## API-Endpunkte

### Authentifizierung
- `POST /api/auth/login` - Admin-Login
- `GET /api/auth/me` - Aktueller Benutzer
- `POST /api/auth/change-password` - Passwort ändern

### Terminbuchung
- `POST /api/booking` - Neuen Termin buchen
- `DELETE /api/booking/:id` - Termin stornieren
- `GET /api/booking/:id` - Termindetails abrufen

### Verfügbare Zeiten
- `GET /api/slots` - Verfügbare Zeiten für ein Datum
- `GET /api/slots/working-hours` - Arbeitszeiten
- `GET /api/slots/break-times` - Pausenzeiten

### Admin-Bereich
- `GET /api/admin/dashboard` - Dashboard-Übersicht
- `PUT /api/admin/working-hours` - Arbeitszeiten aktualisieren
- `PUT /api/admin/settings` - Einstellungen aktualisieren
- `GET /api/admin/statistics` - Statistiken abrufen

### Öffentliche Informationen
- `GET /api/kunde/info` - Anbieter-Informationen
- `GET /api/kunde/contact` - Kontaktinformationen
- `GET /api/kunde/business-hours` - Geschäftszeiten

## Subdomain-System

Jeder Anbieter erhält eine eigene Subdomain:
- `arztpraxis.meinetermine.de`
- `anwalt.meinetermine.de`
- `zahnarzt.meinetermine.de`

Das System erkennt automatisch den Anbieter basierend auf der Subdomain und leitet alle Anfragen entsprechend weiter.

## Entwicklung

### Projektstruktur

```
├── config/          # Konfigurationsdateien
├── db/             # Datenbankschema
├── middleware/     # Express-Middleware
├── routes/         # API-Routen
├── services/       # Geschäftslogik
├── client/         # React-Frontend (geplant)
├── server.js       # Hauptserver-Datei
└── package.json    # Dependencies
```

### Neue Features hinzufügen

1. **Route erstellen**: Neue Datei in `routes/` erstellen
2. **Service erstellen**: Geschäftslogik in `services/` implementieren
3. **Middleware hinzufügen**: Authentifizierung/Validierung in `middleware/`
4. **Datenbank-Schema erweitern**: Neue Tabellen in `db/schema.sql`

### Tests ausführen

```bash
# Unit-Tests (geplant)
npm test

# Integration-Tests (geplant)
npm run test:integration
```

## Deployment

### Produktionsumgebung

1. **Umgebungsvariablen setzen**:
   - `NODE_ENV=production`
   - Sichere JWT-Secrets
   - Produktions-Datenbank-Credentials

2. **HTTPS konfigurieren**:
   - SSL-Zertifikat installieren
   - TLS 1.3 aktivieren

3. **Datenbank optimieren**:
   - Indizes für Performance
   - Backup-Strategie implementieren

4. **Monitoring einrichten**:
   - Log-Aggregation
   - Performance-Monitoring
   - Error-Tracking

### Docker (geplant)

```bash
# Docker-Image bauen
docker build -t terminbuchung .

# Container starten
docker run -p 5000:5000 terminbuchung
```

## Sicherheit

### Implementierte Sicherheitsmaßnahmen

- ✅ Helmet.js für HTTP-Header-Sicherheit
- ✅ Rate Limiting für API-Endpunkte
- ✅ JWT-basierte Authentifizierung
- ✅ Bcrypt-Passwort-Hashing
- ✅ Input-Validierung und Sanitization
- ✅ CORS-Konfiguration
- ✅ SQL-Injection-Schutz (Parameterized Queries)

### DSGVO-Compliance

- 🔒 EU-Hosting erforderlich
- 📧 Double-Opt-In für E-Mail-Bestätigungen
- 🗑️ Automatische Datenbereinigung
- 📋 Datenschutzerklärung und AV-Vertrag (vorzubereiten)
- 🔐 Verschlüsselte Datenübertragung

## Lizenz

MIT License - siehe [LICENSE](LICENSE) Datei.

## Support

Bei Fragen oder Problemen:

1. 📖 Dokumentation durchgehen
2. 🐛 GitHub Issues prüfen
3. 💬 Support-Forum besuchen
4. 📧 Support-E-Mail senden

## Roadmap

### Version 1.1
- [ ] React-Frontend implementieren
- [ ] Mobile App (React Native)
- [ ] Google Calendar Integration
- [ ] Outlook Calendar Integration

### Version 1.2
- [ ] Mehrsprachigkeit (EN, FR, IT)
- [ ] Erweiterte Statistiken
- [ ] API-Dokumentation (Swagger)
- [ ] Webhook-System

### Version 2.0
- [ ] Microservices-Architektur
- [ ] Kubernetes-Deployment
- [ ] Machine Learning für Terminoptimierung
- [ ] Chatbot-Integration

---

**Entwickelt mit ❤️ für die deutsche Gesundheitsbranche**