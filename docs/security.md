# Security

Status: design agreed in Phase 0; controls are implemented in the phase noted.

| Area | Control | Phase |
| --- | --- | --- |
| Sign-in | Entra External ID, email one-time passcode; server-side OIDC code flow with PKCE | 3 |
| Session | `__Host-` HttpOnly, Secure, SameSite=Strict cookie; server-side sessions; 30-day sliding, 90-day max | 3 |
| CSRF | SameSite=Strict plus required `X-NB-CSRF` header on writes | 3 |
| Authorisation | User ID from the session only; EF Core global query filters; composite foreign keys; 404 for other users' data | 4 |
| Isolation tests | Authorisation matrix: User B can't read or change User A's data | 4 |
| Secrets | Managed identities; Key Vault for the two certificates; nothing secret in the web app | 2–3 |
| Database | Private network, Entra authentication, no password, TLS | 2 |
| Transport | HTTPS only, TLS 1.2+, HSTS | 2 |
| Browser headers | CSP, COOP/COEP, `nosniff` (already on every API response), `frame-ancestors 'none'` | 1–3 |
| Rate limiting | Per user and per IP; body size limits | 4 |
| Logging | No tokens, emails, request bodies or workout content | 4 |
| Supply chain | Dependabot, vulnerable-package check in CI, gitleaks, container image scanning | 1–2 |
| Backups | Point-in-time restore (14 days prod), monthly `pg_dump`, resource locks | 2, 12 |

## Rules

- Never trust a user ID supplied by the client.
- Never put database passwords, Azure credentials or privileged keys in the app or the repo.
  The only credentials in the repo are the local Docker ones in `docker-compose.yml`.
- Every endpoint that touches user data must be in the authorisation test matrix.
