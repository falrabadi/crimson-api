@echo off
setlocal

echo ================================
echo  Crimson API - Run Service
echo ================================
echo.

set /p SERVICE_NAME=Enter service name (e.g. Auth, Orders, Notifications):

if "%SERVICE_NAME%"=="" (
    echo Error: Service name cannot be empty.
    exit /b 1
)

set FULL_NAME=Crimson.%SERVICE_NAME%
set SERVICE_DIR=services\%FULL_NAME%
set COMPOSE_FILE=%SERVICE_DIR%\docker-compose.yml
set INFRA_FILE=infra\docker-compose.yml
set ENV_FILE=infra\.env

if not exist "%COMPOSE_FILE%" (
    echo Error: No docker-compose.yml found at %COMPOSE_FILE%
    echo Make sure the service exists and was created with create-service.bat
    exit /b 1
)

if not exist "%ENV_FILE%" (
    echo Error: infra\.env not found.
    echo Copy infra\.env.example to infra\.env and fill in your values.
    exit /b 1
)

echo.
set /p REBUILD=Rebuild image before starting? (y/n):

echo.
echo Starting infrastructure + %FULL_NAME%...
echo.

if /i "%REBUILD%"=="y" (
    docker compose -f %INFRA_FILE% -f %COMPOSE_FILE% --env-file %ENV_FILE% up --build
) else (
    docker compose -f %INFRA_FILE% -f %COMPOSE_FILE% --env-file %ENV_FILE% up
)

endlocal
