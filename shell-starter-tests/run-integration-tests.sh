#!/usr/bin/env bash
#
# Run integration tests locally
# This script runs the comprehensive integration tests that are skipped in CI

set -euo pipefail

# Get the project root directory
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "Running Shell Starter Integration Tests"
echo "======================================="
echo ""

# Set environment to run integration tests
export SHELL_STARTER_RUN_INTEGRATION_TESTS=true

# Run the CI test script which will now include integration tests
"$PROJECT_ROOT/tests/run-tests-ci.sh"
