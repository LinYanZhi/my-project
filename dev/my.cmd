@echo off

@REM Check if already activated (only for add commands)
if "%~1" equ "a" goto CHECK_ACTIVATED
if "%~1" equ "add" goto CHECK_ACTIVATED
if "%~1" equ "activate" goto CHECK_ACTIVATED
goto SKIP_ACTIVATION_CHECK

:CHECK_ACTIVATED
if defined _MY_ENV_ACTIVATED (
    echo [31mError: Environment is already activated. Use "my d" to deactivate first.[0m
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
echo [90mAvailable environments:[0m
if exist "%~dp0envs" (
    for /d %%i in ("%~dp0envs\*") do (
        if "%_MY_CURRENT_ENV%"=="%%~nxi" (
            echo [92m  * %%~nxi[0m
        ) else (
            echo     %%~nxi
        )
    )
) else (
    echo No environments found.
)
goto :EOF

:ACTIVATE_ENV
if "%~2" equ "" (
    echo [31mError: Usage: my [a|add|activate] [env_name][0m
    goto :EOF
)

@REM Check if environment exists
if not exist "%~dp0envs\%~2" (
    echo [31mError: Environment "%~2" does not exist.[0m
    goto :EOF
)

@REM Check if WT_SESSION is defined
if not defined WT_SESSION (
    echo [31mError: WT_SESSION environment variable is not defined.[0m
    echo [31mThis script requires WT_SESSION to save/restore environment.[0m
    goto :EOF
)

@REM Save original PROMPT before modifying it
set "_MY_OLD_PROMPT=%PROMPT%"

@REM Save current environment to WT_SESSION.bat file
set "_ENV_HISTORY_FILE=%~dp0%WT_SESSION%.bat"
echo @echo off > "%_ENV_HISTORY_FILE%"
if errorlevel 1 (
    echo [31mError: Failed to create environment history file: %_ENV_HISTORY_FILE%[0m
    @REM Clear temporary variables
    set "_ENV_HISTORY_FILE="
    set "_MY_OLD_PROMPT="
    goto :EOF
)

@REM Export all environment variables
for /f "delims==" %%a in ('set') do (
    if defined %%a (
        for /f "delims=" %%b in ('cmd /c "echo %%%%a%%"') do (
            echo set "%%a=%%b" >> "%_ENV_HISTORY_FILE%"
        )
    )
)

echo [90mEnvironment history saved to: %WT_SESSION%.bat[0m

@REM Load path.ini
set "_PATH_INI=%~dp0envs\%~2\path.ini"
if exist "%_PATH_INI%" (
    @REM Read path.ini file line by line
    for /f "usebackq delims=" %%a in ("%_PATH_INI%") do (
        @REM Skip comment lines
        echo %%a | findstr /B "#" >nul 2>&1
        if errorlevel 1 (
            @REM Skip empty lines
            if not "%%a"=="" (
                if exist "%%a" 2>&1 (
                    set "PATH=%%a;%PATH%"
                )
            )
        )
    )
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
                @REM Save original value if variable exists
                if defined %%a (
                    for /f "delims=" %%v in ('cmd /c "echo %%%%a%%"') do (
                        echo set "%%a=%%v" >> "%_MY_ENV_CLEAN_FILE%"
                    )
                ) else (
                    @REM Variable didn't exist before, clear it on deactivation
                    echo set "%%a=" >> "%_MY_ENV_CLEAN_FILE%"
                )
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

echo [32mEnvironment "%~2" activated successfully.[0m

@REM Clear temporary variables
set "_VAR_INI="
set "_MY_ENV_CLEAN_FILE="
set "_PATH_INI="
set "_ENV_HISTORY_FILE="
goto :EOF

:DEACTIVATE_ENV
if not defined _MY_ENV_ACTIVATED (
    echo [31mError: No environment is activated.[0m
    goto :EOF
)

@REM Check if WT_SESSION is defined
if not defined WT_SESSION (
    echo [31mError: WT_SESSION environment variable is not defined.[0m
    echo [31mCannot restore environment history.[0m
    goto :EOF
)

@REM Restore environment from WT_SESSION.bat file
set "_ENV_HISTORY_FILE=%~dp0%WT_SESSION%.bat"
if exist "%_ENV_HISTORY_FILE%" (
    echo [90mRestoring environment from: %WT_SESSION%.bat[0m
    call "%_ENV_HISTORY_FILE%"
    del "%_ENV_HISTORY_FILE%"
) else (
    echo [33mWarning: Environment history file not found: %_ENV_HISTORY_FILE%[0m
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

echo [32mEnvironment deactivated successfully.[0m
goto :EOF

:SHOW_HELP
echo Usage:
echo   my [96mlist[0m                          - List available environments
echo   my [92ma[0m [env_name]                 - Activate environment
echo   my [92madd[0m [env_name]               - Activate environment
echo   my [92mactivate[0m [env_name]          - Activate environment
echo   my [33md[0m                            - Deactivate current environment
echo   my [33mdel[0m                          - Deactivate current environment
echo   my [33mdeactivate[0m                   - Deactivate current environment
echo   my help                               - Show this help message
goto :EOF

:SHOW_ERROR
echo [31mError: Unknown command "%~1".[0m
echo Usage:
echo   my [96mlist[0m                    - List available environments
echo   my [92ma[0m [env_name]            - Activate environment
echo   my [92madd[0m [env_name]          - Activate environment
echo   my [92mactivate[0m [env_name]     - Activate environment
echo   my [33md[0m                       - Deactivate current environment
echo   my [33mdel[0m                     - Deactivate current environment
echo   my [33mdeactivate[0m              - Deactivate current environment
echo   my help                    - Show this help message
goto :EOF

:EOF