#!/usr/bin/env bats
#
# Tests for generate-release-notes script

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
	mkdir -p "$TEST_DIR/scripts"

	# Copy the generate-release-notes script to test directory
	cp "${ORIGINAL_PROJECT_ROOT}/scripts/generate-release-notes.sh" "$TEST_DIR/scripts/"
	chmod +x "$TEST_DIR/scripts/generate-release-notes.sh"

	# Initialize git repository for testing
	cd "$TEST_DIR" || exit
	git init
	git config user.name "Test User"
	git config user.email "test@example.com"
	git config commit.gpgsign false

	# Create initial commit
	echo "Initial commit" >initial.txt
	git add initial.txt
	git commit -m "chore: initial commit"
	git tag "v1.0.0"

	# Add some commits for testing
	echo "feature content" >feature.txt
	git add feature.txt
	git commit -m "feat: add new feature for testing"

	echo "fix content" >fix.txt
	git add fix.txt
	git commit -m "fix: resolve critical bug"

	echo "docs content" >docs.txt
	git add docs.txt
	git commit -m "docs: update documentation"

	echo "breaking change" >breaking.txt
	git add breaking.txt
	git commit -m "feat!: breaking change implementation"

	echo "non-conventional content" >other.txt
	git add other.txt
	git commit -m "Random commit message without conventional format"
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

# Help and basic functionality tests
@test "generate-release-notes: help flag" {
	run "$TEST_DIR/scripts/generate-release-notes.sh" --help
	assert_success
	assert_output --partial "Usage:"
	assert_output --partial "Generate automated release notes"
	assert_output --partial "OPTIONS:"
	assert_output --partial "EXAMPLES:"
	assert_output --partial "CONVENTIONAL COMMITS:"
}

@test "generate-release-notes: missing required current version" {
	run "$TEST_DIR/scripts/generate-release-notes.sh"
	assert_failure
	assert_output --partial "Error: Current version is required (-c/--current)"
}

@test "generate-release-notes: invalid option" {
	run "$TEST_DIR/scripts/generate-release-notes.sh" --invalid-option
	assert_failure
	assert_output --partial "Error: Unknown option"
}

# Basic release notes generation tests
@test "generate-release-notes: generates basic release notes" {
	cd "$TEST_DIR" || exit
	run "$TEST_DIR/scripts/generate-release-notes.sh" -c "2.0.0" -p "1.0.0" -o "test-release.md"
	assert_success
	assert_output --partial "Generating release notes: 1.0.0 -> 2.0.0"
	assert_output --partial "✅ Release notes generated: test-release.md"

	# Check that output file was created
	assert [ -f "$TEST_DIR/test-release.md" ]

	# Check basic structure
	run cat "$TEST_DIR/test-release.md"
	assert_output --partial "# Release 2.0.0"
	assert_output --partial "## What's Changed"
}

@test "generate-release-notes: auto-detects previous version from git tags" {
	cd "$TEST_DIR" || exit
	run "$TEST_DIR/scripts/generate-release-notes.sh" -c "2.0.0" -o "auto-release.md"
	assert_success
	assert_output --partial "Auto-detected previous version: 1.0.0"
	assert_output --partial "Generating release notes: 1.0.0 -> 2.0.0"

	# Verify release notes were generated
	assert [ -f "$TEST_DIR/auto-release.md" ]
}

@test "generate-release-notes: handles no previous tags" {
	cd "$TEST_DIR" || exit
	# Remove existing tags
	git tag -d v1.0.0

	run "$TEST_DIR/scripts/generate-release-notes.sh" -c "1.0.0" -o "first-release.md"
	assert_success
	assert_output --partial "Auto-detected previous version: 0.0.0"

	# Check that it generates initial release content
	run cat "$TEST_DIR/first-release.md"
	assert_output --partial "# Release 1.0.0"
	assert_output --partial "🎉 Initial Release"
	assert_output --partial "✨ Core Features"
}

# Conventional commit categorization tests
@test "generate-release-notes: categorizes conventional commits correctly" {
	cd "$TEST_DIR" || exit
	run "$TEST_DIR/scripts/generate-release-notes.sh" -c "2.0.0" -p "1.0.0" -o "categorized.md"
	assert_success

	# Check for proper categorization
	run cat "$TEST_DIR/categorized.md"
	assert_output --partial "### ⚠️ Breaking Changes"
	assert_output --partial "### ✨ New Features"
	assert_output --partial "### 🐛 Bug Fixes"
	assert_output --partial "### 📚 Documentation"
	assert_output --partial "### 📝 Other Changes"
}

@test "generate-release-notes: includes commit hashes and links with repository" {
	cd "$TEST_DIR" || exit
	run "$TEST_DIR/scripts/generate-release-notes.sh" -c "2.0.0" -p "1.0.0" -r "owner/repo" -o "with-links.md"
	assert_success

	run cat "$TEST_DIR/with-links.md"
	assert_output --partial "https://github.com/owner/repo/commit/"
	assert_output --partial "**add new feature for testing**"
	assert_output --partial "**resolve critical bug**"
}

@test "generate-release-notes: handles commits without repository links" {
	cd "$TEST_DIR" || exit
	run "$TEST_DIR/scripts/generate-release-notes.sh" -c "2.0.0" -p "1.0.0" -o "no-links.md"
	assert_success

	run cat "$TEST_DIR/no-links.md"
	# Should have commit hashes but no github.com links
	refute_output --partial "https://github.com"
	# Should still have short hashes in parentheses
	assert_output --regexp "\([a-f0-9]{7}\)"
}

# Repository detection tests
@test "generate-release-notes: auto-detects github repository from git remote" {
	cd "$TEST_DIR" || exit
	git remote add origin "https://github.com/owner/test-repo.git"

	run "$TEST_DIR/scripts/generate-release-notes.sh" -c "2.0.0" -p "1.0.0" -o "auto-repo.md"
	assert_success
	assert_output --partial "Auto-detected repository: owner/test-repo"

	run cat "$TEST_DIR/auto-repo.md"
	assert_output --partial "https://github.com/owner/test-repo/commit/"
	assert_output --partial "**Full Changelog**: https://github.com/owner/test-repo/compare/v1.0.0...v2.0.0"
}

@test "generate-release-notes: handles SSH remote URLs" {
	cd "$TEST_DIR" || exit
	git remote add origin "git@github.com:owner/ssh-repo.git"

	run "$TEST_DIR/scripts/generate-release-notes.sh" -c "2.0.0" -p "1.0.0" -o "ssh-repo.md"
	assert_success
	assert_output --partial "Auto-detected repository: owner/ssh-repo"
}

# Scoped commits tests
@test "generate-release-notes: handles scoped conventional commits" {
	cd "$TEST_DIR" || exit
	echo "scoped feature" >scoped.txt
	git add scoped.txt
	git commit -m "feat(ui): add new button component"

	echo "scoped fix" >scoped-fix.txt
	git add scoped-fix.txt
	git commit -m "fix(api): resolve authentication issue"

	run "$TEST_DIR/scripts/generate-release-notes.sh" -c "2.1.0" -p "2.0.0" -o "scoped.md"
	assert_success

	run cat "$TEST_DIR/scoped.md"
	assert_output --partial "**ui**: add new button component"
	assert_output --partial "**api**: resolve authentication issue"
}

# Contributors section tests
@test "generate-release-notes: includes contributors section" {
	cd "$TEST_DIR" || exit
	run "$TEST_DIR/scripts/generate-release-notes.sh" -c "2.0.0" -p "1.0.0" -o "contributors.md"
	assert_success

	run cat "$TEST_DIR/contributors.md"
	assert_output --partial "### 👥 Contributors"
	assert_output --partial "Thank you to the"
	assert_output --partial "contributor(s) who made this release possible:"
	assert_output --partial "- @Test User"
}

# Output options tests
@test "generate-release-notes: respects custom output file" {
	cd "$TEST_DIR" || exit
	run "$TEST_DIR/scripts/generate-release-notes.sh" -c "2.0.0" -p "1.0.0" -o "CUSTOM_CHANGELOG.md"
	assert_success
	assert_output --partial "✅ Release notes generated: CUSTOM_CHANGELOG.md"

	assert [ -f "$TEST_DIR/CUSTOM_CHANGELOG.md" ]
	assert [ ! -f "$TEST_DIR/release_notes.md" ]
}

@test "generate-release-notes: uses default filename when not specified" {
	cd "$TEST_DIR" || exit
	run "$TEST_DIR/scripts/generate-release-notes.sh" -c "2.0.0" -p "1.0.0"
	assert_success
	assert_output --partial "✅ Release notes generated: release_notes.md"

	assert [ -f "$TEST_DIR/release_notes.md" ]
}

# Metadata and footer tests
@test "generate-release-notes: includes proper metadata in footer" {
	cd "$TEST_DIR" || exit
	run "$TEST_DIR/scripts/generate-release-notes.sh" -c "2.0.0" -p "1.0.0" -r "owner/repo" -o "metadata.md"
	assert_success

	run cat "$TEST_DIR/metadata.md"
	assert_output --partial "**Release Information:**"
	assert_output --partial "**Version**: 2.0.0"
	assert_output --partial "**Previous Version**: 1.0.0"
	assert_output --partial "**Generated**:"
	assert_output --partial "**Full Changelog**: https://github.com/owner/repo/compare/v1.0.0...v2.0.0"
	assert_output --partial "*Generated by Shell Starter release automation.*"
}

# Edge cases and error handling
@test "generate-release-notes: handles commits with special characters" {
	cd "$TEST_DIR" || exit
	echo "special chars" >special.txt
	git add special.txt
	git commit -m "feat: add support for special chars & symbols"

	run "$TEST_DIR/scripts/generate-release-notes.sh" -c "2.0.1" -p "2.0.0" -o "special.md"
	assert_success

	run cat "$TEST_DIR/special.md"
	assert_output --partial "**add support for special chars & symbols**"
}

@test "generate-release-notes: handles empty commit range" {
	cd "$TEST_DIR" || exit
	# Test with same version (no commits between)
	run "$TEST_DIR/scripts/generate-release-notes.sh" -c "1.0.0" -p "1.0.0" -o "empty.md"
	assert_success

	run cat "$TEST_DIR/empty.md"
	assert_output --partial "# Release 1.0.0"
	# Should still have basic structure but minimal content
}

# Breaking changes detection
@test "generate-release-notes: properly detects breaking changes with exclamation" {
	cd "$TEST_DIR" || exit
	run "$TEST_DIR/scripts/generate-release-notes.sh" -c "2.0.0" -p "1.0.0" -o "breaking.md"
	assert_success

	run cat "$TEST_DIR/breaking.md"
	assert_output --partial "### ⚠️ Breaking Changes"
	assert_output --partial "**breaking change implementation**"
	# Breaking change should appear in both breaking section and features
	assert_output --partial "### ✨ New Features"
}

# Directory and file handling
@test "generate-release-notes: can be run from different directories" {
	cd "$TEST_DIR" || exit
	mkdir subdirectory
	cd subdirectory

	run "$TEST_DIR/scripts/generate-release-notes.sh" -c "2.0.0" -p "1.0.0" -o "subdir-release.md"
	assert_success

	# Should create file in current directory (subdirectory)
	assert [ -f "$TEST_DIR/subdirectory/subdir-release.md" ]
	assert [ ! -f "$TEST_DIR/subdir-release.md" ]
}
