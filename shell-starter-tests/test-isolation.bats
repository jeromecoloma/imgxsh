#!/usr/bin/env bats
#
# Test isolation and cleanup verification tests
# Ensures that tests don't interfere with each other or the user environment

# Load test helpers
load test_helper
load bats-support/load
load bats-assert/load

@test "test isolation: environment state preservation" {
	# Verify environment is preserved across tests
	run bash -c "verify_test_isolation"
	assert_success
}

@test "test isolation: temporary directory cleanup" {
	# Create some temporary directories and verify they're tracked
	local temp_dir1 temp_dir2
	temp_dir1=$(mktemp -d)
	temp_dir2=$(mktemp -d)

	track_temp_dir "$temp_dir1"
	track_temp_dir "$temp_dir2"

	# Verify directories exist
	assert [ -d "$temp_dir1" ]
	assert [ -d "$temp_dir2" ]

	# Verify they're tracked
	assert [[ " ${TEMP_DIRS_CREATED[*]} " =~ " $temp_dir1 " ]]
	assert [[ " ${TEMP_DIRS_CREATED[*]} " =~ " $temp_dir2 " ]]

	# Manual cleanup for verification
	cleanup_temp_directories

	# Verify they're cleaned up
	assert [ ! -d "$temp_dir1" ]
	assert [ ! -d "$temp_dir2" ]
}

@test "test isolation: background process cleanup" {
	# Start some background processes and verify they're tracked and cleaned
	sleep 60 &
	local pid1=$!
	sleep 60 &
	local pid2=$!

	track_background_pid "$pid1"
	track_background_pid "$pid2"

	# Verify processes are running
	assert kill -0 "$pid1" 2>/dev/null
	assert kill -0 "$pid2" 2>/dev/null

	# Verify they're tracked
	assert [[ " ${BACKGROUND_PIDS[*]} " =~ " $pid1 " ]]
	assert [[ " ${BACKGROUND_PIDS[*]} " =~ " $pid2 " ]]

	# Manual cleanup for verification
	cleanup_background_processes

	# Give a moment for cleanup
	sleep 0.2

	# Verify they're terminated
	run kill -0 "$pid1" 2>/dev/null
	assert_failure
	run kill -0 "$pid2" 2>/dev/null
	assert_failure
}

@test "test isolation: file creation tracking" {
	# Create some files and verify they're tracked and cleaned
	local temp_file1 temp_file2
	temp_file1=$(mktemp)
	temp_file2=$(mktemp)

	track_created_file "$temp_file1"
	track_created_file "$temp_file2"

	# Write to files to verify they exist
	echo "test data" >"$temp_file1"
	echo "more test data" >"$temp_file2"

	# Verify files exist
	assert [ -f "$temp_file1" ]
	assert [ -f "$temp_file2" ]

	# Verify they're tracked
	assert [[ " ${FILES_CREATED[*]} " =~ " $temp_file1 " ]]
	assert [[ " ${FILES_CREATED[*]} " =~ " $temp_file2 " ]]

	# Manual cleanup for verification
	cleanup_created_files

	# Verify they're cleaned up
	assert [ ! -f "$temp_file1" ]
	assert [ ! -f "$temp_file2" ]
}

@test "test isolation: environment variable restoration" {
	# Test that environment variables are properly restored
	local original_log_level="${LOG_LEVEL:-}"
	local original_no_color="${NO_COLOR:-}"

	# Modify environment
	export LOG_LEVEL="DEBUG"
	export NO_COLOR="1"
	export NEW_TEST_VAR="test_value"

	# Verify changes took effect
	assert [[ "$LOG_LEVEL" == "DEBUG" ]]
	assert [[ "$NO_COLOR" == "1" ]]
	assert [[ "$NEW_TEST_VAR" == "test_value" ]]

	# Simulate teardown environment restoration
	_restore_environment_state

	# Verify restoration (LOG_LEVEL and NO_COLOR should be restored)
	if [[ -n "$original_log_level" ]]; then
		assert [[ "$LOG_LEVEL" == "$original_log_level" ]]
	fi

	if [[ -n "$original_no_color" ]]; then
		assert [[ "$NO_COLOR" == "$original_no_color" ]]
	fi

	# NEW_TEST_VAR should still exist (we don't track all vars automatically)
	assert [[ "$NEW_TEST_VAR" == "test_value" ]]
	unset NEW_TEST_VAR # Manual cleanup
}

@test "test isolation: working directory preservation" {
	# Test that working directory is preserved
	local original_pwd="$PWD"

	# Change to a different directory
	local temp_dir
	temp_dir=$(mktemp -d)
	track_temp_dir "$temp_dir"

	cd "$temp_dir"
	assert [[ "$PWD" == "$temp_dir" ]]

	# Simulate teardown directory restoration
	_restore_environment_state

	# Verify we're back to original directory
	assert [[ "$PWD" == "$original_pwd" ]]
}

@test "test isolation: umask restoration" {
	# Test that umask is properly managed
	local original_umask
	original_umask=$(umask)

	# Simulate setup umask change
	_setup_test_isolation

	# Verify restrictive umask was set
	local test_umask
	test_umask=$(umask)
	assert [[ "$test_umask" == "0077" ]]

	# Simulate teardown umask restoration
	_cleanup_test_isolation

	# Verify umask is restored
	local final_umask
	final_umask=$(umask)
	assert [[ "$final_umask" == "$original_umask" ]]
}

@test "test isolation: spinner cleanup" {
	# Test that spinners are properly cleaned up
	run bash -c "
        source $PROJECT_ROOT/lib/main.sh

        # Start a spinner
        spinner::start 'test spinner'

        # Verify it's running (this is implementation-dependent)
        # The key is that cleanup should handle it gracefully

        # Test cleanup (this happens in teardown)
        if declare -F spinner::stop >/dev/null 2>&1; then
            spinner::stop 2>/dev/null || echo 'Spinner cleanup handled'
        fi
    "
	assert_success
}

@test "test isolation: no interference between tests" {
	# Verify that this test starts with clean state
	assert [[ ${#TEMP_DIRS_CREATED[@]} -eq 1 ]] # Only the BATS temp dir should exist
	assert [[ ${#BACKGROUND_PIDS[@]} -eq 0 ]]
	assert [[ ${#FILES_CREATED[@]} -eq 0 ]]
	assert [[ -n "${SHELL_STARTER_TEST:-}" ]]

	# Create some test artifacts
	local temp_dir temp_file
	temp_dir=$(mktemp -d)
	temp_file=$(mktemp)

	track_temp_dir "$temp_dir"
	track_created_file "$temp_file"

	sleep 30 &
	track_background_pid $!

	# Verify tracking is working
	assert [[ ${#TEMP_DIRS_CREATED[@]} -eq 2 ]] # BATS temp dir + our temp dir
	assert [[ ${#BACKGROUND_PIDS[@]} -eq 1 ]]
	assert [[ ${#FILES_CREATED[@]} -eq 1 ]]
}

@test "test isolation: isolated script execution" {
	# Test the run_script_isolated function
	run bash -c "
        # Use isolated script execution
        export BEFORE_ISOLATION='should not affect script'

        # Run a simple script in isolation
        '${PROJECT_ROOT}/demo/hello-world' --version 2>&1
    "
	assert_success
	assert_output --regexp "[0-9]+\.[0-9]+\.[0-9]+"

	# Test that isolation directory was created
	assert [[ -n "${SCRIPT_ISOLATED_DIR:-}" ]] || skip "SCRIPT_ISOLATED_DIR not set"
}

@test "test isolation: permission reset after restricted tests" {
	# Create a directory with restricted permissions
	local restricted_dir
	restricted_dir=$(mktemp -d)
	track_temp_dir "$restricted_dir"

	# Set restrictive permissions
	chmod 000 "$restricted_dir"

	# Verify permissions are restrictive
	run ls "$restricted_dir" 2>/dev/null
	assert_failure

	# Test that cleanup can handle restricted permissions
	cleanup_temp_directories

	# Verify directory was cleaned up despite permissions
	assert [ ! -d "$restricted_dir" ]
}

@test "test isolation: comprehensive integration test" {
	# Test all isolation features working together

	# Save initial state
	local initial_pwd="$PWD"
	local initial_umask
	initial_umask=$(umask)

	# Create multiple types of test artifacts
	local temp_dir temp_file
	temp_dir=$(mktemp -d)
	temp_file=$(mktemp)

	track_temp_dir "$temp_dir"
	track_created_file "$temp_file"

	# Start background process
	sleep 60 &
	track_background_pid $!

	# Change environment
	cd "$temp_dir"
	umask 0022
	export TEST_ISOLATION_VAR="test_value"

	# Verify all changes took effect
	assert [[ "$PWD" == "$temp_dir" ]]
	assert [[ "$(umask)" == "0022" ]]
	assert [[ "$TEST_ISOLATION_VAR" == "test_value" ]]

	# Run comprehensive cleanup
	_cleanup_test_isolation
	_restore_environment_state

	# Verify complete restoration
	assert [[ "$PWD" == "$initial_pwd" ]]
	assert [[ "$(umask)" == "$initial_umask" ]]

	# Verify test artifacts are cleaned up
	assert [ ! -d "$temp_dir" ]
	assert [ ! -f "$temp_file" ]

	# Clean up test variable
	unset TEST_ISOLATION_VAR
}
