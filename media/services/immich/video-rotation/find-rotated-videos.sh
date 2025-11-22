#!/bin/bash
# Find videos with Display Matrix rotation metadata in Immich library
# This identifies videos that may have black screen issues with NVENC transcoding

echo "Scanning for videos with Display Matrix rotation metadata..."
echo "This may take several minutes depending on library size..."
echo "Checking side_data for Display Matrix (iPhone landscape videos)"
echo ""

log_dir="/d/Immich/tools/logs"
mkdir -p "$log_dir"
timestamp=$(date +"%Y%m%d-%H%M%S")
output_file="$log_dir/rotated-videos-$timestamp.txt"
mkdir -p /d/Immich/tools/logs

# Clear previous results
> "$output_file"

# Write header
echo "Videos with Display Matrix rotation metadata:" > "$output_file"
echo "==============================================" >> "$output_file"
echo "" >> "$output_file"

count=0
total=0

# Find all video files in the library
# Using process substitution instead of pipe to avoid subshell issues
while IFS= read -r video; do
    total=$((total + 1))

    # Check for Display Matrix rotation in side_data (iPhone videos)
    rotation=$(ffprobe -v error -select_streams v:0 -show_entries stream_side_data=rotation -of default=noprint_wrappers=1:nokey=1 "$video" 2>/dev/null | grep -v "^$")

    if [ -n "$rotation" ] && [ "$rotation" != "0" ]; then
        count=$((count + 1))
        echo "Found: $video"
        echo "Found: $video" >> "$output_file"

        # Get video dimensions
        dimensions=$(ffprobe -v error -select_streams v:0 -show_entries stream=width,height -of csv=p=0:s=x "$video" 2>/dev/null)
        echo "  Rotation: ${rotation}°"
        echo "  Rotation: ${rotation}°" >> "$output_file"
        echo "  Dimensions: $dimensions"
        echo "  Dimensions: $dimensions" >> "$output_file"

        # Get file size
        size=$(stat -c %s "$video" 2>/dev/null || stat -f %z "$video" 2>/dev/null)
        size_mb=$((size / 1024 / 1024))
        echo "  Size: ${size_mb}MB"
        echo "  Size: ${size_mb}MB" >> "$output_file"
        echo ""
        echo "" >> "$output_file"
    fi

    # Progress indicator every 100 videos
    if [ $((total % 100)) -eq 0 ]; then
        echo "Processed $total videos so far... (found $count with rotation)"
    fi
done < <(find /d/Immich/library/library -type f \( -name "*.mov" -o -name "*.MOV" -o -name "*.mp4" -o -name "*.MP4" -o -name "*.m4v" -o -name "*.M4V" \) 2>/dev/null)

echo ""
echo "====================================================="
echo "Scan complete!"
echo "Total videos scanned: $total"
echo "Videos with Display Matrix rotation: $count"
echo "Results saved to: $output_file"
echo ""
echo "Videos with -90° rotation need re-transcoding with software encoding."
echo "Use 'Refresh Encoded Video' button in Immich UI for each video."

# Append summary to output file
echo "" >> "$output_file"
echo "====================================================" >> "$output_file"
echo "Scan complete!" >> "$output_file"
echo "Total videos scanned: $total" >> "$output_file"
echo "Videos with Display Matrix rotation: $count" >> "$output_file"
echo "" >> "$output_file"
echo "These videos have black screen issues when transcoded with NVENC." >> "$output_file"
echo "Use 'Refresh Encoded Video' button in Immich UI to re-transcode with software encoding." >> "$output_file"
