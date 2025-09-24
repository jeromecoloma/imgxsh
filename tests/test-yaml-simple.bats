#!/usr/bin/env bats

# Simple YAML validation test

load test_helper
bats_load_library bats-support
bats_load_library bats-assert

@test "simple yaml validation test" {
    # Create a simple test config
    TEST_CONFIG="/tmp/test-config.yaml"
    cat > "$TEST_CONFIG" << 'EOF'
settings:
  output_dir: "./output"
  temp_dir: "/tmp/imgxsh"
  parallel_jobs: 4

workflows:
  test-workflow:
    name: "test-workflow"

presets:
  test-preset:
    name: "test-preset"
EOF

    # Test the validation function
    run imgxsh::validate_yaml_basic "$TEST_CONFIG"
    assert_success
    assert_output --partial "Basic YAML validation passed"
    
    # Clean up
    rm -f "$TEST_CONFIG"
}
