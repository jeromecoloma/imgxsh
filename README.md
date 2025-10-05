# imgxsh

A comprehensive CLI image processing tool that extracts, converts, resizes, and processes images from various sources (PDFs, Excel files, individual images) through configurable workflows.

## 🚀 Overview

imgxsh is a workflow-driven image processing CLI tool built on the [Shell Starter framework](https://github.com/jeromecoloma/shell-starter) that provides both workflow orchestration and individual processing commands.

### Key Features

- **Multi-source Extraction**: Extract images from PDFs, Excel files, and process individual images
- **Workflow Orchestration**: YAML-based workflow configuration with conditional logic
- **Advanced Batch Processing**: Full directory processing with parallel execution and progress tracking
- **Format Conversion**: Support for PNG, JPG, WebP, TIFF, BMP with quality control
- **Template-based Naming**: Flexible output file naming with variables
- **Plugin System**: Extensible through custom workflow steps
- **Notification Integration**: Webhooks and system notifications
- **Built-in Presets**: Common workflows ready to use

## 🎯 Quick Start

### Prerequisites

imgxsh requires the following tools:
- **ImageMagick** (image processing)
- **pdfimages/poppler-utils** (PDF processing)
- **unzip** (Excel processing)
- **yq** (YAML parsing)
- **Tesseract** (OCR - optional)

See [Installing Dependencies](#installing-dependencies) below for detailed installation instructions.

## 🛠️ Installation

> **Note**: imgxsh is currently in development. Installation instructions will be available once the first release is ready.

**Before installing imgxsh**, make sure you have installed the required dependencies (see [Installing Dependencies](#installing-dependencies) below).

```bash
# Remote installation (recommended)
bash <(curl -fsSL https://raw.githubusercontent.com/jeromecoloma/imgxsh/main/install.sh)

# Local installation (if you've cloned the repository)
./install.sh --prefix ~/.local/bin
```

### Uninstallation

```bash
# Method 1: Using imgxsh built-in uninstaller (recommended)
imgxsh --uninstall

# Method 2: Standalone uninstaller
bash <(curl -fsSL https://raw.githubusercontent.com/jeromecoloma/imgxsh/main/uninstall.sh)

# Automatic uninstall without confirmation
bash <(curl -fsSL https://raw.githubusercontent.com/jeromecoloma/imgxsh/main/uninstall.sh) -y
```

## 📦 Installing Dependencies

Before installing imgxsh, you need to install the required dependencies for your platform.

### macOS

```bash
# Install via Homebrew
brew install imagemagick poppler yq

# Optional: Install Tesseract for OCR features
brew install tesseract
```

### Ubuntu/Debian

```bash
# Install core dependencies
sudo apt-get update
sudo apt-get install imagemagick poppler-utils unzip

# Install yq (YAML processor) - recommended binary installation:
sudo wget https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -O /usr/local/bin/yq
sudo chmod +x /usr/local/bin/yq

# Alternative: yq via snap (requires granting home directory access)
# sudo snap install yq && sudo snap connect yq:home

# Optional: Install Tesseract for OCR features
sudo apt-get install tesseract-ocr
```

### Verify Dependencies

After installing dependencies, verify they are available:

```bash
# Manually verify each tool
convert -version        # ImageMagick
pdfimages -v           # poppler-utils
yq --version           # yq YAML processor
tesseract --version    # Tesseract (optional)

# After installing imgxsh, you can also use:
imgxsh-check-deps
```

## 🎨 Basic Usage

```bash
# Extract images from PDF and convert to web format
imgxsh --workflow pdf-to-web document.pdf

# Use built-in presets
imgxsh --preset web-thumbnails *.jpg

# Preview operations without execution
imgxsh --config custom.yaml --dry-run ./images/
```

## 📋 Available Commands

### Main Binary
- `imgxsh` - Main workflow orchestrator with subcommand support

### Individual Tools
- `imgxsh-convert` - Convert images between formats
- `imgxsh-resize` - Resize images with aspect ratio control
  - Pixel/percentage sizing, batch directories, smart no-upscale (`--allow-upscale` to override), `--max-file-size`
  - `--background COLOR` to set background color for transparent images (e.g., white, black, #FF0000)
- `imgxsh-extract-pdf` - Extract images from PDF documents
  - Default: rasterize one image per page (ImageMagick, density 300, quality 90)
  - `--embedded-images` to extract original embedded raster images (pdfimages)
  - `--list-only` shows both Pages (via `pdfinfo`) and Embedded images (via `pdfimages`)
  - Advanced page range selection: simple ranges (`1-5`), individual pages (`1,3,7`), open ranges (`5-`), mixed ranges (`1-3,5,7-9`)
  - Sequential output numbering preserves naming scheme while skipping non-selected pages
  - Format conversion, metadata preservation, template-based naming, quality control, dry-run mode
- `imgxsh-extract-excel` - Extract images from Excel files
  - .xlsx support via `unzip` (lists and extracts `xl/media/*`)
  - .xls (legacy) support via `7z/p7zip` for Composite Document Format
  - `--list-only` to preview embedded media; verbose shows file list
  - Naming: default `{prefix}_{NNN}.{ext}` or `--keep-names`
  - Optional conversion with `-f/--format` and `--quality`
  - Dry-run support with detailed logs
- `imgxsh-watermark` - Add watermarks to images
- `imgxsh-ocr` - Extract text from images using OCR

## 📂 Project Structure

```
imgxsh/
├── bin/                # imgxsh binaries (main tool and individual utilities)
├── tests/              # Comprehensive testing framework with CI integration
│   ├── run-tests.sh   # Local development test runner
│   ├── run-tests-ci.sh # CI-optimized test runner (Shell Starter pattern)
│   ├── setup-ci-environment.sh # CI environment configuration
│   ├── imgxsh-convert.bats # Comprehensive test suite (30+ tests)
│   ├── imgxsh-resize.bats  # Resize test suite (CLI, sizing modes, batch)
│   ├── imgxsh-extract-pdf.bats # PDF extraction test suite (40+ tests)
│   ├── fixtures/      # Test data (images, PDFs, Excel files)
│   └── bats-*/        # Bats testing framework and libraries
├── .github/workflows/  # GitHub Actions CI/CD workflows
├── docs/               # Project documentation
│   └── SETUP-HOOKS.md  # Git hooks setup guide
├── demo/               # Shell Starter example scripts (for reference)
├── lib/                # Shell Starter library (colors, logging, spinners)
├── shell-starter-tests/# Shell Starter framework tests (temporary)
├── shell-starter-docs/ # Shell Starter framework documentation (temporary)
├── .ai-workflow/       # AI development workflow and requirements
├── VERSION             # imgxsh version file (SemVer)
├── .shell-starter-version  # Shell Starter dependency version tracking
├── install.sh          # imgxsh installer
└── uninstall.sh        # imgxsh uninstaller
```

## ⬆️ Updating imgxsh

You can update the imgxsh project itself using the built-in updater.

```bash
# Quick check for available updates (no changes)
bin/update-imgxsh --check

# Update to the latest release
bin/update-imgxsh

# Specify a target version
bin/update-imgxsh --target-version 0.1.0

# Dry run (show actions without applying changes)
bin/update-imgxsh --dry-run

# From any tool, check project version and latest release status
imgxsh --check-version
imgxsh-convert --check-version
imgxsh-extract-pdf --check-version

# From any tool, quickly check for updates
imgxsh --update
```

## 📘 Usage Examples

### PDF Extraction (`imgxsh-extract-pdf`)

```bash
# Show PDF summary (pages and embedded images)
imgxsh-extract-pdf --list-only document.pdf ./out

# Rasterize pages to JPG (default): page-00.jpg, page-01.jpg, ...
imgxsh-extract-pdf document.pdf ./out

# Extract specific page ranges with sequential numbering
imgxsh-extract-pdf --page-range "1-5" document.pdf ./out
imgxsh-extract-pdf --page-range "1,3,7" document.pdf ./out
imgxsh-extract-pdf --page-range "5-" document.pdf ./out
imgxsh-extract-pdf --page-range "1-3,5,7-9" document.pdf ./out

# Extract embedded images instead of rasterizing pages
imgxsh-extract-pdf --embedded-images document.pdf ./out

# Dry run with verbose output
imgxsh-extract-pdf --dry-run --verbose document.pdf ./out
```

Notes:
- Raster mode uses `magick`/`convert -density 300 -quality 90` by default.
- Complex page ranges are fully supported: simple ranges (`1-5`), individual pages (`1,3,7`), open ranges (`5-`), mixed ranges (`1-3,5,7-9`).
- Pages are processed individually to maintain correct sequential output numbering (page-01.jpg, page-02.jpg, etc.).
- Embedded images mode uses `pdfimages` and may produce many images per page depending on the document.

### Excel Extraction (`imgxsh-extract-excel`)

```bash
# List embedded media without extracting
imgxsh-extract-excel --list-only workbook.xlsx ./out

# Extract with default naming (image_001.png, ...)
imgxsh-extract-excel workbook.xlsx ./extracted

# Extract and convert to JPG with quality 85
imgxsh-extract-excel -f jpg --quality 85 workbook.xlsx ./extracted

# Keep original embedded media names
imgxsh-extract-excel --keep-names workbook.xlsx ./extracted

# Dry run (show planned actions only)
imgxsh-extract-excel --dry-run --verbose workbook.xlsx ./extracted
```

Notes:
- Project updates use `bin/update-imgxsh`. Shell Starter library updates remain available via `bin/update-shell-starter`.
- `--check-version` reports the current imgxsh version and the latest GitHub release.
- In CI or tests, `TEST_MODE=true` ensures update commands are no-ops for speed.

## 🔄 Batch Processing

imgxsh provides powerful batch processing capabilities across all tools, allowing you to process entire directories efficiently with parallel execution and progress tracking.

### Batch Processing Overview

| Tool | Directory Support | Parallel Processing | Progress Tracking | Use Case |
|------|-------------------|-------------------|------------------|----------|
| `imgxsh-resize` | ✅ Full recursive | ✅ Built-in | ✅ Yes | Resize entire directory trees |
| `imgxsh-convert` | ✅ Full recursive | ✅ Built-in | ✅ Yes | Convert formats in batch |
| `imgxsh-extract-pdf` | ✅ Output dir | ❌ Single PDF | ✅ Yes | Extract from single PDF |
| `imgxsh-extract-excel` | ✅ Output dir | ❌ Single Excel | ✅ Yes | Extract from single Excel |
| `imgxsh` (workflows) | ✅ Full recursive | ✅ Configurable | ✅ Yes | Advanced batch workflows |

### Quick Batch Examples

```bash
# Resize entire directory with parallel processing
imgxsh-resize --width 800 --format webp ./photos/ ./web_photos/

# Batch convert with directory processing
imgxsh-convert --format webp --quality 90 ./images/ ./converted/

# Process multiple files with workflows
imgxsh --workflow web-optimize *.jpg
imgxsh --workflow pdf-to-thumbnails *.pdf

# Batch process with custom parallel settings
imgxsh --workflow batch-convert --parallel 12 ./large_dataset/
```

### Detailed Batch Processing Guide

#### 1. Directory Resizing (`imgxsh-resize`)

The most comprehensive batch tool - processes entire directory trees recursively:

```bash
# Basic batch resize (preserves directory structure)
imgxsh-resize --width 1200 ./photos/ ./resized/

# Batch resize with format conversion and quality control
imgxsh-resize --width 800 --format webp --quality 85 ./images/ ./web_images/

# Batch resize with constraints and aspect ratio
imgxsh-resize --max-width 1920 --max-height 1080 --aspect-ratio 16:9 ./photos/ ./gallery/

# Batch resize with crop and background handling
imgxsh-resize --crop --size 800x600 --background white ./transparent/ ./cropped/

# Dry run to preview batch operations
imgxsh-resize --dry-run --verbose --width 800 ./photos/ ./resized/
```

**Features:**
- ✅ **Recursive processing**: Handles nested directory structures
- ✅ **Structure preservation**: Maintains relative paths in output
- ✅ **Progress tracking**: Shows `[X/Y] Processing: filename` for each file
- ✅ **Spinner animations**: Visual feedback during processing
- ✅ **Error handling**: Continues processing on individual file failures
- ✅ **Comprehensive options**: All resize options work in batch mode

#### 2. Batch Format Conversion (`imgxsh-convert`)

Integrated batch processing for converting image formats:

```bash
# Convert all images to WebP format
imgxsh-convert --format webp --quality 90 ./photos/ ./web_photos/

# Convert with backup and overwrite control
imgxsh-convert --format webp --backup --overwrite ./photos/ ./optimized/

# Preview batch operations
imgxsh-convert --dry-run --verbose --format webp ./photos/ ./converted/
```

**Features:**
- ✅ **Directory processing**: Handles entire directory trees recursively
- ✅ **Structure preservation**: Maintains relative directory structure
- ✅ **Progress tracking**: Shows `[X/Y] Processing: filename` for each file
- ✅ **Backup creation**: `--backup` to preserve originals
- ✅ **Overwrite control**: `--overwrite` to replace existing files
- ✅ **Dry-run mode**: Preview operations without execution

#### 3. PDF Image Extraction (`imgxsh-extract-pdf`)

Extract multiple images from PDF documents:

```bash
# Extract all pages as images
imgxsh-extract-pdf document.pdf ./extracted/

# Extract specific page ranges
imgxsh-extract-pdf --page-range "1-5" document.pdf ./pages/

# Extract embedded images instead of rasterizing
imgxsh-extract-pdf --embedded-images document.pdf ./embedded/

# Extract with format conversion
imgxsh-extract-pdf --format png --quality 95 document.pdf ./extracted/
```

**Features:**
- ✅ **Multiple extraction methods**: Rasterization or embedded image extraction
- ✅ **Page range selection**: `1-5`, `1,3,7`, `5-`, `1-3,5,7-9`
- ✅ **Sequential numbering**: Maintains consistent naming scheme
- ✅ **Progress tracking**: Shows extraction progress and file counts

#### 4. Excel Image Extraction (`imgxsh-extract-excel`)

Extract embedded images from Excel files:

```bash
# Extract all embedded images
imgxsh-extract-excel workbook.xlsx ./extracted/

# Extract with format conversion
imgxsh-extract-excel --format jpg --quality 85 workbook.xlsx ./converted/

# Keep original embedded names
imgxsh-extract-excel --keep-names workbook.xlsx ./extracted/

# Preview embedded media
imgxsh-extract-excel --list-only workbook.xlsx ./out
```

#### 5. Advanced Workflow Batch Processing (`imgxsh`)

The main workflow system provides the most sophisticated batch processing:

```bash
# Batch process multiple files with workflows
imgxsh --workflow web-optimize *.jpg
imgxsh --workflow pdf-to-thumbnails *.pdf
imgxsh --workflow excel-extract *.xlsx

# Batch process directories
imgxsh --workflow web-optimize ./images/
imgxsh --workflow batch-convert ./photos/

# Parallel processing control
imgxsh --workflow web-optimize --parallel 8 *.jpg

# Batch processing with custom config
imgxsh --config batch-config.yaml --workflow custom-batch ./large_dataset/
```

**Features:**
- ✅ **Multi-file processing**: Handle multiple input files/directories
- ✅ **Parallel execution**: Configurable parallel job limits
- ✅ **Conditional processing**: Smart processing based on file types
- ✅ **Template variables**: Dynamic file naming and paths
- ✅ **Progress tracking**: Comprehensive progress reporting
- ✅ **Error recovery**: Robust error handling and continuation

### Batch Processing Best Practices

#### Performance Optimization

```bash
# Process directories efficiently
imgxsh-resize --width 800 ./photos/ ./resized/  # Uses default parallel processing
imgxsh-convert --format webp ./images/ ./converted/  # Batch conversion
imgxsh --workflow web-optimize --parallel 12 ./large_dataset/  # High parallel for workflows

# Use appropriate quality settings for batch processing
imgxsh-resize --width 1200 --quality 85 ./photos/ ./web_photos/  # Balanced quality/size
imgxsh-convert --format webp --quality 90 ./images/ ./optimized/  # High quality
```

#### Error Handling

```bash
# Use dry-run to preview batch operations
imgxsh-resize --dry-run --verbose --width 800 ./photos/ ./resized/
imgxsh-convert --dry-run --format webp ./images/ ./converted/

# Enable verbose logging for debugging
imgxsh-resize --verbose --width 800 ./photos/ ./resized/
imgxsh --workflow web-optimize --verbose *.jpg
```

#### Directory Structure Management

```bash
# Preserve directory structure (imgxsh-resize)
imgxsh-resize --width 800 ./photos/vacation/ ./resized/vacation/

# Flatten directory structure (imgxsh-convert)
imgxsh-convert --format webp ./photos/vacation/ ./flattened/

# Custom output organization (workflows)
imgxsh --workflow web-optimize ./photos/  # Uses workflow-defined structure
```

### Batch Processing Examples

#### Example 1: Web Gallery Preparation

```bash
# Resize photos for web gallery
imgxsh-resize --width 1200 --format webp --quality 85 ./photos/ ./web_gallery/

# Create thumbnails
imgxsh-resize --width 300 --format jpg --quality 80 ./photos/ ./thumbnails/

# Batch convert remaining images
imgxsh-convert --format webp --quality 90 ./other_images/ ./web_gallery/
```

#### Example 2: Document Processing Pipeline

```bash
# Extract images from multiple PDFs
for pdf in *.pdf; do
    imgxsh-extract-pdf "$pdf" "./extracted/${pdf%.pdf}/"
done

# Batch resize all extracted images
imgxsh-resize --width 800 --format webp ./extracted/ ./web_ready/

# Process Excel files
imgxsh-extract-excel --format png workbook.xlsx ./extracted/excel/
```

#### Example 3: Large Dataset Processing

```bash
# Use workflow for complex batch processing
imgxsh --workflow web-optimize --parallel 16 ./large_dataset/

# Custom batch workflow with progress tracking
imgxsh --config batch-processing.yaml --workflow custom-batch ./dataset/
```

## 🔧 Configuration & Workflows

imgxsh uses a powerful YAML-based workflow system for complex image processing tasks. Workflows allow you to define multi-step processing pipelines with conditional logic, template variables, and hooks.

### Quick Start with Workflows

```bash
# Use built-in workflow
imgxsh --workflow pdf-to-web document.pdf

# Use preset for quick processing
imgxsh --preset quick-thumbnails document.pdf

# Preview workflow without execution
imgxsh --workflow pdf-to-web --dry-run document.pdf
```

### Configuration Files

- **Workflows**: `config/workflows/` - Complete processing pipelines
- **Presets**: `config/presets/` - Workflow variations and shortcuts
- **User Config**: `~/.imgxsh.yaml` - Global settings and custom workflows

### Example Workflow: PDF to Web Gallery

The `pdf-to-web` workflow demonstrates the full power of imgxsh by creating a complete web gallery from a PDF document:

```yaml
name: pdf-to-web
description: "Render PDF pages as images and optimize for web gallery"
version: "1.0"

settings:
  output_dir: "./output"
  temp_dir: "/tmp/imgxsh/pdf-web"
  parallel_jobs: 4

steps:
  - name: extract_pages
    type: pdf_extract
    description: "Render PDF pages as images"
    params:
      input: "{workflow_input}"
      output_dir: "{temp_dir}/extracted"
      format: "png"
      quality: 85
      
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
      output_template: "{output_dir}/thumbnails/{pdf_name}_thumb_{counter:03d}.jpg"
      
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
      output_template: "{output_dir}/full/{pdf_name}_full_{counter:03d}.{format}"
      
  - name: generate_gallery_html
    type: custom
    description: "Generate HTML gallery page"
    condition: "extracted_count > 0"
    params:
      script: |
        #!/bin/bash
        # Generate interactive HTML gallery with modal view
        output_dir="./output"
        html_file="$output_dir/gallery.html"
        
        # Create responsive gallery with modal functionality
        cat > "$html_file" << 'EOF'
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>PDF Gallery</title>
            <style>
                body { font-family: Arial, sans-serif; margin: 20px; background-color: #f5f5f5; }
                .gallery { display: grid; grid-template-columns: repeat(auto-fill, minmax(300px, 1fr)); gap: 20px; }
                .gallery-item { background: white; border-radius: 8px; padding: 15px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
                .gallery-item img { width: 100%; height: auto; border-radius: 4px; cursor: pointer; }
                .gallery-item h3 { margin: 10px 0 5px 0; color: #333; }
                .gallery-item p { margin: 0; color: #666; font-size: 14px; }
                .modal { display: none; position: fixed; z-index: 1000; left: 0; top: 0; width: 100%; height: 100%; background-color: rgba(0,0,0,0.9); }
                .modal-content { margin: auto; display: block; max-width: 90%; max-height: 90%; }
                .close { position: absolute; top: 15px; right: 35px; color: #f1f1f1; font-size: 40px; font-weight: bold; cursor: pointer; }
            </style>
        </head>
        <body>
            <h1>PDF Gallery</h1>
            <div class="gallery">
        EOF
        
        # Add thumbnail entries with modal functionality
        counter=1
        for thumb in "$output_dir/thumbnails"/*.jpg; do
            if [[ -f "$thumb" ]]; then
                thumb_name=$(basename "$thumb")
                full_name="${thumb_name/_thumb_/_full_}"
                full_name="${full_name/.jpg/.webp}"
                full_path="$output_dir/full/$full_name"
                
                if [[ -f "$full_path" ]]; then
                    echo "                <div class=\"gallery-item\">" >> "$html_file"
                    echo "                    <img src=\"thumbnails/$thumb_name\" onclick=\"openModal('full/$full_name')\" alt=\"Page $counter\">" >> "$html_file"
                    echo "                    <h3>Page $counter</h3>" >> "$html_file"
                    echo "                    <p>Click to view full size</p>" >> "$html_file"
                    echo "                </div>" >> "$html_file"
                    ((counter++))
                fi
            fi
        done
        
        # Close the HTML with JavaScript for modal functionality
        cat >> "$html_file" << 'EOF'
            </div>
            
            <div id="modal" class="modal">
                <span class="close" onclick="closeModal()">&times;</span>
                <img class="modal-content" id="modalImg">
            </div>
            
            <script>
                function openModal(src) {
                    const modal = document.getElementById('modal');
                    const modalImg = document.getElementById('modalImg');
                    modal.style.display = 'block';
                    modalImg.src = src;
                }
                
                function closeModal() {
                    document.getElementById('modal').style.display = 'none';
                }
                
                // Close modal when clicking outside the image
                window.onclick = function(event) {
                    const modal = document.getElementById('modal');
                    if (event.target == modal) {
                        modal.style.display = 'none';
                    }
                }
            </script>
        </body>
        </html>
        EOF
        
        echo "Gallery created successfully at $html_file"

hooks:
  pre_workflow:
    - 'echo "Starting PDF page rendering for: {workflow_input}"'
  
  on_success:
    - 'echo "PDF pages rendered successfully"'
    - 'echo "Thumbnails and full-size images created in: {output_dir}"'
    - 'echo "Open gallery.html in your browser to view the interactive gallery"'
  
  on_failure:
    - 'echo "Workflow failed at step: {failed_step}"'
```

**Usage**:
```bash
# Create a complete web gallery from a PDF
imgxsh --workflow pdf-to-web document.pdf

# Output structure:
# output/
# ├── thumbnails/          # 300x200 thumbnails for quick browsing
# │   ├── document_thumb_001.jpg
# │   └── document_thumb_002.jpg
# ├── full/                # Full-size WebP images for detailed viewing
# │   ├── document_full_001.webp
# │   └── document_full_002.webp
# └── gallery.html         # Interactive HTML gallery with modal view
```

### Available Step Types

- **`pdf_extract`** - Extract images from PDF documents
- **`excel_extract`** - Extract embedded images from Excel files
- **`convert`** - Convert images between formats (PNG, JPG, WebP, TIFF, BMP)
- **`resize`** - Resize images with aspect ratio control
- **`watermark`** - Add watermarks to images
- **`ocr`** - Extract text from images using OCR
- **`custom`** - Execute custom shell scripts

### Template Variables

Use dynamic variables in file paths and commands:

- `{workflow_input}` - Input file or directory path
- `{output_dir}` - Configured output directory
- `{pdf_name}` - Base name of PDF file (without extension)
- `{counter:03d}` - Sequential counter with zero padding (001, 002, 003...)
- `{timestamp}` - Current timestamp (YYYYMMDD_HHMMSS)
- `{extracted_count}` - Number of images extracted

### Conditional Logic

Execute steps based on context:

```yaml
- name: smart_resize
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

### Built-in Workflows

- **`pdf-to-web`** - Complete PDF to web gallery workflow with HTML generation
- **`pdf-to-thumbnails`** - Extract PDF images and create thumbnails
- **`web-optimize`** - Optimize images for web use
- **`excel-extract`** - Extract images from Excel files
- **`batch-convert`** - Convert image formats in batch
- **`watermark-apply`** - Apply watermarks to images

### Built-in Presets

- **`quick-thumbnails`** - Fast thumbnail generation for previews
- **`web-optimization`** - Optimize images for web with aggressive compression
- **`high-quality`** - Generate high-quality images for print or archival

### Hooks System

Execute commands at workflow events:

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

### Comprehensive Documentation

For detailed workflow configuration, see:
- **[Workflow Quick Reference](docs/WORKFLOW-QUICK-REFERENCE.md)** - Quick reference for workflow syntax and patterns
- **[Workflow Configuration Guide](docs/WORKFLOW-CONFIGURATION.md)** - Complete workflow system documentation
- **[Presets System Guide](docs/PRESETS-SYSTEM.md)** - Creating and using presets
- **[Examples Gallery](docs/EXAMPLES-GALLERY.md)** - Real-world use cases and examples

## 📖 Development Status

imgxsh is currently in development. The project is built using the Shell Starter framework for robust CLI development patterns.

### Current Status
- ✅ Project structure and requirements defined
- ✅ Shell Starter framework integrated
- 🚧 Core binaries implementation (in progress)
- 🚧 Workflow engine development
- 🚧 Individual tool development
- ✅ Testing and quality assurance
- ⏳ Documentation completion

### Development Framework

This project uses the [Shell Starter framework](https://github.com/jeromecoloma/shell-starter) for:
- **Consistent CLI patterns** with built-in help and version management
- **Logging system** with colored output (`log::info`, `log::warn`, `log::error`)
- **Progress indicators** with spinner support for long-running operations
- **Testing framework** using Bats for reliable script testing
- **Code quality** with ShellCheck and shfmt integration
- **Dependency management** for Shell Starter library updates

### Shell Starter Examples

You can explore Shell Starter patterns in the `./demo/` directory:

```bash
# View Shell Starter example scripts (for development reference)
./demo/hello-world --help      # Basic CLI structure
./demo/show-colors             # Logging functions demonstration
./demo/long-task               # Spinner and progress indicators
./demo/my-cli status           # Multi-command CLI pattern
```

## 🔧 Contributing

We welcome contributions to imgxsh! The project follows Shell Starter conventions for consistency and maintainability.

### Development Setup

1. **Clone the repository**:
   ```bash
   git clone [repository-url]
   cd imgxsh
   ```

2. **Install development tools**:
   ```bash
   # macOS (using Homebrew)
   brew install lefthook shellcheck shfmt imagemagick poppler tesseract yq

   # Ubuntu/Debian
   sudo apt-get install shellcheck imagemagick poppler-utils tesseract-ocr

   # yq (YAML processor) - recommended binary installation:
   sudo wget https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -O /usr/local/bin/yq
   sudo chmod +x /usr/local/bin/yq

   # Alternative yq via snap (requires: sudo snap connect yq:home for home access)
   # sudo snap install yq && sudo snap connect yq:home

   # For lefthook: https://github.com/evilmartians/lefthook#installation
   ```

3. **Set up pre-push validation** (recommended):
   ```bash
   # Install Git hooks to catch issues before pushing
   ./scripts/setup-hooks.sh
   
   # Check if everything is set up correctly
   ./scripts/setup-hooks.sh --check
   ```

4. **Explore Shell Starter patterns**:
   ```bash
   # Study the framework patterns
   ./demo/hello-world --help
   ./demo/my-cli --help
   ```

### Pre-Push Validation

imgxsh uses Lefthook to run validation checks before pushing, preventing CI failures:

#### What Runs on Push
- **ShellCheck**: Validates shell script syntax and best practices
- **shfmt**: Checks code formatting consistency
- **Tests**: Runs the comprehensive test suite (84+ tests)

#### For Developers
```bash
# Set up validation (one-time)
./scripts/setup-hooks.sh

# Check status
./scripts/setup-hooks.sh --check

# Manual validation
./tests/run-tests.sh        # Run tests
shellcheck lib/*.sh bin/*   # Run ShellCheck
shfmt -d lib/*.sh bin/*     # Check formatting
```

#### Bypass (if needed)
```bash
git push --no-verify  # Skip validation (not recommended)
```

#### Detailed Setup Guide
For comprehensive setup instructions, troubleshooting, and advanced configuration, see [**docs/SETUP-HOOKS.md**](docs/SETUP-HOOKS.md).

### Development Guidelines

- **Shell Starter Integration**: Use the Shell Starter library from `./lib/main.sh`
- **Do not modify**: Shell Starter library files (they are updateable)
- **Code Quality**: All scripts must pass ShellCheck and shfmt
- **Testing**: Write Bats tests for all new functionality
- **Documentation**: Include comprehensive help text and examples

### Testing

imgxsh has a comprehensive testing framework with local and CI integration:

```bash
# Local development testing
./tests/run-tests.sh                    # Run all tests
./tests/run-tests.sh --verbose          # Detailed output
./tests/run-tests.sh --setup            # Initialize Bats framework
./tests/run-tests.sh --parallel 4       # Parallel execution (requires: brew install parallel)

# CI-optimized testing
./tests/run-tests-ci.sh                 # CI environment tests

# Individual test suites
./tests/bats-core/bin/bats tests/imgxsh-convert.bats  # Convert tool tests
./tests/bats-core/bin/bats tests/imgxsh-resize.bats   # Resize tool tests

# Local CI simulation (requires Act)
act -W .github/workflows/ci.yml --job test --pull=false

# Code quality checks
# Lint all scripts (configured via .shellcheckrc)
shellcheck bin/* lib/*.sh install.sh uninstall.sh

# Check formatting
shfmt -d bin/* lib/*.sh scripts/*.sh install.sh uninstall.sh

# Apply formatting fixes
shfmt -w bin/* lib/*.sh scripts/*.sh install.sh uninstall.sh
```

**Testing Features**:
- ✅ **30+ comprehensive tests** for imgxsh-convert; dedicated suite for imgxsh-resize
- ✅ **Cross-platform compatibility** (ImageMagick `magick`/`convert` detection)
- ✅ **CI/CD integration** with GitHub Actions
- ✅ **Local CI simulation** with Act
- ✅ **Shell Starter patterns** for reliable testing

See [`tests/README.md`](tests/README.md) for comprehensive testing documentation, including CI setup lessons learned and troubleshooting guides.

### Available Shell Starter Functions

When developing imgxsh tools, you have access to:

#### Logging Functions
- `log::info "message"` - Blue informational message
- `log::warn "message"` - Yellow warning message  
- `log::error "message"` - Red error message
- `log::success "message"` - Green success message

#### Progress Indicators
- `spinner::start "Processing images..."` - Start spinner with message
- `spinner::stop` - Stop current spinner

#### Utilities
- `get_version` - Get version from VERSION file
- Standard argument parsing with `--help`, `--version` support

## 📄 License

MIT License - see LICENSE file for details.

## 🧪 Testing

imgxsh includes comprehensive test coverage with CI/CD integration:

```bash
# Run all tests locally
./tests/run-tests.sh

# Run specific test suite
./tests/run-tests.sh tests/imgxsh-convert.bats

# Run in CI mode
./tests/run-tests-ci.sh
```

**Test Coverage**: 43 tests across imgxsh-convert (30 tests) and imgxsh-resize (13 tests) with support for both local development (with ImageMagick) and CI environments (without ImageMagick).

See `tests/README.md` for detailed testing documentation and CI integration lessons learned.

## 📚 Documentation

### Core Documentation
- **[Workflow Quick Reference](docs/WORKFLOW-QUICK-REFERENCE.md)** - Quick reference for workflow syntax and patterns
- **[Workflow Configuration Guide](docs/WORKFLOW-CONFIGURATION.md)** - Complete workflow system documentation
- **[Presets System Guide](docs/PRESETS-SYSTEM.md)** - Creating and using presets
- **[Examples Gallery](docs/EXAMPLES-GALLERY.md)** - Real-world use cases and examples

### Development Documentation
- **[Testing Documentation](tests/README.md)** - Comprehensive test setup and CI integration guide
- **[Git Hooks Setup](docs/SETUP-HOOKS.md)** - Pre-push validation setup and troubleshooting

### Framework Resources
- **[Shell Starter Framework](https://github.com/jeromecoloma/shell-starter)** - The underlying framework
- **[Shell Starter AI Guide](shell-starter-docs/ai-guide.md)** - AI development patterns
- **[Shell Starter Conventions](shell-starter-docs/conventions.md)** - Coding standards

## 🤝 Support

imgxsh is in active development. For questions or contributions:

1. Review Shell Starter examples in `./demo/` for development patterns
2. Follow Shell Starter conventions for consistency
3. Run tests locally before submitting changes: `./tests/run-tests.sh`

---

> **Framework Note**: This project is built on the [Shell Starter framework](https://github.com/jeromecoloma/shell-starter). The `./lib/` directory contains Shell Starter libraries that should not be modified directly as they are updateable through the framework's dependency management system.

