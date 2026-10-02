#!/bin/sh
# HNPM bootstrap installer (no HAP installer needed).
#
#   wget -O - https://raw.githubusercontent.com/nknkol/HNPM/dist/install.sh | sh
#   sh install.sh [--no-browser] [-v] [local.hap]
#
# Downloads the self-signed hnpm CLI, which logs in to the DevEco account, signs the HNPM HAP
# with a one-off debug certificate, installs it through the local hdcd and then deletes the
# certificate (cloud + local). The CLI binary is removed afterwards.
#
# The system (toybox) wget cannot handle the oversized headers of github.com release redirects,
# so this script and the CLI are served from the `dist` branch via raw.githubusercontent.com;
# the CLI then downloads the HAP from the GitHub release with its own HTTP client.
#
# Env: HNPM_REPO (nknkol/HNPM), HNPM_CLI_BASE, HNPM_RELEASE_BASE, HNPM_HOME (~/.hnpm), HNPM_TMPDIR, HNPM_KEEP_CLI=1
set -eu

REPO="${HNPM_REPO:-nknkol/HNPM}"
BASE="${HNPM_RELEASE_BASE:-https://github.com/$REPO/releases/latest/download}"
CLI_BASE="${HNPM_CLI_BASE:-https://raw.githubusercontent.com/$REPO/dist}"
HNPM_HOME="${HNPM_HOME:-$HOME/.hnpm}"

die() {
  printf 'hnpm-install: %s\n' "$*" >&2
  exit 1
}

fetch() {
  if command -v wget >/dev/null 2>&1; then
    wget -O "$2" "$1"
  elif command -v curl >/dev/null 2>&1; then
    curl -fL -o "$2" "$1"
  else
    die "需要 wget 或 curl"
  fi
}

[ "$(uname -m)" = "aarch64" ] || die "仅支持 aarch64 设备"

if [ -z "${HNPM_TMPDIR:-}" ]; then
  if [ -d /data/storage/el2/base/cache ]; then
    # Cleaned by the system even if we are killed before our own cleanup runs.
    HNPM_TMPDIR=/data/storage/el2/base/cache/hnpm
  else
    HNPM_TMPDIR="$HNPM_HOME/tmp"
  fi
fi
export HNPM_TMPDIR
mkdir -p "$HNPM_TMPDIR" || die "无法创建 $HNPM_TMPDIR"
BIN="$HNPM_TMPDIR/hnpm-bootstrap.$$"
if [ "${HNPM_KEEP_CLI:-0}" = "1" ]; then
  mkdir -p "$HNPM_HOME/bin"
  BIN="$HNPM_HOME/bin/hnpm"
else
  trap 'rm -f "$BIN"' EXIT INT TERM
fi

echo "==> 下载 hnpm CLI"
fetch "$CLI_BASE/hnpm-cli-aarch64" "$BIN.part" || die "下载失败: $CLI_BASE/hnpm-cli-aarch64"
mv -f "$BIN.part" "$BIN"
chmod 700 "$BIN"

# With `... | sh` our stdin is this script; hand the terminal to the CLI so the user can
# paste a tempToken manually if the browser callback cannot reach it.
status=0
if (exec </dev/tty) 2>/dev/null; then
  "$BIN" self-install --release-base "$BASE" "$@" </dev/tty || status=$?
else
  "$BIN" self-install --release-base "$BASE" "$@" </dev/null || status=$?
fi
exit "$status"
