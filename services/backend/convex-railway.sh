#!/bin/bash
# convex-railway: start wrapper for the self-hosted Convex backend on Railway.
#
# 1. INSTANCE_SECRET must be 64 hex characters (32 bytes). Anything else is never used: the
#    backend keeps the secret already stored on the volume, or generates one on the first
#    start (upstream read_credentials.sh), and the log says so. The deploy never fails on it.
# 2. INSTANCE_NAME must be lowercase letters, digits and dashes; it also names the Postgres
#    database (dashes become underscores). An invalid value falls back to convex-self-hosted.
# 3. Normalises POSTGRES_URL (no database path; sslmode=disable when DO_NOT_REQUIRE_SSL is set).
# 4. Prints the admin key (dashboard login, CLI deploys) when CONVEX_LOG_ADMIN_KEY=true.
#    It is derived from INSTANCE_NAME + INSTANCE_SECRET, so everyone who can read the
#    service variables can derive it anyway; set CONVEX_LOG_ADMIN_KEY=false once copied.
# 5. Runs the image's own run_backend.sh.
set -u

log() { printf '[convex-railway] %s\n' "$*"; }

cd /convex || exit 1

if [ -n "${INSTANCE_SECRET:-}" ] && ! [[ "${INSTANCE_SECRET}" =~ ^[0-9a-f]{64}$ ]]; then
  log "WARNING: INSTANCE_SECRET is not 64 lowercase hex characters; it is ignored."
  log "WARNING: using the secret stored on the volume (or a new random one on the first start)."
  unset INSTANCE_SECRET
fi

if [ -n "${INSTANCE_NAME:-}" ] && ! [[ "${INSTANCE_NAME}" =~ ^[a-z0-9]+(-[a-z0-9]+)*$ ]]; then
  log "WARNING: INSTANCE_NAME='${INSTANCE_NAME}' is invalid (lowercase letters, digits, dashes); using convex-self-hosted"
  export INSTANCE_NAME=convex-self-hosted
fi

if [ -n "${POSTGRES_URL:-}" ]; then
  # The backend appends the database name itself: drop a /dbname path, keep ?options.
  stripped="$(printf '%s' "${POSTGRES_URL}" | sed -E 's#^(postgres(ql)?://[^/?]+)(/[^?]*)?(\?.*)?$#\1\4#')"
  if [ "${stripped}" != "${POSTGRES_URL}" ]; then
    log "POSTGRES_URL contained a database name; using the server part only"
  fi
  # Railway's postgres-ssl certificate is self-signed (a CA used as the server certificate),
  # which rustls rejects even with sslmode=prefer. With DO_NOT_REQUIRE_SSL set and no
  # sslmode given, connect without TLS (Railway's private network is encrypted).
  if [ -n "${DO_NOT_REQUIRE_SSL:-}" ] && ! printf '%s' "${stripped}" | grep -q 'sslmode='; then
    case "${stripped}" in *\?*) stripped="${stripped}&sslmode=disable" ;; *) stripped="${stripped}?sslmode=disable" ;; esac
    log "DO_NOT_REQUIRE_SSL is set: connecting to Postgres with sslmode=disable"
  fi
  export POSTGRES_URL="${stripped}"
  log "database: Postgres, database $(printf '%s' "${INSTANCE_NAME:-convex-self-hosted}" | tr '-' '_')"
fi

# read_credentials.sh fills INSTANCE_NAME/INSTANCE_SECRET from the env or the volume and
# stores them on the volume, exactly as run_backend.sh does next.
# shellcheck source=/dev/null
if ! source ./read_credentials.sh; then
  log "WARNING: could not read or store the instance credentials under ${DATA_DIR:-/convex/data}"
fi

case "${CONVEX_LOG_ADMIN_KEY:-true}" in
  true|TRUE|1|yes)
    if admin_key="$(./generate_key "${INSTANCE_NAME}" "${INSTANCE_SECRET}" 2>/dev/null)" && [ -n "${admin_key}" ]; then
      log "Admin key (dashboard login and CONVEX_SELF_HOSTED_ADMIN_KEY):"
      log "${admin_key}"
      log "Set CONVEX_LOG_ADMIN_KEY=false once you have stored it."
    else
      log "WARNING: could not generate the admin key; run ./generate_admin_key.sh via railway ssh"
    fi
    ;;
  *)
    log "admin key not printed (CONVEX_LOG_ADMIN_KEY=false); run ./generate_admin_key.sh via railway ssh"
    ;;
esac
unset admin_key

log "public API ${CONVEX_CLOUD_ORIGIN:-unset}, HTTP actions ${CONVEX_SITE_ORIGIN:-unset}"
exec ./run_backend.sh "$@"
