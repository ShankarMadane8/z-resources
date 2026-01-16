@echo off
TITLE Microservices Ecosystem Master Script (Resources Version)
echo ======================================================
echo STARTING MICROSERVICES ECOSYSTEM
echo ======================================================

:: Resolve absolute paths to avoid pathing issues with '..'
set "RESOURCES_DIR=%~dp0"
for %%i in ("%~dp0..") do set "PROJECT_ROOT=%%~fi"
for %%i in ("%PROJECT_ROOT%\SOFTWARE_INSTALLED") do set "SOFTWARE_DIR=%%~fi"

echo [STATUS] Project Root: %PROJECT_ROOT%
echo [STATUS] Software Dir: %SOFTWARE_DIR%

:: 1. Fix Windows Path Issues for Kafka using Subst
echo [STATUS] Mapping Z: drive to SOFTWARE_INSTALLED for Kafka...
subst Z: /D >nul 2>&1
subst Z: "%SOFTWARE_DIR%"
if errorlevel 1 (
    echo [ERROR] FAILED to map Z: drive. Kafka may fail to start.
) else (
    echo [OK] Z: drive mapped to Z:\
)

:: 2. Start Infrastructure Services
echo [INFRA] Starting Zookeeper...
start "ZOOKEEPER" /D "Z:\kafka\bin\windows" cmd /k "title ZOOKEEPER && zookeeper-server-start.bat Z:\kafka\config\zookeeper.properties"
ping 127.0.0.1 -n 9 >nul

echo [INFRA] Starting Kafka...
start "KAFKA" /D "Z:\kafka\bin\windows" cmd /k "title KAFKA && kafka-server-start.bat Z:\kafka\config\server.properties"
ping 127.0.0.1 -n 11 >nul

echo [INFRA] Starting Redis...
start "REDIS" /D "%SOFTWARE_DIR%\Redis" cmd /k "title REDIS && redis-server.exe"

echo [INFRA] Starting Zipkin...
if exist "%SOFTWARE_DIR%\zipkin.jar" (
    start "ZIPKIN" cmd /k "title ZIPKIN && java -jar "%SOFTWARE_DIR%\zipkin.jar""
) else (
    echo [SKIP] zipkin.jar NOT FOUND in %SOFTWARE_DIR%.
)

echo [INFRA] Starting AKHQ (Kafka UI)...
if exist "%SOFTWARE_DIR%\akhq.jar" (
    :: Using absolute path resolved without '..' to fix Micronaut config loading
    start "AKHQ" /D "%SOFTWARE_DIR%" cmd /k "title AKHQ && java -Dmicronaut.config.files="%SOFTWARE_DIR%\akhq-config.yml" -jar akhq.jar"
) else (
    echo [SKIP] akhq.jar NOT FOUND in %SOFTWARE_DIR%.
)

:: 3. Start ELK Stack
echo [ELK] Starting Elasticsearch...
if exist "%SOFTWARE_DIR%\elasticsearch\bin\elasticsearch.bat" (
    start "ELASTICSEARCH" /D "%SOFTWARE_DIR%\elasticsearch" cmd /k "title ELASTICSEARCH && bin\elasticsearch.bat"
    ping 127.0.0.1 -n 15 >nul
) else (
    echo [SKIP] Elasticsearch NOT FOUND in %SOFTWARE_DIR%\elasticsearch.
)

echo [ELK] Starting Logstash...
if exist "%SOFTWARE_DIR%\logstash\bin\logstash.bat" (
    start "LOGSTASH" /D "%SOFTWARE_DIR%\logstash" cmd /k "title LOGSTASH && bin\logstash.bat -f config\logstash-springboot.conf"
    ping 127.0.0.1 -n 15 >nul
) else (
    echo [SKIP] Logstash NOT FOUND in %SOFTWARE_DIR%\logstash.
)

echo [ELK] Starting Kibana...
if exist "%SOFTWARE_DIR%\kibana\bin\kibana.bat" (
    start "KIBANA" /D "%SOFTWARE_DIR%\kibana" cmd /k "title KIBANA && bin\kibana.bat"
) else (
    echo [SKIP] Kibana NOT FOUND in %SOFTWARE_DIR%\kibana.
)

echo.
echo ======================================================
echo STARTING MICROSERVICES
echo ======================================================

echo [1/6] Starting Config Server (Port: 8888)...
start "CONFIG-SERVER" /D "%PROJECT_ROOT%\config-server" cmd /k "title CONFIG-SERVER && mvn spring-boot:run"
echo Waiting for Config Server to initialize...
ping 127.0.0.1 -n 26 >nul

echo [2/6] Starting Service Registry (Port: 8761)...
start "SERVICE-REGISTRY" /D "%PROJECT_ROOT%\service-registry" cmd /k "title SERVICE-REGISTRY && mvn spring-boot:run"
ping 127.0.0.1 -n 16 >nul

echo [3/6] Starting API Gateway (Port: 8888)...
start "API-GATEWAY" /D "%PROJECT_ROOT%\api-gateway" cmd /k "title API-GATEWAY && mvn spring-boot:run"
ping 127.0.0.1 -n 11 >nul

echo [4/6] Starting Admin Server (Port: 1111)...
start "ADMIN-SERVER" /D "%PROJECT_ROOT%\admin-server" cmd /k "title ADMIN-SERVER && mvn spring-boot:run"
ping 127.0.0.1 -n 11 >nul

:: echo [5/6] Starting Greet Service (Port: 9091)...
:: start "GREET-SERVICE" /D "%PROJECT_ROOT%\greet-service" cmd /k "title GREET-SERVICE && mvn spring-boot:run"
:: ping 127.0.0.1 -n 11 >nul

:: echo [6/6] Starting Welcome Service (Port: 8081)...
:: start "WELCOME-SERVICE" /D "%PROJECT_ROOT%\welcome-service" cmd /k "title WELCOME-SERVICE && mvn spring-boot:run"

:: echo.
echo ======================================================
echo ALL SERVICES ARE STARTING!
echo ======================================================
echo Eureka: http://localhost:8761
echo Admin:  http://localhost:1111
echo Zipkin: http://localhost:9411
echo AKHQ:   http://localhost:9099
echo Test:   http://localhost:8888/welcome-service/welcome
echo ======================================================
echo Press any key to exit this script. The services will keep running.
pause >nul
