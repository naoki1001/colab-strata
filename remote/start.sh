#!/usr/bin/env bash
set -euo pipefail
umask 077

# Runs only inside the temporary Colab VM.
STRATA_REF='v0.1.41'
PORT=18080

cd /content
if [[ ! -d /content/strata/.git ]]; then
  git clone --depth 1 --branch "$STRATA_REF" \
    https://github.com/Niko1221/Strata.git /content/strata
fi
cd /content/strata
# Ensure Python 3.12 can create virtual environments on a fresh Colab VM.
if ! /usr/bin/python3.12 -c 'import venv, ensurepip' >/dev/null 2>&1; then
  apt-get update -qq
  DEBIAN_FRONTEND=noninteractive apt-get install -y python3.12-venv
fi
# Reuse a Python 3.12 virtual environment for Strata.
if [[ ! -x .venv/bin/python ]] \
  || ! .venv/bin/python -m pip --version >/dev/null 2>&1 \
  || ! .venv/bin/python -c 'import sys; assert sys.version_info[:2] == (3, 12)' >/dev/null 2>&1; then
  rm -rf .venv
  /usr/bin/python3.12 -m venv .venv
fi
printf '[colab-strata] Using %s\n' "$(.venv/bin/python --version)"

exec bash ./setup.sh \
  --yes --family qwen \
  --vision yes --no-browser \
  --host 127.0.0.1 --port "$PORT"
