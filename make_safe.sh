#!/bin/bash

# Check for required arguments
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <input_directory> <output_directory>"
    exit 1
fi

input_dir="$1"
output_dir="$2"

# Create directories if they don't exist
mkdir -p "$output_dir"

# Define watermark text
text="$(date +%d/%m/%Y)
Document transmis uniquement pour dossier de location.
Toute autre utilisation, reproduction ou diffusion est strictement interdite."

# Function to create watermark PDF
create_watermark() {
    local page_count=$1
    local watermark_pdf="$2"
    
    # Create temporary directory for watermark pages
    local temp_dir=$(mktemp -d)
    
    # Create first watermark page
    magick -density 150 -size 1595x1842 xc:none -gravity Center \
        -font Helvetica -pointsize 15 -fill "rgba(0,0,0,0.5)" \
        -annotate -45x-45+0-300 "$text" "$temp_dir/watermark_page1.png"
    
    # Create additional pages if needed
    for ((i=2; i<=page_count; i++)); do
        cp "$temp_dir/watermark_page1.png" "$temp_dir/watermark_page$i.png"
    done
    
    # Combine into PDF
    magick "$temp_dir"/watermark_page*.png "$watermark_pdf"
    
    # Cleanup
    rm -rf "$temp_dir"
}

# Process each PDF in input directory
for input_pdf in "$input_dir"/*.pdf; do
    if [ ! -f "$input_pdf" ]; then
        continue  # Skip if no PDFs found
    fi
    
    filename=$(basename "$input_pdf")
    output_pdf="$output_dir/${filename%.*}_securise.pdf"
    temp_watermark=$(mktemp).pdf
    
    # Get page count of input PDF
    page_count=$(qpdf --show-npages "$input_pdf")
    
    echo "Processing $filename ($page_count pages)..."
    
    # Create watermark with correct number of pages
    create_watermark "$page_count" "$temp_watermark"
    
    # Apply watermark
    qpdf "$input_pdf" --overlay "$temp_watermark" -- "$output_pdf"
    
    # Cleanup
    rm "$temp_watermark"
    
    echo "Created secured version: $output_pdf"
done

echo "Processing complete."
