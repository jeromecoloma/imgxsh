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
    cat > "$IMGXSH_CONFIG_FILE" << 'EOF'
# imgxsh Configuration File
# This file controls global settings and default workflows

settings:
  output_dir: "./output"
  temp_dir: "/tmp/imgxsh"
  parallel_jobs: 4
  backup_policy: "auto"  # auto, manual, none
  log_level: "info"      # debug, info, warn, error
  
  # Quality settings per format
  quality:
    jpg: 85
    webp: 90
    png: 95

workflows:
  # Built-in workflow presets
  pdf-to-thumbnails:
    description: "Extract PDF images and create thumbnails"
    steps:
      - name: extract_images
        type: pdf_extract
        params:
          input: "{workflow_input}"
          output_dir: "{temp_dir}/extracted"
          
      - name: create_thumbnails
        type: resize
        params:
          width: 200
          height: 200
          maintain_aspect: true
          output_template: "{output_dir}/{pdf_name}_thumb_{counter:03d}.jpg"
          
  web-optimize:
    description: "Optimize images for web use"
    steps:
      - name: resize_for_web
        type: resize
        params:
          max_width: 1200
          max_height: 800
          quality: 85
          format: "webp"
          output_template: "{output_dir}/{original_name}_web.{format}"

presets:
  quick-thumbnails:
    workflow: pdf-to-thumbnails
    overrides:
      width: 150
      height: 150
      quality: 70
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
