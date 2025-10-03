# imgxsh-convert

Convert images between formats with quality control and comprehensive batch processing capabilities.

## 🎯 Overview

`imgxsh-convert` provides format conversion between PNG, JPG, WebP, TIFF, and BMP with precise quality control and comprehensive batch processing capabilities.

## 🚀 Key Features

- **Single File Processing**: Convert individual images with precise control
- **Batch Directory Processing**: Process entire directory trees recursively
- **Structure Preservation**: Maintains relative directory structure in output
- **Progress Tracking**: Real-time progress indicators with file counts
- **Format Conversion**: Support for PNG, JPG, WebP, TIFF, BMP
- **Quality Control**: Precise quality settings for lossy formats
- **Error Handling**: Continues processing on individual file failures

### Basic Usage

```bash
imgxsh-convert [OPTIONS] INPUT OUTPUT
```

**Arguments:**
- `INPUT` - Input image file path
- `OUTPUT` - Output image file path (format determined by extension)

### Examples

```bash
# Basic format conversion
imgxsh-convert photo.png photo.jpg

# Convert with quality control
imgxsh-convert --quality 95 image.jpg image.webp

# Convert with format override
imgxsh-convert --format png --backup document.pdf document.png

# Preview operations without execution
imgxsh-convert --dry-run --verbose input.tiff output.jpg
```

### Options

| Option | Description | Default | Range |
|--------|-------------|---------|-------|
| `-q, --quality N` | Set quality (1-100) | Format default | 1-100 |
| `-f, --format FMT` | Output format | Auto-detect | png, jpg, webp, tiff, bmp |
| `--backup` | Create backup of original file | No backup | - |
| `--overwrite` | Overwrite output file if it exists | Skip existing | - |
| `--verbose` | Enable verbose output | Standard output | - |
| `--dry-run` | Show what would be done without executing | Execute | - |

### Supported Formats

| Format | Quality Support | Default Quality | Notes |
|--------|----------------|-----------------|-------|
| PNG | ❌ Lossless | N/A | Good for transparency |
| JPG/JPEG | ✅ Lossy | 85 | Good for photographs |
| WebP | ✅ Lossy | 90 | Excellent compression |
| TIFF | ❌ Lossless | N/A | High-quality format |
| BMP | ❌ Lossless | N/A | Uncompressed bitmap |

## 🔄 Batch Processing

### Directory Processing

When you provide a directory as input, `imgxsh-convert` automatically processes all image files recursively:

```bash
# Convert all images in directory to WebP format
imgxsh-convert --format webp --quality 90 photos/ web_photos/

# Convert with backup and overwrite control
imgxsh-convert --format webp --backup --overwrite photos/ optimized/

# Preview batch operations
imgxsh-convert --dry-run --verbose --format webp photos/ converted/
```

### Batch Processing Features

| Feature | Description | Example |
|---------|-------------|---------|
| **Directory Processing** | Processes entire directory trees recursively | `imgxsh-convert ./photos/ ./converted/` |
| **Structure Preservation** | Maintains relative directory structure | `photos/vacation/beach.jpg` → `converted/vacation/beach.webp` |
| **Progress Tracking** | Shows `[X/Y] Processing: filename` for each file | `[3/15] Processing: vacation/beach.jpg` |
| **Error Handling** | Continues processing even if individual files fail | Reports `Processed: 14 files, Failed: 1 files` |
| **Backup Support** | Creates timestamped backups of original files | `image.jpg.backup.20231003_143022` |
| **Overwrite Control** | Skip or replace existing output files | `--overwrite` to replace existing files |

## 🔧 Advanced Features

### Directory Structure Preservation

```bash
# Input structure:
# photos/
# ├── vacation/
# │   ├── beach1.jpg
# │   └── beach2.jpg
# └── family/
#     └── group.jpg

# Command:
imgxsh-convert --format webp ./photos/ ./converted/

# Output structure:
# converted/
# ├── vacation/
# │   ├── beach1.webp
# │   └── beach2.webp
# └── family/
#     └── group.webp
```

### Progress Tracking

```bash
# Batch processing provides detailed progress information
imgxsh-convert --format webp ./photos/ ./converted/

# Output shows:
# Found 15 image files to process
# [1/15] Processing: vacation/beach1.jpg
# [2/15] Processing: vacation/beach2.jpg
# [3/15] Processing: family/group.jpg
# ...
# Processed: 15 files, Failed: 0 files
```

### Error Handling

```bash
# The tool continues processing even when individual files fail
imgxsh-convert --format webp ./photos/ ./converted/

# If one file fails, processing continues with the rest
# [5/15] Processing: corrupted_image.jpg
# Error: Cannot read image dimensions: corrupted_image.jpg
# [6/15] Processing: next_image.jpg
# ...
# Processed: 14 files, Failed: 1 files
```

## 📊 Examples

### Web Optimization

```bash
# Convert to WebP for web use
imgxsh-convert --format webp --quality 85 --parallel 8 ./photos/ ./web_photos/

# Convert to optimized JPG
imgxsh-convert --format jpg --quality 80 --parallel 6 ./photos/ ./web_jpg/

# Convert to PNG for transparency
imgxsh-convert --format png ./transparent_images/ ./web_png/
```

### Archive Preparation

```bash
# Convert to high-quality TIFF for archival
imgxsh-convert --format tiff --quality 100 ./photos/ ./archive/

# Convert to lossless PNG
imgxsh-convert --format png ./photos/ ./lossless/

# Convert with backup for safety
imgxsh-convert --format webp --backup ./photos/ ./converted/
```

### Selective Processing

```bash
# Convert only large files
imgxsh-convert --format webp --pattern "*.tiff" ./images/ ./converted/

# Convert only specific directories
imgxsh-convert --format webp ./photos/vacation/ ./web_vacation/
imgxsh-convert --format webp ./photos/family/ ./web_family/

# Convert with different quality settings
imgxsh-convert --format jpg --quality 95 ./professional/ ./high_quality/
imgxsh-convert --format jpg --quality 75 ./casual/ ./optimized/
```

### Large Dataset Processing

```bash
# Process large datasets with high parallelism
imgxsh-convert --format webp --parallel 16 ./large_dataset/ ./converted/

# Use progress tracking for long operations
imgxsh-convert --progress --format webp --parallel 12 ./massive_dataset/ ./converted/

# Dry run first to estimate processing time
imgxsh-convert --dry-run --format webp ./large_dataset/ ./converted/
```

## 🎯 Best Practices

### Performance Optimization

```bash
# Choose appropriate parallel job count
imgxsh-convert --parallel 8 ./photos/ ./converted/  # Good for most systems
imgxsh-convert --parallel 4 ./photos/ ./converted/  # Conservative
imgxsh-convert --parallel 12 ./photos/ ./converted/  # High-performance systems

# Use appropriate quality settings
imgxsh-convert --format webp --quality 85 ./photos/ ./web_photos/  # Balanced
imgxsh-convert --format webp --quality 90 ./photos/ ./high_quality/  # High quality
imgxsh-convert --format webp --quality 75 ./photos/ ./optimized/  # Smaller files
```

### Error Prevention

```bash
# Always use dry-run for large batches
imgxsh-convert --dry-run --format webp ./large_dataset/ ./converted/

# Enable verbose logging for debugging
imgxsh-convert --verbose --format webp ./photos/ ./converted/

# Use backup for important files
imgxsh-convert --backup --format webp ./important_photos/ ./converted/
```

### Quality Control

```bash
# Test quality settings on a small batch first
imgxsh-convert --format webp --quality 85 ./test_photos/ ./test_output/

# Use different quality settings for different use cases
imgxsh-convert --format jpg --quality 95 ./professional/ ./high_quality/
imgxsh-convert --format jpg --quality 80 ./web_ready/ ./optimized/
imgxsh-convert --format jpg --quality 60 ./thumbnails/ ./small_files/
```

## 🔍 Troubleshooting

### Common Issues

**"No image files found matching pattern"**
```bash
# Check file extensions and pattern
ls -la ./photos/
imgxsh-convert --pattern "*.jpg" --verbose ./photos/ ./output/
```

**"Cannot read image information"**
```bash
# File may be corrupted or not a valid image
file problematic_image.jpg
imgxsh-convert --verbose ./photos/ ./output/
```

**"Output file exists"**
```bash
# Use --overwrite to replace existing files
imgxsh-convert --overwrite --format webp ./photos/ ./output/
```

### Debug Mode

```bash
# Enable verbose logging for detailed information
imgxsh-convert --verbose --format webp ./photos/ ./output/

# Use dry-run to preview operations
imgxsh-convert --dry-run --verbose --format webp ./photos/ ./output/

# Check progress with progress bar
imgxsh-convert --progress --verbose --format webp ./photos/ ./output/
```

## 📚 Related Tools

- **[imgxsh-resize](IMGXSH-RESIZE.md)** - Resize images with batch processing
- **[imgxsh-extract-pdf](IMGXSH-EXTRACT-PDF.md)** - Extract images from PDFs
- **[imgxsh-extract-excel](IMGXSH-EXTRACT-EXCEL.md)** - Extract images from Excel files

## 🛠️ Dependencies

- **ImageMagick** - Required for all image processing operations
- **Shell Starter Framework** - Provides logging, progress indicators, and CLI patterns

## 📄 License

MIT License - see LICENSE file for details.