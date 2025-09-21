#!/usr/bin/env bash
#
# CI Environment Setup Script
# Ensures consistent test environment between local development and CI

set -euo pipefail

# Get the project root directory
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "Setting up CI environment for Shell Starter tests..."

# Set consistent environment variables
export CI="${CI:-true}"
export SHELL_STARTER_CI_MODE="${SHELL_STARTER_CI_MODE:-true}"
export TERM="${TERM:-xterm-256color}"

# Create consistent temporary directory structure
# Use a more container-friendly temp directory approach
if [[ -n "${GITHUB_ACTIONS:-}" ]] || [[ -n "${ACT:-}" ]]; then
    CI_TEMP_DIR="/tmp/shell-starter-ci-$$"
else
    CI_TEMP_DIR="${TMPDIR:-/tmp}/shell-starter-ci-$$"
fi
export SHELL_STARTER_CI_TEMP="$CI_TEMP_DIR"

mkdir -p "$CI_TEMP_DIR"
chmod 755 "$CI_TEMP_DIR" 2>/dev/null || true

# Ensure required tools are available
echo "Checking required tools..."

# Check for timeout command
if ! command -v timeout >/dev/null 2>&1; then
	echo "⚠️  Warning: 'timeout' command not available - tests may run without timeouts"
else
	echo "✅ timeout command available: $(timeout --version 2>&1 | head -1)"
fi

# Check for basic POSIX tools
required_tools=("grep" "sed" "awk" "find" "xargs" "sort" "uniq")
missing_tools=()

for tool in "${required_tools[@]}"; do
	if ! command -v "$tool" >/dev/null 2>&1; then
		missing_tools+=("$tool")
	fi
done

if [[ ${#missing_tools[@]} -gt 0 ]]; then
	echo "❌ Missing required tools: ${missing_tools[*]}"
	echo "   Please install these tools before running tests"
	exit 1
else
	echo "✅ All required POSIX tools available"
fi

# Set up Git configuration if needed (for tests that create commits)
if command -v git >/dev/null 2>&1; then
	if ! git config --global user.email >/dev/null 2>&1; then
		git config --global user.email "ci@shell-starter.test" 2>/dev/null || true
		git config --global user.name "Shell Starter CI" 2>/dev/null || true
		echo "✅ Git configuration set for CI environment"
	fi
else
	echo "⚠️  Git not available in CI environment"
fi

# Create isolated shell configuration directory
SHELL_CONFIG_DIR="$CI_TEMP_DIR/shell_config"
mkdir -p "$SHELL_CONFIG_DIR"
export SHELL_STARTER_TEST_SHELL_CONFIG="$SHELL_CONFIG_DIR"

# Create fake shell rc files for testing
touch "$SHELL_CONFIG_DIR/.bashrc"
touch "$SHELL_CONFIG_DIR/.zshrc"
touch "$SHELL_CONFIG_DIR/.profile"

echo "✅ Isolated shell configuration created"

# Set up test isolation environment variables
export SHELL_STARTER_TEST_MODE=true
export SHELL_STARTER_NO_INTERACTIVE=true
export SHELL_STARTER_NO_COLORS="${SHELL_STARTER_NO_COLORS:-false}"

# Disable spinner animations in CI
export SHELL_STARTER_NO_SPINNER=true

# Set consistent PATH
export PATH="$PROJECT_ROOT/bin:$PROJECT_ROOT/demo:$PATH"

# Create manifest for cleanup
CI_MANIFEST="$CI_TEMP_DIR/.ci-manifest"
echo "$CI_TEMP_DIR" >"$CI_MANIFEST"
echo "$SHELL_CONFIG_DIR" >>"$CI_MANIFEST"
export SHELL_STARTER_CI_MANIFEST="$CI_MANIFEST"

# Display environment summary
echo ""
echo "CI Environment Setup Complete"
echo "============================="
echo "Project Root: $PROJECT_ROOT"
echo "CI Temp Dir:  $CI_TEMP_DIR"
echo "Shell Config: $SHELL_CONFIG_DIR"
echo "CI Mode:      $SHELL_STARTER_CI_MODE"
echo "No Interactive: $SHELL_STARTER_NO_INTERACTIVE"
echo "PATH: $PATH"
echo ""

# Create cleanup function
cleanup_ci_environment() {
	if [[ -f "$SHELL_STARTER_CI_MANIFEST" ]]; then
		echo "Cleaning up CI environment..."
		while IFS= read -r path; do
			if [[ -d "$path" ]]; then
				rm -rf "$path" 2>/dev/null || true
			elif [[ -f "$path" ]]; then
				rm -f "$path" 2>/dev/null || true
			fi
		done <"$SHELL_STARTER_CI_MANIFEST"
		rm -f "$SHELL_STARTER_CI_MANIFEST" 2>/dev/null || true
		echo "✅ CI environment cleanup complete"
	fi
}

# Set up trap for cleanup on exit
trap cleanup_ci_environment EXIT INT TERM

# Export cleanup function for use by test scripts
export -f cleanup_ci_environment

echo "Environment ready for testing!"
