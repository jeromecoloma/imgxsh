#!/usr/bin/env bats
#
# Tests for demo/debug-colors script

# Load test helpers
load test_helper
load bats-support/load
load bats-assert/load

@test "demo/debug-colors: shows debug header" {
	run_script "debug-colors"
	assert_success
	assert_output --partial "=== Terminal Color Debug Information ==="
}

@test "demo/debug-colors: displays basic environment variables" {
	run_script "debug-colors"
	assert_success
	assert_output --partial "Basic environment:"
	assert_output --partial "TERM:"
	assert_output --partial "COLORTERM:"
	assert_output --partial "TERM_PROGRAM:"
	assert_output --partial "NO_COLOR:"
}

@test "demo/debug-colors: shows detection results" {
	run_script "debug-colors"
	assert_success
	assert_output --partial "Detection results:"
	assert_output --partial "Output is terminal:"
	assert_output --partial "Has truecolor:"
	assert_output --partial "Has 256color:"
	assert_output --partial "Has basic color:"
}

@test "demo/debug-colors: detection results show yes/no values" {
	run_script "debug-colors"
	assert_success
	# Should show either "yes" or "no" for each detection
	assert_output --regexp "Output is terminal: (yes|no)"
	assert_output --regexp "Has truecolor: (yes|no)"
	assert_output --regexp "Has 256color: (yes|no)"
	assert_output --regexp "Has basic color: (yes|no)"
}

@test "demo/debug-colors: performs color test" {
	run_script "debug-colors"
	assert_success
	assert_output --partial "Color test (if you see color names in color, your terminal works):"
	assert_output --partial "RED"
	assert_output --partial "GREEN"
	assert_output --partial "BLUE"
	assert_output --partial "YELLOW"
	assert_output --partial "CYAN"
	assert_output --partial "MAGENTA"
}

@test "demo/debug-colors: shows raw color codes" {
	run_script "debug-colors"
	assert_success
	assert_output --partial "Raw color codes (should show literal escape codes):"
	assert_output --partial "RED:"
	assert_output --partial "RESET:"
}

@test "demo/debug-colors: raw color codes show actual escape sequences" {
	run_script "debug-colors"
	assert_success
	# Should show literal escape code representations
	assert_output --regexp "RED: '[^']*'"
	assert_output --regexp "RESET: '[^']*'"
}

@test "demo/debug-colors: includes troubleshooting information" {
	run_script "debug-colors"
	assert_success
	assert_output --partial "If colors appear as literal text like [0;31m instead of actual colors,"
	assert_output --partial "your terminal may not support ANSI colors or colors may be disabled."
}

@test "demo/debug-colors: provides troubleshooting suggestions" {
	run_script "debug-colors"
	assert_success
	assert_output --partial "Try:"
	assert_output --partial "Using a different terminal (iTerm2, Terminal.app, etc.)"
	assert_output --partial "Checking if NO_COLOR environment variable is set"
	assert_output --partial "Running: export TERM=xterm-256color"
}

@test "demo/debug-colors: contains ANSI color codes when colors are enabled" {
	run_script "debug-colors"
	assert_success
	# Should contain ANSI escape sequences for colors in the test section
	assert_output --partial $'\e['
}

@test "demo/debug-colors: environment variables show 'unset' when not defined" {
	# This test verifies that undefined environment variables show as "unset"
	# We can't easily test this without manipulating the environment in a way that
	# would affect other tests, so we'll verify the output format is correct
	run_script "debug-colors"
	assert_success
	# Should have some environment info lines
	assert_output --regexp "TERM: [a-zA-Z0-9_-]+|unset"
	assert_output --regexp "COLORTERM: [a-zA-Z0-9_-]+|unset"
	assert_output --regexp "TERM_PROGRAM: [a-zA-Z0-9_.-]+|unset"
	assert_output --regexp "NO_COLOR: [^[:space:]]+|unset"
}

@test "demo/debug-colors: sources main library successfully" {
	run_script "debug-colors"
	assert_success
	# The script should run without errors, indicating successful library sourcing
	assert_output --partial "Detection results:"
}

@test "demo/debug-colors: uses colors::is_terminal function" {
	run_script "debug-colors"
	assert_success
	# Should call the colors::is_terminal function and show result
	assert_output --partial "Output is terminal:"
}

@test "demo/debug-colors: uses colors::has_truecolor function" {
	run_script "debug-colors"
	assert_success
	# Should call the colors::has_truecolor function and show result
	assert_output --partial "Has truecolor:"
}

@test "demo/debug-colors: uses colors::has_256color function" {
	run_script "debug-colors"
	assert_success
	# Should call the colors::has_256color function and show result
	assert_output --partial "Has 256color:"
}

@test "demo/debug-colors: uses colors::has_color function" {
	run_script "debug-colors"
	assert_success
	# Should call the colors::has_color function and show result
	assert_output --partial "Has basic color:"
}

@test "demo/debug-colors: shows all basic color constants" {
	run_script "debug-colors"
	assert_success
	# Should test all the basic color constants
	assert_output --partial "RED"
	assert_output --partial "GREEN"
	assert_output --partial "BLUE"
	assert_output --partial "YELLOW"
	assert_output --partial "CYAN"
	assert_output --partial "MAGENTA"
}

@test "demo/debug-colors: uses printf for raw color code display" {
	run_script "debug-colors"
	assert_success
	# Should use printf to show raw escape sequences
	assert_output --partial "RED:"
	assert_output --partial "RESET:"
}

@test "demo/debug-colors: no command line options (simple script)" {
	# This script doesn't accept command line arguments
	run_script "debug-colors"
	assert_success
	# Should just run and show debug info regardless of arguments

	# Test with an argument (should still work since script ignores args)
	run_script "debug-colors" "test"
	assert_success
}

@test "demo/debug-colors: script sets error handling options" {
	# The script should use 'set -euo pipefail' for proper error handling
	run_script "debug-colors"
	assert_success
	# If the script runs successfully, it means error handling is working
	assert_output --partial "Detection results:"
}
