#!/bin/bash
# imgxsh/yaml.sh - Simple YAML parser for imgxsh workflows

# Check if already sourced to prevent double-sourcing
[[ -n "${IMGXSH_YAML_LOADED:-}" ]] && return 0
readonly IMGXSH_YAML_LOADED=1

# Source Shell Starter dependencies
source "${SHELL_STARTER_ROOT}/lib/colors.sh"
source "${SHELL_STARTER_ROOT}/lib/logging.sh"

# Simple YAML parser for imgxsh workflow files
# This is a basic parser that handles the specific structure we need
# for imgxsh workflows, not a complete YAML implementation

# Parse a YAML workflow file
yaml::parse_workflow() {
    local yaml_file="$1"
    local output_prefix="${2:-WORKFLOW}"
    
    if [[ ! -f "$yaml_file" ]]; then
        log::error "YAML file does not exist: $yaml_file"
        return 1
    fi
    
    if [[ ! -r "$yaml_file" ]]; then
        log::error "Cannot read YAML file: $yaml_file"
        return 1
    fi
    
    # Initialize workflow variables
    unset "${output_prefix}_NAME"
    unset "${output_prefix}_DESCRIPTION"
    unset "${output_prefix}_VERSION"
    unset "${output_prefix}_STEPS"
    unset "${output_prefix}_SETTINGS"
    unset "${output_prefix}_HOOKS"
    
    local current_section=""
    local step_index=0
    local in_steps=false
    local in_settings=false
    local in_hooks=false
    local current_step=""
    local current_hook=""
    local indent_level=0
    
    while IFS= read -r line; do
        # Skip empty lines and comments
        [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
        
        # Remove trailing comments
        line=$(echo "$line" | sed 's/[[:space:]]*#.*$//')
        [[ -z "$line" ]] && continue
        
        # Calculate indentation level
        local leading_spaces="${line%%[! ]*}"
        local current_indent=${#leading_spaces}
        
        # Remove leading whitespace
        line="${line#"${leading_spaces}"}"
        
        # Parse top-level keys
        if [[ $current_indent -eq 0 ]]; then
            in_steps=false
            in_settings=false
            in_hooks=false
            current_section=""
            
            case "$line" in
                "name:"*)
                    local name="${line#name:}"
                    name="${name#"${name%%[![:space:]]*}"}"  # trim leading space
                    name="${name%"${name##*[![:space:]]}"}"  # trim trailing space
                    eval "${output_prefix}_NAME=\$name"
                    ;;
                "description:"*)
                    local desc="${line#description:}"
                    desc="${desc#"${desc%%[![:space:]]*}"}"  # trim leading space
                    desc="${desc%"${desc##*[![:space:]]}"}"  # trim trailing space
                    # Remove quotes if present
                    desc="${desc#\"}"
                    desc="${desc%\"}"
                    eval "${output_prefix}_DESCRIPTION=\$desc"
                    ;;
                "version:"*)
                    local ver="${line#version:}"
                    ver="${ver#"${ver%%[![:space:]]*}"}"  # trim leading space
                    ver="${ver%"${ver##*[![:space:]]}"}"  # trim trailing space
                    # Remove quotes if present
                    ver="${ver#\"}"
                    ver="${ver%\"}"
                    eval "${output_prefix}_VERSION=\$ver"
                    ;;
                "steps:")
                    in_steps=true
                    step_index=0
                    current_section="steps"
                    ;;
                "settings:")
                    in_settings=true
                    current_section="settings"
                    ;;
                "hooks:")
                    in_hooks=true
                    current_section="hooks"
                    ;;
            esac
        elif [[ $in_steps == true && $current_indent -eq 2 ]]; then
            # Parse step entries
            if [[ "$line" == "- name:"* ]]; then
                local step_name="${line#- name:}"
                step_name="${step_name#"${step_name%%[![:space:]]*}"}"  # trim leading space
                step_name="${step_name%"${step_name##*[![:space:]]}"}"  # trim trailing space
                current_step="STEP_${step_index}"
                eval "${output_prefix}_${current_step}_NAME=\$step_name"
                ((step_index++))
            fi
        elif [[ $in_steps == true && $current_indent -eq 4 && -n "$current_step" ]]; then
            # Parse step properties
            case "$line" in
                "type:"*)
                    local type="${line#type:}"
                    type="${type#"${type%%[![:space:]]*}"}"  # trim leading space
                    type="${type%"${type##*[![:space:]]}"}"  # trim trailing space
                    eval "${output_prefix}_${current_step}_TYPE=\$type"
                    ;;
                "description:"*)
                    local desc="${line#description:}"
                    desc="${desc#"${desc%%[![:space:]]*}"}"  # trim leading space
                    desc="${desc%"${desc##*[![:space:]]}"}"  # trim trailing space
                    # Remove quotes if present
                    desc="${desc#\"}"
                    desc="${desc%\"}"
                    eval "${output_prefix}_${current_step}_DESCRIPTION=\$desc"
                    ;;
                "condition:"*)
                    local cond="${line#condition:}"
                    cond="${cond#"${cond%%[![:space:]]*}"}"  # trim leading space
                    cond="${cond%"${cond##*[![:space:]]}"}"  # trim trailing space
                    # Remove quotes if present
                    cond="${cond#\"}"
                    cond="${cond%\"}"
                    eval "${output_prefix}_${current_step}_CONDITION=\$cond"
                    ;;
                "params:")
                    # Parameters will be parsed in the next indentation level
                    ;;
            esac
        elif [[ $in_steps == true && $current_indent -eq 6 && -n "$current_step" ]]; then
            # Parse step parameters
            if [[ "$line" == *":"* ]]; then
                local key="${line%%:*}"
                local value="${line#*:}"
                value="${value#"${value%%[![:space:]]*}"}"  # trim leading space
                value="${value%"${value##*[![:space:]]}"}"  # trim trailing space
                # Remove quotes if present
                value="${value#\"}"
                value="${value%\"}"
                local upper_key=$(echo "$key" | tr '[:lower:]' '[:upper:]')
                eval "${output_prefix}_${current_step}_PARAM_${upper_key}=\$value"
            fi
        elif [[ $in_settings == true && $current_indent -eq 2 ]]; then
            # Parse settings
            if [[ "$line" == *":"* ]]; then
                local key="${line%%:*}"
                local value="${line#*:}"
                value="${value#"${value%%[![:space:]]*}"}"  # trim leading space
                value="${value%"${value##*[![:space:]]}"}"  # trim trailing space
                # Remove quotes if present
                value="${value#\"}"
                value="${value%\"}"
                local upper_key=$(echo "$key" | tr '[:lower:]' '[:upper:]')
                eval "${output_prefix}_SETTING_${upper_key}=\$value"
            fi
        elif [[ $in_hooks == true && $current_indent -eq 2 ]]; then
            # Parse hooks
            case "$line" in
                *":")
                    current_hook="${line%:}"
                    ;;
            esac
        elif [[ $in_hooks == true && $current_indent -eq 4 && -n "$current_hook" ]]; then
            # Parse hook commands
            if [[ "$line" == "- "* ]]; then
                local command="${line#- }"
                # Remove quotes if present
                command="${command#\"}"
                command="${command%\"}"
                # Append to hook variable (multiple commands possible)
                local upper_hook=$(echo "$current_hook" | tr '[:lower:]' '[:upper:]')
                local hook_var="${output_prefix}_HOOK_${upper_hook}"
                if [[ -n "${!hook_var:-}" ]]; then
                    eval "$hook_var=\"\${!hook_var}|\$command\""
                else
                    eval "$hook_var=\"\$command\""
                fi
            fi
        fi
    done < "$yaml_file"
    
    # Set step count
    eval "${output_prefix}_STEP_COUNT=\$step_index"
    
    return 0
}

# Get a workflow variable value
yaml::get_workflow_var() {
    local prefix="$1"
    local var_name="$2"
    local full_var="${prefix}_${var_name}"
    echo "${!full_var:-}"
}

# Get a step variable value
yaml::get_step_var() {
    local prefix="$1"
    local step_index="$2"
    local var_name="$3"
    local full_var="${prefix}_STEP_${step_index}_${var_name}"
    echo "${!full_var:-}"
}

# Get a step parameter value
yaml::get_step_param() {
    local prefix="$1"
    local step_index="$2"
    local param_name="$3"
    local upper_param=$(echo "$param_name" | tr '[:lower:]' '[:upper:]')
    local full_var="${prefix}_STEP_${step_index}_PARAM_${upper_param}"
    echo "${!full_var:-}"
}

# Get a setting value
yaml::get_setting() {
    local prefix="$1"
    local setting_name="$2"
    local upper_setting=$(echo "$setting_name" | tr '[:lower:]' '[:upper:]')
    local full_var="${prefix}_SETTING_${upper_setting}"
    echo "${!full_var:-}"
}

# Get hook commands (returns commands separated by |)
yaml::get_hook() {
    local prefix="$1"
    local hook_name="$2"
    local upper_hook=$(echo "$hook_name" | tr '[:lower:]' '[:upper:]')
    local full_var="${prefix}_HOOK_${upper_hook}"
    echo "${!full_var:-}"
}

# List all workflow variables (for debugging)
yaml::debug_workflow() {
    local prefix="$1"
    
    echo "=== Workflow Variables (${prefix}) ==="
    
    # Basic info
    echo "Name: $(yaml::get_workflow_var "$prefix" "NAME")"
    echo "Description: $(yaml::get_workflow_var "$prefix" "DESCRIPTION")"
    echo "Version: $(yaml::get_workflow_var "$prefix" "VERSION")"
    
    # Steps
    local step_count
    step_count=$(yaml::get_workflow_var "$prefix" "STEP_COUNT")
    echo "Steps: $step_count"
    
    for ((i=0; i<step_count; i++)); do
        echo "  Step $i:"
        echo "    Name: $(yaml::get_step_var "$prefix" "$i" "NAME")"
        echo "    Type: $(yaml::get_step_var "$prefix" "$i" "TYPE")"
        echo "    Description: $(yaml::get_step_var "$prefix" "$i" "DESCRIPTION")"
        echo "    Condition: $(yaml::get_step_var "$prefix" "$i" "CONDITION")"
        
        # List all parameters for this step
        local param_vars
        param_vars=$(compgen -v "${prefix}_STEP_${i}_PARAM_" 2>/dev/null || true)
        if [[ -n "$param_vars" ]]; then
            echo "    Parameters:"
            while IFS= read -r var; do
                local param_name="${var#"${prefix}"_STEP_"${i}"_PARAM_}"
                local param_value="${!var}"
                echo "      ${param_name,,}: $param_value"
            done <<< "$param_vars"
        fi
    done
    
    # Settings
    echo "Settings:"
    local setting_vars
    setting_vars=$(compgen -v "${prefix}_SETTING_" 2>/dev/null || true)
    if [[ -n "$setting_vars" ]]; then
        while IFS= read -r var; do
            local setting_name="${var#"${prefix}"_SETTING_}"
            local setting_value="${!var}"
            echo "  ${setting_name,,}: $setting_value"
        done <<< "$setting_vars"
    fi
    
    # Hooks
    echo "Hooks:"
    local hook_vars
    hook_vars=$(compgen -v "${prefix}_HOOK_" 2>/dev/null || true)
    if [[ -n "$hook_vars" ]]; then
        while IFS= read -r var; do
            local hook_name="${var#"${prefix}"_HOOK_}"
            local hook_commands="${!var}"
            echo "  ${hook_name,,}: $hook_commands"
        done <<< "$hook_vars"
    fi
}

# Validate that required workflow fields are present
yaml::validate_workflow() {
    local prefix="$1"
    local errors=()
    
    # Check required fields
    if [[ -z "$(yaml::get_workflow_var "$prefix" "NAME")" ]]; then
        errors+=("Missing required field: name")
    fi
    
    if [[ -z "$(yaml::get_workflow_var "$prefix" "DESCRIPTION")" ]]; then
        errors+=("Missing required field: description")
    fi
    
    local step_count
    step_count=$(yaml::get_workflow_var "$prefix" "STEP_COUNT")
    if [[ -z "$step_count" || "$step_count" -eq 0 ]]; then
        errors+=("No steps defined in workflow")
    fi
    
    # Validate each step
    for ((i=0; i<step_count; i++)); do
        local step_name
        step_name=$(yaml::get_step_var "$prefix" "$i" "NAME")
        if [[ -z "$step_name" ]]; then
            errors+=("Step $i: missing name")
        fi
        
        local step_type
        step_type=$(yaml::get_step_var "$prefix" "$i" "TYPE")
        if [[ -z "$step_type" ]]; then
            errors+=("Step $i ($step_name): missing type")
        fi
        
        # Validate step type
        case "$step_type" in
            "pdf_extract"|"excel_extract"|"convert"|"resize"|"watermark"|"ocr"|"webhook"|"custom")
                # Valid step types
                ;;
            *)
                errors+=("Step $i ($step_name): unknown step type '$step_type'")
                ;;
        esac
    done
    
    # Report errors
    if [[ ${#errors[@]} -gt 0 ]]; then
        log::error "Workflow validation failed:"
        for error in "${errors[@]}"; do
            log::error "  - $error"
        done
        return 1
    fi
    
    return 0
}

# Load workflow from file or built-in workflow
yaml::load_workflow() {
    local workflow_name="$1"
    local prefix="${2:-WORKFLOW}"
    
    # Check if it's a file path
    if [[ -f "$workflow_name" ]]; then
        log::debug "Loading workflow from file: $workflow_name"
        yaml::parse_workflow "$workflow_name" "$prefix"
        return $?
    fi
    
    # Check for built-in workflows in config directory
    local builtin_file="${SHELL_STARTER_ROOT}/config/workflows/${workflow_name}.yaml"
    if [[ -f "$builtin_file" ]]; then
        log::debug "Loading built-in workflow: $workflow_name"
        yaml::parse_workflow "$builtin_file" "$prefix"
        return $?
    fi
    
    # Check user workflows directory
    local user_file="${IMGXSH_CONFIG_DIR}/workflows/${workflow_name}.yaml"
    if [[ -f "$user_file" ]]; then
        log::debug "Loading user workflow: $workflow_name"
        yaml::parse_workflow "$user_file" "$prefix"
        return $?
    fi
    
    log::error "Workflow not found: $workflow_name"
    log::info "Searched locations:"
    log::info "  - File path: $workflow_name"
    log::info "  - Built-in: $builtin_file"
    log::info "  - User: $user_file"
    return 1
}
