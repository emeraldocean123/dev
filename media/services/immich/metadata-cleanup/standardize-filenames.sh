#!/bin/bash
# Standardize all filenames to kebab-case across dev, Immich, PhotoMove folders
# Converts PascalCase, camelCase, SCREAMING_CASE to kebab-case

# Function to convert filename to kebab-case
to_kebab_case() {
    local filename="$1"
    local extension="${filename##*.}"
    local basename="${filename%.*}"

    # Convert to kebab-case:
    # 1. Insert hyphen before uppercase letters (PascalCase -> Pascal-Case)
    # 2. Convert to lowercase
    # 3. Replace underscores with hyphens
    # 4. Replace multiple hyphens with single hyphen
    local kebab=$(echo "$basename" | \
        sed 's/\([A-Z]\)/-\1/g' | \
        tr '[:upper:]' '[:lower:]' | \
        tr '_' '-' | \
        sed 's/^-//' | \
        sed 's/-\+/-/g')

    echo "${kebab}.${extension}"
}

# Directories to process
DIRS=(
    "$HOME/Documents/dev"
    "/d/Immich"
    "/d/PhotoMove"
)

echo "Filename Standardization to kebab-case"
echo "======================================"
echo ""

# Find and rename files
for dir in "${DIRS[@]}"; do
    if [ ! -d "$dir" ]; then
        echo "Skipping $dir (not found)"
        continue
    fi

    echo "Processing: $dir"
    echo "---"

    # Find all .ps1, .sh, .md files (excluding README.md and system files)
    find "$dir" -type f \( -name "*.ps1" -o -name "*.sh" -o -name "*.md" \) \
        ! -name "README.md" \
        ! -name "Microsoft.PowerShell_profile.ps1" \
        ! -path "*/node_modules/*" \
        ! -path "*/.git/*" | while read -r filepath; do

        dirpath=$(dirname "$filepath")
        filename=$(basename "$filepath")

        # Skip if already in kebab-case (contains hyphens and all lowercase)
        if echo "$filename" | grep -qE '^[a-z0-9]+(-[a-z0-9]+)*\.(ps1|sh|md)$'; then
            continue
        fi

        # Convert to kebab-case
        new_filename=$(to_kebab_case "$filename")

        # Skip if no change
        if [ "$filename" = "$new_filename" ]; then
            continue
        fi

        new_filepath="$dirpath/$new_filename"

        # Check if target already exists
        if [ -f "$new_filepath" ]; then
            echo "  SKIP: $filename -> $new_filename (target exists)"
            continue
        fi

        # Rename file
        mv "$filepath" "$new_filepath"
        echo "  RENAMED: $filename -> $new_filename"
    done

    echo ""
done

echo "Standardization complete!"
