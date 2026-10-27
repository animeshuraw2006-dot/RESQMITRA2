# 🚨 RESQ-MITRA
### **NO LIFE LEFT BEHIND** · HELP | SUPPORT | TOGETHER

<p align="center">
  <strong>A community-powered emergency response app built to connect people in distress with nearby responders.</strong>
</p>

<p align="center">
  <img alt="Version" src="https://img.shields.io/badge/version-1.0.1%2B2-blue">\n  <img alt="Flutter" src="https://img.shields.io/badge/Flutter-mobile%20app-02569B?logo=flutter&logoColor=white">
  <img alt="Backend" src="https://img.shields.io/badge/Backend-Node.js%20%2B%20Express-339933?logo=nodedotjs&logoColor=white">
  <img alt="Database" src="https://img.shields.io/badge/Database-Neon%20PostgreSQL-00E699">
  <img alt="SMS" src="https://img.shields.io/badge/SMS-Renflair-8A2BE2">
  <img alt="License" src="https://img.shields.io/badge/License-Apache--2.0-blue">
</p>

> **Important:** RESQ-MITRA is an assistance and coordination tool, not a replacement for official emergency services. In immediate danger, contact the relevant local emergency service whenever possible. SOS delivery depends on connectivity, permissions, backend availability and responder availability; never assume an alert was received until the app confirms it.

---

## 📚 Contents

- [🌍 Mission](#-mission)
- [✨ Capabilities](#-capabilities)
- [🔄 How SOS works](#-how-sos-works)
- [🧰 Technology](#-technology)
- [🏗️ Architecture](#️-architecture)
- [🚀 Get started](#-get-started)
- [☁️ Configure the backend](#️-configure-the-backend)
- [📲 Configure Renflair SMS OTP](#-configure-renflair-sms-otp)
- [🖼️ SOS photo and voice sharing](#️-sos-photo-and-voice-sharing)
- [🧪 Testing and build](#-testing-and-build)
- [🔐 Privacy and security](#-privacy-and-security)
- [🧭 Troubleshooting](#-troubleshooting)
- [🤝 Contributing](#-contributing)
- [📜 License](#-license)

## 🌍 Mission

Emergencies move quickly. RESQ-MITRA aims to help a person request assistance, share useful context, and connect with responders who can act. The project focuses on a clear SOS journey, location sharing, accessible emergency information and a responder view that keeps key information together.

Our pledge is simple: **NO LIFE LEFT BEHIND.**

## 🆕 What changed in this update

- 📲 **Real phone OTP integration:** removed the local `123456` demo code. Registration now requests and verifies a phone OTP through the backend and Renflair. Email and emergency contacts no longer use OTP verification.
- 🖼️ **SOS media on the responder screen:** uploaded photos and voice notes refresh on the active alert and become available after the responder accepts the SOS.
- 🔒 **Media access checks:** the API restricts SOS media to the help seeker and the assigned responder after acceptance.
- 🧯 **Demo controls removed:** responder settings no longer show simulated incoming SOS or simulated badge actions.
- 📚 **Project documentation:** refreshed README, full Apache 2.0 license text, `CODE_OF_CONDUCT.md`, `CONTRIBUTING.md` and `SECURITY.md`.

These changes still require a correctly configured backend, current database schema and valid Renflair account to operate end-to-end.

## ✨ Capabilities

### 🆘 For help seekers
- **SOS categories** for general, women’s safety and child-related emergencies.
- **High Alert SOS** for urgent situations.
- **Location-aware requests** with coordinates, address information and a map destination.
- **Optional photo and voice note** captured or recorded during SOS confirmation.
- **Emergency contacts** with call/SMS contact preferences.
- **Rescue progress** updates as the responder accepts, travels, arrives and completes assistance.
- **Profile and medical context** to help responders understand relevant needs.
- **Appreciation and feedback** after an assistance flow is completed.

### 🦺 For responders
- **Online/offline availability** to control whether the app polls for alerts.
- **Nearby SOS feed** with emergency type, location, description, tags and additional details.
- **Siren alert** for new incoming SOS events.
- **Accept and update progress** through the response stages.
- **Photo and voice note in the active SOS screen** after a responder accepts the request, when the media has uploaded successfully and the backend grants access.
- **Navigation** to the help seeker’s reported location.
- **Profile, skills and verification details** for responder onboarding.

### 📞 Emergency information
The app includes emergency-related information and calling/navigation shortcuts. Always verify local numbers and availability for your region.

## 🔄 How SOS works

1. The help seeker selects an SOS category and confirms the emergency.
2. The app attempts to send the core SOS details first, so optional media upload does not delay the alert.
3. If configured, the backend stores the SOS in Neon PostgreSQL and responders poll for nearby active requests.
4. The responder opens the alert and taps **Accept & Respond**.
5. Once the backend assigns the responder, the same active SOS screen can display the seeker’s uploaded photo and provide a **Play voice note** control.
6. The responder updates the rescue stage as the situation progresses.

**Media delivery requirements:** the seeker must grant camera/microphone permissions, capture/record media, have network access for upload, and have a configured backend and storage. A local file on the seeker’s phone cannot be viewed directly by another phone. If media upload fails, the SOS itself may still be sent without the attachment.

## 🧰 Technology

| Layer | Technology | Responsibility |
|---|---|---|
| Mobile application | Flutter / Dart | Seeker and responder interfaces |
| Location | `geolocator`, `geocoding`, `flutter_map` | Device location, address and map display |
| Capture and playback | `image_picker`, `record`, `audioplayers`, `video_player` | Photo, voice note, siren and intro media |
| Backend API | Node.js, Express | Authenticated API, SOS workflow and file access |
| Database | Neon PostgreSQL | Accounts, contacts, SOS requests, response stages and metadata |
| Object storage | Optional S3-compatible storage | Store uploaded files outside the database |
| SMS OTP | Renflair API, called from backend only | Send phone verification codes |
| Deployment | Render-compatible Node service + GitHub Actions | Host API and build Android APK |

## 🏗️ Architecture

```text
Flutter App
 ├── Registration ── phone OTP ───────────────┐
 ├── Help Seeker ── create SOS ───────────────┤
 ├── Camera / Voice Recorder ─ upload media ──┤
 └── Responder Dashboard ─ poll / accept ─────┤
                                               ▼
                                      Node.js / Express API
                                      ├── Renflair SMS OTP
                                      ├── Authenticated file access
                                      ├── SOS lifecycle & assignment
                                      └── Optional S3-compatible storage
                                               │
                                               ▼
                                        Neon PostgreSQL
```

The mobile application must never contain the Neon database connection string, Renflair API key, JWT signing secret or object-storage secret keys. Keep these values in backend environment variables.

## 🗂️ Repository layout

```text
.
├── lib/                      # Flutter UI, app state, API client and SOS services
│   └── screens/              # Registration, seeker flows and responder dashboard
├── assets/                   # App artwork, intro media, siren and badge assets
├── backend/
│   ├── server.js             # Express API, OTP, SOS and file access
│   ├── schema.sql            # PostgreSQL schema and OTP tables
│   ├── migrate.js            # Applies the schema to Neon
│   └── .env.example          # Environment variable template (no real secrets)
├── .github/workflows/        # Android APK build workflow
├── docs/                     # Technical design notes
├── samples/                  # Sanitised test examples
├── CODE_OF_CONDUCT.md
├── CONTRIBUTING.md
├── SECURITY.md
└── LICENSE
```

## 📌 Integration status

| Capability | Current behavior | What it depends on |
|---|---|---|
| SOS creation | Sends core emergency details to the API when configured | API URL, authenticated account, network |
| Cross-device responder alerts | Responders poll for nearby active SOS requests | Both devices online, backend running, responder availability |
| Phone OTP | Renflair SMS request and server-side code verification | `RENFLAIR_API_KEY`, database migration, provider account |
| SOS photo/voice | Uploads after the core SOS; shown to the assigned responder after acceptance | Permissions, upload success, backend and storage |
| Object storage | Optional S3-compatible storage; database fallback remains available | Storage credentials if external storage is selected |
| Emergency calling/SMS | Uses device calling/SMS capability and permissions | Device/OS behavior, permissions and local carrier support |

## 🌿 Branch structure

- `main` is the primary branch for the app, backend, tests, documentation and CI.
- Use focused working branches such as `feature/<description>`, `fix/<description>` and `docs/<description>`.
- Do not commit secrets or production emergency data on any branch. See [`CONTRIBUTING.md`](CONTRIBUTING.md) for the contribution workflow.

## 🚀 Get started

### Prerequisites

- Flutter SDK compatible with the Dart constraints in `pubspec.yaml`
- Dart SDK
- Git
- Android SDK and an Android device/emulator for mobile testing
- Node.js 18+ for the backend (Node.js 20+ recommended)
- A Neon PostgreSQL database for shared accounts/SOS
- A Renflair account/API key for real SMS OTP

### 1. Clone and install Flutter dependencies

```bash
git clone https://github.com/animeshuraw2006-dot/RESQMITRA2.git
cd RESQMITRA2
flutter pub get
```

If your downloaded ZIP contains the Flutter project inside a subfolder, change into the folder that contains `pubspec.yaml`.

### 2. Configure the backend

See [`backend/README.md`](backend/README.md) for Neon, Render, database migration, Renflair and storage setup.

### 3. Run the app with the API configured

```bash
flutter run --dart-define=API_BASE=https://YOUR-API.onrender.com
```

Replace the URL with your deployed backend URL. If `API_BASE` is empty, the app uses local-only behavior and cannot send real SMS OTP or share SOS data with other devices.

### 4. Build an Android APK

```bash
flutter build apk --release --dart-define=API_BASE=https://YOUR-API.onrender.com
```

For a distributable release, configure a proper Android release signing key and protect it as a secret. Do not distribute a debug-signed production build.

## ☁️ Configure the backend

1. Create a PostgreSQL project in Neon and copy its connection string from **Connect**. Use the pooled connection string where appropriate and keep `sslmode=require`.
2. Deploy the `backend/` folder as a Node web service. Set the root directory to `backend`, build command to `npm install`, and start command to `npm start`.
3. Add the environment variables listed in [`backend/.env.example`](backend/.env.example) to the host dashboard. Do not commit a real `.env` file.
4. Run the database migration once against the selected Neon database:
   ```bash
   cd backend
   npm install
   npm run migrate
   ```
   You can run this locally with `DATABASE_URL` set in your shell, or run the schema SQL in the Neon SQL editor. Re-run migrations when the schema changes.
5. Check `https://YOUR-API.onrender.com/health`, then `/health/db`.
6. In GitHub, add repository secret **`API_BASE`** under **Settings → Secrets and variables → Actions**. Set its value to the deployed API base URL with no trailing slash, then run the **Build ResQMitra** workflow.

Some hosting providers may request payment details or impose usage limits. Check the provider’s current plan and requirements before deploying.

## 📲 Configure Renflair SMS OTP

The registration screen should request OTP only for the account holder’s phone number. Email addresses and emergency-contact numbers are not OTP-verified by this implementation.

1. Create/access your Renflair SMS account and obtain the API key from its official dashboard/provider instructions.
2. Add `RENFLAIR_API_KEY` to the backend host’s environment variables. **Never put this key in Flutter, GitHub source, README files or a committed `.env`.**
3. Apply the updated database schema (`npm run migrate`) so the OTP challenge tables exist.
4. Re-deploy/restart the backend after setting the variable.
5. Test with a phone number you own and confirm the SMS is received before using the app in real situations.

The backend generates a short-lived six-digit OTP, asks Renflair to send it using the provider’s `V1.php` endpoint, stores only a server-side digest, limits repeat requests/attempts and checks the OTP before account registration. The phone verification grant expires after 30 minutes. Provider delivery, account credits, approved sender/template settings and regional rules are controlled by Renflair and may need to be configured in their dashboard.

### Expected environment variables

| Variable | Required? | Purpose |
|---|---|---|
| `DATABASE_URL` | Yes | Neon PostgreSQL connection string |
| `JWT_SECRET` | Yes | Long random secret for signing session tokens |
| `RENFLAIR_API_KEY` | Yes for real OTP | Renflair SMS API credential |
| `PORT` | Host supplies it | Local development can use `8080` |
| `S3_ENDPOINT` | Optional | S3-compatible storage endpoint |
| `S3_REGION` | Optional | Storage region, often `auto` for compatible services |
| `S3_BUCKET` | Optional | Bucket name |
| `S3_ACCESS_KEY_ID` | Optional | Storage access key |
| `S3_SECRET_ACCESS_KEY` | Optional | Storage secret key |

## 🖼️ SOS photo and voice sharing

- The seeker captures a photo and/or records a voice note on the SOS confirmation screen.
- The app sends the SOS first, then uploads the optional files.
- The backend links uploaded file IDs to the SOS record.
- The responder’s active SOS card refreshes those file references while polling.
- Media is shown/available to the assigned responder after acceptance. The backend checks that the requesting account is the seeker or the assigned responder.
- Photos are rendered in the active SOS screen. Voice recordings are available through **Play voice note**.

If the media is missing, check that `API_BASE` points to the same backend for both phones, the user has a valid session, upload requests succeed, the database schema is current, and optional object-storage credentials are valid. The core SOS can arrive before the attachments finish uploading.

## 🧪 Testing and build

Before submitting changes:

```bash
dart format lib test
flutter analyze
flutter test
```

Backend syntax check:

```bash
cd backend
node --check server.js
npm install
```

Test these flows on physical devices where possible:
- Phone OTP send, incorrect code, expired code and successful registration
- Seeker SOS delivery to a separate responder device
- Responder accepts SOS, then photo becomes visible and voice note plays
- Attachment upload failure does not prevent the initial SOS attempt
- Cancellation and rescue-stage updates
- Permission denied, location unavailable and no-network states

**Never use a real emergency to test the app.** Use controlled tests and clearly inform any participants.

## 🔐 Privacy and security

RESQ-MITRA can process highly sensitive information, including phone numbers, emergency contacts, live location, photos, voice recordings and emergency descriptions. Collect/share only what is needed, request permissions transparently, and avoid posting personal or incident data in public issues.

- Keep all backend credentials on the server.
- Use HTTPS for deployed API calls.
- Keep phone OTPs short-lived and rate-limited.
- Limit access to uploaded SOS media.
- Review the retention and deletion needs for sensitive emergency records before production deployment.
- Check [`SECURITY.md`](SECURITY.md) before reporting a vulnerability.

This repository’s security controls are not a guarantee that every deployment is secure. Review the deployed configuration, data retention, authentication and provider settings before real-world use.

## 🧭 Troubleshooting

| Problem | What to check |
|---|---|
| OTP button returns an error | Confirm `API_BASE`, backend health, `RENFLAIR_API_KEY`, Renflair account status and schema migration |
| OTP SMS does not arrive | Check the number, provider response/dashboard, account balance, sender/template settings and provider delivery rules |
| Registration says phone is not verified | Verify the same 10-digit number that is entered in the registration form; complete registration within the 30-minute verification window |
| Responder sees SOS but no photo/audio | Confirm the responder accepted the SOS, upload finished, both phones use the same API, and file requests are authorized |
| `/health` works but `/health/db` fails | Check `DATABASE_URL`, SSL mode and Neon project availability |
| APK builds but cannot reach backend | Build with the correct `--dart-define=API_BASE=...` |
| GitHub Actions fails | Open the failed workflow step and inspect the first relevant error; ensure the workflow and required secrets are present |

## 🤝 Contributing

Contributions are welcome. Please read [`CONTRIBUTING.md`](CONTRIBUTING.md) and follow the community standards in [`CODE_OF_CONDUCT.md`](CODE_OF_CONDUCT.md). For security-sensitive issues, follow [`SECURITY.md`](SECURITY.md) instead of opening a public issue.

## 📜 License

The application source code is distributed under the **Apache License 2.0**; see [`LICENSE`](LICENSE). Third-party packages and assets may have their own terms. The license does not grant rights to personal data, emergency media, third-party trademarks or content unless those rights are expressly granted by their owners.

---

<p align="center">
  <strong>NO LIFE LEFT BEHIND</strong><br>
  HELP · SUPPORT · TOGETHER ❤️
</p>

### Build fix (October 2026)

The registration screen's phone OTP button now passes the explicit `mobile` verification key. This avoids a Dart null-safety compile error caused by passing nullable `String? verifyKey` into `_verify(String, String)` from a callback. The OTP action remains available only beside the user's own mobile number; emergency contacts do not receive OTP buttons.

### Phone OTP verification UI fix

The registration and complete-verification OTP dialogs now keep the code entry open when the server rejects an OTP, show the backend error in the dialog, and only mark the phone as verified when the API responds with both a successful HTTP status and `verified: true`. The registration phone field clears its verified state if the number is edited, and the review status updates from Pending to Completed after successful verification.
