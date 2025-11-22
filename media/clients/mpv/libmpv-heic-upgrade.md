# mpv.net libmpv-2.dll Upgrade for HEIC Support

**Date:** November 10, 2025
**Purpose:** Enable HEIC/HEIF image support in mpv.net
**Status:** ❌ FAILED - Original DLL Restored

## Conclusion

**HEIC support is NOT possible in mpv.net** - even with the latest shinchiro build.

**Root Cause:** FFmpeg (including shinchiro builds) lacks libheif decoder. The DLL has HEIF *container* support but not the actual image *decoder*.

**Confirmed by:** String analysis of libmpv-2.dll showed HEIF demuxer but no libheif decoder library.

**Solution:** Use VLC for HEIC images (built-in libheif support works perfectly)

## What Was Done

Replaced mpv.net's `libmpv-2.dll` with a newer build from shinchiro's mpv-winbuild-cmake that includes libheif support.

### Before
- **File:** `libmpv-2.dll`
- **Size:** 98MB
- **Date:** January 11, 2024
- **FFmpeg:** N-113302-g5e751dabc
- **HEIC Support:** ❌ No

### After
- **File:** `libmpv-2.dll`
- **Size:** 110MB
- **Date:** November 9, 2025
- **Source:** [shinchiro/mpv-winbuild-cmake release 20251110](https://github.com/shinchiro/mpv-winbuild-cmake/releases/tag/20251110)
- **HEIC Support:** ✅ Expected (needs testing)

### Backup
- **Location:** `C:\Users\<username>\AppData\Local\Programs\mpv.net\libmpv-2.dll.backup-20251110`
- **Size:** 98MB (original file)

## Installation Steps

1. ✅ Downloaded `mpv-dev-x86_64-20251110-git-bbafb74.7z` (29MB)
2. ✅ Extracted to `<User Downloads Directory>`
3. ✅ Backed up original DLL to `libmpv-2.dll.backup-20251110`
4. ✅ Copied new `libmpv-2.dll` (110MB) to mpv.net directory

## Testing Required

### Test 1: HEIC Image Support

**Try opening a HEIC file:**
```powershell
& "C:\Users\<username>\AppData\Local\Programs\mpv.net\mpvnet.exe" "path\to\image.heic"
```

**Expected:**
- ✅ Image opens and displays correctly
- ✅ Can navigate with arrow keys if multiple images in folder

**If it fails:**
- Check error message in mpv.net console
- Restore original DLL using restore script

### Test 2: HDR Video Playback

**Critical:** Verify HDR tone mapping still works!

**Try opening an HDR video:**
```powershell
& "C:\Users\<username>\AppData\Local\Programs\mpv.net\mpvnet.exe" "path\to\hdr-video.mp4"
```

**Expected:**
- ✅ Colors look natural (not oversaturated)
- ✅ Hable tone mapping active
- ✅ No crashes or errors

**If HDR is broken:**
- Restore original DLL immediately
- HDR configuration might need adjustment for new FFmpeg version

### Test 3: General Functionality

**Verify normal operation:**
- Regular video playback (MP4, MKV, AVI)
- Audio playback (MP3, FLAC)
- Subtitle rendering
- Keybind functionality (arrow keys, space, etc.)

## Restore Original DLL

If the new DLL causes issues, run this script:

```powershell
# Restore original libmpv-2.dll
cd "<Repository Root>/media/clients/mpv"
.\restore-libmpv-original.ps1
```

Or manually:
```powershell
Copy-Item `
  "C:\Users\<username>\AppData\Local\Programs\mpv.net\libmpv-2.dll.backup-20251110" `
  "C:\Users\<username>\AppData\Local\Programs\mpv.net\libmpv-2.dll" `
  -Force

Write-Host "Original DLL restored. Restart mpv.net." -ForegroundColor Green
```

## Potential Risks (Why We Made a Backup)

1. **HDR Tone Mapping Break** ⚠️
   Newer FFmpeg might handle HDR differently. If colors look wrong, restore original.

2. **Compatibility Issues** ⚠️
   mpv.net 7.1.1.0 expects specific mpv API version. Newer libmpv might cause crashes.

3. **Performance Changes** ⚠️
   Newer codecs might be faster or slower depending on optimizations.

4. **Missing Features** ⚠️
   Older builds sometimes have features that newer builds drop.

## Why This Approach?

**Alternative 1:** Use VLC for HEIC
- ✅ Already works perfectly
- ✅ No risk to mpv.net
- ❌ Two separate apps

**Alternative 2:** Convert HEIC to JPEG
- ✅ Universal compatibility
- ✅ Metadata preserved with exiftool
- ❌ Extra step required

**Alternative 3:** Replace libmpv-2.dll (What we did)
- ✅ One app for everything
- ✅ Native HEIC support
- ⚠️ Risk of breaking HDR or causing crashes

## Recommendation

**After testing:**

- **If HEIC works AND HDR works:** Keep new DLL, document success
- **If HEIC works BUT HDR broken:** Restore original, use VLC for HEIC
- **If mpv.net crashes:** Restore original immediately

## Files Involved

- **mpv.net install:** `C:\Users\<username>\AppData\Local\Programs\mpv.net\`
- **Current DLL:** `libmpv-2.dll` (110MB, Nov 9 2025)
- **Backup DLL:** `libmpv-2.dll.backup-20251110` (98MB, Jan 11 2024)
- **Downloaded archive:** `~/Downloads/mpv-dev-x86_64-20251110.7z`
- **Extracted files:** `<User Downloads Directory>`

## Related Documentation

- **HDR Configuration:** `<Repository Root>/media/clients/mpv/mpv-hdr-configuration.md`
- **HEIC Workaround:** `<Repository Root>/media/clients/mpv/heic-support-workaround.md`
- **VLC Setup:** `<Repository Root>/media/clients/vlc/vlc-mpv-keybindings.md`
- **Restore Script:** `<Repository Root>/media/clients/mpv/restore-libmpv-original.ps1`

## Next Steps

1. **Test HEIC file** - Does it open?
2. **Test HDR video** - Are colors correct?
3. **Test regular videos** - Any crashes?
4. **Document results** - Update this file with test results

---

**Test Results** (to be filled in after testing):

- [ ] HEIC images open correctly
- [ ] HDR videos display with correct colors
- [ ] Regular videos play normally
- [ ] No crashes or errors observed
- [ ] Keybindings work as expected

**Decision:**
- [ ] Keep new DLL (all tests passed)
- [ ] Restore original DLL (issues found)
- [ ] Hybrid approach (VLC for images, mpv.net for videos)
