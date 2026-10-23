# Production acceptance checklist

This ZIP is a development candidate, not a certified emergency dispatch system.

## Required before public release
- [ ] Run all Flutter formatting, analysis, tests, and Android build commands in a Flutter-enabled environment.
- [ ] Configure Firebase Authentication, Firestore, Cloud Functions, indexes, App Check, and production environment.
- [ ] Add and test push delivery with provider acceptance, device delivery where measurable, and responder acknowledgement as separate states.
- [ ] Implement a durable encrypted offline queue and restart/reconciliation tests. Current demo/local state is not a durable offline SOS queue.
- [ ] Implement a real map provider and test location permissions, GPS accuracy, timeout, stale fixes, and manual fallback.
- [ ] Implement a secure admin responder-verification workflow and audit trail.
- [ ] Add emulator tests for rules and concurrent claim attempts.
- [ ] Add real-device integration tests for registration, verification, SOS submission, cancellation, offline recovery, and notification failures.
- [ ] Review privacy policy, child-related data safeguards, retention/deletion, abuse reporting, and applicable legal obligations.
- [ ] Verify emergency-number guidance for each deployment region. Do not imply RESQ-MITRA replaces official emergency services.
- [ ] Conduct an independent security review and load test.

## Known limitations in this build
- No live push-notification delivery, SMS gateway, automated calling, or external emergency-service integration.
- No map tile provider or live incident markers configured.
- No durable encrypted offline submission queue.
- No admin UI for responder verification.
- The existing UI remains primarily in `lib/main.dart`; new models and services establish a path toward full screen-by-screen modularization, but the entire UI has not yet been split into individual screen files.
- Automated Flutter commands could not be executed in the generation environment if the Flutter SDK is unavailable. Check the actual verification log delivered with this archive.
