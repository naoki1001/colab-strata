#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/lib.sh"

colab status -s "$COLAB_SESSION"

if [[ -S "$SOCKET_PATH" ]] && \
  ssh -S "$SOCKET_PATH" -O check root@colab-strata >/dev/null 2>&1; then
  echo 'SSH tunnel: connected'
  echo '--- Colab setup logs (last 20 lines) ---'
  # Reuse the existing master connection. Never open a second Colab SSH
  # connection: the backend rejects simultaneous connections with HTTP 429.
  ssh -S "$SOCKET_PATH" \
    -o ControlMaster=no \
    -o ProxyCommand=false \
    -o BatchMode=yes \
    root@colab-strata \
    'if [ -f /content/colab-strata.log ]; then tail -n 20 /content/colab-strata.log; else echo "setup log not created yet"; fi' \
    || echo 'Could not read remote logs over the existing SSH tunnel.' >&2
elif [[ -S "$SOCKET_PATH" ]]; then
  echo 'SSH tunnel: stale control socket (not connected)'
else
  echo 'SSH tunnel: not running'
fi

if command -v curl >/dev/null && \
  curl -fsS --max-time 3 "http://127.0.0.1:${COLAB_LOCAL_PORT}/v1/models" >/dev/null 2>&1; then
  echo "API: ready at http://127.0.0.1:${COLAB_LOCAL_PORT}/v1"
else
  echo 'API: not ready (check logs for download / startup progress)'
fi
