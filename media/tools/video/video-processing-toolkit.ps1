[CmdletBinding()]
param(
    [ValidateSet('Convert','FixCreationTime','PruneNonHdr','ValidateXmp','MergeExtXmp')]
    [string]$Mode = 'Convert',

    # Convert parameters
    [string]$SourceDir,
    [string]$OutputDir,
    [ValidateSet('Lossless','Best','Great','Fast')]
    [string]$Quality = 'Great',
    [ValidateSet('Skip','Overwrite','Check')]
    [string]$ExistingAction = 'Skip',
    [int]$ParallelJobs = 0,
    [switch]$ToneMapHdr,
    [switch]$HdrOnly,
    [switch]$Test,

    # Creation time parameters
    [string]$FixRoot = 'D:\Mylio-Converted',
    [string]$ConversionLog,
    [switch]$DryRun,

    # Prune parameters
    [string]$PruneSourceRoot = 'D:\Immich\library\library',
    [string]$PruneOutputRoot = 'D:\Immich\exports\hdr-to-sdr',

    # Validate params
    [string]$ValidateRoot,
    [string]$ReportPath,

    # Merge params
    [string]$MergeRoot = 'D:\Immich\library\library'
)

# Import shared utilities
$libPath = Join-Path $PSScriptRoot "../../../../lib/utils.ps1"
if (Test-Path $libPath) {
    . $libPath
} else {
    Write-Console "WARNING: Could not find shared library at $libPath" -ForegroundColor Yellow
    # Fallback: simple Write-Console function
    function Write-Console { param($Message, $ForegroundColor) Write-Console $Message -ForegroundColor $ForegroundColor }
}
function Test-IsHdrStream {
    param($stream)
    if (-not $stream) { return $false }
    return ($stream.color_primaries -match 'bt2020') -or
           ($stream.color_transfer -match 'smpte2084|arib-std-b67') -or
           ($stream.color_space -match 'bt2020')
}

function Invoke-VideoConversion {
    param(
        [string]$SourceDir,
        [string]$OutputDir,
        [string]$Quality,
        [string]$ExistingAction,
        [int]$ParallelJobs,
        [switch]$ToneMapHdr,
        [switch]$HdrOnly,
        [switch]$Test
    )

    function WInfo($m) { Write-Console $m -ForegroundColor Cyan }
    function WOk($m) { Write-Console "  [OK]  $m" -ForegroundColor Green }
    function WWarn($m) { Write-Console "  [WARN] $m" -ForegroundColor Yellow }
    function WErr($m) { Write-Console "  [ERR] $m" -ForegroundColor Red }

    $sourceDirectory = Get-Item -LiteralPath $SourceDir -ErrorAction Stop
    if ([string]::IsNullOrWhiteSpace($OutputDir)) {
        $OutputDir = Join-Path $sourceDirectory.Parent.FullName ($sourceDirectory.Name + '-Modernized')
    }
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null

    if ($ParallelJobs -lt 1) {
        $ParallelJobs = (Get-CimInstance Win32_Processor | Measure-Object -Property NumberOfLogicalProcessors -Sum).Sum - 1
        if ($ParallelJobs -lt 1) { $ParallelJobs = 1 }
    }

    if ($HdrOnly -and -not $ToneMapHdr) { $ToneMapHdr = $true }

    $presets = @{
        'Lossless' = @{ Mode='Lossless'; H264=$null; H265=$null; preset='veryslow'; audio='copy' }
        'Best'     = @{ Mode='Crf'; H264='18'; H265='20'; preset='veryslow'; audio='256k' }
        'Great'    = @{ Mode='Crf'; H264='20'; H265='23'; preset='slow'; audio='192k' }
        'Fast'     = @{ Mode='Crf'; H264='23'; H265='26'; preset='medium'; audio='160k' }
    }
    $p = $presets[$Quality]

    $sourceRoot = $sourceDirectory.FullName
    $h264_hw = 'h264_nvenc','h264_qsv','h264_amf','h264_videotoolbox'
    $hevc_hw = 'hevc_nvenc','hevc_qsv','hevc_amf','hevc_videotoolbox'
    $copyVideo = 'h264','hevc','avc','h265'
    $copyAudio = 'aac','ac3','eac3','mp3','alac','pcm_s16le','pcm_s24le','pcm_s32le','flac','truehd','dts'
    $marker = 'Universal4Zado=1'

    foreach ($cmd in 'ffmpeg','ffprobe') {
        if (-not (Get-Command $cmd -ErrorAction SilentlyContinue)) {
            throw "$cmd is required."
        }
    }
    $availableEncoders = ffmpeg -hide_banner -encoders 2>&1

    $extensions = '.mp4','.mov','.mkv','.avi','.m2ts','.mts','.mpg','.mpeg','.wmv','.flv','.webm','.m4v','.ts'
    $files = Get-ChildItem -Path $sourceRoot -File -Recurse | Where-Object { $extensions -contains $_.Extension.ToLower() } | Sort-Object Length -Descending
    if ($Test) {
        $files = $files | Sort-Object Length | Select-Object -First 10
        WWarn "TEST MODE – 10 smallest files only."
    }
    if ($files.Count -eq 0) { throw "No input videos found." }

    WInfo "Output → $OutputDir"
    WInfo "Parallel → $ParallelJobs"
    if ($HdrOnly) { WInfo "HDR-only mode enabled" }

    $pipelineStart = Get-Date
    $results = $files | ForEach-Object -Parallel {
        $file = $_
        $outputDir         = $using:OutputDir
        $p                 = $using:p
        $h264_hw           = $using:h264_hw
        $hevc_hw           = $using:hevc_hw
        $toneMapHdr        = $using:ToneMapHdr
        $hdrOnly           = $using:HdrOnly
        $existingAction    = $using:ExistingAction
        $marker            = $using:marker
        $copyVideo         = $using:copyVideo
        $copyAudio         = $using:copyAudio
        $availableEncoders = $using:availableEncoders
        $sourceRoot        = $using:sourceRoot

        function Normalize-CreationString { param([string]$Value)
            if ([string]::IsNullOrWhiteSpace($Value)) { return $null }
            try {
                $styles = [System.Globalization.DateTimeStyles]::AssumeUniversal -bor [System.Globalization.DateTimeStyles]::AdjustToUniversal
                $parsed = [System.DateTimeOffset]::Parse($Value,[System.Globalization.CultureInfo]::InvariantCulture,$styles)
                return $parsed.UtcDateTime.ToString('yyyy-MM-ddTHH:mm:ssZ')
            } catch { return $null }
        }

        function Get-CreationTime { param($f)
            $c=$null
            try {
                $json = ffprobe -v quiet -print_format json -show_entries format_tags=creation_time "$($f.FullName)" | ConvertFrom-Json
                $c = Normalize-CreationString $json.format.tags.creation_time
            } catch {}
            if (!$c -and $f.Name -match '^(\d{4})-(\d{2})-(\d{2})') { $c = "$($matches[1])-$($matches[2])-$($matches[3])T12:00:00Z" }
            if (!$c) { $c = $f.CreationTimeUtc.ToString('yyyy-MM-ddTHH:mm:ssZ') }
            return $c
        }

        function Get-Encoder { param($list,$fallback)
            foreach ($e in $list) { if ($availableEncoders -match "\b$e\b") { return $e } }
            return $fallback
        }

        function Test-IsSdrFile { param([string]$Path)
            if (-not (Test-Path $Path)) { return $false }
            try {
                $probe = ffprobe -v quiet -print_format json -show_streams $Path | ConvertFrom-Json
                $stream = $probe.streams | Where-Object codec_type -eq 'video' | Select-Object -First 1
                if (-not $stream) { return $false }
                if ((Test-IsHdrStream $stream)) { return $false }
                $primariesOk = [string]::IsNullOrEmpty($stream.color_primaries) -or $stream.color_primaries -eq 'bt709'
                $transferOk  = [string]::IsNullOrEmpty($stream.color_transfer)  -or $stream.color_transfer  -eq 'bt709'
                $spaceOk     = [string]::IsNullOrEmpty($stream.color_space)     -or $stream.color_space     -eq 'bt709'
                return $primariesOk -and $transferOk -and $spaceOk
            } catch { return $false }
        }

        function Set-Timestamps { param($path,$src)
            if (Test-Path $path) {
                $t=Get-Item $path
                $t.CreationTime=$src.CreationTime
                $t.LastWriteTime=$src.LastWriteTime
                $t.LastAccessTime=$src.LastAccessTime
            }
        }

        $relDir = [IO.Path]::GetRelativePath($sourceRoot,$file.DirectoryName)
        $targetDir = if ($relDir -eq '.') { $outputDir } else { Join-Path $outputDir $relDir }
        $outPath = Join-Path $targetDir ($file.BaseName + '_modern.mp4')

        if (Test-Path $outPath) {
            $existingIsSdr = $hdrOnly -and (Test-IsSdrFile -Path $outPath)
            if ($existingIsSdr) { return [PSCustomObject]@{Status='Skipped';File=$file.Name;Reason='AlreadySDR'} }
            $handled = $false
            if ($hdrOnly -and $existingAction -eq 'Skip') { Remove-Item $outPath -Force; $handled=$true }
            if (-not $handled) {
                switch($existingAction) {
                    'Skip' { return [PSCustomObject]@{Status='Skipped';File=$file.Name;Reason='Exists'} }
                    'Overwrite' { Remove-Item $outPath -Force }
                    'Check' {
                        $desc=$null
                        try { $desc=(ffprobe -v quiet -print_format json -show_entries format_tags=description $outPath | ConvertFrom-Json).format.tags.description } catch {}
                        if ($hdrOnly -and (Test-IsSdrFile -Path $outPath)) { return [PSCustomObject]@{Status='Skipped';File=$file.Name;Reason='AlreadySDR'} }
                        if ($desc -and $desc -like "*$marker*") { return [PSCustomObject]@{Status='Skipped';File=$file.Name;Reason='AlreadyConverted'} }
                        Remove-Item $outPath -Force
                    }
                }
            }
        }

        $creation = Get-CreationTime $file
        $probe = ffprobe -v quiet -print_format json -show_streams -show_format $file.FullName | ConvertFrom-Json
        $v = $probe.streams | Where-Object codec_type -eq 'video' | Select-Object -First 1
        $a = $probe.streams | Where-Object codec_type -eq 'audio' | Select-Object -First 1
        $isHdr = Test-IsHdrStream $v
        if ($hdrOnly -and -not $isHdr) { return [PSCustomObject]@{Status='Skipped';File=$file.Name;Reason='NotHDR'} }
        $needToneMap = $toneMapHdr -and $isHdr
        $is4k = ($v.width -ge 3840) -or ($v.height -ge 2160)

        if (-not (Test-Path $targetDir)) { New-Item -ItemType Directory -Path $targetDir -Force | Out-Null }

        $canCopyVideo = ($copyVideo -contains $v.codec_name) -and -not $needToneMap
        $canCopyAudio = $a -and ($copyAudio -contains $a.codec_name)
        $fullRemux = $canCopyVideo -and $canCopyAudio

        $args = @('-i',$file.FullName,'-map_metadata','0','-movflags','+faststart','-y')
        if ($needToneMap) {
            $args += '-vf','libplacebo=tonemapping=bt.2390:peak_detect=1:format=yuv420p'
            $args += '-color_primaries','bt709','-color_trc','bt709','-colorspace','bt709'
        }

        $type='REMUX'
        if ($fullRemux) {
            $args += '-c','copy'
        } else {
            if ($canCopyVideo) { $args += '-c:v','copy' } else {
                $family = if ($is4k) {'hevc'} else {'h264'}
                $encoder = Get-Encoder ($(if ($family -eq 'hevc') {$hevc_hw} else {$h264_hw}), "libx$($family -replace 'vc','65')")
                $args += '-c:v', $encoder
                if ($encoder -like '*hevc*') { $args += '-tag:v','hvc1' }
                if ($encoder -like 'libx26*') { $args += '-preset',$p.preset }
                if ($p.Mode -eq 'Lossless') {
                    if ($encoder -eq 'libx265') { $args += '-x265-params','lossless=1' } else { $args += '-qp','0' }
                } else {
                    $crf = if ($family -eq 'hevc') {$p.H265} else {$p.H264}
                    switch -Regex ($encoder) {
                        'nvenc' { $args += '-cq',$crf }
                        'qsv' { $args += '-global_quality',$crf }
                        'amf' { $args += '-quality','quality','-rc','cqp','-qp',$crf }
                        default { $args += '-crf',$crf }
                    }
                }
                $pix = if ($needToneMap) {'yuv420p'} elseif ($encoder -match 'nvenc|qsv|amf') {'yuv420p'} else {$v.pix_fmt}
                $args += '-pix_fmt',$pix
                $type = if ($family -eq 'hevc') {"HEVC"} else {"H264"}
            }
            if ($a) {
                if ($canCopyAudio) { $args += '-c:a','copy' }
                else {
                    $br = if ($p.audio -ne 'copy') {$p.audio} else {'192k'}
                    $args += '-c:a','aac','-b:a',$br
                }
            }
        }

        $descTag = $null
        try { $descTag = (ffprobe -v quiet -print_format json -show_entries format_tags=description $file.FullName | ConvertFrom-Json).format.tags.description } catch {}
        if ($descTag) { $descTag = "$descTag | $marker" } else { $descTag = $marker }

        if ($creation) { $args += '-metadata',"creation_time=`"$creation`"" }
        $args += '-metadata',"description=`"$descTag`""
        $args += $outPath

        $start = Get-Date
        $proc = Start-Process ffmpeg -ArgumentList $args -Wait -PassThru -NoNewWindow
        if ($proc.ExitCode -eq 0 -and (Test-Path $outPath)) {
            Set-Timestamps $outPath $file
            return [PSCustomObject]@{
                Status='Success';File=$file.Name;Type=$type;
                OldMB=[math]::Round($file.Length/1MB,2);
                NewMB=[math]::Round((Get-Item $outPath).Length/1MB,2);
                Sec=[math]::Round(((Get-Date)-$start).TotalSeconds,2)
            }
        } else {
            if (Test-Path $outPath) { Remove-Item $outPath -Force }
            return [PSCustomObject]@{Status='Failed';File=$file.Name}
        }
    } -ThrottleLimit $ParallelJobs

    $duration=[math]::Round(((Get-Date)-$pipelineStart).TotalSeconds,2)
    $success=@($results | Where-Object Status -eq 'Success')
    $skipped=@($results | Where-Object Status -eq 'Skipped')
    $failed=@($results | Where-Object Status -eq 'Failed')

    WInfo "============================================"
    WInfo "  UNIVERSAL CONVERSION COMPLETE"
    WInfo "============================================"
    WOk "$($success.Count) processed"
    WWarn "$($skipped.Count) skipped"
    if ($failed.Count -gt 0) { WErr "$($failed.Count) failed" }
    if ($success.Count -gt 0) {
        $saved = (($success.OldMB | Measure-Object -Sum).Sum - ($success.NewMB | Measure-Object -Sum).Sum)
        $saved = if ($saved) {[math]::Round($saved/1024,2)} else {0}
        WInfo "Space saved: ~$saved GB"
    }
    if ($skipped.Count -gt 0) {
        WInfo "Skip reasons:"
        $skipped | Group-Object Reason | Sort-Object Count -Descending | ForEach-Object { WWarn ("  $($_.Count) × $($_.Name)") }
    }
    WInfo "Elapsed → ${duration}s for $($results.Count) file(s)"
}

function Invoke-CreationTimeFix {
    param([string]$Root,[string]$ConversionLog,[switch]$DryRun)
    $ffmpeg = (Get-Command ffmpeg -ErrorAction Stop).Source
    $ffprobe = (Get-Command ffprobe -ErrorAction Stop).Source

    $targets=@()
    if ($ConversionLog) {
        if (-not (Test-Path $ConversionLog)) { throw "Log not found." }
        Get-Content $ConversionLog | ForEach-Object {
            if ($_ -match '^SUCCESS: .* -> (.+)$') {
                $path=$matches[1]
                if (Test-Path $path) { $targets += Get-Item $path }
            }
        }
    } else {
        $targets = Get-ChildItem -Path $Root -Filter '*.mp4' -Recurse -File | Where-Object { $_.Name -notlike '*.bak' }
    }
    if ($targets.Count -eq 0) { Write-Console "No MP4 files found." -ForegroundColor Yellow; return }
    $fixed=0;$skipped=0;$failed=0;$idx=0
    foreach($item in $targets){
        $idx++
        $iso=$item.LastWriteTimeUtc.ToString('yyyy-MM-ddTHH:mm:ss.000000Z')
        $hasMeta=$false
        try {
            $meta=( & $ffprobe -v quiet -print_format json -show_entries format_tags=creation_time -- $item.FullName | ConvertFrom-Json)
            $hasMeta= -not [string]::IsNullOrWhiteSpace($meta.format.tags.creation_time)
        } catch {}
        if ($hasMeta) { $skipped++; continue }
        if ($DryRun) { Write-Console "[$idx/$($targets.Count)] DRYRUN -> $($item.Name)"; $fixed++; continue }
        $backup="$($item.FullName).bak"
        if (-not (Test-Path $backup)) { Copy-Item $item.FullName $backup -Force }
        $temp=$item.FullName -replace '\.mp4$','_temp.mp4'
        $args=@('-i',$item.FullName,'-c','copy','-metadata',"creation_time=$iso",'-movflags','+faststart','-y',$temp)
        $proc=Start-Process -FilePath $ffmpeg -ArgumentList $args -Wait -PassThru
        if ($proc.ExitCode -eq 0 -and (Test-Path $temp)) {
            Remove-Item $item.FullName -Force
            Move-Item $temp $item.FullName -Force
            $fixed++; $item.Refresh()
        } else {
            if (Test-Path $temp) { Remove-Item $temp -Force }
            $failed++
        }
    }
    Write-Console "Summary → Fixed:$fixed Skipped:$skipped Failed:$failed" -ForegroundColor Cyan
}

function Invoke-PruneNonHdr {
    param([string]$SourceRoot,[string]$OutputRoot)
    $extensions='.mp4','.mov','.mkv','.avi','.m2ts','.mts','.mpg','.mpeg','.wmv','.flv','.webm','.m4v','.ts'

    $outputs=Get-ChildItem -Path $OutputRoot -Filter '*_modern.mp4' -File -Recurse
    if ($outputs.Count -eq 0) { Write-Console "No outputs to prune."; return }
    $removed=@();$skipMissing=0;$skipHdr=0
    foreach($outFile in $outputs){
        $relative = [IO.Path]::GetRelativePath($OutputRoot,$outFile.DirectoryName)
        $base=[IO.Path]::GetFileNameWithoutExtension($outFile.Name)
        if ($base -notlike '*_modern') { continue }
        $base = $base.Substring(0,$base.Length-7)
        $sourceDir = if ($relative -eq '.') {$SourceRoot} else { Join-Path $SourceRoot $relative }
        $sourcePath=$null
        foreach($ext in $extensions){
            $candidate=Join-Path $sourceDir ($base+$ext)
            if (Test-Path $candidate) { $sourcePath=$candidate; break }
        }
        if (-not $sourcePath) { $skipMissing++; continue }
        if (Test-IsHdrStream ((ffprobe -v quiet -print_format json -show_streams -select_streams v:0 "$sourcePath" | ConvertFrom-Json).streams | Select-Object -First 1)) {
            $skipHdr++; continue
        }
        Remove-Item $outFile.FullName -Force
        $removed += [PSCustomObject]@{Output=$outFile.FullName;Source=$sourcePath}
    }
    if ($removed.Count -gt 0) {
        $gb=[math]::Round((($removed | ForEach-Object {(Get-Item $_.Output).Length} | Measure-Object -Sum).Sum)/1GB,2)
        Write-Console "Removed $($removed.Count) files (~${gb}GB)." -ForegroundColor Green
    } else { Write-Console "No non-HDR conversions found." -ForegroundColor Yellow }
    Write-Console "Skipped missing source: $skipMissing" -ForegroundColor Cyan
    Write-Console "Skipped HDR source: $skipHdr" -ForegroundColor Cyan
}

function Invoke-XmpValidation {
    param([string]$Root,[string]$ReportPath)

    if (-not (Test-Path $Root)) { throw "Root not found." }
    Write-Console "Validating XMP sidecars under $Root …" -ForegroundColor Cyan
    $mismatches=@()
    $photos=Get-ChildItem -Path $Root -Filter '*.jpg' -File -Recurse
    foreach($photo in $photos){
        $xmp=[IO.Path]::ChangeExtension($photo.FullName,'.xmp')
        if (-not (Test-Path $xmp)) { continue }
        $jpgDto=(exiftool -s3 -DateTimeOriginal $photo.FullName) 2>$null
        $xmpDto=(exiftool -s3 -XMP:DateTimeOriginal $xmp) 2>$null
        if ($jpgDto -ne $xmpDto) {
            $mismatches += [PSCustomObject]@{Photo=$photo.FullName;Xmp=$xmp;PhotoDTO=$jpgDto;XmpDTO=$xmpDto}
        }
    }
    if ($mismatches.Count -eq 0) {
        Write-Console "All XMP sidecars match their parent files." -ForegroundColor Green
    } else {
        Write-Console "$($mismatches.Count) mismatches detected." -ForegroundColor Yellow
        if ($ReportPath) {
            $mismatches | Export-Csv -Path $ReportPath -NoTypeInformation
            Write-Console "Report saved to $ReportPath" -ForegroundColor Cyan
        } else {
            $mismatches | Format-Table -AutoSize
        }
    }
}

function Invoke-MergeExtXmp {
    param([string]$Root)

    $candidates = Get-ChildItem -Path $Root -Filter '*.xmp' -Recurse -File | Where-Object { $_.Name -match '\.[^.]+\.(xmp)$' }
    if ($candidates.Count -eq 0) {
        Write-Console "No extension-based XMP files found." -ForegroundColor Green
        return
    }

    $fields = 'XMP:DateTimeOriginal','XMP:CreateDate','XMP:ModifyDate','XMP:Rating','XMP:Label','XMP:Subject','XMP:HierarchicalSubject'

    foreach ($extFile in $candidates) {
        $withoutXmp = [IO.Path]::GetFileNameWithoutExtension($extFile.Name) # removes .xmp -> filename.ext
        $rootName = [IO.Path]::GetFileNameWithoutExtension($withoutXmp)     # removes .ext -> filename
        $stdXmp = Join-Path $extFile.DirectoryName ($rootName + '.xmp')

        if (-not (Test-Path $stdXmp)) {
            Copy-Item $extFile.FullName $stdXmp
            Remove-Item $extFile.FullName -Force
            continue
        }

        foreach ($field in $fields) {
            $extValue = (exiftool -s3 -$field $extFile.FullName) 2>$null
            if ([string]::IsNullOrWhiteSpace($extValue)) { continue }
            $stdValue = (exiftool -s3 -$field $stdXmp) 2>$null
            if ([string]::IsNullOrWhiteSpace($stdValue)) {
                exiftool -overwrite_original -$field="$extValue" $stdXmp | Out-Null
            } elseif ($field -eq 'XMP:Subject' -or $field -eq 'XMP:HierarchicalSubject') {
                $merged = ($stdValue -split ';' + $extValue -split ';' | Where-Object { $_ } | Select-Object -Unique) -join ';'
                exiftool -overwrite_original -sep ';' -$field="$merged" $stdXmp | Out-Null
            }
        }

        Remove-Item $extFile.FullName -Force
    }
    Write-Console "Merged extension-based XMP files into standard .xmp sidecars." -ForegroundColor Green
}

switch ($Mode) {
    'Convert' {
        if (-not $SourceDir) { throw "Specify -SourceDir for Convert mode." }
        Invoke-VideoConversion -SourceDir $SourceDir -OutputDir $OutputDir -Quality $Quality -ExistingAction $ExistingAction `
            -ParallelJobs $ParallelJobs -ToneMapHdr:$ToneMapHdr -HdrOnly:$HdrOnly -Test:$Test
    }
    'FixCreationTime' {
        Invoke-CreationTimeFix -Root $FixRoot -ConversionLog $ConversionLog -DryRun:$DryRun
    }
    'PruneNonHdr' {
        Invoke-PruneNonHdr -SourceRoot $PruneSourceRoot -OutputRoot $PruneOutputRoot
    }
    'ValidateXmp' {
        if (-not $ValidateRoot) { throw "Provide -ValidateRoot." }
        Invoke-XmpValidation -Root $ValidateRoot -ReportPath $ReportPath
    }
    'MergeExtXmp' {
        Invoke-MergeExtXmp -Root $MergeRoot
    }
}
