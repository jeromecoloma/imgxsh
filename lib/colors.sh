#!/bin/bash

# Shell Starter - Color Variables
# Provides standard ANSI color codes for terminal output

# Terminal capability detection
colors::has_truecolor() {
	# Check for explicit truecolor support
	[[ "${COLORTERM:-}" == "truecolor" ]] || [[ "${COLORTERM:-}" == "24bit" ]] || {
		# Check for terminals that typically support truecolor
		[[ "${TERM_PROGRAM:-}" == "iTerm.app" ]] ||
			[[ "${TERM_PROGRAM:-}" == "vscode" ]] ||
			[[ "${TERM:-}" == "xterm-kitty" ]] ||
			[[ "${TERM:-}" == "alacritty" ]] ||
			[[ "${TERM:-}" == "wezterm" ]]
	}
}

colors::has_256color() {
	# Check for 256 color support
	[[ "${TERM:-}" =~ 256color ]] ||
		[[ "${COLORTERM:-}" == "gnome-terminal" ]] ||
		[[ "${TERM:-}" == "screen" ]] ||
		[[ "${TERM:-}" == "tmux" ]] ||
		[[ "${TERM:-}" == "xterm" ]] ||
		[[ "${TERM:-}" == "rxvt-unicode" ]]
}

# Enhanced terminal capability detection
colors::has_color() {
	# Check for NO_COLOR environment variable first (respects user preference)
	[[ "${NO_COLOR:-}" == "" ]] && {
		# Basic color support detection - most terminals support at least 8/16 colors
		colors::has_truecolor || colors::has_256color || {
			# Check for basic color support (even when not directly connected to terminal)
			[[ "${TERM:-}" != "dumb" ]] &&
				[[ "${TERM:-}" != "" ]]
		}
	}
}

# Text colors - conditionally set based on NO_COLOR support (with guard against redefinition)
if ! declare -p COLOR_RESET >/dev/null 2>&1; then
	if colors::has_color; then
		readonly COLOR_BLACK='\033[0;30m'
		readonly COLOR_RED='\033[0;31m'
		readonly COLOR_GREEN='\033[0;32m'
		readonly COLOR_YELLOW='\033[0;33m'
		readonly COLOR_BLUE='\033[0;34m'
		readonly COLOR_MAGENTA='\033[0;35m'
		readonly COLOR_CYAN='\033[0;36m'
		readonly COLOR_WHITE='\033[0;37m'

		# Bright text colors
		readonly COLOR_BRIGHT_BLACK='\033[1;30m'
		readonly COLOR_BRIGHT_RED='\033[1;31m'
		readonly COLOR_BRIGHT_GREEN='\033[1;32m'
		readonly COLOR_BRIGHT_YELLOW='\033[1;33m'
		readonly COLOR_BRIGHT_BLUE='\033[1;34m'
		readonly COLOR_BRIGHT_MAGENTA='\033[1;35m'
		readonly COLOR_BRIGHT_CYAN='\033[1;36m'
		readonly COLOR_BRIGHT_WHITE='\033[1;37m'

		# Text formatting
		readonly COLOR_BOLD='\033[1m'
		readonly COLOR_DIM='\033[2m'
		readonly COLOR_UNDERLINE='\033[4m'
		readonly COLOR_BLINK='\033[5m'
		readonly COLOR_REVERSE='\033[7m'

		# Reset
		readonly COLOR_RESET='\033[0m'
	else
		# No color support - set all variables to empty
		readonly COLOR_BLACK=''
		readonly COLOR_RED=''
		readonly COLOR_GREEN=''
		readonly COLOR_YELLOW=''
		readonly COLOR_BLUE=''
		readonly COLOR_MAGENTA=''
		readonly COLOR_CYAN=''
		readonly COLOR_WHITE=''

		readonly COLOR_BRIGHT_BLACK=''
		readonly COLOR_BRIGHT_RED=''
		readonly COLOR_BRIGHT_GREEN=''
		readonly COLOR_BRIGHT_YELLOW=''
		readonly COLOR_BRIGHT_BLUE=''
		readonly COLOR_BRIGHT_MAGENTA=''
		readonly COLOR_BRIGHT_CYAN=''
		readonly COLOR_BRIGHT_WHITE=''

		readonly COLOR_BOLD=''
		readonly COLOR_DIM=''
		readonly COLOR_UNDERLINE=''
		readonly COLOR_BLINK=''
		readonly COLOR_REVERSE=''

		readonly COLOR_RESET=''
	fi
fi

# Semantic colors (commonly used) - only set if not already defined
if ! declare -p COLOR_INFO >/dev/null 2>&1; then
	readonly COLOR_INFO="${COLOR_BLUE}"
	readonly COLOR_SUCCESS="${COLOR_GREEN}"
	readonly COLOR_WARNING="${COLOR_YELLOW}"
	readonly COLOR_ERROR="${COLOR_RED}"
	readonly COLOR_DEBUG="${COLOR_MAGENTA}"
fi

# 256-color support for gradients
colors::rgb() {
	local r=$1 g=$2 b=$3
	printf '\033[38;2;%d;%d;%dm' "$r" "$g" "$b"
}

colors::bg_rgb() {
	local r=$1 g=$2 b=$3
	printf '\033[48;2;%d;%d;%dm' "$r" "$g" "$b"
}

colors::is_terminal() {
	# Check if output is going to a terminal
	[[ -t 1 ]]
}

# Gradient generation functions
colors::gradient_horizontal() {
	local text="$1"
	local start_r=$2 start_g=$3 start_b=$4
	local end_r=$5 end_g=$6 end_b=$7
	local length=${#text}

	if [[ $length -eq 0 ]]; then
		return
	fi

	local output=""
	local i

	for ((i = 0; i < length; i++)); do
		local ratio=$((i * 100 / (length - 1)))
		local r=$((start_r + (end_r - start_r) * ratio / 100))
		local g=$((start_g + (end_g - start_g) * ratio / 100))
		local b=$((start_b + (end_b - start_b) * ratio / 100))

		output+="$(colors::rgb "$r" "$g" "$b")${text:$i:1}"
	done

	printf '%b%b' "$output" "${COLOR_RESET}"
}

# Banner functions
banner::shell_starter() {
	local style="${1:-block}"

	case "$style" in
	"block" | "pixel")
		banner::block_style
		;;
	"ascii")
		banner::ascii_style
		;;
	"minimal")
		banner::minimal_style
		;;
	*)
		banner::block_style
		;;
	esac
}

banner::block_style() {
	if colors::has_color && (colors::has_truecolor || colors::has_256color); then
		echo
		colors::gradient_horizontal "███████╗██╗  ██╗███████╗██╗     ██╗         ███████╗████████╗ █████╗ ██████╗ ████████╗███████╗██████╗ " 0 100 255 255 100 0
		echo
		colors::gradient_horizontal "██╔════╝██║  ██║██╔════╝██║     ██║         ██╔════╝╚══██╔══╝██╔══██╗██╔══██╗╚══██╔══╝██╔════╝██╔══██╗" 20 120 255 255 120 20
		echo
		colors::gradient_horizontal "███████╗███████║█████╗  ██║     ██║         ███████╗   ██║   ███████║██████╔╝   ██║   █████╗  ██████╔╝" 40 140 255 255 140 40
		echo
		colors::gradient_horizontal "╚════██║██╔══██║██╔══╝  ██║     ██║         ╚════██║   ██║   ██╔══██║██╔══██╗   ██║   ██╔══╝  ██╔══██╗" 60 160 255 255 160 60
		echo
		colors::gradient_horizontal "███████║██║  ██║███████╗███████╗███████╗    ███████║   ██║   ██║  ██║██║  ██║   ██║   ███████╗██║  ██║" 80 180 255 255 180 80
		echo
		colors::gradient_horizontal "╚══════╝╚═╝  ╚═╝╚══════╝╚══════╝╚══════╝    ╚══════╝   ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═╝   ╚═╝   ╚══════╝╚═╝  ╚═╝" 100 200 255 255 200 100
		echo
	else
		banner::fallback_block
	fi
}

banner::ascii_style() {
	if colors::has_color && (colors::has_truecolor || colors::has_256color); then
		echo
		colors::gradient_horizontal " ____  _          _ _   ____  _             _            " 50 150 255 255 150 50
		echo
		colors::gradient_horizontal "/ ___|| |__   ___| | | / ___|| |_ __ _ _ __| |_ ___ _ __ " 70 170 255 255 170 70
		echo
		colors::gradient_horizontal "\\___ \\| '_ \\ / _ \\ | | \\___ \\| __/ _\` | '__| __/ _ \\ '__|" 90 190 255 255 190 90
		echo
		colors::gradient_horizontal " ___) | | | |  __/ | |  ___) | || (_| | |  | ||  __/ |   " 110 210 255 255 210 110
		echo
		colors::gradient_horizontal "|____/|_| |_|\\___|_|_| |____/ \\__\\__,_|_|   \\__\\___|_|   " 130 230 255 255 230 130
		echo
	else
		banner::fallback_ascii
	fi
}

banner::minimal_style() {
	echo
	if colors::has_color && (colors::has_truecolor || colors::has_256color); then
		colors::gradient_horizontal "• Shell Starter •" 0 150 255 255 150 0
	else
		echo "• Shell Starter •"
	fi
	echo
}

# Fallback banners for terminals without color support
banner::fallback_block() {
	if colors::is_terminal; then
		cat <<'EOF'

███████╗██╗  ██╗███████╗██╗     ██╗         ███████╗████████╗ █████╗ ██████╗ ████████╗███████╗██████╗
██╔════╝██║  ██║██╔════╝██║     ██║         ██╔════╝╚══██╔══╝██╔══██╗██╔══██╗╚══██╔══╝██╔════╝██╔══██╗
███████╗███████║█████╗  ██║     ██║         ███████╗   ██║   ███████║██████╔╝   ██║   █████╗  ██████╔╝
╚════██║██╔══██║██╔══╝  ██║     ██║         ╚════██║   ██║   ██╔══██║██╔══██╗   ██║   ██╔══╝  ██╔══██╗
███████║██║  ██║███████╗███████╗███████╗    ███████║   ██║   ██║  ██║██║  ██║   ██║   ███████╗██║  ██║
╚══════╝╚═╝  ╚═╝╚══════╝╚══════╝╚══════╝    ╚══════╝   ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═╝   ╚═╝   ╚══════╝╚═╝  ╚═╝

EOF
	else
		# For non-terminal output (pipes, redirects), use plain text
		cat <<'EOF'

SHELL STARTER

EOF
	fi
}

banner::fallback_ascii() {
	if colors::is_terminal; then
		cat <<'EOF'

 ____  _          _ _   ____  _             _
/ ___|| |__   ___| | | / ___|| |_ __ _ _ __| |_ ___ _ __
\___ \| '_ \ / _ \ | | \___ \| __/ _` | '__| __/ _ \ '__|
 ___) | | | |  __/ | |  ___) | || (_| | |  | ||  __/ |
|____/|_| |_|\___|_|_| |____/ \__\__,_|_|   \__\___|_|

EOF
	else
		# For non-terminal output (pipes, redirects), use plain text
		cat <<'EOF'

Shell Starter

EOF
	fi
}

# Terminal environment inspection functions (for debugging)
colors::debug_terminal() {
	echo "=== Terminal Environment Debug ==="
	echo "TERM: ${TERM:-unset}"
	echo "COLORTERM: ${COLORTERM:-unset}"
	echo "TERM_PROGRAM: ${TERM_PROGRAM:-unset}"
	echo "NO_COLOR: ${NO_COLOR:-unset}"
	echo "Output is terminal: $(colors::is_terminal && echo "yes" || echo "no")"
	echo "Has truecolor: $(colors::has_truecolor && echo "yes" || echo "no")"
	echo "Has 256color: $(colors::has_256color && echo "yes" || echo "no")"
	echo "Has basic color: $(colors::has_color && echo "yes" || echo "no")"
	echo "=================================="
}

# JSON syntax highlighting functions
colors::json_key() {
	local key="$1"
	printf '%b"%s"%b' "${COLOR_CYAN}" "$key" "${COLOR_RESET}"
}

colors::json_string() {
	local value="$1"
	printf '%b"%s"%b' "${COLOR_GREEN}" "$value" "${COLOR_RESET}"
}

colors::json_number() {
	local value="$1"
	printf '%b%s%b' "${COLOR_MAGENTA}" "$value" "${COLOR_RESET}"
}

colors::json_boolean() {
	local value="$1"
	if [[ "$value" == "true" ]]; then
		printf '%b%s%b' "${COLOR_BRIGHT_GREEN}" "$value" "${COLOR_RESET}"
	else
		printf '%b%s%b' "${COLOR_BRIGHT_RED}" "$value" "${COLOR_RESET}"
	fi
}

colors::json_null() {
	printf '%b%s%b' "${COLOR_DIM}" "null" "${COLOR_RESET}"
}

colors::json_structure() {
	local char="$1"
	printf '%b%s%b' "${COLOR_BOLD}" "$char" "${COLOR_RESET}"
}

# JSON syntax highlighting function for complete JSON strings
colors::json_syntax() {
	local json_input="$1"

	# Check if colors are disabled
	if [[ "${NO_COLOR:-}" != "" ]] || ! colors::has_color; then
		echo "$json_input"
		return
	fi

	# Simple JSON syntax highlighting using color variables
	# Process line by line to maintain proper formatting
	local colored_output=""
	while IFS= read -r line; do
		# Color JSON keys (quoted strings followed by colon)
		line=$(echo "$line" | sed "s/\"\\([^\"]*\\)\":/$(printf '%b' "${COLOR_CYAN}")\"\\1\"$(printf '%b' "${COLOR_RESET}"):/g")

		# Color string values (quoted strings after colon)
		line=$(echo "$line" | sed "s/: \"\\([^\"]*\\)\"/: $(printf '%b' "${COLOR_GREEN}")\"\\1\"$(printf '%b' "${COLOR_RESET}")/g")

		# Color numeric values (including standalone numbers)
		line=$(echo "$line" | sed "s/: \\([0-9]\\+\\(\\.[0-9]\\+\\)\\?\\)\\([,}\\]]\\|$\\)/: $(printf '%b' "${COLOR_MAGENTA}")\\1$(printf '%b' "${COLOR_RESET}")\\3/g")
		# Color numeric values after spaces (for arrays)
		line=$(echo "$line" | sed "s/  \\([0-9]\\+\\(\\.[0-9]\\+\\)\\?\\)\\([,]\\|$\\)/  $(printf '%b' "${COLOR_MAGENTA}")\\1$(printf '%b' "${COLOR_RESET}")\\3/g")

		# Color boolean true
		line=$(echo "$line" | sed "s/: true/: $(printf '%b' "${COLOR_BRIGHT_GREEN}")true$(printf '%b' "${COLOR_RESET}")/g")

		# Color boolean false
		line=$(echo "$line" | sed "s/: false/: $(printf '%b' "${COLOR_BRIGHT_RED}")false$(printf '%b' "${COLOR_RESET}")/g")

		# Color null
		line=$(echo "$line" | sed "s/: null/: $(printf '%b' "${COLOR_DIM}")null$(printf '%b' "${COLOR_RESET}")/g")

		# Color structural characters
		line=$(echo "$line" | sed "s/\\([{}\\[\\],]\\)/$(printf '%b' "${COLOR_BOLD}")\\1$(printf '%b' "${COLOR_RESET}")/g")

		colored_output+="$line"$'\n'
	done <<<"$json_input"

	# Remove trailing newline and add final newline
	echo "${colored_output%$'\n'}"
}

# Colors are now initialized inline above based on NO_COLOR and terminal support
