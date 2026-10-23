# Cloud Functions test scenarios to run against Firebase Emulator Suite

These are required acceptance scenarios, not claims that tests have already passed.

1. Unauthenticated callers cannot create, claim, or update an incident.
2. `createSos` rejects unknown categories, malformed coordinates, unsupported blood groups, and a blank description for General SOS → Other.
3. Repeating `createSos` with the same request ID and same owner does not create a second incident.
4. Reusing an existing request ID from a different owner is rejected.
5. Unverified or inactive responders cannot claim an incident.
6. Two verified responders claiming the same pending incident concurrently result in exactly one successful assignment.
7. The assigned responder can read the private document; unrelated responders cannot.
8. The owner can read their own private document but cannot read another user's private document.
9. Only the owner can cancel or mark safe; only the assigned responder can advance the incident.
10. Illegal transitions (for example, `arrived` → `en_route`) are rejected.
11. Client SDK writes to `sosRequests`, `sosPrivate`, and `responders` are denied.
12. A notification API acceptance must never be interpreted as responder acknowledgement.
