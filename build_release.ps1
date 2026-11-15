# HotelPro Multi-App Release Builder (PowerShell)
param (
    [string]$Target = ""
)

Write-Host "========================================================" -ForegroundColor Cyan
Write-Host "       HotelPro Multi-App Release Builder" -ForegroundColor Yellow
Write-Host "========================================================" -ForegroundColor Cyan

if (-not (Test-Path "releases")) {
    New-Item -ItemType Directory -Path "releases" | Out-Null
}

Write-Host "[*] Synchronizing Hotel Brand Logo to App Icons..." -ForegroundColor Cyan
& "$PSScriptRoot\update_hotel_icons.ps1" | Out-Null

function Build-App {
    param (
        [string]$Name,
        [string]$TargetFile,
        [string]$OutputFile,
        [string]$TargetApp
    )
    Write-Host "`n[*] Building $Name APK ($TargetFile, ID: com.isecuresystem.hotelpro.$TargetApp)..." -ForegroundColor Yellow
    flutter build apk -t $TargetFile -PtargetApp=$TargetApp --dart-define=APP_ID=$TargetApp --dart-define=SERVER_IP=192.168.0.100 --release --obfuscate --split-debug-info="build\app\outputs\symbols"
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[X] Failed to build $Name" -ForegroundColor Red
        return $false
    }
    Copy-Item "build\app\outputs\flutter-apk\app-release.apk" "releases\$OutputFile" -Force
    $size = (Get-Item "releases\$OutputFile").Length / 1MB
    Write-Host "[OK] Saved to: releases\$OutputFile ($([math]::Round($size, 2)) MB)" -ForegroundColor Green
    return $true
}

if ([string]::IsNullOrWhiteSpace($Target)) {
    Write-Host "`nChoose which application to build for Release:"
    Write-Host "  1. Staff Waiter & Captain POS App"
    Write-Host "  2. Delivery Boy / Rider Partner App"
    Write-Host "  3. Housekeeping & Room Inspection App"
    Write-Host "  4. Manager & Owner Live MIS App"
    Write-Host "  5. Customer Food & Dining App"
    Write-Host "  6. BUILD ALL 5 APPS (Batch)"
    Write-Host "  7. Windows Desktop ERP Release"
    Write-Host "  8. FULL SUITE (Windows ERP + All 5 Android APKs)"
    $choice = Read-Host "`nEnter choice (1-8)"
    switch ($choice) {
        "1" { $Target = "waiter" }
        "2" { $Target = "delivery" }
        "3" { $Target = "housekeeping" }
        "4" { $Target = "manager" }
        "5" { $Target = "customer" }
        "6" { $Target = "all" }
        "7" { $Target = "windows" }
        "8" { $Target = "full" }
        default { Write-Host "Invalid choice." -ForegroundColor Red; exit 1 }
    }
}

switch ($Target.ToLower()) {
    "waiter" {
        Build-App "Staff Waiter POS" "lib/main_waiter.dart" "HotelPro_WaiterPOS_v1.1.apk" "waiter"
    }
    "delivery" {
        Build-App "Delivery Partner" "lib/main_delivery.dart" "HotelPro_DeliveryBoy_v1.1.apk" "delivery"
    }
    "housekeeping" {
        Build-App "Housekeeping" "lib/main_housekeeping.dart" "HotelPro_Housekeeping_v1.1.apk" "housekeeping"
    }
    "manager" {
        Build-App "Manager MIS" "lib/main_manager.dart" "HotelPro_ManagerMIS_v1.1.apk" "manager"
    }
    "customer" {
        Build-App "Customer Dining" "lib/main_customer.dart" "HotelPro_CustomerDining_v1.1.apk" "customer"
    }
    "all" {
        Write-Host "`n[*] BUILDING ALL 5 MOBILE APPS SEQUENTIALLY..." -ForegroundColor Magenta
        Build-App "Staff Waiter POS" "lib/main_waiter.dart" "HotelPro_WaiterPOS_v1.1.apk" "waiter"
        Build-App "Delivery Partner" "lib/main_delivery.dart" "HotelPro_DeliveryBoy_v1.1.apk" "delivery"
        Build-App "Housekeeping" "lib/main_housekeeping.dart" "HotelPro_Housekeeping_v1.1.apk" "housekeeping"
        Build-App "Manager MIS" "lib/main_manager.dart" "HotelPro_ManagerMIS_v1.1.apk" "manager"
        Build-App "Customer Dining" "lib/main_customer.dart" "HotelPro_CustomerDining_v1.1.apk" "customer"
        Write-Host "`n[🎉] All 5 APKs have been built successfully in the 'releases/' folder!" -ForegroundColor Green
    }
    "windows" {
        Write-Host "`n[*] Building Windows Desktop ERP Release (Hardened & Obfuscated)..." -ForegroundColor Yellow
        flutter build windows --release --obfuscate --split-debug-info="build\windows\symbols"
        if ($LASTEXITCODE -eq 0) {
            Write-Host "[OK] Windows build ready in: build\windows\x64\runner\Release" -ForegroundColor Green
            $winReleaseDir = "releases\HotelPro_Windows_ERP_v1.1"
            if (Test-Path $winReleaseDir) { Remove-Item -Recurse -Force $winReleaseDir }
            Copy-Item -Recurse "build\windows\x64\runner\Release" $winReleaseDir
            Write-Host "[OK] Packaged Windows ERP in: $winReleaseDir" -ForegroundColor Green
        }
    }
    "full" {
        Write-Host "`n[*] BUILDING FULL SUITE (Windows Desktop ERP + All 5 Android APKs)..." -ForegroundColor Magenta
        Write-Host "`n[*] 1/6: Building Windows Desktop ERP Release..." -ForegroundColor Yellow
        flutter build windows --release --obfuscate --split-debug-info="build\windows\symbols"
        if ($LASTEXITCODE -eq 0) {
            $winReleaseDir = "releases\HotelPro_Windows_ERP_v1.1"
            if (Test-Path $winReleaseDir) { Remove-Item -Recurse -Force $winReleaseDir }
            Copy-Item -Recurse "build\windows\x64\runner\Release" $winReleaseDir
            Write-Host "[OK] Windows ERP Packaged in: $winReleaseDir" -ForegroundColor Green
        }
        Write-Host "`n[*] 2/6: Staff Waiter POS APK..." -ForegroundColor Yellow
        Build-App "Staff Waiter POS" "lib/main_waiter.dart" "HotelPro_WaiterPOS_v1.1.apk" "waiter"
        Write-Host "`n[*] 3/6: Delivery Partner APK..." -ForegroundColor Yellow
        Build-App "Delivery Partner" "lib/main_delivery.dart" "HotelPro_DeliveryBoy_v1.1.apk" "delivery"
        Write-Host "`n[*] 4/6: Housekeeping APK..." -ForegroundColor Yellow
        Build-App "Housekeeping" "lib/main_housekeeping.dart" "HotelPro_Housekeeping_v1.1.apk" "housekeeping"
        Write-Host "`n[*] 5/6: Manager MIS APK..." -ForegroundColor Yellow
        Build-App "Manager MIS" "lib/main_manager.dart" "HotelPro_ManagerMIS_v1.1.apk" "manager"
        Write-Host "`n[*] 6/6: Customer Dining APK..." -ForegroundColor Yellow
        Build-App "Customer Dining" "lib/main_customer.dart" "HotelPro_CustomerDining_v1.1.apk" "customer"
        Write-Host "`n[🎉] Complete HotelPro Enterprise Suite v1.1 Packaged in 'releases/' folder!" -ForegroundColor Green
    }
    default {
        Write-Host "Unknown target: $Target. Use: waiter, delivery, housekeeping, manager, customer, all, windows, or full." -ForegroundColor Red
    }
}
