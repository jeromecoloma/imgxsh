# imgxsh

A comprehensive CLI image processing tool that extracts, converts, resizes, and processes images from various sources (PDFs, Excel files, individual images) through configurable workflows.

## 🚀 Overview

imgxsh is a workflow-driven image processing CLI tool built on the [Shell Starter framework](https://github.com/jeromecoloma/shell-starter) that provides both workflow orchestration and individual processing commands.

### Key Features

- **Multi-source Extraction**: Extract images from PDFs, Excel files, and process individual images
- **Workflow Orchestration**: YAML-based workflow configuration with conditional logic
- **Batch Processing**: Parallel processing with progress tracking
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

### Basic Usage

```bash
# Extract images from PDF and convert to web format
imgxsh --workflow pdf-to-web document.pdf

# Use built-in presets
imgxsh --preset web-thumbnails *.jpg

# Preview operations without execution
imgxsh --config custom.yaml --dry-run ./images/
```

## 🛠️ Installation

> **Note**: imgxsh is currently in development. Installation instructions will be available once the first release is ready.

```bash
# Future installation method
curl -fsSL https://github.com/jeromecoloma/imgxsh/install.sh | bash
# or
./install.sh --prefix ~/.local/bin
```

## 📋 Available Commands

### Main Binary
- `imgxsh` - Main workflow orchestrator with subcommand support

### Individual Tools
- `imgxsh-convert` - Convert images between formats
- `imgxsh-resize` - Resize images with aspect ratio control
  - Pixel/percentage sizing, batch directories, smart no-upscale (`--allow-upscale` to override), `--max-file-size`
- `imgxsh-extract-pdf` - Extract images from PDF documents
  - Default: rasterize one image per page (ImageMagick, density 300, quality 90)
  - `--embedded-images` to extract original embedded raster images (pdfimages)
  - `--list-only` shows both Pages (via `pdfinfo`) and Embedded images (via `pdfimages`)
  - Advanced page range selection: simple ranges (`1-5`), individual pages (`1,3,7`), open ranges (`5-`), mixed ranges (`1-3,5,7-9`)
  - Sequential output numbering preserves naming scheme while skipping non-selected pages
  - Format conversion, metadata preservation, template-based naming, quality control, dry-run mode
- `imgxsh-extract-excel` - Extract images from Excel files
  - .xlsx support via `unzip` (lists and extracts `xl/media/*`)
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

### Example Workflow

```yaml
name: pdf-to-web
description: "Extract PDF images and optimize for web"
version: "1.0"

settings:
  output_dir: "./output/pdf-web"
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

hooks:
  on_success:
    - echo "Gallery created successfully at: {output_dir}"
    - echo "Thumbnails: {output_dir}/thumbs/"
    - echo "Full images: {output_dir}/full/"
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
   sudo apt-get install shellcheck imagemagick poppler-utils tesseract-ocr yq
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

