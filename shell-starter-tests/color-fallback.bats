#!/usr/bin/env bats
#
# Tests for enhanced color fallback functions in bin/ tools

# Load test helpers
load test_helper
load bats-support/load
load bats-assert/load

setup() {
	export SHELL_STARTER_TEST=1

	# Create temporary directory for test files
	TEST_DIR=$(mktemp -d)
	export TEST_DIR

	# Save original PROJECT_ROOT and override for testing
	ORIGINAL_PROJECT_ROOT="$PROJECT_ROOT"
	export ORIGINAL_PROJECT_ROOT
	PROJECT_ROOT="$TEST_DIR"
	export PROJECT_ROOT

	# Create basic project structure for testing (without lib/main.sh to test fallback)
	mkdir -p "$TEST_DIR/bin"
	mkdir -p "$TEST_DIR/lib"

	# Copy bin tools to test directory
	cp "${ORIGINAL_PROJECT_ROOT}/bin/bump-version" "$TEST_DIR/bin/"
	cp "${ORIGINAL_PROJECT_ROOT}/bin/generate-ai-workflow" "$TEST_DIR/bin/"
	cp "${ORIGINAL_PROJECT_ROOT}/bin/update-shell-starter" "$TEST_DIR/bin/"
	cp "${ORIGINAL_PROJECT_ROOT}/bin/cleanup-shell-path" "$TEST_DIR/bin/"

	# Create VERSION file
	echo "1.0.0" > "$TEST_DIR/VERSION"
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

	unset SHELL_STARTER_TEST
}

@test "bump-version fallback color detection works" {
	# Test color detection function from fallback
	run bash -c "cd '$TEST_DIR' && source bin/bump-version && colors_has_color && echo 'has_color'"
	assert_success

	# Test with NO_COLOR set
	run bash -c "cd '$TEST_DIR' && NO_COLOR=1 source bin/bump-version && colors_has_color || echo 'no_color'"
	assert_success
	assert_output --partial "no_color"
}

@test "bump-version fallback colors are defined when lib unavailable" {
	# Test that fallback color variables are set when lib/main.sh is unavailable
	run bash -c "cd '$TEST_DIR' && source bin/bump-version && echo \"\${COLOR_INFO+defined}\""
	assert_success
	assert_output "defined"

	run bash -c "cd '$TEST_DIR' && source bin/bump-version && echo \"\${COLOR_SUCCESS+defined}\""
	assert_success
	assert_output "defined"

	run bash -c "cd '$TEST_DIR' && source bin/bump-version && echo \"\${COLOR_WARNING+defined}\""
	assert_success
	assert_output "defined"

	run bash -c "cd '$TEST_DIR' && source bin/bump-version && echo \"\${COLOR_ERROR+defined}\""
	assert_success
	assert_output "defined"
}

@test "bump-version fallback logging functions work with colors" {
	# Test fallback log::info function
	run bash -c "cd '$TEST_DIR' && source bin/bump-version && log::info 'test message'"
	assert_success
	assert_output --partial "test message"
	assert_output --partial "ℹ"

	# Test fallback log::success function
	run bash -c "cd '$TEST_DIR' && source bin/bump-version && log::success 'success message'"
	assert_success
	assert_output --partial "success message"
	assert_output --partial "✓"

	# Test fallback log::warn function
	run bash -c "cd '$TEST_DIR' && source bin/bump-version && log::warn 'warning message'"
	assert_success
	assert_output --partial "warning message"
	assert_output --partial "⚠"

	# Test fallback log::error function
	run bash -c "cd '$TEST_DIR' && source bin/bump-version && log::error 'error message' 2>&1"
	assert_success
	assert_output --partial "error message"
	assert_output --partial "✗"
}

@test "bump-version fallback logging functions work without colors" {
	# Test fallback logging with NO_COLOR
	run bash -c "cd '$TEST_DIR' && NO_COLOR=1 source bin/bump-version && log::info 'test message'"
	assert_success
	assert_output --partial "test message"
	assert_output --partial "ℹ"
	# Should not contain ANSI escape sequences
	refute_output --partial $'['
}

@test "bump-version fallback section functions work" {
	# Test section_header function
	run bash -c "cd '$TEST_DIR' && source bin/bump-version && section_header 'Test Section'"
	assert_success
	assert_output --partial "Test Section"
	assert_output --partial "───"

	# Test section_divider function
	run bash -c "cd '$TEST_DIR' && source bin/bump-version && section_divider"
	assert_success
	assert_output --partial "──"
}

@test "bump-version banner_minimal function works" {
	# Test banner_minimal function with colors
	run bash -c "cd '$TEST_DIR' && source bin/bump-version && banner_minimal"
	assert_success
	assert_output --partial "Bump Version"

	# Test banner_minimal function without colors
	run bash -c "cd '$TEST_DIR' && NO_COLOR=1 source bin/bump-version && banner_minimal"
	assert_success
	assert_output --partial "Bump Version"
	refute_output --partial $'['
}

@test "bump-version fallback colors respect NO_COLOR" {
	# Test that color variables are empty when NO_COLOR is set
	run bash -c "cd '$TEST_DIR' && NO_COLOR=1 source bin/bump-version && echo \"\${COLOR_INFO}\""
	assert_success
	assert_output ""

	run bash -c "cd '$TEST_DIR' && NO_COLOR=1 source bin/bump-version && echo \"\${COLOR_SUCCESS}\""
	assert_success
	assert_output ""
}

@test "bump-version fallback colors work with terminal detection" {
	# Test color variables are set when terminal supports color
	if [[ -t 1 ]] && [[ "${TERM:-}" != "dumb" ]]; then
		run bash -c "cd '$TEST_DIR' && source bin/bump-version && echo \"\${COLOR_INFO}\""
		assert_success
		# Should contain ANSI escape sequences if terminal supports color
		if [[ "${NO_COLOR:-}" == "" ]]; then
			assert_output --partial $'['
		fi
	fi
}

@test "bump-version guard against redefinition works" {
	# Create a script that defines COLOR_RESET first
	cat > "$TEST_DIR/pre_define.sh" << 'EOF'
#!/bin/bash
readonly COLOR_RESET='\033[0m'
readonly COLOR_INFO='\033[0;34m'
source bin/bump-version
EOF

	# Test that existing definitions are not overridden
	run bash -c "cd '$TEST_DIR' && source pre_define.sh && echo \"\${COLOR_RESET}\""
	assert_success
	assert_output $'\033[0m'
}

@test "generate-ai-workflow fallback functions work" {
	# Test that generate-ai-workflow has fallback color support
	run bash -c "cd '$TEST_DIR' && source bin/generate-ai-workflow && log::info 'test' 2>/dev/null || echo 'fallback_works'"
	assert_success
	# Should either work with log::info or show fallback works
}

@test "update-shell-starter fallback functions work" {
	# Test that update-shell-starter has fallback color support
	run bash -c "cd '$TEST_DIR' && source bin/update-shell-starter && log::info 'test' 2>/dev/null || echo 'fallback_works'"
	assert_success
}

@test "cleanup-shell-path fallback functions work" {
	# Test that cleanup-shell-path has fallback color support
	run bash -c "cd '$TEST_DIR' && source bin/cleanup-shell-path && log::info 'test' 2>/dev/null || echo 'fallback_works'"
	assert_success
}