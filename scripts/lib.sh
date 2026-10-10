#!/usr/bin/env bash
set -euo pipefail
umask 077

# Protect credentials and session state written by Colab CLI.
COLAB_CLI_DIR="$HOME/.config/colab-cli"
mkdir -p "$COLAB_CLI_DIR"
chmod 700 "$COLAB_CLI_DIR"
find "$COLAB_CLI_DIR" -maxdepth 1 -type f -exec chmod 600 {} +

COLAB_SESSION="${COLAB_SESSION:-colab-strata}"
COLAB_GPU="${COLAB_GPU:-A100}"
COLAB_LOCAL_PORT="${COLAB_LOCAL_PORT:-8080}"
COLAB_HIGH_MEM="${COLAB_HIGH_MEM:-1}"

if [[ ! "$COLAB_SESSION" =~ ^[A-Za-z0-9_-]+$ ]]; then
  echo 'COLAB_SESSION must contain only letters, digits, _ or -' >&2
  exit 2
fi
if [[ ! "$COLAB_LOCAL_PORT" =~ ^[0-9]+$ ]] || (( COLAB_LOCAL_PORT < 1 || COLAB_LOCAL_PORT > 65535 )); then
  echo 'COLAB_LOCAL_PORT must be 1..65535' >&2
  exit 2
fi

STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/colab-strata"
KEY_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/colab-strata"
KEY_PATH="$KEY_DIR/id_ed25519"
SOCKET_PATH="$STATE_DIR/${COLAB_SESSION}.sock"
CLI_PACKAGE='google-colab-cli==0.7.4'

colab() {
  uvx --python 3.12 --from "$CLI_PACKAGE" colab --auth oauth2 "$@"
}

ensure_ssh_key() {
  mkdir -p "$KEY_DIR" "$STATE_DIR"
  chmod 700 "$KEY_DIR" "$STATE_DIR"
  if [[ ! -f "$KEY_PATH" ]]; then
    (umask 077; ssh-keygen -q -t ed25519 -N '' -f "$KEY_PATH" -C colab-strata)
  fi
  chmod 600 "$KEY_PATH"
}

ssh_colab() {
  # SSH-over-WebSocket ProxyCommand is provided by the official Colab CLI.
  # Quote values for the shell spawned by OpenSSH to interpret ProxyCommand.
  local key_q session_q
  printf -v key_q '%q' "$KEY_PATH"
  printf -v session_q '%q' "$COLAB_SESSION"
  local proxy_cmd="uvx --python 3.12 --from $CLI_PACKAGE colab --auth oauth2 ssh --proxy-mode -s $session_q -i $key_q"
  ssh -i "$KEY_PATH" \
    -o "ProxyCommand=$proxy_cmd" \
    -o BatchMode=yes \
    -o StrictHostKeyChecking=no \
    -o UserKnownHostsFile=/dev/null \
    -o ServerAliveInterval=30 \
    -o ServerAliveCountMax=3 \
    "$@"
}

close_tunnel() {
  if [[ -S "$SOCKET_PATH" ]]; then
    ssh -S "$SOCKET_PATH" -O exit root@colab-strata 2>/dev/null || true
  fi
  rm -f "$SOCKET_PATH"
}
