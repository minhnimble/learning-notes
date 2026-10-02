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
