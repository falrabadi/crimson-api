@echo off
setlocal

echo ================================
echo  Cosmos API - Create Service
echo ================================
echo.

set /p SERVICE_NAME=Enter service name (e.g. Auth, Orders, Notifications):

if "%SERVICE_NAME%"=="" (
    echo Error: Service name cannot be empty.
    exit /b 1
)

set /p PORT=Enter host port for this service (e.g. 5001, 5002):

if "%PORT%"=="" (
    echo Error: Port cannot be empty.
    exit /b 1
)

set FULL_NAME=Cosmos.%SERVICE_NAME%
set SERVICE_DIR=services\%FULL_NAME%

for /f %%i in ('powershell -NoProfile -Command "'%SERVICE_NAME%'.ToLower()"') do set SERVICE_LOWER=%%i
set COMPOSE_NAME=cosmos-%SERVICE_LOWER%

echo.
echo Service Name   : %FULL_NAME%
echo Location       : %SERVICE_DIR%
echo Compose Name   : %COMPOSE_NAME%
echo Port           : %PORT% -> 8080
echo.

set /p CONFIRM=Proceed? (y/n):
if /i not "%CONFIRM%"=="y" (
    echo Cancelled.
    exit /b 0
)

echo.
echo [1/7] Scaffolding Web API project...
dotnet new webapi -n %FULL_NAME% -o %SERVICE_DIR%\src --use-controllers --no-openapi
if errorlevel 1 ( echo Error scaffolding API project. & exit /b 1 )

echo [2/7] Scaffolding test project...
dotnet new xunit -n %FULL_NAME%.Tests -o %SERVICE_DIR%\tests
if errorlevel 1 ( echo Error scaffolding test project. & exit /b 1 )

echo [3/7] Linking test project to source project...
dotnet add %SERVICE_DIR%\tests\%FULL_NAME%.Tests.csproj reference %SERVICE_DIR%\src\%FULL_NAME%.csproj
if errorlevel 1 ( echo Error adding project reference. & exit /b 1 )

echo [4/7] Adding projects to solution...
dotnet sln cosmos-api.sln add %SERVICE_DIR%\src\%FULL_NAME%.csproj
dotnet sln cosmos-api.sln add %SERVICE_DIR%\tests\%FULL_NAME%.Tests.csproj

echo [5/7] Creating folder structure...
mkdir %SERVICE_DIR%\src\Controllers 2>nul
mkdir %SERVICE_DIR%\src\Services    2>nul
mkdir %SERVICE_DIR%\src\Models      2>nul
mkdir %SERVICE_DIR%\src\Middleware  2>nul
mkdir %SERVICE_DIR%\src\Config      2>nul

echo [6/7] Creating environment config and Dockerfile...

echo {} > %SERVICE_DIR%\src\appsettings.Staging.json
echo {} > %SERVICE_DIR%\src\appsettings.Production.json

del /q %SERVICE_DIR%\src\WeatherForecast.cs 2>nul
del /q %SERVICE_DIR%\src\Controllers\WeatherForecastController.cs 2>nul

echo FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS base > %SERVICE_DIR%\Dockerfile
echo WORKDIR /app >> %SERVICE_DIR%\Dockerfile
echo EXPOSE 8080 >> %SERVICE_DIR%\Dockerfile
echo. >> %SERVICE_DIR%\Dockerfile
echo FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build >> %SERVICE_DIR%\Dockerfile
echo WORKDIR /src >> %SERVICE_DIR%\Dockerfile
echo COPY src/%FULL_NAME%.csproj src/ >> %SERVICE_DIR%\Dockerfile
echo RUN dotnet restore src/%FULL_NAME%.csproj >> %SERVICE_DIR%\Dockerfile
echo COPY . . >> %SERVICE_DIR%\Dockerfile
echo WORKDIR /src/src >> %SERVICE_DIR%\Dockerfile
echo RUN dotnet build %FULL_NAME%.csproj -c Release -o /app/build >> %SERVICE_DIR%\Dockerfile
echo. >> %SERVICE_DIR%\Dockerfile
echo FROM build AS publish >> %SERVICE_DIR%\Dockerfile
echo RUN dotnet publish %FULL_NAME%.csproj -c Release -o /app/publish /p:UseAppHost=false >> %SERVICE_DIR%\Dockerfile
echo. >> %SERVICE_DIR%\Dockerfile
echo FROM base AS final >> %SERVICE_DIR%\Dockerfile
echo WORKDIR /app >> %SERVICE_DIR%\Dockerfile
echo COPY --from=publish /app/publish . >> %SERVICE_DIR%\Dockerfile
echo ENTRYPOINT ["dotnet", "%FULL_NAME%.dll"] >> %SERVICE_DIR%\Dockerfile

echo [7/7] Creating docker-compose.yml for service...
echo services:                                                    > %SERVICE_DIR%\docker-compose.yml
echo   %COMPOSE_NAME%:                                           >> %SERVICE_DIR%\docker-compose.yml
echo     build:                                                  >> %SERVICE_DIR%\docker-compose.yml
echo       context: .                                            >> %SERVICE_DIR%\docker-compose.yml
echo       dockerfile: Dockerfile                                >> %SERVICE_DIR%\docker-compose.yml
echo     ports:                                                  >> %SERVICE_DIR%\docker-compose.yml
echo       - '%PORT%:8080'                                       >> %SERVICE_DIR%\docker-compose.yml
echo     environment:                                            >> %SERVICE_DIR%\docker-compose.yml
echo       - ASPNETCORE_ENVIRONMENT=Development                  >> %SERVICE_DIR%\docker-compose.yml
echo       - ConnectionStrings__Postgres=Host=postgres;Database=cosmos;Username=cosmos;Password=cosmos >> %SERVICE_DIR%\docker-compose.yml
echo       - ConnectionStrings__Redis=redis:6379                 >> %SERVICE_DIR%\docker-compose.yml
echo     depends_on:                                             >> %SERVICE_DIR%\docker-compose.yml
echo       postgres:                                             >> %SERVICE_DIR%\docker-compose.yml
echo         condition: service_healthy                          >> %SERVICE_DIR%\docker-compose.yml
echo       redis:                                                >> %SERVICE_DIR%\docker-compose.yml
echo         condition: service_healthy                          >> %SERVICE_DIR%\docker-compose.yml

echo.
echo ================================
echo  Done! Service created.
echo ================================
echo.
echo  %SERVICE_DIR%\
echo  ├── src\
echo  │   ├── Controllers\
echo  │   ├── Services\
echo  │   ├── Models\
echo  │   ├── Middleware\
echo  │   ├── Config\
echo  │   ├── Program.cs
echo  │   ├── appsettings.json
echo  │   ├── appsettings.Development.json
echo  │   ├── appsettings.Staging.json
echo  │   └── appsettings.Production.json
echo  ├── tests\
echo  ├── Dockerfile
echo  └── docker-compose.yml
echo.
echo  Run with:
echo    scripts\run-service.bat
echo.

endlocal
