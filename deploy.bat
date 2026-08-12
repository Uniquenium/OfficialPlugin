@echo off
chcp 65001 >nul
setlocal EnableDelayedExpansion

rem ============================================================
rem  OfficialPlugin Packaging Script
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
if /i "%~1"=="--build-dir" set "BUILD_BIN=%~2"
if /i "%~1"=="-b" set "BUILD_BIN=%~2"

if "%CLEAN_MODE%"=="1" (
    if exist "%DIST_DIR%" (
        echo [CLEAN] Removing dist/ directory...
        rmdir /s /q "%DIST_DIR%"
    )
)

rem --- Find build output ---
if not defined BUILD_BIN (
    echo [SCAN] Searching for build output in %BUILD_DIR% ...
    for /f "delims=" %%F in ('dir /s /b "%BUILD_DIR%\*.dll" 2^>nul') do (
        set "BUILD_BIN=%%~dpF"
        set "BUILD_BIN=!BUILD_BIN:~0,-1!"
        goto :build_found
    )
    echo.
    echo [ERROR] No build output found. Please build the plugin first.
    echo Expected structure: OfficialPlugin\build\**\temp\bin\*.dll
    echo.
    echo Quick setup:
    echo   1. Open OfficialPlugin\CMakeLists.txt in Qt Creator
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

rem --- Find DLL ---
set "DLL_NAME="
for %%F in ("%BUILD_BIN%\*.dll") do (
    set "DLL_NAME=%%~nxF"
    goto :dll_found
)
echo [ERROR] No .dll file found in build output: %BUILD_BIN%
pause
exit /b 1
:dll_found
echo [INFO] DLL: %DLL_NAME%

rem --- Use plugin ID from plugin-info.json if available, else use DLL name ---
set "PLUGIN_ID="
for /f "usebackq tokens=2 delims=:," %%A in (`findstr /c:"\"id\"" "%SCRIPT_DIR%\plugin-info.json" 2^>nul`) do (
    set "RAW=%%A"
    set "RAW=!RAW:"=!"
    set "RAW=!RAW: =!"
    set "PLUGIN_ID=!RAW!"
)
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

rem --- Copy all root-level files (excluding DLL, build artifacts, qmldir, qmltypes, plugin-info) ---
for /f "delims=" %%F in ('dir /b /a:-d "%BUILD_BIN%" 2^>nul') do (
    if /i not "%%~xF"==".dll" (
        if /i not "%%~xF"==".qrc" (
            if /i not "%%~xF"==".qmltypes" (
                if /i not "%%F"=="qmldir" (
                    if /i not "%%F"=="plugin-info.json" (
                        copy /y "%BUILD_BIN%\%%F" "%DIST_PLUGIN%\" >nul
                        echo   [FILE]  %%F
                    )
                )
            )
        )
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

rem --- Copy plugin-info.json from source ---
if exist "%SCRIPT_DIR%\plugin-info.json" (
    copy /y "%SCRIPT_DIR%\plugin-info.json" "%DIST_PLUGIN%\" >nul
    echo   [INFO]  plugin-info.json
)

rem --- Copy defaultSettings.json from source ---
if exist "%SCRIPT_DIR%\defaultSettings.json" (
    copy /y "%SCRIPT_DIR%\defaultSettings.json" "%DIST_PLUGIN%\" >nul
    echo   [INFO]  defaultSettings.json
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