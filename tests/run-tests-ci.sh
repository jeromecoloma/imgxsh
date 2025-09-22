#!/usr/bin/env bash

# CI-optimized test runner for imgxsh
# This script runs tests in CI environments with proper setup and error handling

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Resolve Bats command (prefer vendored, fallback to system)
resolve_bats_cmd() {
    local vendored_bats="$PROJECT_ROOT/tests/bats-core/bin/bats"

    if [ -x "$vendored_bats" ]; then
        echo "$vendored_bats"
        return 0
    fi

    if command -v bats >/dev/null 2>&1; then
        command -v bats
        return 0
    fi

    echo "" # not found
    return 1
}

# Ensure Bats is available (vendored or system-installed)
BATS_CMD="$(resolve_bats_cmd || true)"
if [ -z "${BATS_CMD}" ]; then
    echo "⚠️  Bats not found. Attempting automatic setup (vendored bats-core)..."
    if "$PROJECT_ROOT/tests/run-tests.sh" --setup; then
        echo "✅ Bats-core setup completed successfully"
    else
        echo "❌ Bats setup failed. Skipping tests." >&2
        exit 0
    fi
    BATS_CMD="$(resolve_bats_cmd || true)"
fi

if [ -z "${BATS_CMD}" ]; then
    # As a last resort, try fixing executable bits and re-resolving
    if [ -f "$PROJECT_ROOT/tests/bats-core/bin/bats" ]; then
        chmod +x "$PROJECT_ROOT/tests/bats-core/bin/bats" 2>/dev/null || true
        if [ -d "$PROJECT_ROOT/tests/bats-core/libexec/bats-core" ]; then
            chmod +x "$PROJECT_ROOT/tests/bats-core/libexec/bats-core"/* 2>/dev/null || true
        fi
        BATS_CMD="$(resolve_bats_cmd || true)"
    fi
fi

if [ -z "${BATS_CMD}" ]; then
    echo "❌ No Bats executable available after setup. Exiting." >&2
    exit 1
fi

# Set up comprehensive CI environment
if [[ -f "$PROJECT_ROOT/tests/setup-ci-environment.sh" ]]; then
	echo "🔧 Setting up CI environment..."
	# shellcheck source=tests/setup-ci-environment.sh
	source "$PROJECT_ROOT/tests/setup-ci-environment.sh"
else
	echo "⚠️  CI environment setup script not found, using basic setup"
	export CI=true
	export SHELL_STARTER_CI_MODE=true
fi

# Initialize test tracking
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# Function to run individual test files (following Shell Starter pattern)
run_test_file() {
	local test_file="$1"
	echo "Running: $test_file"
	
	# Run each test file with timeout (if available)
	if command -v timeout >/dev/null 2>&1; then
		# Use timeout if available (most Linux systems)
        if timeout 120s "$BATS_CMD" "$PROJECT_ROOT/$test_file"; then
			file_tests=$(grep -c "^@test" "$PROJECT_ROOT/$test_file" 2>/dev/null || echo 0)
			echo "✅ Passed: $test_file ($file_tests tests)"
			TOTAL_TESTS=$((TOTAL_TESTS + file_tests))
			PASSED_TESTS=$((PASSED_TESTS + file_tests))
			return 0
		else
			echo "❌ Failed: $test_file"
			file_tests=$(grep -c "^@test" "$PROJECT_ROOT/$test_file" 2>/dev/null || echo 0)
			TOTAL_TESTS=$((TOTAL_TESTS + file_tests))
			FAILED_TESTS=$((FAILED_TESTS + file_tests))
			return 1
		fi
	else
		# Run without timeout in containers that don't support it
		echo "⚠️  Running without timeout (not available in this environment)"
        if "$BATS_CMD" "$PROJECT_ROOT/$test_file"; then
			file_tests=$(grep -c "^@test" "$PROJECT_ROOT/$test_file" 2>/dev/null || echo 0)
			echo "✅ Passed: $test_file ($file_tests tests)"
			TOTAL_TESTS=$((TOTAL_TESTS + file_tests))
			PASSED_TESTS=$((PASSED_TESTS + file_tests))
			return 0
		else
			echo "❌ Failed: $test_file"
			file_tests=$(grep -c "^@test" "$PROJECT_ROOT/$test_file" 2>/dev/null || echo 0)
			TOTAL_TESTS=$((TOTAL_TESTS + file_tests))
			FAILED_TESTS=$((FAILED_TESTS + file_tests))
			return 1
		fi
	fi
}

# Run imgxsh tests in CI mode
echo "Running imgxsh tests in CI mode..."
echo "================================================================"

if [[ -n "${IMGXSH_SKIP_IMAGE_TESTS:-}" && "$IMGXSH_SKIP_IMAGE_TESTS" == "true" ]]; then
	echo "ℹ️  Image processing tests are skipped (ImageMagick not available)"
	echo "   This is normal in CI environments without ImageMagick installed"
fi

echo ""

# Find and run test files (following Shell Starter pattern)
echo "Looking for test files in: $PROJECT_ROOT/tests/"

# Find all .bats files, excluding framework test files
test_files=()
if ls "$PROJECT_ROOT/tests"/*.bats >/dev/null 2>&1; then
	while IFS= read -r -d '' file; do
		# Skip framework test files (bats-assert, bats-core, bats-support)
		if [[ "$file" == *"/bats-assert/"* ]] || [[ "$file" == *"/bats-core/"* ]] || [[ "$file" == *"/bats-support/"* ]]; then
			continue
		fi
		# Convert to relative path
		relative_file="${file#$PROJECT_ROOT/}"
		test_files+=("$relative_file")
	done < <(find "$PROJECT_ROOT/tests" -name "*.bats" -not -path "*/bats-*/*" -print0 | sort -z)
fi

if [[ ${#test_files[@]} -eq 0 ]]; then
	echo "⚠️  No test files found in tests/ directory"
	echo "   This might be expected if tests are not set up yet"
	exit 0
fi

echo "Found ${#test_files[@]} test file(s):"
for file in "${test_files[@]}"; do
	echo "  - $file"
done
echo ""

# Run each test file
failed_files=()
for test_file in "${test_files[@]}"; do
	if ! run_test_file "$test_file"; then
		failed_files+=("$test_file")
	fi
	echo ""
done

# Summary
echo "imgxsh CI Test Summary"
echo "======================"
echo "Total tests: $TOTAL_TESTS"
echo "Passed tests: $PASSED_TESTS"
echo "Failed tests: $FAILED_TESTS"
echo "Test files: ${#test_files[@]}"
echo "Failed files: ${#failed_files[@]}"

if [[ ${#failed_files[@]} -gt 0 ]]; then
	echo ""
	echo "❌ Failed test files:"
	for file in "${failed_files[@]}"; do
		echo "  - $file"
	done
	echo ""
	echo "💡 Debugging tips:"
	echo "   - Check if all dependencies are installed"
	echo "   - Run tests locally: ./tests/run-tests.sh"
    echo "   - Run individual test: $BATS_CMD tests/[filename].bats"
	echo ""
	exit 1
else
	echo ""
	echo "🎉 All imgxsh tests passed in CI mode!"
	exit 0
fi
