# Convex backend for Railway: the official self-hosted image plus a start wrapper that checks
# the instance credentials and prints the admin key for the dashboard and CLI.
#
# Convex publishes self-hosted images per commit (no semver). Upgrade: pick a newer tag from
# https://github.com/get-convex/convex-backend/pkgs/container/convex-backend (or ghcr.io/convex),
# bump tag + digest here and in template.json (Convex Dashboard), take an export first
# (`npx convex export`), and read self-hosted/advanced/upgrading.md.
FROM ghcr.io/convex/convex-backend:9fde7cb10083b101c27cd99a83553ce59d7b2034@sha256:1e64c93ce0a6cff9b039d7fb38b81ad0bccedf80072736a8412a622730c86115

COPY --chmod=0755 convex-railway.sh /usr/local/bin/convex-railway

# Fail the build early if the image layout this wrapper relies on changes.
RUN set -eu; \
    bash -n /usr/local/bin/convex-railway; \
    for f in run_backend.sh read_credentials.sh generate_admin_key.sh generate_key convex-local-backend; do test -e "/convex/$f"; done

WORKDIR /convex
ENTRYPOINT ["/usr/local/bin/convex-railway"]
CMD []
