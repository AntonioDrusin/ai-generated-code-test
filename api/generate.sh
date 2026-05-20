#!/usr/bin/env bash
# Regenerate the typed API client libraries from openapi.yaml.
#
# This script only invokes codegen tools. Project structure files
# (csproj / package.json / tsconfig.json / hand-written wrappers) are
# committed alongside each library and are not produced by this script.
#
#   C#         -> csharp/api-library/Generated/   (Kiota)
#   Python     -> python/api-library/             (openapi-python-client)
#   TypeScript -> acceptance/api-library/src/client/ (Hey API)

set -euo pipefail

API_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$API_DIR/.." && pwd)"
SPEC="$API_DIR/openapi.yaml"

if [[ ! -f "$SPEC" ]]; then
  echo "ERROR: $SPEC not found" >&2
  exit 1
fi

# Convert a unix path to a native Windows path under Git Bash / MSYS so
# .NET and Node-based tools resolve it cleanly. No-op elsewhere.
to_native() {
  if command -v cygpath >/dev/null 2>&1; then
    cygpath -w "$1"
  else
    printf '%s' "$1"
  fi
}

require() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "ERROR: required tool '$1' not on PATH" >&2; exit 1
  }
}

require dotnet
require python
require npm
require npx

SPEC_NATIVE="$(to_native "$SPEC")"

# ──────────────────────────────────────────────────────────────────────
# C# — Kiota
# ──────────────────────────────────────────────────────────────────────
echo "==> [1/3] C# (Kiota)"
CSHARP_DIR="$ROOT/csharp/api-library"

if ! command -v kiota >/dev/null 2>&1; then
  echo "    installing Microsoft.OpenApi.Kiota as a global dotnet tool..."
  dotnet tool install --global Microsoft.OpenApi.Kiota
  export PATH="$HOME/.dotnet/tools:$PATH"
  require kiota
fi

kiota generate \
  --language csharp \
  --openapi "$SPEC_NATIVE" \
  --output "$(to_native "$CSHARP_DIR/Generated")" \
  --namespace-name MusicStream.ApiLibrary.Generated \
  --class-name MusicStreamApiClient \
  --clean-output

( cd "$CSHARP_DIR" && dotnet restore >/dev/null )

# ──────────────────────────────────────────────────────────────────────
# Python — openapi-python-client
# ──────────────────────────────────────────────────────────────────────
echo "==> [2/3] Python (openapi-python-client)"
PY_OUT="$ROOT/python/api-library"

if command -v pipx >/dev/null 2>&1; then
  pipx install --force openapi-python-client >/dev/null
else
  python -m pip install --quiet --upgrade openapi-python-client
fi

# Clean regeneration so removed schemas/endpoints don't linger.
rm -rf "$PY_OUT"
( cd "$ROOT/python" && openapi-python-client generate \
    --path "$SPEC_NATIVE" \
    --output-path "$(to_native "$PY_OUT")" \
    --overwrite )

# ──────────────────────────────────────────────────────────────────────
# TypeScript — Hey API (@hey-api/openapi-ts)
# ──────────────────────────────────────────────────────────────────────
echo "==> [3/3] TypeScript (Hey API)"
TS_DIR="$ROOT/acceptance/api-library"

# Clean regeneration so removed schemas/endpoints don't linger.
rm -rf "$TS_DIR/src/client"
( cd "$TS_DIR" && npm install --silent && npm run generate )

echo
echo "Done."
echo "  C#         : $CSHARP_DIR        (dotnet build)"
echo "  Python     : $PY_OUT            (pip install -e .)"
echo "  TypeScript : $TS_DIR            (npm run build)"
