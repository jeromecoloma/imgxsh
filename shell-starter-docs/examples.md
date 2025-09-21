# Shell Starter - Script Examples

This document provides detailed examples and usage patterns for Shell Starter scripts. Use these examples as templates for creating new scripts or understanding existing ones.

## 📂 Directory Structure Note

Shell Starter organizes scripts into two main directories:

- **`demo/`** - Example scripts for learning Shell Starter features and conventions
- **`bin/`** - Core utility scripts that are part of Shell Starter's functionality

The examples in this document are primarily from the `demo/` directory, showing how to build CLI tools using Shell Starter patterns. The core utilities in `bin/` (like `generate-ai-workflow`, `bump-version`, `update-shell-starter`) demonstrate advanced patterns for production tools.

**Important**: All example scripts shown below are located in the `demo/` directory, not `bin/`. The `bin/` directory contains production utilities that come with Shell Starter itself.

**Note**: The actual scripts in the `demo/` directory have been enhanced beyond the basic examples shown in this documentation. The real scripts include features like banner headers, background update notifications, comprehensive argument parsing with `parse_common_args`, and standardized help formatting. The examples below demonstrate the core patterns and functionality, but refer to the actual files in `demo/` for the complete, current implementations with all modern Shell Starter features.

## 🎯 Basic Script Examples

### 1. Hello World Script

The simplest possible Shell Starter script:

```bash
#!/bin/bash

# hello-world - A simple greeting script
# Demonstrates basic library usage and argument parsing

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SHELL_STARTER_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

source "${SHELL_STARTER_ROOT}/lib/main.sh"

show_help() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS] [NAME]

A simple greeting script that demonstrates Shell Starter features.

ARGUMENTS:
    NAME              Name to greet (default: World)

OPTIONS:
    -h, --help        Show this help message and exit
    -v, --version     Show version information and exit
    -q, --quiet       Suppress colorful output

EXAMPLES:
    $(basename "$0")                    # Greets "World"
    $(basename "$0") Alice              # Greets "Alice"
    $(basename "$0") --quiet Bob        # Greets "Bob" without colors
EOF
}

main() {
    local name="World"
    local quiet=false
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -v|--version)
                echo "$(basename "$0") $(get_version)"
                exit 0
                ;;
            -q|--quiet)
                quiet=true
                shift
                ;;
            -*)
                log::error "Unknown option: $1"
                show_help
                exit 1
                ;;
            *)
                name="$1"
                shift
                ;;
        esac
    done
    
    # Main logic
    if [[ "$quiet" == true ]]; then
        echo "Hello, $name!"
    else
        log::success "Hello, $name!"
        log::info "Welcome to Shell Starter!"
    fi
}

main "$@"
```

### 2. Color Showcase Script

Demonstrates all available colors and logging functions:

```bash
#!/bin/bash

# show-colors - Demonstrates Shell Starter color and logging capabilities
# This script showcases all available colors and logging functions

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SHELL_STARTER_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

source "${SHELL_STARTER_ROOT}/lib/main.sh"

main() {
    echo "${COLOR_BOLD}${COLOR_CYAN}Shell Starter - Color Library Showcase${COLOR_RESET}"
    echo "=========================================="

    echo "${COLOR_BOLD}Basic Colors:${COLOR_RESET}"
    echo "  ${COLOR_BLACK}COLOR_BLACK${COLOR_RESET}     - Black text"
    echo "  ${COLOR_RED}COLOR_RED${COLOR_RESET}       - Red text"
    echo "  ${COLOR_GREEN}COLOR_GREEN${COLOR_RESET}     - Green text"
    # ... more color examples

    echo
    echo "${COLOR_BOLD}${COLOR_UNDERLINE}Logging Function Examples:${COLOR_RESET}"
    echo

    log::success "✓ Success: Operation completed successfully!"
    log::warn "⚠ Warning: This is a warning message"
    log::error "✗ Error: Something went wrong"
    log::info "ℹ Info: Here's some information"
    log::debug "🐛 Debug: Debugging information"

    echo
    echo "${COLOR_BOLD}${COLOR_UNDERLINE}Enhanced Color Features:${COLOR_RESET}"
    echo

    # Demonstrate JSON syntax highlighting
    echo "${COLOR_BOLD}JSON Syntax Highlighting:${COLOR_RESET}"
    local sample_json='{"name": "Shell Starter", "version": "1.0.0", "active": true, "count": 42, "data": null}'
    colors::json_syntax "$sample_json"

    echo
    echo "${COLOR_BOLD}Visual Status Indicators:${COLOR_RESET}"
    echo "  ✓ Success indicator with colors"
    echo "  ✗ Error indicator with colors"
    echo "  ⚠ Warning indicator with colors"
    echo "  ℹ Info indicator with colors"
    echo "  → Progress indicator with colors"
}

main "$@"
```

### 3. Long-Running Task with Spinner

Shows how to use spinners for user feedback:

```bash
#!/bin/bash

# long-task - Demonstrates spinner usage for long-running operations
# This script simulates various long-running tasks with progress feedback

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SHELL_STARTER_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

source "${SHELL_STARTER_ROOT}/lib/main.sh"

simulate_task() {
    local task_name="$1"
    local duration="$2"
    
    log::info "Starting: $task_name"
    spinner::start "$task_name"
    
    sleep "$duration"
    
    spinner::stop
    log::success "Completed: $task_name"
}

main() {
    log::info "Demonstrating spinner functionality..."
    echo
    
    simulate_task "Downloading files" 2
    simulate_task "Processing data" 3
    simulate_task "Uploading results" 1
    
    echo
    log::success "All tasks completed successfully!"
}

main "$@"
```

### 3. Banner Showcase Script

Demonstrates the Shell Starter banner system with gradient colors and multiple styles:

```bash
#!/bin/bash

# show-banner - Demonstrates Shell Starter banner system with multiple styles
# This script showcases the visual branding capabilities including gradient colors,
# multiple banner styles, and terminal compatibility detection

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SHELL_STARTER_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

source "${SHELL_STARTER_ROOT}/lib/main.sh"

show_help() {
    # Show banner header for help
    banner::shell_starter minimal
    cat <<EOF
Usage: $(basename "$0") [OPTIONS] [STYLE]

Demonstrates the Shell Starter banner system with gradient colors and multiple styles.

ARGUMENTS:
    STYLE             Banner style to display (block, ascii, minimal, all)
                      Default: all

OPTIONS:
    -h, --help        Show this help message and exit
    -v, --version     Show version information and exit
    --update          Check for available updates
    --check-version   Show detailed version status and check for updates
    --notify-config   Configure update notification settings
    --uninstall       Remove Shell Starter installation
    --no-info         Skip terminal compatibility information
    --debug           Show terminal environment debug information
    --plain           Force plain text output (no colors)

STYLES:
    block            Unicode block characters with gradient (default style)
    pixel            Alias for block style
    ascii            Traditional ASCII art with gradient
    minimal          Simple bullet-point design with gradient
    all              Show all available styles

EXAMPLES:
    $(basename "$0")              # Show all banner styles with info
    $(basename "$0") block        # Show only block style banner
    $(basename "$0") ascii        # Show only ASCII art banner
    $(basename "$0") --debug      # Show banners with debug info
    $(basename "$0") --plain      # Show banners without colors
    $(basename "$0") --no-info    # Show banners without compatibility info
EOF
}

show_terminal_info() {
    echo -e "${COLOR_BOLD}${COLOR_CYAN}Terminal Compatibility Information:${COLOR_RESET}"
    echo "=============================================="
    echo "TERM: ${TERM:-unset}"
    echo "COLORTERM: ${COLORTERM:-unset}"
    echo "TERM_PROGRAM: ${TERM_PROGRAM:-unset}"
    echo "NO_COLOR: ${NO_COLOR:-unset}"
    echo
    echo "Detected capabilities:"
    echo "  Output is terminal: $(colors::is_terminal && echo "yes" || echo "no")"
    echo "  Has truecolor: $(colors::has_truecolor && echo "yes" || echo "no")"
    echo "  Has 256color: $(colors::has_256color && echo "yes" || echo "no")"
    echo "  Has basic color: $(colors::has_color && echo "yes" || echo "no")"
    echo
}

display_banner() {
    local style="$1"
    local show_info="$2"

    echo -e "${COLOR_BOLD}${COLOR_YELLOW}$(echo "$style" | tr '[:lower:]' '[:upper:]') STYLE:${COLOR_RESET}"
    echo "=================================="

    if [[ "$show_info" == "true" ]]; then
        show_style_info "$style"
        echo
    fi

    banner::shell_starter "$style"
    echo
}

main() {
    local style="all"
    local show_info=true
    local show_debug=false
    local force_plain=false

    # Enable optional background update notifications
    enable_background_updates

    while [[ $# -gt 0 ]]; do
        case $1 in
        --no-info)
            show_info=false
            shift
            ;;
        --debug)
            show_debug=true
            shift
            ;;
        --plain)
            force_plain=true
            export NO_COLOR=1
            shift
            ;;
        --help | -h | --version | -v | --update | --check-version | --notify-config | --uninstall)
            parse_common_args "$(basename "$0")" "$@"
            ;;
        -*)
            log::error "Unknown option: $1"
            echo "Use --help for usage information."
            exit 1
            ;;
        *)
            # Validate style argument
            case "$1" in
            "block" | "pixel" | "ascii" | "minimal" | "all")
                style="$1"
                ;;
            *)
                log::error "Invalid style: $1"
                echo "Valid styles: block, pixel, ascii, minimal, all"
                echo "Use --help for usage information."
                exit 1
                ;;
            esac
            shift
            ;;
        esac
    done

    # Welcome banner for the script
    banner::shell_starter minimal
    echo -e "${COLOR_BOLD}${COLOR_MAGENTA}Banner System Showcase${COLOR_RESET}"
    echo "======================"
    echo

    if [[ "$show_debug" == "true" ]]; then
        colors::debug_terminal
        echo
    elif [[ "$show_info" == "true" ]]; then
        show_terminal_info
    fi

    case "$style" in
    "all")
        display_all_banners "$show_info"
        ;;
    *)
        display_banner "$style" "$show_info"
        ;;
    esac

    echo -e "${COLOR_BOLD}Banner Features:${COLOR_RESET}"
    echo "• Gradient color implementation with RGB support"
    echo "• Multiple styles: Block/Pixel, ASCII Art, and Minimalist"
    echo "• Terminal compatibility detection and fallback"
    echo "• NO_COLOR environment variable support"
    echo "• Graceful degradation for all terminal types"
    echo

    log::info "Banner demonstration completed"
}

main "$@"
```

### 4. Debug Colors Script

Simple utility for debugging color support in terminals:

```bash
#!/bin/bash

# debug-colors - Debug color support in the current terminal
# This script helps identify why colors might not be displaying correctly

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SHELL_STARTER_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

source "${SHELL_STARTER_ROOT}/lib/main.sh"

echo "=== Terminal Color Debug Information ==="
echo
echo "Basic environment:"
echo "  TERM: ${TERM:-unset}"
echo "  COLORTERM: ${COLORTERM:-unset}"
echo "  TERM_PROGRAM: ${TERM_PROGRAM:-unset}"
echo "  NO_COLOR: ${NO_COLOR:-unset}"
echo
echo "Detection results:"
echo "  Output is terminal: $(colors::is_terminal && echo "yes" || echo "no")"
echo "  Has truecolor: $(colors::has_truecolor && echo "yes" || echo "no")"
echo "  Has 256color: $(colors::has_256color && echo "yes" || echo "no")"
echo "  Has basic color: $(colors::has_color && echo "yes" || echo "no")"
echo

echo "Color test (if you see color names in color, your terminal works):"
echo -e "  ${COLOR_RED}RED${COLOR_RESET}"
echo -e "  ${COLOR_GREEN}GREEN${COLOR_RESET}"
echo -e "  ${COLOR_BLUE}BLUE${COLOR_RESET}"
echo -e "  ${COLOR_YELLOW}YELLOW${COLOR_RESET}"
echo -e "  ${COLOR_CYAN}CYAN${COLOR_RESET}"
echo -e "  ${COLOR_MAGENTA}MAGENTA${COLOR_RESET}"
echo

echo "Raw color codes (should show literal escape codes):"
printf "  RED: '%s'\n" "$COLOR_RED"
printf "  RESET: '%s'\n" "$COLOR_RESET"
echo

echo "If colors appear as literal text like [0;31m instead of actual colors,"
echo "your terminal may not support ANSI colors or colors may be disabled."
echo "Try:"
echo "  - Using a different terminal (iTerm2, Terminal.app, etc.)"
echo "  - Checking if NO_COLOR environment variable is set"
echo "  - Running: export TERM=xterm-256color"
```

### 5. Update Management Tool

Comprehensive demonstration of update management features:

```bash
#!/bin/bash

# update-tool - Comprehensive update management demonstration
# This script showcases all Shell Starter update management features

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SHELL_STARTER_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

source "${SHELL_STARTER_ROOT}/lib/main.sh"

show_help() {
    # Show banner header for help
    banner::shell_starter minimal
    cat <<EOF
Usage: $(basename "$0") [OPTIONS] [COMMAND]

A comprehensive tool demonstrating Shell Starter's update management system.

COMMANDS:
    check               Check for available updates (default)
    status              Show detailed version status and configuration
    config              Manage update notification settings
    install <version>   Install a specific version (demonstration)
    history             Show release history

OPTIONS:
    -h, --help          Show this help message and exit
    -v, --version       Show version information and exit
    --update            Check for available updates
    --check-version     Show detailed version status and check for updates
    --notify-config     Configure update notification settings
    --uninstall         Remove Shell Starter installation
    -q, --quiet         Suppress colorful output
    --verbose           Show detailed operation information

UPDATE NOTIFICATION COMMANDS:
    config enable       Enable automatic update notifications
    config disable      Disable automatic update notifications
    config interval <hours>  Set check interval in hours
    config quiet <on|off>    Enable/disable quiet notifications
    config status       Show current notification configuration

EXAMPLES:
    $(basename "$0")                    # Check for updates
    $(basename "$0") status             # Show detailed status
    $(basename "$0") config enable      # Enable notifications
    $(basename "$0") config interval 12 # Check every 12 hours
    $(basename "$0") history            # Show release history
EOF
}

cmd_check() {
    log::info "Checking for available updates..."

    # Simulate update check
    spinner::start "Contacting update server"
    sleep 2
    spinner::stop

    log::success "Update check completed"
    echo "Current version: $(get_version)"
    echo "Latest version:  1.2.0"
    echo "Status: Update available"
    echo
    log::info "Run '$(basename "$0") install 1.2.0' to update"
}

cmd_status() {
    log::info "Version Status Information"
    echo "=========================="
    echo "Current version: $(get_version)"
    echo "Shell Starter version: $(get_shell_starter_version)"
    echo "Update notifications: $(update::get_notification_status)"
    echo "Check interval: $(update::get_check_interval) hours"
    echo "Last check: $(update::get_last_check_time)"
    echo
}

cmd_config() {
    local subcommand="${1:-status}"
    case "$subcommand" in
        enable)
            log::info "Enabling update notifications..."
            update::enable_notifications
            log::success "Update notifications enabled"
            ;;
        disable)
            log::info "Disabling update notifications..."
            update::disable_notifications
            log::success "Update notifications disabled"
            ;;
        status)
            cmd_status
            ;;
        *)
            log::error "Unknown config command: $subcommand"
            echo "Valid commands: enable, disable, status"
            exit 1
            ;;
    esac
}

cmd_install() {
    local version="${1:-}"
    if [[ -z "$version" ]]; then
        log::error "Version required for install command"
        echo "Usage: $(basename "$0") install <version>"
        exit 1
    fi

    log::info "Installing version $version..."
    spinner::start "Downloading and installing"
    sleep 3
    spinner::stop
    log::success "Version $version installed successfully"
}

cmd_history() {
    log::info "Release History"
    echo "==============="
    echo "v1.2.0 - 2024-01-15 - Added banner system and enhanced colors"
    echo "v1.1.0 - 2024-01-10 - Improved update management"
    echo "v1.0.0 - 2024-01-01 - Initial release"
}

main() {
    local command="check"
    local verbose=false
    local quiet=false

    # Enable optional background update notifications
    enable_background_updates

    while [[ $# -gt 0 ]]; do
        case $1 in
        --verbose)
            verbose=true
            shift
            ;;
        -q|--quiet)
            quiet=true
            shift
            ;;
        --help | -h | --version | -v | --update | --check-version | --notify-config | --uninstall)
            parse_common_args "$(basename "$0")" "$@"
            ;;
        -*)
            log::error "Unknown option: $1"
            echo "Use --help for usage information."
            exit 1
            ;;
        *)
            command="$1"
            shift
            break
            ;;
        esac
    done

    case "$command" in
    check)
        cmd_check
        ;;
    status)
        cmd_status
        ;;
    config)
        cmd_config "$@"
        ;;
    install)
        cmd_install "$@"
        ;;
    history)
        cmd_history
        ;;
    *)
        log::error "Unknown command: $command"
        echo "Use --help for usage information."
        exit 1
        ;;
    esac
}

main "$@"
```

## 🔧 Advanced Script Patterns

### 6. Interactive User Input Script

Demonstrates input validation and interactive prompts:

```bash
#!/bin/bash

# greet-user - Interactive script with user input validation
# Shows advanced argument parsing and user interaction patterns

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SHELL_STARTER_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

source "${SHELL_STARTER_ROOT}/lib/main.sh"

# Global configuration
GREETING_STYLE="casual"
USE_EMOJI=true
TIME_BASED=false

get_user_input() {
    local prompt="$1"
    local default="$2"
    local result
    
    if [[ -n "$default" ]]; then
        read -p "$prompt [$default]: " result
        result="${result:-$default}"
    else
        read -p "$prompt: " result
    fi
    
    echo "$result"
}

validate_name() {
    local name="$1"
    
    if [[ -z "$name" ]]; then
        log::error "Name cannot be empty"
        return 1
    fi
    
    if [[ ${#name} -lt 2 ]]; then
        log::error "Name must be at least 2 characters long"
        return 1
    fi
    
    if [[ ! "$name" =~ ^[A-Za-z][A-Za-z\ ]*$ ]]; then
        log::error "Name can only contain letters and spaces"
        return 1
    fi
    
    return 0
}

format_greeting() {
    local name="$1"
    local greeting
    
    case "$GREETING_STYLE" in
        formal)
            greeting="Good day, $name."
            ;;
        casual)
            greeting="Hey there, $name!"
            ;;
        *)
            greeting="Hello, $name!"
            ;;
    esac
    
    if [[ "$USE_EMOJI" == true ]]; then
        case "$GREETING_STYLE" in
            formal)
                greeting="🎩 $greeting"
                ;;
            casual)
                greeting="👋 $greeting"
                ;;
            *)
                greeting="😊 $greeting"
                ;;
        esac
    fi
    
    if [[ "$TIME_BASED" == true ]]; then
        local hour
        hour=$(date +%H)
        local time_greeting
        
        if (( hour < 12 )); then
            time_greeting="Good morning"
        elif (( hour < 17 )); then
            time_greeting="Good afternoon"
        else
            time_greeting="Good evening"
        fi
        
        greeting="$time_greeting! $greeting"
    fi
    
    echo "$greeting"
}

main() {
    local name=""
    local interactive=false
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -v|--version)
                echo "$(basename "$0") $(get_version)"
                exit 0
                ;;
            -i|--interactive)
                interactive=true
                shift
                ;;
            -f|--formal)
                GREETING_STYLE="formal"
                shift
                ;;
            -c|--casual)
                GREETING_STYLE="casual"
                shift
                ;;
            --no-emoji)
                USE_EMOJI=false
                shift
                ;;
            --time-based)
                TIME_BASED=true
                shift
                ;;
            -*)
                log::error "Unknown option: $1"
                show_help
                exit 1
                ;;
            *)
                name="$1"
                shift
                ;;
        esac
    done
    
    # Get name interactively if not provided or if interactive mode
    if [[ -z "$name" ]] || [[ "$interactive" == true ]]; then
        log::info "Interactive greeting mode"
        
        while true; do
            name=$(get_user_input "Enter your name" "")
            
            if validate_name "$name"; then
                break
            fi
            
            log::warn "Please try again with a valid name"
        done
    fi
    
    # Generate and display greeting
    local greeting
    greeting=$(format_greeting "$name")
    
    log::success "$greeting"
}

main "$@"
```

### 7. Multi-Command Dispatcher

Pattern for creating git-like subcommand interfaces:

```bash
#!/bin/bash

# my-cli - Multi-command CLI demonstrating subcommand patterns
# This script shows how to create git-like subcommand interfaces

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SHELL_STARTER_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

source "${SHELL_STARTER_ROOT}/lib/main.sh"

show_help() {
    cat << EOF
Usage: $(basename "$0") <command> [options]

A multi-command CLI tool demonstrating Shell Starter patterns.

COMMANDS:
    status          Show system status information
    config          Manage configuration settings
    deploy          Deploy applications or services
    backup          Create and manage backups
    monitor         System monitoring utilities

Use '$(basename "$0") <command> --help' for command-specific help.

EXAMPLES:
    $(basename "$0") status
    $(basename "$0") config list
    $(basename "$0") deploy --env prod app1
EOF
}

# Status command
cmd_status() {
    local verbose=false
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            -v|--verbose)
                verbose=true
                shift
                ;;
            -h|--help)
                status_help
                exit 0
                ;;
            *)
                log::error "Unknown option: $1"
                status_help
                exit 1
                ;;
        esac
    done
    
    log::info "Gathering system status information..."
    echo "${COLOR_BOLD}${COLOR_CYAN}System Status${COLOR_RESET}"
    echo "================================"
    printf "  ${COLOR_GREEN}Hostname:${COLOR_RESET} %s\n" "$(hostname)"
    printf "  ${COLOR_GREEN}Timestamp:${COLOR_RESET} %s\n" "$(date)"
    printf "  ${COLOR_GREEN}Uptime:${COLOR_RESET} %s\n" "$(uptime | awk -F'up ' '{print $2}' | awk -F', [0-9]* users' '{print $1}')"
    printf "  ${COLOR_GREEN}Load Average:${COLOR_RESET} %s\n" "$(uptime | awk -F'load average: ' '{print $2}')"
    
    if [[ "$verbose" == true ]]; then
        echo
        log::info "Detailed system information..."
        printf "  ${COLOR_GREEN}System:${COLOR_RESET} %s\n" "$(uname -s)"
        printf "  ${COLOR_GREEN}Release:${COLOR_RESET} %s\n" "$(uname -r)"
        printf "  ${COLOR_GREEN}Architecture:${COLOR_RESET} %s\n" "$(uname -m)"
    fi
    
    log::success "Status check completed"
}

# Configuration management subcommands
cmd_config() {
    case "${1:-}" in
        get)
            shift
            config_get "$@"
            ;;
        set)
            shift
            config_set "$@"
            ;;
        list|ls)
            shift
            config_list "$@"
            ;;
        --help|-h|help|"")
            config_help
            ;;
        *)
            log::error "Unknown config command: $1"
            config_help
            exit 1
            ;;
    esac
}

config_get() {
    local key="${1:-}"
    
    if [[ -z "$key" ]]; then
        log::error "Configuration key required"
        exit 1
    fi
    
    log::info "Getting configuration for: $key"
    echo "value_for_$key"
}

config_set() {
    local key="${1:-}"
    local value="${2:-}"
    
    if [[ -z "$key" ]] || [[ -z "$value" ]]; then
        log::error "Both key and value required"
        echo "Usage: $(basename "$0") config set <key> <value>"
        exit 1
    fi
    
    log::info "Setting $key = $value"
    log::success "Configuration updated"
}

config_list() {
    log::info "Current configuration:"
    echo "setting1 = value1"
    echo "setting2 = value2"
    echo "setting3 = value3"
}

config_help() {
    cat << EOF
Usage: $(basename "$0") config <subcommand> [options]

Configuration management commands.

SUBCOMMANDS:
    get <key>        Get configuration value
    set <key> <value> Set configuration value
    list, ls         List all configuration
    help             Show this help

EXAMPLES:
    $(basename "$0") config get timeout
    $(basename "$0") config set timeout 30
    $(basename "$0") config list
EOF
}

# Status command
cmd_status() {
    local verbose=false
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            -v|--verbose)
                verbose=true
                shift
                ;;
            -h|--help)
                status_help
                exit 0
                ;;
            *)
                log::error "Unknown option: $1"
                status_help
                exit 1
                ;;
        esac
    done
    
    log::info "System Status"
    echo "✓ Service A: Running"
    echo "✓ Service B: Running"
    echo "⚠ Service C: Warning"
    
    if [[ "$verbose" == true ]]; then
        echo
        log::info "Detailed Status:"
        echo "  Service A: Uptime 5 days, Memory 45%"
        echo "  Service B: Uptime 2 days, Memory 32%"
        echo "  Service C: Uptime 1 hour, Memory 78%"
    fi
}

status_help() {
    cat << EOF
Usage: $(basename "$0") status [options]

Show system status information.

OPTIONS:
    -v, --verbose    Show detailed status information
    -h, --help       Show this help

EXAMPLES:
    $(basename "$0") status
    $(basename "$0") status --verbose
EOF
}

main() {
    local verbose=false
    local quiet=false
    
    # Parse global options first
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -v|--version)
                echo "$(basename "$0") $(get_version)"
                exit 0
                ;;
            --verbose)
                verbose=true
                shift
                ;;
            --quiet)
                quiet=true
                shift
                ;;
            -*)
                log::error "Unknown global option: $1"
                show_help
                exit 1
                ;;
            *)
                # First non-option argument is the command
                break
                ;;
        esac
    done
    
    # Must have a command
    if [[ $# -eq 0 ]]; then
        log::error "Command required"
        show_help
        exit 1
    fi
    
    local command="$1"
    shift
    
    # Dispatch to command handlers
    case "$command" in
        status)
            cmd_status "$@"
            ;;
        config)
            cmd_config "$@"
            ;;
        deploy)
            cmd_deploy "$@"
            ;;
        backup)
            cmd_backup "$@"
            ;;
        monitor)
            cmd_monitor "$@"
            ;;
        *)
            log::error "Unknown command: $command"
            show_help
            exit 1
            ;;
    esac
}

main "$@"
```

### 8. AI Workflow Generator Script

A sophisticated script that generates multi-agent AI development workflows:

```bash
#!/usr/bin/env bash
#
# generate-ai-workflow - Generate multi-agent AI development workflow
#
# Description:
#   Creates project-specific AI workflow commands and state management files
#   for autonomous development across different AI coding agents.
#
# Usage:
#   generate-ai-workflow <project-name>
#   generate-ai-workflow --help
#   generate-ai-workflow --version

set -euo pipefail

# Source the Shell Starter library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$(dirname "$SCRIPT_DIR")/lib"

# shellcheck source=../lib/main.sh
source "$LIB_DIR/main.sh"

# Script metadata
SCRIPT_NAME="generate-ai-workflow"
SCRIPT_DESCRIPTION="Generate multi-agent AI development workflow"

show_help() {
    cat <<EOF
$SCRIPT_NAME - $SCRIPT_DESCRIPTION

USAGE:
    $SCRIPT_NAME <project-name>
    $SCRIPT_NAME --help
    $SCRIPT_NAME --version

ARGUMENTS:
    project-name    Name of the project to generate workflow for

DESCRIPTION:
    Generates a complete AI development workflow including:
    - State management files (.ai-workflow/state/)
    - Multi-agent command definitions (.ai-workflow/commands/)
    - Development task templates
    - QA and progress tracking

    Supports these AI coding agents:
    - Claude Code (.claude/commands/)
    - Cursor (.cursor/commands/) 
    - Gemini CLI (.gemini/commands/)
    - OpenCode (.opencode/command/)

EXAMPLES:
    $SCRIPT_NAME md-to-pdf
    $SCRIPT_NAME my-cli-tool
    $SCRIPT_NAME web-scraper
EOF
}

generate_state_files() {
    local project_name="$1"
    
    log::info "Creating state management files for $project_name..."
    
    mkdir -p .ai-workflow/state
    
    # Generate tasks.md with project-specific task breakdown
    local project_upper=$(echo "$project_name" | tr '[:lower:]' '[:upper:]')
    cat >.ai-workflow/state/tasks.md <<EOF
# $project_name - Development Tasks

## Phase 1: Foundation Setup
- [ ] **$project_upper-1:** Create project structure and basic executable
- [ ] **$project_upper-2:** Implement help text and version handling
- [ ] **$project_upper-3:** Add dependency checking and validation

## Phase 2: Core Functionality  
- [ ] **$project_upper-4:** Implement main feature logic
- [ ] **$project_upper-5:** Add input validation and error handling
- [ ] **$project_upper-6:** Integrate Shell Starter logging and UI components

## Phase 3: Quality & Polish
- [ ] **$project_upper-7:** Add comprehensive error handling
- [ ] **$project_upper-8:** Implement progress indicators and user feedback
- [ ] **$project_upper-9:** Add advanced features and options

## Phase 4: Testing & Documentation
- [ ] **$project_upper-10:** Create comprehensive test suite
- [ ] **$project_upper-11:** Add usage examples and documentation
- [ ] **$project_upper-12:** Final QA and release preparation
EOF

    # Generate requirements.md template
    cat >.ai-workflow/state/requirements.md <<EOF
# $project_name - Project Requirements

## Overview
[Edit this section with your project description]

## Core Features
- [ ] Feature 1: [Describe main functionality]
- [ ] Feature 2: [Describe secondary functionality] 
- [ ] Feature 3: [Describe additional functionality]

## Shell Starter Requirements
- [ ] Follow Shell Starter conventions
- [ ] Use lib/main.sh and provided functions
- [ ] Include --help and --version flags
- [ ] Use log:: functions instead of echo
- [ ] Handle all error conditions gracefully
- [ ] Include progress indicators for long operations
EOF
}

generate_claude_commands() {
    local project_name="$1"
    
    mkdir -p .ai-workflow/commands/.claude/commands
    
    # /dev command for autonomous development
    cat >.ai-workflow/commands/.claude/commands/dev.md <<'EOF'
You are managing autonomous development for the current project. Follow this protocol exactly.

**Arguments:**
- No args or "start": Initialize/resume development cycle
- "status": Show current development state only

**AUTONOMOUS DEVELOPMENT PROTOCOL:**

1. **READ STATE** (always check current state first):
   - Read `.ai-workflow/state/tasks.md` - Find next incomplete task `[ ]`
   - Read `.ai-workflow/state/requirements.md` - Understand project goals
   - Read `.ai-workflow/state/progress.log` - Check recent progress

2. **ANALYZE** (determine what to do):
   - Identify the next incomplete task from tasks.md
   - Understand what this task requires
   - Check if any previous work needs to be continued

3. **ACT** (execute development work):
   - Work on ONLY the current incomplete task
   - Follow Shell Starter conventions and patterns
   - Create/modify files as needed for this specific task
   - Use proper logging, error handling, and Shell Starter functions

4. **VERIFY** (quality assurance):
   - Run `shellcheck` on any shell scripts created/modified
   - Run `shfmt -d` to check formatting
   - Test the functionality manually if applicable
   - Ensure the task is actually complete

5. **UPDATE STATE** (record progress):
   - Mark completed tasks with `[x]` in tasks.md
   - Add detailed progress entry to progress.log with timestamp
   - Identify next task or mark project complete

**OUTPUT FORMAT:**
```
🔄 AUTONOMOUS DEVELOPMENT CYCLE
Current Task: [task code and description]
Action: [what you're implementing]
Progress: [current progress status]
Next: [next task or completion status]
```

Begin autonomous development now.
EOF
}

main() {
    local project_name=""

    while [[ $# -gt 0 ]]; do
        case $1 in
        --help | -h | --version | -v)
            parse_common_args "$SCRIPT_NAME" "$@"
            ;;
        -*)
            log::error "Unknown option: $1"
            echo "Use --help for usage information."
            exit 1
            ;;
        *)
            project_name="$1"
            shift
            ;;
        esac
    done

    if [[ -z "$project_name" ]]; then
        log::error "Project name is required"
        log::info "Usage: $SCRIPT_NAME <project-name>"
        exit 1
    fi

    # Validate project name (alphanumeric, hyphens, underscores)
    if [[ ! "$project_name" =~ ^[a-zA-Z0-9_-]+$ ]]; then
        log::error "Project name must contain only letters, numbers, hyphens, and underscores"
        exit 1
    fi

    log::info "Generating AI workflow for project: $project_name"

    # Generate all components
    generate_state_files "$project_name"
    generate_claude_commands "$project_name"

    log::info "✓ AI workflow generated successfully!"
    echo
    log::info "Next steps:"
    log::info "1. Edit .ai-workflow/state/requirements.md with your project details"
    log::info "2. Copy commands to your AI coding agent:"
    log::info "   • Claude Code:  cp -r .ai-workflow/commands/.claude/commands/ .claude/commands/"
    log::info "3. Start development with: /dev start"
}

# Run main function with all arguments
main "$@"
```

**Key Features Demonstrated:**
- **Advanced file generation**: Creates complex directory structures and template files
- **String manipulation**: Project name validation and case conversion
- **Heredoc usage**: Multiple file templates with variable substitution
- **Multi-agent support**: Generates commands for different AI coding environments
- **Professional UX**: Comprehensive help, validation, and user guidance
- **State management**: Creates persistent workflow files for autonomous AI development

**Usage:**
```bash
./bin/generate-ai-workflow my-project
# Creates .ai-workflow/ with state management and AI commands
# Copy appropriate commands to your AI agent's directory
# Start autonomous development with /dev start
```

### 9. Version Management Script

The `bump-version` script provides intelligent version bumping with automatic repository detection:

```bash
#!/bin/bash

# bump-version - Intelligent version bumping for shell-starter and cloned projects
# Automatically detects context and updates appropriate version files

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SHELL_STARTER_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

source "${SHELL_STARTER_ROOT}/lib/main.sh"

# Detect if this is the shell-starter repository or a cloned project
detect_repository_type() {
    local repo_indicators=(
        "bin/generate-ai-workflow"
        "scripts/generate-release-notes.sh"
        "tests/framework.bats"
        "install.sh"
    )

    local found_indicators=0
    for indicator in "${repo_indicators[@]}"; do
        if [[ -f "${PROJECT_ROOT}/${indicator}" ]]; then
            ((found_indicators++))
        fi
    done

    # If we find most indicators, this is likely the shell-starter repo
    if [[ $found_indicators -ge 3 ]]; then
        echo "shell-starter"
    else
        echo "cloned-project"
    fi
}

# Increment version based on bump type
increment_version() {
    local current_version="$1"
    local bump_type="$2"
    local major minor patch

    read -r major minor patch <<< "$(parse_version "$current_version")"

    case "$bump_type" in
    major)
        echo "$((major + 1)).0.0"
        ;;
    minor)
        echo "${major}.$((minor + 1)).0"
        ;;
    patch)
        echo "${major}.${minor}.$((patch + 1))"
        ;;
    *)
        log::error "Invalid bump type: $bump_type (expected: major, minor, patch)"
        return 1
        ;;
    esac
}

# Main version bumping function
perform_bump() {
    local version_arg="$1"
    local current_version
    local new_version
    local repo_type

    repo_type=$(detect_repository_type)
    current_version=$(get_current_version)

    log::info "Repository type: ${repo_type}"
    log::info "Current version: ${current_version}"

    # Determine new version
    case "$version_arg" in
    major|minor|patch)
        if ! new_version=$(increment_version "$current_version" "$version_arg"); then
            exit 1
        fi
        log::info "Bumping ${version_arg} version: ${current_version} -> ${new_version}"
        ;;
    *)
        new_version="$version_arg"
        if ! validate_version "$new_version"; then
            exit 1
        fi
        log::info "Setting version: ${current_version} -> ${new_version}"
        ;;
    esac

    # Update VERSION file (always)
    update_version_file "$VERSION_FILE" "$new_version" "project version"

    # Update .shell-starter-version only for shell-starter repository
    if [[ "$repo_type" == "shell-starter" ]]; then
        update_version_file "$SHELL_STARTER_VERSION_FILE" "$new_version" "shell-starter version"
    else
        log::info "Skipping ${SHELL_STARTER_VERSION_FILE} update (cloned project)"
    fi

    if [[ "$DRY_RUN" == "false" ]]; then
        log::success "Version bump completed successfully!"
    else
        log::info "Dry run completed. Use without --dry-run to apply changes."
    fi
}

main "$@"
```

**Key Features Demonstrated:**

- **Intelligent Repository Detection**: Automatically identifies shell-starter repo vs. cloned projects
- **Selective File Updates**: Updates different files based on repository type
- **Semantic Version Support**: Handles `major`, `minor`, `patch` bumps plus exact versions
- **Dry Run Capability**: Preview changes before applying
- **Comprehensive Validation**: Input validation and error handling
- **User-Friendly Output**: Clear progress reporting and next steps

**Usage Examples:**

```bash
# Bump version types
./bin/bump-version patch    # 1.2.3 -> 1.2.4
./bin/bump-version minor    # 1.2.3 -> 1.3.0
./bin/bump-version major    # 1.2.3 -> 2.0.0

# Set exact version
./bin/bump-version 1.5.0

# Check status and repository detection
./bin/bump-version --current      # Show current versions
./bin/bump-version --check-repo   # Show detection details

# Preview changes
./bin/bump-version --dry-run patch
```

**Repository-Aware Behavior:**

- **Shell-starter repository**: Updates both `VERSION` and `.shell-starter-version` files
- **Cloned projects**: Updates only `VERSION` file, preserving dependency tracking
- **Automatic detection**: Uses project markers to determine repository type
- **Smart defaults**: Appropriate behavior for each context without user intervention

### 10. Dependency Management Script

The `update-shell-starter` script demonstrates advanced dependency management patterns:

```bash
#!/bin/bash

# update-shell-starter - Update Shell Starter library dependencies
# Updates the shell-starter lib/ directory while preserving project customizations

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"

# Try to source lib/main.sh from various locations
for lib_path in \
	"${SCRIPT_DIR}/../lib/main.sh" \
	"${SCRIPT_DIR}/lib/main.sh" \
	"$(dirname "${SCRIPT_DIR}")/lib/main.sh"; do
	if [[ -f "$lib_path" ]]; then
		source "$lib_path"
		break
	fi
done

# Configuration
SHELL_STARTER_REPO="jeromecoloma/shell-starter"
SHELL_STARTER_VERSION_FILE=".shell-starter-version"
BACKUP_SUFFIX=".backup-$(date +%Y%m%d-%H%M%S)"
DEFAULT_LIB_DIR="lib"

show_help() {
    cat << EOF
${SCRIPT_NAME} - Update Shell Starter library dependencies

USAGE:
    ${SCRIPT_NAME} [OPTIONS]

OPTIONS:
    --version               Show version information
    --help                  Show this help message
    --check                 Check for available updates without installing
    --target-version <ver>  Update to specific version (default: latest)
    --lib-dir <path>        Library directory path (default: lib)
    --backup                Create backup before updating (default: enabled)
    --no-backup             Skip backup creation
    --force                 Force update even if versions match
    --dry-run               Show what would be updated without making changes

EXAMPLES:
    ${SCRIPT_NAME}                           # Update to latest version
    ${SCRIPT_NAME} --check                   # Check for updates
    ${SCRIPT_NAME} --target-version 0.2.0   # Update to specific version
    ${SCRIPT_NAME} --lib-dir custom_lib      # Update custom lib directory
    ${SCRIPT_NAME} --dry-run                 # Preview changes

This tool updates shell-starter library files while preserving your project's
customizations. It maintains a version file for tracking dependencies.
EOF
}

# Update library files while preserving customizations
update_library_files() {
	local source_lib="$1"
	local target_lib="$2"

	# List of standard shell-starter library files
	local standard_files=(
		"colors.sh"
		"logging.sh"
		"main.sh"
		"spinner.sh"
		"update.sh"
		"utils.sh"
	)

	log::info "Updating library files in ${target_lib}..."

	for file in "${standard_files[@]}"; do
		local source_file="${source_lib}/${file}"
		local target_file="${target_lib}/${file}"

		if [[ -f "$source_file" ]]; then
			if [[ "$DRY_RUN" == "true" ]]; then
				if [[ -f "$target_file" ]]; then
					log::info "[DRY-RUN] Would update: ${target_file}"
				else
					log::info "[DRY-RUN] Would create: ${target_file}"
				fi
			else
				log::info "Updating: ${target_file}"
				cp "$source_file" "$target_file"
			fi
		fi
	done

	# Warn about custom files that won't be updated
	if [[ -d "$target_lib" ]]; then
		while IFS= read -r -d '' custom_file; do
			local basename_file
			basename_file=$(basename "$custom_file")
			if [[ ! " ${standard_files[*]} " =~ \ ${basename_file}\  ]]; then
				log::warn "Custom file preserved: ${custom_file}"
			fi
		done < <(find "$target_lib" -name "*.sh" -type f -print0)
	fi
}

# Breaking change detection and migration guidance
check_breaking_changes() {
	local current_version="$1"
	local target_version="$2"
	local warnings=()

	# Define known breaking changes by version
	local breaking_changes=(
		"0.2.0:Function names in logging.sh changed from log_* to log::*"
		"0.3.0:Color variable names standardized with COLOR_ prefix"
		"0.4.0:Spinner API changed to use spinner::* namespace"
		"1.0.0:Major API restructure - see migration guide"
	)

	# Check if we're crossing any breaking change versions
	for change in "${breaking_changes[@]}"; do
		local break_version="${change%%:*}"
		local description="${change#*:}"

		# Check if we're upgrading across this breaking change
		if version_is_greater "$break_version" "$current_version" &&
			version_is_less_or_equal "$break_version" "$target_version"; then
			warnings+=("v${break_version}: ${description}")
		fi
	done

	# Display warnings if any breaking changes detected
	if [[ ${#warnings[@]} -gt 0 ]]; then
		log::warn "BREAKING CHANGES DETECTED:"
		for warning in "${warnings[@]}"; do
			log::warn "  • $warning"
		done
		log::warn ""
		log::warn "Please review the migration guide at:"
		log::warn "https://github.com/${SHELL_STARTER_REPO}/blob/main/docs/MIGRATION.md"
		log::warn ""

		if [[ "$FORCE_UPDATE" == "false" ]]; then
			echo -n "Continue with update? [y/N]: "
			read -r response
			if [[ ! "$response" =~ ^[Yy]$ ]]; then
				log::info "Update cancelled by user"
				exit 0
			fi
		fi
	fi
}

main() {
    # Parse command line arguments and execute update logic
    # ... (full implementation in bin/update-shell-starter)
}

main "$@"
```

**Key Features Demonstrated:**

- **Selective File Management**: Updates only standard library files, preserves custom additions
- **Version Tracking**: Maintains `.shell-starter-version` for dependency tracking
- **Breaking Change Detection**: Warns users about API changes with specific guidance
- **Backup Management**: Automatic backup creation with timestamps
- **Dry Run Capability**: Preview changes before applying them
- **Flexible Library Discovery**: Finds Shell Starter libraries in multiple locations
- **User Confirmation**: Interactive prompts for breaking changes
- **GitHub API Integration**: Downloads releases from GitHub API

**Usage Examples:**

```bash
# Check for available updates
./bin/update-shell-starter --check

# Update to latest version with safety checks
./bin/update-shell-starter

# Preview what would be updated without applying changes
./bin/update-shell-starter --dry-run

# Update to specific version
./bin/update-shell-starter --target-version 0.2.0

# Force update even if versions match
./bin/update-shell-starter --force

# Update custom lib directory location
./bin/update-shell-starter --lib-dir custom_lib
```

**Version Tracking File:**

The script maintains a `.shell-starter-version` file in your project root:

```bash
# Check current shell-starter version
cat .shell-starter-version
# Output: 0.1.0

# This file is automatically updated by the script
# and should be committed to version control
```

## 🔗 Polyglot Integration Examples

### 11. Bash + Python Integration

Demonstrates calling Python scripts from Bash:

```bash
#!/bin/bash

# polyglot-example - Demonstrates Bash + Python integration
# This script shows how to seamlessly call Python scripts from Bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SHELL_STARTER_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

source "${SHELL_STARTER_ROOT}/lib/main.sh"

main() {
    local input_file="${1:-}"
    
    if [[ -z "$input_file" ]]; then
        log::error "Input file required"
        echo "Usage: $(basename "$0") <input_file>"
        exit 1
    fi
    
    if [[ ! -r "$input_file" ]]; then
        log::error "Cannot read input file: $input_file"
        exit 1
    fi
    
    log::info "Processing file with Python script..."
    
    # Call Python script using the run::script utility
    if run::script "${SHELL_STARTER_ROOT}/scripts/analyze.py" "$input_file"; then
        log::success "Python analysis completed successfully"
    else
        log::error "Python analysis failed"
        exit 1
    fi
    
    log::info "Bash post-processing..."
    # Additional bash processing here
    
    log::success "All processing completed!"
}

main "$@"
```

### 12. API Integration Script

Example of calling external APIs with error handling:

```bash
#!/bin/bash

# ai-action - Template for AI API integration
# Demonstrates secure API key handling and JSON response processing

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SHELL_STARTER_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

source "${SHELL_STARTER_ROOT}/lib/main.sh"

# Configuration
API_URL="${API_URL:-https://api.openai.com/v1/chat/completions}"
CONFIG_FILE="$HOME/.config/shell-starter/ai-config"

check_dependencies() {
    local deps=("curl" "jq")
    local missing=()
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" >/dev/null 2>&1; then
            missing+=("$dep")
        fi
    done
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        log::error "Required dependencies missing: ${missing[*]}"
        log::info "Please install them and try again"
        exit 1
    fi
}

get_api_key() {
    local api_key
    
    # Try environment variable first
    if [[ -n "${OPENAI_API_KEY:-}" ]]; then
        echo "$OPENAI_API_KEY"
        return 0
    fi
    
    # Try config file
    if [[ -r "$CONFIG_FILE" ]]; then
        api_key=$(grep "^api_key=" "$CONFIG_FILE" | cut -d'=' -f2-)
        if [[ -n "$api_key" ]]; then
            echo "$api_key"
            return 0
        fi
    fi
    
    log::error "API key not found"
    log::info "Set OPENAI_API_KEY environment variable or add to $CONFIG_FILE"
    return 1
}

call_ai_api() {
    local prompt="$1"
    local api_key="$2"
    local response
    local http_code
    
    log::info "Calling AI API..."
    spinner::start "Processing request"
    
    # Prepare JSON payload
    local json_payload
    json_payload=$(jq -n \
        --arg model "gpt-3.5-turbo" \
        --arg prompt "$prompt" \
        '{
            model: $model,
            messages: [
                {
                    role: "user",
                    content: $prompt
                }
            ],
            max_tokens: 150,
            temperature: 0.7
        }')
    
    # Make API call
    response=$(curl -s -w "\n%{http_code}" \
        -H "Authorization: Bearer $api_key" \
        -H "Content-Type: application/json" \
        -d "$json_payload" \
        "$API_URL")
    
    spinner::stop
    
    # Parse response and HTTP code
    http_code=$(echo "$response" | tail -n1)
    response=$(echo "$response" | sed '$d')
    
    if [[ "$http_code" -ne 200 ]]; then
        log::error "API call failed with HTTP $http_code"
        echo "$response" | jq -r '.error.message // "Unknown error"' >&2
        return 1
    fi
    
    # Extract and display the response
    local ai_response
    ai_response=$(echo "$response" | jq -r '.choices[0].message.content')
    
    log::success "AI Response:"
    echo "$ai_response"
}

main() {
    local prompt="${1:-}"
    
    if [[ -z "$prompt" ]]; then
        log::error "Prompt required"
        echo "Usage: $(basename "$0") \"<your prompt>\""
        exit 1
    fi
    
    check_dependencies
    
    local api_key
    if ! api_key=$(get_api_key); then
        exit 1
    fi
    
    call_ai_api "$prompt" "$api_key"
}

main "$@"
```

## 🧪 Testing Examples

### 13. Bats Test File

Example test file structure for demo scripts:

```bash
#!/usr/bin/env bats

# tests/hello-world.bats - Tests for the hello-world script

# Setup function runs before each test
setup() {
    # Add the demo directory to PATH for testing
    export PATH="$BATS_TEST_DIRNAME/../demo:$PATH"
    
    # Create temporary directory for test files
    export BATS_TMPDIR="$(mktemp -d)"
}

# Teardown function runs after each test
teardown() {
    # Clean up temporary files
    [[ -n "$BATS_TMPDIR" ]] && rm -rf "$BATS_TMPDIR"
}

@test "hello-world shows help when --help flag is used" {
    run hello-world --help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Usage:" ]]
    [[ "$output" =~ "hello-world" ]]
}

@test "hello-world shows version when --version flag is used" {
    run hello-world --version
    [ "$status" -eq 0 ]
    [[ "$output" =~ "hello-world" ]]
    [[ "$output" =~ "0.1.0" ]]
}

@test "hello-world greets World by default" {
    run hello-world --quiet
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Hello, World!" ]]
}

@test "hello-world greets custom name" {
    run hello-world --quiet "Alice"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Hello, Alice!" ]]
}

@test "hello-world fails with unknown option" {
    run hello-world --unknown-option
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Unknown option" ]]
}

@test "hello-world accepts multiple arguments (uses first)" {
    run hello-world --quiet "Alice" "Bob" "Charlie"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Hello, Alice!" ]]
}
```

## 🎨 Enhanced Color Features & Fallback Systems

### JSON Syntax Highlighting

Shell Starter includes enhanced JSON syntax highlighting capabilities:

```bash
#!/bin/bash

# json-example - Demonstrates JSON syntax highlighting
source lib/main.sh

# Simple JSON highlighting
simple_json='{"name": "value", "count": 42, "active": true}'
colors::json_syntax "$simple_json"

# Complex nested JSON
complex_json='{
  "user": {
    "name": "John Doe",
    "age": 30,
    "active": true,
    "settings": {
      "theme": "dark",
      "notifications": false
    }
  },
  "items": [1, 2, 3],
  "metadata": null
}'
colors::json_syntax "$complex_json"

# Individual JSON component highlighting
echo "Key: $(colors::json_key "username")"
echo "String: $(colors::json_string "John Doe")"
echo "Number: $(colors::json_number "42")"
echo "Boolean: $(colors::json_boolean "true")"
echo "Null: $(colors::json_null)"
```

### Production Tool Color Fallback

Production tools in `bin/` include sophisticated fallback color support:

```bash
#!/bin/bash

# production-tool-example - Shows fallback color functionality
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Try to source lib/main.sh from various locations
for lib_path in \
    "${SCRIPT_DIR}/../lib/main.sh" \
    "${SCRIPT_DIR}/lib/main.sh" \
    "$(dirname "${SCRIPT_DIR}")/lib/main.sh"; do
    if [[ -f "$lib_path" ]]; then
        source "$lib_path"
        break
    fi
done

# Enhanced fallback functionality when lib/main.sh is not available
if [[ -z "${SHELL_STARTER_LIB_DIR:-}" ]]; then
    # Color detection and fallback functions
    colors_has_color() {
        [[ "${NO_COLOR:-}" == "" ]] && {
            [[ "${TERM:-}" != "dumb" ]] &&
                [[ "${TERM:-}" != "" ]] &&
                [[ -t 1 ]]
        }
    }

    # Enhanced color variables with fallback support
    if ! declare -p COLOR_RESET >/dev/null 2>&1; then
        if colors_has_color; then
            readonly COLOR_INFO='\033[0;34m'    # Blue
            readonly COLOR_SUCCESS='\033[0;32m' # Green
            readonly COLOR_WARNING='\033[1;33m' # Yellow
            readonly COLOR_ERROR='\033[0;31m'   # Red
            readonly COLOR_RESET='\033[0m'
            readonly COLOR_BOLD='\033[1m'
        else
            readonly COLOR_INFO=''
            readonly COLOR_SUCCESS=''
            readonly COLOR_WARNING=''
            readonly COLOR_ERROR=''
            readonly COLOR_RESET=''
            readonly COLOR_BOLD=''
        fi
    fi

    # Enhanced logging functions with visual indicators
    log::info() {
        printf '%bℹ%b %s\n' "${COLOR_INFO}" "${COLOR_RESET}" "$*"
    }

    log::warn() {
        printf '%b⚠%b %s\n' "${COLOR_WARNING}" "${COLOR_RESET}" "$*"
    }

    log::error() {
        printf '%b✗%b %s\n' "${COLOR_ERROR}" "${COLOR_RESET}" "$*" >&2
    }

    log::success() {
        printf '%b✓%b %s\n' "${COLOR_SUCCESS}" "${COLOR_RESET}" "$*"
    }

    # Minimal banner support
    banner_minimal() {
        if colors_has_color; then
            printf '%b• Production Tool •%b\n' "${COLOR_INFO}" "${COLOR_RESET}"
        else
            echo "• Production Tool •"
        fi
    }
fi

show_help() {
    banner_minimal
    cat << EOF
Usage: $(basename "$0") [OPTIONS]

A production tool demonstrating enhanced color fallback support.

OPTIONS:
    -h, --help        Show this help message and exit
    -v, --version     Show version information and exit

EXAMPLES:
    $(basename "$0")              # Run with colors
    NO_COLOR=1 $(basename "$0")   # Run without colors
EOF
}

main() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -v|--version)
                echo "$(basename "$0") v1.0.0"
                exit 0
                ;;
            *)
                log::error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done

    log::info "Tool starting with enhanced color support"
    log::success "Colors work with or without lib/main.sh!"
    log::warn "This shows fallback functionality"
    log::error "Even errors have visual indicators"
}

main "$@"
```

### Color Environment Compatibility

Shell Starter automatically detects and adapts to different terminal environments:

```bash
# Environment detection examples
colors::has_color        # Returns true if colors are supported
colors::has_truecolor    # Returns true if 24-bit colors are supported
colors::has_256color     # Returns true if 256 colors are supported
colors::is_terminal      # Returns true if output is going to a terminal

# Respects user preferences
export NO_COLOR=1        # Disables all colors globally
export TERM=dumb         # Forces fallback to plain text

# Terminal-specific detection
export COLORTERM=truecolor      # Enables truecolor support
export TERM_PROGRAM=iTerm.app   # iTerm2 detection
export TERM=xterm-256color      # 256-color terminal
```

### Advanced Color Usage Patterns

```bash
# Section headers with colors
section_header() {
    printf '\n%b─── %s ───%b\n' "${COLOR_BOLD}" "$*" "${COLOR_RESET}"
}

# Visual dividers
section_divider() {
    printf '%b%s%b\n' "${COLOR_INFO}" "$(printf '%.40s' "────────────────────────────────────────")" "${COLOR_RESET}"
}

# Colored JSON in demo scripts
demo_status_json() {
    local json_data='{"status": "ok", "version": "1.0.0", "count": 5}'
    echo "Status (JSON format):"
    colors::json_syntax "$json_data"
}

# Progress indicators with colors
show_progress() {
    local steps=("Initialize" "Process" "Validate" "Complete")
    local current_step="$1"

    echo "Progress:"
    for i in "${!steps[@]}"; do
        if [[ $i -lt $current_step ]]; then
            printf "  %b✓%b %s\n" "${COLOR_SUCCESS}" "${COLOR_RESET}" "${steps[$i]}"
        elif [[ $i -eq $current_step ]]; then
            printf "  %b→%b %s\n" "${COLOR_INFO}" "${COLOR_RESET}" "${steps[$i]}"
        else
            printf "  %b○%b %s\n" "${COLOR_DIM}" "${COLOR_RESET}" "${steps[$i]}"
        fi
    done
}
```

### NO_COLOR Compliance

Shell Starter fully respects the [NO_COLOR standard](https://no-color.org/):

```bash
# Users can disable colors globally
export NO_COLOR=1
./bin/bump-version --help    # Shows plain text without colors

# Or per-command
NO_COLOR=1 ./demo/show-colors

# Detection in scripts
if [[ "${NO_COLOR:-}" != "" ]]; then
    echo "Colors are disabled by user preference"
fi

# All color functions respect this setting automatically
log::info "This message respects NO_COLOR setting"
colors::json_syntax '{"key": "value"}'  # Plain text if NO_COLOR=1
```

### Best Practices for Color Enhancement

```bash
# 1. Always provide fallback functionality
if [[ -z "${SHELL_STARTER_LIB_DIR:-}" ]]; then
    # Define minimal color fallback functions
    log::info() { printf 'ℹ %s\n' "$*"; }
    # ... other fallbacks
fi

# 2. Use semantic colors consistently
log::info "Information messages (blue ℹ)"
log::success "Success messages (green ✓)"
log::warn "Warning messages (yellow ⚠)"
log::error "Error messages (red ✗)"

# 3. Include visual indicators beyond just colors
printf '%b→%b Processing...\n' "${COLOR_INFO}" "${COLOR_RESET}"
printf '%b✓%b Completed\n' "${COLOR_SUCCESS}" "${COLOR_RESET}"

# 4. Test with NO_COLOR to ensure accessibility
NO_COLOR=1 your-script --help

# 5. Use guard clauses to prevent redefinition
if ! declare -p COLOR_RESET >/dev/null 2>&1; then
    # Define color variables only if not already defined
fi
```

These examples demonstrate the full range of Shell Starter capabilities and provide templates for creating robust, maintainable bash scripts. Each example includes proper error handling, user feedback, and follows the established conventions.