#!/usr/bin/env bash
set -euo pipefail
umask 077

# Runs only inside the temporary Colab VM.
STRATA_REF='v0.1.41'
MODEL='IQ2_XS'
CONTEXT=32768
PORT=8080

cd /content
if [[ ! -d /content/strata/.git ]]; then
  git clone --depth 1 --branch "$STRATA_REF" \
    https://github.com/Niko1221/Strata.git /content/strata
fi
cd /content/strata
exec bash ./setup.sh \
  --yes --family qwen \
  --vision yes --no-browser \
  --host 127.0.0.1 --port "$PORT"
