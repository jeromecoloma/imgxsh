#!/bin/bash

# Basic test runner for imgxsh without Bats dependency
# This provides essential testing functionality while Bats setup is resolved

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Source Shell Starter main library
source "${PROJECT_ROOT}/lib/main.sh"

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Test helper functions
run_test() {
    local test_name="$1"
    local test_command="$2"
    local expected_exit_code="${3:-0}"
    
    TESTS_RUN=$((TESTS_RUN + 1))
    
    log::info "Running test: $test_name"
    
    # Run the test command and capture output and exit code
    local output
    local exit_code
    
    if output=$(eval "$test_command" 2>&1); then
        exit_code=0
    else
        exit_code=$?
    fi
    
    # Check if exit code matches expectation
    if [[ "$exit_code" -eq "$expected_exit_code" ]]; then
        TESTS_PASSED=$((TESTS_PASSED + 1))
        log::success "PASS: $test_name"
        return 0
    else
        TESTS_FAILED=$((TESTS_FAILED + 1))
        log::error "FAIL: $test_name"
        log::error "Expected exit code: $expected_exit_code, got: $exit_code"
        log::error "Output: $output"
        return 1
    fi
}

run_test_with_output_check() {
    local test_name="$1"
    local test_command="$2"
    local expected_output="$3"
    local expected_exit_code="${4:-0}"
    
    TESTS_RUN=$((TESTS_RUN + 1))
    
    log::info "Running test: $test_name"
    
    # Run the test command and capture output and exit code
    local output
    local exit_code
    
    if output=$(eval "$test_command" 2>&1); then
        exit_code=0
    else
        exit_code=$?
    fi
    
    # Check if exit code matches expectation
    if [[ "$exit_code" -ne "$expected_exit_code" ]]; then
        TESTS_FAILED=$((TESTS_FAILED + 1))
        log::error "FAIL: $test_name (exit code)"
        log::error "Expected exit code: $expected_exit_code, got: $exit_code"
        log::error "Output: $output"
        return 1
    fi
    
    # Check if output contains expected text
    if [[ "$output" == *"$expected_output"* ]]; then
        TESTS_PASSED=$((TESTS_PASSED + 1))
        log::success "PASS: $test_name"
        return 0
    else
        TESTS_FAILED=$((TESTS_FAILED + 1))
        log::error "FAIL: $test_name (output check)"
        log::error "Expected output to contain: $expected_output"
        log::error "Actual output: $output"
        return 1
    fi
}

create_test_image() {
    local output_file="$1"
    local size="${2:-100x100}"
    local color="${3:-red}"
    
    if ! command -v convert >/dev/null 2>&1; then
        log::warn "ImageMagick not available, skipping image creation tests"
        return 1
    fi
    
    if convert -size "$size" "xc:$color" "$output_file" 2>/dev/null; then
        return 0
    else
        return 1
    fi
}

# Test suite for imgxsh-convert
test_imgxsh_convert() {
    log::info "Testing imgxsh-convert..."
    
    # Test 1: Help flag
    run_test_with_output_check \
        "imgxsh-convert help flag" \
        "${PROJECT_ROOT}/bin/imgxsh-convert --help" \
        "Usage:" \
        0
    
    # Test 2: Version flag
    local expected_version
    expected_version=$(cat "${PROJECT_ROOT}/VERSION" | tr -d '\n')
    run_test_with_output_check \
        "imgxsh-convert version flag" \
        "${PROJECT_ROOT}/bin/imgxsh-convert --version" \
        "$expected_version" \
        0
    
    # Test 3: No arguments (should fail)
    run_test_with_output_check \
        "imgxsh-convert no arguments" \
        "${PROJECT_ROOT}/bin/imgxsh-convert" \
        "Input file is required" \
        1
    
    # Test 4: Missing output argument (should fail)
    run_test_with_output_check \
        "imgxsh-convert missing output" \
        "${PROJECT_ROOT}/bin/imgxsh-convert input.png" \
        "Output file is required" \
        1
    
    # Test 5: Non-existent input file (should fail)
    run_test_with_output_check \
        "imgxsh-convert non-existent input" \
        "${PROJECT_ROOT}/bin/imgxsh-convert /nonexistent/file.png output.jpg" \
        "Cannot read input file" \
        1
    
    # Test 6: Invalid quality value (should fail)
    if create_test_image "/tmp/test_input.png"; then
        run_test_with_output_check \
            "imgxsh-convert invalid quality" \
            "${PROJECT_ROOT}/bin/imgxsh-convert --quality 101 /tmp/test_input.png /tmp/test_output.jpg" \
            "Quality must be a number between 1 and 100" \
            1
        rm -f /tmp/test_input.png
    else
        log::warn "Skipping ImageMagick-dependent tests"
    fi
    
    # Test 7: Dry-run mode (if ImageMagick available)
    if create_test_image "/tmp/test_input2.png"; then
        run_test_with_output_check \
            "imgxsh-convert dry-run mode" \
            "${PROJECT_ROOT}/bin/imgxsh-convert --dry-run /tmp/test_input2.png /tmp/test_output2.jpg" \
            "Dry-run completed" \
            0
        
        # Verify output file was not created in dry-run
        if [[ -f "/tmp/test_output2.jpg" ]]; then
            TESTS_FAILED=$((TESTS_FAILED + 1))
            log::error "FAIL: Dry-run created output file when it shouldn't have"
        else
            log::success "PASS: Dry-run did not create output file"
        fi
        
        rm -f /tmp/test_input2.png /tmp/test_output2.jpg
    fi
    
    # Test 8: Actual conversion (if ImageMagick available)
    if create_test_image "/tmp/test_input3.png"; then
        run_test_with_output_check \
            "imgxsh-convert actual conversion" \
            "${PROJECT_ROOT}/bin/imgxsh-convert /tmp/test_input3.png /tmp/test_output3.jpg" \
            "Successfully converted" \
            0
        
        # Verify output file was created
        if [[ -f "/tmp/test_output3.jpg" ]]; then
            log::success "PASS: Conversion created output file"
        else
            TESTS_FAILED=$((TESTS_FAILED + 1))
            log::error "FAIL: Conversion did not create output file"
        fi
        
        rm -f /tmp/test_input3.png /tmp/test_output3.jpg
    fi
}

# Main test runner
main() {
    log::info "Starting imgxsh basic test suite..."
    log::info "=================================="
    
    # Run tests
    test_imgxsh_convert
    
    # Show results
    log::info "=================================="
    log::info "Test Results:"
    log::info "  Tests run: $TESTS_RUN"
    log::success "  Passed: $TESTS_PASSED"
    
    if [[ $TESTS_FAILED -gt 0 ]]; then
        log::error "  Failed: $TESTS_FAILED"
        log::error "Some tests failed!"
        exit 1
    else
        log::success "All tests passed!"
        exit 0
    fi
}

# Only run main if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
