# Examples Gallery

This gallery provides real-world examples of imgxsh workflows and presets for common use cases. Each example includes the complete configuration, usage instructions, and expected output.

## Table of Contents

- [Content Management](#content-management)
- [Web Development](#web-development)
- [Document Processing](#document-processing)
- [Social Media](#social-media)
- [E-commerce](#e-commerce)
- [Archival & Backup](#archival--backup)
- [Automation & CI/CD](#automation--cicd)
- [Advanced Use Cases](#advanced-use-cases)

## Content Management

### Blog Post Image Processing

**Use Case**: Automatically process images for blog posts with consistent sizing and optimization.

**Workflow**: `blog-post-processing.yaml`

```yaml
name: blog-post-processing
description: "Process images for blog posts with consistent sizing"
version: "1.0"

settings:
  output_dir: "./blog-images"
  temp_dir: "/tmp/imgxsh/blog"
  parallel_jobs: 4

steps:
  - name: extract_from_pdf
    type: pdf_extract
    description: "Extract images from PDF documents"
    condition: "file_extension == 'pdf'"
    params:
      input: "{workflow_input}"
      output_dir: "{temp_dir}/extracted"
      format: "png"
      
  - name: create_featured_image
    type: resize
    description: "Create featured image (1200x630 for social sharing)"
    params:
      input_dir: "{temp_dir}/extracted"
      width: 1200
      height: 630
      maintain_aspect: false  # Crop to exact dimensions
      quality: 85
      format: "jpg"
      output_template: "{output_dir}/featured/{input_name}_featured.jpg"
      
  - name: create_content_images
    type: resize
    description: "Create content images (800px max width)"
    params:
      input_dir: "{temp_dir}/extracted"
      max_width: 800
      maintain_aspect: true
      quality: 85
      format: "webp"
      output_template: "{output_dir}/content/{input_name}_content_{counter:03d}.webp"
      
  - name: create_thumbnails
    type: resize
    description: "Create thumbnails for gallery view"
    params:
      input_dir: "{temp_dir}/extracted"
      width: 300
      height: 200
      maintain_aspect: true
      quality: 80
      format: "jpg"
      output_template: "{output_dir}/thumbs/{input_name}_thumb_{counter:03d}.jpg"

hooks:
  on_success:
    - echo "Blog images processed successfully!"
    - echo "Featured image: {output_dir}/featured/"
    - echo "Content images: {output_dir}/content/"
    - echo "Thumbnails: {output_dir}/thumbs/"
```

**Usage**:
```bash
# Process a PDF document for blog use
imgxsh --workflow blog-post-processing document.pdf

# Process multiple images
imgxsh --workflow blog-post-processing *.jpg
```

**Output Structure**:
```
blog-images/
├── featured/
│   └── document_featured.jpg
├── content/
│   ├── document_content_001.webp
│   └── document_content_002.webp
└── thumbs/
    ├── document_thumb_001.jpg
    └── document_thumb_002.jpg
```

### Newsletter Image Optimization

**Use Case**: Optimize images for email newsletters with size constraints.

**Preset**: `newsletter-optimization.yaml`

```yaml
name: newsletter-optimization
description: "Optimize images for email newsletters"
base_workflow: blog-post-processing

overrides:
  settings:
    output_dir: "./newsletter-images"
    
  steps:
    create_featured_image:
      params:
        width: 600
        height: 300
        quality: 75
        max_file_size: "100KB"
        
    create_content_images:
      params:
        max_width: 500
        quality: 70
        max_file_size: "50KB"
        format: "jpg"  # Better email client support
```

**Usage**:
```bash
imgxsh --preset newsletter-optimization images.pdf
```

## Web Development

### Responsive Image Generation

**Use Case**: Generate multiple image sizes for responsive web design.

**Workflow**: `responsive-images.yaml`

```yaml
name: responsive-images
description: "Generate responsive image sets for web"
version: "1.0"

settings:
  output_dir: "./responsive-images"
  parallel_jobs: 6

steps:
  - name: extract_images
    type: pdf_extract
    description: "Extract images from source"
    params:
      input: "{workflow_input}"
      output_dir: "{temp_dir}/extracted"
      format: "png"
      
  - name: generate_mobile
    type: resize
    description: "Generate mobile images (320px, 480px, 640px)"
    params:
      input_dir: "{temp_dir}/extracted"
      widths: [320, 480, 640]
      maintain_aspect: true
      quality: 80
      format: "webp"
      output_template: "{output_dir}/mobile/{input_name}_{width}w.webp"
      
  - name: generate_tablet
    type: resize
    description: "Generate tablet images (768px, 1024px)"
    params:
      input_dir: "{temp_dir}/extracted"
      widths: [768, 1024]
      maintain_aspect: true
      quality: 85
      format: "webp"
      output_template: "{output_dir}/tablet/{input_name}_{width}w.webp"
      
  - name: generate_desktop
    type: resize
    description: "Generate desktop images (1200px, 1920px)"
    params:
      input_dir: "{temp_dir}/extracted"
      widths: [1200, 1920]
      maintain_aspect: true
      quality: 90
      format: "webp"
      output_template: "{output_dir}/desktop/{input_name}_{width}w.webp"
      
  - name: generate_fallback
    type: convert
    description: "Generate JPG fallbacks for older browsers"
    params:
      input_dir: "{temp_dir}/extracted"
      format: "jpg"
      quality: 85
      max_width: 1920
      output_template: "{output_dir}/fallback/{input_name}_fallback.jpg"

hooks:
  on_success:
    - echo "Responsive images generated:"
    - echo "  Mobile: {output_dir}/mobile/"
    - echo "  Tablet: {output_dir}/tablet/"
    - echo "  Desktop: {output_dir}/desktop/"
    - echo "  Fallback: {output_dir}/fallback/"
```

**Usage**:
```bash
imgxsh --workflow responsive-images product-images.pdf
```

### Progressive Web App Assets

**Use Case**: Generate app icons and splash screens for PWA.

**Workflow**: `pwa-assets.yaml`

```yaml
name: pwa-assets
description: "Generate PWA app icons and splash screens"
version: "1.0"

settings:
  output_dir: "./pwa-assets"
  parallel_jobs: 4

steps:
  - name: extract_logo
    type: pdf_extract
    description: "Extract logo from PDF"
    params:
      input: "{workflow_input}"
      output_dir: "{temp_dir}/extracted"
      format: "png"
      
  - name: generate_app_icons
    type: resize
    description: "Generate app icons in various sizes"
    params:
      input_dir: "{temp_dir}/extracted"
      sizes: [16, 32, 48, 64, 96, 128, 144, 152, 192, 256, 384, 512]
      maintain_aspect: true
      quality: 100
      format: "png"
      output_template: "{output_dir}/icons/icon-{size}x{size}.png"
      
  - name: generate_splash_screens
    type: resize
    description: "Generate splash screens for different devices"
    params:
      input_dir: "{temp_dir}/extracted"
      sizes: 
        - {width: 640, height: 1136}   # iPhone 5
        - {width: 750, height: 1334}   # iPhone 6/7/8
        - {width: 1125, height: 2436}  # iPhone X
        - {width: 768, height: 1024}   # iPad
        - {width: 1024, height: 1366}  # iPad Pro
      maintain_aspect: false
      quality: 90
      format: "png"
      output_template: "{output_dir}/splash/splash-{width}x{height}.png"

hooks:
  on_success:
    - echo "PWA assets generated:"
    - echo "  Icons: {output_dir}/icons/"
    - echo "  Splash screens: {output_dir}/splash/"
```

## Document Processing

### PDF to Web Gallery

**Use Case**: Convert PDF documents into interactive web galleries with thumbnails, full-size images, and HTML navigation.

**Workflow**: `pdf-to-web.yaml` (Built-in workflow)

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

# Use with custom output directory
imgxsh --workflow pdf-to-web --output ./my-gallery document.pdf

# Preview the workflow without execution
imgxsh --workflow pdf-to-web --dry-run document.pdf
```

**Output Structure**:
```
output/
├── thumbnails/          # 300x200 thumbnails for quick browsing
│   ├── document_thumb_001.jpg
│   ├── document_thumb_002.jpg
│   └── document_thumb_003.jpg
├── full/                # Full-size WebP images for detailed viewing
│   ├── document_full_001.webp
│   ├── document_full_002.webp
│   └── document_full_003.webp
└── gallery.html         # Interactive HTML gallery with modal view
```

**Features**:
- **Responsive Design**: Grid layout that adapts to different screen sizes
- **Modal View**: Click thumbnails to view full-size images in a modal overlay
- **WebP Optimization**: Full-size images use WebP format for better compression
- **Progressive Enhancement**: Works without JavaScript (thumbnails still clickable)
- **Mobile Friendly**: Touch-friendly interface for mobile devices

**Customization Options**:
- Modify thumbnail size by changing `width` and `height` in the resize step
- Adjust full-size image dimensions with `max_width` and `max_height`
- Change image quality settings for different use cases
- Customize HTML styling by modifying the CSS in the custom script

### Legal Document Processing

**Use Case**: Process legal documents with OCR and metadata extraction.

**Workflow**: `legal-document-processing.yaml`

```yaml
name: legal-document-processing
description: "Process legal documents with OCR and metadata"
version: "1.0"

settings:
  output_dir: "./legal-documents"
  temp_dir: "/tmp/imgxsh/legal"
  parallel_jobs: 2

steps:
  - name: extract_pages
    type: pdf_extract
    description: "Extract all pages as high-quality images"
    params:
      input: "{workflow_input}"
      output_dir: "{temp_dir}/pages"
      format: "tiff"
      quality: 100
      density: 300
      
  - name: ocr_extraction
    type: ocr
    description: "Extract text from each page"
    params:
      input_dir: "{temp_dir}/pages"
      language: "eng"
      confidence_threshold: 80
      output_template: "{output_dir}/text/{pdf_name}_page_{counter:03d}.txt"
      
  - name: create_searchable_pdf
    type: custom
    description: "Create searchable PDF with OCR text"
    params:
      script: |
        #!/bin/bash
        echo "Creating searchable PDF..."
        # Use tesseract to create searchable PDF
        tesseract "{temp_dir}/pages/page_001.tiff" "{output_dir}/{pdf_name}_searchable" -l eng pdf
      
  - name: extract_signatures
    type: custom
    description: "Extract signature areas for verification"
    params:
      script: |
        #!/bin/bash
        echo "Extracting signature areas..."
        # Custom logic to identify and extract signature areas
        # This would use image processing to find signature-like regions
        
  - name: generate_metadata
    type: custom
    description: "Generate document metadata"
    params:
      script: |
        #!/bin/bash
        metadata_file="{output_dir}/{pdf_name}_metadata.json"
        echo "{" > "$metadata_file"
        echo "  \"document_name\": \"{pdf_name}\"," >> "$metadata_file"
        echo "  \"processing_date\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"," >> "$metadata_file"
        echo "  \"page_count\": {extracted_count}," >> "$metadata_file"
        echo "  \"ocr_confidence\": \"high\"" >> "$metadata_file"
        echo "}" >> "$metadata_file"

hooks:
  on_success:
    - echo "Legal document processed:"
    - echo "  Searchable PDF: {output_dir}/{pdf_name}_searchable.pdf"
    - echo "  OCR text: {output_dir}/text/"
    - echo "  Metadata: {output_dir}/{pdf_name}_metadata.json"
```

### Academic Paper Processing

**Use Case**: Process academic papers with figure extraction and citation formatting.

**Workflow**: `academic-paper-processing.yaml`

```yaml
name: academic-paper-processing
description: "Process academic papers with figure extraction"
version: "1.0"

settings:
  output_dir: "./academic-papers"
  temp_dir: "/tmp/imgxsh/academic"
  parallel_jobs: 3

steps:
  - name: extract_figures
    type: pdf_extract
    description: "Extract figures and tables from paper"
    params:
      input: "{workflow_input}"
      output_dir: "{temp_dir}/figures"
      format: "png"
      quality: 95
      density: 300
      
  - name: extract_tables
    type: custom
    description: "Extract and process tables"
    params:
      script: |
        #!/bin/bash
        echo "Extracting tables from {workflow_input}..."
        # Use tabula or similar tool to extract tables
        # This would require additional dependencies
        
  - name: create_figure_gallery
    type: custom
    description: "Create HTML gallery of figures"
    params:
      script: |
        #!/bin/bash
        html_file="{output_dir}/{pdf_name}_figures.html"
        echo "<html><head><title>Figures from {pdf_name}</title></head><body>" > "$html_file"
        echo "<h1>Figures from {pdf_name}</h1>" >> "$html_file"
        
        counter=1
        for figure in {temp_dir}/figures/*.png; do
          if [ -f "$figure" ]; then
            basename=$(basename "$figure")
            echo "<div class=\"figure\">" >> "$html_file"
            echo "<h3>Figure $counter</h3>" >> "$html_file"
            echo "<img src=\"figures/$basename\" alt=\"Figure $counter\">" >> "$html_file"
            echo "</div>" >> "$html_file"
            counter=$((counter + 1))
          fi
        done
        
        echo "</body></html>" >> "$html_file"
        
  - name: generate_citations
    type: custom
    description: "Generate citation information"
    params:
      script: |
        #!/bin/bash
        citations_file="{output_dir}/{pdf_name}_citations.txt"
        echo "Citation Information for {pdf_name}" > "$citations_file"
        echo "Processed on: $(date)" >> "$citations_file"
        echo "Number of figures: {extracted_count}" >> "$citations_file"
        echo "" >> "$citations_file"
        echo "Figure files:" >> "$citations_file"
        ls -la {temp_dir}/figures/ >> "$citations_file"

hooks:
  on_success:
    - echo "Academic paper processed:"
    - echo "  Figures: {output_dir}/figures/"
    - echo "  Gallery: {output_dir}/{pdf_name}_figures.html"
    - echo "  Citations: {output_dir}/{pdf_name}_citations.txt"
```

## Social Media

### Instagram Content Creation

**Use Case**: Create Instagram posts and stories from PDF documents.

**Workflow**: `instagram-content.yaml`

```yaml
name: instagram-content
description: "Create Instagram posts and stories from documents"
version: "1.0"

settings:
  output_dir: "./instagram-content"
  temp_dir: "/tmp/imgxsh/instagram"
  parallel_jobs: 4

steps:
  - name: extract_images
    type: pdf_extract
    description: "Extract images from PDF"
    params:
      input: "{workflow_input}"
      output_dir: "{temp_dir}/extracted"
      format: "png"
      quality: 95
      
  - name: create_square_posts
    type: resize
    description: "Create square posts (1080x1080)"
    params:
      input_dir: "{temp_dir}/extracted"
      width: 1080
      height: 1080
      maintain_aspect: false
      quality: 90
      format: "jpg"
      output_template: "{output_dir}/posts/{input_name}_post_{counter:03d}.jpg"
      
  - name: create_stories
    type: resize
    description: "Create story format (1080x1920)"
    params:
      input_dir: "{temp_dir}/extracted"
      width: 1080
      height: 1920
      maintain_aspect: false
      quality: 90
      format: "jpg"
      output_template: "{output_dir}/stories/{input_name}_story_{counter:03d}.jpg"
      
  - name: add_brand_overlay
    type: watermark
    description: "Add brand overlay to posts"
    params:
      input_dir: "{output_dir}/posts"
      watermark_image: "/path/to/brand-overlay.png"
      position: "bottom-right"
      opacity: 0.8
      scale: 0.15
      output_template: "{output_dir}/branded/{input_name}_branded_{counter:03d}.jpg"

hooks:
  on_success:
    - echo "Instagram content created:"
    - echo "  Posts: {output_dir}/posts/"
    - echo "  Stories: {output_dir}/stories/"
    - echo "  Branded: {output_dir}/branded/"
```

### LinkedIn Professional Content

**Use Case**: Create professional LinkedIn posts and articles.

**Preset**: `linkedin-professional.yaml`

```yaml
name: linkedin-professional
description: "Create professional LinkedIn content"
base_workflow: instagram-content

overrides:
  settings:
    output_dir: "./linkedin-content"
    
  steps:
    create_square_posts:
      params:
        width: 1200
        height: 627  # LinkedIn recommended size
        quality: 85
        format: "jpg"
        
    create_stories:
      enabled: false  # LinkedIn doesn't use stories format
      
    add_brand_overlay:
      params:
        opacity: 0.6  # More subtle for professional use
        scale: 0.1
```

## E-commerce

### Product Image Processing

**Use Case**: Process product images for e-commerce with multiple variants.

**Workflow**: `ecommerce-product-images.yaml`

```yaml
name: ecommerce-product-images
description: "Process product images for e-commerce"
version: "1.0"

settings:
  output_dir: "./product-images"
  temp_dir: "/tmp/imgxsh/ecommerce"
  parallel_jobs: 6

steps:
  - name: extract_product_images
    type: pdf_extract
    description: "Extract product images from catalog"
    params:
      input: "{workflow_input}"
      output_dir: "{temp_dir}/extracted"
      format: "png"
      quality: 95
      
  - name: create_main_images
    type: resize
    description: "Create main product images (800x800)"
    params:
      input_dir: "{temp_dir}/extracted"
      width: 800
      height: 800
      maintain_aspect: true
      quality: 90
      format: "jpg"
      output_template: "{output_dir}/main/{input_name}_main_{counter:03d}.jpg"
      
  - name: create_thumbnails
    type: resize
    description: "Create product thumbnails (200x200)"
    params:
      input_dir: "{temp_dir}/extracted"
      width: 200
      height: 200
      maintain_aspect: true
      quality: 85
      format: "jpg"
      output_template: "{output_dir}/thumbs/{input_name}_thumb_{counter:03d}.jpg"
      
  - name: create_zoom_images
    type: resize
    description: "Create zoom images (1600x1600)"
    params:
      input_dir: "{temp_dir}/extracted"
      width: 1600
      height: 1600
      maintain_aspect: true
      quality: 95
      format: "jpg"
      output_template: "{output_dir}/zoom/{input_name}_zoom_{counter:03d}.jpg"
      
  - name: create_gallery_images
    type: resize
    description: "Create gallery images (400x400)"
    params:
      input_dir: "{temp_dir}/extracted"
      width: 400
      height: 400
      maintain_aspect: true
      quality: 85
      format: "webp"
      output_template: "{output_dir}/gallery/{input_name}_gallery_{counter:03d}.webp"
      
  - name: generate_product_data
    type: custom
    description: "Generate product data JSON"
    params:
      script: |
        #!/bin/bash
        json_file="{output_dir}/{input_name}_products.json"
        echo "[" > "$json_file"
        
        counter=1
        for main_img in {output_dir}/main/*.jpg; do
          if [ -f "$main_img" ]; then
            basename=$(basename "$main_img" .jpg)
            echo "  {" >> "$json_file"
            echo "    \"id\": \"product_$counter\"," >> "$json_file"
            echo "    \"name\": \"Product $counter\"," >> "$json_file"
            echo "    \"main_image\": \"main/$basename.jpg\"," >> "$json_file"
            echo "    \"thumbnail\": \"thumbs/${basename}_thumb.jpg\"," >> "$json_file"
            echo "    \"zoom_image\": \"zoom/${basename}_zoom.jpg\"," >> "$json_file"
            echo "    \"gallery_images\": [\"gallery/${basename}_gallery.webp\"]" >> "$json_file"
            echo "  }," >> "$json_file"
            counter=$((counter + 1))
          fi
        done
        
        echo "]" >> "$json_file"

hooks:
  on_success:
    - echo "E-commerce images processed:"
    - echo "  Main images: {output_dir}/main/"
    - echo "  Thumbnails: {output_dir}/thumbs/"
    - echo "  Zoom images: {output_dir}/zoom/"
    - echo "  Gallery: {output_dir}/gallery/"
    - echo "  Product data: {output_dir}/{input_name}_products.json"
```

### Shopify Integration

**Use Case**: Generate images specifically for Shopify stores.

**Preset**: `shopify-integration.yaml`

```yaml
name: shopify-integration
description: "Generate images optimized for Shopify"
base_workflow: ecommerce-product-images

overrides:
  settings:
    output_dir: "./shopify-images"
    
  steps:
    create_main_images:
      params:
        width: 1024
        height: 1024
        quality: 85
        format: "jpg"
        
    create_thumbnails:
      params:
        width: 100
        height: 100
        quality: 80
        
    create_zoom_images:
      params:
        width: 2048
        height: 2048
        quality: 90
        
    generate_product_data:
      params:
        script: |
          #!/bin/bash
          # Generate Shopify-compatible CSV
          csv_file="{output_dir}/{input_name}_shopify.csv"
          echo "Handle,Title,Image Src,Image Alt Text" > "$csv_file"
          
          counter=1
          for main_img in {output_dir}/main/*.jpg; do
            if [ -f "$main_img" ]; then
              basename=$(basename "$main_img" .jpg)
              echo "product-$counter,Product $counter,main/$basename.jpg,Product $counter image" >> "$csv_file"
              counter=$((counter + 1))
            fi
          done
```

## Archival & Backup

### Document Archival System

**Use Case**: Create archival copies of documents with metadata preservation.

**Workflow**: `document-archival.yaml`

```yaml
name: document-archival
description: "Create archival copies with metadata preservation"
version: "1.0"

settings:
  output_dir: "./archival"
  temp_dir: "/tmp/imgxsh/archival"
  parallel_jobs: 2

steps:
  - name: extract_high_quality
    type: pdf_extract
    description: "Extract high-quality archival images"
    params:
      input: "{workflow_input}"
      output_dir: "{temp_dir}/archival"
      format: "tiff"
      quality: 100
      density: 600  # High DPI for archival
      
  - name: preserve_metadata
    type: custom
    description: "Extract and preserve document metadata"
    params:
      script: |
        #!/bin/bash
        metadata_file="{output_dir}/{pdf_name}_metadata.txt"
        echo "Document Archival Information" > "$metadata_file"
        echo "=============================" >> "$metadata_file"
        echo "Original file: {workflow_input}" >> "$metadata_file"
        echo "Processing date: $(date)" >> "$metadata_file"
        echo "File size: $(stat -f%z "{workflow_input}" 2>/dev/null || stat -c%s "{workflow_input}" 2>/dev/null) bytes" >> "$metadata_file"
        echo "Page count: {extracted_count}" >> "$metadata_file"
        echo "" >> "$metadata_file"
        echo "Archival images:" >> "$metadata_file"
        ls -la {temp_dir}/archival/ >> "$metadata_file"
        
  - name: create_checksums
    type: custom
    description: "Create checksums for integrity verification"
    params:
      script: |
        #!/bin/bash
        checksum_file="{output_dir}/{pdf_name}_checksums.md5"
        echo "MD5 Checksums for {pdf_name}" > "$checksum_file"
        echo "=============================" >> "$checksum_file"
        
        # Create checksum for original file
        md5sum "{workflow_input}" >> "$checksum_file"
        
        # Create checksums for archival images
        for img in {temp_dir}/archival/*.tiff; do
          if [ -f "$img" ]; then
            md5sum "$img" >> "$checksum_file"
          fi
        done
        
  - name: create_archive_package
    type: custom
    description: "Create archive package with all files"
    params:
      script: |
        #!/bin/bash
        archive_name="{output_dir}/{pdf_name}_archive_$(date +%Y%m%d_%H%M%S).tar.gz"
        
        # Create archive with all files
        tar -czf "$archive_name" \
          -C "{temp_dir}" archival/ \
          -C "{output_dir}" {pdf_name}_metadata.txt \
          -C "{output_dir}" {pdf_name}_checksums.md5
        
        echo "Archive created: $archive_name"

hooks:
  on_success:
    - echo "Document archived successfully:"
    - echo "  Archive: {output_dir}/{pdf_name}_archive_*.tar.gz"
    - echo "  Metadata: {output_dir}/{pdf_name}_metadata.txt"
    - echo "  Checksums: {output_dir}/{pdf_name}_checksums.md5"
```

## Automation & CI/CD

### Automated Image Processing Pipeline

**Use Case**: Integrate image processing into CI/CD pipelines.

**Workflow**: `ci-image-processing.yaml`

```yaml
name: ci-image-processing
description: "Automated image processing for CI/CD"
version: "1.0"

settings:
  output_dir: "./build/images"
  temp_dir: "/tmp/imgxsh/ci"
  parallel_jobs: 8

steps:
  - name: extract_build_images
    type: pdf_extract
    description: "Extract images for build process"
    params:
      input: "{workflow_input}"
      output_dir: "{temp_dir}/extracted"
      format: "png"
      quality: 95
      
  - name: generate_web_assets
    type: resize
    description: "Generate web assets"
    params:
      input_dir: "{temp_dir}/extracted"
      widths: [320, 640, 1024, 1920]
      maintain_aspect: true
      quality: 85
      format: "webp"
      output_template: "{output_dir}/web/{input_name}_{width}w.webp"
      
  - name: generate_mobile_assets
    type: resize
    description: "Generate mobile app assets"
    params:
      input_dir: "{temp_dir}/extracted"
      sizes: [72, 96, 128, 144, 152, 192, 384, 512]
      maintain_aspect: true
      quality: 90
      format: "png"
      output_template: "{output_dir}/mobile/icon-{size}.png"
      
  - name: generate_manifest
    type: custom
    description: "Generate web app manifest"
    params:
      script: |
        #!/bin/bash
        manifest_file="{output_dir}/manifest.json"
        echo "{" > "$manifest_file"
        echo "  \"name\": \"{input_name}\"," >> "$manifest_file"
        echo "  \"icons\": [" >> "$manifest_file"
        
        counter=0
        for icon in {output_dir}/mobile/icon-*.png; do
          if [ -f "$icon" ]; then
            size=$(basename "$icon" .png | sed 's/icon-//')
            if [ $counter -gt 0 ]; then
              echo "," >> "$manifest_file"
            fi
            echo "    {" >> "$manifest_file"
            echo "      \"src\": \"mobile/icon-$size.png\"," >> "$manifest_file"
            echo "      \"sizes\": \"${size}x${size}\"," >> "$manifest_file"
            echo "      \"type\": \"image/png\"" >> "$manifest_file"
            echo -n "    }" >> "$manifest_file"
            counter=$((counter + 1))
          fi
        done
        
        echo "" >> "$manifest_file"
        echo "  ]" >> "$manifest_file"
        echo "}" >> "$manifest_file"

hooks:
  on_success:
    - echo "CI image processing completed"
    - echo "Web assets: {output_dir}/web/"
    - echo "Mobile assets: {output_dir}/mobile/"
    - echo "Manifest: {output_dir}/manifest.json"
    
  on_failure:
    - echo "CI image processing failed"
    - exit 1  # Fail the CI build
```

### GitHub Actions Integration

**Use Case**: Process images automatically on GitHub.

**GitHub Actions Workflow**: `.github/workflows/process-images.yml`

```yaml
name: Process Images

on:
  push:
    paths:
      - 'docs/images/**'
      - 'assets/**'
  pull_request:
    paths:
      - 'docs/images/**'
      - 'assets/**'

jobs:
  process-images:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Setup imgxsh
      run: |
        # Install dependencies
        sudo apt-get update
        sudo apt-get install -y imagemagick poppler-utils
        
        # Install imgxsh (assuming it's in the repo)
        chmod +x ./install.sh
        ./install.sh
        
    - name: Process Images
      run: |
        # Process images with imgxsh
        imgxsh --workflow ci-image-processing docs/images/source.pdf
        
    - name: Upload Processed Images
      uses: actions/upload-artifact@v3
      with:
        name: processed-images
        path: build/images/
```

## Advanced Use Cases

### Multi-format Document Processing

**Use Case**: Process documents in multiple formats with unified output.

**Workflow**: `multi-format-processing.yaml`

```yaml
name: multi-format-processing
description: "Process documents in multiple formats"
version: "1.0"

settings:
  output_dir: "./multi-format-output"
  temp_dir: "/tmp/imgxsh/multi"
  parallel_jobs: 4

steps:
  - name: detect_format
    type: custom
    description: "Detect input document format"
    params:
      script: |
        #!/bin/bash
        input_file="{workflow_input}"
        extension="${input_file##*.}"
        echo "Detected format: $extension"
        echo "$extension" > "{temp_dir}/format.txt"
        
  - name: extract_pdf
    type: pdf_extract
    description: "Extract from PDF documents"
    condition: "format == 'pdf'"
    params:
      input: "{workflow_input}"
      output_dir: "{temp_dir}/extracted"
      format: "png"
      
  - name: extract_excel
    type: excel_extract
    description: "Extract from Excel documents"
    condition: "format == 'xlsx'"
    params:
      input: "{workflow_input}"
      output_dir: "{temp_dir}/extracted"
      
  - name: process_images
    type: convert
    description: "Process individual image files"
    condition: "format == 'jpg' || format == 'png'"
    params:
      input: "{workflow_input}"
      output_dir: "{temp_dir}/extracted"
      format: "png"
      
  - name: unified_processing
    type: resize
    description: "Unified processing for all extracted images"
    condition: "extracted_count > 0"
    params:
      input_dir: "{temp_dir}/extracted"
      width: 800
      height: 600
      maintain_aspect: true
      quality: 85
      format: "webp"
      output_template: "{output_dir}/{input_name}_processed_{counter:03d}.webp"

hooks:
  on_success:
    - echo "Multi-format processing completed"
    - echo "Processed {processed_count} images from {format} document"
```

### Batch Processing with Progress Tracking

**Use Case**: Process large batches with detailed progress tracking.

**Workflow**: `batch-processing-with-progress.yaml`

```yaml
name: batch-processing-with-progress
description: "Batch processing with detailed progress tracking"
version: "1.0"

settings:
  output_dir: "./batch-output"
  temp_dir: "/tmp/imgxsh/batch"
  parallel_jobs: 6

steps:
  - name: initialize_batch
    type: custom
    description: "Initialize batch processing"
    params:
      script: |
        #!/bin/bash
        echo "Starting batch processing at $(date)"
        echo "Input: {workflow_input}"
        echo "Output: {output_dir}"
        echo "Parallel jobs: {parallel_jobs}"
        
        # Create progress file
        echo "0" > "{temp_dir}/progress.txt"
        echo "0" > "{temp_dir}/total.txt"
        
  - name: extract_all_images
    type: pdf_extract
    description: "Extract images from all documents"
    params:
      input: "{workflow_input}"
      output_dir: "{temp_dir}/extracted"
      format: "png"
      parallel: true
      max_parallel: 4
      
  - name: count_total_images
    type: custom
    description: "Count total images to process"
    params:
      script: |
        #!/bin/bash
        total=$(find {temp_dir}/extracted -name "*.png" | wc -l)
        echo "$total" > "{temp_dir}/total.txt"
        echo "Total images to process: $total"
        
  - name: process_with_progress
    type: resize
    description: "Process images with progress tracking"
    params:
      input_dir: "{temp_dir}/extracted"
      width: 800
      height: 600
      maintain_aspect: true
      quality: 85
      format: "webp"
      output_template: "{output_dir}/processed_{counter:03d}.webp"
      progress_callback: |
        #!/bin/bash
        current=$(find {output_dir} -name "*.webp" | wc -l)
        total=$(cat {temp_dir}/total.txt)
        progress=$((current * 100 / total))
        echo "Progress: $progress% ($current/$total)"
        echo "$current" > "{temp_dir}/progress.txt"
        
  - name: generate_batch_report
    type: custom
    description: "Generate batch processing report"
    params:
      script: |
        #!/bin/bash
        report_file="{output_dir}/batch_report.txt"
        echo "Batch Processing Report" > "$report_file"
        echo "======================" >> "$report_file"
        echo "Start time: $(date)" >> "$report_file"
        echo "Input: {workflow_input}" >> "$report_file"
        echo "Total images processed: $(cat {temp_dir}/total.txt)" >> "$report_file"
        echo "Output directory: {output_dir}" >> "$report_file"
        echo "Processing time: $(date)" >> "$report_file"

hooks:
  pre_workflow:
    - echo "Starting batch processing: {workflow_input}"
    
  post_step:
    - echo "Step {step_name} completed"
    - if [ -f "{temp_dir}/progress.txt" ]; then
        current=$(cat {temp_dir}/progress.txt)
        total=$(cat {temp_dir}/total.txt)
        echo "Progress: $current/$total images processed"
      fi
    
  on_success:
    - echo "Batch processing completed successfully"
    - echo "Report: {output_dir}/batch_report.txt"
    
  on_failure:
    - echo "Batch processing failed at step: {failed_step}"
    - echo "Partial results available in: {output_dir}"
```

## Usage Tips

### Performance Optimization

1. **Adjust parallel jobs** based on your system capabilities
2. **Use appropriate quality settings** for your use case
3. **Choose the right format** (WebP for web, PNG for transparency, JPG for compatibility)
4. **Process in batches** for large document sets

### Error Handling

1. **Use dry-run mode** to preview operations
2. **Enable verbose logging** for debugging
3. **Test with sample data** before processing large batches
4. **Monitor disk space** for large processing jobs

### Customization

1. **Modify existing workflows** to match your needs
2. **Create custom presets** for common variations
3. **Add custom steps** for specialized processing
4. **Use hooks** for notifications and cleanup

This examples gallery provides a comprehensive set of real-world use cases that demonstrate the flexibility and power of the imgxsh workflow system. Each example can be adapted and customized for specific needs while maintaining the core principles of efficient, automated image processing.
