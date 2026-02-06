@echo off
setlocal enabledelayedexpansion

@REM 检查参数
if "%~1" equ "" (
    echo error: my env remove [name]
    exit /b 1
)

set "ORIGINAL_ENV_NAME=%~1"
set "ENV_NAME=%~1"
set "ENV_DIR=%~dp0..\envs"
set "ENV_PATH=%ENV_DIR%\%ENV_NAME%"

@REM 检查环境名是否合法（只允许字母、数字、下划线、连字符）
set "VALID_CHARS=abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_-"
set "INVALID_FOUND=0"

@REM 检查每个字符是否合法
:CHECK_LOOP
if "%ENV_NAME%"=="" goto CHECK_DONE
set "CHAR=%ENV_NAME:~0,1%"
set "ENV_NAME=%ENV_NAME:~1%"

echo %VALID_CHARS% | findstr /c:"%CHAR%" >nul
if !errorlevel! neq 0 (
    set "INVALID_FOUND=1"
    goto CHECK_DONE
)
goto CHECK_LOOP

:CHECK_DONE
set "ENV_NAME=%ORIGINAL_ENV_NAME%"

if !INVALID_FOUND! equ 1 (
    echo error: Environment name can only contain letters, numbers, underscores, and hyphens
    exit /b 1
)

@REM 检查环境是否存在
if not exist "%ENV_PATH%" (
    echo error: Environment "%ENV_NAME%" does not exist
    exit /b 1
)

@REM 显示要删除的目录
echo.
echo The following directory will be deleted:
echo   %ENV_PATH%
echo.

@REM 询问确认
set /p "CONFIRM=Are you sure you want to delete environment "%ENV_NAME%"? (y/N): "
if /i not "!CONFIRM!"=="y" (
    echo Deletion cancelled
    exit /b 0
)

@REM 删除目录
rmdir /s /q "%ENV_PATH%" 2>nul
if !errorlevel! equ 0 (
    echo.
    echo Environment "%ENV_NAME%" deleted successfully!
    
    @REM 检查当前是否激活了该环境
    for /f "tokens=2 delims=[]" %%a in ("%PROMPT%") do (
        if "%%a"=="%ENV_NAME%" (
            echo.
            echo Warning: Currently active environment is "%ENV_NAME%"
            echo Suggest using "my deactivate" to exit the environment first
            echo.
        )
    )
) else (
    echo.
    echo Deletion failed
    exit /b 1
)

exit /b 0