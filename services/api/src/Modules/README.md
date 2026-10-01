# API modules

One folder per module from Phase 4: Identity, Users, Exercises, Training, Records, Progress, Sync, Billing. Each has `*.Contracts`, `*.Domain`, `*.Application` and `*.Infrastructure` projects and its own PostgreSQL schema. Other modules may reference only `*.Contracts`; architecture tests enforce this.
