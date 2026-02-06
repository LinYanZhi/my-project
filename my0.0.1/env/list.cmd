@echo off
setlocal enabledelayedexpansion

echo.
echo # my envs:
echo #

@REM 检查自定义环境目录
set "ENV_DIR=%~dp0..\envs"
if exist "%ENV_DIR%" (
    @REM 遍历envs目录下的所有子目录
    for /d %%d in ("%ENV_DIR%\*") do (
        @REM 跳过envs目录本身
        if /i not "%%~nd"=="envs" (
            set "ENV_NAME=%%~nd"
            
            @REM 检查目录中是否有path.ini或variable.ini文件
            set "HAS_CONFIG=0"
            if exist "%%d\path.ini" set "HAS_CONFIG=1"
            if exist "%%d\variable.ini" set "HAS_CONFIG=1"
            
            if "!HAS_CONFIG!"=="1" (
                @REM 检查是否为当前激活环境
                set "ACTIVE_MARK="
                if not "%PROMPT%"=="" (
                    @REM 只检查中括号中的环境名称 [name]
                    set "prompt_copy=!PROMPT!"
                    @REM 查找方括号位置
                    echo "!prompt_copy!" | find "[" >nul 2>&1
                    if !errorlevel! equ 0 (
                        @REM 提取方括号内的环境名称
                        for /f "tokens=1,2 delims=[]" %%a in ("!prompt_copy!") do (
                            @REM 检查第一个非空token
                            if not "%%a"=="" (
                                if "%%a"=="!ENV_NAME!" (
                                    set "ACTIVE_MARK=*"
                                )
                            )
                            @REM 检查第二个token
                            if not "%%b"=="" (
                                if "%%b"=="!ENV_NAME!" (
                                    set "ACTIVE_MARK=*"
                                )
                            )
                        )
                    )
                )
                
                @REM 统一对齐到20个字符宽度
                set "PADDED_NAME=!ENV_NAME!"
                set "PADDED_NAME=!PADDED_NAME!                    "
                set "PADDED_NAME=!PADDED_NAME:~0,20!"
                
                @REM 显示环境信息
                if "!ACTIVE_MARK!"=="*" (
                    echo !PADDED_NAME! !ACTIVE_MARK! !ENV_DIR!\!ENV_NAME!
                ) else (
                    echo !PADDED_NAME!   !ENV_DIR!\!ENV_NAME!
                )
            )
        )
    )
)

echo.