# Sample test data and test cases

Use a separate test database and fake contact numbers. Do not send test SOS messages to emergency services.

## Test cases
| ID | Scenario | Expected result |
|---|---|---|
| AUTH-01 | Register with a valid role and name | User and contacts persist; API returns JWT |
| AUTH-02 | Call protected route without a token | HTTP 401 |
| FILE-01 | Upload supported JPEG as authenticated user | Returns `file_id`; object storage used if configured |
| FILE-02 | Upload unsupported MIME type | HTTP 400 |
| FILE-03 | Read another user's ID document | HTTP 403 |
| SOS-01 | Submit valid SOS with unique client reference | SOS persists and is returned |
| SOS-02 | Two responders accept same SOS concurrently | Only one succeeds; other receives conflict |
| SOS-03 | Cancel an active SOS as its owner | SOS status changes to cancelled |
| HEALTH-01 | GET `/health` | `{ "ok": true, ... }` |
| HEALTH-02 | GET `/health/db` with valid Neon credentials | Database reports connected |

## Safe manual smoke test
1. Deploy a staging API and run schema migrations.
2. Register two test users, one seeker and one rescuer.
3. Set the rescuer online with a test coordinate near the seeker.
4. Create a test SOS and verify it appears in the nearby endpoint.
5. Accept it from two concurrent clients and confirm only one responder is assigned.
6. Upload a harmless test image and audio file, then retrieve them with an authorized token.
7. Repeat with invalid tokens and a different user's ID document; access must be denied.
