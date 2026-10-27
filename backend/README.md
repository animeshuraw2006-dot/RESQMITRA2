# 🧩 RESQ-MITRA Backend Setup

This folder contains the Node.js/Express API and PostgreSQL schema used for shared accounts, SOS requests, rescue stages, appreciation records, and optional file storage.

## Architecture

- **Node.js + Express** API (`server.js`)
- **Neon PostgreSQL** database (`schema.sql`)
- **Renflair** for SMS OTP delivery (the API key stays on the server)
- Optional **S3-compatible object storage** for photos and voice notes
- **Render-compatible** web-service deployment

## Prerequisites

- Node.js 18+ (Node.js 20+ recommended)
- A Neon PostgreSQL project
- A Renflair account and API key for live SMS verification
- Optional S3-compatible storage credentials

## 1. Configure Neon

1. Open your Neon project and select **Connect**.
2. Copy the PostgreSQL connection string. Use the pooled connection string where appropriate and keep `sslmode=require`.
3. Store it in a local `backend/.env` file as `DATABASE_URL`. Do not commit this file.
4. Generate a strong JWT secret:
   ```bash
   node -e "console.log(require('crypto').randomBytes(48).toString('hex'))"
   ```
5. Add your Renflair key:
   ```dotenv
   RENFLAIR_API_KEY=your_real_renflair_api_key
   ```
6. Apply the schema:
   ```bash
   npm install
   npm run migrate
   ```

For PowerShell, the Node command above works without relying on newer PowerShell-specific conversion methods.

## 2. Local development

```bash
cd backend
npm install
cp .env.example .env
# Edit .env and add real test credentials
npm run migrate
npm start
```

The API defaults to `http://localhost:8080` for local development. Confirm:

- `GET /health` — API process is running
- `GET /health/db` — API can query Neon

Do not expose a local development server with production credentials.

## 3. Deploy to Render

Create a Web Service and use:

| Setting | Value |
|---|---|
| Root Directory | `backend` |
| Runtime | Node |
| Build Command | `npm install` |
| Start Command | `npm start` |

Set these variables in the service's **Environment** settings:

| Name | Value |
|---|---|
| `DATABASE_URL` | Neon PostgreSQL connection string |
| `JWT_SECRET` | Strong random secret generated on your computer |
| `RENFLAIR_API_KEY` | Renflair API key |
| `S3_ENDPOINT` | Optional storage endpoint |
| `S3_REGION` | Optional; often `auto` for compatible services |
| `S3_BUCKET` | Optional; defaults to `assets` |
| `S3_ACCESS_KEY_ID` | Optional storage access key |
| `S3_SECRET_ACCESS_KEY` | Optional storage secret key |

Let Render set `PORT` automatically. Do not set it to a blank value. Do not add secrets to source files, GitHub workflow YAML, Flutter `--dart-define`, or a public issue.

After deployment, open `/health` and `/health/db`. If you change `schema.sql`, apply the migration to the same Neon database used by the deployed service and restart/redeploy the API.

> Hosting providers can change their pricing, free-tier limits and card-verification requirements. Review the current provider terms before creating a service.

## 4. Renflair phone OTP flow

The app's registration flow verifies only the account holder's phone number. Email addresses and emergency-contact numbers are not OTP-verified.

### How it works

1. Flutter calls `POST /auth/otp/send` with the 10-digit Indian mobile number.
2. The API generates a six-digit OTP, stores a digest with a five-minute expiry, and calls `https://sms.renflair.in/V1.php` with `API`, `PHONE` and `OTP` query parameters.
3. Flutter asks the user to enter the received code.
4. Flutter calls `POST /auth/otp/verify`. The API compares the digest, limits attempts and stores a verified-phone grant that expires after 30 minutes.
5. `POST /auth/register` requires an unexpired verified-phone grant and consumes it on successful registration.

The database migration creates `phone_otp_challenges` and `verified_phones`. Run the migration before deploying the OTP-enabled backend.

### Provider configuration checklist

- Use the API key from the Renflair account dashboard.
- Ensure the account is active and has any required SMS balance/credits.
- Confirm sender ID, template, DLT or other provider compliance requirements that apply to your account and destination.
- Test with a phone you own.
- Check the Renflair dashboard/provider response if messages are not received.
- Never log or share the API key or OTP value.

The API key is not included in the Flutter app. Provider availability and delivery are outside this repository's control. A successful API response does not guarantee that a message reached the handset.

## 5. SOS photo and voice uploads

The Flutter app creates the SOS first, then uploads optional attachments using `POST /files?kind=sos_photo` or `POST /files?kind=sos_audio`, and links the returned file IDs through `PATCH /sos/:id/files`.

- Uploads require a valid bearer token.
- The API accepts a limited allowlist of image/audio MIME types and limits the raw request size to 8 MB.
- When S3-compatible storage is configured, object bytes are stored there; otherwise, the PostgreSQL `bytea` fallback is used.
- The file endpoint only serves SOS media to the help seeker or the responder assigned to that SOS after acceptance.
- ID documents are owner-only.

For object storage, use a private bucket and credentials with the minimum required permissions. Never place object-storage credentials in Flutter or publish media URLs in a public issue.

## 6. Important API routes

| Method | Route | Purpose |
|---|---|---|
| `GET` | `/health` | Liveness check |
| `GET` | `/health/db` | Database connectivity check |
| `POST` | `/auth/otp/send` | Request SMS OTP |
| `POST` | `/auth/otp/verify` | Verify phone OTP |
| `POST` | `/auth/register` | Register with verified phone |
| `GET` | `/me` | Read account and contacts |
| `PUT` | `/me/profile` | Update profile and contacts |
| `PUT` | `/me/presence` | Update responder availability/location |
| `POST` | `/sos` | Create SOS |
| `GET` | `/sos/nearby` | Poll for nearby SOS requests |
| `GET` | `/sos/:id` | Read SOS status |
| `PATCH` | `/sos/:id/files` | Attach uploaded media IDs |
| `PATCH` | `/sos/:id/stage` | Accept/update rescue stage |
| `POST` | `/sos/:id/cancel` | Cancel a request |
| `POST` | `/files?kind=...` | Upload a file |
| `GET` | `/files/:id` | Fetch an authorised file |

Protected endpoints use a bearer token returned at registration. Do not share tokens or include them in logs.

## 7. Troubleshooting

| Symptom | Checks |
|---|---|
| `DATABASE_URL and JWT_SECRET must be set` | Set both environment variables in the correct backend service |
| `/health` succeeds, `/health/db` fails | Check the Neon connection string, SSL mode, credentials and project status |
| OTP endpoint returns `503` | `RENFLAIR_API_KEY` is missing in the backend environment |
| OTP endpoint returns `502` | Check Renflair status, key validity, account balance, provider configuration and network access |
| Registration rejects the phone | Verify the same 10-digit number and complete registration within 30 minutes |
| Media not visible to responder | Ensure the responder accepted the SOS, upload completed, schema is current, and both devices use the same API |
| Upload fails | Check MIME type, 8 MB limit, auth token, database/storage availability and backend logs |

## 🔐 Security

- Keep `.env` out of version control.
- Rotate credentials immediately if exposed.
- Use HTTPS in production.
- Do not share real emergency details when asking for help.
- Review the repository's [`SECURITY.md`](../SECURITY.md) for responsible vulnerability reporting.
