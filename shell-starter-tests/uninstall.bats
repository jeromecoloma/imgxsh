#!/usr/bin/env bats
#
# Tests for uninstall.sh script

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
    
    # Create test install directory with mock scripts
    mkdir -p "$TEST_PREFIX"
    echo '#!/bin/bash' > "$TEST_PREFIX/test-script"
    echo 'echo "test script"' >> "$TEST_PREFIX/test-script"
    chmod +x "$TEST_PREFIX/test-script"
    
    echo '#!/bin/bash' > "$TEST_PREFIX/another-script"
    echo 'echo "another script"' >> "$TEST_PREFIX/another-script"
    chmod +x "$TEST_PREFIX/another-script"
    
    # Create manifest directory and file
    mkdir -p "$TEST_MANIFEST_DIR"
    cat > "$TEST_MANIFEST_FILE" <<EOF
# Shell Starter Install Manifest
# Generated on $(date)
# Install prefix: $TEST_PREFIX

$TEST_PREFIX/test-script
$TEST_PREFIX/another-script
EOF
    
    # Create shell config with PATH entry
    cat > "$TEST_SHELL_CONFIG" <<EOF
# Some existing config
export PATH="/some/other/path:\$PATH"

# Added by shell-starter installer
export PATH="$TEST_PREFIX:\$PATH"

# More config after
alias ll='ls -la'
EOF
    
    cd "$TEST_DIR"
}

teardown() {
    # Clean up test directory
    rm -rf "$TEST_DIR"
}

@test "uninstall.sh: help flag displays usage" {
    run "$PROJECT_ROOT/uninstall.sh" --help
    assert_success
    assert_output --partial "Shell Starter Uninstaller"
    assert_output --partial "Usage:"
    assert_output --partial "--force"
}

@test "uninstall.sh: short help flag displays usage" {
    run "$PROJECT_ROOT/uninstall.sh" -h
    assert_success
    assert_output --partial "Shell Starter Uninstaller"
}

@test "uninstall.sh: unknown option shows error" {
    run "$PROJECT_ROOT/uninstall.sh" --unknown-option
    assert_failure
    assert_output --partial "Unknown option: --unknown-option"
}

@test "uninstall.sh: fails when no manifest exists" {
    # Override manifest location
    export MANIFEST_FILE="$TEST_DIR/nonexistent-manifest.txt"
    
    run "$PROJECT_ROOT/uninstall.sh" --force
    assert_failure
    assert_output --partial "No installation manifest found"
    
    unset MANIFEST_FILE
}

@test "uninstall.sh: reads manifest correctly" {
    export MANIFEST_DIR="$TEST_MANIFEST_DIR"
    export MANIFEST_FILE="$TEST_MANIFEST_FILE"
    
    # Source the script to access its functions
    source "$PROJECT_ROOT/uninstall.sh"
    
    run read_manifest
    assert_success
    assert_output --partial "Found 2 file(s) to remove"
    assert_output --partial "Install prefix: $TEST_PREFIX"
    
    unset MANIFEST_DIR MANIFEST_FILE
}

@test "uninstall.sh: get_shell_config function works for bash" {
    export SHELL="/bin/bash"

    source "$PROJECT_ROOT/uninstall.sh"

    # Mock the file checks
    touch "$HOME/.bashrc"
    run get_shell_config
    assert_success
    assert_output "$HOME/.bashrc"

    rm -f "$HOME/.bashrc"
}

@test "uninstall.sh: get_shell_config function works for zsh" {
    export SHELL="/bin/zsh"

    source "$PROJECT_ROOT/uninstall.sh"

    # Mock the file checks
    touch "$HOME/.zshrc"
    run get_shell_config
    assert_success
    assert_output "$HOME/.zshrc"

    rm -f "$HOME/.zshrc"
}

@test "uninstall.sh: cleanup_path_from_file function removes PATH entry" {
    source "$PROJECT_ROOT/uninstall.sh"

    run cleanup_path_from_file "$TEST_SHELL_CONFIG" "$TEST_PREFIX"
    assert_success

    # Check that PATH was removed from the config file
    run grep "export PATH.*$TEST_PREFIX" "$TEST_SHELL_CONFIG"
    assert_failure
}

@test "uninstall.sh: cleanup_path_from_file preserves other PATH entries" {
    source "$PROJECT_ROOT/uninstall.sh"

    run cleanup_path_from_file "$TEST_SHELL_CONFIG" "$TEST_PREFIX"
    assert_success

    # Check that other PATH entries are preserved
    run grep "/some/other/path" "$TEST_SHELL_CONFIG"
    assert_success

    # Check that other config lines are preserved
    run grep "alias ll=" "$TEST_SHELL_CONFIG"
    assert_success
}

@test "uninstall.sh: cleanup_path_from_file handles non-existent config file" {
    source "$PROJECT_ROOT/uninstall.sh"

    run cleanup_path_from_file "$TEST_DIR/nonexistent-config" "$TEST_PREFIX"
    assert_success
    assert_output --partial "Config file not found"
}

@test "uninstall.sh: cleanup_path_from_file handles non-existent PATH entry" {
    source "$PROJECT_ROOT/uninstall.sh"

    # Create a clean config file without shell-starter entries
    local CLEAN_CONFIG="$TEST_DIR/.clean_shell_config"
    cat > "$CLEAN_CONFIG" <<EOF
# Some existing config
export PATH="/some/other/path:\$PATH"
alias ll="ls -la"
EOF

    run cleanup_path_from_file "$CLEAN_CONFIG" "/nonexistent/path"
    assert_success
    assert_output --partial "No shell-starter PATH entries found"

    rm -f "$CLEAN_CONFIG"
}

@test "uninstall.sh: removes files listed in manifest" {
    export MANIFEST_DIR="$TEST_MANIFEST_DIR"
    export MANIFEST_FILE="$TEST_MANIFEST_FILE"
    
    run "$PROJECT_ROOT/uninstall.sh" --force
    assert_success
    
    # Check that files were removed
    assert [ ! -f "$TEST_PREFIX/test-script" ]
    assert [ ! -f "$TEST_PREFIX/another-script" ]
    
    unset MANIFEST_DIR MANIFEST_FILE
}

@test "uninstall.sh: handles already missing files gracefully" {
    export MANIFEST_DIR="$TEST_MANIFEST_DIR"
    export MANIFEST_FILE="$TEST_MANIFEST_FILE"
    
    # Remove one file manually before uninstalling
    rm "$TEST_PREFIX/test-script"
    
    run "$PROJECT_ROOT/uninstall.sh" --force
    assert_success
    assert_output --partial "1 file(s) were already missing"
    
    unset MANIFEST_DIR MANIFEST_FILE
}

@test "uninstall.sh: removes manifest file after uninstall" {
    export MANIFEST_DIR="$TEST_MANIFEST_DIR"
    export MANIFEST_FILE="$TEST_MANIFEST_FILE"
    
    run "$PROJECT_ROOT/uninstall.sh" --force
    assert_success
    
    # Check that manifest file was removed
    assert [ ! -f "$TEST_MANIFEST_FILE" ]
    
    unset MANIFEST_DIR MANIFEST_FILE
}

@test "uninstall.sh: removes empty manifest directory" {
    export MANIFEST_DIR="$TEST_MANIFEST_DIR"
    export MANIFEST_FILE="$TEST_MANIFEST_FILE"
    
    run "$PROJECT_ROOT/uninstall.sh" --force
    assert_success
    
    # Check that manifest directory was removed (since it should be empty)
    assert [ ! -d "$TEST_MANIFEST_DIR" ]
    
    unset MANIFEST_DIR MANIFEST_FILE
}

@test "uninstall.sh: preserves manifest directory if not empty" {
    export MANIFEST_DIR="$TEST_MANIFEST_DIR"
    export MANIFEST_FILE="$TEST_MANIFEST_FILE"
    
    # Add another file to manifest directory
    echo "other file" > "$TEST_MANIFEST_DIR/other-file.txt"
    
    run "$PROJECT_ROOT/uninstall.sh" --force
    assert_success
    
    # Check that manifest directory still exists (not empty)
    assert [ -d "$TEST_MANIFEST_DIR" ]
    assert [ -f "$TEST_MANIFEST_DIR/other-file.txt" ]
    
    unset MANIFEST_DIR MANIFEST_FILE
}

@test "uninstall.sh: force flag bypasses confirmation" {
    export MANIFEST_DIR="$TEST_MANIFEST_DIR"
    export MANIFEST_FILE="$TEST_MANIFEST_FILE"
    
    run "$PROJECT_ROOT/uninstall.sh" --force
    assert_success
    assert_output --partial "Force removal enabled - proceeding without confirmation"
    
    unset MANIFEST_DIR MANIFEST_FILE
}

@test "uninstall.sh: short force flag works" {
    export MANIFEST_DIR="$TEST_MANIFEST_DIR"
    export MANIFEST_FILE="$TEST_MANIFEST_FILE"
    
    run "$PROJECT_ROOT/uninstall.sh" -y
    assert_success
    assert_output --partial "Force removal enabled - proceeding without confirmation"
    
    unset MANIFEST_DIR MANIFEST_FILE
}

@test "uninstall.sh: success messages are displayed" {
    export MANIFEST_DIR="$TEST_MANIFEST_DIR"
    export MANIFEST_FILE="$TEST_MANIFEST_FILE"
    
    run "$PROJECT_ROOT/uninstall.sh" --force
    assert_success
    assert_output --partial "Uninstallation completed successfully"
    assert_output --partial "All Shell Starter files and PATH entries have been removed"
    
    unset MANIFEST_DIR MANIFEST_FILE
}

@test "uninstall.sh: handles empty manifest gracefully" {
    # Create a completely separate test environment
    local EMPTY_TEST_DIR
    EMPTY_TEST_DIR=$(mktemp -d)
    local EMPTY_MANIFEST_DIR="$EMPTY_TEST_DIR/manifest"
    local EMPTY_MANIFEST_FILE="$EMPTY_MANIFEST_DIR/install-manifest.txt"
    
    mkdir -p "$EMPTY_MANIFEST_DIR"
    
    # Create empty manifest (only comments)
    cat > "$EMPTY_MANIFEST_FILE" <<EOF
# Shell Starter Install Manifest
# Generated on $(date)
# Install prefix: $EMPTY_TEST_DIR/install

EOF
    
    export MANIFEST_DIR="$EMPTY_MANIFEST_DIR"
    export MANIFEST_FILE="$EMPTY_MANIFEST_FILE"
    
    run "$PROJECT_ROOT/uninstall.sh" --force
    # The script exits with 0 when no files to uninstall, which is correct behavior
    assert_success
    assert_output --partial "No files listed in manifest. Nothing to uninstall."
    
    unset MANIFEST_DIR MANIFEST_FILE
    rm -rf "$EMPTY_TEST_DIR"
}

@test "uninstall.sh: shows files that will be removed" {
    export MANIFEST_DIR="$TEST_MANIFEST_DIR"
    export MANIFEST_FILE="$TEST_MANIFEST_FILE"
    
    run "$PROJECT_ROOT/uninstall.sh" --force
    assert_success
    assert_output --partial "Files that will be removed:"
    assert_output --partial "$TEST_PREFIX/test-script"
    assert_output --partial "$TEST_PREFIX/another-script"
    
    unset MANIFEST_DIR MANIFEST_FILE
}