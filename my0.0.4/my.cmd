@echo off
@REM my0.0.4 - Ultra-fast environment switcher
@REM Pure CMD implementation for maximum efficiency
@REM No colors, no validation, just speed

@REM Generate WT_SESSION if not defined
if not defined WT_SESSION (
    set WT_SESSION=%RANDOM%-%RANDOM%-%RANDOM%-%RANDOM%
)

@REM Command routing
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

@REM Check if environment exists
if not exist "%~dp0envs\%~2" (
    echo Error: Env %~2 not found.
    goto :EOF
)

@REM Save current environment (minimal)
> "%~dp0cache\%WT_SESSION%.bat" (
    echo @echo off
    echo set "PATH=%PATH%"
    echo set "PROMPT=%PROMPT%"
    echo set "WT_SESSION=%WT_SESSION%"
    echo set "_MY_ENV_ACTIVATED=%_MY_ENV_ACTIVATED%"
    echo set "_MY_CURRENT_ENV=%_MY_CURRENT_ENV%"
)

@REM Load paths (no validation)
set "_PATH_INI=%~dp0envs\%~2\path.ini"
if exist "%_PATH_INI%" (
    @REM Read paths from path.ini and add to PATH
    for /f "usebackq delims=" %%a in ("%_PATH_INI%") do (
        @REM Skip comments and empty lines
        echo %%a | findstr /r "^\s*[#;]\|^\s*$" >nul
        if errorlevel 1 (
            set "PATH=%%a;%PATH%"
        )
    )
    set "_PATH_INI="
)

@REM Load variables
if exist "%~dp0envs\%~2\variable.ini" (
    for /f "tokens=1,2 delims==" %%a in ('type "%~dp0envs\%~2\variable.ini" ^| findstr /v "^# ^; ^$"') do (
        set "%%a=%%b"
    )
)

@REM Update prompt and mark as activated
set "PROMPT=[%~2] %PROMPT%"
set _MY_ENV_ACTIVATED=1
set _MY_CURRENT_ENV=%~2

echo Activated: %~2
set "_PATH_INI="
goto :EOF

:DEACTIVATE_ENV
if not defined _MY_ENV_ACTIVATED (
    echo Error: No env active.
    goto :EOF
)

@REM Restore environment
if exist "%~dp0cache\%WT_SESSION%.bat" (
    call "%~dp0cache\%WT_SESSION%.bat"
    del "%~dp0cache\%WT_SESSION%.bat"
)

@REM Clear activation flags
set "_MY_ENV_ACTIVATED="
set "_MY_CURRENT_ENV="

echo Deactivated: %_MY_CURRENT_ENV%
goto :EOF

:CACHE_MANAGEMENT
if "%~2" equ "l" goto CACHE_LIST
if "%~2" equ "list" goto CACHE_LIST
if "%~2" equ "c" goto CACHE_CLEAR
if "%~2" equ "clear" goto CACHE_CLEAR
echo Error: Usage: my cache list^|clear
goto :EOF

:CACHE_LIST
dir /b "%~dp0cache\*.bat" 2>nul
goto :EOF

:CACHE_CLEAR
del /q "%~dp0cache\*.bat" 2>nul
echo Cache cleared.
goto :EOF

:SHOW_ERROR
echo Error: Unknown command "%~1"
:SHOW_HELP
echo Usage:
echo     my list             - List environments
echo     my add [env_name]  - Activate environment
echo     my del             - Deactivate environment
echo     my cache list       - List cache files
echo     my cache clear     - Clear cache
echo     my help           - Show this help
goto :EOF