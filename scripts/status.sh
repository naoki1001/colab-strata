#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/lib.sh"

colab status -s "$COLAB_SESSION"
if [[ -S "$SOCKET_PATH" ]]; then
  echo 'SSH tunnel: socket exists (may still be stale)'
else
  echo 'SSH tunnel: not running'
fi

if [[ -f "$KEY_PATH" ]]; then
  echo '--- Colab setup logs (last 20 lines) ---'
  ssh_colab root@colab-strata \
    'if [ -f /content/colab-strata.log ]; then tail -n 20 /content/colab-strata.log; else echo "setup log not created yet"; fi' \
    || echo 'Could not read remote logs; SSH may be unavailable.' >&2
fi

if command -v curl >/dev/null && \
  curl -fsS --max-time 3 "http://127.0.0.1:${COLAB_LOCAL_PORT}/v1/models" >/dev/null 2>&1; then
  echo "API: ready at http://127.0.0.1:${COLAB_LOCAL_PORT}/v1"
else
  echo 'API: not ready (check logs for download / startup progress)'
fi
