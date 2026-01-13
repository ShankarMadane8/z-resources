# Spring Cloud Config Server Guide

This document explains how to organize your configuration files for microservices using Spring Cloud Config Server.

## 1. Repository Structure
In a "Native" setup (local folder), we organize files in `src/main/resources/config` inside the Config Server.

**Naming Convention:** `{application-name}-{profile}.properties`

*   `application.properties`: **Global default config** (applied to ALL services).
*   `{service}.properties`: Default config for a specific service.
*   `{service}-{profile}.properties`: Config for a specific profile (overrides default).

## 2. Recommended Folder Structure
```text
config-server/src/main/resources/config/
├── application.properties          (Global: logging, common kafka urls)
├── application-dev.properties      (Global Dev overrides)
├── application-prod.properties     (Global Prod overrides)
│
├── greet-service.properties        (Greet Service Default)
├── greet-service-dev.properties    (Greet Dev)
├── greet-service-prod.properties   (Greet Prod)
│
├── welcome-service.properties      (Welcome Default)
├── welcome-service-dev.properties  (Welcome Dev)
└── welcome-service-prod.properties (Welcome Prod)
```

## 3. How it Works
When **Greet Service** starts with profile `dev`:
1.  It fetches `application.properties` (Global)
2.  It fetches `application-dev.properties` (Global Dev)
3.  It fetches `greet-service.properties` (Service Default)
4.  It fetches `greet-service-dev.properties` (Service Dev - Highest Priority)

## 4. How to Activate a Profile
In your service's `bootstrap.properties` or `application.properties` (in the service itself), you set the active profile:

```properties
spring.profiles.active=dev
```
OR pass it as a command line argument:
```bash
java -jar greet-service.jar --spring.profiles.active=prod
```

---
I will now generate these files for you in the project.
