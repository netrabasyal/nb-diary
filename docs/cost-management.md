# Cost management

Target: about AUD 30–100 a month on Azure. Phase 0 estimate: **AUD 55–80**, roughly half of it
the production PostgreSQL server. These are estimates; check the Azure pricing calculator.

## Controls (written into Bicep in Phase 2)

- Subscription budgets: AUD 70 (prod) and AUD 25 (non-prod), alerts at 50/80/100% and on forecast.
- Tags on every resource: `app`, `env`, `owner`, `module`.
- API scales to zero; staging PostgreSQL stopped nightly by a scheduled workflow
  (Azure restarts stopped servers after 7 days).
- Log Analytics: 30-day retention, 0.5 GB daily cap, sampling.
- Blob lifecycle rules for exports and database dumps.

## Main cost drivers

1. PostgreSQL compute (B1ms).
2. Keeping an API replica warm (not done; about AUD 15 a month).
3. Log volume.
4. Moving to General Purpose PostgreSQL or adding high availability (not needed for personal use).

Outside Azure: no Apple fee while the App Store is deferred; GitHub Free; optional domain about AUD 20 a year.
