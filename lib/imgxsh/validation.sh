#!/bin/bash
# imgxsh/validation.sh - Comprehensive workflow validation system

# Check if already sourced to prevent double-sourcing
[[ -n "${IMGXSH_VALIDATION_LOADED:-}" ]] && return 0
readonly IMGXSH_VALIDATION_LOADED=1

# Source Shell Starter dependencies
source "${SHELL_STARTER_ROOT}/lib/colors.sh"
source "${SHELL_STARTER_ROOT}/lib/logging.sh"

# Source imgxsh dependencies
source "${SHELL_STARTER_ROOT}/lib/imgxsh/yaml.sh"

# Validation error collection
declare -a VALIDATION_ERRORS
declare -a VALIDATION_WARNINGS

# Clear validation results
validation::clear_results() {
    VALIDATION_ERRORS=()
    VALIDATION_WARNINGS=()
}

# Add validation error
validation::add_error() {
    local error_msg="$1"
    VALIDATION_ERRORS+=("$error_msg")
}

# Add validation warning
validation::add_warning() {
    local warning_msg="$1"
    VALIDATION_WARNINGS+=("$warning_msg")
}

# Get validation error count
validation::error_count() {
    echo "${#VALIDATION_ERRORS[@]}"
}

# Get validation warning count
validation::warning_count() {
    echo "${#VALIDATION_WARNINGS[@]}"
}

# Report validation results
validation::report_results() {
    local error_count="${#VALIDATION_ERRORS[@]}"
    local warning_count="${#VALIDATION_WARNINGS[@]}"
    
    if [[ $error_count -gt 0 ]]; then
        log::error "Workflow validation failed with $error_count error(s):"
        for error in "${VALIDATION_ERRORS[@]}"; do
            log::error "  - $error"
        done
    fi
    
    if [[ $warning_count -gt 0 ]]; then
        log::warn "Workflow validation completed with $warning_count warning(s):"
        for warning in "${VALIDATION_WARNINGS[@]}"; do
            log::warn "  - $warning"
        done
    fi
    
    if [[ $error_count -eq 0 && $warning_count -eq 0 ]]; then
        log::success "Workflow validation passed"
    fi
    
    if [[ $error_count -eq 0 ]]; then
        return 0
    else
        return 1
    fi
}

# Validate step type and its required parameters
validation::validate_step_type() {
    local step_type="$1"
    local step_index="$2"
    local workflow_prefix="$3"
    local step_name
    step_name=$(yaml::get_step_var "$workflow_prefix" "$step_index" "NAME")
    
    case "$step_type" in
        "pdf_extract")
            validation::validate_pdf_extract_step "$step_index" "$workflow_prefix" "$step_name"
            ;;
        "excel_extract")
            validation::validate_excel_extract_step "$step_index" "$workflow_prefix" "$step_name"
            ;;
        "convert")
            validation::validate_convert_step "$step_index" "$workflow_prefix" "$step_name"
            ;;
        "resize")
            validation::validate_resize_step "$step_index" "$workflow_prefix" "$step_name"
            ;;
        "watermark")
            validation::validate_watermark_step "$step_index" "$workflow_prefix" "$step_name"
            ;;
        "ocr")
            validation::validate_ocr_step "$step_index" "$workflow_prefix" "$step_name"
            ;;
        "webhook")
            validation::validate_webhook_step "$step_index" "$workflow_prefix" "$step_name"
            ;;
        "custom")
            validation::validate_custom_step "$step_index" "$workflow_prefix" "$step_name"
            ;;
        *)
            validation::add_error "Step '$step_name': Unknown step type '$step_type'"
            ;;
    esac
}

# Validate PDF extraction step
validation::validate_pdf_extract_step() {
    local step_index="$1"
    local workflow_prefix="$2"
    local step_name="$3"
    
    # Check required parameters
    local input_param
    input_param=$(yaml::get_step_param "$workflow_prefix" "$step_index" "INPUT")
    if [[ -z "$input_param" ]]; then
        validation::add_error "Step '$step_name': Missing required parameter 'input'"
    fi
    
    local output_dir_param
    output_dir_param=$(yaml::get_step_param "$workflow_prefix" "$step_index" "OUTPUT_DIR")
    if [[ -z "$output_dir_param" ]]; then
        validation::add_error "Step '$step_name': Missing required parameter 'output_dir'"
    fi
    
    # Validate optional parameters
    local format_param
    format_param=$(yaml::get_step_param "$workflow_prefix" "$step_index" "FORMAT")
    if [[ -n "$format_param" ]]; then
        case "$format_param" in
            "png"|"jpg"|"jpeg"|"ppm"|"pbm")
                # Valid formats for pdfimages
                ;;
            *)
                validation::add_warning "Step '$step_name': Format '$format_param' may not be supported by pdfimages"
                ;;
        esac
    fi
    
    # Check dependency
    if ! command -v pdfimages >/dev/null 2>&1; then
        validation::add_error "Step '$step_name': Required dependency 'pdfimages' not found"
    fi
}

# Validate Excel extraction step
validation::validate_excel_extract_step() {
    local step_index="$1"
    local workflow_prefix="$2"
    local step_name="$3"
    
    # Check required parameters
    local input_param
    input_param=$(yaml::get_step_param "$workflow_prefix" "$step_index" "INPUT")
    if [[ -z "$input_param" ]]; then
        validation::add_error "Step '$step_name': Missing required parameter 'input'"
    fi
    
    local output_dir_param
    output_dir_param=$(yaml::get_step_param "$workflow_prefix" "$step_index" "OUTPUT_DIR")
    if [[ -z "$output_dir_param" ]]; then
        validation::add_error "Step '$step_name': Missing required parameter 'output_dir'"
    fi
    
    # Check dependency
    if ! command -v unzip >/dev/null 2>&1; then
        validation::add_error "Step '$step_name': Required dependency 'unzip' not found"
    fi
}

# Validate convert step
validation::validate_convert_step() {
    local step_index="$1"
    local workflow_prefix="$2"
    local step_name="$3"
    
    # Check required parameters
    local format_param
    format_param=$(yaml::get_step_param "$workflow_prefix" "$step_index" "FORMAT")
    if [[ -z "$format_param" ]]; then
        validation::add_error "Step '$step_name': Missing required parameter 'format'"
    else
        # Validate format
        case "$format_param" in
            "jpg"|"jpeg"|"png"|"webp"|"tiff"|"bmp"|"gif")
                # Valid formats
                ;;
            *)
                validation::add_warning "Step '$step_name': Format '$format_param' may not be supported"
                ;;
        esac
    fi
    
    # Validate quality parameter if present
    local quality_param
    quality_param=$(yaml::get_step_param "$workflow_prefix" "$step_index" "QUALITY")
    if [[ -n "$quality_param" ]]; then
        if ! [[ "$quality_param" =~ ^[0-9]+$ ]] || [[ "$quality_param" -lt 1 ]] || [[ "$quality_param" -gt 100 ]]; then
            validation::add_error "Step '$step_name': Quality must be a number between 1 and 100, got '$quality_param'"
        fi
    fi
    
    # Check dependency
    if ! command -v convert >/dev/null 2>&1; then
        validation::add_error "Step '$step_name': Required dependency 'convert' (ImageMagick) not found"
    fi
}

# Validate resize step
validation::validate_resize_step() {
    local step_index="$1"
    local workflow_prefix="$2"
    local step_name="$3"
    
    # Check for width or height parameters
    local width_param
    local height_param
    local max_width_param
    local max_height_param
    
    width_param=$(yaml::get_step_param "$workflow_prefix" "$step_index" "WIDTH")
    height_param=$(yaml::get_step_param "$workflow_prefix" "$step_index" "HEIGHT")
    max_width_param=$(yaml::get_step_param "$workflow_prefix" "$step_index" "MAX_WIDTH")
    max_height_param=$(yaml::get_step_param "$workflow_prefix" "$step_index" "MAX_HEIGHT")
    
    if [[ -z "$width_param" && -z "$height_param" && -z "$max_width_param" && -z "$max_height_param" ]]; then
        validation::add_error "Step '$step_name': Must specify at least one dimension (width, height, max_width, or max_height)"
    fi
    
    # Validate numeric parameters
    for param_name in "width" "height" "max_width" "max_height"; do
        local param_value
        local upper_param=$(echo "$param_name" | tr '[:lower:]' '[:upper:]')
        param_value=$(yaml::get_step_param "$workflow_prefix" "$step_index" "$upper_param")
        
        if [[ -n "$param_value" ]]; then
            if ! [[ "$param_value" =~ ^[0-9]+$ ]] || [[ "$param_value" -lt 1 ]]; then
                validation::add_error "Step '$step_name': Parameter '$param_name' must be a positive integer, got '$param_value'"
            fi
        fi
    done
    
    # Validate quality parameter if present
    local quality_param
    quality_param=$(yaml::get_step_param "$workflow_prefix" "$step_index" "QUALITY")
    if [[ -n "$quality_param" ]]; then
        if ! [[ "$quality_param" =~ ^[0-9]+$ ]] || [[ "$quality_param" -lt 1 ]] || [[ "$quality_param" -gt 100 ]]; then
            validation::add_error "Step '$step_name': Quality must be a number between 1 and 100, got '$quality_param'"
        fi
    fi
    
    # Check dependency
    if ! command -v convert >/dev/null 2>&1; then
        validation::add_error "Step '$step_name': Required dependency 'convert' (ImageMagick) not found"
    fi
}

# Validate watermark step
validation::validate_watermark_step() {
    local step_index="$1"
    local workflow_prefix="$2"
    local step_name="$3"
    
    # Check required parameters
    local watermark_param
    watermark_param=$(yaml::get_step_param "$workflow_prefix" "$step_index" "WATERMARK")
    if [[ -z "$watermark_param" ]]; then
        validation::add_error "Step '$step_name': Missing required parameter 'watermark'"
    fi
    
    # Validate position parameter if present
    local position_param
    position_param=$(yaml::get_step_param "$workflow_prefix" "$step_index" "POSITION")
    if [[ -n "$position_param" ]]; then
        case "$position_param" in
            "northwest"|"north"|"northeast"|"west"|"center"|"east"|"southwest"|"south"|"southeast")
                # Valid positions
                ;;
            *)
                validation::add_warning "Step '$step_name': Position '$position_param' may not be supported"
                ;;
        esac
    fi
    
    # Validate transparency parameter if present
    local transparency_param
    transparency_param=$(yaml::get_step_param "$workflow_prefix" "$step_index" "TRANSPARENCY")
    if [[ -n "$transparency_param" ]]; then
        if ! [[ "$transparency_param" =~ ^[0-9]+$ ]] || [[ "$transparency_param" -lt 0 ]] || [[ "$transparency_param" -gt 100 ]]; then
            validation::add_error "Step '$step_name': Transparency must be a number between 0 and 100, got '$transparency_param'"
        fi
    fi
    
    # Check dependency
    if ! command -v composite >/dev/null 2>&1; then
        validation::add_error "Step '$step_name': Required dependency 'composite' (ImageMagick) not found"
    fi
}

# Validate OCR step
validation::validate_ocr_step() {
    local step_index="$1"
    local workflow_prefix="$2"
    local step_name="$3"
    
    # Check required parameters
    local input_param
    input_param=$(yaml::get_step_param "$workflow_prefix" "$step_index" "INPUT")
    if [[ -z "$input_param" ]]; then
        validation::add_error "Step '$step_name': Missing required parameter 'input'"
    fi
    
    # Validate output format if present
    local output_format_param
    output_format_param=$(yaml::get_step_param "$workflow_prefix" "$step_index" "OUTPUT_FORMAT")
    if [[ -n "$output_format_param" ]]; then
        case "$output_format_param" in
            "txt"|"pdf"|"hocr"|"tsv")
                # Valid Tesseract output formats
                ;;
            *)
                validation::add_warning "Step '$step_name': Output format '$output_format_param' may not be supported by Tesseract"
                ;;
        esac
    fi
    
    # Validate language parameter if present
    local language_param
    language_param=$(yaml::get_step_param "$workflow_prefix" "$step_index" "LANGUAGE")
    if [[ -n "$language_param" ]]; then
        # Check if language data is available (basic check)
        if command -v tesseract >/dev/null 2>&1; then
            if ! tesseract --list-langs 2>/dev/null | grep -q "^$language_param$"; then
                validation::add_warning "Step '$step_name': Language '$language_param' may not be available in Tesseract"
            fi
        fi
    fi
    
    # Check dependency
    if ! command -v tesseract >/dev/null 2>&1; then
        validation::add_error "Step '$step_name': Required dependency 'tesseract' not found"
    fi
}

# Validate webhook step
validation::validate_webhook_step() {
    local step_index="$1"
    local workflow_prefix="$2"
    local step_name="$3"
    
    # Check required parameters
    local url_param
    url_param=$(yaml::get_step_param "$workflow_prefix" "$step_index" "URL")
    if [[ -z "$url_param" ]]; then
        validation::add_error "Step '$step_name': Missing required parameter 'url'"
    else
        # Basic URL validation
        if [[ ! "$url_param" =~ ^https?:// ]]; then
            validation::add_warning "Step '$step_name': URL should start with http:// or https://"
        fi
    fi
    
    # Validate method parameter if present
    local method_param
    method_param=$(yaml::get_step_param "$workflow_prefix" "$step_index" "METHOD")
    if [[ -n "$method_param" ]]; then
        case "$method_param" in
            "GET"|"POST"|"PUT"|"DELETE"|"PATCH")
                # Valid HTTP methods
                ;;
            *)
                validation::add_warning "Step '$step_name': HTTP method '$method_param' may not be supported"
                ;;
        esac
    fi
    
    # Check dependency
    if ! command -v curl >/dev/null 2>&1; then
        validation::add_warning "Step '$step_name': Optional dependency 'curl' not found, webhook will be skipped"
    fi
}

# Validate custom step
validation::validate_custom_step() {
    local step_index="$1"
    local workflow_prefix="$2"
    local step_name="$3"
    
    # Check required parameters
    local script_param
    script_param=$(yaml::get_step_param "$workflow_prefix" "$step_index" "SCRIPT")
    if [[ -z "$script_param" ]]; then
        validation::add_error "Step '$step_name': Missing required parameter 'script'"
    else
        # Basic script validation
        if [[ ${#script_param} -lt 10 ]]; then
            validation::add_warning "Step '$step_name': Script content seems very short, may be incomplete"
        fi
        
        # Check for potentially dangerous commands
        if [[ "$script_param" =~ rm[[:space:]]+-rf|sudo|su[[:space:]]|chmod[[:space:]]+777 ]]; then
            validation::add_warning "Step '$step_name': Script contains potentially dangerous commands"
        fi
    fi
}

# Validate template variables in parameters
validation::validate_template_variables() {
    local workflow_prefix="$1"
    local step_count
    step_count=$(yaml::get_workflow_var "$workflow_prefix" "STEP_COUNT")
    
    # Define valid template variables
    local valid_variables=(
        "workflow_input" "workflow_name" "output_dir" "temp_dir"
        "timestamp" "date" "time" "counter" "pdf_name" "excel_name"
        "original_name" "format" "width" "height" "quality"
        "extracted_count" "processed_count" "step_name" "failed_step"
    )
    
    # Check each step's parameters for template variables
    for ((i=0; i<step_count; i++)); do
        local step_name
        step_name=$(yaml::get_step_var "$workflow_prefix" "$i" "NAME")
        
        # Get all parameters for this step
        local param_vars
        param_vars=$(compgen -v "${workflow_prefix}_STEP_${i}_PARAM_" 2>/dev/null || true)
        
        while IFS= read -r var; do
            [[ -z "$var" ]] && continue
            local param_value="${!var}"
            
            # Find template variables in the parameter value
            while [[ "$param_value" =~ \{([^}]+)\} ]]; do
                local template_var="${BASH_REMATCH[1]}"
                local is_valid=false
                
                # Check if it's a valid template variable
                for valid_var in "${valid_variables[@]}"; do
                    if [[ "$template_var" == "$valid_var"* ]]; then
                        is_valid=true
                        break
                    fi
                done
                
                if [[ "$is_valid" == false ]]; then
                    validation::add_warning "Step '$step_name': Unknown template variable '{$template_var}'"
                fi
                
                # Remove this occurrence to continue searching
                param_value="${param_value/${BASH_REMATCH[0]}/}"
            done
        done <<< "$param_vars"
    done
}

# Validate workflow step dependencies
validation::validate_step_dependencies() {
    local workflow_prefix="$1"
    local step_count
    step_count=$(yaml::get_workflow_var "$workflow_prefix" "STEP_COUNT")
    
    # Note: Using arrays to track step dependencies
    # Due to compatibility, we'll use a simpler approach
    
    # Check for basic step ordering issues
    local has_extraction_step=false
    local processing_steps_found=false
    
    for ((i=0; i<step_count; i++)); do
        local step_name
        local step_type
        step_name=$(yaml::get_step_var "$workflow_prefix" "$i" "NAME")
        step_type=$(yaml::get_step_var "$workflow_prefix" "$i" "TYPE")
        
        case "$step_type" in
            "pdf_extract"|"excel_extract")
                has_extraction_step=true
                ;;
            "convert"|"resize"|"watermark")
                processing_steps_found=true
                # Check if we have extraction before processing
                if [[ "$has_extraction_step" == false && "$i" -gt 0 ]]; then
                    validation::add_warning "Step '$step_name': Image processing step found without prior extraction step"
                fi
                ;;
        esac
    done
}

# Comprehensive workflow validation
validation::validate_workflow_comprehensive() {
    local workflow_prefix="$1"
    
    # Clear previous results
    validation::clear_results
    
    # Basic workflow validation (from yaml.sh)
    if ! yaml::validate_workflow "$workflow_prefix" 2>/dev/null; then
        validation::add_error "Basic workflow structure validation failed"
        validation::report_results
        return 1
    fi
    
    # Get workflow info
    local step_count
    step_count=$(yaml::get_workflow_var "$workflow_prefix" "STEP_COUNT")
    
    # Validate each step
    for ((i=0; i<step_count; i++)); do
        local step_type
        step_type=$(yaml::get_step_var "$workflow_prefix" "$i" "TYPE")
        validation::validate_step_type "$step_type" "$i" "$workflow_prefix"
    done
    
    # Validate template variables
    validation::validate_template_variables "$workflow_prefix"
    
    # Validate step dependencies
    validation::validate_step_dependencies "$workflow_prefix"
    
    # Report results
    validation::report_results
    return $?
}

# Validate workflow file
validation::validate_workflow_file() {
    local workflow_file="$1"
    local prefix="${2:-VALIDATION_WF}"
    
    log::info "Validating workflow: $workflow_file"
    
    # Load workflow
    if ! yaml::load_workflow "$workflow_file" "$prefix"; then
        log::error "Failed to load workflow file"
        return 1
    fi
    
    # Validate workflow
    validation::validate_workflow_comprehensive "$prefix"
    return $?
}
