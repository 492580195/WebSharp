@echo off
set SELF=%~dp0

set FLAVOR=%1

if "%FLAVOR%" equ "" set FLAVOR=Release

if not exist "%SELF%\build\download.exe" (
	csc /out:"%SELF%\build\download.exe" "%SELF%\download.cs"
)

if not exist "%SELF%\build\nuget.exe" (
	"%SELF%\build\download.exe" http://nuget.org/nuget.exe "%SELF%\build\nuget.exe"
	"%SELF%\build\nuget.exe" update -self
)

cd "%SELF%\..\src\websharpjs\WebSharp.js"
msbuild WebSharp.js.sln /p:Configuration=Release /p:Platform="Any Cpu"
if %ERRORLEVEL% neq 0 exit /b -1
..\..\..\tools\build\nuget.exe pack WebSharp.js.nuspec -OutputDirectory ./bin/%FLAVOR%

if %ERRORLEVEL% neq 0 (
	echo Failure building Nuget package
	cd "%SELF%"
	exit /b -1
)

cd "%SELF%"
copy /y "%SELF%\..\src\websharpjs\WebSharp.js\bin\%FLAVOR%\*.nupkg" "%SELF%\build\nuget"
rem Make it available to the electron-dotnet module
copy /y "%SELF%\..\src\websharpjs\WebSharp.js\bin\%FLAVOR%\net451\*.dll" "%SELF%\..\lib\bin"
echo SUCCESS. Nuget package at %SELF%\build\nuget

echo Building Language Compilers
cd "%SELF%\..\src\websharp-cs\src\websharp-cs"
dotnet build websharp-cs.sln /p:Configuration=%FLAVOR% /p:Platform="Any CPU"

if %ERRORLEVEL% neq 0 (
	echo Failure building Language Compiler for C-Sharp
	cd "%SELF%"
	exit /b -1
)

cd "%SELF%"
echo SUCCESS. Language Compiler for C-Sharp

exit /b 0
