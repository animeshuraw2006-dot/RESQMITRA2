# ResQMitra — Combined Flutter App Source

This archive combines the available ResQMitra onboarding, dashboard, SOS selection, emergency request and responder screens into one Flutter project, along with the six supplied screen references.

## Screen flow
1. **Splash** — ResQMitra launch screen.
2. **Role selection** — choose Help Seeker, Rescuer, or both.
3. **Create Account** — local form validation and navigation.
4. **Home dashboard** — large SOS action, High Alert SOS, siren/flashlight preview controls, profile/responder shortcuts, helpline, and Home/Map/History/Badges/Profile navigation.
5. **Choose Your SOS** — General SOS, Women SOS, Child SOS.
6. **Emergency category grids** — 12 General categories, 8 Women categories, 8 Child categories.
7. **Emergency request form** — selected category is passed into the existing form.
8. **Responder screen** — responder workflow screen.

## Run locally
1. Install Flutter and a compatible Android toolchain.
2. Extract the ZIP and open the `ResQMitra_Production_Upgrade` folder.
3. Run `flutter pub get`.
4. Run `flutter analyze`.
5. Run `flutter test` and then `flutter run` on a configured emulator/device.

## Important safety and integration notes
- High Alert countdown starts at **5 seconds** and keeps 5 visible for a full second before decrementing. It currently opens a confirmation flow; it does **not** automatically submit an SOS when the timer reaches zero.
- Call **112** directly in India for immediate danger. Do not rely on this app as a replacement for emergency services.
- Siren and flashlight controls are UI preview toggles until hardware plugins and permissions are integrated and tested.
- SOS delivery, responder notifications, real account authentication, database rules and user identity verification require configured backend services and device testing.
- Map needs valid API keys/permissions. History, Badges and Profile tabs include UI/navigation placeholders where production data integration remains necessary.
- Do not commit real API keys, passwords or backend secrets to GitHub.

## Source layout
- `lib/main.dart` — splash, role selection, signup flow and app entry point.
- `lib/screens/home_screen.dart` — home dashboard and High Alert countdown.
- `lib/screens/sos_selection_screen.dart` — Choose Your SOS and all category grids.
- `lib/screens/victim_screen.dart` — emergency request form.
- `lib/screens/responder_screen.dart` — responder screen.
- `lib/screens/incident_map_screen.dart` — map screen starter.
- `lib/models/` and `lib/services/` — models and service layer.
- `assets/reference_designs/` — supplied screenshots for design reference only.

## Verification status
The ZIP archive was checked for integrity. Flutter analysis, automated tests and APK build have not been run in this environment, so run the commands above before deployment.
