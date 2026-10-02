# VPC Fundamentals

---

## VPC Fundamentals - Section Introduction

### TL;DR

- **VPC** = **Virtual Private Cloud**. This section is a **high-level crash course**, not a deep dive.
- VPC is covered in depth in the **Solutions Architect Associate** and **SysOps Administrator Associate** exams. The **Developer Associate** only needs the basics.
- Expect roughly **1 to 3 questions** on VPC in the exam.
- Topics to know: **VPC, subnets, Internet Gateway, NAT Gateway, security groups, NACL, VPC Flow Logs, VPC peering, VPC endpoints, Site-to-Site VPN, and Direct Connect**.
- Don't worry about memorizing everything now. Later sections that touch VPC will **remind you of the relevant concepts**.

---

## VPC, Subnets, IGW and NAT

### TL;DR

- A **VPC (Virtual Private Cloud)** is your **private network inside AWS**. It is a **regional** resource, so each region has its own VPC(s). It spans **all AZs** in the region.
- A **subnet** partitions the VPC and lives in **one AZ**. It is either **public** (reachable from the internet) or **private** (not reachable from the internet).
- **Route tables** control how traffic flows between subnets and to the internet.
- A subnet is **public** because its route table has a **route to an Internet Gateway (IGW)**.
- Private instances that need **outbound-only** internet access (for example software updates) use a **NAT Gateway** (AWS-managed) or **NAT instance** (self-managed). It sits in a **public subnet**.
- The **default VPC** has **one public subnet per AZ** and no private subnets.
- This section is conceptual, with no hands-on. Expect only 1 to 3 VPC questions in the exam.

### 1. VPC Basics

| Property | Detail |
|---|---|
| **What it is** | A **private network** in the AWS cloud where you deploy your resources |
| **Scope** | **Regional.** Two regions means two different VPCs. |
| **AZ span** | A VPC **spans all AZs** of its region |
| **IP range** | A **CIDR range** (the IPs allowed in the VPC), for example `10.0.0.0/16` |
| **Nature** | A **logical construct**. It is not a physical thing. |

- **CIDR facts (extras beyond the lecture):**
  - IPv4 VPC CIDR size: from **/16 (largest) to /28 (smallest)**.
  - Use **private ranges** (RFC 1918): `10.0.0.0/8`, `172.16.0.0/12`, `192.168.0.0/16`.
  - **Don't overlap** CIDRs with other VPCs or your on-premises network if you plan to connect them (peering and VPN need non-overlapping ranges).

```
Region
 └── VPC (CIDR 10.0.0.0/16)
      ├── AZ-a: [public subnet] [private subnet]
      └── AZ-b: [public subnet] [private subnet]
```

### 2. Subnets

- Subnets **partition your network** inside the VPC.
- **A subnet is defined at the AZ level** (it can't span AZs).
- You can have **multiple subnets per AZ**.
- Each subnet gets a **slice of the VPC's CIDR range**.
- You launch resources (EC2, RDS, and so on) **into a subnet**.

| | **Public subnet** | **Private subnet** |
|---|---|---|
| **Internet access** | Can reach the internet **and be reached from it** | **Not reachable** from the internet |
| **Route to an IGW** | **Yes** | **No** |
| **Typical contents** | Load balancers, bastion hosts, NAT gateways, web servers | App servers, databases, caches |
| **Why** | Needs to be public | **More secure and more private** |

- **Example from the lecture:** an EC2 instance in the public subnet has internet access. An EC2 instance in the private subnet has none, and the internet can't reach it.
- Extra: AWS **reserves 5 IP addresses** in every subnet (first four and the last), so a `/24` has **251** usable IPs.
- Extra: **DB subnet groups** (RDS) and **ElastiCache subnet groups** are made of subnets in **at least 2 AZs**.

### 3. Route Tables

- **Route tables** define **how traffic flows** between subnets and to destinations such as the internet.
- Each subnet is **associated with one route table**. One route table can serve many subnets.
- Every route table has a **`local` route** that lets resources in the VPC talk to each other.
- A route is: **destination** (a CIDR) and **target** (where to send it).

| Subnet | Route table (example) |
|---|---|
| **Public** | `10.0.0.0/16` to `local`, and **`0.0.0.0/0` to IGW** |
| **Private** | `10.0.0.0/16` to `local`, and **`0.0.0.0/0` to NAT Gateway** (if outbound access is needed) |
| **Private (isolated)** | `10.0.0.0/16` to `local` only |

- The lecture's point: you define a bunch of route tables to say **how network traffic flows between subnets and out to the internet**.
- The **most specific route wins** (longest prefix match).

### 4. Default VPC

- AWS creates one **default VPC in every region** for your account.
- It has:
  - **One public subnet per AZ**.
  - An **Internet Gateway** already attached.
  - Routes that make the subnets public.
- **No private subnets.** That is why instances you launched earlier in the course had public IPs and were internet-reachable.
- The lecture: "when you use your cloud on AWS you only have public subnets".
- Default VPC CIDR is `172.31.0.0/16` (extra detail).
- Instances launched there get a **public IPv4 address** by default (auto-assign is on).

### 5. Internet Gateway (IGW)

#### 5.1 What it does

- Helps instances in your VPC **connect to the internet** (and the internet reach them).
- It **lives at the VPC level**. You create one and **attach** it to the VPC.
- What makes a subnet **public** is a **direct route to the IGW**:

```
Internet <--> [Internet Gateway] <--> [Route table: 0.0.0.0/0 -> IGW] <--> Public subnet <--> EC2
```

#### 5.2 Properties

| Property | Detail |
|---|---|
| **Managed by** | AWS (**horizontally scaled, redundant, highly available**) |
| **Direction** | **Two-way**: inbound and outbound |
| **Attachment** | One IGW per VPC, and a VPC has at most one IGW |
| **Cost** | No charge for the IGW itself |

- **Both of these** are needed for an instance to be reachable from the internet:
  1. The subnet has a **route to the IGW**.
  2. The instance has a **public IPv4 address (or Elastic IP)** and the **security group and NACL allow** the traffic.
- Public subnet plus no public IP means the instance still can't be reached or reach out directly.

### 6. NAT Gateway and NAT Instance

#### 6.1 The problem

- An EC2 instance in a **private subnet** needs the internet **outbound**, for example to download **software updates**.
- But you **don't want the internet to initiate connections** to it, and you don't want it reachable from websites.

#### 6.2 The solution

```
Private subnet EC2
   |  route: 0.0.0.0/0 -> NAT
   v
NAT Gateway (in a PUBLIC subnet, with an Elastic IP)
   |  route: 0.0.0.0/0 -> IGW
   v
Internet Gateway --> Internet
```

1. **Deploy a NAT Gateway (or NAT instance) in a public subnet.**
2. Add a **route** in the **private subnet's route table** to send internet-bound traffic to the NAT.
3. The NAT is in a public subnet, so it has a **route to the IGW**.
4. Result: private instances reach the internet **through the NAT**, while staying **private** (the internet can't start connections inward).

#### 6.3 NAT Gateway vs NAT instance

| | **NAT Gateway** | **NAT instance** |
|---|---|---|
| **Managed by** | **AWS** (no provisioning or scaling work) | **You** (self-managed EC2 instance) |
| **Scaling** | Automatic (up to high bandwidth) | You choose the instance size |
| **Availability** | Redundant **within one AZ**. Create **one per AZ** for HA. | You build your own HA |
| **Elastic IP** | **Required** (public NAT gateway) | Needs an Elastic IP or public IP |
| **Security group** | **None** (use NACLs on the subnet) | **Yes**, you manage it |
| **Source/destination check** | N/A | Must be **disabled** on the instance |
| **Cost** | Hourly plus per-GB processed | The EC2 instance cost |
| **Status** | **Recommended** | Legacy, not recommended |

- The lecture: both "do the same thing" (**provide NAT for private subnets**), but the gateway is **managed**, and the instance is **self-managed**.
- **NAT is outbound only.** It can't be used to accept inbound internet connections.
- For **IPv6**, use an **egress-only Internet Gateway** (extra detail).

#### 6.4 Connection to later sections

- The lecture says NAT gateways and NAT instances "come into play later in the course, when we talk about **Lambda functions**".
- Reason: a **Lambda function placed in a VPC's private subnet** has **no internet access** unless there is a **NAT Gateway** (or VPC endpoints for AWS services).

### 7. Typical Architecture (Recap)

```
Region
 └── VPC 10.0.0.0/16  ── [Internet Gateway]
      ├── AZ-a
      │    ├── Public subnet  : ALB node, NAT Gateway (EIP)
      │    └── Private subnet : EC2 app servers, RDS
      └── AZ-b
           ├── Public subnet  : ALB node, NAT Gateway (EIP)
           └── Private subnet : EC2 app servers, RDS standby
```

- **Public subnets** hold things that must be reachable (ALB, NAT).
- **Private subnets** hold things that must be protected (application and data).
- Spread across **at least 2 AZs** for high availability.
- A fuller example is covered in the **Three Tier Architecture** lecture later in this section.

### 8. Key Facts to Remember

- **VPC = regional**, spans all AZs. **Subnet = one AZ.**
- **Public subnet = has a route to an IGW.** Private subnet = no such route.
- **Route tables** decide where traffic goes.
- The **default VPC** has **one public subnet per AZ** and an attached IGW, and **no private subnets**.
- **IGW:** managed, highly available, **two-way**, one per VPC.
- **NAT Gateway:** managed, in a **public subnet**, **outbound only** for private subnets, needs an **Elastic IP**, **AZ-scoped** (one per AZ for HA).
- **NAT instance:** self-managed, older, requires **source/destination check disabled**.
- Private subnet route to the internet: **`0.0.0.0/0` to NAT**. NAT's own route: **`0.0.0.0/0` to IGW**.
- A **CIDR range** defines the VPC's IPs. Avoid overlapping CIDRs when connecting networks.
- **AWS reserves 5 IPs** per subnet.
- Lambda in a VPC needs a **NAT Gateway** (or endpoints) to reach the internet.

### 9. Exam-Style Recall

| If the question says... | Think... |
|---|---|
| "Private network inside AWS" | **VPC** |
| "Is a VPC regional or global?" | **Regional** |
| "Is a subnet regional or AZ-scoped?" | **AZ-scoped** (one AZ) |
| "What makes a subnet public?" | A **route to an Internet Gateway** |
| "Allow a VPC to reach and be reached by the internet" | **Internet Gateway** |
| "Private instances need outbound internet only (updates)" | **NAT Gateway** |
| "Where do you place a NAT Gateway?" | In a **public subnet** |
| "AWS-managed vs self-managed NAT" | **NAT Gateway** vs **NAT instance** |
| "NAT high availability across AZs" | **One NAT Gateway per AZ** |
| "Defines how traffic flows between subnets and to the internet" | **Route table** |
| "Range of IPs allowed in a VPC" | **CIDR range** |
| "VPC that comes with every account, only public subnets" | **Default VPC** |
| "Lambda in a private subnet can't reach the internet" | Add a **NAT Gateway** (or VPC endpoint for AWS services) |
| "Instance in a public subnet still unreachable from the internet" | Missing **public IP** or blocked by **security group/NACL** |

---

## NACL, SG, VPC Flow Logs

### TL;DR

- **NACL (Network ACL):** a **subnet-level** firewall with **allow and deny** rules. It is **stateless**, and rules match on **IP ranges (CIDRs)**.
- **Security group (SG):** an **instance/ENI-level** firewall with **allow rules only**. It is **stateful**, and rules can reference **IPs or other security groups**.
- Inbound traffic hits the **NACL first** (subnet edge), then the **security group** (instance). That gives two layers of defense.
- The **default VPC's default NACL allows everything in and out**, so you rarely touch NACLs. The lecture does no hands-on for them.
- **VPC Flow Logs** capture **IP traffic metadata** (accepted and rejected) at the **VPC, subnet, or ENI** level. They help **monitor and troubleshoot connectivity**.
- Flow logs can go to **S3, CloudWatch Logs, or Kinesis Data Firehose**.
- The detailed NACL vs SG table matters more for the SAA and SysOps exams. For the Developer exam, know the headline differences.

### 1. Network Defense Layers

```
Internet --> [Internet Gateway] --> [NACL: subnet level] --> [Security group: ENI/instance level] --> EC2
```

- Traffic reaching a public subnet passes the **NACL first**, then the **security group**.
- Traffic reaches the instance only if **both** allow it.
- The lecture's picture: a VPC with **1 public subnet and 1 EC2 instance**. The NACL is the **first line of defense** at the subnet. The SG is the **second line** at the instance.
- For **outbound** traffic the order reverses: SG first, then NACL.

### 2. Network ACL (NACL)

| Property | Detail |
|---|---|
| **What it is** | A firewall that controls traffic **to and from a subnet** |
| **Attached to** | A **subnet**. Each subnet has **exactly one** NACL. One NACL can cover **many subnets**. |
| **Rule types** | **Allow and deny**, both explicit |
| **Rule match** | **IP address ranges (CIDR blocks)**, plus protocol and port |
| **State** | **Stateless.** Return traffic must be **explicitly allowed**. |
| **Rule order** | Rules have **numbers**. They are evaluated from the **lowest number up**, and the **first match wins**. |
| **Default rule** | A final `*` rule **denies** anything not matched |
| **Applies to** | **All resources in the subnet** (no per-instance setup) |

- Example rules: "allow all traffic from this IP range", "deny all traffic from these IPs" (for example to block a bad actor).
- **Stateless** means: if you allow **inbound** TCP 80, you must also allow the **outbound ephemeral ports** (about **1024-65535**) for the response. If you don't, replies are dropped.
- **Why deny rules matter:** a security group can't deny. A NACL is the tool for **blocking a specific IP or range**.

#### 2.1 Default vs custom NACL

| | **Default NACL** (every VPC has one) | **Custom NACL** (you create) |
|---|---|---|
| **Inbound** | **Allow all** | **Deny all** until you add allow rules |
| **Outbound** | **Allow all** | **Deny all** until you add allow rules |
| **Subnets** | Automatically associated with subnets that have no other NACL | You associate it explicitly |

- **Why the course never changed NACLs:** the **default VPC's default NACL** allows everything in and out, so traffic was only filtered by **security groups**.
- The lecturer won't do a hands-on for NACLs.

### 3. Security Group (SG)

| Property | Detail |
|---|---|
| **What it is** | A firewall that controls traffic **to and from an ENI** (and so an EC2 instance) |
| **Attached to** | **ENIs** (Elastic Network Interfaces) / instances. One instance can have **several SGs**. |
| **Rule types** | **Allow only.** There is no deny rule. |
| **Rule source/destination** | **IP addresses (CIDR)** or **another security group** |
| **State** | **Stateful.** If a request is allowed in, the **response is automatically allowed out** (and the reverse). |
| **Rule evaluation** | **All rules are evaluated** together, so there is no ordering |
| **Default (new SG)** | **No inbound**, **all outbound** allowed |

- You've used these throughout the course: for example the ALB SG, and the EC2 SG whose source was the ALB SG.
- **Referencing another SG** is the key pattern (app SG to DB SG). It keeps working as IPs change.
- The lecture's table says SGs are **stateful: return traffic is automatically allowed regardless of rules**.

### 4. NACL vs Security Group

The lecturer says you don't need to memorize the full table, and that it matters more for the SAA and SysOps exams. This is a compact version.

| Feature | **Security group** | **NACL** |
|---|---|---|
| **Operates at** | **Instance / ENI** level | **Subnet** level |
| **Rules** | **Allow only** | **Allow and deny** |
| **State** | **Stateful** | **Stateless** |
| **Rule evaluation** | **All rules** evaluated | **In number order**, first match wins |
| **Applies to** | Instances the SG is attached to | **All instances** in the subnet |
| **Source/destination** | IPs **or other SGs** | **IP ranges** only |
| **Default** | Deny inbound, allow outbound | Default NACL allows all |

- **Quick recall:** **SG = stateful, allow-only, instance.** **NACL = stateless, allow + deny, subnet.**

### 5. VPC Flow Logs

#### 5.1 What they capture

- **Information about the IP traffic going to and from your network interfaces.**
- You can enable them at three levels:

| Level | Scope |
|---|---|
| **VPC flow logs** | All ENIs in the VPC |
| **Subnet flow logs** | All ENIs in the subnet |
| **ENI flow logs** | One specific network interface |

- Any network traffic through your VPC (at those levels) can be logged.
- Both **allowed (ACCEPT)** and **denied (REJECT)** traffic are recorded, whether blocked by an **SG or a NACL**.
- They also capture traffic of **AWS-managed services** that use ENIs in your VPC: **Elastic Load Balancers, ElastiCache, RDS, Aurora**, and others.

#### 5.2 Why use them

- **Monitor** traffic and **troubleshoot connectivity issues.**
- Lecture examples:
  - Why can't a **subnet reach the internet**?
  - Why can't one subnet talk to another?
  - Why can't the internet reach a subnet?
- "Anytime you have a network issue, look at the VPC flow logs."
- They also support **security analysis** (spotting unusual or blocked traffic) and **auditing**.

#### 5.3 Destinations

| Destination | Typical use |
|---|---|
| **Amazon S3** | Cheap long-term storage, query with **Athena** |
| **CloudWatch Logs** | Search, metric filters, alarms, **Logs Insights** |
| **Kinesis Data Firehose** | Stream to other tools (for example OpenSearch, Splunk) |

#### 5.4 What a record looks like

A flow log record is a line of **metadata** (not packet contents):

```
version account-id interface-id srcaddr dstaddr srcport dstport protocol packets bytes start end action log-status
2 123456789012 eni-0abc 203.0.113.12 10.0.1.5 49152 80 6 10 840 1700000000 1700000060 ACCEPT OK
```

- **Key fields:** `srcaddr`, `dstaddr`, `srcport`, `dstport`, `protocol`, `packets`, `bytes`, and **`action` (ACCEPT or REJECT)**.
- Records are **aggregated over a time window** (about **1 or 10 minutes**), so flow logs aren't real time.
- **Not captured:** the **payload** of the traffic. Also, some traffic such as **DNS to the Amazon DNS server**, **DHCP**, and **instance metadata (169.254.169.254)** isn't logged.

#### 5.5 Reading flow logs to find the blocker (useful trick)

| Pattern in the logs | Likely cause |
|---|---|
| **Inbound REJECT** | Blocked by a **security group or NACL** |
| Inbound **ACCEPT**, then outbound **REJECT** for the reply | A **NACL** (SGs are stateful, so they wouldn't block the reply) |
| **No records at all** | Traffic never reached the ENI (route table, IGW, or a different problem) |

### 6. Key Facts to Remember

- **NACL = subnet level, allow and deny, stateless, IP ranges, numbered rules.**
- **SG = ENI/instance level, allow only, stateful, can reference other SGs.**
- Inbound path: **NACL first, then SG**.
- The **default NACL allows all** in and out. A **custom NACL denies all** until you add rules.
- Use a **NACL to block a specific IP**. SGs can't deny.
- **VPC Flow Logs** capture **IP traffic metadata** at **VPC, subnet, or ENI** level, **including AWS-managed services' ENIs** (ELB, RDS, ElastiCache, Aurora).
- Flow logs include **accepted and rejected** traffic.
- Destinations: **S3, CloudWatch Logs, Kinesis Data Firehose**.
- Flow logs help with **connectivity troubleshooting**. They show metadata, not content.
- Flow logs are **not real time**, and they don't change traffic. They only record it.

### 7. Exam-Style Recall

| If the question says... | Think... |
|---|---|
| "Firewall at the subnet level" | **NACL** |
| "Firewall at the instance / ENI level" | **Security group** |
| "Stateful firewall" | **Security group** |
| "Stateless firewall" | **NACL** |
| "Explicitly deny traffic from a specific IP" | **NACL** |
| "Only allow rules" | **Security group** |
| "Rules evaluated in number order" | **NACL** |
| "Rules can reference another security group" | **Security group** |
| "First line of defense for traffic entering a subnet" | **NACL** |
| "Default NACL behavior" | **Allow all** inbound and outbound |
| "Capture information about IP traffic in a VPC" | **VPC Flow Logs** |
| "Troubleshoot why a subnet can't reach the internet" | **VPC Flow Logs** |
| "Levels at which flow logs can be enabled" | **VPC, subnet, ENI** |
| "Where can flow logs be sent?" | **S3, CloudWatch Logs, Kinesis Data Firehose** |
| "Query flow logs stored in S3" | **Athena** |
| "Do flow logs include RDS, ELB, and ElastiCache traffic?" | **Yes** (their ENIs in your VPC) |
| "Do flow logs capture packet contents?" | **No**, only metadata |

---

## VPC Peering, Endpoints, VPN, DX

### TL;DR

- Four ways to connect a VPC to other networks:
  1. **VPC peering**: connect **two VPCs** privately (same or different account or region).
  2. **VPC endpoints**: reach **AWS services privately**, without the public internet.
  3. **Site-to-Site VPN**: **encrypted** connection from on premises to a VPC **over the public internet**. Set up in **minutes**.
  4. **Direct Connect (DX)**: **dedicated physical private** connection from on premises to AWS. Takes **at least a month** to set up.
- **VPC peering** needs **non-overlapping CIDRs** and is **not transitive**.
- **VPC endpoints** come in two types: **Gateway** (S3 and DynamoDB only) and **Interface** (most other services, via an ENI).
- Exam default: "**privately connect to an AWS service**" means **VPC endpoint**.
- VPN vs DX: **same purpose, different method and timeline** (encrypted over the internet vs private physical line).

### 1. VPC Peering

#### 1.1 What it is

- Connects **two VPCs privately** using the **AWS network**, so they behave **as if they were in the same network**.
- The VPCs can be in **different accounts** or **different regions** (inter-region peering).
- You create a **peering connection** between VPC A and VPC B (one side requests, the other accepts).

```
[VPC A] <--- peering connection ---> [VPC B]
```

#### 1.2 Rules

| Rule | Detail |
|---|---|
| **No overlapping CIDRs** | The two VPCs' IP ranges **must not overlap**. If they did, the network wouldn't know where to send a packet. |
| **Not transitive** | A peered with B, and A peered with C, does **not** let B talk to C |
| **One connection per pair** | Every pair that needs to communicate needs **its own** peering connection |
| **Route tables** | You must **add routes** in each VPC's route table pointing the other VPC's CIDR to the peering connection (extra detail) |
| **Security groups** | Rules must still **allow the traffic**. SGs can reference peered SGs in the same region (extra detail). |

#### 1.3 Not transitive (lecture example)

```
VPC A <---> VPC B
VPC A <---> VPC C
VPC B  X    VPC C   (cannot talk, no transitivity)
```

- To let B and C talk, create **a separate peering connection between B and C**.
- **Scaling problem:** N VPCs fully meshed need N(N-1)/2 connections. As the number of VPCs grows, so does the number of connections.
- Many VPCs: use **AWS Transit Gateway** (hub-and-spoke, covered in other exams) instead of a full mesh.

### 2. VPC Endpoints

#### 2.1 The problem

- All **AWS services are public** (they have public endpoints on the internet).
- When an EC2 instance calls an AWS service (S3, DynamoDB, CloudWatch, and so on), by default the traffic goes to the **public endpoint**.
- Instances in a **private subnet** have no internet route. To reach AWS services they would need a **NAT Gateway and IGW**, with the traffic crossing the public internet.

#### 2.2 The solution

- A **VPC endpoint** lets you connect to AWS services using a **private network** (the AWS network) **instead of the public internet**.
- Benefits: **more security** and **lower latency**. It can also **save NAT Gateway costs**.

```
Private subnet EC2 --> [VPC endpoint] --> AWS service     (no IGW, no NAT, no internet)
```

#### 2.3 Two types

| | **Gateway endpoint** | **Interface endpoint** |
|---|---|---|
| **Services** | **S3 and DynamoDB only** | **Most other AWS services** (CloudWatch, SQS, SNS, Secrets Manager, KMS, and more, plus S3) |
| **How it works** | A **target in your route table** (a prefix list route) | An **ENI with a private IP** in your subnet (powered by **AWS PrivateLink**) |
| **Cost** | **Free** | **Hourly charge plus per-GB** |
| **Access from on premises / other VPCs** | **No** | **Yes** (over VPN, DX, or peering) |
| **Security** | Endpoint policy | **Security groups** plus endpoint policy |

- Lecture example (gateway): an EC2 instance in a **private subnet** reaches **S3 and DynamoDB** through a **VPC endpoint gateway**, and the traffic **doesn't go through the internet**.
- Lecture example (interface): an **interface endpoint (an ENI)** in the private subnet gives private access to **CloudWatch**.
- The lecturer says the gateway vs interface difference is **probably not tested** in the Developer exam, but you should know it **when the exam asks for private access to an AWS service, the answer is a VPC endpoint**.
- Tip: the lecture calls it "interface" for "the rest of the service". "Only used within your VPC" means the endpoint ENI sits inside your VPC.

### 3. Site-to-Site VPN

- Connects an **on-premises network** (office, data center) to **your VPC**.
- Uses a **VPN appliance on premises** (customer gateway) and a **virtual private gateway (VGW)** or **Transit Gateway** on the AWS side.
- The connection is **automatically encrypted** (IPsec) and goes over the **public internet**.
- **Quick to set up**: "a matter of minutes".

```
On-premises data center <== encrypted tunnel over the PUBLIC INTERNET ==> VPC
 (customer gateway)                                    (virtual private gateway)
```

| Property | Detail |
|---|---|
| **Path** | **Public internet** |
| **Encryption** | **Yes** (IPsec) |
| **Setup time** | **Minutes** |
| **Bandwidth** | Up to about 1.25 Gbps per tunnel (extra detail) |
| **Consistency** | Variable, since the internet is shared |
| **Resilience** | Two tunnels per connection for redundancy (extra detail) |

### 4. Direct Connect (DX)

- Establishes a **physical, dedicated connection** between your **on-premises data center** and AWS.
- It does **not go over the public internet**. It uses a **private line**.
- **Secure and fast.**
- **Slow to set up**: it takes **at least a month**, because physical work is needed (a DX location, cross connects, and a partner or carrier).

```
On-premises data center ==== private physical line ==== AWS Direct Connect location ==== VPC
                          (NOT the public internet)
```

| Property | Detail |
|---|---|
| **Path** | **Private dedicated line** |
| **Encryption** | **Not encrypted by default.** Add a VPN over DX, or MACsec, if you need it (extra detail). |
| **Setup time** | **At least a month** |
| **Bandwidth** | 1, 10, or 100 Gbps dedicated (and smaller hosted options) (extra detail) |
| **Consistency** | **Consistent, low-latency** performance |
| **Cost** | Higher than VPN |

### 5. VPN vs Direct Connect

Both connect on premises to a VPC. The lecturer: "same purpose, different methods and timelines".

| | **Site-to-Site VPN** | **Direct Connect** |
|---|---|---|
| **Connection type** | **Encrypted tunnel** | **Physical private line** |
| **Goes over the public internet?** | **Yes** | **No** |
| **Encrypted by default?** | **Yes** | **No** (add VPN or MACsec) |
| **Setup time** | **Minutes** | **At least a month** |
| **Performance** | Variable | **Consistent, high bandwidth** |
| **Cost** | Lower | Higher |
| **Use when** | You need connectivity **fast** or a **backup path** | You need **steady, high-throughput, low-latency** private connectivity |

- A common design: **DX as the primary path and Site-to-Site VPN as the backup**.

### 6. Choosing the Right Option

| Need | Use |
|---|---|
| Connect **two VPCs** privately | **VPC peering** |
| Let a **private subnet** reach **S3 or DynamoDB** with no internet | **Gateway endpoint** |
| Let a private subnet reach **other AWS services** (CloudWatch, SQS, and so on) privately | **Interface endpoint** |
| **Quick**, encrypted link from on premises to AWS | **Site-to-Site VPN** |
| **Dedicated, private, consistent** link from on premises | **Direct Connect** |
| Many VPCs and on-premises networks in one hub | **Transit Gateway** (beyond this lecture) |

### 7. Key Facts to Remember

- **VPC peering:** private VPC-to-VPC link, **CIDRs must not overlap**, **not transitive**, cross-account and cross-region supported.
- **VPC endpoints:** private access to **AWS services**. **Gateway** (S3, DynamoDB) and **Interface** (ENI, PrivateLink, the rest).
- AWS services are **public by default**, so private subnets need an **endpoint** (or NAT) to reach them.
- **Site-to-Site VPN:** **encrypted**, over the **public internet**, **minutes** to set up.
- **Direct Connect:** **physical private line**, **not on the internet**, **at least a month** to set up.
- VPN and DX connect **on premises to AWS**. Peering connects **VPC to VPC**. Endpoints connect **VPC to AWS services**.
- Peering needs **route table entries** and **non-overlapping CIDRs** on both sides.

### 8. Exam-Style Recall

| If the question says... | Think... |
|---|---|
| "Connect two VPCs privately using the AWS network" | **VPC peering** |
| "VPC A to B and A to C, can B reach C?" | **No**, peering is **not transitive** |
| "Peering fails between two VPCs" | **Overlapping CIDRs** |
| "Private subnet instance needs to access S3 without the internet" | **VPC (gateway) endpoint** |
| "Privately access an AWS service from a VPC" | **VPC endpoint** |
| "Endpoint types and which services each supports" | **Gateway = S3 and DynamoDB. Interface = most others.** |
| "Gateway endpoint cost" | **Free** |
| "Encrypted connection from on premises to AWS over the internet" | **Site-to-Site VPN** |
| "Set up connectivity from on premises within minutes" | **Site-to-Site VPN** |
| "Dedicated private connection, not over the public internet" | **Direct Connect** |
| "On-premises connection that takes a month or more to set up" | **Direct Connect** |
| "Consistent, high-bandwidth, low-latency link to AWS" | **Direct Connect** |
| "Backup for a Direct Connect link" | **Site-to-Site VPN** |
| "Connect many VPCs without a full mesh" | **Transit Gateway** |

---

## VPC Cheat Sheet & Closing Comments

### TL;DR

- This is the **one-slide summary** of the whole VPC section. The lecturer says it is all you need for the VPC questions in the Developer exam, so **don't stress**.
- **VPC** = Virtual Private Cloud. There is **one default VPC per region**, and you've been using it all along.
- **Subnets** are tied to **one AZ**. **IGW** gives public subnets internet access. **NAT** gives private subnets outbound internet access.
- **NACL** = **stateless**, subnet-level firewall. **SG** = **stateful**, instance/ENI-level firewall that **can reference other SGs**.
- **VPC peering** = connect two VPCs, **no overlapping CIDRs**, **not transitive**.
- **VPC endpoints** = **private access to AWS services**. **Flow Logs** = network traffic logs for debugging.
- **On premises to AWS:** **Site-to-Site VPN** (over the public internet, encrypted) or **Direct Connect** (private physical line).

### 1. The Cheat Sheet

| Component | What to remember |
|---|---|
| **VPC** (Virtual Private Cloud) | **One default VPC per region.** Used all along the course when launching EC2 instances. |
| **Subnets** | Tied to a **specific AZ**. A **network partition** of the VPC. Where EC2 instances are launched. |
| **Internet Gateway (IGW)** | Gives **public subnets** access to the internet. Defined at the **VPC level**. |
| **NAT Gateway / NAT instance** | Gives **private subnets** (their EC2 instances) **internet access**, outbound. |
| **NACL** | **Stateless** firewall at the **subnet** level. Rules for **inbound and outbound**. |
| **Security group** | **Stateful** firewall at the **EC2 instance / ENI** level. **Can reference other security groups.** |
| **VPC peering** | Connects **two VPCs**. CIDRs **must not overlap**. **Not transitive**, so each pair needs its own connection. |
| **VPC endpoints** | **Private access to AWS services** from within your VPC. Shows up again in later lectures for specific services. |
| **VPC Flow Logs** | **Network traffic logs.** Debug **access denied**, or whether traffic is **blocked or allowed** in the VPC. |
| **Site-to-Site VPN** | VPN connection from on premises to AWS **over the public internet**. |
| **Direct Connect (DX)** | **Direct private connection** from on premises to AWS. |

### 2. Quick Comparisons

#### 2.1 Security group vs NACL

| | **Security group** | **NACL** |
|---|---|---|
| **Level** | EC2 instance / ENI | Subnet |
| **State** | **Stateful** | **Stateless** |
| **Rules** | Allow only | Allow and deny |
| **Can reference other SGs** | **Yes** | No (IP ranges only) |

#### 2.2 IGW vs NAT

| | **Internet Gateway** | **NAT Gateway / instance** |
|---|---|---|
| **For** | **Public** subnets | **Private** subnets |
| **Direction** | Two-way | **Outbound only** |
| **Placement** | Attached to the VPC | Sits in a **public subnet** |

#### 2.3 On premises to AWS

| | **Site-to-Site VPN** | **Direct Connect** |
|---|---|---|
| **Path** | **Public internet** (encrypted) | **Private physical line** |
| **Setup** | Minutes | At least a month |

### 3. Closing Comments from the Lecturer

- The section was **heavy and had no hands-on** on purpose. It isn't needed for the Certified Developer level.
- Remember a **few concepts** and you'll be set on VPC questions.
- The course will **highlight specific VPC features** when they are needed later (for example NAT and endpoints with Lambda).
- Come back to this section later if you want. **Don't stress** if you didn't understand everything.
- The lecturer gave a bit more than the exam needs, "just to make sure we are on the same page". The course **gets more developed very soon**.

### 4. Key Facts to Remember

- **Default VPC:** one per region, with public subnets.
- **Subnet = one AZ.** **VPC = regional.**
- **IGW:** VPC level, internet access for **public** subnets.
- **NAT:** internet access for **private** subnets (outbound).
- **NACL = stateless, subnet. SG = stateful, instance/ENI, can reference SGs.**
- **Peering:** no overlapping CIDRs, **not transitive**.
- **Endpoints:** private access to AWS services.
- **Flow Logs:** debug allowed or denied traffic.
- **VPN** = encrypted over the internet. **DX** = private line.

### 5. Exam-Style Recall

| If the question says... | Think... |
|---|---|
| "Which VPC did we use for the EC2 instances in the course?" | The **default VPC** |
| "Network partition tied to a single AZ" | **Subnet** |
| "Gives public subnets internet access" | **Internet Gateway** |
| "Private subnet instances need internet access" | **NAT Gateway / instance** |
| "Stateless firewall at subnet level" | **NACL** |
| "Stateful firewall that can reference other SGs" | **Security group** |
| "Connect two VPCs, but traffic between B and C via A fails" | **Peering is not transitive** |
| "Private access to AWS services from a VPC" | **VPC endpoint** |
| "Debug whether traffic is blocked or allowed" | **VPC Flow Logs** |
| "Encrypted on-premises link over the public internet" | **Site-to-Site VPN** |
| "Direct private link from on premises to AWS" | **Direct Connect** |

---

## Three Tier Architecture

### TL;DR

- The **typical three-tier architecture** is built from everything covered so far: **Route 53, ELB, Auto Scaling, EC2, RDS, ElastiCache, and VPC subnets**.
- **Tier 1 (web/presentation):** an **ELB** in **public subnets**, spread across multiple AZs, reached through **Route 53**.
- **Tier 2 (application):** EC2 instances in an **Auto Scaling Group** in **private subnets**, reached only from the ELB.
- **Tier 3 (data):** **RDS** (and optionally **ElastiCache**) in **data subnets**, a second private layer one level deeper.
- Security principle: **only the ELB is public**. Compute and data are isolated in private subnets.
- Also covered: the **LAMP stack** on EC2, and a simplified **WordPress on AWS** architecture using **EFS**.
- This pattern comes up **very often in scenario questions** in the exam.

### 1. Why VPC Came First

- The lecturer's point: the VPC and subnet material exists so this architecture **makes sense**.
- You need to understand **public vs private subnets** and **route tables** to see why each component sits where it does.

### 2. The Three-Tier Architecture

```
Users
  |  DNS query
  v
[Route 53]  --> returns the ELB address (Alias record)
  |
  v
+---------------- VPC ----------------------------------------------+
|  PUBLIC subnets (AZ-a, AZ-b, AZ-c)                                |
|     [ Elastic Load Balancer, multi-AZ ]                           |
|                |  route tables                                    |
|                v                                                  |
|  PRIVATE subnets (AZ-a, AZ-b, AZ-c)                               |
|     [ EC2 instances in an Auto Scaling Group ]                    |
|                |                                                  |
|                v                                                  |
|  DATA subnets (AZ-a, AZ-b, AZ-c)                                  |
|     [ RDS ]   [ ElastiCache ]                                     |
+-------------------------------------------------------------------+
```

#### 2.1 Tier 1: Load balancer (public)

| Point | Detail |
|---|---|
| **Component** | **Elastic Load Balancer**, spread across **multiple AZs** |
| **Subnet type** | **Public subnets**, because it must be reachable from the internet |
| **How users find it** | A **DNS query** to **Route 53**, which returns the ELB. Users then talk to the ELB directly. |
| **Route 53 record** | An **Alias** record to the ELB (needed for the root domain) |

#### 2.2 Tier 2: Application (private)

| Point | Detail |
|---|---|
| **Component** | **EC2 instances** in an **Auto Scaling Group** |
| **Subnet type** | **Private subnets**. They don't need internet exposure, only traffic **from the ELB**. |
| **Spread** | **3 AZs**, with instances in each |
| **Traffic path** | ELB (public subnet) to instances (private subnet) **through route tables** |
| **Benefit** | Compute is **isolated**, so it is **a lot more secure** |

- The ASG gives **scaling and self-healing**. The ELB gives **traffic distribution and health checks**.
- **Security groups:** instance SG allows traffic **only from the ELB's SG**.
- Private instances that need outbound internet (patches) use a **NAT Gateway** in a public subnet.

#### 2.3 Tier 3: Data (private, deeper)

| Point | Detail |
|---|---|
| **Component** | **Amazon RDS** (read and write data) and **ElastiCache** |
| **Subnet type** | **Data subnets**, a **second layer of private subnets**, one level deeper |
| **RDS role** | The **database**. EC2 instances connect to it. |
| **ElastiCache role** | **Cache** RDS query results, and store **session data** so the web app is stateless |

- **Security groups:** the RDS SG allows the DB port **only from the application tier's SG**. The ElastiCache SG allows its port only from the app tier.
- Data subnets typically have **no route to the internet at all** (not even via NAT).
- **RDS Multi-AZ** or **Aurora** gives database HA across the AZs.

### 3. Why This Design Works

| Goal | How the design achieves it |
|---|---|
| **Security** | Only the ELB is public. App and data tiers are in private subnets with **SG-to-SG rules**. |
| **High availability** | Everything is spread across **multiple AZs** |
| **Scalability** | **ASG** scales the app tier. **Read replicas** and **ElastiCache** scale the data tier. |
| **Elasticity and self-healing** | ASG replaces unhealthy instances, using ELB health checks |
| **Statelessness** | **Sessions in ElastiCache**, so any instance can serve any user |
| **Performance** | **ElastiCache** reduces database load |

**Security group chain:**

```
Internet --80/443--> [ELB SG] --app port--> [App SG] --DB port--> [RDS SG]
                                                   \--6379--> [ElastiCache SG]
```

### 4. LAMP Stack on EC2

The exam may mention it. **LAMP** stands for:

| Letter | Component | Role |
|---|---|---|
| **L** | **Linux** | The operating system of the EC2 instances |
| **A** | **Apache** | The web server running on Linux |
| **M** | **MySQL** | The database. On AWS, usually **MySQL on RDS**. |
| **P** | **PHP** | The application logic that renders pages |

- **Add caching:** put **Redis or Memcached from ElastiCache** in front of the database.
- **Local storage:** use **EBS volumes** on the EC2 instances to store data locally, cache locally, or hold application data and software.
- The web and PHP layers run on **EC2**. The database runs on **RDS**.

### 5. WordPress on AWS

- **WordPress** is a blogging tool.
- Simplified version: the **same load balancer tier and application tier** as above.

#### 5.1 The problem

- Users **upload images** through the load balancer to an EC2 instance.
- Those images must be **available to every other EC2 instance**, because the next request may land on a different one.
- Local EBS volumes can't do this (each is attached to **one instance** in one AZ).

#### 5.2 The solution: EFS

```
Users --> [ELB] --> EC2 (AZ-a) --\
                    EC2 (AZ-b) ---+--> [EFS network file system, ENI in each AZ]
                    EC2 (AZ-c) --/
```

| Point | Detail |
|---|---|
| **EFS** | A **network file system (network drive)** |
| **How it connects** | Creates an **ENI in each AZ**, and instances mount it |
| **Result** | Images stored by one instance are **visible to all instances** |
| **Compared with EBS** | EBS is attached to **one instance, one AZ**. EFS is **shared across many instances and AZs**. |

- The diagram leaves out the **database**. A real deployment adds **RDS or Aurora**.
- AWS publishes a **full reference architecture for WordPress**. The lecturer says you should now understand **almost all of it**: NAT gateways, internet gateways, Auto Scaling groups, subnets, Aurora, EFS, and caching.
- The only parts not yet covered: **CloudFront** and **S3** (coming soon).

### 6. Key Facts to Remember

- **Three tiers:** **web/ELB (public)**, **app/ASG (private)**, **data/RDS + ElastiCache (private, deeper)**.
- The **ELB goes in public subnets**. **EC2 and databases go in private subnets.**
- **Route 53** resolves the user's request to the ELB.
- **ELB to ASG instances** through route tables and security groups.
- **ElastiCache** caches RDS data and stores **session data**.
- **LAMP** = **Linux, Apache, MySQL, PHP**. Add **ElastiCache** for caching and **EBS** for local storage.
- **EFS** shares files (such as WordPress images) across instances and AZs. **EBS** is per instance and AZ.
- **Multi-AZ** everywhere gives availability.
- Scenario answers usually combine **ELB + ASG + RDS/Aurora + ElastiCache + Route 53**.

### 7. Exam-Style Recall

| If the question says... | Think... |
|---|---|
| "Typical web app architecture on AWS" | **ELB (public) + ASG (private) + RDS/ElastiCache (data subnets)** |
| "Where should the load balancer go?" | **Public subnets** |
| "Where should EC2 app servers and databases go?" | **Private subnets** |
| "How do users find the ELB?" | **Route 53** DNS (Alias record) |
| "Reduce database load, or keep user sessions across instances" | **ElastiCache** |
| "Make the web tier stateless" | Store sessions in **ElastiCache** (or DynamoDB) |
| "Only the load balancer should reach app servers" | App SG source = **ELB SG**, instances in private subnets |
| "What does LAMP stand for?" | **Linux, Apache, MySQL, PHP** |
| "Add caching to a LAMP stack" | **ElastiCache** (Redis or Memcached) |
| "Share uploaded images across EC2 instances in several AZs" | **EFS** |
| "Shared network file system, ENI in each AZ" | **EFS** |
| "Private instances need to download updates" | **NAT Gateway** in a public subnet |
| "Highly available database tier" | **RDS Multi-AZ** or **Aurora** |
