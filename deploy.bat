@echo off
chcp 65001 >nul
setlocal EnableDelayedExpansion

rem ============================================================
rem  Plugin Packaging Script
rem  Single .bat file - no external dependencies
rem  Extracts build output into dist/ for Uniquenium deployment
rem ============================================================

set "SCRIPT_DIR=%~dp0"
cd /d "%SCRIPT_DIR%"
set "DIST_DIR=%SCRIPT_DIR%dist"
set "BUILD_DIR=%SCRIPT_DIR%build"
set "BUILD_BIN="

rem --- Parse arguments ---
if /i "%~1"=="--clean" ( set "CLEAN_MODE=1" ) else ( if /i "%~1"=="-c" ( set "CLEAN_MODE=1" ) else ( set "CLEAN_MODE=0" ) )

rem --- Support: --build-dir <path>, --build-dir=<path>, -b <path>, or just pass the path ---
if /i "%~1"=="--build-dir" set "BUILD_BIN=%~2"
if /i "%~1"=="-b" set "BUILD_BIN=%~2"
for /f "tokens=2 delims==" %%A in ("%~1") do (
    if /i "%%A"=="--build-dir" set "BUILD_BIN=%%B"
)
if not defined BUILD_BIN (
    if exist "%~1" if not "%~1"=="" set "BUILD_BIN=%~1"
)

if "%CLEAN_MODE%"=="1" (
    if exist "%DIST_DIR%" (
        echo [CLEAN] Removing dist/ directory...
        rmdir /s /q "%DIST_DIR%"
    )
)

rem --- Find plugin ID from plugin-info.json early ---
set "PLUGIN_ID="
for /f "usebackq tokens=2 delims=:," %%A in (`findstr /c:"\"id\"" "%SCRIPT_DIR%\plugin-info.json" 2^>nul`) do (
    set "RAW=%%A"
    set "RAW=!RAW:"=!"
    set "RAW=!RAW: =!"
    set "PLUGIN_ID=!RAW!"
)

rem --- Find build output: prefer temp/bin, then recursive search ---
if not defined BUILD_BIN (
    echo [SCAN] Searching for build output in %BUILD_DIR% ...

    rem --- First try: temp/bin in all build config directories ---
    for /f "delims=" %%D in ('dir /s /b /ad "%BUILD_DIR%\temp\bin" 2^>nul') do (
        set "BUILD_BIN=%%D"
        goto :build_found
    )

    rem --- Fallback: find first directory containing a .dll ---
    for /f "delims=" %%F in ('dir /s /b "%BUILD_DIR%\*.dll" 2^>nul') do (
        set "BUILD_BIN=%%~dpF"
        set "BUILD_BIN=!BUILD_BIN:~0,-1!"
        goto :build_found
    )

    echo.
    echo [ERROR] No build output found. Please build the plugin first.
    echo Expected structure: build\**\temp\bin\*.dll
    echo.
    echo Quick setup:
    echo   1. Open CMakeLists.txt in Qt Creator
    echo   2. Select Release configuration
    echo   3. Build the project ^(Build ^> Build Project^)
    echo.
    pause
    exit /b 1
)
:build_found

if not exist "%BUILD_BIN%" (
    echo [ERROR] Build directory does not exist: %BUILD_BIN%
    pause
    exit /b 1
)

echo [BUILD] Using build output: %BUILD_BIN%

rem --- Find DLL: use plugin-info.json dlls field, or fallback to any .dll ---
set "DLL_NAME="

rem --- Try to get DLL name from plugin-info.json dlls array ---
for /f "usebackq tokens=2 delims=:," %%A in (`findstr /c:"\"dlls\"" "%SCRIPT_DIR%\plugin-info.json" 2^>nul`) do (
    rem --- Found "dlls": [ ... now search for entries ---
    for /f "usebackq tokens=2 delims=:," %%B in (`findstr /c:".dll" "%SCRIPT_DIR%\plugin-info.json" 2^>nul`) do (
        set "RAW=%%B"
        set "RAW=!RAW:"=!"
        set "RAW=!RAW: =!"
        set "RAW=!RAW:]=!"
        set "RAW=!RAW:[=!"
        set "DLL_NAME=!RAW!"
        goto :dll_found
    )
)

rem --- Fallback: search BUILD_BIN for any .dll ---
if not defined DLL_NAME (
    for %%F in ("%BUILD_BIN%\*.dll") do (
        set "DLL_NAME=%%~nxF"
        goto :dll_found
    )
)

if not defined DLL_NAME (
    echo [ERROR] No .dll file found in build output: %BUILD_BIN%
    pause
    exit /b 1
)
:dll_found
echo [INFO] DLL: %DLL_NAME%

rem --- Resolve plugin ID ---
if not defined PLUGIN_ID (
    for /f "usebackq tokens=2 delims=:," %%A in (`findstr /c:"\"id\"" "%BUILD_BIN%\plugin-info.json" 2^>nul`) do (
        set "RAW=%%A"
        set "RAW=!RAW:"=!"
        set "RAW=!RAW: =!"
        set "PLUGIN_ID=!RAW!"
    )
)
if not defined PLUGIN_ID set "PLUGIN_ID=%DLL_NAME%"
echo [INFO] Plugin ID:   %PLUGIN_ID%

rem --- Create output directory ---
set "DIST_PLUGIN=%DIST_DIR%\%PLUGIN_ID%"
if exist "%DIST_PLUGIN%" rmdir /s /q "%DIST_PLUGIN%"
mkdir "%DIST_PLUGIN%"

echo.
echo [COPY] Copying plugin files to %DIST_PLUGIN% ...

rem --- Copy DLL ---
copy /y "%BUILD_BIN%\%DLL_NAME%" "%DIST_PLUGIN%\" >nul
echo   [DLL]   %DLL_NAME%

rem --- Copy all root-level files from build output ---
rem --- Exclude: .dll, .qrc (artifacts), _qml_module_dir_map, qmldir, .qmltypes ---
for /f "delims=" %%F in ('dir /b /a:-d "%BUILD_BIN%" 2^>nul') do (
    set "SKIP=0"
    if /i "%%~xF"==".dll" set "SKIP=1"
    if /i "%%~xF"==".qrc" set "SKIP=1"
    if /i "%%~xF"==".qmltypes" set "SKIP=1"
    if /i "%%F"=="qmldir" set "SKIP=1"
    echo %%F | findstr /i "_qml_module_dir_map.qrc" >nul && set "SKIP=1"
    if "!SKIP!"=="0" (
        copy /y "%BUILD_BIN%\%%F" "%DIST_PLUGIN%\" >nul
        echo   [FILE]  %%F
    )
)

rem --- Copy QML subdirectories (excluding qmldir files) ---
for /f "delims=" %%D in ('dir /b /ad "%BUILD_BIN%"') do (
    xcopy /e /i /q /y "%BUILD_BIN%\%%D" "%DIST_PLUGIN%\%%D\" >nul
    if exist "%DIST_PLUGIN%\%%D\qmldir" (
        del /q "%DIST_PLUGIN%\%%D\qmldir"
    )
    echo   [DIR]   %%D\
)

rem --- Copy source files (overwrite build versions with source versions) ---
if exist "%SCRIPT_DIR%\plugin-info.json" (
    copy /y "%SCRIPT_DIR%\plugin-info.json" "%DIST_PLUGIN%\" >nul
    echo   [INFO]  plugin-info.json ^(source^)
)
if exist "%SCRIPT_DIR%\defaultSettings.json" (
    copy /y "%SCRIPT_DIR%\defaultSettings.json" "%DIST_PLUGIN%\" >nul
    echo   [INFO]  defaultSettings.json ^(source^)
)
if exist "%SCRIPT_DIR%\SignalHandler.qml" (
    copy /y "%SCRIPT_DIR%\SignalHandler.qml" "%DIST_PLUGIN%\" >nul
    echo   [INFO]  SignalHandler.qml ^(source^)
)

rem --- Clean artifacts ---
for %%F in ("%DIST_PLUGIN%\*_qml_module_dir_map.qrc") do (
    if exist "%%F" (
        del /q "%%F"
        echo   [CLEAN] Removed artifact: %%~nxF
    )
)

rem --- Count files ---
set "FILE_COUNT=0"
set "DIR_COUNT=0"
for /f "delims=" %%F in ('dir /s /b /a:-d "%DIST_PLUGIN%" 2^>nul') do set /a FILE_COUNT+=1
for /f "delims=" %%D in ('dir /s /b /ad "%DIST_PLUGIN%" 2^>nul') do set /a DIR_COUNT+=1

rem --- Summary ---
echo.
echo ============================================================
echo   Packaging complete!
echo   Output:   %DIST_PLUGIN%
echo   Files:    %FILE_COUNT%
echo   Folders:  %DIR_COUNT%
echo ============================================================
echo.
echo To install, copy this folder to:
echo   ^<Uniquenium-install^>\data\plugins\%PLUGIN_ID%\
echo.
echo Or to user data directory:
echo   %%APPDATA%%\Uniquenium\Plugins\%PLUGIN_ID%\
echo.
echo Then restart Uniquenium.
echo.

endlocal