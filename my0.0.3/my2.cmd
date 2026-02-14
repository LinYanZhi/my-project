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

@REM Save current environment to WT_SESSION.bat file - OPTIMIZED VERSION
> "%~dp0cache\%WT_SESSION%.bat" echo @echo off
set > "%~dp0_temp_set.txt"
(
    for /f "usebackq tokens=1,* delims==" %%a in ("%~dp0_temp_set.txt") do (
        echo set "%%a=%%b"
    )
) >> "%~dp0cache\%WT_SESSION%.bat"
del "%~dp0_temp_set.txt"

echo Save Envs: %WT_SESSION%.bat

@REM Load path.ini using optimized method
set "_PATH_INI=%~dp0envs\%~2\path.ini"
if exist "%_PATH_INI%" (
    @REM Batch process paths for better performance
    set "_NEW_PATH="
    for /f "delims=" %%a in ('type "%_PATH_INI%" ^| findstr /v "^# ^; ^$"') do (
        @REM Check if path exists (unless force is enabled)
        if "%_MY_FORCE%"=="0" (
            if not exist "%%a" (
                echo Skip path: %%a
            ) else (
                echo Add path: %%a
                if defined _NEW_PATH (
                    set "_NEW_PATH=%%a;!_NEW_PATH!"
                ) else (
                    set "_NEW_PATH=%%a"
                )
            )
        ) else (
            @REM Force mode - add path regardless of existence
            echo Add path: %%a
            if defined _NEW_PATH (
                set "_NEW_PATH=%%a;!_NEW_PATH!"
            ) else (
                set "_NEW_PATH=%%a"
            )
        )
    )
    
    @REM Update PATH in one operation
    if defined _NEW_PATH (
        set "PATH=!_NEW_PATH!;%PATH%"
        set "_NEW_PATH="
    )
)

@REM Get current environment variables BEFORE setting new ones
> "%~dp0_temp_env.txt" set

@REM Load variable.ini using optimized method
if exist "%~dp0envs\%~2\variable.ini" (
    @REM Process variable.ini in one pass
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

@REM Display environment variables with optimized method
call :SHOW_ENV_VARIABLES_OPTIMIZED "%~2" "%~dp0_temp_env.txt"

echo Activate: %~2 success.

@REM Cleanup temporary file
if exist "%~dp0_temp_env.txt" del "%~dp0_temp_env.txt"

@REM Clear temporary variables
set "_PATH_INI="
set "_MY_FORCE="
goto :EOF

:DEACTIVATE_ENV
if not defined _MY_ENV_ACTIVATED (
    echo Error: No env active.
    goto :EOF
)

@REM WT_SESSION is now automatically generated if not defined

@REM Restore environment from WT_SESSION.bat file
if exist "%~dp0cache\%WT_SESSION%.bat" (
    echo Reloading: %WT_SESSION%.bat
    call "%~dp0cache\%WT_SESSION%.bat"
    del "%~dp0cache\%WT_SESSION%.bat"
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

:SHOW_ENV_VARIABLES_OPTIMIZED
@REM Optimized version of environment variable display
@REM Parameters: %1 = environment name, %2 = temporary environment file
setlocal enabledelayedexpansion

@REM Get environment variables from variable.ini
if not exist "%~dp0envs\%~1\variable.ini" (
    endlocal
    goto :EOF
)

@REM Pre-calculate maximum variable name length
set "_MAX_NAME_LEN=0"
for /f "tokens=1,2 delims==" %%a in ('type "%~dp0envs\%~1\variable.ini" ^| findstr /v "^# ^; ^$"') do (
    set "_VAR_NAME=%%a"
    call :GET_STRING_LENGTH_FAST "!_VAR_NAME!"
    if !_LENGTH! gtr !_MAX_NAME_LEN! set "_MAX_NAME_LEN=!_LENGTH!"
)

@REM Display environment variables with optimized processing
set "_NEW_VARS=0"
set "_EXISTING_VARS=0"

for /f "tokens=1,2 delims==" %%a in ('type "%~dp0envs\%~1\variable.ini" ^| findstr /v "^# ^; ^$"') do (
    @REM Check if variable already exists in current environment
    set "_VAR_EXISTS=0"
    for /f "usebackq tokens=1 delims==" %%x in ("%~2") do (
        if /i "%%x"=="%%a" set "_VAR_EXISTS=1"
    )
    
    @REM Calculate padding using fast method
    set "_VAR_NAME=%%a"
    call :GET_STRING_LENGTH_FAST "!_VAR_NAME!"
    set /a _PADDING=!_MAX_NAME_LEN! - !_LENGTH!
    set "_SPACES="
    for /l %%i in (1,1,!_PADDING!) do set "_SPACES=!_SPACES! "
    
    if !_VAR_EXISTS! equ 1 (
        @REM Update existing variable
        echo Rnew vari: %%a!_SPACES! = %%b
        set /a _EXISTING_VARS+=1
    ) else (
        @REM Add new variable
        echo Add vari: %%a!_SPACES! = %%b
        set /a _NEW_VARS+=1
    )
)

endlocal
goto :EOF

:GET_STRING_LENGTH_FAST
@REM Optimized string length calculation
@REM Parameters: %1 = string to measure
setlocal
set "_STR=%~1"
set "_LENGTH=0"

@REM Fast length calculation using string manipulation
if defined _STR (
    set "_LENGTH=1"
    :FAST_LOOP
    if not "!_STR:~%_LENGTH%!"=="" (
        set /a _LENGTH+=1
        goto FAST_LOOP
    )
)

endlocal & set "_LENGTH=%_LENGTH%"
goto :EOF

:EOF