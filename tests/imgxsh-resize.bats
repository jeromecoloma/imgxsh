#!/usr/bin/env bats

load 'test_helper.bash'
load 'bats-support/load'
load 'bats-assert/load'

@test "imgxsh-resize shows help" {
  run "$PROJECT_ROOT/bin/imgxsh-resize" --help
  assert_success
  assert_output --partial "Usage:"
  assert_output --partial "--size"
}

@test "imgxsh-resize shows version" {
  run "$PROJECT_ROOT/bin/imgxsh-resize" --version
  assert_success
  assert_output --regexp "imgxsh-resize [0-9]+\\.[0-9]+\\.[0-9]+"
}

@test "fails when required args missing" {
  run "$PROJECT_ROOT/bin/imgxsh-resize"
  assert_failure
  assert_output --partial "required"
}

@test "dry-run single file width resize" {
  require_imagemagick
  local in="$BATS_TEST_TMPDIR/in.png"
  create_test_image "$in" png 100x100 red
  local out="$BATS_TEST_TMPDIR/out.png"
  run "$PROJECT_ROOT/bin/imgxsh-resize" --dry-run --width 50 "$in" "$out"
  assert_success
  assert_output --partial "Would resize"
}

@test "actual single file width resize to smaller (no upscale)" {
  require_imagemagick
  local in="$BATS_TEST_TMPDIR/in2.png"
  create_test_image "$in" png 100x100 red
  local out="$BATS_TEST_TMPDIR/out2.png"
  run "$PROJECT_ROOT/bin/imgxsh-resize" --width 50 "$in" "$out"
  assert_success
  assert [ -f "$out" ]
  run get_image_dimensions "$out"
  assert_output "50x50"
}

@test "no-upscale by default for pixel spec" {
  require_imagemagick
  local in="$BATS_TEST_TMPDIR/in3.png"
  create_test_image "$in" png 100x100 red
  local out="$BATS_TEST_TMPDIR/out3.png"
  run "$PROJECT_ROOT/bin/imgxsh-resize" --width 200 "$in" "$out"
  assert_success
  run get_image_dimensions "$out"
  assert_output "100x100"
}

@test "--allow-upscale permits enlargement" {
  require_imagemagick
  local in="$BATS_TEST_TMPDIR/in4.png"
  create_test_image "$in" png 100x100 red
  local out="$BATS_TEST_TMPDIR/out4.png"
  run "$PROJECT_ROOT/bin/imgxsh-resize" --allow-upscale --width 200 "$in" "$out"
  assert_success
  run get_image_dimensions "$out"
  assert_output "200x200"
}

@test "percentage resize allows upscale" {
  require_imagemagick
  local in="$BATS_TEST_TMPDIR/in5.png"
  create_test_image "$in" png 100x100 red
  local out="$BATS_TEST_TMPDIR/out5.png"
  run "$PROJECT_ROOT/bin/imgxsh-resize" --size 200% "$in" "$out"
  assert_success
  run get_image_dimensions "$out"
  assert_output "200x200"
}

@test "dual percentage resize parses correctly" {
  require_imagemagick
  local in="$BATS_TEST_TMPDIR/in6.png"
  create_test_image "$in" png 200x100 red
  local out="$BATS_TEST_TMPDIR/out6.png"
  run "$PROJECT_ROOT/bin/imgxsh-resize" --size 120%x50% "$in" "$out"
  assert_success
  assert [ -f "$out" ]
}

@test "max file size enforcement errors when exceeded" {
  require_imagemagick
  local in="$BATS_TEST_TMPDIR/in7.png"
  # Create a more complex image to increase JPEG size
  create_test_image_with_text "$in" "Complex Test Content" 800x600 white black
  local out="$BATS_TEST_TMPDIR/out7.jpg"
  # Use a very small limit (200 bytes) to reliably trigger failure; include a size param (100%) to satisfy requirement
  run "$PROJECT_ROOT/bin/imgxsh-resize" --size 100% --format jpg --quality 100 --max-file-size 200 "$in" "$out"
  assert_failure
  assert_output --partial "exceeds max size"
}

@test "directory batch resize with width preserves structure" {
  require_imagemagick
  local dir="$BATS_TEST_TMPDIR/dir"
  mkdir -p "$dir/sub"
  create_test_image "$dir/a.png" png 100x100 red
  create_test_image "$dir/sub/b.jpg" jpg 100x100 red
  local outdir="$BATS_TEST_TMPDIR/outdir"
  run "$PROJECT_ROOT/bin/imgxsh-resize" --width 80 "$dir" "$outdir"
  assert_success
  assert [ -f "$outdir/a.png" ]
  assert [ -f "$outdir/sub/b.jpg" ]
  run get_image_dimensions "$outdir/a.png"
  assert_output "80x80"
}

@test "invalid size spec fails with helpful message" {
  local in="$BATS_TEST_TMPDIR/in8.png"
  create_test_image "$in" png 100x100 red
  local out="$BATS_TEST_TMPDIR/out8.png"
  run "$PROJECT_ROOT/bin/imgxsh-resize" --size invalid "$in" "$out"
  assert_failure
  assert_output --partial "Invalid size specification"
}

@test "missing input file handled gracefully" {
  run "$PROJECT_ROOT/bin/imgxsh-resize" --width 80 "$BATS_TEST_TMPDIR/missing.png" "$BATS_TEST_TMPDIR/out.png"
  assert_failure
  assert_output --partial "does not exist"
}


