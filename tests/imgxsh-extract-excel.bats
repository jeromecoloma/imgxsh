#!/usr/bin/env bats

# Load test helpers
load test_helper
bats_load_library bats-support
bats_load_library bats-assert

# setup() and teardown() are handled by test_helper.bash

@test "imgxsh-extract-excel shows help" {
    run_imgxsh "imgxsh-extract-excel" --help
    assert_success
    assert_output --partial "Usage:"
    assert_output --partial "imgxsh-extract-excel"
}

@test "imgxsh-extract-excel shows version" {
    run_imgxsh "imgxsh-extract-excel" --version
    assert_success
    assert_output --regexp "imgxsh-extract-excel [0-9]+\.[0-9]+\.[0-9]+"
}

@test "fails when required arguments are missing" {
    run_imgxsh "imgxsh-extract-excel"
    assert_failure
    assert_output --partial "Excel file is required"
}

@test "checks dependencies via --check-deps" {
    run_imgxsh "imgxsh-extract-excel" --check-deps
    # If unzip/file missing, script exits 1; allow either outcome but ensure no crash
    [[ "$status" -eq 0 || "$status" -eq 1 ]]
}

@test "list-only on non-xlsx gracefully warns (requires unzip)" {
    require_dependency unzip "brew install unzip"
    # create a dummy non-xlsx file
    tmp_file="${BATS_TEST_TMPDIR}/not_excel.bin"
    echo "hello" > "$tmp_file"
    run_imgxsh "imgxsh-extract-excel" --list-only "$tmp_file" "${BATS_TEST_TMPDIR}/out"
    # Should warn listing unsupported but still succeed
    assert_success
    assert_output --partial "Listing unsupported"
}

@test "list-only enumerates xl/media on xlsx (requires unzip)" {
    require_dependency unzip "brew install unzip"
    # build minimal xlsx with xl/media path
    work_dir="${BATS_TEST_TMPDIR}/xlsx"
    mkdir -p "$work_dir/xl/media"
    echo "dummy" > "$work_dir/xl/media/image1.png"
    ( cd "$work_dir" && zip -qr "../test.xlsx" . )
    xlsx_file="${BATS_TEST_TMPDIR}/test.xlsx"
    run_imgxsh "imgxsh-extract-excel" --list-only "$xlsx_file" "${BATS_TEST_TMPDIR}/out"
    assert_success
    assert_output --partial "Found 1 media file"
}

@test "extracts media from xlsx without conversion (requires unzip)" {
    require_dependency unzip "brew install unzip"
    out_dir="${BATS_TEST_TMPDIR}/out"
    mkdir -p "$out_dir"
    # embed a small png payload
    work_dir="${BATS_TEST_TMPDIR}/xlsx2"
    mkdir -p "$work_dir/xl/media"
    echo "dummy" > "$work_dir/xl/media/image2.png"
    ( cd "$work_dir" && zip -qr "../test2.xlsx" . )
    xlsx_file="${BATS_TEST_TMPDIR}/test2.xlsx"
    run_imgxsh "imgxsh-extract-excel" "$xlsx_file" "$out_dir"
    assert_success
    # Expect a file with prefix_001.png (mime detects png)
    [ -f "$out_dir/image_001.png" ]
}

@test "extracts and converts to requested format when ImageMagick available" {
    require_dependency unzip "brew install unzip"
    if ! has_imagemagick; then
        skip "ImageMagick not available"
    fi
    out_dir="${BATS_TEST_TMPDIR}/out3"
    mkdir -p "$out_dir"
    work_dir="${BATS_TEST_TMPDIR}/xlsx3"
    mkdir -p "$work_dir/xl/media"
    echo "dummy" > "$work_dir/xl/media/image3.png"
    ( cd "$work_dir" && zip -qr "../test3.xlsx" . )
    xlsx_file="${BATS_TEST_TMPDIR}/test3.xlsx"
    run_imgxsh "imgxsh-extract-excel" -f jpg --quality 80 "$xlsx_file" "$out_dir"
    assert_success
    [ -f "$out_dir/image_001.jpg" ]
}

@test "handles .xls gracefully without 7z (skips with warning)" {
    # create a fake file labeled as CDF (not real), just to hit the code path
    xls_file="${BATS_TEST_TMPDIR}/fake.xls"
    echo "dummy" > "$xls_file"
    # If 7z missing, should warn and succeed
    if ! has_dependency 7z; then
        run_imgxsh "imgxsh-extract-excel" "$xls_file" "${BATS_TEST_TMPDIR}/out_xls"
        assert_success
        assert_output --partial ".xls detected"
    else
        skip "7z present; .xls path will attempt real extraction"
    fi
}


