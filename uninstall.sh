#!/bin/bash

set -euo pipefail

# Shell Starter Uninstaller
# Removes installed CLI scripts based on the installation manifest

# Configuration
MANIFEST_DIR="${MANIFEST_DIR:-$HOME/.config/shell-starter}"
MANIFEST_FILE="${MANIFEST_FILE:-$MANIFEST_DIR/install-manifest.txt}"

# Colors and logging
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Enhanced shell configuration detection
get_shell_configs() {
  local shell_name configs=()
  shell_name="$(basename "${SHELL:-bash}")"

  case "$shell_name" in
    zsh)
      # Check common zsh config files in order of preference
      [[ -f "$HOME/.zshrc" ]] && configs+=("$HOME/.zshrc")
      [[ -f "$HOME/.zprofile" ]] && configs+=("$HOME/.zprofile")
      ;;
    bash)
      # Check bash config files in order of preference
      [[ -f "$HOME/.bashrc" ]] && configs+=("$HOME/.bashrc")
      [[ -f "$HOME/.bash_profile" ]] && configs+=("$HOME/.bash_profile")
      [[ -f "$HOME/.profile" ]] && configs+=("$HOME/.profile")
      ;;
    fish)
      [[ -f "$HOME/.config/fish/config.fish" ]] && configs+=("$HOME/.config/fish/config.fish")
      ;;
    dash | sh)
      [[ -f "$HOME/.profile" ]] && configs+=("$HOME/.profile")
      ;;
    *)
      # Fallback: check common files
      [[ -f "$HOME/.bashrc" ]] && configs+=("$HOME/.bashrc")
      [[ -f "$HOME/.profile" ]] && configs+=("$HOME/.profile")
      ;;
  esac

  # Return all found config files
  if [[ ${#configs[@]} -gt 0 ]]; then
    printf '%s\n' "${configs[@]}"
  fi
}

# Legacy function for backward compatibility
get_shell_config() {
  get_shell_configs | head -n1
}

# Enhanced PATH cleanup from shell config
cleanup_path_from_file() {
  local config_file="$1" path_to_remove="$2"

  [[ ! -f $config_file ]] && {
    log "Config file not found: $config_file"
    return 0
  }

  # Check if any shell-starter PATH entries exist
  if ! grep -q "shell-starter" "$config_file" 2>/dev/null && ! grep -q "$path_to_remove" "$config_file" 2>/dev/null; then
    log "No shell-starter PATH entries found in $config_file"
    return 0
  fi

  log "Removing PATH entries from $config_file"
  local temp_file backup_file
  temp_file=$(mktemp)
  backup_file="${config_file}.backup.$(date +%s)"

  # Create backup
  if ! cp "$config_file" "$backup_file"; then
    error "Failed to create backup: $backup_file"
    rm -f "$temp_file"
    return 1
  fi

  # Remove multiple possible PATH entry patterns
  local escaped_path
  # shellcheck disable=SC2016
  escaped_path=$(printf '%s\n' "$path_to_remove" | sed 's/[[\.*^$()+?{|/]/\\&/g')
  sed \
    -e '/^# Added by shell-starter installer$/,+1d' \
    -e '/^# Shell Starter PATH$/,+1d' \
    -e '/^export PATH=.*shell-starter.*$/d' \
    -e "/^export PATH=.*${escaped_path}.*\$/d" \
    -e '/^PATH=.*shell-starter.*$/d' \
    -e "/^PATH=.*${escaped_path}.*\$/d" \
    "$config_file" >"$temp_file"

  # Check if any changes were actually made
  if cmp -s "$config_file" "$temp_file"; then
    # No changes made
    log "No shell-starter PATH entries found in $config_file"
    rm -f "$temp_file" "$backup_file"
    return 0
  fi

  # Verify the operation and apply changes
  if [[ -s $temp_file ]] && mv "$temp_file" "$config_file"; then
    success "Cleaned PATH from $config_file"
    log "Backup created: $backup_file"
    return 0
  else
    error "Failed to update $config_file"
    # Restore from backup
    mv "$backup_file" "$config_file" 2>/dev/null
    rm -f "$temp_file"
    return 1
  fi
}

# Clean up PATH from all detected shell config files
cleanup_path() {
  local path_to_remove="$1"
  local cleaned=0 failed=0

  log "Scanning shell configuration files for PATH cleanup..."

  # Process all detected shell config files
  while IFS= read -r config_file || [[ -n $config_file ]]; do
    if [[ -n $config_file ]]; then
      if cleanup_path_from_file "$config_file" "$path_to_remove"; then
        ((cleaned++))
      else
        ((failed++))
      fi
    fi
  done < <(get_shell_configs)

  # Report results with actionable guidance
  if [[ $cleaned -gt 0 ]]; then
    success "Cleaned PATH from $cleaned configuration file(s)"
    log "To apply changes immediately, run one of:"
    get_shell_configs | head -1 | while read -r config; do
      log "  source $config"
    done
    log "Or simply restart your terminal/shell"
  elif [[ $failed -gt 0 ]]; then
    warn "Failed to clean PATH from $failed configuration file(s)"
    warn "You may need to manually edit your shell configuration"
  else
    log "No shell configuration files found or no PATH entries to remove"
  fi

  return $((failed > 0 ? 1 : 0))
}

# Show help
show_help() {
  cat <<EOF
Shell Starter Uninstaller

Usage: $0 [OPTIONS]

OPTIONS:
    -y, --force      Skip confirmation
    -n, --dry-run    Preview what would be removed
    -h, --help       Show this help

Removes Shell Starter CLI scripts using the installation manifest.
Manifest: $MANIFEST_FILE

EXAMPLES:
    $0           # Interactive removal with preview
    $0 -y        # Force removal without confirmation
    $0 -n        # Preview files to be removed
EOF
}

# Parse arguments
parse_args() {
  FORCE_REMOVE=false
  DRY_RUN=false
  while [[ $# -gt 0 ]]; do
    case $1 in
      -y | --force)
        FORCE_REMOVE=true
        shift
        ;;
      -n | --dry-run)
        DRY_RUN=true
        shift
        ;;
      -h | --help)
        show_help
        exit 0
        ;;
      *)
        error "Unknown option: $1. Use --help for usage information."
        show_help
        exit 1
        ;;
    esac
  done
}

# Check and read manifest
read_manifest() {
  [[ ! -f $MANIFEST_FILE ]] && {
    error "No installation manifest found: $MANIFEST_FILE"
    error "Shell Starter may not be installed, or the manifest was deleted."
    error "Try running the installer first, or check if files were manually removed."
    exit 1
  }

  log "Reading manifest: $MANIFEST_FILE"
  INSTALL_PREFIX=$(grep '^# Install prefix:' "$MANIFEST_FILE" 2>/dev/null | cut -d' ' -f4- | head -1 || true)

  local file_count=0
  local temp_file
  temp_file=$(mktemp)

  if grep -v '^#\|^[[:space:]]*$' "$MANIFEST_FILE" >"$temp_file" 2>/dev/null; then
    file_count=$(wc -l <"$temp_file" 2>/dev/null | tr -d ' ')
    # Ensure it's numeric
    case "$file_count" in
      *[!0-9]*) file_count=0 ;;
    esac
  fi
  rm -f "$temp_file"

  [[ $file_count -eq 0 ]] && {
    log "No files listed in manifest. Nothing to uninstall."
    exit 0
  }

  log "Found $file_count file(s) to remove"
  [[ -n $INSTALL_PREFIX ]] && log "Install prefix: $INSTALL_PREFIX"
}

# Show files to be removed
show_files() {
  local total=0 exists=0 missing=0

  echo
  log "Files that will be removed:"

  # Count and categorize files
  while IFS= read -r file_path; do
    [[ $file_path =~ ^[#[:space:]]*$ ]] && continue
    ((total++))
    if [[ -f $file_path ]]; then
      echo "  🗑️  $file_path"
      ((exists++))
    else
      echo "  ❌ $file_path (missing)"
      ((missing++))
    fi
  done < <(grep -v '^#\|^[[:space:]]*$' "$MANIFEST_FILE")

  # Summary
  echo
  if [[ $missing -gt 0 ]]; then
    warn "$missing of $total files are already missing"
  fi
  log "$exists files ready for removal"
  [[ -n $INSTALL_PREFIX ]] && log "PATH cleanup: $INSTALL_PREFIX"
  echo
}

# Get confirmation
confirm() {
  [[ $DRY_RUN == "true" ]] && {
    log "Dry run complete. Use without --dry-run to actually remove files."
    exit 0
  }

  [[ $FORCE_REMOVE == "true" ]] && {
    log "Force removal enabled - proceeding without confirmation"
    return 0
  }

  echo -e "${YELLOW}⚠️  This will permanently delete the files shown above.${NC}"
  echo -e "${YELLOW}   Shell configuration will also be cleaned up.${NC}"
  echo
  echo -e "${YELLOW}Proceed with removal? [y/N]${NC} "
  read -r response
  case "$response" in
    [yY]*)
      log "Confirmed by user - proceeding with removal"
      return 0
      ;;
    *)
      log "Operation cancelled by user - no files were removed"
      exit 0
      ;;
  esac
}

# Remove files
remove_files() {
  local removed=0 missing=0 failed=0 total=0

  log "Removing files..."

  # Count total files first
  while IFS= read -r file_path; do
    [[ $file_path =~ ^[#[:space:]]*$ ]] && continue
    ((total++))
  done < <(grep -v '^#\|^[[:space:]]*$' "$MANIFEST_FILE")

  # Process each file with progress
  local current=0
  while IFS= read -r file_path; do
    [[ $file_path =~ ^[#[:space:]]*$ ]] && continue
    ((current++))

    printf "\r${BLUE}[INFO]${NC} Progress: %d/%d - %s" "$current" "$total" "$(basename "$file_path")"

    if [[ -f $file_path ]]; then
      if rm "$file_path" 2>/dev/null; then
        ((removed++))
      else
        echo # New line for error message
        if [[ ! -w "$(dirname "$file_path")" ]]; then
          error "Permission denied: $file_path"
          error "Try running with 'sudo' or check file permissions"
        else
          error "Failed to remove: $file_path (unknown error)"
        fi
        ((failed++))
      fi
    else
      ((missing++))
    fi
  done < <(grep -v '^#\|^[[:space:]]*$' "$MANIFEST_FILE")

  echo # New line after progress

  # Detailed summary
  if [[ $removed -gt 0 ]]; then
    success "Successfully removed $removed file(s)"
  fi
  [[ $missing -gt 0 ]] && warn "$missing file(s) were already missing"
  [[ $failed -gt 0 ]] && error "Failed to remove $failed file(s)"

  if [[ $failed -gt 0 ]]; then
    error "Some files could not be removed. Check permissions and try again."
    return 1
  fi
}

# Clean up shell PATH and manifest
cleanup() {
  if [[ -n $INSTALL_PREFIX ]]; then
    cleanup_path "$INSTALL_PREFIX"
  fi

  log "Removing manifest..."
  if rm "$MANIFEST_FILE"; then
    log "Removed: $MANIFEST_FILE"
  else
    warn "Failed to remove manifest"
  fi

  # Remove empty directory
  [[ -d $MANIFEST_DIR && -z "$(ls -A "$MANIFEST_DIR" 2>/dev/null)" ]] \
    && rmdir "$MANIFEST_DIR" 2>/dev/null && log "Removed: $MANIFEST_DIR"
}

# Main function
main() {
  local start_time
  start_time=$(date +%s)

  # Initialize variables first
  FORCE_REMOVE=false
  DRY_RUN=false

  parse_args "$@"

  if [[ $DRY_RUN == "true" ]]; then
    log "Starting Shell Starter uninstallation preview..."
  else
    log "Starting Shell Starter uninstallation..."
  fi
  read_manifest
  show_files
  confirm

  # Exit early for dry run
  [[ $DRY_RUN == "true" ]] && return 0

  if ! remove_files; then
    error "Uninstallation completed with errors. Some files may remain."
    error "Check the output above and retry with appropriate permissions."
    return 1
  fi

  if ! cleanup; then
    error "PATH cleanup completed with warnings, but files were removed successfully."
    # Don't return 1 here - cleanup issues shouldn't fail the whole operation
  fi

  local end_time duration
  end_time=$(date +%s)
  duration=$((end_time - start_time))

  echo
  success "🎉 Uninstallation completed successfully in ${duration}s!"
  log "All Shell Starter files and PATH entries have been removed"
  log "Thank you for using Shell Starter!"
}

# Run if executed directly
if [[ ${BASH_SOURCE[0]:-} == "${0:-}" ]]; then
  main "$@"
fi
