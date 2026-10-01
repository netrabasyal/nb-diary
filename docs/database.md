# Database

The full initial model (ERDs, conventions, metric formulas) is in the Phase 0 architecture package.
Tables are created in Phase 4 (server) and from Phase 6 (device).

## Conventions

- `uuid` primary keys (UUIDv7). User-owned rows get their ID on the device.
- `user_id NOT NULL` on every user-owned table; composite foreign keys `(parent_id, user_id)`.
- `created_at`, `updated_at` (`timestamptz`, UTC), `version`, `change_seq`, `deleted_at` on user-owned tables.
- Units in column names: `weight_kg`, `distance_m`, `duration_s`; plus `entered_value` and `entered_unit`.
- `CHECK` constraints on ranges and enums back up API validation.
- One PostgreSQL schema per API module.

## Device database (Drift)

- Defined in `apps/mobile/lib/platform/database/app_database.dart`; schema snapshots in `apps/mobile/drift_schemas/`.
- `PRAGMA foreign_keys = ON` and `PRAGMA synchronous = FULL` on every open.
- Phase 1 has one table, `app_meta`, used to prove data persists across reloads.
