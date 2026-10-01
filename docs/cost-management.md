# Cost management

Target: about AUD 30–100 a month on Azure. Phase 0 estimate: **AUD 55–80**, roughly half of it
the production PostgreSQL server. These are estimates; check the Azure pricing calculator.

## Controls (in Bicep)

- Budgets in the `nb-lab-001` subscription, filtered to NB Diary's resource groups: AUD 70 (prod)
  and AUD 25 (staging plus the shared registry), emails at 50/80/100% and on forecast.
  Set in `infrastructure/azure/bootstrap/main.bicep`.
- Tags on every resource: `app`, `env`, `owner`, `module`.
- API scales to zero; staging PostgreSQL stopped nightly by the `staging-db-stop` workflow
  (Azure restarts stopped servers after 7 days).
- Log Analytics: 30-day retention, 0.5 GB daily cap; Application Insights sampling at 50%.
- No private endpoints for Key Vault or storage yet (about AUD 12 a month each); both allow only
  Entra sign-in.
- Blob lifecycle rules for exports and database dumps.

## Main cost drivers

1. PostgreSQL compute (B1ms).
2. Keeping an API replica warm (not done; about AUD 15 a month).
3. Log volume.
4. Moving to General Purpose PostgreSQL or adding high availability (not needed for personal use).

Outside Azure: no Apple fee while the App Store is deferred; GitHub Free; optional domain about AUD 20 a year.
