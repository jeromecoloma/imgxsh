# Workflow Configuration Guide

This guide covers the complete workflow configuration system in imgxsh, including YAML syntax, step types, conditional logic, template variables, and hooks.

## Table of Contents

- [Configuration File Structure](#configuration-file-structure)
- [Workflow Definition](#workflow-definition)
- [Step Types](#step-types)
- [Conditional Logic](#conditional-logic)
- [Template Variables](#template-variables)
- [Hooks System](#hooks-system)
- [Settings Configuration](#settings-configuration)
- [Examples](#examples)

## Configuration File Structure

imgxsh workflows are defined in YAML files with the following structure:

```yaml
# Workflow metadata
name: workflow-name
description: "Human-readable description"
version: "1.0"

# Global settings
settings:
  output_dir: "./output"
  temp_dir: "/tmp/imgxsh"
  parallel_jobs: 4

# Workflow steps
steps:
  - name: step_name
    type: step_type
    description: "Step description"
    condition: "optional_condition"
    params:
      # Step-specific parameters

# Hooks for workflow events
hooks:
  pre_workflow: []
  post_step: []
  on_success: []
  on_failure: []
```

## Workflow Definition

### Basic Workflow Properties

- **`name`**: Unique identifier for the workflow (required)
- **`description`**: Human-readable description of what the workflow does
- **`version`**: Workflow version for compatibility tracking

### Example Basic Workflow

```yaml
name: simple-convert
description: "Convert images to WebP format"
version: "1.0"

steps:
  - name: convert_images
    type: convert
    params:
      format: "webp"
      quality: 85
```

## Step Types

### Core Step Types

#### `pdf_extract`
Extracts images from PDF documents.

```yaml
- name: extract_pdf
  type: pdf_extract
  params:
    input: "{workflow_input}"
    output_dir: "{temp_dir}/extracted"
    format: "png"  # png, jpg, tiff
    page_range: "1-5"  # Optional: specific pages
    embedded_images: false  # Extract embedded vs rasterize pages
```

#### `excel_extract`
Extracts embedded images from Excel files.

```yaml
- name: extract_excel
  type: excel_extract
  params:
    input: "{workflow_input}"
    output_dir: "{temp_dir}/extracted"
    keep_names: false  # Keep original embedded names
    format: "png"  # Convert to specific format
    quality: 85
```

#### `convert`
Converts images between formats.

```yaml
- name: convert_format
  type: convert
  params:
    input_dir: "{temp_dir}/extracted"
    format: "webp"  # png, jpg, webp, tiff, bmp
    quality: 85
    output_template: "{output_dir}/converted/{counter:03d}.{format}"
```

#### `resize`
Resizes images with various options.

```yaml
- name: create_thumbnails
  type: resize
  params:
    input_dir: "{temp_dir}/extracted"
    width: 300
    height: 200
    maintain_aspect: true
    quality: 80
    allow_upscale: false
    output_template: "{output_dir}/thumbs/{counter:03d}.jpg"
```

#### `watermark`
Adds watermarks to images.

```yaml
- name: add_watermark
  type: watermark
  params:
    input_dir: "{temp_dir}/extracted"
    watermark_image: "/path/to/watermark.png"
    position: "bottom-right"  # top-left, top-right, bottom-left, bottom-right, center
    opacity: 0.7
    scale: 0.1  # 10% of image size
    output_template: "{output_dir}/watermarked/{counter:03d}.jpg"
```

#### `ocr`
Extracts text from images using OCR.

```yaml
- name: extract_text
  type: ocr
  params:
    input_dir: "{temp_dir}/extracted"
    language: "eng"  # Tesseract language code
    output_template: "{output_dir}/text/{counter:03d}.txt"
    confidence_threshold: 60
```

#### `custom`
Executes custom shell scripts.

```yaml
- name: custom_processing
  type: custom
  params:
    script: |
      #!/bin/bash
      echo "Processing {workflow_input}"
      # Custom processing logic here
    output_file: "{output_dir}/custom_result.txt"
```

#### HTML Generation with Custom Steps

Custom steps are particularly powerful for generating HTML galleries and reports:

```yaml
- name: generate_html_gallery
  type: custom
  description: "Generate interactive HTML gallery"
  condition: "extracted_count > 0"
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
      
      echo "Gallery created successfully at $html_file"
```

#### Custom Step Best Practices

1. **Always use shebang**: Start scripts with `#!/bin/bash`
2. **Handle errors**: Use `set -euo pipefail` for robust error handling
3. **Use template variables**: Leverage `{workflow_input}`, `{output_dir}`, etc.
4. **Generate meaningful output**: Create files that users can easily access
5. **Include progress feedback**: Use `echo` statements to show progress
6. **Clean up temporary files**: Remove any temporary files created during execution

### Advanced Step Parameters

#### Batch Processing
Most steps support batch processing with directory inputs:

```yaml
- name: batch_convert
  type: convert
  params:
    input_dir: "{temp_dir}/images"  # Process all images in directory
    format: "webp"
    parallel: true  # Enable parallel processing
    max_parallel: 4  # Limit parallel jobs
```

#### File Filtering
Filter files by type, size, or other criteria:

```yaml
- name: filter_large_images
  type: convert
  params:
    input_dir: "{temp_dir}/images"
    file_pattern: "*.jpg"  # Only process JPG files
    min_size: "1MB"  # Skip files smaller than 1MB
    max_size: "10MB"  # Skip files larger than 10MB
    format: "webp"
```

## Conditional Logic

Workflows support conditional step execution based on context variables.

### Basic Conditions

```yaml
- name: conditional_resize
  type: resize
  condition: "image_count > 10"  # Only resize if more than 10 images
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
    quality: 80  # Lower quality for large batches
```

### Available Context Variables

- `image_count`: Number of images processed so far
- `total_size`: Total size of processed files (in bytes)
- `processed_count`: Number of successfully processed files
- `failed_count`: Number of failed operations
- `step_number`: Current step number in workflow
- `workflow_duration`: Time elapsed since workflow start (seconds)

### Conditional Step with Else

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

## Template Variables

Template variables allow dynamic content generation in file paths, commands, and output.

### Basic Variables

- `{workflow_input}`: Input file or directory path
- `{output_dir}`: Configured output directory
- `{temp_dir}`: Temporary working directory
- `{timestamp}`: Current timestamp (YYYYMMDD_HHMMSS)
- `{workflow_name}`: Name of the current workflow
- `{step_name}`: Name of the current step

### File-Specific Variables

- `{input_name}`: Base name of input file (without extension)
- `{input_ext}`: Extension of input file
- `{pdf_name}`: Base name of PDF file (if processing PDF)
- `{counter}`: Sequential counter (1, 2, 3...)
- `{counter:03d}`: Formatted counter with zero padding (001, 002, 003...)

### Template Examples

```yaml
# Basic file naming
output_template: "{output_dir}/{input_name}_processed.{format}"

# Sequential numbering
output_template: "{output_dir}/image_{counter:03d}.jpg"

# Timestamp-based naming
output_template: "{output_dir}/{timestamp}_{input_name}.webp"

# Complex path structure
output_template: "{output_dir}/{pdf_name}/page_{counter:03d}_{timestamp}.jpg"
```

## Hooks System

Hooks allow you to execute commands at specific points in the workflow lifecycle.

### Available Hooks

#### `pre_workflow`
Executed before the workflow starts.

```yaml
hooks:
  pre_workflow:
    - echo "Starting workflow for: {workflow_input}"
    - mkdir -p "{output_dir}"
```

#### `post_step`
Executed after each step completes successfully.

```yaml
hooks:
  post_step:
    - echo "Completed step: {step_name}"
    - echo "Processed {processed_count} files so far"
```

#### `on_success`
Executed when the entire workflow completes successfully.

```yaml
hooks:
  on_success:
    - echo "Workflow completed successfully!"
    - echo "Output available at: {output_dir}"
    - notify-send "imgxsh" "Workflow completed: {workflow_name}"
```

#### `on_failure`
Executed when the workflow fails.

```yaml
hooks:
  on_failure:
    - echo "Workflow failed at step: {failed_step}"
    - echo "Error: {error_message}"
    - notify-send "imgxsh" "Workflow failed: {workflow_name}"
```

### Webhook Integration

```yaml
hooks:
  on_success:
    - curl -X POST "https://api.example.com/webhook" \
        -H "Content-Type: application/json" \
        -d '{"workflow": "{workflow_name}", "status": "completed", "files": {processed_count}}'
```

## Settings Configuration

Global settings control workflow behavior and resource usage.

### Output and Temporary Directories

```yaml
settings:
  output_dir: "./output"  # Default output directory
  temp_dir: "/tmp/imgxsh"  # Temporary working directory
```

### Performance Settings

```yaml
settings:
  parallel_jobs: 4  # Number of parallel processing jobs
  max_memory: "2GB"  # Memory limit for processing
  timeout: 300  # Step timeout in seconds
```

### Quality and Format Settings

```yaml
settings:
  default_quality: 85  # Default quality for lossy formats
  default_format: "webp"  # Default output format
  preserve_metadata: true  # Keep EXIF and other metadata
```

### Logging and Debugging

```yaml
settings:
  log_level: "info"  # debug, info, warn, error
  verbose: false  # Enable verbose output
  dry_run: false  # Preview mode without execution
```

## Examples

### Complete PDF to Web Gallery Workflow

```yaml
name: pdf-to-web-gallery
description: "Extract PDF images and create web gallery"
version: "1.0"

settings:
  output_dir: "./output/gallery"
  temp_dir: "/tmp/imgxsh/gallery"
  parallel_jobs: 4

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
      width: 300
      height: 200
      maintain_aspect: true
      quality: 80
      output_template: "{output_dir}/thumbs/{pdf_name}_thumb_{counter:03d}.jpg"
      
  - name: create_full_size
    type: convert
    description: "Create full-size web-optimized versions"
    condition: "extracted_count > 0"
    params:
      input_dir: "{temp_dir}/extracted"
      format: "webp"
      quality: 85
      max_width: 1200
      max_height: 800
      output_template: "{output_dir}/full/{pdf_name}_full_{counter:03d}.webp"
      
  - name: generate_gallery_html
    type: custom
    description: "Generate HTML gallery page"
    condition: "extracted_count > 0"
    params:
      script: |
        #!/bin/bash
        html_file="{output_dir}/gallery.html"
        echo "<html><head><title>Gallery</title></head><body>" > "$html_file"
        echo "<h1>Image Gallery</h1>" >> "$html_file"
        
        for thumb in {output_dir}/thumbs/*.jpg; do
          if [ -f "$thumb" ]; then
            basename=$(basename "$thumb" .jpg)
            full_image="{output_dir}/full/${basename}_full.webp"
            echo "<a href=\"$full_image\"><img src=\"$thumb\" alt=\"$basename\"></a>" >> "$html_file"
          fi
        done
        
        echo "</body></html>" >> "$html_file"
        echo "Gallery created: $html_file"

hooks:
  pre_workflow:
    - echo "Starting PDF to web gallery conversion for: {workflow_input}"
    - mkdir -p "{output_dir}/thumbs" "{output_dir}/full"
    
  post_step:
    - echo "Completed step: {step_name}"
    
  on_success:
    - echo "Gallery created successfully at: {output_dir}/gallery.html"
    - echo "Thumbnails: {output_dir}/thumbs/"
    - echo "Full images: {output_dir}/full/"
    
  on_failure:
    - echo "Workflow failed at step: {failed_step}"
    - echo "Check logs for details"
```

### Excel Image Extraction and Optimization

```yaml
name: excel-to-web
description: "Extract and optimize Excel embedded images"
version: "1.0"

settings:
  output_dir: "./output/excel-images"
  parallel_jobs: 2

steps:
  - name: extract_excel_images
    type: excel_extract
    description: "Extract embedded images from Excel"
    params:
      input: "{workflow_input}"
      output_dir: "{temp_dir}/extracted"
      keep_names: false
      
  - name: convert_to_webp
    type: convert
    description: "Convert to WebP for web optimization"
    condition: "extracted_count > 0"
    params:
      input_dir: "{temp_dir}/extracted"
      format: "webp"
      quality: 85
      output_template: "{output_dir}/{input_name}_image_{counter:03d}.webp"
      
  - name: create_thumbnails
    type: resize
    description: "Create thumbnail versions"
    condition: "extracted_count > 0"
    params:
      input_dir: "{temp_dir}/extracted"
      width: 200
      height: 200
      maintain_aspect: true
      quality: 75
      output_template: "{output_dir}/thumbs/{input_name}_thumb_{counter:03d}.jpg"

hooks:
  on_success:
    - echo "Excel images extracted and optimized"
    - echo "WebP images: {output_dir}/*.webp"
    - echo "Thumbnails: {output_dir}/thumbs/"
```

### Conditional Processing Workflow

```yaml
name: smart-batch-process
description: "Intelligent batch processing with conditional logic"
version: "1.0"

settings:
  output_dir: "./output/smart-batch"
  parallel_jobs: 4

steps:
  - name: analyze_input
    type: custom
    description: "Analyze input to determine processing strategy"
    params:
      script: |
        #!/bin/bash
        echo "Analyzing input: {workflow_input}"
        # Custom analysis logic here
        
  - name: high_quality_process
    type: convert
    description: "High quality processing for small batches"
    condition: "image_count <= 5"
    params:
      input_dir: "{workflow_input}"
      format: "webp"
      quality: 95
      output_template: "{output_dir}/hq_{counter:03d}.webp"
      
  - name: standard_process
    type: convert
    description: "Standard processing for medium batches"
    condition: "image_count > 5 && image_count <= 20"
    params:
      input_dir: "{workflow_input}"
      format: "webp"
      quality: 85
      output_template: "{output_dir}/std_{counter:03d}.webp"
      
  - name: fast_process
    type: convert
    description: "Fast processing for large batches"
    condition: "image_count > 20"
    params:
      input_dir: "{workflow_input}"
      format: "webp"
      quality: 75
      parallel: true
      max_parallel: 8
      output_template: "{output_dir}/fast_{counter:03d}.webp"

hooks:
  on_success:
    - echo "Smart batch processing completed"
    - echo "Processed {processed_count} images with optimal settings"
```

## Best Practices

### Workflow Design

1. **Use descriptive names**: Choose clear, descriptive names for workflows and steps
2. **Add descriptions**: Always include descriptions for complex workflows
3. **Version your workflows**: Use version numbers for workflow compatibility
4. **Test incrementally**: Test each step individually before combining

### Performance Optimization

1. **Use parallel processing**: Enable parallel processing for batch operations
2. **Optimize step order**: Place faster operations before slower ones
3. **Use conditional logic**: Skip unnecessary steps based on context
4. **Set appropriate timeouts**: Prevent hanging on problematic files

### Error Handling

1. **Use hooks for notifications**: Set up failure notifications
2. **Implement cleanup**: Use hooks to clean up temporary files
3. **Add validation**: Validate inputs before processing
4. **Test error scenarios**: Test workflows with invalid inputs

### Template Variables

1. **Use consistent naming**: Follow consistent patterns for file naming
2. **Include timestamps**: Add timestamps for unique file identification
3. **Use formatted counters**: Use zero-padded counters for proper sorting
4. **Document custom variables**: Document any custom variables you create

## Troubleshooting

### Common Issues

1. **Template variable not found**: Ensure the variable is available in the current context
2. **Conditional step not executing**: Check the condition syntax and available variables
3. **Hook not running**: Verify hook syntax and ensure the event occurred
4. **Performance issues**: Adjust parallel_jobs and check for resource constraints

### Debug Mode

Enable debug mode to troubleshoot workflow issues:

```yaml
settings:
  log_level: "debug"
  verbose: true
  dry_run: true  # Preview without execution
```

This will provide detailed logging and allow you to preview operations without actually executing them.
