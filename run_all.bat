@echo off
TITLE Microservices Ecosystem Master Script (Resources Version)
echo ======================================================
echo 🚀 STARTING MICROSERVICES ECOSYSTEM
echo ======================================================

:: Paths relative to the script location (z-resources)
set RESOURCES_DIR=%~dp0
set PROJECT_ROOT=%RESOURCES_DIR%..
set SOFTWARE_DIR=%PROJECT_ROOT%\SOFTWARE_INSTALLED

:: 1. Fix Windows Path Issues for Kafka using Subst
echo 🛠️ Mapping Z: drive to SOFTWARE_INSTALLED for Kafka...
subst Z: /D >nul 2>&1
subst Z: "%SOFTWARE_DIR%"
echo ✅ Z: drive mapped to %SOFTWARE_DIR%

:: 2. Start Infrastructure Services
echo 🐘 Starting Zookeeper...
start "ZOOKEEPER" /D "Z:\kafka\bin\windows" cmd /k "zookeeper-server-start.bat Z:\kafka\config\zookeeper.properties"
timeout /t 5 >nul

echo 🪵 Starting Kafka...
start "KAFKA" /D "Z:\kafka\bin\windows" cmd /k "kafka-server-start.bat Z:\kafka\config\server.properties"
timeout /t 8 >nul

echo 🔴 Starting Redis...
start "REDIS" /D "%SOFTWARE_DIR%\Redis" cmd /k "redis-server.exe"

echo 👁️ Starting Zipkin...
start "ZIPKIN" cmd /k "java -jar "%SOFTWARE_DIR%\zipkin.jar""

echo 📊 Starting AKHQ (Kafka UI)...
start "AKHQ" /D "%SOFTWARE_DIR%" cmd /k "java -Dmicronaut.config.files=%RESOURCES_DIR%akhq-config.yml -jar akhq.jar"

echo.
echo ======================================================
echo 🌐 STARTING MICROSERVICES (from parent directory)
echo ======================================================

echo ⚙️ [1/6] Starting Config Server (Port: 8888)...
start "CONFIG-SERVER" /D "%PROJECT_ROOT%\config-server" cmd /k "mvn spring-boot:run"
echo Waiting for Config Server to initialize...
timeout /t 20 >nul

echo 📞 [2/6] Starting Service Registry (Port: 8761)...
start "SERVICE-REGISTRY" /D "%PROJECT_ROOT%\service-registry" cmd /k "mvn spring-boot:run"
timeout /t 15 >nul

echo 🚪 [3/6] Starting API Gateway (Port: 8080)...
start "API-GATEWAY" /D "%PROJECT_ROOT%\api-gateway" cmd /k "mvn spring-boot:run"
timeout /t 10 >nul

echo 🛡️ [4/6] Starting Admin Server (Port: 1111)...
start "ADMIN-SERVER" /D "%PROJECT_ROOT%\admin-server" cmd /k "mvn spring-boot:run"
timeout /t 10 >nul

echo 💬 [5/6] Starting Greet Service (Port: 9091)...
start "GREET-SERVICE" /D "%PROJECT_ROOT%\greet-service" cmd /k "mvn spring-boot:run"
timeout /t 10 >nul

echo 👋 [6/6] Starting Welcome Service (Port: 8081)...
start "WELCOME-SERVICE" /D "%PROJECT_ROOT%\welcome-service" cmd /k "mvn spring-boot:run"

echo.
echo ======================================================
echo ✅ ALL SERVICES ARE STARTING!
echo ======================================================
echo Eureka: http://localhost:8761
echo Admin:  http://localhost:1111
echo Zipkin: http://localhost:9411
echo AKHQ:   http://localhost:9099
echo Test:   http://localhost:8080/welcome-service/welcome
echo ======================================================
echo Press any key to exit this script. The services will keep running.
pause >nul
