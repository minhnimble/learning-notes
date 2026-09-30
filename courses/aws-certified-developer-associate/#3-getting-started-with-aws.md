# Getting Started with AWS

---

## AWS Cloud Overview - Regions & AZ

### TL;DR

- AWS was launched internally in **2002**. Public services began in **2004** (SQS preview), then **S3** and **EC2** in **2006**.
- The AWS Cloud is built from **Regions** (geographic areas), each with multiple isolated **Availability Zones (AZs)**, plus **edge locations** (Points of Presence) for content delivery.
- As of 2026: **39 Regions**, **123 AZs**, **750+ Points of Presence**.
- Choose a Region by **compliance**, **latency**, **service availability**, and **pricing**.
- Services are either **Region-scoped** (EC2, Lambda) or **global** (IAM, Route 53, CloudFront).

### 1. History of AWS

| Year | Milestone |
|---|---|
| **2002** | AWS launched, initially for **internal use** at Amazon |
| **2004** | **SQS** (Simple Queue Service) is the first public service (preview) |
| **2006** | **S3** (March) and **EC2** (August) launch, and SQS becomes generally available |

| Metric | Lecture (Q1 2024) | Latest (Q2 2026) |
|---|---|---|
| Revenue | ~$90 billion (annual run rate) | **~$42.2 billion per quarter**, up ~37% year over year |
| Market share | ~31% | ~28% per Synergy Research (other trackers cite ~31%, depending on how the market is defined) |
| Rank | Leader | Still the leader, with Microsoft and Google growing faster |

- Used by enterprises, start-ups, and governments, and it powers well-known sites and apps (Netflix, for example).

### 2. Global Infrastructure

```
AWS Cloud
└── Region (for example eu-west-1)          isolated geographic area
    ├── Availability Zone (eu-west-1a)      one or more data centers
    ├── Availability Zone (eu-west-1b)
    └── Availability Zone (eu-west-1c)
Edge locations / Points of Presence         content delivery and DNS, outside the Regions
```

| Term | Meaning |
|---|---|
| **Region** | A separate geographic area with a name and a code (for example `us-east-1`, `eu-west-3`, `ap-southeast-2`). Regions are **isolated from each other** |
| **Availability Zone (AZ)** | One or more **discrete data centers** in a Region, each with **independent power, cooling, and networking**. Most Regions have **3 or more AZs** (a few have fewer) |
| **Edge location / PoP** | Sites used by **CloudFront**, **Route 53**, and **Global Accelerator** to serve content and requests close to users |
| **Regional edge cache** | A larger cache tier between edge locations and the origin |

- AZs are named per Region (`us-east-1a`, `us-east-1b`) and are far enough apart to avoid **cascading failures** (a fire, flood, or power loss), but close enough for **low-latency, high-bandwidth** links between them.
- **AZ names map to different physical zones in each account.** Your `us-east-1a` may not be another account's `us-east-1a`. The **AZ ID** (for example `use1-az1`) is the same physical location for every account, so use AZ IDs when coordinating across accounts.
- A **Region** is where you deploy. Your data stays in that Region unless you replicate or copy it elsewhere.
- Some Regions are **opt-in** (disabled by default), and you must enable them for your account first.

### 3. Extended Infrastructure

| Type | What it is | Use case |
|---|---|---|
| **Local Zones** | AWS compute and storage in metro areas, near large population centers | Low-latency workloads: video rendering, virtual desktops, gaming |
| **Wavelength Zones** | AWS services at the edge of telecom carriers' **5G** networks | Ultra-low latency for mobile and 5G apps |
| **Outposts** | AWS-managed infrastructure **in your own data center** | Local data processing, hybrid, data residency |

- Counts (2026): 30+ Local Zones, 30+ Wavelength Zones, 13 Regional Edge Caches.

### 4. Choosing a Region

| Factor | Question to ask |
|---|---|
| **Compliance** | Do laws or company policy require data to stay in a country or Region? Data doesn't leave a Region without your action |
| **Latency** | Where are the users? Closer means lower latency |
| **Service availability** | Is every service you need offered there? New services usually reach `us-east-1` first and expand over time |
| **Pricing** | Prices differ by Region. `us-east-1` is typically among the cheapest. `sa-east-1` and `ap-northeast-1` are among the most expensive |

- Cross-Region data transfer is billed, and so is cross-AZ transfer. Traffic within one AZ is free.
- Check the **AWS Regional Services List** to confirm a service or feature exists in your target Region.

### 5. Points of Presence

- **Edge locations** (750+ Points of Presence) sit in many more cities than Regions.
- They **cache content close to users** (CloudFront) and answer DNS queries (Route 53), which reduces latency.
- They are not places to run your application servers.

### 6. Regional vs Global Services

| Scope | Examples | Notes |
|---|---|---|
| **Region-scoped** | EC2, Elastic Beanstalk, Lambda, Rekognition, ECS, RDS, DynamoDB | Choose a Region. Resources exist only there |
| **Global** | **IAM**, **Route 53**, **CloudFront**, AWS WAF (for CloudFront), AWS Organizations, Global Accelerator | No Region selection. Created once, used everywhere |
| **S3** | Buckets | Bucket **names are globally unique**, but each bucket lives in **one Region** |

- Most global services keep their control plane in **`us-east-1`**. For example, an **ACM certificate for CloudFront must be requested in `us-east-1`**.

### 7. Exam-Style Recall

| If the question says... | Think... |
|---|---|
| "One or more discrete data centers with independent power and networking" | **Availability Zone** |
| "Geographic area with multiple isolated AZs" | **Region** |
| "Cache content close to users" | **Edge location** (CloudFront) |
| "Data must stay in a specific country" | Choose a Region there (**compliance**) |
| "Which Region for the lowest latency?" | The Region **closest to the users** |
| "Service isn't available in the Region" | Check **service availability**, or choose another Region |
| "Global services" | **IAM, Route 53, CloudFront, WAF** |
| "Region-scoped services" | **EC2, Lambda, Elastic Beanstalk** |
| "Same AZ name refers to different data centers in two accounts" | Use the **AZ ID** |
| "AWS in my own data center" | **Outposts** |
| "Ultra-low latency to 5G devices" | **Wavelength** |
| "Run AWS closer to a metro area's users" | **Local Zones** |

---

## Tour of the AWS Console & Services in AWS

### TL;DR

- The **Region selector** (top right) sets where new resources are created. Pick one close to you and **stay in the same Region for the whole course**.
- The console home shows **recently visited services** and widgets for **AWS Health**, cost and usage, and getting-started tutorials.
- Find services by **search bar**, by **category**, or alphabetically.
- **Global services** (for example Route 53, IAM) show no Region choice. **Region-scoped** services (for example EC2) depend on the selected Region.

### 1. AWS Console Home

- The **Region selector** sits in the top-right corner. Choosing a Region near you reduces latency.
- The home page shows **recently visited** services, **AWS Health** information, **cost and usage**, and links to tutorials.
- The account menu (top right) leads to **Security credentials**, **Billing**, and **Sign out**.

### 2. Navigating Services

| Method | How |
|---|---|
| **Search bar** | Type the service name (for example "Route 53") to jump straight to it |
| **Services menu** | Browse **by category** (Compute, Storage, Database, and so on) or alphabetically |
| **Recently visited** | Shortcut to services you've used lately |

### 3. Regional vs Global in the Console

| Service | Behavior |
|---|---|
| **Route 53** | **Global.** The Region selector shows "Global" |
| **IAM** | **Global** (see #4) |
| **EC2** | **Region-scoped.** You see only the instances in the selected Region |

- If resources seem to be missing, check that the **Region selector** matches where you created them.

### 4. Staying in One Region

- Resources are Region-specific, and availability, quotas, and pricing differ by Region. Using one Region for the whole course keeps every demo consistent and easy to find.
- Verify a service's availability in your Region on the **AWS Global Infrastructure** Regional Services page if a demo doesn't work as expected.

### 5. Hands-On Checklist

- [x] Open the console and find the **Region selector**
- [x] Switch Regions and observe how the visible resources change
- [x] Review **recently visited**, **AWS Health**, and cost widgets on the home page
- [x] Search for a service (for example **Route 53**) with the search bar
- [x] Browse the **Services** menu by category
- [x] Notice which services are **global** (no Region choice) and which are **Region-scoped**
- [x] Choose a Region to use throughout the course

### 6. Exam-Style Recall

| If the question says... | Think... |
|---|---|
| "Can't see EC2 instances I created" | Wrong **Region** selected |
| "Which console element sets where resources are created?" | **Region selector** |
| "Service with no Region choice" | A **global** service (Route 53, IAM, CloudFront) |
| "Check whether a service exists in a Region" | **AWS Regional Services List** |
