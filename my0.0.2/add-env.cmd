@echo off

if "%~1"=="" (
    goto :deactivate
) else if "%~1"=="/" (
    goto :deactivate
) else if "%~1"=="\" (
    goto :deactivate
) else if "%~1"=="?" (
    goto :deactivate
) else if exist "%~dp0envs\%~1" (
    goto :activate
) else (
    echo error: %~1 is not found.
    goto :eof
)

:activate
@REM Save original environment variables if not already saved
if not defined _OLD_MY2_VIRTUAL_PROMPT (
    set "_OLD_MY2_VIRTUAL_PROMPT=%PROMPT%"
)
if not defined _OLD_MY2_VIRTUAL_PATH (
    set "_OLD_MY2_VIRTUAL_PATH=%PATH%"
)

@REM Reset PROMPT
set "PROMPT=[%~1] %_OLD_MY2_VIRTUAL_PROMPT%"

@REM Process path.ini - add user paths first
set "USER_PATHS="
if exist "%~dp0envs\%~1\path.ini" (
    echo [90mpaths: %~dp0envs\%~1\path.ini[0m
    for /f "usebackq delims=" %%a in (`type "%~dp0envs\%~1\path.ini" ^| findstr /v "^#" ^| findstr /v "^;"`) do (
        if not "%%a"=="" (
            call :append_path "%%a"
            echo [37m%%a[0m
        )
    )
    echo.
)

@REM Add remaining original path
call :append_path "%_OLD_MY2_VIRTUAL_PATH%"

@REM Remove trailing semicolon
if not "%USER_PATHS%"=="" (
    set "USER_PATHS=%USER_PATHS:~0,-1%"
)

@REM Set new PATH
set "PATH=%USER_PATHS%"

@REM Clear temporary variable
set "USER_PATHS="

@REM Load variables from variable.ini
if exist "%~dp0envs\%~1\variable.ini" (
    echo [90mvars: %~dp0envs\%~1\variable.ini[0m
    for /f "usebackq delims== tokens=1*" %%a in (`type "%~dp0envs\%~1\variable.ini" ^| findstr /v "^#" ^| findstr /v "^;"`) do (
        if not "%%a"=="" (
            set "%%a=%%b"
            echo [37m%%a=%%b[0m
        )
    )
    echo.
)

goto :eof

:deactivate
@REM Restore original environment variables if saved
if defined _OLD_MY2_VIRTUAL_PROMPT (
    set "PROMPT=%_OLD_MY2_VIRTUAL_PROMPT%"
    set "_OLD_MY2_VIRTUAL_PROMPT="
)

if defined _OLD_MY2_VIRTUAL_PATH (
    set "PATH=%_OLD_MY2_VIRTUAL_PATH%"
    set "_OLD_MY2_VIRTUAL_PATH="
)

goto :eof

:append_path
setlocal enabledelayedexpansion
set "APPEND_PATH=%~1"
set "USER_PATHS=!USER_PATHS!!APPEND_PATH!;"
endlocal & set "USER_PATHS=%USER_PATHS%"
goto :eof
