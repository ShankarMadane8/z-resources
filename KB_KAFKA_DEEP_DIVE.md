# Kafka Deep Dive: Partitions, Groups, and Scaling

## 1. The Golden Rule of Kafka Scaling
> **"You cannot have more active consumers in a group than you have partitions."**

*   **1 Partition, 10 Consumers** -> 1 Active, 9 Idle.
*   **10 Partitions, 1 Consumer** -> 1 Active (handles all 10).
*   **10 Partitions, 10 Consumers** -> 10 Active (Optimum Speed).

---

## 2. Topic, Partition, and Group ID
Currently, your code looks like this:
```java
@KafkaListener(topics = "user-visits", groupId = "greet-group")
public void consume(String message) { ... }
```
It prints only the message.

### How to see Metadata (Explanation Only)
If you *wanted* to see the Partition, Topic, and Offset, you would change your method signature to this:
```java
// DO NOT CHANGE CODE, JUST FOR LEARNING
@KafkaListener(topics = "user-visits", groupId = "greet-group")
public void consume(String message, 
                    @Header(KafkaHeaders.RECEIVED_TOPIC) String topic,
                    @Header(KafkaHeaders.RECEIVED_PARTITION) int partition,
                    @Header(KafkaHeaders.OFFSET) long offset) {
    
    log.info("Topic: {}, Partition: {}, Offset: {}, Message: {}", 
             topic, partition, offset, message);
}
```
This allows the Consumer to "know" where the data came from.

---

## 3. How to Increase Partitions
You currently have **1 Partition**. To make both of your Greet Services work in parallel, you need **2 Partitions**.

### The Command
Since we installed Kafka in `SOFTWARE_INSTALLED`, you can run this command in your terminal (PowerShell):

```powershell
# 1. Map the drive (if not already done)
subst Z: "C:\Users\madan\OneDrive\Desktop\Microservices\MicroservicesProject\SOFTWARE_INSTALLED"

# 2. Run the Alter Command
Z:\kafka\bin\windows\kafka-topics.bat --bootstrap-server localhost:9092 --alter --topic user-visits --partitions 2
```

### What happens after increasing?
1.  **Rebalancing**: Kafka detects the change.
2.  **Assignment**:
    *   It gives **Partition 0** to Greet-Service-Instance-1.
    *   It gives **Partition 1** to Greet-Service-Instance-2.
3.  **Result**: Now, when Welcome Service sends 10 messages:
    *   ~5 go to Instance 1.
    *   ~5 go to Instance 2.
    *   **Both logs will show activity!**

---

## 4. Consumer Groups vs. Broadcast
*   **Scaling (Load Balancing)**:
    *   Same `groupId` ("greet-group").
    *   Message goes to **Instance A OR Instance B**.
    *   Used for: Heavy processing (don't do work twice).

*   **Broadcasting (Notification)**:
    *   Different `groupId` ("greet-group-A", "greet-group-B").
    *   Message goes to **Instance A AND Instance B**.
    *   Used for: Updating local caches on every server.

---

## 5. The Mystery: How was the topic created?
You asked: *"I never ran a command to create `user-visits`, so how does it exist?"*

### The Answer: "Auto Creation"
Kafka has a setting called `auto.create.topics.enable`. By default, this is **TRUE**.

**The Chain of Events:**
1.  **Welcome Service** (Producer) started up.
2.  It tried to send a message to `user-visits`.
3.  **Kafka Broker** checked if `user-visits` existed.
4.  **Broker**: "It doesn't exist? No problem, I will create it for you right now with default settings."
    *   **Default Partitions**: 1 (Set by `num.partitions` in `server.properties`).
    *   **Default Replication**: 1.

### Can we stop this?
Yes. In Production, we usually set `auto.create.topics.enable=false`.
This forces developers to manually create topics (via Terraform or scripts) before the app starts, ensuring they set the correct number of partitions (e.g., 10 or 50) instead of the default 1.

---

## 6. The "Sticky" Problem & Solution
**The Issue**: After increasing partitions to 2, you noticed only **one** instance was receiving messages.
**The Cause**: Kafka's Default Partitioner is "Sticky". If you send messages with specific keys (or null keys), it might optimize by sending them all to the same partition for a while to batch them together.
**The Fix**: We added a **Random Key** (`UUID.randomUUID()`) to every message in the Producer.
```java
kafkaTemplate.send(topic, UUID.randomUUID().toString(), message);
```
**The Result**: Kafka hashes the random key. Since the keys are always different, they hash to different buckets (Partition 0 vs Partition 1), ensuring **Perfect Load Balancing**.

---

## 7. Where is the Kafka UI?
You tried visiting `http://localhost:9092/` and it failed.

### The Reason
*   **Port 9092** is NOT a Web/HTTP port. It is a **TCP Binary Port**.
*   It is designed for high-speed communication between Services (Java Code) and the Broker. It does not understand Browser requests.
*   **Kafka does not have a built-in UI.** It is a "Headless" backend system.

### The Solution: 3rd Party Tools
To see a UI, you must install a separate tool that connects to Port 9092 and serves a Web Page.

**Recommended for Non-Docker Setup:**
1.  **Offset Explorer (Formerly Kafka Tool)**:
    *   **Type**: Windows Desktop Application (.exe).
    *   **Pros**: Easy to install, looks like File Explorer.
    *   **Cons**: Old-school look.
2.  **AKHQ (KafkaHQ)**:
    *   **Type**: Java Application (.jar).
    *   **Pros**: Beautiful Web UI (like Zipkin).
    *   **How to run**: Download the jar and run `java -jar akhq.jar`.
    *   **Cons**: Paid/Freemium.

---

## 8. Tool Comparison Check (Your List)

| Tool | Type | Best For | Authentication | My Verdict for YOU |
| :--- | :--- | :--- | :--- | :--- |
| **Kafka UI (Provectus)** | Docker (mostly) | Best Overall | Good | **Hard to run without Docker** |
| **AKHQ** | Java JAR | Feature-rich | Excellent | **🏆 WINNER (Best for Windows/No-Docker)** |
| **Confluent** | Enterprise | Big Corp | Enterprise | **Overkill (Too heavy)** |
| **Kafdrop** | Java JAR | Lightweight | Basic | **Good, but valid alternatives exist** |

### Why AKHQ is the Winner for you?
1.  **It is a JAR file**: You run it exactly like Zipkin (`java -jar akhq.jar`).
2.  **No Docker**: It works natively on Windows.
3.  **Visuals**: It has a beautiful "Dark Mode" UI (matches your design preference).
4.  **Power**: You can `Produce` messages, `Consume` with filters, and view `Consumer Groups` easily.

### Why AKHQ (Alternative)?
...

## 8. Setup Complete: AKHQ on Port 9099
I have **installed AKHQ** for you as requested!

*   **URL**: `http://localhost:9099`
*   **Startup**: It is now part of `run-all.bat`.
*   **Features**:
    *   **Produce Messages**: Go to Topic -> "Produce" Tab.
    *   **View Data**: See all messages in real-time.
    *   **Consumer Groups**: Reset offsets or view lag.
