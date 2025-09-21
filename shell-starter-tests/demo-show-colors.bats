#!/usr/bin/env bats
#
# Tests for demo/show-colors script

# Load test helpers
load test_helper
load bats-support/load
load bats-assert/load

@test "demo/show-colors: default behavior shows all color sections" {
	run_script "show-colors"
	assert_success
	assert_output --partial "Color Library Showcase"
	assert_output --partial "Basic Colors:"
	assert_output --partial "Bright Colors:"
	assert_output --partial "Text Formatting:"
	assert_output --partial "Semantic Colors:"
	assert_output --partial "Color Demonstration Examples:"
	assert_output --partial "Color showcase completed"
}

@test "demo/show-colors: contains basic color variables" {
	run_script "show-colors"
	assert_success
	assert_output --partial "COLOR_BLACK"
	assert_output --partial "COLOR_RED"
	assert_output --partial "COLOR_GREEN"
	assert_output --partial "COLOR_YELLOW"
	assert_output --partial "COLOR_BLUE"
	assert_output --partial "COLOR_MAGENTA"
	assert_output --partial "COLOR_CYAN"
	assert_output --partial "COLOR_WHITE"
}

@test "demo/show-colors: contains bright color variables" {
	run_script "show-colors"
	assert_success
	assert_output --partial "COLOR_BRIGHT_BLACK"
	assert_output --partial "COLOR_BRIGHT_RED"
	assert_output --partial "COLOR_BRIGHT_GREEN"
	assert_output --partial "COLOR_BRIGHT_YELLOW"
	assert_output --partial "COLOR_BRIGHT_BLUE"
	assert_output --partial "COLOR_BRIGHT_MAGENTA"
	assert_output --partial "COLOR_BRIGHT_CYAN"
	assert_output --partial "COLOR_BRIGHT_WHITE"
}

@test "demo/show-colors: contains text formatting variables" {
	run_script "show-colors"
	assert_success
	assert_output --partial "COLOR_BOLD"
	assert_output --partial "COLOR_DIM"
	assert_output --partial "COLOR_UNDERLINE"
	assert_output --partial "COLOR_BLINK"
	assert_output --partial "COLOR_REVERSE"
}

@test "demo/show-colors: contains semantic color variables" {
	run_script "show-colors"
	assert_success
	assert_output --partial "COLOR_INFO"
	assert_output --partial "COLOR_SUCCESS"
	assert_output --partial "COLOR_WARNING"
	assert_output --partial "COLOR_ERROR"
	assert_output --partial "COLOR_DEBUG"
}

@test "demo/show-colors: contains demonstration examples" {
	run_script "show-colors"
	assert_success
	assert_output --partial "✓ Success:"
	assert_output --partial "⚠ Warning:"
	assert_output --partial "✗ Error:"
	assert_output --partial "ℹ Info:"
	assert_output --partial "🐛 Debug:"
	assert_output --partial "Bold Red"
	assert_output --partial "Underlined Blue"
}

@test "demo/show-colors: --no-demo flag skips demonstration examples" {
	run_script "show-colors" --no-demo
	assert_success
	assert_output --partial "Color Library Showcase"
	assert_output --partial "Basic Colors:"
	assert_output --partial "Bright Colors:"
	assert_output --partial "Text Formatting:"
	assert_output --partial "Semantic Colors:"
	refute_output --partial "Color Demonstration Examples:"
	refute_output --partial "✓ Success:"
	assert_output --partial "Color showcase completed"
}

@test "demo/show-colors: --plain flag shows escape codes" {
	run_script "show-colors" --plain
	assert_success
	assert_output --partial "Color Library Showcase"
	assert_output --partial "\\033[0;30m"
	assert_output --partial "\\033[0;31m"
	assert_output --partial "\\033[0;32m"
	assert_output --partial "\\033[1;30m"
	assert_output --partial "\\033[1m"
	assert_output --partial "\\033[0m"
	refute_output --partial "Color Demonstration Examples:"
}

@test "demo/show-colors: plain mode skips demo section" {
	run_script "show-colors" --plain
	assert_success
	refute_output --partial "Color Demonstration Examples:"
	refute_output --partial "✓ Success:"
	refute_output --partial "Combination Examples:"
}

@test "demo/show-colors: help flag shows usage" {
	run_script "show-colors" --help
	assert_success
	assert_output --partial "Usage:"
	assert_output --partial "show-colors"
	assert_output --partial "OPTIONS:"
	assert_output --partial "--no-demo"
	assert_output --partial "--plain"
	assert_output --partial "EXAMPLES:"
}

@test "demo/show-colors: short help flag" {
	run_script "show-colors" -h
	assert_success
	assert_output --partial "Usage:"
	assert_output --partial "show-colors"
}

@test "demo/show-colors: version flag shows version" {
	expected_version=$(cat "${PROJECT_ROOT}/VERSION" | tr -d '\n')
	run_script "show-colors" --version
	assert_success
	assert_output --partial "show-colors"
	assert_output --partial "$expected_version"
}

@test "demo/show-colors: short version flag" {
	expected_version=$(cat "${PROJECT_ROOT}/VERSION" | tr -d '\n')
	run_script "show-colors" -v
	assert_success
	assert_output --partial "show-colors"
	assert_output --partial "$expected_version"
}

@test "demo/show-colors: unknown option error" {
	run_script "show-colors" --unknown
	assert_failure
	assert_output --partial "Unknown option: --unknown"
	assert_output --partial "Use --help for usage information."
}

@test "demo/show-colors: unknown short option error" {
	run_script "show-colors" -x
	assert_failure
	assert_output --partial "Unknown option: -x"
	assert_output --partial "Use --help for usage information."
}

@test "demo/show-colors: unexpected argument error" {
	run_script "show-colors" "unexpected"
	assert_failure
	assert_output --partial "Unexpected argument: unexpected"
	assert_output --partial "Use --help for usage information."
}

@test "demo/show-colors: contains ANSI color codes in default mode" {
	run_script "show-colors"
	assert_success
	# Should contain ANSI escape sequences for colors
	assert_output --partial $'\e['
}

@test "demo/show-colors: shows shell starter banner" {
	run_script "show-colors"
	assert_success
	assert_output --partial "Shell Starter"
}

@test "demo/show-colors: combination flags --no-demo --plain" {
	run_script "show-colors" --no-demo --plain
	assert_success
	assert_output --partial "Color Library Showcase"
	assert_output --partial "\\033[0;30m"
	refute_output --partial "Color Demonstration Examples:"
}

@test "demo/show-colors: includes final usage message" {
	run_script "show-colors"
	assert_success
	assert_output --partial "Use these color variables in your Shell Starter scripts!"
}
