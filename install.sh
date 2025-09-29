#!/bin/bash

set -euo pipefail

# imgxsh Installer
# Configuration
DEFAULT_PREFIX="$HOME/.local/bin"
DEFAULT_LIB_PREFIX="$HOME/.local/lib/imgxsh"
MANIFEST_DIR="${MANIFEST_DIR:-$HOME/.config/imgxsh}"
MANIFEST_FILE="$MANIFEST_DIR/install-manifest.txt"
GITHUB_REPO="${GITHUB_REPO:-jeromecoloma/imgxsh}"
TEMP_DIR="${TMPDIR:-/tmp}/imgxsh-install-$$"
CURL_TIMEOUT="${CURL_TIMEOUT:-30}"
CURL_RETRY_COUNT="${CURL_RETRY_COUNT:-3}"

# Colors
RED='\033[0;31m' GREEN='\033[0;32m' YELLOW='\033[1;33m' BLUE='\033[0;34m' NC='\033[0m'

# Banner functions for installation success
show_installation_banner() {
	# Simple banner for installation success
	echo
	echo -e "${GREEN}╔══════════════════════════════════════════════╗${NC}"
	echo -e "${GREEN}║            INSTALLATION COMPLETE            ║${NC}"
	echo -e "${GREEN}║                                              ║${NC}"
	echo -e "${GREEN}║         🎉 imgxsh Successfully Installed     ║${NC}"
	echo -e "${GREEN}╚══════════════════════════════════════════════╝${NC}"
	echo
}

# Unified logging function
log() {
	local level="$1" && shift
	case "$level" in
	error) echo -e "${RED}[ERROR]${NC} $*" >&2 ;;
	warn) echo -e "${YELLOW}[WARN]${NC} $*" >&2 ;;
	success) echo -e "${GREEN}[SUCCESS]${NC} $*" ;;
	*) echo -e "${BLUE}[INFO]${NC} $*" ;;
	esac
}

# Enhanced error handling with exit codes
fatal_error() {
	log error "$1"
	[[ -n ${2:-} ]] && log error "Error code: $2"
	log error "Installation failed. See above for details."
	exit "${2:-1}"
}

# Cleanup function for emergency exits
cleanup_on_exit() {
	local exit_code=$?
	if [[ $exit_code -ne 0 && -n ${TEMP_DIR:-} && -d $TEMP_DIR ]]; then
		log warn "Cleaning up temporary files due to error..."
		rm -rf "$TEMP_DIR" 2>/dev/null || true
	fi
	exit $exit_code
}

# Set up cleanup trap
trap cleanup_on_exit EXIT

# Detect shell config file
detect_shell_config() {
	case "$(basename "$SHELL")" in
	zsh) echo "$HOME/.zshrc" ;;
	bash) [[ -f "$HOME/.bashrc" ]] && echo "$HOME/.bashrc" || echo "$HOME/.bash_profile" ;;
	fish) echo "$HOME/.config/fish/config.fish" ;;
	*) echo "$HOME/.bashrc" ;;
	esac
}

# Add directory to PATH
add_to_path() {
	local config_file="$1" path_to_add="$2"

	# Validate inputs
	if [[ -z $config_file || -z $path_to_add ]]; then
		log error "add_to_path requires both config_file and path_to_add parameters"
		return 1
	fi

	# Enhanced duplicate detection
	if [[ -f $config_file ]]; then
		# Check for exact path matches in various PATH formats
		local escaped_path
		escaped_path=$(printf '%s\n' "$path_to_add" | sed "s/[[\.*^$()+?{|/]/\\\\&/g")

		# Check for multiple possible PATH entry patterns
		if grep -E "^export PATH=.*${escaped_path}(:|$)" "$config_file" >/dev/null 2>&1 ||
			grep -E "^PATH=.*${escaped_path}(:|$)" "$config_file" >/dev/null 2>&1 ||
			grep -F "# Added by imgxsh installer" "$config_file" >/dev/null 2>&1; then
			log info "PATH entry already exists in $config_file (detected duplicate or imgxsh entry)"
			return 0
		fi

		# Check if the path is already in the current PATH environment
		if [[ ":$PATH:" == *":$path_to_add:"* ]]; then
			log info "PATH directory already available in current session"
			# Still add to config file for persistence, but warn about potential duplicate
			log warn "Adding to config file for persistence, but directory is already in current PATH"
		fi
	fi

	# Create config file if it doesn't exist
	if [[ ! -f $config_file ]]; then
		if ! touch "$config_file"; then
			log error "Failed to create shell config file: $config_file"
			log error "You may need to manually add '$path_to_add' to your PATH"
			return 1
		fi
	fi

	# Check write permissions
	if [[ ! -w $config_file ]]; then
		log error "No write permission for shell config: $config_file"
		log error "Please manually add 'export PATH=\"$path_to_add:\$PATH\"' to your shell configuration"
		return 1
	fi

	# Improved PATH entry addition with duplicate prevention
	if {
		echo ""
		echo "# Added by imgxsh installer on $(date)"
		echo "# This line is managed automatically - do not edit manually"
		echo "if [[ \":\$PATH:\" != *\":$path_to_add:\"* ]]; then"
		echo "    export PATH=\"$path_to_add:\$PATH\""
		echo "fi"
	} >>"$config_file"; then
		log success "Added PATH entry to $config_file with duplicate prevention"
	else
		log error "Failed to write to shell config: $config_file"
		log error "Please manually add 'export PATH=\"$path_to_add:\$PATH\"' to your shell configuration"
		return 1
	fi
}

# Show usage
show_help() {
	cat <<EOF
imgxsh Installer

Usage: $0 [OPTIONS]

Install imgxsh CLI image processing tools to your system.

OPTIONS:
    --prefix PATH         Install scripts location (default: $DEFAULT_PREFIX)
    --lib-prefix PATH     Install libraries location (default: $DEFAULT_LIB_PREFIX)
    --from-github         Download from GitHub releases (latest)
    --version VERSION     Install specific version (enables --from-github)
    --uninstall           Remove imgxsh installation
    --help, -h            Show this help

EXAMPLES:
    $0                    # Install from current directory (or auto-detect GitHub)
    $0 --from-github      # Install latest from GitHub
    $0 --version v1.2.3   # Install specific version
    $0 --uninstall        # Remove installation

NOTE:
    When run via curl (e.g., curl -fsSL ... | bash), automatically downloads
    from GitHub if no local imgxsh files are found.

EOF
}

# Validate argument values
validate_args() {
	# Validate prefix paths
	if [[ -z $PREFIX ]]; then
		fatal_error "PREFIX cannot be empty"
	fi

	if [[ -z $LIB_PREFIX ]]; then
		fatal_error "LIB_PREFIX cannot be empty"
	fi

	# Validate version format if provided
	if [[ -n $VERSION && ! $VERSION =~ ^(v?[0-9]+\.[0-9]+\.[0-9]+|latest|main|master)$ ]]; then
		log warn "Version format '$VERSION' may not be recognized by GitHub API"
	fi

	# Ensure paths are absolute or relative to HOME
	case "$PREFIX" in
	/*) ;; # Absolute path - OK
	~/*) PREFIX="${PREFIX/#~/$HOME}" ;;
	*) log warn "Relative prefix path '$PREFIX' - this may cause issues" ;;
	esac

	case "$LIB_PREFIX" in
	/*) ;; # Absolute path - OK
	~/*) LIB_PREFIX="${LIB_PREFIX/#~/$HOME}" ;;
	*) log warn "Relative lib prefix path '$LIB_PREFIX' - this may cause issues" ;;
	esac

	# Prevent installing to system directories without explicit confirmation
	case "$PREFIX" in
	/usr/bin | /usr/local/bin | /bin | /sbin)
		log warn "Installing to system directory: $PREFIX"
		log warn "This requires elevated privileges and may affect system stability"
		;;
	esac
}

# Parse arguments
parse_args() {
	PREFIX="$DEFAULT_PREFIX" LIB_PREFIX="$DEFAULT_LIB_PREFIX" FROM_GITHUB=false VERSION="" UNINSTALL=false

	while [[ $# -gt 0 ]]; do
		case $1 in
		--prefix)
			if [[ -z ${2:-} ]]; then
				fatal_error "--prefix requires a directory path argument"
			fi
			PREFIX="$2"
			# Set lib prefix relative to bin prefix if not explicitly set
			[[ $LIB_PREFIX == "$DEFAULT_LIB_PREFIX" ]] && LIB_PREFIX="$(dirname "$PREFIX")/lib"
			shift 2
			;;
		--lib-prefix)
			if [[ -z ${2:-} ]]; then
				fatal_error "--lib-prefix requires a directory path argument"
			fi
			LIB_PREFIX="$2"
			shift 2
			;;
		--from-github)
			FROM_GITHUB=true
			shift
			;;
		--version)
			if [[ -z ${2:-} ]]; then
				fatal_error "--version requires a version string argument"
			fi
			VERSION="$2"
			FROM_GITHUB=true
			shift 2
			;;
		--uninstall)
			UNINSTALL=true
			shift
			;;
		--help | -h)
			show_help
			exit 0
			;;
		*)
			fatal_error "Unknown option: $1. Use --help to see available options."
			;;
		esac
	done

	validate_args
}

# Check system prerequisites
check_prerequisites() {
	local missing_tools=()

	command -v curl >/dev/null || missing_tools+=("curl")
	command -v tar >/dev/null || missing_tools+=("tar")

	if [[ ${#missing_tools[@]} -gt 0 ]]; then
		fatal_error "Missing required tools: ${missing_tools[*]}. Please install them first."
	fi
}

# HTTP request with retry
http_request() {
	local url="$1" output_file="${2:-}" attempt=1

	while [[ $attempt -le $CURL_RETRY_COUNT ]]; do
		local curl_cmd="curl -fsSL --connect-timeout $CURL_TIMEOUT --max-time $((CURL_TIMEOUT * 2)) -A 'imgxsh-installer/1.0'"
		[[ -n $output_file ]] && curl_cmd="$curl_cmd -o '$output_file'"
		curl_cmd="$curl_cmd '$url'"

		local error_output
		if [[ -n $output_file ]]; then
			if error_output=$(eval "$curl_cmd" 2>&1); then
				return 0
			fi
		else
			local response
			if response=$(eval "$curl_cmd" 2>&1); then
				echo "$response"
				return 0
			fi
			error_output="$response"
		fi

		log warn "Request failed (attempt $attempt/$CURL_RETRY_COUNT): $error_output"
		[[ $attempt -lt $CURL_RETRY_COUNT ]] && sleep $((attempt * 2))
		((attempt++))
	done

	log error "All HTTP requests failed for URL: $url"
	return 1
}

# Create manifest
init_manifest() {
	if ! mkdir -p "$MANIFEST_DIR"; then
		fatal_error "Failed to create manifest directory: $MANIFEST_DIR"
	fi

	if ! {
		echo "# imgxsh Install Manifest"
		echo "# Generated on $(date)"
		echo "# Scripts prefix: $PREFIX"
		echo "# Libraries prefix: $LIB_PREFIX"
		echo ""
	} >"$MANIFEST_FILE"; then
		fatal_error "Failed to create manifest file: $MANIFEST_FILE"
	fi
}

# Get GitHub release download URL
get_download_url() {
	local repo="${1:-$GITHUB_REPO}" tag="${2:-latest}"
	local api_url="https://api.github.com/repos/${repo}/releases"
	[[ $tag != "latest" ]] && api_url="$api_url/tags/$tag" || api_url="$api_url/latest"

	local response
	if ! response=$(http_request "$api_url"); then
		# Fallback to archive URL
		local fallback="https://github.com/${repo}/archive/refs"
		[[ $tag == "latest" ]] && fallback="$fallback/heads/main.tar.gz" || fallback="$fallback/tags/$tag.tar.gz"
		echo "$fallback"
		return 0
	fi

	# Parse tarball_url (with or without jq)
	local url
	if command -v jq >/dev/null; then
		url=$(echo "$response" | jq -r '.tarball_url' 2>/dev/null)
	else
		url=$(echo "$response" | grep -o '"tarball_url"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*"tarball_url"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')
	fi

	[[ -n $url && $url != "null" ]] && echo "$url" || return 1
}

# Download and extract from GitHub
download_release() {
	local version="${1:-latest}" temp_dir="$TEMP_DIR"

	log info "Preparing download directory..."
	if ! mkdir -p "$temp_dir"; then
		fatal_error "Failed to create temporary directory: $temp_dir"
	fi

	log info "Getting download URL for version: $version"
	local download_url
	if ! download_url=$(get_download_url "$GITHUB_REPO" "$version"); then
		fatal_error "Failed to get download URL for version: $version"
	fi

	local tarball="$temp_dir/release.tar.gz"
	log info "Downloading from: $download_url"
	if ! http_request "$download_url" "$tarball"; then
		fatal_error "Download failed from: $download_url"
	fi

	log info "Extracting archive..."
	if ! tar -xzf "$tarball" -C "$temp_dir" --strip-components=1; then
		fatal_error "Failed to extract archive: $tarball"
	fi

	rm -f "$tarball"
	log info "Download and extraction complete"
	echo "$temp_dir"
}

# Validate directory permissions
validate_directory_permissions() {
	local dir="$1" purpose="$2"

	if [[ ! -d $dir ]]; then
		if ! mkdir -p "$dir"; then
			fatal_error "Failed to create $purpose directory: $dir"
		fi
	fi

	if [[ ! -w $dir ]]; then
		fatal_error "No write permission for $purpose directory: $dir"
	fi
}

# Install scripts and libraries
install_scripts() {
	local working_dir="." script_count=0 lib_count=0

	# Download if from GitHub
	if [[ $FROM_GITHUB == true ]]; then
		if ! working_dir=$(download_release "${VERSION:-latest}"); then
			fatal_error "GitHub download failed"
		fi
	fi

	# Verify source directories exist
	if [[ ! -d "$working_dir/bin" ]]; then
		fatal_error "Source 'bin' directory not found in: $working_dir"
	fi

	log info "Validating installation directories..."
	validate_directory_permissions "$PREFIX" "scripts"
	validate_directory_permissions "$LIB_PREFIX" "libraries"

	log info "Installing scripts from: $working_dir/bin/"
	# Note: demo/ scripts are not installed by default (they are examples only)
	if [[ -d "$working_dir/demo" ]]; then
		log info "Note: Found demo/ directory with example scripts (not installed)"
	fi

	# Install scripts from bin/
	for script in "$working_dir"/bin/*; do
		if [[ -f $script && -x $script ]]; then
			local name dest_path
			name=$(basename "$script")
			dest_path="$PREFIX/$name"

			if ! cp "$script" "$dest_path"; then
				fatal_error "Failed to copy script: $script -> $dest_path"
			fi

			if ! chmod +x "$dest_path"; then
				log warn "Failed to set executable permission on: $dest_path"
			fi

			echo "$dest_path" >>"$MANIFEST_FILE" || {
				log warn "Failed to add to manifest: $dest_path"
			}
			((script_count++))
			log info "Installed script: $name"
		fi
	done

	# Install libraries from lib/ if directory exists
	if [[ -d "$working_dir/lib" ]]; then
		log info "Installing libraries from: $working_dir/lib/"
		for lib_file in "$working_dir"/lib/*; do
			if [[ -f $lib_file ]]; then
				local name dest_path
				name=$(basename "$lib_file")
				dest_path="$LIB_PREFIX/$name"

				if ! cp "$lib_file" "$dest_path"; then
					fatal_error "Failed to copy library: $lib_file -> $dest_path"
				fi

				if ! chmod 644 "$dest_path"; then
					log warn "Failed to set permissions on library: $dest_path"
				fi

				echo "$dest_path" >>"$MANIFEST_FILE" || {
					log warn "Failed to add to manifest: $dest_path"
				}
				((lib_count++))
				log info "Installed library: $name"
			fi
		done
	else
		log warn "No 'lib' directory found, skipping library installation"
	fi

	# Report installation results
	if [[ $script_count -eq 0 ]]; then
		fatal_error "No executable scripts found in source directory"
	else
		log success "Successfully installed $script_count script(s) to: $PREFIX"
	fi

	if [[ $lib_count -gt 0 ]]; then
		log success "Successfully installed $lib_count library file(s) to: $LIB_PREFIX"
	fi
}

# Remove PATH entry from shell configuration
remove_from_path() {
	local config_file="$1" path_to_remove="$2"

	[[ ! -f $config_file ]] && {
		log info "Shell config file not found: $config_file"
		return 0
	}

	# Check for both old and new format PATH entries
	if ! grep -q "imgxsh installer" "$config_file" 2>/dev/null &&
		! grep -q "export PATH.*$path_to_remove" "$config_file" 2>/dev/null; then
		log info "No imgxsh PATH entries found in $config_file"
		return 0
	fi

	log info "Removing imgxsh PATH entries from $config_file"

	local temp_file backup_file
	temp_file=$(mktemp)
	backup_file="${config_file}.backup.$(date +%s)"

	# Create backup
	if ! cp "$config_file" "$backup_file"; then
		log error "Failed to create backup: $backup_file"
		rm -f "$temp_file"
		return 1
	fi

	# Enhanced removal to handle both old and new formats
	awk -v target_path="$path_to_remove" '
	# Skip old format: comment + PATH line
	/^# Added by imgxsh installer$/ {
		getline nextline
		if (index(nextline, target_path) > 0 && nextline ~ /^export PATH=/) {
			next
		} else {
			print $0
			print nextline
		}
		next
	}

	# Skip new format: multi-line block
	/^# Added by imgxsh installer on/ {
		# Skip the entire block: comment, managed comment, if-block
		getline managed_comment  # "# This line is managed automatically..."
		getline if_line         # "if [[ \":$PATH:\" != ..."
		getline export_line     # "    export PATH=..."
		getline fi_line         # "fi"

		# Only skip if this block contains our target path
		if (index(if_line target_path export_line, target_path) > 0) {
			next
		} else {
			# Not our block, keep it
			print $0
			print managed_comment
			print if_line
			print export_line
			print fi_line
		}
		next
	}

	# Remove any direct PATH entries that contain our path
	/^export PATH=.*/ || /^PATH=.*/ {
		if (index($0, target_path) > 0) {
			next
		}
		print
		next
	}

	# Keep all other lines
	{ print }
	' "$config_file" >"$temp_file"

	# Apply changes or report failure
	if mv "$temp_file" "$config_file"; then
		log success "Removed imgxsh PATH entries from $config_file"
		log info "Backup created: $backup_file"
	else
		log error "Failed to update $config_file"
		# Restore from backup
		mv "$backup_file" "$config_file" 2>/dev/null
		rm -f "$temp_file"
		return 1
	fi
}

# Show files that will be removed
show_uninstall_files() {
	echo
	log info "The following files will be removed:"
	echo

	grep -v '^#' "$MANIFEST_FILE" | grep -v '^[[:space:]]*$' | while read -r file_path; do
		if [[ -f $file_path ]]; then
			echo "  🗑️  $file_path"
		else
			echo "  ❌ $file_path (not found)"
		fi
	done
	echo
}

# Get user confirmation for uninstall
get_uninstall_confirmation() {
	echo -e "${YELLOW}Are you sure you want to remove these files? [y/N]${NC} "
	read -r response

	case "$response" in
	[yY] | [yY][eE][sS])
		return 0
		;;
	*)
		log info "Uninstallation cancelled by user"
		exit 0
		;;
	esac
}

# Remove files listed in manifest
remove_files() {
	local removed_count=0 not_found_count=0

	log info "Starting file removal..."

	while IFS= read -r file_path; do
		[[ $file_path =~ ^#.*$ ]] || [[ -z $file_path ]] || [[ $file_path =~ ^[[:space:]]*$ ]] && continue

		if [[ -f $file_path ]]; then
			log info "Removing: $file_path"
			if rm "$file_path"; then
				((removed_count++))
			else
				log error "Failed to remove: $file_path"
			fi
		else
			log warn "File not found (already removed?): $file_path"
			((not_found_count++))
		fi
	done <"$MANIFEST_FILE"

	log success "Removed $removed_count file(s)"
	[[ $not_found_count -gt 0 ]] && log warn "$not_found_count file(s) were already missing"
}

# Clean up manifest file and directory
cleanup_manifest() {
	log info "Cleaning up installation manifest..."

	if rm "$MANIFEST_FILE"; then
		log info "Removed manifest file: $MANIFEST_FILE"
	else
		log warn "Failed to remove manifest file: $MANIFEST_FILE"
	fi

	if [[ -d $MANIFEST_DIR ]] && [[ -z "$(ls -A "$MANIFEST_DIR" 2>/dev/null)" ]]; then
		if rmdir "$MANIFEST_DIR"; then
			log info "Removed empty manifest directory: $MANIFEST_DIR"
		else
			log warn "Failed to remove manifest directory: $MANIFEST_DIR"
		fi
	fi
}

# Uninstall functionality
run_uninstaller() {
	log info "Starting imgxsh uninstallation..."

	if [[ ! -f $MANIFEST_FILE ]]; then
		log error "No installation manifest found at: $MANIFEST_FILE"
		log error "Either imgxsh was never installed, or the manifest was deleted."
		log info "If you installed imgxsh manually, you'll need to remove files manually:"
		log info "  - Check $PREFIX for scripts"
		log info "  - Check $LIB_PREFIX for libraries"
		log info "  - Check shell config files for PATH entries"
		exit 1
	fi

	# Validate manifest file is readable
	if [[ ! -r $MANIFEST_FILE ]]; then
		fatal_error "Cannot read manifest file: $MANIFEST_FILE (permission denied)"
	fi

	local file_count
	if ! file_count=$(grep -v '^#' "$MANIFEST_FILE" | grep -v '^[[:space:]]*$' | wc -l | tr -d ' \n\r\t'); then
		fatal_error "Failed to count files in manifest"
	fi

	if [[ $file_count -eq 0 ]]; then
		log warn "No files listed in manifest. Nothing to uninstall."
		cleanup_manifest
		exit 0
	fi

	log info "Found $file_count file(s) to remove"
	show_uninstall_files
	get_uninstall_confirmation
	remove_files

	local shell_config
	if shell_config=$(detect_shell_config); then
		if ! remove_from_path "$shell_config" "$PREFIX"; then
			log warn "Failed to remove PATH entry - you may need to do this manually"
		fi
	else
		log warn "Could not detect shell config - PATH cleanup skipped"
	fi

	cleanup_manifest
	log success "Uninstallation complete!"
	log info "All imgxsh files and PATH entries have been removed from your system."
	[[ -n ${shell_config:-} ]] && log info "Please run 'source $shell_config' or restart your shell to update PATH"
}

# Main installation
main() {
	# Parse and validate arguments first
	parse_args "$@"

	# Handle uninstall option
	if [[ $UNINSTALL == true ]]; then
		run_uninstaller
		return 0
	fi

	# Auto-detect if we should install from GitHub
	# If no local bin/ directory exists and --from-github wasn't explicitly set, enable GitHub installation
	if [[ $FROM_GITHUB == false && ! -d "./bin" ]]; then
		log info "No local imgxsh files found - automatically enabling GitHub installation"
		FROM_GITHUB=true
	fi

	# Check system prerequisites for installation
	if [[ $FROM_GITHUB == true ]]; then
		check_prerequisites
		log info "Installing imgxsh from GitHub (${VERSION:-latest})"
	else
		log info "Installing imgxsh from local directory"
	fi

	# Initialize installation
	init_manifest

	# Perform main installation
	install_scripts

	# Configure shell PATH
	local shell_config
	if shell_config=$(detect_shell_config); then
		if add_to_path "$shell_config" "$PREFIX"; then
			log success "PATH configuration updated successfully"
		else
			log warn "PATH configuration failed - you may need to add manually"
		fi
	else
		log warn "Could not detect shell configuration - PATH not updated"
		log info "Please manually add 'export PATH=\"$PREFIX:\$PATH\"' to your shell configuration"
	fi

	# Installation complete
	show_installation_banner
	log info "Scripts installed to: $PREFIX"
	log info "Libraries installed to: $LIB_PREFIX"
	log info "Installation manifest: $MANIFEST_FILE"

	if [[ -n ${shell_config:-} ]]; then
		log info "To use the installed scripts immediately, run: source $shell_config"
		log info "Or restart your shell to automatically load the new PATH"
	fi
}

# Run main function if script is executed directly
if [[ ${BASH_SOURCE[0]:-} == "${0:-}" ]]; then
	main "$@"
fi
