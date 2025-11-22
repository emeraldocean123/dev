# Video Processing Toolkit Enhancement Roadmap

**Status:** Deferred from Phase 4 implementation
**Priority:** Medium (Production workaround exists)
**Complexity:** High (Parallel processing + WhatIf support)

## Overview

The video processing toolkit currently lacks comprehensive safety rails (`-WhatIf` support) in its parallel processing operations. While the current implementation is functional and stable, adding production-grade safety features requires careful consideration of PowerShell's parallel execution model.

## Current State

**Location:** `media/tools/video/video-processing-toolkit.ps1`

**Existing Operations:**
1. HDR → SDR conversion (ffmpeg with tonemap filter)
2. HEVC → H.264 transcoding (compatibility conversion)
3. Video rotation (metadata + transcoding)
4. Batch metadata extraction
5. Orphaned sidecar cleanup

**Current Safety Features:**
- ✅ Error handling with try/catch blocks
- ✅ File existence validation
- ✅ Progress reporting with colored output
- ✅ Backup recommendations in documentation
- ❌ No `-WhatIf` support for simulated execution
- ❌ No `-Confirm` prompts for destructive operations
- ❌ Parallel operations cannot simulate safely

## Technical Challenge

### The Parallel Processing WhatIf Problem

PowerShell's `ForEach-Object -Parallel` creates isolated runspaces where automatic variables like `$WhatIfPreference` are not automatically propagated.

**Current Pattern:**
```powershell
$files | ForEach-Object -Parallel {
    # This runspace does NOT have access to parent's $WhatIfPreference
    ffmpeg -i $_ -vf "tonemap" output.mp4
}
```

**Required Pattern:**
```powershell
[CmdletBinding(SupportsShouldProcess=$true)]
param()

$files | ForEach-Object -Parallel {
    param($File, $WhatIfMode)

    if ($WhatIfMode) {
        Write-Host "What if: Converting $File"
    } else {
        ffmpeg -i $File -vf "tonemap" output.mp4
    }
} -ArgumentList $_, $WhatIfPreference
```

### Complexity Factors

1. **Five Operation Modes:** Each with different file mutation patterns
2. **Parallel Execution:** Must pass WhatIf state via `$using:` scope
3. **ffmpeg Integration:** External process doesn't support native -WhatIf
4. **Comprehensive Testing:** Must verify all 5 operations × 2 modes (WhatIf + Execute)
5. **Error Handling:** Must gracefully handle simulation failures

## Recommended Implementation Approach

### Phase 1: Add CmdletBinding Support

```powershell
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [Parameter(Mandatory=$true, Position=0)]
    [ValidateSet("hdr-to-sdr", "hevc-to-h264", "rotate", "extract-metadata", "cleanup-sidecars")]
    [string]$Operation,

    [Parameter(Mandatory=$true, Position=1)]
    [string]$Path,

    [int]$Threads = 4
)
```

### Phase 2: Create Simulation Helpers

```powershell
function Invoke-VideoOperation {
    param(
        [string]$InputFile,
        [string]$OutputFile,
        [string]$Description,
        [scriptblock]$Operation,
        [bool]$WhatIfMode
    )

    if ($WhatIfMode) {
        Write-Host "What if: $Description" -ForegroundColor Cyan
        Write-Host "  Input:  $InputFile" -ForegroundColor Gray
        Write-Host "  Output: $OutputFile" -ForegroundColor Gray
        return @{ Success = $true; Simulated = $true }
    }

    & $Operation
}
```

### Phase 3: Refactor Parallel Blocks

```powershell
$files | ForEach-Object -Parallel {
    param($File, $WhatIfEnabled, $ThreadID)

    $using:functionDefinitions | ForEach-Object { . $_ }

    $result = Invoke-VideoOperation `
        -InputFile $File `
        -OutputFile "$($File -replace '\.mp4$','_converted.mp4')" `
        -Description "Convert HDR to SDR" `
        -WhatIfMode $WhatIfEnabled `
        -Operation {
            ffmpeg -i $File -vf "zscale=t=linear:npl=100,format=gbrpf32le,..." output.mp4
        }

    return $result
} -ArgumentList $_, $WhatIfPreference, $i -ThrottleLimit $Threads
```

### Phase 4: Add Confirmation Prompts

For destructive operations (cleanup-sidecars):

```powershell
if ($PSCmdlet.ShouldProcess($orphanFile, "Delete orphaned sidecar")) {
    Remove-Item $orphanFile -Force
}
```

### Phase 5: Comprehensive Testing

**Test Matrix:**
```
Operation          | Mode     | Expected Result
-------------------|----------|------------------
hdr-to-sdr         | WhatIf   | Simulation only
hdr-to-sdr         | Execute  | File converted
hevc-to-h264       | WhatIf   | Simulation only
hevc-to-h264       | Execute  | File converted
rotate             | WhatIf   | Simulation only
rotate             | Execute  | File rotated
extract-metadata   | WhatIf   | Simulation only
extract-metadata   | Execute  | JSON created
cleanup-sidecars   | WhatIf   | List orphans
cleanup-sidecars   | Execute  | Delete orphans
```

## Alternative: Separate Simulation Mode

**Simpler Implementation:**

Instead of full `-WhatIf` integration, add a dedicated `-Simulate` switch:

```powershell
param(
    [switch]$Simulate
)

if ($Simulate) {
    Write-Host "[SIMULATION MODE]" -ForegroundColor Yellow
    # Run parallel blocks with simulation flag
    $files | ForEach-Object -Parallel {
        param($File, $SimMode)
        if ($SimMode) {
            Write-Host "Would convert: $File"
        } else {
            # Actual conversion
        }
    } -ArgumentList $_, $true
}
```

**Advantages:**
- Simpler to implement
- Explicit user intent
- No automatic variable propagation issues

**Disadvantages:**
- Non-standard PowerShell pattern
- Requires different switch than other scripts

## Current Workaround

Until safety rails are implemented, users should:

1. **Start Small:** Test operations on 1-2 files first
2. **Use Backups:** Keep originals in separate location
3. **Monitor First Run:** Watch initial batch complete before walking away
4. **Check Logs:** Review terminal output for errors

## Estimated Effort

- **Research & Design:** 2 hours (understand parallel runspace model)
- **Implementation:** 4 hours (refactor all 5 operations)
- **Testing:** 3 hours (verify test matrix)
- **Documentation:** 1 hour (update README with -WhatIf examples)
- **Total:** ~10 hours of focused development

## Dependencies

- PowerShell 7.2+ (parallel support)
- ffmpeg (already required)
- Test video files (HDR, HEVC, various rotations)

## Success Criteria

- [ ] All operations support `-WhatIf` flag
- [ ] Parallel blocks correctly simulate without file modification
- [ ] Destructive operations prompt with `-Confirm`
- [ ] Test matrix passes for all 10 scenarios
- [ ] Documentation updated with safety examples
- [ ] No regression in existing functionality

## References

**PowerShell Documentation:**
- [About WhatIf](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_commonparameters)
- [ForEach-Object -Parallel](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/foreach-object)
- [About Scopes](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_scopes)

**Similar Implementations:**
- `deploy-to-proxmox.ps1` (Phase 4) - Sequential WhatIf implementation
- `manage-immich.ps1` - Confirmation prompts for destructive operations

## Notes

This enhancement was deferred during Phase 4 to maintain focus on cleanly additive features (deployment automation and health monitoring). The current implementation is production-stable with proper error handling; safety rails are a quality-of-life improvement rather than a critical bug fix.

**Created:** November 21, 2025
**Phase:** Post-Phase 4 Enhancement
**Owner:** Deferred for focused implementation session
