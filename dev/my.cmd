@echo off

@REM Set script directory
set "SCRIPT_DIR=%~dp0"

@REM Check if already activated (only for reset and add commands)
if "%~1" equ "reset" goto CHECK_ACTIVATED
if "%~1" equ "add" goto CHECK_ACTIVATED
goto SKIP_ACTIVATION_CHECK

:CHECK_ACTIVATED
if defined _MY_ENV_ACTIVATED (
    echo Error: Environment is already activated. Use "my deactivate" first.
    goto :EOF
)

:SKIP_ACTIVATION_CHECK

@REM my list - List environments
if "%~1" equ "list" (
    echo Environments available:
    echo ======================
    for /d %%i in ("%~dp0envs\*") do (
        echo   %%~nxi
    )
    goto :EOF
) else if "%~1" equ "reset" (
    if "%~2" equ "" (
        echo Error: Usage: my reset [env_name]
        goto :EOF
    )
    
    @REM Check if environment exists
    if not exist "%SCRIPT_DIR%envs\%~2" (
        echo Error: Environment "%~2" does not exist.
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
    
    echo Environment "%~2" reset and activated.
    goto :EOF
) else if "%~1" equ "add" (
    if "%~2" equ "" (
        echo Error: Usage: my add [env_name]
        goto :EOF
    )
    
    @REM Check if environment exists
    if not exist "%SCRIPT_DIR%envs\%~2" (
        echo Error: Environment "%~2" does not exist.
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
        echo Error: No environment is activated.
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
    echo   my list                - List available environments
    echo   my reset [env_name]    - Reset and activate environment
    echo   my add [env_name]      - Add and activate environment
    echo   my deactivate          - Deactivate current environment
    echo   my help                - Show this help message
    goto :EOF
) else if "%~1" equ "" (
    echo Error: No command specified.
    echo Usage:
    echo   my list                - List available environments
    echo   my reset [env_name]    - Reset and activate environment
    echo   my add [env_name]      - Add and activate environment
    echo   my deactivate          - Deactivate current environment
    echo   my help                - Show this help message
    goto :EOF
) else (
    echo Error: Unknown command "%~1".
    echo Usage:
    echo   my list                - List available environments
    echo   my reset [env_name]    - Reset and activate environment
    echo   my add [env_name]      - Add and activate environment
    echo   my deactivate          - Deactivate current environment
    echo   my help                - Show this help message
    goto :EOF
)

:EOF