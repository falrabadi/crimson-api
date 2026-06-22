@echo off
setlocal

echo ================================
echo  Crimson API - Create Package
echo ================================
echo.

set /p PACKAGE_NAME=Enter package name (e.g. Shared.Contracts, Shared.Logging):

if "%PACKAGE_NAME%"=="" (
    echo Error: Package name cannot be empty.
    exit /b 1
)

set FULL_NAME=Crimson.%PACKAGE_NAME%
set PACKAGE_DIR=packages\%FULL_NAME%

echo.
echo Package Name : %FULL_NAME%
echo Location     : %PACKAGE_DIR%
echo.

set /p CONFIRM=Proceed? (y/n):
if /i not "%CONFIRM%"=="y" (
    echo Cancelled.
    exit /b 0
)

echo.
echo [1/4] Scaffolding class library project...
dotnet new classlib -n %FULL_NAME% -o %PACKAGE_DIR%\src
if errorlevel 1 ( echo Error scaffolding class library. & exit /b 1 )

echo [2/4] Scaffolding test project...
dotnet new xunit -n %FULL_NAME%.Tests -o %PACKAGE_DIR%\tests
if errorlevel 1 ( echo Error scaffolding test project. & exit /b 1 )

echo [3/4] Linking test project to source project...
dotnet add %PACKAGE_DIR%\tests\%FULL_NAME%.Tests.csproj reference %PACKAGE_DIR%\src\%FULL_NAME%.csproj
if errorlevel 1 ( echo Error adding project reference. & exit /b 1 )

echo [4/4] Adding projects to solution...
dotnet sln crimson-api.sln add %PACKAGE_DIR%\src\%FULL_NAME%.csproj
dotnet sln crimson-api.sln add %PACKAGE_DIR%\tests\%FULL_NAME%.Tests.csproj

del /q %PACKAGE_DIR%\src\Class1.cs 2>nul

echo.
echo ================================
echo  Done! Package created.
echo ================================
echo.
echo  %PACKAGE_DIR%\
echo  ├── src\
echo  │   └── %FULL_NAME%.csproj
echo  └── tests\
echo      └── %FULL_NAME%.Tests.csproj
echo.

endlocal
