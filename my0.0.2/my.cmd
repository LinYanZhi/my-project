@echo off
if "%1"=="list" (
    @REM List environments
    echo [90m%~dp0[0m
    echo.
    @REM Extract environment name from PROMPT
    setlocal
    set "CURRENT_ENV="
    for /f "tokens=1 delims=]" %%a in ("%PROMPT%") do (
        set "CURRENT_ENV=%%a"
    )
    set "CURRENT_ENV=!CURRENT_ENV:~1!"

    for /d %%i in ("%~dp0envs\*") do (
        if "%%~nxi"=="!CURRENT_ENV!" (
            echo [32m* %%~nxi[0m
        ) else (
            echo [37m  %%~nxi[0m
        )
    )
    @REM Clear temporary variable
    set "CURRENT_ENV="
    endlocal
) else if "%1"=="reset" (
    %~dp0reset-env.cmd %2
) else if "%1"=="add" (
    %~dp0add-env.cmd %2
) else (
    echo [31merror[0m:
    echo     my [32m list[0m
    echo     my [33mreset[0m [env_name]
    echo     my [36m  add[0m [env_name]
)