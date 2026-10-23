# Role modes and incident photos update

- HELP SEEKER routes to the help-seeker home screen only.
- RESCUER routes directly to the responder page.
- BOTH uses the combined home screen and retains a responder-dashboard shortcut.
- The home-screen role-switch action is removed; only BOTH has a responder-dashboard shortcut.
- SOS confirmation supports selecting up to five incident photos. They upload privately to Supabase Storage bucket `emergency-photos` and metadata is written to `public.emergency_incident_photos`.

## Required setup
1. Run `supabase/migrations/20261022_emergency_incident_photos.sql` in the Supabase SQL editor.
2. Run `flutter pub get` to install `image_picker`.
3. Ensure `emergency_requests.id` is UUID and requester policies match your deployed schema. Review the SQL policies against your existing RLS policies before production.
4. Test photo upload using a test SOS; verify private bucket contents and metadata rows. The photos are not public.

Note: This change does not rewrite the responder live-query/acceptance backend. Verify that existing `accept-sos` and assignment RLS policies return only assignments for the authenticated responder and that the accepted SOS page loads its emergency coordinates.
