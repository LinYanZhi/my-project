@echo off
setlocal enabledelayedexpansion

@REM my env 
if "%~1" equ "env" (
    @REM my env list
    if "%~2" equ "list" (
        @REM 调用环境列表命令
        call "%~dp0env\list.cmd"
        exit /b 0
    ) else if "%~2" equ "rename" (
        @REM 调用环境重命名命令 - 使用完整命令行
        call "%~dp0env\rename.cmd" %~3 %~4
        exit /b 0
    ) else if "%~2" equ "create" (
        @REM 调用环境创建命令
        call "%~dp0env\create.cmd" %~3
        exit /b 0
    ) else if "%~2" equ "remove" (
        @REM 调用环境删除命令
        call "%~dp0env\remove.cmd" %~3
        exit /b 0
    ) else (
        echo error
        exit /b 0
    )
) else if "%~1" equ "activate" (
    @REM my activate
    if "%~2" equ "" (
        echo error: my activate [name]
        exit /b 1
    )
    call "%~dp0activate.cmd" %~2
) else if "%~1" equ "deactivate" (
    @REM my deactivate
    call "%~dp0deactivate.cmd"
) else if "%~1" equ "help" (
    @REM my help - 显示帮助信息
    echo.
    echo please input:
    echo    my activate [name]
    echo    my deactivate
    echo    my env list
    echo    my env rename old-name new-name
    echo    my env create [name]
    echo    my env remove [name]
    exit /b 1
) else if "%~1" equ "" (
    @REM my 无参数 - 检查MY_ENV环境变量
    if not "%MY_ENV%" equ "" (
        @REM 如果存在MY_ENV环境变量，则触发my activate %MY_ENV%
        call "%~dp0my.cmd" activate %MY_ENV%
        exit /b 0
    ) else (
        @REM 如果不存在 MY_ENV 环境变量 则提示错误
        echo error: my, must set MY_ENV environment variable
        exit /b 1
    )
) else (
    @REM 如果不存在MY_ENV环境变量，则显示帮助信息
    echo.
    echo please input:
    echo    my activate [name]
    echo    my env list
    echo    my env rename old-name new-name
    echo    my env create [name]
    echo    my env remove [name]
    exit /b 1
)