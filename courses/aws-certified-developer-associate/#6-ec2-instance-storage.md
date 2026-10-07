# EC2 Instance Storage

---

## Elastic Block Store (EBS) Overview

### TL;DR

- **EBS** is **network-attached block storage** for EC2. It behaves like a virtual hard drive that survives independently of the instance's lifecycle (subject to the "delete on termination" setting).
- An EBS volume is **bound to a single Availability Zone (AZ)** and can only attach to instances in that same AZ.
- Capacity, **IOPS**, and throughput are **provisioned in advance** and billed accordingly, not pay-as-you-go like S3.
- There are **6 current-generation volume types** across 3 families (General Purpose SSD, Provisioned IOPS SSD, HDD), plus a legacy **Magnetic/Standard** type.
- **Snapshots** are the mechanism to back up a volume and move data across AZs or Regions (detailed in the next section).

### 1. What Is EBS?

- **Elastic Block Store (EBS)**: network-based block storage for EC2 instances. It provides **persistence**, so data survives instance stop/start (and termination, unless configured otherwise).
- It's the AWS equivalent of an external hard drive you can plug into a virtual machine.

### 2. Attachment Rules

| Rule | Detail |
|---|---|
| AZ-bound | A volume in `us-east-1a` can only attach to an instance in `us-east-1a` |
| One instance at a time | The default. Exception: **Multi-Attach** on io1/io2 (see Multi-Attach below) |
| Re-attachable | Detach from one instance, attach to another, similar to swapping a USB drive — used for failover |
| Multiple volumes per instance | One EC2 instance can have several EBS volumes attached |

```
AZ us-east-1a                    AZ us-east-1b
┌─────────────┐                  ┌─────────────┐
│  EC2 (a)     │◄──►[EBS vol]     │  EC2 (b)     │
└─────────────┘                  └─────────────┘
        ✗ [EBS vol] cannot attach directly across AZs
```

### 3. Provisioning and Billing

- Capacity is defined **in advance**: size (GB), and for some types, **IOPS** and throughput.
- Billing is based on what's **provisioned**, not what's actually used.

### 4. Delete on Termination

| Volume | Default behavior |
|---|---|
| Root volume | **Deleted** on instance termination (default), but this attribute can be turned off |
| Additional (non-root) volumes | **Kept** by default |

- Useful pattern: turn off "delete on termination" for the root volume when you want to preserve data or forensically inspect it after termination.

### 5. Exam-Style Recall

| If the question says... | Think... |
|---|---|
| "Volume must move to another AZ" | Take a **snapshot**, then create a new volume from it in the target AZ |
| "Attach the same volume to instance A, then to instance B" | Detach from A, attach to B (or use **Multi-Attach** if io1/io2 and same AZ) |
| "Data should be gone when the instance terminates" | Leave **delete on termination** enabled (default for root volume) |
| "Preserve the root volume after termination" | Disable **delete on termination** on the root volume |
| "Volume in `us-east-1a`, instance in `us-east-1b`" | **Not attachable directly.** Snapshot and recreate in `us-east-1b` |

---

## Elastic Block Store (EBS) Demo

### Steps

1. Open EC2, **Volumes**, create a new volume (size + type, e.g. gp2)
2. Confirm the volume is created in the **same AZ** as the target EC2 instance
3. Attach the volume to the running instance
4. Inspect the instance's **Storage** tab to confirm the new volume is attached
5. Review/toggle the **delete on termination** attribute on the attached volume

---

## EBS Snapshots

### TL;DR

- A **snapshot** is a point-in-time backup of an EBS volume. It can be taken while the volume is attached, though **detaching first gives the most consistent result**.
- Snapshots can be **copied across AZs and across Regions** — this is how EBS data crosses AZ/Region boundaries.
- **EBS Snapshot Archive**: up to ~75% cheaper storage tier, with a **24–72 hour** restore time. Snapshots must stay archived for a **minimum of 90 days** (early deletion is billed for the remaining days).
- **Recycle Bin**: deleted snapshots (including archived ones) can be retained for **1 day to 1 year** before permanent deletion, based on a retention rule. A snapshot recovered from the Recycle Bin's archive tier must still be restored from archive before use.
- **Fast Snapshot Restore (FSR)**: pre-warms a snapshot so **new volumes created from it have full performance immediately**, instead of the default "lazy-load first touch" latency penalty. Costs extra per snapshot, per AZ, per hour.

### 1. What Are EBS Snapshots?

- Point-in-time backups of a volume's data, stored in S3 behind the scenes (not directly browsable).
- Can be created without detaching the volume, but detaching removes any risk of in-flight writes being missed.

### 2. Cross-AZ and Cross-Region

- A snapshot is **not** bound to a single AZ. Copy it to a new AZ, then create a volume from the copy there.
- Copy across Regions for **disaster recovery** or to launch resources closer to users elsewhere.

### 3. Snapshot Archive Tier

| Aspect | Detail |
|---|---|
| Cost savings | Up to ~**75% cheaper** than the standard snapshot tier |
| Restore time | **24–72 hours**, depending on snapshot size |
| Minimum archive duration | **90 days**. Deleting/restoring earlier bills for the remaining days |
| Use case | Long-term compliance/archival copies that are rarely, if ever, restored |

### 4. Recycle Bin for Snapshots

| Aspect | Detail |
|---|---|
| Purpose | Protects against **accidental deletion** of EBS snapshots (and volumes, AMIs) |
| Retention rule | Configurable, **1 day to 1 year** |
| Applies to archived snapshots | **Yes** — an archived snapshot that's deleted still lands in the Recycle Bin per the retention rule |
| To reuse a bin-recovered archived snapshot | Recover it from the bin, **then** restore it from the archive tier to standard |

### 5. Fast Snapshot Restore (FSR)

- Without FSR, the first read to each block of a volume created from a snapshot is slower (lazy loading from S3).
- FSR **pre-warms** the snapshot in a specific AZ so new volumes are at full performance from the first I/O.
- Trade-off: **higher cost**, billed per snapshot, per AZ enabled, per hour.

### 6. Exam-Style Recall

| If the question says... | Think... |
|---|---|
| "Back up an EBS volume" | **Snapshot** |
| "Move data to another AZ/Region" | Copy the **snapshot**, then create a volume from it |
| "Reduce snapshot storage cost, restore time isn't critical" | **EBS Snapshot Archive** |
| "Accidentally deleted a snapshot" | **Recycle Bin** (if a retention rule was configured) |
| "New volume from a snapshot needs full performance immediately" | **Fast Snapshot Restore** |
| "Most consistent snapshot possible" | **Detach** the volume first, then snapshot |

---

## EBS Snapshots Demo

### Steps

1. Select a small gp2 volume, create a **snapshot** with a description
2. Wait for the snapshot to complete
3. Create a **new volume from the snapshot**, choosing encryption and the target AZ
4. Review the **Recycle Bin** settings for deleted-snapshot recovery
5. Review the **Archive** tier option and its longer restore time

---

## Amazon Machine Images (AMIs)

### TL;DR

- An **AMI** is a template that bundles an OS, software, and configuration for launching EC2 instances. It's how you get a pre-configured instance up **faster** than running setup scripts every time.
- AMIs are **Region-scoped**: an AMI built in `us-east-1` can only launch instances directly in `us-east-1`. To use it elsewhere, **copy the AMI** to the target Region first.
- Three sources: **AWS-provided public AMIs**, your own **custom AMIs**, and **AWS Marketplace AMIs** (paid, vendor-maintained).
- Building a custom AMI from a running instance also creates the underlying **EBS snapshot(s)**.

### 1. What Is an AMI?

- Specifies OS, installed software, and configuration for launching one or many EC2 instances with the same baseline.
- Using a custom AMI skips repeating setup steps (e.g. user data scripts) on every launch, which speeds up boot time and standardizes environments.

### 2. AMI Sources

| Type | Description |
|---|---|
| **Public AMIs** | Provided and maintained by AWS (e.g. Amazon Linux 2023) or other publishers |
| **Custom AMIs** | Built and maintained by you, from your own instances |
| **Marketplace AMIs** | Pre-configured, often paid, AMIs from third-party vendors on AWS Marketplace |

### 3. Creating a Custom AMI

1. Launch and configure an EC2 instance (install software, apply config).
2. **Stop the instance** first for the most consistent, data-integrity-safe AMI (not strictly required, but recommended — same trade-off as EBS snapshots).
3. Create the AMI. This **also creates the underlying EBS snapshot(s)** for the instance's volumes.
4. Launch new instances directly from that AMI — they boot with everything already installed.

### 4. AMIs Are Regional

- An AMI in `us-east-1` (N. Virginia) can launch instances **only in `us-east-1`**.
- To launch in another Region, **copy the AMI** to that Region first, then launch from the copy.
- This is the same cross-Region pattern as EBS snapshots (because an AMI is backed by snapshots).

### 5. Exam-Style Recall

| If the question says... | Think... |
|---|---|
| "Speed up repeated instance launches with the same setup" | **Custom AMI** |
| "Launch the same AMI in another Region" | **Copy the AMI** to that Region first |
| "AMI creation also does what to storage?" | Creates the underlying **EBS snapshot(s)** |
| "Most consistent custom AMI" | **Stop** the instance before creating it |
| "Paid, vendor-maintained image" | **AWS Marketplace AMI** |

---

## AMI Hands On

### Steps

1. Launch an EC2 instance: Amazon Linux 2 (use **AL2023** for new work), `t2.micro`, existing security group, with a key pair
2. Add user data to install **HTTPD** (Apache) automatically at first boot
3. Verify the web server responds at the instance's public IP
4. Create an **AMI** from the running instance, with a descriptive name
5. Wait for the AMI to become **available**
6. Launch a **new instance from the AMI** — no user data needed, Apache is already installed

---

## EC2 Instance Store

### TL;DR

- **Instance Store** is NVMe/SSD (or HDD) storage **physically attached to the host hardware**, not network-attached like EBS.
- It's **ephemeral**: data survives a **reboot**, but is **lost on stop, terminate, hibernate, or underlying hardware failure**.
- It delivers **much higher IOPS and lower latency** than EBS, because there's no network hop.
- Included **free** in the instance's hourly cost — no separate billing line.
- Best for data that's disposable or reproducible: **caches, buffers, scratch space, and replicated data in distributed systems**.

### 1. What Is Instance Store?

- High-performance block storage physically attached to the same host running the EC2 instance.
- Common on instance families with a `d` suffix (e.g. `m5d`, `r5d`, `c5d`), and dedicated storage families like **I3, I3en, I4i, D3, D3en**.

### 2. Ephemeral Nature

| Event | Data survives? |
|---|---|
| Reboot (OS or via console) | **Yes** |
| Stop / Stop-Hibernate | **No** |
| Terminate | **No** |
| Underlying hardware failure | **No** |

### 3. Ideal Use Cases

- **Caches and buffers** for an application tier.
- **Scratch data** for temporary processing (e.g. sorting, ETL staging).
- **Replicated data in distributed systems** (e.g. a distributed database or cache cluster) — if one node's instance store is lost, the data is still available from the other replicas.

### 4. Performance Comparison

- Instance Store typically delivers **significantly higher IOPS and lower latency** than EBS, because it skips the network path entirely.
- Example from the high-end I-family: RAID 0 across multiple local NVMe drives can push **millions of IOPS** and **double-digit GB/s** of sequential throughput — far beyond what a single EBS volume provides.
- This is also why the "310,000 IOPS" exam scenario (see EBS volume types) allows Instance Store as an alternative to EBS RAID 0, **if** the ephemeral trade-off is acceptable.

### 5. Risks and Data Management

- Main risk: **permanent data loss** on stop/terminate/hibernate or a hardware fault.
- Mitigate by **backing up or replicating** anything that must survive — to EBS, S3, or across multiple instances.

### 6. Exam-Style Recall

| If the question says... | Think... |
|---|---|
| "Highest possible IOPS, lowest latency, data can be lost" | **Instance Store** |
| "Temporary cache or scratch space" | **Instance Store** |
| "Data must survive instance stop/terminate" | **EBS** (or S3/EFS), not Instance Store |
| "Distributed DB with its own replication, one node's disk fails" | **Instance Store** is fine — other replicas still have the data |
| "No extra charge for the storage" | **Instance Store** (bundled into instance price) |

---

## Amazon Elastic Block Store (EBS) Volumes — Types in Depth

### TL;DR

- **6 current-generation types**: **gp2, gp3** (General Purpose SSD), **io1, io2** (Provisioned IOPS SSD), **st1, sc1** (HDD) — plus the legacy **Magnetic (Standard)** type.
- **gp3** decouples IOPS/throughput from size, with a baseline of **3,000 IOPS / 125 MiB/s free**, scalable up to **80,000 IOPS / 2,000 MiB/s** (AWS raised this ceiling in September 2025 — this course's slides may still show the older 16,000 IOPS / 1,000 MB/s limit).
- **io2 Block Express** is the top tier for IOPS: up to **256,000 IOPS**, **4,000 MB/s**, sub-millisecond latency, and **99.999% durability**.
- **st1/sc1 cannot be boot volumes.** Everything else can.
- To exceed a single volume's IOPS ceiling, **stripe multiple volumes in RAID 0**.

### 1. Volume Type Specifications (2026)

| Type | Category | Max IOPS | Max throughput | Max size | Boot volume? | Notes |
|---|---|---|---|---|---|---|
| **gp2** | General Purpose SSD | 16,000 (3 IOPS/GB baseline, burst to 3,000 for volumes < 1 TiB) | 250 MiB/s | 16 TiB | Yes | Previous generation; IOPS scale with size |
| **gp3** | General Purpose SSD | 80,000 (3,000 baseline, free) | 2,000 MiB/s (125 MiB/s baseline, free) | 64 TiB | Yes | IOPS/throughput **independent of size**; current default |
| **io1** | Provisioned IOPS SSD | 64,000 (Nitro instances) | 1,000 MiB/s | 16 TiB | Yes | Up to 50 IOPS/GB |
| **io2 (Block Express)** | Provisioned IOPS SSD | 256,000 | 4,000 MiB/s | 64 TiB | Yes | Up to 1,000 IOPS/GB; **99.999% durability**; sub-ms latency |
| **st1** | Throughput Optimized HDD | 500 | 500 MiB/s (baseline 40 MiB/s per TiB, burst 250 MiB/s per TiB) | 16 TiB | **No** | Big data, log processing, data warehouses |
| **sc1** | Cold HDD | 250 | 250 MiB/s | 16 TiB | **No** | Lowest cost, infrequent access |
| **Magnetic (Standard)** | Previous generation | ~40–200 | ~40–90 MiB/s | 1 TiB | Yes | Legacy; avoid for new workloads |

### 2. Boot Volume Eligibility

| Type | Can be a boot volume? |
|---|---|
| gp2 / gp3 | Yes — common default |
| io1 / io2 | Yes — when high IOPS is needed from boot |
| Magnetic (Standard) | Yes — legacy only |
| st1 / sc1 | **No** |

### 3. Increasing Performance Beyond a Single Volume

- **RAID 0**: stripe multiple EBS volumes into one logical volume to combine their IOPS and throughput. No redundancy — losing one volume loses the whole array.
- **gp2 exam gotcha**: an **8 TiB gp2 volume already sits at the 16,000 IOPS ceiling**. Making it *larger* doesn't raise IOPS further — gp2 performance scales with size only up to that cap.
- **310,000 IOPS exam scenario**: no single EBS volume can deliver that alone. The answer is **RAID 0 across multiple io1/io2 volumes** (or accept the ephemeral trade-off and use **Instance Store**, see previous section).

### 4. Exam-Style Recall

| If the question says... | Think... |
|---|---|
| "Cost-effective SSD for most workloads, decoupled IOPS/throughput" | **gp3** |
| "Mission-critical DB, sub-ms latency, extreme IOPS" | **io2 Block Express** |
| "Big data / log processing, sequential throughput" | **st1** |
| "Rarely accessed data, lowest cost HDD" | **sc1** |
| "Volume can't be used as a boot volume" | **st1 or sc1** |
| "Increase IOPS beyond one volume's max" | **RAID 0** across multiple volumes |
| "8 TiB gp2, want more IOPS by resizing" | Won't work — **already at the 16,000 IOPS cap** |
| "Need 300,000+ IOPS" | **RAID 0 of io1/io2** volumes (or accept ephemeral data and use **Instance Store**) |

---

## Multi-Attach Feature of Amazon EBS Volumes

### TL;DR

- **Multi-Attach** lets a single **io1 or io2** volume attach to **up to 16 Nitro-based EC2 instances**, all in the **same AZ**.
- Every attached instance gets **full read/write** access — the application layer must coordinate concurrent writes with a **cluster-aware file system**, since EBS itself doesn't do that.
- Cannot span AZs, cannot be used as a **root/boot volume**, and requires **Nitro** instances.

### 1. Overview

- Supported **only** on io1 and io2 volumes.
- All attached instances must be **within the same AZ** as the volume.

### 2. Key Points

| Aspect | Detail |
|---|---|
| Max instances | **16**, all built on the **Nitro System** |
| Concurrent access | Every attached instance has **full read and write** access simultaneously |
| OS support | **Linux**: io1 and io2. **Windows**: io2 only |
| Regional availability | io1 Multi-Attach: limited Regions (e.g. us-east-1, us-west-2, ap-northeast-2). io2 Multi-Attach: **all Regions that support io2** |
| Root/boot volume | **Not allowed** |
| Data consistency | **io2** supports **I/O fencing** for consistency; **io1** does not |
| File system requirement | A **cluster-aware file system** is required — standard file systems like XFS/EXT4 aren't safe for concurrent multi-writer access |

### 3. Use Cases

- Clustered applications that manage their own concurrent-write coordination (e.g. Teradata-style clustered databases).
- Raising availability for a shared storage layer without going through a network file system like EFS.

### 4. Exam-Style Recall

| If the question says... | Think... |
|---|---|
| "One EBS volume, multiple EC2 instances, same AZ, concurrent read/write" | **EBS Multi-Attach** (io1/io2 only) |
| "Multi-Attach across AZs" | **Not possible** — same AZ only |
| "Multi-Attach as the root volume" | **Not allowed** |
| "Prevent write conflicts across attached instances" | Requires a **cluster-aware file system**; EBS doesn't arbitrate this |
| "Which volume type gives I/O fencing on Multi-Attach?" | **io2** |
| "Need shared file access across AZs" | Not Multi-Attach — use **EFS** instead |

---

## Amazon Elastic File System (EFS)

### TL;DR

- **EFS** is a **managed, elastic NFS (v4.1) file system** that many EC2 instances can mount **concurrently, across multiple AZs**.
- **Linux-only.** No pre-provisioning of capacity — it grows and shrinks automatically.
- Three **throughput modes**: **Bursting** (free, scales with storage size), **Provisioned** (fixed, paid), **Elastic** (auto-scales with load, pay-per-use — best for unpredictable/spiky traffic).
- Two **performance modes**: **General Purpose** (default, recommended for nearly everything) and legacy **Max I/O** (higher latency, not available with Elastic throughput or One Zone).
- **Storage classes + lifecycle management** move infrequently accessed files to cheaper tiers automatically, for substantial cost savings.
- Roughly **3x the per-GB cost of gp2 EBS** for the Standard storage class — the lifecycle/IA classes exist to bring that down.

### 1. What Is EFS?

- A network file system (NFS), not block storage — files are shared, not a single volume attached to one instance.
- Scales to **thousands of concurrent NFS clients**, up to petabyte-scale, without any capacity planning.

### 2. Performance Modes

| Mode | Use case | Notes |
|---|---|---|
| **General Purpose** | Default, recommended for **almost all workloads** (web serving, CMS, general apps) | Scales to hundreds of thousands of IOPS; lower per-operation latency |
| **Max I/O** | Legacy, for highly parallelized workloads tolerant of higher latency | **Not supported** with One Zone file systems or **Elastic** throughput; largely superseded by General Purpose's scaling improvements |

### 3. Throughput Modes

| Mode | Cost model | Best for |
|---|---|---|
| **Bursting** | Free (bundled into storage cost), throughput scales with **file system size**, uses burst credits for spikes | Dev/test, light or intermittent production traffic |
| **Provisioned** | Fixed extra cost for a **guaranteed** throughput level | Predictable, sustained throughput needs (steady CI/CD, batch jobs) |
| **Elastic** | Pay-per-use, **auto-scales up and down** with actual workload | Spiky or hard-to-forecast traffic — the closest to a "just works" default |

### 4. Storage Classes and Lifecycle Management

| Class | Description |
|---|---|
| **Standard** | Multi-AZ, highest cost per GB |
| **Standard-IA** (Infrequent Access) | Multi-AZ, cheaper, for files not accessed often |
| **One Zone** | Single-AZ, lower cost, no multi-AZ redundancy — good for dev/non-critical workloads |
| **One Zone-IA** | Single-AZ + infrequent access, cheapest option |

- **Lifecycle management** automatically moves files between Standard and IA tiers based on last-access time, without manual intervention.

### 5. Availability and Durability

| File system type | AZ footprint | Typical use |
|---|---|---|
| **Regional (Standard)** | Multiple AZs | Production, shared applications |
| **One Zone** | Single AZ | Development, staging, cost-sensitive non-critical workloads |

### 6. Security

- Access is controlled by **security groups** attached to the EFS mount targets — they must allow **NFS (port 2049)** from the connecting instances.

### 7. Exam-Style Recall

| If the question says... | Think... |
|---|---|
| "Shared file storage across many EC2 instances, multiple AZs, Linux" | **EFS** |
| "Unpredictable, spiky throughput needs" | **Elastic** throughput mode |
| "Guaranteed throughput regardless of storage size" | **Provisioned** throughput mode |
| "Lowest-cost dev/test file system" | **EFS One Zone** (or One Zone-IA) |
| "Automatically tier cold files to save cost" | **EFS lifecycle management** to **IA** |
| "Highly parallel workload needing Max I/O" | Possible, but check it's **not** paired with One Zone or Elastic throughput |
| "Windows instances need shared file storage" | **Not EFS** (Linux-only) — consider **FSx for Windows File Server** |

---

## Hands-On Demonstration of Amazon Elastic File System (EFS)

### Steps

1. Create a file system, choosing the **VPC** (default VPC)
2. Choose **Regional** (multi-AZ, production) or **One-Zone** (single-AZ, dev)
3. Enable automatic **backups**
4. Configure **lifecycle management** to move cold files to a cheaper tier
5. Choose **throughput mode** (Bursting / Provisioned / Elastic)
6. Choose **performance mode** (General Purpose / Max I/O)
7. Configure network access and a **security group** allowing NFS
8. Launch multiple EC2 instances and mount the **same EFS file system** on each
9. Confirm concurrent access from instances in **different AZs**

### Key Use Cases Demonstrated

- **Content management**: shared files for websites/applications.
- **Web serving**: files accessed concurrently by multiple app servers.
- **Data sharing**: multiple applications on different EC2 instances reading/writing the same data.

---

## Comparison of Amazon EBS, EFS, and Instance Store

### 1. Side-by-Side

| Aspect | EBS | EFS | Instance Store |
|---|---|---|---|
| Storage type | Block | File (NFS) | Block (local) |
| AZ scope | Single AZ | **Multi-AZ** | Single host |
| Attachable to | 1 instance (16 with Multi-Attach, io1/io2) | **Many instances concurrently** | The one host it's physically on |
| Persistence | Survives stop/terminate (config-dependent) | Survives, independent of any instance | **Lost** on stop/terminate/hibernate |
| Performance | Good, network-attached | Good, scales with demand | **Highest** (no network hop) |
| OS support | Linux + Windows | **Linux only** | Linux + Windows |
| Typical cost | Baseline | ~3x gp2 for Standard class (IA/One Zone reduce this) | **Included** in instance price |
| Best for | Single-instance boot/data volumes, databases | Shared file storage across a fleet | Caches, scratch space, replicated cluster data |

### 2. Migration and Cross-AZ Notes

- **EBS**: crossing AZs requires a **snapshot**, then creating a new volume from it — this can add latency/impact during high traffic.
- **EFS**: natively spans AZs via **mount targets** in each AZ — no snapshot dance needed.
- **Instance Store**: never crosses hosts — data must be replicated at the application layer if it needs to survive a host loss.

### 3. Exam-Style Recall

| If the question says... | Think... |
|---|---|
| "One instance, persistent block storage" | **EBS** |
| "Many instances, shared files, multi-AZ" | **EFS** |
| "Fastest possible local storage, data is disposable" | **Instance Store** |
| "Move block data between AZs" | **EBS snapshot** and recreate |
| "Database needing extreme IOPS with data persistence" | **EBS (io2 Block Express)**, not Instance Store |
