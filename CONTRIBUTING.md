# 🤝 Contributing to RESQ-MITRA

Thank you for considering a contribution to **RESQ-MITRA — NO LIFE LEFT BEHIND**. Every thoughtful improvement helps us build a clearer, safer and more reliable emergency-assistance experience.

> 🚨 **Safety first:** Do not test with real emergencies or use real people's emergency details in development. The app is not a replacement for official emergency services.

## 📚 Table of Contents

- [Getting Started](#-getting-started)
- [Branch Structure](#-branch-structure)
- [Development Setup](#-development-setup)
- [How to Contribute](#-how-to-contribute)
- [Pull Request Process](#-pull-request-process)
- [Commit Messages](#-commit-messages)
- [Code Style](#-code-style)
- [Privacy and Test Data](#-privacy-and-test-data)
- [Reporting Issues](#-reporting-issues)

---

## 🚀 Getting Started

1. Check existing issues and pull requests to avoid duplicate work.
2. Fork the repository on GitHub.
3. Clone your fork and create a focused branch.
4. Install dependencies and understand the affected feature before editing.
5. Make the smallest complete change, add/update tests and documentation, then run the checks below.
6. Open a pull request describing the problem, solution and verification performed.

## 🌿 Branch Structure

The repository uses `main` as the primary development branch.

- `main` — application source, backend, tests, documentation and build workflows.
- `feature/<short-description>` — new features.
- `fix/<short-description>` — bug fixes.
- `docs/<short-description>` — documentation-only changes.
- `security/<short-description>` — security changes; coordinate privately with maintainers when the details are sensitive.

**Rules**
- Do not commit directly to the shared `main` branch unless a maintainer has explicitly asked you to.
- Keep each branch focused on one change.
- Rebase or merge the latest `main` as appropriate before requesting review.
- Never include unrelated generated files, local build output, credentials or user data.

## 🧰 Development Setup

### Prerequisites

- Flutter SDK and Dart SDK compatible with `pubspec.yaml`
- Git
- Android SDK for Android builds
- Node.js 18+ (Node.js 20+ recommended) for the API
- A test Neon PostgreSQL database if testing shared backend functionality
- A Renflair test account/API key if testing SMS OTP

### Flutter app

```bash
git clone https://github.com/animeshuraw2006-dot/RESQMITRA2.git
cd RESQMITRA2
flutter pub get
flutter run --dart-define=API_BASE=https://YOUR-TEST-API.example.com
```

For local UI-only work, `API_BASE` may be omitted. Real SMS OTP and cross-device SOS delivery require a correctly configured backend.

### Backend

```bash
cd backend
npm install
cp .env.example .env
# Edit .env locally with test-only credentials. Never commit it.
npm run migrate
npm start
```

Use a disposable development database and a test SMS account. Never use production credentials in pull-request builds.

## 🛠️ How to Contribute

### 🐛 Bug fixes

- Search existing issues first.
- Create a branch such as `fix/otp-expiry-message`.
- Include reproducible steps, expected behaviour and actual behaviour.
- Add a regression test where practical.

### ✨ New features

- Open an issue or discussion first for substantial changes.
- Describe the user need, possible privacy implications and failure states.
- Keep the seeker and responder experience consistent.
- Do not delay the core SOS attempt for optional media upload or other non-essential work.

### 📝 Documentation

- Improve README instructions, backend setup, troubleshooting, comments and test notes.
- Keep environment-variable names consistent across code, `.env.example` and documentation.
- Clearly distinguish implemented behaviour from planned or optional integrations.

### 🧪 Testing

- Add or update tests for logic changes.
- Test permission denial, no network, backend errors, expired OTPs and missing attachments where relevant.
- When testing cross-device SOS, use two controlled test accounts/devices and synthetic information.
- Never claim a real emergency workflow is production-ready based only on a successful local build.

## 🔍 Pull Request Process

Before opening a pull request:

1. Run formatting:
   ```bash
   dart format lib test
   ```
2. Run static analysis:
   ```bash
   flutter analyze
   ```
3. Run tests:
   ```bash
   flutter test
   ```
4. For backend changes, run:
   ```bash
   cd backend
   node --check server.js
   ```
5. Update documentation and `.env.example` when configuration changes.
6. Confirm that no secrets, personal data, screenshots of private information or generated build output are included.
7. Use a clear pull request title and describe the changes, testing, limitations and any migration steps.
8. Respond constructively to review feedback. Maintainers may request changes before merging.

## 🧾 Commit Messages

Use a short conventional format:

```text
type(scope): concise description
```

Examples:

```text
feat(sos): show seeker voice note after acceptance
fix(otp): reject expired phone verification codes
fix(responder): refresh uploaded SOS media references
docs(readme): clarify Renflair environment setup
test(api): cover invalid OTP attempts
build(ci): document API_BASE secret
```

Common types include `feat`, `fix`, `docs`, `test`, `build`, `refactor` and `security`.

## 🎨 Code Style

- Follow the [Dart style guide](https://dart.dev/effective-dart) and the project's existing conventions.
- Prefer small, readable, reusable widgets and services.
- Use parameterised SQL queries; never concatenate untrusted values into SQL.
- Validate external input at the API boundary.
- Keep credentials in environment variables and never log OTPs, API keys, tokens or sensitive incident data.
- Handle network errors and permission failures gracefully.
- Document public APIs and non-obvious security decisions.
- Avoid unrelated formatting or refactoring in a feature PR.

## 🔒 Privacy and Test Data

RESQ-MITRA handles potentially sensitive emergency information. Contributions must:

- Use fake names, synthetic phone numbers and fictional locations in examples.
- Avoid committing audio, photos, identity documents or logs from real incidents.
- Obtain consent for any sample media and remove identifying metadata when appropriate.
- Restrict file access to authorised accounts and test that access control.
- Never place Renflair, Neon, JWT or object-storage secrets in the app or repository.
- Follow [`SECURITY.md`](SECURITY.md) for vulnerability reports and [`CODE_OF_CONDUCT.md`](CODE_OF_CONDUCT.md) for community expectations.

## 🐞 Reporting Issues

### Bug reports

Open a GitHub issue with:
- A concise title and the affected screen/API endpoint
- Steps to reproduce
- Expected versus actual behaviour
- Flutter/Dart version, device model and Android version where relevant
- Sanitised logs with secrets and personal information removed

### Feature requests

Explain the user problem, proposed behaviour, alternative approaches and relevant privacy/safety considerations.

### Security vulnerabilities

**Do not open a public issue for a vulnerability.** Follow [`SECURITY.md`](SECURITY.md) and use GitHub's private vulnerability reporting or contact a maintainer privately.

---

Thank you for helping make RESQ-MITRA more useful, respectful and dependable. ❤️  
**NO LIFE LEFT BEHIND · HELP | SUPPORT | TOGETHER**
