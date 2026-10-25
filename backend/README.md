# RESQ-MITRA backend starter (Neon PostgreSQL + Node.js API)

This is a backend starter scaffold, not a deployed service. You must create your Neon project, run the SQL, configure secrets and connect a trusted authentication issuer before production use.

## 1. Neon database
1. Create a Neon project and database in the Neon Console.
2. Open SQL Editor and run `sql/schema.sql`, then `sql/badges.sql`.
3. Copy the pooled PostgreSQL connection string from Connect. Keep it only in backend environment variables.

## 2. Run API locally
Requires Node.js 20+. Copy `.env.example` to `.env`, fill in `DATABASE_URL` and a random `JWT_SECRET` (32+ chars), then:

```bash
npm install
npm start
```

Check `GET /health`. Do not commit `.env`.

## 3. Authentication (required)
Protected routes accept a JWT signed with HS256, issuer `resqmitra-api`, and a `sub` claim matching `profiles.auth_subject`. **This starter does not issue login tokens.** Configure a trusted auth provider or implement a secure server-side login/token exchange before using protected routes. Never hard-code a shared signing secret in Flutter or let the mobile app mint its own token. Demo OTP `123456` in the current Flutter app is not real verification.

## 4. Deploy
Deploy this `backend/` directory to a Node.js host that supports HTTPS and environment variables. Add `DATABASE_URL`, `JWT_SECRET`, and optional object-storage credentials as platform secrets. Restrict CORS to your real app/web origins. Do not expose database or storage credentials to the client.

## 5. API routes included
- `GET /health`
- `GET /profile/me` (JWT required)
- `POST /sos` (JWT required; persists SOS + status history)
- `GET /sos/mine` (JWT required)
- `POST /sos/:id/cancel` (JWT required; owner-only)
- `POST /sos/:id/accept` (JWT required; verified and available responders only)
- `POST /uploads/presign` (JWT required; optional S3-compatible private object storage)

## Important gaps before a live emergency launch
- No token issuance/auth provider integration is included.
- Push notifications, background realtime delivery, SMS/OTP provider, proximity matching, responder escalation and upload completion/metadata registration still need integration and end-to-end tests.
- The current Flutter app stores profiles, contacts, badges and alert streams locally in SharedPreferences/in-memory. This ZIP adds backend foundations but does not silently replace those local flows. Connect `lib/services.dart` to the deployed API only after auth is in place.
- Review privacy, retention, legal, security, rate limiting, backups, monitoring, and emergency fallback requirements before production.
