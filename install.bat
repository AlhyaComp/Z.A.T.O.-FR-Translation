@echo off
setlocal enabledelayedexpansion
chcp 65001 >nul 2>&1

echo ============================================
echo  Z.A.T.O. - French Translation Installer
echo ============================================
echo.

set "SCRIPT_DIR=%~dp0"
set "STEAM_APP_ID=4122860"
set "GAME_FOLDER=Z.A.T.O.  I Love the World and Everything In It"
set "GAME_DIR="

REM --- Try to find Steam install path from registry ---
set "STEAM_PATH="
for %%R in (
    "HKLM\SOFTWARE\WOW6432Node\Valve\Steam"
    "HKLM\SOFTWARE\Valve\Steam"
    "HKCU\SOFTWARE\Valve\Steam"
) do (
    if not defined STEAM_PATH (
        for /f "tokens=2*" %%A in ('reg query %%R /v InstallPath 2^>nul') do (
            set "STEAM_PATH=%%B"
        )
    )
)

REM If registry failed, try common default paths
if not defined STEAM_PATH (
    for %%D in (
        "C:\Program Files (x86)\Steam"
        "C:\Program Files\Steam"
        "%LOCALAPPDATA%\Programs\Steam"
    ) do (
        if not defined STEAM_PATH (
            if exist "%%~D\steam.exe" set "STEAM_PATH=%%~D"
        )
    )
)

if not defined STEAM_PATH (
    echo [!] Could not find Steam installation.
    goto :manual
)

echo [*] Steam found at: %STEAM_PATH%

REM --- Parse libraryfolders.vdf for all Steam library paths ---
set "VDF_FILE=%STEAM_PATH%\steamapps\libraryfolders.vdf"
if not exist "%VDF_FILE%" (
    echo [!] Could not find libraryfolders.vdf
    goto :manual
)

REM Check the default Steam library first
if exist "%STEAM_PATH%\steamapps\appmanifest_%STEAM_APP_ID%.acf" (
    set "GAME_DIR=%STEAM_PATH%\steamapps\common\%GAME_FOLDER%"
    goto :found
)

REM Parse additional library folders from VDF
for /f "usebackq tokens=*" %%L in ("%VDF_FILE%") do (
    set "LINE=%%L"
    REM Look for lines containing "path"
    echo !LINE! | findstr /i /c:"\"path\"" >nul 2>&1
    if !errorlevel! equ 0 (
        REM Extract the path value (between the last pair of quotes)
        for /f "tokens=2 delims=	" %%P in ("!LINE!") do (
            set "RAW=%%~P"
        )
        REM Clean up: the VDF format is "path"		"C:\path\here"
        REM We need to extract just the path portion
        for /f "tokens=4 delims=^"" %%V in ("!LINE!") do (
            set "LIB_PATH=%%V"
        )
        if defined LIB_PATH (
            REM Replace double backslashes with single
            set "LIB_PATH=!LIB_PATH:\\=\!"
            if exist "!LIB_PATH!\steamapps\appmanifest_%STEAM_APP_ID%.acf" (
                set "GAME_DIR=!LIB_PATH!\steamapps\common\%GAME_FOLDER%"
                goto :found
            )
        )
    )
)

echo [!] Z.A.T.O. (App ID %STEAM_APP_ID%) was not found in any Steam library.
goto :manual

:found
echo [*] Game found at: %GAME_DIR%
echo.

if not exist "%GAME_DIR%\game\" (
    echo [!] The game folder exists but has no 'game\' subfolder.
    echo     Path: %GAME_DIR%
    goto :manual
)

goto :install

:manual
echo.
echo Please enter the full path to the Z.A.T.O. game folder manually.
echo Example: C:\Program Files (x86)\Steam\steamapps\common\Z.A.T.O.  I Love the World and Everything In It
echo.
set /p "GAME_DIR=Game path: "

if not defined GAME_DIR (
    echo [!] No path entered. Aborting.
    goto :end
)

REM Remove surrounding quotes if present
set "GAME_DIR=!GAME_DIR:"=!"

if not exist "!GAME_DIR!\game\" (
    echo [!] Invalid path: could not find a 'game\' subfolder at:
    echo     !GAME_DIR!
    goto :end
)

:install
echo [*] Installing French translation...
echo.

REM Copy force_lang_fr.rpy
copy /y "%SCRIPT_DIR%force_lang_fr.rpy" "%GAME_DIR%\game\force_lang_fr.rpy" >nul 2>&1
if errorlevel 1 (
    echo [!] Failed to copy force_lang_fr.rpy
    goto :end
)
echo     Copied: force_lang_fr.rpy

REM Copy tl\french\ directory
xcopy /e /i /y "%SCRIPT_DIR%tl\french" "%GAME_DIR%\game\tl\french" >nul 2>&1
if errorlevel 1 (
    echo [!] Failed to copy tl\french\ folder
    goto :end
)
echo     Copied: tl\french\ (translation files)

echo.
echo ============================================
echo  Installation complete!
echo  Launch Z.A.T.O. and the game will be
echo  in French.
echo ============================================

:end
echo.
pause
endlocal
