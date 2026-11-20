# Convex Self-Hosted Backend + Dashboard (Postgres 18): Railway template spec

## Listing

| Field | Value |
|---|---|
| Name | **Convex Self-Hosted Backend + Dashboard (Postgres 18)** (52 chars; Convex has no semver for self-hosted builds, so no version label) |
| Description | Reactive TypeScript backend with dashboard, on Postgres 18. (59 chars) |
| Category | Other |
| Icon | `https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/convex.svg` (200, image/svg+xml) |

## License decision

FSL-1.1-Apache-2.0. Permitted Purpose = anything but a Competing Use (offering Convex to others as a substitute commercial service). A one-click template that deploys the unmodified images into the end user's own Railway account for their own apps is self-hosting by that user. Caveat written into README ("License") and NOTICE.md. Convex itself links the Railway marketplace templates from its self-hosting docs (`self-hosted/advanced/railway/README.md`).

## Base market templates

| Market template | Active | What it does | Kept | Problems fixed |
|---|---|---|---|---|
| `convex` "Convex" (leader) | 94 | backend + dashboard `:latest`, Postgres, start command writes credentials and prints the admin key, HTTP actions via **TCP proxy over plain http** | admin key in the log | `latest` tags (backend and dashboard can drift apart); HTTP actions on an unencrypted TCP proxy URL; `INSTANCE_NAME` tied to Postgres' `PGDATABASE`; Postgres 17 |
| `convex-and-postgres-official` | 38 | backend + dashboard `:latest`, Postgres, `/http` site origin | `/http` site origin, Postgres | `latest`; `DO_NOT_REQUIRE_SSL=false` actually *enables* the flag (the script tests for non-empty); no healthchecks; admin key only via `railway ssh` |
| `convex-1` | 56 | SQLite on the volume, `/http` site origin, healthchecks | healthchecks `/version`, `/` | SQLite only; `latest` |

## Pinned versions (checked 2026-11-20)

| Component | Image | Released |
|---|---|---|
| Convex backend | `ghcr.io/convex/convex-backend:9fde7cb10083b101c27cd99a83553ce59d7b2034@sha256:1e64c93ce0a6cff9b039d7fb38b81ad0bccedf80072736a8412a622730c86115` | 2026-11-19 (`precompiled-2026-11-19-9fde7cb`) |
| Convex dashboard | `ghcr.io/convex/convex-dashboard:9fde7cb…@sha256:85c1726baa1cb10bfdce9cb2ed40a116effa001487e6eb32efe2c1063b776756` | same commit |
| Postgres | `ghcr.io/railwayapp-templates/postgres-ssl:18` | — |

## Services

### Convex Backend
- Source: repo `baranberkay96/convex-railway`, `/services/backend` (official image + `convex-railway.sh`).
- Public domain → 3210; HTTP actions on the same domain under `/http` (the backend forwards `/http/*` to its site proxy, `LocalConfig::site_forward_prefix`). Healthcheck `/version` (600 s). Restart ALWAYS (survives Postgres starting later). Volume `/convex/data` (credentials, files, modules, search indexes, tmp).
- Wrapper: `POSTGRES_URL` trimmed to the server part (query kept), `sslmode=disable` added when `DO_NOT_REQUIRE_SSL` is set; invalid `INSTANCE_SECRET` → ignored, stored/new secret used (Rule 8.29); invalid `INSTANCE_NAME` → default; admin key printed when `CONVEX_LOG_ADMIN_KEY=true`.
- Postgres: `POSTGRES_URL=${{Postgres.CONVEX_POSTGRES_URL}}` (no database name); database `convex_self_hosted` = `INSTANCE_NAME` with underscores, created by Postgres' `POSTGRES_DB` on first start. `DO_NOT_REQUIRE_SSL=1` and the wrapper appends `sslmode=disable`: Railway's `postgres-ssl` certificate is a self-signed CA used as the server certificate, which the backend's rustls rejects (`CaUsedAsEndEntity`) even with the default `sslmode=prefer` — first test deploy crash-looped on exactly that. The private network is encrypted by Railway.

### Convex Dashboard
Pinned image, port 6791, healthcheck `/`, `NEXT_PUBLIC_DEPLOYMENT_URL` = backend public URL. No `NEXT_PUBLIC_ADMIN_KEY`: the dashboard always asks for the admin key (setting it would publish an unauthenticated admin UI).

### Postgres
Railway `postgres-ssl:18`, `POSTGRES_DB=convex_self_hosted`, extra variable `CONVEX_POSTGRES_URL`.

### Why no Railway Bucket
`--s3-storage` needs five bucket variables (`S3_STORAGE_{EXPORTS,SNAPSHOT_IMPORTS,MODULES,FILES,SEARCH}_BUCKET`) and one AWS key pair. All use cases share one key prefix per instance (`{instance}-{uuid}/`), so pointing them at one bucket mixes their objects; upstream documents separate buckets only. Railway Buckets carry their own credentials each, so five Railway Buckets cannot share one key pair. Local storage on the volume is upstream's default and what every market template uses.

## Resource estimate

Measured values in the round report. Plan: backend ~150–300 MB idle, dashboard ~80–120 MB, Postgres ~60–100 MB: about $4–6/month idle. Trial (1 GB/service) fits; Hobby for production.

## Improvements over market templates

1. Backend and dashboard pinned to the same commit, by digest (no drift between `latest` pulls).
2. Postgres 18 with the Convex database created on first start, and a working connection to Railway's self-signed Postgres (the backend rejects that certificate under the default TLS mode).
3. HTTPS HTTP-actions origin on the same domain (`/http`) instead of a plain-http TCP proxy.
4. Admin key printed at start (no SSH), with a switch to stop printing it.
5. Fail-safe handling of `INSTANCE_SECRET`, `INSTANCE_NAME`, `POSTGRES_URL` values typed into the deploy form.
6. Healthchecks, restart policy, beacon off, metrics endpoint off.

## Verification checklist

- [ ] All services SUCCESS; backend `/version` 200; dashboard `/` 200.
- [ ] Log shows `Connected to Postgres` and the admin key.
- [ ] Dashboard login with the admin key works.
- [ ] Deploy a function (`npx convex deploy` against the backend), run a mutation and a query, call an HTTP action under `/http`.
- [ ] Redeploy the backend → data persists.
- [ ] Odd `INSTANCE_SECRET` → backend still starts.

## Open questions

- Postgres 18 is newer than upstream's tested Postgres 17 (checked in the deploy test).
