#!/usr/bin/env bash

# imgxsh test helper functions
# This file is sourced by all test files

# Get the project root directory - robust resolution
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Source the main library
source "${PROJECT_ROOT}/lib/main.sh"

# Set up BATS_LIB_PATH for library loading (must be at top level, not in setup())
# Override bats default (/usr/lib/bats) with correct paths for our libraries

# Debug output for CI troubleshooting
if [[ -n "${CI:-}" ]]; then
    echo "DEBUG test_helper: PROJECT_ROOT=${PROJECT_ROOT}" >&2
    echo "DEBUG test_helper: Current BATS_LIB_PATH=${BATS_LIB_PATH:-UNSET}" >&2
    echo "DEBUG test_helper: Checking paths..." >&2
    echo "DEBUG test_helper: ${PROJECT_ROOT}/tests/bats-support exists: $([ -d "${PROJECT_ROOT}/tests/bats-support" ] && echo YES || echo NO)" >&2
    echo "DEBUG test_helper: /usr/lib/bats-support exists: $([ -d "/usr/lib/bats-support" ] && echo YES || echo NO)" >&2
    echo "DEBUG test_helper: /usr/local/lib/bats-support exists: $([ -d "/usr/local/lib/bats-support" ] && echo YES || echo NO)" >&2
fi

if [[ -d "${PROJECT_ROOT}/tests/bats-support" ]]; then
    # Local vendored libraries (development)
    export BATS_LIB_PATH="${PROJECT_ROOT}/tests"
    [[ -n "${CI:-}" ]] && echo "DEBUG test_helper: Set BATS_LIB_PATH to local: $BATS_LIB_PATH" >&2
elif [[ -d "/usr/lib/bats-support" ]]; then
    # System installation (CI with bats-action)
    export BATS_LIB_PATH="/usr/lib"
    [[ -n "${CI:-}" ]] && echo "DEBUG test_helper: Set BATS_LIB_PATH to system: $BATS_LIB_PATH" >&2
elif [[ -d "/usr/local/lib/bats-support" ]]; then
    # Alternative system installation path
    export BATS_LIB_PATH="/usr/local/lib"
    [[ -n "${CI:-}" ]] && echo "DEBUG test_helper: Set BATS_LIB_PATH to local system: $BATS_LIB_PATH" >&2
else
    # Keep bats default if no libraries found
    export BATS_LIB_PATH="${BATS_LIB_PATH:-/usr/lib/bats}"
    [[ -n "${CI:-}" ]] && echo "DEBUG test_helper: Using default BATS_LIB_PATH: $BATS_LIB_PATH" >&2
fi

# Global test state tracking
declare -a TEMP_DIRS_CREATED=()
declare -a BACKGROUND_PIDS=()
declare -a ENV_VARS_SET=()
declare -a FILES_CREATED=()
declare -a TEST_IMAGES_CREATED=()

# Test utilities
setup() {
    # Common setup for all tests
    export SHELL_STARTER_TEST=1
    export IMGXSH_TEST=1

    # Save original environment state
    _save_environment_state

    # Create isolated test environment
    _setup_test_isolation

    # Detect CI environments and set optimizations
    if [[ -n "${CI:-}" ]] || [[ -n "${GITHUB_ACTIONS:-}" ]] || [[ -n "${SHELL_STARTER_CI_MODE:-}" ]]; then
        export SHELL_STARTER_CI=1
        export SHELL_STARTER_SPINNER_DISABLED=1  # Disable spinners in CI
        # Don't set BATS_TEST_TIMEOUT in CI environments that lack pkill/ps
        if command -v pkill >/dev/null 2>&1 && command -v ps >/dev/null 2>&1; then
            export BATS_TEST_TIMEOUT=60          # Longer timeout for image processing
        fi
    fi
}

teardown() {
    # Comprehensive cleanup for all tests
    _cleanup_test_isolation
    _restore_environment_state
    
    # Clean up test images
    cleanup_test_images

    # Common cleanup
    unset SHELL_STARTER_TEST
    unset IMGXSH_TEST
    unset SHELL_STARTER_CI 2>/dev/null || true
    unset SHELL_STARTER_SPINNER_DISABLED 2>/dev/null || true
    unset BATS_TEST_TIMEOUT 2>/dev/null || true

    # Clear tracking arrays
    TEMP_DIRS_CREATED=()
    BACKGROUND_PIDS=()
    ENV_VARS_SET=()
    FILES_CREATED=()
    TEST_IMAGES_CREATED=()
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

track_test_image() {
    local image="$1"
    if [[ -n "$image" ]]; then
        TEST_IMAGES_CREATED+=("$image")
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

cleanup_test_images() {
    local image
    for image in "${TEST_IMAGES_CREATED[@]:-}"; do
        if [[ -n "$image" && -e "$image" ]]; then
            rm -f "$image" 2>/dev/null || true
        fi
    done
}

# Helper function to run imgxsh scripts and capture output
run_imgxsh() {
    local script_name="$1"
    shift

    # Check if script exists in bin/ directory
    if [[ -f "${PROJECT_ROOT}/bin/${script_name}" ]]; then
        run "${PROJECT_ROOT}/bin/${script_name}" "$@"
    else
        # Script not found
        run false
    fi
}

# Helper function to check if ImageMagick is available
has_imagemagick() {
    command -v convert >/dev/null 2>&1 && command -v identify >/dev/null 2>&1
}

# Helper function to check if other dependencies are available
has_dependency() {
    local dep="$1"
    command -v "$dep" >/dev/null 2>&1
}

# Helper function to create test images
create_test_image() {
    local output_file="$1"
    local format="${2:-png}"
    local size="${3:-100x100}"
    local color="${4:-red}"
    
    # Require ImageMagick for test image creation
    if ! has_imagemagick; then
        skip "ImageMagick not available for test image creation"
    fi
    
    # Create the test image
    if convert -size "$size" "xc:$color" "$output_file"; then
        track_test_image "$output_file"
        track_created_file "$output_file"
        return 0
    else
        return 1
    fi
}

# Helper function to create complex test image with text
create_test_image_with_text() {
    local output_file="$1"
    local text="${2:-Test}"
    local size="${3:-200x100}"
    local bg_color="${4:-white}"
    local text_color="${5:-black}"
    
    if ! has_imagemagick; then
        skip "ImageMagick not available for test image creation"
    fi
    
    # Create image with text - handle font availability gracefully
    local font_arg=""
    
    # Try to use available fonts, fallback to system default if needed
    if convert -list font | grep -qi helvetica 2>/dev/null; then
        font_arg="-font Helvetica"
    elif convert -list font | grep -qi arial 2>/dev/null; then
        font_arg="-font Arial"
    elif convert -list font | grep -qi liberation-sans 2>/dev/null; then
        font_arg="-font Liberation-Sans"
    elif convert -list font | grep -qi dejavu 2>/dev/null; then
        font_arg="-font DejaVu-Sans"
    else
        # Use system default font (usually works in containers)
        font_arg=""
    fi
    
    # Create image with text using available font or system default
    if convert -size "$size" "xc:$bg_color" -gravity center -pointsize 20 $font_arg -fill "$text_color" -annotate +0+0 "$text" "$output_file" 2>/dev/null; then
        track_test_image "$output_file"
        track_created_file "$output_file"
        return 0
    else
        # Fallback: create simple image without text if font issues persist
        if convert -size "$size" "xc:$bg_color" "$output_file" 2>/dev/null; then
            track_test_image "$output_file"
            track_created_file "$output_file"
            return 0
        else
            return 1
        fi
    fi
}

# Helper function to verify image properties
verify_image_format() {
    local image_file="$1"
    local expected_format="$2"
    
    if ! has_imagemagick; then
        skip "ImageMagick not available for image verification"
    fi
    
    local actual_format
    if actual_format=$(identify -format "%m" "$image_file" 2>/dev/null); then
        actual_format=$(echo "$actual_format" | tr '[:upper:]' '[:lower:]')
        expected_format=$(echo "$expected_format" | tr '[:upper:]' '[:lower:]')
        
        # Handle format variations
        case "$expected_format" in
            jpg|jpeg)
                [[ "$actual_format" == "jpeg" ]]
                ;;
            *)
                [[ "$actual_format" == "$expected_format" ]]
                ;;
        esac
    else
        return 1
    fi
}

# Helper function to get image dimensions
get_image_dimensions() {
    local image_file="$1"
    
    if ! has_imagemagick; then
        skip "ImageMagick not available for image verification"
    fi
    
    identify -format "%wx%h" "$image_file" 2>/dev/null
}

# Helper function to get image file size
get_image_file_size() {
    local image_file="$1"
    
    if [[ -f "$image_file" ]]; then
        stat -f%z "$image_file" 2>/dev/null || stat -c%s "$image_file" 2>/dev/null
    else
        return 1
    fi
}

# Helper function for dependency mocking in CI
mock_missing_dependency() {
    local dep_name="$1"
    local mock_dir="${BATS_TEST_TMPDIR}/mock_bin"
    
    # Create mock directory
    mkdir -p "$mock_dir"
    
    # Create mock script that fails
    cat > "${mock_dir}/${dep_name}" << 'EOF'
#!/bin/bash
echo "Mock: $0 not available" >&2
exit 127
EOF
    chmod +x "${mock_dir}/${dep_name}"
    
    # Prepend mock directory to PATH
    export PATH="${mock_dir}:${PATH}"
    track_env_var "PATH"
}

# Helper function to skip tests based on dependencies
require_dependency() {
    local dep_name="$1"
    local install_hint="${2:-}"
    
    if ! has_dependency "$dep_name"; then
        if [[ -n "$install_hint" ]]; then
            skip "$dep_name not available. Install with: $install_hint"
        else
            skip "$dep_name not available"
        fi
    fi
}

# Helper function to skip tests requiring ImageMagick
require_imagemagick() {
    if ! has_imagemagick; then
        skip "ImageMagick not available. Install with: brew install imagemagick (macOS) or apt-get install imagemagick (Ubuntu)"
    fi
}

# Helper function to test workflow execution
run_workflow() {
    local workflow_name="$1"
    shift
    
    run_imgxsh "imgxsh" --workflow "$workflow_name" "$@"
}

# Helper function to test workflow dry-run
run_workflow_dry() {
    local workflow_name="$1"
    shift
    
    run_imgxsh "imgxsh" --workflow "$workflow_name" --dry-run "$@"
}

# Test environment verification
verify_test_isolation() {
    # Verify that test isolation is working correctly
    local issues=()

    # Check that we're in test mode
    [[ -n "${SHELL_STARTER_TEST:-}" ]] || issues+=("SHELL_STARTER_TEST not set")
    [[ -n "${IMGXSH_TEST:-}" ]] || issues+=("IMGXSH_TEST not set")

    # Check that temporary directories are tracked
    [[ ${#TEMP_DIRS_CREATED[@]} -eq 0 || -d "${TEMP_DIRS_CREATED[0]}" ]] || issues+=("Temp directory tracking failed")

    # Return verification results
    if [[ ${#issues[@]} -gt 0 ]]; then
        printf '%s\n' "${issues[@]}"
        return 1
    fi

    return 0
}
