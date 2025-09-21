#!/usr/bin/env bats
#
# Tests for update-shell-starter script

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
	mkdir -p "$TEST_DIR/demo"

	# Copy the update-shell-starter script to test directory
	cp "${ORIGINAL_PROJECT_ROOT}/bin/update-shell-starter" "$TEST_DIR/bin/"

	# Create a mock shell-starter version file
	echo "0.1.0" > "$TEST_DIR/.shell-starter-version"

	# Create basic lib files for testing
	echo "# colors.sh" > "$TEST_DIR/lib/colors.sh"
	echo "# main.sh" > "$TEST_DIR/lib/main.sh"
	echo "# logging.sh" > "$TEST_DIR/lib/logging.sh"

	# Create custom files to test preservation
	echo "# custom.sh" > "$TEST_DIR/lib/custom.sh"
	echo "#!/bin/bash" > "$TEST_DIR/bin/custom-script"
	chmod +x "$TEST_DIR/bin/custom-script"

	# Mock curl command for testing (create a wrapper script)
	MOCK_CURL_DIR="$TEST_DIR/mock_bin"
	mkdir -p "$MOCK_CURL_DIR"
	cat > "$MOCK_CURL_DIR/curl" << 'EOF'
#!/bin/bash
# Mock curl for testing
if [[ "$*" == *"api.github.com"* ]]; then
	echo '{"tag_name": "v0.2.0"}'
elif [[ "$*" == *".tar.gz"* ]]; then
	# Create a mock tar.gz content structure
	mkdir -p /tmp/mock-shell-starter/lib
	mkdir -p /tmp/mock-shell-starter/bin
	echo "# Updated colors.sh" > /tmp/mock-shell-starter/lib/colors.sh
	echo "# Updated main.sh" > /tmp/mock-shell-starter/lib/main.sh
	echo "# Updated logging.sh" > /tmp/mock-shell-starter/lib/logging.sh
	echo "# Updated spinner.sh" > /tmp/mock-shell-starter/lib/spinner.sh
	echo "# Updated utils.sh" > /tmp/mock-shell-starter/lib/utils.sh
	echo "# Updated update.sh" > /tmp/mock-shell-starter/lib/update.sh
	echo "#!/bin/bash\necho updated-update-shell-starter" > /tmp/mock-shell-starter/bin/update-shell-starter
	echo "#!/bin/bash\necho updated-bump-version" > /tmp/mock-shell-starter/bin/bump-version
	echo "#!/bin/bash\necho updated-generate-ai-workflow" > /tmp/mock-shell-starter/bin/generate-ai-workflow
	(cd /tmp && tar -czf - mock-shell-starter --transform 's/mock-shell-starter//')
else
	echo "Mock curl called with: $*" >&2
	exit 1
fi
EOF
	chmod +x "$MOCK_CURL_DIR/curl"
	export PATH="$MOCK_CURL_DIR:$PATH"
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

	# Clean up mock files
	rm -rf /tmp/mock-shell-starter 2>/dev/null || true

	# Call parent teardown
	unset SHELL_STARTER_TEST
	unset TEST_DIR
	unset ORIGINAL_PROJECT_ROOT
}

# Help and version tests
@test "update-shell-starter: help flag" {
	run "$TEST_DIR/bin/update-shell-starter" --help
	assert_success
	assert_output --partial "update-shell-starter - Update Shell Starter library dependencies"
	assert_output --partial "USAGE:"
	assert_output --partial "OPTIONS:"
	assert_output --partial "EXAMPLES:"
	assert_output --partial "IMPORTANT: Demo scripts in the demo/ folder"
}

@test "update-shell-starter: version flag" {
	run "$TEST_DIR/bin/update-shell-starter" --version
	assert_success
	assert_output --partial "version"
}

# Check functionality tests
@test "update-shell-starter: check for updates" {
	run "$TEST_DIR/bin/update-shell-starter" --check
	assert_success
	assert_output --partial "Current version: 0.1.0"
	assert_output --partial "Latest version: 0.2.0"
	assert_output --partial "Update available: v0.1.0 -> v0.2.0"
}

@test "update-shell-starter: check when up to date" {
	echo "0.2.0" > "$TEST_DIR/.shell-starter-version"
	run "$TEST_DIR/bin/update-shell-starter" --check
	assert_success
	assert_output --partial "Current version: 0.2.0"
	assert_output --partial "Latest version: 0.2.0"
	assert_output --partial "You are using the latest version"
}

@test "update-shell-starter: check with unknown current version" {
	rm "$TEST_DIR/.shell-starter-version"
	run "$TEST_DIR/bin/update-shell-starter" --check
	assert_success
	assert_output --partial "Current version: unknown"
	assert_output --partial "Latest version: 0.2.0"
	assert_output --partial "Update available"
}

# Dry-run tests
@test "update-shell-starter: dry-run mode" {
	run "$TEST_DIR/bin/update-shell-starter" --dry-run
	assert_success
	assert_output --partial "Current shell-starter version: 0.1.0"
	assert_output --partial "Target shell-starter version: 0.2.0"
	assert_output --partial "[DRY-RUN] Would update"
	assert_output --partial "Dry run completed. Use without --dry-run to apply changes."

	# Verify files were not actually modified
	run cat "$TEST_DIR/.shell-starter-version"
	assert_output "0.1.0"
}

@test "update-shell-starter: dry-run with target version" {
	run "$TEST_DIR/bin/update-shell-starter" --dry-run --target-version "0.3.0"
	assert_success
	assert_output --partial "Target shell-starter version: 0.3.0"
	assert_output --partial "[DRY-RUN] Would update"
}

@test "update-shell-starter: dry-run with custom lib directory" {
	mkdir -p "$TEST_DIR/custom_lib"
	run "$TEST_DIR/bin/update-shell-starter" --dry-run --lib-dir "$TEST_DIR/custom_lib"
	assert_success
	assert_output --partial "[DRY-RUN] Would update"
}

# Force update tests
@test "update-shell-starter: force update when versions match" {
	echo "0.2.0" > "$TEST_DIR/.shell-starter-version"
	run "$TEST_DIR/bin/update-shell-starter" --force --dry-run
	assert_success
	assert_output --partial "Current shell-starter version: 0.2.0"
	assert_output --partial "Target shell-starter version: 0.2.0"
	assert_output --partial "[DRY-RUN] Would update"
}

@test "update-shell-starter: skip update when versions match without force" {
	echo "0.2.0" > "$TEST_DIR/.shell-starter-version"
	run "$TEST_DIR/bin/update-shell-starter" --dry-run
	assert_success
	assert_output --partial "Already using shell-starter v0.2.0"
}

# Backup functionality tests
@test "update-shell-starter: creates backup by default" {
	run "$TEST_DIR/bin/update-shell-starter" --dry-run
	assert_success
	assert_output --partial "Creating backup:"
}

@test "update-shell-starter: no-backup flag skips backup" {
	run "$TEST_DIR/bin/update-shell-starter" --dry-run --no-backup
	assert_success
	refute_output --partial "Creating backup:"
}

@test "update-shell-starter: backup flag explicitly enables backup" {
	run "$TEST_DIR/bin/update-shell-starter" --dry-run --backup
	assert_success
	assert_output --partial "Creating backup:"
}

# Demo folder preservation tests
@test "update-shell-starter: demo folder preservation message with demo" {
	run "$TEST_DIR/bin/update-shell-starter" --dry-run
	assert_success
	assert_output --partial "Demo scripts in demo/ folder will be preserved"
}

@test "update-shell-starter: demo folder preservation without demo" {
	rmdir "$TEST_DIR/demo"
	run "$TEST_DIR/bin/update-shell-starter" --dry-run
	assert_success
	refute_output --partial "Demo scripts in demo/ folder"
}

# Custom file preservation tests
@test "update-shell-starter: preserves custom lib files" {
	run "$TEST_DIR/bin/update-shell-starter" --dry-run
	assert_success
	assert_output --partial "Custom file preserved:"
	assert_output --partial "custom.sh"
}

@test "update-shell-starter: preserves custom bin scripts" {
	run "$TEST_DIR/bin/update-shell-starter" --dry-run
	assert_success
	assert_output --partial "Custom bin script preserved:"
	assert_output --partial "custom-script"
}

# Core utilities update tests
@test "update-shell-starter: updates core utilities" {
	run "$TEST_DIR/bin/update-shell-starter" --dry-run
	assert_success
	assert_output --partial "Updating core utility scripts"
	assert_output --partial "[DRY-RUN] Would update:"
	assert_output --partial "update-shell-starter"
}

@test "update-shell-starter: handles missing core utilities gracefully" {
	# Mock curl to return incomplete bin directory
	cat > "$MOCK_CURL_DIR/curl" << 'EOF'
#!/bin/bash
if [[ "$*" == *"api.github.com"* ]]; then
	echo '{"tag_name": "v0.2.0"}'
elif [[ "$*" == *".tar.gz"* ]]; then
	mkdir -p /tmp/mock-shell-starter/lib
	mkdir -p /tmp/mock-shell-starter/bin
	echo "# Updated main.sh" > /tmp/mock-shell-starter/lib/main.sh
	# Only create one core utility
	echo "#!/bin/bash\necho updated-bump-version" > /tmp/mock-shell-starter/bin/bump-version
	(cd /tmp && tar -czf - mock-shell-starter --transform 's/mock-shell-starter//')
fi
EOF

	run "$TEST_DIR/bin/update-shell-starter" --dry-run
	assert_success
	assert_output --partial "Core utility not found in source:"
}

# Library files update tests
@test "update-shell-starter: updates standard library files" {
	run "$TEST_DIR/bin/update-shell-starter" --dry-run
	assert_success
	assert_output --partial "Updating library files"
	assert_output --partial "[DRY-RUN] Would update:"
	assert_output --partial "colors.sh"
	assert_output --partial "main.sh"
	assert_output --partial "logging.sh"
}

# Version tracking tests
@test "update-shell-starter: updates version tracking file" {
	run "$TEST_DIR/bin/update-shell-starter" --dry-run
	assert_success
	assert_output --partial "[DRY-RUN] Would update version file to: v0.2.0"
}

# Target version tests
@test "update-shell-starter: target version specification" {
	# Mock curl to return a different version
	cat > "$MOCK_CURL_DIR/curl" << 'EOF'
#!/bin/bash
if [[ "$*" == *"v0.5.0.tar.gz"* ]]; then
	mkdir -p /tmp/mock-shell-starter/lib
	echo "# Version 0.5.0 main.sh" > /tmp/mock-shell-starter/lib/main.sh
	(cd /tmp && tar -czf - mock-shell-starter --transform 's/mock-shell-starter//')
else
	exit 1
fi
EOF

	run "$TEST_DIR/bin/update-shell-starter" --dry-run --target-version "0.5.0"
	assert_success
	assert_output --partial "Target shell-starter version: 0.5.0"
}

# Custom lib directory tests
@test "update-shell-starter: custom lib directory" {
	mkdir -p "$TEST_DIR/custom_lib"
	echo "# existing custom file" > "$TEST_DIR/custom_lib/existing.sh"

	run "$TEST_DIR/bin/update-shell-starter" --dry-run --lib-dir "$TEST_DIR/custom_lib"
	assert_success
	assert_output --partial "Updating library files in ${TEST_DIR}/custom_lib"
}

@test "update-shell-starter: creates lib directory if missing" {
	rmdir "$TEST_DIR/lib"
	run "$TEST_DIR/bin/update-shell-starter" --dry-run
	assert_success
	assert_output --partial "Library directory does not exist"
	assert_output --partial "Will create directory during update"
}

# Error handling tests
@test "update-shell-starter: unknown option" {
	run "$TEST_DIR/bin/update-shell-starter" --invalid-option
	assert_failure
	assert_output --partial "Unknown option: --invalid-option"
}

@test "update-shell-starter: handles curl failure for version check" {
	# Remove mock curl to simulate failure
	rm "$MOCK_CURL_DIR/curl"
	unset PATH

	run "$TEST_DIR/bin/update-shell-starter" --check
	assert_failure
	assert_output --partial "curl is required but not installed"
}

@test "update-shell-starter: handles download failure" {
	# Mock curl to fail on download
	cat > "$MOCK_CURL_DIR/curl" << 'EOF'
#!/bin/bash
if [[ "$*" == *"api.github.com"* ]]; then
	echo '{"tag_name": "v0.2.0"}'
elif [[ "$*" == *".tar.gz"* ]]; then
	exit 1  # Simulate download failure
fi
EOF

	run "$TEST_DIR/bin/update-shell-starter" --dry-run
	assert_failure
	assert_output --partial "Failed to download shell-starter"
}

# Breaking changes detection tests (mock scenarios)
@test "update-shell-starter: breaking changes detection (dry-run simulation)" {
	# This test simulates breaking changes detection
	# Since we can't easily test interactive prompts, we test dry-run output
	echo "0.1.0" > "$TEST_DIR/.shell-starter-version"

	# Mock a version that would trigger breaking changes
	cat > "$MOCK_CURL_DIR/curl" << 'EOF'
#!/bin/bash
if [[ "$*" == *"api.github.com"* ]]; then
	echo '{"tag_name": "v0.3.0"}'
elif [[ "$*" == *".tar.gz"* ]]; then
	mkdir -p /tmp/mock-shell-starter/lib
	echo "# Version 0.3.0 main.sh" > /tmp/mock-shell-starter/lib/main.sh
	(cd /tmp && tar -czf - mock-shell-starter --transform 's/mock-shell-starter//')
fi
EOF

	run "$TEST_DIR/bin/update-shell-starter" --dry-run --force
	assert_success
	assert_output --partial "Target shell-starter version: 0.3.0"
	# The breaking changes detection would happen, but with --force it should proceed
}

# Integration-style tests
@test "update-shell-starter: complete dry-run workflow" {
	run "$TEST_DIR/bin/update-shell-starter" --dry-run
	assert_success
	assert_output --partial "Current shell-starter version: 0.1.0"
	assert_output --partial "Target shell-starter version: 0.2.0"
	assert_output --partial "Creating backup:"
	assert_output --partial "Updating library files"
	assert_output --partial "Updating core utility scripts"
	assert_output --partial "[DRY-RUN] Would update version file"
	assert_output --partial "Dry run completed"
}

@test "update-shell-starter: preserves project structure" {
	run "$TEST_DIR/bin/update-shell-starter" --dry-run
	assert_success
	assert_output --partial "Custom file preserved:"
	assert_output --partial "Custom bin script preserved:"
	assert_output --partial "Demo scripts in demo/ folder will be preserved"
}

# Edge cases
@test "update-shell-starter: handles empty version file" {
	echo "" > "$TEST_DIR/.shell-starter-version"
	run "$TEST_DIR/bin/update-shell-starter" --check
	assert_success
	assert_output --partial "Current version:"
}

@test "update-shell-starter: handles missing version file gracefully" {
	rm "$TEST_DIR/.shell-starter-version"
	run "$TEST_DIR/bin/update-shell-starter" --dry-run
	assert_success
	assert_output --partial "Current shell-starter version: unknown"
}

@test "update-shell-starter: argument parsing with multiple flags" {
	run "$TEST_DIR/bin/update-shell-starter" --dry-run --no-backup --force --target-version "0.2.0"
	assert_success
	assert_output --partial "Target shell-starter version: 0.2.0"
	refute_output --partial "Creating backup:"
}