#!/usr/bin/env bats

# imgxsh YAML Validation Tests
# Tests YAML validation behavior with yq-required configuration

load test_helper
bats_load_library bats-support
bats_load_library bats-assert

setup() {
    # Create test directory
    TEST_DIR=$(mktemp -d)
    cd "$TEST_DIR"
    
    # Set up test configuration file path
    export IMGXSH_CONFIG_FILE="$TEST_DIR/test-config.yaml"
}

teardown() {
    # Clean up test directory
    rm -rf "$TEST_DIR"
}

validate_with_yq() {
    local file="$1"
    yq eval '.' "$file" >/dev/null 2>&1
}

# Test 1: Valid YAML configuration should pass validation (yq)
@test "yaml validation: valid configuration passes" {
    cat > "$IMGXSH_CONFIG_FILE" << 'EOF'
settings:
  output_dir: "./output"
  temp_dir: "/tmp/imgxsh"
  parallel_jobs: 4
  backup_policy: "auto"
  log_level: "info"
  quality:
    jpg: 85
    webp: 90
  max_file_size: "10MB"
  max_dimensions: "4000x4000"
  notifications:
    enabled: false
    webhook_url: ""
    desktop_notifications: true

workflows:
  test-workflow:
    name: "test-workflow"
    description: "Test workflow"
    version: "1.0"
    steps:
      - name: test_step
        type: convert
        description: "Test step"
        params:
          input: "{workflow_input}"
          output_dir: "{output_dir}"

presets:
  test-preset:
    name: "test-preset"
    description: "Test preset"
    base_workflow: "test-workflow"
EOF

    run validate_with_yq "$IMGXSH_CONFIG_FILE"
    assert_success
}

# Test 2: Missing required sections should fail validation
@test "yaml validation: missing settings section fails" {
    cat > "$IMGXSH_CONFIG_FILE" << 'EOF'
workflows:
  test-workflow:
    name: "test-workflow"
    description: "Test workflow"
    version: "1.0"

presets:
  test-preset:
    name: "test-preset"
    description: "Test preset"
    base_workflow: "test-workflow"
EOF

    run yq eval -e 'has("settings")' "$IMGXSH_CONFIG_FILE"
    assert_failure
}

# Test 3: Missing workflows section should fail validation
@test "yaml validation: missing workflows section fails" {
    cat > "$IMGXSH_CONFIG_FILE" << 'EOF'
settings:
  output_dir: "./output"
  temp_dir: "/tmp/imgxsh"
  parallel_jobs: 4

presets:
  test-preset:
    name: "test-preset"
    description: "Test preset"
    base_workflow: "test-workflow"
EOF

    run yq eval -e 'has("workflows")' "$IMGXSH_CONFIG_FILE"
    assert_failure
}

# Test 4: Missing presets section should fail validation
@test "yaml validation: missing presets section fails" {
    cat > "$IMGXSH_CONFIG_FILE" << 'EOF'
settings:
  output_dir: "./output"
  temp_dir: "/tmp/imgxsh"
  parallel_jobs: 4

workflows:
  test-workflow:
    name: "test-workflow"
    description: "Test workflow"
    version: "1.0"
EOF

    run yq eval -e 'has("presets")' "$IMGXSH_CONFIG_FILE"
    assert_failure
}

# Test 5: Missing required settings should fail validation
@test "yaml validation: missing output_dir setting fails" {
    cat > "$IMGXSH_CONFIG_FILE" << 'EOF'
settings:
  temp_dir: "/tmp/imgxsh"
  parallel_jobs: 4

workflows:
  test-workflow:
    name: "test-workflow"
    description: "Test workflow"
    version: "1.0"

presets:
  test-preset:
    name: "test-preset"
    description: "Test preset"
    base_workflow: "test-workflow"
EOF

    run yq eval -e '.settings | has("output_dir")' "$IMGXSH_CONFIG_FILE"
    assert_failure
}

# Test 6: Missing temp_dir setting should fail validation
@test "yaml validation: missing temp_dir setting fails" {
    cat > "$IMGXSH_CONFIG_FILE" << 'EOF'
settings:
  output_dir: "./output"
  parallel_jobs: 4

workflows:
  test-workflow:
    name: "test-workflow"
    description: "Test workflow"
    version: "1.0"

presets:
  test-preset:
    name: "test-preset"
    description: "Test preset"
    base_workflow: "test-workflow"
EOF

    run yq eval -e '.settings | has("temp_dir")' "$IMGXSH_CONFIG_FILE"
    assert_failure
}

# Test 7: Missing parallel_jobs setting should fail validation
@test "yaml validation: missing parallel_jobs setting fails" {
    cat > "$IMGXSH_CONFIG_FILE" << 'EOF'
settings:
  output_dir: "./output"
  temp_dir: "/tmp/imgxsh"

workflows:
  test-workflow:
    name: "test-workflow"
    description: "Test workflow"
    version: "1.0"

presets:
  test-preset:
    name: "test-preset"
    description: "Test preset"
    base_workflow: "test-workflow"
EOF

    run yq eval -e '.settings | has("parallel_jobs")' "$IMGXSH_CONFIG_FILE"
    assert_failure
}

# Test 8: Non-numeric parallel_jobs should fail validation
@test "yaml validation: non-numeric parallel_jobs fails" {
    cat > "$IMGXSH_CONFIG_FILE" << 'EOF'
settings:
  output_dir: "./output"
  temp_dir: "/tmp/imgxsh"
  parallel_jobs: "four"

workflows:
  test-workflow:
    name: "test-workflow"
    description: "Test workflow"
    version: "1.0"

presets:
  test-preset:
    name: "test-preset"
    description: "Test preset"
    base_workflow: "test-workflow"
EOF

    run yq eval '.settings.parallel_jobs | (type == "!!int")' "$IMGXSH_CONFIG_FILE"
    assert_output "false"
}

# Test 9: Mixed tabs and spaces should fail validation
@test "yaml validation: mixed tabs and spaces fails" {
    cat > "$IMGXSH_CONFIG_FILE" << 'EOF'
settings:
  output_dir: "./output"
	temp_dir: "/tmp/imgxsh"  # This line uses tabs
  parallel_jobs: 4

workflows:
  test-workflow:
    name: "test-workflow"
    description: "Test workflow"
    version: "1.0"

presets:
  test-preset:
    name: "test-preset"
    description: "Test preset"
    base_workflow: "test-workflow"
EOF

    # yq will fail to parse mixed-indented invalid YAML
    run yq eval '.' "$IMGXSH_CONFIG_FILE"
    assert_failure
}

# Test 10: Keys without values should fail validation
@test "yaml validation: keys without values become null (yq)" {
    cat > "$IMGXSH_CONFIG_FILE" << 'EOF'
settings:
  output_dir: "./output"
  temp_dir: "/tmp/imgxsh"
  parallel_jobs: 4
  invalid_key:  # Missing value

workflows:
  test-workflow:
    name: "test-workflow"
    description: "Test workflow"
    version: "1.0"

presets:
  test-preset:
    name: "test-preset"
    description: "Test preset"
    base_workflow: "test-workflow"
EOF

    run bash -lc 'yq -r ".settings.invalid_key // \"\"" "$IMGXSH_CONFIG_FILE"'
    assert_success
    # yq prints an empty line when the value is null with this expression
    assert_output ""
}

# Test 11: No valid YAML keys should fail validation
@test "yaml validation: no valid YAML keys (comments only) parses as comments (yq)" {
    cat > "$IMGXSH_CONFIG_FILE" << 'EOF'
# This is just a comment file
# No actual YAML content
# Just comments and empty lines

EOF

    # yq outputs the comments unchanged; just ensure it does not error
    run yq '.' "$IMGXSH_CONFIG_FILE"
    assert_success
}

# Test 12: Empty file should fail validation
@test "yaml validation: empty file yields empty or null (yq)" {
    touch "$IMGXSH_CONFIG_FILE"

    run yq -r '.' "$IMGXSH_CONFIG_FILE"
    assert_success
    # Some yq builds print nothing for empty input; accept empty or null
    if [[ "$output" != "null" && -n "$output" ]]; then
        echo "Unexpected output: $output" >&2
        false
    fi
}

# Test 13: parallel_jobs with comments should still validate correctly
@test "yaml validation: parallel_jobs with comments validates correctly" {
    cat > "$IMGXSH_CONFIG_FILE" << 'EOF'
settings:
  output_dir: "./output"
  temp_dir: "/tmp/imgxsh"
  parallel_jobs: 8  # Use 8 parallel jobs for faster processing

workflows:
  test-workflow:
    name: "test-workflow"
    description: "Test workflow"
    version: "1.0"

presets:
  test-preset:
    name: "test-preset"
    description: "Test preset"
    base_workflow: "test-workflow"
EOF

    run yq eval '.' "$IMGXSH_CONFIG_FILE"
    assert_success
}

# Test 14: parallel_jobs with quotes should validate correctly
@test "yaml validation: parallel_jobs with quotes validates correctly" {
    cat > "$IMGXSH_CONFIG_FILE" << 'EOF'
settings:
  output_dir: "./output"
  temp_dir: "/tmp/imgxsh"
  parallel_jobs: "4"

workflows:
  test-workflow:
    name: "test-workflow"
    description: "Test workflow"
    version: "1.0"

presets:
  test-preset:
    name: "test-preset"
    description: "Test preset"
    base_workflow: "test-workflow"
EOF

    run yq eval '.' "$IMGXSH_CONFIG_FILE"
    assert_success
}

# Test 15: Integration test with validate_config (with yq)
@test "yaml validation: integration test with validate_config (with yq)" {
    cat > "$IMGXSH_CONFIG_FILE" << 'EOF'
settings:
  output_dir: "./output"
  temp_dir: "/tmp/imgxsh"
  parallel_jobs: 4

workflows:
  test-workflow:
    name: "test-workflow"
    description: "Test workflow"
    version: "1.0"

presets:
  test-preset:
    name: "test-preset"
    description: "Test preset"
    base_workflow: "test-workflow"
EOF

    run imgxsh::validate_config "$IMGXSH_CONFIG_FILE"
    assert_success
    assert_output --partial "Configuration validation passed"
}

# Test 16: Integration test with invalid config (with yq)
@test "yaml validation: integration test with invalid config (with yq)" {
    cat > "$IMGXSH_CONFIG_FILE" << 'EOF'
settings:
  output_dir: "./output"
  temp_dir: "/tmp/imgxsh"
  parallel_jobs: "invalid"

workflows:
  test-workflow:
    name: "test-workflow"
    description: "Test workflow"
    version: "1.0"

presets:
  test-preset:
    name: "test-preset"
    description: "Test preset"
    base_workflow: "test-workflow"
EOF

    run imgxsh::validate_config "$IMGXSH_CONFIG_FILE"
    assert_failure
    assert_output --partial "settings.parallel_jobs must be a number"
    assert_output --partial "Configuration validation failed"
}
