#!/usr/bin/env bats
#
# Tests for lib/update.sh - update management library

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
	mkdir -p "$TEST_DIR/lib"
	mkdir -p "$TEST_DIR/.config/shell-starter"

	# Copy the library files to test directory
	cp "${ORIGINAL_PROJECT_ROOT}/lib/colors.sh" "$TEST_DIR/lib/"
	cp "${ORIGINAL_PROJECT_ROOT}/lib/logging.sh" "$TEST_DIR/lib/"
	cp "${ORIGINAL_PROJECT_ROOT}/lib/main.sh" "$TEST_DIR/lib/"
	cp "${ORIGINAL_PROJECT_ROOT}/lib/update.sh" "$TEST_DIR/lib/"

	# Create test VERSION file
	echo "1.2.3" >"$TEST_DIR/VERSION"

	# Source the update library
	cd "$TEST_DIR"
	source "$TEST_DIR/lib/update.sh"

	# Mock curl for network tests
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

	# Mock jq
	cat >"$TEST_DIR/jq" <<'EOF'
#!/bin/bash
if [[ "$1" == "-r" && "$2" == ".tag_name" ]]; then
	echo "$MOCK_CURL_RESPONSE" | grep -o '"tag_name"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*"tag_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/'
elif [[ "$1" == "-r" && "$2" == ".tarball_url" ]]; then
	echo "$MOCK_CURL_RESPONSE" | grep -o '"tarball_url"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*"tarball_url"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/'
else
	echo "null"
fi
EOF
	chmod +x "$TEST_DIR/jq"

	# Override config directory for testing
	export UPDATE_CONFIG_DIR="$TEST_DIR/.config/shell-starter"
	export UPDATE_CONFIG_FILE="$UPDATE_CONFIG_DIR/update-notifications.conf"
	export UPDATE_LAST_CHECK_FILE="$UPDATE_CONFIG_DIR/last-update-check"

	# Mock date for consistent timestamp testing
	export MOCK_TIMESTAMP="1640995200" # 2022-01-01 00:00:00
	cat >"$TEST_DIR/date" <<'EOF'
#!/bin/bash
if [[ "$1" == "+%s" ]]; then
	echo "$MOCK_TIMESTAMP"
elif [[ "$1" == "-r" ]]; then
	# Mock date -r for showing human readable time
	echo "Sat Jan  1 00:00:00 UTC 2022"
else
	command date "$@"
fi
EOF
	chmod +x "$TEST_DIR/date"
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
	unset MOCK_TIMESTAMP
	unset UPDATE_CONFIG_DIR
	unset UPDATE_CONFIG_FILE
	unset UPDATE_LAST_CHECK_FILE
}

# Version comparison tests
@test "lib-update: version_compare - equal versions" {
	version_compare "1.2.3" "1.2.3"
	assert_equal "$?" 0
}

@test "lib-update: version_compare - first version greater" {
	version_compare "2.0.0" "1.9.9"
	assert_equal "$?" 1
}

@test "lib-update: version_compare - first version less" {
	version_compare "1.2.3" "1.3.0"
	assert_equal "$?" 2
}

@test "lib-update: version_compare - handles v prefix" {
	version_compare "v1.2.3" "v1.2.3"
	assert_equal "$?" 0
}

@test "lib-update: version_compare - mixed v prefix" {
	version_compare "v2.0.0" "1.9.9"
	assert_equal "$?" 1
}

@test "lib-update: version_compare - different lengths" {
	version_compare "1.2" "1.2.0"
	assert_equal "$?" 0
}

@test "lib-update: version_compare - handles leading zeros" {
	version_compare "1.02.3" "1.2.03"
	assert_equal "$?" 0
}

@test "lib-update: version_compare - handles empty parts" {
	version_compare "1..3" "1.0.3"
	assert_equal "$?" 0
}

@test "lib-update: version_compare - complex versions" {
	version_compare "1.10.5" "1.9.20"
	assert_equal "$?" 1
}

# get_latest_release tests
@test "lib-update: get_latest_release - successful response" {
	export MOCK_CURL_RESPONSE='{"tag_name":"v1.5.0","name":"Release 1.5.0"}'

	run get_latest_release
	assert_success
	assert_output "v1.5.0"
}

@test "lib-update: get_latest_release - with custom repository" {
	export MOCK_CURL_RESPONSE='{"tag_name":"v2.1.0","name":"Release 2.1.0"}'

	run get_latest_release "owner/custom-repo"
	assert_success
	assert_output "v2.1.0"
}

@test "lib-update: get_latest_release - network failure" {
	export MOCK_CURL_EXIT_CODE="1"

	run get_latest_release
	assert_failure
}

@test "lib-update: get_latest_release - invalid JSON response" {
	export MOCK_CURL_RESPONSE='{"invalid":"response"}'

	run get_latest_release
	assert_failure
}

@test "lib-update: get_latest_release - empty response" {
	export MOCK_CURL_RESPONSE=""

	run get_latest_release
	assert_failure
}

@test "lib-update: get_latest_release - null tag_name" {
	export MOCK_CURL_RESPONSE='{"tag_name":null,"name":"Invalid Release"}'

	run get_latest_release
	assert_failure
}

@test "lib-update: get_latest_release - fallback parsing without jq" {
	# Remove jq from PATH to test fallback
	rm "$TEST_DIR/jq"
	export MOCK_CURL_RESPONSE='{"tag_name": "v1.4.0", "name": "Release 1.4.0"}'

	run get_latest_release
	assert_success
	assert_output "v1.4.0"
}

@test "lib-update: get_latest_release - handles curl not available" {
	# Remove curl from PATH
	rm "$TEST_DIR/curl"

	run get_latest_release
	assert_failure
}

# check_for_update tests
@test "lib-update: check_for_update - up to date" {
	export MOCK_CURL_RESPONSE='{"tag_name":"v1.2.3","name":"Release 1.2.3"}'

	run check_for_update "1.2.3"
	assert_failure
}

@test "lib-update: check_for_update - update available" {
	export MOCK_CURL_RESPONSE='{"tag_name":"v1.5.0","name":"Release 1.5.0"}'

	run check_for_update "1.2.3"
	assert_success
	assert_output "v1.5.0"
}

@test "lib-update: check_for_update - ahead of latest" {
	export MOCK_CURL_RESPONSE='{"tag_name":"v1.0.0","name":"Release 1.0.0"}'

	run check_for_update "1.2.3"
	assert_failure
}

@test "lib-update: check_for_update - uses VERSION file when no version provided" {
	export MOCK_CURL_RESPONSE='{"tag_name":"v1.5.0","name":"Release 1.5.0"}'

	run check_for_update
	assert_success
	assert_output "v1.5.0"
}

@test "lib-update: check_for_update - custom repository" {
	export MOCK_CURL_RESPONSE='{"tag_name":"v2.0.0","name":"Release 2.0.0"}'

	run check_for_update "1.2.3" "owner/custom-repo"
	assert_success
	assert_output "v2.0.0"
}

@test "lib-update: check_for_update - network failure" {
	export MOCK_CURL_EXIT_CODE="1"

	run check_for_update "1.2.3"
	assert_failure
}

# get_release_download_url tests
@test "lib-update: get_release_download_url - latest release" {
	export MOCK_CURL_RESPONSE='{"tag_name":"v1.5.0","tarball_url":"https://api.github.com/repos/owner/repo/tarball/v1.5.0"}'

	run get_release_download_url "owner/repo"
	assert_success
	assert_output "https://api.github.com/repos/owner/repo/tarball/v1.5.0"
}

@test "lib-update: get_release_download_url - specific tag" {
	export MOCK_CURL_RESPONSE='{"tag_name":"v1.3.0","tarball_url":"https://api.github.com/repos/owner/repo/tarball/v1.3.0"}'

	run get_release_download_url "owner/repo" "v1.3.0"
	assert_success
	assert_output "https://api.github.com/repos/owner/repo/tarball/v1.3.0"
}

@test "lib-update: get_release_download_url - fallback parsing without jq" {
	rm "$TEST_DIR/jq"
	export MOCK_CURL_RESPONSE='{"tarball_url": "https://api.github.com/repos/owner/repo/tarball/v1.4.0"}'

	run get_release_download_url "owner/repo"
	assert_success
	assert_output "https://api.github.com/repos/owner/repo/tarball/v1.4.0"
}

@test "lib-update: get_release_download_url - network failure" {
	export MOCK_CURL_EXIT_CODE="1"

	run get_release_download_url "owner/repo"
	assert_failure
}

@test "lib-update: get_release_download_url - invalid response" {
	export MOCK_CURL_RESPONSE='{"invalid":"response"}'

	run get_release_download_url "owner/repo"
	assert_failure
}

# update::info tests
@test "lib-update: update::info - update available" {
	export MOCK_CURL_RESPONSE='{"tag_name":"v2.0.0","name":"Release 2.0.0"}'

	run update::info "1.2.3"
	assert_success
	assert_output --partial "Update Check for shell-starter/shell-starter"
	assert_output --partial "Current version: 1.2.3"
	assert_output --partial "Latest version: v2.0.0"
	assert_output --partial "Update available!"
}

@test "lib-update: update::info - no update available" {
	export MOCK_CURL_RESPONSE='{"tag_name":"v1.2.3","name":"Release 1.2.3"}'

	run update::info "1.2.3"
	assert_failure
	assert_output --partial "Update Check for shell-starter/shell-starter"
	assert_output --partial "Current version: 1.2.3"
	assert_output --partial "No update available."
}

@test "lib-update: update::info - custom repository" {
	export MOCK_CURL_RESPONSE='{"tag_name":"v1.5.0","name":"Release 1.5.0"}'

	run update::info "1.2.3" "owner/custom-repo"
	assert_success
	assert_output --partial "Update Check for owner/custom-repo"
	assert_output --partial "Current version: 1.2.3"
	assert_output --partial "Latest version: v1.5.0"
	assert_output --partial "Update available!"
}

# Configuration management tests
@test "lib-update: ensure_config_dir creates directory" {
	rm -rf "$UPDATE_CONFIG_DIR"

	ensure_config_dir

	assert [ -d "$UPDATE_CONFIG_DIR" ]
}

@test "lib-update: get_config_value returns default when file doesn't exist" {
	rm -f "$UPDATE_CONFIG_FILE"

	run get_config_value "TEST_KEY" "default_value"
	assert_success
	assert_output "default_value"
}

@test "lib-update: get_config_value returns stored value" {
	mkdir -p "$UPDATE_CONFIG_DIR"
	echo "TEST_KEY=stored_value" >"$UPDATE_CONFIG_FILE"

	run get_config_value "TEST_KEY" "default_value"
	assert_success
	assert_output "stored_value"
}

@test "lib-update: set_config_value creates and sets value" {
	rm -f "$UPDATE_CONFIG_FILE"

	set_config_value "TEST_KEY" "test_value"

	assert [ -f "$UPDATE_CONFIG_FILE" ]
	run grep "TEST_KEY=test_value" "$UPDATE_CONFIG_FILE"
	assert_success
}

@test "lib-update: set_config_value updates existing value" {
	mkdir -p "$UPDATE_CONFIG_DIR"
	echo "TEST_KEY=old_value" >"$UPDATE_CONFIG_FILE"
	echo "OTHER_KEY=other_value" >>"$UPDATE_CONFIG_FILE"

	set_config_value "TEST_KEY" "new_value"

	# Should have new value
	run grep "TEST_KEY=new_value" "$UPDATE_CONFIG_FILE"
	assert_success

	# Should preserve other values
	run grep "OTHER_KEY=other_value" "$UPDATE_CONFIG_FILE"
	assert_success

	# Should not have old value
	run grep "TEST_KEY=old_value" "$UPDATE_CONFIG_FILE"
	assert_failure
}

# Time-based checking tests
@test "lib-update: should_check_for_update returns true when never checked" {
	rm -f "$UPDATE_LAST_CHECK_FILE"

	should_check_for_update
	assert_equal "$?" 0
}

@test "lib-update: should_check_for_update returns false when recently checked" {
	mkdir -p "$UPDATE_CONFIG_DIR"
	# Set last check to current timestamp (mocked)
	echo "$MOCK_TIMESTAMP" >"$UPDATE_LAST_CHECK_FILE"

	should_check_for_update
	assert_equal "$?" 1
}

@test "lib-update: should_check_for_update respects custom interval" {
	mkdir -p "$UPDATE_CONFIG_DIR"
	# Set interval to 1 hour
	echo "CHECK_INTERVAL_HOURS=1" >"$UPDATE_CONFIG_FILE"

	# Set last check to 2 hours ago (7200 seconds)
	old_timestamp=$((MOCK_TIMESTAMP - 7200))
	echo "$old_timestamp" >"$UPDATE_LAST_CHECK_FILE"

	should_check_for_update
	assert_equal "$?" 0
}

@test "lib-update: record_check_time writes timestamp" {
	rm -f "$UPDATE_LAST_CHECK_FILE"

	record_check_time

	assert [ -f "$UPDATE_LAST_CHECK_FILE" ]
	run cat "$UPDATE_LAST_CHECK_FILE"
	assert_output "$MOCK_TIMESTAMP"
}

# Notification tests
@test "lib-update: notify_update_available with quiet mode" {
	run notify_update_available "1.2.3" "1.5.0" "true"
	assert_success
	# Should produce log output (implementation detail may vary)
}

@test "lib-update: notify_update_available without quiet mode" {
	run notify_update_available "1.2.3" "1.5.0" "false"
	assert_success
	assert_output --partial "Update available: 1.2.3 → 1.5.0"
}

# Optional update check tests
@test "lib-update: optional_update_check with notifications disabled" {
	set_config_value "NOTIFICATIONS_ENABLED" "false"

	run optional_update_check
	assert_success
}

@test "lib-update: optional_update_check with notifications enabled but recently checked" {
	set_config_value "NOTIFICATIONS_ENABLED" "true"
	echo "$MOCK_TIMESTAMP" >"$UPDATE_LAST_CHECK_FILE"

	run optional_update_check
	assert_success
}

@test "lib-update: optional_update_check performs check when conditions are met" {
	set_config_value "NOTIFICATIONS_ENABLED" "true"
	rm -f "$UPDATE_LAST_CHECK_FILE" # Never checked
	export MOCK_CURL_RESPONSE='{"tag_name":"v1.5.0","name":"Release 1.5.0"}'

	run optional_update_check
	assert_success

	# Should record the check time
	assert [ -f "$UPDATE_LAST_CHECK_FILE" ]
}

@test "lib-update: optional_update_check handles network failure gracefully" {
	set_config_value "NOTIFICATIONS_ENABLED" "true"
	rm -f "$UPDATE_LAST_CHECK_FILE"
	export MOCK_CURL_EXIT_CODE="1"

	run optional_update_check
	assert_failure

	# Should still record the check time even on failure
	assert [ -f "$UPDATE_LAST_CHECK_FILE" ]
}

# update::config tests
@test "lib-update: update::config enable" {
	run update::config enable
	assert_success

	# Check that configuration was set
	local enabled
	enabled=$(get_config_value "NOTIFICATIONS_ENABLED" "false")
	assert_equal "$enabled" "true"
}

@test "lib-update: update::config disable" {
	run update::config disable
	assert_success

	# Check that configuration was set
	local enabled
	enabled=$(get_config_value "NOTIFICATIONS_ENABLED" "true")
	assert_equal "$enabled" "false"
}

@test "lib-update: update::config interval with valid hours" {
	run update::config interval 48
	assert_success

	# Check that configuration was set
	local interval
	interval=$(get_config_value "CHECK_INTERVAL_HOURS" "24")
	assert_equal "$interval" "48"
}

@test "lib-update: update::config interval with invalid hours" {
	run update::config interval "invalid"
	assert_failure
}

@test "lib-update: update::config status shows configuration" {
	set_config_value "NOTIFICATIONS_ENABLED" "true"
	set_config_value "CHECK_INTERVAL_HOURS" "12"
	set_config_value "SHOW_QUIET_NOTIFICATIONS" "false"
	echo "$MOCK_TIMESTAMP" >"$UPDATE_LAST_CHECK_FILE"

	run update::config status
	assert_success
	assert_output --partial "Update Notification Configuration:"
	assert_output --partial "Enabled: true"
	assert_output --partial "Check interval: 12 hours"
	assert_output --partial "Quiet notifications: false"
	assert_output --partial "Last check:"
}

@test "lib-update: update::config status shows never checked" {
	rm -f "$UPDATE_LAST_CHECK_FILE"

	run update::config status
	assert_success
	assert_output --partial "Last check: Never"
}

@test "lib-update: update::config quiet on" {
	run update::config quiet on
	assert_success

	local quiet
	quiet=$(get_config_value "SHOW_QUIET_NOTIFICATIONS" "false")
	assert_equal "$quiet" "true"
}

@test "lib-update: update::config quiet off" {
	run update::config quiet off
	assert_success

	local quiet
	quiet=$(get_config_value "SHOW_QUIET_NOTIFICATIONS" "true")
	assert_equal "$quiet" "false"
}

@test "lib-update: update::config quiet with invalid mode" {
	run update::config quiet invalid
	assert_failure
}

@test "lib-update: update::config shows help for unknown action" {
	run update::config unknown
	assert_success
	assert_output --partial "Usage: update::config <action> [args]"
	assert_output --partial "ACTIONS:"
	assert_output --partial "EXAMPLES:"
}

@test "lib-update: update::config shows help for no action" {
	run update::config
	assert_success
	assert_output --partial "Usage: update::config <action> [args]"
}

# Integration tests
@test "lib-update: full update workflow with notifications" {
	# Enable notifications
	set_config_value "NOTIFICATIONS_ENABLED" "true"
	set_config_value "CHECK_INTERVAL_HOURS" "1"
	rm -f "$UPDATE_LAST_CHECK_FILE"

	# Mock an update being available
	export MOCK_CURL_RESPONSE='{"tag_name":"v2.0.0","name":"Release 2.0.0"}'

	# Perform optional check
	run optional_update_check "owner/repo" "test-script"
	assert_success

	# Check that timestamp was recorded
	assert [ -f "$UPDATE_LAST_CHECK_FILE" ]

	# Get detailed info
	run update::info "1.2.3" "owner/repo"
	assert_success
	assert_output --partial "Update available!"
}

@test "lib-update: configuration persists across function calls" {
	# Set configuration
	set_config_value "NOTIFICATIONS_ENABLED" "true"
	set_config_value "CHECK_INTERVAL_HOURS" "72"

	# Verify persistence
	local enabled interval
	enabled=$(get_config_value "NOTIFICATIONS_ENABLED" "false")
	interval=$(get_config_value "CHECK_INTERVAL_HOURS" "24")

	assert_equal "$enabled" "true"
	assert_equal "$interval" "72"
}

# Edge cases and error handling
@test "lib-update: handles malformed VERSION file gracefully" {
	echo "invalid-version" >"$TEST_DIR/VERSION"

	# Should still work, treating invalid version as-is
	export MOCK_CURL_RESPONSE='{"tag_name":"v1.5.0","name":"Release 1.5.0"}'
	run check_for_update
	assert_success
}

@test "lib-update: handles missing VERSION file gracefully" {
	rm "$TEST_DIR/VERSION"

	export MOCK_CURL_RESPONSE='{"tag_name":"v1.5.0","name":"Release 1.5.0"}'
	run check_for_update
	assert_success
}

@test "lib-update: handles config file with malformed entries" {
	mkdir -p "$UPDATE_CONFIG_DIR"
	echo "VALID_KEY=valid_value" >"$UPDATE_CONFIG_FILE"
	echo "malformed line without equals" >>"$UPDATE_CONFIG_FILE"
	echo "ANOTHER_KEY=another_value" >>"$UPDATE_CONFIG_FILE"

	# Should still work and find valid entries
	run get_config_value "VALID_KEY" "default"
	assert_success
	assert_output "valid_value"

	run get_config_value "ANOTHER_KEY" "default"
	assert_success
	assert_output "another_value"
}
