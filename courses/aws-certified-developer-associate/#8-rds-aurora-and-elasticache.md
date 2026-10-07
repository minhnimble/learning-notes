# AWS Fundamentals: RDS + Aurora + ElastiCache

---

## Amazon RDS Overview

### TL;DR

- **RDS (Relational Database Service)** is a **managed** database service for databases that use **SQL**. AWS runs the infrastructure and you manage the data and schema.
- **Engines:** **PostgreSQL, MySQL, MariaDB, Oracle, Microsoft SQL Server, IBM Db2, and Aurora** (AWS's own engine, with MySQL and PostgreSQL compatibility).
- **What you get over a self-managed DB on EC2:** automated provisioning, OS patching, continuous backups with **Point-in-Time Restore**, monitoring dashboards, **read replicas**, **Multi-AZ**, maintenance windows, and vertical and horizontal scaling.
- **The trade-off:** **no SSH** into the underlying instance. (**RDS Custom** is the exception.)
- Storage is **EBS-backed**.
- **RDS Storage Auto Scaling** grows storage automatically when space runs low, up to a **maximum storage threshold** you set. It supports all RDS engines.

### 1. What Is RDS?

- **Relational** database = tables with a fixed schema, queried with **SQL** (Structured Query Language).
- **Managed service:** you create a database instance in the cloud, and AWS runs it for you.
- You choose the **engine**, **instance class** (CPU/RAM), **storage type and size**, and **network settings**.
- Typical workloads are **OLTP**: transactional apps, web back ends, and anything needing joins and ACID transactions.
- RDS is a **regional** service. A DB instance lives in a **VPC**, usually in **private subnets**, and apps connect to it through its **endpoint (DNS name)**.
- It is **not** for NoSQL or key-value use (that is **DynamoDB**).

### 2. Supported Database Engines

| Engine | Notes |
|---|---|
| **PostgreSQL** | Open source |
| **MySQL** | Open source |
| **MariaDB** | MySQL fork, open source |
| **Oracle** | Commercial. License included or **bring your own license (BYOL)**. |
| **Microsoft SQL Server** | Commercial. License included. |
| **IBM Db2** | Commercial |
| **Aurora** | **AWS proprietary**, MySQL- and PostgreSQL-compatible. Has its own dedicated lectures. |

- The lecturer says to **remember the supported engines**. This is a common exam question.
- Aurora is part of the RDS family. It is covered in depth later, including its different storage and replication model.
- **RDS Custom** (Oracle and SQL Server) is a variant that gives you **OS and database customization access**, including SSH. It is for legacy or customized apps.

### 3. Why RDS Instead of a Database on EC2?

You *can* install a database on an EC2 instance. RDS handles the operational work for you.

| Feature | What RDS does for you |
|---|---|
| **Provisioning** | Fully **automated** setup |
| **OS patching** | Automated for the underlying operating system |
| **Backups** | **Continuous backups** (daily snapshot plus transaction logs) |
| **Point-in-Time Restore (PITR)** | Restore to a **specific timestamp** within the retention window |
| **Monitoring** | Dashboards in the console, plus CloudWatch metrics |
| **Read replicas** | Improve **read performance** (own lecture) |
| **Multi-AZ** | **High availability and disaster recovery** (own lecture) |
| **Maintenance windows** | Scheduled slots for upgrades and patching |
| **Scaling** | **Vertical** (bigger instance class) and **horizontal** (read replicas) |
| **Storage** | **EBS-backed**, with optional **auto scaling** |

**The one thing you give up: no SSH access.**
- RDS is a managed service, so you can't log in to the underlying EC2 instance or OS.
- This is a fair trade, because you would otherwise have to build and maintain everything above yourself.
- If you need OS-level access, the options are a **self-managed DB on EC2** or **RDS Custom**.

### 4. Key Features in a Bit More Detail

#### 4.1 Backups and PITR
- **Automated backups** are enabled by default. They take a daily snapshot and capture transaction logs, which are stored in S3 (managed by AWS).
- Retention: up to **35 days**. Setting it to **0** disables automated backups.
- **PITR** restores to any second within the retention window (typically up to about 5 minutes ago).
- A restore **always creates a new DB instance**. It never overwrites the existing one.
- **Manual snapshots** are user-triggered, have **no expiry**, and are kept until you delete them.

#### 4.2 Maintenance windows
- A weekly window you choose for patching and upgrades.
- Some changes (for example a minor engine patch) can cause **brief downtime** or a **Multi-AZ failover**.

### 5. RDS Storage Auto Scaling

#### 5.1 The problem
- When you create an RDS database, you pick a storage size (for example **20 GB**).
- If the database fills up, you would normally have to **modify the storage manually**, which is operational work and carries some risk.

#### 5.2 The solution
- With **Storage Auto Scaling** enabled, RDS **detects low free space and increases storage automatically**.
- There is **no manual step** and **no database downtime**.
- It is "a very nice feature" for applications with **unpredictable workloads**.
- It is **supported by all RDS database engines**.

#### 5.3 Required setting
- You must set a **Maximum Storage Threshold**, the upper limit the storage can grow to.
- This prevents unbounded growth and unbounded cost.

#### 5.4 When it triggers (all three must be true)

| Condition | Value |
|---|---|
| **Free storage** is below | **10%** of the allocated storage |
| The low-storage condition has lasted at least | **5 minutes** |
| Time since the **last storage modification** is at least | **6 hours** |

```
Free space < 10%  AND  lasted >= 5 min  AND  >= 6 h since last change
                              |
                              v
              RDS automatically increases allocated storage
              (up to the Maximum Storage Threshold)
```

- The size of each increase is chosen by RDS: the largest of **10 GiB**, **10% of the current allocated storage**, or an amount **predicted from recent growth**.
- Storage can only **grow**. It never shrinks automatically, and RDS has no way to shrink storage in place.
- Pricing comes from **instance hours**, **storage** (and provisioned IOPS if used), **backup storage beyond the free allocation**, and **data transfer**.

### 6. Exam-Style Recall

| If the question says... | Think... |
|---|---|
| "Managed relational database using SQL" | **Amazon RDS** |
| "Which engines does RDS support?" | **PostgreSQL, MySQL, MariaDB, Oracle, SQL Server, Db2, Aurora** |
| "AWS's proprietary relational engine" | **Aurora** |
| "Offload patching, backups, and provisioning of the database" | **RDS** (instead of a DB on EC2) |
| "Need to SSH into the database server" | **Not possible on RDS**. Use **EC2**, or **RDS Custom**. |
| "Restore the database to a specific moment in time" | **Point-in-Time Restore** (creates a new DB) |
| "Improve read performance" | **Read replicas** |
| "Disaster recovery / high availability" | **Multi-AZ** |
| "Database is running out of storage, no downtime allowed" | **RDS Storage Auto Scaling** |
| "Prevent storage auto scaling from growing forever" | Set the **maximum storage threshold** |
| "When does storage auto scaling trigger?" | Free space **under 10%**, for **5 minutes**, and **6 hours** since the last change |
| "Unpredictable workload, avoid manual storage resizing" | **Storage Auto Scaling** |
| "Vertical scaling of RDS" | Change the **instance class** |
| "Horizontal scaling of RDS" | Add **read replicas** (reads only) |
| "Schedule patching and upgrades" | **Maintenance window** |
| "Key-value or NoSQL workload" | **DynamoDB**, not RDS |

---

## RDS Read Replicas vs Multi AZ

### TL;DR

- **Read replicas scale reads (performance).** **Multi-AZ gives high availability and disaster recovery (DR).** This is the core exam distinction.
- **Read replicas:** up to **15** per source (MySQL, MariaDB, PostgreSQL), in the **same AZ, a different AZ, or a different region**. Replication is **asynchronous**, so reads are **eventually consistent**. They accept **`SELECT` only** and can be **promoted** to standalone databases.
- **Multi-AZ:** a **synchronous** standby in another AZ, reached through **one DNS name**, with **automatic failover**. The standby is **not readable** and **not used for scaling**.
- A read replica **can itself be Multi-AZ** (a common exam question).
- Going from **Single-AZ to Multi-AZ is zero downtime**. You click **Modify** and enable Multi-AZ. Behind the scenes RDS takes a snapshot, restores it as the standby, and syncs.
- **Cost:** replication traffic between AZs in the **same region is free**. **Cross-region replication is charged**.

### 1. Read Replicas

#### 1.1 Purpose

- Scale **read** traffic when the main DB instance can't keep up with requests.
- The app still sends **reads and writes** to the main instance, and can send **reads** to the replicas.

```
              writes + reads
Application ------------------> [Main RDS instance]
     |                               |  asynchronous replication
     | reads                         +--> [Read replica 1]
     +-----------------------------> +--> [Read replica 2]
```

#### 1.2 Key characteristics

| Property | Detail |
|---|---|
| **Max replicas** | Up to **15** (MySQL, MariaDB, PostgreSQL). Oracle and SQL Server allow fewer (about 5). |
| **Placement** | **Same AZ**, **cross-AZ**, or **cross-region** (three options to remember) |
| **Replication** | **Asynchronous** |
| **Consistency** | **Eventually consistent** reads |
| **Allowed SQL** | **`SELECT` only**. No `INSERT`, `UPDATE`, or `DELETE`. |
| **Promotion** | A replica can be **promoted to its own standalone database** |
| **Endpoint** | Each replica has **its own DNS endpoint** |

#### 1.3 Asynchronous replication and eventual consistency

- The main instance **doesn't wait** for replicas to confirm a write.
- If the app reads from a replica **before the change has replicated**, it may get **old (stale) data**.
- Hence the term **eventually consistent**. The delay is called **replica lag**.
- Don't send reads that need the **latest data** to a replica. Send them to the main instance.

#### 1.4 Promotion

- You can take a replica and **promote it to a standalone DB** that accepts **writes**.
- After promotion, it is **out of the replication chain** and has **its own lifecycle**. The link to the source is **gone** and can't be restored.
- Uses: **manual DR** (especially for a cross-region replica), splitting off a database, and testing.
- Promotion is a **manual** action. It is not automatic failover.

#### 1.5 Application changes required

- **The app must be changed** to use read replicas. The **connection string** (or data-access layer) must be updated to send reads to the **list of replica endpoints**.
- Nothing is routed automatically. For an automatic reader endpoint you would need **Aurora** or **RDS Proxy**.

#### 1.6 Classic use case: reporting and analytics

- Production app does **reads and writes** on the main instance.
- A new team wants **reporting and analytics** on the same data.
- Pointing it at the main instance would **overload it** and **slow down production**.
- Solution: create a **read replica**, and run the reporting workload there.
- Result: the production app is **unaffected**.
- The reporting app must only run **`SELECT`**.

#### 1.7 Network cost

AWS normally **charges for data moving between AZs**. RDS read replicas are an exception.

| Replica location | Replication traffic cost |
|---|---|
| **Same region** (same AZ or a different AZ) | **Free**. Example: primary in `us-east-1a`, replica in `us-east-1b`. |
| **Cross-region** | **Charged** (inter-region data transfer). Example: `us-east-1` to `eu-west-1`. |

- **Automated backups** must be **on** (retention above 0) on the source before you can create replicas for MySQL, MariaDB, and PostgreSQL.

### 2. Multi-AZ

#### 2.1 Purpose

- Mainly for **disaster recovery** and **high availability**.
- It is **not** for scaling.

```
Application --reads + writes--> [DNS name (one endpoint)]
                                     |
                       +-------------+--------------+
                       v                            v
              [Primary, AZ-A]  --synchronous-->  [Standby, AZ-B]
                       |                            |
                       +-- on failure: standby is promoted, DNS flips --+
```

#### 2.2 How it works

- The **primary** (lecturer says "master") is in **AZ-A**. A **standby** is in **AZ-B**.
- **Synchronous replication:** every change on the primary must **also be written to the standby** before the write is acknowledged.
- The app uses **one DNS name** (the DB endpoint).
- On a problem, RDS performs an **automatic failover**: the standby is promoted to primary and the DNS name points to it. **No manual intervention.**
- Your app only needs to **reconnect** (with retry logic). It has no endpoint change to make.

**Failover triggers:**

| Trigger | Included |
|---|---|
| **AZ outage** (loss of the whole AZ) | Yes |
| **Network loss** to the primary | Yes |
| **Instance failure** of the primary | Yes |
| **Storage failure** on the primary | Yes |
| Maintenance work such as OS patching or an **instance class change** | Yes (can cause a failover) |
| Manual **reboot with failover** | Yes (useful for testing) |

- Failover usually takes **about 1-2 minutes** (typically 60-120 s).
- The standby is **passive**: **no one can read from it or write to it** (for the classic Multi-AZ instance deployment). It exists only as a failover target.

#### 2.3 Benefits and limits

| | Detail |
|---|---|
| **Availability** | Survives AZ, network, instance, and storage failures |
| **Durability** | Data is written to two AZs **before** the write is acknowledged |
| **Backups** | Taken from the **standby**, so no I/O impact on the primary |
| **Patching** | Applied to the standby first, then failover, so less downtime |
| **Scope** | **Same region only** (different AZ). Not cross-region. |
| **Scaling** | **None**. It adds no read capacity. |
| **Cost** | Roughly **double** the instance cost, because you pay for the standby |

### 3. Read Replicas vs Multi-AZ

| Feature | Read replicas | Multi-AZ |
|---|---|---|
| **Main goal** | **Scale reads** (performance) | **HA and disaster recovery** |
| **Replication** | **Asynchronous** | **Synchronous** |
| **Consistency** | Eventually consistent | Strongly consistent (standby is up to date) |
| **Serves traffic?** | **Yes** (reads) | **No** (standby is passive) |
| **Count** | Up to **15** | **1 standby** |
| **Placement** | Same AZ, cross-AZ, or **cross-region** | **Different AZ, same region** |
| **Endpoint** | **Each replica has its own** | **One DNS name**, flipped on failover |
| **Failover** | **Manual** (promote the replica) | **Automatic** |
| **App changes** | **Yes**, update the connection strings | **None** |
| **Cross-AZ network cost** | **Free** in the same region, **charged** cross-region | Free (managed by RDS) |
| **Can it be combined?** | **Yes**, a replica can be Multi-AZ | N/A |

### 4. Single-AZ to Multi-AZ

#### 4.1 Exam answer

- It is a **zero-downtime operation**. **No need to stop the database.**
- Steps: select the DB, click **Modify**, enable **Multi-AZ**, and apply.

#### 4.2 What happens behind the scenes

1. RDS takes a **snapshot** of the main database automatically.
2. The snapshot is **restored into a new standby DB** in another AZ.
3. **Synchronous replication** is set up between the primary and the standby.
4. The standby **catches up** with the primary, and the database is now **Multi-AZ**.

- Apply it **immediately** or in the next **maintenance window**.
- There may be a **brief performance impact** during the snapshot and sync, so many people do it off-peak.
- Multi-AZ is **not** the same as a backup. A bad `DELETE` replicates to the standby instantly.

### 5. Exam-Style Recall

| If the question says... | Think... |
|---|---|
| "Scale read traffic on RDS" | **Read replicas** |
| "Main DB overloaded by reporting or analytics" | **Create a read replica** for the reporting workload |
| "Automatic failover with no application change" | **Multi-AZ** (one DNS name) |
| "Synchronous replication" | **Multi-AZ** |
| "Asynchronous replication" | **Read replicas** |
| "Reads might return slightly old data" | **Read replica**, eventual consistency |
| "Maximum number of read replicas" | **15** (MySQL, MariaDB, PostgreSQL) |
| "Replica in another region" | **Cross-region read replica** (charged replication traffic) |
| "Replication traffic cost, same region, different AZ" | **Free** |
| "Can anyone read from the Multi-AZ standby?" | **No** (classic Multi-AZ) |
| "Can a read replica be Multi-AZ?" | **Yes** |
| "Convert Single-AZ to Multi-AZ with no downtime" | **Modify, enable Multi-AZ** (snapshot, restore, sync) |
| "App must change to use replicas" | **Update the connection string** to the replica endpoints |
| "Run `INSERT` on a read replica" | **Not allowed**: replicas are `SELECT` only |
| "Turn a replica into a standalone database" | **Promote** the replica |
| "Multi-AZ to scale reads" | **Wrong**: Multi-AZ doesn't add read capacity |
| "Connection times out to RDS" | **Security group** or network (subnet and route) problem |
| "Let only the application servers reach the database" | DB SG inbound on the DB port with **source = app's security group** |
| "Authenticate to RDS with IAM instead of a password" | **IAM database authentication** (token valid 15 min, SSL required) |
| "Database runs out of space automatically handled" | **Storage autoscaling** and a maximum storage threshold |
| "Add read capacity from the console" | **Create read replica** |
| "Change a Single-AZ database to Multi-AZ" | **Modify**, enable Multi-AZ (zero downtime) |
| "Back up a DB manually and keep it forever" | **Manual snapshot** |
| "Recover to 10 minutes ago" | **Point-in-time restore** (creates a new instance) |
| "Copy a database to another region" | **Copy a snapshot** to the other region and restore |
| "Can't delete the RDS instance" | **Deletion protection** is on. Disable it via **Modify**. |
| "Connect an app to RDS endpoint after failover" | Use the **DNS endpoint**, and the DNS name flips to the new primary |
| "Scale the DB instance size" | **Modify** the instance class (vertical scaling, brief downtime) |

---

## Amazon RDS Hands On

### 1. Starting the Wizard

- Console: **Aurora and RDS**, **Databases**, **Create database**.
- **Creation method:**
  - **Standard create** (the lecture calls it "full configuration") shows every option.
  - **Easy create** uses recommended defaults.
- The demo used **MySQL** to keep it simple, with the **default engine version**.
- **Default ports:** MySQL/MariaDB **3306**, PostgreSQL **5432**, Oracle **1521**, SQL Server **1433**, Db2 **50000**. Aurora uses its MySQL or PostgreSQL port.

### 2. Templates and Availability Options

| Template | What it gives you |
|---|---|
| **Production** | Full settings, including Multi-AZ options |
| **Dev/Test** | Cheaper, for non-production |
| **Free tier** | Only **single-AZ, one DB instance**. This is what the demo used. |

**Availability and durability options (shown with the Production template):**

| Option | Instances | Notes |
|---|---|---|
| **Single-AZ DB instance** | 1 | No standby. The only option on Free tier. |
| **Multi-AZ DB instance deployment** | 2 (primary and a standby) | Classic Multi-AZ. The standby is **passive** and can't be read. |
| **Multi-AZ DB cluster deployment** | 3 (writer and two readable standbys) | Newer option for MySQL and PostgreSQL. The standbys **can serve reads**. |

- The lecturer didn't use the Production options, but showed them to illustrate **spreading across multiple AZs**.

### 3. Settings Used in the Demo

#### 3.1 Credentials and authentication

| Setting | Demo value | Notes |
|---|---|---|
| **DB instance identifier** | Default | The name of the instance (not the database name) |
| **Master username** | `admin` | Default for MySQL |
| **Credentials management** | **Self-managed** | Alternative: **AWS Secrets Manager** manages the password. It is the **most secure** (and supports **automatic rotation**) but **costs extra**. |
| **Master password** | A weak demo password | Never do this in real use |
| **Database authentication** | **Password authentication** only | **IAM database authentication** is optional (see RDS & Aurora Security) |

#### 3.2 Instance configuration and storage

| Setting | Demo value | Notes |
|---|---|---|
| **Instance class** | `db.t4g.micro` (or `db.t3.micro`, whatever default is free-tier eligible) | Burstable class |
| **Storage** | **20 GB** | |
| **Storage autoscaling** | Option under **Additional storage configuration** | Set a **maximum storage threshold** (example: **1000 GB**). RDS grows storage automatically when free space runs low. |

#### 3.3 Connectivity

| Setting | Demo value | Notes |
|---|---|---|
| **Compute resource** | **Don't connect to an EC2 compute resource** | The alternative auto-configures SG rules between an EC2 instance and the DB |
| **VPC** | Default VPC | |
| **DB subnet group** | Default | A subnet group lists subnets (in **at least 2 AZs**) where RDS may place the DB |
| **Public access** | **Yes** | Gives the DB a **public IP** so you can connect from your laptop. **Not for production.** |
| **VPC security group** | **Create new**, named `demo-rds` | |
| **Availability zone** | No preference | |
| **RDS Proxy** | Not used | Connection pooling (covered later) |
| **Port** | **3306** | MySQL's default |

#### 3.4 Monitoring and additional configuration

| Setting | Demo value | Notes |
|---|---|---|
| **Monitoring** | **Standard** (Database Insights) | **Enhanced Monitoring** (OS-level metrics) and **log exports to CloudWatch Logs** are optional |
| **Initial database name** | `mydb` | If you leave it blank, RDS creates **no** database (only the instance) |
| **Estimated monthly cost** | Free tier info | Free tier lasts **12 months** and applies to specific instance types |

- Click **Create database**. Creation takes several minutes: **Creating**, then **Available**.

### 4. Connecting to the Database

#### 4.1 What you need

| Item | Where to find it |
|---|---|
| **Endpoint** (DNS name) | RDS, Databases, select the DB, **Connectivity & security** |
| **Port** | **3306** |
| **Username / password** | What you set at creation (`admin` and the demo password) |
| **Initial database** | `mydb` |

- **Use the endpoint DNS name**, not an IP. The IP can change (for example after a failover).

#### 4.2 Client used: SQLElectron

- A free, open-source GUI SQL client. Download the latest version for your OS (DMG for Mac, installer for Windows).
- **Add a new server**: name `RDSDemo`, type **MySQL**, address = the **endpoint**, port **3306**, user `admin`, the password, and database `mydb`.
- Click **Test** (a success message appears), **Save**, then **Connect**.
- Any MySQL client works (MySQL Workbench, DBeaver, the `mysql` CLI).

#### 4.3 Security group behavior

- The wizard created `demo-rds` with an **inbound rule: TCP 3306 from your IP address only**.
- If you can't connect, check these two things:
  1. The DB is **publicly accessible**.
  2. The **security group** allows **your current IP** on port 3306. Edit the inbound rule (for example, set it to **My IP** again if your IP changed).
- Allowing `0.0.0.0/0` makes it work from anywhere, but it is a security risk. Fine for a throwaway demo only.
- Connecting also needs a **route to an Internet Gateway** in the DB's subnets. The default VPC has this.

- Production pattern: RDS in a **private subnet**, public access **No**, SG inbound on the DB port with **source = the app's security group**. No SSH to the host, only a SQL client over the DB port.

### 5. SQL Demo (Out of Scope for the Exam)

```sql
CREATE TABLE my_table (name VARCHAR(20), first_name VARCHAR(20));
INSERT INTO my_table (name, first_name) VALUES ('<last name>', 'Stephane');
SELECT * FROM my_table;
```

- Creates a table, inserts a row, and selects it, which shows a normal MySQL database running on RDS.
- Beyond running the DB, the SQL itself is not tested on the Developer Associate exam.

### 6. Exploring RDS Features in the Console

- **Actions** menu: **Create read replica** (choose whether the replica is Multi-AZ; the lecture cancelled), **Take snapshot**, **Restore to point in time** (always creates a new DB instance), **Copy snapshot** to another region.
- **Modify** button: instance class (vertical scaling), Multi-AZ, storage settings.
- **Monitoring** tab: CloudWatch metrics such as CPU utilization and database connections, used to decide when to scale up or add replicas.

### 7. Deleting the Database (Cost Control)

- **Deletion protection** must be turned off (**Modify**, apply immediately) before **Actions, Delete** works.
- A final snapshot and retained automated backups are optional. Automated backups are deleted with the instance unless retained.

---

## Amazon Aurora

### TL;DR

- **Aurora** is AWS's **proprietary**, cloud-optimized relational database, **compatible with MySQL and PostgreSQL** (same drivers and tools).
- **Performance claims:** up to **5x** MySQL on RDS and **3x** PostgreSQL on RDS.
- **Storage** auto-grows from **10 GB** up to **128 TiB** (**256 TiB** on newer versions). There is no capacity planning.
- **Up to 15 read replicas**, with very low replica lag (typically **under 10-100 ms**), and **cross-region** replication.
- **Failover is fast**: typically **under 30 seconds**, much faster than RDS Multi-AZ.
- **6 copies of data across 3 AZs.** Writes need **4 of 6** copies and reads need **3 of 6**. It self-heals.
- **One writer, many readers.** Use the **writer endpoint** and **reader endpoint** (connection-level load balancing). Replicas can **auto scale**.
- **Backtrack** rewinds the database to a point in time without restoring from a backup (MySQL-compatible only).
- **Cost:** about **20% more** than RDS, but more efficient at scale.

### 1. What Is Aurora?

| Property | Detail |
|---|---|
| Type | **Proprietary** AWS technology (not open source) |
| Compatibility | **MySQL** and **PostgreSQL**. Connect with the usual drivers as if it were MySQL or PostgreSQL. |
| Design | **Cloud-native**: storage and compute are separated, and storage is a shared distributed volume |
| Part of | The **RDS** family (managed, no SSH, automated patching and backups) |
| Ports | MySQL-compatible **3306**, PostgreSQL-compatible **5432** |
| Availability | **High availability by default** (data is always spread across 3 AZs) |

- The lecture: you don't need the internals, only enough of a high-level view to answer exam questions.
- Aurora is a **cluster** of DB instances plus one **cluster volume**. It isn't a single instance.

### 2. Key Benefits Over RDS

- The lecturer's point on storage: as a DBA/SysOps person you **don't monitor disk space**. It grows by itself.
- You pay for the storage **actually used** (not what is provisioned), and it doesn't shrink automatically as a rule (newer versions can release space when data is deleted).

### 3. High Availability and Storage Design

#### 3.1 Six copies across three AZs

- Each write is stored as **6 copies**, **2 per AZ**, across **3 AZs**.
- The storage is a **shared, logical cluster volume**, striped across **many** underlying storage volumes (the lecture says "hundreds").

```
          AZ-A          AZ-B          AZ-C
        [copy][copy]  [copy][copy]  [copy][copy]     <- every write: 6 copies
              \            |            /
               ---- shared cluster volume ----
          (replicated, self-healing, auto-expanding)
```

#### 3.2 Quorum

| Operation | Copies needed | What survives |
|---|---|---|
| **Write** | **4 of 6** | Loss of **1 AZ** (2 copies) still allows writes |
| **Read** | **3 of 6** | Loss of **1 AZ plus one more copy** still allows reads |

#### 3.3 Self-healing

- If data blocks become **corrupted or bad**, Aurora repairs them using **peer-to-peer replication** between storage nodes, in the background.
- The data is spread across many volumes, which reduces the risk of losing any of it.
- None of this is something you manage.

### 4. Cluster Architecture: Writer and Readers

#### 4.1 The model

- Only **one instance takes writes**: the **writer** (the lecture says "master", which is the old term).
- Up to **15 read replicas** serve **reads**.
- All instances use the **same shared storage volume**. Replicas don't keep their own copy of the data.
- Aurora is "like Multi-AZ for RDS", except the replicas are **usable** and are also the **failover targets**.

#### 4.2 Failover

- If the writer fails, Aurora **promotes a read replica** to writer.
- Typically in **under 30 seconds**, and fast because the storage is already shared (no data to copy).
- **Any replica can become the writer.** Replicas have a **failover priority tier (0 to 15)**, and the lowest tier number wins (then the largest instance).
- With **no replicas**, Aurora creates a new instance in the same AZ, which takes longer.
- Compare with RDS: promoting an RDS read replica is a **manual** action and separate from Multi-AZ.

#### 4.3 Endpoints

| Endpoint | Points to | Why you use it |
|---|---|---|
| **Writer endpoint** (cluster endpoint) | Always the **current writer** | Your app keeps one DNS name. After a failover it is redirected to the new writer. |
| **Reader endpoint** | **All read replicas** | **Connection-level load balancing** across replicas. You don't track replica URLs. |
| **Custom endpoint** | A **subset** of instances you choose | For example, bigger instances for analytics |
| **Instance endpoint** | One specific instance | Debugging or special cases |

- **Remember for the exam:** writer endpoint plus reader endpoint.
- The lecture's detail: load balancing happens at the **connection level**, **not at the statement level**. Each new connection goes to a replica, and queries on that connection stay there.
- The reader endpoint is a DNS record, so connection pooling or reconnecting is needed to rebalance.

```
Clients --> [Writer endpoint] --> Writer instance (reads + writes)
Clients --> [Reader endpoint] --> Replica 1 | Replica 2 | ... | Replica 15  (reads)
                                      \          |            /
                                  [Shared cluster volume, 6 copies, 3 AZs]
```

#### 4.4 Auto scaling of read replicas

- Aurora supports **Auto Scaling** for replicas (through **Application Auto Scaling**), with **1 to 15** replicas.
- You pick a **metric** (for example average CPU or connections) and a **target value**, and Aurora adds or removes replicas.
- The **reader endpoint** is what makes this easy: apps don't need to know which replicas currently exist.

### 5. Replication and Disaster Recovery

| Feature | Detail |
|---|---|
| **Cross-region read replicas** | Aurora supports replicas in other regions (the lecture mention) |
| **Aurora Global Database** | One **primary region** (read/write) plus up to **5 secondary regions** (read-only). Replication lag is **typically under 1 second**. Cross-region **DR with RTO around 1 minute**. |
| **Backups** | **Continuous**, stored in S3, **no performance impact**, retention **1-35 days** |
| **Point-in-time restore** | Yes. Creates a **new cluster**. |
| **Snapshots** | Manual snapshots that you keep until you delete them. They can be shared or copied across regions. |

- The exam usually mentions "cross-region replicas" in an **RDS** context. For Aurora, **Global Database** is the stronger answer for low-latency, fast-failover DR.

### 6. Other Features

| Feature | What it does |
|---|---|
| **Automatic failover** | Described above |
| **Backup and recovery** | Continuous backups, PITR |
| **Isolation and security** | Runs in your **VPC**, **security groups**, **KMS encryption at rest**, **TLS in transit** |
| **Industry compliance** | Meets common compliance programs |
| **Push-button scaling** | Resize the instance class, add replicas, replica auto scaling |
| **Automated patching with zero downtime** | Zero-downtime patching (ZDP) where possible |
| **Advanced monitoring** | CloudWatch, Enhanced Monitoring, Performance Insights |
| **Routine maintenance** | Handled by AWS |
| **Backtrack** | Rewind the cluster to a point in time (see Backtrack below) |

**Related (not in the lecture, but exam-adjacent):**
- **Encryption** is chosen at **cluster creation**. To encrypt an unencrypted cluster, restore from an encrypted snapshot copy.

### 7. Backtrack

- **Backtrack** lets you **rewind the database to a chosen point in time**. Lecture example: "go back to yesterday 4 pm", and then "actually 5 pm instead" (you can move forward and backward within the window).
- It is **in place**: it **doesn't create a new cluster** and **doesn't restore from a backup**. The lecture notes it relies on something different.
- Limits:
  - **Aurora MySQL-compatible only** (not PostgreSQL).
  - Must be **enabled at cluster creation** (or on a restored/cloned cluster).
  - Maximum window **72 hours**.
  - Use it to **undo mistakes** quickly (a bad `DELETE`, `DROP`, or deployment).
- Compare:

| | Backtrack | Point-in-time restore |
|---|---|---|
| Creates new cluster | **No** (in place) | **Yes** |
| Speed | **Fast** (minutes) | Slower (restore time) |
| Window | Up to **72 hours** | Up to **35 days** |
| Engine | **Aurora MySQL** only | Aurora MySQL and PostgreSQL |

### 8. Aurora vs RDS (Quick Comparison)

| Feature | RDS (MySQL / PostgreSQL) | Aurora |
|---|---|---|
| Technology | Open-source engine on EBS | **Proprietary**, shared distributed storage |
| Performance | Baseline | Up to **5x** MySQL on RDS, up to **3x** PostgreSQL on RDS |
| Replica lag | Higher (asynchronous, own storage) | Typically **single-digit to low tens of ms** (replicas read the same shared storage) |
| Storage | Provisioned, with optional auto scaling | **Auto-expands**, pay for use |
| Data copies | 1 (plus a Multi-AZ standby) | **6 copies across 3 AZs** |
| Read replicas | Up to 15, **asynchronous** | Up to **15**, share storage, **lower lag** |
| Failover | Multi-AZ, about **60-120 s** | Typically **under 30 s** |
| Standby usable? | Classic Multi-AZ standby: **no** | **Replicas serve reads** and are failover targets |
| Replica auto scaling | No | **Yes** |
| Endpoints | One per instance | **Writer and reader endpoints** |
| Backtrack | No | **Yes** (MySQL) |
| Cross-region | Cross-region replicas | Replicas and **Global Database** |
| Cost | Lower | About **20% higher** |

### 9. Exam-Style Recall

| If the question says... | Think... |
|---|---|
| "MySQL/PostgreSQL-compatible, cloud-optimized, 5x faster" | **Amazon Aurora** |
| "Relational DB that auto-grows storage with no capacity planning" | **Aurora** |
| "Data replicated across 3 AZs with 6 copies" | **Aurora** |
| "Single endpoint that always points to the writer" | **Aurora writer endpoint** |
| "Load balance reads across all replicas" | **Aurora reader endpoint** |
| "Scale read replicas automatically" | **Aurora Auto Scaling** (1 to 15 replicas) |
| "Fastest automatic failover for a relational database" | **Aurora** (typically under 30 s) |
| "Write quorum / read quorum" | **4 of 6 / 3 of 6** |
| "Undo a bad change by rewinding to a point in time without restoring" | **Backtrack** (Aurora MySQL) |
| "Cross-region DR with sub-second replication lag" | **Aurora Global Database** |
| "Storage self-heals and replicates peer-to-peer" | **Aurora** storage layer |
| "Unpredictable workload, capacity adjusts automatically" | **Aurora Serverless v2** |
| "Which is more expensive: Aurora or RDS?" | **Aurora** (about 20%), but more efficient |
| "Does the load balancing of the reader endpoint happen per query?" | **No**, per **connection** |
| "Which instance can be promoted if the writer fails?" | **Any replica** (by failover priority) |
| "High I/O workload, predictable cost, no per-I/O charge" | **Aurora I/O-Optimized** |
| "Low or moderate I/O, pay per request" | **Aurora Standard** |
| "Replica in another AZ for fast failover" | **Aurora replica** (reader) in a different AZ |
| "Writes sent to a reader are forwarded to the writer" | **Local write forwarding** |
| "Restore Aurora to a time yesterday" | **PITR** (new cluster) or **Backtrack** (in place, MySQL) |
| "Default Aurora MySQL / PostgreSQL port" | **3306 / 5432** |
| "Can't connect to Aurora from my laptop" | **Public access** and **security group** (DB port, your IP) |
| "Delete an Aurora cluster" | Delete **instances first**, then the **cluster** |

---

## Amazon Aurora - Hands On

### 1. Cost Warning

- Aurora has no free tier. A writer **and** a reader instance bill **per hour**, plus **storage, I/O, and backups**.
- The wizard shows an **estimated monthly cost** at the bottom. Check it before clicking Create.
- Aurora is **not** covered by the RDS Free Tier template.
- **Delete everything right after the demo.**

### 2. Wizard: Engine and Template

| Setting | Demo value | Notes |
|---|---|---|
| **Creation method** | **Standard create** | Shows every option. Easy create hides most of them. |
| **Engine** | **Aurora (MySQL Compatible)** | The other choice is **Aurora (PostgreSQL Compatible)** |
| **Engine version** | Console default (**3.04.1**) | Aurora MySQL 3.x is MySQL 8.0-compatible. Your default may differ. |
| **Version filters** | Not used | Show only versions that support **Global Database**, **Parallel Query**, or **Serverless v2** |
| **Template** | **Production** | Unlocks all configuration options. **Dev/Test** is the cheaper option. |

- **Parallel Query** (MySQL only) pushes query processing down to the storage layer, which helps analytics on large tables.
- The version filters matter because **features depend on the engine version**.

### 3. Wizard: Settings, Storage, and Instance

#### 3.1 Settings

| Setting | Demo value |
|---|---|
| **DB cluster identifier** | `database-2` (lecture: "database two") |
| **Master username** | `admin` |
| **Master password** | Entered manually (self-managed). **Secrets Manager** is the managed alternative. |

- The identifier names the **cluster**, not an instance.

#### 3.2 Cluster storage configuration

| Option | Best for |
|---|---|
| **Aurora Standard** | Cost-effective workloads with **moderate I/O**. You pay per I/O request. |
| **Aurora I/O-Optimized** | **I/O-intensive** workloads (high read/write). **No per-I/O charge**, but higher instance and storage prices. |

- Storage itself is not provisioned. It **auto-expands** (10 GB steps), as covered in the Aurora overview.

#### 3.3 Instance configuration

| Choice | Detail |
|---|---|
| **Provisioned instance class** | Memory-optimized (`r` classes), **burstable** (`t` classes), and optionally previous-generation classes. The demo used **`db.t3.medium`**. |
| **Serverless v2** | Only shown for **compatible versions**. You don't pick an instance type. You set a **minimum and maximum ACU** (Aurora Capacity Units). |

- **ACU** is a unit of compute plus memory (1 ACU is about 2 GiB RAM). The database **scales automatically between your min and max ACU**.
- Newer versions allow a **minimum of 0 ACU** (auto-pause), so a Serverless v2 cluster can idle at near-zero compute cost.
- Serverless v2 suits **unpredictable or intermittent** workloads.

#### 3.4 Availability and durability

- The demo created a **reader in a different AZ** to show Aurora's full behavior (it costs a second instance).
- Storage is **already 6 copies across 3 AZs** with or without a replica. The replica adds **compute** redundancy and a fast failover target.

### 4. Wizard: Connectivity and Additional Configuration

#### 4.1 Connectivity

| Setting | Demo value | Notes |
|---|---|---|
| **Compute resource** | **Don't connect to an EC2 compute resource** | |
| **Network type** | **IPv4** | **Dual-stack** (IPv4 + IPv6) is available if the VPC supports it |
| **VPC / subnet group** | Default VPC / default subnet group | The subnet group needs subnets in **at least 2 AZs** |
| **Public access** | **Yes** | Gives a public IP. Fine for a demo, **not for production**. |
| **VPC security group** | **Create new**: `demo-database-aurora` | The inbound rule must allow your IP on the DB port |
| **Port** | **3306** | Aurora MySQL default. Aurora PostgreSQL uses **5432**. |

#### 4.2 Additional configuration

| Setting | Demo value / note |
|---|---|
| **Local write forwarding** | Option shown. **Writes sent to a reader are forwarded to the writer**, which simplifies connection management. |
| **Database authentication** | **Password**, or add **IAM database authentication**, or **Kerberos** (external identity) |
| **Enhanced Monitoring** | **Disabled** (not needed) |
| **Initial database name** | `mydb` |
| **Backup retention** | **1 day** (range **1 to 35 days**) |
| **Encryption** | Option shown. **KMS**, and it must be chosen at **creation**. |
| **Backtrack** | Option shown (rewind in place, covered in the overview). Not configured. |
| **Log exports** | Option shown, to CloudWatch Logs. Skipped. |
| **Deletion protection** | Option shown. It blocks accidental deletion. |

### 5. After Creation: Cluster, Instances, Endpoints

- The database list shows a **regional cluster** with two instances:
  - A **writer instance**.
  - A **reader instance** in a **different AZ**.
- Only **one writer** exists. Reads can go to the reader. This is the "different instances for writing and reading" point in the lecture.
- Open the cluster to see the writer, reader, and per-instance endpoints (the reader's endpoint appears once it finishes creating).

- Connecting works like RDS: the endpoint DNS name, port 3306, the master credentials, and `mydb`. The security group must allow your source IP.

### 6. Features Explored in the Console

#### 6.1 Cluster Actions

| Action | What it does |
|---|---|
| **Add reader** | Adds a replica to the cluster for more **read scaling** (up to **15**) |
| **Create cross-region read replica** | Creates a replica cluster in **another region** |
| **Restore to point in time** | Creates a **new cluster** at a chosen time within the backup retention window |
| **Add replica auto scaling** | Creates a scaling policy for replicas (section 6.2) |
| **Add AWS Region** | Turns the cluster into a **Global Database** (section 6.3) |

#### 6.2 Replica Auto Scaling

The lecture opened the policy form and cancelled it.

| Setting | Demo value |
|---|---|
| **Policy name** | Read replica scaling policy |
| **Metric** | **Average CPU utilization of Aurora Replicas**, or **average connections of Aurora Replicas** |
| **Target value** | **60%** |
| **Scaling cooldowns** | Optional scale-out and scale-in periods |
| **Capacity** | **Min 1, max 15** replicas |

- It scales **readers only**. The writer never auto-scales (use Serverless v2 for compute that scales).

#### 6.3 Add AWS Region (Global Database)

- **Actions, Add AWS Region** turns the cluster into an **Aurora Global Database**: one primary region plus read-only secondary regions.
- It was **not possible in the demo** for two reasons:
  - The engine version must **support Global Database**.
  - The **instance class must be large enough**. `db.t3.medium` wasn't, so the lecturer would need to change to a larger class (for example a `large`).

---

## RDS & Aurora Security

### TL;DR

- **Encryption at rest:** **KMS**, chosen at **creation time**. The master and all replicas are encrypted. You can't encrypt an existing unencrypted DB in place: **snapshot, copy encrypted, restore**.
- **Encryption in flight:** **TLS**. Clients must trust the **AWS root/CA certificates** (downloaded from AWS).
- **Authentication:** **username/password**, or **IAM database authentication** (a short-lived token instead of a password, so EC2/Lambda roles can connect).
- **Network control:** **security groups** (ports, IPs, other security groups).
- **No SSH access** (managed service), except with **RDS Custom**.
- **Audit logs:** record the queries and activity. They are kept only for a short time on the instance, so **export them to CloudWatch Logs** for long-term retention.

### 1. Encryption at Rest

| Property | Detail |
|---|---|
| **What is encrypted** | The DB storage volumes, **automated backups, snapshots, logs, and read replicas** |
| **Mechanism** | **AWS KMS** (AES-256) |
| **When it is set** | **At creation time**, on the first launch of the DB or cluster |
| **Key options** | AWS managed key (`aws/rds`) or your own **customer managed key (CMK)** |
| **Applies to** | **RDS** (all engines) and **Aurora** |

**Rules to know:**
- The **master and every replica** use encryption. This is applied through KMS.
- **If the master is not encrypted, its read replicas cannot be encrypted** either. The replica inherits the primary's encryption state (for same-region replicas).
- **Encryption cannot be removed**, and **cannot be enabled in place** on an existing unencrypted DB.
- Snapshots of an encrypted DB are **encrypted**.
- **Sharing** an encrypted snapshot with another account requires a **customer managed key** (the default `aws/rds` key can't be shared).
- Encryption has **minimal performance impact**.
- Oracle and SQL Server also offer **TDE (Transparent Data Encryption)**, a separate engine-level feature.

#### 1.1 Encrypting an existing unencrypted database

```
Unencrypted DB --> [Take snapshot] --> [Copy snapshot with encryption enabled (KMS key)]
                                                   |
                                                   v
                                    [Restore from the encrypted snapshot]
                                                   |
                                                   v
                                  New ENCRYPTED DB (point the app to it)
```

1. **Take a snapshot** of the unencrypted DB.
2. **Copy the snapshot** and choose **Enable encryption** with a KMS key.
3. **Restore** a new DB from the encrypted copy.
4. Switch your application to the **new endpoint**, then delete the old DB.

- The lecture says "snapshot and restore as an encrypted database". The documented path is **snapshot, encrypted copy, restore**. Newer console versions may let you pick encryption during restore.
- Restore always creates a **new instance** with a **new endpoint**, so plan for a cutover.
- For **Aurora**, the same applies at the cluster level.

### 2. Encryption in Flight (TLS)

- Traffic between **clients and the database** can be encrypted with **TLS** (the lecture says each RDS/Aurora DB is "ready" for it by default).
- **Clients must use the AWS TLS root certificates**, which AWS provides on its website. Use the **global CA bundle**.
- This protects against eavesdropping and verifies you reach the real DB.
- **Enforcing TLS** is an engine setting:

| Engine | How to require TLS |
|---|---|
| **MySQL / MariaDB / Aurora MySQL** | `require_secure_transport = 1` (parameter group) |
| **PostgreSQL / Aurora PostgreSQL** | `rds.force_ssl = 1` (parameter group) |
| **SQL Server** | `rds.force_ssl = 1` |

- **IAM database authentication requires TLS.**
- Certificates **expire and rotate**, so keep clients on the current CA bundle.

### 3. Authentication

| Method | How it works | Notes |
|---|---|---|
| **Username and password** | The classic master user plus DB users | Can be stored and **rotated automatically** with **AWS Secrets Manager** |
| **IAM database authentication** | The client requests an **auth token** with its **IAM** identity and uses it **instead of a password** | See below |
| **Kerberos / Active Directory** | Integrates with **AWS Managed Microsoft AD** | Common for SQL Server, Oracle, PostgreSQL, MySQL |

#### 3.1 IAM database authentication

- The lecture: EC2 instances with **IAM roles** can authenticate to the DB **without a username and password**, so access is managed centrally in IAM.
- How it works:
  1. The app (with an **IAM role** or user) generates a token, for example via `aws rds generate-db-auth-token` or the SDK.
  2. The token is used as the **password** when connecting.
  3. The token is **valid for 15 minutes**. It only authenticates the **initial connection**, and an open connection stays up.
- Requirements:
  - **TLS must be used.**
  - The IAM policy allows **`rds-db:connect`** for that DB user.
  - A **DB user** (without a password) is created in the database and mapped to IAM.
- Supported on **MySQL, MariaDB, PostgreSQL, Aurora MySQL, and Aurora PostgreSQL**. **Not** available for Oracle and SQL Server.
- Benefits: **no passwords in code**, **central control**, and **short-lived** credentials.
- Limit: there is a cap on new IAM-authenticated connections per second, so it is not for very high connection rates.

**Two different "IAM" uses (a common mix-up):**

| | What it controls |
|---|---|
| **IAM policies on the RDS API** | **Who can manage** DB resources (create, modify, delete instances) |
| **IAM database authentication** | **Who can log in** to the database engine |

### 4. Network Access Control

- **Security groups** control network access to the DB:
  - Allow or block **specific ports**, **specific IP ranges**, or **specific security groups**.
  - The DB port is **3306** (MySQL/Aurora MySQL/MariaDB), **5432** (PostgreSQL), **1433** (SQL Server), **1521** (Oracle).
- **Best practice:**
  - DB in **private subnets**, with **Public access = No**.
  - DB SG inbound on the DB port with **source = the application's security group** (not `0.0.0.0/0`).
- **Network ACLs** at the subnet level are an extra layer.
- Security groups are **stateful**. Return traffic is allowed automatically.
- The DB subnet group must span **at least 2 AZs**.

### 5. No SSH Access

- RDS and Aurora are **managed services**, so you **can't SSH** into the underlying instance or access the OS.
- **Exception: RDS Custom** (for **Oracle and SQL Server**) lets you reach the OS and customize the environment.
- If you need OS access, the other option is a **self-managed DB on EC2**.
- You connect to the **database** through the DB port with a SQL client.

### 6. Audit Logs

- **Audit logs** record **which queries are run** and **what happens** on the database over time (connections, queries, changes).
- You enable them per engine, usually via an **option group** or **parameter group**:

| Engine | Typical mechanism |
|---|---|
| **MySQL / MariaDB** | **MariaDB Audit Plugin** (option group) |
| **Aurora MySQL** | **Advanced Auditing** (parameters) |
| **PostgreSQL / Aurora PostgreSQL** | **pgAudit** extension |
| **Oracle / SQL Server** | Native audit features |

- **Retention is short.** The lecture says the logs "will be lost after a bit of time", because logs on the instance rotate and are deleted.
- **To keep them long term, export the logs to CloudWatch Logs.**
  - Turn on **Log exports** in the DB's configuration (for example audit, error, general, and slow query logs).
  - In CloudWatch Logs you set the **retention period** and can build **metric filters, alarms, or queries**.
  - From there you can archive to **S3**.
- Related: **Database Activity Streams** (Aurora, and RDS Oracle/SQL Server) send a near-real-time activity feed to **Kinesis**, for compliance use.
- **CloudTrail** records **API calls** to RDS (who created or deleted a DB). It is separate from DB audit logs, which record **queries**.

### 7. Exam-Style Recall

| If the question says... | Think... |
|---|---|
| "Encrypt RDS/Aurora data at rest" | **KMS**, enabled at **creation** |
| "Encrypt an existing unencrypted RDS DB" | **Snapshot, copy with encryption, restore** |
| "Read replica of an unencrypted DB must be encrypted" | **Not possible.** Encrypt the primary first (via snapshot and restore). |
| "Encrypt data in transit between app and DB" | **TLS**, with the **AWS root certificates** on the client |
| "Force all connections to use SSL" | Parameter group: `rds.force_ssl` (PostgreSQL/SQL Server) or `require_secure_transport` (MySQL) |
| "EC2 instance connects to RDS without storing a password" | **IAM database authentication** (IAM role, auth token) |
| "How long is the IAM DB auth token valid?" | **15 minutes** |
| "IAM auth requirement" | **TLS** (SSL) connection |
| "Rotate DB credentials automatically" | **AWS Secrets Manager** |
| "Track which queries were run on the DB" | **Audit logs** |
| "Keep DB audit logs for a long time" | **Export to CloudWatch Logs** (set retention) |
| "Who deleted the DB instance?" | **CloudTrail** |
| "Share an encrypted snapshot with another account" | Use a **customer managed KMS key** and share the key too |
| "Near-real-time database activity feed for compliance" | **Database Activity Streams** (Kinesis) |

---

## RDS Proxy

### TL;DR

- **RDS Proxy** is a **fully managed, serverless database proxy** that sits between your application and an RDS or Aurora database.
- **Main job:** **pool and share (multiplex) database connections**, so thousands of client connections become far fewer connections to the DB. This reduces CPU/RAM pressure, open connections, and timeouts.
- **Faster failover:** reduces failover time by **up to 66%** (RDS Multi-AZ and Aurora). The proxy handles the failover, and apps keep connecting to the same proxy endpoint.
- **No code change:** just point the app at the **proxy endpoint** instead of the DB endpoint.
- **Security:** can **enforce IAM authentication** and keep DB credentials in **Secrets Manager**. It is **never publicly accessible** (VPC only).
- **Classic use case:** **AWS Lambda**. Many short-lived functions opening connections can overwhelm a DB, and the proxy absorbs them.
- Serverless, auto scaling, and **highly available across multiple AZs**.

### 1. What Is RDS Proxy?

- You can already run RDS in a VPC and connect to it directly. RDS Proxy adds a **managed proxy layer** in front of it.
- Without a proxy:

```
App 1 --\
App 2 ---+--> many connections --> [RDS / Aurora]   (CPU, RAM, and connection limits under stress)
App N --/
```

- With a proxy:

```
App 1 --\
App 2 ---+--> [RDS Proxy] --> fewer, pooled connections --> [RDS / Aurora]
App N --/
```

| Property | Detail |
|---|---|
| **Type** | Fully managed database proxy |
| **Scaling** | **Serverless, auto scaling.** You don't manage its capacity. |
| **Availability** | **Highly available**, spread across **multiple AZs** |
| **Network** | Lives **inside your VPC**, **never publicly accessible** |
| **Supported databases** | **RDS MySQL, PostgreSQL, MariaDB, SQL Server**, and **Aurora MySQL and PostgreSQL**. Not every engine is supported, so check the docs for Oracle and Db2. |
| **App changes** | **None** except the connection endpoint |

### 2. Benefit 1: Connection Pooling

- **Problem:** every connection to a DB consumes **memory and CPU** on the DB, and each engine has a **maximum connection count**. Too many connections cause **timeouts, errors, and slowdowns**.
- **Solution:** apps connect to the **proxy**. The proxy keeps a **pool** of DB connections and **reuses them** across many client connections.
- Results:
  - **Fewer open connections** on the database.
  - **Lower CPU and RAM usage**, so better database efficiency.
  - **Fewer timeouts** and connection errors.
- **Multiplexing:** a DB connection is **borrowed** for a transaction and returned when it finishes, so one DB connection can serve many clients.
- **Pinning:** some session-specific operations (for example certain `SET` statements, temporary tables, or locks) **pin** a client to one DB connection. This reduces the pooling benefit. Keep sessions simple to get the most from it.

**Key settings:**

| Setting | Meaning |
|---|---|
| **Max connections percentage** | The share of the DB's `max_connections` that the proxy may use |
| **Max idle connections percentage** | How many idle connections the proxy keeps warm |
| **Connection borrow timeout** | How long a client waits for a free connection (default **120 s**) |
| **Idle client connection timeout** | Closes idle client connections (default **30 minutes**) |

- It reduces **database load and open connections**, not query latency (it adds a small hop).
- **Pinning** reduces multiplexing, so avoid session-level state where you can.

### 3. Benefit 2: Faster Failover

- During a failover (for example Multi-AZ primary to standby, or an Aurora writer to a replica), apps normally lose connections and must **reconnect and retry**.
- With RDS Proxy:
  - Apps keep connecting to the **proxy**, which **doesn't change** during failover.
  - The proxy **detects the failover** and **reconnects to the new primary** itself.
  - It holds or retries client requests during the switch, and doesn't depend on DNS propagation.
- Result: failover time is reduced by **up to 66%**. The lecture says this applies to **RDS and Aurora**.

```
Before failover:  App -> Proxy -> Primary (AZ-A)   [Standby (AZ-B)]
During failover:  App -> Proxy -> (proxy waits and reconnects)
After failover:   App -> Proxy -> New primary (AZ-B)
```

- Reminder: Aurora failover is typically under 30 s, and RDS Multi-AZ about 60-120 s. The proxy trims time off both.

### 4. Benefit 3: Enforce IAM Authentication and Secure Credentials

- The proxy can **require IAM authentication** for client connections, so only identities with permission (for example a Lambda or EC2 role) can connect.
- Database credentials are stored in **AWS Secrets Manager**. The proxy fetches them and uses them to connect to the DB. **Apps don't need the DB password.**
- Flow:

```
App (IAM role) --IAM auth token--> [RDS Proxy] --credentials from Secrets Manager--> [DB]
```

- Requirements:
  - The proxy's **IAM role** must be allowed to read the secret in Secrets Manager (and decrypt it with KMS).
  - The app's IAM identity needs **`rds-db:connect`** permission for the proxy.
  - **TLS** is required for IAM authentication. The proxy can also **require TLS** for all connections.
- Exam shortcut: "**enforce IAM authentication for an RDS database**" means **RDS Proxy**. A DB with IAM authentication enabled still allows password logins, but the proxy can **require** IAM.

### 5. Network and Security

- **VPC only.** It is **never publicly accessible**, so you **can't connect to the proxy over the internet**.
- To reach it, the client must be **in the VPC** (or connected through **VPN**, **Direct Connect**, or **peering**).
- Security groups:

| SG | Inbound rule |
|---|---|
| **Proxy SG** | DB port, source = the **application's SG** |
| **DB SG** | DB port, source = the **proxy's SG** |

- The proxy needs **subnets in at least 2 AZs**, which is how it is made highly available.
- The proxy is **not** a replacement for a read replica or Multi-AZ. It sits **in front of** them.

### 6. Endpoints

| Endpoint | Use |
|---|---|
| **Default proxy endpoint** | Read/write traffic. Points to the **writer**. |
| **Read-only endpoint** | For **Aurora**, sends reads to **replicas** (load balanced). |
| **Additional custom endpoints** | Reach the proxy from a **different VPC or subnets** |

- The app uses the **proxy endpoint** as its DB host name. Port and credentials usage otherwise stay the same.
- A proxy targets **one** RDS instance or Aurora cluster (through its target group).

### 7. Use Case: AWS Lambda

- **Lambda** (covered later in the course) runs code in short-lived function instances.
- Functions can **scale to hundreds or thousands** of concurrent runs, and they **appear and disappear quickly**.
- **Without a proxy:** each function opens its **own DB connection**, and many are left open or time out. The DB hits its **connection limit**, producing errors and timeouts ("a mess").
- **With RDS Proxy:** the functions **connect to the proxy**, and the proxy **pools** them into a **small number of DB connections**.
- The lecture's phrase "the functions will overload the proxy, but it's meant to be overloaded" means **the proxy is built to absorb huge numbers of client connections**, so the DB doesn't have to.
- Notes:
  - The Lambda function must be **in the same VPC** (or one that can reach the proxy).
  - Lambda can use **IAM authentication** with its **execution role**, so no password is stored in code.
  - The lecturer says it will be revisited in the **Lambda** section.

### 8. When to Use It

| Good fit | Poor fit |
|---|---|
| **Lambda** and other highly concurrent, bursty clients | A **few long-lived** connections (little to pool) |
| Apps that **open and close** many short connections | Apps with heavy **session pinning** |
| DBs hitting **connection limits** or high CPU from connections | Needs a **public** endpoint |
| Need **faster failover** | Engines the proxy doesn't support |
| Want **IAM auth** plus **Secrets Manager** | |

- **Cost:** billed **per vCPU-hour** of the provisioned DB instance (Aurora Serverless v2 is billed per **ACU-hour**). It is not free, so use it when pooling or failover handling is needed.

### 9. Exam-Style Recall

| If the question says... | Think... |
|---|---|
| "Too many connections to RDS from many clients" | **RDS Proxy** (connection pooling) |
| "Lambda functions overwhelm the RDS database with connections" | **RDS Proxy** |
| "Reduce RDS or Aurora failover time" | **RDS Proxy** (up to **66%**) |
| "Enforce IAM authentication for an RDS database" | **RDS Proxy** |
| "Store DB credentials securely for the proxy" | **AWS Secrets Manager** |
| "Change needed in the application to adopt it" | Only the **connection endpoint** |
| "Can the RDS Proxy be accessed over the internet?" | **No**, VPC only |
| "Is the proxy highly available?" | **Yes**, across multiple AZs |
| "Does the proxy need capacity management?" | **No**, it is serverless and auto scaling |
| "Which DBs does RDS Proxy support?" | **MySQL, PostgreSQL, MariaDB, SQL Server, Aurora MySQL/PostgreSQL** |
| "Reduce CPU and memory pressure from connections on the DB" | **RDS Proxy** |
| "Scale reads on RDS" | **Read replicas**, not RDS Proxy |
| "High availability for the database itself" | **Multi-AZ** or **Aurora** (the proxy complements it) |

---

## ElastiCache Overview

### TL;DR

- **ElastiCache** is AWS's **managed in-memory cache** service. It runs **Redis OSS**, **Memcached**, or **Valkey** (a Redis-compatible fork, added in recent years). It is the "RDS for caches".
- **In-memory** means very high performance and **sub-millisecond latency**.
- **Two main uses:**
  1. **Reduce load on databases** for **read-intensive** workloads (cache common query results).
  2. **Make apps stateless** by storing **session data** in the cache.
- AWS manages **OS patching, optimization, setup, configuration, monitoring, failure recovery, and backups**.
- **Heavy application code changes are required.** You must write the logic that checks the cache before or after the database.
- **Redis** = rich data types, **Multi-AZ with auto-failover**, **read replicas**, persistence, backup/restore. **Memcached** = simple, **multi-threaded**, **sharded**, **no replication or HA**, no persistence.
- Exam note: Redis vs Memcached is probably not heavily tested, but know the contrast.

### 1. What Is ElastiCache?

- **Cache** = fast, in-memory data store placed in front of a slower data store.
- As **RDS** gives you managed relational databases, **ElastiCache** gives you managed Redis or Memcached.
- Because data lives in **RAM**, reads are far faster than reads from a disk-based database.

| Property | Detail |
|---|---|
| **Type** | Managed in-memory data store and cache |
| **Engines** | **Redis OSS**, **Memcached**, **Valkey** |
| **Latency** | Typically **sub-millisecond** |
| **Deployment** | **Node-based clusters** (you pick node types) or **ElastiCache Serverless** (capacity scales automatically) |
| **Network** | Runs **inside your VPC**, reached through **security groups**. It has **no public access** by design. |
| **Default ports** | **Redis 6379**, **Memcached 11211** |
| **Managed by AWS** | OS patching, optimization, setup, configuration, monitoring, failure recovery, backups |

### 2. Why Use a Cache?

#### 2.1 Reduce database load

- Databases like RDS are comparatively slow and costly for **repeated, read-heavy** queries.
- Cache the results of **common queries** so the database isn't hit every time.
- Benefits: **lower DB load**, **faster responses**, and **better scalability**.
- It also complements **read replicas**: replicas scale reads, and the cache removes many reads altogether.

#### 2.2 Make the application stateless

- Store **user state** (for example sessions) in ElastiCache instead of on the app instance.
- Any instance can serve any user, so scaling in and out with an **ASG** works smoothly.
- This is the "better design" alternative to **sticky sessions**.

#### 2.3 Application code changes are required

- **This is not a toggle.** You must change the application to:
  - Query the **cache first** (or write through it), and
  - Query the **database** when the cache doesn't have the data.
- The lecture says caching strategies come in the next lectures (lazy loading, write-through, and so on).

### 3. Architecture 1: Cache in Front of the Database

```
                 1. check cache
Application  ----------------------->  [ElastiCache]
     |                                      |
     | 2a. CACHE HIT: return data  <--------+
     |
     | 2b. CACHE MISS:
     +----------------------------------->  [RDS]   read from the database
     |
     | 3. write the result back to ElastiCache
     +----------------------------------->  [ElastiCache]
```

| Term | Meaning |
|---|---|
| **Cache hit** | The data is **in the cache**. The app returns it right away and **saves a trip to the database**. |
| **Cache miss** | The data **isn't in the cache**. The app reads the database, then **writes the result into the cache** so the next request hits. |

- Other app instances making the same query benefit from the entry already written.
- **Result:** the RDS database gets much less read traffic.
- **Cache invalidation:** a cache can hold **stale data**, so you need a strategy (for example **TTL**, or deleting or updating entries when the DB changes).
  - The lecture calls this "the whole difficulty" of caching.
  - The goal is that **only current data** is served.
- A cache is **not** a system of record. The **database remains the source of truth**.
- Related services: **DAX** (cache for **DynamoDB**), **CloudFront** (cache at the edge for content), **API Gateway caching**. They solve different caching problems.

### 4. Architecture 2: User Session Store

```
User logs in --> App instance A --writes session--> [ElastiCache]
User's next request --> App instance B --reads session--> [ElastiCache] --> still logged in
```

1. The user logs in through any application instance.
2. That instance **writes the session data to ElastiCache**.
3. If the next request lands on **another instance**, it **reads the session from ElastiCache**.
4. The user stays logged in and doesn't log in again.

- The app is now **stateless**. Instances hold no session data, so any one can be added or removed.
- Set a **TTL** on sessions so they expire.
- Compared to sticky sessions: **no load imbalance** and **no lost sessions** if an instance dies.

### 5. Redis vs Memcached

| Feature | **Redis** | **Memcached** |
|---|---|---|
| **Data model** | Rich structures: strings, hashes, lists, **sets**, **sorted sets**, and more | Simple key-value (strings and blobs) |
| **High availability** | **Multi-AZ with auto-failover** | **None** |
| **Replication / read replicas** | **Yes**. Replicas **scale reads** and give HA. | **No replication** |
| **Scaling writes / data** | **Cluster mode** shards data across multiple shards | **Sharding** (partitioning) across multiple nodes |
| **Persistence** | **Yes**: **AOF** persistence and snapshots | **No** (data lives in memory only) |
| **Backup and restore** | **Yes** | Not on self-designed clusters. The lecture says only the **serverless** version has it. |
| **Threading** | Mostly **single-threaded** command execution | **Multi-threaded** architecture |
| **Typical features** | Leaderboards (sorted sets), pub/sub, geospatial, transactions, Lua | Simple, large, fast cache |
| **If a node fails** | Replica takes over | **You lose that node's data**, possibly the whole cache |

**Lecture mental models:**
- **Redis**: a node **replicated** to another node (primary plus replicas).
- **Memcached**: **multiple nodes side by side, each holding a slice** of the data (**sharding**). No copies, so no HA.
- The lecture says these are simplifications, since both engines (and the serverless versions) keep evolving.

**Choosing:**
- Pick **Redis** (or Valkey) when you need **HA, persistence, backups, replicas, or advanced data types** (leaderboards, session store you can't afford to lose).
- Pick **Memcached** for a **simple, multi-threaded, horizontally scaled** cache where losing the cache is acceptable.
- Sorted sets give an **ordered ranking**, so they suit **gaming leaderboards**.

### 6. Exam-Style Recall

| If the question says... | Think... |
|---|---|
| "Managed in-memory cache" | **ElastiCache** |
| "Reduce read load on RDS for repeated queries" | **ElastiCache** (cache in front of the DB) |
| "Store session data so instances are stateless" | **ElastiCache** (session store) |
| "Data found in the cache" | **Cache hit** |
| "Data not in the cache, read the DB and store it" | **Cache miss**, then populate the cache |
| "Cached data may be outdated" | **Cache invalidation** or **TTL** |
| "Adopting ElastiCache requires application changes" | **True** |
| "Multi-AZ with automatic failover for a cache" | **Redis** |
| "Read replicas for a cache" | **Redis** |
| "Sorted sets or a leaderboard" | **Redis** |
| "Cache with persistence (AOF) and backup/restore" | **Redis** |
| "Simple multi-threaded cache, sharded across nodes, no HA needed" | **Memcached** |
| "Which cache engine has no replication?" | **Memcached** |
| "Cache for DynamoDB" | **DAX**, not ElastiCache |
| "Cache static content close to users" | **CloudFront** |
| "Run ElastiCache on premises" | **AWS Outposts** |
| "Controls which subnets the cache can run in" | **Subnet group** |
| "Password-protect a Redis cluster" | **Redis AUTH token** (needs **in-transit encryption**) |
| "Fine-grained user permissions on Redis" | **User group ACL (RBAC)** |
| "Encrypt cache data on disk / in backups" | **Encryption at rest** (KMS) |
| "Limit which apps can reach the cache" | **Security group** (source = the app's SG) |
| "Cache that needs no capacity management" | **ElastiCache Serverless** |
| "Redis with a primary and up to 5 read replicas, single shard" | **Cluster mode disabled** |
| "Scale writes by partitioning data across shards" | **Cluster mode enabled** |
| "Failover and availability for the cache" | **Multi-AZ with auto-failover** (needs replicas) |
| "Endpoint for read-only traffic" | **Reader endpoint** |
| "Send slow queries to CloudWatch" | **Slow log** delivery to CloudWatch Logs |
| "Connect to ElastiCache from outside the VPC" | **Not directly possible.** Use VPN, a bastion host, or an app inside the VPC. |
| "Redis replacement, open source, recommended" | **Valkey** |

---

## ElastiCache Hands On

### 1. Starting the Wizard

- **Engine:** **Redis OSS** in the demo. **Valkey** is the recommended open-source replacement and shows the same wizard options. **Memcached** is the other engine.

#### 1.1 Deployment option

| Option | What it is |
|---|---|
| **Serverless** | Capacity scales automatically and you don't pick node types. Billed on **data stored** and **compute used (ECPUs)**. |
| **Node-based cluster** | **You choose node type, node count, and shards.** Billed per **node-hour**. **Used in the demo.** |

#### 1.2 Creation method

| Method | What it does |
|---|---|
| **Restore from backup** | Creates the cluster from an existing **backup (snapshot)** |
| **Easy create** | Applies **recommended best practices** for a chosen type: **Production**, **Dev/Test**, or **Demo** |
| **Configure and create** (cluster create) | Shows **every option**. **Used in the demo.** |

### 2. Cluster Mode

| | Cluster mode **disabled** | Cluster mode **enabled** |
|---|---|---|
| **Shards** | **1 shard** | **Multiple shards** across multiple servers |
| **Nodes per shard** | **1 primary** plus **up to 5 read replicas** | 1 primary plus up to 5 replicas **per shard** |
| **Scales** | **Reads** (replicas) | **Reads and writes** (and total data size), by adding shards |
| **Demo choice** | **Yes** | No |

- Mental model: **disabled** = one primary replicated to replicas. **Enabled** = the data is **partitioned (sharded)** across several primaries.

### 3. Settings Used in the Demo

#### 3.1 Cluster info

| Setting | Demo value | Notes |
|---|---|---|
| **Cluster name** | `DemoCluster` | |
| **Location** | **AWS Cloud** | The alternative is **On-premises** via **AWS Outposts**. |
| **Multi-AZ** | **Disabled** | Helps **availability and failover**, but adds cost because it needs replicas in other AZs |
| **Auto-failover** | Left **enabled** | Only meaningful when there are **replicas** to promote. The lecture left it on. |

#### 3.2 Cluster settings

| Setting | Detail |
|---|---|
| **Engine version** | Pick from the list |
| **Port** | **6379** (Redis/Valkey). Memcached uses **11211**. |
| **Parameter group** | Engine configuration settings, like an RDS parameter group |
| **Node type** | A **micro** type. Options shown: `cache.t2.micro`, `t3.micro`, `t4g.micro`. The lecturer says t2 and t3 are **free tier** eligible. |
| **Number of replicas** | **0** (cost saving) |

- With **Multi-AZ** you should have **at least one replica** (in another AZ), so failover has a target.
- Free tier eligibility changes by account type, so check the console estimate.

#### 3.3 Connectivity

| Setting | Detail |
|---|---|
| **Subnet group** | Create a new one, `my-first-subnet-group`. It tells ElastiCache **which subnets it may place nodes in**. |
| **VPC** | Choose the VPC. Subnets are **auto-selected** and can be overridden. |
| **AZ placement** | Choose which AZ each node or replica goes in. It didn't matter here, since there is no Multi-AZ. |

- Compare with RDS: a **DB subnet group** does the same job. For Multi-AZ, the subnet group needs subnets in **multiple AZs**.
- ElastiCache has **no public access**. It runs inside your VPC.

#### 3.4 Security

| Setting | Detail |
|---|---|
| **Encryption at rest** | Yes or no. If yes, choose a **KMS key**. |
| **Encryption in transit** | Yes or no. Encrypts data **between client and server** (TLS). **Disabled** in the demo. |
| **Access control** | **Only available if in-transit encryption is enabled.** See below. |
| **Security groups** | Network-level control over **which applications can reach the cluster** |

**Access control options (when in-transit encryption is on):**

| Option | How it works |
|---|---|
| **Redis AUTH** | A **password / AUTH token** that clients supply to connect |
| **User group access control list (ACL / RBAC)** | Define **users and permissions** in a **user group**. The wizard lets you **create a user group** from the console. |

- Without encryption in transit, the demo had **no AUTH** and relied on **security groups only**.
- **Production:** enable **TLS** and an **AUTH token or ACL**, and restrict the **security group** to the app's SG.
- **Security group rule:** inbound **TCP 6379** with **source = the application's security group**.

#### 3.5 Backup, maintenance, logs, tags

| Setting | Detail |
|---|---|
| **Backup** | Enable automatic backups (snapshots), yes or no. Set a **retention period** if yes. |
| **Maintenance window** | Preferred window for patching and **minor version upgrades** |
| **Log delivery** | **Slow log** and **engine log** can be sent to **CloudWatch Logs** |
| **Tags** | Optional |

- Same ideas as **RDS**, which is why the lecturer went through them quickly.
- Review, then click **Create**. Status goes from **creating** to **available**.

### 4. After Creation

- Open the cluster to see **details, nodes, metrics, logs, and network security**.
- **Endpoints:**

| Endpoint | Use |
|---|---|
| **Primary endpoint** | **Reads and writes** go to the primary. Use it in the app. |
| **Reader endpoint** | **Reads** across the replicas (when you have any) |
| **Configuration endpoint** | Used instead when **cluster mode is enabled** (and for Memcached) |

- The lecture: you'd put the **primary endpoint** (or the **reader endpoint** for reads) in your application code.
- **Why no connection demo:** you need **application code**, plus access from **inside the VPC** (an EC2 instance, Lambda in the VPC, or a bastion). It isn't reachable from your laptop.
- A quick manual check, from an EC2 instance in the same VPC (and allowed by the SG):

```bash
redis-cli -h <primary-endpoint> -p 6379 ping   # expect: PONG
```

---

## ElastiCache Strategies

### TL;DR

- **Before caching, ask four questions:** Is it safe to cache this data? Is caching effective for it? Is it structured correctly? Which design pattern fits?
- **Lazy loading** (also called **cache-aside** or **lazy population**): read the cache first. On a miss, read the DB and write the result to the cache. Easy and efficient, but **stale data is possible** and a miss costs **3 round trips**.
- **Write-through:** write to the DB **and** the cache on every write. The cache is **never stale**, but there is a **write penalty (2 calls)**, **missing data** until it is written, and **cache churn**.
- **Combine both:** lazy loading fills gaps, and write-through keeps data fresh.
- **TTL** (time-to-live) expires entries. **Eviction** removes entries when memory is full (**LRU**) or on explicit delete. **Too many evictions means scale the cache up or out.**
- **Exam focus:** you must be able to **read pseudocode and recognize the strategy** (lazy loading versus write-through).
- Famous quote: "There are only two hard things in computer science: **cache invalidation** and naming things."

### 1. Questions to Ask Before Caching

| Question | Guidance |
|---|---|
| **Is it safe to cache?** | Usually yes, but cached data can be **out of date**, so you get **eventual consistency**. Only cache data where that is acceptable. |
| **Is caching effective for this data?** | **Good fit:** data changes **slowly** and **few keys** are requested **frequently**. **Anti-pattern:** data changes **very quickly** and you need the **whole key space**. |
| **Is the data structured correctly for caching?** | Key-value lookups and **aggregation results** cache well. Caching is about saving time, so shape the data to match your queries. |
| **Which caching design pattern fits?** | The rest of the lecture: lazy loading, write-through, TTL. |

- **Good candidates:** user profiles, blog posts, leaderboards, comments, activity streams, expensive query results.
- **Poor candidates:** data that must always be exact, such as **pricing** or **bank account balances**.

### 2. Strategy 1: Lazy Loading (Cache-Aside, Lazy Population)

- **Three names, one pattern.** The exam may use any of them.
- Components: **application**, **ElastiCache** (Redis or Memcached), **RDS** (or another DB).

#### 2.1 Flow

```
Read request
   |
   v
1. App asks the cache
   |-- CACHE HIT  --> return data (best case)
   |
   '-- CACHE MISS
         |
         v
   2. App reads the database (RDS)
         |
         v
   3. App WRITES the result into the cache
         |
         v
   Return data  (next request for this key = cache hit)
```

#### 2.2 Pros and cons

| Pros | Cons |
|---|---|
| **Only requested data is cached**, so it is space-efficient. Data nobody asks for never fills the cache. | A **cache miss costs 3 round trips**: (1) read cache, (2) read DB, (3) write cache. This causes **noticeable latency** for the user. |
| **Node failure or a wiped cache isn't fatal.** The app still works through the DB. | **Stale data:** if the DB is updated, the cache **isn't automatically updated** until the entry expires or is replaced. |
| **Simple to implement** and works in many situations. | A **cold cache** hurts: after a failure or restart, every read goes to the DB until the cache is **warmed**. |

- **Warm-up:** after a cache is wiped or replaced, early reads all miss and hit the DB. The cache fills over time.
- Ask yourself: is my data **OK to be out of date and eventually consistent**?

#### 2.3 Pseudocode (recognize this on the exam)

```python
def get_user(user_id):
    # 1. Check the cache
    record = cache.get(user_id)

    if record is None:
        # 2. Cache MISS: query the database
        record = db.query("SELECT * FROM users WHERE id = %s", user_id)
        # 3. Populate the cache for next time
        cache.set(user_id, record)

    # Cache HIT (or freshly loaded): return the record
    return record

user = get_user(17)
```

**How to spot it:** a **`get`** function that **checks the cache first**, **falls back to the DB when the result is `None`**, then **sets the cache**.

- ElastiCache requires **application code changes**. These patterns live in **your code**.

### 3. Strategy 2: Write-Through

- **Idea:** whenever the **DB is updated, also add or update the cache**. The write goes **through the cache to the DB**.
- Reads still check the cache first and get **cache hits**.

#### 3.1 Flow

```
Write request
   |
   v
1. App writes to the database (RDS)
   |
   v
2. App writes the same data to the cache
   |
   v
Cache now matches the DB
```

#### 3.2 Pros and cons

| Pros | Cons |
|---|---|
| **Cache data is never stale.** Every DB change is mirrored. | **Write penalty:** every write needs **2 calls** (DB and cache). |
| **Read penalty is replaced by a write penalty.** Users **expect writes to take longer** (posting something) and reads to be instant (opening a profile). | **Missing data:** the cache only gets data **when it is written**. Existing rows, or new rows after a cache failure, **aren't in the cache** until written again. |
| Reads are fast and predictable. | **Cache churn:** lots of data is written that **may never be read**. This wastes memory, especially in a **small cache**. |

- **Fix for missing data:** **combine write-through with lazy loading.** If a read misses, fall back to the DB and populate the cache.

#### 3.3 Pseudocode (recognize this on the exam)

```python
def save_user(user_id, values):
    # 1. Write to the database
    record = db.query("UPDATE users SET ... WHERE id = %s", user_id, values)

    # 2. Write the same data to the cache
    cache.set(user_id, record)

    return record
```

**How to spot it:** a **`save` / `update`** function that **writes to the DB and then to the cache**. The earlier function was `get_user`, which is a **read** optimization. This one is a **write** optimization.

- `get_user` (lazy loading) and `save_user` (write-through) **can be used together** in the same app.

### 4. Lazy Loading vs Write-Through

| Aspect | Lazy loading | Write-through |
|---|---|---|
| **Also called** | Cache-aside, lazy population | Write-through |
| **Cache is populated on** | **Read miss** | **Every write** |
| **Penalty** | **Read penalty** on a miss (3 round trips) | **Write penalty** (2 calls per write) |
| **Stale data** | **Possible** | **No** (cache mirrors the DB) |
| **Missing data** | Only on a miss, then self-heals | **Yes**, until the data is written |
| **Cache size** | Only requested data | Can hold **unread data** (churn) |
| **Cache failure** | Not fatal, but a **cold-start** period | Cache is missing data until rewritten |
| **Complexity** | **Easy** | More work |
| **Best used** | **Foundation** for most apps | **Add-on** to improve freshness |

### 5. Cache Evictions and TTL

#### 5.1 Evictions

The cache has **limited memory**, so entries get removed. Reasons for an eviction:

| Reason | Detail |
|---|---|
| **Explicit delete** | The app deletes the item (for example on a DB update, to **invalidate** it) |
| **Memory full** | The cache is full, so it evicts an item **not used recently**: **LRU (Least Recently Used)** |
| **TTL expiry** | The item's **time-to-live** ran out |

- **Too many evictions?** The cache is always at full memory. **Scale the cache up (bigger node) or out (more nodes/shards).** Watch the CloudWatch **`Evictions`** metric.

#### 5.2 TTL (Time-To-Live)

- A **TTL** says "this item may live only N seconds". When it expires, the cache **evicts** it.
- Works for **any** data type: leaderboards, comments, activity streams, and so on.
- The range depends on the app: **a few seconds** to **hours or days**.
- Even a **TTL of a few seconds** is **very effective** for **hot, heavily requested** data, because it absorbs the load while staying fresh.
- It balances **keeping data in the cache** against **evicting it so new data takes its place**.

```python
cache.set(user_id, record, ex=300)   # Redis: expire after 300 seconds (5 minutes)
```

### 6. Final Words of Wisdom

- **Lazy loading / cache-aside** is **easy to implement** and works in many situations. It is a **solid foundation**, especially to **improve read performance**.
- **Write-through** is more involved. It is an **optimization on top of lazy loading**, not a strategy on its own. **Don't make it your first priority.** Add it if you need to reduce staleness.
- **TTL** is usually a good idea, **except when using write-through** (per the lecture), since write-through already keeps entries fresh. Set TTLs to **sensible values for your app**.
- **Only cache data that makes sense** (profiles, blog posts), and **not data that must be exact** (pricing, bank balances).
- You can be asked to **read pseudocode** and name the strategy.

### 7. Additional Concepts (Beyond the Lecture)

| Concept | Description |
|---|---|
| **Write-behind (write-back)** | The app writes to the **cache first**, and the cache **asynchronously** writes to the DB. Very fast writes, but **data can be lost** if the cache fails before the DB write. Not covered in this lecture. |
| **Explicit invalidation** | On a DB update, **delete (or update) the cache key** so the next read reloads it. A common companion to lazy loading. |
| **Thundering herd / cache stampede** | When a hot key expires, many requests miss at once and all hit the DB. Reduce it with **randomized TTLs (jitter)** or by locking the refresh. |
| **Redis eviction policy** | The default on ElastiCache for Redis is **`volatile-lru`** (evict least recently used keys **that have a TTL**). Other policies exist (`allkeys-lru`, `noeviction`, and so on). **Memcached** uses LRU. |
| **Memory headroom** | Reserve memory so backups and replication don't push the node into swap or errors. |

### 8. Exam-Style Recall

| If the question says... | Think... |
|---|---|
| "Cache-aside" or "lazy population" | **Lazy loading** |
| "Check the cache, then the DB on a miss, then populate the cache" | **Lazy loading** |
| "Only requested data is cached" | **Lazy loading** |
| "Cache miss causes 3 network calls" | **Lazy loading** (read penalty) |
| "Cache can contain stale data" | **Lazy loading** |
| "Cache failure isn't fatal, but latency rises (cold cache)" | **Lazy loading** |
| "Write to the DB and then to the cache on each update" | **Write-through** |
| "Cache data is never stale" | **Write-through** |
| "Each write requires two calls" | **Write-through** (write penalty) |
| "Cache is missing data until it's written" | **Write-through** (fix: add lazy loading) |
| "Lots of data cached that is never read" | **Write-through** (cache churn) |
| "Pseudocode: `get` function with `if record is None` then `db.query` then `cache.set`" | **Lazy loading** |
| "Pseudocode: `save` function with `db.query(UPDATE...)` then `cache.set`" | **Write-through** |
| "Expire entries after a set time" | **TTL** |
| "Evict the item not used recently when memory is full" | **LRU** |
| "Cache is constantly evicting items" | **Scale the cache up or out** |
| "Easiest caching strategy to implement first" | **Lazy loading** |
| "Data must always be exact (balances, prices)" | **Don't cache it** (or use very short TTL, carefully) |

---

## Amazon MemoryDB for Redis - Overview

### TL;DR

- **MemoryDB** is a **Redis-compatible, durable, in-memory database service**. It is a **primary database**, not just a cache.
- **Redis/ElastiCache vs MemoryDB:** ElastiCache is typically used as a **cache** (some durability, optional). MemoryDB is a **real database** with a Redis-compatible API.
- **Performance:** ultra-fast, with **over 160 million requests per second**. Reads take **microseconds** and writes take **single-digit milliseconds**.
- **Durability:** data lives **in memory**, but every write is also stored in a **Multi-AZ transaction log**. This gives **fast recovery and data durability**.
- **Scale:** seamlessly from **tens of GB to hundreds of TB**.
- **Use cases:** web and mobile apps, **online gaming**, **media streaming**, and **microservices** that need a Redis-compatible in-memory database.
- The lecture is "just an overview, but enough for the exam".

### 1. What Is MemoryDB?

| Property | Detail |
|---|---|
| **Type** | Managed, **durable**, in-memory database |
| **API** | **Redis-compatible** (use your existing Redis clients, data structures, and commands). Newer versions also support **Valkey**. |
| **Role** | **Primary database** (system of record), not only a cache |
| **Durability** | **Multi-AZ transaction log** |
| **Latency** | **Microsecond reads**, **single-digit millisecond writes** |
| **Throughput** | **Over 160 million requests per second** |
| **Storage** | From **tens of GB to hundreds of TB** |
| **Network** | Runs **inside your VPC**, with no public access. Access it through **security groups**. |
| **Default port** | **6379** |

- Redis-compatible, so **existing Redis clients and apps** work with little change.
- Runs in a **VPC** only, and is **not** publicly accessible.

### 2. MemoryDB vs ElastiCache for Redis

| Aspect | **ElastiCache for Redis** | **MemoryDB for Redis** |
|---|---|---|
| **Intended use** | **Cache** in front of another database (optional persistence) | **Primary database** |
| **Durability** | Optional (AOF, snapshots). Data can be lost on failure. | **Durable by design** via the **Multi-AZ transaction log** |
| **Writes** | Acknowledged from memory | Acknowledged **after** the transaction log stores them across AZs |
| **Needs a backing DB?** | **Yes** (RDS, DynamoDB, and so on) | **No**, it is the database |
| **Write latency** | Lower (sub-millisecond) | Slightly higher (**single-digit ms**), because of durability |
| **Failover** | Replica promoted. **Recent writes may be lost.** | Replica promoted with **no data loss** |
| **Cost** | Lower | **Higher** |
| **Pick it when** | You want to **offload a database** | You want **Redis speed and durability** in one service |

- Using MemoryDB avoids running **two systems** (a cache and a database) and the **cache invalidation** problems that come with them.

### 3. How Durability Works

```
Write --> [Primary node (memory)]
              |
              +--> [Multi-AZ transaction log]  (stored durably across multiple AZs)
              |
              +--> replicas apply the log (AZ-b, AZ-c)

Write is acknowledged only after the log has stored it.
```

- Data is kept **in memory** for speed, and **also written to the Multi-AZ transaction log** for durability.
- After a failure or restart, MemoryDB **rebuilds the data from the log**, so it **recovers quickly**.
- A **failover** promotes a replica that is **consistent with the log**, so **no data loss**.
- **Consistency:** reads from the **primary** are **strongly consistent**. Reads from **replicas** are **eventually consistent**.
- **Snapshots** (backups) are stored in **S3**, and you can restore or keep them for retention.
- Highly available: **Multi-AZ**, with automatic failover and **no data loss**.

### 4. Scaling and Architecture

- **Cluster mode is always on.** Data is **sharded** across shards.
- Each shard has **1 primary and up to 5 replicas** (in different AZs for Multi-AZ).
- **Scale out** by adding shards (more write capacity and data size), and **scale reads** by adding replicas.
- **Scale up/down** by changing the node type. Scaling can be done with **minimal downtime**.
- The lecture's range: **tens of GB to hundreds of TB**.

### 5. Security

| Feature | Detail |
|---|---|
| **Encryption at rest** | **KMS** |
| **Encryption in transit** | **TLS** |
| **Access control** | **ACLs** (users and user groups), and **IAM** authentication |
| **Network** | **VPC**, **security groups**, **subnet groups**, no public access |

### 6. Use Cases

- **Web and mobile apps**, for example session stores and user profiles that need **durability**.
- **Online gaming**: leaderboards, player state, and matchmaking (Redis sorted sets).
- **Media streaming**: metadata, watch history, and personalization.
- **Microservices:** many services needing a shared, **Redis-compatible, in-memory database**.
- Also: shopping carts, real-time bidding, IoT state, and counters.

### 7. Choosing the Right In-Memory Option

| Need | Service |
|---|---|
| **Cache** for an RDS or other database | **ElastiCache** (Redis or Memcached) |
| **Cache for DynamoDB** with microsecond reads | **DAX** |
| **Redis-compatible primary database** with durability | **MemoryDB** |
| **Simple, multi-threaded, sharded cache** with no HA | **ElastiCache for Memcached** |
| **Durable key-value or document store** (not in memory) | **DynamoDB** |
| **Relational data** with SQL | **RDS / Aurora** |

### 8. Exam-Style Recall

| If the question says... | Think... |
|---|---|
| "Redis-compatible, durable, in-memory database" | **Amazon MemoryDB for Redis** |
| "Use Redis as a primary database, not a cache" | **MemoryDB** |
| "Redis data must survive failures, with no data loss" | **MemoryDB** (Multi-AZ transaction log) |
| "Ultra-fast performance with data durability" | **MemoryDB** |
| "Over 160 million requests per second" | **MemoryDB** |
| "Microservices need a shared Redis-compatible in-memory database" | **MemoryDB** |
| "What provides MemoryDB's durability?" | **Multi-AZ transaction log** |
| "Where are MemoryDB snapshots stored?" | **S3** |
| "Do I need a separate database behind MemoryDB?" | **No**, it is the database |
| "Memcached-compatible durable database" | **Not available.** MemoryDB is Redis-compatible only. |
