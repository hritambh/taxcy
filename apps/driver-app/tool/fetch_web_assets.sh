#!/usr/bin/env bash
# Downloads the SQLite WebAssembly module and the drift web worker into web/,
# matching the sqlite3 and drift versions in pubspec.lock. Re-run after upgrading
# either package (the driver app's local database needs both in the browser).
set -euo pipefail
cd "$(dirname "$0")/.."

locked() {
  awk -v p="  $1:" '$0 == p { found = 1 } found && /version:/ { gsub(/"/, "", $2); print $2; exit }' pubspec.lock
}

sqlite3_version=$(locked sqlite3)
drift_version=$(locked drift)

curl -fsSL -o web/sqlite3.wasm \
  "https://github.com/simolus3/sqlite3.dart/releases/download/sqlite3-${sqlite3_version}/sqlite3.wasm"
curl -fsSL -o web/drift_worker.js \
  "https://github.com/simolus3/drift/releases/download/drift-${drift_version}/drift_worker.js"

echo "web/sqlite3.wasm (sqlite3 ${sqlite3_version}) and web/drift_worker.js (drift ${drift_version}) updated"
