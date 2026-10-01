#!/usr/bin/env bash
# Downloads the SQLite WebAssembly build and Drift web worker that match the
# versions in pubspec.lock. Run after upgrading drift or sqlite3.
set -euo pipefail
cd "$(dirname "$0")/.."

version_of() {
  awk -v pkg="  $1:" '$0 == pkg {found=1} found && /version:/ {gsub(/"/, "", $2); print $2; exit}' pubspec.lock
}

sqlite3_version=$(version_of sqlite3)
drift_version=$(version_of drift)
echo "sqlite3 ${sqlite3_version}, drift ${drift_version}"

curl -fsSL -o web/sqlite3.wasm \
  "https://github.com/simolus3/sqlite3.dart/releases/download/sqlite3-${sqlite3_version}/sqlite3.wasm"
curl -fsSL -o web/drift_worker.js \
  "https://github.com/simolus3/drift/releases/download/drift-${drift_version}/drift_worker.js"
echo "Updated web/sqlite3.wasm and web/drift_worker.js"
