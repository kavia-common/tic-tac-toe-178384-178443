#!/usr/bin/env bash
set -euo pipefail
# validation - build app, publish build to /app/build and verify via static server
WORKSPACE="/home/kavia/workspace/code-generation/tic-tac-toe-178384-178443/Tic_Tac_ToeWebApp"
OUTDIR="/app/build"
PORT=5000
cd "$WORKSPACE"
# headless build
CI=true npm run build --silent
# ensure OUTDIR exists and is writable, normalize ownership to current user when sudo is available
sudo mkdir -p "$(dirname "$OUTDIR")" "$OUTDIR"
sudo rm -rf "$OUTDIR"/* || true
sudo cp -a build/. "$OUTDIR"/
# ensure ownership matches invoking user when not root
if [ "$(id -u)" -ne 0 ]; then
  SUDO_USER=${SUDO_USER:-$(whoami)}
  sudo chown -R "$SUDO_USER":"$SUDO_USER" "$(dirname "$OUTDIR")" || true
fi
LOGFILE="/tmp/static_server_$$.log"
# start http-server in its own process group and capture logs
setsid npx --yes http-server "$OUTDIR" -p $PORT >"$LOGFILE" 2>&1 &
SERVER_PID=$!
# get process group id
PGID=$(ps -o pgid= -p "$SERVER_PID" | tr -d ' ')
trap 'if [ -n "${PGID:-}" ]; then kill -TERM -$PGID >/dev/null 2>&1 || true; fi' EXIT
# wait up to 30s for readiness
WAIT=0
while [ $WAIT -lt 30 ]; do
  if command -v curl >/dev/null 2>&1; then curl -sSf "http://127.0.0.1:$PORT" >/dev/null && break; fi
  if command -v wget >/dev/null 2>&1; then wget -q --spider "http://127.0.0.1:$PORT" && break; fi
  sleep 1; WAIT=$((WAIT+1))
done
if [ $WAIT -ge 30 ]; then
  echo "static server failed to start; see $LOGFILE" >&2
  sed -n '1,200p' "$LOGFILE" >&2 || true
  kill -TERM -$PGID >/dev/null 2>&1 || true
  exit 50
fi
# verify index.html is present and contains CRA root div (best-effort)
if [ -f "$OUTDIR/index.html" ]; then
  if ! grep -E "<div id=\"root\"|<div id='root'" "$OUTDIR/index.html" >/dev/null 2>&1; then
    echo "warning: index.html missing expected root element" >&2
  fi
else
  echo "index.html missing in build output" >&2
  ls -1 "$OUTDIR" | sed -n '1,200p' >&2 || true
  kill -TERM -$PGID >/dev/null 2>&1 || true
  exit 52
fi
# list a few build files for evidence
ls -1 "$OUTDIR" | sed -n '1,200p' || true
# stop server cleanly
kill -TERM -$PGID >/dev/null 2>&1 || true
wait "$SERVER_PID" 2>/dev/null || true
trap - EXIT
