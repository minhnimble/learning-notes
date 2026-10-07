# EC2 Fundamentals

---

## AWS Budget Setup

### TL;DR

- Set a budget **before** launching resources so unexpected spend triggers an email instead of a surprise bill.
- **AWS Budgets** offers templates such as **Zero spend budget** (alerts as soon as spend exceeds Free Tier limits) and **Monthly cost budget** (alerts at thresholds such as 85% and 100%).
- Billing pages are hidden from IAM users by default. The **root user** must enable **IAM user and role access to Billing information** first.
- Free Tier usage is tracked separately in the **Billing and Cost Management** console.

### 1. Why Monitor Expenses

- Prevents overspending and surfaces forgotten resources (running instances, volumes, load balancers).
- Cost data lags real usage by several hours, so alerts are a safety net, not real-time control.

### 2. Accessing the Billing Console

- Open **Billing and Cost Management**.
- If an IAM user can't see billing data, sign in as the **root user** and activate IAM access to billing information (Account settings).

### 3. What the Console Shows

| View | What it tells you |
|---|---|
| Month-to-date cost | Spend so far this month |
| Forecasted cost | Projected end-of-month spend |
| Last month's cost | Baseline for comparison |
| Cost by service | Breakdown, for example how much is EC2 (Elastic Compute Cloud) |
| **Free Tier** page | Usage against Free Tier limits per service |

### 4. Creating a Budget

1. Billing and Cost Management, **Budgets**, **Create budget**.
2. Pick a template (for example **Zero spend budget**) or a custom cost budget.
3. Add **email recipients** and alert thresholds (for example **85%** and **100%** of actual spend).

| Budget template | Alerts when |
|---|---|
| **Zero spend budget** | Spend exceeds Free Tier limits (effectively above $0.01) |
| **Monthly cost budget** | Actual or forecasted spend crosses a threshold you set |
| **Daily Savings Plans coverage** | Coverage drops below a target |

- Monitoring cost, usage, RI, and Savings Plans budgets is **free**. Budgets that trigger **actions** include a free allowance of **62 action-enabled budget-days** per month (for example 2 budgets for 31 days), then **$0.10** per action-enabled budget-day.

### 5. Free Tier (2026)

| Account created | Free Tier model |
|---|---|
| **Before 2025-07-15** | Legacy: **12 months** of service-specific allowances, for example **750 hours/month** of a `t2.micro` (or `t3.micro` where `t2.micro` isn't offered) and **30 GB** of EBS |
| **On or after 2025-07-15** | Credits: **$100** at signup plus up to **$100** more from onboarding activities, usable for **6 months** or until the credits run out |

- The lecture describes the legacy 750-hour/30 GB offer. Check your account's Free Tier page to see which model applies.
- The 750 hours cover **one** `t2.micro` running 24/7 (about 730 hours in a month), or several instances sharing the total.

### 6. Exam-Style Recall

| If the question says... | Think... |
|---|---|
| "Get notified when spend exceeds a threshold" | **AWS Budgets** alert |
| "Alert as soon as anything leaves the Free Tier" | **Zero spend budget** |
| "IAM user can't see the Billing console" | Root user enables **IAM access to Billing information** |
| "Break down cost by service or tag" | **Cost Explorer** |

---

## Amazon EC2 Basics

### TL;DR

- **EC2 (Elastic Compute Cloud)** rents resizable virtual machines (**instances**) by the second, with a choice of OS, CPU, RAM, storage, and networking.
- EC2 is a bundle of related pieces: **instances**, **EBS volumes**, **security groups**, **Elastic Load Balancers**, and **Auto Scaling Groups**.
- **User data** is a bootstrap script that runs **once, at first launch, as root**. Use it to install software and configure the instance.
- **Security groups** are stateful, allow-only firewalls attached to instances.

### 1. What Is EC2?

- Infrastructure as a Service (IaaS): virtual machines in the cloud, no physical hardware to buy.
- Related services in the same "compute" family:

| Component | Role |
|---|---|
| **Instances** | Virtual machines |
| **EBS volumes** | Persistent block storage attached to instances (see #6) |
| **Elastic Load Balancer (ELB)** | Spreads traffic across instances (see #7) |
| **Auto Scaling Group (ASG)** | Adds or removes instances based on demand (see #7) |
| **Security groups** | Instance-level firewall |

### 2. Instance Configuration Choices

- **OS**: Linux, Windows, or macOS.
- **Compute**: CPU (vCPU count), RAM, network performance.
- **Storage**: network-attached (**EBS**, **EFS**) or hardware-attached (**instance store**).
- **Firewall**: security groups.
- **Bootstrap**: **EC2 user data**.

### 3. User Data

| Property | Detail |
|---|---|
| When it runs | **Once**, at the instance's **first boot** (not on every reboot by default) |
| Runs as | **root**, so no `sudo` needed |
| Purpose | Install updates and software, download files, start services |
| Size limit | **16 KB** |
| Cost of a long script | Delays the instance becoming ready |

Sample user data (installs a web server and a test page):

```bash
#!/bin/bash
yum update -y
yum install httpd -y
echo "<h1>Hello World</h1>" > /var/www/html/index.html
service httpd start
```

- The script matches **Amazon Linux 2**. On **Amazon Linux 2023** use `dnf` (`yum` still works through a symlink) and `systemctl start httpd`.
- The instance is **not** automatically ready when it shows *running*: user data can still be executing.

### 4. Networking Basics

- Instances get a **private IPv4** address (stable) and, in a public subnet, a **public IPv4** address (changes on stop/start).
- **Security groups** control inbound and outbound traffic (detailed later in this section).

### 5. Exam-Style Recall

| If the question says... | Think... |
|---|---|
| "Run a script only at first boot" | **EC2 user data** |
| "User data runs as which user?" | **root** |
| "Bootstrap script needs to run on every boot" | Cloud-init config (`scripts-user` per boot), not default user data |
| "Change an instance's CPU/RAM" | Stop, change **instance type**, start (vertical scaling) |
| "Public IP changed after restart" | Normal. Use an **Elastic IP** for a fixed address |
| "Stopped instance still costs money" | Its **EBS volumes** (and any Elastic IP) keep billing |
| "Automatically recover a failed instance" | **CloudWatch alarm** with a recover/reboot/terminate action |

---

## EC2 Instance Launch Hands On

### 1. Launch Parameters

| Parameter | Value used | Notes |
|---|---|---|
| Name and tags | "My First Instance" | Tags help with cost allocation and filtering |
| AMI | Amazon Linux 2 | Use **AL2023** for new work |
| Instance type | `t2.micro` | Free-Tier-eligible where available. Use `t3.micro` where `t2.micro` isn't offered. |
| Key pair | Created for SSH | Downloaded once as a `.pem` file |
| Security group | New group allowing SSH/HTTP | See the security group sections |
| User data | httpd install script | See "Amazon EC2 Basics, section 3" |

### 2. Instance Lifecycle

| State | Billing | Notes |
|---|---|---|
| `pending` | No | Starting up |
| `running` | **Yes** | Per-second billing for Linux/Windows (60-second minimum) |
| `stopping` / `stopped` | Compute **no**, EBS **yes** | Public IPv4 released and reassigned on next start |
| `shutting-down` / `terminated` | No | Terminated instances can't be restarted |

- A **CloudWatch alarm** can be attached to stop, terminate, reboot, or recover an instance automatically.
- The **private IP stays** across stop/start. The **public IPv4 changes**. Use an **Elastic IP** for a stable public address.

---

## EC2 Instance Types Basics

### TL;DR

- Instance types are grouped into **families** by workload: general purpose, compute optimized, memory optimized, storage optimized, accelerated computing, and HPC optimized.
- Names follow `family + generation + attributes . size`, for example **`m5.2xlarge`** = general purpose, generation 5, **8 vCPU / 32 GiB**.
- Attribute letters describe the processor and features, for example `g` = **Graviton (Arm)**, `a` = **AMD**, `d` = **local NVMe instance store**, `n` = **network optimized**.
- Details and prices: [AWS EC2 Instance Types](https://aws.amazon.com/ec2/instance-types/) and [ec2instances.info](https://ec2instances.info).

### 1. Instance Families

| Family | Prefix (examples) | Optimized for | Typical use cases |
|---|---|---|---|
| **General Purpose** | `t`, `m` | Balanced CPU, memory, network | Web servers, small databases, dev/test. Example: `t2.micro` for low-traffic sites |
| **Compute Optimized** | `c` | CPU-bound work | Media transcoding, batch processing, high-performance web servers, gaming servers, scientific modeling |
| **Memory Optimized** | `r`, `x`, `z` | Large in-memory datasets | In-memory databases and caches, real-time big data analytics, large relational databases |
| **Storage Optimized** | `i`, `d`, `h` | High local disk throughput and IOPS | NoSQL databases, data warehousing, Elasticsearch |
| **Accelerated Computing** | `p`, `g`, `trn`, `inf` | GPUs or custom accelerators | Machine learning training/inference, graphics rendering |
| **HPC Optimized** | `hpc` | Tightly coupled, low-latency compute | Scientific simulation, financial modeling, parallel processing |

- The lecture's examples (`T2`, `C5`, `R5`, `I3`, `P3`) are older generations. Current generations are **8th gen** (for example `M8g`, `C8g`, `R8g` on **Graviton4**, `M8a` on AMD EPYC, `M8id` on Intel Xeon 6 with local NVMe). Newer generations generally give better price-performance.

### 2. Naming Convention

```
m 5 g d . 2xlarge
│ │ │ │   └── size
│ │ └─┴────── attributes (g = Graviton, d = local NVMe)
│ └────────── generation
└──────────── family
```

| Part | Meaning |
|---|---|
| **m** | Instance family (general purpose) |
| **5** | Generation. Newer generations are typically faster and cheaper per unit of work |
| **2xlarge** | Size within the family. `m5.2xlarge` has **8 vCPUs and 32 GiB** of memory |

| Attribute letter | Meaning |
|---|---|
| `g` | AWS **Graviton** (Arm) processor |
| `a` | **AMD** processor |
| `i` | **Intel** processor |
| `d` | **Local NVMe** instance store |
| `n` | Enhanced **networking** |
| `e` | Extra storage or memory |

- Within a family, each size step up typically doubles vCPU and memory (`large`, `xlarge`, `2xlarge`, `4xlarge`, and so on).
- **Burstable** `t` instances earn **CPU credits** at idle and spend them under load. Cheap for spiky, low-average-CPU workloads.

### 3. Cost Considerations

- Price depends on type, Region, OS, and **purchasing option** (see the last section).
- Example from the lecture: an `m4.large` in `us-east-1` was about **$0.10/hour On-Demand**, with Spot up to ~61% cheaper. `m4` is an old generation, so treat the numbers as an illustration.

### 4. Exam-Style Recall

| If the question says... | Think... |
|---|---|
| "Video encoding, batch processing, CPU-bound" | **Compute optimized** (`c`) |
| "In-memory database or cache, large datasets in RAM" | **Memory optimized** (`r`, `x`) |
| "High IOPS local disk, NoSQL, data warehouse" | **Storage optimized** (`i`, `d`) |
| "Machine learning training/inference, GPUs" | **Accelerated computing** (`p`, `g`) |
| "Balanced default, dev/test, small web app" | **General purpose** (`t`, `m`) |
| "`m5.2xlarge` means?" | General purpose, generation 5, size 2xlarge (8 vCPU, 32 GiB) |

---

## Security Groups and Classic Ports

### TL;DR

- A **security group (SG)** is a **virtual, stateful firewall** attached to an instance's network interface. It only has **allow** rules.
- **Default behavior:** all **inbound is blocked**, all **outbound is allowed**.
- Rules are made of **type/protocol**, **port range**, and **source** (an IP range, another security group, or a prefix list).
- SGs are scoped to a **Region and VPC**. One SG can attach to many instances, and one instance can have many SGs.
- Classic ports to know: **22** SSH, **21** FTP, **80** HTTP, **443** HTTPS, **3389** RDP.

### 1. What a Security Group Does

- Controls **inbound** and **outbound** traffic for the instance.
- Lives **outside** the instance. Blocked traffic never reaches the OS, and changes apply **immediately** with no restart.
- **Stateful:** if an inbound request is allowed, the response is allowed back automatically (and vice versa).
- **Allow-only:** there are no deny rules. Anything not explicitly allowed is blocked.
- All rules are evaluated together (no rule order or priority).

### 2. Rule Structure

| Field | Example | Notes |
|---|---|---|
| Type / Protocol | SSH, HTTP, TCP, UDP | Protocol and port are usually implied by the type |
| Port range | `22`, `80`, `443` | A single port or a range |
| Source (inbound) / Destination (outbound) | `203.0.113.5/32`, `0.0.0.0/0`, `sg-0abc...` | CIDR, another **security group**, or a **prefix list** |

- `/32` means a single IP address. `0.0.0.0/0` means **anywhere** (all IPv4). `::/0` means anywhere on IPv6.

| Default | Inbound | Outbound |
|---|---|---|
| **New security group** | Nothing allowed | **All traffic allowed** |

### 3. Attachment and Scope

| Question | Answer |
|---|---|
| One SG on many instances? | **Yes** |
| Many SGs on one instance? | **Yes** (rules are combined, a union of allows) |
| Scope | Locked to a **Region and VPC**. Create a new SG when switching Region or VPC |
| Where is a SG attached? | To the instance's **network interface (ENI)** |

### 4. Classic Ports

| Port | Protocol | Used for |
|---|---|---|
| **22** | SSH | Secure login to **Linux** instances (also SFTP) |
| **21** | FTP | Uploading files to a file share |
| **80** | HTTP | Unsecured web sites |
| **443** | HTTPS | Secured web sites |
| **3389** | RDP | Remote Desktop into **Windows** instances |
| **3306** | MySQL | Database example used in the lecture |

### 5. Advanced Features

| Feature | Detail |
|---|---|
| **Referencing another SG** | Use a SG as the **source**: "allow anything that has SG-X attached". Doesn't depend on IPs, so it survives scaling and IP changes. Example: a database SG allows **3306 from the web-server SG only**. |
| **Multiple SGs per instance** | Modular rules, for example one SG for HTTP and another for SSH |
| **Cross-instance trust** | Instances sharing an SG reference can talk without knowing each other's IPs |

```
Users --80/443--> [Web SG: inbound 80/443 from 0.0.0.0/0]
                          |
                          v
      [DB SG: inbound 3306, SOURCE = Web SG]
```

- **IAM roles are not security groups.** Roles give an instance temporary credentials for AWS API calls (see the IAM roles section). SGs control network traffic.

### 6. Good to Know

- Grant access from services like **RDS** or **ElastiCache** by referencing SGs (for example allow the app's SG on the database port).
- Check **Regional services availability** before planning, since not every service exists in every Region.
- For subnet-level filtering with **allow and deny** rules, use **Network ACLs** (covered in the VPC section).

### 7. Exam-Style Recall

| If the question says... | Think... |
|---|---|
| "Connection times out" | **Security group** (or other firewall) blocking |
| "Connection refused" | SG passed, but **nothing is listening** on that port |
| "Only web servers may reach the database" | DB SG inbound rule with **source = web SG** |
| "Allow SSH from my IP only" | Port **22**, source **my IP `/32`** |
| "Block a specific IP address" | SGs can't deny. Use a **Network ACL** |
| "Default outbound behavior of a new SG" | **All allowed** |
| "Windows remote access port" | **3389** (RDP) |
| "Web page times out after launch" | Inbound **HTTP/HTTPS rule missing** on the SG |
| "Instance can't reach the internet" | Check **outbound** rules (and the route table) |
| "SG change needs an instance restart" | **No.** Changes apply immediately |
| "Two SGs on one instance conflict" | They don't conflict. Rules are a **union** of allows |

---

## Security Groups Hands On

### 1. Where to Find Security Groups

- EC2 console, **Network and Security**, **Security Groups**. Each group has a unique **ID** (`sg-...`).
- An instance's **Security** tab shows the groups attached to it.

### 2. Demo

- Removing the **HTTP 80** inbound rule made the page **time out**. Adding it back fixed it without a restart.
- With **port 22** closed, an SSH attempt **times out**.
- Outbound is open by default. It can be restricted, for example to **HTTPS 443** only, to reduce data exfiltration risk.
- A second SG attached to the same instance combined with the first (rules are a union).

---

## Connecting to Linux Servers via SSH

### TL;DR

- Four ways to reach a Linux instance: **SSH from a terminal** (Mac/Linux/Windows 10+), **PuTTY** (older Windows), **EC2 Instance Connect** (browser), and **Session Manager** (no open port).
- SSH needs **port 22 open** in the SG and a **key pair**. EC2 Instance Connect also needs port 22 but skips key handling.
- Default username on **Amazon Linux** is **`ec2-user`**.

### 1. Options by Operating System

| Client | Method |
|---|---|
| **Mac / Linux** | `ssh` in the terminal |
| **Windows 10 and later** | Built-in OpenSSH (`ssh` in PowerShell/CMD) |
| **Older Windows** | **PuTTY** (convert the `.pem` to `.ppk` with PuTTYgen) |
| **Any OS, browser only** | **EC2 Instance Connect** |
| **Any OS, no inbound port** | **AWS Systems Manager Session Manager** |

- The Windows-specific lectures were skipped in these notes.

### 2. EC2 Instance Connect

- Browser-based SSH from the EC2 console, on **every OS**, with no command-line setup.
- AWS pushes a **temporary key** to the instance, so there's no key file to manage.
- Uses `ec2-user` as the default user on Amazon Linux.
- **EC2 Instance Connect Endpoint** lets you connect to instances that have **no public IPv4 address**.

### 3. Exam-Style Recall

| If the question says... | Think... |
|---|---|
| "SSH without managing key files" | **EC2 Instance Connect** |
| "SSH to an instance with no public IP" | **EC2 Instance Connect Endpoint** (or Session Manager) |
| "Remote access with no inbound port open" | **Session Manager** |
| "Default user on Amazon Linux" | **`ec2-user`** |

---

## Using SSH to Connect to an EC2 Instance on Linux/Mac

### 1. Prerequisites

- The instance has a **public IPv4 address**.
- The SG allows **inbound TCP 22** from your IP.
- The **`.pem` file** from key pair creation (no spaces in the file name, for example `EC2Tutorial.pem`).

### 2. Steps

1. Copy the **Public IPv4 address** from the instance's overview page.
2. Change into the directory that holds the `.pem` file (`cd`, `ls`).
3. Fix permissions if SSH reports `UNPROTECTED PRIVATE KEY FILE` / `Permissions 0644 ... are too open`:

   ```bash
   chmod 0400 EC2Tutorial.pem
   ```

4. Connect:

   ```bash
   ssh -i EC2Tutorial.pem ec2-user@<public-ip>
   ```

5. Verify with `whoami` (prints `ec2-user`) and `ping google.com`.
6. Leave the session with `exit` (or Ctrl+D).

- Running `ssh ec2-user@<public-ip>` **without `-i`** fails with an authentication error, because no key is offered.
- On stop/start the **public IP changes**, so update the command.

---

## SSH Troubleshooting

### TL;DR

- **Timeout** = network block (security group or firewall). **Connection refused** = host reached, SSH not running. **Permission denied** = wrong key or user.
- If nothing works, fall back to **EC2 Instance Connect** on an **Amazon Linux** instance.
- "Worked yesterday, not today" usually means the **public IP changed** after a stop/start.

### 1. Symptom Table

| Symptom | Likely cause | Fix |
|---|---|---|
| **Connection timeout** | Security group or firewall blocks port 22 | Ensure the SG allows SSH (port 22) from your IP and is attached to the instance |
| **Timeout persists** with a correct SG | A corporate or personal **firewall** blocks outbound SSH | Use **EC2 Instance Connect** |
| `ssh: command not found` (Windows) | No OpenSSH client | Use **PuTTY**, or **EC2 Instance Connect** if PuTTY fails |
| **Connection refused** | Instance is reachable, but the SSH service isn't running | Restart the instance. If it persists, recreate it from an **Amazon Linux** AMI |
| **Permission denied** | Wrong key, wrong username | Check the assigned key pair. For Amazon Linux use `ssh ec2-user@<public-ip>` |
| Worked yesterday, not today | **Public IPv4 changed** after stop/start | Update the SSH command or PuTTY config with the new IP (or use an Elastic IP) |
| Nothing works | Multiple issues | **EC2 Instance Connect** on an Amazon Linux instance |

### 2. Exam-Style Recall

| If the question says... | Think... |
|---|---|
| "SSH times out" | **Security group** (or firewall) issue |
| "SSH connection refused" | **SSH daemon** not running or wrong port |
| "Permission denied (publickey)" | Wrong **key pair** or **username** |
| "SSH worked before a stop/start, now times out" | New **public IP**. Use an **Elastic IP** |

---

## Using EC2 Instance Connect to Connect to EC2 Instances

### 1. How It Works

1. In the console, choose the instance and click **Connect**.
2. On the EC2 Instance Connect tab, keep the default username (`ec2-user`) or change it.
3. AWS pushes a **one-time public key** to the instance, and a browser terminal opens.

| Aspect | Detail |
|---|---|
| Key management | None. The key is temporary |
| Network requirement | Inbound **TCP 22** from the EC2 Instance Connect service range (or use an **Instance Connect Endpoint** for private instances) |
| Agent | Preinstalled on Amazon Linux 2023 and Amazon Linux 2, and on recent Ubuntu |
| Permissions | IAM policy allowing `ec2-instance-connect:SendSSHPublicKey` |

### 2. Exam-Style Recall

| If the question says... | Think... |
|---|---|
| "Instance Connect fails to connect" | SG missing **inbound 22** |

---

## IAM Roles for EC2 Instances Demo

### 1. Why Not Store Credentials on the Instance

- Long-lived keys on a server can leak through the file system, logs, or an AMI/snapshot copy.
- Roles remove the need to store secrets, and permissions can be changed centrally.

### 2. How Roles Work

| Piece | Detail |
|---|---|
| **IAM role** | Set of permissions plus a **trust policy** allowing EC2 to assume it |
| **Instance profile** | The container that attaches a role to an instance (the console creates it automatically) |
| **Credentials** | Temporary, delivered via the **instance metadata service (IMDS)**, rotated automatically |
| **CLI / SDK** | Picks up the role credentials automatically through the default credential chain |

- **IMDSv2** (session-token based) is the default and required on Amazon Linux 2023. IMDSv1 is discouraged.

### 3. Demo Steps

1. Connect with EC2 Instance Connect.
2. Run `aws iam list-users` and see it fail: **no credentials**.
3. Create an IAM role for the **EC2** service with **IAM read-only** access (`demoRoleForEC2`).
4. On the instance: **Actions, Security, Modify IAM role**, then attach `demoRoleForEC2`.
5. Run `aws iam list-users` again and see the users listed.

- A role attached to a **running** instance takes effect within a short time. No restart is needed.
- The role can be swapped or detached later.

### 4. Exam-Style Recall

| If the question says... | Think... |
|---|---|
| "EC2 app needs to call S3/DynamoDB securely" | **IAM role** on the instance |
| "Where do the role's credentials come from?" | **Instance metadata service** (temporary, auto-rotated) |
| "Access keys stored on the instance" | Wrong answer. Use a **role** |
| "What attaches a role to an EC2 instance?" | An **instance profile** |
| "Which metadata version is more secure?" | **IMDSv2** (session-oriented, token required) |

---

## Purchasing Options for EC2 Instances

### TL;DR

- **On-Demand**: pay per second, no commitment, highest price. Best for short, unpredictable workloads.
- **Reserved Instances (RI)**: 1 or 3 year commitment, up to **72%** off. **Convertible RIs** allow changing instance attributes for a smaller discount.
- **Savings Plans**: commit to **$/hour** for 1 or 3 years. **EC2 Instance Savings Plans** (up to **72%**) are tied to a family and Region, and **Compute Savings Plans** (up to **66%**) apply across families, Regions, and even Fargate and Lambda.
- **Spot Instances**: up to **90%** off, but AWS can **reclaim them with a 2-minute warning**. Best for fault-tolerant, flexible, stateless work.
- **Dedicated Hosts**: a **whole physical server** you control, for compliance and **BYOL** licensing. **Dedicated Instances**: dedicated hardware, but no host visibility.
- **Capacity Reservations**: reserve capacity in a specific AZ for any duration. Billed at On-Demand rates whether used or not.

### 1. Comparison

| Option | Commitment | Discount vs On-Demand | Best for | Catch |
|---|---|---|---|---|
| **On-Demand** | None | 0% (baseline) | Short-term, spiky, first-time workloads | Highest price. Per-second billing (60 s minimum) for Linux/Windows |
| **Reserved (Standard)** | 1 or 3 years | Up to **72%** | Steady, predictable workloads | Locked to attributes (family, Region/AZ, OS, tenancy). Sellable on the **RI Marketplace** |
| **Reserved (Convertible)** | 1 or 3 years | Lower (up to ~66%) | Steady workloads that may change type | Can exchange for other convertible RIs. Not sellable on the Marketplace |
| **EC2 Instance Savings Plan** | 1 or 3 years, $/hour | Up to **72%** | Steady use of one family in one Region | Size, OS, and tenancy are flexible within the family and Region |
| **Compute Savings Plan** | 1 or 3 years, $/hour | Up to **66%** | Steady spend across changing families, Regions, Fargate, Lambda | Smaller discount for more flexibility |
| **Spot** | None | Up to **90%** | Batch, big data, CI/CD, web with flexible fleets | **Interruptible** with a 2-minute notice |
| **Dedicated Host** | On-Demand or 1/3-year | Reservation up to ~70% | Compliance, per-socket/core software licenses | Most expensive. You manage placement |
| **Dedicated Instance** | None | None | Hardware isolation without host-level control | Billed per instance plus a per-Region fee. May share the host with your other instances |
| **Capacity Reservation** | None (cancel any time) | None (add RI/Savings Plan for a discount) | Guaranteed capacity in a specific AZ | Billed at On-Demand rate **even if unused** |

### 2. Reserved Instances

| Detail | Value |
|---|---|
| Term | **1 or 3 years** (3 years gives the bigger discount) |
| Payment | All Upfront, Partial Upfront, or No Upfront (more upfront means a bigger discount) |
| Scope | **Regional** (flexible AZ, no capacity reservation) or **Zonal** (reserves capacity in one AZ) |
| Standard vs Convertible | Standard: biggest discount, fixed attributes. Convertible: can change instance family, OS, and tenancy |
| Selling | Unused **Standard** RIs can be sold on the **Reserved Instance Marketplace** |

### 3. Savings Plans

- Commit to a **dollar amount per hour** of usage. Usage above the commitment bills at On-Demand rates.
- **Compute Savings Plans** are the most flexible: any instance family, size, Region, OS, and tenancy, plus **Fargate** and **Lambda**.
- **EC2 Instance Savings Plans** give the deepest discount but lock the **family and Region** (size, OS, and tenancy stay flexible).
- The lecture summary says Savings Plans apply "within a family or region". That describes the EC2 Instance plan. The Compute plan is wider.

### 4. Spot Instances

- Pay the current **Spot price**, which changes gradually with supply and demand. There is **no bidding** to win capacity, though you can set a maximum price you're willing to pay (the default max is the On-Demand price).
- When capacity is needed elsewhere (or the price exceeds your max), AWS sends a **2-minute interruption notice**, then **stops, hibernates, or terminates** the instance based on the request.
- Good fit: batch jobs, data analysis, image processing, CI workers, stateless web tiers behind an ASG. **Bad fit:** critical jobs, databases, anything that can't tolerate interruption.
- **Spot Fleet / EC2 Fleet** choose the cheapest pools across instance types and AZs to hit a target capacity.
- **Spot Blocks** (fixed 1-6 hour duration) are no longer available to new customers.

| Request type | Behavior |
|---|---|
| **One-time** | Launches once. When interrupted, it's not re-requested |
| **Persistent** | Re-requests capacity after an interruption |

- **Exam classic:** to stop a **persistent** Spot request from relaunching, **cancel the Spot request first, then terminate the instance**. Terminating the instance alone makes the request launch a new one.
- Cancelling a Spot request does **not** terminate its running instances.

### 5. Dedicated Hosts vs Dedicated Instances

| Aspect | Dedicated Host | Dedicated Instance |
|---|---|---|
| What you get | A **physical server** fully for you | Instances on hardware dedicated to your **account** |
| Visibility | Sockets, physical cores, **host ID** | None |
| Placement control | **Yes** (which instances go on the host) | No |
| Licensing | **BYOL** with per-socket/core/VM licenses | Not licensing-friendly |
| Billing | Per **host** (On-Demand or Reservation) | Per **instance** (plus a per-Region fee) |
| Use case | **Compliance**, strict licensing | Isolation from other customers |

### 6. Capacity Reservations

- Reserve On-Demand capacity in a **specific AZ** for any duration, with no long-term commitment.
- You pay the On-Demand rate **whether or not the capacity is used**.
- Combine with **Regional RIs** or **Savings Plans** to get a discount on the reserved capacity.
- Use case: short-term events or must-have capacity for a critical launch.

### 7. Pricing Example (lecture illustration)

| Option | `m4.large` in `us-east-1` |
|---|---|
| On-Demand | ~$0.10 per hour |
| Spot | Up to ~61% cheaper (varies over time) |
| RI / Savings Plan | Discounts of a similar order for a 1-3 year commitment |

### 8. Exam-Style Recall

| If the question says... | Think... |
|---|---|
| "Short, unpredictable workload, no commitment" | **On-Demand** |
| "Steady-state database running for years" | **Reserved Instance** or **Savings Plan** |
| "Commit to spend but change instance families/Regions" | **Compute Savings Plan** |
| "Change the instance type mid-term" | **Convertible RI** (or a Savings Plan) |
| "Sell unused reservations" | **Standard RI** on the **RI Marketplace** |
| "Cheapest, can tolerate interruptions (batch, big data)" | **Spot Instances** |
| "Spot interruption warning time" | **2 minutes** |
| "Stop a persistent Spot request from relaunching" | **Cancel the request**, then terminate the instance |
| "Strict compliance or BYOL server-bound licenses" | **Dedicated Host** |
| "Hardware not shared with other AWS accounts, no host control" | **Dedicated Instance** |
| "Guarantee capacity in one AZ, pay On-Demand rates" | **Capacity Reservation** |
| "Discount applies to Fargate and Lambda too" | **Compute Savings Plan** |
