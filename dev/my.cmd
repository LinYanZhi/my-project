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
    echo [31mError: Environment is already activated. Use [0m[94m"my d"[0m[31m to deactivate first.[0m
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
if "%~1" equ "clear" goto CLEAR_CACHE
if "%~1" equ "help" goto SHOW_HELP
goto SHOW_ERROR

:LIST_ENVS
echo [90mAvailable environments:[0m
if exist "%~dp0envs" (
    for /d %%i in ("%~dp0envs\*") do (
        if "%_MY_CURRENT_ENV%"=="%%~nxi" (
            echo   [92m* %%~nxi[0m
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
    echo [31mError: Usage: my a env_name[0m
    goto :EOF
)
echo [90mActivating environment:[0m `%~2`

@REM Check if environment exists
if not exist "%~dp0envs\%~2" (
    echo [31mError: Environment [0m[94m"%~2"[0m[31m does not exist.[0m
    goto :EOF
)

@REM Check for --force or -f parameter
set "_MY_FORCE=0"
if "%~3" equ "--force" set "_MY_FORCE=1"
if "%~3" equ "-f" set "_MY_FORCE=1"

@REM Check if WT_SESSION is defined
if not defined WT_SESSION (
    @REM Only variable values WT_SESSION are allowed to be used as file names
    echo [31mError: WT_SESSION environment variable is not defined.[0m
    echo [33mThis script requires WT_SESSION to save/restore environment.[0m
    goto :EOF
)

@REM Save original PROMPT before modifying it
set "_MY_OLD_PROMPT=%PROMPT%"

@REM Save current environment to WT_SESSION.bat file
set "_ENV_HISTORY_FILE=%~dp0cache\%WT_SESSION%.bat"
echo @echo off > "%_ENV_HISTORY_FILE%"
if errorlevel 1 (
    echo [31mError: Failed to create environment history file: [0m[90;4m%_ENV_HISTORY_FILE%[0m
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
    @REM Use read.exe to filter comments and empty lines, then process key=value pairs
    for /f "tokens=1,2 delims==" %%a in ('read "%_VAR_INI%" -c "#" --skip-comments --skip-empty') do (
        @REM Check if variable already exists in environment history
        call :CHECK_VAR_EXISTS "%%a" "%_ENV_HISTORY_FILE%"
        if errorlevel 1 (
            @REM Variable doesn't exist in current environment, add it as empty
            echo set "%%a=" >> "%_ENV_HISTORY_FILE%"
        )
    )
)
set "_VAR_INI="

echo [90mEnvironment history saved to: [0m[90;4m%WT_SESSION%.bat[0m

@REM Load path.ini using read.exe (much simpler and more powerful)
set "_PATH_INI=%~dp0envs\%~2\path.ini"
if exist "%_PATH_INI%" (
    @REM Use read.exe to filter comments and empty lines
    for /f "delims=" %%a in ('read "%_PATH_INI%" -c "#" --skip-comments --skip-empty') do (
        @REM Check if path exists (unless force is enabled)
        if "%_MY_FORCE%"=="0" (
            if not exist "%%a" (
                        echo   [33mSkip path: [0m[90;4m%%a[0m
            ) else (
                @REM Add path to the beginning of PATH
                echo Adding path: [90;4m%%a[0m
                call set "PATH=%%a;%%PATH%%"
            )
        ) else (
            @REM Force mode - add path regardless of existence
            echo Adding path: [90;4m%%a[0m
            call set "PATH=%%a;%%PATH%%"
        )
    )

    echo on
    echo [92mPATH updated successfully[0m
    echo off
)

@REM Load variable.ini using read.exe
set "_VAR_INI=%~dp0envs\%~2\variable.ini"
set "_MY_ENV_CLEAN_FILE=%~dp0cache\%WT_SESSION%_clean.bat"
if exist "%_VAR_INI%" (
    @REM Use read.exe to filter comments and empty lines, then process key=value pairs
    for /f "tokens=1,2 delims==" %%a in ('read "%_VAR_INI%" -c "#" --skip-comments --skip-empty') do (
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

@REM Update prompt
set "PROMPT=[%~2] %PROMPT%"

@REM Mark as activated
set _MY_ENV_ACTIVATED=1
set _MY_CURRENT_ENV=%~2

echo [92mEnvironment "%~2" activated successfully.[0m

@REM Clear temporary variables
set "_VAR_INI="
set "_MY_ENV_CLEAN_FILE="
set "_PATH_INI="
set "_ENV_HISTORY_FILE="
set "_MY_FORCE="
goto :EOF

:DEACTIVATE_ENV
if not defined _MY_ENV_ACTIVATED (
    echo [31mError: No environment is activated.[0m
    goto :EOF
)

@REM Check if WT_SESSION is defined
if not defined WT_SESSION (
    echo [31mError: WT_SESSION environment variable is not defined.[0m
    echo [33mCannot restore environment history.[0m
    goto :EOF
)

@REM Restore environment from WT_SESSION.bat file
set "_ENV_HISTORY_FILE=%~dp0cache\%WT_SESSION%.bat"
if exist "%_ENV_HISTORY_FILE%" (
    echo [90mRestoring environment from:[0m [90;4m%WT_SESSION%.bat[0m
    call "%_ENV_HISTORY_FILE%"
    del "%_ENV_HISTORY_FILE%"
) else (
    echo [33mWarning: Environment history file not found:[0m [90;4m%_ENV_HISTORY_FILE%[0m
)

@REM Restore original PROMPT
if defined _MY_OLD_PROMPT (
    set "PROMPT=%_MY_OLD_PROMPT%"
    set "_MY_OLD_PROMPT="
)

@REM Clear environment variables that were set from variable.ini
set "_MY_ENV_CLEAN_FILE=%~dp0cache\%WT_SESSION%_clean.bat"
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

echo [92mEnvironment deactivated successfully.[0m
goto :EOF

:CHECK_VAR_EXISTS
@REM Subroutine to check if variable exists in environment history file
@REM Parameters: %1 = variable name, %2 = environment history file
set "_TEMP_FILE=%~dp0_check.tmp"
> "%_TEMP_FILE%" type "%~2"
cmd /c "findstr /C:\"set \\\"%~1=\" \"%_TEMP_FILE%\" >nul 2>nul"
if errorlevel 1 (
    if exist "%_TEMP_FILE%" del "%_TEMP_FILE%"
    set "_TEMP_FILE="
    exit /b 1
) else (
    if exist "%_TEMP_FILE%" del "%_TEMP_FILE%"
    set "_TEMP_FILE="
    exit /b 0
)

:CLEAR_CACHE
echo [90mCache files in cache directory:[0m
set "_CACHE_DIR=%~dp0cache"
if not exist "%_CACHE_DIR%" (
    echo   [33mNo cache directory found.[0m
    set "_CACHE_DIR="
    goto :EOF
)

@REM List all cache files
dir /b "%_CACHE_DIR%\*.bat" >nul 2>nul
if errorlevel 1 (
    echo   [33mNo cache files found.[0m
    set "_CACHE_DIR="
    goto :EOF
)

echo.
for /f "delims=" %%f in ('dir /b "%_CACHE_DIR%\*.bat"') do (
    echo   [90m[4m%%f[0m
)

echo.
echo [33mWarning: This will delete all cache files.[0m
set /p "_CONFIRM=Are you sure you want to delete all cache files? (y/N): "
if /i not "%_CONFIRM%"=="y" (
    echo [90mOperation cancelled.[0m
    set "_CACHE_DIR="
    set "_CONFIRM="
    goto :EOF
)

@REM Delete all cache files
for /f "delims=" %%f in ('dir /b "%_CACHE_DIR%\*.bat"') do (
    del "%_CACHE_DIR%\%%f" >nul 2>nul
    if errorlevel 1 (
        echo [31mFailed to delete: [0m[90m%%f[0m
    ) else (
        echo [92mDeleted: [0m[90m%%f[0m
    )
)

echo [92mAll cache files have been cleared.[0m
set "_CACHE_DIR="
set "_CONFIRM="
goto :EOF

:SHOW_ERROR
echo [31mError: Unknown command "[0m[5m%~1[0m[31m".[0m
:SHOW_HELP
echo [90mUsage:[0m
echo   my [96mlist[0m                    [90m- List available environments[0m
echo   my [92ma[0m [env_name]            [90m- Activate environment[0m
echo   my [92madd[0m [env_name]          
echo   my [92mactivate[0m [env_name]     
echo   my [93md[0m                       [90m- Deactivate current environment[0m
echo   my [93mdel[0m                    
echo   my [93mdeactivate[0m             
echo   my [96mclear[0m                   [90m- Clear all cache files[0m
echo   my [96mhelp[0m                    [90m- Show this help message[0m
echo [90mParams:[0m
echo    -[0m[95mf[0m                        [90m- Add the path if it does not exist[0m
echo   --[0m[95mforce[0m                    
goto :EOF

:EOF
