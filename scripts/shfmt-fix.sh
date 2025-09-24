#!/usr/bin/env bash

set -euo pipefail

if ! command -v shfmt >/dev/null 2>&1; then
	echo "⚠️  shfmt not found. Install with: brew install shfmt" >&2
	exit 1
fi

echo "🛠  Applying shfmt fixes..."

# Read shared exclude patterns
EXCLUDES_FILE="$(dirname "$0")/.shfmtignore"
exclude_args=()
if [[ -f $EXCLUDES_FILE ]]; then
	while IFS= read -r line; do
		[[ -z $line || $line =~ ^# ]] && continue
		exclude_args+=(-not -path "$line")
	done <"$EXCLUDES_FILE"
fi

find . \( -name "*.sh" -o -path "./bin/*" \) -type f \
	"${exclude_args[@]}" \
	-exec shfmt -w {} +

echo "✅ shfmt fixes applied"
