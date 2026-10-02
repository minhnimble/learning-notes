# AWS Fundamentals: ELB + ASG

---

## Scalability and High Availability

### TL;DR

- **Scalability** = the system can handle a greater load by adapting. Two kinds: **vertical** (bigger instance) and **horizontal** (more instances).
- **High availability (HA)** = the app survives the loss of a data center/AZ. It is achieved by running in **at least 2 AZs**.
- Scalability and HA are **related but different**. Horizontal scaling often gives you both, but they answer different questions.
- AWS tooling: **ASG** for horizontal scaling, **ELB** for spreading traffic and health checks, and **Multi-AZ** for HA.
- Exam default: prefer **horizontal scaling across multiple AZs** for web/app tiers. Vertical scaling is a fallback for non-distributed systems (for example, databases).

### 1. Vertical Scalability (Scale Up / Down)

- Increase (or decrease) the **size of a single instance**.
- Lecture analogy: a **junior** phone operator handles 5 calls/min, a **senior** handles 10. You upgrade the operator.
- AWS example: `t2.micro` to `t2.large` to a much bigger type. The course cites the range from `t2.nano` (0.5 GB RAM, 1 vCPU) up to `u-12tb1.metal` (~12 TB RAM, 448 vCPUs).
- Common for **non-distributed systems**, especially **databases** (RDS, ElastiCache). Scaling up is the usual answer for them.

| Aspect | Vertical scaling |
|---|---|
| Terms | **Scale up** (bigger) / **scale down** (smaller) |
| What changes | Instance type/size (CPU, RAM, network) |
| Downtime | Usually **yes**. An EBS-backed EC2 instance must be **stopped**, resized, and started. |
| Limit | **Hardware ceiling**. There is a biggest instance type. |
| Failure risk | Still **one instance**, so a single point of failure |
| Cost | Large instances cost disproportionately more |
| Code changes | Usually none |

### 2. Horizontal Scalability (Scale Out / In)

- Increase (or decrease) the **number of instances/systems**.
- Lecture analogy: **hire more operators** instead of upgrading one.
- Implies a **distributed system**. This is the norm for **modern web applications**.
- Easy on AWS because EC2 instances can be launched on demand, with billing per use.

| Aspect | Horizontal scaling |
|---|---|
| Terms | **Scale out** (add) / **scale in** (remove) |
| What changes | Instance **count** |
| Downtime | **None**. New instances join while others keep serving. |
| Limit | Practically very high (bounded by quotas and your design) |
| Failure risk | Losing one instance is tolerable |
| Requirement | App should be **stateless** (see section 4) |
| AWS tools | **Auto Scaling Group (ASG)** + **Load Balancer (ELB)** |

```
Vertical:    [small EC2]  ->  [BIG EC2]

Horizontal:  [EC2]  ->  [EC2] [EC2] [EC2] [EC2]  (behind an ELB)
```

**Exam wording:** "scale up/down" means vertical. "Scale out/in" means horizontal.

### 3. High Availability

- The goal is that the app keeps running **even if a data center (AZ) fails**.
- Achieved by running the app in **at least 2 AZs**. The lecture analogy: put operators in **two call centers in different cities**. If one loses power, the other keeps taking calls.
- **AZ = one or more discrete data centers** with independent power, cooling, and networking. A region has multiple AZs (3 or more in most regions).
- HA is often **paired with horizontal scaling**, but it doesn't have to be.

| Type | Description | Example |
|---|---|---|
| **Active-active** | Instances in multiple AZs **all serve traffic** | ASG + ALB across 3 AZs |
| **Active-passive** | A standby takes over on failure | **RDS Multi-AZ** (standby replica, automatic failover) |

- HA also means **automatic recovery**: detect failure (health checks), stop routing to it, and replace it.

### 4. Designing for Scale and HA

- **Stateless app tier**: don't keep session data or files on a single instance. Otherwise scaling in or losing an instance loses users' data.
  - Sessions: **ElastiCache** (Redis/Memcached) or **DynamoDB**, or stateless tokens (**JWT**).
  - Files: **S3** or **EFS**, not the instance's local disk.
  - Sticky sessions (ALB cookie) are a workaround, not a good HA design.
- **Stateful tier (databases)**: scale up, add **read replicas** for read scaling, and use **Multi-AZ** for HA.
- **Multi-AZ everywhere**: spread ASG instances, load balancer subnets, and databases across AZs.

### 5. AWS Services That Deliver This

| Concern | AWS service/feature |
|---|---|
| Horizontal scaling (automatic) | **Auto Scaling Group (ASG)**. It adds/removes EC2 instances based on policies and metrics. |
| Traffic distribution + health checks | **Elastic Load Balancer (ELB)** |
| Vertical scaling | Manual: **stop, change instance type, start** (or RDS "modify instance class") |
| HA for compute | ASG + ELB spanning **multiple AZs** |
| HA for databases | **RDS Multi-AZ**, Aurora (6 copies across 3 AZs) |
| Scale reads | **RDS read replicas**, Aurora replicas, ElastiCache |
| Manage sessions | ElastiCache, DynamoDB |

**How ASG and ELB work together:**
- The ASG **registers/deregisters** instances with the load balancer's target group as it scales.
- The ELB **health check** can be used by the ASG (health check type = ELB) so failed instances get **replaced**.
- The ASG can be told to launch instances in **multiple AZs** and rebalances if one becomes unavailable.
- **Vertical scaling isn't automated by an ASG.** An ASG only changes the **number** of instances.

### 6. Scalability vs High Availability vs Elasticity

| Term | Meaning | Example |
|---|---|---|
| **Scalability** | Ability to handle more load by adding capacity | Add instances or resize |
| **Elasticity** | Scale **automatically** with demand, out **and** back in (pay only for what you use) | ASG policies |
| **High availability** | Survive component or AZ failure with minimal downtime | Multi-AZ deployment |
| **Fault tolerance** | Continues with **zero** interruption during failure (stricter than HA) | Fully redundant systems |

- A single huge instance is **scalable (vertically)** but **not highly available**.
- Many instances all in **one AZ** are **scalable** but **not highly available**.
- Many instances across **multiple AZs** behind an ELB are **both**.

### 7. Exam-Style Recall

| If the question says... | Think... |
|---|---|
| "Increase instance size" / "scale up" | **Vertical scaling** |
| "Add more instances" / "scale out" | **Horizontal scaling** (ASG + ELB) |
| "Survive an AZ failure" | Deploy across **at least 2 AZs** (Multi-AZ) |
| "Database needs more capacity" | Scale **up** (bigger class) or add **read replicas** for reads |
| "Automatically add/remove instances with demand" | **Auto Scaling Group** (elasticity) |
| "Users lose their session when an instance is removed" | Make the app **stateless** (ElastiCache/DynamoDB) |
| "Remove a single point of failure" | Add instances in another AZ behind a load balancer |
| "Vertical scaling needs downtime" | Yes, stop/resize/start for EC2 |
| "Passive standby in another AZ with automatic failover" | **RDS Multi-AZ** |

---

## Elastic Load Balancing (ELB) in AWS

### TL;DR

- A **load balancer** forwards incoming traffic to multiple backend targets (EC2, containers, IPs, Lambda). Clients see **one endpoint** (a DNS name).
- **ELB** is AWS's **managed** load balancer service: highly available, auto-scaling, and integrated with other AWS services.
- Four types: **CLB** (legacy), **ALB** (Layer 7), **NLB** (Layer 4), **GWLB** (Layer 3).
- **Health checks** keep traffic away from failed targets.
- Security pattern: **LB SG** takes traffic from the internet, and **target SG** takes traffic only from the **LB SG**.
- Exam default: use **ALB** for HTTP, **NLB** for TCP/UDP or static IPs, and **GWLB** for network appliances.

### 1. What Is Load Balancing?

- Load balancers are servers that **forward traffic to multiple downstream targets** so no single instance is overwhelmed.
- They give users a **single point of access**, so backend instances can be added, removed, or replaced without clients noticing.
- An ELB is **regional**. It spreads traffic across **multiple AZs** in one region.
- **Internet-facing** load balancers have public IPs. **Internal** ones have private IPs only, for service-to-service traffic inside a VPC.
- You reach an ELB through its **DNS name**. Its IPs can change, so never hardcode them (except NLB Elastic IPs).

```
Users -> [ELB: single DNS endpoint] -> EC2 (AZ-a)
                                    -> EC2 (AZ-b)
                                    -> EC2 (AZ-c)
```

### 2. Why Use a Load Balancer?

| Benefit | How it helps |
|---|---|
| **Spread load** | Distributes requests across many targets |
| **Single access point** | One DNS name hides the backend complexity |
| **Fault tolerance** | Health checks detect failures and stop routing to unhealthy targets |
| **High availability** | Targets can span multiple AZs, so an AZ outage doesn't take the app down |
| **SSL/TLS termination** | The LB handles HTTPS and certificates, and targets can use plain HTTP |
| **Stickiness** | Sends a user to the same target using cookies (ALB/CLB) or source IP (NLB) |
| **Public/private separation** | Public LB in front, private targets behind it |
| **Managed service** | AWS handles patching, scaling, and availability. This is cheaper and easier than running HAProxy/NGINX yourself, but it has an hourly plus usage cost. |

### 3. Health Checks

- Health checks are configured **per target group** (per CLB for classic).
- The LB calls a **port and route** on each target, commonly `/health`. An HTTP `200` means healthy.
- An **unhealthy** target gets no new traffic until it passes again.
- If **all** targets are unhealthy, the LB **fails open** and sends traffic to all of them anyway.
- Health checks are the reason ELB and Auto Scaling work well together (see section 5).

| Protocols supported | ALB | NLB | GWLB |
|---|---|---|---|
| Health check protocol | HTTP, HTTPS, gRPC | TCP, HTTP, HTTPS | TCP, HTTP, HTTPS |

### 4. The Four Load Balancer Types

| Type | Year | Layer | Protocols | Status |
|---|---|---|---|---|
| **CLB** (Classic) | 2009 | 4 and 7 | HTTP, HTTPS, TCP, SSL/TLS | **Previous generation**. Legacy, and AWS recommends migrating. |
| **ALB** (Application) | 2016 | **7** | HTTP, HTTPS, **HTTP/2**, **WebSocket**, **gRPC** | Current |
| **NLB** (Network) | 2017 | **4** | **TCP, UDP, TCP_UDP, TLS** | Current |
| **GWLB** (Gateway) | 2020 | **3** (+4) | **IP packets** via **GENEVE** (port 6081) | Current |

- The lecture's message: prefer the newer generation load balancers for their extra capabilities.
- **CLB:** not needed for new designs and not a focus of the exam, but it can show up as a **wrong answer** in options.
- **"SSL"** is the older name for what is now **TLS**. AWS still uses "SSL" in some CLB and console wording.

#### 4.1 When to use each

| Type | Use it when... |
|---|---|
| **ALB** | HTTP/HTTPS apps, microservices, containers, path/host/header routing, Lambda targets |
| **NLB** | TCP/UDP traffic, extreme performance (millions of req/sec), ultra-low latency, **static/Elastic IPs**, PrivateLink |
| **GWLB** | Sending traffic through **third-party virtual appliances** (firewalls, IDS/IPS, deep packet inspection) |
| **CLB** | Only legacy workloads that already use it |

#### 4.2 Target types

| Type | ALB | NLB | GWLB |
|---|---|---|---|
| EC2 instances | Yes | Yes | Yes |
| IP addresses (private) | Yes | Yes | Yes |
| Lambda function | Yes | No | No |
| Application Load Balancer | No | Yes | No |

- ECS tasks register as **instance** or **IP** targets.

#### 4.3 Quick feature comparison

| Feature | CLB | ALB | NLB | GWLB |
|---|---|---|---|---|
| Path/host/header routing | No | **Yes** | No | No |
| Static / Elastic IP | No | No | **Yes** | No |
| Cross-zone LB default | Console: on. API/CLI: off | **Always on** | Off | Off |
| SNI (multiple certificates) | No | Yes | Yes | N/A |
| Lambda targets | No | **Yes** | No | No |
| Redirect / fixed response / auth | No | **Yes** | No | No |

### 5. Integration with AWS Services

| Service | How it works with ELB |
|---|---|
| **EC2** | Instances are registered as targets |
| **Auto Scaling Group (ASG)** | The ASG **automatically registers/deregisters** instances in the target group as it scales. It can use **ELB health checks** to replace unhealthy instances, not just EC2 status checks. |
| **ECS** | Containers register as targets. ALB supports **dynamic port mapping**. |
| **EKS** | Provisioned via the AWS Load Balancer Controller |
| **Lambda** | Direct target for ALB |
| **ACM** | Provides free TLS certificates for HTTPS/TLS listeners |
| **Route 53** | Point a domain (**Alias record**) at the ELB DNS name |
| **CloudWatch** | Metrics and alarms (request count, latency, `HTTPCode_Target_5XX`, `UnHealthyHostCount`) |
| **AWS WAF** | Web firewall, attachable to an **ALB** |
| **S3** | Access logs (off by default) |
| **Global Accelerator** | Static anycast IPs in front of ALB/NLB |

**Key exam relationship, ELB + ASG:**
- ELB **spreads** traffic. ASG **adds and removes** capacity.
- Health check failure means ELB stops routing, and ASG can terminate and replace the instance.

### 6. Security Considerations

**Recommended setup:**

```
Internet --80/443--> [LB SG: inbound 80/443 from 0.0.0.0/0]
                               |
                               v
           [EC2 SG: inbound app port, SOURCE = LB SG]
```

| SG | Inbound rule |
|---|---|
| **Load balancer SG** | HTTP 80 / HTTPS 443 from `0.0.0.0/0` (or a restricted range) |
| **EC2 / target SG** | App port with **source = the LB's security group ID**, not a CIDR |

- This means EC2 instances **only accept traffic that came through the load balancer**. Direct access by public IP is blocked and shows up as a **timeout**.
- Referencing an SG (not IPs) keeps working when the LB scales or its IPs change.
- Don't forget health checks. They come from the LB, so the health check port must also be allowed.
- Security groups are **stateful**. Return traffic is automatic.
- Common exam bug: targets show **unhealthy** because the target SG doesn't allow the LB SG.
- Instances can then be placed in **private subnets** for extra protection.

### 7. Other Facts to Remember

- **Client IP:** ALB/CLB (HTTP) pass the original IP in **`X-Forwarded-For`** (plus `X-Forwarded-Proto`, `X-Forwarded-Port`). NLB with instance targets preserves the source IP.
- **TLS termination:** the certificate lives on the LB (from **ACM**). Traffic to the targets can be plain HTTP, or re-encrypted.
- **Stickiness:** ALB uses `AWSALB` cookies (or app cookies). It's configured in the **target group**, with a duration of 1 second to 7 days.
- **Common error codes (ALB):**
  - `4xx` = client error.
  - `502` = bad response from target.
  - `503` = no healthy or registered targets.
  - `504` = target timed out.
  - `5xx` = server/LB-side error.
- **Multi-AZ:** ALB needs subnets in **at least 2 AZs**.
- **Pricing:** hourly charge plus capacity units (**LCU/NLCU/GLCU**). Delete unused LBs.

### 8. Exam-Style Recall

| If the question says... | Think... |
|---|---|
| "Single entry point for many EC2 instances" | **ELB** |
| "Stop sending traffic to a failed instance" | **Health checks** |
| "HTTP routing by path, host, or header" | **ALB** |
| "TCP/UDP, ultra-low latency, millions of req/sec" | **NLB** |
| "Fixed IP addresses / whitelisting" | **NLB** with Elastic IPs |
| "Inspect traffic with a third-party firewall" | **GWLB** |
| "Offload SSL/TLS to the load balancer" | **HTTPS listener** with an ACM certificate |
| "Only the load balancer may reach the instances" | EC2 SG source = **LB SG** |
| "Scale instances automatically behind the LB" | **ELB + Auto Scaling Group** |
| "Replace instances that fail app-level checks" | ASG with **ELB health check type** |
| "Which LB is legacy?" | **CLB** |
| "Users always return to the same instance" | **Sticky sessions** |

---

## Application Load Balancer (ALB) in AWS

### TL;DR

- ALB is a **Layer 7 (HTTP/HTTPS/gRPC)** load balancer that routes requests to **target groups**.
- **One ALB can serve many applications**, using listener rules on path, host, query string, header, method, or source IP.
- Health checks are configured **per target group**. Unhealthy targets stop receiving traffic.
- The app sees the ALB's IP as the source. The real client IP is in **`X-Forwarded-For`**.
- Security pattern: **ALB SG** takes traffic from the internet, and **EC2 SG** takes traffic only from the **ALB SG**.

### 1. What Is an ALB?

| Property | Detail |
|---|---|
| OSI layer | **7** (application) |
| Protocols | HTTP, HTTPS, **HTTP/2**, **WebSockets**, **gRPC** |
| Scope | Regional. It spans multiple AZs in one region. |
| Scheme | **Internet-facing** (public) or **internal** (private) |
| Endpoint | A **DNS name**. There are **no static IPs** or Elastic IPs, and the IPs change. |
| Connection model | ALB **terminates** the client connection and opens a new one to the target. |

- HTTP/2 to clients requires an **HTTPS** listener. Targets receive HTTP/1.1 unless the target group uses the HTTP2 or gRPC protocol version.
- WebSockets work on both HTTP and HTTPS listeners.

### 2. Key Features

| Feature | Detail |
|---|---|
| **Advanced routing** | By URL path, host name, query string, HTTP header, HTTP method, source IP |
| **HTTP to HTTPS redirect** | Done with a **redirect action** on the port-80 listener (301). It is **not automatic**. You configure it. |
| **Fixed responses** | ALB returns a custom status code and body without touching targets |
| **Authentication** | Cognito or OIDC login before forwarding (HTTPS listener) |
| **Weighted target groups** | Split traffic between target groups (blue/green, canary) |
| **Sticky sessions** | Cookie-based (`AWSALB`, or an app-generated cookie) |
| **SNI** | Multiple TLS certificates and domains on one HTTPS listener |
| **Cross-zone load balancing** | Always on at the ALB level, with **no inter-AZ data charge** |

### 3. Routing Examples

| Need | Rule |
|---|---|
| Mobile vs desktop (lecture example) | Query string `?platform=mobile` goes to the mobile target group, `?platform=desktop` goes to the desktop target group |
| Microservices | `/users*` goes to the users target group, `/orders*` goes to the orders target group |
| Multiple domains | Host `api.example.com` goes to the API target group, `www.example.com` goes to the web target group |
| Device detection (alternative) | `User-Agent` header condition |

- Rules live on the **listener**. Lowest priority number is evaluated first, and the first match wins. The default rule runs last.
- Multiple conditions in one rule are combined with **AND**.

### 4. Why ALB Is Great for Microservices and Containers

- **One ALB, many apps**: each microservice gets its own target group and listener rule.
- **Classic Load Balancer (CLB)** needed **one load balancer per application** and had no path or host routing. This meant more cost and more to manage.
- **ECS and Docker**: ALB supports **dynamic port mapping**, so multiple containers of the same service can run on one EC2 host using random ports. ALB tracks each port.
  - ECS on EC2 (bridge network) registers tasks as **instance** targets with dynamic ports.
  - ECS on Fargate or `awsvpc` mode registers tasks as **IP** targets.
- Also works with **EKS** (via the AWS Load Balancer Controller).

### 5. Target Groups

#### 5.1 Purpose

A target group is a set of destinations that receive traffic from the ALB. It also holds the health check and routing settings. The listener rule forwards to the target group, not to individual servers.

```
Client -> [ALB Listener] -> [Rule] -> [Target Group] -> targets (health-checked)
```

#### 5.2 Target types

| Type | What you register | Notes |
|---|---|---|
| **Instance** | EC2 instance IDs | Traffic goes to the instance's primary ENI |
| **IP** | **Private IPs** | Includes on-premises servers (VPN/Direct Connect), peered VPCs, containers. **Public IPs are not allowed.** |
| **Lambda** | One Lambda function | ALB invokes it synchronously. Request/response payload limit is ~1 MB. |

- ECS tasks are not a separate type. They register as **instance** or **IP** targets, as in section 4.
- The **Application Load Balancer** target type exists only for **NLB** target groups (NLB in front of ALB).
- One ALB can have target groups of different types. For example, EC2 instances in AWS in one group and on-premises servers by IP in another.
- A target can be registered in **more than one** target group.

#### 5.3 Health checks

- Configured **at the target group level**.
- A target that fails is marked `unhealthy` and gets no traffic until it passes again.
- The ALB **fails open**: if **all** targets are unhealthy, it routes to all of them anyway.

| Setting | ALB default |
|---|---|
| Protocol / Port | HTTP / traffic port |
| Path | `/` |
| Interval | 30 s |
| Timeout | 5 s |
| Healthy threshold | 5 |
| Unhealthy threshold | 2 |
| Success codes | 200 |

- Health check protocols on ALB: **HTTP, HTTPS** (and gRPC). There is **no plain TCP** check (that's NLB).
- You can override the health check **port**. That port must also be allowed in the target's SG.

#### 5.4 Useful target group attributes

- **Deregistration delay** (default 300 s): in-flight requests finish before a target is removed.
- **Slow start**: gradually ramps traffic to a newly healthy target.
- **Routing algorithm**: round robin (default), least outstanding requests, weighted random.
- **Stickiness**: enable and set the duration here.

### 6. Client IP Handling

- ALB terminates the connection, so the target sees the **ALB's private IP** as the source.
- The original client info is passed in headers:

| Header | Contains |
|---|---|
| **`X-Forwarded-For`** | Original client IP (proxies append to the list) |
| **`X-Forwarded-Proto`** | Original protocol (`http` or `https`) |
| **`X-Forwarded-Port`** | Original port the client connected to |

- Apps and logs should read `X-Forwarded-For` to get the real client IP.
- The same trick applies to **NLB**? No. NLB with instance targets **preserves the source IP**, so it has no such header.

### 7. Security Groups

**Correct setup:**

```
Internet --80/443--> [ALB SG: inbound 80/443 from 0.0.0.0/0]
                                 |
                                 v
             [EC2 SG: inbound app port, SOURCE = ALB SG]
```

| SG | Inbound | Outbound |
|---|---|---|
| **ALB SG** | 80/443 from the clients (usually `0.0.0.0/0`) | Must allow the target port and the health check port to the targets. Default "all" works. |
| **EC2 / target SG** | Target port with **source = ALB SG** (not a CIDR) | Default |

- Only the **target's SG** should reference the ALB's SG. This means EC2 instances only accept traffic that comes through the ALB.
- Referencing an SG (not an IP range) keeps working as ALB nodes scale and their IPs change.
- If instances are reached directly by IP, the EC2 SG still allows `0.0.0.0/0`. Remove that rule.
- Health check traffic also comes from the ALB, so the same rule covers it (or add the health check port).
- Security groups are **stateful**. Return traffic is allowed automatically.
- Direct access blocked by an SG shows up as a **timeout**, not "connection refused".

### 8. Good to Know

- **Lambda behind ALB** gives a serverless HTTP backend without API Gateway. It's good for simple cases, but it has no throttling, usage plans, or API keys.
- **Static IP needed?** ALB can't have one. Options are **NLB in front of ALB**, or **Global Accelerator** in front of ALB.
- **Non-HTTP traffic (TCP/UDP)**: use NLB, not ALB.
- **ALB needs at least 2 AZs** (2 subnets in different AZs).
- **Idle timeout**: 60 s by default.
- **Access logs** go to S3 (disabled by default). **CloudWatch metrics** include `HTTPCode_ELB_5XX`, `HTTPCode_Target_5XX`, `TargetResponseTime`, `UnHealthyHostCount`.
- **Error codes**: `502` = bad response from the target, `503` = no healthy targets, `504` = target timed out.
- **Billing**: hourly charge plus **LCU** usage. Delete demo ALBs after use.

### 9. Exam-Style Recall

| If the question says... | Think... |
|---|---|
| "Route by URL path or host name" | **ALB** listener rules |
| "Route mobile vs desktop traffic" | Query string or `User-Agent` header rule |
| "Multiple apps, one load balancer" | **ALB** with multiple target groups |
| "Containers on random ports (ECS)" | **Dynamic port mapping** with ALB |
| "Unhealthy instances shouldn't get traffic" | **Target group health checks** |
| "App needs the client's real IP" | **`X-Forwarded-For`** header |
| "Only the load balancer may reach EC2" | EC2 SG source = **ALB SG** |
| "On-premises servers behind the ALB" | **IP** target type (private IPs over VPN/Direct Connect) |
| "Serverless backend behind the ALB" | **Lambda** target group |
| "Redirect HTTP to HTTPS" | Listener **redirect action** (80 to 443) |
| "Static IP for the load balancer" | **NLB** (or Global Accelerator). Not ALB. |
| "`503` from the ALB" | **No healthy targets** |

---

## Application Load Balancer (ALB) - Hands On - Part 1

### TL;DR

- Launched 2 EC2 instances, each serving a "Hello World" page from user data.
- Created an internet-facing ALB, a security group for it, and a target group holding both instances.
- Hitting the ALB DNS name and refreshing alternated between the two instances, which is round-robin load balancing.
- Stopping one instance made the target group stop routing to it (health checks). Starting it again brought it back automatically.

### 1. Prerequisite: Backend EC2 Instances

| Setting | Value used in demo | Notes |
|---|---|---|
| Count | 2 (launched together, second renamed to "My Second Instance") | Different AZs is best practice for HA |
| AMI | Amazon Linux 2 | AL2 has hit end of support (scheduled June 2026). Use **Amazon Linux 2023** for new work |
| Instance type | t2.micro | Free-tier-eligible type |
| Key pair | None | SSH isn't needed. Use **EC2 Instance Connect** (or SSM Session Manager) if access is needed |
| Security group | Existing `Launch Wizard 1` | Allows HTTP (80) and SSH (22) inbound from anywhere |
| Storage | Default/basic | |
| User data | Script that starts a web server and returns "Hello World" | Runs once at first boot as root |

Typical user data script (from the earlier lecture, not shown in this transcript):

```bash
#!/bin/bash
yum update -y
yum install -y httpd
systemctl start httpd
systemctl enable httpd
echo "<h1>Hello World from $(hostname -f)</h1>" > /var/www/html/index.html
```

**Verification before adding the LB:**
- Visited each instance's public IPv4 address in the browser and got a "Hello World" from each.
- Problem: 2 instances means 2 different URLs, and the IPs change on stop/start.
- Goal: **one URL** that spreads load across both instances, which is the job of a load balancer.

### 2. The Four ELB Types

| Type | Layer | Protocols | Use case |
|---|---|---|---|
| **ALB** (Application) | 7 | HTTP, HTTPS, gRPC, WebSocket | Web apps, microservices, containers. This demo |
| **NLB** (Network) | 4 | TCP, UDP, TLS | Ultra-high performance (millions of req/sec), ultra-low latency, **static IP / Elastic IP per AZ** |
| **GWLB** (Gateway) | 3 (+4) | IP, GENEVE (port 6081) | Route traffic through 3rd-party virtual appliances: firewalls, IDS/IPS, deep packet inspection |
| **CLB** (Classic) | 4 and 7 | HTTP/S, TCP | Legacy, being phased out. **Not covered**, and not the answer for new designs |

### 3. Creating the ALB: Step by Step

#### 3.1 Basic configuration
- **Name**: `DemoALB`
- **Scheme**: **Internet-facing** (public IPs, reachable from the internet). The alternative is **Internal** (private IPs only, for service-to-service traffic inside a VPC).
- **IP address type**: IPv4 (dualstack is also available).

#### 3.2 Network mapping
- Pick the VPC and the AZs/subnets to deploy into.
- Demo: selected **all AZs**.
- **Rule: an ALB needs subnets in at least 2 AZs.** For an internet-facing ALB these must be public subnets (route to an Internet Gateway).
- AWS puts an ALB node in each selected AZ.

#### 3.3 Security group (for the ALB)
- Created a **new** SG: `demo-sg-load-balancer`, described as "Allow HTTP into ALB".
- **Inbound**: HTTP (TCP 80) from `0.0.0.0/0` (anywhere).
- **Outbound**: default (all traffic).
- After creating it, refreshed the wizard, selected it, and **removed the default SG** so only one remained.
- The ALB's SG is separate from the EC2 SG.

#### 3.4 Listeners and routing
- **Listener** = process that checks for connection requests using a protocol and port.
- Demo: listener **HTTP : 80** with the default action **Forward to target group**.
- Other listener options: HTTPS 443 (needs an ACM certificate) and redirect actions such as HTTP to HTTPS.

#### 3.5 Target group (created inline from the wizard)
- **Target type**: "Instances". The others are IP addresses, Lambda function, and Application Load Balancer.
- **Name**: `demo-tg-alb`
- **Protocol : Port**: HTTP : 80 (the port traffic is sent to on the targets)
- **Protocol version**: HTTP1 (other options: HTTP2, gRPC)
- **Health checks**: left at defaults (see section 6)
- **Register targets**: selected both EC2 instances, port 80, then clicked "Include as pending below" and "Create target group"
- Back in the ALB wizard, **refreshed** the target group dropdown and selected `demo-tg-alb`.

#### 3.6 Finish
- Clicked **Create load balancer**, then "View load balancer".
- State: **Provisioning**, then **Active** after a few minutes.
- The ALB is given a **DNS name** (format `name-<id>.<region>.elb.amazonaws.com`).

### 4. Testing Load Balancing

1. Copied the ALB **DNS name** into a browser and got "Hello World".
2. Refreshed repeatedly: the response alternated between instance 1 and instance 2.
3. That alternation proves the ALB distributes requests across targets.

Notes:
- The default algorithm is **round robin**. It can be switched to **least outstanding requests** in the target group attributes.
- Always use the ALB's **DNS name**. Its IPs change over time, and there are no static IPs (use NLB or Global Accelerator if you need static IPs).
- **Cross-zone load balancing is always on for ALB** at the load balancer level, so traffic is spread across all registered targets in all enabled AZs. There is **no inter-AZ data charge** for this on ALB.

### 5. Demo of Health Checks and Failover

1. Target group, Targets tab: both instances showed **healthy**.
2. **Stopped instance 1.**
3. After ~30 seconds, refreshed the target group and the instance showed as **unused**.
4. Refreshing the ALB URL now returned responses only from instance 2, so **there was no downtime for users**.
5. **Started instance 1 again.** Its status went **initial** and then **healthy**.
6. The ALB then served responses from **both** instances again.

Target health states:

| State | Meaning |
|---|---|
| `initial` | Being registered, or health checks are running for the first time |
| `healthy` | Passing health checks, receiving traffic |
| `unhealthy` | Failing health checks, no traffic sent |
| `unused` | Not registered, not in an enabled AZ, or **the instance is stopped/not running** (what the demo showed) |
| `draining` | Being deregistered, in-flight requests are finishing (**deregistration delay**, default 300 s) |
| `unavailable` | Health checks disabled |

The lecturer said the stopped instance becomes "unhealthy". In the console it actually shows **unused**, because the instance isn't in the running state. A *running* instance whose app fails the check shows **unhealthy**.

### 6. Target Group Health Check Defaults (ALB)

| Setting | Default |
|---|---|
| Protocol / Port | HTTP / traffic port |
| Path | `/` |
| Interval | 30 s |
| Timeout | 5 s |
| Healthy threshold | 5 consecutive successes |
| Unhealthy threshold | 2 consecutive failures |
| Success codes | 200 |

- Health checks are configured **per target group**, not per ALB.
- Recovery isn't instant: a restarted instance must pass the healthy threshold (5 checks × 30 s ≈ 2.5 min by default) before receiving traffic. The video skips this wait.
- If **all** targets in a target group are unhealthy, the ALB **fails open** and routes to all of them anyway, which is a common exam gotcha.

### 7. Security Group Design

**What the demo did:**
- The ALB SG allows HTTP 80 from anywhere.
- The EC2 SG (`Launch Wizard 1`) *also* allows HTTP 80 from anywhere. That is why each instance was still reachable directly by its public IP.

**Best practice (exam-relevant):**
```
Internet --HTTP/HTTPS--> [ALB SG: inbound 80/443 from 0.0.0.0/0]
                                   |
                                   v
                 [EC2 SG: inbound 80 with SOURCE = ALB SG (by SG ID)]
```
- Restrict the EC2 SG so it only accepts traffic **from the ALB's security group**, not from `0.0.0.0/0`.
- Instances can then also live in private subnets.
- Security groups are **stateful**, so return traffic is allowed automatically.
- Referencing a **security group as the source** is the key technique. It survives IP changes and scaling.

### 8. Key Facts to Remember

**Client IP and proxy headers**
- The app server sees the **ALB's private IP** as the source. The real client IP is in the **`X-Forwarded-For`** header.
- Other headers: **`X-Forwarded-Port`** and **`X-Forwarded-Proto`**.
- On NLB, the client IP is preserved by default for instance targets.

**Features of ALB**
- **Routing rules** on: URL **path**, **host** name, **query string**, **HTTP headers**, HTTP method, and source IP.
  - Example: `?platform=mobile` goes to the mobile target group.
  - Example: `/users` goes to the users service.
- **Multiple target groups** behind one ALB (microservices).
- Supports **HTTP/2, WebSockets, gRPC**, redirects (HTTP to HTTPS), fixed responses, and authentication (Cognito/OIDC).
- Target types: **EC2 instances, ECS tasks, IP addresses (including on-premises via VPN/Direct Connect), Lambda functions**.
- **Dynamic port mapping** for ECS. ALB can route to containers on random ports, which CLB can't do.
- One ALB can serve **many applications**, whereas CLB needed one per app.

**Other**
- ALB is a **regional** service. It doesn't span regions.
- Idle timeout: 60 s by default.
- An ALB can't be assigned an Elastic IP. Use an **NLB** (which can sit in front of an ALB) or **Global Accelerator** if you need fixed IPs.
- Pricing: hourly charge plus **LCU** (Load Balancer Capacity Units) usage.

### 9. Exam-Style Recall

| If the question says... | Think... |
|---|---|
| "HTTP/HTTPS, path-based or host-based routing, microservices" | **ALB** |
| "Millions of requests/sec, ultra-low latency, static IP, TCP/UDP" | **NLB** |
| "Inspect traffic with 3rd-party firewall/IDS appliances" | **GWLB** |
| "Unhealthy instance shouldn't get traffic" | **Target group health checks** |
| "Backend needs the real client IP" | **`X-Forwarded-For`** header |
| "Only allow traffic to EC2 from the load balancer" | EC2 SG source = **ALB SG** |
| "ALB routes to containers on dynamic ports" | ECS + **dynamic port mapping** |
| "Serverless backend behind the ALB" | **Lambda target group** |
| "Redirect HTTP to HTTPS" | **Listener redirect rule** (80 to 443) |
| "One entry point, many services" | **Listener rules to multiple target groups** |

### 10. Hands-On Checklist

- [x] Launch 2 EC2 instances with a web server user data script
- [x] Verify each one directly
- [x] Create a security group allowing HTTP 80 inbound for the ALB
- [x] Create a target group (type: instances, HTTP:80) and register both instances
- [x] Create an internet-facing ALB in at least 2 AZs with the HTTP:80 listener forwarding to the target group
- [x] Wait for the ALB to become **Active**
- [x] Open the ALB DNS name and refresh to see alternating responses
- [x] Stop one instance and watch it go `unused` while traffic continues on the other
- [x] Start it again and watch `initial` then `healthy`

---

## Application Load Balancer (ALB) - Hands On - Part 2

### TL;DR

- **Network security:** changed the EC2 security group so HTTP is only allowed **from the ALB's security group** (not from anywhere). Direct access to the instance's public IP now times out, while access through the ALB still works.
- **Listener rules:** added a rule to the ALB's HTTP:80 listener. If the **path is `/error`**, the ALB returns a **fixed response** (404, text/plain) and never reaches the EC2 instances.
- Together these show that the ALB is the single controlled entry point, and it can make routing decisions at layer 7 itself.

### 1. Starting Point (End State of Part 1)

- ALB with security group `demo-sg-load-balancer` (HTTP 80 from anywhere).
- Two EC2 instances using `launch-wizard-1` (HTTP 80 and SSH 22 from anywhere).
- Both instances were reachable in two ways:
  - **Directly** via their public IPv4 address (not desired).
  - **Through the ALB** DNS name (desired).
- Problem: anyone can bypass the load balancer and hit an instance directly, skipping any ALB-level routing, auth, or logging.

### 2. Tightening Network Security

#### 2.1 Goal

Only traffic coming **from the load balancer** should be able to reach the EC2 instances.

#### 2.2 Steps in the console

1. EC2, **Security Groups**, select `launch-wizard-1` (the EC2 instances' SG).
2. **Edit inbound rules.**
3. Find the **HTTP (80)** rule with source `0.0.0.0/0` and **delete** it.
4. **Add rule**: Type **HTTP**, port 80.
5. For **Source**, don't enter a CIDR. Type "load" in the source box and pick the **ALB's security group** (`demo-sg-load-balancer`) from the list.
6. Save the rules.

#### 2.3 Result

| Access path | Result | Why |
|---|---|---|
| Browser to EC2 **public IP** directly | **Times out** | Source isn't the ALB SG, so the packet is silently dropped |
| Browser to **ALB DNS name** | Works | Traffic arrives from the ALB, which is in the allowed SG |

#### 2.4 Key concepts

- **SG referencing another SG as the source** means "allow traffic from any resource that has this SG attached".
  - It doesn't depend on IP addresses, so it survives ALB IP changes and scaling. This is **the recommended pattern**.
  - The ALB's nodes use private IPs inside your VPC, and the EC2 SG rule matches those via the ALB's SG.
- **Timeout, not "connection refused"**: security groups *drop* denied traffic silently. This is a classic exam clue.
  - Timeout usually means a **security group** or network problem.
  - "Connection refused" usually means the SG was passed but nothing is listening on that port.
- Security groups only have **allow** rules (no explicit deny). Removing the allow rule is how you block.
- Security groups are **stateful**, so return traffic is allowed automatically.

#### 2.5 Things the demo did not change (gotchas)

- The **SSH (22)** rule on `launch-wizard-1` was untouched. It's still open to anywhere, and EC2 Instance Connect relies on it. In production, restrict or remove it (use **SSM Session Manager** instead).
- **Health checks** come from the ALB too. The health check port (by default, the traffic port, 80) is covered by the same SG rule. If you use a different health check port, allow it from the ALB SG as well, or targets will show **unhealthy**.
- The **ALB's outbound rules** must allow traffic to the targets and the health check port. The default "all outbound" does this.
- With this setup, the instances could also be moved to **private subnets** for extra protection.

#### 2.6 Layered security model

```
Internet --HTTP/HTTPS--> [ALB SG: inbound 80/443 from 0.0.0.0/0]
                                   |
                                   v
                 [EC2 SG: inbound 80, SOURCE = ALB SG (by SG ID)]
```

### 3. ALB Listener Rules

#### 3.1 Where to find them

**EC2, Load Balancers, DemoALB, Listeners tab, click the listener (HTTP:80), Rules section (listener rules).**

- Each listener has its own set of rules.
- Initially there is only the **default rule**: for every request, forward to `demo-tg-alb`.
- You can add more rules of any complexity.

#### 3.2 Anatomy of a rule

A rule = **priority** + **conditions (IF)** + **actions (THEN)**.

#### 3.3 Conditions (what to match)

| Condition | Matches on | Example |
|---|---|---|
| **Host header** | The `Host` header / domain name | `myapp.example.com`, `*.example.com` |
| **Path** | The URL path | `/error`, `/users/*` |
| **HTTP request method** | GET, POST, PUT, DELETE, etc. | `POST` |
| **Source IP** | Client IP (CIDR) | `203.0.113.0/24` |
| **Query string** | Key/value pairs in the URL | `?platform=mobile` |
| **HTTP header** | Any custom or standard header | `User-Agent`, `X-Custom-Header` |

- Multiple conditions can be combined in one rule. **All** conditions must match (AND).
- Path patterns are **case-sensitive** and support wildcards (`*`, `?`).
  - `/error` matches exactly `/error`.
  - `/error/*` matches sub-paths.
- Host headers are case-insensitive.
- A path condition looks at the **path only**, not the query string. Use a query-string condition for `?key=value`.
- Limits (defaults): ~5 match evaluations per rule, ~100 rules per ALB (not counting the default rule). Check the console's "rules limit" link for current quotas.

#### 3.4 Actions (what to do on a match)

| Action | What it does | Typical use |
|---|---|---|
| **Forward** | Sends to one or more **target groups** | Microservices routing (`/users` to users-TG, `/orders` to orders-TG) |
| **Redirect** | Returns **301/302** to another URL (change protocol, host, port, path, query) | **HTTP to HTTPS**, domain migration |
| **Fixed response** | ALB itself returns a custom HTTP code, content type, and body | Custom 404/403/503, maintenance page, block a path |
| **Authenticate (Cognito / OIDC)** | Authenticates users before forwarding | Login for internal apps (**requires an HTTPS listener**) |

- **Forward** can target **multiple target groups with weights** (for example 90/10), useful for **blue/green** and **canary** deployments.
- **Fixed response** supports `2XX`, `4XX`, and `5XX` codes, with content types such as `text/plain`, `text/html`, `application/json`. The body is limited to ~1 KB.
- Redirect and fixed-response actions are handled by the ALB. **No request reaches your targets.**

#### 3.5 Priority

- Range: **1 to 50,000**.
- **Lower number = higher priority = evaluated first.** Rules are evaluated in ascending order and the **first match wins**.
- The **default rule** has no priority number and is evaluated **last**. It catches everything that no other rule matched.
- Lecturer's phrasing ("one is highest, five is lower") means priority 1 is evaluated before priority 5.
- Best practice: leave gaps (10, 20, 30...) so you can insert rules later.

### 4. Demo: Fixed-Response Rule for `/error`

#### 4.1 Steps

1. Listener, **Add rule**.
2. **Name:** `DemoRule`.
3. **Condition:** Path is `/error`, then confirm.
4. **Action:** **Return fixed response**.
   - Response code: **404**.
   - Content type: `text/plain`.
   - Body: "not found custom error".
5. **Priority:** `5`.
6. Review and create.

The listener now has **2 rules**: `DemoRule` (priority 5) and the **default rule** (forward to `demo-tg-alb`).

#### 4.2 Test

| Request | Matches | Response |
|---|---|---|
| `http://<alb-dns-name>/` | Default rule | "Hello World" from EC2 (load balanced between the 2 instances) |
| `http://<alb-dns-name>/error` | `DemoRule` (priority 5) | **404**, `text/plain`, "not found custom error" |

- The `/error` response came from the **ALB itself**, not from EC2. The ALB matched on layer 7 (the HTTP path) and answered directly.

### 5. Key Facts to Remember

**Security**
- Best practice is EC2 SG source = **ALB SG**, not `0.0.0.0/0`.
- SG changes take effect **immediately** and don't require a restart.
- Timeout = SG/network block. Connection refused = reached the host, but no listener on that port.

**Rules**
- Rules are on **listeners**, not on the ALB as a whole and not on target groups.
- **Path-based routing** (`/users`) and **host-based routing** (`api.example.com`) are ALB-only features. NLB and CLB can't do this.
- Rules can route on query strings (`?platform=mobile`) and HTTP headers too.
- One ALB with multiple listener rules and target groups can replace many classic load balancers (**cost saving**).
- ALB rules only see HTTP(S) traffic. For TCP/UDP, use an NLB.

**Related (helpful for the exam)**
- **HTTP to HTTPS redirect:** a listener on port 80 with a default action of Redirect to HTTPS:443, status **301**.
- **HTTPS listener** needs an **ACM certificate** (or an imported one). **SNI** lets one listener serve multiple certificates/domains.
- The **X-Forwarded-For** header carries the client IP to your targets.
- Sticky sessions (target-group setting) use a cookie (`AWSALB` for duration-based).

### 6. Exam-Style Recall

| If the question says... | Think... |
|---|---|
| "Only allow the ALB to reach EC2" | EC2 SG inbound source = **ALB SG** |
| "Users can still reach instances by public IP" | EC2 SG allows `0.0.0.0/0`. Restrict to the ALB SG |
| "Request times out when hitting the instance directly" | **Security group** is blocking it |
| "Route `/api` and `/images` to different services" | **Path-based listener rules** with multiple target groups |
| "Route by domain / subdomain" | **Host-header** rule |
| "Route mobile vs desktop users" | **Query-string** or **HTTP header** (User-Agent) rule |
| "Return a custom error / maintenance page without hitting the servers" | **Fixed-response** action |
| "Force HTTPS" | **Redirect** action (80 to 443, 301) |
| "Send 10% of traffic to a new version" | **Weighted forward** to two target groups |
| "Require login before reaching the app" | **Authenticate-Cognito/OIDC** action on an HTTPS listener |
| "Two rules match the same request" | The rule with the **lowest priority number** wins |

### 7. Hands-On Checklist

- [x] Edit the EC2 SG: delete HTTP `0.0.0.0/0`, add HTTP with source = **ALB SG**
- [x] Test: direct EC2 public IP **times out**, ALB DNS still works
- [x] Open the ALB, Listeners, HTTP:80, Rules
- [x] Add rule `DemoRule` with condition **Path = `/error`**
- [x] Set action **Fixed response** (404, text/plain, custom message) and priority **5**
- [x] Test `<alb-dns>/error` and confirm the 404 custom response
- [x] Test `<alb-dns>/` and confirm it still load balances between both instances

---

## Network Load Balancer (NLB)

### TL;DR

- NLB is a **Layer 4** load balancer that handles **TCP, UDP** (and TLS) traffic.
- It is built for **extreme performance**: millions of requests per second with ultra-low latency.
- It has **one static IP per AZ**, and you can attach an **Elastic IP** to each. This is its signature feature.
- Target groups can hold **EC2 instances, private IP addresses, or an ALB**.
- NLB target group health checks support **TCP, HTTP, and HTTPS**.
- Exam triggers: **UDP**, **static/Elastic IP**, or **extreme performance** all point to NLB.

### 1. What Is an NLB?

| Property | Detail |
|---|---|
| OSI layer | **Layer 4** (transport). ALB is Layer 7 (HTTP). |
| Protocols | **TCP, UDP, TLS**, plus TCP_UDP (one listener for both). Newer: QUIC. |
| Performance | **Millions of requests/sec**, ultra-low latency (AWS quotes ~100 µs vs ~400 ms for ALB) |
| Scope | Regional. It can be **internet-facing** or **internal**. |
| Understands HTTP? | **No.** It has no path, host, header, or query-string routing. Those are ALB features. |

- The lecture's rule: if you see **UDP** (or plain TCP), think NLB. **ALB does not support UDP.**
- Typical workloads: gaming, IoT, VoIP/streaming, financial systems, and any non-HTTP protocol.
- It also works for very spiky or sudden traffic surges, because it scales with no pre-warming.

### 2. Static IPs and Elastic IPs (the Big Exam Point)

- The NLB gets **one static IP per Availability Zone** it is enabled in.
- You can **assign one Elastic IP (EIP) per AZ** (internet-facing NLB).
- The EIPs are chosen when you configure the subnet mappings at creation time. You can't add or change them later without recreating the load balancer.
- Example: 3 AZs means 3 static IPs to give to clients.
- Use cases:
  - Clients or partners must **whitelist a small fixed set of IPs** in their firewall.
  - The exam says "the application must be accessible from only 1, 2, or 3 specific IP addresses", so **NLB**.

| Need | Use |
|---|---|
| Static/Elastic IPs on a regional entry point | **NLB** |
| Static anycast IPs across regions | **Global Accelerator** |
| Static IP in front of an HTTP app with L7 rules | **NLB to ALB**, or Global Accelerator to ALB |
| ALB alone | No static IP, no EIP. Its IPs change, so use the DNS name. |

### 3. How It Works: Listeners and Target Groups

The flow is the same as ALB:

```
Client --TCP/UDP/TLS--> [NLB Listener] --forward--> [Target Group] --> targets
```

- A **listener** defines protocol and port (1–65535).
- A **target group** holds the targets and does health checks.
- Target-group protocol can differ from the listener's. TLS on the listener can forward as plain TCP to the targets, which is TLS termination on the NLB using an ACM certificate.
- The lecture said "GTP in the backend". That is very likely a transcription error. The NLB protocols to know are **TCP, UDP, TCP_UDP, TLS**.

#### 3.1 Target types

| Target type | Details |
|---|---|
| **Instance** | EC2 instances, registered by instance ID. |
| **IP address** | Registered by **IP**. Must be **private IPs** (in your VPC CIDR or another allowed private range), not public. |
| **Application Load Balancer** | An ALB as the target (see section 4). |

**Why IP targets?**
- Register the **private IP of an EC2 instance** you own.
- Register **private IPs of on-premises servers** (reachable over **VPN or Direct Connect**).
- Register IPs in a **peered VPC**.
- One NLB can front **both AWS and on-premises** servers at the same time.
- IP targets can also be **containers** (for example ECS/Fargate tasks with awsvpc networking).

### 4. NLB in Front of an ALB

```
Client --> [NLB: static IPs, L4] --> [ALB: HTTP rules, L7] --> targets
```

- **Why do it?**
  - NLB provides **fixed/Elastic IPs**.
  - ALB provides **HTTP routing rules** (path, host, header, query string, redirects, auth).
- This gives you the best of both, and the exam calls it a valid combination.
- The ALB is registered as an **ALB-type target** in an NLB target group. The listener protocol is TCP.
- Trade-off: one extra hop and an extra bill.
- The alternative for static IPs is **Global Accelerator in front of the ALB**.

### 5. Health Checks

NLB target groups support **three** health check protocols:

| Protocol | Notes |
|---|---|
| **TCP** | The check passes if a TCP connection succeeds. It is the default and works for any app. |
| **HTTP** | Checks a path and status code (default success: `200-399`). Use it if the backend speaks HTTP. |
| **HTTPS** | Same as HTTP, over TLS. |

Defaults (worth knowing, but they can be changed):

| Setting | NLB default |
|---|---|
| Interval | 30 s |
| Healthy threshold | 3 |
| Unhealthy threshold | 3 |
| Timeout | 10 s for TCP and HTTPS, 6 s for HTTP |

- Health checks are configured **per target group**, same as ALB.
- Comparison: ALB health checks only support **HTTP/HTTPS** (and gRPC). NLB adds **TCP**.
- If a target fails the checks, no new traffic goes to it. If **all** targets are unhealthy, the load balancer **fails open** and routes to all of them.

### 6. Other Facts to Remember

**Client IP preservation**
- The NLB does **not** proxy at Layer 7, so there is **no `X-Forwarded-For` header**.
- For **instance targets**, the **client's source IP is preserved** by default, and the app sees the real client IP directly.
- For **IP targets** (TCP/TLS), preservation is off by default. Use **Proxy Protocol v2** to pass client info.

**Security groups**
- Older NLBs had no SG at all. NLBs now support SGs. If your NLB has an SG, the targets' SG can allow traffic **from the NLB's SG**.
- If the NLB has no SG and preserves client IPs, the targets' SGs must allow the **client IP ranges** (for example, `0.0.0.0/0` for a public service).

**Cross-zone load balancing**
- **Disabled by default on NLB** (each node sends only to targets in its own AZ). You can enable it, and then **inter-AZ data charges apply**.
- On ALB, cross-zone is always on and has no inter-AZ charge for it.

**TLS**
- Supports **TLS termination** with an ACM certificate, and SNI for multiple certificates.

**Connection behavior**
- Uses **flow-hash** routing: the same connection goes to the same target.
- Idle timeout defaults: **350 s for TCP**, **120 s for UDP**.

**Other**
- **AWS PrivateLink** (VPC endpoint services) requires an **NLB** (or GWLB) in front of the service.
- Pricing: hourly charge plus **NLCU** (Network Load Balancer Capacity Units).

### 7. ALB vs NLB Cheat Sheet

| Feature | ALB | NLB |
|---|---|---|
| Layer | 7 | **4** |
| Protocols | HTTP, HTTPS, gRPC, WebSocket | **TCP, UDP, TLS** |
| Routing | Path, host, header, query string, method, source IP | Port and protocol only |
| Static / Elastic IP | No | **Yes (per AZ)** |
| Performance | High | **Extreme (millions req/sec, lowest latency)** |
| Target types | Instance, IP, Lambda | Instance, IP, ALB |
| Health check protocols | HTTP, HTTPS, gRPC | **TCP**, HTTP, HTTPS |
| Client IP to app | `X-Forwarded-For` header | **Preserved** (instance targets) |
| Cross-zone LB | On (free) | Off by default (paid if enabled) |
| Redirects, fixed responses, auth | Yes | No |
| Lambda as target | Yes | No |

### 8. Exam-Style Recall

| If the question says... | Think... |
|---|---|
| "UDP traffic" | **NLB** |
| "TCP / non-HTTP protocol" | **NLB** |
| "Millions of requests per second, ultra-low latency" | **NLB** |
| "Clients need to whitelist fixed IP addresses" | **NLB with Elastic IPs** |
| "Application accessible from only 1–3 IPs" | **NLB** |
| "Static IP **and** path-based routing" | **NLB in front of ALB** |
| "Load balance to on-premises servers" | Target group with **IP targets** (private IPs over VPN/Direct Connect) |
| "Expose a service to other VPCs/accounts via PrivateLink" | **NLB** behind a VPC endpoint service |
| "Health check on a plain TCP port" | **NLB** (TCP health check) |
| "Real client IP without `X-Forwarded-For`" | NLB with instance targets (source IP preserved) |
| "Need URL-path, host, or header routing" | **ALB**, not NLB |


---

## Network Load Balancer (NLB) - Hands On

### TL;DR

- Created an internet-facing **NLB** (`DemoNLB`) across all 3 AZs, with its own security group (`demo-sg-nlb`).
- Listener **TCP:80** forwards to a new target group (`demo-tg-nlb`, TCP:80) with the same 2 EC2 instances used in the ALB demos.
- Targets went **unhealthy**. Cause: the EC2 security group only allowed HTTP from the **ALB's SG**, not the **NLB's SG**.
- Fix: add an inbound HTTP rule on the EC2 SG with **source = NLB SG**. Targets turned healthy, and the NLB DNS name returned "Hello World" from both instances.
- Main lesson: **unhealthy targets right after setup usually means a security group problem.**

### 1. Starting Point

- 2 EC2 instances running a web server ("Hello World").
- EC2 SG `launch-wizard-1`:
  - SSH 22 from anywhere.
  - HTTP 80 with **source = ALB SG** (set in ALB Part 2).
- Nothing yet allowed the NLB to reach the instances. This causes the failure later in the demo.

### 2. Creating the NLB: Step by Step

#### 2.1 Basic configuration

- **Name**: `DemoNLB`
- **Scheme**: **Internet-facing**
- **IP address type**: IPv4

#### 2.2 Network mapping

- Select the VPC and **all 3 AZs**, one subnet per AZ.
- For each AZ, the console shows an **IPv4 address assigned by AWS**. This is the NLB's **fixed IP for that AZ**.
- Instead of an AWS-assigned IP, you can pick an **Elastic IP** per AZ. Use this when clients must whitelist known IPs.
- The demo used the AWS-assigned IPs.
- Choose the IP mapping at creation. Changing the EIPs later generally means recreating the NLB.

#### 2.3 Security group (for the NLB)

- Attaching an SG to an NLB is **recommended**. The lecturer called it "new" because NLBs originally had no SGs (support was added in 2023).
- Created a new SG: `demo-sg-nlb`.
  - **Inbound**: HTTP (TCP 80) from `0.0.0.0/0`.
  - **Outbound**: default (all traffic).
- Refreshed the wizard, selected it, and **removed the default SG**.
- It works like the ALB's SG: it controls what can reach the load balancer.
- An SG can be attached at creation or added to an existing NLB later. Once an NLB has an SG, you can't remove all SGs from it.

#### 2.4 Listener and routing

- Listener protocol options: **TCP, UDP, TCP_UDP, TLS**.
- Demo: **TCP : 80**, default action **forward to target group**.
- The NLB doesn't understand HTTP. It passes the TCP stream through, so there are no path or host rules.

#### 2.5 Target group (created inline)

| Setting | Value |
|---|---|
| Target type | **Instances** (others: IP, ALB) |
| Name | `demo-tg-nlb` |
| Protocol : Port | **TCP : 80** |
| VPC | Same VPC as the instances |
| Health check protocol | **HTTP** (options: TCP, HTTP, HTTPS) |
| Healthy threshold | 2 |
| Timeout | 2 s |
| Interval | 5 s |
| Targets | Both EC2 instances, port 80, "Include as pending below" |

- A TCP target group is for an **NLB**. A group with HTTP/HTTPS protocol is for an **ALB**.
- The fast health check settings (5 s interval, threshold 2) are for the demo only, so targets turn healthy quickly. NLB defaults are slower (interval 30 s, thresholds 3).
- HTTP was chosen because the app speaks HTTP. **TCP** would also pass, because it only checks that the port accepts a connection.
- Back in the NLB wizard: **refresh** the dropdown and select `demo-tg-nlb`.

#### 2.6 Finish

- **Create load balancer**, then wait for **Provisioning** to become **Active**.

### 3. The Troubleshooting Moment (High Exam Value)

#### 3.1 Symptoms

- The NLB is **Active**, but its DNS name **doesn't load** in the browser.
- Target group, Targets tab: instances stay in **initial**, then turn **unhealthy** (health checks failed).

#### 3.2 Root cause

The EC2 SG had only one HTTP rule, with **source = the ALB's SG**. Health checks and traffic from the NLB don't carry the ALB SG, so they were dropped.

#### 3.3 Fix

1. EC2 instance, **Security** tab, click the SG (`launch-wizard-1`).
2. **Edit inbound rules, Add rule**: Type **HTTP**, port 80, **Source = `demo-sg-nlb`**.
3. Save and wait a few seconds.
4. Target group: instances go **initial** and then **healthy**.
5. Refresh the NLB DNS name: "Hello World" appears with the instance's IP.
6. Keep refreshing: the IP changes, which proves load balancing across both instances.

#### 3.4 Resulting EC2 SG

| Type | Port | Source | Purpose |
|---|---|---|---|
| SSH | 22 | 0.0.0.0/0 | Admin access (tighten in production) |
| HTTP | 80 | `demo-sg-load-balancer` (ALB SG) | Traffic from the ALB |
| HTTP | 80 | `demo-sg-nlb` (NLB SG) | Traffic and health checks from the NLB |

- Security groups only have **allow** rules, so adding another SG as a source **adds** access.
- Both load balancers can now reach the same instances.

#### 3.5 Troubleshooting checklist for unhealthy targets

1. **Target SG** allows the traffic port and health check port from the LB's SG (most common cause).
2. The health check **port and path** are correct and the app returns the expected code (`200-399` for NLB HTTP checks).
3. The app is **running and listening** on that port.
4. Target group **protocol and port** match what the app serves.
5. If the health check port differs from the traffic port, open that port too.
6. NACLs and routing aren't blocking the traffic.

### 4. Testing Load Balancing

- The NLB DNS name returns "Hello World" from one instance.
- The instance changes **after a while**, not necessarily on every refresh.
  - NLB routes by **flow hash**: the same TCP connection goes to the same target.
  - Browsers reuse keep-alive connections, so you can stay on one target for a bit.
  - A new connection (new tab, private window, or `curl`) can land on the other target.
- ALB balances **per HTTP request**, so it alternates more visibly.
- No `X-Forwarded-For` here. With instance targets, the app sees the client's source IP directly.

### 5. ALB vs NLB: Differences Seen in the Demos

| Aspect | ALB | NLB |
|---|---|---|
| Listener protocols | HTTP, HTTPS | TCP, UDP, TCP_UDP, TLS |
| Target group protocol | HTTP / HTTPS | TCP / UDP / TCP_UDP / TLS |
| Health check protocols | HTTP, HTTPS | TCP, HTTP, HTTPS |
| IP per AZ | Not fixed | **Fixed** (AWS-assigned or Elastic IP) |
| Listener rules (path, host, etc.) | Yes | No |
| Security group | Always | Optional, recommended |
| Balancing unit | Per HTTP request | Per connection (flow hash) |

### 6. Exam-Style Recall

| If the question says... | Think... |
|---|---|
| "Targets behind NLB are unhealthy but the app is running" | **EC2 security group** doesn't allow the NLB SG (or its source IPs) |
| "Only the load balancer should reach the instances" | EC2 SG source = **LB's SG** |
| "Allow both an ALB and an NLB to reach the same instances" | **Two inbound rules**, one per LB SG |
| "Fixed IPs for clients to whitelist" | **NLB + Elastic IPs**, one per AZ |
| "NLB unreachable from the internet" | **NLB SG** inbound rule missing (if an SG is attached) |
| "Health check for an HTTP app behind NLB" | HTTP/HTTPS check is possible, and TCP also works |
| "Refreshing the NLB URL doesn't switch instances every time" | Normal: **flow-hash, per-connection** balancing |
| "Reduce cost after testing" | Delete the load balancer |

### 7. Hands-On Checklist

- [x] Create the NLB (`DemoNLB`): internet-facing, IPv4, 3 AZs
- [x] Note the fixed IP per AZ (or choose an Elastic IP)
- [x] Create SG `demo-sg-nlb` (HTTP 80 from anywhere), attach it, and remove the default SG
- [x] Listener TCP:80 forwarding to a new target group
- [x] Target group `demo-tg-nlb`: instances, TCP:80, HTTP health check (threshold 2, timeout 2 s, interval 5 s)
- [x] Register both instances and create the NLB
- [x] Test the DNS name and observe failure, with targets **unhealthy**
- [x] Add inbound HTTP on the EC2 SG with source = `demo-sg-nlb`
- [x] Wait for **healthy** targets, then refresh the NLB DNS name to see the instance change

---

## Gateway Load Balancer (GWLB)

### TL;DR

- GWLB is the **newest** ELB type (2020). It deploys, scales, and manages a fleet of **third-party virtual network appliances** in AWS.
- Use it to send **all traffic through a firewall, IDS/IPS, or deep packet inspection (DPI)** system before it reaches your application.
- It works at **Layer 3** (IP packets) and has **two functions**: a **transparent network gateway** (single entry and exit) and a **load balancer** (spreads traffic across appliances).
- It uses the **GENEVE protocol on UDP port 6081**. This is the exam keyword for GWLB.
- Target types: **EC2 instances** or **private IP addresses** (including on-premises appliances).
- The lecturer skipped the hands-on. The exam only needs a **high-level understanding of the diagram**.

### 1. What Is a GWLB?

| Property | Detail |
|---|---|
| Purpose | Deploy, scale, and manage **3rd-party network virtual appliances** |
| OSI layer | **3** (network layer, IP packets). The load-balancing part works at layer 4 (flow hashing). |
| Protocol | **GENEVE**, **UDP port 6081** |
| Roles | **Transparent network gateway** + **load balancer** |
| Targets | EC2 instances (by instance ID) or private IPs |
| Launched | 2020 |

**Typical appliances:**
- **Firewalls** (allow or drop traffic)
- **Intrusion detection and prevention systems (IDS/IPS)**
- **Deep packet inspection (DPI)**
- Systems that **modify payloads** at the network level

Vendors sell these as AMIs on the **AWS Marketplace** (for example Palo Alto, Fortinet, Check Point).

### 2. The Problem It Solves

Without GWLB, users reach the app directly:

```
Users --> [ALB] --> Application
```

Requirement: **all network traffic must be inspected first**, by a fleet of third-party appliances. Doing this by hand (routing, scaling, health, failover) used to be very complicated. GWLB makes it simple.

### 3. How It Works (the One Diagram to Remember)

```
                    +--------------------------+
Users --> IGW --> [GWLB endpoint] --> [GWLB] --> Virtual appliances
                                          ^        (firewall / IDS / IPS / DPI)
                                          |               |
                                          +---------------+
                                        (approved traffic returns)
                                                |
                                                v
                                     [GWLB endpoint] --> Application (ALB / EC2)

  Not approved --> appliance DROPS the traffic
```

Step by step:
1. **VPC route tables are updated** so traffic is sent to the GWLB (through a **GWLB endpoint**). This is the networking-heavy part the lecturer mentioned.
2. All user traffic reaches the **GWLB** first.
3. The GWLB **spreads the traffic** across the **target group of virtual appliances**.
4. The appliance **analyzes** the traffic (firewall, IDS, and so on).
   - Approved: it sends the traffic **back to the GWLB**.
   - Not approved: it **drops** the traffic.
5. The GWLB **forwards approved traffic** to the application.
6. To the application this is **transparent**. It just sees normal traffic.

### 4. The Two Functions of a GWLB

| Function | What it means |
|---|---|
| **Transparent network gateway** | Gives the VPC a **single entry and exit point** for all traffic. Source and destination IPs aren't modified ("bump in the wire"). |
| **Load balancer** | **Distributes** traffic across the appliances in the target group and health-checks them |

### 5. GENEVE Protocol

- **GENEVE** (Generic Network Virtualization Encapsulation) wraps the original IP packet and sends it to the appliance, then back.
- Port: **UDP 6081**.
- Appliances must **support GENEVE**.
- **Exam clue:** "GENEVE" or "port 6081" means **Gateway Load Balancer**.

### 6. Target Groups

| Target type | Details |
|---|---|
| **EC2 instances** | Registered by **instance ID** |
| **IP addresses** | Must be **private IPs**. Use this for appliances on your own network or **data center** (over VPN/Direct Connect), registered manually by IP. |

- The target group protocol is **GENEVE**.
- **Health checks** support TCP, HTTP, and HTTPS.
- Appliances can be scaled by putting them in an **Auto Scaling Group**.

### 7. Other Facts to Remember

- **GWLB endpoint (GWLBE):** a VPC endpoint (built on **AWS PrivateLink**) that you put in the route tables to send traffic to the GWLB. The GWLB and appliances can live in a **separate "security" VPC or account** from the applications.
- **Listener:** no protocol or port to choose. It accepts **all IP traffic** and forwards it to the target group.
- **Flow stickiness:** packets of the same flow, in both directions, go to the **same appliance**. Stateful firewalls need this.
- **Cross-zone load balancing** is off by default.
- **Security groups:** GWLB doesn't use them. The **appliances' SG** must allow **UDP 6081** (GENEVE) and the health check port.
- **Pricing:** hourly charge plus **GLCU** (Gateway Load Balancer Capacity Units).
- The lecturer said hands-on is "extremely difficult", so expect **no deep-dive question**. Know what it is and how the traffic flows.

### 8. Comparing the Three Modern ELBs

| Feature | ALB | NLB | GWLB |
|---|---|---|---|
| Layer | 7 | 4 | **3** (+4 for load balancing) |
| Protocols | HTTP, HTTPS, gRPC, WebSocket | TCP, UDP, TLS | **IP packets via GENEVE (UDP 6081)** |
| Main use | Web apps, microservices | Extreme performance, static IPs, TCP/UDP | **Route traffic through 3rd-party appliances** |
| Routing | Path, host, header, query string | Port and protocol | None (transparent forwarding) |
| Target types | Instance, IP, Lambda | Instance, IP, ALB | **Instance, IP** |
| Static/Elastic IP | No | Yes | No |
| Health checks | HTTP, HTTPS, gRPC | TCP, HTTP, HTTPS | TCP, HTTP, HTTPS |

### 9. Exam-Style Recall

| If the question says... | Think... |
|---|---|
| "Route all traffic through a third-party firewall" | **GWLB** |
| "Intrusion detection/prevention or deep packet inspection" | **GWLB** |
| "GENEVE protocol" or "port 6081" | **GWLB** |
| "Deploy and scale a fleet of virtual network appliances" | **GWLB** |
| "Transparent network gateway plus load balancer" | **GWLB** |
| "Layer 3 load balancer" | **GWLB** |
| "Appliances in an on-premises data center as targets" | **IP** target type (private IPs) |
| "Appliance receives traffic, then drops or approves it" | **GWLB** flow |
| "HTTP path-based routing" | **ALB**, not GWLB |
| "Static IPs, UDP, millions of requests/sec" | **NLB**, not GWLB |

---

## Elastic Load Balancer - Sticky Sessions

### TL;DR

- **Sticky sessions (session affinity)** make the load balancer send a client's repeat requests to the **same target**, instead of spreading them.
- Supported on **CLB, ALB, and NLB**. ALB and CLB use **cookies**. NLB uses **source IP** affinity.
- On ALB, stickiness is enabled at the **target group** level and has two cookie types: **duration-based** (`AWSALB`) and **application-based** (`AWSALBAPP` or a custom cookie).
- Duration range: **1 second to 7 days** (default **1 day**).
- Use case: keep the user's **session data** (for example, login) on one backend instance.
- Downside: possible **uneven load** across targets. Stateless design is the better fix.

### 1. What Are Sticky Sessions?

Default behavior: the load balancer spreads requests across all targets.

With stickiness: a client that hit target A keeps going to target A until the stickiness expires.

```
Without stickiness:                 With stickiness:

Client 1 -> ALB -> EC2-A            Client 1 -> ALB -> EC2-A  (always)
Client 1 -> ALB -> EC2-B            Client 2 -> ALB -> EC2-B  (always)
Client 1 -> ALB -> EC2-A            Client 3 -> ALB -> EC2-B  (always)
```

- Lecture example: 1 ALB, 2 EC2 instances, 3 clients. Client 1 always goes to instance 1, and client 2 always goes to instance 2. Client 3 also sticks to one instance.
- When the stickiness **expires**, the client **may be sent to a different** target.

### 2. How It Works

1. The client sends its first request. The ALB picks a target and **returns a cookie** (`Set-Cookie`) with an **expiry**.
2. The browser stores the cookie and **sends it back on every request**.
3. The ALB reads the cookie and routes to the **same target**.
4. When the cookie expires, the ALB picks a target again (possibly a different one).

**Support by load balancer:**

| LB | Supported | Mechanism |
|---|---|---|
| **CLB** | Yes | Cookie (`AWSELB` for duration-based) |
| **ALB** | Yes | Cookie (`AWSALB`, `AWSALBAPP`, or custom) |
| **NLB** | Yes | **Source IP** affinity (no cookies, since it works at layer 4) |
| **GWLB** | Flow-based | Same flow goes to the same appliance (not a cookie feature) |

The lecture says stickiness works with cookies on all three. That is accurate for ALB and CLB, but the NLB has no HTTP awareness, so it can't use cookies.

### 3. Why Use It (and Why Not)

| | Detail |
|---|---|
| **Use case** | Keep the user on the **same backend instance** so **session data** (login, cart) isn't lost |
| **Downside** | **Load imbalance**: a "very sticky" or heavy user can overload one instance |
| **Downside** | If the target **fails or is deregistered**, the session data on it is **lost** and the client is routed to a new target |
| **Downside** | Scaling in or removing instances is harder |
| **Better design** | Make the app **stateless** and store sessions in **ElastiCache** or **DynamoDB** |

### 4. Cookie Types (ALB)

There are two types: **duration-based** and **application-based**.

| | Duration-based | Application-based |
|---|---|---|
| Generated by | The **load balancer** | The **application** (custom) or the **load balancer** (`AWSALBAPP`) |
| Cookie name | **`AWSALB`** (ALB) / **`AWSELB`** (CLB) | **`AWSALBAPP`** (LB-generated) or **your custom name** |
| Expiry | Set by the LB from the configured **duration** | Tied to the application cookie's lifetime, plus the configured duration |
| Console label | "Load balancer generated cookie" | "Application-based cookie" |

**Application-based cookie details:**
- **Custom cookie**: generated by your **target application**. It can carry any custom attributes your app needs.
- The cookie name is specified **per target group**.
- **Reserved names you must not use**: `AWSALB`, `AWSALBAPP`, `AWSALBTG`. The ELB uses these itself.
- **LB-generated application cookie**: created by the ALB using the name `AWSALBAPP`.

**Also worth knowing:** ALB adds `AWSALBCORS` for cross-origin requests when stickiness is on.

**From the lecturer:** you don't need to memorize every cookie name. Know that there are **application-based** and **duration-based** cookies, and that they have specific names. This will matter again with **CloudFront**, where cookies must be forwarded for stickiness to work through the CDN.

### 5. Demo: Enabling Stickiness on an ALB

**Before:** opening the ALB DNS name in a new tab and refreshing bounced between the **3 instances**.

**Steps:**
1. EC2, **Target Groups**, open the target group.
2. **Actions, Edit attributes**.
3. Scroll to **Target selection configuration**, then **Stickiness**, and turn it **on**.
4. Choose the stickiness type:
   - **Load balancer generated cookie** (duration-based), or
   - **Application-based cookie** (LB-generated or custom cookie name, for example `MYCUSTOMCOOKIEAPP`).
5. Set the **duration**: 1 second to 7 days.
6. Demo choice: **Load balancer generated cookie**, default **1 day**. Click **Save changes**.

**Verification:**
1. Open the browser **developer tools**, **Network** tab.
2. Refresh the ALB page repeatedly.
3. The **same instance** answers every time (the lecture showed the same instance ID repeating).
4. Click the `GET` request, then the **Cookies** tab:
   - **Response cookie**: `Set-Cookie` from the ALB, with the expiry (tomorrow), the path, and the value.
   - **Request cookie**: the browser sends that cookie back. This is how stickiness works.

**Undo:** target group, Edit attributes, turn stickiness **off** to return to normal balancing.

### 6. Key Facts to Remember

- Stickiness is configured on the **target group** (ALB) or on the **load balancer** (CLB), not on a listener rule.
- **Duration range: 1 s to 7 days.** Default: **1 day (86,400 s)**.
- If the **target becomes unhealthy or is deregistered**, the ALB routes the client to a **healthy** target and updates the cookie.
- With **weighted forwarding** across multiple target groups, you can also enable **target-group stickiness at the rule level**, so a client stays with the same target group.
- Clients must accept **cookies**. Without them, stickiness doesn't work.
- The **Network tab** in browser dev tools (Chrome and Firefox) is a handy way to inspect the cookies.
- Stickiness helps with session state, but it is a workaround. It isn't real high availability.

### 7. Exam-Style Recall

| If the question says... | Think... |
|---|---|
| "User must return to the same instance to keep session data" | **Sticky sessions** |
| "Users lose their login when routed to another instance" | Enable **stickiness**, or store sessions in **ElastiCache/DynamoDB** |
| "One instance is overloaded while others are idle" | Stickiness causing **imbalance** |
| "Cookie generated by the load balancer with an expiry" | **Duration-based** cookie (`AWSALB`) |
| "Cookie generated by the application" | **Application-based** (custom) cookie |
| "Cookie name reserved by ELB" | `AWSALB`, `AWSALBAPP`, `AWSALBTG` |
| "Stickiness duration limits" | **1 second to 7 days** |
| "Where is stickiness configured on ALB?" | **Target group attributes** |
| "Stickiness on NLB" | **Source IP** affinity, not cookies |
| "Best long-term fix for session loss" | **Stateless app** with an external session store |

---

## Elastic Load Balancer - Cross Zone Load Balancing

### TL;DR

- **Cross-zone load balancing ON**: each load balancer node spreads traffic **evenly across all registered targets in all enabled AZs**.
- **Cross-zone load balancing OFF**: each node sends traffic **only to targets in its own AZ**. If AZs have unequal instance counts, load becomes uneven.
- **Defaults:**
  - **ALB**: always on at the load balancer level (no inter-AZ charge). It can be overridden at the **target group** level.
  - **NLB and GWLB**: **off** by default. Turning it on **incurs inter-AZ data charges**.
  - **CLB**: off in the lecture (console-created CLBs default to on, API/CLI default to off). No inter-AZ charge either way.
- There is **no right or wrong** setting. It depends on the use case.

### 1. Background: Why This Matters

- Each AZ you enable gets **its own load balancer node**.
- The client is sent to the nodes by **DNS**, roughly **50/50** across two AZs, regardless of how many targets sit in each AZ.
- Cross-zone load balancing decides what each node does with the traffic it receives: **only local targets** or **all targets everywhere**.

### 2. The Lecture Example

Setup: **2 AZs**, one LB node per AZ.

| AZ | LB node | EC2 instances |
|---|---|---|
| AZ-A | Node A | **2** |
| AZ-B | Node B | **8** |

Total: **10 instances**. The client sends **50%** of the traffic to Node A and **50%** to Node B.

#### 2.1 Cross-zone ON

```
Client --50%--> Node A --+
                         +--> all 10 instances (AZ-A and AZ-B)
Client --50%--> Node B --+
```

- Each node spreads its traffic across **all 10 instances**.
- Result: **10% per instance** (evenly balanced).

#### 2.2 Cross-zone OFF

```
Client --50%--> Node A --> 2 instances in AZ-A  (25% each)
Client --50%--> Node B --> 8 instances in AZ-B  (6.25% each)
```

- Each node only sends to targets in **its own AZ**.
- AZ-A instances get **25% each**. AZ-B instances get only **6.25% each**.
- Traffic stays **contained within each AZ**, but the imbalance is large.

The lecture states the 25% figure for AZ-A. The AZ-B figure (50% ÷ 8 = 6.25%) follows from the same logic.

#### 2.3 Trade-offs

| | Cross-zone ON | Cross-zone OFF |
|---|---|---|
| Distribution across instances | **Even** | Uneven if AZs have different instance counts |
| Traffic stays in one AZ | No | **Yes** |
| Inter-AZ data cost (NLB/GWLB) | **Yes** | No |
| Latency | Slightly higher (cross-AZ hops) | Slightly lower |
| Resilience | Better: a node can use targets in other AZs | A node only has its own AZ's targets |

- If you turn it **off**, keep the **number of targets per AZ balanced** to avoid hot spots.

### 3. Defaults and Charges by Load Balancer

| Load balancer | Default | Can you change it? | Inter-AZ data charge when cross-zone is on |
|---|---|---|---|
| **ALB** | **On** | **Always on** at the LB level. Override per **target group** (inherit / on / off). | **No charge** |
| **NLB** | **Off** | Yes, edit LB attributes | **Yes** (regional data transfer charges) |
| **GWLB** | **Off** | Yes, edit LB attributes | **Yes** |
| **CLB** | Off per the lecture (console-created: on, API/CLI: off) | Yes | **No charge** |

- Normally, AWS **charges for data moving between AZs**. ALB and CLB are the exceptions, and NLB and GWLB are not.
- Exam shortcut: **ALB = on, free. NLB/GWLB = off, paid if enabled.**

### 4. Demo: Where to Find the Setting

#### 4.1 NLB
1. EC2, **Load Balancers**, select the NLB, **Attributes** tab.
2. **Cross-zone load balancing** shows **Off**.
3. **Edit**, turn it **on**, and save.
4. The console warns that this **may include regional data transfer charges**.

#### 4.2 GWLB
- Same location and behavior: **Attributes**, cross-zone **Off**, edit to turn **on**. Data charges apply.

#### 4.3 ALB
1. Load balancer, **Attributes** tab: cross-zone is **On**.
2. **Edit**: it is shown as **always on** and can't be turned off at this level. The lecturer said an on-screen message there is wrong and can be ignored.
3. Override it at the **target group** instead:
   - Target group, **Attributes**, **Edit**, **Cross-zone load balancing**.
   - Options: **Use load balancer settings** (inherit, the default), **Turn on**, or **Turn off**.
   - This lets you disable cross-zone for **one specific target group** only.

#### 4.4 CLB
- Not demonstrated. It is **previous generation** and being retired, so it is not expected on the exam.

### 5. Key Facts to Remember

- The setting is about **how a node distributes traffic**, not about whether AZs are used at all.
- DNS splits traffic across **AZ nodes**, not across instances. That is why unequal instance counts per AZ matter when cross-zone is off.
- **ALB:** cross-zone is on at the LB level and **can only be turned off per target group**.
- **NLB/GWLB:** enabling cross-zone is a **cost decision** (inter-AZ data transfer).
- **Weighing it up:** even distribution and better use of capacity versus lower latency and lower cost.
- The lecture's tip: delete the demo load balancers when done. NLB and GWLB bill hourly.

### 6. Exam-Style Recall

| If the question says... | Think... |
|---|---|
| "Distribute traffic evenly across all instances in all AZs" | **Enable cross-zone load balancing** |
| "Some instances in one AZ get far more traffic than in another AZ" | **Cross-zone is off** with unequal instances per AZ. Turn it on. |
| "Cross-zone is on by default" | **ALB** |
| "Cross-zone is off by default" | **NLB and GWLB** |
| "Enabling cross-zone incurs inter-AZ data charges" | **NLB / GWLB** |
| "No inter-AZ charge for cross-zone" | **ALB** (and CLB) |
| "Disable cross-zone for a single ALB target group" | **Target group attribute** (turn off, or inherit) |
| "Keep traffic within each AZ to avoid cross-AZ data costs" | Leave cross-zone **off** (NLB) |
| "AZ-A has 2 instances, AZ-B has 8, cross-zone on" | **10% each** |
| "Same setup with cross-zone off" | AZ-A **25% each**, AZ-B **6.25% each** |

---

## Elastic Load Balancer - SSL Certificates

### TL;DR

- An **SSL/TLS certificate** encrypts traffic between clients and the load balancer (**in-flight encryption**). Only the sender and receiver can decrypt it.
- **TLS** is the newer version of **SSL**. Everyone still says "SSL", but the certificates in use today are TLS.
- The load balancer does **SSL/TLS termination**: clients connect over **HTTPS**, and the LB can talk to EC2 over plain **HTTP** inside the private VPC.
- Certificates are managed in **ACM (AWS Certificate Manager)**. You can also **import your own**.
- An **HTTPS listener must have a default certificate**. You can add more certificates to serve multiple domains.
- **SNI (Server Name Indication)** lets one listener serve **multiple certificates**. It works on **ALB, NLB, and CloudFront**, **not on CLB**.
- Exam trigger: "multiple SSL certificates on one load balancer" means **ALB or NLB with SNI**.

### 1. SSL vs TLS

| Term | Meaning |
|---|---|
| **SSL** | Secure Sockets Layer. Older protocol for encrypting connections. Now deprecated. |
| **TLS** | Transport Layer Security. The **newer version** of SSL and what is actually used today. |

- The lecturer says "SSL" on purpose because it's the common term, but "TLS certificate" is the correct name.
- AWS names it both ways: "SSL/TLS certificate", and the NLB listener protocol is called **TLS**.

**In-flight encryption:**
- Data is encrypted while it travels over the network.
- Only the sender and the receiver can decrypt it.
- This protects against eavesdropping (for example, login details and credit card numbers).
- The browser lock icon means the connection is encrypted. Otherwise the browser warns that the site is "not secure".

### 2. Public Certificates and Certificate Authorities

- **Public certificates** are issued by a **Certificate Authority (CA)**.
- Examples from the lecture: Comodo, Symantec, GoDaddy, GlobalSign, DigiCert, Let's Encrypt.
- AWS also issues public certificates itself through **ACM**.
- Certificates have an **expiration date** and **must be renewed** regularly, so a client can trust that the site is authentic.
- The certificate is attached to the **load balancer**, which encrypts the client-to-LB connection.

### 3. How It Works with a Load Balancer

```
Client --HTTPS (encrypted, public internet)--> [Load Balancer]
                                                    |  SSL/TLS termination
                                                    |  (LB decrypts using the certificate)
                                                    v
                          HTTP (unencrypted, private VPC traffic) --> EC2 instances
```

- Users connect over **HTTPS**, and the "S" means it is encrypted with a certificate.
- The load balancer **terminates** the SSL/TLS connection (**SSL termination**) and decrypts the traffic.
- The LB then forwards to the targets over **HTTP** inside the VPC, a private network that is "somewhat secure".
- Benefits of termination:
  - EC2 instances don't need to hold certificates or spend CPU on encryption.
  - Certificates are managed in one place.

**Variations (worth knowing for the exam):**

| Setup | Client to LB | LB to targets |
|---|---|---|
| **Terminate at LB** (lecture default) | HTTPS / TLS | HTTP / TCP |
| **Re-encrypt** (end-to-end encryption) | HTTPS / TLS | HTTPS / TLS (targets need a certificate) |
| **TLS passthrough** (NLB with a **TCP** listener) | Encrypted | Same encrypted stream. The **targets** terminate TLS. |

- An ALB re-encrypting to the targets doesn't validate the target's certificate, so self-signed certificates work.
- Compliance requirements (for example, "encrypt everything in transit") may need **re-encryption or passthrough**.
- The LB's **security group** must allow **inbound 443** for HTTPS.

### 4. The Certificate: X.509 and ACM

- The load balancer loads an **X.509 certificate**, also called an **SSL/TLS server certificate**.
- **ACM (AWS Certificate Manager)** manages these certificates:
  - Request **public** certificates. These are **free** when used with integrated services such as ELB.
  - **Import** your own certificate from a third-party CA. The lecture says you can upload your own to ACM.
  - **Renewal:** ACM-issued public certificates **renew automatically** when domain validation is still valid. **Imported certificates don't**, so you must renew and re-import them yourself.
  - Validation options: **DNS validation** (works well with Route 53) or **email validation**.
- ACM certificates are **regional**. The certificate must be in the **same region** as the load balancer. (For CloudFront it must be in **us-east-1**.)
- ACM wasn't shown in this lecture. It only gave the concept.

### 5. Setting Up an HTTPS Listener

| Setting | Detail |
|---|---|
| **Listener protocol** | **HTTPS** on ALB, **TLS** on NLB (usually port 443) |
| **Default certificate** | **Required.** Used when no other certificate matches, or when the client doesn't send SNI. |
| **Additional certificates** | Optional list of certs for **multiple domains** on the same listener |
| **Security policy** | Defines which TLS versions and ciphers the LB accepts |

**Security policy:**
- Choose a policy on the HTTPS/TLS listener.
- Newer policies accept only modern protocols (TLS 1.2 and 1.3).
- To support **legacy clients** that use older SSL/TLS versions, pick an older policy. That is the lecture's point about "supporting all the versions". It weakens security.

**Common pattern:** listener **HTTP:80** with a **redirect action** to **HTTPS:443** (301), so all traffic ends up encrypted.

### 6. SNI (Server Name Indication)

#### 6.1 The problem

How do you serve **multiple websites, each with its own SSL certificate, from one server or load balancer** (one IP and one port 443)? The server doesn't know which certificate to present until it knows which site the client wants.

#### 6.2 The solution

- **SNI** is a newer extension of the TLS protocol.
- The client **states the hostname it wants** in the **initial handshake**, before any encryption happens.
- The server reads it and **loads the matching certificate**.

#### 6.3 Support

| Supports SNI | Doesn't support SNI |
|---|---|
| **ALB** | **CLB** (older generation) |
| **NLB** | |
| **CloudFront** (covered later in the course) | |

- Not every client supports SNI. Very old clients and browsers don't.
- If a client sends no SNI, the **default certificate** is used.

#### 6.4 Lecture diagram

```
                       +--> Target group: www.mycorp.com
Client --> [ALB] ------+
   HTTPS   | Certs:    +--> Target group: domain1.example.com
           |  - www.mycorp.com
           |  - domain1.example.com
```

1. The client connects and says: "I want `www.mycorp.com`" (SNI).
2. The ALB **selects the `www.mycorp.com` certificate**, encrypts the traffic, and uses a **host-header listener rule** to send it to the matching target group.
3. Another client asking for `domain1.example.com` gets **that** certificate and target group.

So SNI (certificates) and host-based **listener rules** (routing) work together to serve many sites from one ALB.

### 7. Certificate Support by Load Balancer

| Load balancer | Certificates | Notes |
|---|---|---|
| **CLB** | **One** certificate only | For several hostnames with different certificates you need **multiple CLBs** |
| **ALB (v2)** | **Multiple** certificates | Uses **SNI** |
| **NLB (v2)** | **Multiple** certificates | Uses **SNI**, on **TLS** listeners |
| **GWLB** | N/A | Forwards IP packets and doesn't terminate TLS |

- The lecture says "multiple listeners with multiple certificates". More precisely, **one listener can hold a default certificate plus a list of additional ones**, and SNI picks the right one.
- **Wildcard certificates** (`*.example.com`) can cover many subdomains with one certificate.
- Default quota: about **25 additional certificates per ALB** (this can change).

### 8. Key Facts to Remember

- **Termination at the LB** offloads encryption work from the EC2 instances.
- The **default certificate is mandatory** on an HTTPS/TLS listener.
- SNI requires the **newer generation** load balancers.
- ACM auto-renews **only ACM-issued** certificates.
- Certificates must be in the **same region** as the LB.
- Expired certificates cause browser errors, so watch expiry (use ACM's automatic renewal, or CloudWatch/EventBridge alerts for imported certs).
- **CloudFront** is another SNI-capable service and comes up again later in the course.
- SSL terminated on the LB means the **backend sees plain HTTP**. Use `X-Forwarded-Proto` to tell whether the client originally used HTTPS.

### 9. Exam-Style Recall

| If the question says... | Think... |
|---|---|
| "Encrypt traffic between clients and the load balancer" | **HTTPS listener with an SSL/TLS certificate** |
| "Data encrypted while traveling over the network" | **In-flight encryption** |
| "Offload SSL/TLS from the EC2 instances" | **SSL termination** at the load balancer |
| "Where do you manage/renew the certificates?" | **ACM (AWS Certificate Manager)** |
| "Use a certificate bought from a third-party CA" | **Import it into ACM** |
| "Multiple SSL certificates on one load balancer" | **ALB or NLB with SNI** |
| "SNI support" | **ALB, NLB, CloudFront** |
| "Which load balancer doesn't support SNI?" | **CLB** |
| "CLB and multiple domains with different certificates" | **One CLB per certificate** |
| "Required setting on an HTTPS listener" | A **default certificate** |
| "Support old clients with legacy TLS versions" | Choose an older **security policy** |
| "Client tells the server the hostname it wants" | **SNI** |
| "Encrypt all the way to the EC2 instances" | **Re-encrypt** (HTTPS to targets) or **TLS passthrough** on NLB |
| "Force all HTTP users onto HTTPS" | **Redirect action**, port 80 to 443 |

---

## Elastic Load Balancer - Connection Draining

### TL;DR

- **Connection draining** gives a target time to finish its **in-flight requests** while it is being **deregistered** (or, on the CLB, marked unhealthy).
- **Two names for one idea:**
  - **CLB**: **Connection Draining**.
  - **ALB / NLB (and GWLB)**: **Deregistration Delay**.
- While a target is draining, the ELB sends **no new requests** to it. Existing requests can complete, and new ones go to the other targets.
- Range: **1 to 3,600 seconds**. Default: **300 seconds (5 minutes)**. Setting it to **0** disables draining on ALB/NLB.
- Trade-off: **short values** free the instance faster. **Long values** protect long-running requests but delay removal.

### 1. What Is It?

- When an instance is **deregistered** (or, on the CLB, goes unhealthy), the ELB doesn't cut it off immediately.
- The target enters a **draining** state for a set period.
- During that period:
  - Users **already connected** can finish their **in-flight / active requests**.
  - The ELB stops opening **new** connections to that target.
  - New users are routed only to the **other healthy targets**.
- When the period ends, remaining connections are **closed** and the target is fully deregistered.

### 2. Lecture Diagram

```
                +--> EC2 #1 (DRAINING)  <-- existing users finish their requests
Users --> [ELB] +--> EC2 #2 (healthy)    <-- new users go here
                +--> EC2 #3 (healthy)    <-- and here
```

1. Three EC2 instances sit behind the ELB.
2. One instance is set to **draining** (deregistered).
3. Users already connected to it get the **draining period** to finish.
4. Once done (or once the period ends), the connections are shut down.
5. **New** connections never go to the draining instance.

### 3. Names and Where to Configure It

| Load balancer | Feature name | Where it is configured |
|---|---|---|
| **CLB** | **Connection Draining** | On the **load balancer** |
| **ALB** | **Deregistration Delay** | **Target group** attribute |
| **NLB** | **Deregistration Delay** | **Target group** attribute |
| **GWLB** | **Deregistration Delay** | **Target group** attribute |

- Console path for ALB/NLB: **Target Groups**, select the group, **Attributes**, **Edit**, **Deregistration delay**.
- Because it lives on the target group, different target groups on the same ALB can have different delays.

### 4. Configuration

| Setting | Value |
|---|---|
| **Range** | **1 to 3,600 seconds** |
| **Default** | **300 seconds (5 minutes)** |
| **Disable** | Set to **0** (no draining) |

**Choosing a value:**

| Your requests are... | Set the delay... | Why |
|---|---|---|
| **Very short** (under about 1 second) | **Low** (for example 30 s) | The instance drains fast and can be replaced or taken offline sooner |
| **Long-lived** (uploads, long downloads, streaming, WebSockets) | **High** | Gives them time to finish |

- **Trade-off:** a high value keeps the instance around longer. It stays in `draining` until the timer ends, so scale-in, deployments, and replacements take longer.
- Set it to roughly your **longest expected request time**, not the maximum by default.

### 5. Details Worth Knowing

- A deregistering target shows the state **`draining`** in the target group. After the delay it moves to **`unused`**.
- If the target has **no in-flight requests or active connections**, deregistration finishes immediately. The console can still show `draining` until the timer expires.
- Requests that are **still running when the delay expires** are terminated.
- **Auto Scaling:** when an ASG scales in or replaces an instance, it **deregisters it from the target group** first and **waits for the deregistration delay** before terminating it. This keeps users from getting cut off during scale-in.
- **Deployments:** rolling and blue/green deployments (for example CodeDeploy) use the same mechanism to take instances out of service gracefully.
- **New connections vs existing ones:** only **new** requests are redirected. The ELB never moves an in-flight request to another instance.
- **NLB:** connections are long-lived (TCP). The **"connection termination on deregistration"** attribute controls whether the NLB closes remaining connections when the delay ends. It is **off by default**.
- **Unhealthy targets:** on the **CLB**, draining also applies when an instance fails health checks. On ALB/NLB, the delay applies to **deregistration**, and an unhealthy target simply stops receiving new requests.
- **Stateless design:** draining reduces cut-offs but doesn't replace it. Keep session state outside the instance.

### 6. Exam-Style Recall

| If the question says... | Think... |
|---|---|
| "Let in-flight requests finish before an instance is removed" | **Connection draining / deregistration delay** |
| "Users get errors when an instance is terminated during scale-in" | Enable or raise the **deregistration delay** |
| "Connection draining on an ALB or NLB" | **Deregistration delay** |
| "Connection draining on a CLB" | **Connection Draining** |
| "Default draining period" | **300 seconds** |
| "Draining range" | **1 to 3,600 seconds** |
| "Disable draining" | Set the delay to **0** (ALB/NLB) |
| "Very short requests, want fast instance replacement" | **Low value** (for example 30 s) |
| "Long uploads or long-lived requests" | **High value** |
| "What happens to new requests during draining?" | Routed to **other healthy targets** |
| "Where is it configured on an ALB?" | **Target group attributes** |
| "Target state while draining" | **`draining`** |

---

## Auto Scaling Groups (ASG) Overview

### TL;DR

- An **Auto Scaling Group (ASG)** automatically **adds (scale out)** or **removes (scale in)** EC2 instances to match load.
- You set **minimum**, **desired**, and **maximum** capacity. The group size stays within **min to max**.
- ASGs are **free**. You only pay for the resources they create (EC2, EBS, and so on).
- **ASG + load balancer**: new instances are registered with the LB automatically, and traffic is spread to them.
- **Self-healing**: an unhealthy instance is **terminated and replaced**. The ELB health check can be used for this, but it must be enabled.
- Instances are launched from a **launch template**. Launch configurations are **deprecated**.
- Automatic scaling is driven by **scaling policies** that react to **CloudWatch alarms** (for example, average CPU).
- ASGs scale **horizontally** only (instance count). They never resize an instance.

### 1. What Is an ASG?

- Website or app load **changes over time**. In AWS, servers can be created and destroyed in minutes through the EC2 API, so this can be automated.
- The ASG's goals:
  - **Scale out**: add EC2 instances when load increases.
  - **Scale in**: remove EC2 instances when load decreases.
  - Keep the count between a **minimum** and a **maximum**.
  - **Register instances with a load balancer** automatically.
  - **Replace unhealthy instances** automatically.
- The size of the ASG **varies over time**.
- **Cost:** the ASG itself is **free**. You pay for the instances and other resources it launches.
- An ASG is **regional**. It can span **multiple AZs** (through the subnets you choose) and it **rebalances** across them.

### 2. Capacity Settings

| Setting | Meaning | Lecture example |
|---|---|---|
| **Minimum capacity** | The fewest instances the ASG will ever run | **2** |
| **Desired capacity** | The number the ASG **tries to run right now** | **4** |
| **Maximum capacity** | The most instances the ASG will ever run | **7** |

```
Min 2 <-- desired 4 --> scale out up to --> Max 7
```

- **Rule:** `min <= desired <= max`.
- Raising the desired capacity (still below max) makes the ASG **scale out**. Lowering it makes the ASG **scale in**.
- Scaling policies change the **desired capacity** for you. You can also set it **manually**.
- If an instance dies, the ASG launches a replacement to get back to the desired capacity.
- **Initial capacity** is the desired capacity the group starts with.

### 3. ASG + Load Balancer

```
Users --> [ELB] --> EC2 (in ASG)
                    EC2 (in ASG)
                    EC2 (in ASG)   <-- ASG registers/deregisters these
                    EC2 (in ASG)      and can use ELB health checks
```

- Instances in the ASG are **linked to the load balancer's target group**. The ASG **registers them automatically** as it scales.
- The ELB spreads traffic across all instances **right away**, so users see one load-balanced site.
- On **scale out**, new instances get traffic automatically. On **scale in**, instances are **deregistered** first (**deregistration delay** applies), then terminated.
- **Health checks:**
  - The ELB health-checks each instance.
  - The ASG can use this result and **terminate instances the ELB marks unhealthy**.
  - A new instance is launched to replace it.

| ASG health check type | What it checks | Notes |
|---|---|---|
| **EC2** (default) | Instance state and EC2 status checks | An app crash is not detected |
| **ELB** (optional) | The load balancer's target health | Must be **turned on** in the ASG. Catches app-level failures. |
| **Custom** | Your own signal (through the API) | For special cases |

- The **health check grace period** (default **300 s**) gives a new instance time to boot before health checks can fail it.

### 4. Launch Template

An ASG needs a **launch template** that describes **how to launch instances**.

| Launch template contains | Examples |
|---|---|
| **AMI** | Amazon Linux 2023, a custom AMI |
| **Instance type** | `t3.micro` and others |
| **EC2 user data** | Bootstrap script |
| **EBS volumes** | Root and extra volumes |
| **Security groups** | Firewall rules |
| **SSH key pair** | Optional |
| **IAM role** (instance profile) | Permissions for the instances |
| **Network settings** | Network interfaces, public IP setting |

- These are the **same parameters** you give when launching an EC2 instance by hand.
- **Launch configurations** are the older mechanism. They are **deprecated**, and AWS recommends **launch templates**. The idea is the same, but templates are **versioned** and support newer features (mixed instance types, Spot and On-Demand mix, and so on).
- Settings on the **ASG itself** (not in the template): **min / desired / max**, **subnets/AZs**, **load balancer target group**, **health check type**, and **scaling policies**.
- **Mixed instances policy:** an ASG can combine several instance types and **On-Demand + Spot** in one group.

### 5. Scaling Policies and CloudWatch Alarms

- An ASG can scale in and out based on **CloudWatch alarms**.
- Flow:

```
CloudWatch metric (for example, average CPU of the ASG)
        |
        v
   [Alarm fires]  (threshold breached)
        |
        v
   Scaling policy --> ASG changes desired capacity
        |                 (scale OUT: add instances)
        v                 (scale IN: remove instances)
```

- Example from the lecture: an ASG with **3 instances** has high average CPU, the **alarm is triggered**, and the ASG **scales out**.
- The metric can be **average CPU**, **network in/out**, **request count per target**, or any **custom metric**.
- **Auto** scaling is the combination of a **policy + alarm**, with no manual work.
- You can define **scale-out policies** (add instances) and **scale-in policies** (remove instances).

**Types of scaling policies (a preview of the next lectures):**

| Type | Idea |
|---|---|
| **Target tracking** | Keep a metric near a target (for example, average CPU at 50%). Simplest option, and it creates the alarms for you. |
| **Simple / step scaling** | Add or remove instances when a CloudWatch alarm fires. Step scaling varies the amount by how far the metric is from the threshold. |
| **Scheduled** | Scale at known times (for example, a sale on Friday at 9 am) |
| **Predictive** | Uses machine learning on history to scale ahead of the load |

### 6. Key Facts to Remember

- ASG = **horizontal scaling only**. Vertical scaling (bigger instance) is manual.
- The ASG is **free**. The EC2 instances, EBS volumes, and load balancer are not.
- `min <= desired <= max`, and the ASG never goes outside min or max.
- An ASG **replaces unhealthy instances**. Turn on the **ELB health check type** so it reacts to app failures.
- **Instances launched by an ASG can be terminated by it.** Store no state on them (use S3, EBS snapshots, RDS, ElastiCache, and so on).
- The **launch template** defines what gets launched. **Launch configurations are deprecated.**
- The ASG **registers and deregisters instances** with the target group automatically.
- Spreading instances over **multiple AZs** gives high availability, and the ASG **rebalances** them.
- **Cooldown** (default **300 s**) stops the ASG from launching or terminating again before the last action has had effect.
- Default **scale-in** choice: the ASG terminates an instance in the AZ with the **most instances** first, to keep the AZs balanced.
- Related features to know by name: **instance refresh** (rolling replace to a new AMI), **lifecycle hooks** (run actions at launch or terminate), and **warm pools** (pre-initialized instances).

### 7. Exam-Style Recall

| If the question says... | Think... |
|---|---|
| "Automatically add or remove EC2 instances with load" | **Auto Scaling Group** |
| "Add instances to handle more load" | **Scale out** |
| "Remove instances when load drops" | **Scale in** |
| "Minimum and maximum number of instances" | ASG **min / max capacity** |
| "How many instances the ASG is trying to run now" | **Desired capacity** |
| "Replace instances that fail health checks" | **ASG self-healing** |
| "Replace instances that fail application health checks" | ASG health check type = **ELB** |
| "Register new instances with the load balancer automatically" | **ASG attached to a target group** |
| "Defines AMI, instance type, user data, SGs, IAM role for the ASG" | **Launch template** |
| "Launch configuration" | **Deprecated**, use a launch template |
| "Scale based on average CPU" | **CloudWatch alarm + scaling policy** (or **target tracking**) |
| "Cost of using an ASG" | **Free**. Pay only for the resources. |
| "Scale to a schedule / ahead of a known spike" | **Scheduled scaling** |
| "Make an instance bigger automatically" | Not an ASG feature (**vertical** scaling) |

---

## Auto Scaling Groups Hands On

### TL;DR

- Created a **launch template** (`my demo template`) and an **ASG** (`Demo ASG`) attached to the existing ALB target group (`demo-tg-alb`).
- The ASG launched an instance by itself to reach the **desired capacity (1)**. The instance registered in the target group, turned **healthy**, and the ALB served "Hello World".
- **Health checks:** enabled both **EC2** and **ELB** types, so the ASG replaces instances the load balancer marks unhealthy.
- **Scale out:** set desired to **2** (raising max to 2 first). The ASG launched a second instance, and the ALB alternated between two IPs.
- **Scale in:** set desired back to **1**. The ASG picked one instance, deregistered it from the target group, and terminated it.
- The **Activity** tab (activity history) is where you see why the ASG launched or terminated instances.

### 1. Prerequisite

- **Terminate all existing EC2 instances** so you start with zero running.
  - The ASG will create the instances it needs.
  - Leftover manual instances would also sit in the target group unmanaged.
- Reuse from earlier demos:
  - The **ALB** and target group `demo-tg-alb`.
  - The SG `launch-wizard-1`, which already allows HTTP **from the ALB SG**.
  - The **user data** script (web server returning "Hello World").

### 2. Step 1: Create the Launch Template

EC2, Auto Scaling Groups, **Create Auto Scaling group**, name it `Demo ASG`, then **Create a launch template**.

| Setting | Value used | Notes |
|---|---|---|
| Name / description | `my demo template` / "templates" | Launch templates are **versioned**. This is **version 1**. |
| AMI | Amazon Linux 2 (x86), free tier eligible | AL2 is reaching end of support. Use **Amazon Linux 2023** for new work. |
| Instance type | `t2.micro` | Free tier eligible |
| Key pair | `EC2 tutorial` | Optional. Not needed if you use EC2 Instance Connect or SSM. |
| Subnet | **Not in the launch template** | Chosen on the **ASG** |
| Security group | Existing `launch-wizard-1` | |
| Storage | 8 GB gp2 | Default |
| User data | The same web server script from before | Every instance the ASG launches becomes a web server |

- The options mirror what you set when launching a single EC2 instance. The template stores them so the ASG can launch **identical instances** repeatedly.
- Click **Create launch template**, go back to the ASG wizard, **refresh** the dropdown, and select `my demo template` **Version 1**.

### 3. Step 2: Instance Launch Options

| Setting | Value | Notes |
|---|---|---|
| **Instance type requirements** | **Reset to launch template** (`t2.micro` only) | You can override the template with multiple instance types (mixed instances, Spot and On-Demand). It is an advanced option. |
| **VPC / subnets** | The default VPC, **multiple AZs** | The ASG decides the subnets. The template doesn't. |
| **AZ distribution** | **Balanced best effort** | Spreads instances evenly across AZs. If an AZ can't launch, it tries another. |

### 4. Step 3: Integrate with the Load Balancer

- **Attach to an existing load balancer**, choose **target group**, and select `demo-tg-alb`.
  - The ASG registers every instance it launches in this target group, and deregisters instances it terminates.
  - You attach a **target group** (for ALB/NLB), not the ALB itself.
- **VPC Lattice** integration and **zonal shift**: left alone (not needed).
- **Health checks:** turned on **EC2 health checks** *and* **Elastic Load Balancing health checks**.
  - The ASG can now **terminate instances that the load balancer reports unhealthy**.
  - The **health check grace period** (default **300 s**) gives new instances time to boot before they can be failed.

### 5. Step 4: Group Size and Scaling

| Setting | Value | Notes |
|---|---|---|
| **Desired capacity** | **1** | |
| **Min capacity** | **1** | |
| **Max capacity** | **1** | Raised to 2 later in the demo |
| **Automatic scaling** | **None** | Scaling policies come in the next lecture |
| **Instance maintenance policy** | **No policy** | Default. Controls how replacements happen (availability versus cost). |
| **Additional capacity settings** | Defaults | |
| **Notifications, tags** | None | |

- Review everything and click **Create Auto Scaling group**.

### 6. What Happens After Creation

1. Open the ASG. The **Details** tab shows the **desired, min, and max** capacity and the launch template used.
2. Open the **Activity** tab. After a refresh the **activity history** shows **"Launching a new EC2 instance"**.
   - The ASG had **0 instances** but wanted **1**, so it launched one to match the desired capacity.
3. **Instance management** tab: one instance created by the ASG.
4. **EC2, Instances:** the instance shows **running / initializing**.
5. **Target group, Targets tab:**
   - The instance is registered automatically.
   - It shows **unhealthy** at first because it is still **bootstrapping** (user data running).
   - After a while it turns **healthy**.
6. **ALB DNS name**: shows "Hello World".

Chain to remember:
```
ASG -> launches EC2 (launch template) -> registers in target group -> ALB routes traffic
```

### 7. If the Instance Never Becomes Healthy

- Because the ASG has **ELB health checks enabled**, an instance that keeps failing is **terminated and a new one is launched** (a loop). You see this in the **activity history**.
- The cause is a **misconfigured instance**, usually one of:
  - **Security group**: the EC2 SG doesn't allow the ALB SG (or the health check port).
  - **User data script**: the web server didn't install or start.
- Check both before asking for help.
- Other checks: the AMI/user data matches the target group's port and health check path, and the health check grace period is long enough for the boot time.

### 8. Demo: Scale Out (1 to 2)

1. ASG, **Details**, **Group details**, **Edit**.
2. Set **desired capacity = 2**. Also raise **max capacity to 2**, otherwise the update is rejected.
   - Rule: `min <= desired <= max`.
3. Save and open the **Activity** tab. It shows "Launching a new EC2 instance", because the **desired changed from 1 to 2** while the **actual count was 1**.
4. The second instance appears, registers in the target group, and turns **healthy** after bootstrapping.
5. Refresh the **ALB URL**: **two different IPs** alternate, so both instances serve traffic.
6. Activity history shows both launches as **successful**.

### 9. Demo: Scale In (2 to 1)

1. Edit the ASG and set **desired capacity = 1**. Update.
2. The ASG sees 2 instances but needs 1, so it **picks one and terminates it**.
   - Activity message: it is terminating an instance because of a change in the ASG configuration.
   - The instance is first **deregistered from the target group** (the **deregistration delay** applies, so in-flight requests can finish), and then terminated.
3. The ASG ends with **1 instance**.

- **Which instance is terminated?** The **default termination policy** favors the AZ with the most instances first, then applies further tie-breakers (such as the oldest launch template version or instance). You don't choose it manually.
- Manually changing desired capacity is one of several triggers. Scaling policies (next lecture) do this automatically.

### 10. Key Facts to Remember

- An ASG **creates instances to match the desired capacity**, and it does this from the **launch template**.
- **Subnets/AZs and the target group** are set on the **ASG**. The launch template holds AMI, instance type, user data, SG, key pair, IAM role, and storage.
- The ASG **auto-registers** instances in the attached **target group** and **deregisters** them on termination.
- Health check types: **EC2** (default) and **ELB** (optional, enable it to catch application failures). The demo turned on both.
- **Self-healing:** unhealthy instances are **terminated and replaced**.
- To scale manually, change **desired capacity** (and **max** if needed).
- **Activity history** (Activity tab) explains every launch and termination and is the first place to debug.
- **Newly launched instances show `unhealthy` briefly** while user data runs. That is normal, not an error.
- **Terminating an ASG instance by hand** makes the ASG launch a replacement, since the count drops below desired.
- **Deleting the ASG** terminates its instances.

### 11. Exam-Style Recall

| If the question says... | Think... |
|---|---|
| "ASG launches instances with the same configuration each time" | **Launch template** |
| "Where do you choose subnets/AZs for an ASG?" | On the **ASG**, not the launch template |
| "Attach ASG instances to a load balancer" | Attach the **target group** to the ASG |
| "ASG replaces instances that fail app-level checks" | Enable **ELB health checks** on the ASG |
| "Set desired above max" | Not allowed. Raise **max** first (`min <= desired <= max`). |
| "Spread instances across AZs evenly" | **AZ distribution: balanced best effort** |
| "Why did the ASG launch or terminate an instance?" | **Activity history** |
| "New instance keeps being terminated and replaced" | Failing health checks: check the **SG** and **user data** |
| "What determines how many instances run right now?" | **Desired capacity** |
| "Scale in: which instance is removed?" | The **termination policy**, by default from the AZ with the most instances |
| "Instances terminate mid-request during scale-in" | Increase the **deregistration delay** |
| "Manual instances still running when the ASG is created" | They are **not** managed by the ASG |

### 12. Hands-On Checklist

- [x] **Terminate** all running EC2 instances
- [x] Create the launch template `my demo template`: AL2/AL2023, `t2.micro`, SG, user data (no subnet)
- [x] Create ASG `Demo ASG` and select the template (version 1)
- [x] Instance launch options: reset instance types to the template, multiple AZs, **balanced best effort**
- [x] Attach the existing target group `demo-tg-alb`
- [x] Enable **EC2 + ELB health checks**
- [x] Set **desired = min = max = 1**, no scaling policies, no notifications, then create
- [x] Check **Activity**, **Instance management**, and **EC2, Instances** for the new instance
- [x] Wait for the target to become **healthy**, then open the ALB URL and see "Hello World"
- [x] Edit the group: **desired 2, max 2**, then verify the second instance and two alternating IPs
- [x] Edit the group: **desired 1**, then verify that one instance is deregistered and terminated

---

## Auto Scaling Groups - Scaling Policies

### TL;DR

- Four kinds of scaling policy: **target tracking**, **simple/step scaling**, **scheduled scaling**, and **predictive scaling**. The first two are **dynamic** (they react to metrics).
- **Target tracking** is the easiest. Pick a metric and a target value (for example, average CPU at **40%**), and the ASG scales out and in to hold it there.
- **Simple/step scaling** uses **CloudWatch alarms** you define to add or remove capacity.
- **Scheduled scaling** is for **known patterns** (for example, raise min capacity to 10 every Friday at 5 pm).
- **Predictive scaling** uses **historical load to forecast** and schedules capacity **ahead of time**. It suits cyclical patterns.
- Common scaling metrics: **average CPU utilization**, **`RequestCountPerTarget`** (ALB), **average network in/out**, and **custom CloudWatch metrics**.
- **Cooldown**: default **300 s (5 min)**. After a scaling activity, the ASG waits so metrics can stabilize.
- Speed tip: use a **ready-to-use (golden) AMI** so instances serve traffic sooner, and turn on **detailed (1-minute) monitoring**.

### 1. The Four Types of Scaling Policy

| Type | Category | Idea | Best for |
|---|---|---|---|
| **Target tracking** | Dynamic | Keep a metric near a target value | Most workloads. Simplest option. |
| **Simple / Step scaling** | Dynamic | CloudWatch alarm fires, then add/remove capacity | Custom control over thresholds and amounts |
| **Scheduled scaling** | Scheduled | Change capacity at set times | **Predictable, known** usage patterns |
| **Predictive scaling** | Predictive | ML forecast of load, then scale **before** it arrives | **Recurring/cyclical** patterns |

- All policies work within the group's **min and max**. The ASG never goes outside them.
- You can combine policies. For example, predictive plus target tracking is a common pairing.

### 2. Target Tracking Scaling

- You choose a **metric** and a **target value**. Example: average CPU utilization = **40%**.
- The ASG then **scales out** when the metric goes above the target and **scales in** when it drops below, to keep it **around 40%**.
- **Behind the scenes:** the ASG **creates and manages the CloudWatch alarms** for you. There is no alarm setup, and you shouldn't edit those alarms by hand.
- It scales out **aggressively** and scales in **conservatively**, to protect availability.

**Predefined metrics:**

| Metric | Meaning |
|---|---|
| **`ASGAverageCPUUtilization`** | Average CPU across the group |
| **`ASGAverageNetworkIn`** | Average bytes in per instance |
| **`ASGAverageNetworkOut`** | Average bytes out per instance |
| **`ALBRequestCountPerTarget`** | Average requests per target from the ALB |

- You can also use a **custom metric**. It must **change in inverse proportion** to the number of instances. Average requests per instance works, and total requests does not.

### 3. Simple / Step Scaling

- **You define the CloudWatch alarms**. When an alarm fires, the ASG adds or removes **units of capacity**.
- Example: an alarm at CPU above **70%** adds **2 instances**, and another at CPU below **30%** removes **1 instance**.

| | Simple scaling | Step scaling |
|---|---|---|
| Action | **One fixed adjustment** per alarm | **Different adjustments by breach size** (steps) |
| Example | CPU > 70%: add 2 | CPU 60-70%: add 1, 70-80%: add 2, over 80%: add 4 |
| Waits after acting | **Cooldown** period | **Instance warmup**, so it can keep reacting to the alarm |
| Recommended? | Older option | **Preferred** over simple scaling |

- **Adjustment types:** change in capacity (+/- N), **exact** capacity, or **percent** change.
- These need **more setup** than target tracking, but give **finer control**.

### 4. Scheduled Scaling

- Use it when you **anticipate load** from a known pattern.
- Lecture example: "Every **Friday at 5 pm** more users arrive, so raise the **minimum capacity to 10**."
- You define a **schedule** (one-time or recurring **cron**) and set the group's **min, max, and desired** values.
- It is **time-based**, not metric-based. It can run alongside dynamic policies, which then handle anything unexpected.
- Good for: sales events, business hours, batch windows, and launch days.

### 5. Predictive Scaling

- The ASG **continuously forecasts load** and **schedules scaling actions ahead of time**.
- How it works:
  1. It **analyzes historical load** (CloudWatch data).
  2. It **generates a forecast**.
  3. It **schedules scaling actions** based on the forecast.
- Best for **cyclical, repeating** patterns (daily or weekly cycles).
- It **needs history**: at least **24 hours** of data. It uses up to **14 days** and forecasts **48 hours** ahead.
- **Forecast only** mode lets you check the predictions **before** letting it scale.
- Because it scales **before** the load, instances are ready when users arrive. This helps when instances take a while to start.

### 6. Which Metric Should You Scale On?

"It depends on the application", but these are the usual choices:

| Metric | Why it works | Use when |
|---|---|---|
| **Average CPU utilization** | Each request takes some computation. Higher average CPU means the instances are busier. | **CPU-bound** apps. The default choice. |
| **`RequestCountPerTarget`** | Load is measured per instance, straight from the ALB. | You know from **load testing** how many requests one instance handles well (for example 1,000). Set that as the target. |
| **Average network in / out** | Catches **network bottlenecks** | **Network-bound** apps (large uploads and downloads) |
| **Custom metric** | Any application-specific signal, pushed to **CloudWatch** | Queue depth, active sessions, business metrics |

**`RequestCountPerTarget` example:**
- The ASG has **3 instances** behind an ALB, and requests are spread across all of them.
- The lecture says the metric value is **3**, because each instance averages about 3 requests.
- The metric is really the **average number of requests per target per minute**. The lecture calls them "outstanding requests", which is a looser description.
- If the target is 1,000 per instance and the value rises above it, the ASG scales out.

**Custom metrics:**
- Publish your own metric to **CloudWatch** (for example, with `PutMetricData`), then use it in a target tracking or step scaling policy.
- Example: **SQS queue length per instance**, the classic worker-fleet metric.

### 7. Scaling Cooldown

- After a scaling activity (instances added or removed), the ASG enters a **cooldown period**.
- **Default: 300 seconds (5 minutes).**
- **During cooldown, the ASG doesn't launch or terminate additional instances.**
- **Why:** it gives time for the new instance to come up and take load, and for **metrics to stabilize**, so the ASG doesn't over-react to stale numbers.

**Decision flow from the lecture:**

```
Scaling action requested
        |
        v
Is the default cooldown in effect?
   |                        |
  Yes                      No
   |                        |
Ignore the action     Proceed: launch or terminate instances
```

- The default cooldown mainly applies to **simple scaling** policies. **Target tracking** and **step scaling** use **instance warmup** instead.
- The cooldown can also be set **per policy**.
- The value trades off **stability** (longer) against **responsiveness** (shorter).

### 8. Making Scaling Faster and More Responsive

1. **Use a ready-to-use AMI (golden AMI).**
   - Bake the application and dependencies into the AMI. Don't install them at boot with user data.
   - **Less configuration time** means new instances serve requests sooner.
   - Because instances become effective faster, you can **shorten the cooldown** and get **more dynamic scaling**.
2. **Enable detailed monitoring.**
   - **Basic monitoring** publishes metrics every **5 minutes**. **Detailed monitoring** publishes every **1 minute**, at extra cost.
   - Faster metric updates mean quicker reactions. Enable **detailed monitoring** on the instances (launch template) and **group metrics collection** on the ASG (1-minute granularity).
3. Tune the **health check grace period** and **instance warmup** to match your real startup time.

### 9. Key Facts to Remember

- **Target tracking** = pick a metric and a target, and AWS handles the alarms. It is the simplest and recommended default.
- **Step scaling** is preferred over **simple scaling**. Both need **your CloudWatch alarms**.
- **Scheduled** = known times. **Predictive** = forecast from history. **Dynamic** = reacts to live metrics.
- The **default cooldown is 300 s**, and it prevents scaling thrash.
- **Never scales outside min/max.** Scheduled actions can change min and max themselves.
- If **several policies** fire at once, the ASG follows the one that gives the **largest capacity** for scale-out.
- **CPU** is the general-purpose metric. **`ALBRequestCountPerTarget`** needs an ALB or a target group. **Network** is for I/O-heavy apps.
- **Custom metrics** are pushed to **CloudWatch**.
- Scaling policies only change **instance count** (horizontal), never instance size.

### 10. Exam-Style Recall

| If the question says... | Think... |
|---|---|
| "Keep average CPU at 40%" | **Target tracking** |
| "Simplest way to scale automatically" | **Target tracking** |
| "Add 2 instances when an alarm fires" | **Simple / step scaling** |
| "Different scaling amounts depending on how high the metric is" | **Step scaling** |
| "Traffic spike every Friday at 5 pm" | **Scheduled scaling** |
| "Known event date (sale, launch)" | **Scheduled scaling** |
| "Recurring daily or weekly pattern, scale ahead of time" | **Predictive scaling** |
| "Forecast load from history" | **Predictive scaling** |
| "Scale on requests per instance behind an ALB" | **`ALBRequestCountPerTarget`** |
| "Upload/download-heavy app, network bottleneck" | **Average network in/out** |
| "Scale on queue length or a business metric" | **Custom CloudWatch metric** |
| "Prevent the ASG from adding instances too quickly" | **Cooldown** (default **300 s**) |
| "Instances take long to become useful, so scaling is slow" | Use a **golden AMI** and shorten the cooldown |
| "Metrics update too slowly" | Enable **detailed monitoring** (1-minute) |
| "Which policy needs you to create the alarms?" | **Simple / step scaling** |
| "Scale to a size beyond the maximum" | Not possible. Raise **max capacity** first. |

---

## Auto Scaling Groups - Scaling Policies Hands On

### TL;DR

- The ASG's **Automatic scaling** tab has three categories: **dynamic scaling policies**, **predictive scaling policies**, and **scheduled actions**.
- **Scheduled actions** and **predictive scaling** were only walked through, not demoed. Predictive scaling needs days of history.
- The demo built a **target tracking** policy: **average CPU utilization = 40%**. AWS **created two CloudWatch alarms** for it (`AlarmHigh` to scale out, `AlarmLow` to scale in).
- Load was generated with the **`stress`** tool on an instance. CPU hit 100%, `AlarmHigh` fired, and the ASG scaled **1 to 2 to 3** instances (capped by max = 3).
- After the load stopped (instances rebooted), `AlarmLow` fired after about 15 minutes and the ASG scaled back **3 to 2 to 1**.
- **Scale out is fast and scale in is slow**. This is deliberate.

### 1. The Automatic Scaling Tab

| Category | What it is | Demoed? |
|---|---|---|
| **Scheduled actions** | Change min/desired/max at set times | Walked through |
| **Predictive scaling policies** | ML forecast from past load, scales ahead of time | Walked through |
| **Dynamic scaling policies** | React to live metrics: target tracking, step, simple | **Yes (target tracking)** |

### 2. Scheduled Actions (Walkthrough)

- Use them for events you **know in advance**. Lecture example: a big promotion **next Saturday**.
- Settings on a scheduled action:
  - **Desired**, **min**, and **max** capacity to apply.
  - **Recurrence**: once, or repeating (hourly, daily, weekly, monthly, or a **cron** expression).
  - **Start time** and optional **end time**. A **time zone** can be set.
- It is **time-based**, not metric-based. It runs alongside dynamic policies.
- Example: every Friday at 5 pm, set **min = 10**.

### 3. Predictive Scaling (Walkthrough)

- **Machine-learning driven.** It looks at **past load**, builds a **forecast**, and scales **before** the load arrives.
- You pick:
  - A **metric**: **CPU utilization**, **network in**, **network out**, **ALB request count per target**, or a **custom metric**.
  - A **target value**, for example **50% CPU**.
  - Optional extra settings.
- Modes:
  - **Forecast only**: generates forecasts so you can check them, but doesn't scale.
  - **Forecast and scale**: acts on the forecast.
- Why it wasn't demoed: it needs **history**. The lecturer would have to run it for about a week with real traffic. AWS's minimum is **24 hours** of data, and it uses up to **14 days**.
- It suits **cyclical, repeating** patterns.

### 4. Dynamic Scaling Policy Types (Console Tour)

| Type | How you configure it |
|---|---|
| **Target tracking** | Name, **metric**, **target value**. AWS creates the alarms. **This is the one demoed.** |
| **Step scaling** | Name, **your CloudWatch alarm**, and **steps** by how far the metric is from the threshold. Example: very high, add 10. High, add 1. |
| **Simple scaling** | Name, **your CloudWatch alarm**, and **one action**: add/remove N capacity units, set exact capacity, or change by a percentage. |

**Simple scaling details from the lecture:**
- The **alarm must exist beforehand**. You select it in the policy.
- Action example: **add 2 capacity units**, or **add 10% of the group**.
- "Add capacity units in increments of at least 2" is the **minimum adjustment magnitude**. It applies to percentage changes.
- Actions can be **scale out** (add), **scale in** (remove), or **set to** an exact size.

**Step scaling** is preferred over simple scaling today. Both need you to create the alarms.

### 5. Demo: Target Tracking on CPU

#### 5.1 Create the policy

1. ASG, **Automatic scaling** tab, **Create dynamic scaling policy**.
2. Policy type: **Target tracking scaling**.
3. Name: `target tracking policy`.
4. Metric type: **Average CPU utilization**. **Target value: 40**.
5. Create.

The ASG now tries to **keep average CPU near 40%**.

#### 5.2 Allow room to scale

- The group was **min = desired = max = 1**, so it couldn't grow.
- Edit the group and set **max capacity = 3** (lecturer: "three or two, whatever").
- Rule: `min <= desired <= max`. The policy changes the **desired** capacity, and never goes above **max**.
- Baseline: CPU is about **0%** because the instance is idle.

#### 5.3 Generate load with `stress`

1. EC2, select the instance, **Connect**, **EC2 Instance Connect**.
2. Install the tool (Amazon Linux 2):
```bash
   sudo amazon-linux-extras install epel -y
   sudo yum install -y stress
```
   On **Amazon Linux 2023** there is no `stress` package. Use `sudo dnf install -y stress-ng`, then `stress-ng --cpu 4`.
3. Run:
```bash
   stress -c 4
```
   - `-c 4` starts **4 CPU workers**, which drives the CPU to about **100%**. The transcript says `-C`, but the flag is a **lowercase `-c`**.
4. Wait for CloudWatch to collect enough metrics (the video is paused here).

#### 5.4 Scale out

- **Activity history** shows an alarm triggered and, due to the **target tracking policy**, capacity went **1 to 2**.
- **Instance management** shows **2 instances**.
- **Monitoring** tab: CPU jumped very high, then scaling happened.
- The CPU was still high, so capacity went **2 to 3** and a **third instance** was added.

**Why it went to 3:** target tracking works on the **group average**. One instance at 100% CPU plus one idle new instance averages **50%**, which is still above 40%. With three instances the average is about **33%**, which is below the target, so it stops.

#### 5.5 The alarms behind the scenes

CloudWatch, **Alarms**: **two alarms were created by the policy**.

| Alarm | Purpose | Condition (approx.) |
|---|---|---|
| **`AlarmHigh`** | **Scale out** (add instances) | CPU **above 40%** for **3 datapoints within 3 minutes** |
| **`AlarmLow`** | **Scale in** (remove instances) | CPU **below 28%** for **15 datapoints within 15 minutes** |

- The lecture says "20 eights", which is a caption error for **28%**. The scale-in threshold is roughly **70% of the target** (40 x 0.7 = 28).
- **Don't edit or delete these alarms by hand.** They belong to the policy. Deleting the policy removes them.
- Alarm view: CPU rose, `AlarmHigh` went to **In alarm**, and the scaling activity followed.

#### 5.6 Scale in

1. Stop the load. The lecturer **rebooted** the stressed instances, which kills the `stress` process. `Ctrl+C` in the terminal also works.
2. CPU fell to near **0%**.
3. `AlarmLow` (15 minutes of low CPU) went into alarm and the ASG scaled **3 to 2, then 2 to 1**.
4. **Instance management** showed one instance already terminated and another **terminating**.
5. The CPU graph showed it rising, then falling below the low threshold, then the scale-in.

**Scale-in is slower than scale-out** (3 minutes versus 15 minutes). This protects availability. Scale-in also respects the **deregistration delay** and the ASG's **termination policy**.

### 6. Key Facts to Remember

- **Target tracking** creates and manages its own CloudWatch alarms (`AlarmHigh` and `AlarmLow`). **Step and simple scaling need alarms you create.**
- Target tracking scales **out fast** (3 datapoints, 3 minutes) and **in slowly** (15 datapoints, 15 minutes).
- The **scale-in threshold** is about **70% of the target**.
- Max capacity **limits** dynamic scaling. The ASG never exceeds it.
- The policy changes **desired capacity**, and the ASG launches or terminates instances to match.
- Group-average metrics mean **one busy instance** doesn't fully drive scaling.
- **Activity history** shows the cause for each scaling action. **CloudWatch, Alarms** shows the alarm state.
- **Predictive scaling** needs **history** (at least 24 hours) and can run in **forecast only** mode first.
- **Scheduled actions** set **min/max/desired** at specific times, once or on a recurring schedule.
- Newly launched instances need **warm-up time**, so scaling isn't instant.

### 7. Exam-Style Recall

| If the question says... | Think... |
|---|---|
| "Keep average CPU at a target value" | **Target tracking** policy |
| "Which policy creates the CloudWatch alarms for you?" | **Target tracking** |
| "Which policies require you to create the alarms?" | **Simple and step scaling** |
| "Scale by different amounts depending on the alarm value" | **Step scaling** |
| "Add 10% of the group when an alarm fires" | **Simple scaling** (percentage change) |
| "Known promotion or event next week" | **Scheduled action** |
| "Recurring pattern, scale ahead using forecasts" | **Predictive scaling** |
| "Predictive scaling, check the forecast without scaling" | **Forecast only** mode |
| "ASG didn't scale beyond N instances" | **Max capacity** reached |
| "Why did the ASG scale in slowly?" | Scale-in alarm needs about **15 minutes** of low metric data |
| "Simulate CPU load for testing" | `stress` (or `stress-ng`) on an instance |
| "Where do you see why an instance was launched or terminated?" | ASG **Activity history** |
| "Where do you see the alarms that target tracking made?" | **CloudWatch, Alarms** |
| "Remove the policy's alarms" | **Delete the scaling policy** |

### 8. Hands-On Checklist

- [x] Open the ASG, **Automatic scaling** tab, and review the three categories
- [x] Skim the **Scheduled action** form (desired/min/max, recurrence, start/end time)
- [x] Skim the **Predictive scaling** form (metric, target value, mode)
- [x] Skim **simple** and **step** scaling (alarm, action)
- [x] Create a **target tracking** policy: **Average CPU utilization = 40**
- [x] Edit the ASG: **max capacity = 3** (keep min/desired = 1)
- [x] EC2 Instance Connect to the instance, install `stress`, run `stress -c 4`
- [x] Watch **Monitoring** (CPU) and **Activity history** for the scale-out (1, then 2, then 3)
- [X] Open **CloudWatch, Alarms** and find the **`AlarmHigh`** and **`AlarmLow`** alarms
- [x] Stop the load (`Ctrl+C` or reboot the instances)
- [x] Wait about 15 minutes and watch the scale-in back to 1 instance

---

## Auto Scaling Groups - Instance Refresh

### TL;DR

- **Instance Refresh** is a native ASG feature that **replaces all instances in a group** so they use a new launch template (or a new version of it). It is a **rolling** replacement.
- **Why:** updating a launch template **does not change running instances**, only new launches. Instance Refresh applies the change without you terminating instances by hand and waiting.
- Started with the **`StartInstanceRefresh`** API (console, CLI, or SDK).
- **Minimum healthy percentage** (lecture example: **60%**) controls how many instances can be out of service at once.
- **Instance warmup** is how long the ASG waits before treating a new instance as ready to serve traffic.
- Typical trigger: a **new AMI** (patching, new app version baked into the image).

### 1. The Problem

- The ASG's instances were launched from an **old launch template**.
- You create a **new launch template** (or a new version), for example with an **updated AMI**.
- **Existing instances keep running the old configuration.** Only instances launched **after** the change use the new one.
- Doing it by hand (terminate one, wait for the replacement, repeat) is slow and error-prone. You can also drop capacity too far.
- **Instance Refresh** automates this while keeping enough healthy capacity.

### 2. How It Works

1. Create the **new launch template version** (for example, a new AMI).
2. Call **`StartInstanceRefresh`** on the ASG with your preferences (minimum healthy percentage, warmup).
3. The ASG **terminates a batch** of old instances, limited by the minimum healthy percentage.
4. It **launches replacements** with the new launch template.
5. It waits for the new instances to be ready (**warmup** and health checks).
6. It repeats until **all instances** use the new configuration.

```
Before:  [old] [old] [old] [old] [old]
Step 1:  [old] [old] [old] [new] [new]   <- batch replaced, min healthy respected
After:   [new] [new] [new] [new] [new]
```

- The name comes from the behavior: instances are **terminated and new ones come up** over time.

### 3. Key Settings

| Setting | Meaning | Notes |
|---|---|---|
| **Minimum healthy percentage** | The share of the group's capacity that must stay **healthy and in service** during the refresh | Lecture example: **60%**. **Default: 90%.** Range **0-100%**. |
| **Instance warmup** | How long to wait after an instance launches before it is considered **ready to serve traffic** | Defaults to the group's **health check grace period** if not set |

#### 3.1 Minimum healthy percentage

- It tells the ASG **how many instances it may take out at a time**.
- Example: **10 instances, minimum healthy 60%**. At least **6** must stay healthy, so up to **4** can be replaced in a batch.
- Trade-offs:

| Value | Effect |
|---|---|
| **High** (90-100%) | **Slower** refresh, **little or no capacity loss**. Safer for production. |
| **Low** (for example 50-60%) | **Faster** refresh, but **less capacity** during the rollout |
| **0%** | Replaces everything at once, so **downtime is possible** |

#### 3.2 Instance warmup

- After a new instance starts, the ASG waits the **warmup time** before counting it as ready and moving on to the next batch.
- Set it to about your **real startup time** (boot, user data, app start).
- Too short means the ASG may terminate more old instances before the new ones can take traffic.
- Too long means the refresh takes longer than it needs to.

### 4. Other Options Worth Knowing

The lecture covers only the two main settings. The API has more:

| Option | Purpose |
|---|---|
| **Checkpoints** | **Pause** at chosen percentages (for example 20%, 50%, 100%) so you can verify before continuing |
| **Skip matching** | **Skip instances** that already use the desired launch template and version |
| **Auto rollback** | **Roll back** if the refresh fails or alarms trigger |
| **Desired configuration** | Pass the **launch template/version** directly in the call |
| **Scale-in protection handling** | Decide what happens to **scale-in protected** instances (wait, ignore, refresh) |
| **Max healthy percentage** | Allows **launching new instances before terminating old ones** (extra capacity during the rollout) |

- **Cancel** an in-progress refresh with `CancelInstanceRefresh`.
- Check progress with `DescribeInstanceRefreshes`. Statuses include `Pending`, `InProgress`, `Successful`, `Failed`, and `Cancelled`.
- Only **one** instance refresh can run at a time per ASG.

### 5. Instance Refresh vs Other Approaches

| Approach | Behavior | Downside |
|---|---|---|
| **Update the launch template only** | Only **new** launches use it | Existing instances stay old |
| **Terminate instances manually** | ASG replaces each one | Manual, slow, easy to over-terminate |
| **Instance Refresh** | **Automated rolling replacement** with min healthy % and warmup | Takes time, and temporarily reduces capacity (unless max healthy is used) |
| **New ASG (blue/green)** | Create a new ASG with the new template and switch traffic | More resources and more setup |

### 6. Key Facts to Remember

- **Instance Refresh** = update the **whole ASG** to a new launch template by **replacing instances gradually**.
- It is started with **`StartInstanceRefresh`**.
- **Minimum healthy percentage** = how much capacity must stay healthy. **Lower means faster**, and **higher means safer**.
- **Instance warmup** = time before a new instance is considered ready.
- New instances register with the **target group** and old ones **deregister** (the **deregistration delay** applies), so users are not cut off mid-request.
- The launch template is **versioned**, so you can point the ASG at the new version and refresh.
- It works with **ELB health checks**: replacements must pass before the rollout continues.
- The ASG's **instance maintenance policy** (seen in the ASG hands-on) also controls min/max healthy percentages during replacements.
- Instance Refresh is **rolling**. It is not the same as blue/green.

### 7. Exam-Style Recall

| If the question says... | Think... |
|---|---|
| "Update all instances in an ASG to a new AMI" | **Instance Refresh** |
| "Replace instances with a new launch template without downtime" | **Instance Refresh** with a high **minimum healthy percentage** |
| "API to start it" | **`StartInstanceRefresh`** |
| "Control how many instances are replaced at once" | **Minimum healthy percentage** |
| "Give new instances time before they count as ready" | **Instance warmup** |
| "Launch template updated, but running instances still use the old AMI" | Only new launches use it, so run an **Instance Refresh** |
| "Pause the refresh to verify" | **Checkpoints** |
| "Stop an unwanted refresh" | **`CancelInstanceRefresh`** |
| "Rolling replacement of instances" | **Instance Refresh** |
| "Refresh faster, and some capacity loss is fine" | **Lower** minimum healthy percentage |
