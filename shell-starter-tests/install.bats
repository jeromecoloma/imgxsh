#!/usr/bin/env bats
#
# Tests for install.sh script

# Load test helpers
load test_helper
load bats-support/load
load bats-assert/load

# Setup and teardown for each test
setup() {
    # Create temporary test directory
    TEST_DIR=$(mktemp -d)
    TEST_PREFIX="$TEST_DIR/test-install"
    TEST_MANIFEST_DIR="$TEST_DIR/test-manifest"
    TEST_MANIFEST_FILE="$TEST_MANIFEST_DIR/install-manifest.txt"
    TEST_SHELL_CONFIG="$TEST_DIR/.test_shell_config"
    
    # Create test bin directory with mock scripts
    mkdir -p "$TEST_DIR/bin"
    echo '#!/bin/bash' > "$TEST_DIR/bin/test-script"
    echo 'echo "test script"' >> "$TEST_DIR/bin/test-script"
    chmod +x "$TEST_DIR/bin/test-script"
    
    echo '#!/bin/bash' > "$TEST_DIR/bin/another-script"
    echo 'echo "another script"' >> "$TEST_DIR/bin/another-script"
    chmod +x "$TEST_DIR/bin/another-script"
    
    # Create test shell config file
    touch "$TEST_SHELL_CONFIG"
    
    cd "$TEST_DIR"
}

teardown() {
    # Clean up test directory
    rm -rf "$TEST_DIR"
}

@test "install.sh: help flag displays usage" {
    run "$PROJECT_ROOT/install.sh" --help
    assert_success
    assert_output --partial "Shell Starter Installer"
    assert_output --partial "Usage:"
    assert_output --partial "--prefix"
}

@test "install.sh: short help flag displays usage" {
    run "$PROJECT_ROOT/install.sh" -h
    assert_success
    assert_output --partial "Shell Starter Installer"
}

@test "install.sh: unknown option shows error" {
    run "$PROJECT_ROOT/install.sh" --unknown-option
    assert_failure
    assert_output --partial "Unknown option: --unknown-option"
}

@test "install.sh: fails when no bin directory exists" {
    rm -rf "$TEST_DIR/bin"
    run "$PROJECT_ROOT/install.sh" --prefix "$TEST_PREFIX"
    assert_failure
    assert_output --partial "Source 'bin' directory not found"
}

@test "install.sh: creates install directory if it doesn't exist" {
    run "$PROJECT_ROOT/install.sh" --prefix "$TEST_PREFIX"
    assert_success
    assert [ -d "$TEST_PREFIX" ]
}

@test "install.sh: installs executable scripts" {
    run "$PROJECT_ROOT/install.sh" --prefix "$TEST_PREFIX"
    assert_success
    assert [ -f "$TEST_PREFIX/test-script" ]
    assert [ -f "$TEST_PREFIX/another-script" ]
    assert [ -x "$TEST_PREFIX/test-script" ]
    assert [ -x "$TEST_PREFIX/another-script" ]
}

@test "install.sh: creates manifest directory and file" {
    # Set environment variables to override default locations
    export MANIFEST_DIR="$TEST_MANIFEST_DIR"
    export MANIFEST_FILE="$TEST_MANIFEST_FILE"
    
    run "$PROJECT_ROOT/install.sh" --prefix "$TEST_PREFIX"
    assert_success
    assert [ -d "$TEST_MANIFEST_DIR" ]
    assert [ -f "$TEST_MANIFEST_FILE" ]
    unset MANIFEST_DIR MANIFEST_FILE
}

@test "install.sh: manifest contains installed files" {
    export MANIFEST_DIR="$TEST_MANIFEST_DIR"
    export MANIFEST_FILE="$TEST_MANIFEST_FILE"
    
    run "$PROJECT_ROOT/install.sh" --prefix "$TEST_PREFIX"
    assert_success
    
    # Check manifest contains the installed files (count non-comment lines)
    run bash -c "grep -v '^#' '$TEST_MANIFEST_FILE' | grep -v '^[[:space:]]*\$' | wc -l | tr -d ' '"
    assert_success
    assert_output "2"  # Should contain 2 installed files
    
    unset MANIFEST_DIR MANIFEST_FILE
}

@test "install.sh: detect_shell_config function works for bash" {
    export SHELL="/bin/bash"
    
    # Source the script to access its functions
    source "$PROJECT_ROOT/install.sh"
    
    # Mock the file checks
    touch "$HOME/.bashrc"
    run detect_shell_config
    assert_success
    assert_output "$HOME/.bashrc"
    
    rm -f "$HOME/.bashrc"
}

@test "install.sh: detect_shell_config function works for zsh" {
    export SHELL="/bin/zsh"
    
    source "$PROJECT_ROOT/install.sh"
    
    run detect_shell_config
    assert_success
    assert_output "$HOME/.zshrc"
}

@test "install.sh: detect_shell_config function works for fish" {
    export SHELL="/usr/local/bin/fish"
    
    source "$PROJECT_ROOT/install.sh"
    
    run detect_shell_config
    assert_success
    assert_output "$HOME/.config/fish/config.fish"
}

@test "install.sh: add_to_path function adds PATH entry" {
    source "$PROJECT_ROOT/install.sh"
    
    run add_to_path "$TEST_SHELL_CONFIG" "$TEST_PREFIX"
    assert_success
    
    # Check that PATH was added to the config file
    run grep "export PATH.*$TEST_PREFIX" "$TEST_SHELL_CONFIG"
    assert_success
}

@test "install.sh: add_to_path function doesn't duplicate entries" {
    source "$PROJECT_ROOT/install.sh"
    
    # Add PATH entry first time
    run add_to_path "$TEST_SHELL_CONFIG" "$TEST_PREFIX"
    assert_success
    
    # Try to add the same PATH entry again
    run add_to_path "$TEST_SHELL_CONFIG" "$TEST_PREFIX"
    assert_success
    assert_output --partial "PATH entry already exists"
    
    # Verify only one entry exists
    run grep -c "export PATH.*$TEST_PREFIX" "$TEST_SHELL_CONFIG"
    assert_success
    assert_output "1"
}

@test "install.sh: add_to_path creates config file if it doesn't exist" {
    rm -f "$TEST_SHELL_CONFIG"
    source "$PROJECT_ROOT/install.sh"
    
    run add_to_path "$TEST_SHELL_CONFIG" "$TEST_PREFIX"
    assert_success
    assert [ -f "$TEST_SHELL_CONFIG" ]
}

@test "install.sh: success messages are displayed" {
    run "$PROJECT_ROOT/install.sh" --prefix "$TEST_PREFIX"
    assert_success
    assert_output --partial "INSTALLATION COMPLETE"
    assert_output --partial "Scripts installed to: $TEST_PREFIX"
}

@test "install.sh: handles empty bin directory gracefully" {
    # Remove all scripts from bin directory
    rm -f "$TEST_DIR/bin"/*

    run "$PROJECT_ROOT/install.sh" --prefix "$TEST_PREFIX"
    assert_failure
    assert_output --partial "No executable scripts found in source directory"
}

@test "install.sh: only installs executable files" {
    # Create a non-executable file
    echo "not executable" > "$TEST_DIR/bin/not-executable"
    
    run "$PROJECT_ROOT/install.sh" --prefix "$TEST_PREFIX"
    assert_success
    
    # Should not install the non-executable file
    assert [ ! -f "$TEST_PREFIX/not-executable" ]
    # Should still install the executable ones
    assert [ -f "$TEST_PREFIX/test-script" ]
}