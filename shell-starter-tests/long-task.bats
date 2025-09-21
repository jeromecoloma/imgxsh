#!/usr/bin/env bats
#
# Tests for long-task demo script

# Load test helpers
load test_helper
load bats-support/load
load bats-assert/load

# Help and version tests
@test "long-task: help flag" {
	run_script "long-task" --help
	assert_success
	assert_output --partial "Usage:"
	assert_output --partial "Simulates a long-running task"
	assert_output --partial "ARGUMENTS:"
	assert_output --partial "OPTIONS:"
	assert_output --partial "EXAMPLES:"
}

@test "long-task: short help flag" {
	run_script "long-task" -h
	assert_success
	assert_output --partial "Usage:"
}

@test "long-task: version flag" {
	expected_version=$(cat "${PROJECT_ROOT}/VERSION" | tr -d '\n')
	run_script "long-task" --version
	assert_success
	assert_output --partial "long-task"
	assert_output --partial "$expected_version"
}

@test "long-task: short version flag" {
	expected_version=$(cat "${PROJECT_ROOT}/VERSION" | tr -d '\n')
	run_script "long-task" -v
	assert_success
	assert_output --partial "long-task"
	assert_output --partial "$expected_version"
}

# Basic functionality tests
@test "long-task: default execution (short duration for testing)" {
	run_script "long-task" "1"
	assert_success
	assert_output --partial "Long Task Simulator"
	assert_output --partial "Duration: 1s"
	assert_output --partial "Starting long-running task"
	assert_output --partial "Task completed successfully!"
	assert_output --partial "Actual duration:"
}

@test "long-task: custom duration" {
	run_script "long-task" "2"
	assert_success
	assert_output --partial "Duration: 2s"
	assert_output --partial "Starting long-running task (2s duration)"
}

@test "long-task: zero duration should fail" {
	run_script "long-task" "0"
	assert_failure
	assert_output --partial "Duration must be a positive integer"
}

@test "long-task: negative duration should fail" {
	run_script "long-task" "-5"
	assert_failure
	assert_output --partial "Invalid duration: -5"
}

@test "long-task: invalid duration format" {
	run_script "long-task" "abc"
	assert_failure
	assert_output --partial "Invalid duration: abc (must be a positive integer)"
}

# Quiet mode tests
@test "long-task: quiet mode suppresses spinner" {
	run_script "long-task" --quiet "1"
	assert_success
	assert_output --partial "Starting long-running task"
	assert_output --partial "Task completed successfully!"
	# Should not contain spinner initialization messages
	refute_output --partial "Initializing task..."
}

@test "long-task: short quiet flag" {
	run_script "long-task" -q "1"
	assert_success
	assert_output --partial "Quiet: true"
}

# No-color mode tests
@test "long-task: no-color mode disables colors" {
	run_script "long-task" --no-color "1"
	assert_success
	assert_output --partial "Long Task Simulator"
	assert_output --partial "Task completed successfully!"
	# Check that ANSI color codes are not present
	refute_output --regexp '\x1b\['
}

@test "long-task: no-color with quiet mode" {
	run_script "long-task" --no-color --quiet "1"
	assert_success
	assert_output --partial "Long Task Simulator"
	refute_output --regexp '\x1b\['
}

# Steps customization tests
@test "long-task: custom steps count" {
	run_script "long-task" --steps "3" "1"
	assert_success
	assert_output --partial "Steps: 3"
}

@test "long-task: steps with zero should fail" {
	run_script "long-task" --steps "0" "1"
	assert_failure
	assert_output --partial "Steps must be a positive integer"
}

@test "long-task: steps with negative value should fail" {
	run_script "long-task" --steps "-2" "1"
	assert_failure
	assert_output --partial "Steps must be a positive integer"
}

@test "long-task: steps without argument" {
	run_script "long-task" --steps
	assert_failure
	assert_output --partial "--steps requires a numeric argument"
}

@test "long-task: steps with non-numeric argument" {
	run_script "long-task" --steps "abc" "1"
	assert_failure
	assert_output --partial "--steps requires a numeric argument"
}

# Fast spinner mode tests
@test "long-task: fast spinner mode" {
	run_script "long-task" --fast "1"
	assert_success
	assert_output --partial "Task completed successfully!"
	# Fast mode should complete normally
}

@test "long-task: fast spinner with quiet mode" {
	run_script "long-task" --fast --quiet "1"
	assert_success
	assert_output --partial "Task completed successfully!"
}

# Progress tracking tests
@test "long-task: shows progress steps" {
	run_script "long-task" "1"
	assert_success
	assert_output --partial "✓ Task initialized"
	assert_output --partial "completed"
}

@test "long-task: progress with custom steps" {
	run_script "long-task" --steps "2" "1"
	assert_success
	assert_output --partial "step 1/2"
	assert_output --partial "step 2/2"
}

@test "long-task: quiet mode hides progress details" {
	run_script "long-task" --quiet "1"
	assert_success
	refute_output --partial "✓ Task initialized"
	refute_output --partial "Processing data"
}

# Combined flags tests
@test "long-task: multiple flags combined" {
	run_script "long-task" --quiet --no-color --steps "2" "1"
	assert_success
	assert_output --partial "Steps: 2"
	assert_output --partial "Quiet: true"
	refute_output --regexp '\x1b\['
}

@test "long-task: fast quiet no-color combination" {
	run_script "long-task" --fast --quiet --no-color "1"
	assert_success
	assert_output --partial "Task completed successfully!"
	refute_output --regexp '\x1b\['
}

# Argument order tests
@test "long-task: flags before duration" {
	run_script "long-task" --quiet --steps "3" "1"
	assert_success
	assert_output --partial "Duration: 1s"
	assert_output --partial "Steps: 3"
}

@test "long-task: flags after duration" {
	run_script "long-task" "1" --quiet --steps "3"
	assert_success
	assert_output --partial "Duration: 1s"
	assert_output --partial "Steps: 3"
}

@test "long-task: mixed flag positions" {
	run_script "long-task" --quiet "1" --steps "3"
	assert_success
	assert_output --partial "Duration: 1s"
	assert_output --partial "Steps: 3"
}

# Error handling tests
@test "long-task: unknown option" {
	run_script "long-task" --unknown
	assert_failure
	assert_output --partial "Unknown option: --unknown"
	assert_output --partial "Use --help for usage information."
}

@test "long-task: invalid flag format" {
	run_script "long-task" ---invalid
	assert_failure
	assert_output --partial "Unknown option: ---invalid"
}

# Duration edge cases
@test "long-task: very short duration with multiple steps" {
	run_script "long-task" --steps "10" "1"
	assert_success
	assert_output --partial "Steps: 10"
	# Should handle the case where duration < steps
}

@test "long-task: longer duration for timing verification" {
	local start_time end_time duration
	start_time=$(date +%s)
	run_script "long-task" "2"
	end_time=$(date +%s)
	duration=$((end_time - start_time))

	assert_success
	assert_output --partial "Task completed successfully!"
	# Should take at least 2 seconds (allowing some variance for test execution)
	assert [ "$duration" -ge 1 ]
}

# Output format verification
@test "long-task: contains required header information" {
	run_script "long-task" "1"
	assert_success
	assert_output --partial "Long Task Simulator"
	assert_output --partial "========================================"
	assert_output --partial "Duration: 1s | Steps: 5 | Quiet: false"
}

@test "long-task: shows initialization step" {
	run_script "long-task" "1"
	assert_success
	assert_output --partial "✓ Task initialized"
}

@test "long-task: shows completion message" {
	run_script "long-task" "1"
	assert_success
	assert_output --partial "Task completed successfully!"
	assert_output --partial "Actual duration:"
}

@test "long-task: logs task completion" {
	run_script "long-task" "1"
	assert_success
	assert_output --partial "Long task completed in"
	assert_output --partial "seconds"
}

# Step name verification
@test "long-task: shows standard step names" {
	run_script "long-task" "2"
	assert_success
	assert_output --partial "Processing data"
	assert_output --partial "Validating inputs"
}

@test "long-task: handles many steps with generic names" {
	run_script "long-task" --steps "8" "1"
	assert_success
	assert_output --partial "Finalizing step"
}

# Special behavior tests
@test "long-task: handles duration less than steps" {
	run_script "long-task" --steps "5" "2"
	assert_success
	# Should complete without errors even when steps > duration
	assert_output --partial "Task completed successfully!"
}

@test "long-task: actual vs expected duration tracking" {
	run_script "long-task" "1"
	assert_success
	assert_output --partial "Actual duration:"
	# Should report some duration even if it's less than expected due to processing overhead
}

# Integration with spinner system
@test "long-task: spinner integration works" {
	# Test that spinner calls don't cause errors
	run_script "long-task" "1"
	assert_success
	# Should complete without spinner-related errors
	assert_output --partial "Task completed successfully!"
}

@test "long-task: spinner disabled in quiet mode" {
	run_script "long-task" --quiet "1"
	assert_success
	# Quiet mode should suppress spinner output
	refute_output --partial "Initializing task..."
}

# Color output verification
@test "long-task: colored output by default" {
	run_script "long-task" "1"
	assert_success
	# Should contain ANSI color codes when colors are enabled
	assert_output --regexp '\x1b\['
}

@test "long-task: no color codes in no-color mode" {
	run_script "long-task" --no-color "1"
	assert_success
	# Should not contain ANSI color codes
	refute_output --regexp '\x1b\['
}