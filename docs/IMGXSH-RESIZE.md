# imgxsh-resize

Resize images with aspect ratio preservation, quality control, and comprehensive batch processing capabilities.

## 🎯 Overview

`imgxsh-resize` is the most powerful batch processing tool in the imgxsh suite, capable of processing entire directory trees recursively while preserving structure and providing detailed progress tracking.

## 🚀 Key Features

- **Full Directory Processing**: Process entire directory trees recursively
- **Structure Preservation**: Maintains relative directory structure in output
- **Parallel Processing**: Built-in parallel execution for faster processing
- **Progress Tracking**: Real-time progress indicators with file counts
- **Comprehensive Options**: All resize options work in batch mode
- **Error Handling**: Continues processing on individual file failures
- **Format Conversion**: Convert formats while resizing
- **Quality Control**: Precise quality settings for lossy formats

## 📋 Usage

### Basic Syntax

```bash
imgxsh-resize [OPTIONS] INPUT OUTPUT
```

**Arguments:**
- `INPUT` - Input image file or directory
- `OUTPUT` - Output image file or directory

### Single File Processing

```bash
# Resize to specific width (maintains aspect ratio)
imgxsh-resize --width 800 input.jpg output.jpg

# Resize to specific height (maintains aspect ratio)  
imgxsh-resize --height 600 input.png output.png

# Resize to specific dimensions
imgxsh-resize --size 800x600 input.jpg output.jpg

# Resize with percentage (uniform)
imgxsh-resize --size 50% input.jpg output.jpg

# Resize with dual percentage
imgxsh-resize --size 120%x80% input.jpg output.jpg
```

### Batch Directory Processing

```bash
# Basic batch resize (preserves directory structure)
imgxsh-resize --width 800 ./photos/ ./resized/

# Batch resize with format conversion and quality control
imgxsh-resize --width 800 --format webp --quality 85 ./images/ ./web_images/

# Batch resize with constraints and aspect ratio
imgxsh-resize --max-width 1920 --max-height 1080 --aspect-ratio 16:9 ./photos/ ./gallery/

# Batch resize with crop and background handling
imgxsh-resize --crop --size 800x600 --background white ./transparent/ ./cropped/

# Dry run to preview batch operations
imgxsh-resize --dry-run --verbose --width 800 ./photos/ ./resized/
```

## 🔧 Options

### Size Control

| Option | Description | Example |
|--------|-------------|---------|
| `-w, --width WIDTH` | Target width in pixels | `--width 800` |
| `--height HEIGHT` | Target height in pixels | `--height 600` |
| `-s, --size SIZE` | Target size specification | `--size 800x600` |
| `--max-width WIDTH` | Maximum width constraint | `--max-width 1200` |
| `--max-height HEIGHT` | Maximum height constraint | `--max-height 800` |
| `--min-width WIDTH` | Minimum width constraint | `--min-width 200` |
| `--min-height HEIGHT` | Minimum height constraint | `--min-height 200` |

### Size Specifications

The `--size` option supports multiple formats:

```bash
# Exact dimensions
imgxsh-resize --size 800x600 input.jpg output.jpg

# Width only (maintains aspect ratio)
imgxsh-resize --size 800x input.jpg output.jpg

# Height only (maintains aspect ratio)
imgxsh-resize --size x600 input.jpg output.jpg

# Percentage (uniform scaling)
imgxsh-resize --size 50% input.jpg output.jpg

# Dual percentage (width and height)
imgxsh-resize --size 120%x80% input.jpg output.jpg
```

### Resize Modes

| Option | Description | Behavior |
|--------|-------------|----------|
| `--fit` | Fit within dimensions (default) | Maintains aspect ratio, fits within bounds |
| `--fill` | Fill dimensions (crop to fit) | Maintains aspect ratio, crops to fill |
| `--stretch` | Stretch to exact dimensions | Ignores aspect ratio completely |
| `--crop` | Crop to exact dimensions | Crops to exact size |

### Aspect Ratio Control

```bash
# Force specific aspect ratio
imgxsh-resize --aspect-ratio 16:9 --width 1920 input.jpg output.jpg

# Crop with gravity positioning
imgxsh-resize --crop --size 800x600 --crop-gravity northeast input.jpg output.jpg

# Crop with specific position (top-left corner)
imgxsh-resize --crop --size 800x600 --crop-x 0 --crop-y 0 input.jpg output.jpg
```

### Quality and Format

| Option | Description | Default | Range |
|--------|-------------|---------|-------|
| `-q, --quality QUAL` | Quality setting | 85 | 1-100 |
| `-f, --format FORMAT` | Output format | auto | png, jpg, webp, tiff, bmp |
| `--background COLOR` | Background color for transparent images | transparent | white, black, #FF0000 |

### Batch Processing Options

| Option | Description | Default |
|--------|-------------|---------|
| `--overwrite` | Overwrite existing output files | Skip existing |
| `--backup` | Create backup of original file | No backup |
| `--dry-run` | Preview operations without executing | Execute |
| `--verbose` | Enable detailed logging | Standard output |
| `--quiet` | Suppress non-essential output | Standard output |

## 🔄 Batch Processing Features

### Directory Structure Preservation

When processing directories, `imgxsh-resize` maintains the relative directory structure:

```bash
# Input structure:
# photos/
# ├── vacation/
# │   ├── beach1.jpg
# │   └── beach2.jpg
# └── family/
#     └── group.jpg

# Command:
imgxsh-resize --width 800 ./photos/ ./resized/

# Output structure:
# resized/
# ├── vacation/
# │   ├── beach1.jpg
# │   └── beach2.jpg
# └── family/
#     └── group.jpg
```

### Progress Tracking

Batch processing provides detailed progress information:

```
Found 15 image files to process
[1/15] Processing: vacation/beach1.jpg
[2/15] Processing: vacation/beach2.jpg
[3/15] Processing: family/group.jpg
...
Processed: 15 files, Failed: 0 files
```

### Error Handling

The tool continues processing even when individual files fail:

```bash
# If one file fails, processing continues with the rest
[5/15] Processing: corrupted_image.jpg
Error: Cannot read image dimensions: corrupted_image.jpg
[6/15] Processing: next_image.jpg
...
Processed: 14 files, Failed: 1 files
```

## 📊 Examples

### Web Gallery Preparation

```bash
# Create web-optimized images
imgxsh-resize --width 1200 --format webp --quality 85 ./photos/ ./web_gallery/

# Create thumbnails
imgxsh-resize --width 300 --format jpg --quality 80 ./photos/ ./thumbnails/

# Create multiple sizes for responsive design
imgxsh-resize --width 800 --format webp --quality 85 ./photos/ ./web_800/
imgxsh-resize --width 1200 --format webp --quality 85 ./photos/ ./web_1200/
imgxsh-resize --width 1920 --format webp --quality 85 ./photos/ ./web_1920/
```

### Social Media Optimization

```bash
# Instagram square format (1080x1080)
imgxsh-resize --crop --size 1080x1080 --crop-gravity center ./photos/ ./instagram/

# Facebook cover format (1200x630)
imgxsh-resize --crop --size 1200x630 --crop-gravity center ./photos/ ./facebook/

# Twitter header format (1500x500)
imgxsh-resize --crop --size 1500x500 --crop-gravity center ./photos/ ./twitter/
```

### Print Preparation

```bash
# High-resolution print images (300 DPI equivalent)
imgxsh-resize --width 2400 --format tiff --quality 100 ./photos/ ./print/

# Standard print sizes
imgxsh-resize --size 8x10 --format tiff --quality 100 ./photos/ ./print_8x10/
imgxsh-resize --size 11x14 --format tiff --quality 100 ./photos/ ./print_11x14/
```

### Transparent Image Handling

```bash
# Add white background to transparent PNGs
imgxsh-resize --width 800 --background white ./transparent/ ./opaque/

# Add black background
imgxsh-resize --width 800 --background black ./transparent/ ./opaque/

# Custom background color
imgxsh-resize --width 800 --background "#FF0000" ./transparent/ ./opaque/
```

### Constraint-Based Resizing

```bash
# Resize to fit within bounds (no upscaling)
imgxsh-resize --max-width 1200 --max-height 800 ./photos/ ./constrained/

# Resize to meet minimum bounds (with upscaling)
imgxsh-resize --min-width 800 --min-height 600 ./photos/ ./minimum/

# Combined constraints
imgxsh-resize --min-width 400 --max-width 1200 --min-height 300 --max-height 800 ./photos/ ./combined/
```

## 🎯 Best Practices

### Performance Optimization

```bash
# Use appropriate quality settings for your use case
imgxsh-resize --width 1200 --quality 85 ./photos/ ./web_photos/  # Balanced quality/size
imgxsh-resize --width 1200 --quality 95 ./photos/ ./high_quality/  # High quality
imgxsh-resize --width 1200 --quality 75 ./photos/ ./optimized/  # Smaller files

# Choose the right format
imgxsh-resize --width 1200 --format webp ./photos/ ./web_photos/  # Best compression
imgxsh-resize --width 1200 --format jpg ./photos/ ./compatible/  # Universal compatibility
imgxsh-resize --width 1200 --format png ./photos/ ./transparent/  # Transparency support
```

### Error Prevention

```bash
# Always use dry-run for large batches
imgxsh-resize --dry-run --verbose --width 800 ./large_dataset/ ./output/

# Enable verbose logging for debugging
imgxsh-resize --verbose --width 800 ./photos/ ./resized/

# Use backup for important files
imgxsh-resize --backup --width 800 ./important_photos/ ./resized/
```

### Directory Management

```bash
# Create organized output structure
imgxsh-resize --width 800 ./photos/vacation/ ./web_gallery/vacation/
imgxsh-resize --width 800 ./photos/family/ ./web_gallery/family/

# Process different directories with different settings
imgxsh-resize --width 1200 --quality 90 ./professional/ ./high_quality/
imgxsh-resize --width 800 --quality 80 ./casual/ ./web_ready/
```

## 🔍 Troubleshooting

### Common Issues

**"No image files found in directory"**
```bash
# Check file extensions and permissions
ls -la ./photos/
imgxsh-resize --verbose --width 800 ./photos/ ./output/
```

**"Cannot read image dimensions"**
```bash
# File may be corrupted or not a valid image
file problematic_image.jpg
imgxsh-resize --verbose --width 800 ./photos/ ./output/
```

**"Output file exists"**
```bash
# Use --overwrite to replace existing files
imgxsh-resize --overwrite --width 800 ./photos/ ./output/
```

### Debug Mode

```bash
# Enable verbose logging for detailed information
imgxsh-resize --verbose --width 800 ./photos/ ./output/

# Use dry-run to preview operations
imgxsh-resize --dry-run --verbose --width 800 ./photos/ ./output/
```

## 📚 Related Tools

- **[imgxsh-convert](IMGXSH-CONVERT.md)** - Single file format conversion
- **[imgxsh-batch-convert](IMGXSH-BATCH-CONVERT.md)** - Batch format conversion
- **[imgxsh-extract-pdf](IMGXSH-EXTRACT-PDF.md)** - Extract images from PDFs
- **[imgxsh-extract-excel](IMGXSH-EXTRACT-EXCEL.md)** - Extract images from Excel files

## 🛠️ Dependencies

- **ImageMagick** - Required for all image processing operations
- **Shell Starter Framework** - Provides logging, progress indicators, and CLI patterns

## 📄 License

MIT License - see LICENSE file for details.