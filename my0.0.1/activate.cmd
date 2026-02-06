@echo off
setlocal enabledelayedexpansion

@REM 获取环境名称
set "ENV_NAME=%~1"

@REM 检查环境名称是否为空，如果为空则检查MY_ENV环境变量
if "%ENV_NAME%" equ "" (
    if not "%MY_ENV%" equ "" (
        @REM 使用MY_ENV环境变量的值
        set "ENV_NAME=%MY_ENV%"
    ) else (
        @REM 没有参数也没有MY_ENV环境变量
        exit /b 1
    )
)

@REM 构建环境目录路径
set "ENV_DIR=%~dp0envs\%ENV_NAME%"
set "ENV_VAR_FILE="
set "ENV_PATH_FILE="

@REM 检查环境目录是否存在
if not exist "%ENV_DIR%" (
    echo error: env directory %ENV_NAME% not found
    exit /b 1
)

@REM 在目录中查找配置文件（忽略文件扩展名）
for %%f in ("%ENV_DIR%\variable.*") do (
    if exist "%%f" (
        set "ENV_VAR_FILE=%%f"
        echo success: found %%f
    )
)

for %%f in ("%ENV_DIR%\path.*") do (
    if exist "%%f" (
        set "ENV_PATH_FILE=%%f"
        echo success: found %%f
    )
)

@REM 检查是否找到配置文件
if "!ENV_VAR_FILE!"=="" (
    echo error: no variable config file found in %ENV_DIR%
    exit /b 1
)
if "!ENV_PATH_FILE!"=="" (
    echo error: no path config file found in %ENV_DIR%
    exit /b 1
)
echo.

@REM -------------------------------------------------------------------------------------
@REM 要保存的环境变量 PS：一味清除所有环境变量 则会导致命令出错
set "MY_KEEP_VARS=TEMP;TMP;MY_ENV;USERPROFILE;USERNAME;SystemRoot;ComSpec;SystemDrive"

@REM 清空当前环境变量 除了 MY_KEEP_VARS 和本文件内定义的变量
for /f "delims==" %%i in ('set') do (
    set "MY_KEEP=0"
    for %%j in (%MY_KEEP_VARS%) do (
        if "%%i" equ "%%j" set "MY_KEEP=1"
    )
    @REM 保留本文件内定义的变量
    if "%%i" equ "ENV_NAME" set "MY_KEEP=1"
    if "%%i" equ "ENV_VAR_FILE" set "MY_KEEP=1"
    if "%%i" equ "ENV_PATH_FILE" set "MY_KEEP=1"
    if "%%i" equ "CONFIG_PATH" set "MY_KEEP=1"
    if "%%i" equ "MY_KEEP_VARS" set "MY_KEEP=1"
    if "%%i" equ "ENV_DIR" set "MY_KEEP=1"
    if "!MY_KEEP!" equ "0" (
        set "%%i="
    )
)
:: -------------------------------------------------------------------------------------
@REM =====================================================================================
@REM 加载环境变量配置（.env.var）
if exist "%ENV_VAR_FILE%" (
    for /f "usebackq delims=" %%a in ("%ENV_VAR_FILE%") do (
        set "line=%%a"
        if not "!line:~0,1!"=="#" if not "!line!"=="" (
            set "var="
            set "val="
            for /f "delims== tokens=1,*" %%b in ("!line!") do (
                set "var=%%b"
                set "val=%%c"
            )
            if not "!var!"=="" (
                if not "!val!"=="" (
                    set "!var!=!val!"
                ) else (
                    set "!var!="
                )
            )
        )
    )
)

@REM 加载PATH配置（.env.path）
set "CONFIG_PATH="
if exist "%ENV_PATH_FILE%" (
    for /f "usebackq delims=" %%a in ("%ENV_PATH_FILE%") do (
        set "line=%%a"
        if not "!line:~0,1!"=="#" if not "!line!"=="" (
            if not "!CONFIG_PATH!"=="" (
                set "CONFIG_PATH=!CONFIG_PATH!;!line!"
            ) else (
                set "CONFIG_PATH=!line!"
            )
        )
    )
)

@REM 要保存的系统路径
set "MY_KEEP_PATHS=C:\Windows\system32;C:\Windows;C:\Windows\System32\Wbem;C:\Windows\System32\WindowsPowerShell\v1.0\;C:\Windows\System32\OpenSSH\;"

@REM 合并PATH变量：配置文件中的在前，keep-paths中的在后
if not "!CONFIG_PATH!"=="" (
    @REM 如果.env.path文件中定义了路径，合并
    set "PATH=!MY_KEEP_PATHS!;!CONFIG_PATH!"
) else (
    @REM 如果.env.path文件中没有定义路径，只使用keep-paths
    set "PATH=!MY_KEEP_PATHS!"
)
@REM =====================================================================================
@REM 设置环境标识
set PROMPT=[%ENV_NAME%] $P$G
title %ENV_NAME%

@REM 强迫症 过河拆桥 清理前面使用的变量
set "var="
set "val="
set "line="
set "MY_KEEP_PATHS="
set "MY_KEEP_VARS="
set "MY_KEEP="
set "ENV_VAR_FILE="
set "ENV_PATH_FILE="
set "CONFIG_PATH="
set "ENV_NAME="
set "ENV_DIR="

:: 重启CMD
cmd /k