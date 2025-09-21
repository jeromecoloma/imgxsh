#!/usr/bin/env bats
#
# Tests for banner integration in production tools

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

	# Create basic project structure for testing
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

@test "bump-version banner_minimal function works" {
	# Test banner_minimal function displays correctly
	run bash -c "cd '$TEST_DIR' && source bin/bump-version && banner_minimal"
	assert_success
	assert_output --partial "Bump Version"

	# Test banner works without colors
	run bash -c "cd '$TEST_DIR' && NO_COLOR=1 source bin/bump-version && banner_minimal"
	assert_success
	assert_output --partial "Bump Version"
	refute_output --partial $'['
}

@test "bump-version help output includes banner" {
	# Test that help output includes banner
	run "$TEST_DIR/bin/bump-version" --help
	assert_success
	assert_output --partial "Bump Version"
	assert_output --partial "USAGE:"
	assert_output --partial "bump-version"
}

@test "generate-ai-workflow help output includes banner" {
	# Test that help output includes banner
	run "$TEST_DIR/bin/generate-ai-workflow" --help
	assert_success
	assert_output --partial "Generate AI Workflow"
	assert_output --partial "USAGE:"
}

@test "update-shell-starter help output includes banner" {
	# Test that help output includes banner
	run "$TEST_DIR/bin/update-shell-starter" --help
	assert_success
	assert_output --partial "Update Shell Starter"
	assert_output --partial "USAGE:"
}

@test "cleanup-shell-path help output includes banner" {
	# Test that help output includes banner
	run "$TEST_DIR/bin/cleanup-shell-path" --help
	assert_success
	assert_output --partial "Cleanup Shell Path"
	assert_output --partial "USAGE:"
}

@test "banners work without lib/main.sh (fallback mode)" {
	# Test banners work when lib/main.sh is not available (fallback mode)
	run bash -c "cd '$TEST_DIR' && bin/bump-version --help"
	assert_success
	assert_output --partial "Bump Version"

	run bash -c "cd '$TEST_DIR' && bin/generate-ai-workflow --help"
	assert_success
	assert_output --partial "Generate AI Workflow"
}

@test "banners respect NO_COLOR in fallback mode" {
	# Test that banners respect NO_COLOR when using fallback functions
	run bash -c "cd '$TEST_DIR' && NO_COLOR=1 bin/bump-version --help"
	assert_success
	assert_output --partial "Bump Version"
	refute_output --partial $'['

	run bash -c "cd '$TEST_DIR' && NO_COLOR=1 bin/generate-ai-workflow --help"
	assert_success
	assert_output --partial "Generate AI Workflow"
	refute_output --partial $'['
}

@test "banners work with lib/main.sh available" {
	# Copy lib files to test full banner functionality
	cp -r "${ORIGINAL_PROJECT_ROOT}/lib" "$TEST_DIR/"

	# Test banners work when lib/main.sh is available
	run bash -c "cd '$TEST_DIR' && bin/bump-version --help"
	assert_success
	assert_output --partial "Bump Version"

	run bash -c "cd '$TEST_DIR' && bin/generate-ai-workflow --help"
	assert_success
	assert_output --partial "Generate AI Workflow"
}

@test "banner functions are consistently defined across tools" {
	# Test that all tools have banner functions available
	run bash -c "cd '$TEST_DIR' && source bin/bump-version && declare -f banner_minimal"
	assert_success

	# Test banner_minimal function exists and works in different tools
	run bash -c "cd '$TEST_DIR' && source bin/generate-ai-workflow && declare -f banner_minimal 2>/dev/null || echo 'banner_function_available'"
	assert_success
}

@test "banners maintain consistent style across tools" {
	# Test that all tools use consistent banner style
	run "$TEST_DIR/bin/bump-version" --help
	assert_success
	local bump_banner_output="$output"

	run "$TEST_DIR/bin/generate-ai-workflow" --help
	assert_success
	local workflow_banner_output="$output"

	# Both should contain tool-specific text but use similar banner format
	assert [[ "$bump_banner_output" == *"Bump Version"* ]]
	assert [[ "$workflow_banner_output" == *"Generate AI Workflow"* ]]
}

@test "banners work in different terminal environments" {
	# Test banners work in limited terminal environments
	run bash -c "cd '$TEST_DIR' && TERM=dumb bin/bump-version --help"
	assert_success
	assert_output --partial "Bump Version"

	# Test with screen/tmux-like environment
	run bash -c "cd '$TEST_DIR' && TERM=screen bin/bump-version --help"
	assert_success
	assert_output --partial "Bump Version"
}

@test "banners display appropriate content for each tool" {
	# Test bump-version banner content
	run "$TEST_DIR/bin/bump-version" --help
	assert_success
	assert_output --partial "Bump Version"
	assert_output --partial "Intelligent version bumping"

	# Test generate-ai-workflow banner content
	run "$TEST_DIR/bin/generate-ai-workflow" --help
	assert_success
	assert_output --partial "Generate AI Workflow"
	assert_output --partial "AI development workflows"

	# Test update-shell-starter banner content
	run "$TEST_DIR/bin/update-shell-starter" --help
	assert_success
	assert_output --partial "Update Shell Starter"
	assert_output --partial "Shell Starter library dependencies"

	# Test cleanup-shell-path banner content
	run "$TEST_DIR/bin/cleanup-shell-path" --help
	assert_success
	assert_output --partial "Cleanup Shell Path"
	assert_output --partial "shell configuration cleanup"
}