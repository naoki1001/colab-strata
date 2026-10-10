#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/lib.sh"

close_tunnel
colab stop -s "$COLAB_SESSION"
echo 'Colab session release requested.'
