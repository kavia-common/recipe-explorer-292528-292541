#!/usr/bin/env bash
set -euo pipefail
# Ensure script runs in authoritative workspace
WORKSPACE="/home/kavia/workspace/code-generation/recipe-explorer-292528-292541/mobile_app"
cd "$WORKSPACE"
# ensure sqlite3 and rsync are present (idempotent)
command -v sqlite3 >/dev/null 2>&1 || (sudo apt-get update -q && sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -q sqlite3 >/dev/null)
command -v rsync >/dev/null 2>&1 || (sudo apt-get update -q && sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -q rsync >/dev/null)
# Validate node major version if node exists (do not reinstall node if preinstalled)
if command -v node >/dev/null 2>&1; then
  NODE_MAJOR=$(node -e "console.log(process.versions.node.split('.')[0])")
  if [ "${NODE_MAJOR:-0}" -lt 14 ]; then
    echo "Warning: Node major version <14 detected ($NODE_MAJOR); some tooling may fail" >&2
  fi
fi
# Install npm deps non-interactively only if package.json exists
if [ -f package.json ]; then
  if command -v npm >/dev/null 2>&1; then
    if [ -f package-lock.json ]; then
      npm ci --silent --no-audit --no-fund
    else
      npm i --silent --no-audit --no-fund
    fi
  else
    echo "Error: npm not found but package.json exists" >&2
    exit 3
  fi
fi
# Quick verify sqlite3 usable
if ! sqlite3 --version >/dev/null 2>&1; then
  echo "Error: sqlite3 not available after install" >&2
  exit 2
fi
