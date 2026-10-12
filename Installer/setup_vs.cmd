@echo off
setlocal

rem Locate Visual Studio 2022 regardless of edition or installation directory.
set "sbie_vswhere=%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe"
if not exist "%sbie_vswhere%" (
  echo Visual Studio Installer was not found. Install Visual Studio 2022 with C++ build tools. >&2
  exit /b 1
)

set "sbie_vsroot="
for /f "usebackq delims=" %%I in (`""%sbie_vswhere%" -latest -products * -version "[17.0,18.0)" -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath"`) do set "sbie_vsroot=%%I"
if not defined sbie_vsroot (
  echo Visual Studio 2022 with x86/x64 C++ build tools was not found. >&2
  exit /b 1
)

set "sbie_vcvars="
if /i "%~1" == "Win32" set "sbie_vcvars=%sbie_vsroot%\VC\Auxiliary\Build\vcvars32.bat"
if /i "%~1" == "x64" set "sbie_vcvars=%sbie_vsroot%\VC\Auxiliary\Build\vcvars64.bat"
if /i "%~1" == "ARM64" set "sbie_vcvars=%sbie_vsroot%\VC\Auxiliary\Build\vcvarsamd64_arm64.bat"
if not defined sbie_vcvars (
  echo Unsupported architecture "%~1". Expected Win32, x64, or ARM64. >&2
  exit /b 1
)
if not exist "%sbie_vcvars%" (
  echo Required Visual Studio environment script was not found: "%sbie_vcvars%" >&2
  exit /b 1
)

rem Leave the initialized compiler environment available to the calling script.
endlocal & call "%sbie_vcvars%"
exit /b %errorlevel%
