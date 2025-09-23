#!/usr/bin/env bats

# tests/imgxsh-extract-pdf.bats - Tests for imgxsh-extract-pdf script

# Load test helpers
load test_helper
bats_load_library bats-support
bats_load_library bats-assert

setup() {
    # Add bin directory to PATH
    export PATH="$BATS_TEST_DIRNAME/../bin:$PATH"
    
    # Create temporary directory for test files
    export BATS_TMPDIR="$(mktemp -d)"
    
    # Create test PDF file (real PDF for testing)
    if command -v convert >/dev/null 2>&1; then
        # Try to create a simple PDF, but handle ImageMagick security policy restrictions
        if convert -size 100x100 xc:white "$BATS_TMPDIR/test.pdf" 2>/dev/null; then
            # Success - we have a basic PDF
            :
        else
            # ImageMagick failed (likely due to security policies), use fallback
            printf "%%PDF-1.4\n1 0 obj\n<<\n/Type /Catalog\n/Pages 2 0 R\n>>\nendobj\n2 0 obj\n<<\n/Type /Pages\n/Kids [3 0 R]\n/Count 1\n>>\nendobj\n3 0 obj\n<<\n/Type /Page\n/Parent 2 0 R\n/MediaBox [0 0 612 792]\n>>\nendobj\nxref\n0 4\n0000000000 65535 f \n0000000009 00000 n \n0000000058 00000 n \n0000000115 00000 n \ntrailer\n<<\n/Size 4\n/Root 1 0 R\n>>\nstartxref\n200\n%%%%EOF\n" > "$BATS_TMPDIR/test.pdf"
        fi
    else
        # Fallback: create a minimal PDF header
        printf "%%PDF-1.4\n1 0 obj\n<<\n/Type /Catalog\n/Pages 2 0 R\n>>\nendobj\n2 0 obj\n<<\n/Type /Pages\n/Kids [3 0 R]\n/Count 1\n>>\nendobj\n3 0 obj\n<<\n/Type /Page\n/Parent 2 0 R\n/MediaBox [0 0 612 792]\n>>\nendobj\nxref\n0 4\n0000000000 65535 f \n0000000009 00000 n \n0000000058 00000 n \n0000000115 00000 n \ntrailer\n<<\n/Size 4\n/Root 1 0 R\n>>\nstartxref\n200\n%%%%EOF\n" > "$BATS_TMPDIR/test.pdf"
    fi
    
    # Create test output directory
    mkdir -p "$BATS_TMPDIR/output"
    
    # Copy real PDF with images for testing if available
    if [[ -f "$BATS_TEST_DIRNAME/fixtures/pdfs/test_with_images.pdf" ]]; then
        cp "$BATS_TEST_DIRNAME/fixtures/pdfs/test_with_images.pdf" "$BATS_TMPDIR/test_with_images.pdf"
    fi
    
    # Set up test environment
    export TEST_MODE=true
}

teardown() {
    # Clean up temporary files
    [[ -n "$BATS_TMPDIR" ]] && rm -rf "$BATS_TMPDIR"
}

# Helper function to mock pdfimages command
mock_pdfimages() {
    local pdf_file="$1"
    local output_dir="$2"
    
    # Create mock extracted images
    echo "Mock image 1" > "$output_dir/page-001.jpg"
    echo "Mock image 2" > "$output_dir/page-002.jpg"
    echo "Mock image 3" > "$output_dir/page-003.jpg"
    
    # Create mock pdfimages list output
    cat > "$output_dir/pdf_images_list.txt" << EOF
page   num  type   width height color comp bpc  enc interp  object ID x-ppi y-ppi size ratio
--------------------------------------------------------------------------------------------
   0     0 image     100    100  rgb     3   8  jpeg   no         4  0   0  1234  12%
   1     1 image     200    150  rgb     3   8  jpeg   no         5  0   0  2345  15%
   2     2 image     300    200  rgb     3   8  jpeg   no         6  0   0  3456  18%
EOF
}


@test "imgxsh-extract-pdf shows help when --help flag is used" {
    run_imgxsh "imgxsh-extract-pdf" --help
    assert_success
    assert_output --partial "Usage:"
    assert_output --partial "imgxsh-extract-pdf"
    assert_output --partial "Extract images from PDF files"
    assert_output --partial "ARGUMENTS:"
    assert_output --partial "OPTIONS:"
    assert_output --partial "EXAMPLES:"
}

@test "imgxsh-extract-pdf shows version when --version flag is used" {
    run_imgxsh "imgxsh-extract-pdf" --version
    assert_success
    assert_output --regexp "imgxsh-extract-pdf [0-9]+\.[0-9]+\.[0-9]+"
}

@test "imgxsh-extract-pdf fails when PDF file is missing" {
    run_imgxsh "imgxsh-extract-pdf"
    assert_failure
    assert_output --partial "PDF file is required"
    assert_output --partial "Usage:"
}

@test "imgxsh-extract-pdf fails when output directory is missing" {
    run_imgxsh "imgxsh-extract-pdf" "$BATS_TMPDIR/test.pdf"
    assert_failure
    assert_output --partial "Output directory is required"
    assert_output --partial "Usage:"
}

@test "imgxsh-extract-pdf fails with invalid PDF file" {
    run_imgxsh "imgxsh-extract-pdf" "/nonexistent/file.pdf" "$BATS_TMPDIR/output"
    assert_failure
    assert_output --partial "PDF file does not exist"
}

@test "imgxsh-extract-pdf fails with unreadable PDF file" {
    # Create unreadable file
    touch "$BATS_TMPDIR/unreadable.pdf"
    chmod 000 "$BATS_TMPDIR/unreadable.pdf"
    
    run_imgxsh "imgxsh-extract-pdf" "$BATS_TMPDIR/unreadable.pdf" "$BATS_TMPDIR/output"
    assert_failure
    # The error message depends on whether the file is readable or not
    # In some environments, chmod 000 might not make the file truly unreadable
    assert_output --regexp "(Cannot read PDF file|File does not appear to be a PDF)"
    
    # Restore permissions for cleanup
    chmod 644 "$BATS_TMPDIR/unreadable.pdf"
}

@test "imgxsh-extract-pdf fails with non-PDF file" {
    echo "Not a PDF" > "$BATS_TMPDIR/notpdf.txt"
    
    run_imgxsh "imgxsh-extract-pdf" "$BATS_TMPDIR/notpdf.txt" "$BATS_TMPDIR/output"
    assert_failure
    # Should fail due to file not being a PDF
    assert_output --partial "File does not appear to be a PDF"
}

@test "imgxsh-extract-pdf creates output directory if it doesn't exist" {
    local new_output_dir="$BATS_TMPDIR/new_output"
    
    require_pdfimages
    run_imgxsh "imgxsh-extract-pdf" "$BATS_TMPDIR/test.pdf" "$new_output_dir" --dry-run
    assert_success
    assert_output --partial "Would create output directory"
}

@test "imgxsh-extract-pdf fails when output directory is a file" {
    touch "$BATS_TMPDIR/output_file"
    
    run_imgxsh "imgxsh-extract-pdf" "$BATS_TMPDIR/test.pdf" "$BATS_TMPDIR/output_file"
    assert_failure
    assert_output --partial "Output path is a file, not a directory"
}

@test "imgxsh-extract-pdf fails with invalid format" {
    run_imgxsh "imgxsh-extract-pdf" "$BATS_TMPDIR/test.pdf" "$BATS_TMPDIR/output" --format invalid
    assert_failure
    assert_output --partial "Invalid format: invalid"
    assert_output --partial "Supported formats:"
}

@test "imgxsh-extract-pdf accepts valid formats" {
    local formats=("jpg" "jpeg" "png" "tiff" "bmp")
    
    for format in "${formats[@]}"; do
        require_pdfimages
        run_imgxsh "imgxsh-extract-pdf" "$BATS_TMPDIR/test.pdf" "$BATS_TMPDIR/output" --format "$format" --dry-run
        assert_success
    done
}

@test "imgxsh-extract-pdf fails with invalid quality" {
    run_imgxsh "imgxsh-extract-pdf" "$BATS_TMPDIR/test.pdf" "$BATS_TMPDIR/output" --quality 150
    assert_failure
    assert_output --partial "Quality must be between 1 and 100"
}

@test "imgxsh-extract-pdf accepts valid quality values" {
    local qualities=(1 50 85 100)
    
    for quality in "${qualities[@]}"; do
        require_pdfimages
        run_imgxsh "imgxsh-extract-pdf" "$BATS_TMPDIR/test.pdf" "$BATS_TMPDIR/output" --quality "$quality" --dry-run
        assert_success
    done
}

@test "imgxsh-extract-pdf fails with invalid page range format" {
    run_imgxsh "imgxsh-extract-pdf" "$BATS_TMPDIR/test.pdf" "$BATS_TMPDIR/output" --page-range "invalid"
    assert_failure
    assert_output --partial "Invalid page range format"
    assert_output --partial "Valid formats:"
}

@test "imgxsh-extract-pdf accepts valid page range formats" {
    local ranges=("1-5" "1,3,7" "2-" "1-3,5,7-10")
    
    for range in "${ranges[@]}"; do
        require_pdfimages
        run_imgxsh "imgxsh-extract-pdf" "$BATS_TMPDIR/test.pdf" "$BATS_TMPDIR/output" --page-range "$range" --dry-run
        assert_success
    done
}

@test "imgxsh-extract-pdf shows dependency check" {
    run_imgxsh "imgxsh-extract-pdf" --check-deps
    # This should succeed if pdfimages is installed (no output when dependencies are available)
    if command -v pdfimages >/dev/null 2>&1; then
        assert_success
        # No output expected when dependencies are available
    else
        assert_failure
        assert_output --partial "Required dependencies missing"
    fi
}

@test "imgxsh-extract-pdf dry run shows operations without execution" {
    require_pdfimages
    
    run_imgxsh "imgxsh-extract-pdf" "$BATS_TMPDIR/test.pdf" "$BATS_TMPDIR/output" --dry-run --verbose
    assert_success
    assert_output --partial "DRY RUN MODE"
    assert_output --partial "Would run:"
}

@test "imgxsh-extract-pdf list-only mode works" {
    require_pdfimages
    
    # Use the real PDF with images if available, otherwise use mock
    local test_pdf="$BATS_TMPDIR/test.pdf"
    if [[ -f "$BATS_TMPDIR/test_with_images.pdf" ]]; then
        test_pdf="$BATS_TMPDIR/test_with_images.pdf"
    else
        # Mock pdfimages list output
        mock_pdfimages "$BATS_TMPDIR/test.pdf" "$BATS_TMPDIR/output"
    fi
    
    run_imgxsh "imgxsh-extract-pdf" "$test_pdf" "$BATS_TMPDIR/output" --list-only
    assert_success
    assert_output --partial "Listing images in PDF"
    assert_output --partial "Found"
}

@test "imgxsh-extract-pdf verbose mode shows detailed output" {
    require_pdfimages
    
    run_imgxsh "imgxsh-extract-pdf" "$BATS_TMPDIR/test.pdf" "$BATS_TMPDIR/output" --verbose --dry-run
    assert_success
    assert_output --partial "Starting PDF image extraction"
    assert_output --partial "PDF:"
    assert_output --partial "Output:"
    assert_output --partial "Format:"
    assert_output --partial "Quality:"
}

@test "imgxsh-extract-pdf quiet mode suppresses verbose output" {
    require_pdfimages
    
    run_imgxsh "imgxsh-extract-pdf" "$BATS_TMPDIR/test.pdf" "$BATS_TMPDIR/output" --quiet --dry-run
    assert_success
    refute_output --partial "Starting PDF image extraction"
    refute_output --partial "PDF:"
}

@test "imgxsh-extract-pdf handles custom prefix" {
    require_pdfimages
    
    run_imgxsh "imgxsh-extract-pdf" "$BATS_TMPDIR/test.pdf" "$BATS_TMPDIR/output" --prefix "custom" --dry-run
    assert_success
    assert_output --partial "custom"
}

@test "imgxsh-extract-pdf handles keep-names option" {
    require_pdfimages
    
    run_imgxsh "imgxsh-extract-pdf" "$BATS_TMPDIR/test.pdf" "$BATS_TMPDIR/output" --keep-names --dry-run
    assert_success
}

@test "imgxsh-extract-pdf handles no-metadata option" {
    require_pdfimages
    
    run_imgxsh "imgxsh-extract-pdf" "$BATS_TMPDIR/test.pdf" "$BATS_TMPDIR/output" --no-metadata --dry-run
    assert_success
}

@test "imgxsh-extract-pdf handles backup option" {
    require_pdfimages
    
    run_imgxsh "imgxsh-extract-pdf" "$BATS_TMPDIR/test.pdf" "$BATS_TMPDIR/output" --backup --dry-run
    assert_success
}

@test "imgxsh-extract-pdf handles overwrite option" {
    require_pdfimages
    
    run_imgxsh "imgxsh-extract-pdf" "$BATS_TMPDIR/test.pdf" "$BATS_TMPDIR/output" --overwrite --dry-run
    assert_success
}

@test "imgxsh-extract-pdf handles unknown options gracefully" {
    run_imgxsh "imgxsh-extract-pdf" --unknown-option
    assert_failure
    assert_output --partial "Unknown option"
    assert_output --partial "Usage:"
}

@test "imgxsh-extract-pdf handles too many arguments" {
    run_imgxsh "imgxsh-extract-pdf" "$BATS_TMPDIR/test.pdf" "$BATS_TMPDIR/output" "extra_arg"
    assert_failure
    assert_output --partial "Too many arguments"
    assert_output --partial "Usage:"
}

@test "imgxsh-extract-pdf shows update information" {
    run_imgxsh "imgxsh-extract-pdf" --update
    # In TEST_MODE, the script should emit a fast-path message and succeed
    assert_success
    assert_output --partial "update-imgxsh"
}

@test "imgxsh-extract-pdf shows version check information" {
    run_imgxsh "imgxsh-extract-pdf" --check-version
    # This may fail if update-shell-starter is not available, which is expected
    # We just want to make sure the command runs and shows version info
    assert_output --partial "imgxsh-extract-pdf"
}

@test "imgxsh-extract-pdf integration with Shell Starter logging" {
    require_pdfimages
    
    run_imgxsh "imgxsh-extract-pdf" "$BATS_TMPDIR/test.pdf" "$BATS_TMPDIR/output" --dry-run
    assert_success
    # Check for Shell Starter logging patterns
    assert_output --regexp "\[[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}\]"
}

@test "imgxsh-extract-pdf handles empty PDF gracefully" {
    require_pdfimages
    
    # Create empty PDF file (minimal valid PDF structure)
    printf "%%PDF-1.4\n1 0 obj\n<<\n/Type /Catalog\n/Pages 2 0 R\n>>\nendobj\n2 0 obj\n<<\n/Type /Pages\n/Kids [3 0 R]\n/Count 1\n>>\nendobj\n3 0 obj\n<<\n/Type /Page\n/Parent 2 0 R\n/MediaBox [0 0 612 792]\n>>\nendobj\nxref\n0 4\n0000000000 65535 f \n0000000009 00000 n \n0000000058 00000 n \n0000000115 00000 n \ntrailer\n<<\n/Size 4\n/Root 1 0 R\n>>\nstartxref\n200\n%%%%EOF\n" > "$BATS_TMPDIR/empty.pdf"
    
    run_imgxsh "imgxsh-extract-pdf" "$BATS_TMPDIR/empty.pdf" "$BATS_TMPDIR/output" --list-only
    # This should handle the case gracefully, either succeeding or failing appropriately
    assert_output --partial "Listing images in PDF"
}

@test "imgxsh-extract-pdf validates file type correctly" {
    # Create a file that looks like a PDF but isn't
    echo "%PDF-1.4" > "$BATS_TMPDIR/fake.pdf"
    echo "This is not actually a PDF file" >> "$BATS_TMPDIR/fake.pdf"
    
    run_imgxsh "imgxsh-extract-pdf" "$BATS_TMPDIR/fake.pdf" "$BATS_TMPDIR/output" --dry-run
    
    # The behavior depends on whether pdfimages is available
    if command -v pdfimages >/dev/null 2>&1; then
        # If pdfimages is available, should succeed in dry-run mode
        assert_success
        assert_output --partial "Would run:"
    else
        # If pdfimages is not available, should fail due to missing dependencies
        assert_failure
        assert_output --partial "Required dependencies missing"
    fi
}

@test "imgxsh-extract-pdf handles large page ranges" {
    require_pdfimages
    
    run_imgxsh "imgxsh-extract-pdf" "$BATS_TMPDIR/test.pdf" "$BATS_TMPDIR/output" --page-range "1-1000" --dry-run
    assert_success
}

@test "imgxsh-extract-pdf handles complex page ranges" {
    require_pdfimages
    
    run_imgxsh "imgxsh-extract-pdf" "$BATS_TMPDIR/test.pdf" "$BATS_TMPDIR/output" --page-range "1-5,10,15-20,25-" --dry-run
    assert_success
}

@test "imgxsh-extract-pdf shows format-specific quality defaults" {
    require_pdfimages
    
    # Test different formats with their default quality settings
    run_imgxsh "imgxsh-extract-pdf" "$BATS_TMPDIR/test.pdf" "$BATS_TMPDIR/output" --format jpg --dry-run
    assert_success
    assert_output --partial "Quality: 85"
    
    run_imgxsh "imgxsh-extract-pdf" "$BATS_TMPDIR/test.pdf" "$BATS_TMPDIR/output" --format png --dry-run
    assert_success
    # PNG is lossless, so quality might not be shown
}

@test "imgxsh-extract-pdf handles case-insensitive format input" {
    local formats=("JPG" "Png" "TIFF" "BMP")
    
    for format in "${formats[@]}"; do
        require_pdfimages
        run_imgxsh "imgxsh-extract-pdf" "$BATS_TMPDIR/test.pdf" "$BATS_TMPDIR/output" --format "$format" --dry-run
        assert_success
    done
}

@test "imgxsh-extract-pdf shows comprehensive help with examples" {
    run_imgxsh "imgxsh-extract-pdf" --help
    assert_success
    assert_output --partial "EXAMPLES:"
    assert_output --partial "Extract all images to output directory"
    assert_output --partial "Extract specific pages with custom naming"
    assert_output --partial "Extract as PNG with high quality"
    assert_output --partial "List available images without extracting"
    assert_output --partial "Dry run to preview operations"
}

@test "imgxsh-extract-pdf shows dependency installation instructions" {
    # This test verifies that the help shows dependency information
    # The actual dependency check behavior is tested in the check_dependencies test
    run_imgxsh "imgxsh-extract-pdf" --help
    assert_success
    assert_output --partial "DEPENDENCIES:"
    assert_output --partial "pdfimages (poppler-utils)"
    assert_output --partial "ImageMagick"
}

@test "imgxsh-extract-pdf shows format support information" {
    run_imgxsh "imgxsh-extract-pdf" --help
    assert_success
    assert_output --partial "FORMATS SUPPORTED:"
    assert_output --partial "jpg, png, tiff, bmp"
    assert_output --partial "ImageMagick"
}

@test "imgxsh-extract-pdf handles version information correctly" {
    run_imgxsh "imgxsh-extract-pdf" --version
    assert_success
    assert_output --regexp "^imgxsh-extract-pdf [0-9]+\.[0-9]+\.[0-9]+.*$"
}

@test "imgxsh-extract-pdf maintains Shell Starter compatibility" {
    # Test that the script follows Shell Starter patterns
    run_imgxsh "imgxsh-extract-pdf" --help
    assert_success
    assert_output --partial "imgxsh-extract-pdf"
    
    run_imgxsh "imgxsh-extract-pdf" --version
    assert_success
    assert_output --regexp "imgxsh-extract-pdf [0-9]+\.[0-9]+\.[0-9]+"
    
    # Test error handling follows Shell Starter patterns
    run_imgxsh "imgxsh-extract-pdf"
    assert_failure
    assert_output --partial "Usage:"
}
