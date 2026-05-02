@echo off
@REM my.cmd - Environment activation tool
@REM Version 0.0.6
@REM Design: Simplified - No environment restore, just activation

if "%~1" equ "l" goto LIST_ENVS
if "%~1" equ "list" goto LIST_ENVS
if "%~1" equ "a" goto ACTIVATE_ENV
if "%~1" equ "add" goto ACTIVATE_ENV
if "%~1" equ "activate" goto ACTIVATE_ENV
if "%~1" equ "h" goto SHOW_HELP
if "%~1" equ "help" goto SHOW_HELP
goto SHOW_ERROR

:LIST_ENVS
echo Available environments:
if exist "%~dp0envs" (
    for %%f in ("%~dp0envs\*.bat") do (
        echo   %%~nf
    )
) else (
    echo   No environments found.
)
goto :EOF

:ACTIVATE_ENV
if "%~2"=="" (
    echo Error: Usage: my a env_name
    goto :EOF
)

if not exist "%~dp0envs\%~2.bat" (
    echo Error: Environment '%~2' not found.
    echo Available environments:
    for %%f in ("%~dp0envs\*.bat") do (
        echo   %%~nf
    )
    goto :EOF
)

echo Activating: %~2
call "%~dp0envs\%~2.bat"
set "PROMPT=[%~2] %PROMPT%"
echo Environment '%~2' activated successfully.
goto :EOF

:SHOW_ERROR
echo Error: Unknown command '%~1'
:SHOW_HELP
echo Usage:
echo     my list          - List available environments (alias: l)
echo     my add [env]     - Activate environment (alias: a, activate)
echo     my help          - Show this help (alias: h)
goto :EOF