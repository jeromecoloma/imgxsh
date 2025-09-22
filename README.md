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
- `imgxsh-extract-excel` - Extract images from Excel files
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
│   ├── fixtures/      # Test data (images, PDFs, Excel files)
│   └── bats-*/        # Bats testing framework and libraries
├── .github/workflows/  # GitHub Actions CI/CD workflows
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

## 🔧 Configuration

imgxsh uses YAML-based workflow configuration files:

### Default Config Location
- `~/.imgxsh.yaml` - Main configuration file
- Override with `--workflow-config` parameter

### Example Workflow
```yaml
workflows:
  pdf-to-web:
    description: "Extract PDF images and optimize for web"
    steps:
      - name: extract_images
        type: pdf_extract
        params:
          input: "{workflow_input}"
          output_dir: "{temp_dir}/extracted"
          
      - name: conditional_resize
        type: resize
        condition: "image_count > 10"
        params:
          width: 800
          height: 600
          quality: 85
        else:
          width: 1200
          height: 900
          quality: 90
```

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
   brew install shellcheck shfmt imagemagick poppler tesseract

   # Ubuntu/Debian
   sudo apt-get install shellcheck imagemagick poppler-utils tesseract-ocr
   ```

3. **Explore Shell Starter patterns**:
   ```bash
   # Study the framework patterns
   ./demo/hello-world --help
   ./demo/my-cli --help
   ```

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

## 📚 Resources

- **[Product Requirements Document](/.ai-workflow/state/requirements.md)** - Detailed project specifications
- **[Shell Starter Framework](https://github.com/jeromecoloma/shell-starter)** - The underlying framework
- **[Shell Starter Documentation](shell-starter-docs/)** - Development patterns and conventions (temporary)

## 🤝 Support

imgxsh is in active development. For questions or contributions:

1. Check the [PRD](/.ai-workflow/state/requirements.md) for project details
2. Review Shell Starter examples in `./demo/` for development patterns
3. Follow Shell Starter conventions for consistency

---

> **Framework Note**: This project is built on the [Shell Starter framework](https://github.com/jeromecoloma/shell-starter). The `./lib/` directory contains Shell Starter libraries that should not be modified directly as they are updateable through the framework's dependency management system.

