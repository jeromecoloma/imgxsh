#!/usr/bin/env bash

set -euo pipefail

# Consistent shfmt options (can be overridden via SHFMT_OPTS)
: "${SHFMT_OPTS:=-i 2 -ci -bn -s}"

if ! command -v shfmt >/dev/null 2>&1; then
  echo "⚠️  shfmt not found. Install with: brew install shfmt" >&2
  exit 1
fi

# Read shared exclude patterns
EXCLUDES_FILE="$(dirname "$0")/.shfmtignore"
exclude_args=()
if [[ -f $EXCLUDES_FILE ]]; then
  while IFS= read -r line; do
    [[ -z $line || $line =~ ^# ]] && continue
    exclude_args+=(-not -path "$line")
  done <"$EXCLUDES_FILE"
fi

# Build file list matching lefthook.yml scope
# Run shfmt diff; don't exit the script on nonzero here so we can print diffs
set +e
diff_output=$(find . \( -name "*.sh" -o -path "./bin/*" \) -type f \
  "${exclude_args[@]}" \
  -exec shfmt $SHFMT_OPTS -d {} +)
shfmt_status=$?
set -e

if [[ ${shfmt_status} -ne 0 || -n ${diff_output} ]]; then
  echo "$diff_output"
  echo "✖ shfmt detected formatting issues. Fix them with:"
  echo "  scripts/shfmt-fix.sh"
  exit 1
fi
