# Reference ADF writer for Amiga Dev Machine's auto-boot disks (no GameMaker
# needed). Mirrors scr_amiga_write_boot_adf: [hunkboot.bin][hunk executable],
# patches readsize / reserve fields after the "ADMB" tag and the bootblock
# checksum, then optionally boots the disk in the bundled FS-UAE.
#   powershell -File tools\make_adf.ps1 -Hunk main.bin -Out test.adf [-Run] [-Model A1200]
param(
    [Parameter(Mandatory = $true)][string]$Hunk,
    [Parameter(Mandatory = $true)][string]$Out,
    [string]$Boot = "",
    [UInt32]$ResvAddr = 0x20000,
    [UInt32]$ResvSize = 0x50000,
    [switch]$Run,
    [string]$Model = "A600"
)
$ErrorActionPreference = "Stop"
if ($Boot -eq "") { $Boot = Join-Path $PSScriptRoot "..\datafiles\boot\hunkboot.bin" }
function Put-Long([byte[]]$b, [int]$at, [UInt32]$v) {
    $b[$at] = [byte](($v -shr 24) -band 255); $b[$at + 1] = [byte](($v -shr 16) -band 255)
    $b[$at + 2] = [byte](($v -shr 8) -band 255); $b[$at + 3] = [byte]($v -band 255)
}
$bootBytes = [IO.File]::ReadAllBytes((Resolve-Path $Boot))
$hunkBytes = [IO.File]::ReadAllBytes((Resolve-Path $Hunk))
if ($bootBytes.Length -gt 1024) { throw "bootblock too big" }
$readsize = [UInt32]([Math]::Ceiling($hunkBytes.Length / 512) * 512)
if (1024 + $readsize -gt 901120) { throw "program too big for one floppy" }
$disk = New-Object byte[] 901120
[Array]::Copy($bootBytes, $disk, $bootBytes.Length)
$tag = -1
for ($i = 0; $i -lt 1020; $i += 2) {
    if ($disk[$i] -eq 0x41 -and $disk[$i + 1] -eq 0x44 -and $disk[$i + 2] -eq 0x4D -and $disk[$i + 3] -eq 0x42) { $tag = $i; break }
}
if ($tag -lt 0) { throw "ADMB tag missing" }
Put-Long $disk ($tag + 4) $readsize
Put-Long $disk ($tag + 8) $ResvAddr
Put-Long $disk ($tag + 12) $ResvSize
Put-Long $disk 4 0
[UInt64]$mask = 4294967295
[UInt64]$sum = 0
for ($i = 0; $i -lt 1024; $i += 4) {
    $sum += ([UInt64]$disk[$i] -shl 24) + ([UInt64]$disk[$i + 1] -shl 16) + ([UInt64]$disk[$i + 2] -shl 8) + [UInt64]$disk[$i + 3]
    if ($sum -gt $mask) { $sum = ($sum -band $mask) + 1 }
}
Put-Long $disk 4 ([UInt32]($mask - $sum))
[Array]::Copy($hunkBytes, 0, $disk, 1024, $hunkBytes.Length)
[IO.File]::WriteAllBytes($Out, $disk)
"wrote $Out (program $($hunkBytes.Length) bytes)"
if ($Run) {
    $fs = Resolve-Path "$PSScriptRoot\..\datafiles\fsuae\fs-uae.exe"
    $chip = 1024; if ($Model -eq "A1200") { $chip = 2048 }
    $adf = (Resolve-Path $Out).Path
    Start-Process -FilePath $fs -WorkingDirectory (Split-Path $fs) -ArgumentList @(
        "--amiga_model=$Model", "--chip_memory=$chip", "--slow_memory=0", "--fast_memory=0",
        "--floppy_drive_0=`"$adf`"", "--floppy_drive_speed=0", "--fullscreen=0",
        "--window_width=960", "--window_height=720", "--kickstart_file=", "--base_dir=`"$env:TEMP\adm_fsuae`"")
}
