@echo off
@REM Absolutely not allowed setlocal enabledelayedexpansion
@REM Because this script is to change the environment
@REM This script follows the following rules:
@REM 1. Define as few variables as possible;
@REM 2. The defined variables begin with an underscore _;

@REM Generate WT_SESSION if not defined
if not defined WT_SESSION (
    for /f "delims=" %%g in ('powershell -Command "[System.Guid]::NewGuid().ToString()"') do set WT_SESSION=%%g
)

@REM Check if already activated (only for add commands)
if "%~1" equ "a" goto CHECK_ACTIVATED
if "%~1" equ "add" goto CHECK_ACTIVATED
if "%~1" equ "activate" goto CHECK_ACTIVATED
goto SKIP_ACTIVATION_CHECK

:CHECK_ACTIVATED
if defined _MY_ENV_ACTIVATED (
    echo Error: Env already active. Use "my d" to deactivate first.
    goto :EOF
)

:SKIP_ACTIVATION_CHECK

@REM my list - List environments
if "%~1" equ "l" goto LIST_ENVS
if "%~1" equ "list" goto LIST_ENVS
if "%~1" equ "a" goto ACTIVATE_ENV
if "%~1" equ "add" goto ACTIVATE_ENV
if "%~1" equ "activate" goto ACTIVATE_ENV
if "%~1" equ "d" goto DEACTIVATE_ENV
if "%~1" equ "del" goto DEACTIVATE_ENV
if "%~1" equ "deactivate" goto DEACTIVATE_ENV
if "%~1" equ "c" goto CACHE_MANAGEMENT
if "%~1" equ "cache" goto CACHE_MANAGEMENT
if "%~1" equ "h" goto SHOW_HELP
if "%~1" equ "help" goto SHOW_HELP
goto SHOW_ERROR

:LIST_ENVS
echo Available envs:
if exist "%~dp0envs" (
    for /d %%i in ("%~dp0envs\*") do (
        if "%_MY_CURRENT_ENV%"=="%%~nxi" (
            echo   * %%~nxi
        ) else (
            echo     %%~nxi
        )
    )
) else (
    echo No environments found.
)
goto :EOF

:ACTIVATE_ENV
if "%~2"=="" (
    echo Error: Usage: my a env_name
    goto :EOF
)
echo Activate: %~2

@REM Check if environment exists
if not exist "%~dp0envs\%~2" (
    echo Error: Env %~2 not found.
    goto :EOF
)

@REM Check for --force or -f parameter
set "_MY_FORCE=0"
if "%~3" equ "--force" set "_MY_FORCE=1"
if "%~3" equ "-f" set "_MY_FORCE=1"

@REM WT_SESSION is now automatically generated if not defined

@REM Save original PROMPT before modifying it
set "_MY_OLD_PROMPT=%PROMPT%"

@REM ULTIMATE OPTIMIZATION: Save only essential environment variables
echo Saving current environment...
> "%~dp0cache\%WT_SESSION%.bat" (
    echo @echo off
    @REM Save only critical environment variables to avoid PATH truncation
    echo set "PATH=%PATH%"
    echo set "PROMPT=%PROMPT%"
    echo set "WT_SESSION=%WT_SESSION%"
)
echo Save Envs: %WT_SESSION%.bat

@REM ULTIMATE OPTIMIZATION: Fast path loading without network checks
echo Loading paths...
set "_PATH_INI=%~dp0envs\%~2\path.ini"
if exist "%_PATH_INI%" (
    @REM Add paths directly without slow existence checks
    for /f "delims=" %%a in ('type "%_PATH_INI%" ^| findstr /v "^# ^; ^$"') do (
        echo Add path: %%a
        set "PATH=%%a;%PATH%"
    )
)
echo Paths loaded

@REM Load variable.ini
echo Loading variables...
if exist "%~dp0envs\%~2\variable.ini" (
    for /f "tokens=1,2 delims==" %%a in ('type "%~dp0envs\%~2\variable.ini" ^| findstr /v "^# ^; ^$"') do (
        set "%%a=%%b"
    )
)

@REM Update prompt
set "PROMPT=[%~2] %PROMPT%"

@REM Mark as activated
set _MY_ENV_ACTIVATED=1
set _MY_CURRENT_ENV=%~2

@REM Display environment variables
echo Displaying variables...
if exist "%~dp0envs\%~2\variable.ini" (
    for /f "tokens=1,2 delims==" %%a in ('type "%~dp0envs\%~2\variable.ini" ^| findstr /v "^# ^; ^$"') do (
        echo Add vari: %%a = %%b
    )
)

echo Activate: %~2 success.

@REM Clear temporary variables
set "_PATH_INI="
set "_MY_FORCE="
goto :EOF

:DEACTIVATE_ENV
if not defined _MY_ENV_ACTIVATED (
    echo Error: No env active.
    goto :EOF
)

echo Deactivate: %_MY_CURRENT_ENV%

@REM WT_SESSION is now automatically generated if not defined

@REM Restore environment from WT_SESSION.bat file
if exist "%~dp0cache\%WT_SESSION%.bat" (
    echo Reloading: %WT_SESSION%.bat
    call "%~dp0cache\%WT_SESSION%.bat"
    echo Environment restored successfully
) else (
    echo Warning: Env history file not found: %WT_SESSION%.bat
)

@REM Restore original PROMPT
if defined _MY_OLD_PROMPT (
    set "PROMPT=%_MY_OLD_PROMPT%"
    set "_MY_OLD_PROMPT="
)

@REM Clear activation flags
set "_MY_ENV_ACTIVATED="

echo Deactivate: %_MY_CURRENT_ENV% success.
set "_MY_CURRENT_ENV="
goto :EOF

:CACHE_MANAGEMENT
if "%~2"=="" (
    echo Error: Usage: my cache list,clear
    goto :EOF
)

if "%~2" equ "l" goto CACHE_LIST
if "%~2" equ "list" goto CACHE_LIST
if "%~2" equ "c" goto CACHE_CLEAR
if "%~2" equ "clear" goto CACHE_CLEAR

echo Error: Unknown cache command "%~2". Use "list" or "clear".
goto :EOF

:CACHE_LIST
echo Cache files:
set "_CACHE_DIR=%~dp0cache"
if not exist "%_CACHE_DIR%" (
    echo   No cache directory found.
    set "_CACHE_DIR="
    goto :EOF
)

@REM List all cache files
dir /b "%_CACHE_DIR%\*.bat" >nul 2>nul
if errorlevel 1 (
    echo   No cache files found.
    set "_CACHE_DIR="
    goto :EOF
)

echo.
for /f "delims=" %%f in ('dir /b "%_CACHE_DIR%\*.bat"') do (
    echo   %%f
)
set "_CACHE_DIR="
goto :EOF

:CACHE_CLEAR
echo Cache files:
set "_CACHE_DIR=%~dp0cache"
if not exist "%_CACHE_DIR%" (
    echo   No cache directory found.
    set "_CACHE_DIR="
    goto :EOF
)

@REM List all cache files
dir /b "%_CACHE_DIR%\*.bat" >nul 2>nul
if errorlevel 1 (
    echo   No cache files found.
    set "_CACHE_DIR="
    goto :EOF
)

echo.
for /f "delims=" %%f in ('dir /b "%_CACHE_DIR%\*.bat"') do (
    echo   %%f
)

echo.
echo Warning: Delete all cache files.
set /p "_CONFIRM=Delete all cache files? (y/N): "
if /i not "%_CONFIRM%"=="y" (
    echo Operation cancelled.
    set "_CACHE_DIR="
    set "_CONFIRM="
    goto :EOF
)

@REM Delete all cache files
for /f "delims=" %%f in ('dir /b "%_CACHE_DIR%\*.bat"') do (
    del "%_CACHE_DIR%\%%f" >nul 2>nul
    if errorlevel 1 (
        echo Failed to delete: %%f
    ) else (
        echo Deleted: %%f
    )
)

echo Cache cleared.
set "_CACHE_DIR="
set "_CONFIRM="
goto :EOF

:SHOW_ERROR
echo Error: Unknown command "%~1".
:SHOW_HELP
echo Usage:
echo     my list             - [l/list]
echo     my add [env_name]  - [a/add/activate]
echo     my del             - [d/del/deactivate]
echo     my cache list        - [c l]
echo     my cache clear       - [c c]
echo     my help             - [h/help]
echo Params:
echo     --force              - [-f/--force]
goto :EOF

:EOF