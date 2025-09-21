#!/bin/bash

# Shell Starter - Update Management Functions
# Provides version comparison and GitHub API functions for update management

# Source logging if not already sourced
if [[ -z "${COLOR_RESET:-}" ]]; then
	SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
	source "${SCRIPT_DIR}/colors.sh"
	source "${SCRIPT_DIR}/logging.sh"
fi

# GitHub repository configuration
GITHUB_REPO="${GITHUB_REPO:-jeromecoloma/shell-starter}"
GITHUB_API_URL="https://api.github.com"

# Function to compare semantic versions
# Returns: 0 if v1 == v2, 1 if v1 > v2, 2 if v1 < v2
version_compare() {
	local v1="$1"
	local v2="$2"

	# Remove 'v' prefix if present
	v1="${v1#v}"
	v2="${v2#v}"

	# Split versions into arrays
	IFS='.' read -ra V1_PARTS <<<"$v1"
	IFS='.' read -ra V2_PARTS <<<"$v2"

	# Pad arrays to same length
	local max_length=$((${#V1_PARTS[@]} > ${#V2_PARTS[@]} ? ${#V1_PARTS[@]} : ${#V2_PARTS[@]}))

	for ((i = 0; i < max_length; i++)); do
		local part1="${V1_PARTS[i]:-0}"
		local part2="${V2_PARTS[i]:-0}"

		# Remove leading zeros and handle empty parts
		part1=$((10#${part1:-0}))
		part2=$((10#${part2:-0}))

		if ((part1 > part2)); then
			return 1 # v1 > v2
		elif ((part1 < part2)); then
			return 2 # v1 < v2
		fi
	done

	return 0 # v1 == v2
}

# Function to get the latest release from GitHub
get_latest_release() {
	local repo="${1:-$GITHUB_REPO}"
	local api_url="${GITHUB_API_URL}/repos/${repo}/releases/latest"

	log::debug "Fetching latest release from: $api_url"

	# Use curl to fetch the latest release info
	local response
	if command -v curl >/dev/null 2>&1; then
		response=$(curl -s "$api_url" 2>/dev/null)
		local curl_exit_code=$?

		if [[ $curl_exit_code -ne 0 ]]; then
			log::error "Failed to fetch release information (curl exit code: $curl_exit_code)"
			return 1
		fi
	else
		log::error "curl is required but not installed"
		return 1
	fi

	# Parse the JSON response to extract tag_name
	local tag_name
	if command -v jq >/dev/null 2>&1; then
		tag_name=$(echo "$response" | jq -r '.tag_name' 2>/dev/null)
	else
		# Fallback parsing without jq
		tag_name=$(echo "$response" | grep -o '"tag_name"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*"tag_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')
	fi

	if [[ -z "$tag_name" || "$tag_name" == "null" ]]; then
		log::error "Could not parse release information"
		return 1
	fi

	echo "$tag_name"
	return 0
}

# Function to check if an update is available
check_for_update() {
	local current_version="${1:-$(get_version)}"
	local repo="${2:-$GITHUB_REPO}"

	log::debug "Checking for updates. Current version: $current_version"

	local latest_version
	latest_version=$(get_latest_release "$repo")
	local fetch_exit_code=$?

	if [[ $fetch_exit_code -ne 0 ]]; then
		log::error "Failed to check for updates"
		return 1
	fi

	log::debug "Latest version: $latest_version"

	# Compare versions
	version_compare "$current_version" "$latest_version"
	local comparison_result=$?

	case $comparison_result in
	0)
		log::info "You are running the latest version ($current_version)"
		return 1 # No update available
		;;
	1)
		log::info "You are running a newer version ($current_version) than the latest release ($latest_version)"
		return 1 # No update needed
		;;
	2)
		log::info "Update available: $current_version → $latest_version"
		echo "$latest_version"
		return 0 # Update available
		;;
	esac
}

# Function to get download URL for a specific release
get_release_download_url() {
	local repo="${1:-$GITHUB_REPO}"
	local tag="${2:-latest}"
	local api_url

	if [[ "$tag" == "latest" ]]; then
		api_url="${GITHUB_API_URL}/repos/${repo}/releases/latest"
	else
		api_url="${GITHUB_API_URL}/repos/${repo}/releases/tags/${tag}"
	fi

	log::debug "Fetching release download URL from: $api_url"

	local response
	if command -v curl >/dev/null 2>&1; then
		response=$(curl -s "$api_url" 2>/dev/null)
		local curl_exit_code=$?

		if [[ $curl_exit_code -ne 0 ]]; then
			log::error "Failed to fetch release information (curl exit code: $curl_exit_code)"
			return 1
		fi
	else
		log::error "curl is required but not installed"
		return 1
	fi

	# Parse the JSON response to extract tarball_url
	local download_url
	if command -v jq >/dev/null 2>&1; then
		download_url=$(echo "$response" | jq -r '.tarball_url' 2>/dev/null)
	else
		# Fallback parsing without jq
		download_url=$(echo "$response" | grep -o '"tarball_url"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*"tarball_url"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')
	fi

	if [[ -z "$download_url" || "$download_url" == "null" ]]; then
		log::error "Could not parse download URL from release information"
		return 1
	fi

	echo "$download_url"
	return 0
}

# Function to display update information
update::info() {
	local current_version="${1:-$(get_version)}"
	local repo="${2:-$GITHUB_REPO}"

	echo "Update Check for $repo"
	echo "Current version: $current_version"

	local latest_version
	latest_version=$(check_for_update "$current_version" "$repo")
	local check_exit_code=$?

	if [[ $check_exit_code -eq 0 ]]; then
		echo "Latest version: $latest_version"
		echo "Update available!"
		return 0
	else
		echo "No update available."
		return 1
	fi
}

# Configuration directory and files for optional notifications
UPDATE_CONFIG_DIR="${HOME}/.config/shell-starter"
UPDATE_CONFIG_FILE="${UPDATE_CONFIG_DIR}/update-notifications.conf"
UPDATE_LAST_CHECK_FILE="${UPDATE_CONFIG_DIR}/last-update-check"

# Default configuration values
DEFAULT_NOTIFICATIONS_ENABLED=false
DEFAULT_CHECK_INTERVAL_HOURS=24
DEFAULT_SHOW_QUIET_NOTIFICATIONS=true

# Function to ensure config directory exists
ensure_config_dir() {
	if [[ ! -d "$UPDATE_CONFIG_DIR" ]]; then
		mkdir -p "$UPDATE_CONFIG_DIR"
	fi
}

# Function to get configuration value
get_config_value() {
	local key="$1"
	local default_value="$2"

	if [[ -f "$UPDATE_CONFIG_FILE" ]]; then
		local value
		value=$(grep "^${key}=" "$UPDATE_CONFIG_FILE" 2>/dev/null | cut -d'=' -f2-)
		if [[ -n "$value" ]]; then
			echo "$value"
			return 0
		fi
	fi

	echo "$default_value"
}

# Function to set configuration value
set_config_value() {
	local key="$1"
	local value="$2"

	ensure_config_dir

	# Remove existing key if present
	if [[ -f "$UPDATE_CONFIG_FILE" ]]; then
		grep -v "^${key}=" "$UPDATE_CONFIG_FILE" >"${UPDATE_CONFIG_FILE}.tmp" 2>/dev/null || true
		mv "${UPDATE_CONFIG_FILE}.tmp" "$UPDATE_CONFIG_FILE"
	fi

	# Add new key-value pair
	echo "${key}=${value}" >>"$UPDATE_CONFIG_FILE"
}

# Function to check if enough time has passed since last check
should_check_for_update() {
	local check_interval_hours
	check_interval_hours=$(get_config_value "CHECK_INTERVAL_HOURS" "$DEFAULT_CHECK_INTERVAL_HOURS")

	if [[ ! -f "$UPDATE_LAST_CHECK_FILE" ]]; then
		return 0 # Never checked before
	fi

	local last_check_time
	last_check_time=$(cat "$UPDATE_LAST_CHECK_FILE" 2>/dev/null || echo "0")

	local current_time
	current_time=$(date +%s)

	local time_diff
	time_diff=$((current_time - last_check_time))

	local interval_seconds
	interval_seconds=$((check_interval_hours * 3600))

	if [[ $time_diff -ge $interval_seconds ]]; then
		return 0 # Enough time has passed
	else
		return 1 # Too soon to check again
	fi
}

# Function to record current time as last check time
record_check_time() {
	ensure_config_dir
	date +%s >"$UPDATE_LAST_CHECK_FILE"
}

# Function to show optional update notification
notify_update_available() {
	local current_version="$1"
	local latest_version="$2"
	local show_quiet="$3"

	if [[ "$show_quiet" == "true" ]]; then
		log::info "💡 Update available: $current_version → $latest_version (use --update for details)"
	else
		echo "Update available: $current_version → $latest_version"
	fi
}

# Function to perform optional background update check
optional_update_check() {
	local repo="${1:-$GITHUB_REPO}"
	local script_name="${2:-$(basename "$0")}"

	# Check if notifications are enabled
	local notifications_enabled
	notifications_enabled=$(get_config_value "NOTIFICATIONS_ENABLED" "$DEFAULT_NOTIFICATIONS_ENABLED")

	if [[ "$notifications_enabled" != "true" ]]; then
		return 0 # Notifications disabled
	fi

	# Check if enough time has passed
	if ! should_check_for_update; then
		return 0 # Too soon to check
	fi

	# Perform the check quietly
	local current_version
	current_version=$(get_version)

	local latest_version
	latest_version=$(get_latest_release "$repo" 2>/dev/null)
	local fetch_exit_code=$?

	# Record that we checked (even if failed)
	record_check_time

	if [[ $fetch_exit_code -ne 0 ]]; then
		return 1 # Failed to check
	fi

	# Compare versions
	version_compare "$current_version" "$latest_version"
	local comparison_result=$?

	if [[ $comparison_result -eq 2 ]]; then
		# Update available
		local show_quiet
		show_quiet=$(get_config_value "SHOW_QUIET_NOTIFICATIONS" "$DEFAULT_SHOW_QUIET_NOTIFICATIONS")
		notify_update_available "$current_version" "$latest_version" "$show_quiet"
		return 0
	fi

	return 1 # No update available
}

# Function to enable/disable update notifications
update::config() {
	local action="${1:-}"

	case "$action" in
	enable)
		set_config_value "NOTIFICATIONS_ENABLED" "true"
		log::info "Update notifications enabled"
		;;
	disable)
		set_config_value "NOTIFICATIONS_ENABLED" "false"
		log::info "Update notifications disabled"
		;;
	interval)
		local hours="$2"
		if [[ -z "$hours" || ! "$hours" =~ ^[0-9]+$ ]]; then
			log::error "Invalid interval. Please specify hours as a positive integer."
			return 1
		fi
		set_config_value "CHECK_INTERVAL_HOURS" "$hours"
		log::info "Update check interval set to $hours hours"
		;;
	status)
		local enabled
		enabled=$(get_config_value "NOTIFICATIONS_ENABLED" "$DEFAULT_NOTIFICATIONS_ENABLED")
		local interval
		interval=$(get_config_value "CHECK_INTERVAL_HOURS" "$DEFAULT_CHECK_INTERVAL_HOURS")
		local quiet
		quiet=$(get_config_value "SHOW_QUIET_NOTIFICATIONS" "$DEFAULT_SHOW_QUIET_NOTIFICATIONS")

		echo "Update Notification Configuration:"
		echo "  Enabled: $enabled"
		echo "  Check interval: $interval hours"
		echo "  Quiet notifications: $quiet"

		if [[ -f "$UPDATE_LAST_CHECK_FILE" ]]; then
			local last_check
			last_check=$(date -r "$(cat "$UPDATE_LAST_CHECK_FILE")" 2>/dev/null || echo "Unknown")
			echo "  Last check: $last_check"
		else
			echo "  Last check: Never"
		fi
		;;
	quiet)
		local mode="$2"
		if [[ "$mode" == "on" ]]; then
			set_config_value "SHOW_QUIET_NOTIFICATIONS" "true"
			log::info "Quiet notifications enabled"
		elif [[ "$mode" == "off" ]]; then
			set_config_value "SHOW_QUIET_NOTIFICATIONS" "false"
			log::info "Quiet notifications disabled"
		else
			log::error "Invalid mode. Use 'on' or 'off'."
			return 1
		fi
		;;
	*)
		cat <<EOF
Usage: update::config <action> [args]

ACTIONS:
    enable              Enable update notifications
    disable             Disable update notifications
    interval <hours>    Set check interval in hours
    quiet <on|off>      Enable/disable quiet notifications
    status              Show current configuration

EXAMPLES:
    update::config enable
    update::config interval 48
    update::config quiet off
    update::config status
EOF
		;;
	esac
}
