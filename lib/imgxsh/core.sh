#!/bin/bash
# imgxsh/core.sh - Core imgxsh library functions

# Check if already sourced to prevent double-sourcing
[[ -n "${IMGXSH_CORE_LOADED:-}" ]] && return 0
readonly IMGXSH_CORE_LOADED=1

# Source Shell Starter dependencies
source "${SHELL_STARTER_ROOT}/lib/colors.sh"
source "${SHELL_STARTER_ROOT}/lib/logging.sh"
source "${SHELL_STARTER_ROOT}/lib/spinner.sh"

# Source imgxsh YAML parser and validation
source "${SHELL_STARTER_ROOT}/lib/imgxsh/yaml.sh"
source "${SHELL_STARTER_ROOT}/lib/imgxsh/validation.sh"

# Core imgxsh configuration and constants
readonly IMGXSH_CONFIG_DIR="${HOME}/.imgxsh"
readonly IMGXSH_CONFIG_FILE="${IMGXSH_CONFIG_DIR}/config.yaml"
readonly IMGXSH_PLUGINS_DIR="${IMGXSH_CONFIG_DIR}/plugins"
readonly IMGXSH_PRESETS_DIR="${IMGXSH_CONFIG_DIR}/presets"
readonly IMGXSH_TEMP_DIR="${TMPDIR:-/tmp}/imgxsh"

# Internal state for error tracking
IMGXSH_ERROR_COUNT=${IMGXSH_ERROR_COUNT:-0}

# Stop any active spinner safely (no-op if none active)
_imgxsh_stop_spinner_safely() {
	# spinner::stop is safe to call even if not started, but guard just in case
	if declare -F spinner::stop >/dev/null 2>&1; then
		spinner::stop || true
	fi
}

# Central error handler (used by traps)
imgxsh::handle_error() {
	local exit_code=$?
	local last_cmd=${BASH_COMMAND:-unknown}
	local context_msg="${1:-}"

	_imgxsh_stop_spinner_safely
	((IMGXSH_ERROR_COUNT++))

	if [[ -n "$context_msg" ]]; then
		log::error "$context_msg"
	fi

	log::error "Command failed (exit $exit_code): $last_cmd"
	# Respect strict failure if set by caller
	if [[ "${IMGXSH_STRICT_FAIL:-1}" -eq 1 ]]; then
		exit "$exit_code"
	fi
}

# Install robust error traps for callers (use early in entrypoints)
imgxsh::setup_error_traps() {
	# -E to ensure ERR is inherited by functions, -o pipefail already set by scripts
	set -E
	trap 'imgxsh::handle_error "An unexpected error occurred"' ERR
	trap '_imgxsh_stop_spinner_safely' EXIT
}

# Execute a command with a spinner and consistent logging
imgxsh::with_spinner() {
	local message="$1"
	shift
	local quiet="${QUIET:-false}"

	if [[ "$quiet" != true ]]; then
		spinner::start "$message"
	fi

	# Run the command; on failure, handler will be triggered by ERR trap
	"$@"

	if [[ "$quiet" != true ]]; then
		spinner::stop
	fi
}

# Validate output directory and one or more input paths
imgxsh::validate_paths() {
	local output_dir="$1"
	shift || true

	if [[ -n "$output_dir" ]]; then
		if ! imgxsh::ensure_output_dir "$output_dir"; then
			return 1
		fi
	fi

	local input
	for input in "$@"; do
		if [[ -z "$input" ]]; then
			log::error "Empty input path provided"
			return 1
		fi
		if [[ ! -e "$input" ]]; then
			log::error "Input path does not exist: $input"
			return 1
		fi
		if [[ -f "$input" ]] && [[ ! -r "$input" ]]; then
			log::error "Cannot read file: $input"
			return 1
		fi
		if [[ -d "$input" ]] && [[ ! -x "$input" ]]; then
			log::error "Cannot access directory: $input"
			return 1
		fi
	done

	return 0
}

# Initialize imgxsh environment
imgxsh::init() {
	# Create configuration directories if they don't exist
	local dirs=(
		"$IMGXSH_CONFIG_DIR"
		"$IMGXSH_PLUGINS_DIR"
		"$IMGXSH_PRESETS_DIR"
		"$IMGXSH_TEMP_DIR"
	)

	for dir in "${dirs[@]}"; do
		if [[ ! -d "$dir" ]]; then
			if ! mkdir -p "$dir"; then
				log::error "Failed to create directory: $dir"
				return 1
			fi
		fi
	done

	# Create default config if it doesn't exist
	if [[ ! -f "$IMGXSH_CONFIG_FILE" ]]; then
		imgxsh::create_default_config
	fi

	return 0
}

# Create default configuration file
imgxsh::create_default_config() {
	local config_file="${1:-$IMGXSH_CONFIG_FILE}"
	local backup_existing="${2:-true}"

	# Create backup of existing config if it exists
	if [[ -f "$config_file" ]] && [[ "$backup_existing" == true ]]; then
		local backup_file="${config_file}.backup.$(date +%Y%m%d_%H%M%S)"
		if cp "$config_file" "$backup_file"; then
			log::info "Backed up existing config to: $backup_file"
		else
			log::warn "Failed to backup existing config"
		fi
	fi

	cat >"$config_file" <<EOF
# imgxsh Configuration File
# This file controls global settings and default workflows
# Generated on: $(date)
# Version: $(imgxsh::version)

# Global settings
settings:
  # Default directories
  output_dir: "./output"
  temp_dir: "/tmp/imgxsh"
  
  # Processing settings
  parallel_jobs: 4
  backup_policy: "auto"  # auto, manual, none
  log_level: "info"      # debug, info, warn, error
  
  # Quality settings per format
  quality:
    jpg: 85
    jpeg: 85
    webp: 90
    png: 95
    tiff: 95
    bmp: 95
    
  # Size constraints
  max_file_size: "10MB"  # Maximum output file size
  max_dimensions: "4000x4000"  # Maximum image dimensions
  
  # Notification settings
  notifications:
    enabled: false
    webhook_url: ""
    desktop_notifications: true

# Built-in workflow definitions
workflows:
  pdf-to-thumbnails:
    name: "pdf-to-thumbnails"
    description: "Extract PDF images and create thumbnails"
    version: "1.0"
    steps:
      - name: extract_images
        type: pdf_extract
        description: "Extract all images from PDF"
        params:
          input: "{workflow_input}"
          output_dir: "{temp_dir}/extracted"
          format: "png"
          
      - name: create_thumbnails
        type: resize
        description: "Create thumbnail versions"
        condition: "extracted_count > 0"
        params:
          input_dir: "{temp_dir}/extracted"
          width: 200
          height: 200
          maintain_aspect: true
          quality: 80
          output_template: "{output_dir}/{pdf_name}_thumb_{counter:03d}.jpg"
          
  web-optimize:
    name: "web-optimize"
    description: "Optimize images for web use"
    version: "1.0"
    steps:
      - name: resize_for_web
        type: resize
        description: "Resize and optimize for web"
        params:
          input: "{workflow_input}"
          max_width: 1200
          max_height: 800
          quality: 85
          format: "webp"
          output_template: "{output_dir}/{original_name}_web.{format}"
          
  excel-extract:
    name: "excel-extract"
    description: "Extract images from Excel files"
    version: "1.0"
    steps:
      - name: extract_excel_images
        type: excel_extract
        description: "Extract embedded images from Excel"
        params:
          input: "{workflow_input}"
          output_dir: "{output_dir}"
          format: "png"
          keep_names: false
          prefix: "{excel_name}_img"
          
  batch-convert:
    name: "batch-convert"
    description: "Convert image formats in batch"
    version: "1.0"
    steps:
      - name: convert_format
        type: convert
        description: "Convert images to target format"
        params:
          input: "{workflow_input}"
          output_dir: "{output_dir}"
          format: "webp"
          quality: 90
          backup: true
          
  watermark-apply:
    name: "watermark-apply"
    description: "Apply watermarks to images"
    version: "1.0"
    steps:
      - name: apply_watermark
        type: watermark
        description: "Apply watermark to images"
        params:
          input: "{workflow_input}"
          output_dir: "{output_dir}"
          watermark_file: "{watermark_path}"
          position: "bottom-right"
          opacity: 0.7

# Built-in presets
presets:
  quick-thumbnails:
    name: "quick-thumbnails"
    description: "Generate small thumbnails quickly for preview purposes"
    base_workflow: "pdf-to-thumbnails"
    overrides:
      settings:
        parallel_jobs: 8
      steps:
        create_thumbnails:
          params:
            width: 150
            height: 100
            quality: 70
            
  web-gallery-prep:
    name: "web-gallery-prep"
    description: "Prepare images for web gallery with multiple sizes"
    base_workflow: "pdf-to-thumbnails"
    overrides:
      steps:
        create_thumbnails:
          params:
            width: 300
            height: 200
            quality: 85
        - name: create_medium
          type: resize
          description: "Create medium-sized versions"
          condition: "extracted_count > 0"
          params:
            input_dir: "{temp_dir}/extracted"
            width: 800
            height: 600
            maintain_aspect: true
            quality: 90
            output_template: "{output_dir}/medium/{pdf_name}_med_{counter:03d}.jpg"
            
  high-quality:
    name: "high-quality"
    description: "High-quality processing with maximum quality settings"
    base_workflow: "web-optimize"
    overrides:
      settings:
        quality:
          jpg: 95
          webp: 95
          png: 100
      steps:
        resize_for_web:
          params:
            quality: 95
            max_width: 2000
            max_height: 1500

# Template variables available in workflows:
# {workflow_input} - Input file/directory path
# {pdf_name} - Base name of PDF file without extension
# {excel_name} - Base name of Excel file without extension
# {original_name} - Original filename without extension
# {output_dir} - Configured output directory
# {temp_dir} - Temporary working directory
# {timestamp} - Current timestamp (YYYYMMDD_HHMMSS)
# {date} - Current date (YYYY-MM-DD)
# {time} - Current time (HH:MM:SS)
# {counter:03d} - Sequential counter with zero padding
# {step_name} - Current step name
# {extracted_count} - Number of images extracted
# {processed_count} - Number of images processed
# {error_count} - Number of errors encountered
EOF

	log::success "Created default configuration at $config_file"

	# Validate the created config
	if imgxsh::validate_config "$config_file"; then
		log::info "Configuration validation passed"
	else
		log::warn "Configuration validation failed - please check the file"
		return 1
	fi

	return 0
}

# Validate that required dependencies are available
imgxsh::check_dependencies() {
	local missing_deps=()
	local required_commands=("convert" "identify" "pdfimages" "unzip")

	for cmd in "${required_commands[@]}"; do
		if ! command -v "$cmd" >/dev/null 2>&1; then
			missing_deps+=("$cmd")
		fi
	done

	if [[ ${#missing_deps[@]} -gt 0 ]]; then
		log::error "Missing required dependencies: ${missing_deps[*]}"
		log::info "Run 'imgxsh-check-deps --install-guide' for installation instructions"
		return 1
	fi

	return 0
}

# Get imgxsh version
imgxsh::version() {
	if [[ -f "${SHELL_STARTER_ROOT}/VERSION" ]]; then
		cat "${SHELL_STARTER_ROOT}/VERSION"
	else
		echo "unknown"
	fi
}

# Clean up temporary files
imgxsh::cleanup() {
	if [[ -d "$IMGXSH_TEMP_DIR" ]]; then
		log::debug "Cleaning up temporary directory: $IMGXSH_TEMP_DIR"
		rm -rf "${IMGXSH_TEMP_DIR:?}"/*
	fi
}

# Validate file input
imgxsh::validate_file() {
	local file="$1"
	local file_type="${2:-any}"

	if [[ ! -f "$file" ]]; then
		log::error "File does not exist: $file"
		return 1
	fi

	if [[ ! -r "$file" ]]; then
		log::error "Cannot read file: $file"
		return 1
	fi

	case "$file_type" in
	"pdf")
		if [[ ! "$file" =~ \.(pdf|PDF)$ ]]; then
			log::error "File is not a PDF: $file"
			return 1
		fi
		;;
	"excel")
		if [[ ! "$file" =~ \.(xlsx|xls|XLSX|XLS)$ ]]; then
			log::error "File is not an Excel file: $file"
			return 1
		fi
		;;
	"image")
		if [[ ! "$file" =~ \.(jpg|jpeg|png|gif|bmp|tiff|webp|JPG|JPEG|PNG|GIF|BMP|TIFF|WEBP)$ ]]; then
			log::error "File is not a supported image format: $file"
			return 1
		fi
		;;
	esac

	return 0
}

# Create output directory if it doesn't exist
imgxsh::ensure_output_dir() {
	local output_dir="$1"

	if [[ ! -d "$output_dir" ]]; then
		if ! mkdir -p "$output_dir"; then
			log::error "Failed to create output directory: $output_dir"
			return 1
		fi
		log::debug "Created output directory: $output_dir"
	fi

	return 0
}

# Basic YAML validation without external tools
imgxsh::validate_yaml_basic() {
	local config_file="$1"
	local -i error_count=0

	# Check for common YAML syntax issues
	# 1. Check for basic YAML structure issues
	# Check for lines that look like they should have values but don't
	# Exclude section headers (top-level keys) which are valid without values
	# Handle comments by checking if line ends with colon and optional whitespace/comment
	if grep -q '^[[:space:]]\+[a-zA-Z_][a-zA-Z0-9_]*:[[:space:]]*\(#.*\)\?$' "$config_file"; then
		log::error "Found key without value (missing colon or value)"
		((error_count++))
	fi

	# 2. Check for invalid indentation (mixed tabs and spaces)
	if grep -q $'\t' "$config_file" && grep -q '^[ ]' "$config_file"; then
		log::error "Mixed tabs and spaces in indentation"
		((error_count++))
	fi

	# 3. Check for basic structure (must have at least one key-value pair)
	if ! grep -q '^[a-zA-Z_][a-zA-Z0-9_]*:' "$config_file"; then
		log::error "No valid YAML keys found"
		((error_count++))
	fi

	# 4. Check for required sections (basic grep check)
	local required_sections=("settings:" "workflows:" "presets:")
	for section in "${required_sections[@]}"; do
		if ! grep -q "^$section" "$config_file"; then
			log::error "Missing required section: $section"
			((error_count++))
		fi
	done

	# 5. Check for basic settings
	local required_settings=("output_dir:" "temp_dir:" "parallel_jobs:")
	for setting in "${required_settings[@]}"; do
		if ! grep -q "^\s*$setting" "$config_file"; then
			log::error "Missing required setting: $setting"
			((error_count++))
		fi
	done

	if [[ $error_count -gt 0 ]]; then
		log::error "Basic YAML validation failed with $error_count errors"
		return 1
	fi

	log::debug "Basic YAML validation passed"
	return 0
}

# Load configuration from file
imgxsh::load_config() {
	local config_file="${1:-$IMGXSH_CONFIG_FILE}"

	if [[ ! -f "$config_file" ]]; then
		log::error "Configuration file not found: $config_file"
		return 1
	fi

	if [[ ! -r "$config_file" ]]; then
		log::error "Cannot read configuration file: $config_file"
		return 1
	fi

	# Export config file path for other functions
	export IMGXSH_ACTIVE_CONFIG="$config_file"

	log::debug "Loaded configuration from: $config_file"
	return 0
}

# Validate configuration file
imgxsh::validate_config() {
	local config_file="${1:-$IMGXSH_CONFIG_FILE}"
	local -i error_count=0

	if [[ ! -f "$config_file" ]]; then
		log::error "Configuration file not found: $config_file"
		return 1
	fi

	# Check if file is valid YAML (basic check)
	if ! command -v yq >/dev/null 2>&1; then
		log::warn "yq not available - using basic YAML validation"

		# Basic YAML syntax validation using grep patterns
		if ! imgxsh::validate_yaml_basic "$config_file"; then
			log::error "Basic YAML validation failed"
			((error_count++))
		fi
	else
		# Use yq for robust YAML validation
		if ! yq eval '.' "$config_file" >/dev/null 2>&1; then
			log::error "Invalid YAML syntax in configuration file: $config_file"
			((error_count++))
		fi
	fi

	# Validate required sections
	local required_sections=("settings" "workflows" "presets")
	for section in "${required_sections[@]}"; do
		if command -v yq >/dev/null 2>&1; then
			if ! yq eval ".$section" "$config_file" >/dev/null 2>&1; then
				log::error "Missing required section: $section"
				((error_count++))
			fi
		else
			# Fallback: check if section exists in file
			if ! grep -q "^$section:" "$config_file"; then
				log::error "Missing required section: $section"
				((error_count++))
			fi
		fi
	done

	# Validate settings section
	if command -v yq >/dev/null 2>&1; then
		if yq eval '.settings' "$config_file" >/dev/null 2>&1; then
			# Check required settings
			local required_settings=("output_dir" "temp_dir" "parallel_jobs")
			for setting in "${required_settings[@]}"; do
				if ! yq eval ".settings.$setting" "$config_file" >/dev/null 2>&1; then
					log::error "Missing required setting: settings.$setting"
					((error_count++))
				fi
			done

			# Validate parallel_jobs is a number
			local parallel_jobs
			parallel_jobs=$(yq eval '.settings.parallel_jobs' "$config_file" 2>/dev/null)
			if [[ -n "$parallel_jobs" ]] && ! [[ "$parallel_jobs" =~ ^[0-9]+$ ]]; then
				log::error "settings.parallel_jobs must be a number, got: $parallel_jobs"
				((error_count++))
			fi
		fi
	else
		# Fallback: basic settings validation
		local required_settings=("output_dir:" "temp_dir:" "parallel_jobs:")
		for setting in "${required_settings[@]}"; do
			if ! grep -q "^\s*$setting" "$config_file"; then
				log::error "Missing required setting: $setting"
				((error_count++))
			fi
		done

		# Validate parallel_jobs is a number (basic check)
		local parallel_jobs
		parallel_jobs=$(grep "^\s*parallel_jobs:" "$config_file" | head -1 | sed 's/.*parallel_jobs:\s*//' | sed 's/#.*$//' | tr -d '"' | tr -d "'" | tr -d ' \t')
		if [[ -n "$parallel_jobs" ]] && ! [[ "$parallel_jobs" =~ ^[0-9]+$ ]]; then
			log::error "settings.parallel_jobs must be a number, got: $parallel_jobs"
			((error_count++))
		fi
	fi

	if [[ $error_count -gt 0 ]]; then
		log::error "Configuration validation failed with $error_count errors"
		return 1
	fi

	log::success "Configuration validation passed"
	return 0
}

# Get configuration value
imgxsh::get_config() {
	local key="$1"
	local config_file="${2:-$IMGXSH_CONFIG_FILE}"

	if [[ ! -f "$config_file" ]]; then
		log::error "Configuration file not found: $config_file"
		return 1
	fi

	if command -v yq >/dev/null 2>&1; then
		yq eval ".$key" "$config_file" 2>/dev/null
	else
		# Fallback to grep-based parsing for basic values
		case "$key" in
		"settings.output_dir")
			grep -E "^\s*output_dir:" "$config_file" | sed 's/.*output_dir:\s*//' | tr -d '"' | tr -d "'"
			;;
		"settings.temp_dir")
			grep -E "^\s*temp_dir:" "$config_file" | sed 's/.*temp_dir:\s*//' | tr -d '"' | tr -d "'"
			;;
		"settings.parallel_jobs")
			grep -E "^\s*parallel_jobs:" "$config_file" | sed 's/.*parallel_jobs:\s*//' | tr -d '"' | tr -d "'"
			;;
		*)
			log::warn "Cannot parse complex config key without yq: $key"
			return 1
			;;
		esac
	fi
}

# List available workflows from config
imgxsh::list_workflows() {
	local config_file="${1:-$IMGXSH_CONFIG_FILE}"

	if [[ ! -f "$config_file" ]]; then
		log::error "Configuration file not found: $config_file"
		return 1
	fi

	if command -v yq >/dev/null 2>&1; then
		yq eval '.workflows | keys[]' "$config_file" 2>/dev/null
	else
		# Fallback to grep-based parsing - find workflows section and extract workflow names
		# Only get the top-level workflow names (2 spaces indentation)
		sed -n '/^workflows:/,/^[a-zA-Z]/p' "$config_file" | grep -E "^\s{2}[a-zA-Z0-9_-]+:$" | sed 's/://' | tr -d ' \t'
	fi
}

# List available presets from config
imgxsh::list_presets() {
	local config_file="${1:-$IMGXSH_CONFIG_FILE}"

	if [[ ! -f "$config_file" ]]; then
		log::error "Configuration file not found: $config_file"
		return 1
	fi

	if command -v yq >/dev/null 2>&1; then
		yq eval '.presets | keys[]' "$config_file" 2>/dev/null
	else
		# Fallback to grep-based parsing - find presets section and extract preset names
		# Only get the top-level preset names (2 spaces indentation)
		sed -n '/^presets:/,/^[a-zA-Z]/p' "$config_file" | grep -E "^\s{2}[a-zA-Z0-9_-]+:$" | sed 's/://' | tr -d ' \t'
	fi
}

# Create user preset
imgxsh::create_preset() {
	local preset_name="$1"
	local base_workflow="$2"
	local description="$3"
	local config_file="${4:-$IMGXSH_CONFIG_FILE}"

	if [[ -z "$preset_name" ]] || [[ -z "$base_workflow" ]]; then
		log::error "Usage: imgxsh::create_preset PRESET_NAME BASE_WORKFLOW [DESCRIPTION] [CONFIG_FILE]"
		return 1
	fi

	if [[ ! -f "$config_file" ]]; then
		log::error "Configuration file not found: $config_file"
		return 1
	fi

	# Check if preset already exists
	if imgxsh::list_presets "$config_file" | grep -q "^$preset_name$"; then
		log::error "Preset '$preset_name' already exists"
		return 1
	fi

	# Check if base workflow exists
	if ! imgxsh::list_workflows "$config_file" | grep -q "^$base_workflow$"; then
		log::error "Base workflow '$base_workflow' not found"
		return 1
	fi

	# Create preset entry
	log::info "Creating preset '$preset_name' based on workflow '$base_workflow'"

	# Use yq if available for proper YAML manipulation
	if command -v yq >/dev/null 2>&1; then
		# Create temporary preset definition
		local temp_preset_file="${IMGXSH_TEMP_DIR}/preset_${preset_name}.yaml"
		cat >"$temp_preset_file" <<EOF
  $preset_name:
    name: "$preset_name"
    description: "${description:-User-created preset based on $base_workflow}"
    base_workflow: "$base_workflow"
    overrides:
      settings:
        # Add custom settings here
      steps:
        # Add step overrides here
EOF

		# Insert preset into config file
		if yq eval-all 'select(fileIndex == 0) * select(fileIndex == 1)' "$config_file" "$temp_preset_file" >"${config_file}.tmp" 2>/dev/null; then
			mv "${config_file}.tmp" "$config_file"
			rm -f "$temp_preset_file"
			log::success "Preset '$preset_name' created successfully"
			return 0
		else
			log::error "Failed to add preset to configuration file"
			rm -f "$temp_preset_file" "${config_file}.tmp"
			return 1
		fi
	else
		# Fallback: append to presets section (basic approach)
		log::warn "yq not available - using basic preset creation"

		# Find the end of the presets section and add the new preset
		local temp_config="${config_file}.tmp"
		local in_presets=false
		local preset_added=false
		local line_count=0
		local total_lines
		total_lines=$(wc -l <"$config_file")

		while IFS= read -r line; do
			((line_count++))

			if [[ "$line" =~ ^presets:$ ]]; then
				in_presets=true
				echo "$line" >>"$temp_config"
			elif [[ "$in_presets" == true ]] && [[ "$line" =~ ^[a-zA-Z] ]] && [[ ! "$line" =~ ^[[:space:]] ]]; then
				# End of presets section, add our preset before this line
				if [[ "$preset_added" == false ]]; then
					cat >>"$temp_config" <<EOF
  $preset_name:
    name: "$preset_name"
    description: "${description:-User-created preset based on $base_workflow}"
    base_workflow: "$base_workflow"
    overrides:
      settings:
        # Add custom settings here
      steps:
        # Add step overrides here

EOF
					preset_added=true
				fi
				in_presets=false
				echo "$line" >>"$temp_config"
			elif [[ "$in_presets" == true ]] && [[ $line_count -eq $total_lines ]]; then
				# End of file while in presets section, add our preset
				if [[ "$preset_added" == false ]]; then
					cat >>"$temp_config" <<EOF
  $preset_name:
    name: "$preset_name"
    description: "${description:-User-created preset based on $base_workflow}"
    base_workflow: "$base_workflow"
    overrides:
      settings:
        # Add custom settings here
      steps:
        # Add step overrides here

EOF
					preset_added=true
				fi
				echo "$line" >>"$temp_config"
			else
				echo "$line" >>"$temp_config"
			fi
		done <"$config_file"

		if [[ "$preset_added" == true ]]; then
			mv "$temp_config" "$config_file"
			log::success "Preset '$preset_name' created successfully (basic mode)"
			return 0
		else
			log::error "Failed to add preset to configuration file"
			rm -f "$temp_config"
			return 1
		fi
	fi
}

# Delete user preset
imgxsh::delete_preset() {
	local preset_name="$1"
	local config_file="${2:-$IMGXSH_CONFIG_FILE}"

	if [[ -z "$preset_name" ]]; then
		log::error "Usage: imgxsh::delete_preset PRESET_NAME [CONFIG_FILE]"
		return 1
	fi

	if [[ ! -f "$config_file" ]]; then
		log::error "Configuration file not found: $config_file"
		return 1
	fi

	# Check if preset exists
	if ! imgxsh::list_presets "$config_file" | grep -q "^$preset_name$"; then
		log::error "Preset '$preset_name' not found"
		return 1
	fi

	# Check if it's a built-in preset
	local builtin_presets=("quick-thumbnails" "web-gallery-prep" "high-quality")
	for builtin in "${builtin_presets[@]}"; do
		if [[ "$preset_name" == "$builtin" ]]; then
			log::error "Cannot delete built-in preset: $preset_name"
			return 1
		fi
	done

	log::info "Deleting preset: $preset_name"

	# Use yq if available for proper YAML manipulation
	if command -v yq >/dev/null 2>&1; then
		if yq eval "del(.presets.$preset_name)" "$config_file" >"${config_file}.tmp" 2>/dev/null; then
			mv "${config_file}.tmp" "$config_file"
			log::success "Preset '$preset_name' deleted successfully"
			return 0
		else
			log::error "Failed to delete preset from configuration file"
			rm -f "${config_file}.tmp"
			return 1
		fi
	else
		# Fallback: basic deletion using sed
		log::warn "yq not available - using basic preset deletion"

		local temp_config="${config_file}.tmp"
		local in_preset=false
		local preset_deleted=false

		while IFS= read -r line; do
			if [[ "$line" =~ ^[[:space:]]*$preset_name:$ ]]; then
				in_preset=true
				preset_deleted=true
				# Skip this line and all indented lines that follow
				continue
			elif [[ "$in_preset" == true ]] && [[ "$line" =~ ^[[:space:]]*[a-zA-Z] ]]; then
				# End of preset section
				in_preset=false
				echo "$line" >>"$temp_config"
			elif [[ "$in_preset" == false ]]; then
				echo "$line" >>"$temp_config"
			fi
		done <"$config_file"

		if [[ "$preset_deleted" == true ]]; then
			mv "$temp_config" "$config_file"
			log::success "Preset '$preset_name' deleted successfully (basic mode)"
			return 0
		else
			log::error "Failed to delete preset from configuration file"
			rm -f "$temp_config"
			return 1
		fi
	fi
}

# Export preset to file
imgxsh::export_preset() {
	local preset_name="$1"
	local output_file="$2"
	local config_file="${3:-$IMGXSH_CONFIG_FILE}"

	if [[ -z "$preset_name" ]] || [[ -z "$output_file" ]]; then
		log::error "Usage: imgxsh::export_preset PRESET_NAME OUTPUT_FILE [CONFIG_FILE]"
		return 1
	fi

	if [[ ! -f "$config_file" ]]; then
		log::error "Configuration file not found: $config_file"
		return 1
	fi

	# Check if preset exists
	if ! imgxsh::list_presets "$config_file" | grep -q "^$preset_name$"; then
		log::error "Preset '$preset_name' not found"
		return 1
	fi

	log::info "Exporting preset '$preset_name' to: $output_file"

	# Use yq if available for proper YAML extraction
	if command -v yq >/dev/null 2>&1; then
		if yq eval ".presets.$preset_name" "$config_file" >"$output_file" 2>/dev/null; then
			log::success "Preset exported successfully"
			return 0
		else
			log::error "Failed to export preset"
			return 1
		fi
	else
		# Fallback: basic extraction using sed
		log::warn "yq not available - using basic preset export"

		local in_preset=false
		local preset_found=false

		while IFS= read -r line; do
			if [[ "$line" =~ ^[[:space:]]*$preset_name:$ ]]; then
				in_preset=true
				preset_found=true
				echo "$line" >"$output_file"
			elif [[ "$in_preset" == true ]] && [[ "$line" =~ ^[[:space:]]*[a-zA-Z] ]] && [[ ! "$line" =~ ^[[:space:]] ]]; then
				# End of preset section
				break
			elif [[ "$in_preset" == true ]]; then
				echo "$line" >>"$output_file"
			fi
		done <"$config_file"

		if [[ "$preset_found" == true ]]; then
			log::success "Preset exported successfully (basic mode)"
			return 0
		else
			log::error "Failed to export preset"
			return 1
		fi
	fi
}

# Import preset from file
imgxsh::import_preset() {
	local input_file="$1"
	local preset_name="$2"
	local config_file="${3:-$IMGXSH_CONFIG_FILE}"

	if [[ -z "$input_file" ]] || [[ -z "$preset_name" ]]; then
		log::error "Usage: imgxsh::import_preset INPUT_FILE PRESET_NAME [CONFIG_FILE]"
		return 1
	fi

	if [[ ! -f "$input_file" ]]; then
		log::error "Input file not found: $input_file"
		return 1
	fi

	if [[ ! -f "$config_file" ]]; then
		log::error "Configuration file not found: $config_file"
		return 1
	fi

	# Check if preset already exists
	if imgxsh::list_presets "$config_file" | grep -q "^$preset_name$"; then
		log::error "Preset '$preset_name' already exists"
		return 1
	fi

	log::info "Importing preset '$preset_name' from: $input_file"

	# Use yq if available for proper YAML manipulation
	if command -v yq >/dev/null 2>&1; then
		# Read the preset content and add it to the config
		local preset_content
		preset_content=$(yq eval '.' "$input_file" 2>/dev/null)

		if [[ -n "$preset_content" ]]; then
			# Create temporary file with the preset
			local temp_preset_file="${IMGXSH_TEMP_DIR}/import_${preset_name}.yaml"
			echo "presets:" >"$temp_preset_file"
			echo "  $preset_name:" >>"$temp_preset_file"
			echo "$preset_content" | sed 's/^/    /' >>"$temp_preset_file"

			# Merge with existing config
			if yq eval-all 'select(fileIndex == 0) * select(fileIndex == 1)' "$config_file" "$temp_preset_file" >"${config_file}.tmp" 2>/dev/null; then
				mv "${config_file}.tmp" "$config_file"
				rm -f "$temp_preset_file"
				log::success "Preset imported successfully"
				return 0
			else
				log::error "Failed to import preset to configuration file"
				rm -f "$temp_preset_file" "${config_file}.tmp"
				return 1
			fi
		else
			log::error "Invalid preset file format"
			return 1
		fi
	else
		# Fallback: basic import using file concatenation
		log::warn "yq not available - using basic preset import"

		# Find the end of the presets section and add the new preset
		local temp_config="${config_file}.tmp"
		local in_presets=false
		local preset_added=false
		local line_count=0
		local total_lines
		total_lines=$(wc -l <"$config_file")

		while IFS= read -r line; do
			((line_count++))

			if [[ "$line" =~ ^presets:$ ]]; then
				in_presets=true
				echo "$line" >>"$temp_config"
			elif [[ "$in_presets" == true ]] && [[ "$line" =~ ^[a-zA-Z] ]] && [[ ! "$line" =~ ^[[:space:]] ]]; then
				# End of presets section, add our preset before this line
				if [[ "$preset_added" == false ]]; then
					echo "  $preset_name:" >>"$temp_config"
					# Add the preset content with proper indentation, skipping the first line (preset name)
					tail -n +2 "$input_file" | sed 's/^/    /' >>"$temp_config"
					echo >>"$temp_config"
					preset_added=true
				fi
				in_presets=false
				echo "$line" >>"$temp_config"
			elif [[ "$in_presets" == true ]] && [[ $line_count -eq $total_lines ]]; then
				# End of file while in presets section, add our preset
				if [[ "$preset_added" == false ]]; then
					echo "  $preset_name:" >>"$temp_config"
					# Add the preset content with proper indentation, skipping the first line (preset name)
					tail -n +2 "$input_file" | sed 's/^/    /' >>"$temp_config"
					echo >>"$temp_config"
					preset_added=true
				fi
				echo "$line" >>"$temp_config"
			else
				echo "$line" >>"$temp_config"
			fi
		done <"$config_file"

		if [[ "$preset_added" == true ]]; then
			mv "$temp_config" "$config_file"
			log::success "Preset imported successfully (basic mode)"
			return 0
		else
			log::error "Failed to import preset to configuration file"
			rm -f "$temp_config"
			return 1
		fi
	fi
}

# Template variable substitution
imgxsh::substitute_template() {
	local template="$1"
	local -A variables=()

	# Parse additional arguments as key=value pairs
	shift
	while [[ $# -gt 0 ]]; do
		if [[ "$1" =~ ^([^=]+)=(.*)$ ]]; then
			variables["${BASH_REMATCH[1]}"]="${BASH_REMATCH[2]}"
		fi
		shift
	done

	# Add common variables
	variables["timestamp"]="$(date +%Y%m%d_%H%M%S)"
	variables["date"]="$(date +%Y-%m-%d)"
	variables["time"]="$(date +%H:%M:%S)"

	local result="$template"

	# Substitute variables
	for var in "${!variables[@]}"; do
		result="${result//\{$var\}/${variables[$var]}}"
	done

	echo "$result"
}
