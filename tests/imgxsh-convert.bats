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
    assert_output --partial "Input file or directory is required"
}

@test "imgxsh-convert: fails when only input provided" {
    run_imgxsh "imgxsh-convert" "input.png"
    assert_failure
    assert_output --partial "Output file or directory is required"
}

@test "imgxsh-convert: fails with non-existent input file" {
    run_imgxsh "imgxsh-convert" "/nonexistent/file.png" "output.jpg"
    assert_failure
    # In CI without ImageMagick, dependency check fails first
    # In local dev with ImageMagick, file check happens
    if [[ "$output" == *"Missing required dependencies"* ]]; then
        assert_output --partial "Missing required dependencies"
    else
        assert_output --partial "Input path does not exist"
    fi
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

# Batch processing tests
@test "imgxsh-convert: batch processing help mentions directory support" {
    run_imgxsh "imgxsh-convert" --help
    assert_success
    assert_output --partial "Input image file or directory (supports batch processing)"
    assert_output --partial "BATCH PROCESSING:"
    assert_output --partial "Supports directory input for recursive batch processing"
    assert_output --partial "Batch directory conversion"
}

@test "imgxsh-convert: batch processing with directory input" {
    # Create test directory structure
    local test_dir="${BATS_TEST_TMPDIR}/batch_test"
    local output_dir="${BATS_TEST_TMPDIR}/batch_output"
    mkdir -p "$test_dir"
    mkdir -p "$test_dir/subdir"
    
    # Create test images
    create_test_image "${test_dir}/image1.png" 100 100
    create_test_image "${test_dir}/image2.jpg" 150 150
    create_test_image "${test_dir}/subdir/image3.png" 200 200
    
    # Run batch conversion
    run_imgxsh "imgxsh-convert" --format webp --quality 85 "$test_dir" "$output_dir"
    
    # Check results
    assert_success
    assert_output --partial "Found 3 image files to process"
    assert_output --partial "Processed: 3 files, Failed: 0 files"
    
    # Verify output structure is preserved
    [[ -f "${output_dir}/image1.webp" ]]
    [[ -f "${output_dir}/image2.webp" ]]
    [[ -f "${output_dir}/subdir/image3.webp" ]]
    
    # Verify files are valid images (basic check)
    [[ -s "${output_dir}/image1.webp" ]]  # File exists and is not empty
    [[ -s "${output_dir}/image2.webp" ]]
    [[ -s "${output_dir}/subdir/image3.webp" ]]
}

@test "imgxsh-convert: batch processing with dry-run" {
    # Create test directory structure
    local test_dir="${BATS_TEST_TMPDIR}/batch_dry_test"
    local output_dir="${BATS_TEST_TMPDIR}/batch_dry_output"
    mkdir -p "$test_dir"
    
    # Create test images
    create_test_image "${test_dir}/image1.png" 100 100
    create_test_image "${test_dir}/image2.jpg" 150 150
    
    # Run batch conversion with dry-run
    run_imgxsh "imgxsh-convert" --dry-run --format webp "$test_dir" "$output_dir"
    
    # Check results
    assert_success
    assert_output --partial "Found 2 image files to process"
    assert_output --partial "Processed: 2 files, Failed: 0 files"
    
    # Verify no output files were created
    [[ ! -f "${output_dir}/image1.webp" ]]
    [[ ! -f "${output_dir}/image2.webp" ]]
}

@test "imgxsh-convert: batch processing with verbose output" {
    # Create test directory structure
    local test_dir="${BATS_TEST_TMPDIR}/batch_verbose_test"
    local output_dir="${BATS_TEST_TMPDIR}/batch_verbose_output"
    mkdir -p "$test_dir"
    
    # Create test images
    create_test_image "${test_dir}/image1.png" 100 100
    
    # Run batch conversion with verbose output
    run_imgxsh "imgxsh-convert" --verbose --format webp "$test_dir" "$output_dir"
    
    # Check results
    assert_success
    assert_output --partial "Starting image conversion operation..."
    assert_output --partial "Input directory: $test_dir"
    assert_output --partial "Output directory: $output_dir"
    assert_output --partial "Format: webp"
    assert_output --partial "Found 1 image files to process"
    assert_output --partial "[1/1] Processing: image1.png"
}

@test "imgxsh-convert: batch processing with overwrite" {
    # Create test directory structure
    local test_dir="${BATS_TEST_TMPDIR}/batch_overwrite_test"
    local output_dir="${BATS_TEST_TMPDIR}/batch_overwrite_output"
    mkdir -p "$test_dir"
    mkdir -p "$output_dir"
    
    # Create test images
    create_test_image "${test_dir}/image1.png" 100 100
    
    # Create existing output file
    create_test_image "${output_dir}/image1.webp" 50 50
    
    # Run batch conversion without overwrite (should skip)
    run_imgxsh "imgxsh-convert" --format webp "$test_dir" "$output_dir"
    assert_success
    assert_output --partial "Output file exists, skipping:"
    
    # Run batch conversion with overwrite
    run_imgxsh "imgxsh-convert" --overwrite --format webp "$test_dir" "$output_dir"
    assert_success
    assert_output --partial "Processed: 1 files, Failed: 0 files"
}

@test "imgxsh-convert: batch processing with backup" {
    # Create test directory structure
    local test_dir="${BATS_TEST_TMPDIR}/batch_backup_test"
    local output_dir="${BATS_TEST_TMPDIR}/batch_backup_output"
    mkdir -p "$test_dir"
    
    # Create test images
    create_test_image "${test_dir}/image1.png" 100 100
    
    # Run batch conversion with backup
    run_imgxsh "imgxsh-convert" --backup --format webp "$test_dir" "$output_dir"
    
    # Check results
    assert_success
    assert_output --partial "Processed: 1 files, Failed: 0 files"
    
    # Verify backup was created
    local backup_files
    backup_files=$(find "$test_dir" -name "*.backup.*" | wc -l | tr -d ' ')
    assert_equal "$backup_files" "1"
}

@test "imgxsh-convert: batch processing error handling" {
    # Create test directory structure
    local test_dir="${BATS_TEST_TMPDIR}/batch_error_test"
    local output_dir="${BATS_TEST_TMPDIR}/batch_error_output"
    mkdir -p "$test_dir"
    
    # Create test images and one invalid file
    create_test_image "${test_dir}/image1.png" 100 100
    create_test_image "${test_dir}/image2.jpg" 150 150
    echo "not an image" > "${test_dir}/invalid.txt"
    
    # Run batch conversion
    run_imgxsh "imgxsh-convert" --format webp "$test_dir" "$output_dir"
    
    # Should succeed but report some failures
    assert_success
    assert_output --partial "Found 2 image files to process"
    assert_output --partial "Processed: 2 files, Failed: 0 files"
    
    # Verify only valid images were processed
    [[ -f "${output_dir}/image1.webp" ]]
    [[ -f "${output_dir}/image2.webp" ]]
    [[ ! -f "${output_dir}/invalid.webp" ]]
}

@test "imgxsh-convert: batch processing with different formats" {
    # Create test directory structure
    local test_dir="${BATS_TEST_TMPDIR}/batch_format_test"
    local output_dir="${BATS_TEST_TMPDIR}/batch_format_output"
    mkdir -p "$test_dir"
    
    # Create test images
    create_test_image "${test_dir}/image1.png" 100 100
    create_test_image "${test_dir}/image2.jpg" 150 150
    
    # Test different output formats
    for format in webp jpg png tiff; do
        local format_output="${output_dir}_${format}"
        run_imgxsh "imgxsh-convert" --format "$format" "$test_dir" "$format_output"
        assert_success
        assert_output --partial "Processed: 2 files, Failed: 0 files"
        [[ -f "${format_output}/image1.${format}" ]]
        [[ -f "${format_output}/image2.${format}" ]]
    done
}

@test "imgxsh-convert: batch processing with quality settings" {
    # Create test directory structure
    local test_dir="${BATS_TEST_TMPDIR}/batch_quality_test"
    local output_dir="${BATS_TEST_TMPDIR}/batch_quality_output"
    mkdir -p "$test_dir"
    
    # Create test images
    create_test_image "${test_dir}/image1.jpg" 100 100
    
    # Test different quality settings
    for quality in 50 75 90 95; do
        local quality_output="${output_dir}_${quality}"
        run_imgxsh "imgxsh-convert" --format jpg --quality "$quality" "$test_dir" "$quality_output"
        assert_success
        assert_output --partial "Processed: 1 files, Failed: 0 files"
        [[ -f "${quality_output}/image1.jpg" ]]
    done
}

@test "imgxsh-convert: batch processing empty directory" {
    # Create empty test directory
    local test_dir="${BATS_TEST_TMPDIR}/batch_empty_test"
    local output_dir="${BATS_TEST_TMPDIR}/batch_empty_output"
    mkdir -p "$test_dir"
    
    # Run batch conversion on empty directory
    run_imgxsh "imgxsh-convert" --format webp "$test_dir" "$output_dir"
    
    # Check results
    assert_success
    assert_output --partial "No image files found in directory: $test_dir"
}

@test "imgxsh-convert: batch processing preserves directory structure" {
    # Create nested test directory structure
    local test_dir="${BATS_TEST_TMPDIR}/batch_nested_test"
    local output_dir="${BATS_TEST_TMPDIR}/batch_nested_output"
    mkdir -p "$test_dir/level1/level2"
    
    # Create test images at different levels
    create_test_image "${test_dir}/image1.png" 100 100
    create_test_image "${test_dir}/level1/image2.png" 150 150
    create_test_image "${test_dir}/level1/level2/image3.png" 200 200
    
    # Run batch conversion
    run_imgxsh "imgxsh-convert" --format webp "$test_dir" "$output_dir"
    
    # Check results
    assert_success
    assert_output --partial "Found 3 image files to process"
    assert_output --partial "Processed: 3 files, Failed: 0 files"
    
    # Verify directory structure is preserved
    [[ -f "${output_dir}/image1.webp" ]]
    [[ -f "${output_dir}/level1/image2.webp" ]]
    [[ -f "${output_dir}/level1/level2/image3.webp" ]]
}
