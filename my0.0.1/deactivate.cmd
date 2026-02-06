@echo off
setlocal enabledelayedexpansion

@echo Restoring environment variables from registry...

@echo Restoring user environment variables...
for /f "skip=2 tokens=1,2*" %%a in ('reg query "HKCU\Environment" 2^>nul') do (
    if "%%a" neq "ERROR" (
        set "VAR_NAME=%%~a"
        set "VAR_VALUE=%%~c"

        echo !VAR_NAME! | findstr /r "^[a-zA-Z_][a-zA-Z0-9_]*$" >nul
        if !errorlevel! equ 0 (
            if "!VAR_NAME!" == "Path" (
                set "USER_PATH=!VAR_VALUE!"
            ) else (
                @REM 安全地设置环境变量
                for /f "delims=" %%x in ("!VAR_VALUE!") do set "!VAR_NAME!=!VAR_VALUE!"
            )
        )
    )
)

@echo Restoring system environment variables...
for /f "skip=2 tokens=1,2*" %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" 2^>nul') do (
    if "%%a" neq "ERROR" (
        set "VAR_NAME=%%~a"
        set "VAR_VALUE=%%~c"

        echo !VAR_NAME! | findstr /r "^[a-zA-Z_][a-zA-Z0-9_]*$" >nul
        if !errorlevel! equ 0 (
            if "!VAR_NAME!" == "Path" (
                set "SYSTEM_PATH=!VAR_VALUE!"
            ) else (
                for /f "delims=" %%x in ("!VAR_VALUE!") do set "!VAR_NAME!=!VAR_VALUE!"
            )
        )
    )
)

@echo Getting system basic information...

for /f "tokens=*" %%a in ('hostname') do set "COMPUTERNAME=%%a"

set "LOGONSERVER=\\%COMPUTERNAME%"

for /f "tokens=2 delims==" %%a in ('wmic cpu get NumberOfLogicalProcessors /value') do set "NUMBER_OF_PROCESSORS=%%a"

for /f "tokens=2 delims==" %%a in ('wmic computersystem get Domain /value') do set "USERDOMAIN=%%a"
if "%USERDOMAIN%" equ "WORKGROUP" set "USERDOMAIN=%COMPUTERNAME%"
set "USERDOMAIN_ROAMINGPROFILE=%USERDOMAIN%"

if not defined USERNAME for /f "tokens=2 delims==" %%a in ('wmic computersystem get UserName /value') do set "USERNAME=%%a"
if defined USERNAME for /f "tokens=* delims=\\" %%a in ("%USERNAME%") do set "USERNAME=%%a"

if not defined USERPROFILE set "USERPROFILE=%SystemDrive%\Users\%USERNAME%"

if defined SYSTEM_PATH (
    if defined USER_PATH (
        set "PATH=%SYSTEM_PATH%;%USER_PATH%"
    ) else (
        set "PATH=%SYSTEM_PATH%"
    )
) else (
    set "PATH=%SystemRoot%\system32;%SystemRoot%;%SystemRoot%\System32\Wbem;%SystemRoot%\System32\WindowsPowerShell\v1.0\;%SystemRoot%\System32\OpenSSH\"
)

@echo Ensuring Path variable contains all necessary default paths...
if not defined SystemRoot set "SystemRoot=C:\WINDOWS"
if not "%PATH%" == "%PATH:%SystemRoot%\system32;=%" set "PATH=%SystemRoot%\system32;%PATH%"
if not "%PATH%" == "%PATH:%SystemRoot%;=%" set "PATH=%SystemRoot%;%PATH%"
if not "%PATH%" == "%PATH:%SystemRoot%\System32\Wbem;=%" set "PATH=%SystemRoot%\System32\Wbem;%PATH%"
if not "%PATH%" == "%PATH:%SystemRoot%\System32\WindowsPowerShell\v1.0\;=%" set "PATH=%SystemRoot%\System32\WindowsPowerShell\v1.0\;%PATH%"
if not "%PATH%" == "%PATH:%SystemRoot%\System32\OpenSSH\;=%" set "PATH=%SystemRoot%\System32\OpenSSH\;%PATH%"

@echo Restoring critical system variables...

if not defined ALLUSERSPROFILE set "ALLUSERSPROFILE=%SystemDrive%\ProgramData"
if not defined APPDATA set "APPDATA=%USERPROFILE%\AppData\Roaming"
if not defined LOCALAPPDATA set "LOCALAPPDATA=%USERPROFILE%\AppData\Local"
if not defined PUBLIC set "PUBLIC=%SystemDrive%\Users\Public"
if not defined ComSpec set "ComSpec=%SystemRoot%\system32\cmd.exe"
if not defined PATHEXT set "PATHEXT=.COM;.EXE;.BAT;.CMD;.VBS;.VBE;.JS;.JSE;.WSF;.WSH;.MSC"
if not defined OS set "OS=Windows_NT"
if not defined windir set "windir=%SystemRoot%"
if not defined SystemRoot set "SystemRoot=C:\WINDOWS"
if not defined SystemDrive set "SystemDrive=C:"
if not defined HOMEDRIVE set "HOMEDRIVE=%SystemDrive%"
if not defined HOMEPATH set "HOMEPATH=\Users\%USERNAME%"

if not defined ProgramFiles set "ProgramFiles=%SystemDrive%\Program Files"
if not defined ProgramFiles(x86) set "ProgramFiles(x86)=%SystemDrive%\Program Files (x86)"
if not defined ProgramW6432 set "ProgramW6432=%SystemDrive%\Program Files"
if not defined CommonProgramFiles set "CommonProgramFiles=%SystemDrive%\Program Files\Common Files"
if not defined CommonProgramFiles(x86) set "CommonProgramFiles(x86)=%SystemDrive%\Program Files (x86)\Common Files"
if not defined CommonProgramW6432 set "CommonProgramW6432=%SystemDrive%\Program Files\Common Files"
if not defined DriverData set "DriverData=%SystemRoot%\System32\Drivers\DriverData"
if not defined OneDrive set "OneDrive=%USERPROFILE%\OneDrive"

for /f "skip=2 tokens=1,2*" %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" 2^>nul ^| find /i "processor"') do (
    if "%%a" neq "ERROR" (
        set "VAR_NAME=%%~a"
        set "VAR_VALUE=%%~c"
        for /f "delims=" %%x in ("!VAR_VALUE!") do set "!VAR_NAME!=!VAR_VALUE!"
    )
)

for /f "skip=2 tokens=1,2*" %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" 2^>nul ^| findstr /v "ERROR"') do (
    if not "%%a" == "" (
        set "VAR_NAME=%%~a"
        set "VAR_VALUE=%%~c"
        echo !VAR_NAME! | findstr /r "^[a-zA-Z_][a-zA-Z0-9_]*$" >nul
        if !errorlevel! equ 0 (
            if not "!VAR_VALUE!" == "" (
                for /f "delims=" %%x in ("!VAR_VALUE!") do set "!VAR_NAME!=!VAR_VALUE!"
            )
        )
    )
)

for /f "skip=2 tokens=1,2*" %%a in ('reg query "HKCU\Environment" 2^>nul ^| findstr /v "ERROR"') do (
    if not "%%a" == "" (
        set "VAR_NAME=%%~a"
        set "VAR_VALUE=%%~c"
        echo !VAR_NAME! | findstr /r "^[a-zA-Z_][a-zA-Z0-9_]*$" >nul
        if !errorlevel! equ 0 (
            if not "!VAR_VALUE!" == "" (
                for /f "delims=" %%x in ("!VAR_VALUE!") do set "!VAR_NAME!=!VAR_VALUE!"
            )
        )
    )
)

if not defined PROCESSOR_ARCHITECTURE (
    for /f "tokens=2 delims==" %%a in ('wmic os get OSArchitecture /value') do set "ARCH=%%a"
    if "!ARCH!" equ "64位" set "PROCESSOR_ARCHITECTURE=AMD64"
    if "!ARCH!" equ "32位" set "PROCESSOR_ARCHITECTURE=x86"
)
if not defined PROCESSOR_IDENTIFIER (
    for /f "tokens=2 delims==" %%a in ('wmic cpu get Description /value') do set "PROCESSOR_IDENTIFIER=%%a"
)
if not defined PROCESSOR_LEVEL for /f "tokens=2 delims==" %%a in ('wmic cpu get Level /value') do set "PROCESSOR_LEVEL=%%a"
if not defined PROCESSOR_REVISION for /f "tokens=2 delims==" %%a in ('wmic cpu get Revision /value') do set "PROCESSOR_REVISION=%%a"
if not defined ProgramData set "ProgramData=%SystemDrive%\ProgramData"
if not defined PSModulePath set "PSModulePath=%ProgramFiles%\WindowsPowerShell\Modules;%SystemRoot%\system32\WindowsPowerShell\v1.0\Modules"
if not defined SESSIONNAME set "SESSIONNAME=Console"
if not defined WSLENV set "WSLENV=WT_SESSION:WT_PROFILE_ID:"
if not defined WT_PROFILE_ID set "WT_PROFILE_ID={0caa0dad-35be-5f56-a8ff-afceeeaa6101}"
if not defined WT_SESSION for /f "tokens=3 delims= " %%a in ('tasklist ^| find "WindowsTerminal" 2^>nul') do set "WT_SESSION=%%a"

if "%TEMP%" == "%SystemRoot%\TEMP" (
    set "TEMP=%USERPROFILE%\AppData\Local\Temp"
    set "TMP=%USERPROFILE%\AppData\Local\Temp"
)

set "PROMPT=$P$G"
title Command Prompt

set "USER_PATH="
set "SYSTEM_PATH="
set "VAR_NAME="
set "VAR_VALUE="
set "TEMP_USERNAME="
set "ARCH="

cmd /k
