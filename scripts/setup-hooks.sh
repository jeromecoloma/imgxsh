#!/bin/bash

# Setup script for Git hooks using Lefthook
# Run this after cloning the repository to enable pre-push validation

set -euo pipefail

# Get the project root
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Source Shell Starter main library for logging functions
if [[ -f "${PROJECT_ROOT}/lib/main.sh" ]]; then
	source "${PROJECT_ROOT}/lib/main.sh"
else
	# Fallback logging functions if main.sh not available
	log::info() { echo -e "\033[0;34mℹ️  $*\033[0m"; }
	log::warn() { echo -e "\033[1;33m⚠️  $*\033[0m"; }
	log::error() { echo -e "\033[0;31m❌ $*\033[0m"; }
	log::success() { echo -e "\033[0;32m✅ $*\033[0m"; }
fi

# Function to check dependencies
check_dependencies() {
	local missing_deps=()

	if ! command -v lefthook >/dev/null 2>&1; then
		missing_deps+=("lefthook")
	fi

	if ! command -v shellcheck >/dev/null 2>&1; then
		missing_deps+=("shellcheck")
	fi

	if ! command -v shfmt >/dev/null 2>&1; then
		missing_deps+=("shfmt")
	fi

	if [[ ${#missing_deps[@]} -gt 0 ]]; then
		log::error "Missing dependencies: ${missing_deps[*]}"
		log::info "Install with:"
		log::info "  brew install lefthook shellcheck shfmt"
		return 1
	fi

	return 0
}

# Function to install hooks
install_hooks() {
	log::info "Installing Git hooks with Lefthook..."

	# Check if lefthook.yml exists
	if [[ ! -f "${PROJECT_ROOT}/lefthook.yml" ]]; then
		log::error "lefthook.yml not found in project root"
		return 1
	fi

	# Install hooks
	if lefthook install; then
		log::success "Git hooks installed successfully"
	else
		log::error "Failed to install Git hooks"
		return 1
	fi
}

# Function to show help
show_help() {
	cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Setup Git hooks for imgxsh development using Lefthook.
This script installs pre-push hooks that run validation before pushing.

OPTIONS:
    -h, --help        Show this help message and exit
    --check           Check if hooks are installed and dependencies are available

EXAMPLES:
    $(basename "$0")              # Install Git hooks
    $(basename "$0") --check      # Check installation status

WHAT THIS DOES:
1. Installs pre-push Git hooks using Lefthook
2. The hooks run ShellCheck, shfmt, and tests before pushing
3. Prevents pushing code that would fail in CI
4. Can be bypassed with 'git push --no-verify' if needed

REQUIREMENTS:
- lefthook (install with: brew install lefthook)
- shellcheck (install with: brew install shellcheck)
- shfmt (install with: brew install shfmt)

MANUAL VALIDATION:
You can also run validation manually:
- ./tests/run-tests.sh        # Run tests
- shellcheck lib/*.sh bin/*   # Run ShellCheck
- shfmt -d lib/*.sh bin/*     # Check formatting

EOF
}

# Function to check installation status
check_status() {
	echo "Git Hooks Status Check"
	echo "====================="

	# Check if we're in a git repository
	if [[ ! -d "${PROJECT_ROOT}/.git" ]]; then
		log::error "Not in a Git repository"
		return 1
	else
		log::success "In a Git repository"
	fi

	# Check if lefthook.yml exists
	if [[ -f "${PROJECT_ROOT}/lefthook.yml" ]]; then
		log::success "lefthook.yml found"
	else
		log::error "lefthook.yml not found"
	fi

	# Check if hooks are installed
	if [[ -f "${PROJECT_ROOT}/.git/hooks/pre-push" ]]; then
		log::success "Pre-push hook is installed"
	else
		log::warn "Pre-push hook is not installed"
	fi

	# Check dependencies
	echo ""
	echo "Dependencies Check"
	echo "=================="
	if check_dependencies; then
		log::success "All dependencies are available"
	else
		log::error "Some dependencies are missing"
	fi

	echo ""
	echo "Manual Validation"
	echo "================="
	log::info "You can run validation manually with:"
	log::info "  ./tests/run-tests.sh"
	log::info "  shellcheck lib/*.sh bin/*"
	log::info "  shfmt -d lib/*.sh bin/*"
}

# Main execution
main() {
	local check_only=false

	# Parse command line arguments
	while [[ $# -gt 0 ]]; do
		case $1 in
		-h | --help)
			show_help
			exit 0
			;;
		--check)
			check_only=true
			shift
			;;
		*)
			log::error "Unknown option: $1"
			show_help
			exit 1
			;;
		esac
	done

	# Check if we're in a git repository
	if [[ ! -d "${PROJECT_ROOT}/.git" ]]; then
		log::error "Not in a Git repository. Please run this from the project root."
		exit 1
	fi

	if [[ "$check_only" == "true" ]]; then
		check_status
		exit 0
	fi

	# Install hooks
	echo ""
	log::info "Setting up Git hooks for imgxsh..."
	echo "======================================"

	# Check dependencies
	if ! check_dependencies; then
		log::error "Please install missing dependencies and try again"
		exit 1
	fi

	# Install hooks
	install_hooks

	echo ""
	log::success "Git hooks setup complete!"
	echo ""
	log::info "What happens now:"
	log::info "  - Every 'git push' will run validation checks"
	log::info "  - Checks include ShellCheck, shfmt, and tests"
	log::info "  - Use 'git push --no-verify' to bypass if needed"
	echo ""
	log::info "Manual validation:"
	log::info "  ./tests/run-tests.sh"
	log::info "  shellcheck lib/*.sh bin/*"
	log::info "  shfmt -d lib/*.sh bin/*"
	echo ""
	log::info "To check status later:"
	log::info "  ./scripts/setup-hooks.sh --check"
}

# Run main function
main "$@"
