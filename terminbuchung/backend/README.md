# Backend (Express + Sequelize + Postgres)

- Dev start: `npm run dev`
- Env: copy `.env.example` to `.env`
- DB: `docker compose up -d db`

API endpoints (MVP):
- POST `/api/booking`
- GET `/api/slots?kundeId=...&date=YYYY-MM-DD`
- POST `/api/booking/confirm` { booking, token }
- DELETE `/api/booking/:id?token=...`
- POST `/api/login` -> { token }
- GET `/api/bookings` (auth)