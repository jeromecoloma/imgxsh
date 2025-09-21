#!/usr/bin/env bats
#
# Comprehensive argument validation tests for all scripts
# Tests edge cases, invalid inputs, and error handling

# Load test helpers
load test_helper
load bats-support/load
load bats-assert/load

# Test helper function to check invalid flag handling
test_invalid_flag() {
	local script="$1"
	local invalid_flag="$2"

	run_script "$script" "$invalid_flag"
	assert_failure
	assert_output --partial "Unknown option:"
	assert_output --partial "$invalid_flag"
}

# Test helper function to check help output
test_help_output() {
	local script="$1"

	run_script "$script" --help
	assert_success
	# Check for either "Usage:" or "USAGE:" (both formats are used)
	assert_output --regexp "(Usage|USAGE):"
}

# Test helper function to check version output
test_version_output() {
	local script="$1"

	run_script "$script" --version
	assert_success
	# Should contain semantic version (may have different format)
	assert_output --regexp "[0-9]+\.[0-9]+\.[0-9]+"
}

@test "argument validation: all bin scripts handle --help" {
	local scripts=("bump-version" "update-shell-starter" "generate-ai-workflow")

	for script in "${scripts[@]}"; do
		test_help_output "$script"
	done
}

@test "argument validation: all bin scripts handle --version" {
	local scripts=("bump-version" "update-shell-starter" "generate-ai-workflow")

	for script in "${scripts[@]}"; do
		test_version_output "$script"
	done
}

@test "argument validation: all demo scripts handle --help" {
	local scripts=("hello-world" "greet-user" "show-colors" "show-banner" "long-task" "my-cli" "ai-action" "debug-colors" "update-tool" "polyglot-example")

	for script in "${scripts[@]}"; do
		test_help_output "$script"
	done
}

@test "argument validation: all demo scripts handle --version" {
	local scripts=("hello-world" "greet-user" "show-colors" "show-banner" "long-task" "my-cli" "ai-action" "debug-colors" "update-tool" "polyglot-example")

	for script in "${scripts[@]}"; do
		test_version_output "$script"
	done
}

@test "argument validation: invalid flags are rejected consistently" {
	local scripts=("bump-version" "update-shell-starter" "generate-ai-workflow" "hello-world" "greet-user")
	local invalid_flags=("--invalid" "--fake-flag" "--xyz" "-z" "--long-invalid-flag")

	for script in "${scripts[@]}"; do
		for flag in "${invalid_flags[@]}"; do
			test_invalid_flag "$script" "$flag"
		done
	done
}

@test "argument validation: empty arguments handled properly" {
	# Scripts that require arguments should fail gracefully
	run_script "bump-version"
	assert_failure
	assert_output --partial "required"

	run_script "generate-ai-workflow"
	assert_failure
	assert_output --partial "required"

	# Scripts that don't require arguments should succeed
	run_script "hello-world"
	assert_success

	run_script "show-colors"
	assert_success
}

@test "argument validation: excessive arguments handled properly" {
	# Test too many arguments
	run_script "bump-version" "1.0.0" "2.0.0" "3.0.0"
	assert_failure
	assert_output --partial "Multiple version arguments"

	# Some scripts should handle extra arguments gracefully
	run_script "hello-world" "extra" "args" "ignored"
	assert_success
}

@test "argument validation: special characters in arguments" {
	# Test special characters that might break parsing
	# Using single quotes intentionally to prevent expansion during testing
	# shellcheck disable=SC2016
	local special_chars=('$VAR' '$(command)' '`command`' ';rm -rf /' '../../etc/passwd' '<script>' '&nbsp;')

	for char in "${special_chars[@]}"; do
		run_script "generate-ai-workflow" "$char"
		assert_failure
		# Should fail validation, not execute dangerous commands
		assert_output --partial "must contain only letters, numbers, hyphens, and underscores"
	done
}

@test "argument validation: unicode and non-ASCII characters" {
	# Test unicode project names
	run_script "generate-ai-workflow" "プロジェクト"
	assert_failure
	assert_output --partial "must contain only letters, numbers, hyphens, and underscores"

	run_script "generate-ai-workflow" "project-émoji"
	assert_failure
	assert_output --partial "must contain only letters, numbers, hyphens, and underscores"
}

@test "argument validation: very long arguments" {
	# Test extremely long project name
	local long_name
	long_name=$(printf 'a%.0s' {1..1000}) # 1000 character string

	run_script "generate-ai-workflow" "$long_name"
	assert_failure
	# Should have reasonable length limits
}

@test "argument validation: boundary value testing" {
	# Test empty string
	run_script "generate-ai-workflow" ""
	assert_failure
	assert_output --partial "required"

	# Test single character
	run bash -c "echo 'y' | '${PROJECT_ROOT}/bin/generate-ai-workflow' 'a'"
	assert_success

	# Test whitespace-only
	run_script "generate-ai-workflow" "   "
	assert_failure
	assert_output --partial "required"
}

@test "argument validation: conflicting flags" {
	# Test conflicting version flags
	run_script "bump-version" "--version" "--help"
	# Should handle gracefully - typically version takes precedence
	assert_success

	# Test dry-run with current version
	run_script "bump-version" "--dry-run" "--current"
	assert_success
	assert_output --partial "Current version:"
}

@test "argument validation: case sensitivity" {
	# Test case variations of flags
	run_script "bump-version" "--HELP"
	assert_failure
	assert_output --partial "Unknown option: --HELP"

	run_script "bump-version" "--Version"
	assert_failure
	assert_output --partial "Unknown option: --Version"
}

@test "argument validation: numeric edge cases" {
	# Test version number edge cases
	run_script "bump-version" "0.0.0"
	assert_success

	run_script "bump-version" "999.999.999"
	assert_success

	# Invalid version formats
	run_script "bump-version" "1.2"
	assert_failure
	assert_output --partial "Invalid version format"

	run_script "bump-version" "1.2.3.4"
	assert_failure
	assert_output --partial "Invalid version format"

	run_script "bump-version" "v1.2.3"
	assert_failure
	assert_output --partial "Invalid version format"
}

@test "argument validation: path injection attempts" {
	# Test attempts to use relative paths in project names
	run_script "generate-ai-workflow" "../malicious"
	assert_failure
	assert_output --partial "must contain only letters, numbers, hyphens, and underscores"

	run_script "generate-ai-workflow" "./current"
	assert_failure
	assert_output --partial "must contain only letters, numbers, hyphens, and underscores"

	run_script "generate-ai-workflow" "/absolute/path"
	assert_failure
	assert_output --partial "must contain only letters, numbers, hyphens, and underscores"
}
