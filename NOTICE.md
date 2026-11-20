# NOTICE

This is a community template for self-hosting Convex on Railway. It is not affiliated with or endorsed by Convex, Inc. or Railway. This file is a summary for attribution, not legal advice.

## License of the software (read this)

The Convex backend and dashboard are licensed under the **Functional Source License, Version 1.1, Apache 2.0 Future License (FSL-1.1-Apache-2.0)**, Copyright Convex, Inc.

- Permitted: using, copying, modifying and running the software for any purpose other than a *Competing Use*. Self-hosting Convex as the backend of your own applications, internal tools or products is permitted.
- Not permitted: making the software available to others in a commercial product or service that substitutes for Convex or for another Convex product (for example, selling hosted Convex backends to third parties).
- Each version converts to the Apache License 2.0 on the second anniversary of its release.

This template only deploys the unmodified images into the deploying user's own Railway account for that user's own use. Deciding whether a particular use is a Competing Use is the deploying user's responsibility; read the full text at https://github.com/get-convex/convex-backend/blob/main/LICENSE.md.

## Software the template runs (unmodified)

| Component | Version | Source | License |
|---|---|---|---|
| Convex backend | commit `9fde7cb10083b101c27cd99a83553ce59d7b2034` (release `precompiled-2026-11-19-9fde7cb`), image `ghcr.io/convex/convex-backend@sha256:1e64c93ce0a6cff9b039d7fb38b81ad0bccedf80072736a8412a622730c86115` | https://github.com/get-convex/convex-backend | FSL-1.1-Apache-2.0, Copyright Convex, Inc. |
| Convex dashboard | same commit, image `ghcr.io/convex/convex-dashboard@sha256:85c1726baa1cb10bfdce9cb2ed40a116effa001487e6eb32efe2c1063b776756` | same repository (`npm-packages/dashboard-self-hosted`) | FSL-1.1-Apache-2.0, Copyright Convex, Inc. |
| PostgreSQL | 18, `ghcr.io/railwayapp-templates/postgres-ssl:18` | https://github.com/railwayapp-templates/postgres-ssl | PostgreSQL License; Railway image MIT |

The backend image gets one extra file, `convex-railway.sh`, which checks `INSTANCE_SECRET`, `INSTANCE_NAME` and `POSTGRES_URL`, prints the admin key with the image's own `generate_key`, and then runs the image's `run_backend.sh`. No Convex code is changed.

## Files written for this template

`services/backend/Dockerfile`, `services/backend/convex-railway.sh`, `template.json`, `TEMPLATE.md` and `README.md` were written for this template. No file or text was copied from the marketplace templates listed in TEMPLATE.md.

## Upstream files checked (2026-11-20, `main` at 9fde7cb)

`self-hosted/README.md`, `self-hosted/docker/docker-compose.yml`, `self-hosted/docker-build/run_backend.sh`, `read_credentials.sh`, `generate_admin_key.sh`, `self-hosted/advanced/postgres_or_mysql.md`, `s3_storage.md`, `upgrading.md`, `railway/README.md`, `crates/local_backend/src/config.rs` (`/http` site forwarding on the API port), `crates/aws_s3/src/storage.rs` and `crates/model/src/database_globals/mod.rs` (S3 bucket per use case, one key prefix per instance), `LICENSE.md`.
