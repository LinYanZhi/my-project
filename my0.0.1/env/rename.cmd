@echo off
setlocal enabledelayedexpansion

@REM 直接获取旧名字和新名字参数
set "OLD_NAME=%~1"
set "NEW_NAME=%~2"

@REM 不允许无参数
if "!OLD_NAME!" equ "" (
    echo error: you must input old-name
    exit /b 1
) else if "!NEW_NAME!" equ "" (
    echo error: you must input new-name
    exit /b 1
)

@REM 两个环境名不能相同
if "!OLD_NAME!" equ "!NEW_NAME!" (
    echo error: old-name and new-name cannot be the same.
    exit /b 1
)

@REM 设置环境目录
set "ENV_DIR=%~dp0..\envs\"
set "OLD_PATH=!ENV_DIR!!OLD_NAME!"
set "NEW_PATH=!ENV_DIR!!NEW_NAME!"

@REM 检查旧环境是否存在
if not exist "!OLD_PATH!" (
    echo error: env '!OLD_NAME!' does not exist.
    exit /b 1
)

@REM 检查新环境是否已存在
if exist "!NEW_PATH!" (
    echo error: env '!NEW_NAME!' already exists.
    exit /b 1
)

@REM 执行重命名操作
echo rename env '!OLD_NAME!' to '!NEW_NAME!'...

@REM 重命名目录
move "!OLD_PATH!" "!NEW_PATH!" >nul 2>&1
if !errorlevel! equ 0 (
    echo success: rename env '!OLD_NAME!' to '!NEW_NAME!'.
) else (
    echo error: rename failed
    exit /b 1
)

exit /b 0