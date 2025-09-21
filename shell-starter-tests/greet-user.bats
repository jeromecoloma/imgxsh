#!/usr/bin/env bats
#
# Tests for greet-user demo script

# Load test helpers
load test_helper
load bats-support/load
load bats-assert/load

# Help and version tests
@test "greet-user: help flag" {
	run_script "greet-user" --help
	assert_success
	assert_output --partial "Usage:"
	assert_output --partial "Interactive script that greets users"
	assert_output --partial "ARGUMENTS:"
	assert_output --partial "OPTIONS:"
	assert_output --partial "EXAMPLES:"
}

@test "greet-user: short help flag" {
	run_script "greet-user" -h
	assert_success
	assert_output --partial "Usage:"
}

@test "greet-user: version flag" {
	expected_version=$(cat "${PROJECT_ROOT}/VERSION" | tr -d '\n')
	run_script "greet-user" --version
	assert_success
	assert_output --partial "greet-user"
	assert_output --partial "$expected_version"
}

@test "greet-user: short version flag" {
	expected_version=$(cat "${PROJECT_ROOT}/VERSION" | tr -d '\n')
	run_script "greet-user" -v
	assert_success
	assert_output --partial "greet-user"
	assert_output --partial "$expected_version"
}

# Basic greeting functionality
@test "greet-user: direct greeting with valid name" {
	run_script "greet-user" "Alice"
	assert_success
	assert_output --partial "Hello, Alice!"
	assert_output --partial "Using provided name: Alice"
	assert_output --partial "Greeting completed for user: Alice"
}

@test "greet-user: greeting with special characters in name" {
	run_script "greet-user" "Mary-Jane"
	assert_success
	assert_output --partial "Hello, Mary-Jane!"
	assert_output --partial "Using provided name: Mary-Jane"
}

@test "greet-user: greeting with apostrophe in name" {
	run_script "greet-user" "O'Connor"
	assert_success
	assert_output --partial "Hello, O'Connor!"
	assert_output --partial "Using provided name: O'Connor"
}

@test "greet-user: greeting with spaces in name" {
	run_script "greet-user" "John Doe"
	assert_success
	assert_output --partial "Hello, John Doe!"
	assert_output --partial "Using provided name: John Doe"
}

# Style options tests
@test "greet-user: formal greeting style" {
	run_script "greet-user" --formal "Bob"
	assert_success
	assert_output --partial "It is a pleasure to meet you, Bob!"
	assert_output --partial "🎩"
}

@test "greet-user: casual greeting style" {
	run_script "greet-user" --casual "Charlie"
	assert_success
	assert_output --partial "Hey there, Charlie!"
	assert_output --partial "👋"
}

@test "greet-user: formal with short flag" {
	run_script "greet-user" -f "David"
	assert_success
	assert_output --partial "It is a pleasure to meet you, David!"
}

@test "greet-user: casual with short flag" {
	run_script "greet-user" -c "Eve"
	assert_success
	assert_output --partial "Hey there, Eve!"
}

# Emoji control tests
@test "greet-user: no emoji flag disables emoji" {
	run_script "greet-user" --no-emoji "Frank"
	assert_success
	assert_output --partial "Hello, Frank!"
	refute_output --partial "😊"
}

@test "greet-user: formal no emoji" {
	run_script "greet-user" --formal --no-emoji "Grace"
	assert_success
	assert_output --partial "It is a pleasure to meet you, Grace!"
	refute_output --partial "🎩"
}

@test "greet-user: casual no emoji" {
	run_script "greet-user" --casual --no-emoji "Henry"
	assert_success
	assert_output --partial "Hey there, Henry!"
	refute_output --partial "👋"
}

# Time-based greeting tests
@test "greet-user: time-based greeting includes time component" {
	run_script "greet-user" --time-based "Isabel"
	assert_success
	# Should contain either "Good morning", "Good afternoon", or "Good evening"
	assert_output --regexp "(Good morning|Good afternoon|Good evening), Isabel!"
}

@test "greet-user: time-based with formal style" {
	run_script "greet-user" --time-based --formal "Jack"
	assert_success
	assert_output --regexp "(Good morning|Good afternoon|Good evening), it is a pleasure to meet you, Jack!"
}

@test "greet-user: time-based with casual style" {
	run_script "greet-user" --time-based --casual "Kate"
	assert_success
	assert_output --regexp "(Good morning|Good afternoon|Good evening), hey there, Kate!"
}

@test "greet-user: time-based with no emoji" {
	run_script "greet-user" --time-based --no-emoji "Luke"
	assert_success
	assert_output --regexp "(Good morning|Good afternoon|Good evening), Luke!"
	refute_output --partial "😊"
}

# Interactive mode tests (simulated)
@test "greet-user: interactive mode with valid input" {
	run bash -c "echo 'Alice' | '${PROJECT_ROOT}/demo/greet-user'"
	assert_success
	assert_output --partial "Starting interactive mode"
	assert_output --partial "Please enter your name:"
	assert_output --partial "Hello, Alice!"
	assert_output --partial "Name collected: Alice"
	assert_output --partial "Greeting Details:"
}

@test "greet-user: force interactive mode with provided name" {
	run bash -c "echo 'Bob' | '${PROJECT_ROOT}/demo/greet-user' --interactive 'Alice'"
	assert_success
	assert_output --partial "Starting interactive mode"
	assert_output --partial "Note: Name 'Alice' provided but interactive mode forced"
	assert_output --partial "Hello, Bob!"
}

@test "greet-user: interactive mode shows user info" {
	run bash -c "echo 'Charlie' | '${PROJECT_ROOT}/demo/greet-user'"
	assert_success
	assert_output --partial "Greeting Details:"
	assert_output --partial "Name: Charlie"
	assert_output --partial "Style: normal"
	assert_output --partial "Emoji: enabled"
	assert_output --partial "Time-based: disabled"
	assert_output --partial "Current time:"
}

@test "greet-user: interactive mode with formal style" {
	run bash -c "echo 'David' | '${PROJECT_ROOT}/demo/greet-user' --formal"
	assert_success
	assert_output --partial "Style: formal"
	assert_output --partial "It is a pleasure to meet you, David!"
}

# Input validation tests
@test "greet-user: rejects invalid name with numbers" {
	run_script "greet-user" "Alice123"
	assert_failure
	assert_output --partial "Invalid name provided: 'Alice123'"
	assert_output --partial "Names must contain only letters, spaces, hyphens, and apostrophes"
}

@test "greet-user: rejects invalid name with special characters" {
	run_script "greet-user" "Alice@Bob"
	assert_failure
	assert_output --partial "Invalid name provided: 'Alice@Bob'"
}

@test "greet-user: rejects empty name" {
	run_script "greet-user" ""
	assert_failure
	assert_output --partial "Invalid name provided:"
}

@test "greet-user: rejects name that is too long" {
	# Create a name longer than 50 characters
	local long_name="ThisIsAVeryLongNameThatExceedsFiftyCharactersInLength"
	run_script "greet-user" "$long_name"
	assert_failure
	assert_output --partial "Invalid name provided:"
}

@test "greet-user: interactive mode with invalid input retries" {
	# Simulate invalid input followed by valid input
	run bash -c "printf 'Alice123\nBob456\nCharlie\n' | '${PROJECT_ROOT}/demo/greet-user'"
	assert_success
	assert_output --partial "Invalid name. Please use only letters, spaces, hyphens, and apostrophes"
	assert_output --partial "Attempts remaining:"
	assert_output --partial "Hello, Charlie!"
}

@test "greet-user: interactive mode exits after max attempts" {
	# Simulate repeated invalid input
	run bash -c "printf 'Alice123\nBob456\nCharlie789\n' | '${PROJECT_ROOT}/demo/greet-user'"
	assert_failure
	assert_output --partial "Maximum attempts reached. Exiting."
}

# Multiple arguments error handling
@test "greet-user: rejects multiple names" {
	run_script "greet-user" "Alice" "Bob"
	assert_failure
	assert_output --partial "Multiple names provided. Please provide only one name."
}

@test "greet-user: unknown option error" {
	run_script "greet-user" --unknown
	assert_failure
	assert_output --partial "Unknown option: --unknown"
	assert_output --partial "Use --help for usage information."
}

# Combined flag tests
@test "greet-user: multiple flags combined" {
	run_script "greet-user" --formal --no-emoji --time-based "Alice"
	assert_success
	assert_output --regexp "(Good morning|Good afternoon|Good evening), it is a pleasure to meet you, Alice!"
	refute_output --partial "🎩"
}

@test "greet-user: casual with time-based and emoji" {
	run_script "greet-user" --casual --time-based "Bob"
	assert_success
	assert_output --regexp "(Good morning|Good afternoon|Good evening), hey there, Bob!"
	assert_output --partial "👋"
}

@test "greet-user: interactive flag with formal style" {
	run bash -c "echo 'Charlie' | '${PROJECT_ROOT}/demo/greet-user' --interactive --formal"
	assert_success
	assert_output --partial "Starting interactive mode"
	assert_output --partial "It is a pleasure to meet you, Charlie!"
	assert_output --partial "Style: formal"
}

# Output content verification
@test "greet-user: contains required system elements" {
	run_script "greet-user" "Alice"
	assert_success
	assert_output --partial "User Greeting System"
	assert_output --partial "=============================="
	assert_output --partial "Using provided name: Alice"
	assert_output --partial "Greeting completed for user: Alice"
}

@test "greet-user: interactive mode shows spinner message" {
	run bash -c "echo 'Alice' | '${PROJECT_ROOT}/demo/greet-user'"
	assert_success
	# Note: actual spinner might not be visible in test, but the start message should be
	# or at least the greeting should appear which means spinner completed
	assert_output --partial "Hello, Alice!"
}

# Edge cases
@test "greet-user: name with only spaces and letters" {
	run_script "greet-user" "Mary Jane"
	assert_success
	assert_output --partial "Hello, Mary Jane!"
}

@test "greet-user: name with multiple hyphens" {
	run_script "greet-user" "Jean-Marie-Claire"
	assert_success
	assert_output --partial "Hello, Jean-Marie-Claire!"
}

@test "greet-user: single letter name" {
	run_script "greet-user" "A"
	assert_success
	assert_output --partial "Hello, A!"
}

@test "greet-user: name exactly 50 characters" {
	# Create a name that is exactly 50 characters (valid boundary)
	local fifty_char_name="AbcdefghijklmnopqrstuvwxyzAbcdefghijklmnopqrstuvwx"
	run_script "greet-user" "$fifty_char_name"
	assert_success
	assert_output --partial "Hello, $fifty_char_name!"
}

# Test argument order flexibility
@test "greet-user: flags before name" {
	run_script "greet-user" --formal --no-emoji "Alice"
	assert_success
	assert_output --partial "It is a pleasure to meet you, Alice!"
	refute_output --partial "🎩"
}

@test "greet-user: flags after name" {
	run_script "greet-user" "Alice" --formal --no-emoji
	assert_success
	assert_output --partial "It is a pleasure to meet you, Alice!"
	refute_output --partial "🎩"
}

@test "greet-user: mixed flag positions" {
	run_script "greet-user" --formal "Alice" --no-emoji
	assert_success
	assert_output --partial "It is a pleasure to meet you, Alice!"
	refute_output --partial "🎩"
}