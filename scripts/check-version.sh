#!/bin/bash

# Shell Starter - Version Comparison Script
# Standalone script for comparing semantic versions and checking for updates

set -euo pipefail

# Script configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
GITHUB_REPO="${GITHUB_REPO:-shell-starter/shell-starter}"
GITHUB_API_URL="https://api.github.com"

# Function to get the current version from VERSION file
get_version() {
	local version_file="${PROJECT_ROOT}/VERSION"
	if [[ -f $version_file ]]; then
		cat "$version_file"
	else
		echo "0.0.0"
	fi
}

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

	# Use curl to fetch the latest release info
	local response
	if command -v curl >/dev/null 2>&1; then
		response=$(curl -s "$api_url" 2>/dev/null)
		local curl_exit_code=$?

		if [[ $curl_exit_code -ne 0 ]]; then
			echo "Error: Failed to fetch release information" >&2
			return 1
		fi
	else
		echo "Error: curl is required but not installed" >&2
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

	if [[ -z $tag_name || $tag_name == "null" ]]; then
		echo "Error: Could not parse release information" >&2
		return 1
	fi

	echo "$tag_name"
	return 0
}

# Function to check if an update is available
check_for_update() {
	local current_version="${1:-$(get_version)}"
	local repo="${2:-$GITHUB_REPO}"

	local latest_version
	latest_version=$(get_latest_release "$repo")
	local fetch_exit_code=$?

	if [[ $fetch_exit_code -ne 0 ]]; then
		echo "Error: Failed to check for updates" >&2
		return 1
	fi

	# Compare versions
	version_compare "$current_version" "$latest_version"
	local comparison_result=$?

	case $comparison_result in
	0)
		echo "up-to-date"
		return 1 # No update available
		;;
	1)
		echo "ahead"
		return 1 # No update needed
		;;
	2)
		echo "outdated"
		return 0 # Update available
		;;
	esac
}

# Function to display usage information
usage() {
	cat <<EOF
Usage: $0 [OPTIONS] [COMMAND]

Version comparison and update checking script for Shell Starter.

COMMANDS:
    compare VERSION1 VERSION2    Compare two semantic versions
    current                      Show current version
    latest [REPO]               Show latest release version
    check [REPO]                Check if update is available
    status [REPO]               Show detailed version status

OPTIONS:
    -h, --help                  Show this help message
    -q, --quiet                 Suppress output (for scripting)

EXAMPLES:
    $0 current                  # Show current version
    $0 latest                   # Show latest release version
    $0 check                    # Check if update is available
    $0 compare 1.2.3 1.3.0     # Compare two versions
    $0 status user/repo         # Check status for specific repository

EXIT CODES:
    0: Success / Update available / Version 1 > Version 2
    1: No update available / Versions equal / Version 1 < Version 2
    2: Error occurred
EOF
}

# Main script logic
main() {
	local quiet=false

	# Parse options
	while [[ $# -gt 0 ]]; do
		case $1 in
		-h | --help)
			usage
			exit 0
			;;
		-q | --quiet)
			quiet=true
			shift
			;;
		*)
			break
			;;
		esac
	done

	# Parse command
	local command="${1:-status}"
	shift || true

	case $command in
	compare)
		if [[ $# -lt 2 ]]; then
			echo "Error: compare command requires two version arguments" >&2
			exit 2
		fi
		version_compare "$1" "$2"
		local exit_code=$?
		if [[ $quiet == false ]]; then
			case $exit_code in
			0) echo "$1 == $2" ;;
			1) echo "$1 > $2" ;;
			2) echo "$1 < $2" ;;
			esac
		fi
		exit $exit_code
		;;
	current)
		current_version=$(get_version)
		if [[ $quiet == false ]]; then
			echo "Current version: $current_version"
		else
			echo "$current_version"
		fi
		;;
	latest)
		repo="${1:-$GITHUB_REPO}"
		latest_version=$(get_latest_release "$repo")
		exit_code=$?
		if [[ $exit_code -eq 0 ]]; then
			if [[ $quiet == false ]]; then
				echo "Latest version: $latest_version"
			else
				echo "$latest_version"
			fi
		fi
		exit $exit_code
		;;
	check)
		repo="${1:-$GITHUB_REPO}"
		result=$(check_for_update "$(get_version)" "$repo")
		exit_code=$?
		if [[ $quiet == false ]]; then
			case $result in
			"up-to-date") echo "You are running the latest version" ;;
			"ahead") echo "You are running a newer version than the latest release" ;;
			"outdated") echo "An update is available" ;;
			esac
		else
			echo "$result"
		fi
		exit $exit_code
		;;
	status)
		repo="${1:-$GITHUB_REPO}"
		current_version=$(get_version)
		latest_version=$(get_latest_release "$repo")
		exit_code=$?

		if [[ $exit_code -ne 0 ]]; then
			exit $exit_code
		fi

		if [[ $quiet == false ]]; then
			echo "Repository: $repo"
			echo "Current version: $current_version"
			echo "Latest version: $latest_version"
			echo ""
		fi

		result=$(check_for_update "$current_version" "$repo")
		status_exit_code=$?

		if [[ $quiet == false ]]; then
			case $result in
			"up-to-date") echo "Status: Up to date ✓" ;;
			"ahead") echo "Status: Ahead of latest release" ;;
			"outdated") echo "Status: Update available" ;;
			esac
		else
			echo "$result"
		fi
		exit $status_exit_code
		;;
	*)
		echo "Error: Unknown command '$command'" >&2
		echo "Use '$0 --help' for usage information" >&2
		exit 2
		;;
	esac
}

# Run main function with all arguments
main "$@"
