#!/usr/bin/env bash
set -euo pipefail
WORKSPACE="/home/kavia/workspace/code-generation/tic-tac-toe-178384-178443/Tic_Tac_ToeWebApp"
cd "$WORKSPACE"
# create minimal CRA-friendly smoke test using testing-library render
mkdir -p src/__tests__
TESTFILE="src/__tests__/App.test.js"
if [ ! -f "$TESTFILE" ]; then cat > "$TESTFILE" <<'EOF'
import React from 'react';
import { render } from '@testing-library/react';
import App from '../App';

test('renders App without crashing', () => {
  const { container } = render(<App />);
  expect(container).toBeDefined();
});
EOF
fi
# detect package manager and install @testing-library/react only if required
if node -e "try{require.resolve('@testing-library/react'); process.exit(0);}catch(e){process.exit(1);}" >/dev/null 2>&1; then
  # already present
  :
else
  if [ -f yarn.lock ]; then
    CI=true yarn add -D @testing-library/react --silent || { echo "failed to add @testing-library/react with yarn" >&2; exit 30; }
  elif [ -f package-lock.json ]; then
    CI=true npm ci --no-audit --no-fund --silent || true
    CI=true npm i -D @testing-library/react --silent || { echo "failed to add @testing-library/react with npm" >&2; exit 31; }
  else
    CI=true npm i -D @testing-library/react --silent || { echo "failed to add @testing-library/react" >&2; exit 32; }
  fi
fi
# Run tests once (CI=true and disable watch)
CI=true npm test -- --watchAll=false || { echo "tests failed" >&2; exit 33; }
