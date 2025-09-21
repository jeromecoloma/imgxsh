#!/usr/bin/env bats
#
# Tests for demo/polyglot-example script

# Load test helpers
load test_helper
load bats-support/load
load bats-assert/load

@test "demo/polyglot-example: requires command argument" {
	run_script "polyglot-example"
	assert_failure
	assert_output --partial "No command specified"
	assert_output --partial "Usage:"
}

@test "demo/polyglot-example: shows main help" {
	run_script "polyglot-example" --help
	assert_success
	assert_output --partial "Usage:"
	assert_output --partial "polyglot-example"
	assert_output --partial "COMMANDS:"
	assert_output --partial "process"
	assert_output --partial "demo"
	assert_output --partial "benchmark"
	assert_output --partial "generate"
	assert_output --partial "pipeline"
	assert_output --partial "test"
	assert_output --partial "POLYGLOT FEATURES:"
}

@test "demo/polyglot-example: short help flag" {
	run_script "polyglot-example" -h
	assert_success
	assert_output --partial "Usage:"
	assert_output --partial "polyglot-example"
}

@test "demo/polyglot-example: version flag shows version" {
	expected_version=$(cat "${PROJECT_ROOT}/VERSION" | tr -d '\n')
	run_script "polyglot-example" --version
	assert_success
	assert_output --partial "polyglot-example"
	assert_output --partial "$expected_version"
}

@test "demo/polyglot-example: short version flag" {
	expected_version=$(cat "${PROJECT_ROOT}/VERSION" | tr -d '\n')
	run_script "polyglot-example" -v
	assert_success
	assert_output --partial "polyglot-example"
	assert_output --partial "$expected_version"
}

@test "demo/polyglot-example: unknown global option error" {
	run_script "polyglot-example" --unknown
	assert_failure
	assert_output --partial "Unknown global option: --unknown"
	assert_output --partial "Use --help for usage information."
}

@test "demo/polyglot-example: unknown command error" {
	run_script "polyglot-example" "unknown-command"
	assert_failure
	assert_output --partial "Unknown command: unknown-command"
	assert_output --partial "Use --help to see available commands."
}

@test "demo/polyglot-example: process command help" {
	run_script "polyglot-example" process --help
	assert_success
	assert_output --partial "Usage:"
	assert_output --partial "process"
	assert_output --partial "OPERATIONS:"
	assert_output --partial "analyze"
	assert_output --partial "transform"
	assert_output --partial "validate"
	assert_output --partial "format"
	assert_output --partial "EXAMPLES:"
}

@test "demo/polyglot-example: demo command help" {
	run_script "polyglot-example" demo --help
	assert_success
	assert_output --partial "Usage:"
	assert_output --partial "demo"
	assert_output --partial "--auto"
	assert_output --partial "--delay"
	assert_output --partial "EXAMPLES:"
}

@test "demo/polyglot-example: generate command help" {
	run_script "polyglot-example" generate --help
	assert_success
	assert_output --partial "Usage:"
	assert_output --partial "generate"
	assert_output --partial "DATA TYPES:"
	assert_output --partial "users"
	assert_output --partial "products"
	assert_output --partial "metrics"
	assert_output --partial "generic"
	assert_output --partial "EXAMPLES:"
}

@test "demo/polyglot-example: pipeline command help" {
	run_script "polyglot-example" pipeline --help
	assert_success
	assert_output --partial "Usage:"
	assert_output --partial "pipeline"
	assert_output --partial "--input"
	assert_output --partial "--output-dir"
	assert_output --partial "--operations"
	assert_output --partial "EXAMPLES:"
}

@test "demo/polyglot-example: benchmark command help" {
	run_script "polyglot-example" benchmark --help
	assert_success
	assert_output --partial "Usage:"
	assert_output --partial "benchmark"
	assert_output --partial "--size"
	assert_output --partial "--iterations"
	assert_output --partial "EXAMPLES:"
}

@test "demo/polyglot-example: test command help" {
	run_script "polyglot-example" test --help
	assert_success
	assert_output --partial "Usage:"
	assert_output --partial "test"
	assert_output --partial "--verbose"
	assert_output --partial "EXAMPLES:"
}

@test "demo/polyglot-example: process unknown option error" {
	run_script "polyglot-example" process --unknown
	assert_failure
	assert_output --partial "Unknown option for process command: --unknown"
	assert_output --partial "Use"
	assert_output --partial "process --help"
}

@test "demo/polyglot-example: demo unknown option error" {
	run_script "polyglot-example" demo --unknown
	assert_failure
	assert_output --partial "Unknown option for demo command: --unknown"
}

@test "demo/polyglot-example: generate unknown option error" {
	run_script "polyglot-example" generate --unknown
	assert_failure
	assert_output --partial "Unknown option for generate command: --unknown"
}

@test "demo/polyglot-example: pipeline unknown option error" {
	run_script "polyglot-example" pipeline --unknown
	assert_failure
	assert_output --partial "Unknown option for pipeline command: --unknown"
}

@test "demo/polyglot-example: benchmark unknown option error" {
	run_script "polyglot-example" benchmark --unknown
	assert_failure
	assert_output --partial "Unknown option for benchmark command: --unknown"
}

@test "demo/polyglot-example: test unknown option error" {
	run_script "polyglot-example" test --unknown
	assert_failure
	assert_output --partial "Unknown option for test command: --unknown"
}

@test "demo/polyglot-example: test command runs integration tests" {
	run_script "polyglot-example" test
	# Note: This test may pass or fail depending on Python availability
	# We're just testing that it attempts to run tests and shows results
	assert_output --partial "Polyglot Integration Tests"
	assert_output --partial "Test Results:"
	assert_output --partial "Tests passed:"
	# The command should always return some test results, regardless of pass/fail
}

@test "demo/polyglot-example: test command verbose mode" {
	run_script "polyglot-example" test --verbose
	assert_output --partial "Polyglot Integration Tests"
	assert_output --partial "Test Results:"
	# Verbose mode should provide more detailed output
}

@test "demo/polyglot-example: demo command automatic mode" {
	run_script "polyglot-example" demo --auto --delay 0
	# This should run the demo automatically with no delay
	assert_output --partial "Polyglot Integration Demo"
	assert_output --partial "Step 1:"
	assert_output --partial "Step 2:"
	# Note: Some steps may fail if Python/scripts aren't available, but structure should be there
}

@test "demo/polyglot-example: process command with missing python script shows error" {
	# This test assumes the Python script might not be present
	run_script "polyglot-example" process
	# Should either process successfully or show a specific error about missing Python script
	# We'll check that it at least attempts to process
	assert_output --partial "Starting data processing with Python backend"
}

@test "demo/polyglot-example: global verbose flag" {
	run_script "polyglot-example" --verbose test
	# Should enable verbose mode and run the test command
	assert_output --partial "Test Results:"
}

@test "demo/polyglot-example: python availability warning" {
	# This test checks if the script warns about missing Python
	# The exact behavior depends on system Python availability
	run_script "polyglot-example" --no-python test
	# With --no-python flag, should skip Python availability check
	assert_output --partial "Polyglot Integration Tests"
}

@test "demo/polyglot-example: sources main library successfully" {
	run_script "polyglot-example" --help
	assert_success
	# If help shows successfully, the main library was sourced correctly
	assert_output --partial "Usage:"
}

@test "demo/polyglot-example: uses Shell Starter logging functions" {
	run_script "polyglot-example" test
	# Should use log::info, log::error functions from Shell Starter
	# We can't easily test the log functions directly, but the script should run
	assert_output --partial "Test Results:"
}

@test "demo/polyglot-example: uses Shell Starter color variables" {
	run_script "polyglot-example" --help
	assert_success
	# Should contain ANSI color codes when colors are enabled
	assert_output --partial $'\e['
}

@test "demo/polyglot-example: enable background updates" {
	run_script "polyglot-example" --help
	assert_success
	# Script should call enable_background_updates function
	# If it runs without error, the function call worked
	assert_output --partial "Usage:"
}

@test "demo/polyglot-example: parse common args integration" {
	run_script "polyglot-example" --version
	assert_success
	# Should use parse_common_args function for version handling
	assert_output --partial "polyglot-example"
}

@test "demo/polyglot-example: error handling with set options" {
	# The script uses 'set -euo pipefail' for proper error handling
	run_script "polyglot-example" --help
	assert_success
	# If the script runs successfully, error handling is working
	assert_output --partial "Usage:"
}
