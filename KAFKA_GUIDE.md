# Kafka Integration Guide

## 1. Setup (Manual)
Since we are not using Docker, we installed Kafka in `SOFTWARE_INSTALLED\kafka`.
*   **Zookeeper Port**: 2181
*   **Kafka Port**: 9092

## 2. Startup
The `run-all.bat` script has been updated (and fixed with `subst` for path issues). It now:
1.  Starts **Zookeeper**
2.  Starts **Kafka**
3.  Starts **Redis & Zipkin**
4.  Starts **All Microservices**

## 3. How it Works in this Project
We implemented an **Asynchronous Event Flow**:

1.  **Trigger**: You call `GET /welcome` (Welcome Service).
2.  **Synchronous**: Welcome Service calls Greet Service via **Feign** (REST) to get the string.
3.  **Asynchronous**: Welcome Service sends a "User Visit" event to **Kafka Topic** `user-visits`.
4.  **Reaction**: Greet Service (listening on `user-visits`) picks up the message and logs it.

## 4. Understanding Consumer Behavior (Why only one service logs?)
You noticed that even if you have **multiple instances** of Greet Service running (e.g., Port 9091 and 9093), **only one** of them prints the log.

### The Reason: Consumer Groups
In `KafkaConsumerService.java`, we set:
`groupId = "greet-group"`

*   **Rule**: Kafka ensures that each message is processed by **ONLY ONE** consumer in a group. This is for **Load Balancing**.
*   **Partitions**: A topic is split into partitions. By default, a new topic has **1 Partition**.
*   **Result**: If you have 1 Partition and 2 Consumers in the same group:
    *   **Consumer A** gets the partition (Active).
    *   **Consumer B** gets nothing (Idle/Standby).

### How to change this?
*   **To Share Load**: You must **increase the partitions** of the topic (e.g., to 2). Then Consumer A takes Partition 1, Consumer B takes Partition 2.
*   **To Broadcast (Both receive)**: You must give them **Different Group IDs** (e.g., `greet-group-1` and `greet-group-2`).

## 5. How to Verify
1.  Run `.\run-all.bat`.
2.  Wait for everything to start.
3.  Hit `http://localhost:8080/welcome-service/welcome`.
4.  Check the **Greet Service Console**. You will see:
    `INFO ... KafkaConsumerService : Kafka Event Received: User visited Welcome Service at ...`
