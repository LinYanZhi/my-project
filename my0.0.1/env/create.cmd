@echo off
setlocal enabledelayedexpansion

@REM 检查参数
if "%~1" equ "" (
    echo error: my env create [name]
    exit /b 1
)

set "ORIGINAL_ENV_NAME=%~1"
set "ENV_NAME=%~1"
set "ENV_DIR=%~dp0..\envs"
set "ENV_PATH=%ENV_DIR%\%ENV_NAME%"
set "VAR_FILE=%ENV_PATH%\variable.ini"
set "PATH_FILE=%ENV_PATH%\path.ini"

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

@REM 检查环境是否已存在
if exist "%ENV_PATH%" (
    echo error: Environment "%ENV_NAME%" already exists
    exit /b 1
)

@REM 创建环境目录
mkdir "%ENV_PATH%" 2>nul

@REM 创建环境变量文件
echo # %ENV_NAME% Environment > "%VAR_FILE%"
echo. >> "%VAR_FILE%"
echo # Add environment variables here, format: VAR_NAME=value >> "%VAR_FILE%"
echo # Example: >> "%VAR_FILE%"
echo # PYTHON_HOME=C:\Path\To\Python >> "%VAR_FILE%"
echo # NODE_HOME=C:\Path\To\Node >> "%VAR_FILE%"
echo. >> "%VAR_FILE%"
echo # Add your environment variables >> "%VAR_FILE%"

@REM 创建路径文件
echo # %ENV_NAME% Environment > "%PATH_FILE%"
echo. >> "%PATH_FILE%"
echo # Add paths here, one per line >> "%PATH_FILE%"
echo # Example: >> "%PATH_FILE%"
echo # C:\Path\To\Tools >> "%PATH_FILE%"
echo # C:\Path\To\Scripts >> "%PATH_FILE%"
echo. >> "%PATH_FILE%"
echo # Script paths >> "%PATH_FILE%"
echo %~dp0..\ >> "%PATH_FILE%"
echo %~dp0..\.script\.bat >> "%PATH_FILE%"
echo %~dp0..\.script\.cmd >> "%PATH_FILE%"
echo. >> "%PATH_FILE%"
echo # Add your paths >> "%PATH_FILE%"

@REM 显示创建成功信息
echo.
echo env "%ENV_NAME%" created successfully!
echo.
echo Please edit the following files to configure the environment:
echo   %VAR_FILE%
echo   %PATH_FILE%
echo.
echo Use the following command to activate the environment:
echo   my activate %ENV_NAME%
echo.

exit /b 0