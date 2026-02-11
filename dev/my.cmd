@echo off
@REM Absolutely not allowed setlocal enabledelayedexpansion
@REM Because this script is to change the environment
@REM This script follows the following rules:
@REM 1. Define as few variables as possible;
@REM 2. The defined variables begin with an underscore _;

@REM Check if already activated (only for add commands)
if "%~1" equ "a" goto CHECK_ACTIVATED
if "%~1" equ "add" goto CHECK_ACTIVATED
if "%~1" equ "activate" goto CHECK_ACTIVATED
goto SKIP_ACTIVATION_CHECK

:CHECK_ACTIVATED
if defined _MY_ENV_ACTIVATED (
    echo Error: Environment is already activated. Use "my d" to deactivate first.
    goto :EOF
)

:SKIP_ACTIVATION_CHECK

@REM my list - List environments
if "%~1" equ "list" goto LIST_ENVS
if "%~1" equ "a" goto ACTIVATE_ENV
if "%~1" equ "add" goto ACTIVATE_ENV
if "%~1" equ "activate" goto ACTIVATE_ENV
if "%~1" equ "d" goto DEACTIVATE_ENV
if "%~1" equ "del" goto DEACTIVATE_ENV
if "%~1" equ "deactivate" goto DEACTIVATE_ENV
if "%~1" equ "help" goto SHOW_HELP
goto SHOW_ERROR

:LIST_ENVS
echo Available environments:
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
echo Activating environment: `%~2`

@REM Check if environment exists
if not exist "%~dp0envs\%~2" (
    echo Error: Environment "%~2" does not exist.
    goto :EOF
)

@REM Check for --force or -f parameter
set "_MY_FORCE=0"
if "%~3" equ "--force" set "_MY_FORCE=1"
if "%~3" equ "-f" set "_MY_FORCE=1"

@REM Check if WT_SESSION is defined
if not defined WT_SESSION (
    @REM Only variable values WT_SESSION are allowed to be used as file names
    echo Error: WT_SESSION environment variable is not defined.
    echo This script requires WT_SESSION to save/restore environment.
    goto :EOF
)

@REM Save original PROMPT before modifying it
set "_MY_OLD_PROMPT=%PROMPT%"

@REM Save current environment to WT_SESSION.bat file
set "_ENV_HISTORY_FILE=%~dp0%WT_SESSION%.bat"
echo @echo off > "%_ENV_HISTORY_FILE%"
if errorlevel 1 (
    echo Error: Failed to create environment history file: %_ENV_HISTORY_FILE%
    @REM Clear temporary variables
    set "_ENV_HISTORY_FILE="
    set "_MY_OLD_PROMPT="
    goto :EOF
)

@REM Export all environment variables
for /f "delims==" %%a in ('set') do (
    for /f "delims=" %%b in ('cmd /c "echo %%%%a%%"') do (
        echo set "%%a=%%b" >> "%_ENV_HISTORY_FILE%"
    )
)

@REM Also include variables from variable.ini in environment history
set "_VAR_INI=%~dp0envs\%~2\variable.ini"
if exist "%_VAR_INI%" (
    @REM Read variable.ini file and add variables to environment history
    for /f "usebackq tokens=1,2 delims==" %%a in ("%_VAR_INI%") do (
        @REM Skip comment lines
        echo %%a | findstr /B "#" >nul
        if errorlevel 1 (
            @REM Skip empty lines
            if not "%%a"=="" (
                @REM Check if variable already exists in environment history
                @REM Use call to execute findstr and check errorlevel
                call :CHECK_VAR_EXISTS "%%a" "%_ENV_HISTORY_FILE%"
                if errorlevel 1 (
                    @REM Variable doesn't exist in current environment, add it as empty
                    echo set "%%a=" >> "%_ENV_HISTORY_FILE%"
                )
            )
        )
    )
)
set "_VAR_INI="

echo Environment history saved to: %WT_SESSION%.bat

@REM Load path.ini
set "_PATH_INI=%~dp0envs\%~2\path.ini"
if exist "%_PATH_INI%" (
    @REM Read path.ini file line by line and add paths directly
    @REM Simple approach: add paths one by one in file order
    for /f "usebackq delims=" %%a in ("%_PATH_INI%") do (
        @REM Skip comment lines
        echo %%a | findstr /B "#" >nul 2>&1
        if errorlevel 1 (
            @REM Skip empty lines
            if not "%%a"=="" (
                @REM Check if path exists (unless force is enabled)
                if "%_MY_FORCE%"=="0" (
                    if not exist "%%a" (
                        echo Skipping non-existent path: %%a
                    ) else (
                        @REM Add path to the beginning of PATH
                        echo Adding path: %%a
                        call set "PATH=%%a;%%PATH%%"
                    )
                ) else (
                    @REM Force mode - add path regardless of existence
                    echo Adding path: %%a
                    call set "PATH=%%a;%%PATH%%"
                )
            )
        )
    )

    echo on
    echo PATH updated successfully
    echo off
)

@REM Load variable.ini
set "_VAR_INI=%~dp0envs\%~2\variable.ini"
set "_MY_ENV_CLEAN_FILE=%~dp0%WT_SESSION%_clean.bat"
if exist "%_VAR_INI%" (
    @REM Read variable.ini file line by line
    for /f "usebackq tokens=1,2 delims==" %%a in ("%_VAR_INI%") do (
        @REM Skip comment lines
        echo %%a | findstr /B "#" >nul 2>&1
        if errorlevel 1 (
            @REM Skip empty lines
            if not "%%a"=="" (
                @REM Save original value (empty if not defined)
                set "_TEMP_VAR=%%%%a%%"
                for /f "delims=" %%v in ('cmd /c "echo.%_TEMP_VAR%"') do (
                    if "%%v"=="" (
                        echo set "%%a=" >> "%_MY_ENV_CLEAN_FILE%"
                    ) else (
                        echo set "%%a=%%v" >> "%_MY_ENV_CLEAN_FILE%"
                    )
                )
                set "_TEMP_VAR="
                @REM Set the new value
                set "%%a=%%b"
            )
        )
    )
)

@REM Update prompt
set "PROMPT=[%~2] %PROMPT%"

@REM Mark as activated
set _MY_ENV_ACTIVATED=1
set _MY_CURRENT_ENV=%~2

echo Environment "%~2" activated successfully.

@REM Clear temporary variables
set "_VAR_INI="
set "_MY_ENV_CLEAN_FILE="
set "_PATH_INI="
set "_ENV_HISTORY_FILE="
set "_MY_FORCE="
goto :EOF

:DEACTIVATE_ENV
if not defined _MY_ENV_ACTIVATED (
    echo Error: No environment is activated.
    goto :EOF
)

@REM Check if WT_SESSION is defined
if not defined WT_SESSION (
    echo Error: WT_SESSION environment variable is not defined.
    echo Cannot restore environment history.
    goto :EOF
)

@REM Restore environment from WT_SESSION.bat file
set "_ENV_HISTORY_FILE=%~dp0%WT_SESSION%.bat"
if exist "%_ENV_HISTORY_FILE%" (
    echo Restoring environment from: %WT_SESSION%.bat
    call "%_ENV_HISTORY_FILE%"
    del "%_ENV_HISTORY_FILE%"
) else (
    echo mWarning: Environment history file not found: %_ENV_HISTORY_FILE%
)

@REM Restore original PROMPT
if defined _MY_OLD_PROMPT (
    set "PROMPT=%_MY_OLD_PROMPT%"
    set "_MY_OLD_PROMPT="
)

@REM Clear environment variables that were set from variable.ini
set "_MY_ENV_CLEAN_FILE=%~dp0%WT_SESSION%_clean.bat"
if exist "%_MY_ENV_CLEAN_FILE%" (
    @REM Execute cleanup batch file
    call "%_MY_ENV_CLEAN_FILE%"
    @REM Delete cleanup file
    del "%_MY_ENV_CLEAN_FILE%"
)

@REM Clear activation flags
set "_MY_ENV_ACTIVATED="
set "_MY_CURRENT_ENV="

@REM Clear temporary variables
set "_MY_ENV_CLEAN_FILE="
set "_ENV_HISTORY_FILE="
set "_MY_OLD_PROMPT="

echo Environment deactivated successfully.
goto :EOF

:CHECK_VAR_EXISTS
@REM Subroutine to check if variable exists in environment history file
@REM Parameters: %1 = variable name, %2 = environment history file
set "_TEMP_FILE=%~dp0_check.tmp"
> "%_TEMP_FILE%" type "%~2"
findstr /C:"set \"%~1=" "%_TEMP_FILE%" >nul 2>nul
if errorlevel 1 (
    if exist "%_TEMP_FILE%" del "%_TEMP_FILE%"
    exit /b 1
) else (
    if exist "%_TEMP_FILE%" del "%_TEMP_FILE%"
    exit /b 0
)

:SHOW_ERROR
echo Error: Unknown command "%~1".
:SHOW_HELP
echo Usage:
echo   my list                    - List available environments
echo   my a [env_name]            - Activate environment
echo   my add [env_name]          
echo   my activate [env_name]     
echo   my md                      - Deactivate current environment
echo   my mdel                    
echo   my mdeactivate             
echo   my help                    - Show this help message
echo Params:
echo   -f                         - Force deactivation even if no environment is activated
echo   --force                    
goto :EOF

:EOF
