# Deploy and Host Convex with Railway

Convex is a reactive backend for TypeScript apps: a document database, server functions, scheduling, file storage and live queries in one. This community template runs the self-hosted Convex backend and its dashboard on Railway with PostgreSQL 18 as the database, a volume for files and indexes, and an admin key printed in the deploy log.

## About Hosting Convex

With Convex you write queries, mutations and actions as TypeScript functions in a `convex/` folder, push them with `npx convex deploy`, and clients subscribe to query results that update in real time. The open-source backend is the same engine that runs Convex's cloud, packaged as a Docker image. Self-hosting it means running that backend next to a database, giving it public URLs for the API and HTTP actions, keeping its files on persistent storage, and getting an admin key for the dashboard and CLI. This template sets the public origins from Railway's domain, stores documents in PostgreSQL 18 over the private network, keeps uploaded files, modules and search indexes on a volume, checks the instance secret at every start, and prints the admin key so you do not need SSH.

## Common Use Cases

- Backend for React, Next.js, Vue, Svelte or React Native apps with live-updating queries
- Real-time collaborative apps, chat, multiplayer and dashboards
- AI apps that combine a database, vector search, scheduled jobs and LLM calls in actions
- Running Convex in your own Railway account for data-location, cost or compliance reasons
- Development and staging backends next to a Convex Cloud production deployment

## Dependencies for Convex Hosting

- Convex backend and dashboard (self-hosted images, pinned to commit `9fde7cb` of 2026-11-19)
- PostgreSQL 18 (included, Railway's `postgres-ssl` image with a volume)
- A Railway volume at `/convex/data` for files, modules and search indexes (included)
- Node.js and the `convex` npm package on your machine or CI to deploy functions

### Deployment Dependencies

- Self-hosting guide: https://github.com/get-convex/convex-backend/tree/main/self-hosted
- Convex documentation: https://docs.convex.dev
- Source and license: https://github.com/get-convex/convex-backend
- Railway volumes: https://docs.railway.com/volumes

### Implementation Details

| Service | Source | Purpose |
|---|---|---|
| Convex Backend | this repo, `services/backend` (official `convex-backend` image + start wrapper) | API, function runtime, scheduler, HTTP actions (`/http`), port 3210, volume `/convex/data` |
| Convex Dashboard | `ghcr.io/convex/convex-dashboard`, same commit | Data browser, logs, function runner, environment variables; login with the admin key |
| Postgres | `ghcr.io/railwayapp-templates/postgres-ssl:18` | Document and index storage (database `convex_self_hosted`) |

**First steps**

1. Open **Convex Backend** → Deployments → the latest deploy log and copy the line after `Admin key`. Store it in a password manager, then set `CONVEX_LOG_ADMIN_KEY=false` on the backend so it is no longer printed.
2. Open the **Convex Dashboard** domain and paste the admin key.
3. In your app, create `.env.local`:

```bash
CONVEX_SELF_HOSTED_URL='https://{backend-domain}'
CONVEX_SELF_HOSTED_ADMIN_KEY='{admin-key}'
```

4. Run `npx convex deploy` (or `npx convex dev`). Point the client at the same URL, for example `VITE_CONVEX_URL=https://{backend-domain}`.

HTTP actions are served under `/http` on the backend domain: a route `/webhook` is `https://{backend-domain}/http/webhook`. `CONVEX_SITE_ORIGIN` holds that base URL. If you prefer a separate domain for HTTP actions, add a second domain on the backend service with target port 3211, set `CONVEX_SITE_ORIGIN` to it and redeploy.

**Security.** The admin key grants full access to data and functions; anyone with access to the project's variables can derive it from `INSTANCE_SECRET`. The dashboard has no other login, so treat its URL as public and the key as the password. An `INSTANCE_SECRET` that is not 64 hex characters is never used: the backend keeps the secret stored on its volume (or creates one on the first start) and the log says so.

**Storage.** Documents live in Postgres. Uploaded files, deployed modules, search indexes and exports stay on the backend's volume (Hobby: up to 5 GB per volume by default). Convex's S3 mode needs five separate buckets with one shared key pair, which a single Railway Bucket cannot provide, so the template keeps the local-storage mode. Back up with `npx convex export` and restore with `npx convex import`.

**Scaling.** The self-hosted backend is a single process; give it more memory and CPU as load grows (it runs functions in V8 isolates). Keep Postgres in the same Railway region. Concurrency limits can be raised with `APPLICATION_MAX_CONCURRENT_QUERIES`, `..._MUTATIONS`, `..._V8_ACTIONS` and `..._NODE_ACTIONS` (default 16).

**Versions.** Convex publishes self-hosted images per commit. The backend tag and digest are in `services/backend/Dockerfile`, the dashboard's in `template.json`; upgrade both to the same commit after an export, as described in the upstream `upgrading.md`.

**License.** The Convex backend is under the Functional Source License (FSL-1.1-Apache-2.0): you may run it for your own apps and products, but not offer it to others as a competing hosted Convex service. Each version becomes Apache-2.0 two years after release. This template is a self-hosting aid, not affiliated with Convex, Inc.

### Why Deploy Convex on Railway?

Railway runs the backend, the dashboard and Postgres as one project on a private network with HTTPS domains, so a self-hosted Convex is a few minutes from deploy to `npx convex deploy`. You pay for the resources the services use, can resize them at any time, and keep your data in your own account.
