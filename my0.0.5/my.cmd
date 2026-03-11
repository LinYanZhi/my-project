@echo off
@REM my.cmd - Environment activation tool
@REM Version 0.0.5
@REM Design: Single .bat file per environment

@REM Generate WT_SESSION if not defined
if not defined WT_SESSION (
    @REM Use PowerShell to generate UUID for uniqueness
    for /f "tokens=*" %%a in ('powershell -Command "[guid]::NewGuid()"') do set "WT_SESSION=%%a"
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

@REM Command dispatcher
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
if "%~1"=="" goto SHOW_HELP
goto SHOW_ERROR

:LIST_ENVS
echo [90mAvailable envs:[0m
if exist "%~dp0envs" (
    for %%f in ("%~dp0envs\*.bat") do (
        if "%_MY_CURRENT_ENV%"=="%%~nf" (
            echo   [92m* %%~nf[0m
        ) else (
            echo     %%~nf
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

@REM Check if environment file exists
if not exist "%~dp0envs\%~2.bat" (
    echo [31mError: Env [0m[94m`%~2`[0m[31m not found.[0m
    goto :EOF
)

@REM Save current environment to cache
@REM Create cache directory if not exists
if not exist "%~dp0cache" mkdir "%~dp0cache"

@REM First: Add empty settings for variables from environment file (cleanup phase)
@REM This ensures that environment variables are properly cleared before restoration
> "%~dp0cache\%WT_SESSION%.bat" (
    echo @echo off
)

@REM Parse environment file and add empty settings for each variable
@REM Use a temporary file to store variable names
set "_MY_TEMP_VARS=%~dp0cache\_temp_vars_%RANDOM%.txt"
> "%_MY_TEMP_VARS%" (
    for /f "tokens=2 delims== " %%a in ('type "%~dp0envs\%~2.bat"') do (
        @REM Extract variable name from "VAR=value" format
        @REM Remove quotes from variable name
        echo %%~a
    )
)

@REM Read variable names from temp file and write empty settings to cache
for /f "usebackq" %%a in ("%_MY_TEMP_VARS%") do (
    echo set "%%a=" >> "%~dp0cache\%WT_SESSION%.bat"
)

@REM Clean up temp file
del "%_MY_TEMP_VARS%"
set "_MY_TEMP_VARS="

@REM Second: Export all environment variables (restoration phase)
@REM Write all variables at once for better performance
>> "%~dp0cache\%WT_SESSION%.bat" (
    for /f "tokens=1* delims==" %%a in ('set') do (
        echo set "%%a=%%b"
    )
)

if errorlevel 1 (
    echo [31mError: Failed to create env history file: [0m[90;4m%WT_SESSION%.bat[0m
    goto :EOF
)

echo Save Envs: [90;4m%WT_SESSION%.bat[0m

@REM Execute environment file
call "%~dp0envs\%~2.bat"

@REM Update prompt
set "PROMPT=[%~2] %PROMPT%"

@REM Mark as activated
set "_MY_ENV_ACTIVATED=1"
set "_MY_CURRENT_ENV=%~2"

@REM Display environment activation
call :SHOW_ENV_ACTIVATION "%~2"

echo [90m Activate: [0m`%~2` [92msuccess.[0m
goto :EOF

:DEACTIVATE_ENV
if not defined _MY_ENV_ACTIVATED (
    echo [31mError: No env active.[0m
    goto :EOF
)

@REM Restore environment from cache
if exist "%~dp0cache\%WT_SESSION%.bat" (
    echo Reloading: [90;4m%WT_SESSION%.bat[0m
    call "%~dp0cache\%WT_SESSION%.bat"
    del "%~dp0cache\%WT_SESSION%.bat"
) else (
    echo [33mWarning: Env history file not found:[0m [90;4m%WT_SESSION%.bat[0m
)

@REM Save environment name before clearing flags
set "_MY_DEACTIVATING_ENV=%_MY_CURRENT_ENV%"

@REM Clear activation flags
set "_MY_ENV_ACTIVATED="
set "_MY_CURRENT_ENV="

echo [90mDeactivat: [0m`%_MY_DEACTIVATING_ENV%` [92msuccess.[0m
set "_MY_DEACTIVATING_ENV="
goto :EOF

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
if not exist "%~dp0cache" (
    echo   [33mNo cache directory found.[0m
    goto :EOF
)

@REM List all cache files
dir /b "%~dp0cache\*.bat" >nul 2>nul
if errorlevel 1 (
    echo   [33mNo cache files found.[0m
    goto :EOF
)

echo.
for /f "delims=" %%f in ('dir /b "%~dp0cache\*.bat"') do (
    echo   [90m[4m%%f[0m
)
goto :EOF

:CACHE_CLEAR
echo [90mCache files:[0m
if not exist "%~dp0cache" (
    echo   [33mNo cache directory found.[0m
    goto :EOF
)

@REM List all cache files
dir /b "%~dp0cache\*.bat" >nul 2>nul
if errorlevel 1 (
    echo   [33mNo cache files found.[0m
    goto :EOF
)

echo.
for /f "delims=" %%f in ('dir /b "%~dp0cache\*.bat"') do (
    echo   [90m[4m%%f[0m
)

echo.
echo [33mWarning: Delete all cache files.[0m
set /p "_MY_CONFIRM=Delete all cache files? (y/N): "
if /i not "%_MY_CONFIRM%"=="y" (
    echo [90mOperation cancelled.[0m
    set "_MY_CONFIRM="
    goto :EOF
)

@REM Delete all cache files
for /f "delims=" %%f in ('dir /b "%~dp0cache\*.bat"') do (
    del "%~dp0cache\%%f" >nul 2>nul
    if errorlevel 1 (
        echo [31mFailed to delete: [0m[90m%%f[0m
    ) else (
        echo [92mDeleted: [0m[90m%%f[0m
    )
)

echo [92mCache cleared.[0m
set "_MY_CONFIRM="
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
goto :EOF

:SHOW_ENV_ACTIVATION
@REM Display environment activation message
@REM Parameters: %1 = environment name
echo [90mEnvironment file:[0m [90;4m%~dp0envs\%~1.bat[0m
goto :EOF

:EXTRACT_VAR_NAME
@REM Extract variable name from quoted string
@REM Parameters: %1 = "VAR=value" or VAR=value
@REM Output: Writes "set VAR=" to cache file
set "_MY_EXTRACTED_VAR=%~1"
@REM Remove everything after first equals sign
for /f "tokens=1 delims==" %%v in ("%_MY_EXTRACTED_VAR%") do set "_MY_EXTRACTED_VAR=%%v"
@REM Write to cache file
echo set "%_MY_EXTRACTED_VAR%=" >> "%~dp0cache\%WT_SESSION%.bat"
set "_MY_EXTRACTED_VAR="
goto :EOF

:EOF