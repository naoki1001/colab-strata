#!/usr/bin/env bash
set -Eeuo pipefail
source "$(dirname "$0")/lib.sh"

command -v uvx >/dev/null || { echo 'uvx unavailable: run mise install first' >&2; exit 1; }
command -v ssh >/dev/null || { echo 'OpenSSH client is required' >&2; exit 1; }
command -v ssh-keygen >/dev/null || { echo 'ssh-keygen is required' >&2; exit 1; }
ensure_ssh_key

# Abort without assigning a second GPU when a local tunnel is already present.
if [[ -S "$SOCKET_PATH" ]]; then
  echo "A local tunnel already exists: $SOCKET_PATH" >&2
  echo 'Use mise run status or mise run down first.' >&2
  exit 1
fi

created=0
cleanup_on_failure() {
  if (( created == 1 )); then
    echo 'Startup failed. Releasing the newly allocated Colab session...' >&2
    close_tunnel
    colab stop -s "$COLAB_SESSION" || true
  fi
}
trap cleanup_on_failure ERR

args=(new -s "$COLAB_SESSION" --gpu "$COLAB_GPU")
if [[ "$COLAB_HIGH_MEM" == 1 ]]; then args+=(--high-mem); fi
printf 'Allocating Colab GPU (%s; high-mem=%s)...\n' "$COLAB_GPU" "$COLAB_HIGH_MEM"
colab "${args[@]}"
created=1

colab upload -s "$COLAB_SESSION" remote/start.sh /content/colab-strata-start.sh

# Setup/download runs entirely on the VM, detached from the SSH connection.
# Keep stdout/stderr in ephemeral /content, never in a notebook.
ssh_colab root@colab-strata \
  'nohup bash /content/colab-strata-start.sh > /content/colab-strata.log 2>&1 < /dev/null &'

mkdir -p "$STATE_DIR"
ssh_colab -f -N -M -S "$SOCKET_PATH" \
  -o ExitOnForwardFailure=yes \
  -L "127.0.0.1:${COLAB_LOCAL_PORT}:127.0.0.1:18080" \
  root@colab-strata

created=0
trap - ERR
printf 'Colab allocated; Strata installation is running in the background.\n'
printf 'Local API after model load: http://127.0.0.1:%s/v1\n' "$COLAB_LOCAL_PORT"
printf 'Check progress: mise run status\nAlways stop the VM: mise run down\n'
