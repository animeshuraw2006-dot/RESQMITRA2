# Firebase setup for RESQ-MITRA

1. Install Flutter stable, Dart, Node.js 20, npm, and Firebase CLI.
2. Create a Firebase project and register the Android app using the actual Android application ID.
3. Add the generated `google-services.json` under `android/app/`. Do not commit service-account credentials or private keys.
4. Enable Firebase Authentication → Email/Password. Configure email verification and password reset templates. The current login screen supports email/password only; phone authentication is not implemented.
5. Enable Cloud Firestore and deploy `firestore.rules` and `firestore.indexes.json`.
6. From `functions/`, run `npm install` then `npm run build`; from the project root deploy with `firebase deploy --only functions,firestore:rules,firestore:indexes` after configuring `.firebaserc` for your project.
7. Provision responder records only through a trusted admin process. A record in `responders/{uid}` must not be writable by the client. Set `verified: true` and `active: true` only after real-world verification.
8. Configure Firebase App Check before production release. The callable functions currently do not enforce App Check to avoid blocking initial local integration; enable enforcement after registering supported app providers and testing.
9. Configure Android notification channels and an authorized push-notification sender before claiming responder notifications are delivered. The current package does not implement push delivery.
10. Test with Firebase Emulator Suite and test accounts before using any real incident data.

## Important behavior

- If Firebase is not configured, the app can be explored in local demo mode. It does not create a real account or send an SOS.
- The callable `createSos` function stores incident metadata in `sosRequests` and private notes/location in `sosPrivate`.
- `claimSos` atomically assigns a single verified, active responder.
- `updateSosStatus` checks ownership or assignment before changing status.
- No SMS, automated phone call, or push notification is sent by these functions. DO NOT CALL records a preference; a messaging/dispatch integration must be separately configured.
