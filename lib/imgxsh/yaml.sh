#!/bin/bash
# imgxsh/yaml.sh - Simple YAML parser for imgxsh workflows

# Check if already sourced to prevent double-sourcing
[[ -n ${IMGXSH_YAML_LOADED:-} ]] && return 0
readonly IMGXSH_YAML_LOADED=1

# Source Shell Starter dependencies
source "${SHELL_STARTER_ROOT}/lib/colors.sh"
source "${SHELL_STARTER_ROOT}/lib/logging.sh"

# Safe assign helper (supports newlines/quotes)
yaml::_assign_var() {
  local var_name="$1"
  local var_value="$2"
  # Escape single quotes for safe single-quoted assignment
  local escaped
  escaped=${var_value//\'/\'"'"\'}
  eval "$var_name='$escaped'"
}

# Simple YAML parser for imgxsh workflow files
# This is a basic parser that handles the specific structure we need
# for imgxsh workflows, not a complete YAML implementation

# Parse a YAML workflow file
yaml::parse_workflow() {
  local yaml_file="$1"
  local output_prefix="${2:-WORKFLOW}"

  if [[ ! -f $yaml_file ]]; then
    log::error "YAML file does not exist: $yaml_file"
    return 1
  fi

  if [[ ! -r $yaml_file ]]; then
    log::error "Cannot read YAML file: $yaml_file"
    return 1
  fi

  if ! command -v yq >/dev/null 2>&1; then
    log::error "Required dependency missing: yq"
    return 1
  fi

  # Clear existing variables for this prefix
  unset "${output_prefix}_NAME" "${output_prefix}_DESCRIPTION" "${output_prefix}_VERSION"
  unset "${output_prefix}_STEPS" "${output_prefix}_SETTINGS" "${output_prefix}_HOOKS"
  # Track source file for fallback lookups
  yaml::_assign_var "${output_prefix}_SOURCE_FILE" "$yaml_file"

  # Basic metadata
  local wf_name wf_desc wf_version
  wf_name=$(yq -r '.name // ""' "$yaml_file")
  wf_desc=$(yq -r '.description // ""' "$yaml_file")
  wf_version=$(yq -r '.version // ""' "$yaml_file")
  yaml::_assign_var "${output_prefix}_NAME" "$wf_name"
  yaml::_assign_var "${output_prefix}_DESCRIPTION" "$wf_desc"
  yaml::_assign_var "${output_prefix}_VERSION" "$wf_version"

  # Settings
  local settings_keys
  settings_keys=$(yq -r '.settings | keys | .[]? // empty' "$yaml_file" 2>/dev/null || true)
  if [[ -n $settings_keys ]]; then
    while IFS= read -r key; do
      [[ -z $key ]] && continue
      local value upper_key
      value=$(yq -r ".settings.$key // \"\"" "$yaml_file")
      upper_key=$(echo "$key" | tr '[:lower:]' '[:upper:]')
      yaml::_assign_var "${output_prefix}_SETTING_${upper_key}" "$value"
    done <<<"$settings_keys"
  fi

  # Steps
  local step_count i
  step_count=$(yq -r '.steps | length // 0' "$yaml_file")
  i=0
  while [[ $i -lt $step_count ]]; do
    local step_name step_type step_desc step_cond
    step_name=$(yq -r ".steps[$i].name // \"\"" "$yaml_file")
    step_type=$(yq -r ".steps[$i].type // \"\"" "$yaml_file")
    step_desc=$(yq -r ".steps[$i].description // \"\"" "$yaml_file")
    step_cond=$(yq -r ".steps[$i].condition // \"\"" "$yaml_file")

    yaml::_assign_var "${output_prefix}_STEP_${i}_NAME" "$step_name"
    yaml::_assign_var "${output_prefix}_STEP_${i}_TYPE" "$step_type"
    yaml::_assign_var "${output_prefix}_STEP_${i}_DESCRIPTION" "$step_desc"
    yaml::_assign_var "${output_prefix}_STEP_${i}_CONDITION" "$step_cond"

    local -a param_keys_arr=()
    # Collect keys safely into an array (portable)
    while IFS= read -r pkey; do
      param_keys_arr+=("$pkey")
    done < <(yq -r ".steps[$i].params | keys | .[]? // empty" "$yaml_file" 2>/dev/null || true)
    if [[ ${#param_keys_arr[@]} -gt 0 ]]; then
      for pkey in "${param_keys_arr[@]}"; do
        [[ -z $pkey ]] && continue
        local pval upper_pkey
        pval=$(yq -r ".steps[$i].params.$pkey // \"\"" "$yaml_file")
        upper_pkey=$(echo "$pkey" | tr '[:lower:]' '[:upper:]')
        yaml::_assign_var "${output_prefix}_STEP_${i}_PARAM_${upper_pkey}" "$pval"
      done
    fi

    ((i++))
  done

  eval "${output_prefix}_STEP_COUNT=\$step_count"

  # Hooks
  local hook_names=(pre_workflow post_step on_success on_failure)
  for hook in "${hook_names[@]}"; do
    local hook_lines joined upper
    hook_lines=$(yq -r ".hooks.${hook}[]?" "$yaml_file" 2>/dev/null || true)
    if [[ -n $hook_lines ]]; then
      joined=$(echo "$hook_lines" | tr '\n' '|' | sed 's/|$//')
      upper=$(echo "$hook" | tr '[:lower:]' '[:upper:]')
      yaml::_assign_var "${output_prefix}_HOOK_${upper}" "$joined"
    fi
  done

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
  if [[ -n ${!full_var:-} ]]; then
    echo "${!full_var}"
    return 0
  fi

  # Fallback: if parsing didn't materialize param variables, read from source YAML via yq
  local source_file_var="${prefix}_SOURCE_FILE"
  local source_file="${!source_file_var:-}"
  if [[ -n $source_file ]] && command -v yq >/dev/null 2>&1; then
    local lower_param
    lower_param=$(echo "$param_name" | tr '[:upper:]' '[:lower:]')
    yq -r ".steps[$step_index].params.$lower_param // \"\"" "$source_file"
    return 0
  fi

  echo ""
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

  for ((i = 0; i < step_count; i++)); do
    echo "  Step $i:"
    echo "    Name: $(yaml::get_step_var "$prefix" "$i" "NAME")"
    echo "    Type: $(yaml::get_step_var "$prefix" "$i" "TYPE")"
    echo "    Description: $(yaml::get_step_var "$prefix" "$i" "DESCRIPTION")"
    echo "    Condition: $(yaml::get_step_var "$prefix" "$i" "CONDITION")"

    # List all parameters for this step
    local param_vars
    param_vars=$(compgen -v "${prefix}_STEP_${i}_PARAM_" 2>/dev/null || true)
    if [[ -n $param_vars ]]; then
      echo "    Parameters:"
      while IFS= read -r var; do
        local param_name="${var#"${prefix}"_STEP_"${i}"_PARAM_}"
        local param_value="${!var}"
        echo "      ${param_name,,}: $param_value"
      done <<<"$param_vars"
    fi
  done

  # Settings
  echo "Settings:"
  local setting_vars
  setting_vars=$(compgen -v "${prefix}_SETTING_" 2>/dev/null || true)
  if [[ -n $setting_vars ]]; then
    while IFS= read -r var; do
      local setting_name="${var#"${prefix}"_SETTING_}"
      local setting_value="${!var}"
      echo "  ${setting_name,,}: $setting_value"
    done <<<"$setting_vars"
  fi

  # Hooks
  echo "Hooks:"
  local hook_vars
  hook_vars=$(compgen -v "${prefix}_HOOK_" 2>/dev/null || true)
  if [[ -n $hook_vars ]]; then
    while IFS= read -r var; do
      local hook_name="${var#"${prefix}"_HOOK_}"
      local hook_commands="${!var}"
      echo "  ${hook_name,,}: $hook_commands"
    done <<<"$hook_vars"
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
  if [[ -z $step_count || $step_count -eq 0 ]]; then
    errors+=("No steps defined in workflow")
  fi

  # Validate each step
  for ((i = 0; i < step_count; i++)); do
    local step_name
    step_name=$(yaml::get_step_var "$prefix" "$i" "NAME")
    if [[ -z $step_name ]]; then
      errors+=("Step $i: missing name")
    fi

    local step_type
    step_type=$(yaml::get_step_var "$prefix" "$i" "TYPE")
    if [[ -z $step_type ]]; then
      errors+=("Step $i ($step_name): missing type")
    fi

    # Validate step type
    case "$step_type" in
      "pdf_extract" | "excel_extract" | "convert" | "resize" | "watermark" | "ocr" | "webhook" | "custom")
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

# Evaluate a condition string with variables
yaml::evaluate_condition() {
  local condition="$1"
  local context_prefix="${2:-WORKFLOW_CONTEXT}"

  if [[ -z $condition ]]; then
    # No condition means always execute
    return 0
  fi

  log::debug "Evaluating condition: $condition"

  # Simple condition evaluator for common patterns
  # This supports basic comparisons: variable > number, variable < number, variable == value

  # Replace known variables with their values
  local evaluated_condition="$condition"

  # Get all context variables (variables that start with the context prefix)
  local context_vars
  context_vars=$(compgen -v "${context_prefix}_" 2>/dev/null || true)

  if [[ -n $context_vars ]]; then
    while IFS= read -r var; do
      local var_name="${var#"${context_prefix}"_}"
      local var_value="${!var}"
      local var_name_lower=$(echo "$var_name" | tr '[:upper:]' '[:lower:]')

      # Replace variable references in the condition
      evaluated_condition="${evaluated_condition//$var_name_lower/$var_value}"
    done <<<"$context_vars"
  fi

  log::debug "After variable substitution: $evaluated_condition"

  # Handle common comparison patterns
  if [[ $evaluated_condition =~ ^([0-9]+)[[:space:]]*([><=]+)[[:space:]]*([0-9]+)$ ]]; then
    local left="${BASH_REMATCH[1]}"
    local operator="${BASH_REMATCH[2]}"
    local right="${BASH_REMATCH[3]}"

    case "$operator" in
      ">")
        [[ $left -gt $right ]]
        return $?
        ;;
      ">=")
        [[ $left -ge $right ]]
        return $?
        ;;
      "<")
        [[ $left -lt $right ]]
        return $?
        ;;
      "<=")
        [[ $left -le $right ]]
        return $?
        ;;
      "==" | "=")
        [[ $left -eq $right ]]
        return $?
        ;;
      "!=")
        [[ $left -ne $right ]]
        return $?
        ;;
      *)
        log::warn "Unknown comparison operator: $operator"
        return 1
        ;;
    esac
  fi

  # Handle string comparisons
  if [[ $evaluated_condition =~ ^\"?([^\"]+)\"?[[:space:]]*([><=!]+)[[:space:]]*\"?([^\"]+)\"?$ ]]; then
    local left="${BASH_REMATCH[1]}"
    local operator="${BASH_REMATCH[2]}"
    local right="${BASH_REMATCH[3]}"

    case "$operator" in
      "==" | "=")
        [[ $left == "$right" ]]
        return $?
        ;;
      "!=")
        [[ $left != "$right" ]]
        return $?
        ;;
      *)
        log::warn "String comparison operator '$operator' not supported for strings"
        return 1
        ;;
    esac
  fi

  # Handle boolean conditions (true/false, yes/no, 1/0)
  local evaluated_condition_lower
  evaluated_condition_lower=$(echo "$evaluated_condition" | tr '[:upper:]' '[:lower:]')
  case "$evaluated_condition_lower" in
    "true" | "yes" | "1" | "on" | "enabled")
      return 0
      ;;
    "false" | "no" | "0" | "off" | "disabled")
      return 1
      ;;
  esac

  # If we can't parse the condition, log a warning but default to true
  log::warn "Could not evaluate condition: $condition"
  log::warn "Condition will be treated as true (step will execute)"
  return 0
}

# Set a context variable for condition evaluation
yaml::set_context_var() {
  local context_prefix="${1:-WORKFLOW_CONTEXT}"
  local var_name="$2"
  local var_value="$3"

  local upper_var_name=$(echo "$var_name" | tr '[:lower:]' '[:upper:]')
  local full_var="${context_prefix}_${upper_var_name}"

  eval "${full_var}=\$var_value"
  log::debug "Set context variable: ${full_var}=${var_value}"
}

# Get a context variable value
yaml::get_context_var() {
  local context_prefix="${1:-WORKFLOW_CONTEXT}"
  local var_name="$2"

  local upper_var_name=$(echo "$var_name" | tr '[:lower:]' '[:upper:]')
  local full_var="${context_prefix}_${upper_var_name}"

  echo "${!full_var:-}"
}

# Initialize context variables with common defaults
yaml::init_context() {
  local context_prefix="${1:-WORKFLOW_CONTEXT}"

  # Clear any existing context variables
  local context_vars
  context_vars=$(compgen -v "${context_prefix}_" 2>/dev/null || true)
  if [[ -n $context_vars ]]; then
    while IFS= read -r var; do
      unset "$var"
    done <<<"$context_vars"
  fi

  # Set default context variables
  yaml::set_context_var "$context_prefix" "extracted_count" "0"
  yaml::set_context_var "$context_prefix" "processed_count" "0"
  yaml::set_context_var "$context_prefix" "error_count" "0"
  yaml::set_context_var "$context_prefix" "current_step" "0"
  yaml::set_context_var "$context_prefix" "total_steps" "0"

  log::debug "Initialized context variables with defaults"
}

# Debug function to show all context variables
yaml::debug_context() {
  local context_prefix="${1:-WORKFLOW_CONTEXT}"

  echo "=== Context Variables (${context_prefix}) ==="

  local context_vars
  context_vars=$(compgen -v "${context_prefix}_" 2>/dev/null || true)
  if [[ -n $context_vars ]]; then
    while IFS= read -r var; do
      local var_name="${var#"${context_prefix}"_}"
      local var_value="${!var}"
      echo "  ${var_name,,}: $var_value"
    done <<<"$context_vars"
  else
    echo "  No context variables set"
  fi
}

# Template variable substitution system
yaml::substitute_variables() {
  local text="$1"
  local context_prefix="${2:-TEMPLATE_VARS}"

  if [[ -z $text ]]; then
    echo ""
    return 0
  fi

  local result="$text"

  # Get all template variables (variables that start with the context prefix)
  local template_vars
  template_vars=$(compgen -v "${context_prefix}_" 2>/dev/null || true)

  if [[ -n $template_vars ]]; then
    while IFS= read -r var; do
      [[ -z $var ]] && continue
      local var_name="${var#"${context_prefix}"_}"
      local var_value="${!var}"
      local var_name_lower=$(echo "$var_name" | tr '[:upper:]' '[:lower:]')

      # Replace {variable_name} with value
      result="${result//\{$var_name_lower\}/$var_value}"
    done <<<"$template_vars"
  fi

  # Handle special formatting patterns like {counter:03d}
  # Extract counter variables and apply formatting
  while [[ $result =~ \{([^}:]+):([^}]+)\} ]]; do
    local full_match="${BASH_REMATCH[0]}"
    local var_name="${BASH_REMATCH[1]}"
    local format="${BASH_REMATCH[2]}"

    # Get the variable value
    local upper_var_name=$(echo "$var_name" | tr '[:lower:]' '[:upper:]')
    local full_var="${context_prefix}_${upper_var_name}"
    local var_value="${!full_var:-0}"

    # Apply formatting
    local formatted_value
    case "$format" in
      *d)
        # Numeric formatting (e.g., 03d for zero-padded 3 digits)
        formatted_value=$(printf "%${format}" "$var_value")
        ;;
      *)
        # Unknown format, use value as-is
        formatted_value="$var_value"
        log::warn "Unknown variable format: $format, using value as-is"
        ;;
    esac

    # Replace the pattern
    result="${result//$full_match/$formatted_value}"
  done

  echo "$result"
}

# Set a template variable
yaml::set_template_var() {
  local context_prefix="${1:-TEMPLATE_VARS}"
  local var_name="$2"
  local var_value="$3"

  local upper_var_name=$(echo "$var_name" | tr '[:lower:]' '[:upper:]')
  local full_var="${context_prefix}_${upper_var_name}"

  eval "${full_var}=\$var_value"
  log::debug "Set template variable: ${full_var}=${var_value}"
}

# Get a template variable value
yaml::get_template_var() {
  local context_prefix="${1:-TEMPLATE_VARS}"
  local var_name="$2"

  local upper_var_name=$(echo "$var_name" | tr '[:lower:]' '[:upper:]')
  local full_var="${context_prefix}_${upper_var_name}"

  echo "${!full_var:-}"
}

# Initialize template variables with common defaults
yaml::init_template_vars() {
  local context_prefix="${1:-TEMPLATE_VARS}"
  local workflow_input="$2"
  local output_dir="$3"

  # Clear any existing template variables
  local template_vars
  template_vars=$(compgen -v "${context_prefix}_" 2>/dev/null || true)
  if [[ -n $template_vars ]]; then
    while IFS= read -r var; do
      [[ -z $var ]] && continue
      unset "$var"
    done <<<"$template_vars"
  fi

  # Set basic template variables
  yaml::set_template_var "$context_prefix" "workflow_input" "$workflow_input"
  yaml::set_template_var "$context_prefix" "output_dir" "$output_dir"
  yaml::set_template_var "$context_prefix" "temp_dir" "/tmp/imgxsh"

  # Generate timestamp
  local timestamp
  timestamp=$(date +%Y%m%d_%H%M%S)
  yaml::set_template_var "$context_prefix" "timestamp" "$timestamp"

  # Initialize counter
  yaml::set_template_var "$context_prefix" "counter" "1"

  # Extract file-specific variables from workflow_input if it's a file
  if [[ -f $workflow_input ]]; then
    local base_name
    base_name=$(basename "$workflow_input")
    local name_without_ext="${base_name%.*}"
    local file_ext="${base_name##*.}"

    yaml::set_template_var "$context_prefix" "input_basename" "$base_name"
    yaml::set_template_var "$context_prefix" "input_name" "$name_without_ext"
    yaml::set_template_var "$context_prefix" "input_ext" "$file_ext"

    # Set format-specific names (convert to lowercase for comparison)
    local file_ext_lower
    file_ext_lower=$(echo "$file_ext" | tr '[:upper:]' '[:lower:]')
    case "$file_ext_lower" in
      "pdf")
        yaml::set_template_var "$context_prefix" "pdf_name" "$name_without_ext"
        ;;
      "xlsx" | "xls")
        yaml::set_template_var "$context_prefix" "excel_name" "$name_without_ext"
        ;;
    esac
  fi

  log::debug "Initialized template variables for: $workflow_input"
}

# Increment a numeric template variable (useful for counters)
yaml::increment_template_var() {
  local context_prefix="${1:-TEMPLATE_VARS}"
  local var_name="$2"
  local increment="${3:-1}"

  local current_value
  current_value=$(yaml::get_template_var "$context_prefix" "$var_name")
  local new_value=$((current_value + increment))

  yaml::set_template_var "$context_prefix" "$var_name" "$new_value"
  echo "$new_value"
}

# Debug function to show all template variables
yaml::debug_template_vars() {
  local context_prefix="${1:-TEMPLATE_VARS}"

  echo "=== Template Variables (${context_prefix}) ==="

  local template_vars
  template_vars=$(compgen -v "${context_prefix}_" 2>/dev/null || true)
  if [[ -n $template_vars ]]; then
    while IFS= read -r var; do
      [[ -z $var ]] && continue
      local var_name="${var#"${context_prefix}"_}"
      local var_value="${!var}"
      local var_name_lower
      var_name_lower=$(echo "$var_name" | tr '[:upper:]' '[:lower:]')
      echo "  {${var_name_lower}}: $var_value"
    done <<<"$template_vars"
  else
    echo "  No template variables set"
  fi
}

# Apply template substitution to a workflow step's parameters
yaml::substitute_step_params() {
  local workflow_prefix="$1"
  local step_index="$2"
  local template_context="${3:-TEMPLATE_VARS}"

  # Get all parameters for this step
  local param_vars
  param_vars=$(compgen -v "${workflow_prefix}_STEP_${step_index}_PARAM_" 2>/dev/null || true)

  if [[ -n $param_vars ]]; then
    while IFS= read -r var; do
      [[ -z $var ]] && continue
      local original_value="${!var}"
      local substituted_value
      substituted_value=$(yaml::substitute_variables "$original_value" "$template_context")

      # Update the parameter with substituted value
      eval "$var=\"\$substituted_value\""

      if [[ $original_value != "$substituted_value" ]]; then
        log::debug "Template substitution: $original_value -> $substituted_value"
      fi
    done <<<"$param_vars"
  fi
}

# Apply template substitution to hook commands
yaml::substitute_hook_commands() {
  local workflow_prefix="$1"
  local hook_name="$2"
  local template_context="${3:-TEMPLATE_VARS}"

  local hook_commands
  hook_commands=$(yaml::get_hook "$workflow_prefix" "$hook_name")

  if [[ -n $hook_commands ]]; then
    local substituted_commands
    substituted_commands=$(yaml::substitute_variables "$hook_commands" "$template_context")

    # Update the hook variable
    local upper_hook=$(echo "$hook_name" | tr '[:lower:]' '[:upper:]')
    local hook_var="${workflow_prefix}_HOOK_${upper_hook}"
    eval "$hook_var=\"\$substituted_commands\""

    if [[ $hook_commands != "$substituted_commands" ]]; then
      log::debug "Hook template substitution: $hook_commands -> $substituted_commands"
    fi
  fi
}

# Load workflow from file or built-in workflow
yaml::load_workflow() {
  local workflow_name="$1"
  local prefix="${2:-WORKFLOW}"

  # Check if it's a file path
  if [[ -f $workflow_name ]]; then
    log::debug "Loading workflow from file: $workflow_name"
    yaml::parse_workflow "$workflow_name" "$prefix"
    return $?
  fi

  # Check for built-in workflows in config directory
  local builtin_file="${SHELL_STARTER_ROOT}/config/workflows/${workflow_name}.yaml"
  if [[ -f $builtin_file ]]; then
    log::debug "Loading built-in workflow: $workflow_name"
    yaml::parse_workflow "$builtin_file" "$prefix"
    return $?
  fi

  # Check user workflows directory
  local user_file="${IMGXSH_CONFIG_DIR}/workflows/${workflow_name}.yaml"
  if [[ -f $user_file ]]; then
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
