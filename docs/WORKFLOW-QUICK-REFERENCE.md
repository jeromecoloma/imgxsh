# Workflow Quick Reference

A quick reference guide for imgxsh workflow configuration, step types, and common patterns.

## Quick Commands

```bash
# List available workflows
imgxsh --list-workflows

# List available presets
imgxsh --list-presets

# Run workflow
imgxsh --workflow pdf-to-web document.pdf

# Use preset
imgxsh --preset quick-thumbnails document.pdf

# Preview without execution
imgxsh --workflow pdf-to-web --dry-run document.pdf

# Get workflow info
imgxsh --workflow-info pdf-to-web
```

## Workflow Structure

```yaml
name: workflow-name
description: "Description"
version: "1.0"

settings:
  output_dir: "./output"
  parallel_jobs: 4

steps:
  - name: step_name
    type: step_type
    condition: "optional_condition"
    params:
      # Step parameters

hooks:
  pre_workflow: []
  on_success: []
  on_failure: []
```

## Step Types

### pdf_extract
```yaml
- name: extract_pdf
  type: pdf_extract
  params:
    input: "{workflow_input}"
    output_dir: "{temp_dir}/extracted"
    format: "png"  # png, jpg, tiff
    page_range: "1-5"  # Optional
    embedded_images: false
```

### excel_extract
```yaml
- name: extract_excel
  type: excel_extract
  params:
    input: "{workflow_input}"
    output_dir: "{temp_dir}/extracted"
    keep_names: false
    format: "png"
    quality: 85
```

### convert
```yaml
- name: convert_format
  type: convert
  params:
    input_dir: "{temp_dir}/extracted"
    format: "webp"  # png, jpg, webp, tiff, bmp
    quality: 85
    output_template: "{output_dir}/converted/{counter:03d}.{format}"
```

### resize
```yaml
- name: resize_images
  type: resize
  params:
    input_dir: "{temp_dir}/extracted"
    width: 800
    height: 600
    maintain_aspect: true
    quality: 85
    allow_upscale: false
    output_template: "{output_dir}/resized/{counter:03d}.jpg"
```

### watermark
```yaml
- name: add_watermark
  type: watermark
  params:
    input_dir: "{temp_dir}/extracted"
    watermark_image: "/path/to/watermark.png"
    position: "bottom-right"  # top-left, top-right, bottom-left, bottom-right, center
    opacity: 0.7
    scale: 0.1
    output_template: "{output_dir}/watermarked/{counter:03d}.jpg"
```

### ocr
```yaml
- name: extract_text
  type: ocr
  params:
    input_dir: "{temp_dir}/extracted"
    language: "eng"
    confidence_threshold: 60
    output_template: "{output_dir}/text/{counter:03d}.txt"
```

### custom
```yaml
- name: custom_step
  type: custom
  params:
    script: |
      #!/bin/bash
      echo "Custom processing for {workflow_input}"
      # Your custom logic here
    output_file: "{output_dir}/custom_result.txt"
```

## Template Variables

### Basic Variables
- `{workflow_input}` - Input file/directory path
- `{output_dir}` - Configured output directory
- `{temp_dir}` - Temporary working directory
- `{timestamp}` - Current timestamp (YYYYMMDD_HHMMSS)
- `{workflow_name}` - Name of current workflow
- `{step_name}` - Name of current step

### File Variables
- `{input_name}` - Base name of input file (without extension)
- `{input_ext}` - Extension of input file
- `{pdf_name}` - Base name of PDF file
- `{counter}` - Sequential counter (1, 2, 3...)
- `{counter:03d}` - Formatted counter (001, 002, 003...)

### Context Variables
- `{image_count}` - Number of images processed
- `{total_size}` - Total size of processed files
- `{processed_count}` - Number of successfully processed files
- `{failed_count}` - Number of failed operations
- `{extracted_count}` - Number of images extracted

## Conditional Logic

### Basic Conditions
```yaml
- name: conditional_step
  type: resize
  condition: "image_count > 10"
  params:
    width: 800
    height: 600
```

### Complex Conditions
```yaml
- name: smart_processing
  type: convert
  condition: "image_count > 5 && total_size > 50MB"
  params:
    format: "webp"
    quality: 80
```

### Conditional with Else
```yaml
- name: adaptive_resize
  type: resize
  condition: "image_count > 10"
  params:
    width: 800
    height: 600
    quality: 80
  else:
    width: 1200
    height: 900
    quality: 90
```

## Hooks

### Available Hooks
```yaml
hooks:
  pre_workflow:
    - echo "Starting workflow for: {workflow_input}"
    
  post_step:
    - echo "Completed step: {step_name}"
    
  on_success:
    - echo "Workflow completed successfully!"
    - notify-send "imgxsh" "Processing complete"
    
  on_failure:
    - echo "Workflow failed at step: {failed_step}"
```

### Webhook Integration
```yaml
hooks:
  on_success:
    - curl -X POST "https://api.example.com/webhook" \
        -H "Content-Type: application/json" \
        -d '{"workflow": "{workflow_name}", "status": "completed"}'
```

## Presets

### Basic Preset Structure
```yaml
name: preset-name
description: "Description"
base_workflow: workflow-name

overrides:
  settings:
    parallel_jobs: 8
    
  steps:
    step_name:
      params:
        quality: 70
      enabled: true
```

### Common Preset Patterns
```yaml
# Speed-focused preset
overrides:
  settings:
    parallel_jobs: 8
    
  steps:
    create_full_size:
      enabled: false  # Skip full-size creation
      
# Quality-focused preset
overrides:
  steps:
    create_thumbnails:
      params:
        quality: 95
        format: "png"
```

### Preset steps: mapping vs list

- Workflows define `steps` as a sequence (list).
- Presets define `overrides.steps` as a mapping of step-name → overrides.
- To add multiple preset overrides, add more named keys under `overrides.steps` (do not use `- name:` items).

See also: Preset system details in [docs/PRESETS-SYSTEM.md](./PRESETS-SYSTEM.md).

## Common Patterns

### Multi-size Generation
```yaml
- name: generate_mobile
  type: resize
  params:
    input_dir: "{temp_dir}/extracted"
    widths: [320, 480, 640]
    maintain_aspect: true
    quality: 80
    format: "webp"
    output_template: "{output_dir}/mobile/{input_name}_{width}w.webp"
```

### Batch Processing
```yaml
- name: batch_convert
  type: convert
  params:
    input_dir: "{temp_dir}/images"
    format: "webp"
    parallel: true
    max_parallel: 4
```

### File Filtering
```yaml
- name: filter_large_images
  type: convert
  params:
    input_dir: "{temp_dir}/images"
    file_pattern: "*.jpg"
    min_size: "1MB"
    max_size: "10MB"
    format: "webp"
```

### Progress Tracking
```yaml
hooks:
  post_step:
    - echo "Step {step_name} completed"
    - echo "Processed {processed_count} files so far"
```

## Settings

### Performance Settings
```yaml
settings:
  parallel_jobs: 4
  max_memory: "2GB"
  timeout: 300
```

### Quality Settings
```yaml
settings:
  default_quality: 85
  default_format: "webp"
  preserve_metadata: true
```

### Logging Settings
```yaml
settings:
  log_level: "info"  # debug, info, warn, error
  verbose: false
  dry_run: false
```

## Troubleshooting

### Debug Mode
```bash
# Enable debug output
imgxsh --workflow my-workflow --verbose --dry-run input.pdf
```

### Common Issues
- **Template variable not found**: Check variable availability in context
- **Conditional step not executing**: Verify condition syntax
- **Hook not running**: Check hook syntax and event occurrence
- **Performance issues**: Adjust parallel_jobs and check resources

### Validation
```bash
# Validate workflow syntax
imgxsh --validate-workflow my-workflow.yaml

# Test with sample data
imgxsh --workflow my-workflow --test-mode sample.pdf
```

## Best Practices

### Workflow Design
- Use descriptive names and descriptions
- Version your workflows
- Test incrementally
- Use conditional logic appropriately

### Performance
- Enable parallel processing for batch operations
- Optimize step order (fast operations first)
- Use appropriate quality settings
- Set reasonable timeouts

### Error Handling
- Use hooks for notifications
- Implement cleanup procedures
- Add validation steps
- Test error scenarios

### Template Variables
- Use consistent naming patterns
- Include timestamps for uniqueness
- Use formatted counters for sorting
- Document custom variables
