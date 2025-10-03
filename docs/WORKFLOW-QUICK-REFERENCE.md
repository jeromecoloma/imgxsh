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

# Use built-in workflow
imgxsh --workflow pdf-to-thumbnails document.pdf

# Use preset
imgxsh --preset quick-thumbnails document.pdf

# Preview without execution
imgxsh --workflow pdf-to-web --dry-run document.pdf

# Get workflow info
imgxsh --workflow-info pdf-to-web

# Batch process multiple files
imgxsh --workflow web-optimize *.jpg
imgxsh --workflow pdf-to-thumbnails *.pdf

# Batch process with parallel processing
imgxsh --workflow web-optimize --parallel 8 *.jpg
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

### HTML Generation Pattern
```yaml
- name: generate_html_gallery
  type: custom
  description: "Generate interactive HTML gallery"
  params:
    script: |
      #!/bin/bash
      html_file="{output_dir}/gallery.html"
      
      # Create HTML with embedded CSS and JavaScript
      cat > "$html_file" << 'EOF'
      <!DOCTYPE html>
      <html lang="en">
      <head>
          <meta charset="UTF-8">
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
          <title>Image Gallery</title>
          <style>
              .gallery { display: grid; grid-template-columns: repeat(auto-fill, minmax(300px, 1fr)); gap: 20px; }
              .gallery-item { background: white; border-radius: 8px; padding: 15px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
              .gallery-item img { width: 100%; height: auto; cursor: pointer; }
              .modal { display: none; position: fixed; z-index: 1000; left: 0; top: 0; width: 100%; height: 100%; background-color: rgba(0,0,0,0.9); }
              .modal-content { margin: auto; display: block; max-width: 90%; max-height: 90%; }
          </style>
      </head>
      <body>
          <h1>Image Gallery</h1>
          <div class="gallery">
      EOF
      
      # Generate gallery items dynamically
      counter=1
      for thumb in "{output_dir}/thumbnails"/*.jpg; do
          if [[ -f "$thumb" ]]; then
              thumb_name=$(basename "$thumb")
              full_name="${thumb_name/_thumb_/_full_}"
              echo "              <div class=\"gallery-item\">" >> "$html_file"
              echo "                  <img src=\"thumbnails/$thumb_name\" onclick=\"openModal('full/$full_name')\" alt=\"Image $counter\">" >> "$html_file"
              echo "                  <h3>Image $counter</h3>" >> "$html_file"
              echo "              </div>" >> "$html_file"
              ((counter++))
          fi
      done
      
      # Close HTML with JavaScript
      cat >> "$html_file" << 'EOF'
          </div>
          <div id="modal" class="modal">
              <span class="close" onclick="closeModal()">&times;</span>
              <img class="modal-content" id="modalImg">
          </div>
          <script>
              function openModal(src) {
                  document.getElementById('modal').style.display = 'block';
                  document.getElementById('modalImg').src = src;
              }
              function closeModal() {
                  document.getElementById('modal').style.display = 'none';
              }
          </script>
      </body>
      </html>
      EOF
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

## Built-in Workflows

### pdf-to-web
Complete PDF to web gallery workflow with HTML generation:
```bash
imgxsh --workflow pdf-to-web document.pdf
```
Creates:
- `thumbnails/` - 300x200 thumbnails for quick browsing
- `full/` - Full-size WebP images for detailed viewing  
- `gallery.html` - Interactive HTML gallery with modal view

### pdf-to-thumbnails
Extract PDF images and create thumbnails:
```bash
imgxsh --workflow pdf-to-thumbnails document.pdf
```

### web-optimize
Optimize images for web use:
```bash
imgxsh --workflow web-optimize *.jpg
```

### excel-extract
Extract images from Excel files:
```bash
imgxsh --workflow excel-extract workbook.xlsx
```

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

### Individual Tool Batch Processing
```bash
# Directory resizing with structure preservation
imgxsh-resize --width 800 ./photos/ ./resized/

# Batch format conversion with parallel processing
imgxsh-batch-convert --format webp --parallel 8 ./images/ ./converted/

# Extract from multiple PDFs
for pdf in *.pdf; do
    imgxsh-extract-pdf "$pdf" "./extracted/${pdf%.pdf}/"
done

# Extract from multiple Excel files
for excel in *.xlsx; do
    imgxsh-extract-excel "$excel" "./extracted/${excel%.xlsx}/"
done
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
