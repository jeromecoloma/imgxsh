#!/usr/bin/env bats
#
# Tests for JSON color formatting functions in lib/colors.sh

# Load test helpers
load test_helper
load bats-support/load
load bats-assert/load

@test "colors::json_key function formats keys correctly" {
	# Test JSON key formatting with colors
	run bash -c "source $PROJECT_ROOT/lib/colors.sh && colors::json_key 'testkey'"
	assert_success
	assert_output --partial "testkey"
	assert_output --partial '"'

	# Test with NO_COLOR (should still have quotes but no color codes)
	run bash -c "NO_COLOR=1 source $PROJECT_ROOT/lib/colors.sh && colors::json_key 'testkey'"
	assert_success
	assert_output --partial "testkey"
	assert_output --partial '"'
}

@test "colors::json_string function formats string values correctly" {
	# Test JSON string formatting with colors
	run bash -c "source $PROJECT_ROOT/lib/colors.sh && colors::json_string 'test value'"
	assert_success
	assert_output --partial "test value"
	assert_output --partial '"'

	# Test with NO_COLOR
	run bash -c "NO_COLOR=1 source $PROJECT_ROOT/lib/colors.sh && colors::json_string 'test value'"
	assert_success
	assert_output --partial "test value"
}

@test "colors::json_number function formats numbers correctly" {
	# Test JSON number formatting with colors
	run bash -c "source $PROJECT_ROOT/lib/colors.sh && colors::json_number '42'"
	assert_success
	assert_output --partial "42"

	# Test with decimal number
	run bash -c "source $PROJECT_ROOT/lib/colors.sh && colors::json_number '3.14'"
	assert_success
	assert_output --partial "3.14"

	# Test with NO_COLOR
	run bash -c "NO_COLOR=1 source $PROJECT_ROOT/lib/colors.sh && colors::json_number '42'"
	assert_success
	assert_output "42"
}

@test "colors::json_boolean function formats boolean values correctly" {
	# Test JSON boolean true formatting
	run bash -c "source $PROJECT_ROOT/lib/colors.sh && colors::json_boolean 'true'"
	assert_success
	assert_output --partial "true"

	# Test JSON boolean false formatting
	run bash -c "source $PROJECT_ROOT/lib/colors.sh && colors::json_boolean 'false'"
	assert_success
	assert_output --partial "false"

	# Test with NO_COLOR
	run bash -c "NO_COLOR=1 source $PROJECT_ROOT/lib/colors.sh && colors::json_boolean 'true'"
	assert_success
	assert_output "true"
}

@test "colors::json_null function formats null correctly" {
	# Test JSON null formatting
	run bash -c "source $PROJECT_ROOT/lib/colors.sh && colors::json_null"
	assert_success
	assert_output --partial "null"

	# Test with NO_COLOR
	run bash -c "NO_COLOR=1 source $PROJECT_ROOT/lib/colors.sh && colors::json_null"
	assert_success
	assert_output "null"
}

@test "colors::json_structure function formats structural characters correctly" {
	# Test structural character formatting
	run bash -c "source $PROJECT_ROOT/lib/colors.sh && colors::json_structure '{'"
	assert_success
	assert_output --partial "{"

	run bash -c "source $PROJECT_ROOT/lib/colors.sh && colors::json_structure '}'"
	assert_success
	assert_output --partial "}"

	run bash -c "source $PROJECT_ROOT/lib/colors.sh && colors::json_structure '['"
	assert_success
	assert_output --partial "["

	run bash -c "source $PROJECT_ROOT/lib/colors.sh && colors::json_structure ']'"
	assert_success
	assert_output --partial "]"

	# Test with NO_COLOR
	run bash -c "NO_COLOR=1 source $PROJECT_ROOT/lib/colors.sh && colors::json_structure '{'"
	assert_success
	assert_output "{"
}

@test "colors::json_syntax function formats complete JSON correctly" {
	# Create a test JSON string
	local test_json='{"name": "test", "value": 42, "active": true, "data": null}'

	# Test complete JSON syntax highlighting
	run bash -c "source $PROJECT_ROOT/lib/colors.sh && colors::json_syntax '$test_json'"
	assert_success
	assert_output --partial "name"
	assert_output --partial "test"
	assert_output --partial "42"
	assert_output --partial "true"
	assert_output --partial "null"

	# Test with NO_COLOR - should return original JSON
	run bash -c "NO_COLOR=1 source $PROJECT_ROOT/lib/colors.sh && colors::json_syntax '$test_json'"
	assert_success
	assert_output "$test_json"
}

@test "colors::json_syntax function handles multiline JSON correctly" {
	# Create a multiline test JSON string
	local test_json=$'{\n  "name": "test",\n  "value": 42,\n  "active": true\n}'

	# Test multiline JSON syntax highlighting
	run bash -c "source $PROJECT_ROOT/lib/colors.sh && colors::json_syntax '$test_json'"
	assert_success
	assert_output --partial "name"
	assert_output --partial "test"
	assert_output --partial "42"
	assert_output --partial "true"

	# Should preserve line structure
	run bash -c "source $PROJECT_ROOT/lib/colors.sh && colors::json_syntax '$test_json' | wc -l"
	assert_success
	assert_output "4"
}

@test "colors::json_syntax function handles nested JSON correctly" {
	# Create a nested test JSON string
	local test_json='{"user": {"name": "John", "age": 30}, "items": [1, 2, 3]}'

	# Test nested JSON syntax highlighting
	run bash -c "source $PROJECT_ROOT/lib/colors.sh && colors::json_syntax '$test_json'"
	assert_success
	assert_output --partial "user"
	assert_output --partial "name"
	assert_output --partial "John"
	assert_output --partial "age"
	assert_output --partial "30"
	assert_output --partial "items"
}

@test "colors::json_syntax function handles arrays correctly" {
	# Create a JSON array
	local test_json='[{"id": 1}, {"id": 2}, {"id": 3}]'

	# Test array JSON syntax highlighting
	run bash -c "source $PROJECT_ROOT/lib/colors.sh && colors::json_syntax '$test_json'"
	assert_success
	assert_output --partial "id"
	assert_output --partial "1"
	assert_output --partial "2"
	assert_output --partial "3"
}

@test "colors::json_syntax function handles special characters correctly" {
	# Create JSON with special characters
	local test_json='{"message": "Hello \"World\"!", "path": "/home/user"}'

	# Test JSON with escaped quotes and special characters
	run bash -c "source $PROJECT_ROOT/lib/colors.sh && colors::json_syntax '$test_json'"
	assert_success
	assert_output --partial "message"
	assert_output --partial "Hello"
	assert_output --partial "path"
}

@test "colors::json_syntax function respects color support detection" {
	local test_json='{"test": "value"}'

	# Test with colors enabled
	if colors::has_color; then
		run bash -c "source $PROJECT_ROOT/lib/colors.sh && colors::json_syntax '$test_json'"
		assert_success
		# Should contain ANSI escape sequences if colors are supported
		if [[ "${NO_COLOR:-}" == "" ]]; then
			assert_output --partial $'['
		fi
	fi

	# Test with colors disabled via terminal detection
	run bash -c "TERM=dumb source $PROJECT_ROOT/lib/colors.sh && colors::json_syntax '$test_json'"
	assert_success
	# Should not contain ANSI escape sequences
	assert_output "$test_json"
}

@test "JSON color functions work in demo scripts" {
	# Test that demo scripts can use JSON color functions
	run bash -c "source $PROJECT_ROOT/lib/main.sh && colors::json_syntax '{\"status\": \"ok\"}'"
	assert_success
	assert_output --partial "status"
	assert_output --partial "ok"
}