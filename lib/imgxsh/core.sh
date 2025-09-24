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
	cat >"$IMGXSH_CONFIG_FILE" <<EOF
# imgxsh Configuration File
# This file controls global settings and default workflows
# Generated on: $(date)

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

	log::success "Created default configuration at $IMGXSH_CONFIG_FILE"
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
	local errors=0
	
	# Check for common YAML syntax issues
	# 1. Check for basic YAML structure issues
	# Check for lines that look like they should have values but don't
	# Exclude section headers (top-level keys) which are valid without values
	# Handle comments by checking if line ends with colon and optional whitespace/comment
	if grep -q '^[[:space:]]\+[a-zA-Z_][a-zA-Z0-9_]*:[[:space:]]*\(#.*\)\?$' "$config_file"; then
		log::error "Found key without value (missing colon or value)"
		((errors++))
	fi
	
	# 2. Check for invalid indentation (mixed tabs and spaces)
	if grep -q $'\t' "$config_file" && grep -q '^[ ]' "$config_file"; then
		log::error "Mixed tabs and spaces in indentation"
		((errors++))
	fi
	
	# 3. Check for basic structure (must have at least one key-value pair)
	if ! grep -q '^[a-zA-Z_][a-zA-Z0-9_]*:' "$config_file"; then
		log::error "No valid YAML keys found"
		((errors++))
	fi
	
	# 4. Check for required sections (basic grep check)
	local required_sections=("settings:" "workflows:" "presets:")
	for section in "${required_sections[@]}"; do
		if ! grep -q "^$section" "$config_file"; then
			log::error "Missing required section: $section"
			((errors++))
		fi
	done
	
	# 5. Check for basic settings
	local required_settings=("output_dir:" "temp_dir:" "parallel_jobs:")
	for setting in "${required_settings[@]}"; do
		if ! grep -q "^\s*$setting" "$config_file"; then
			log::error "Missing required setting: $setting"
			((errors++))
		fi
	done
	
	if [[ $errors -gt 0 ]]; then
		log::error "Basic YAML validation failed with $errors errors"
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
	local errors=0
	
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
			((errors++))
		fi
	else
		# Use yq for robust YAML validation
		if ! yq eval '.' "$config_file" >/dev/null 2>&1; then
			log::error "Invalid YAML syntax in configuration file: $config_file"
			((errors++))
		fi
	fi
	
	# Validate required sections
	local required_sections=("settings" "workflows" "presets")
	for section in "${required_sections[@]}"; do
		if command -v yq >/dev/null 2>&1; then
			if ! yq eval ".$section" "$config_file" >/dev/null 2>&1; then
				log::error "Missing required section: $section"
				((errors++))
			fi
		else
			# Fallback: check if section exists in file
			if ! grep -q "^$section:" "$config_file"; then
				log::error "Missing required section: $section"
				((errors++))
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
					((errors++))
				fi
			done
			
			# Validate parallel_jobs is a number
			local parallel_jobs
			parallel_jobs=$(yq eval '.settings.parallel_jobs' "$config_file" 2>/dev/null)
			if [[ -n "$parallel_jobs" ]] && ! [[ "$parallel_jobs" =~ ^[0-9]+$ ]]; then
				log::error "settings.parallel_jobs must be a number, got: $parallel_jobs"
				((errors++))
			fi
		fi
	else
		# Fallback: basic settings validation
		local required_settings=("output_dir:" "temp_dir:" "parallel_jobs:")
		for setting in "${required_settings[@]}"; do
			if ! grep -q "^\s*$setting" "$config_file"; then
				log::error "Missing required setting: $setting"
				((errors++))
			fi
		done
		
		# Validate parallel_jobs is a number (basic check)
		local parallel_jobs
		parallel_jobs=$(grep "^\s*parallel_jobs:" "$config_file" | head -1 | sed 's/.*parallel_jobs:\s*//' | sed 's/#.*$//' | tr -d '"' | tr -d "'" | tr -d ' \t')
		if [[ -n "$parallel_jobs" ]] && ! [[ "$parallel_jobs" =~ ^[0-9]+$ ]]; then
			log::error "settings.parallel_jobs must be a number, got: $parallel_jobs"
			((errors++))
		fi
	fi
	
	if [[ $errors -gt 0 ]]; then
		log::error "Configuration validation failed with $errors errors"
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
	local config_file="${3:-$IMGXSH_CONFIG_FILE}"
	
	if [[ -z "$preset_name" ]] || [[ -z "$base_workflow" ]]; then
		log::error "Usage: imgxsh::create_preset PRESET_NAME BASE_WORKFLOW [CONFIG_FILE]"
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
	
	# Create preset entry (this would need yq for proper YAML manipulation)
	log::info "Creating preset '$preset_name' based on workflow '$base_workflow'"
	log::warn "Manual YAML editing required - preset creation not fully automated without yq"
	
	return 0
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
