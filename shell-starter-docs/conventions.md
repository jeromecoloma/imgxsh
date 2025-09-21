# Shell Starter - Coding Conventions

This document outlines the coding standards and conventions used in Shell Starter. Following these conventions ensures consistency, maintainability, and compatibility with the project's architecture.

## 📋 Quick Reference: Example Scripts and Core Utilities

Conventions are demonstrated in both example scripts (`demo/`) and core utilities (`bin/`):

### Demo Scripts (`demo/` - Examples for Learning)
| Script | Demonstrates |
|--------|-------------|
| `demo/hello-world` | Basic structure, standard header, help/version patterns |
| `demo/greet-user` | Argument parsing, input validation, multiple options |
| `demo/show-colors` | Color usage, output formatting |
| `demo/long-task` | Logging functions, spinner usage, progress indicators |
| `demo/my-cli` | Multi-command structure, subcommand routing |
| `demo/ai-action` | Dependency checking, external tool integration |
| `demo/polyglot-example` | Polyglot scripts, `run::script` function |
| `demo/show-banner` | Banner system, visual branding |
| `demo/debug-colors` | Color debugging, terminal compatibility |
| `demo/update-tool` | Update management demonstration |

### Core Utilities (`bin/` - Production Tools)
| Script | Demonstrates |
|--------|-------------|
| `bin/generate-ai-workflow` | Complex argument parsing, file generation |
| `bin/update-shell-starter` | Dependency management, version tracking, breaking change detection |
| `bin/bump-version` | Version management, repository detection |
| `bin/cleanup-shell-path` | Shell configuration management, PATH cleanup |

**Test Examples**: `tests/hello-world.bats`, `tests/library-functions.bats`

## 📁 File Organization

### Directory Structure
```
shell-starter/
├── bin/                # Core utility scripts (no .sh extension)
├── demo/               # Example scripts for learning (no .sh extension)
├── lib/                # Shared library functions (.sh extension)
├── scripts/            # Helper scripts in other languages
├── tests/              # Bats test files (.bats extension)
└── docs/               # Documentation files (.md extension)
```

### Directory Purpose Guidelines

#### `bin/` - Core Utilities
- **Purpose**: Production-ready tools that are part of Shell Starter's core functionality
- **Audience**: Shell Starter maintainers and advanced users
- **Installation**: These scripts are installed when using Shell Starter as a dependency
- **Examples**: `update-shell-starter`, `bump-version`, `generate-ai-workflow`

#### `demo/` - Example Scripts
- **Purpose**: Educational examples demonstrating Shell Starter features and conventions
- **Audience**: Developers learning Shell Starter or building new CLI tools
- **Installation**: These scripts are NOT installed by `install.sh` - they remain as local examples
- **Examples**: `hello-world`, `show-colors`, `my-cli`, `greet-user`

#### `lib/` - Shared Library Functions
- **Purpose**: Reusable shell functions that provide Shell Starter's core functionality
- **Audience**: All Shell Starter scripts (both bin/ and demo/) and derived projects
- **Installation**: These files are installed alongside CLI tools and sourced by scripts
- **Examples**: `main.sh` (main entry point), `colors.sh`, `logging.sh`, `spinner.sh`, `utils.sh`
- **Usage**: Scripts source `lib/main.sh` which automatically includes all other library files

### Naming Conventions

- **Core Utility Scripts** (`bin/`): Use kebab-case without file extensions
  - ✅ `generate-ai-workflow`, `update-shell-starter`, `bump-version`
  - ❌ `generate_ai_workflow.sh`, `updateShellStarter`, `bump-version.bash`

- **Example Scripts** (`demo/`): Use kebab-case without file extensions
  - ✅ `hello-world`, `my-cli`, `greet-user` (see `demo/hello-world`, `demo/my-cli`)
  - ❌ `hello_world.sh`, `myScript`, `greet-user.bash`

- **Library Files** (`lib/`): Use kebab-case with `.sh` extension
  - ✅ `colors.sh`, `logging.sh`, `spinner.sh` (see `lib/colors.sh`, `lib/logging.sh`)
  - ❌ `Colors.sh`, `logging_utils.sh`, `spinner`

- **Test Files** (`tests/`): Use kebab-case with `.bats` extension
  - ✅ `hello-world.bats`, `library-functions.bats` (see `tests/hello-world.bats`)
  - ❌ `test_hello.bats`, `HelloWorld.bats`

## 📜 Script Structure

### Standard Header Template
Every script should start with this template (example: `demo/hello-world`):

```bash
#!/bin/bash

# script-name - Brief description of what the script does
# Optional: Longer description with usage examples

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SHELL_STARTER_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

source "${SHELL_STARTER_ROOT}/lib/main.sh"
```

### Error Handling
- Always use `set -euo pipefail` for strict error handling
- Use the logging functions for consistent error reporting
- Exit with appropriate codes (0 for success, non-zero for errors)

### Function Definitions
```bash
# Use snake_case for function names
function show_help() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS]
...
EOF
}

# Functions should have descriptive names
function validate_input() {
    local input="$1"
    # validation logic
}
```

## 🎨 Styling Guidelines

### Colors and Logging
- Use the provided logging functions instead of raw `echo`
- Prefer semantic colors over direct color codes
- **Examples**: See `demo/long-task` for logging, `demo/show-colors` for color usage

```bash
# ✅ Good
log::info "Processing data..."
log::warn "Configuration file not found, using defaults"
log::error "Failed to connect to server"

# ❌ Avoid
echo -e "${BLUE}Processing data...${RESET}"
echo "Warning: Configuration file not found"
```

### Variables
- Use UPPERCASE for environment variables and constants
- Use lowercase for local variables
- Quote variables to prevent word splitting

```bash
# ✅ Good
readonly DEFAULT_CONFIG_PATH="/etc/myapp/config"
local user_input="$1"
local file_count="${#files[@]}"

# ❌ Avoid
default_config_path="/etc/myapp/config"
USERINPUT="$1"
echo $user_input  # Unquoted variable
```

### Command Substitution
- Prefer `$()` over backticks for command substitution

```bash
# ✅ Good
current_date="$(date +%Y-%m-%d)"
file_count="$(ls -1 | wc -l)"

# ❌ Avoid
current_date=`date +%Y-%m-%d`
```

## 🔧 Argument Parsing

### Standard Pattern
Use this pattern for consistent argument parsing (example: `demo/greet-user`):

```bash
show_help() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS] [ARGS]

ARGUMENTS:
    ARG1              Description of first argument

OPTIONS:
    -h, --help        Show this help message and exit
    -v, --version     Show version information and exit
    -q, --quiet       Suppress verbose output
    -f, --force       Force operation without confirmation

EXAMPLES:
    $(basename "$0") --help
    $(basename "$0") --version
EOF
}

# Parse command line arguments
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
            QUIET=true
            shift
            ;;
        -*)
            log::error "Unknown option: $1"
            show_help
            exit 1
            ;;
        *)
            # Positional argument
            break
            ;;
    esac
done
```

## 📚 Library Usage

### Sourcing Libraries
Always source `lib/main.sh` which includes all other libraries:

```bash
source "${SHELL_STARTER_ROOT}/lib/main.sh"
```

### Available Functions

#### Logging Functions
```bash
log::info "Informational message"
log::warn "Warning message" 
log::error "Error message"
log::debug "Debug message" # Only shown if DEBUG=1
log::success "Success message"
```

#### Spinner Functions
```bash
spinner::start "Loading data..."
# Long running operation
spinner::stop
```
**Example**: See `demo/long-task` for spinner usage

#### Utility Functions
```bash
# Get version from VERSION file
version="$(get_version)"

# Execute scripts in other languages
run::script "scripts/analyze.py" "$input_file"
```
**Examples**: 
- Version handling: `demo/hello-world --version`
- Polyglot scripts: `demo/polyglot-example`

## 🧪 Testing Conventions

### Bats Test Structure
**Example**: See `tests/hello-world.bats` for comprehensive test patterns
```bash
#!/usr/bin/env bats

# Test file should be named after the script being tested
# Example: tests/hello-world.bats

setup() {
    # Common setup for all tests
    export PATH="$BATS_TEST_DIRNAME/../bin:$PATH"
}

@test "script shows help when --help flag is used" {
    run hello-world --help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Usage:" ]]
}

@test "script shows version when --version flag is used" {
    run hello-world --version
    [ "$status" -eq 0 ]
    [[ "$output" =~ "hello-world" ]]
}
```

## 🔐 Security Best Practices

### Input Validation
```bash
# Always validate user input
validate_email() {
    local email="$1"
    if [[ ! "$email" =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$ ]]; then
        log::error "Invalid email format: $email"
        return 1
    fi
}
```

### File Operations
```bash
# Check if file exists and is readable
if [[ ! -r "$config_file" ]]; then
    log::error "Cannot read configuration file: $config_file"
    exit 1
fi

# Use absolute paths when possible
config_file="$(realpath "$config_file")"
```

### Environment Variables
```bash
# Provide defaults for environment variables
API_URL="${API_URL:-https://api.example.com}"
TIMEOUT="${TIMEOUT:-30}"

# Never log sensitive information
log::debug "Connecting to API at $API_URL"
# Don't log: log::debug "Using API key: $API_KEY"
```

## 📦 Dependencies

### Optional Dependencies
Handle optional dependencies gracefully (example: `demo/ai-action`):

```bash
check_dependencies() {
    local missing_deps=()
    
    if ! command -v jq >/dev/null 2>&1; then
        missing_deps+=("jq")
    fi
    
    if ! command -v curl >/dev/null 2>&1; then
        missing_deps+=("curl")
    fi
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        log::warn "Optional dependencies missing: ${missing_deps[*]}"
        log::info "Some features may be unavailable"
    fi
}
```

### Required Dependencies
**Example**: See `bin/generate-ai-workflow` for dependency checking patterns
```bash
require_dependencies() {
    local deps=("git" "bash")
    local missing_deps=()
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" >/dev/null 2>&1; then
            missing_deps+=("$dep")
        fi
    done
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        log::error "Required dependencies missing: ${missing_deps[*]}"
        log::error "Please install them and try again"
        exit 1
    fi
}
```

## 📦 Version Tracking and Dependency Management

### Shell Starter Version Tracking

Projects using Shell Starter as a library foundation should maintain version tracking:

#### Version File
- **`.shell-starter-version`**: Tracks the version of shell-starter libraries in use
- This file is automatically maintained by the `update-shell-starter` tool
- Should be committed to version control for team synchronization

```bash
# Check current shell-starter version
cat .shell-starter-version

# Example content
0.1.0
```

#### Project Structure for Derived Projects
```
my-cli-project/
├── bin/                     # Your custom CLI scripts
├── lib/                     # Shell Starter libraries + your custom libs
│   ├── colors.sh           # Shell Starter library (managed)
│   ├── logging.sh          # Shell Starter library (managed)
│   ├── main.sh             # Shell Starter library (managed)
│   ├── spinner.sh          # Shell Starter library (managed)
│   ├── utils.sh            # Shell Starter library (managed)
│   ├── update.sh           # Shell Starter library (managed)
│   └── my-custom.sh        # Your custom library (preserved)
├── .shell-starter-version  # Version tracking file
└── VERSION                 # Your project's version
```

### Dependency Management Practices

#### Updating Shell Starter Dependencies

Use the built-in dependency management system to keep libraries current:

```bash
# Regular maintenance - check for updates
./bin/update-shell-starter --check

# Update to latest with safety checks
./bin/update-shell-starter

# Preview changes before applying
./bin/update-shell-starter --dry-run

# Update to specific version
./bin/update-shell-starter --target-version 0.2.0
```

#### Breaking Change Management

Follow these practices when shell-starter releases breaking changes:

1. **Review Migration Guide**: Check `docs/MIGRATION.md` for version-specific guidance
2. **Test Updates**: Use `--dry-run` to preview changes
3. **Backup Strategy**: Updates automatically create backups, but consider additional backups for critical projects
4. **Staged Rollout**: Update development environments before production

```bash
# Example workflow for breaking changes
./bin/update-shell-starter --dry-run  # Preview changes
./bin/update-shell-starter            # Apply with prompts
# Review warnings and migration guide
# Test your scripts with updated libraries
```

#### Custom Library Preservation

The dependency management system preserves your customizations:

- **Standard Files**: Automatically updated (`colors.sh`, `logging.sh`, `main.sh`, `spinner.sh`, `utils.sh`, `update.sh`)
- **Custom Files**: Preserved and warned about (`my-custom.sh`, `project-specific.sh`)
- **Backup Creation**: Automatic backups before updates (configurable)

### Version Management Best Practices

#### For Project Maintainers

```bash
# Version consistency checks
check_version_consistency() {
    local project_version
    local shell_starter_version

    project_version="$(cat VERSION)"
    shell_starter_version="$(cat .shell-starter-version 2>/dev/null || echo 'unknown')"

    log::info "Project version: $project_version"
    log::info "Shell Starter version: $shell_starter_version"
}
```

#### For Teams

- **Commit Version Files**: Include both `VERSION` and `.shell-starter-version` in version control
- **Update Documentation**: Document shell-starter version requirements in README
- **CI Integration**: Consider adding dependency checks to CI pipelines

```bash
# Example CI check
if [[ ! -f .shell-starter-version ]]; then
    log::warn "Shell Starter version not tracked - consider running update-shell-starter"
fi
```

## 📖 Documentation

### Inline Comments
- Use comments sparingly and only when necessary
- Focus on explaining "why" rather than "what"
- Keep comments up-to-date with code changes

```bash
# Good: Explains why this is necessary
# We need to sleep here because the API rate limits requests
sleep 1

# Avoid: States the obvious
# Increment counter by 1
((counter++))
```

### Help Text
- Always provide comprehensive help text
- Include examples in help output
- Keep help text concise but informative

## 🔍 Code Quality Tools

### Tool Installation

Before contributing, install the required development tools:

**macOS (Homebrew):**
```bash
brew install shellcheck shfmt
```

**Ubuntu/Debian:**
```bash
# ShellCheck
sudo apt-get install -y shellcheck

# shfmt  
curl -L -o /tmp/shfmt https://github.com/mvdan/sh/releases/download/v3.12.0/shfmt_v3.12.0_linux_amd64
sudo install /tmp/shfmt /usr/local/bin/shfmt
```

**Windows:**
- Use WSL2 with Ubuntu setup above, or
- Use package managers like Chocolatey or Scoop
- See official tool documentation for Windows-specific instructions

### Shellcheck Configuration

The project includes a `.shellcheckrc` file that configures shellcheck for shell library development:

```bash
# Check if shellcheck passes
shellcheck lib/*.sh scripts/*.sh bin/* demo/* install.sh uninstall.sh
```

The configuration suppresses warnings that are expected in a shell library project:
- `SC2034`: Variables defined in libraries for external use
- `SC1091`: File sourcing behavior when analyzing individual files  
- Various style/info warnings that don't affect functionality

### Code Formatting

Use `shfmt` to ensure consistent formatting:

```bash
# Check formatting
shfmt -d lib/*.sh scripts/*.sh bin/* demo/* install.sh uninstall.sh

# Apply formatting fixes
shfmt -w lib/*.sh scripts/*.sh bin/* demo/* install.sh uninstall.sh
```

### Continuous Integration

The project uses GitHub Actions to automatically verify:
- Shellcheck linting passes
- Code formatting is consistent with shfmt
- All Bats tests pass

Following these conventions ensures that all Shell Starter scripts are consistent, maintainable, and follow bash best practices.