# SecureFolder Backend (Express)

- Auth: Firebase ID token via `Authorization: Bearer <token>`
- Storage: Firebase Storage bucket
- DB: Firestore (`users/{uid}/files`)

## .env

Copy `.env.example` to `.env` and fill values.

## Run

```
npm install
npm run start
```

## Routes
- GET `/health` -> `{ ok: true }`
- GET `/files` -> list user files
- POST `/upload` (multipart/form-data): fields `type` (image|video|audio|note), `file` or `text` for notes
- GET `/files/:id/download` -> stream file
- DELETE `/files/:id` -> delete