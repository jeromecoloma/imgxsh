#!/usr/bin/env bats
#
# Tests for demo/show-banner script

# Load test helpers
load test_helper
load bats-support/load
load bats-assert/load

@test "demo/show-banner: default behavior shows all banner styles" {
	run_script "show-banner"
	assert_success
	assert_output --partial "Banner System Showcase"
	assert_output --partial "BLOCK STYLE:"
	assert_output --partial "ASCII STYLE:"
	assert_output --partial "MINIMAL STYLE:"
	assert_output --partial "Banner demonstration completed"
}

@test "demo/show-banner: shows terminal compatibility information by default" {
	run_script "show-banner"
	assert_success
	assert_output --partial "Terminal Compatibility Information:"
	assert_output --partial "TERM:"
	assert_output --partial "Detected capabilities:"
	assert_output --partial "Output is terminal:"
}

@test "demo/show-banner: shows banner features section" {
	run_script "show-banner"
	assert_success
	assert_output --partial "Banner Features:"
	assert_output --partial "Gradient color implementation with RGB support"
	assert_output --partial "Multiple styles: Block/Pixel, ASCII Art, and Minimalist"
	assert_output --partial "Terminal compatibility detection and fallback"
	assert_output --partial "NO_COLOR environment variable support"
}

@test "demo/show-banner: block style only" {
	run_script "show-banner" "block"
	assert_success
	assert_output --partial "Banner System Showcase"
	assert_output --partial "BLOCK STYLE:"
	assert_output --partial "Block/Pixel Style: Unicode block characters"
	refute_output --partial "ASCII STYLE:"
	refute_output --partial "MINIMAL STYLE:"
	assert_output --partial "Banner demonstration completed"
}

@test "demo/show-banner: pixel style (alias for block)" {
	run_script "show-banner" "pixel"
	assert_success
	assert_output --partial "Banner System Showcase"
	assert_output --partial "PIXEL STYLE:"
	assert_output --partial "Block/Pixel Style: Unicode block characters"
	refute_output --partial "ASCII STYLE:"
	refute_output --partial "MINIMAL STYLE:"
}

@test "demo/show-banner: ascii style only" {
	run_script "show-banner" "ascii"
	assert_success
	assert_output --partial "Banner System Showcase"
	assert_output --partial "ASCII STYLE:"
	assert_output --partial "ASCII Style: Traditional figlet-style text art"
	refute_output --partial "BLOCK STYLE:"
	refute_output --partial "MINIMAL STYLE:"
}

@test "demo/show-banner: minimal style only" {
	run_script "show-banner" "minimal"
	assert_success
	assert_output --partial "Banner System Showcase"
	assert_output --partial "MINIMAL STYLE:"
	assert_output --partial "Minimal Style: Clean bullet-point design"
	refute_output --partial "BLOCK STYLE:"
	refute_output --partial "ASCII STYLE:"
}

@test "demo/show-banner: all style (explicit)" {
	run_script "show-banner" "all"
	assert_success
	assert_output --partial "Banner System Showcase"
	assert_output --partial "BLOCK STYLE:"
	assert_output --partial "ASCII STYLE:"
	assert_output --partial "MINIMAL STYLE:"
}

@test "demo/show-banner: --no-info flag skips terminal information" {
	run_script "show-banner" --no-info
	assert_success
	assert_output --partial "Banner System Showcase"
	refute_output --partial "Terminal Compatibility Information:"
	refute_output --partial "TERM:"
	refute_output --partial "Detected capabilities:"
	assert_output --partial "BLOCK STYLE:"
}

@test "demo/show-banner: --debug flag shows debug information" {
	run_script "show-banner" --debug
	assert_success
	assert_output --partial "Banner System Showcase"
	# Should call colors::debug_terminal function
	assert_output --partial "BLOCK STYLE:"
	assert_output --partial "Banner demonstration completed"
}

@test "demo/show-banner: --plain flag forces plain text" {
	run_script "show-banner" --plain
	assert_success
	assert_output --partial "Banner System Showcase"
	assert_output --partial "Running in plain text mode (NO_COLOR=1)"
	assert_output --partial "BLOCK STYLE:"
}

@test "demo/show-banner: help flag shows usage" {
	run_script "show-banner" --help
	assert_success
	assert_output --partial "Usage:"
	assert_output --partial "show-banner"
	assert_output --partial "STYLE"
	assert_output --partial "STYLES:"
	assert_output --partial "block"
	assert_output --partial "ascii"
	assert_output --partial "minimal"
	assert_output --partial "EXAMPLES:"
}

@test "demo/show-banner: short help flag" {
	run_script "show-banner" -h
	assert_success
	assert_output --partial "Usage:"
	assert_output --partial "show-banner"
}

@test "demo/show-banner: version flag shows version" {
	expected_version=$(cat "${PROJECT_ROOT}/VERSION" | tr -d '\n')
	run_script "show-banner" --version
	assert_success
	assert_output --partial "show-banner"
	assert_output --partial "$expected_version"
}

@test "demo/show-banner: short version flag" {
	expected_version=$(cat "${PROJECT_ROOT}/VERSION" | tr -d '\n')
	run_script "show-banner" -v
	assert_success
	assert_output --partial "show-banner"
	assert_output --partial "$expected_version"
}

@test "demo/show-banner: unknown option error" {
	run_script "show-banner" --unknown
	assert_failure
	assert_output --partial "Unknown option: --unknown"
	assert_output --partial "Use --help for usage information."
}

@test "demo/show-banner: unknown short option error" {
	run_script "show-banner" -x
	assert_failure
	assert_output --partial "Unknown option: -x"
	assert_output --partial "Use --help for usage information."
}

@test "demo/show-banner: invalid style error" {
	run_script "show-banner" "invalid"
	assert_failure
	assert_output --partial "Invalid style: invalid"
	assert_output --partial "Valid styles: block, pixel, ascii, minimal, all"
	assert_output --partial "Use --help for usage information."
}

@test "demo/show-banner: combination of flags --no-info and block style" {
	run_script "show-banner" --no-info "block"
	assert_success
	assert_output --partial "Banner System Showcase"
	refute_output --partial "Terminal Compatibility Information:"
	assert_output --partial "BLOCK STYLE:"
	refute_output --partial "ASCII STYLE:"
	refute_output --partial "MINIMAL STYLE:"
}

@test "demo/show-banner: combination of flags --debug and ascii style" {
	run_script "show-banner" --debug "ascii"
	assert_success
	assert_output --partial "Banner System Showcase"
	assert_output --partial "ASCII STYLE:"
	refute_output --partial "BLOCK STYLE:"
	refute_output --partial "MINIMAL STYLE:"
}

@test "demo/show-banner: includes shell starter banner" {
	run_script "show-banner"
	assert_success
	assert_output --partial "Shell Starter"
}

@test "demo/show-banner: includes usage tips" {
	run_script "show-banner"
	assert_success
	assert_output --partial "Try different styles with:"
	assert_output --partial "Use --debug to see detailed terminal information"
}

@test "demo/show-banner: contains ANSI color codes in default mode" {
	run_script "show-banner"
	assert_success
	# Should contain ANSI escape sequences for colors
	assert_output --partial $'\e['
}

@test "demo/show-banner: style descriptions are shown with info" {
	run_script "show-banner" "block"
	assert_success
	assert_output --partial "Block/Pixel Style: Unicode block characters with gradient colors"
}

@test "demo/show-banner: style descriptions are hidden with --no-info" {
	run_script "show-banner" --no-info "block"
	assert_success
	refute_output --partial "Block/Pixel Style: Unicode block characters with gradient colors"
}
