#!/usr/bin/env bats
#
# Tests for check-version script

# Load test helpers
load test_helper
load bats-support/load
load bats-assert/load

setup() {
	# Call parent setup
	export SHELL_STARTER_TEST=1

	# Create temporary directory for test files
	TEST_DIR=$(mktemp -d)
	export TEST_DIR

	# Save original PROJECT_ROOT and override for testing
	ORIGINAL_PROJECT_ROOT="$PROJECT_ROOT"
	export ORIGINAL_PROJECT_ROOT
	PROJECT_ROOT="$TEST_DIR"
	export PROJECT_ROOT

	# Create basic project structure for testing
	mkdir -p "$TEST_DIR/scripts"

	# Copy the check-version script to test directory
	cp "${ORIGINAL_PROJECT_ROOT}/scripts/check-version.sh" "$TEST_DIR/scripts/"
	chmod +x "$TEST_DIR/scripts/check-version.sh"

	# Create test VERSION file
	echo "1.2.3" >"$TEST_DIR/VERSION"

	# Mock curl for network tests - create a simple mock that can be controlled
	export MOCK_CURL_RESPONSE=""
	export MOCK_CURL_EXIT_CODE="0"
	export PATH="$TEST_DIR:$PATH"

	# Create mock curl script
	cat >"$TEST_DIR/curl" <<'EOF'
#!/bin/bash
if [[ "$MOCK_CURL_EXIT_CODE" != "0" ]]; then
	exit "$MOCK_CURL_EXIT_CODE"
fi
echo "$MOCK_CURL_RESPONSE"
EOF
	chmod +x "$TEST_DIR/curl"

	# Mock jq if available
	cat >"$TEST_DIR/jq" <<'EOF'
#!/bin/bash
if [[ "$1" == "-r" && "$2" == ".tag_name" ]]; then
	# Extract tag_name from mocked JSON response
	echo "$MOCK_CURL_RESPONSE" | grep -o '"tag_name"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*"tag_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/'
else
	echo "null"
fi
EOF
	chmod +x "$TEST_DIR/jq"
}

teardown() {
	# Restore original PROJECT_ROOT
	if [[ -n "$ORIGINAL_PROJECT_ROOT" ]]; then
		PROJECT_ROOT="$ORIGINAL_PROJECT_ROOT"
		export PROJECT_ROOT
	fi

	# Clean up test directory
	if [[ -n "$TEST_DIR" && -d "$TEST_DIR" ]]; then
		rm -rf "$TEST_DIR"
	fi

	# Restore PATH
	export PATH="${PATH#"$TEST_DIR":}"

	# Call parent teardown
	unset SHELL_STARTER_TEST
	unset TEST_DIR
	unset ORIGINAL_PROJECT_ROOT
	unset MOCK_CURL_RESPONSE
	unset MOCK_CURL_EXIT_CODE
}

# Help and basic functionality tests
@test "check-version: help flag" {
	run "$TEST_DIR/scripts/check-version.sh" --help
	assert_success
	assert_output --partial "Usage:"
	assert_output --partial "Version comparison and update checking script"
	assert_output --partial "COMMANDS:"
	assert_output --partial "OPTIONS:"
	assert_output --partial "EXAMPLES:"
	assert_output --partial "EXIT CODES:"
}

@test "check-version: unknown option" {
	run "$TEST_DIR/scripts/check-version.sh" --invalid-option
	assert_success
	# Unknown options are treated as commands, so this will fail as unknown command
	assert_output --partial "Error: Unknown command '--invalid-option'"
}

# Current version tests
@test "check-version: current command shows version from VERSION file" {
	run "$TEST_DIR/scripts/check-version.sh" current
	assert_success
	assert_output --partial "Current version: 1.2.3"
}

@test "check-version: current command with missing VERSION file" {
	rm "$TEST_DIR/VERSION"
	run "$TEST_DIR/scripts/check-version.sh" current
	assert_success
	assert_output --partial "Current version: 0.0.0"
}

@test "check-version: current command with quiet flag" {
	run "$TEST_DIR/scripts/check-version.sh" --quiet current
	assert_success
	assert_output "1.2.3"
}

# Version comparison tests
@test "check-version: compare equal versions" {
	run "$TEST_DIR/scripts/check-version.sh" compare "1.2.3" "1.2.3"
	assert_success
	assert_output "1.2.3 == 1.2.3"
}

@test "check-version: compare first version greater" {
	run "$TEST_DIR/scripts/check-version.sh" compare "2.0.0" "1.9.9"
	assert_failure
	assert_output "2.0.0 > 1.9.9"
}

@test "check-version: compare first version less" {
	run "$TEST_DIR/scripts/check-version.sh" compare "1.2.3" "1.3.0"
	# Exit code 2 for v1 < v2
	assert_equal "$status" 2
	assert_output "1.2.3 < 1.3.0"
}

@test "check-version: compare with v prefix" {
	run "$TEST_DIR/scripts/check-version.sh" compare "v1.2.3" "v1.2.3"
	assert_success
	assert_output "v1.2.3 == v1.2.3"
}

@test "check-version: compare mixed v prefix" {
	run "$TEST_DIR/scripts/check-version.sh" compare "v2.0.0" "1.9.9"
	assert_failure
	assert_output "v2.0.0 > 1.9.9"
}

@test "check-version: compare different lengths" {
	run "$TEST_DIR/scripts/check-version.sh" compare "1.2" "1.2.0"
	assert_success
	assert_output "1.2 == 1.2.0"
}

@test "check-version: compare with quiet flag" {
	run "$TEST_DIR/scripts/check-version.sh" --quiet compare "1.2.3" "1.2.3"
	assert_success
	assert_output ""
}

@test "check-version: compare missing arguments" {
	run "$TEST_DIR/scripts/check-version.sh" compare "1.2.3"
	assert_equal "$status" 2
	assert_output --partial "Error: compare command requires two version arguments"
}

@test "check-version: compare no arguments" {
	run "$TEST_DIR/scripts/check-version.sh" compare
	assert_equal "$status" 2
	assert_output --partial "Error: compare command requires two version arguments"
}

# Latest version tests (mocked network)
@test "check-version: latest command with successful response" {
	export MOCK_CURL_RESPONSE='{"tag_name":"v1.5.0","name":"Release 1.5.0"}'
	run "$TEST_DIR/scripts/check-version.sh" latest
	assert_success
	assert_output --partial "Latest version: v1.5.0"
}

@test "check-version: latest command with quiet flag" {
	export MOCK_CURL_RESPONSE='{"tag_name":"v1.5.0","name":"Release 1.5.0"}'
	run "$TEST_DIR/scripts/check-version.sh" --quiet latest
	assert_success
	assert_output "v1.5.0"
}

@test "check-version: latest command with custom repository" {
	export MOCK_CURL_RESPONSE='{"tag_name":"v2.1.0","name":"Release 2.1.0"}'
	run "$TEST_DIR/scripts/check-version.sh" latest "owner/custom-repo"
	assert_success
	assert_output --partial "Latest version: v2.1.0"
}

@test "check-version: latest command with network failure" {
	export MOCK_CURL_EXIT_CODE="1"
	run "$TEST_DIR/scripts/check-version.sh" latest
	assert_failure
	assert_output --partial "Error: Failed to fetch release information"
}

@test "check-version: latest command with invalid JSON response" {
	export MOCK_CURL_RESPONSE='{"invalid":"response"}'
	run "$TEST_DIR/scripts/check-version.sh" latest
	assert_failure
	assert_output --partial "Error: Could not parse release information"
}

@test "check-version: latest command with empty response" {
	export MOCK_CURL_RESPONSE=""
	run "$TEST_DIR/scripts/check-version.sh" latest
	assert_failure
	assert_output --partial "Error: Could not parse release information"
}

# Check command tests
@test "check-version: check command - up to date" {
	export MOCK_CURL_RESPONSE='{"tag_name":"v1.2.3","name":"Release 1.2.3"}'
	run "$TEST_DIR/scripts/check-version.sh" check
	assert_failure
	assert_output --partial "You are running the latest version"
}

@test "check-version: check command - update available" {
	export MOCK_CURL_RESPONSE='{"tag_name":"v1.5.0","name":"Release 1.5.0"}'
	run "$TEST_DIR/scripts/check-version.sh" check
	assert_success
	assert_output --partial "An update is available"
}

@test "check-version: check command - ahead of latest" {
	export MOCK_CURL_RESPONSE='{"tag_name":"v1.0.0","name":"Release 1.0.0"}'
	run "$TEST_DIR/scripts/check-version.sh" check
	assert_failure
	assert_output --partial "You are running a newer version than the latest release"
}

@test "check-version: check command with quiet flag - up to date" {
	export MOCK_CURL_RESPONSE='{"tag_name":"v1.2.3","name":"Release 1.2.3"}'
	run "$TEST_DIR/scripts/check-version.sh" --quiet check
	assert_failure
	assert_output "up-to-date"
}

@test "check-version: check command with quiet flag - outdated" {
	export MOCK_CURL_RESPONSE='{"tag_name":"v1.5.0","name":"Release 1.5.0"}'
	run "$TEST_DIR/scripts/check-version.sh" --quiet check
	assert_success
	assert_output "outdated"
}

@test "check-version: check command with quiet flag - ahead" {
	export MOCK_CURL_RESPONSE='{"tag_name":"v1.0.0","name":"Release 1.0.0"}'
	run "$TEST_DIR/scripts/check-version.sh" --quiet check
	assert_failure
	assert_output "ahead"
}

@test "check-version: check command with custom repository" {
	export MOCK_CURL_RESPONSE='{"tag_name":"v2.0.0","name":"Release 2.0.0"}'
	run "$TEST_DIR/scripts/check-version.sh" check "owner/custom-repo"
	assert_success
	assert_output --partial "An update is available"
}

@test "check-version: check command with network failure" {
	export MOCK_CURL_EXIT_CODE="1"
	run "$TEST_DIR/scripts/check-version.sh" check
	assert_failure
	assert_output --partial "Error: Failed to check for updates"
}

# Status command tests
@test "check-version: status command - up to date" {
	export MOCK_CURL_RESPONSE='{"tag_name":"v1.2.3","name":"Release 1.2.3"}'
	run "$TEST_DIR/scripts/check-version.sh" status
	assert_failure
	assert_output --partial "Repository: shell-starter/shell-starter"
	assert_output --partial "Current version: 1.2.3"
	assert_output --partial "Latest version: v1.2.3"
	assert_output --partial "Status: Up to date ✓"
}

@test "check-version: status command - update available" {
	export MOCK_CURL_RESPONSE='{"tag_name":"v2.0.0","name":"Release 2.0.0"}'
	run "$TEST_DIR/scripts/check-version.sh" status
	assert_success
	assert_output --partial "Repository: shell-starter/shell-starter"
	assert_output --partial "Current version: 1.2.3"
	assert_output --partial "Latest version: v2.0.0"
	assert_output --partial "Status: Update available"
}

@test "check-version: status command - ahead of latest" {
	export MOCK_CURL_RESPONSE='{"tag_name":"v1.0.0","name":"Release 1.0.0"}'
	run "$TEST_DIR/scripts/check-version.sh" status
	assert_failure
	assert_output --partial "Repository: shell-starter/shell-starter"
	assert_output --partial "Current version: 1.2.3"
	assert_output --partial "Latest version: v1.0.0"
	assert_output --partial "Status: Ahead of latest release"
}

@test "check-version: status command with custom repository" {
	export MOCK_CURL_RESPONSE='{"tag_name":"v1.5.0","name":"Release 1.5.0"}'
	run "$TEST_DIR/scripts/check-version.sh" status "owner/custom-repo"
	assert_success
	assert_output --partial "Repository: owner/custom-repo"
	assert_output --partial "Current version: 1.2.3"
	assert_output --partial "Latest version: v1.5.0"
	assert_output --partial "Status: Update available"
}

@test "check-version: status command with quiet flag" {
	export MOCK_CURL_RESPONSE='{"tag_name":"v1.2.3","name":"Release 1.2.3"}'
	run "$TEST_DIR/scripts/check-version.sh" --quiet status
	assert_failure
	assert_output "up-to-date"
}

@test "check-version: status command with network failure" {
	export MOCK_CURL_EXIT_CODE="1"
	run "$TEST_DIR/scripts/check-version.sh" status
	assert_failure
	assert_output --partial "Error: Failed to fetch release information"
}

# Default command (status) tests
@test "check-version: default command is status" {
	export MOCK_CURL_RESPONSE='{"tag_name":"v1.2.3","name":"Release 1.2.3"}'
	run "$TEST_DIR/scripts/check-version.sh"
	assert_failure
	assert_output --partial "Repository: shell-starter/shell-starter"
	assert_output --partial "Current version: 1.2.3"
	assert_output --partial "Latest version: v1.2.3"
	assert_output --partial "Status: Up to date ✓"
}

# Edge cases and error handling
@test "check-version: handles curl not available" {
	# Remove curl from PATH
	rm "$TEST_DIR/curl"

	run "$TEST_DIR/scripts/check-version.sh" latest
	assert_failure
	assert_output --partial "Error: curl is required but not installed"
}

@test "check-version: handles complex version comparisons" {
	run "$TEST_DIR/scripts/check-version.sh" compare "1.0.0" "1.0.0-alpha"
	assert_failure
	# 1.0.0 should be greater than 1.0.0-alpha in most cases
	# but our implementation treats them as numeric comparison
}

@test "check-version: handles version comparison with leading zeros" {
	run "$TEST_DIR/scripts/check-version.sh" compare "1.02.3" "1.2.03"
	assert_success
	assert_output "1.02.3 == 1.2.03"
}

@test "check-version: handles empty version parts" {
	run "$TEST_DIR/scripts/check-version.sh" compare "1..3" "1.0.3"
	assert_success
	assert_output "1..3 == 1.0.3"
}

@test "check-version: unknown command" {
	run "$TEST_DIR/scripts/check-version.sh" unknown-command
	assert_equal "$status" 2
	assert_output --partial "Error: Unknown command 'unknown-command'"
	assert_output --partial "Use"
	assert_output --partial "--help"
}

# JSON parsing without jq tests
@test "check-version: parses JSON without jq when jq is not available" {
	# Remove jq from PATH to test fallback parsing
	rm "$TEST_DIR/jq"

	export MOCK_CURL_RESPONSE='{"tag_name": "v1.4.0", "name": "Release 1.4.0"}'
	run "$TEST_DIR/scripts/check-version.sh" latest
	assert_success
	assert_output --partial "Latest version: v1.4.0"
}

@test "check-version: handles JSON with spaces in parsing" {
	export MOCK_CURL_RESPONSE='{ "tag_name" : "v1.6.0" , "name" : "Release 1.6.0" }'
	run "$TEST_DIR/scripts/check-version.sh" latest
	assert_success
	assert_output --partial "Latest version: v1.6.0"
}

# Integration-style tests
@test "check-version: end-to-end version comparison workflow" {
	# Test a complete workflow of checking current, getting latest, and comparing
	export MOCK_CURL_RESPONSE='{"tag_name":"v1.5.0","name":"Release 1.5.0"}'

	# Get current version
	run "$TEST_DIR/scripts/check-version.sh" --quiet current
	assert_success
	local current_version="$output"

	# Get latest version
	run "$TEST_DIR/scripts/check-version.sh" --quiet latest
	assert_success
	local latest_version="$output"

	# Compare them
	run "$TEST_DIR/scripts/check-version.sh" --quiet compare "$current_version" "$latest_version"
	assert_equal "$status" 2 # current < latest
}

# Error handling for VERSION file issues
@test "check-version: handles unreadable VERSION file gracefully" {
	# Make VERSION file unreadable (simulating permission issues)
	chmod 000 "$TEST_DIR/VERSION" 2>/dev/null || skip "Cannot change file permissions on this system"

	run "$TEST_DIR/scripts/check-version.sh" current
	# Should fallback to 0.0.0 or handle gracefully
	assert_success
}

# Environment variable tests
@test "check-version: respects GITHUB_REPO environment variable" {
	export GITHUB_REPO="custom/repo"
	export MOCK_CURL_RESPONSE='{"tag_name":"v3.0.0","name":"Release 3.0.0"}'

	run "$TEST_DIR/scripts/check-version.sh" status
	assert_success
	assert_output --partial "Repository: custom/repo"
}
