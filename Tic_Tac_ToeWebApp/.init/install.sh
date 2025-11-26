#!/usr/bin/env bash
set -euo pipefail
WORKSPACE="/home/kavia/workspace/code-generation/tic-tac-toe-178384-178443/Tic_Tac_ToeWebApp"
cd "$WORKSPACE"
# Ensure node and npm present
command -v node >/dev/null 2>&1 || { echo "node not found on PATH" >&2; exit 11; }
command -v npm >/dev/null 2>&1 || { echo "npm not found on PATH" >&2; exit 12; }
# Prefer yarn if lockfile exists
if [ -f yarn.lock ]; then
  command -v yarn >/dev/null 2>&1 || { echo "yarn not available but yarn.lock present" >&2; exit 20; }
  CI=true yarn --frozen-lockfile --silent || { echo "yarn install failed" >&2; exit 21; }
elif [ -f package-lock.json ]; then
  CI=true npm ci --no-audit --silent || { echo "npm ci failed" >&2; exit 22; }
else
  CI=true npm i --no-audit --silent || { echo "npm install failed" >&2; exit 23; }
fi
# Log versions for observability (non-fatal)
npm -v 2>/dev/null || true
yarn -v 2>/dev/null || true
node -v 2>/dev/null || true
# Verify essential packages
if [ ! -d node_modules/react ] || [ ! -f node_modules/.bin/react-scripts ]; then
  echo "essential packages missing (react/react-scripts)" >&2
  exit 24
fi
