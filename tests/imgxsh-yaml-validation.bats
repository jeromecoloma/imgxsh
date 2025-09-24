#!/usr/bin/env bats

# imgxsh YAML Validation Tests
# Tests for the basic YAML validation feature when yq is not available

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

# Test 1: Valid YAML configuration should pass validation
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

    # Test the validation function directly
    run imgxsh::validate_yaml_basic "$IMGXSH_CONFIG_FILE"
    assert_success
    assert_output --partial "Basic YAML validation passed"
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

    run imgxsh::validate_yaml_basic "$IMGXSH_CONFIG_FILE"
    assert_failure
    assert_output --partial "Missing required section: settings:"
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

    run imgxsh::validate_yaml_basic "$IMGXSH_CONFIG_FILE"
    assert_failure
    assert_output --partial "Missing required section: workflows:"
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

    run imgxsh::validate_yaml_basic "$IMGXSH_CONFIG_FILE"
    assert_failure
    assert_output --partial "Missing required section: presets:"
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

    run imgxsh::validate_yaml_basic "$IMGXSH_CONFIG_FILE"
    assert_failure
    assert_output --partial "Missing required setting: output_dir:"
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

    run imgxsh::validate_yaml_basic "$IMGXSH_CONFIG_FILE"
    assert_failure
    assert_output --partial "Missing required setting: temp_dir:"
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

    run imgxsh::validate_yaml_basic "$IMGXSH_CONFIG_FILE"
    assert_failure
    assert_output --partial "Missing required setting: parallel_jobs:"
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

    run imgxsh::validate_yaml_basic "$IMGXSH_CONFIG_FILE"
    assert_failure
    assert_output --partial "settings.parallel_jobs must be a number"
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

    run imgxsh::validate_yaml_basic "$IMGXSH_CONFIG_FILE"
    assert_failure
    assert_output --partial "Mixed tabs and spaces in indentation"
}

# Test 10: Keys without values should fail validation
@test "yaml validation: keys without values fails" {
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

    run imgxsh::validate_yaml_basic "$IMGXSH_CONFIG_FILE"
    assert_failure
    assert_output --partial "Found key without value"
}

# Test 11: No valid YAML keys should fail validation
@test "yaml validation: no valid YAML keys fails" {
    cat > "$IMGXSH_CONFIG_FILE" << 'EOF'
# This is just a comment file
# No actual YAML content
# Just comments and empty lines

EOF

    run imgxsh::validate_yaml_basic "$IMGXSH_CONFIG_FILE"
    assert_failure
    assert_output --partial "No valid YAML keys found"
}

# Test 12: Empty file should fail validation
@test "yaml validation: empty file fails" {
    touch "$IMGXSH_CONFIG_FILE"

    run imgxsh::validate_yaml_basic "$IMGXSH_CONFIG_FILE"
    assert_failure
    assert_output --partial "No valid YAML keys found"
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

    run imgxsh::validate_yaml_basic "$IMGXSH_CONFIG_FILE"
    assert_success
    assert_output --partial "Basic YAML validation passed"
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

    run imgxsh::validate_yaml_basic "$IMGXSH_CONFIG_FILE"
    assert_success
    assert_output --partial "Basic YAML validation passed"
}

# Test 15: Integration test with imgxsh::validate_config (without yq)
@test "yaml validation: integration test with validate_config" {
    # Mock yq as unavailable
    command() {
        case "$1" in
            yq) return 1 ;;
            *) /usr/bin/command "$@" ;;
        esac
    }
    
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
    assert_output --partial "yq not available - using basic YAML validation"
    assert_output --partial "Configuration validation passed"
}

# Test 16: Integration test with invalid config (without yq)
@test "yaml validation: integration test with invalid config" {
    # Mock yq as unavailable
    command() {
        case "$1" in
            yq) return 1 ;;
            *) /usr/bin/command "$@" ;;
        esac
    }
    
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
    assert_output --partial "yq not available - using basic YAML validation"
    assert_output --partial "settings.parallel_jobs must be a number"
    assert_output --partial "Configuration validation failed"
}
