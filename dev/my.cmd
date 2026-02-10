@echo off

@REM Set script directory
set "SCRIPT_DIR=%~dp0"

@REM Check if already activated (only for add commands)
if "%~1" equ "add" goto CHECK_ACTIVATED
goto SKIP_ACTIVATION_CHECK

:CHECK_ACTIVATED
if defined _MY_ENV_ACTIVATED (
    echo [31mError: Environment is already activated. Use "my deactivate" first.[0m
    goto :EOF
)

:SKIP_ACTIVATION_CHECK

@REM my list - List environments
if "%~1" equ "list" (
    echo [90menvs:[0m
    for /d %%i in ("%~dp0envs\*") do (
        if "%_MY_CURRENT_ENV%"=="%%~nxi" (
            echo [92m  * %%~nxi[0m
        ) else (
            echo     %%~nxi
        )
    )
    goto :EOF
) else if "%~1" equ "add" (
    if "%~2" equ "" (
            echo [31mError: Usage: mm add [env_name][0m
            goto :EOF
        )
    
    @REM Check if environment exists
    if not exist "%SCRIPT_DIR%envs\%~2" (
        echo [31mError: Environment "%~2" does not exist.[0m
        goto :EOF
    )
    
    @REM Save original environment if not already saved
    if not defined _MY_ENV_ACTIVATED (
        @REM Save PATH and PROMPT specifically
        set "_MY_OLD_PATH=%PATH%"
        set "_MY_OLD_PROMPT=%PROMPT%"
    )
    
    @REM Load environment variables
    if exist "%SCRIPT_DIR%envs\%~2\path.ini" (
        @REM Read path.ini file line by line
        for /f "tokens=*" %%a in ('type "%SCRIPT_DIR%envs\%~2\path.ini" 2^>nul') do (
            @REM Skip comment lines
            echo %%a | findstr "^#" >nul || (
                @REM Skip empty lines
                if not "%%a"=="" (
                    @REM Ignore non-existent paths
                    @REM Only add existing paths to PATH
                    if exist "%%a" (
                        set "PATH=%%a;%PATH%"
                    )
                )
            )
        )
    )
    
    if exist "%SCRIPT_DIR%envs\%~2\variable.ini" (
        @REM Read variable.ini file line by line
        for /f "tokens=1,2 delims==" %%a in ('type "%SCRIPT_DIR%envs\%~2\variable.ini" 2^>nul') do (
            @REM Skip comment lines
            echo %%a | findstr "^#" >nul || (
                @REM Skip empty lines
                if not "%%a"=="" (
                    set "%%a=%%b"
                )
            )
        )
    )
    
    @REM Update prompt
    set "PROMPT=[%~2] %PROMPT%"
    
    @REM Mark as activated
    set "_MY_ENV_ACTIVATED=1"
    set "_MY_CURRENT_ENV=%~2"
    
    echo Environment "%~2" added and activated.
    goto :EOF
) else if "%~1" equ "deactivate" (
    if not defined _MY_ENV_ACTIVATED (
        echo [31mError: No environment is activated.[0m
        goto :EOF
    )
    
    @REM Restore original environment
    @REM Restore PATH and PROMPT specifically
    if defined _MY_OLD_PATH set "PATH=%_MY_OLD_PATH%"
    if defined _MY_OLD_PROMPT set "PROMPT=%_MY_OLD_PROMPT%"
    
    @REM Clear activation flags and old variables
    set "_MY_ENV_ACTIVATED="
    set "_MY_CURRENT_ENV="
    set "_MY_OLD_PATH="
    set "_MY_OLD_PROMPT="
    
    echo Environment deactivated.
    goto :EOF
) else if "%~1" equ "help" (
    echo Usage:
    echo   mm [96mlist[0m                - List available environments
    echo   mm [92madd[0m [env_name]      - Add and activate environment
    echo   mm [33mdeactivate[0m          - Deactivate current environment
    echo   mm help                - Show this help message
    goto :EOF
) else if "%~1" equ "" (
    echo [31mError: No command specified.[0m
    echo Usage:
    echo   mm [96mlist[0m                - List available environments
    echo   mm [92madd[0m [env_name]      - Add and activate environment
    echo   mm [33mdeactivate[0m          - Deactivate current environment
    echo   mm help                - Show this help message
    goto :EOF
) else (
    echo [31mError: Unknown command "%~1".[0m
    echo Usage:
    echo   mm [96mlist[0m                - List available environments
    echo   mm [92madd[0m [env_name]      - Add and activate environment
    echo   mm [33mdeactivate[0m          - Deactivate current environment
    echo   mm help                - Show this help message
    goto :EOF
)

:EOF