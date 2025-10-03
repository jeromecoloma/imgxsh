# imgxsh-extract-pdf

Extract images from PDF documents with multiple extraction methods, page range selection, and format conversion capabilities.

## 🎯 Overview

`imgxsh-extract-pdf` extracts images from PDF documents using two methods: rasterization (converting pages to images) or embedded image extraction (extracting original embedded images). It supports page range selection, format conversion, and comprehensive progress tracking.

## 🚀 Key Features

- **Multiple Extraction Methods**: Rasterization or embedded image extraction
- **Page Range Selection**: Flexible page range specifications
- **Format Conversion**: Convert extracted images to different formats
- **Quality Control**: Precise quality settings for output images
- **Progress Tracking**: Real-time progress indicators and file counts
- **Sequential Numbering**: Consistent naming scheme with zero-padding
- **Dry-run Mode**: Preview operations without execution

## 📋 Usage

### Basic Syntax

```bash
imgxsh-extract-pdf [OPTIONS] PDF_FILE OUTPUT_DIR
```

**Arguments:**
- `PDF_FILE` - Input PDF file path
- `OUTPUT_DIR` - Output directory for extracted images

### Basic Examples

```bash
# Extract all pages as images (default: rasterize at 300 DPI, JPG quality 90)
imgxsh-extract-pdf document.pdf ./extracted/

# Extract specific page ranges
imgxsh-extract-pdf --page-range "1-5" document.pdf ./pages/

# Extract embedded images instead of rasterizing
imgxsh-extract-pdf --embedded-images document.pdf ./embedded/

# Extract with format conversion
imgxsh-extract-pdf --format png --quality 95 document.pdf ./extracted/
```

## 🔧 Options

### Extraction Method

| Option | Description | Default | Notes |
|--------|-------------|---------|-------|
| `--embedded-images` | Extract original embedded images | Rasterization | Uses pdfimages |
| Default (no flag) | Rasterize pages to images | ✅ Default | Uses ImageMagick |

### Page Range Selection

| Option | Description | Example | Notes |
|--------|-------------|---------|-------|
| `--page-range RANGE` | Specify page range to extract | `--page-range "1-5"` | Multiple formats supported |

### Page Range Formats

```bash
# Simple range
imgxsh-extract-pdf --page-range "1-5" document.pdf ./pages/

# Individual pages
imgxsh-extract-pdf --page-range "1,3,7" document.pdf ./pages/

# Open range (from page 5 to end)
imgxsh-extract-pdf --page-range "5-" document.pdf ./pages/

# Mixed range (combines ranges and individual pages)
imgxsh-extract-pdf --page-range "1-3,5,7-9" document.pdf ./pages/
```

### Format and Quality

| Option | Description | Default | Range |
|--------|-------------|---------|-------|
| `-f, --format FORMAT` | Output format | jpg | png, jpg, tiff |
| `-q, --quality QUALITY` | Quality setting | 90 | 1-100 |
| `--dpi DPI` | Rasterization DPI | 300 | 72-600 |

### Output Control

| Option | Description | Default |
|--------|-------------|---------|
| `--list-only` | Show PDF summary without extracting | Extract images |
| `--dry-run` | Preview operations without execution | Execute |
| `--verbose` | Enable detailed logging | Standard output |
| `--quiet` | Suppress non-essential output | Standard output |

## 🔄 Extraction Methods

### 1. Rasterization (Default)

Converts PDF pages to images using ImageMagick:

```bash
# Default rasterization (300 DPI, JPG quality 90)
imgxsh-extract-pdf document.pdf ./extracted/

# Custom DPI and quality
imgxsh-extract-pdf --dpi 600 --quality 95 document.pdf ./extracted/

# PNG format for transparency support
imgxsh-extract-pdf --format png --quality 100 document.pdf ./extracted/
```

**Features:**
- ✅ **High quality**: Configurable DPI (72-600)
- ✅ **Format options**: JPG, PNG, TIFF
- ✅ **Quality control**: Precise quality settings
- ✅ **Page range support**: Extract specific pages
- ✅ **Sequential numbering**: page-001.jpg, page-002.jpg, etc.

### 2. Embedded Image Extraction

Extracts original embedded images using pdfimages:

```bash
# Extract embedded images
imgxsh-extract-pdf --embedded-images document.pdf ./embedded/

# Extract with format conversion
imgxsh-extract-pdf --embedded-images --format png document.pdf ./embedded/
```

**Features:**
- ✅ **Original quality**: Preserves embedded image quality
- ✅ **Multiple images per page**: May extract many images
- ✅ **Format detection**: Automatically detects embedded formats
- ✅ **Sequential numbering**: img-001.png, img-002.png, etc.

## 📊 Examples

### Document Processing

```bash
# Extract all pages for document review
imgxsh-extract-pdf report.pdf ./pages/

# Extract specific sections
imgxsh-extract-pdf --page-range "1-10" report.pdf ./introduction/
imgxsh-extract-pdf --page-range "11-25" report.pdf ./main_content/
imgxsh-extract-pdf --page-range "26-" report.pdf ./appendices/

# Extract with high quality for printing
imgxsh-extract-pdf --dpi 600 --format tiff --quality 100 report.pdf ./print_quality/
```

### Image Extraction

```bash
# Extract embedded images from PDF
imgxsh-extract-pdf --embedded-images image_collection.pdf ./extracted_images/

# Extract with format conversion
imgxsh-extract-pdf --embedded-images --format jpg --quality 85 image_collection.pdf ./converted/

# Extract specific pages with embedded images
imgxsh-extract-pdf --embedded-images --page-range "5-10" image_collection.pdf ./selected_images/
```

### Web Preparation

```bash
# Extract pages optimized for web
imgxsh-extract-pdf --dpi 150 --format webp --quality 80 document.pdf ./web_pages/

# Extract thumbnails
imgxsh-extract-pdf --dpi 72 --format jpg --quality 70 document.pdf ./thumbnails/

# Extract high-resolution for detailed viewing
imgxsh-extract-pdf --dpi 300 --format png --quality 95 document.pdf ./high_res/
```

### Batch Processing

```bash
# Process multiple PDFs
for pdf in *.pdf; do
    imgxsh-extract-pdf "$pdf" "./extracted/${pdf%.pdf}/"
done

# Extract specific pages from multiple PDFs
for pdf in *.pdf; do
    imgxsh-extract-pdf --page-range "1-3" "$pdf" "./previews/${pdf%.pdf}/"
done
```

## 🎯 Best Practices

### Quality Settings

```bash
# Web use (balanced quality/size)
imgxsh-extract-pdf --dpi 150 --format jpg --quality 80 document.pdf ./web/

# Print quality (high resolution)
imgxsh-extract-pdf --dpi 600 --format tiff --quality 100 document.pdf ./print/

# Thumbnails (small files)
imgxsh-extract-pdf --dpi 72 --format jpg --quality 60 document.pdf ./thumbnails/
```

### Page Range Selection

```bash
# Extract specific sections
imgxsh-extract-pdf --page-range "1-5" document.pdf ./introduction/
imgxsh-extract-pdf --page-range "6-15" document.pdf ./main_content/
imgxsh-extract-pdf --page-range "16-" document.pdf ./appendices/

# Extract individual important pages
imgxsh-extract-pdf --page-range "1,5,10,15" document.pdf ./key_pages/
```

### Error Prevention

```bash
# Always use dry-run for large documents
imgxsh-extract-pdf --dry-run --verbose document.pdf ./output/

# Enable verbose logging for debugging
imgxsh-extract-pdf --verbose document.pdf ./output/

# Check PDF information first
imgxsh-extract-pdf --list-only document.pdf ./output/
```

## 🔍 Troubleshooting

### Common Issues

**"Cannot read PDF file"**
```bash
# Check file permissions and format
file document.pdf
ls -la document.pdf
imgxsh-extract-pdf --verbose document.pdf ./output/
```

**"No images found"**
```bash
# Try embedded image extraction
imgxsh-extract-pdf --embedded-images document.pdf ./output/

# Check PDF content
imgxsh-extract-pdf --list-only document.pdf ./output/
```

**"Page range out of bounds"**
```bash
# Check PDF page count first
imgxsh-extract-pdf --list-only document.pdf ./output/

# Use valid page ranges
imgxsh-extract-pdf --page-range "1-5" document.pdf ./output/
```

### Debug Mode

```bash
# Enable verbose logging for detailed information
imgxsh-extract-pdf --verbose document.pdf ./output/

# Use dry-run to preview operations
imgxsh-extract-pdf --dry-run --verbose document.pdf ./output/

# Check PDF information
imgxsh-extract-pdf --list-only --verbose document.pdf ./output/
```

### Performance Optimization

```bash
# Use appropriate DPI for your use case
imgxsh-extract-pdf --dpi 150 document.pdf ./web/  # Web use
imgxsh-extract-pdf --dpi 300 document.pdf ./standard/  # Standard quality
imgxsh-extract-pdf --dpi 600 document.pdf ./print/  # Print quality

# Choose appropriate format
imgxsh-extract-pdf --format jpg document.pdf ./web/  # Smaller files
imgxsh-extract-pdf --format png document.pdf ./transparent/  # Transparency support
imgxsh-extract-pdf --format tiff document.pdf ./archive/  # High quality
```

## 📚 Related Tools

- **[imgxsh-resize](IMGXSH-RESIZE.md)** - Resize extracted images
- **[imgxsh-convert](IMGXSH-CONVERT.md)** - Convert extracted images
- **[imgxsh-extract-excel](IMGXSH-EXTRACT-EXCEL.md)** - Extract images from Excel files

## 🛠️ Dependencies

- **ImageMagick** - Required for rasterization
- **pdfimages (poppler-utils)** - Required for embedded image extraction
- **pdfinfo (poppler-utils)** - Required for PDF information
- **Shell Starter Framework** - Provides logging, progress indicators, and CLI patterns

## 📄 License

MIT License - see LICENSE file for details.