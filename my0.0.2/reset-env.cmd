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
if not exist "%~dp0envs\%~1" (
    echo dir: [90m%~dp0envs\%~1[0m is not exist
    goto :eof
)

@REM Save variables to keep
set "_MY_TEMP=%TEMP%"
set "_MY_TMP=%TMP%"
set "_MY_USERPROFILE=%USERPROFILE%"
set "_MY_USERNAME=%USERNAME%"
set "_MY_SystemRoot=%SystemRoot%"
set "_MY_ComSpec=%ComSpec%"
set "_MY_SystemDrive=%SystemDrive%"
set "_MY_PATH=%PATH%"
set "_MY_ENV=%MY_ENV%"

@REM Clear all environment variables except _MY_*
for /f "delims== tokens=1" %%a in ('set ^| findstr /v "^_MY_"') do set "%%a="

@REM Restore saved variables
set "TEMP=%_MY_TEMP%"
set "TMP=%_MY_TMP%"
set "USERPROFILE=%_MY_USERPROFILE%"
set "USERNAME=%_MY_USERNAME%"
set "SystemRoot=%_MY_SystemRoot%"
set "ComSpec=%_MY_ComSpec%"
set "SystemDrive=%_MY_SystemDrive%"
set "PATH=%_MY_PATH%"
set "MY_ENV=%_MY_ENV%"

@REM Delete temporary save variables
@REM set "_MY_TEMP="
@REM set "_MY_TMP="
@REM set "_MY_USERPROFILE="
@REM set "_MY_USERNAME="
@REM set "_MY_SystemRoot="
@REM set "_MY_ComSpec="
@REM set "_MY_SystemDrive="
@REM set "_MY_PATH="
@REM set "_MY_PROMPT="
@REM set "_MY_ENV="
for /f "delims== tokens=1" %%a in ('set ^| findstr "_MY_"') do set "%%a="

@REM Reset PROMPT and MY_ENV
set "PROMPT=[%~1] $P$G"
set "MY_ENV=%~1"

@REM TEMP;TMP;USERPROFILE;USERNAME;SystemRoot;ComSpec;SystemDrive
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

@REM Process path.ini
set "NEW_PATH="
@REM Add default paths first
call :append_path C:\Windows\system32
call :append_path C:\Windows
call :append_path C:\Windows\System32\Wbem
call :append_path C:\Windows\System32\WindowsPowerShell\v1.0\
call :append_path C:\Windows\System32\OpenSSH\

@REM Then add user paths
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

@REM Remove trailing semicolon
setlocal enabledelayedexpansion
if not "!NEW_PATH!"=="" (
    set "NEW_PATH=!NEW_PATH:~0,-1!"
)
set "Path=!NEW_PATH!"
endlocal & set "Path=%Path%"

@REM Clear temporary variables
set "NEW_PATH="

goto :eof

:deactivate
set "PROMPT=$P$G"
goto :eof

:append_path
setlocal enabledelayedexpansion
set "APPEND_PATH=%~1"
set "NEW_PATH=!NEW_PATH!!APPEND_PATH!;"
endlocal & set "NEW_PATH=%NEW_PATH%"
goto :eof
