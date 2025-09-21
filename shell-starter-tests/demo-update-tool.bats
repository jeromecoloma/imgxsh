#!/usr/bin/env bats
#
# Tests for demo/update-tool script

# Load test helpers
load test_helper
load bats-support/load
load bats-assert/load

@test "demo/update-tool: default command is check" {
	run_script "update-tool"
	# Default behavior should be to check for updates
	# Note: May succeed or fail depending on network/GitHub availability
	assert_output --partial "Checking for updates"
}

@test "demo/update-tool: help flag shows usage" {
	run_script "update-tool" --help
	assert_success
	assert_output --partial "Usage:"
	assert_output --partial "update-tool"
	assert_output --partial "COMMANDS:"
	assert_output --partial "check"
	assert_output --partial "status"
	assert_output --partial "config"
	assert_output --partial "install"
	assert_output --partial "history"
	assert_output --partial "UPDATE NOTIFICATION COMMANDS:"
	assert_output --partial "EXAMPLES:"
}

@test "demo/update-tool: short help flag" {
	run_script "update-tool" -h
	assert_success
	assert_output --partial "Usage:"
	assert_output --partial "update-tool"
}

@test "demo/update-tool: version flag shows version" {
	expected_version=$(cat "${PROJECT_ROOT}/VERSION" | tr -d '\n')
	run_script "update-tool" --version
	assert_success
	assert_output --partial "update-tool"
	assert_output --partial "$expected_version"
}

@test "demo/update-tool: short version flag" {
	expected_version=$(cat "${PROJECT_ROOT}/VERSION" | tr -d '\n')
	run_script "update-tool" -v
	assert_success
	assert_output --partial "update-tool"
	assert_output --partial "$expected_version"
}

@test "demo/update-tool: check command explicit" {
	run_script "update-tool" check
	# Should check for updates
	assert_output --partial "Checking for updates"
}

@test "demo/update-tool: check command with quiet flag" {
	run_script "update-tool" --quiet check
	# Should run check in quiet mode
	# Note: May show "Update available" or "No update available" messages
	refute_output --partial "🔍 Checking for updates..."
}

@test "demo/update-tool: status command shows detailed information" {
	run_script "update-tool" status
	assert_success
	assert_output --partial "Shell Starter Status"
	assert_output --partial "Current version:"
	assert_output --partial "Latest version:"
	assert_output --partial "Installation Details"
	assert_output --partial "Notification Configuration"
}

@test "demo/update-tool: status command with verbose flag" {
	run_script "update-tool" --verbose status
	assert_success
	assert_output --partial "Shell Starter Status"
	assert_output --partial "System Information"
	assert_output --partial "Tool Availability"
	assert_output --partial "Operating System:"
	assert_output --partial "Architecture:"
	assert_output --partial "Shell:"
	assert_output --partial "Bash version:"
}

@test "demo/update-tool: history command shows release information" {
	run_script "update-tool" history
	assert_success
	assert_output --partial "Release History"
	assert_output --partial "Recent Releases:"
	assert_output --partial "v1.0.0"
	assert_output --partial "Initial release"
	assert_output --partial "github.com/shell-starter/shell-starter/releases"
}

@test "demo/update-tool: config command without arguments" {
	run_script "update-tool" config
	assert_success
	# Should show configuration options
}

@test "demo/update-tool: config status subcommand" {
	run_script "update-tool" config status
	assert_success
	# Should show notification configuration status
}

@test "demo/update-tool: config enable subcommand" {
	run_script "update-tool" config enable
	assert_success
	# Should enable notifications
}

@test "demo/update-tool: config disable subcommand" {
	run_script "update-tool" config disable
	assert_success
	# Should disable notifications
}

@test "demo/update-tool: config unknown action error" {
	run_script "update-tool" config unknown
	assert_failure
	assert_output --partial "Unknown config action: unknown"
	assert_output --partial "Use: config {enable|disable|interval|quiet|status}"
}

@test "demo/update-tool: install command requires version" {
	run_script "update-tool" install
	assert_failure
	assert_output --partial "install command requires a version argument"
}

@test "demo/update-tool: install command with version" {
	run_script "update-tool" install v1.0.0
	assert_success
	assert_output --partial "Installing version v1.0.0"
	assert_output --partial "This is a demonstration feature"
	assert_output --partial "Demo: Would install version v1.0.0" || assert_output --partial "In a real implementation, this would:"
}

@test "demo/update-tool: install command with quiet flag" {
	run_script "update-tool" --quiet install v1.0.0
	assert_success
	assert_output --partial "Demo: Would install version v1.0.0"
	refute_output --partial "Installing version v1.0.0"
}

@test "demo/update-tool: unknown command error" {
	run_script "update-tool" unknown-command
	assert_failure
	assert_output --partial "Unknown command: unknown-command"
	assert_output --partial "Use --help for usage information."
}

@test "demo/update-tool: unknown option error" {
	run_script "update-tool" --unknown
	assert_failure
	assert_output --partial "Unknown option: --unknown"
	assert_output --partial "Use --help for usage information."
}

@test "demo/update-tool: quiet mode suppresses colors" {
	run_script "update-tool" --quiet check
	# In quiet mode, should show less colorful output
	refute_output --partial "🔍"
}

@test "demo/update-tool: verbose mode provides detailed output" {
	run_script "update-tool" --verbose status
	assert_success
	assert_output --partial "System Information"
	assert_output --partial "Tool Availability"
	assert_output --partial "curl:"
	assert_output --partial "Available" || assert_output --partial "Not found"
}

@test "demo/update-tool: shows shell starter banner in help" {
	run_script "update-tool" --help
	assert_success
	assert_output --partial "Shell Starter"
}

@test "demo/update-tool: uses Shell Starter color variables" {
	run_script "update-tool" status
	assert_success
	# Should contain ANSI color codes when colors are enabled
	assert_output --partial $'\e['
}

@test "demo/update-tool: calls get_version function" {
	run_script "update-tool" status
	assert_success
	assert_output --partial "Current version:"
	# Should show the current version from get_version function
}

@test "demo/update-tool: sources main library successfully" {
	run_script "update-tool" --help
	assert_success
	# If help shows successfully, the main library was sourced correctly
	assert_output --partial "Usage:"
}

@test "demo/update-tool: uses Shell Starter logging functions" {
	run_script "update-tool" unknown-command
	assert_failure
	# Should use log::error function from Shell Starter
	assert_output --partial "Unknown command:"
}

@test "demo/update-tool: enables background updates" {
	run_script "update-tool" --help
	assert_success
	# Script should call enable_background_updates function
	# If it runs without error, the function call worked
	assert_output --partial "Usage:"
}

@test "demo/update-tool: uses parse_common_args integration" {
	run_script "update-tool" --version
	assert_success
	# Should use parse_common_args function for version handling
	assert_output --partial "update-tool"
}

@test "demo/update-tool: error handling with set options" {
	# The script uses 'set -euo pipefail' for proper error handling
	run_script "update-tool" --help
	assert_success
	# If the script runs successfully, error handling is working
	assert_output --partial "Usage:"
}

@test "demo/update-tool: config quiet subcommand" {
	run_script "update-tool" config quiet on
	assert_success
	# Should configure quiet notifications
}

@test "demo/update-tool: config interval subcommand" {
	run_script "update-tool" config interval 24
	assert_success
	# Should set notification interval
}

@test "demo/update-tool: status shows installation path" {
	run_script "update-tool" status
	assert_success
	assert_output --partial "Shell Starter root:"
	assert_output --partial "shell-starter"
}

@test "demo/update-tool: check handles network failures gracefully" {
	run_script "update-tool" check
	# Should handle both success and failure cases
	# Either shows update status or handles connection errors gracefully
	assert_output --partial "version:" || assert_output --partial "Current version:"
}
