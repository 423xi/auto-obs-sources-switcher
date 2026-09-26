@echo off
setlocal
echo Finding Visual Studio installation...
for /f "usebackq tokens=*" %%i in (`"%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe" -latest -property installationPath`) do (
    set "VS_PATH=%%i"
)

if not defined VS_PATH (
    echo [ERROR] Visual Studio / MSVC build tools not found!
    exit /b 1
)

echo Initializing MSVC x64 build environment...
call "%VS_PATH%\VC\Auxiliary\Build\vcvars64.bat"

echo Compiling fg_helper.dll...
cl.exe /O2 /LD /MT fg_helper.cpp user32.lib /Fe:fg_helper.dll

if %ERRORLEVEL% EQU 0 (
    echo [SUCCESS] fg_helper.dll compiled successfully!
    del *.obj *.lib *.exp 2>nul
) else (
    echo [FAILED] Compilation failed!
)
endlocal
