#!/usr/bin/env bash
set -euo pipefail
WORKSPACE="/home/kavia/workspace/code-generation/tic-tac-toe-178384-178443/Tic_Tac_ToeWebApp"
mkdir -p "$WORKSPACE"
# If package.json exists and looks like a CRA app, skip scaffolding (preserve lockfiles)
if [ -f "$WORKSPACE/package.json" ]; then
  node -e 'try{const p=require(process.argv[1]); const deps=Object.assign({},p.dependencies||{},p.devDependencies||{}); const ok=(deps.react||deps["react-dom"])|| (p.scripts && (p.scripts.start||p.scripts.build)); process.exit(ok?0:2)}catch(e){process.exit(3)}' "$WORKSPACE/package.json" 2>/dev/null && exit 0 || { echo "package.json exists but not a CRA-like app; aborting" >&2; exit 10; }
fi
TMPDIR=$(mktemp -d -t cra-tmp-XXXX)
export CI=true
export BROWSER=none
export REACT_APP_DISABLE_TELEMETRY=1
# Scaffold into TMPDIR non-interactively using npm (explicit JS template)
npx --yes create-react-app "$TMPDIR" --template javascript --use-npm --silent >"/tmp/cra_stdout_$$.log" 2>"/tmp/cra_err_$$.log" || { sed -n '1,200p' "/tmp/cra_err_$$.log" >&2 || true; rm -rf "$TMPDIR"; exit 11; }
# verify scaffold produced expected files
[ -f "$TMPDIR/package.json" ] || { echo "scaffold produced no package.json" >&2; rm -rf "$TMPDIR"; exit 12; }
node -e 'try{const p=require(process.argv[1]); const deps=Object.assign({},p.dependencies||{},p.devDependencies||{}); if(!(p.scripts&&p.scripts.start&&p.scripts.build&& (deps.react||deps["react-dom"]))) process.exit(13); }catch(e){process.exit(13)}' "$TMPDIR/package.json" || { echo "scaffold verification failed" >&2; rm -rf "$TMPDIR"; exit 13; }
# Ensure workspace is empty before atomic move to avoid overwriting existing files
if [ -n "$(ls -A "$WORKSPACE")" ]; then echo "workspace not empty; aborting move" >&2; rm -rf "$TMPDIR"; exit 14; fi
# Move all files including dotfiles atomically
sudo mv "$TMPDIR"/. "$WORKSPACE" || { echo "failed to move scaffold into workspace" >&2; rm -rf "$TMPDIR"; exit 15; }
rm -rf "$TMPDIR" || true
# Normalize ownership to invoking user when not root
if [ "$(id -u)" -ne 0 ]; then sudo chown -R "$(id -u):$(id -g)" "$WORKSPACE" || true; fi
# Ensure package.json has start/build scripts only if missing
node -e 'const fs=require("fs"),p=JSON.parse(fs.readFileSync(process.argv[1]));p.scripts=p.scripts||{};let changed=false; if(!p.scripts.start){p.scripts.start="react-scripts start";changed=true;} if(!p.scripts.build){p.scripts.build="react-scripts build";changed=true;} if(changed)fs.writeFileSync(process.argv[1],JSON.stringify(p,null,2));' "$WORKSPACE/package.json"
# Success
exit 0
