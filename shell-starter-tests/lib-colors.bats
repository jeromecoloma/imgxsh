#!/usr/bin/env bats
#
# Tests for lib/colors.sh - color variables and constants

# Load test helpers
load test_helper
load bats-support/load
load bats-assert/load

@test "basic text colors are defined" {
    # Colors should be defined (either with values or empty strings)
    assert [ "${COLOR_BLACK+defined}" = "defined" ]
    assert [ "${COLOR_RED+defined}" = "defined" ]
    assert [ "${COLOR_GREEN+defined}" = "defined" ]
    assert [ "${COLOR_YELLOW+defined}" = "defined" ]
    assert [ "${COLOR_BLUE+defined}" = "defined" ]
    assert [ "${COLOR_MAGENTA+defined}" = "defined" ]
    assert [ "${COLOR_CYAN+defined}" = "defined" ]
    assert [ "${COLOR_WHITE+defined}" = "defined" ]
}

@test "bright text colors are defined" {
    # Colors should be defined (either with values or empty strings)
    assert [ "${COLOR_BRIGHT_BLACK+defined}" = "defined" ]
    assert [ "${COLOR_BRIGHT_RED+defined}" = "defined" ]
    assert [ "${COLOR_BRIGHT_GREEN+defined}" = "defined" ]
    assert [ "${COLOR_BRIGHT_YELLOW+defined}" = "defined" ]
    assert [ "${COLOR_BRIGHT_BLUE+defined}" = "defined" ]
    assert [ "${COLOR_BRIGHT_MAGENTA+defined}" = "defined" ]
    assert [ "${COLOR_BRIGHT_CYAN+defined}" = "defined" ]
    assert [ "${COLOR_BRIGHT_WHITE+defined}" = "defined" ]
}

@test "text formatting codes are defined" {
    # Colors should be defined (either with values or empty strings)
    assert [ "${COLOR_BOLD+defined}" = "defined" ]
    assert [ "${COLOR_DIM+defined}" = "defined" ]
    assert [ "${COLOR_UNDERLINE+defined}" = "defined" ]
    assert [ "${COLOR_BLINK+defined}" = "defined" ]
    assert [ "${COLOR_REVERSE+defined}" = "defined" ]
}

@test "reset code is defined" {
    # Reset code should be defined (either with value or empty string)
    assert [ "${COLOR_RESET+defined}" = "defined" ]
}

@test "semantic colors are defined" {
    # Semantic colors should be defined (either with values or empty strings)
    assert [ "${COLOR_INFO+defined}" = "defined" ]
    assert [ "${COLOR_SUCCESS+defined}" = "defined" ]
    assert [ "${COLOR_WARNING+defined}" = "defined" ]
    assert [ "${COLOR_ERROR+defined}" = "defined" ]
    assert [ "${COLOR_DEBUG+defined}" = "defined" ]
}

@test "color codes have correct ANSI sequences" {
    # Only test ANSI sequences if colors are enabled
    if colors::has_color; then
        # Test basic colors
        assert_equal "$COLOR_RED" '\033[0;31m'
        assert_equal "$COLOR_GREEN" '\033[0;32m'
        assert_equal "$COLOR_BLUE" '\033[0;34m'

        # Test bright colors
        assert_equal "$COLOR_BRIGHT_RED" '\033[1;31m'
        assert_equal "$COLOR_BRIGHT_GREEN" '\033[1;32m'

        # Test formatting
        assert_equal "$COLOR_BOLD" '\033[1m'
        assert_equal "$COLOR_RESET" '\033[0m'
    else
        # In no-color environment, variables should be empty
        assert_equal "$COLOR_RED" ''
        assert_equal "$COLOR_GREEN" ''
        assert_equal "$COLOR_BLUE" ''
        assert_equal "$COLOR_BRIGHT_RED" ''
        assert_equal "$COLOR_BRIGHT_GREEN" ''
        assert_equal "$COLOR_BOLD" ''
        assert_equal "$COLOR_RESET" ''
    fi
}

@test "semantic colors map to correct base colors" {
    assert_equal "$COLOR_INFO" "$COLOR_BLUE"
    assert_equal "$COLOR_SUCCESS" "$COLOR_GREEN"
    assert_equal "$COLOR_WARNING" "$COLOR_YELLOW"
    assert_equal "$COLOR_ERROR" "$COLOR_RED"
    assert_equal "$COLOR_DEBUG" "$COLOR_MAGENTA"
}

@test "color variables are readonly" {
    # Test that color variables cannot be modified
    run bash -c "source $PROJECT_ROOT/lib/colors.sh; COLOR_RED='modified'; echo \$COLOR_RED"
    assert_failure
}

@test "colors work in terminal output" {
    # Test that colors produce expected output format
    run bash -c "source $PROJECT_ROOT/lib/colors.sh; printf \"\${COLOR_RED}red text\${COLOR_RESET}\""
    assert_success
    assert_output --partial "red text"

    # Should contain ANSI escape sequences only if colors are enabled
    if bash -c "source $PROJECT_ROOT/lib/colors.sh; colors::has_color"; then
        assert_output --partial $'['
    else
        # In no-color environment, should not contain escape sequences
        refute_output --partial $'['
    fi
}