@echo off
setlocal

echo ========================================================
echo        HotelPro Multi-App Release Builder
echo ========================================================
echo.

if not exist "releases" mkdir "releases"

echo [*] Synchronizing Hotel Brand Logo to App Icons...
powershell -ExecutionPolicy Bypass -File .\update_hotel_icons.ps1 >nul 2>&1
if %errorlevel% equ 0 (echo [OK] Hotel Logo synced to Android App Icons.)

set TARGET=%1
if "%TARGET%"=="" goto menu

:process
if /i "%TARGET%"=="waiter" goto build_waiter
if /i "%TARGET%"=="delivery" goto build_delivery
if /i "%TARGET%"=="housekeeping" goto build_housekeeping
if /i "%TARGET%"=="manager" goto build_manager
if /i "%TARGET%"=="customer" goto build_customer
if /i "%TARGET%"=="all" goto build_all
if /i "%TARGET%"=="windows" goto build_windows

echo [!] Unknown target: %TARGET%
echo Please choose: waiter, delivery, housekeeping, manager, customer, all, windows
exit /b 1

:menu
echo Choose which application to build for Release:
echo   1. Staff Waiter and Captain POS App
echo   2. Delivery Boy / Rider Partner App
echo   3. Housekeeping and Room Inspection App
echo   4. Manager and Owner Live MIS App
echo   5. Customer Food and Dining App
echo   6. BUILD ALL 5 APPS (Batch)
echo   7. Windows Desktop ERP Release
echo.
set /p choice="Enter choice (1-7): "

if "%choice%"=="1" goto build_waiter
if "%choice%"=="2" goto build_delivery
if "%choice%"=="3" goto build_housekeeping
if "%choice%"=="4" goto build_manager
if "%choice%"=="5" goto build_customer
if "%choice%"=="6" (
    set TARGET=all
    goto build_all
)
if "%choice%"=="7" goto build_windows
echo Invalid choice.
exit /b 1

:build_waiter
echo.
echo [*] Building Waiter POS App APK (Name: HotelPro Waiter POS, ID: com.isecuresystem.hotelpro.waiter)...
call flutter build apk -t lib/main_waiter.dart -PtargetApp=waiter --dart-define=APP_ID=waiter --dart-define=SERVER_IP=192.168.0.100 --release --obfuscate --split-debug-info="build\app\outputs\symbols"
if %errorlevel% neq 0 (
    echo [X] Failed to build Waiter POS App
    exit /b 1
)
copy /y "build\app\outputs\flutter-apk\app-release.apk" "releases\HotelPro_WaiterPOS_v1.0.apk" >nul
echo [OK] Saved to: releases\HotelPro_WaiterPOS_v1.0.apk
if not "%TARGET%"=="all" exit /b 0

:build_delivery
echo.
echo [*] Building Delivery Boy App APK (Name: HotelPro Delivery Boy, ID: com.isecuresystem.hotelpro.delivery)...
call flutter build apk -t lib/main_delivery.dart -PtargetApp=delivery --dart-define=APP_ID=delivery --dart-define=SERVER_IP=192.168.0.100 --release --obfuscate --split-debug-info="build\app\outputs\symbols"
if %errorlevel% neq 0 (
    echo [X] Failed to build Delivery Boy App
    exit /b 1
)
copy /y "build\app\outputs\flutter-apk\app-release.apk" "releases\HotelPro_DeliveryBoy_v1.0.apk" >nul
echo [OK] Saved to: releases\HotelPro_DeliveryBoy_v1.0.apk
if not "%TARGET%"=="all" exit /b 0

:build_housekeeping
echo.
echo [*] Building Housekeeping App APK (Name: HotelPro Housekeeping, ID: com.isecuresystem.hotelpro.housekeeping)...
call flutter build apk -t lib/main_housekeeping.dart -PtargetApp=housekeeping --dart-define=APP_ID=housekeeping --dart-define=SERVER_IP=192.168.0.100 --release --obfuscate --split-debug-info="build\app\outputs\symbols"
if %errorlevel% neq 0 (
    echo [X] Failed to build Housekeeping App
    exit /b 1
)
copy /y "build\app\outputs\flutter-apk\app-release.apk" "releases\HotelPro_Housekeeping_v1.0.apk" >nul
echo [OK] Saved to: releases\HotelPro_Housekeeping_v1.0.apk
if not "%TARGET%"=="all" exit /b 0

:build_manager
echo.
echo [*] Building Manager MIS App APK (Name: HotelPro Manager MIS, ID: com.isecuresystem.hotelpro.manager)...
call flutter build apk -t lib/main_manager.dart -PtargetApp=manager --dart-define=APP_ID=manager --dart-define=SERVER_IP=192.168.0.100 --release --obfuscate --split-debug-info="build\app\outputs\symbols"
if %errorlevel% neq 0 (
    echo [X] Failed to build Manager MIS App
    exit /b 1
)
copy /y "build\app\outputs\flutter-apk\app-release.apk" "releases\HotelPro_ManagerMIS_v1.0.apk" >nul
echo [OK] Saved to: releases\HotelPro_ManagerMIS_v1.0.apk
if not "%TARGET%"=="all" exit /b 0

:build_customer
echo.
echo [*] Building Customer Food and Dining App APK (Name: HotelPro Customer Dining, ID: com.isecuresystem.hotelpro.customer)...
call flutter build apk -t lib/main_customer.dart -PtargetApp=customer --dart-define=APP_ID=customer --dart-define=SERVER_IP=192.168.0.100 --release --obfuscate --split-debug-info="build\app\outputs\symbols"
if %errorlevel% neq 0 (
    echo [X] Failed to build Customer App
    exit /b 1
)
copy /y "build\app\outputs\flutter-apk\app-release.apk" "releases\HotelPro_CustomerDining_v1.0.apk" >nul
echo [OK] Saved to: releases\HotelPro_CustomerDining_v1.0.apk
if not "%TARGET%"=="all" exit /b 0
echo.
echo ========================================================
echo [OK] ALL 5 ANDROID APKs BUILT AND SAVED IN releases\ FOLDER
echo ========================================================
exit /b 0

:build_all
echo.
echo ========================================================
echo [*] BUILDING ALL 5 MOBILE APPS SEQUENTIALLY...
echo ========================================================
set TARGET=all
goto build_waiter

:build_windows
echo.
echo [*] Building Windows Desktop ERP Release (Hardened and Obfuscated)...
call flutter build windows --release --obfuscate --split-debug-info="build\windows\symbols"
if %errorlevel% neq 0 (
    echo [X] Failed to build Windows ERP
    exit /b 1
)
echo [OK] Windows build ready in: build\windows\x64\runner\Release
exit /b 0
