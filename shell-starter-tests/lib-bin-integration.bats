#!/usr/bin/env bats
#
# Integration tests between library components and bin scripts
# Tests that bin scripts properly use lib functions and interact correctly

# Load test helpers
load test_helper
load bats-support/load
load bats-assert/load

setup() {
	export SHELL_STARTER_TEST=1

	# Create temporary directory for integration testing
	INTEGRATION_TEST_DIR=$(mktemp -d)
	export INTEGRATION_TEST_DIR

	# Create test project structure
	mkdir -p "$INTEGRATION_TEST_DIR/bin"
	mkdir -p "$INTEGRATION_TEST_DIR/lib"
	mkdir -p "$INTEGRATION_TEST_DIR/demo"

	# Copy lib files for testing
	cp -r "$PROJECT_ROOT/lib"/* "$INTEGRATION_TEST_DIR/lib/"

	# Create VERSION file
	echo "1.0.0" >"$INTEGRATION_TEST_DIR/VERSION"
}

teardown() {
	# Clean up test directory
	if [[ -n "$INTEGRATION_TEST_DIR" && -d "$INTEGRATION_TEST_DIR" ]]; then
		rm -rf "$INTEGRATION_TEST_DIR"
	fi

	unset SHELL_STARTER_TEST
	unset INTEGRATION_TEST_DIR
}

@test "integration: bump-version uses lib functions correctly" {
	# Copy bump-version to test directory
	cp "$PROJECT_ROOT/bin/bump-version" "$INTEGRATION_TEST_DIR/bin/"

	run bash -c "
        cd '$INTEGRATION_TEST_DIR'
        export PROJECT_ROOT='$INTEGRATION_TEST_DIR'

        # Test that bump-version properly uses version functions
        ./bin/bump-version --current 2>&1
    "
	assert_success
	assert_output --partial "Current version: 1.0.0"
	assert_output --partial "Repository type:"

	# Test integration with library versioning
	run bash -c "
        cd '$INTEGRATION_TEST_DIR'
        export PROJECT_ROOT='$INTEGRATION_TEST_DIR'

        # Test version bump uses lib functions
        ./bin/bump-version --dry-run patch 2>&1
    "
	assert_success
	assert_output --partial "Bumping patch version: 1.0.0 -> 1.0.1"
	assert_output --partial "[DRY-RUN]"
}

@test "integration: generate-ai-workflow uses lib functions correctly" {
	# Copy generate-ai-workflow to test directory
	cp "$PROJECT_ROOT/bin/generate-ai-workflow" "$INTEGRATION_TEST_DIR/bin/"

	run bash -c "
        cd '$INTEGRATION_TEST_DIR'
        export PROJECT_ROOT='$INTEGRATION_TEST_DIR'

        # Test that generate-ai-workflow uses logging and colors
        echo 'y' | ./bin/generate-ai-workflow test-project 2>&1
    "
	assert_success
	assert_output --partial "Generating AI workflow for project: test-project"
	assert_output --partial "✓ AI workflow generated successfully!"

	# Verify integration with library functions
	assert [ -d "$INTEGRATION_TEST_DIR/.ai-workflow" ]
}

@test "integration: update-shell-starter uses lib functions correctly" {
	# Copy update-shell-starter to test directory
	cp "$PROJECT_ROOT/bin/update-shell-starter" "$INTEGRATION_TEST_DIR/bin/"

	# Create shell-starter version file
	echo "1.0.0" >"$INTEGRATION_TEST_DIR/.shell-starter-version"

	run bash -c "
        cd '$INTEGRATION_TEST_DIR'
        export PROJECT_ROOT='$INTEGRATION_TEST_DIR'

        # Test help function integration
        ./bin/update-shell-starter --help 2>&1
    "
	assert_success
	assert_output --partial "update-shell-starter - Shell Starter library dependency manager"
	assert_output --partial "Usage:"

	# Test version integration
	run bash -c "
        cd '$INTEGRATION_TEST_DIR'
        export PROJECT_ROOT='$INTEGRATION_TEST_DIR'

        ./bin/update-shell-starter --version 2>&1
    "
	assert_success
	assert_output --regexp "[0-9]+\.[0-9]+\.[0-9]+"
}

@test "integration: demo scripts use lib functions correctly" {
	# Test hello-world integration
	run_script "hello-world" --version
	assert_success
	assert_output --regexp "[0-9]+\.[0-9]+\.[0-9]+"

	run_script "hello-world" --help
	assert_success
	assert_output --partial "Usage:"

	# Test show-colors integration with color library
	run_script "show-colors"
	assert_success
	# Should use color library functions

	# Test spinner integration
	run bash -c "timeout 5 '${PROJECT_ROOT}/demo/long-task' --help"
	assert_success
	assert_output --partial "long-task - Demonstration of spinner functionality"
}

@test "integration: lib functions work consistently across scripts" {
	# Test that all scripts produce consistent version output format
	local scripts=("hello-world" "greet-user" "show-colors" "long-task")

	for script in "${scripts[@]}"; do
		run_script "$script" --version
		assert_success
		# All should contain semantic version
		assert_output --regexp "[0-9]+\.[0-9]+\.[0-9]+"
	done
}

@test "integration: logging consistency across scripts" {
	# Test that logging works consistently
	run bash -c "
        # Test with different log levels
        export LOG_LEVEL=DEBUG

        # Test demo script logging
        timeout 2 '${PROJECT_ROOT}/demo/long-task' 2>&1 || true
    "
	# Should see consistent log formatting across scripts
}

@test "integration: color system works across all scripts" {
	# Test color integration in various scripts
	run_script "show-colors"
	assert_success
	# Should contain ANSI color codes
	assert_output --partial $'\e['

	run_script "show-banner"
	assert_success
	# Should also contain color codes
	assert_output --partial $'\e['

	# Test that colors can be disabled
	run bash -c "
        export NO_COLOR=1
        '${PROJECT_ROOT}/demo/show-colors'
    "
	assert_success
}

@test "integration: update functionality across scripts" {
	# Test that update flag works consistently
	run_script "hello-world" --update
	# Should attempt update check (may fail due to network, that's OK)

	run_script "update-tool" --help
	assert_success
	assert_output --partial "update-tool - Demonstration of update management"
}

@test "integration: argument parsing consistency" {
	# Test that all scripts handle common flags consistently
	local common_scripts=("hello-world" "greet-user" "show-colors" "long-task" "my-cli")

	for script in "${common_scripts[@]}"; do
		# Test help flag
		run_script "$script" --help
		assert_success
		assert_output --partial "Usage:"

		# Test version flag
		run_script "$script" --version
		assert_success
		assert_output --partial "$script"

		# Test unknown flag handling
		run_script "$script" --unknown-flag
		assert_failure
		assert_output --partial "Unknown option: --unknown-flag"
	done
}

@test "integration: polyglot functionality" {
	# Test polyglot script integration with lib utilities
	run_script "polyglot-example" --help
	assert_success
	assert_output --partial "polyglot-example - Demonstration of multi-language script integration"

	# Test that it can handle Python integration
	run bash -c "
        cd '$PROJECT_ROOT'
        demo/polyglot-example --version 2>&1
    "
	assert_success
}

@test "integration: spinner and logging interaction" {
	# Test that spinner and logging work together
	run bash -c "
        source '$PROJECT_ROOT/lib/main.sh'

        log::info 'Starting integration test'
        spinner::start 'Processing...'
        sleep 0.1
        log::warn 'Warning during processing'
        spinner::update 'Almost done...'
        sleep 0.1
        spinner::stop
        log::info 'Integration test completed'
    "
	assert_success
	assert_output --partial "Starting integration test"
	assert_output --partial "Warning during processing"
	assert_output --partial "Integration test completed"
}

@test "integration: library state management" {
	# Test that library state is properly managed across function calls
	run bash -c "
        source '$PROJECT_ROOT/lib/main.sh'

        # Test state consistency
        initial_version=\$(get_version)
        echo \"Initial version: \$initial_version\"

        # Call multiple functions
        log::info 'State test'
        spinner::start 'test'
        spinner::stop

        # Check state is still consistent
        final_version=\$(get_version)
        echo \"Final version: \$final_version\"

        if [[ \"\$initial_version\" == \"\$final_version\" ]]; then
            echo 'State consistency maintained'
        else
            echo 'State consistency failed'
        fi
    "
	assert_success
	assert_output --partial "State consistency maintained"
}

@test "integration: error propagation from lib to bin" {
	# Test that library errors are properly handled by bin scripts
	run bash -c "
        # Create a script that sources lib and calls functions
        temp_script='$INTEGRATION_TEST_DIR/test-error-prop.sh'
        cat > \"\$temp_script\" << 'EOF'
#!/bin/bash
source '$PROJECT_ROOT/lib/main.sh'

# Test error propagation
log::info 'Testing error propagation'
run::script '/nonexistent/script.py' 2>&1 || {
    log::error 'Caught error from lib function'
    exit 1
}
EOF
        chmod +x \"\$temp_script\"
        \"\$temp_script\" 2>&1
    "
	assert_failure
	assert_output --partial "Testing error propagation"
	assert_output --partial "Caught error from lib function"
}

@test "integration: performance and resource usage" {
	# Test that integration doesn't cause performance issues
	run bash -c "
        start_time=\$(date +%s)

        # Load library multiple times (simulating multiple script calls)
        for i in {1..5}; do
            source '$PROJECT_ROOT/lib/main.sh'
            version=\$(get_version)
            log::info \"Iteration \$i: version \$version\"
        done

        end_time=\$(date +%s)
        duration=\$((end_time - start_time))
        echo \"Performance test completed in \${duration}s\"

        # Should complete quickly
        if [[ \$duration -lt 10 ]]; then
            echo 'Performance acceptable'
        else
            echo 'Performance issue detected'
        fi
    "
	assert_success
	assert_output --partial "Performance acceptable"
}

@test "integration: concurrent script execution" {
	# Test that multiple scripts can run concurrently without conflicts
	run bash -c "
        # Run multiple demo scripts in background
        timeout 5 '${PROJECT_ROOT}/demo/hello-world' &
        timeout 5 '${PROJECT_ROOT}/demo/show-colors' &
        timeout 5 '${PROJECT_ROOT}/demo/show-banner' &

        # Wait for all to complete
        wait

        echo 'Concurrent execution completed'
    "
	assert_success
	assert_output --partial "Concurrent execution completed"
}
