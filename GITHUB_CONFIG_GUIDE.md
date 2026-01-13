# GitHub Centralized Config Server Guide

This guide explains how to migrate your configuration from a local folder to a **Centralized GitHub Repository**.

## 1. The Concept
Instead of reading files from `src/main/resources/config`, the Config Server will clone a remote Git repository and read properties from there. This allows you to update configuration **without restarting** the Config Server or the Microservices (using `/refresh` endpoint).

## 2. GitHub Repository Structure
You should create a **NEW** repository on GitHub (e.g., `my-microservices-config`).
The structure inside that repository should look exactly like your local folder:

```text
my-microservices-config/ (Root of Repo)
│
├── application.properties          (Global config for ALL services)
├── application-dev.properties      (Global DEV overrides)
├── application-prod.properties     (Global PROD overrides)
│
├── greet-service.properties        (Default for Greet)
├── greet-service-dev.properties    (Greet DEV)
├── greet-service-prod.properties   (Greet PROD)
│
├── welcome-service.properties      (Default for Welcome)
├── welcome-service-dev.properties  (Welcome DEV)
└── welcome-service-prod.properties (Welcome PROD)
```

## 3. How to Configure Config Server
You need to modifiy `config-server/src/main/resources/application.properties` to point to this repo.

**Current (Native/Local):**
```properties
spring.profiles.active=native
spring.cloud.config.server.native.search-locations=classpath:/config
```

**Change to (GitHub):**
```properties
spring.profiles.active=git
spring.cloud.config.server.git.uri=https://github.com/{your-username}/my-microservices-config.git
# If private, add:
# spring.cloud.config.server.git.username=...
# spring.cloud.config.server.git.password=... (or token)
```

## 4. Branching Strategy (Optional)
You can also use Git Branches for profiles instead of file names, but the **File Name Strategy** (above) is simpler and recommended for beginners.

*   **File Name Strategy**: `greet-service-dev.properties` (All in `main` branch)
*   **Branch Strategy**: `greet-service.properties` (In `dev` branch vs `prod` branch)

## 5. Workflow
1.  **Dev** pushes a change to `greet-service-dev.properties` in GitHub.
2.  **Config Server** detects the change (on next request).
3.  **Greet Service** can refresh its beans (if marked with `@RefreshScope`) to pick up changes without restarting.
