# ResQMitra backend (Neon PostgreSQL + Node API)

```
Phone app ──HTTPS──▶  API (backend/server.js, hosted on Render)  ──▶  Neon PostgreSQL
                       • accounts & JWT login                          • users, contacts
                       • SOS create / stages / cancel                  • sos, sos_events
                       • photo, voice-note & ID storage                • files (bytea)
                       • badges / ratings                              • appreciations
```
**Never put the Neon connection string inside the app.** An APK can be unpacked; the phone talks only to the API.

## 1 · Create the database (Neon)
1. https://neon.tech → sign up → **Create project** (region: *Singapore* – closest to India / Andaman).
2. On the project dashboard click **Connect**, tick **Connection pooling**, copy the string
   `postgresql://…-pooler….neon.tech/neondb?sslmode=require` – this is your `DATABASE_URL`.
3. Open **SQL Editor**, paste the whole of `backend/schema.sql`, press **Run** (NOT *Explain* – EXPLAIN cannot be used on CREATE TABLE and causes `syntax error at or near "uuid"`).
   (or from your PC: `cd backend && npm install && cp .env.example .env`, edit `.env`, `npm run migrate`)

## 2 · Test the API on your PC (optional)
```bash
cd backend
npm install
cp .env.example .env      # paste DATABASE_URL, set JWT_SECRET (see comment inside)
npm run dev               # → http://localhost:8080/health   must answer {"ok":true}
```

## 3 · Deploy the API (Render – free)
1. Push this repo to GitHub (already done).
2. https://render.com → **New + → Web Service** → connect the repo.
   * Root Directory: `backend`  · Build: `npm install`  · Start: `npm start`  · Health check path: `/health`
   * (or **New + → Blueprint** and Render reads `render.yaml`)
3. **Environment** → add `DATABASE_URL` (Neon string) and `JWT_SECRET` (long random text).
   * **Do NOT add a `PORT` variable** – Render sets it for you. A blank `PORT` used to crash the server
     (`ERR_SOCKET_BAD_PORT`); the server now ignores blank/invalid values, but leaving it out is cleanest.
4. Deploy. You get a URL like `https://resqmitra-api.onrender.com`; open `/health` to check.

> Render's free plan sleeps after 15 min idle (first request ≈ 30–50 s). For an emergency app use a paid
> always-on instance (≈ $7/mo) or Railway / Fly.io / Koyeb, or ping `/health` every 10 min with a free monitor (UptimeRobot).

## 4 · Connect the app
GitHub repo → **Settings → Secrets and variables → Actions → New repository secret**
`API_BASE` = `https://resqmitra-api.onrender.com` (no trailing slash). Run the workflow again –
the APK is built with `--dart-define=API_BASE=…`. With the secret empty the app works exactly as before (local only).

## What now works across phones
| Feature | How |
|---|---|
| Registration, role switch, profile edits, photo & ID upload | `POST /auth/register`, `PUT /me/profile`, `POST /files` |
| Help seeker sends SOS | `POST /sos` (retried 6×), photo/voice uploaded afterwards |
| Online responders get the siren pop-up | app polls `GET /sos/nearby` every 5 s (50 km radius) |
| Accept / on the way / arrived / provided | `PATCH /sos/:id/stage` – seeker's phone follows it live |
| I AM SAFE | `POST /sos/:id/cancel` |
| Badge + rating + message to the responder | `POST /appreciations` → responder phone collects it → glowing reveal |
| Profile stats, badges, reviews, history | `GET /me/summary` (restored after reinstall *with the same account token*) |

## Limits you should know / next steps
* **Push when the app is closed** needs Firebase Cloud Messaging (FCM): add a `push_tokens` table, send from the
  `POST /sos` handler to nearby responders. Until then responders must have the app open and *Online*.
* **Login after reinstall / new phone**: accounts are created per install (JWT token kept on the phone). Add real
  phone-OTP (Firebase Phone Auth, MSG91, Twilio Verify) at `/auth/register` (marked `TODO(otp)`).
* **Files** are stored in Postgres (`files.data`) – fine up to a few thousand images. Neon free = 0.5 GB. To scale,
  upload to Cloudflare R2 / S3 and store only the URL (change `/files` handlers only).
* ID documents are readable **only by their owner** (`GET /files/:id` checks it). Add encryption + a retention
  policy before real-world launch (India DPDP Act 2023: collect only what you need, allow deletion).
* Two responders can accept the same SOS: the first wins, the second gets `409 already_assigned`.

## API cheat-sheet (all JSON, header `Authorization: Bearer <token>` except register/health)
`POST /auth/register` · `GET /me` · `PUT /me/profile` · `PUT /me/presence` · `GET /me/summary` · `GET /me/appreciations`
`POST /files?kind=photo|id_doc|sos_photo|sos_audio` (raw bytes, `Content-Type: image/jpeg`) · `GET /files/:id`
`POST /sos` · `PATCH /sos/:id/files` · `GET /sos/nearby?lat&lng&radius_km` · `GET /sos/:id` · `PATCH /sos/:id/stage` · `POST /sos/:id/cancel`
`POST /appreciations` · `GET /health`

## 5 · Configure S3-compatible object storage
The API now supports Neon-compatible S3 object storage through the AWS SDK. In the object-storage dashboard, create a bucket and generate an access key/secret scoped to that bucket. Add these environment variables to the backend service (Render → Environment):

- `S3_ENDPOINT`: the exact S3-compatible endpoint shown by your storage provider (not the Neon SQL connection string).
- `S3_REGION`: the region shown by the provider, or `auto` if the provider specifies it.
- `S3_BUCKET`: bucket name, e.g. `assets`.
- `S3_ACCESS_KEY_ID`: access key ID.
- `S3_SECRET_ACCESS_KEY`: secret access key.

Do not paste these secrets into Flutter, GitHub source, screenshots or public chat. Keep the bucket private. The API streams files back only after authentication and enforces owner-only access for `id_doc`. If the S3 settings are absent, file uploads continue to use PostgreSQL as a backward-compatible fallback.

**Existing database migration:** run the following once in the Neon SQL Editor before deploying this version:

```sql
ALTER TABLE files ADD COLUMN IF NOT EXISTS storage_key text;
ALTER TABLE files ALTER COLUMN data SET DEFAULT ''::bytea;
```

Then redeploy the API. New files use object storage only when all three credentials and the endpoint are configured. Existing files remain in PostgreSQL; this migration does not automatically copy them to the bucket.

## Project deliverables
- Setup and environment variable instructions: this README and `.env.example`.
- Architecture and trust-boundary notes: `docs/TECHNICAL_DESIGN.md`.
- Sample test plan: `samples/test-cases.md`.
- License: repository-root `LICENSE`.
