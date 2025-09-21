#!/bin/bash

# Shell Starter - Main Library Entrypoint
# This file serves as the main library entrypoint for Shell Starter scripts.

# Get the directory where this script is located
SHELL_STARTER_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SHELL_STARTER_ROOT_DIR="$(cd "${SHELL_STARTER_LIB_DIR}/.." && pwd)"

# Source color and logging libraries
source "${SHELL_STARTER_LIB_DIR}/colors.sh"
source "${SHELL_STARTER_LIB_DIR}/logging.sh"
source "${SHELL_STARTER_LIB_DIR}/spinner.sh"
source "${SHELL_STARTER_LIB_DIR}/utils.sh"
source "${SHELL_STARTER_LIB_DIR}/update.sh"

# Function to get the current version from VERSION file
get_version() {
	local version_file="${SHELL_STARTER_ROOT_DIR}/VERSION"
	if [[ -f "$version_file" ]]; then
		cat "$version_file"
	else
		echo "unknown"
	fi
}

# Function to parse common command line arguments
parse_common_args() {
	local script_name="${1:-$(basename "$0")}"
	shift

	while [[ $# -gt 0 ]]; do
		case $1 in
		--version | -v)
			echo "$script_name $(get_version)"
			exit 0
			;;
		--help | -h)
			show_help "$script_name"
			exit 0
			;;
		--update)
			update::info
			exit $?
			;;
		--check-version)
			"${SHELL_STARTER_ROOT_DIR}/scripts/check-version.sh" status
			exit $?
			;;
		--notify-config)
			shift
			update::config "$@"
			exit $?
			;;
		--uninstall)
			"${SHELL_STARTER_ROOT_DIR}/install.sh" --uninstall
			exit $?
			;;
		*)
			# Unknown option, return to caller for handling
			return 1
			;;
		esac
		shift
	done
	return 0
}

# Default help function (can be overridden by scripts)
show_help() {
	local script_name="${1:-$(basename "$0")}"
	cat <<EOF
Usage: $script_name [OPTIONS]

OPTIONS:
    -h, --help        Show this help message and exit
    -v, --version     Show version information and exit
    --update          Check for available updates
    --check-version   Show detailed version status and check for updates
    --notify-config   Configure update notification settings
    --uninstall       Remove Shell Starter installation

This is a Shell Starter script. Override the show_help function
in your script to provide specific usage information.
EOF
}

# Function to enable optional background update notifications
# Call this function in your script's main() function to enable automatic update checking
enable_background_updates() {
	# This function performs a background check and shows notifications if updates are available
	# It respects user configuration and rate limiting
	optional_update_check "$GITHUB_REPO" "$(basename "$0")" &>/dev/null || true
}

# Section header and divider functions for visual hierarchy
section_header() {
	printf '\n%b─── %s ───%b\n' "${COLOR_BOLD}" "$*" "${COLOR_RESET}"
}

section_divider() {
	printf '%b%s%b\n' "${COLOR_INFO}" "$(printf '%.50s' "──────────────────────────────────────────────────")" "${COLOR_RESET}"
}
