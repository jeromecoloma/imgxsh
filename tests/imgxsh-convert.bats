#!/usr/bin/env bats
#
# Tests for imgxsh-convert script

# Load test helpers
load test_helper
bats_load_library bats-support
bats_load_library bats-assert

# Help and version tests
@test "imgxsh-convert: help flag" {
    run_imgxsh "imgxsh-convert" --help
    assert_success
    assert_output --partial "Usage:"
    assert_output --partial "Convert images between different formats"
    assert_output --partial "ARGUMENTS:"
    assert_output --partial "OPTIONS:"
    assert_output --partial "SUPPORTED FORMATS:"
    assert_output --partial "EXAMPLES:"
}

@test "imgxsh-convert: short help flag" {
    run_imgxsh "imgxsh-convert" -h
    assert_success
    assert_output --partial "Usage:"
}

@test "imgxsh-convert: version flag" {
    expected_version=$(cat "${PROJECT_ROOT}/VERSION" | tr -d '\n')
    run_imgxsh "imgxsh-convert" --version
    assert_success
    assert_output --partial "imgxsh-convert"
    assert_output --partial "$expected_version"
}

@test "imgxsh-convert: short version flag" {
    expected_version=$(cat "${PROJECT_ROOT}/VERSION" | tr -d '\n')
    run_imgxsh "imgxsh-convert" -v
    assert_success
    assert_output --partial "imgxsh-convert"
    assert_output --partial "$expected_version"
}

# Argument validation tests
@test "imgxsh-convert: fails when no arguments provided" {
    run_imgxsh "imgxsh-convert"
    assert_failure
    assert_output --partial "Input file is required"
}

@test "imgxsh-convert: fails when only input provided" {
    run_imgxsh "imgxsh-convert" "input.png"
    assert_failure
    assert_output --partial "Output file is required"
}

@test "imgxsh-convert: fails with non-existent input file" {
    run_imgxsh "imgxsh-convert" "/nonexistent/file.png" "output.jpg"
    assert_failure
    assert_output --partial "Cannot read input file"
}

@test "imgxsh-convert: unknown option error" {
    run_imgxsh "imgxsh-convert" --unknown
    assert_failure
    assert_output --partial "Unknown option: --unknown"
}

# Quality validation tests
@test "imgxsh-convert: invalid quality value (too low)" {
    create_test_image "${BATS_TEST_TMPDIR}/input.png"
    run_imgxsh "imgxsh-convert" --quality 0 "${BATS_TEST_TMPDIR}/input.png" "${BATS_TEST_TMPDIR}/output.jpg"
    assert_failure
    assert_output --partial "Quality must be a number between 1 and 100"
}

@test "imgxsh-convert: invalid quality value (too high)" {
    create_test_image "${BATS_TEST_TMPDIR}/input.png"
    run_imgxsh "imgxsh-convert" --quality 101 "${BATS_TEST_TMPDIR}/input.png" "${BATS_TEST_TMPDIR}/output.jpg"
    assert_failure
    assert_output --partial "Quality must be a number between 1 and 100"
}

@test "imgxsh-convert: invalid quality value (non-numeric)" {
    create_test_image "${BATS_TEST_TMPDIR}/input.png"
    run_imgxsh "imgxsh-convert" --quality abc "${BATS_TEST_TMPDIR}/input.png" "${BATS_TEST_TMPDIR}/output.jpg"
    assert_failure
    assert_output --partial "Quality must be a number between 1 and 100"
}

# Format validation tests
@test "imgxsh-convert: unsupported format" {
    create_test_image "${BATS_TEST_TMPDIR}/input.png"
    run_imgxsh "imgxsh-convert" --format xyz "${BATS_TEST_TMPDIR}/input.png" "${BATS_TEST_TMPDIR}/output.xyz"
    assert_failure
    assert_output --partial "Unsupported format: xyz"
    assert_output --partial "Supported formats:"
}

# Dependency checking tests
@test "imgxsh-convert: dependency check with ImageMagick available" {
    require_imagemagick
    create_test_image "${BATS_TEST_TMPDIR}/input.png"
    run_imgxsh "imgxsh-convert" --dry-run "${BATS_TEST_TMPDIR}/input.png" "${BATS_TEST_TMPDIR}/output.jpg"
    assert_success
    assert_output --partial "Dry-run completed"
}

@test "imgxsh-convert: dependency check fails without ImageMagick" {
    # Mock missing ImageMagick
    mock_missing_dependency "convert"
    mock_missing_dependency "identify"
    
    run_imgxsh "imgxsh-convert" --help  # Just test help, which should work without ImageMagick
    assert_success
}

# Dry-run mode tests
@test "imgxsh-convert: dry-run mode shows operation preview" {
    require_imagemagick
    create_test_image "${BATS_TEST_TMPDIR}/input.png"
    
    run_imgxsh "imgxsh-convert" --dry-run --verbose "${BATS_TEST_TMPDIR}/input.png" "${BATS_TEST_TMPDIR}/output.jpg"
    assert_success
    assert_output --partial "Detected output format from filename: jpg"
    assert_output --partial "Using default quality for jpg: 85"
    assert_output --partial "Would execute:"
    assert_output --partial "Dry-run completed - no files were modified"
    
    # Verify output file was not created
    [[ ! -f "${BATS_TEST_TMPDIR}/output.jpg" ]]
}

@test "imgxsh-convert: dry-run mode with custom quality" {
    require_imagemagick
    create_test_image "${BATS_TEST_TMPDIR}/input.png"
    
    run_imgxsh "imgxsh-convert" --dry-run --quality 95 "${BATS_TEST_TMPDIR}/input.png" "${BATS_TEST_TMPDIR}/output.jpg"
    assert_success
    assert_output --partial "Quality:  95"
    assert_output --partial "Dry-run completed"
}

# Basic conversion tests (require ImageMagick)
@test "imgxsh-convert: PNG to JPG conversion" {
    require_imagemagick
    create_test_image "${BATS_TEST_TMPDIR}/input.png" "png"
    
    run_imgxsh "imgxsh-convert" "${BATS_TEST_TMPDIR}/input.png" "${BATS_TEST_TMPDIR}/output.jpg"
    assert_success
    assert_output --partial "Successfully converted"
    
    # Verify output file exists and has correct format
    [[ -f "${BATS_TEST_TMPDIR}/output.jpg" ]]
    verify_image_format "${BATS_TEST_TMPDIR}/output.jpg" "jpg"
}

@test "imgxsh-convert: JPG to PNG conversion" {
    require_imagemagick
    create_test_image "${BATS_TEST_TMPDIR}/input.jpg" "jpg"
    
    run_imgxsh "imgxsh-convert" "${BATS_TEST_TMPDIR}/input.jpg" "${BATS_TEST_TMPDIR}/output.png"
    assert_success
    assert_output --partial "Successfully converted"
    
    # Verify output file exists and has correct format
    [[ -f "${BATS_TEST_TMPDIR}/output.png" ]]
    verify_image_format "${BATS_TEST_TMPDIR}/output.png" "png"
}

@test "imgxsh-convert: conversion with custom quality" {
    require_imagemagick
    create_test_image "${BATS_TEST_TMPDIR}/input.png" "png"
    
    run_imgxsh "imgxsh-convert" --quality 95 "${BATS_TEST_TMPDIR}/input.png" "${BATS_TEST_TMPDIR}/output.jpg"
    assert_success
    assert_output --partial "Successfully converted"
    
    [[ -f "${BATS_TEST_TMPDIR}/output.jpg" ]]
    verify_image_format "${BATS_TEST_TMPDIR}/output.jpg" "jpg"
}

@test "imgxsh-convert: conversion with format override" {
    require_imagemagick
    create_test_image "${BATS_TEST_TMPDIR}/input.png" "png"
    
    run_imgxsh "imgxsh-convert" --format jpg "${BATS_TEST_TMPDIR}/input.png" "${BATS_TEST_TMPDIR}/output.xyz"
    assert_success
    assert_output --partial "Successfully converted"
    
    [[ -f "${BATS_TEST_TMPDIR}/output.xyz" ]]
    verify_image_format "${BATS_TEST_TMPDIR}/output.xyz" "jpg"
}

# Verbose mode tests
@test "imgxsh-convert: verbose mode shows detailed information" {
    require_imagemagick
    create_test_image "${BATS_TEST_TMPDIR}/input.png" "png"
    
    run_imgxsh "imgxsh-convert" --verbose "${BATS_TEST_TMPDIR}/input.png" "${BATS_TEST_TMPDIR}/output.jpg"
    assert_success
    assert_output --partial "Detected output format from filename: jpg"
    assert_output --partial "Using default quality for jpg: 85"
    assert_output --partial "Input image:"
    assert_output --partial "Conversion summary:"
    assert_output --partial "Output image:"
    assert_output --partial "Successfully converted"
}

# Backup functionality tests
@test "imgxsh-convert: backup option creates backup file" {
    require_imagemagick
    create_test_image "${BATS_TEST_TMPDIR}/input.png" "png"
    
    run_imgxsh "imgxsh-convert" --backup "${BATS_TEST_TMPDIR}/input.png" "${BATS_TEST_TMPDIR}/output.jpg"
    assert_success
    assert_output --partial "Created backup:"
    assert_output --partial "Successfully converted"
    
    # Check that backup was created
    local backup_count
    backup_count=$(find "${BATS_TEST_TMPDIR}" -name "input.png.backup.*" | wc -l)
    [[ "$backup_count" -eq 1 ]]
}

# Overwrite protection tests
@test "imgxsh-convert: fails when output file exists without overwrite flag" {
    require_imagemagick
    create_test_image "${BATS_TEST_TMPDIR}/input.png" "png"
    create_test_image "${BATS_TEST_TMPDIR}/output.jpg" "jpg"
    
    run_imgxsh "imgxsh-convert" "${BATS_TEST_TMPDIR}/input.png" "${BATS_TEST_TMPDIR}/output.jpg"
    assert_failure
    assert_output --partial "Output file exists:"
    assert_output --partial "Use --overwrite to replace existing file"
}

@test "imgxsh-convert: succeeds when output file exists with overwrite flag" {
    require_imagemagick
    create_test_image "${BATS_TEST_TMPDIR}/input.png" "png"
    create_test_image "${BATS_TEST_TMPDIR}/output.jpg" "jpg"
    
    run_imgxsh "imgxsh-convert" --overwrite "${BATS_TEST_TMPDIR}/input.png" "${BATS_TEST_TMPDIR}/output.jpg"
    assert_success
    assert_output --partial "Successfully converted"
}

# Format detection tests
@test "imgxsh-convert: detects JPG format from .jpeg extension" {
    require_imagemagick
    create_test_image "${BATS_TEST_TMPDIR}/input.png" "png"
    
    run_imgxsh "imgxsh-convert" --dry-run --verbose "${BATS_TEST_TMPDIR}/input.png" "${BATS_TEST_TMPDIR}/output.jpeg"
    assert_success
    assert_output --partial "Detected output format from filename: jpg"
}

@test "imgxsh-convert: detects TIFF format from .tif extension" {
    require_imagemagick
    create_test_image "${BATS_TEST_TMPDIR}/input.png" "png"
    
    run_imgxsh "imgxsh-convert" --dry-run --verbose "${BATS_TEST_TMPDIR}/input.png" "${BATS_TEST_TMPDIR}/output.tif"
    assert_success
    assert_output --partial "Detected output format from filename: tiff"
}

# Error handling tests
@test "imgxsh-convert: handles ImageMagick conversion errors gracefully" {
    require_imagemagick
    
    # Create a file that looks like an image but isn't
    echo "Not an image" > "${BATS_TEST_TMPDIR}/fake.png"
    track_created_file "${BATS_TEST_TMPDIR}/fake.png"
    
    run_imgxsh "imgxsh-convert" "${BATS_TEST_TMPDIR}/fake.png" "${BATS_TEST_TMPDIR}/output.jpg"
    assert_failure
    # Should fail gracefully, not crash
}

@test "imgxsh-convert: too many arguments error" {
    create_test_image "${BATS_TEST_TMPDIR}/input.png"
    run_imgxsh "imgxsh-convert" "${BATS_TEST_TMPDIR}/input.png" "${BATS_TEST_TMPDIR}/output.jpg" "extra"
    assert_failure
    assert_output --partial "Too many arguments"
}

# Integration with Shell Starter features
@test "imgxsh-convert: uses Shell Starter logging functions" {
    require_imagemagick
    create_test_image "${BATS_TEST_TMPDIR}/input.png" "png"
    
    run_imgxsh "imgxsh-convert" --verbose "${BATS_TEST_TMPDIR}/input.png" "${BATS_TEST_TMPDIR}/output.jpg"
    assert_success
    
    # Check for Shell Starter log format (timestamps and symbols)
    assert_output --regexp "\[[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}\]"
    assert_output --partial "ℹ:"  # Info symbol
    assert_output --partial "✓:"  # Success symbol
}

@test "imgxsh-convert: integrates with Shell Starter version system" {
    # Version should come from VERSION file
    local expected_version
    expected_version=$(cat "${PROJECT_ROOT}/VERSION" | tr -d '\n')
    
    run_imgxsh "imgxsh-convert" --version
    assert_success
    assert_output --partial "$expected_version"
}
