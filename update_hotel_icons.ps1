# HotelPro Android Launcher Icon Updater
# Generates Android launcher icons from the Hotel Logo instead of the software logo
param (
    [string]$SourceLogo = ""
)

Add-Type -AssemblyName System.Drawing

$projectRoot = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($projectRoot)) {
    $projectRoot = (Get-Location).Path
}

# 1. Determine Source Logo
if ([string]::IsNullOrWhiteSpace($SourceLogo) -or -not (Test-Path $SourceLogo)) {
    # Check custom hotel logo in AppData first
    $appData = [System.Environment]::GetFolderPath('ApplicationData')
    $customLogo = Join-Path $appData "HotelPro\custom_hotel_logo.png"
    if (Test-Path $customLogo) {
        $SourceLogo = $customLogo
    } else {
        # Check assets/hotel_logo.png
        $defaultLogo = Join-Path $projectRoot "lib\ui\features\master\assets\hotel_logo.png"
        if (Test-Path $defaultLogo) {
            $SourceLogo = $defaultLogo
        } else {
            # Check temp generated artifact
            $artifactLogo = "C:\Users\dell\.gemini\antigravity-ide\brain\f43ec253-9e37-483c-ad1f-f9ebc4d51bbf\hotel_brand_logo_1790612415810.jpg"
            if (Test-Path $artifactLogo) {
                $SourceLogo = $artifactLogo
            }
        }
    }
}

if (-not (Test-Path $SourceLogo)) {
    Write-Host "[X] Hotel logo source not found!" -ForegroundColor Red
    exit 1
}

Write-Host "[*] Using Hotel Logo: $SourceLogo" -ForegroundColor Cyan

# Read completely into memory to prevent file lock
$fileBytes = [System.IO.File]::ReadAllBytes($SourceLogo)
$memStream = New-Object System.IO.MemoryStream(,$fileBytes)
$srcImg = [System.Drawing.Image]::FromStream($memStream)

# 2. Ensure lib/ui/features/master/assets/hotel_logo.png exists
$assetTarget = Join-Path $projectRoot "lib\ui\features\master\assets\hotel_logo.png"
if ($SourceLogo -ne $assetTarget) {
    $masterBmp = New-Object System.Drawing.Bitmap(512, 512)
    $masterG = [System.Drawing.Graphics]::FromImage($masterBmp)
    $masterG.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $masterG.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    $masterG.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $masterG.DrawImage($srcImg, 0, 0, 512, 512)
    $masterBmp.Save($assetTarget, [System.Drawing.Imaging.ImageFormat]::Png)
    $masterG.Dispose()
    $masterBmp.Dispose()
    Write-Host "[OK] Updated $assetTarget" -ForegroundColor Green
}

# 3. Generate Android Mipmap & Drawable Icons
$resDir = Join-Path $projectRoot "android\app\src\main\res"

# Mipmap launcher icons (width, folder)
$mipmapSizes = @(
    @{ Folder = "mipmap-mdpi"; Size = 48 },
    @{ Folder = "mipmap-hdpi"; Size = 72 },
    @{ Folder = "mipmap-xhdpi"; Size = 96 },
    @{ Folder = "mipmap-xxhdpi"; Size = 144 },
    @{ Folder = "mipmap-xxxhdpi"; Size = 192 }
)

foreach ($entry in $mipmapSizes) {
    $dir = Join-Path $resDir $entry.Folder
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir | Out-Null }
    
    $outBmp = New-Object System.Drawing.Bitmap($entry.Size, $entry.Size)
    $g = [System.Drawing.Graphics]::FromImage($outBmp)
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $g.DrawImage($srcImg, 0, 0, $entry.Size, $entry.Size)
    
    $destFile = Join-Path $dir "ic_launcher.png"
    $outBmp.Save($destFile, [System.Drawing.Imaging.ImageFormat]::Png)
    $destFile2 = Join-Path $dir "launcher_icon.png"
    $outBmp.Save($destFile2, [System.Drawing.Imaging.ImageFormat]::Png)
    
    $g.Dispose()
    $outBmp.Dispose()
    Write-Host "[OK] Updated $($entry.Folder) ($($entry.Size)x$($entry.Size))" -ForegroundColor Green
}

# Drawable adaptive foreground icons
$drawableSizes = @(
    @{ Folder = "drawable-mdpi"; Size = 108 },
    @{ Folder = "drawable-hdpi"; Size = 162 },
    @{ Folder = "drawable-xhdpi"; Size = 216 },
    @{ Folder = "drawable-xxhdpi"; Size = 324 },
    @{ Folder = "drawable-xxxhdpi"; Size = 432 }
)

foreach ($entry in $drawableSizes) {
    $dir = Join-Path $resDir $entry.Folder
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir | Out-Null }
    
    $outBmp = New-Object System.Drawing.Bitmap($entry.Size, $entry.Size)
    $g = [System.Drawing.Graphics]::FromImage($outBmp)
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $g.DrawImage($srcImg, 0, 0, $entry.Size, $entry.Size)
    
    $destFile = Join-Path $dir "ic_launcher_foreground.png"
    $outBmp.Save($destFile, [System.Drawing.Imaging.ImageFormat]::Png)
    
    $g.Dispose()
    $outBmp.Dispose()
    Write-Host "[OK] Updated $($entry.Folder) Foreground ($($entry.Size)x$($entry.Size))" -ForegroundColor Green
}

$srcImg.Dispose()
$memStream.Dispose()
Write-Host "`n[🎉] All Android app launcher icons successfully updated with the Hotel Logo!" -ForegroundColor Cyan
