#!/usr/bin/env bash
set -euo pipefail

# Start react-scripts dev server in its own process group and verify binding
WORKSPACE="/home/kavia/workspace/code-generation/tic-tac-toe-178384-178443/Tic_Tac_ToeWebApp"
cd "$WORKSPACE"
PORT=${PORT:-3000}
LOGFILE="/tmp/cra_dev_server_$$.log"
export BROWSER=none
export HOST=0.0.0.0
export CI=false

# Launch in separate process group so we can kill children cleanly
setsid bash -c "CI=false npm start" >"$LOGFILE" 2>&1 &
SERVER_PID=$!
PGID=$(ps -o pgid= -p "$SERVER_PID" | tr -d ' ')

# Ensure cleanup on exit or error: terminate entire process group
trap 'if [ -n "${PGID:-}" ]; then kill -TERM -$PGID >/dev/null 2>&1 || true; fi' EXIT

# Wait up to 30 seconds for server to bind
WAIT=0
while [ $WAIT -lt 30 ]; do
  if command -v curl >/dev/null 2>&1; then
    curl -sSf "http://127.0.0.1:$PORT" >/dev/null 2>&1 && break
  fi
  if command -v wget >/dev/null 2>&1; then
    wget -q --spider "http://127.0.0.1:$PORT" >/dev/null 2>&1 && break
  fi
  sleep 1
  WAIT=$((WAIT+1))
done

if [ $WAIT -ge 30 ]; then
  echo "dev server failed to start within timeout; see $LOGFILE" >&2
  sed -n '1,200p' "$LOGFILE" >&2 || true
  # best-effort cleanup
  kill -TERM -$PGID >/dev/null 2>&1 || true
  exit 40
fi

# Optional content probe: look for root div
if command -v curl >/dev/null 2>&1; then
  curl -s "http://127.0.0.1:$PORT" | grep -qi '<div id="root"' || true
fi

# Stop server cleanly
kill -TERM -$PGID >/dev/null 2>&1 || true
wait "$SERVER_PID" 2>/dev/null || true
trap - EXIT
