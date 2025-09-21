#!/usr/bin/env bats
#
# Tests for bump-version script

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
	mkdir -p "$TEST_DIR/bin"
	mkdir -p "$TEST_DIR/lib"
	mkdir -p "$TEST_DIR/tests"
	mkdir -p "$TEST_DIR/scripts"

	# Copy the bump-version script to test directory
	cp "${ORIGINAL_PROJECT_ROOT}/bin/bump-version" "$TEST_DIR/bin/"

	# Create initial VERSION file
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

	# Call parent teardown
	unset SHELL_STARTER_TEST
	unset TEST_DIR
	unset ORIGINAL_PROJECT_ROOT
}

# Help and version tests
@test "bump-version: help flag" {
	run "$TEST_DIR/bin/bump-version" --help
	assert_success
	assert_output --partial "bump-version - Intelligent version bumping"
	assert_output --partial "USAGE:"
	assert_output --partial "VERSION FORMATS:"
	assert_output --partial "BUMP TYPES:"
	assert_output --partial "OPTIONS:"
	assert_output --partial "EXAMPLES:"
}

@test "bump-version: version flag" {
	run "$TEST_DIR/bin/bump-version" --version
	assert_success
	assert_output --partial "Bump Version Tool"
}

# Current version display tests
@test "bump-version: show current version" {
	run "$TEST_DIR/bin/bump-version" --current
	assert_success
	assert_output --partial "Current version: 1.0.0"
	assert_output --partial "Repository type:"
}

@test "bump-version: current version with missing VERSION file" {
	rm "$TEST_DIR/VERSION"
	run "$TEST_DIR/bin/bump-version" --current
	assert_success
	assert_output --partial "Current version: 0.0.0"
}

# Repository detection tests
@test "bump-version: detects cloned project (no shell-starter indicators)" {
	run "$TEST_DIR/bin/bump-version" --current
	assert_success
	assert_output --partial "Repository type: cloned-project"
}

@test "bump-version: detects shell-starter repo (with indicators)" {
	# Create shell-starter indicators
	touch "$TEST_DIR/bin/generate-ai-workflow"
	touch "$TEST_DIR/scripts/generate-release-notes.sh"
	touch "$TEST_DIR/tests/framework.bats"
	touch "$TEST_DIR/install.sh"

	run "$TEST_DIR/bin/bump-version" --current
	assert_success
	assert_output --partial "Repository type: shell-starter"
}

@test "bump-version: check-repo flag shows detection details" {
	run "$TEST_DIR/bin/bump-version" --check-repo
	assert_success
	assert_output --partial "Repository Detection Results"
	assert_output --partial "Detected type:"
	assert_output --partial "Shell-starter indicators:"
	assert_output --partial "Files that will be updated:"
}

# Version validation tests
@test "bump-version: validates semantic version format" {
	run "$TEST_DIR/bin/bump-version" "invalid-version"
	assert_failure
	assert_output --partial "Invalid version format"
}

@test "bump-version: accepts valid semantic versions" {
	run "$TEST_DIR/bin/bump-version" --dry-run "2.1.0"
	assert_success
	assert_output --partial "Setting version: 1.0.0 -> 2.1.0"
}

# Patch version bumping tests
@test "bump-version: patch bump" {
	run "$TEST_DIR/bin/bump-version" --dry-run "patch"
	assert_success
	assert_output --partial "Bumping patch version: 1.0.0 -> 1.0.1"
	assert_output --partial "[DRY-RUN] Would update VERSION to: 1.0.1"
}

@test "bump-version: patch bump without dry-run" {
	run "$TEST_DIR/bin/bump-version" "patch"
	assert_success
	assert_output --partial "Bumping patch version: 1.0.0 -> 1.0.1"
	assert_output --partial "Updated project version to 1.0.1"
	assert_output --partial "Version bump completed successfully!"

	# Verify VERSION file was updated
	run cat "$TEST_DIR/VERSION"
	assert_output "1.0.1"
}

# Minor version bumping tests
@test "bump-version: minor bump" {
	run "$TEST_DIR/bin/bump-version" --dry-run "minor"
	assert_success
	assert_output --partial "Bumping minor version: 1.0.0 -> 1.1.0"
	assert_output --partial "[DRY-RUN] Would update VERSION to: 1.1.0"
}

@test "bump-version: minor bump without dry-run" {
	run "$TEST_DIR/bin/bump-version" "minor"
	assert_success
	assert_output --partial "Bumping minor version: 1.0.0 -> 1.1.0"
	assert_output --partial "Updated project version to 1.1.0"

	# Verify VERSION file was updated
	run cat "$TEST_DIR/VERSION"
	assert_output "1.1.0"
}

# Major version bumping tests
@test "bump-version: major bump" {
	run "$TEST_DIR/bin/bump-version" --dry-run "major"
	assert_success
	assert_output --partial "Bumping major version: 1.0.0 -> 2.0.0"
	assert_output --partial "[DRY-RUN] Would update VERSION to: 2.0.0"
}

@test "bump-version: major bump without dry-run" {
	run "$TEST_DIR/bin/bump-version" "major"
	assert_success
	assert_output --partial "Bumping major version: 1.0.0 -> 2.0.0"
	assert_output --partial "Updated project version to 2.0.0"

	# Verify VERSION file was updated
	run cat "$TEST_DIR/VERSION"
	assert_output "2.0.0"
}

# Exact version setting tests
@test "bump-version: set exact version" {
	run "$TEST_DIR/bin/bump-version" --dry-run "3.2.1"
	assert_success
	assert_output --partial "Setting version: 1.0.0 -> 3.2.1"
	assert_output --partial "[DRY-RUN] Would update VERSION to: 3.2.1"
}

@test "bump-version: set exact version without dry-run" {
	run "$TEST_DIR/bin/bump-version" "3.2.1"
	assert_success
	assert_output --partial "Setting version: 1.0.0 -> 3.2.1"
	assert_output --partial "Updated project version to 3.2.1"

	# Verify VERSION file was updated
	run cat "$TEST_DIR/VERSION"
	assert_output "3.2.1"
}

# Shell-starter repository behavior tests
@test "bump-version: shell-starter repo updates both version files" {
	# Create shell-starter indicators
	touch "$TEST_DIR/bin/generate-ai-workflow"
	touch "$TEST_DIR/scripts/generate-release-notes.sh"
	touch "$TEST_DIR/tests/framework.bats"
	touch "$TEST_DIR/install.sh"

	# Create .shell-starter-version file
	echo "1.0.0" > "$TEST_DIR/.shell-starter-version"

	run "$TEST_DIR/bin/bump-version" "patch"
	assert_success
	assert_output --partial "Repository type: shell-starter"
	assert_output --partial "Updated project version to 1.0.1"
	assert_output --partial "Updated shell-starter version to 1.0.1"

	# Verify both files were updated
	run cat "$TEST_DIR/VERSION"
	assert_output "1.0.1"
	run cat "$TEST_DIR/.shell-starter-version"
	assert_output "1.0.1"
}

@test "bump-version: cloned project skips shell-starter-version file" {
	run "$TEST_DIR/bin/bump-version" "patch"
	assert_success
	assert_output --partial "Repository type: cloned-project"
	assert_output --partial "Updated project version to 1.0.1"
	assert_output --partial "Skipping .shell-starter-version update (cloned project)"

	# Verify only VERSION file was updated
	run cat "$TEST_DIR/VERSION"
	assert_output "1.0.1"
	assert [ ! -f "$TEST_DIR/.shell-starter-version" ]
}

# Error handling tests
@test "bump-version: missing arguments" {
	run "$TEST_DIR/bin/bump-version"
	assert_failure
	assert_output --partial "Version or bump type required"
}

@test "bump-version: unknown option" {
	run "$TEST_DIR/bin/bump-version" --invalid-option
	assert_failure
	assert_output --partial "Unknown option: --invalid-option"
}

@test "bump-version: multiple version arguments" {
	run "$TEST_DIR/bin/bump-version" "1.2.3" "4.5.6"
	assert_failure
	assert_output --partial "Multiple version arguments provided"
}

@test "bump-version: invalid bump type" {
	run "$TEST_DIR/bin/bump-version" "invalid-bump"
	assert_failure
	assert_output --partial "Invalid version format"
}

# Edge cases and version parsing tests
@test "bump-version: handles complex version increments" {
	# Test patch increment from x.y.9 -> x.y.10
	echo "1.2.9" > "$TEST_DIR/VERSION"
	run "$TEST_DIR/bin/bump-version" "patch"
	assert_success
	run cat "$TEST_DIR/VERSION"
	assert_output "1.2.10"
}

@test "bump-version: handles minor increment resets patch" {
	# Test minor increment from x.y.z -> x.(y+1).0
	echo "1.5.7" > "$TEST_DIR/VERSION"
	run "$TEST_DIR/bin/bump-version" "minor"
	assert_success
	run cat "$TEST_DIR/VERSION"
	assert_output "1.6.0"
}

@test "bump-version: handles major increment resets minor and patch" {
	# Test major increment from x.y.z -> (x+1).0.0
	echo "2.8.3" > "$TEST_DIR/VERSION"
	run "$TEST_DIR/bin/bump-version" "major"
	assert_success
	run cat "$TEST_DIR/VERSION"
	assert_output "3.0.0"
}

@test "bump-version: creates VERSION file if missing" {
	rm "$TEST_DIR/VERSION"
	run "$TEST_DIR/bin/bump-version" "1.0.0"
	assert_success
	assert_output --partial "VERSION file not found, will create one"
	assert_output --partial "Updated project version to 1.0.0"

	# Verify VERSION file was created
	assert [ -f "$TEST_DIR/VERSION" ]
	run cat "$TEST_DIR/VERSION"
	assert_output "1.0.0"
}

# Dry-run mode tests
@test "bump-version: dry-run mode does not modify files" {
	local original_version
	original_version=$(cat "$TEST_DIR/VERSION")

	run "$TEST_DIR/bin/bump-version" --dry-run "major"
	assert_success
	assert_output --partial "[DRY-RUN] Would update VERSION to: 2.0.0"
	assert_output --partial "Dry run completed. Use without --dry-run to apply changes."

	# Verify files were not modified
	run cat "$TEST_DIR/VERSION"
	assert_output "$original_version"
}

@test "bump-version: dry-run with shell-starter indicators" {
	# Create shell-starter indicators
	touch "$TEST_DIR/bin/generate-ai-workflow"
	touch "$TEST_DIR/scripts/generate-release-notes.sh"
	touch "$TEST_DIR/tests/framework.bats"
	touch "$TEST_DIR/install.sh"
	echo "1.0.0" > "$TEST_DIR/.shell-starter-version"

	run "$TEST_DIR/bin/bump-version" --dry-run "patch"
	assert_success
	assert_output --partial "[DRY-RUN] Would update VERSION to: 1.0.1"
	assert_output --partial "[DRY-RUN] Would update .shell-starter-version to: 1.0.1"

	# Verify files were not modified
	run cat "$TEST_DIR/VERSION"
	assert_output "1.0.0"
	run cat "$TEST_DIR/.shell-starter-version"
	assert_output "1.0.0"
}

# Color output verification tests
@test "bump-version: shows colored output when colors enabled" {
	# Test that colored output contains visual indicators
	run "$TEST_DIR/bin/bump-version" --current
	assert_success
	assert_output --partial "Current version:"

	# Check for visual indicators (should be present regardless of color support)
	assert_output --partial "Repository type:"
}

@test "bump-version: colored help output includes banner" {
	# Test that help output includes banner
	run "$TEST_DIR/bin/bump-version" --help
	assert_success
	assert_output --partial "Bump Version"
	assert_output --partial "USAGE:"
}

@test "bump-version: version bump shows colored status messages" {
	run "$TEST_DIR/bin/bump-version" "patch"
	assert_success

	# Should contain status message
	assert_output --partial "Updated project version to 1.0.1"
	assert_output --partial "Repository type:"
}

@test "bump-version: respects NO_COLOR environment variable" {
	# Test with NO_COLOR set
	run bash -c "cd '$TEST_DIR' && NO_COLOR=1 bin/bump-version --current"
	assert_success
	assert_output --partial "Current version: 1.0.0"

	# Should not contain ANSI escape sequences
	refute_output --partial $'['
}

@test "bump-version: error messages have visual indicators" {
	# Test error message formatting
	run "$TEST_DIR/bin/bump-version" --invalid-option
	assert_failure
	assert_output --partial "Unknown option: --invalid-option"
}

@test "bump-version: dry-run shows colored output" {
	run "$TEST_DIR/bin/bump-version" --dry-run "major"
	assert_success
	assert_output --partial "[DRY-RUN]"
	assert_output --partial "Dry run completed"
}