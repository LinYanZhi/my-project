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
    echo [31mError: Env already active. Use [0m[94m"my d"[0m[31m to deactivate first.[0m
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
echo [90mAvailable envs:[0m
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
echo  [90mActivate:[0m `%~2`

@REM Check if environment exists
if not exist "%~dp0envs\%~2" (
    echo [31mError: Env [0m[94m`%~2`[0m[31m not found.[0m
    goto :EOF
)

@REM Check for --force or -f parameter
set "_MY_FORCE=0"
if "%~3" equ "--force" set "_MY_FORCE=1"
if "%~3" equ "-f" set "_MY_FORCE=1"

@REM WT_SESSION is now automatically generated if not defined

@REM Save original PROMPT before modifying it
set "_MY_OLD_PROMPT=%PROMPT%"

@REM Save current environment to WT_SESSION.bat file
echo @echo off > "%~dp0cache\%WT_SESSION%.bat"
if errorlevel 1 (
    echo [31mError: Failed to create env history file: [0m[90;4m%WT_SESSION%.bat[0m
    @REM Clear temporary variables
    set "_MY_OLD_PROMPT="
    goto :EOF
)

@REM First: Add empty settings for variables from variable.ini (cleanup phase)
@REM This ensures that environment variables are properly cleared before restoration
if exist "%~dp0envs\%~2\variable.ini" (
    for /f "tokens=1,2 delims==" %%a in ('type "%~dp0envs\%~2\variable.ini" ^| findstr /v "^# ^; ^$"') do (
        @REM Add empty setting at the beginning (cleanup phase)
        @REM Use uppercase to ensure consistency with Windows environment variables
        for %%c in (%%a) do echo set "%%c=" >> "%~dp0cache\%WT_SESSION%.bat"
    )
)

@REM Second: Export all environment variables (restoration phase)
@REM Use consistent uppercase for environment variable names
for /f "delims==" %%a in ('set') do (
    for /f "delims=" %%b in ('cmd /c "echo %%%%a%%"') do (
        @REM Convert variable name to uppercase for consistency
        for %%c in (%%a) do echo set "%%c=%%b" >> "%~dp0cache\%WT_SESSION%.bat"
    )
)

echo Save Envs: [90;4m%WT_SESSION%.bat[0m

@REM Load path.ini using pure CMD commands (most efficient)
set "_PATH_INI=%~dp0envs\%~2\path.ini"
set "_USER_PATHS_FILE=%~dp0_user_paths.tmp"
if exist "%_USER_PATHS_FILE%" del "%_USER_PATHS_FILE%"
if exist "%_PATH_INI%" (
    @REM Use type and findstr to filter comments and empty lines
    @REM Collect paths in order to maintain config file order
    for /f "delims=" %%a in ('type "%_PATH_INI%" ^| findstr /v "^# ^; ^$"') do (
        @REM Check if path is a network path (starts with \\)
        set "_IS_NETWORK=0"
        call :DETECT_NETWORK_PATH "%%a"

        @REM Network paths are always added without existence check to avoid timeout
        @REM Local paths are checked for existence (unless force is enabled)
        if "%_MY_FORCE%"=="0" (
            call :CHECK_IS_NETWORK
            if errorlevel 1 (
                @REM Network path - skip existence check to avoid timeout
                echo  [32mAdd path: [0m[90;4m%%a[0m
                echo %%a>> "%_USER_PATHS_FILE%"
            ) else (
                @REM Local path - check existence
                if not exist "%%a" (
                    echo [33mSkip path: [0m[90;4m%%a[0m
                ) else (
                    echo  [32mAdd path: [0m[90;4m%%a[0m
                    echo %%a>> "%_USER_PATHS_FILE%"
                )
            )
        ) else (
            @REM Force mode - add all paths regardless of existence
            echo  [32mAdd path: [0m[90;4m%%a[0m
            echo %%a>> "%_USER_PATHS_FILE%"
        )
        set "_IS_NETWORK="
    )
)

@REM Add user paths to the beginning of PATH (before system paths)
@REM Read file in order and add each to PATH beginning
if exist "%_USER_PATHS_FILE%" (
    for /f "usebackq delims=" %%a in ("%_USER_PATHS_FILE%") do (
        call set "PATH=%%a;%%PATH%%"
    )
    del "%_USER_PATHS_FILE%"
)
set "_USER_PATHS_FILE="

@REM Get current environment variables BEFORE setting new ones
> "%~dp0_temp_env.txt" set

@REM Load variable.ini using pure CMD commands
if exist "%~dp0envs\%~2\variable.ini" (
    @REM Use type and findstr to filter comments and empty lines, then process key=value pairs
    for /f "tokens=1,2 delims==" %%a in ('type "%~dp0envs\%~2\variable.ini" ^| findstr /v "^# ^; ^$"') do (
        @REM Set the new value
        set "%%a=%%b"
    )
)

@REM Update prompt
set "PROMPT=[%~2] %PROMPT%"

@REM Mark as activated
set _MY_ENV_ACTIVATED=1
set _MY_CURRENT_ENV=%~2

@REM Display environment variables
call :SHOW_ENV_VARIABLES "%~2" "%~dp0_temp_env.txt"

echo [90m Activate: [0m`%~2` [92msuccess.[0m

@REM Cleanup temporary file
if exist "%~dp0_temp_env.txt" del "%~dp0_temp_env.txt"

@REM Clear temporary variables
set "_PATH_INI="
set "_MY_FORCE="
goto :EOF

:DETECT_NETWORK_PATH
@REM Subroutine to detect if a path is a network path
@REM Parameters: %1 = path to check
@REM Sets: _IS_NETWORK to 1 if network path, 0 otherwise
set "_IS_NETWORK=0"
set "_CHECK_PATH=%~1"
if "%_CHECK_PATH:~0,2%"=="\\" set "_IS_NETWORK=1"
set "_CHECK_PATH="
exit /b 0

:CHECK_IS_NETWORK
@REM Subroutine to check if current path is a network path
@REM Returns: exit code 1 if network path, 0 otherwise
if "%_IS_NETWORK%"=="1" exit /b 1
exit /b 0

:DEACTIVATE_ENV
if not defined _MY_ENV_ACTIVATED (
    echo [31mError: No env active.[0m
    goto :EOF
)

@REM WT_SESSION is now automatically generated if not defined

@REM Restore environment from WT_SESSION.bat file
if exist "%~dp0cache\%WT_SESSION%.bat" (
    echo Reloading: [90;4m%WT_SESSION%.bat[0m
    call "%~dp0cache\%WT_SESSION%.bat"
    del "%~dp0cache\%WT_SESSION%.bat"
) else (
    echo [33mWarning: Env history file not found:[0m [90;4m%WT_SESSION%.bat[0m
)

@REM Restore original PROMPT
if defined _MY_OLD_PROMPT (
    set "PROMPT=%_MY_OLD_PROMPT%"
    set "_MY_OLD_PROMPT="
)

@REM Clear activation flags
set "_MY_ENV_ACTIVATED="

echo [90mDeactivat: [0m`%_MY_CURRENT_ENV%` [92msuccess.[0m
set "_MY_CURRENT_ENV="
goto :EOF

:CHECK_VAR_EXISTS
@REM Subroutine to check if variable exists in environment history file
@REM Parameters: %1 = variable name, %2 = environment history file
setlocal
set "_TEMP_FILE=%~dp0_check.tmp"
> "%_TEMP_FILE%" type "%~2"
cmd /c "findstr /C:\"set \\\"%~1=\" \"%_TEMP_FILE%\" >nul 2>nul"
if errorlevel 1 (
    if exist "%_TEMP_FILE%" del "%_TEMP_FILE%"
    endlocal
    exit /b 1
) else (
    if exist "%_TEMP_FILE%" del "%_TEMP_FILE%"
    endlocal
    exit /b 0
)

:CACHE_MANAGEMENT
if "%~2"=="" (
    echo [31mError: Usage: my cache list,clear[0m
    goto :EOF
)

if "%~2" equ "l" goto CACHE_LIST
if "%~2" equ "list" goto CACHE_LIST
if "%~2" equ "c" goto CACHE_CLEAR
if "%~2" equ "clear" goto CACHE_CLEAR

echo [31mError: Unknown cache command "[0m[5m%~2[0m[31m". Use "list" or "clear".[0m
goto :EOF

:CACHE_LIST
echo [90mCache files:[0m
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
set "_CACHE_DIR="
goto :EOF

:CACHE_CLEAR
echo [90mCache files:[0m
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
echo [33mWarning: Delete all cache files.[0m
set /p "_CONFIRM=Delete all cache files? (y/N): "
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

echo [92mCache cleared.[0m
set "_CACHE_DIR="
set "_CONFIRM="
goto :EOF

:SHOW_ERROR
echo [31mError: Unknown command "[0m[5m%~1[0m[31m".[0m
:SHOW_HELP
echo [90mUsage:[0m
echo     my [96m list[0m             [90m- [l/list]          [0m
echo     my [92m  add[0m [env_name]  [90m- [a/add/activate]  [0m
echo     my [93m  del[0m             [90m- [d/del/deactivate][0m
echo     my [36mcache[0m list        [90m- [c l]             [0m
echo     my [36mcache[0m clear       [90m- [c c]             [0m
echo     my [0m help[0m             [90m- [h/help]          [0m
echo [90mParams:[0m
echo     --[0m[95mforce[0m              [90m- [-f/--force][0m
goto :EOF

:SHOW_ENV_VARIABLES
@REM Display environment variables with color coding
@REM Parameters: %1 = environment name, %2 = temporary environment file
setlocal enabledelayedexpansion

@REM Get environment variables from variable.ini
if not exist "%~dp0envs\%~1\variable.ini" (
    endlocal
    goto :EOF
)

@REM Read variable.ini and process each variable
set "_NEW_VARS=0"
set "_EXISTING_VARS=0"

@REM Calculate maximum variable name length for alignment
set "_MAX_NAME_LEN=0"
for /f "tokens=1,2 delims==" %%a in ('type "%~dp0envs\%~1\variable.ini" ^| findstr /v "^# ^; ^$"') do (
    set "_NAME_LEN=%%a"
    call :GET_STRING_LENGTH "!_NAME_LEN!"
    if !_LENGTH! gtr !_MAX_NAME_LEN! set "_MAX_NAME_LEN=!_LENGTH!"
)

@REM Display environment variables

@REM Use type and findstr to process variable.ini file
for /f "tokens=1,2 delims==" %%a in ('type "%~dp0envs\%~1\variable.ini" ^| findstr /v "^# ^; ^$"') do (
    @REM Check if variable already exists in current environment
    set "_VAR_EXISTS=0"
    for /f "usebackq tokens=1 delims==" %%x in ("%~2") do (
        if /i "%%x"=="%%a" set "_VAR_EXISTS=1"
    )
    
    @REM Calculate padding for alignment
    set "_NAME_LEN=%%a"
    call :GET_STRING_LENGTH "!_NAME_LEN!"
    set /a _PADDING=!_MAX_NAME_LEN! - !_LENGTH!
    set "_SPACES="
    for /l %%i in (1,1,!_PADDING!) do set "_SPACES=!_SPACES! "
    
    if !_VAR_EXISTS! equ 1 (
        @REM Update existing variable - show in yellow
        echo [33mRnew vari:[0m %%a!_SPACES! = %%b
        set /a _EXISTING_VARS+=1
    ) else (
        @REM Add new variable - show in green
        echo  [32mAdd vari:[0m %%a!_SPACES! = %%b
        set /a _NEW_VARS+=1
    )
)

endlocal
goto :EOF

:GET_STRING_LENGTH
@REM Subroutine to get string length
@REM Parameters: %1 = string to measure
setlocal enabledelayedexpansion
set "_STR=%~1"
set "_LENGTH=0"
:LOOP
if not "!_STR!"=="" (
    set "_STR=!_STR:~1!"
    set /a _LENGTH+=1
    goto LOOP
)
endlocal & set "_LENGTH=%_LENGTH%"
goto :EOF

:EOF
