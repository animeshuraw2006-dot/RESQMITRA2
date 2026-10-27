# 🔐 RESQ-MITRA Security Policy

Security is especially important for RESQ-MITRA because the application may handle phone numbers, emergency contacts, location, photos, voice recordings, medical context and incident descriptions.

## Supported Versions

| Version | Support |
|---|---|
| `1.0.x` (current project line) | ✅ Security fixes considered |
| Versions below `1.0.0` | ❌ Not supported; upgrade to the current release |

The table describes the repository's current support intention, not a guarantee that every release is free of vulnerabilities.

## Reporting a Vulnerability

Please report suspected vulnerabilities responsibly.

### How to report

- **Do not open a public GitHub issue** for a security vulnerability.
- Use GitHub's **Private vulnerability reporting** feature for this repository if it is enabled.
- Alternatively, contact a project maintainer privately through GitHub.

If the repository does not offer private reporting, contact a maintainer directly and ask for a private channel before sending sensitive details.

### What to include

- A concise description of the issue and affected component/version
- Steps to reproduce in a test environment
- Potential impact and the attacker capabilities required
- Relevant sanitised logs or proof of concept
- A suggested fix, if you have one

Do not include real user phone numbers, live locations, identity documents, access tokens, real SOS photos or voice recordings in the report.

### Response targets

We aim to:
- Acknowledge a report within **48 hours**
- Provide an initial assessment within **7 days**
- Work toward a fix or mitigation within **14 days** when the issue is reproducible and scope permits
- Coordinate public disclosure with the reporter after a fix or mitigation is available

These are response goals, not contractual guarantees. Complex issues or limited maintainer availability may affect timing. Please avoid publicly disclosing details before a coordinated resolution.

## Security Architecture and Current Controls

The repository currently includes the following controls:

- **Backend secrets:** Neon credentials, JWT signing secret, Renflair API key and optional object-storage keys are intended to stay in backend environment variables.
- **Phone OTP:** the backend requests SMS delivery from Renflair, stores a digest rather than the plaintext code, expires codes after 5 minutes, limits repeated requests and verification attempts, and grants verified-phone status for 30 minutes.
- **Authenticated API:** protected endpoints use bearer tokens.
- **Request hardening:** Express Helmet, request-rate limits and JSON body limits are configured.
- **File uploads:** uploads are authenticated, size-limited and restricted to an allowlist of media MIME types.
- **SOS media access:** SOS photo/audio file reads are restricted to the help seeker or the responder assigned to that SOS after acceptance.
- **Database queries:** API database operations use parameterised queries.
- **HTTPS:** deployed services should be accessed only over HTTPS.

## Known Limitations and Production Checklist

This is a project policy, not a completed independent security audit. Before production deployment, maintainers should review and test at least the following:

- The current API issues long-lived bearer tokens; token expiry, revocation, device logout and account recovery need a production-grade review.
- The application uses polling for responder alerts. Delivery is dependent on connectivity, app operation, service availability and responder status; it is not a guaranteed emergency dispatch service.
- Renflair delivery, sender/template approvals, credits and regional SMS rules are controlled by the provider. Do not treat an HTTP success alone as proof that a handset received a message.
- Review the deployment's CORS policy, rate limits, logs, backup policy, retention and deletion rules, monitoring, incident response and database access.
- Configure a proper Android release signing key. Do not distribute debug-signed builds as production releases.
- Configure optional object storage only with server-side credentials and appropriate bucket access controls. Test the PostgreSQL fallback and storage failure paths.
- Verify that OTP tables are migrated before deploying the API version that requires them.
- Review third-party dependencies and their advisories; third-party services and packages have their own security processes.
- Confirm that photo/audio retention and user consent meet the requirements applicable to the deployment and jurisdiction.

## Scope

This policy covers:
- The RESQ-MITRA Flutter application source in this repository
- The Node.js/Express backend and database schema maintained here
- Repository build workflows and project configuration

This policy does not directly govern:
- Renflair, Neon, Render, GitHub or other third-party service infrastructure
- Third-party package vulnerabilities (report them to the relevant maintainer as well)
- A deployment that has been modified outside this repository

## Sensitive Data and Misuse Reports

If you believe that emergency media, location information, contact details or identity documents have been exposed or misused, report the issue privately to a maintainer. Do not post the data publicly. Include only the minimum information necessary to identify the affected feature, and redact credentials and personal data.

## Disclosure and Credit

We appreciate good-faith security research that avoids harming users, disrupting emergency workflows or accessing data beyond what is necessary to demonstrate a vulnerability. With the reporter's agreement, maintainers may acknowledge the contribution in a release note after the issue is resolved.

---

**RESQ-MITRA · NO LIFE LEFT BEHIND · HELP | SUPPORT | TOGETHER**
