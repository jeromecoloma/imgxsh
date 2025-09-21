#!/usr/bin/env bats
#
# Tests for my-cli demo script

# Load test helpers
load test_helper
load bats-support/load
load bats-assert/load

# Help and version tests
@test "my-cli: help flag" {
	run_script "my-cli" --help
	assert_success
	assert_output --partial "Usage:"
	assert_output --partial "Multi-command CLI demonstrating subcommand architecture"
	assert_output --partial "COMMANDS:"
	assert_output --partial "OPTIONS:"
	assert_output --partial "EXAMPLES:"
}

@test "my-cli: short help flag" {
	run_script "my-cli" -h
	assert_success
	assert_output --partial "Usage:"
}

@test "my-cli: version flag" {
	expected_version=$(cat "${PROJECT_ROOT}/VERSION" | tr -d '\n')
	run_script "my-cli" --version
	assert_success
	assert_output --partial "my-cli"
	assert_output --partial "$expected_version"
}

@test "my-cli: short version flag" {
	expected_version=$(cat "${PROJECT_ROOT}/VERSION" | tr -d '\n')
	run_script "my-cli" -v
	assert_success
	assert_output --partial "my-cli"
	assert_output --partial "$expected_version"
}

# No command error
@test "my-cli: no command specified shows error and help" {
	run_script "my-cli"
	assert_failure
	assert_output --partial "No command specified"
	assert_output --partial "Multi-command CLI demonstrating subcommand architecture"
}

@test "my-cli: unknown command shows error" {
	run_script "my-cli" "unknown-command"
	assert_failure
	assert_output --partial "Unknown command: unknown-command"
	assert_output --partial "Use --help to see available commands"
}

# Global options tests
@test "my-cli: verbose flag" {
	run_script "my-cli" --verbose "status"
	assert_success
	assert_output --partial "System Status"
}

@test "my-cli: quiet flag" {
	run_script "my-cli" --quiet "status"
	assert_success
	assert_output --partial "System Status"
}

@test "my-cli: unknown global option" {
	run_script "my-cli" --unknown-global
	assert_failure
	assert_output --partial "Unknown global option: --unknown-global"
}

# Status command tests
@test "my-cli: status command basic" {
	run_script "my-cli" "status"
	assert_success
	assert_output --partial "System Status"
	assert_output --partial "Hostname:"
	assert_output --partial "Timestamp:"
	assert_output --partial "Uptime:"
	assert_output --partial "Load Average:"
	assert_output --partial "Status check completed"
}

@test "my-cli: status command with detailed flag" {
	run_script "my-cli" "status" --detailed
	assert_success
	assert_output --partial "System Status"
	assert_output --partial "Disk Usage"
	# Memory usage might not be available on all systems, so we don't assert for it
}

@test "my-cli: status command with short detailed flag" {
	run_script "my-cli" "status" -d
	assert_success
	assert_output --partial "System Status"
	assert_output --partial "Disk Usage"
}

@test "my-cli: status command with JSON format" {
	run_script "my-cli" "status" --format "json"
	assert_success
	assert_output --partial "{"
	assert_output --partial "\"timestamp\":"
	assert_output --partial "\"hostname\":"
	assert_output --partial "\"uptime\":"
	assert_output --partial "\"load_average\":"
	assert_output --partial "}"
}

@test "my-cli: status command with JSON format and detailed" {
	run_script "my-cli" "status" --format "json" --detailed
	assert_success
	assert_output --partial "\"disk_usage\":"
}

@test "my-cli: status command help" {
	run_script "my-cli" "status" --help
	assert_success
	assert_output --partial "Usage:"
	assert_output --partial "Show system status information"
	assert_output --partial "OPTIONS:"
	assert_output --partial "--detailed"
	assert_output --partial "--format"
}

@test "my-cli: status command unknown option" {
	run_script "my-cli" "status" --unknown
	assert_failure
	assert_output --partial "Unknown option for status command: --unknown"
}

# Config command tests
@test "my-cli: config command help" {
	run_script "my-cli" "config" --help
	assert_success
	assert_output --partial "Usage:"
	assert_output --partial "Manage configuration settings"
	assert_output --partial "SUBCOMMANDS:"
	assert_output --partial "list"
	assert_output --partial "get"
	assert_output --partial "set"
}

@test "my-cli: config command without subcommand shows help" {
	run_script "my-cli" "config"
	assert_success
	assert_output --partial "Usage:"
	assert_output --partial "Manage configuration settings"
}

@test "my-cli: config list subcommand" {
	run_script "my-cli" "config" "list"
	assert_success
	assert_output --partial "Configuration Settings"
	assert_output --partial "app.name"
	assert_output --partial "app.version"
	assert_output --partial "app.environment"
	assert_output --partial "logging.level"
	assert_output --partial "Configuration listed successfully"
}

@test "my-cli: config get subcommand with key" {
	run_script "my-cli" "config" "get" "app.name"
	assert_success
	assert_output --partial "Value for app.name: development"
}

@test "my-cli: config get subcommand without key" {
	run_script "my-cli" "config" "get"
	assert_failure
	assert_output --partial "Usage: my-cli config get <key>"
}

@test "my-cli: config set subcommand with key and value" {
	run_script "my-cli" "config" "set" "app.env" "production"
	assert_success
	assert_output --partial "Setting configuration: app.env = production"
	assert_output --partial "Configuration updated: app.env = production"
}

@test "my-cli: config set subcommand without key or value" {
	run_script "my-cli" "config" "set"
	assert_failure
	assert_output --partial "Usage: my-cli config set <key> <value>"
}

@test "my-cli: config set subcommand without value" {
	run_script "my-cli" "config" "set" "app.env"
	assert_failure
	assert_output --partial "Usage: my-cli config set <key> <value>"
}

@test "my-cli: config unknown subcommand" {
	run_script "my-cli" "config" "unknown"
	assert_failure
	assert_output --partial "Unknown config subcommand: unknown"
}

# Deploy command tests
@test "my-cli: deploy command help" {
	run_script "my-cli" "deploy" --help
	assert_success
	assert_output --partial "Usage:"
	assert_output --partial "Deploy applications or services"
	assert_output --partial "ARGUMENTS:"
	assert_output --partial "OPTIONS:"
	assert_output --partial "--env"
	assert_output --partial "--dry-run"
	assert_output --partial "--force"
}

@test "my-cli: deploy command without app name" {
	run_script "my-cli" "deploy"
	assert_failure
	assert_output --partial "Application name is required"
}

@test "my-cli: deploy command with app name" {
	run_script "my-cli" "deploy" "myapp"
	assert_success
	assert_output --partial "Preparing deployment of 'myapp' to 'staging'"
	assert_output --partial "Pre-deployment checks passed"
	assert_output --partial "Successfully deployed myapp to staging"
	assert_output --partial "Deployment completed: myapp -> staging"
}

@test "my-cli: deploy command with custom environment" {
	run_script "my-cli" "deploy" "--env" "production" "myapp"
	assert_success
	assert_output --partial "Preparing deployment of 'myapp' to 'production'"
}

@test "my-cli: deploy command with short env flag" {
	run_script "my-cli" "deploy" "-e" "prod" "myapp"
	assert_success
	assert_output --partial "Preparing deployment of 'myapp' to 'prod'"
}

@test "my-cli: deploy command with dry-run" {
	run_script "my-cli" "deploy" "--dry-run" "myapp"
	assert_success
	assert_output --partial "DRY RUN MODE - No actual deployment will occur"
	assert_output --partial "[DRY RUN] Would deploy myapp to staging"
}

@test "my-cli: deploy command with short dry-run flag" {
	run_script "my-cli" "deploy" "-n" "myapp"
	assert_success
	assert_output --partial "DRY RUN MODE"
}

@test "my-cli: deploy command with force to production" {
	run_script "my-cli" "deploy" "--env" "prod" "--force" "myapp"
	assert_success
	assert_output --partial "Successfully deployed myapp to prod"
	# Should not prompt when force is used
}

@test "my-cli: deploy command production without force prompts" {
	# This test simulates the 'n' response to the production deployment prompt
	run bash -c "echo 'n' | '${PROJECT_ROOT}/demo/my-cli' deploy --env prod myapp"
	assert_success
	assert_output --partial "Are you sure you want to deploy to production?"
	assert_output --partial "Deployment cancelled by user"
}

@test "my-cli: deploy command unknown option" {
	run_script "my-cli" "deploy" "--unknown"
	assert_failure
	assert_output --partial "Unknown option: --unknown"
}

# Backup command tests
@test "my-cli: backup command help" {
	run_script "my-cli" "backup" --help
	assert_success
	assert_output --partial "Usage:"
	assert_output --partial "Create and manage backups"
	assert_output --partial "SUBCOMMANDS:"
	assert_output --partial "create"
	assert_output --partial "list"
	assert_output --partial "restore"
}

@test "my-cli: backup command without subcommand defaults to create" {
	run_script "my-cli" "backup"
	assert_success
	assert_output --partial "Creating backup:"
	assert_output --partial "Backup created successfully:"
	assert_output --partial "Configuration and data included"
}

@test "my-cli: backup create subcommand" {
	run_script "my-cli" "backup" "create"
	assert_success
	assert_output --partial "Creating backup:"
	assert_output --partial "Backup created successfully:"
}

@test "my-cli: backup create with custom name" {
	run_script "my-cli" "backup" "create" "--name" "my-custom-backup"
	assert_success
	assert_output --partial "Creating backup: my-custom-backup"
	assert_output --partial "Backup created successfully: my-custom-backup"
}

@test "my-cli: backup create with short name flag" {
	run_script "my-cli" "backup" "create" "-n" "test-backup"
	assert_success
	assert_output --partial "Creating backup: test-backup"
}

@test "my-cli: backup create with no-data flag" {
	run_script "my-cli" "backup" "create" "--no-data"
	assert_success
	assert_output --partial "Configuration only (data excluded)"
}

@test "my-cli: backup create help" {
	run_script "my-cli" "backup" "create" --help
	assert_success
	assert_output --partial "Usage:"
	assert_output --partial "Create a new backup"
	assert_output --partial "--name"
	assert_output --partial "--no-data"
}

@test "my-cli: backup list subcommand" {
	run_script "my-cli" "backup" "list"
	assert_success
	assert_output --partial "Available Backups"
	assert_output --partial "backup-20241201-143022"
	assert_output --partial "backup-20241128-091545"
	assert_output --partial "backup-20241121-180330"
	assert_output --partial "Listed 3 available backups"
}

@test "my-cli: backup restore subcommand without name" {
	run_script "my-cli" "backup" "restore"
	assert_failure
	assert_output --partial "Backup name is required for restore"
	assert_output --partial "Use 'my-cli backup list' to see available backups"
}

@test "my-cli: backup restore with name and cancellation" {
	run bash -c "echo 'n' | '${PROJECT_ROOT}/demo/my-cli' backup restore test-backup"
	assert_success
	assert_output --partial "Are you sure you want to restore from 'test-backup'?"
	assert_output --partial "Restore cancelled by user"
}

@test "my-cli: backup restore with name and confirmation" {
	run bash -c "echo 'y' | '${PROJECT_ROOT}/demo/my-cli' backup restore test-backup"
	assert_success
	assert_output --partial "Restoring from backup: test-backup"
	assert_output --partial "Successfully restored from backup: test-backup"
}

@test "my-cli: backup unknown subcommand" {
	run_script "my-cli" "backup" "unknown"
	assert_failure
	assert_output --partial "Unknown backup subcommand: unknown"
}

# Monitor command tests
@test "my-cli: monitor command help" {
	run_script "my-cli" "monitor" --help
	assert_success
	assert_output --partial "Usage:"
	assert_output --partial "System monitoring utilities"
	assert_output --partial "OPTIONS:"
	assert_output --partial "--watch"
	assert_output --partial "--interval"
	assert_output --partial "--metric"
}

@test "my-cli: monitor command basic" {
	run_script "my-cli" "monitor"
	assert_success
	assert_output --partial "System Monitoring Snapshot"
	assert_output --partial "Timestamp:"
	assert_output --partial "CPU Load:"
	assert_output --partial "Disk (/):"
	assert_output --partial "Monitoring snapshot completed"
}

@test "my-cli: monitor command with specific metric cpu" {
	run_script "my-cli" "monitor" "--metric" "cpu"
	assert_success
	assert_output --partial "Starting monitoring (metric: cpu)"
	assert_output --partial "CPU Load:"
}

@test "my-cli: monitor command with specific metric memory" {
	run_script "my-cli" "monitor" "--metric" "memory"
	assert_success
	assert_output --partial "Starting monitoring (metric: memory)"
}

@test "my-cli: monitor command with specific metric disk" {
	run_script "my-cli" "monitor" "--metric" "disk"
	assert_success
	assert_output --partial "Starting monitoring (metric: disk)"
	assert_output --partial "Disk (/):"
}

@test "my-cli: monitor command with short metric flag" {
	run_script "my-cli" "monitor" "-m" "cpu"
	assert_success
	assert_output --partial "Starting monitoring (metric: cpu)"
}

@test "my-cli: monitor command unknown option" {
	run_script "my-cli" "monitor" "--unknown"
	assert_failure
	assert_output --partial "Unknown option: --unknown"
}

# Note: Watch mode tests are commented out as they would run indefinitely
# @test "my-cli: monitor command with watch mode" {
#     # This would run indefinitely, so we skip it in tests
#     skip "Watch mode runs indefinitely"
# }

# Combined command and global option tests
@test "my-cli: global verbose with status command" {
	run_script "my-cli" --verbose "status"
	assert_success
	assert_output --partial "System Status"
}

@test "my-cli: global quiet with config command" {
	run_script "my-cli" --quiet "config" "list"
	assert_success
	assert_output --partial "Configuration Settings"
}

# Command with complex argument combinations
@test "my-cli: deploy with multiple flags" {
	run_script "my-cli" "deploy" "--env" "staging" "--dry-run" "myapp"
	assert_success
	assert_output --partial "Preparing deployment of 'myapp' to 'staging'"
	assert_output --partial "DRY RUN MODE"
}

@test "my-cli: backup create with multiple flags" {
	run_script "my-cli" "backup" "create" "--name" "test" "--no-data"
	assert_success
	assert_output --partial "Creating backup: test"
	assert_output --partial "Configuration only (data excluded)"
}

# Edge cases and error conditions
@test "my-cli: status command with invalid format" {
	run_script "my-cli" "status" "--format" "invalid"
	assert_success
	# Should default to text format behavior
	assert_output --partial "System Status"
}

@test "my-cli: deploy command with flags before app name" {
	run_script "my-cli" "deploy" "--env" "prod" "--dry-run" "myapp"
	assert_success
	assert_output --partial "Preparing deployment of 'myapp' to 'prod'"
}

@test "my-cli: deploy command with flags after app name" {
	run_script "my-cli" "deploy" "myapp" "--env" "prod" "--dry-run"
	assert_success
	assert_output --partial "Preparing deployment of 'myapp' to 'prod'"
}

# Argument parsing edge cases
@test "my-cli: command with unknown flag" {
	run_script "my-cli" "status" "--invalid-flag"
	assert_failure
	assert_output --partial "Unknown option for status command: --invalid-flag"
}

@test "my-cli: global flag after command" {
	run_script "my-cli" "status" "--verbose"
	assert_failure
	# Global flags should come before the command
	assert_output --partial "Unknown option for status command: --verbose"
}

# Help for subcommands
@test "my-cli: all commands support help flag" {
	local commands=("status" "deploy" "monitor")
	for cmd in "${commands[@]}"; do
		run_script "my-cli" "$cmd" --help
		assert_success
		assert_output --partial "Usage:"
	done
}

# Integration-style tests
@test "my-cli: complete workflow simulation" {
	# Test a sequence of commands that might be used together
	run_script "my-cli" "status"
	assert_success

	run_script "my-cli" "config" "list"
	assert_success

	run_script "my-cli" "backup" "create" "--name" "pre-deploy"
	assert_success

	run_script "my-cli" "deploy" "--dry-run" "myapp"
	assert_success
}

@test "my-cli: output formatting consistency" {
	# Verify that all commands produce properly formatted output
	local commands=("status" "config list" "backup list" "monitor")
	for cmd in "${commands[@]}"; do
		run bash -c "'${PROJECT_ROOT}/demo/my-cli' $cmd"
		assert_success
		# Should not have obvious formatting issues
		refute_output --partial "ERROR"
		refute_output --partial "command not found"
	done
}