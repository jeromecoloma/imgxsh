#!/bin/bash

# Test runner for imgxsh
# This script runs the Bats test suite for imgxsh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Source Shell Starter main library
source "${PROJECT_ROOT}/lib/main.sh"

show_help() {
	cat <<EOF
Usage: $(basename "$0") [OPTIONS] [TEST_FILES...]

Run the imgxsh test suite using Bats.

ARGUMENTS:
    TEST_FILES...     Specific test files to run (optional)

OPTIONS:
    -h, --help        Show this help message and exit
    -v, --verbose     Enable verbose test output
    -p, --parallel N  Run tests in parallel (N = number of jobs)
    --tap             Output in TAP format
    --setup           Set up Bats testing framework
    --ci              Run in CI mode (optimized for automated environments)
    --coverage        Run with test coverage reporting (if available)

EXAMPLES:
    $(basename "$0")                          # Run all tests
    $(basename "$0") tests/imgxsh-convert.bats # Run specific test file
    $(basename "$0") --verbose               # Run with verbose output
    $(basename "$0") --parallel 4            # Run tests in parallel
    $(basename "$0") --setup                 # Set up Bats framework

DEPENDENCIES:
    Bats testing framework (automatically set up if missing)
EOF
}

setup_bats() {
	log::info "Setting up Bats testing framework..."

	local tests_dir="${PROJECT_ROOT}/tests"

	# Check if Bats is available in tests directory
	if [[ ! -d "$tests_dir/bats-core" ]]; then
		log::info "Copying Bats framework from Shell Starter reference..."

		# Copy Bats components from shell-starter-tests (reference)
		local shell_starter_tests="${PROJECT_ROOT}/shell-starter-tests"

		if [[ ! -d "$shell_starter_tests" ]]; then
			log::error "Shell Starter reference tests not found: $shell_starter_tests"
			log::info "Please ensure shell-starter-tests directory is available for reference"
			return 1
		fi

		# Copy the Bats framework components
		if [[ -d "$shell_starter_tests/bats-core" ]]; then
			cp -r "$shell_starter_tests/bats-core" "$tests_dir/"
			log::info "Copied bats-core"
		fi

		if [[ -d "$shell_starter_tests/bats-support" ]]; then
			cp -r "$shell_starter_tests/bats-support" "$tests_dir/"
			log::info "Copied bats-support"
		fi

		if [[ -d "$shell_starter_tests/bats-assert" ]]; then
			cp -r "$shell_starter_tests/bats-assert" "$tests_dir/"
			log::info "Copied bats-assert"
		fi

		if [[ ! -d "$tests_dir/bats-core" ]]; then
			log::error "Failed to set up Bats framework"
			return 1
		fi
	fi

	log::success "Bats testing framework is ready"
}

check_dependencies() {
	local missing_deps=()

    # Check for Bats (vendored or system)
    local bats_executable="${PROJECT_ROOT}/tests/bats-core/bin/bats"
    if [[ -x "$bats_executable" ]]; then
        true
    elif command -v bats >/dev/null 2>&1; then
        bats_executable="$(command -v bats)"
    else
        missing_deps+=("Bats testing framework")
    fi

	if [[ ${#missing_deps[@]} -gt 0 ]]; then
		log::error "Missing dependencies: ${missing_deps[*]}"
		log::info "Run: $(basename "$0") --setup"
		return 1
	fi

	return 0
}

run_tests() {
	local test_files=("$@")
    local bats_executable="${PROJECT_ROOT}/tests/bats-core/bin/bats"
    if [[ ! -x "$bats_executable" ]] && command -v bats >/dev/null 2>&1; then
        bats_executable="$(command -v bats)"
    fi
	local bats_args=()

	# Add common Bats arguments
	if [[ "${VERBOSE:-false}" == "true" ]]; then
		bats_args+=("--verbose-run")
	fi

	if [[ "${TAP_OUTPUT:-false}" == "true" ]]; then
		bats_args+=("--tap")
	fi

	if [[ -n "${PARALLEL_JOBS:-}" ]]; then
		bats_args+=("--jobs" "$PARALLEL_JOBS")
	fi

	# CI mode optimizations
	if [[ "${CI_MODE:-false}" == "true" ]]; then
		export SHELL_STARTER_CI_MODE=1
		export SHELL_STARTER_SPINNER_DISABLED=1
		export CI=true
		bats_args+=("--tap") # TAP output is better for CI

		# Create output directory for CI artifacts
		mkdir -p "${PROJECT_ROOT}/tests/ci-output"
	fi

	# Determine test files to run
	if [[ ${#test_files[@]} -eq 0 ]]; then
		# Run all test files
		test_files=("${PROJECT_ROOT}/tests"/*.bats)
	else
		# Validate provided test files
		local validated_files=()
		for file in "${test_files[@]}"; do
			if [[ -f "$file" ]]; then
				validated_files+=("$file")
			elif [[ -f "${PROJECT_ROOT}/tests/${file}" ]]; then
				validated_files+=("${PROJECT_ROOT}/tests/${file}")
			else
				log::warn "Test file not found: $file"
			fi
		done
		test_files=("${validated_files[@]}")
	fi

	if [[ ${#test_files[@]} -eq 0 ]]; then
		log::error "No test files found to run"
		return 1
	fi

	log::info "Running tests with Bats..."
	log::info "Test files: ${test_files[*]}"

	# Prepare output files for CI
	local output_file=""
	local xml_file=""
	if [[ "${CI_MODE:-false}" == "true" ]]; then
		output_file="${PROJECT_ROOT}/tests/ci-output/test-output.log"
		xml_file="${PROJECT_ROOT}/tests/ci-output/test-results.xml"
	fi

	# Run the tests with output capture for CI
	local test_result=0
	if [[ "${CI_MODE:-false}" == "true" && -n "$output_file" ]]; then
		# Run with output capture for CI
		if [[ ${#bats_args[@]} -gt 0 ]]; then
			"${bats_executable}" "${bats_args[@]}" "${test_files[@]}" >"$output_file" 2>&1
		else
			"${bats_executable}" "${test_files[@]}" >"$output_file" 2>&1
		fi
		if [[ $? -eq 0 ]]; then
			test_result=0
		else
			test_result=1
		fi

		# Display results even in CI mode
		if [[ "${VERBOSE:-false}" == "true" ]]; then
			cat "$output_file"
		else
			# Show summary
			grep -E "(^[0-9]+\.\.[0-9]+|^ok |^not ok |# )" "$output_file" || true
		fi
	else
		# Normal interactive run
		if [[ ${#bats_args[@]} -gt 0 ]]; then
			"${bats_executable}" "${bats_args[@]}" "${test_files[@]}"
		else
			"${bats_executable}" "${test_files[@]}"
		fi
		if [[ $? -eq 0 ]]; then
			test_result=0
		else
			test_result=1
		fi
	fi

	# Report results
	if [[ $test_result -eq 0 ]]; then
		log::success "All tests passed!"

		# Generate summary for CI
		if [[ "${CI_MODE:-false}" == "true" && -n "$output_file" ]]; then
			local total_tests
			total_tests=$(grep -c "^ok " "$output_file" 2>/dev/null || echo "0")
			log::info "CI Summary: $total_tests tests passed"
		fi
		return 0
	else
		log::error "Some tests failed"

		# Generate failure summary for CI
		if [[ "${CI_MODE:-false}" == "true" && -n "$output_file" ]]; then
			local passed_tests failed_tests
			passed_tests=$(grep -c "^ok " "$output_file" 2>/dev/null || echo "0")
			failed_tests=$(grep -c "^not ok " "$output_file" 2>/dev/null || echo "0")
			log::error "CI Summary: $passed_tests passed, $failed_tests failed"
		fi
		return 1
	fi
}

main() {
	local test_files=()
	local setup_only=false

	# Parse command line arguments
	while [[ $# -gt 0 ]]; do
		case $1 in
		-h | --help)
			show_help
			exit 0
			;;
		-v | --verbose)
			VERBOSE=true
			shift
			;;
		-p | --parallel)
			PARALLEL_JOBS="$2"
			shift 2
			;;
		--tap)
			TAP_OUTPUT=true
			shift
			;;
		--setup)
			setup_only=true
			shift
			;;
		--ci)
			CI_MODE=true
			shift
			;;
		--coverage)
			log::warn "Test coverage reporting not yet implemented"
			shift
			;;
		-*)
			log::error "Unknown option: $1"
			show_help
			exit 1
			;;
		*)
			test_files+=("$1")
			shift
			;;
		esac
	done

	# Setup mode - just set up Bats and exit
	if [[ "$setup_only" == "true" ]]; then
		setup_bats
		exit $?
	fi

	# Check and set up dependencies if needed
	if ! check_dependencies; then
		log::info "Setting up missing dependencies..."
		setup_bats

		# Check again after setup
		if ! check_dependencies; then
			exit 1
		fi
	fi

	# Run the tests
	if [[ ${#test_files[@]} -gt 0 ]]; then
		run_tests "${test_files[@]}"
	else
		run_tests
	fi
}

# Only run main if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
	main "$@"
fi
