# imgxsh Testing Framework

This document outlines the testing conventions, patterns, and infrastructure for the imgxsh project. All testing follows Shell Starter conventions while extending them for image processing functionality.

## 🧪 Testing Overview

The imgxsh testing framework provides comprehensive coverage for:
- **Core functionality testing** - All binary tools and workflow engine
- **Integration testing** - End-to-end workflow execution with real files
- **Dependency testing** - External tool integration and error handling
- **Cross-platform testing** - macOS and Linux compatibility
- **CI/CD integration** - Automated testing with GitHub Actions

### New: imgxsh-resize Test Coverage
- CLI interface: help/version, required arguments
- Single-file resizing: width/height, dry-run, verbose
- Smart resizing: no-upscale default, `--allow-upscale` override
- Percentage sizing: single and dual percentage specs (`50%`, `120%x80%`)
- Constraints: `--max-file-size` validation (platform-flexible assertion)
- Batch mode: directory processing, nested output structure preservation
- Error paths: invalid size spec, missing inputs

### New: imgxsh-extract-pdf Test Coverage
- CLI interface: help/version, argument validation, dependency checking
- PDF validation: file existence, readability, format detection
- Output directory: creation, validation, file vs directory handling
- Format support: jpg, png, tiff, bmp with case-insensitive input
- Quality control: validation (1-100), format-specific defaults
- Page ranges: validation and parsing of complex range formats
- Extraction modes: list-only, dry-run, verbose, quiet
- Template naming: custom prefixes, sequential numbering
- Metadata handling: extraction, preservation, optional skipping
- Error handling: missing dependencies, invalid inputs, file permissions
- Shell Starter integration: logging patterns, version management

## 📁 Testing Structure

```
tests/
├── README.md                    # This comprehensive testing documentation
├── test_helper.bash            # Common test utilities and helpers
├── run-tests.sh               # Main test runner for local development
├── run-tests-ci.sh            # CI-optimized test runner (Shell Starter pattern)
├── setup-ci-environment.sh    # CI environment configuration script
├── imgxsh-convert.bats        # Comprehensive tests for imgxsh-convert (30+ tests)
├── imgxsh-resize.bats         # Tests for imgxsh-resize (CLI, sizing modes, batch)
├── imgxsh-extract-pdf.bats    # Tests for imgxsh-extract-pdf (40+ tests)
├── fixtures/                  # Test data and sample files
│   ├── images/               # Sample images for testing (PNG, JPG)
│   ├── pdfs/                 # Sample PDF files for extraction tests
│   └── excel/                # Sample Excel files for extraction tests
├── bats-core/                 # Bats testing framework (v1.11.0+)
├── bats-support/              # Bats support library for test utilities
├── bats-assert/               # Bats assertion library for test validation
└── bats-helpers/              # Additional helper functions (if needed)
```

**Key Files Explained**:
- **`run-tests.sh`**: Local development runner with setup, verbose, and filtering options
- **`run-tests-ci.sh`**: CI-specific runner following Shell Starter patterns
- **`setup-ci-environment.sh`**: Environment setup for consistent CI testing
- **`imgxsh-convert.bats`**: Complete test suite with 30 tests covering all functionality
- **`imgxsh-resize.bats`**: Test suite covering resize operations and options
- **`imgxsh-extract-pdf.bats`**: Test suite covering PDF extraction functionality (40+ tests)

## 🔧 Test Runners

### Comprehensive Test Runner (`run-tests.sh`)

The main test runner using the Bats framework:

```bash
# Run all tests
./tests/run-tests.sh

# Run specific test file
./tests/run-tests.sh tests/imgxsh-convert.bats
./tests/run-tests.sh tests/imgxsh-resize.bats
./tests/run-tests.sh tests/imgxsh-extract-pdf.bats

# Run with verbose output
./tests/run-tests.sh --verbose

# Run in parallel (requires GNU parallel: brew install parallel)
./tests/run-tests.sh --parallel 4

# Run in CI mode
./tests/run-tests.sh --ci

# Set up Bats framework
./tests/run-tests.sh --setup
```

**Features:**
- Automatic Bats framework setup
- Dependency checking and mocking
- CI mode optimization
- TAP output support
- Parallel test execution (requires GNU parallel)
- Test result artifacts

**Parallel Testing Requirements:**
For parallel test execution, GNU `parallel` must be installed:
```bash
# macOS (Homebrew)
brew install parallel

# Ubuntu/Debian  
sudo apt-get install parallel

# Verify installation
parallel --version
```

If GNU `parallel` is not available, tests will run sequentially (which is perfectly fine for most development).

### CI Test Runner (`run-tests-ci.sh`)

CI-optimized test runner following Shell Starter patterns:

```bash
# Run CI-optimized tests
./tests/run-tests-ci.sh
```

**Features:**
- Automatic CI environment setup via `setup-ci-environment.sh`
- Bats framework auto-initialization
- Individual test file execution (Shell Starter pattern)
- Comprehensive error reporting and test summaries
- Container-aware path resolution
- Cross-platform ImageMagick command detection

**Use Cases:**
- GitHub Actions CI/CD workflows
- Local CI simulation with Act
- Container-based testing environments
- Automated quality assurance

## 📝 Test Writing Conventions

### Test File Structure

Each tool should have a corresponding `.bats` test file:

```bash
#!/usr/bin/env bats

# Load testing libraries
load 'test_helper'

# Test setup
setup() {
    # Initialize test environment
    setup_test_environment
    
    # Create test fixtures if needed
    create_test_image "test_input.png"
}

# Test cleanup
teardown() {
    # Clean up test resources
    cleanup_test_environment
}

# Test cases
@test "tool shows help when --help flag is used" {
    run imgxsh-tool --help
    assert_success
    assert_output --partial "Usage:"
}

@test "tool shows version when --version flag is used" {
    run imgxsh-tool --version
    assert_success
    assert_output --regexp "imgxsh-tool [0-9]+\.[0-9]+\.[0-9]+"
}

# More test cases...
```

### Test Categories

#### 1. Interface Tests
Test CLI interface and argument parsing:

```bash
@test "shows help with --help flag" {
    run imgxsh-convert --help
    assert_success
    assert_output --partial "Usage:"
}

@test "shows version with --version flag" {
    run imgxsh-convert --version
    assert_success
    assert_output --regexp "imgxsh-convert [0-9]"
}

@test "fails with missing required arguments" {
    run imgxsh-convert
    assert_failure
    assert_output --partial "required"
}
```

#### 2. Functionality Tests
Test core functionality with real operations:
#### imgxsh-resize Examples
```bash
# Single-file width resize with no-upscale default
run "$PROJECT_ROOT/bin/imgxsh-resize" --width 200 in.png out.png
assert_success
run get_image_dimensions "out.png"
assert_output "<original-or-200>x<original-or-200>"

# Allow upscaling explicitly
run "$PROJECT_ROOT/bin/imgxsh-resize" --allow-upscale --width 200 in.png out.png
assert_success
```

```bash
@test "converts PNG to JPG successfully" {
    create_test_image "input.png"
    
    run imgxsh-convert input.png output.jpg
    assert_success
    assert_file_exists "output.jpg"
    
    # Verify output format
    run identify output.jpg
    assert_output --partial "JPEG"
}
```

#### 3. Error Handling Tests
Test error conditions and edge cases:

```bash
@test "handles missing input file gracefully" {
    run imgxsh-convert nonexistent.png output.jpg
    assert_failure
    assert_output --partial "Cannot read file"
}

@test "validates output format" {
    create_test_image "input.png"
    
    run imgxsh-convert input.png output.invalid
    assert_failure
    assert_output --partial "Unsupported format"
}
```

#### 4. Integration Tests
Test workflow execution and complex scenarios:

```bash
@test "executes workflow with multiple steps" {
    create_test_pdf_with_images "test.pdf"
    
    run imgxsh --workflow pdf-to-thumbnails test.pdf
    assert_success
    assert_directory_exists "output"
    assert_file_count "output/*.jpg" 3
}
```

## 🛠 Test Helper Functions

The `test_helper.bash` file provides common utilities:

### Environment Management
```bash
setup_test_environment()     # Initialize clean test environment
cleanup_test_environment()   # Clean up test resources
require_dependency()         # Check for required tools
mock_missing_dependency()    # Mock missing dependencies for CI
```

### Test File Creation
```bash
create_test_image()          # Create test images using ImageMagick
create_test_pdf()           # Create test PDF files
create_test_excel()         # Create test Excel files
verify_image_format()       # Verify image format and properties
```

### Assertions
```bash
assert_file_exists()        # Assert file exists
assert_directory_exists()   # Assert directory exists
assert_file_count()         # Assert number of files matching pattern
assert_image_format()       # Assert image format
assert_image_dimensions()   # Assert image dimensions
```

### CI Optimizations
```bash
is_ci_environment()         # Detect CI environment
disable_spinners()          # Disable Shell Starter spinners
set_test_timeouts()         # Configure appropriate timeouts
```

## 🎯 Testing Patterns

### Pattern 1: Basic Tool Testing

```bash
@test "tool basic functionality" {
    # Setup
    create_test_input
    
    # Execute
    run tool-name input output
    
    # Verify
    assert_success
    assert_file_exists "output"
    assert_expected_output
}
```

### Pattern 2: Workflow Testing

```bash
@test "workflow execution" {
    # Setup workflow environment
    setup_workflow_test
    
    # Execute with dry-run first
    run imgxsh --workflow test-workflow --dry-run input
    assert_success
    assert_output --partial "would execute"
    
    # Execute actual workflow
    run imgxsh --workflow test-workflow input
    assert_success
    verify_workflow_output
}
```

### Pattern 3: Error Testing

```bash
@test "error handling" {
    # Test various error conditions
    run tool-name --invalid-option
    assert_failure
    assert_output --partial "Unknown option"
    
    run tool-name missing-file
    assert_failure
    assert_output --partial "Cannot read file"
}
```

### Pattern 4: Dependency Testing

```bash
@test "dependency requirements" {
    # Mock missing dependency
    mock_missing_dependency "imagemagick"
    
    # Test graceful failure
    run imgxsh-convert input.png output.jpg
    assert_failure
    assert_output --partial "ImageMagick is required"
    assert_output --partial "Install with:"
}
```

## 🔄 CI/CD Integration

### GitHub Actions Workflows

The project includes two CI workflows:

#### 1. Test Suite (`.github/workflows/test.yml`)
- Runs on Ubuntu with full dependency installation
- Executes comprehensive test suite
- Includes ShellCheck and shfmt validation
- Tests basic functionality and workflow validation
- Generates test artifacts

#### 2. Cross-Platform Compatibility (`.github/workflows/compatibility.yml`)
- Tests on Ubuntu and macOS
- Validates dependency detection across platforms
- Tests core functionality on different systems
- Runs weekly to catch dependency changes

### CI Environment Variables

```bash
CI=true                          # Standard CI environment indicator
SHELL_STARTER_CI_MODE=1         # Shell Starter CI optimizations
SHELL_STARTER_SPINNER_DISABLED=1 # Disable spinners in CI
BATS_NO_PARALLELIZE_ACROSS_FILES=1 # Bats CI optimization
```

### Test Artifacts

CI runs generate artifacts:
- `test-results.xml` - Test results in XML format
- `test-output.log` - Complete test output log
- Test coverage reports (when available)

## 📊 Test Coverage Guidelines

### Minimum Coverage Requirements
- **Core Functions**: 80% test coverage minimum
- **CLI Interface**: 100% argument and option coverage
- **Error Handling**: All error paths tested
- **Integration**: Major workflows tested end-to-end

### Coverage Areas

#### Tool-Level Coverage
- [ ] Help and version display
- [ ] All command-line options
- [ ] Input validation
- [ ] Core functionality
- [ ] Error conditions
- [ ] Output verification

#### Workflow-Level Coverage
- [ ] YAML parsing and validation
- [ ] Step execution
- [ ] Conditional logic
- [ ] Template substitution
- [ ] Hook execution
- [ ] Error handling and recovery

#### Integration Coverage
- [ ] Cross-tool workflows
- [ ] File format conversions
- [ ] Batch processing
- [ ] External dependency integration
- [ ] Configuration management

## 🚀 Performance Testing

### Benchmark Tests
```bash
@test "batch processing performance" {
    # Create multiple test files
    create_test_images 50
    
    # Time the batch operation
    start_time=$(date +%s)
    run imgxsh --workflow batch-convert *.png
    end_time=$(date +%s)
    
    # Verify performance expectations
    duration=$((end_time - start_time))
    [[ $duration -lt 30 ]]  # Should complete in under 30 seconds
}
```

### Memory Usage Tests
```bash
@test "memory efficiency with large files" {
    create_large_test_image "large.png" "4000x4000"
    
    # Monitor memory usage during processing
    run_with_memory_monitoring imgxsh-resize large.png resized.png --width 1000
    
    # Verify memory usage stays reasonable
    assert_memory_usage_under "500MB"
}
```

## 🔧 Debugging Tests

### Debug Mode
```bash
# Run tests with debug output
DEBUG=1 ./tests/run-tests.sh

# Run specific test with verbose Bats output
./tests/run-tests.sh --verbose tests/imgxsh-convert.bats
./tests/run-tests.sh --verbose tests/imgxsh-extract-pdf.bats
```

### Test Isolation
```bash
# Run single test case
./tests/bats-core/bin/bats -f "specific test name" tests/imgxsh-convert.bats

# Skip cleanup for debugging
SKIP_CLEANUP=1 ./tests/run-tests.sh
```

### Manual Testing
```bash
# Test basic functionality manually
./tests/run-basic-tests.sh

# Test specific tool manually
./bin/imgxsh-convert --help
./bin/imgxsh-convert test.png test.jpg --verbose
```

## 📚 Best Practices

### Writing Effective Tests
1. **Test One Thing**: Each test should verify one specific behavior
2. **Use Descriptive Names**: Test names should clearly describe what's being tested
3. **Setup and Cleanup**: Always clean up test resources
4. **Independent Tests**: Tests should not depend on each other
5. **Fast Execution**: Optimize for quick feedback loops

### Test Maintenance
1. **Keep Tests Updated**: Update tests when functionality changes
2. **Remove Obsolete Tests**: Delete tests for removed features
3. **Refactor Common Code**: Extract reusable test utilities
4. **Document Complex Tests**: Add comments for complex test scenarios

### CI Optimization
1. **Parallel Execution**: Use parallel testing when possible
2. **Fail Fast**: Configure tests to fail quickly on errors
3. **Artifact Collection**: Collect useful artifacts for debugging
4. **Resource Management**: Clean up resources to avoid CI limits

## 🚀 CI/CD Setup and Lessons Learned

### Shell Starter CI Integration

This project successfully integrates with Shell Starter CI patterns through extensive debugging and refinement. Here are the key lessons learned:

#### Critical Success Factors

1. **Follow Shell Starter Patterns Exactly**
   - Use `shell-starter-tests` as a guide, not a permanent part of the repository
   - Maintain separate CI scripts: `run-tests-ci.sh` and `setup-ci-environment.sh`
   - Local tests must work perfectly before CI integration

2. **Environment-Specific Configuration**
   ```bash
   # CI Environment Variables (automatically set)
   export CI=true
   export SHELL_STARTER_CI_MODE=true
   export SHELL_STARTER_SPINNER_DISABLED=true
   # Note: Don't set BATS_NO_PARALLELIZE_ACROSS_FILES without --jobs 2+
   ```

3. **Cross-Platform ImageMagick Compatibility**
   ```bash
   # Smart command detection in CI
   if command -v magick >/dev/null 2>&1; then
       imagemagick_cmd="magick"
   elif command -v convert >/dev/null 2>&1; then
       imagemagick_cmd="convert"
   fi
   ```

#### CI Script Architecture

**`tests/setup-ci-environment.sh`**:
- Environment variable configuration
- Dependency checking with fallbacks
- Path setup and cleanup handling
- Tool availability verification

**`tests/run-tests-ci.sh`**:
- Bats framework auto-setup
- Individual test file execution (Shell Starter pattern)
- Comprehensive error reporting
- Test result summarization

#### Common CI Pitfalls and Solutions

1. **Bats Configuration Errors**
   ```bash
   # ❌ WRONG: Causes "requires at least --jobs 2" error
   export BATS_NO_PARALLELIZE_ACROSS_FILES=true
   
   # ✅ CORRECT: Only set when using parallel jobs
   # Don't set this flag for single-file execution
   ```

2. **ImageMagick Command Conflicts**
   ```bash
   # ❌ WRONG: Hardcoded command
   magick "$input" -quality 85 "$output"
   
   # ✅ CORRECT: Environment-aware detection
   local imagemagick_cmd="magick"
   if ! command -v magick >/dev/null 2>&1 && command -v convert >/dev/null 2>&1; then
       imagemagick_cmd="convert"
   fi
   ```

3. **Path Resolution in Containers**
   ```bash
   # ❌ WRONG: Assumes host paths
   PROJECT_ROOT="/Users/user/project"
   
   # ✅ CORRECT: Dynamic path resolution
   PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
   ```

#### Act (Local GitHub Actions) Testing

Essential for CI validation:
```bash
# Test specific job
act -W .github/workflows/ci.yml --job test --pull=false

# Test all workflows  
act --pull=false

# Debug with verbose output
act -W .github/workflows/ci.yml --job test -v
```

**Key Act Insights**:
- Use `--pull=false` to avoid Docker registry timeouts
- Container environment differs from local (Ubuntu vs macOS)
- ImageMagick version differences require command detection
- Test execution time indicates whether tests are actually running

#### Act Compatibility Testing

The compatibility workflow was restructured to work properly with act:

```bash
# Run Ubuntu compatibility tests
act -j compatibility-ubuntu

# Use the convenient script
./scripts/run-act-compatibility.sh ubuntu
./scripts/run-act-compatibility.sh both
```

**Compatibility Workflow Fixes**:
- **Matrix Strategy Issue**: Original `runs-on: ${{ matrix.os }}` caused Docker image reference errors
- **Solution**: Split into separate jobs (`compatibility-ubuntu`, `compatibility-macos`)
- **GPG Signature Handling**: Added robust apt installation with `--allow-unauthenticated` fallback
- **Platform Limitations**: act cannot simulate macOS; use GitHub Actions for full macOS testing

#### GitHub Actions Workflow Structure

```yaml
# .github/workflows/ci.yml
jobs:
  test:
    runs-on: ubuntu-latest
    timeout-minutes: 25
    steps:
    - uses: actions/checkout@v4
    - name: Install system dependencies
      run: |
        sudo apt-get update
        sudo apt-get install -y imagemagick poppler-utils unzip curl
    - name: Run Bats tests
      run: |
        if [ -d tests ] && ls tests/*.bats 1> /dev/null 2>&1; then
          ./tests/run-tests-ci.sh
        else
          echo "No tests directory or test files found. Skipping tests."
        fi
```

#### Testing Strategy Evolution

1. **Start Local**: Ensure all tests pass locally with multiple modes
2. **Follow Patterns**: Use Shell Starter conventions exactly
3. **Debug Systematically**: Use Act for local CI simulation
4. **Fix Root Causes**: Address environment differences, not symptoms
5. **Document Everything**: Capture lessons for future development

#### Debugging Process Documentation

Our CI setup went through several iterations. Here's the systematic debugging approach:

**Phase 1: Initial Failures**
- Issue: Tests failed immediately in CI (3-second failures)
- Root Cause: Missing or incorrectly configured CI scripts
- Solution: Restored `run-tests-ci.sh` and `setup-ci-environment.sh` from Shell Starter patterns

**Phase 2: Bats Configuration Issues**
- Issue: `Error: The flag --no-parallelize-across-files requires at least --jobs 2`
- Root Cause: Environment variable `BATS_NO_PARALLELIZE_ACROSS_FILES=true` without parallel jobs
- Solution: Removed the flag for single-file test execution

**Phase 3: ImageMagick Command Detection**
- Issue: Tests passed locally but failed in CI with `magick: command not found`
- Root Cause: Container has `convert` but not `magick` command
- Solution: Dynamic command detection with fallback logic

**Phase 4: Path Resolution**
- Issue: Project root incorrectly calculated in container environment
- Root Cause: Different filesystem structure in Docker containers
- Solution: Improved path resolution logic with container awareness

**Debugging Tools Used**:
```bash
# Local CI simulation
act -W .github/workflows/ci.yml --job test --pull=false

# Verbose debugging
act -W .github/workflows/ci.yml --job test -v | tail -50

# Direct container testing
docker run --rm -v $(pwd):/workspace -w /workspace catthehacker/ubuntu:act-latest bash -c "command"

# Test isolation
tests/run-tests-ci.sh  # Local CI runner test
```

**Key Debugging Insights**:
- **Execution time indicates success**: 3s = immediate failure, 40s+ = actual test execution
- **Error messages can be misleading**: Environment issues often manifest as test failures
- **Container vs local differences**: Always test both environments
- **Shell Starter patterns work**: Following established patterns prevents most issues

#### Performance Insights

- **Local Tests**: ~6-8 seconds for 30 tests
- **CI Tests**: ~40-45 seconds (includes setup, dependencies)
- **Act Simulation**: ~60-90 seconds (includes Docker overhead)

#### Dependency Management

**Required Dependencies**:
- ImageMagick (`magick` or `convert` + `identify`)
- poppler-utils (`pdfimages`)
- unzip (Excel processing)

**Optional Dependencies**:
- Tesseract OCR
- curl (webhooks)
- notify-send/osascript (notifications)

**CI Installation**:
```bash
# Ubuntu/GitHub Actions
sudo apt-get install -y imagemagick poppler-utils unzip curl

# macOS (local development)
brew install imagemagick poppler tesseract
```

## 🔍 Troubleshooting

### Common Test Issues

#### Dependency Problems
```bash
# Check dependencies
./bin/imgxsh-check-deps

# Install missing dependencies (macOS)
brew install imagemagick poppler tesseract

# Install missing dependencies (Ubuntu)
sudo apt-get install imagemagick poppler-utils tesseract-ocr
```

#### Bats Framework Issues
```bash
# Reinitialize Bats framework
./tests/run-tests.sh --setup

# Check Bats installation
./tests/bats-core/bin/bats --version

# Fix parallel execution errors
unset BATS_NO_PARALLELIZE_ACROSS_FILES  # Remove if not using --jobs

# Test Bats directly
./tests/bats-core/bin/bats tests/imgxsh-convert.bats
```

#### CI-Specific Issues

**Act Simulation Failures**:
```bash
# Network timeouts
act --pull=false  # Use cached images

# Container platform warnings
# WARNING: The requested image's platform (linux/amd64) does not match...
# This is expected on ARM Macs, tests will still work

# Job execution time debugging
# <3 seconds = immediate failure (config issue)
# 40+ seconds = actual test execution (may pass or fail on content)
```

**ImageMagick Command Issues in CI**:
```bash
# Check available commands in container
docker run --rm catthehacker/ubuntu:act-latest bash -c "which magick convert identify"

# Test command detection logic
if ! command -v magick >/dev/null 2>&1 && command -v convert >/dev/null 2>&1; then
    echo "Using convert command (legacy ImageMagick)"
else
    echo "Using magick command (modern ImageMagick)"
fi
```

**Environment Variable Issues**:
```bash
# Check CI environment setup
echo "CI: $CI"
echo "SHELL_STARTER_CI_MODE: $SHELL_STARTER_CI_MODE"
echo "PATH: $PATH"

# Reset environment if needed
unset BATS_NO_PARALLELIZE_ACROSS_FILES
export CI=true
export SHELL_STARTER_CI_MODE=true
```

#### Test Environment Issues
```bash
# Clean test environment
rm -rf /tmp/imgxsh-test-*

# Reset test fixtures
rm -rf tests/fixtures/generated/
```

### Getting Help

- Check test output logs in `tests/ci-output/`
- Run tests with `--verbose` flag for detailed output
- Use `DEBUG=1` environment variable for debug information
- Review GitHub Actions logs for CI failures

## 📈 Future Enhancements

### Planned Testing Improvements
- [ ] Test coverage reporting with detailed metrics
- [ ] Performance regression testing
- [ ] Visual diff testing for image outputs
- [ ] Fuzz testing for edge cases
- [ ] Integration with external testing services
- [ ] Automated test generation for new tools

### Testing Tools Integration
- [ ] ShellCheck integration in test pipeline
- [ ] Code coverage tools for shell scripts
- [ ] Performance monitoring and alerting
- [ ] Test result visualization
- [ ] Automated test documentation generation

## 📋 Quick Reference

### Essential Commands

```bash
# Local development
./tests/run-tests.sh                    # Run all tests locally
./tests/run-tests.sh --verbose          # Run with detailed output
./tests/run-tests.sh --setup            # Set up Bats framework
./tests/run-tests.sh --parallel 4       # Parallel execution (requires GNU parallel)

# CI testing
./tests/run-tests-ci.sh                 # Run CI-optimized tests
act -W .github/workflows/ci.yml --job test --pull=false  # Simulate CI locally

# Debugging
./bin/imgxsh-check-deps                 # Check dependencies
./tests/bats-core/bin/bats tests/imgxsh-convert.bats  # Run specific test file
DEBUG=1 ./tests/run-tests.sh            # Enable debug output
```

### File Structure Quick Guide

```
tests/
├── run-tests.sh              # Main test runner (local development)
├── run-tests-ci.sh           # CI-optimized test runner
├── setup-ci-environment.sh   # CI environment configuration
├── test_helper.bash          # Shared test utilities
├── imgxsh-convert.bats       # Test suite for imgxsh-convert
├── bats-core/               # Bats testing framework
├── bats-assert/             # Assertion helpers
├── bats-support/            # Support utilities
└── fixtures/                # Test data and images
```

### CI Workflow Status Checklist

Before pushing to GitHub, ensure:

- ✅ `./tests/run-tests.sh` passes locally (all modes)
- ✅ `./tests/run-tests-ci.sh` passes locally  
- ✅ `act -W .github/workflows/ci.yml --job test --pull=false` passes
- ✅ ShellCheck and shfmt pass (`act` shows all green)
- ✅ Dependencies are properly detected in both environments

### Common Issues Quick Fixes

| Issue | Quick Fix |
|-------|-----------|
| `BATS_NO_PARALLELIZE_ACROSS_FILES requires --jobs 2` | `unset BATS_NO_PARALLELIZE_ACROSS_FILES` |
| `parallel: command not found` with `--parallel` | `brew install parallel` or omit `--parallel` flag |
| `magick: command not found` in CI | Check ImageMagick command detection logic |
| Tests fail immediately (3s) | Missing/broken CI scripts |
| Tests run but fail content | Environment differences (paths, commands) |
| Act network timeouts | Use `act --pull=false` |

## Lessons Learned: CI Integration with bats-action

### The Challenge: Multiple Bats Environments

During CI setup, we discovered a complex interaction between:
- **Local vendored bats**: `tests/bats-core/bin/bats` with libraries in `tests/bats-*`
- **System bats from bats-action**: `/home/runner/.local/share/bats/bin/bats` with libraries in `/usr/lib/bats-*`
- **Bats default BATS_LIB_PATH**: `/usr/lib/bats` (set by bats executable itself)

### Root Cause Analysis

The critical insight was that **bats executables and bats libraries must match**:
- ❌ **Wrong**: System bats + vendored libraries → `Could not find library 'bats-support'`
- ❌ **Wrong**: Vendored bats + system libraries → Path mismatches
- ✅ **Correct**: System bats + system libraries in CI, vendored bats + vendored libraries locally

### Solution Architecture

#### 1. CI Workflow Integration
```yaml
- name: Setup Bats and Bats libs
  uses: bats-core/bats-action@3.0.1
  with:
    bats-install: true
    support-install: true
    assert-install: true
    file-install: true
```

#### 2. Environment-Aware Library Detection
```bash
# test_helper.bash - CI-first detection
if [[ -n "${CI:-}" ]] && [[ -d "/usr/lib/bats-support" ]]; then
    export BATS_LIB_PATH="/usr/lib"  # System libraries from bats-action
elif [[ -d "${PROJECT_ROOT}/tests/bats-support" ]]; then
    export BATS_LIB_PATH="${PROJECT_ROOT}/tests"  # Local vendored libraries
fi
```

#### 3. Bats Executable Selection
```bash
# run-tests-ci.sh - Environment-aware bats selection
if [[ -n "${CI:-}" ]] && command -v bats >/dev/null 2>&1; then
    BATS_CMD="$(command -v bats)"  # Use system bats in CI
elif [[ -f "$PROJECT_ROOT/tests/bats-core/bin/bats" ]]; then
    BATS_CMD="$PROJECT_ROOT/tests/bats-core/bin/bats"  # Use vendored locally
fi
```

#### 4. Test Environment Compatibility
```bash
# Handle dependency vs logic errors
if [[ "$output" == *"Missing required dependencies"* ]]; then
    assert_output --partial "Missing required dependencies"  # CI without ImageMagick
else
    assert_output --partial "Cannot read input file"  # Local with ImageMagick
fi
```

### Key Success Factors

1. **Environment Detection**: Always check CI vs local environment first
2. **Library Path Consistency**: Match bats executable with corresponding libraries
3. **Override Bats Defaults**: Don't rely on bats built-in BATS_LIB_PATH defaults
4. **Test Robustness**: Handle both dependency errors and logic errors in tests
5. **Debug Systematically**: Add debug output to understand actual vs expected paths

### Debugging Workflow

When CI fails with library loading issues:
1. **Check bats executable**: Which bats is actually running?
2. **Check library paths**: Where are libraries actually installed?
3. **Check BATS_LIB_PATH**: What path is being used for library discovery?
4. **Verify consistency**: Do the bats executable and libraries match?

### Production-Ready Configuration

The final working setup:
- **✅ Local Development**: Vendored bats + vendored libraries via `tests/run-tests.sh`
- **✅ CI Environment**: System bats + system libraries via bats-action
- **✅ Cross-Platform**: Works on macOS (local) and Ubuntu (CI)
- **✅ Dependency Aware**: Handles ImageMagick presence/absence gracefully
- **✅ Shell Starter Compatible**: Follows all framework conventions

---

This testing framework provides comprehensive coverage for imgxsh functionality while maintaining compatibility with Shell Starter conventions and enabling reliable CI/CD integration.

**Key Success Factors**: Follow Shell Starter patterns exactly, test locally first, use Act for CI validation, understand bats environment interactions, and document everything for future development.
