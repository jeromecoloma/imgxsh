# imgxsh-extract-excel

Extract embedded images from Excel files (.xlsx and .xls) with format conversion, naming options, and comprehensive progress tracking.

## 🎯 Overview

`imgxsh-extract-excel` extracts embedded images from Excel files, supporting both modern .xlsx format and legacy .xls format. It provides flexible naming options, format conversion, and detailed progress tracking.

## 🚀 Key Features

- **Multi-format Support**: .xlsx (modern) and .xls (legacy) Excel files
- **Flexible Naming**: Default sequential naming or preserve original names
- **Format Conversion**: Convert extracted images to different formats
- **Quality Control**: Precise quality settings for output images
- **Progress Tracking**: Real-time progress indicators and file counts
- **Preview Mode**: List embedded media without extracting
- **Dry-run Mode**: Preview operations without execution

## 📋 Usage

### Basic Syntax

```bash
imgxsh-extract-excel [OPTIONS] EXCEL_FILE OUTPUT_DIR
```

**Arguments:**
- `EXCEL_FILE` - Input Excel file path (.xlsx or .xls)
- `OUTPUT_DIR` - Output directory for extracted images

### Basic Examples

```bash
# Extract all embedded images with default naming
imgxsh-extract-excel workbook.xlsx ./extracted/

# Extract with format conversion
imgxsh-extract-excel --format jpg --quality 85 workbook.xlsx ./converted/

# Keep original embedded media names
imgxsh-extract-excel --keep-names workbook.xlsx ./extracted/

# Preview embedded media without extracting
imgxsh-extract-excel --list-only workbook.xlsx ./out
```

## 🔧 Options

### Format and Quality

| Option | Description | Default | Range |
|--------|-------------|---------|-------|
| `-f, --format FORMAT` | Output format | png | png, jpg, jpeg, webp, tiff |
| `-q, --quality QUALITY` | Quality setting | 85 | 1-100 |

### Naming Options

| Option | Description | Default | Example |
|--------|-------------|---------|---------|
| `--keep-names` | Preserve original embedded names | Sequential naming | image1.png, chart2.jpg |
| Default (no flag) | Use sequential naming | ✅ Default | image_001.png, image_002.jpg |
| `--prefix PREFIX` | Custom prefix for sequential naming | image | custom_001.png |

### Output Control

| Option | Description | Default |
|--------|-------------|---------|
| `--list-only` | Show embedded media list without extracting | Extract images |
| `--dry-run` | Preview operations without execution | Execute |
| `--verbose` | Enable detailed logging | Standard output |
| `--quiet` | Suppress non-essential output | Standard output |

## 🔄 Extraction Methods

### 1. Modern Excel (.xlsx) Files

Uses `unzip` to extract images from the Excel archive:

```bash
# Extract from .xlsx file
imgxsh-extract-excel workbook.xlsx ./extracted/

# Extract with format conversion
imgxsh-extract-excel --format jpg --quality 80 workbook.xlsx ./converted/

# Extract with custom naming
imgxsh-extract-excel --prefix "chart" workbook.xlsx ./charts/
```

**Features:**
- ✅ **High compatibility**: Works with all modern Excel files
- ✅ **Format conversion**: Convert to any supported format
- ✅ **Quality control**: Precise quality settings
- ✅ **Sequential naming**: chart_001.jpg, chart_002.jpg, etc.

### 2. Legacy Excel (.xls) Files

Uses `7z/p7zip` to extract images from Composite Document Format:

```bash
# Extract from .xls file
imgxsh-extract-excel legacy_workbook.xls ./extracted/

# Extract with format conversion
imgxsh-extract-excel --format png --quality 90 legacy_workbook.xls ./converted/
```

**Features:**
- ✅ **Legacy support**: Handles old Excel format
- ✅ **Format conversion**: Convert extracted images
- ✅ **Quality control**: Precise quality settings
- ✅ **Sequential naming**: image_001.png, image_002.png, etc.

## 📊 Examples

### Basic Extraction

```bash
# Extract all embedded images
imgxsh-extract-excel workbook.xlsx ./extracted/

# Extract with default sequential naming
imgxsh-extract-excel workbook.xlsx ./extracted/
# Output: image_001.png, image_002.jpg, image_003.png

# Extract with custom prefix
imgxsh-extract-excel --prefix "chart" workbook.xlsx ./charts/
# Output: chart_001.png, chart_002.jpg, chart_003.png
```

### Format Conversion

```bash
# Convert to JPG for web use
imgxsh-extract-excel --format jpg --quality 80 workbook.xlsx ./web_images/

# Convert to WebP for optimization
imgxsh-extract-excel --format webp --quality 85 workbook.xlsx ./optimized/

# Convert to PNG for transparency
imgxsh-extract-excel --format png --quality 100 workbook.xlsx ./transparent/

# Convert to TIFF for archival
imgxsh-extract-excel --format tiff --quality 100 workbook.xlsx ./archive/
```

### Naming Options

```bash
# Keep original embedded names
imgxsh-extract-excel --keep-names workbook.xlsx ./extracted/
# Output: sales_chart.png, quarterly_report.jpg, logo.png

# Use custom prefix
imgxsh-extract-excel --prefix "report" workbook.xlsx ./reports/
# Output: report_001.png, report_002.jpg, report_003.png

# Default sequential naming
imgxsh-extract-excel workbook.xlsx ./extracted/
# Output: image_001.png, image_002.jpg, image_003.png
```

### Preview and Information

```bash
# List embedded media without extracting
imgxsh-extract-excel --list-only workbook.xlsx ./out

# Preview with verbose output
imgxsh-extract-excel --list-only --verbose workbook.xlsx ./out

# Dry run to preview operations
imgxsh-extract-excel --dry-run --verbose workbook.xlsx ./extracted/
```

### Batch Processing

```bash
# Process multiple Excel files
for excel in *.xlsx; do
    imgxsh-extract-excel "$excel" "./extracted/${excel%.xlsx}/"
done

# Process with format conversion
for excel in *.xlsx; do
    imgxsh-extract-excel --format jpg --quality 85 "$excel" "./converted/${excel%.xlsx}/"
done

# Process with custom naming
for excel in *.xlsx; do
    imgxsh-extract-excel --prefix "${excel%.xlsx}" "$excel" "./extracted/${excel%.xlsx}/"
done
```

## 🎯 Best Practices

### Quality Settings

```bash
# Web use (balanced quality/size)
imgxsh-extract-excel --format jpg --quality 80 workbook.xlsx ./web/

# High quality (for presentations)
imgxsh-extract-excel --format png --quality 95 workbook.xlsx ./presentation/

# Archive quality (lossless)
imgxsh-extract-excel --format tiff --quality 100 workbook.xlsx ./archive/
```

### Naming Strategy

```bash
# Use descriptive prefixes for different content types
imgxsh-extract-excel --prefix "chart" charts.xlsx ./charts/
imgxsh-extract-excel --prefix "logo" branding.xlsx ./logos/
imgxsh-extract-excel --prefix "photo" photos.xlsx ./photos/

# Keep original names when they're meaningful
imgxsh-extract-excel --keep-names workbook.xlsx ./extracted/

# Use default naming for generic extraction
imgxsh-extract-excel workbook.xlsx ./extracted/
```

### Error Prevention

```bash
# Always use dry-run for large files
imgxsh-extract-excel --dry-run --verbose large_workbook.xlsx ./output/

# Enable verbose logging for debugging
imgxsh-extract-excel --verbose workbook.xlsx ./output/

# Check embedded media first
imgxsh-extract-excel --list-only workbook.xlsx ./output/
```

## 🔍 Troubleshooting

### Common Issues

**"Cannot read Excel file"**
```bash
# Check file permissions and format
file workbook.xlsx
ls -la workbook.xlsx
imgxsh-extract-excel --verbose workbook.xlsx ./output/
```

**"No images found in Excel file"**
```bash
# Check if file has embedded media
imgxsh-extract-excel --list-only workbook.xlsx ./output/

# Try with verbose output
imgxsh-extract-excel --list-only --verbose workbook.xlsx ./output/
```

**"Unsupported Excel format"**
```bash
# Check file format
file workbook.xls
file workbook.xlsx

# Ensure dependencies are installed
which unzip  # For .xlsx files
which 7z     # For .xls files
```

### Debug Mode

```bash
# Enable verbose logging for detailed information
imgxsh-extract-excel --verbose workbook.xlsx ./output/

# Use dry-run to preview operations
imgxsh-extract-excel --dry-run --verbose workbook.xlsx ./output/

# Check embedded media information
imgxsh-extract-excel --list-only --verbose workbook.xlsx ./output/
```

### Performance Optimization

```bash
# Use appropriate quality settings
imgxsh-extract-excel --format jpg --quality 80 workbook.xlsx ./web/  # Smaller files
imgxsh-extract-excel --format png --quality 95 workbook.xlsx ./high_quality/  # Better quality
imgxsh-extract-excel --format webp --quality 85 workbook.xlsx ./optimized/  # Best compression
```

## 📚 Related Tools

- **[imgxsh-resize](IMGXSH-RESIZE.md)** - Resize extracted images
- **[imgxsh-convert](IMGXSH-CONVERT.md)** - Convert extracted images
- **[imgxsh-extract-pdf](IMGXSH-EXTRACT-PDF.md)** - Extract images from PDFs

## 🛠️ Dependencies

- **unzip** - Required for .xlsx files
- **7z/p7zip** - Required for .xls files
- **ImageMagick** - Required for format conversion
- **Shell Starter Framework** - Provides logging, progress indicators, and CLI patterns

## 📄 License

MIT License - see LICENSE file for details.