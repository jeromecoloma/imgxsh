#!/usr/bin/env bash

set -euo pipefail

# Allow custom shellcheck options via env; defaults are reasonable and fast
: "${SHELLCHECK_OPTS:=-x}"

if ! command -v shellcheck >/dev/null 2>&1; then
  echo "⚠️  ShellCheck not found. Install with: brew install shellcheck" >&2
  exit 1
fi

echo "🔍 Running ShellCheck..."

# Match lefthook.yml scope exactly
set +e
find . \( -name "*.sh" -o -path "./bin/*" \) -type f \
  -not -path "./tests/bats-*/*" \
  -not -path "./shell-starter-tests/*" \
  -not -path "./.development/*" \
  -not -path "./.ai-workflow/*" \
  -exec shellcheck $SHELLCHECK_OPTS {} +
status=$?
set -e

if [[ $status -ne 0 ]]; then
  echo "✖ ShellCheck found issues."
  echo "  Tip: run 'shellcheck <file>' to see details, or install an editor plugin."
  exit $status
fi

echo "✅ ShellCheck passed"
