#!/bin/bash
#
# run-act-compatibility.sh - Run compatibility tests locally with act
#
# This script helps run the GitHub Actions compatibility workflow locally
# using act (https://github.com/nektos/act)
#
# Usage:
#   ./scripts/run-act-compatibility.sh [ubuntu|macos|both]
#
# Examples:
#   ./scripts/run-act-compatibility.sh ubuntu    # Run only Ubuntu compatibility
#   ./scripts/run-act-compatibility.sh macos     # Run only macOS compatibility (requires platform mapping)
#   ./scripts/run-act-compatibility.sh both      # Run both platforms
#   ./scripts/run-act-compatibility.sh           # Default: run Ubuntu only
#

set -euo pipefail

# Default to Ubuntu if no argument provided
PLATFORM="${1:-ubuntu}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
	echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
	echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
	echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
	echo -e "${RED}❌ $1${NC}"
}

# Check if act is installed
if ! command -v act >/dev/null 2>&1; then
	log_error "act is not installed. Please install it first:"
	echo "  - macOS: brew install act"
	echo "  - Linux: Download from https://github.com/nektos/act/releases"
	exit 1
fi

run_ubuntu_compatibility() {
	log_info "Running Ubuntu compatibility tests with act..."
	log_info "This will use the catthehacker/ubuntu:act-latest image"

	if act -j compatibility-ubuntu; then
		log_success "Ubuntu compatibility tests passed!"
		return 0
	else
		log_error "Ubuntu compatibility tests failed!"
		return 1
	fi
}

run_macos_compatibility() {
	log_warning "macOS compatibility testing with act requires a custom runner image"
	log_info "act doesn't support macOS natively. You can:"
	echo "  1. Use a macOS-compatible Docker image (limited functionality)"
	echo "  2. Run tests on actual macOS system"
	echo "  3. Use GitHub Actions for full macOS testing"

	log_info "Attempting with platform mapping..."

	# Note: This will likely fail as act doesn't really support macOS
	if act -j compatibility-macos -P macos-latest=ubuntu:latest; then
		log_warning "macOS compatibility test ran (but with Ubuntu container)"
		return 0
	else
		log_error "macOS compatibility test failed"
		return 1
	fi
}

case "$PLATFORM" in
"ubuntu")
	log_info "Running Ubuntu compatibility tests only..."
	run_ubuntu_compatibility
	;;
"macos")
	log_info "Running macOS compatibility tests only..."
	run_macos_compatibility
	;;
"both")
	log_info "Running compatibility tests for both platforms..."
	ubuntu_result=0
	macos_result=0

	run_ubuntu_compatibility || ubuntu_result=1
	echo ""
	run_macos_compatibility || macos_result=1

	if [ $ubuntu_result -eq 0 ] && [ $macos_result -eq 0 ]; then
		log_success "All compatibility tests completed!"
		exit 0
	else
		log_error "Some compatibility tests failed"
		exit 1
	fi
	;;
*)
	log_error "Unknown platform: $PLATFORM"
	echo "Usage: $0 [ubuntu|macos|both]"
	exit 1
	;;
esac
