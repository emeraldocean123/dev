# ExifTool Optimization Guide

**Last Updated:** November 14, 2025
**Performance Gain:** 10-20x speedup for batch operations

## The Problem: Per-File ExifTool Calls

Most scripts call ExifTool once per file in a loop:

```powershell
# SLOW - Spawns ExifTool process for each file (~2-3 files/sec)
foreach ($file in $files) {
    $exif = & exiftool -json $file.FullName | ConvertFrom-Json
    # Process $exif...
}
```

**Why It's Slow:**
- Each `exiftool` call spawns a new process
- Process startup overhead is ~300-500ms per file
- For 78,123 files: 78,123 process spawns = hours of overhead

## The Solution: Single ExifTool Command

### Approach 1: Batch JSON Read (Best for Read-Only Operations)

Call ExifTool once with all files and parse the JSON array:

```powershell
# FAST - Single ExifTool process for all files (~30+ files/sec)
$allExif = & exiftool -json -r -Make -Model -DateTimeOriginal $Path | ConvertFrom-Json

# Create hashtable for fast lookup
$exifLookup = @{}
foreach ($item in $allExif) {
    $exifLookup[$item.SourceFile] = $item
}

# Now process files using the lookup
foreach ($file in $files) {
    $exif = $exifLookup[$file.FullName]
    # Process $exif...
}
```

**Performance:**
- 1 process spawn for entire operation
- Reads all files in single pass
- **10-20x faster** than loop approach

### Approach 2: Recursive Directory Processing (Best for Write Operations)

Let ExifTool process the entire directory tree in one command:

```bash
# ULTRA FAST - ExifTool handles entire directory (~30+ files/sec)
exiftool \
  -all= \
  -tagsFromFile @ \
  -Description \
  -Rating \
  -DateTimeOriginal \
  -ext xmp \
  -r \
  -progress \
  -overwrite_original \
  "/path/to/directory"
```

**Performance:**
- 1 process for entire tree
- ExifTool's internal optimization
- **50-100x faster** for write operations
- Used in `sanitize-xmp-simple.sh` (30 files/sec)

### Approach 3: Argument File (For Complex Operations)

For operations too complex for single command, use ExifTool's argument file:

```bash
# Create argument file
cat > args.txt << EOF
-Make
-Model
-DateTimeOriginal
-json
-r
EOF

# Single ExifTool call with argument file
exiftool -@ args.txt /path/to/directory
```

## Real-World Example: XMP Sanitization

### Before (Slow - 2.5 files/sec):
```powershell
foreach ($xmpFile in $xmpFiles) {
    $exiftoolArgs = @("-all=", "-tagsFromFile", $xmpFile, "-Description", ...)
    & exiftool $exiftoolArgs  # New process each iteration
}
```

**Time for 78,123 files:** ~8-10 hours

### After (Fast - 30+ files/sec):
```bash
exiftool -all= -tagsFromFile @ -Description -Rating -ext xmp -r -progress /d/Immich/library/library
```

**Time for 78,123 files:** ~40 minutes

## Optimization Checklist

When optimizing an ExifTool script:

1. **Identify the pattern:**
   - ❌ Loop with `foreach` calling `exiftool` each iteration
   - ✅ Single `exiftool` call processing all files

2. **Choose the right approach:**
   - **Read-only**: Use `-json -r` with all files, parse once
   - **Write operations**: Use recursive `-r` with filters (`-ext`, `-if`)
   - **Complex**: Use argument file `-@ args.txt`

3. **Use ExifTool's built-in features:**
   - `-r` for recursive directory processing
   - `-ext` to filter file types
   - `-if` for conditional processing
   - `-progress` to show progress
   - `-overwrite_original` to skip backups (or omit for automatic `.original` backups)

4. **Test on small subset first:**
   - Use `-@ /dev/stdin` or argument files for testing
   - Verify output before processing entire library

## Scripts to Optimize

### High Priority (Batch Operations):
- ✅ `~/Documents/dev/applications/immich/scripts/sanitize-xmp-simple.sh` - **Already optimized (30 files/sec)**
- ⚠️ `~/Documents/dev/applications/photomove/scripts/batch-rename-photos.ps1` - Reads EXIF per file (needs optimization)
- ⚠️ Mylio scripts in `~/Documents/dev/photos/mylio/` - Many use per-file loops

### Medium Priority (Smaller Operations):
- Scripts in `~/Documents/dev/applications/media-players/` - Verify if they process many files

## Performance Benchmarks

| Method | Files/Sec | Time for 78,123 files |
|--------|-----------|----------------------|
| Per-file loop | 2-3 | 8-10 hours |
| Batch JSON read | 15-20 | 1-1.5 hours |
| Recursive write | 30-50 | 25-45 minutes |

## Common Pitfalls

1. **Don't parse per-file in bash:**
   ```bash
   # WRONG - Still slow
   find . -name "*.jpg" | while read file; do
       exiftool "$file"  # New process each time
   done
   ```

2. **Don't use xargs without -n:**
   ```bash
   # WRONG - Only slightly better
   find . -name "*.jpg" | xargs -n 1 exiftool  # Still one process per file

   # RIGHT - Single process
   find . -name "*.jpg" | xargs exiftool  # All files to one process
   ```

3. **Use `-json` for batch reads:**
   ```powershell
   # WRONG - Text parsing is fragile
   $output = & exiftool -s file1.jpg file2.jpg

   # RIGHT - Structured data
   $output = & exiftool -json file1.jpg file2.jpg | ConvertFrom-Json
   ```

## Summary

**Golden Rule:** *Minimize ExifTool process spawns. One process for entire operation is optimal.*

For any script processing more than ~10 files, refactor to use:
- Batch JSON read for read operations
- Recursive directory processing for write operations
- Single ExifTool invocation with all files

This simple change can yield **10-100x performance improvements**.
