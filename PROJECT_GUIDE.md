# Spring Boot Microservices Project Guide

## 1. Project Overview
This project is a complete Microservices Ecosystem built with Spring Boot, Spring Cloud, and non-Dockerized external tools (Redis, Kafka, Zipkin).

### Architecture
*   **Service Registry (Eureka)**: 8761
*   **API Gateway**: 8080
*   **Config Server**: 8888 (Backed by GitHub)
*   **Admin Server**: 1111 (Monitoring)
*   **Greet Service**: 9091 (Provider, uses DB, Redis, Kafka)
*   **Welcome Service**: 8081 (Consumer, uses Feign Client)
*   **Tracing**: Zipkin (9411)

---

## 2. Infrastructure Services

### A. Service Registry (Eureka)
*   **Port**: `8761`
*   **Role**: All services register here. The Gateway queries this to find services.
*   **URL**: `http://localhost:8761`

### B. Config Server
*   **Port**: `8888`
*   **Role**: Centralized configuration management.
*   **Source**: [https://github.com/ShankarMadane8/my-microservices-config](https://github.com/ShankarMadane8/my-microservices-config)
*   **Key Concept**: Services only "bootstrap" locally (Name + URL). All real config (Ports, DB) comes from here.

### C. API Gateway
*   **Port**: `8080`
*   **Role**: Single Entry Point. Routes traffic to services dynamically using Eureka.
*   **Routes**:
    *   `/greet-service/**` -> Greet Service
    *   `/welcome-service/**` -> Welcome Service

### D. Admin Server
*   **Port**: `1111`
*   **Role**: Visual monitoring of all Spring Boot applications.
*   **URL**: `http://localhost:1111`

---

## 3. Business Services

### E. Greet Service (Provider)
*   **Port**: `9091`
*   **Tech**: MySQL (Data), Redis (Cache), Kafka (Messaging).
*   **Endpoint**: `GET /greet`
*   **Caching**: Uses `@Cacheable("greet-cache")` to store results in Redis.

### F. Welcome Service (Consumer)
*   **Port**: `8081`
*   **Tech**: OpenFeign (to call Greet), Redis (Cache).
*   **Endpoint**: `GET /welcome`
*   **Logic**: Calls Greet Service -> Appends message -> Returns to user.

---

## 4. Configuration Strategy
We use a **Hybrid Approach**:

1.  **Local (`src/main/resources/application.properties`)**:
    *   Contains ONLY `spring.application.name` and `spring.config.import`.
    *   This "bootstraps" the connection to the Config Server.
2.  **Remote (GitHub Repo)**:
    *   Contains `server.port`, `spring.datasource.*`, `logging`, etc.
    *   Allows changing config without redeploying the code.

---

## 5. External Tools (Manual Setup)
Since we are not using Docker, these run as standalone processes in `SOFTWARE_INSTALLED`:

1.  **Redis**: `SOFTWARE_INSTALLED\Redis\redis-server.exe` (Port 6379)
2.  **Zipkin**: `java -jar SOFTWARE_INSTALLED\zipkin.jar` (Port 9411)
3.  **Kafka/Zookeeper**: Standard Windows scripts (Ports 9092 / 2181)
4.  **MySQL**: Installed on Host (Port 3306).

---

## 6. How to Run
I have provided a **One-Click Script**: `run-all.bat`.

1.  Start **MySQL** manually (ensure `greetdb` exists).
2.  Run `.\run-all.bat`:
    *   It starts Redis & Zipkin.
    *   It starts Registry, Config, Gateway, Admin.
    *   It starts Greet & Welcome services.

---

## 7. Verification URLs
*   **Eureka**: [http://localhost:8761](http://localhost:8761)
*   **Admin**: [http://localhost:1111](http://localhost:1111)
*   **Zipkin**: [http://localhost:9411](http://localhost:9411)
*   **Test**: [http://localhost:8080/welcome-service/welcome](http://localhost:8080/welcome-service/welcome) (Via Gateway)
