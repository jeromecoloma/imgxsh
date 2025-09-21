#!/usr/bin/env bash

# Bats test helper functions
# This file is sourced by all test files

# Get the project root directory
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Source the main library
source "${PROJECT_ROOT}/lib/main.sh"

# Global test state tracking
declare -a TEMP_DIRS_CREATED=()
declare -a BACKGROUND_PIDS=()
declare -a ENV_VARS_SET=()
declare -a FILES_CREATED=()

# Test utilities
setup() {
    # Common setup for all tests
    export SHELL_STARTER_TEST=1

    # Save original environment state
    _save_environment_state

    # Create isolated test environment
    _setup_test_isolation

    # Detect CI environments and set optimizations
    if [[ -n "${CI:-}" ]] || [[ -n "${GITHUB_ACTIONS:-}" ]] || [[ -n "${SHELL_STARTER_CI_MODE:-}" ]]; then
        export SHELL_STARTER_CI=1
        export SHELL_STARTER_SPINNER_DISABLED=1  # Disable spinners in CI
        # Don't set BATS_TEST_TIMEOUT in CI environments that lack pkill/ps
        # This prevents the "Cannot execute timeout" errors in containers
        if command -v pkill >/dev/null 2>&1 && command -v ps >/dev/null 2>&1; then
            export BATS_TEST_TIMEOUT=30          # Only set timeout if tools are available
        fi
    fi
}

teardown() {
    # Comprehensive cleanup for all tests
    _cleanup_test_isolation
    _restore_environment_state

    # Common cleanup
    unset SHELL_STARTER_TEST
    unset SHELL_STARTER_CI 2>/dev/null || true
    unset SHELL_STARTER_SPINNER_DISABLED 2>/dev/null || true
    unset BATS_TEST_TIMEOUT 2>/dev/null || true

    # Clear tracking arrays
    TEMP_DIRS_CREATED=()
    BACKGROUND_PIDS=()
    ENV_VARS_SET=()
    FILES_CREATED=()
}

# Environment state management
_save_environment_state() {
    # Save original environment variables that tests might modify
    export ORIGINAL_PATH="${PATH:-}"
    export ORIGINAL_HOME="${HOME:-}"
    export ORIGINAL_PWD="${PWD:-}"
    export ORIGINAL_LOG_LEVEL="${LOG_LEVEL:-}"
    export ORIGINAL_NO_COLOR="${NO_COLOR:-}"
    export ORIGINAL_PROJECT_ROOT="${PROJECT_ROOT:-}"
}

_restore_environment_state() {
    # Restore original environment
    [[ -n "${ORIGINAL_PATH:-}" ]] && export PATH="$ORIGINAL_PATH"
    [[ -n "${ORIGINAL_HOME:-}" ]] && export HOME="$ORIGINAL_HOME"
    [[ -n "${ORIGINAL_PWD:-}" ]] && cd "$ORIGINAL_PWD" 2>/dev/null || true
    [[ -n "${ORIGINAL_LOG_LEVEL:-}" ]] && export LOG_LEVEL="$ORIGINAL_LOG_LEVEL" || unset LOG_LEVEL
    [[ -n "${ORIGINAL_NO_COLOR:-}" ]] && export NO_COLOR="$ORIGINAL_NO_COLOR" || unset NO_COLOR
    [[ -n "${ORIGINAL_PROJECT_ROOT:-}" ]] && export PROJECT_ROOT="$ORIGINAL_PROJECT_ROOT"

    # Clean up saved state variables
    unset ORIGINAL_PATH ORIGINAL_HOME ORIGINAL_PWD ORIGINAL_LOG_LEVEL ORIGINAL_NO_COLOR ORIGINAL_PROJECT_ROOT
}

# Test isolation setup
_setup_test_isolation() {
    # Create isolated temp directory for this test
    if [[ -z "${BATS_TEST_TMPDIR:-}" ]]; then
        TEST_ISOLATED_DIR=$(mktemp -d)
        export BATS_TEST_TMPDIR="$TEST_ISOLATED_DIR"
        track_temp_dir "$TEST_ISOLATED_DIR"
    fi

    # Set restrictive umask for test isolation
    export ORIGINAL_UMASK=$(umask)
    umask 0077
}

# Test isolation cleanup
_cleanup_test_isolation() {
    # Kill any background processes started during tests
    cleanup_background_processes

    # Remove temporary directories
    cleanup_temp_directories

    # Clean up any created files
    cleanup_created_files

    # Stop any running spinners
    if declare -F spinner::stop >/dev/null 2>&1; then
        spinner::stop 2>/dev/null || true
    fi

    # Restore umask
    if [[ -n "${ORIGINAL_UMASK:-}" ]]; then
        umask "$ORIGINAL_UMASK"
        unset ORIGINAL_UMASK
    fi
}

# Utility functions for tracking and cleanup
track_temp_dir() {
    local dir="$1"
    if [[ -n "$dir" && -d "$dir" ]]; then
        TEMP_DIRS_CREATED+=("$dir")
    fi
}

track_background_pid() {
    local pid="$1"
    if [[ -n "$pid" ]]; then
        BACKGROUND_PIDS+=("$pid")
    fi
}

track_env_var() {
    local var_name="$1"
    if [[ -n "$var_name" ]]; then
        ENV_VARS_SET+=("$var_name")
    fi
}

track_created_file() {
    local file="$1"
    if [[ -n "$file" ]]; then
        FILES_CREATED+=("$file")
    fi
}

cleanup_temp_directories() {
    local dir
    for dir in "${TEMP_DIRS_CREATED[@]:-}"; do
        if [[ -n "$dir" && -d "$dir" ]]; then
            # Ensure we can remove it (fix permissions if needed)
            chmod -R u+rwx "$dir" 2>/dev/null || true
            rm -rf "$dir" 2>/dev/null || true
        fi
    done
}

cleanup_background_processes() {
    local pid
    for pid in "${BACKGROUND_PIDS[@]:-}"; do
        if [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null; then
            # Try graceful termination first
            kill "$pid" 2>/dev/null || true
            sleep 0.1
            # Force kill if still running
            if kill -0 "$pid" 2>/dev/null; then
                kill -KILL "$pid" 2>/dev/null || true
            fi
        fi
    done
}

cleanup_created_files() {
    local file
    for file in "${FILES_CREATED[@]:-}"; do
        if [[ -n "$file" && -e "$file" ]]; then
            rm -f "$file" 2>/dev/null || true
        fi
    done
}

# Enhanced run_script with isolation
run_script_isolated() {
    local script_name="$1"
    shift

    # Create isolated environment for script execution
    local isolated_dir
    isolated_dir=$(mktemp -d)
    track_temp_dir "$isolated_dir"

    # Export isolated directory
    export SCRIPT_ISOLATED_DIR="$isolated_dir"

    # Run script with isolation
    run_script "$script_name" "$@"

    # Clean up isolated environment is handled in teardown
}

# Test environment verification
verify_test_isolation() {
    # Verify that test isolation is working correctly
    local issues=()

    # Check that we're in test mode
    [[ -n "${SHELL_STARTER_TEST:-}" ]] || issues+=("SHELL_STARTER_TEST not set")

    # Check that temporary directories are tracked
    [[ ${#TEMP_DIRS_CREATED[@]} -eq 0 || -d "${TEMP_DIRS_CREATED[0]}" ]] || issues+=("Temp directory tracking failed")

    # Return verification results
    if [[ ${#issues[@]} -gt 0 ]]; then
        printf '%s\n' "${issues[@]}"
        return 1
    fi

    return 0
}

# Helper function to run scripts and capture output
run_script() {
    local script_name="$1"
    shift

    # Check if script exists in demo/ directory first (example scripts)
    if [[ -f "${PROJECT_ROOT}/demo/${script_name}" ]]; then
        run "${PROJECT_ROOT}/demo/${script_name}" "$@"
    # Otherwise check bin/ directory (core utilities)
    elif [[ -f "${PROJECT_ROOT}/bin/${script_name}" ]]; then
        run "${PROJECT_ROOT}/bin/${script_name}" "$@"
    else
        # Script not found in either location
        run false
    fi
}

# Helper function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}