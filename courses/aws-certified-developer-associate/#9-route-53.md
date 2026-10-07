# Route 53

---

## What Is DNS?

### TL;DR

- **DNS (Domain Name System)** translates **human-friendly hostnames** (for example `www.google.com`) into **IP addresses** that computers use.
- It is the **backbone of the internet**. You use it every time you open a website.
- DNS has a **hierarchical naming structure**: root, then **TLD** (`.com`), then **second-level domain** (`example.com`), then **subdomain** (`www.example.com`).
- Lookups are **recursive**: your **local DNS server** asks the **root**, then the **TLD** server, then the **authoritative (second-level) server**, until it gets the answer. It then **caches** the result.
- Key terms to know: **domain registrar, DNS records (A, AAAA, CNAME, NS), zone file, name server, TLD, SLD, FQDN, URL**.
- This is background for **Route 53**, AWS's DNS service.

### 1. What Is DNS?

- DNS = **Domain Name System**.
- It maps **hostnames to the IP addresses of target servers**.
  - Example: you type `www.google.com`, DNS returns an IP address, and the browser connects to that IP to get the data.
- You use it constantly "behind the scenes", but rarely see it.
- Without DNS you would have to remember the IP address of every site.
- DNS uses **port 53** (mostly **UDP**, and **TCP** for large responses and zone transfers).

### 2. Hierarchical Naming Structure

```
.                      <- root
 └── .com              <- top-level domain (TLD)
      └── example.com          <- second-level domain (SLD)
           ├── www.example.com <- subdomain
           └── api.example.com <- subdomain
```

- The hierarchy goes from **most general** (the root, then `.com`) to **most specific** (`api.example.com`).
- Each level is separated by a **dot**, and the **rightmost** label is the **most general**.
- Reading `api.www.example.com` from right to left: `.com`, then `example`, then `www`, then `api`.

### 3. DNS Terminology

| Term | Meaning | Example |
|---|---|---|
| **Domain registrar** | The company where you **register** (buy) a domain name | **Amazon Route 53**, GoDaddy, and others |
| **DNS records** | Entries that say how to resolve a name. They have **types**. | **A, AAAA, CNAME, NS**, and others (covered in the Route 53 section) |
| **Zone file** | A file that **contains all the DNS records** for a domain. It maps hostnames to IPs or other names. | The records for `example.com` |
| **Name server** | A server that **resolves DNS queries** | Route 53 name servers |
| **Top-level domain (TLD)** | The last part of the name | `.com`, `.us`, `.in`, `.gov`, `.org` |
| **Second-level domain (SLD)** | The name just before the TLD (two labels joined by a dot) | `amazon.com`, `google.com` |
| **Subdomain** | A label added in front of a domain | `www.example.com` |
| **FQDN** (Fully Qualified Domain Name) | The **complete** name, from the host to the root | `api.www.example.com.` |
| **Root** | The **trailing dot** at the end of a FQDN. It is the root of all domain names. | `.` |
| **Protocol** | How you talk to the server | `http://` or `https://` |
| **URL** | Protocol plus FQDN plus path | `http://api.www.example.com` |

**Breaking down the lecture example `http://api.www.example.com.`:**

| Part | Name |
|---|---|
| `.` (final dot) | **Root** |
| `.com` | **TLD** |
| `example.com` | **Second-level domain** |
| `www.example.com` | **Subdomain** |
| `api.www.example.com` | **FQDN** |
| `http://` | **Protocol** |
| Everything together | **URL** |

### 4. How a DNS Lookup Works (Lecture Walkthrough)

**Setup:**
- A web server has the public IP **9.10.11.12** (for example an EC2 instance).
- You registered **`example.com`** and want users to reach the server by that name.
- The user's browser wants to open `example.com`.

```
Browser
   |  1. "What is example.com?"
   v
Local DNS server (resolver, from your ISP or company)
   |  2. Not cached --> ask the ROOT server
   v
Root DNS server (ICANN/IANA)
   |  3. "Don't know example.com, but the .com name server is at 1.2.3.4" (NS record)
   v
Local DNS server
   |  4. Ask the .com TLD server at 1.2.3.4
   v
TLD DNS server (.com)
   |  5. "Don't know the record, but the name server for example.com is at 5.6.7.8" (NS record)
   v
Local DNS server
   |  6. Ask the example.com name server at 5.6.7.8
   v
Second-level (authoritative) DNS server (for example Route 53)
   |  7. "example.com is an A record = 9.10.11.12"
   v
Local DNS server
   |  8. Cache the answer, then return it to the browser
   v
Browser  --> connects to 9.10.11.12
```

**Step by step:**

| Step | Who | What happens |
|---|---|---|
| 1 | **Browser** | Asks its **local DNS server**: "What is `example.com`?" |
| 2 | **Local DNS server** | Has never seen this query, so it asks a **root DNS server** |
| 3 | **Root server** | Replies with a **referral**: "I don't know `example.com`, but the **`.com` name server (NS record)** is at `1.2.3.4`" |
| 4 | **Local DNS server** | Asks the **`.com` TLD server** at `1.2.3.4` |
| 5 | **TLD server** | Replies with a referral: "The name server for **`example.com`** is at `5.6.7.8`" |
| 6 | **Local DNS server** | Asks the **second-level (authoritative) server** at `5.6.7.8` |
| 7 | **Authoritative server** | Has the record: "`example.com` is an **A record**, the IP is **9.10.11.12**" |
| 8 | **Local DNS server** | **Caches** the answer and returns it to the browser |
| 9 | **Browser** | Connects to the web server at **9.10.11.12** |

**Key points:**
- The local DNS server finds the answer by **recursively asking** servers, getting **closer and closer** with each step ("the most specific one").
- The **root and TLD servers** don't hold your record. They only point to the **next name server** (using **NS records**).
- The **final server** holds the real record. It is **authoritative** for the domain, and it is the one **Route 53** can act as.
- Caching makes later lookups fast. The **next request for `example.com`** is answered **immediately** from the local DNS server's cache.

### 5. Who Runs Each Server?

| Server | Role | Run by (per the lecture) |
|---|---|---|
| **Local DNS server** (resolver) | First stop for the client. Does the recursive work and **caches**. | Your **company**, or your **ISP** (assigned dynamically) |
| **Root DNS server** | Points to the right **TLD** server | **ICANN** |
| **TLD DNS server** | Points to the right **domain** name server | **IANA** |
| **Second-level / authoritative DNS server** | Holds your **actual DNS records** | Your **domain registrar or DNS provider**, for example **Route 53** |

- The lecture's attribution of the root and TLD servers is a simplification. In practice, **IANA** (a function run by ICANN) manages the **root zone**, and each **TLD registry** (for example Verisign for `.com`) operates its own TLD servers.

### 6. Where Route 53 Fits

- Route 53 can be your **domain registrar** (where you buy `example.com`).
- Route 53 can also host your **DNS zone**, acting as the **authoritative name server** in step 7 above.
- The coming section covers how to **manage a DNS server on your own** with Route 53: record types, routing policies, and health checks.
- Caching duration is controlled by the record's **TTL** (Route 53 section).

### 7. Exam-Style Recall

| If the question says... | Think... |
|---|---|
| "Translate a hostname into an IP address" | **DNS** |
| "Where do you register a domain name?" | **Domain registrar** (for example Route 53) |
| "File or collection of all records for a domain" | **Zone file** |
| "Server that resolves DNS queries" | **Name server** |
| "`.com`, `.org`, `.gov`" | **Top-level domains (TLDs)** |
| "`amazon.com`" | **Second-level domain** |
| "`api.www.example.com`" | **FQDN** (fully qualified domain name) |
| "Record type that points a name to another name" | **CNAME** |
| "Record that says which name servers hold a domain" | **NS record** |
| "Which server first receives the browser's DNS question?" | **Local DNS server** (ISP or company) |
| "Which server holds the final answer for `example.com`?" | **Authoritative (second-level) DNS server** (for example Route 53) |
| "Why is the second lookup of the same domain faster?" | The local DNS server **cached** the answer |
| "AWS service that is both registrar and DNS" | **Amazon Route 53** |

---

## Route 53 Overview

### TL;DR

- **Amazon Route 53** is a **highly available, scalable, fully managed, authoritative DNS** service. "Authoritative" means **you control and update the DNS records**.
- It is also a **domain registrar** and can run **health checks** on your resources.
- It is the **only AWS service with a 100% availability SLA**.
- The name comes from **port 53**, the traditional DNS port.
- A **record** holds: **name, type, value, routing policy, TTL**.
- **Must-know record types:** **A** (name to IPv4), **AAAA** (name to IPv6), **CNAME** (name to another name, **not allowed at the zone apex**), **NS** (name servers of the hosted zone).
- **Hosted zone** = a container of records. **Public** (answers the internet) or **private** (answers only inside your VPCs).
- **Cost:** about **$0.50 per month per hosted zone**, and **domain registration from about $12 per year**. This section is **not free**.

### 1. What Is Route 53?

| Property | Detail |
|---|---|
| **Type** | Managed **authoritative DNS** |
| **Authoritative** | The customer can **create, update, and delete DNS records**, so you have **full control** of the zone |
| **Availability** | **100% availability SLA** (the only AWS service with this) |
| **Scalability** | Fully managed, and it scales automatically |
| **Registrar** | You can **buy and register domain names** (for example `example.com`) |
| **Health checks** | Can **check the health of resources** and use the result in routing (later lectures) |
| **Name origin** | **53** = the traditional **DNS port** |
| **Scope** | **Global** service (not tied to one region) |

**Lecture example:**

```
Client --"example.com?"--> [Route 53 hosted zone]
                              record: example.com  A  54.22.33.44
Client <------ 54.22.33.44 ---+
Client --connects directly--> EC2 instance (public IP 54.22.33.44)
```

- The EC2 instance only has a **public IP**.
- You write a **DNS record** in a **hosted zone** in Route 53.
- When a client asks for `example.com`, Route 53 answers with the IP, and the client connects straight to the instance.
- Route 53 **only answers DNS questions**. It never carries the actual traffic.
- **100% availability SLA**. This is a classic exam fact.

### 2. Anatomy of a DNS Record

Records define **how to route traffic to a domain**. Each record contains:

| Field | Meaning | Example |
|---|---|---|
| **Domain / subdomain name** | The name being resolved | `example.com`, `www.example.com` |
| **Record type** | What kind of data the record holds | `A`, `AAAA`, `CNAME`, `NS` |
| **Value** | The data the name resolves to | `12.34.56.78` |
| **Routing policy** | **How Route 53 responds to queries** | Simple, weighted, latency, and others (later lectures) |
| **TTL** | **Time to live.** How long **DNS resolvers cache** the answer. | `300` seconds |

- A **low TTL** means changes spread faster but there are **more queries**. A **high TTL** means **fewer queries** but **slower propagation** of changes.
- The routing policy decides the **answer**, not the network path.

### 3. Supported Record Types

| Level | Types |
|---|---|
| **Must know for the exam** | **A, AAAA, CNAME, NS** |
| **Advanced (not needed for the exam)** | CAA, DS, MX, NAPTR, PTR, SOA, TXT, SPF, SRV |

#### 3.1 A record

- Maps a **hostname to an IPv4 address**.
- Example: `example.com` to `1.2.3.4`.

#### 3.2 AAAA record

- Same idea as A, but maps a **hostname to an IPv6 address**.
- Pronounced "quad A" (the lecture says "quadruple A").

#### 3.3 CNAME record

- Maps a **hostname to another hostname**.
- The **target hostname** can itself resolve to an **A or AAAA** record.
- **Restriction:** you **can't create a CNAME for the top node of a DNS namespace (the zone apex)**.
  - **Not allowed:** `example.com` as a CNAME.
  - **Allowed:** `www.example.com` as a CNAME.
- The zone apex is also called the **naked domain** or **root domain**.
- The lecture says a future lecture shows how to deal with the apex. The answer is the **Alias record**, a Route 53-specific feature.

| | A / AAAA | CNAME |
|---|---|---|
| Points to | An **IP address** | Another **hostname** |
| Allowed at the zone apex (`example.com`) | **Yes** | **No** |
| Allowed on a subdomain (`www.example.com`) | Yes | Yes |

#### 3.4 NS record

- **Name servers for the hosted zone.**
- The values are the **DNS names of the servers** that can answer queries for your hosted zone.
- They **control how traffic is routed for the domain**, because they tell resolvers where to ask.
- Every hosted zone gets **its own set of 4 name servers** from Route 53.
- When a domain is registered in Route 53, its registrar entry points at the hosted zone's NS records. If you buy the domain elsewhere, you update the **NS records at that registrar** to point to the Route 53 name servers.

### 4. Hosted Zones

- A **hosted zone** is a **container for records**.
- It defines **how to route traffic to a domain and its subdomains**.
- Two types: **public** and **private**.

| | Public hosted zone | Private hosted zone |
|---|---|---|
| **Who can query** | **Anyone on the internet** | **Only resources inside the associated VPC(s)** |
| **Used for** | **Public domain names** | **Internal names** that shouldn't be public |
| **Example** | `application1.mypublicdomain.com` | `application1.company.internal` |
| **Requires** | A registered public domain (or at least delegated NS records) | A **VPC association** |
| **Answers** | The public IP | Usually **private IPs** |

#### 4.1 Public hosted zone

- You buy a public domain such as `mypublicdomain.com` and create a **public hosted zone**.
- It answers queries like "what is the IP of `application1.mypublicdomain.com`?" from any client, for example a **web browser**.

#### 4.2 Private hosted zone

- For names that **aren't publicly available**. Only resources **inside your VPC** can resolve them.
- Like the private corporate URLs you can open only on the company network.
- Behind the scenes there is a **private DNS record**.
- You **associate** the private hosted zone with **one or more VPCs**. The VPC needs **DNS support and DNS hostnames enabled** (`enableDnsSupport` and `enableDnsHostnames`).

**Lecture example:**

| Resource | Private name | Private IP |
|---|---|---|
| EC2 instance 1 | `webapp.example.internal` | |
| EC2 instance 2 | `api.example.internal` | `10.0.0.10` |
| Database | `database.example.internal` | |

```
EC2 (webapp) --"api.example.internal?"--> [Private hosted zone] --> 10.0.0.10
EC2 (api)    --"database.example.internal?"--> [Private hosted zone] --> private IP of the DB
```

1. The web app instance asks for `api.example.internal`.
2. The private hosted zone answers with `10.0.0.10`.
3. The API instance then asks for `database.example.internal`.
4. The private hosted zone answers with the database's private IP, and the instance connects directly.

- **Public and private hosted zones work the same way.** The only difference is **who can query them**: anyone on the internet (public) or only your VPC resources (private).
- **Split-view (split-horizon) DNS:** you can have a **public and a private zone with the same domain name**. VPC clients get the private answers and the internet gets the public ones.

### 5. Costs

| Item | Price (per the lecture) |
|---|---|
| **Hosted zone** | **$0.50 per month** each |
| **Domain registration** | From about **$12 per year**, depending on the TLD |
| **Queries and health checks** | Billed separately, per use |

- The lecturer's warning: **this section is not free.** Delete hosted zones you don't need.
- Prices vary by TLD (`.com` is more than some others), and AWS can change them.
- Domain registration is **not refundable**, and registered domains **auto-renew** by default.
- You can also **transfer** a domain in or out of Route 53.

### 6. Exam-Style Recall

| If the question says... | Think... |
|---|---|
| "Highly available, scalable, fully managed, authoritative DNS" | **Route 53** |
| "Only AWS service with a 100% availability SLA" | **Route 53** |
| "Why is it called Route 53?" | **DNS port 53** |
| "Map a hostname to an IPv4 address" | **A record** |
| "Map a hostname to an IPv6 address" | **AAAA record** |
| "Map a hostname to another hostname" | **CNAME** |
| "Create a CNAME for `example.com`" | **Not allowed** (zone apex). Use an **Alias record**. |
| "Create a CNAME for `www.example.com`" | **Allowed** |
| "Which servers answer queries for the hosted zone?" | **NS records** |
| "How long resolvers cache a record" | **TTL** |
| "Container of DNS records for a domain" | **Hosted zone** |
| "Resolve names only from inside a VPC" | **Private hosted zone** |
| "Names like `app.company.internal`" | **Private hosted zone** |
| "Answer queries from the public internet" | **Public hosted zone** |
| "How Route 53 decides which answer to return" | **Routing policy** |
| "Cost of a hosted zone" | **$0.50 per month** |

---

## Route 53 - Registering a Domain

### 1. Where to Start

- Console: **Route 53**, **Registered domains** (left menu), **Register domains**.
- Use the **new console experience** (the lecturer says it is what you'll see going forward).
- **Registered domains** and **Hosted zones** are two separate lists:
  - **Registered domains** = domains you **bought** through Route 53.
  - **Hosted zones** = **containers of DNS records**.
- The lecturer's account already had a domain and a hosted zone from earlier use. **Yours will be empty.**

### 2. Registration Flow

1. **Search for a domain name**. Enter a name nobody else has taken.
2. The console shows **availability and price** for different TLDs. In the demo, the chosen name was available for **US $13 per year**.
3. **Select** the domain, which puts it in your **basket**.
4. **Proceed to checkout**.
5. Choose the **duration** (for example **1 year**) and the **auto-renew** setting.
6. Fill in **contact information**.
7. Enable **privacy protection**.
8. **Review**, accept the **terms and conditions**, and **submit**. This is the point where you are charged.
9. Wait for the registration to complete, then **verify** it (section 4).

### 3. Key Settings

#### 3.1 Duration and auto-renew

| Setting | Detail |
|---|---|
| **Duration** | Number of years to register (for example 1 year) |
| **Auto-renew** | **On:** the domain **renews automatically** each year. **Off:** it **expires** at the end of the term. |

- **Keep auto-renew on** if you intend to keep using the domain. If it lapses, **someone else can buy it**, which is a real risk for a production domain.
- Turn it **off** if you only want the domain for the course.
- Auto-renew is **on by default** in the console, so uncheck it if you don't want another charge.

#### 3.2 Contact information

- **Pre-populated** from your account, and you can change it.
- Three contacts: **registrant**, **admin**, and **tech**. The admin and tech contacts can be the **same as the registrant**.
- This information is required by domain registration rules (**ICANN**).
- **Verify your email:** AWS sends a **verification email** to the registrant contact. If you don't click the link in time, the domain can be **suspended**.

#### 3.3 Privacy protection

- **Enable it.** It **hides your real contact details** (address, phone, email) from the public **WHOIS** database.
- It protects you from **spam** and unwanted solicitation.
- Route 53 provides privacy protection at **no extra cost** for most TLDs. Some TLDs don't support it.

### 4. Verifying the Registration

- Registration is **not instant**. It can take **a few minutes to a few hours** (occasionally longer).
- To confirm, go to **Hosted zones** and open your domain's hosted zone.

#### 4.1 What you should see

| Record | Purpose |
|---|---|
| **NS** | Lists the **4 AWS name servers** that answer DNS queries for this domain. It says "use the **AWS DNS** (Route 53) to answer queries". |
| **SOA** | **Start of Authority**. Administrative information about the zone (primary name server, contact, serial number, refresh timers). Created automatically. |

- The lecturer's own zone had **4 records** because of earlier use. A fresh one has **2**: NS and SOA.
- **Don't delete the NS or SOA records.** They are required for the zone to work.

#### 4.2 What this means

- Because the domain's NS records point to Route 53, **any DNS records you add to this hosted zone** (for example an A record) are what the internet sees.
- **Route 53 is the source of truth** for the domain's DNS.
- The next lecture covers **creating records** in the hosted zone.

### 5. Exam-Style Recall

| If the question says... | Think... |
|---|---|
| "Register a domain name in AWS" | **Route 53 registered domains** |
| "Domain registered in Route 53, DNS records managed where?" | The **hosted zone** created for it |
| "What two records exist in a new hosted zone?" | **NS** and **SOA** |
| "What does the NS record in a hosted zone indicate?" | The **name servers** that answer queries for the domain |
| "Hide personal contact info for a domain" | **Privacy protection** |
| "Domain must not be lost accidentally at year end" | Keep **auto-renew on** |
| "Domain registration fee is charged how often?" | **Yearly** |

---

## Route 53 - Creating Our First Records

### 1. Creating the Record

#### 1.1 Steps in the console

1. Route 53, **Hosted zones**, open your domain's hosted zone.
2. Click **Create record**.
3. **Record name**: `test` (the console appends the domain, giving `test.<your-domain>`).
4. **Record type**: **A** (route a hostname to an **IPv4 address**).
5. **Value**: `11.22.33.44`.
6. **TTL**: **300 seconds** (default).
7. **Routing policy**: **Simple routing**.
8. Click **Create records**.

#### 1.2 Notes

- You can enter **multiple IP addresses** in the value box (one per line). With simple routing, the client gets **all of them** and picks one.
- You can create several records at once with **Add another record**.
- Choosing a TTL: a **lower** value means changes spread faster but there are more queries. A **higher** value means fewer queries but slower change propagation.

### 2. What Happens When You Query It

1. A client asks for `test.<domain>`.
2. The query goes through the normal DNS chain (local resolver, root, TLD) to the **hosted zone's name servers** (Route 53).
3. Route 53 answers: "`test.<domain>` is an **A record** with value **11.22.33.44**".
4. The resolver **caches** the answer for the **TTL** (300 s).

- **Opening the URL in a browser doesn't work.** No server exists at `11.22.33.44`.
- This shows that **DNS resolution and reaching the server are separate steps**. The DNS answer is correct even when nothing is listening at the IP.
- To make the URL work, the A record must point to a **real server** (for example an EC2 instance), and that server must allow the traffic (security group, web server running).
- **Route 53 answers DNS queries only.** Whether the destination actually works is a separate matter.

### 3. Testing from the Command Line

#### 3.1 Why CloudShell?

- The lecturer uses **AWS CloudShell** so everyone has the **same Linux environment**.
- Open it with the **CloudShell** icon in the top bar of the management console.
- You can use your own terminal instead:

| Your OS | Command |
|---|---|
| **Windows** | `nslookup` |
| **Mac / Linux** | `dig` (and `nslookup`) |

#### 3.2 Installing the tools (CloudShell)

`nslookup` and `dig` are **not installed** by default in CloudShell. They come in one package:

```bash
sudo yum install -y bind-utils
```

- The transcript says "bind minus utils". The package name is **`bind-utils`**.
- If `yum` isn't available (newer CloudShell images are based on Amazon Linux 2023), use `sudo dnf install -y bind-utils`.

#### 3.3 `nslookup`

```bash
nslookup test.<your-domain>
```

- Returns the **resolved address**: `test.<your-domain>` resolves to **11.22.33.44**, matching the record.
- The server line shows **which DNS resolver answered**.

#### 3.4 `dig`

```bash
dig test.<your-domain>
```

- The lecturer prefers `dig` because it shows more detail.
- Look at the **ANSWER SECTION**:

```
;; ANSWER SECTION:
test.<your-domain>.   300   IN   A   11.22.33.44
```

| Column | Meaning |
|---|---|
| `test.<your-domain>.` | The **record name** (the trailing dot is the DNS root) |
| `300` | The **TTL** (seconds remaining in the cache) |
| `IN` | Class: **Internet** |
| `A` | The **record type** |
| `11.22.33.44` | The **value** |

- **TTL behavior:** run `dig` repeatedly. The TTL **counts down** (299, 280, ...) while the resolver serves the cached answer, then resets to 300 when it expires.
- Useful variants:

```bash
dig +short test.<your-domain>            # just the IP
dig test.<your-domain> A                 # ask for a specific record type
dig NS <your-domain>                     # show the hosted zone's name servers
dig @<route53-ns-server> test.<your-domain>   # query Route 53 directly (skips caches)
```

- Querying a Route 53 name server directly with `@` shows the **authoritative** answer and **avoids stale cache**, which is helpful right after you change a record.

### 4. Troubleshooting Checklist

| Symptom | Likely cause |
|---|---|
| `nslookup` or `dig` says **command not found** | Install **`bind-utils`** |
| **NXDOMAIN** (name doesn't exist) | Typo in the record name, wrong hosted zone, or the domain's **NS records** don't point to this hosted zone |
| Answer shows the **old value** after a change | The resolver is **caching** it until the **TTL** expires |
| DNS resolves but the **browser times out** | DNS is fine. The **server or security group** is the problem. |
| Domain just registered and nothing resolves | Registration or propagation may still be in progress (minutes to hours) |
| Record created in the wrong zone | Public vs private hosted zone mix-up. Check the **zone type** and **VPC association**. |

### 5. Exam-Style Recall

| If the question says... | Think... |
|---|---|
| "Default routing policy" | **Simple routing** |
| "Tool to test DNS resolution on Windows" | **`nslookup`** |
| "Tool to test DNS resolution on Mac/Linux, shows TTL" | **`dig`** |
| "DNS resolves correctly but the website doesn't load" | **Server / security group** problem, not DNS |
| "DNS change isn't visible yet" | **Cached** until the TTL expires |
| "Which record would you use to point to a real EC2 public IP?" | **A record** |
| "Browser-based terminal in the AWS console" | **CloudShell** |

---

## Route 53 - EC2 Setup

### 1. Why This Setup?

- Route 53 routing policies (simple, weighted, latency, failover, geolocation, and others) need **multiple endpoints in different places** to show different answers.
- The "Hello from AZ ..." page shows **which instance (and region) answered**, so you can see a routing policy working.
- The lecture's note: **keep the IPs and regions handy**. You will paste them into Route 53 records later.

| Resource | Region | Purpose in later demos |
|---|---|---|
| **EC2 instance 1** | `eu-central-1` (Frankfurt) | A record target |
| **EC2 instance 2** | `us-east-1` (N. Virginia) | A record target |
| **EC2 instance 3** | `ap-southeast-1` (Singapore) | A record target |
| **ALB** (`DemoRoute53ALB`) | `eu-central-1` (Frankfurt) | **Alias record** target |

### 2. Launching the EC2 Instances

Repeat the same steps in **each of the three regions**. Switch region with the **region selector** in the console's top-right corner.

#### 2.1 Settings used

| Setting | Value | Notes |
|---|---|---|
| **AMI** | Amazon Linux 2 (x86) | **Amazon Linux 2023** works too (see the IMDSv2 note below). |
| **Instance type** | `t2.micro` | Free tier eligible |
| **Key pair** | **None** ("proceed without a key pair") | Use **EC2 Instance Connect** if you need shell access |
| **Security group** | **Create new**, allow **HTTP (80)** from anywhere | The Frankfurt instance also allowed **SSH (22)** |
| **User data** | The Route 53 bootstrap script from the course resources | See section 2.2 |

#### 2.2 User data script

The lecture's script is the same "Hello World" server as before, plus a line that reads the **AZ** from the instance metadata (the transcript calls it an environment variable `EC2_AVAIL_ZONE`).

```bash
#!/bin/bash
yum update -y
yum install -y httpd
systemctl start httpd
systemctl enable httpd
EC2_AVAIL_ZONE=$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone)
echo "<h1>Hello World from $(hostname -f) in AZ $EC2_AVAIL_ZONE</h1>" > /var/www/html/index.html
```

- `169.254.169.254` is the **instance metadata service (IMDS)**, reachable only from inside the instance.
- On **Amazon Linux 2023**, **IMDSv2** is required by default, so the plain `curl` above returns nothing. Fetch a token first:

```bash
TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
EC2_AVAIL_ZONE=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/placement/availability-zone)
```

- User data runs **once, at first boot, as root**.

#### 2.3 Why you repeat the steps per region

- **EC2 instances, security groups, key pairs, and AMI IDs are all regional.**
- A security group created in Frankfurt **does not exist** in N. Virginia, so you create a new one in each region.
- The console picks the **right AMI for the region** automatically. The AMI **ID differs** per region even for the same image.
- **User data** sets up the web server on first boot, and the page shows the **AZ** so you can tell instances apart.

### 3. Creating the ALB (Frankfurt)

#### 3.1 Load balancer settings

| Setting | Value |
|---|---|
| **Type** | **Application Load Balancer** |
| **Name** | `DemoRoute53ALB` |
| **Scheme / IP type** | **Internet-facing**, **IPv4** |
| **Network mapping** | VPC plus **3 subnets** (3 AZs) |
| **Security group** | The existing `launch-wizard-2` group, which allows **HTTP** (and SSH). This guarantees port 80 is open. |
| **Listener** | **HTTP : 80**, forward to a new target group |

- An ALB needs subnets in **at least 2 AZs**.
- A load balancer can have **up to 5 security groups**.

#### 3.2 Target group

| Setting | Value |
|---|---|
| **Type** | **Instances** |
| **Name** | `demo-tg-route53` |
| **Targets** | The **Frankfurt EC2 instance** (**Include as pending below**, then **Create target group**) |

- Back in the ALB wizard: **refresh** the target group dropdown, select `demo-tg-route53`, and create the load balancer.
- Provisioning takes a few minutes, and the state goes **Provisioning** to **Active**.

**Why an ALB only in Frankfurt?**
- An ALB is **regional** and **can only target resources in its own region**.
- It is the endpoint for the **Alias record** demo later (alias to an ALB).
- Its target group holds **one instance**, so every request returns the same "Hello" page.
- Public IPv4 addresses of EC2 instances **change on stop/start**. Use an **Elastic IP** for a stable address.

### 4. Verifying Everything

| Check | URL | Expected response |
|---|---|---|
| Frankfurt instance | `http://<public-ipv4>` | Hello from AZ **`eu-central-1b`** |
| N. Virginia instance | `http://<public-ipv4>` | Hello from AZ **`us-east-1a`** |
| Singapore instance | `http://<public-ipv4>` | Hello from AZ **`ap-southeast-1b`** |
| ALB | `http://<alb-dns-name>` | Hello from **`eu-central-1b`** (the only target) |

- **Use `http://`**. Browsers may try HTTPS and fail, because nothing listens on 443.
- The ALB can take a few minutes to become reachable. The lecturer says it can fail for a while, so wait for **Active** and for the target to turn **healthy**.
- Record the results in a text file:

```
eu-central-1     <public-ip>   eu-central-1b
us-east-1        <public-ip>   us-east-1a
ap-southeast-1   <public-ip>   ap-southeast-1b
ALB (eu-central-1)  <alb-dns-name>
```

### 5. Exam-Style Recall

| If the question says... | Think... |
|---|---|
| "Is Route 53 regional?" | **No**, it is a **global** service |
| "Can an ALB send traffic to EC2 in another region?" | **No.** ALBs are regional. Use **Route 53** (or Global Accelerator) across regions. |
| "Security group created in one region, needed in another" | **Create it again.** Security groups are regional. |
| "Where does an instance read its own AZ or ID?" | **Instance metadata** at `169.254.169.254` |
| "Run a script once when an instance first boots" | **User data** |
| "Which metadata version is required by default on AL2023?" | **IMDSv2** (token based) |
| "Multi-region endpoints behind one domain name" | **Route 53 routing policies** |
| "Public IP of an instance changes

---

## Route 53 - TTL

### TL;DR

- **TTL (Time To Live)** is how long, in seconds, a DNS answer may be **cached** by clients and DNS resolvers before they ask Route 53 again.
- While the answer is cached, **no new DNS query is sent**, so Route 53 sees less traffic. The trade-off is that a changed record isn't visible until the cache expires.
- **High TTL** (for example 24 hours) means **less Route 53 traffic and lower cost**, but **slow propagation** of changes and a risk of **outdated records**.
- **Low TTL** (for example 60 seconds) means **more queries and higher cost**, but **changes show up quickly**.
- **Strategy for a planned change:** lower the TTL first, wait for the old TTL to expire, change the record, then raise the TTL again.
- **TTL is mandatory on every record, except Alias records** (covered next lecture).
- The demo showed it live: after a record was edited, `dig` and the browser kept returning the **old IP** until the TTL ran out.

### 1. What Is TTL?

| Property | Detail |
|---|---|
| **Meaning** | **Time To Live**: how long a DNS answer may be cached |
| **Unit** | **Seconds** |
| **Set on** | Each **DNS record** |
| **Console default** | **300 seconds** (5 minutes) |
| **Who caches** | **Recursive DNS resolvers** (ISP or company), plus the **OS and browser** cache |
| **Required?** | **Yes for every record, except Alias records** |

- The lecture says "clients" cache the result. In practice the **local DNS resolver** does most of the caching, and the OS and browser can cache too.
- The TTL is sent **inside the DNS answer**. It tells the resolver: "keep this for N seconds".

### 2. How TTL Works (Lecture Flow)

```
Client --"myapp.example.com?"--> [Route 53]
Client <-- A record: 12.34.56.78, TTL = 300 --

Client caches the answer for 300 seconds
   |
   +-- request within 300 s: answered from cache, NO query to Route 53
   |
   +-- request after 300 s: cache expired, ask Route 53 again
   |
   v
Client --HTTP request--> web server at 12.34.56.78
```

1. The client asks Route 53 for `myapp.example.com`.
2. Route 53 answers with the **A record** (the IP) and a **TTL** (for example 300 s).
3. The client **caches** it for that time.
4. Within the TTL, the client **reuses the cached IP** and sends no DNS query.
5. After the TTL expires, it asks Route 53 again.

- **Why this design:** records rarely change, so asking DNS on every request would be wasteful.
- The HTTP connection to the web server is separate from DNS, and TTL only affects the **lookup**.

### 3. High TTL vs Low TTL

| | **High TTL** (for example 24 hours) | **Low TTL** (for example 60 seconds) |
|---|---|---|
| **DNS query volume** | **Low** | **High** |
| **Route 53 cost** | **Lower** (billed per query) | **Higher** |
| **Load on DNS** | Light | Heavy |
| **Speed of record changes** | **Slow.** You may wait up to the full TTL for everyone to see the new value. | **Fast** |
| **Risk of outdated records** | **High** | Low |
| **Ease of changing records** | Harder | **Easier** |
| **Good for** | **Stable** records that rarely change | Records you **change often**, or need to **fail over quickly** |

- There is no single right value. It is a trade-off between **cost and load** and **agility**.
- Route 53 charges **per million standard queries**, so a very low TTL on a busy domain adds up. Queries to **Alias records that point at AWS resources** are free.
- **Failover and health-check-based routing** work best with a **low TTL** (for example 60 s), so clients move to the healthy endpoint quickly.

### 4. Strategy for Changing a Record Safely

When you plan to change a record's value (for example migrating to a new server):

1. **Lower the TTL** well ahead of time (for example from 24 hours to 60 seconds).
2. **Wait at least the old TTL** (24 hours in this example), so every cache holds the **new low TTL**.
3. **Change the record value.** It now reaches everyone within about 60 seconds.
4. **Raise the TTL back** to a higher value to cut query volume.

```
TTL 24h --> lower to 60s --> wait 24h --> change the IP --> raise TTL again
```

- **Step 2 matters.** If you change the value right after lowering the TTL, clients that cached the old record under the **old 24-hour TTL** still hold the old IP until that expires.
- The same logic applies to **any migration, cutover, or failover plan**.

### 5. Demo: Watching TTL in Action

#### 5.1 Setup

1. Create a new **A record** in the hosted zone: `demo.<your-domain>`.
2. **Value:** the **public IP of the Frankfurt (`eu-central-1`) EC2 instance** from the previous lecture.
3. **TTL: 120 seconds** (two minutes). The console TTL field has increment buttons, and the lecturer clicked the minute button twice.
4. Create the record.

#### 5.2 Verify it works

- Opening `demo.<your-domain>` in the browser shows the **Frankfurt instance** ("Hello from `eu-central-1`").
- The lecturer used Chrome, because Firefox gave him a problem with this plain-HTTP domain that he didn't resolve.
- Check with CloudShell:

```bash
nslookup demo.<your-domain>     # the address matches the record
dig demo.<your-domain>          # shows the answer plus the TTL counting down
```

#### 5.3 TTL counting down

| Time | `dig` ANSWER SECTION TTL | Meaning |
|---|---|---|
| First `dig` | **~115** | Answer just cached. 120 s minus a few seconds. |
| A bit later | **98** | Cache still valid, **TTL counts down** |
| Edit made, then `dig` again | **66** | Still the **old cached answer**, even though Route 53 now has a new value |

- The number in the answer is the **remaining cache time**, not the configured TTL.

#### 5.4 Change the record while cached

1. Quickly **edit the record**: change the IP to the **Singapore (`ap-southeast-1`) instance**.
2. Run `dig` again: it **still shows the old IP**, with the TTL still counting down.
3. Refresh the Chrome tab: it **still shows "Hello from `eu-central-1`"**.

The record is updated in Route 53, but the client **keeps using its cached copy** until the TTL expires.

#### 5.5 After the TTL expires

1. Wait about another minute, until the cache expires.
2. Refresh the browser: **"Hello from `ap-southeast-1b`"**, the new instance.
3. Run `dig` again: the **TTL resets to 120** and shows the **new IP**.

**Lesson:** to see a DNS change, you often just have to **wait out the TTL**. Route 53 is not "slow". The cache holds the old answer.

### 6. Practical Notes

- **Browser and OS caches** can hold a record **separately** from the resolver. If a change still doesn't show, restart the browser or flush the OS DNS cache.
- Query a Route 53 name server directly to see the **current authoritative answer** and skip the caches:

```bash
dig @<route53-name-server> demo.<your-domain>
```

- TTL does **not** control how long an HTTP connection or a load balancer target lasts. It only controls the **DNS lookup cache**.
- Some resolvers apply their own **minimum or maximum TTL**, so the real expiry can differ a bit from the configured value.
- **NS records** in a hosted zone usually have a long TTL (the Route 53 default is **172,800 s, which is 48 hours**), so delegation changes at a registrar can take a long time to spread.

### 7. Exam-Style Recall

| If the question says... | Think... |
|---|---|
| "Reduce the number of DNS queries and cost" | **Increase the TTL** |
| "Change a DNS record and have clients see it quickly" | **Lower the TTL** (ideally before the change) |
| "I changed the record, but clients still hit the old IP" | The **old answer is cached** until the TTL expires |
| "Which record type doesn't need a TTL?" | **Alias record** |
| "Best practice before migrating to a new server IP" | **Lower the TTL, wait, change the record, raise the TTL** |
| "Downside of a very high TTL" | **Slow propagation** and outdated records |
| "Downside of a very low TTL" | **More queries and higher cost** |
| "Command that shows the remaining TTL" | **`dig`** |
| "TTL for fast DNS failover" | **Low** (for example 60 s) |

---

## Route 53 - CNAME vs Alias

### TL;DR

- **Problem:** AWS resources (ELB, CloudFront, and others) expose an AWS-generated hostname. You want your own name (for example `myapp.mydomain.com`) to point to it.
- **CNAME:** points a hostname to **any other hostname**. It works only for **non-root (subdomain)** names. It is **rejected at the zone apex** (`mydomain.com`).
- **Alias:** a **Route 53-specific** record that points a hostname to a **specific AWS resource**. It works at the **zone apex and on subdomains**.
- **Alias extras:** **free queries** (to AWS resources), a **native health check** option (**Evaluate target health**), **TTL set automatically** (you can't set it), and it **follows IP changes** of the target automatically.
- **Alias record type:** always **A or AAAA** (for the exam).
- **Not a valid Alias target:** an **EC2 DNS name**.
- **Exam favorite:** "Point the root domain (`example.com`) at an ALB/CloudFront" means **Alias A record**, not CNAME.

### 1. The Problem

- Many AWS resources give you a **generated DNS name**, for example `my-alb-123456.eu-central-1.elb.amazonaws.com`.
- You want users to reach it through **your own domain**, for example `myapp.mydomain.com`.
- Route 53 gives you **two options**: **CNAME** or **Alias**.

```
myapp.mydomain.com  --(CNAME or Alias)-->  my-alb-123456.eu-central-1.elb.amazonaws.com  -->  ALB  -->  EC2
```

### 2. CNAME Record

| Property | Detail |
|---|---|
| **What it does** | Maps a hostname to **any other hostname** |
| **Example** | `app.mydomain.com` to `blabla.anything.com` |
| **Target** | Any domain name (AWS or not) |
| **Standard DNS?** | **Yes.** It works with any DNS provider. |
| **Zone apex (`mydomain.com`)** | **Not allowed** |
| **Subdomain (`app.mydomain.com`)** | Allowed |
| **TTL** | **You set it** (required) |
| **Query cost** | **Billed** per query |
| **Health checks** | No native target health evaluation |

- The lecture's rule: it only works with a **non-root domain name** (`something.mydomain.com`).
- A CNAME also **can't share a name with other record types**. This is another reason it can't live at the apex, which always holds NS and SOA records.
- Resolving a CNAME needs an **extra lookup** (name to name, then name to IP).

### 3. Alias Record

| Property | Detail |
|---|---|
| **What it does** | Maps a hostname to a **specific AWS resource** |
| **Example** | `app.mydomain.com` to `blabla.amazonaws.com` |
| **Standard DNS?** | **No.** It is a **Route 53 extension** to DNS. |
| **Zone apex (`mydomain.com`)** | **Allowed** |
| **Subdomain** | Allowed |
| **Record type** | **A** (IPv4) or **AAAA** (IPv6) |
| **TTL** | **Can't be set.** Route 53 sets it automatically. |
| **Query cost** | **Free** for queries to supported AWS resources |
| **Health checks** | **Native**: the **Evaluate target health** option |
| **IP changes** | **Handled automatically.** If the ALB's IPs change, the alias follows. |

- Clients see a normal **A/AAAA answer** with IP addresses. The alias is resolved **inside Route 53**, so it is invisible to them.
- Choose **A** for an ALB that is IPv4-only. Create an **AAAA** alias as well for dualstack or IPv6 targets.

### 4. Alias Targets

**Valid targets:**

| Target | Notes |
|---|---|
| **Elastic Load Balancers** (ALB, NLB, CLB) | The console picks the **region**, then the load balancer |
| **CloudFront distributions** | Great for the apex of a CDN-fronted site |
| **API Gateway** | Custom domain endpoints |
| **Elastic Beanstalk environments** | |
| **S3 websites** | A bucket with **static website hosting enabled**, **not a plain S3 bucket** |
| **VPC interface endpoints** | |
| **Global Accelerator accelerators** | |
| **Another Route 53 record in the same hosted zone** | |

**Not a valid target:**

| Target | Why |
|---|---|
| **EC2 DNS name** | Not supported. Use an **A record** with the instance's public IP (ideally an **Elastic IP**) instead. |

- The lecture says some of these appear later in the course, and that it is fine if you haven't seen them yet.
- An alias to an ALB, NLB, CloudFront, and so on **tracks the target's IP changes** with no action from you.

### 5. CNAME vs Alias

| Feature | **CNAME** | **Alias** |
|---|---|---|
| **Works at the zone apex** | **No** | **Yes** |
| **Works on subdomains** | Yes | Yes |
| **Target** | Any hostname | **AWS resources only** |
| **Standard DNS feature** | Yes | **Route 53 only** |
| **Record type** | CNAME | **A or AAAA** |
| **TTL** | You set it | **Automatic** |
| **Query charges** | **Yes** | **Free** (to AWS resources) |
| **Health check** | No | **Evaluate target health** |
| **Follows resource IP changes** | Yes (through the hostname) | Yes (automatically) |
| **EC2 DNS name as target** | Yes (it is just a hostname) | **No** |

### 6. Demo Walkthrough

All three records point to the **ALB** from the EC2 setup lecture (`DemoRoute53ALB` in `eu-central-1`). A test in the browser returns the "Hello World" page from the instance behind it.
 
#### 6.1 CNAME record (subdomain)

1. Hosted zone, **Create record**.
2. **Name:** `myapp`, so the full name is `myapp.<your-domain>`.
3. **Type:** **CNAME**.
4. **Value:** the **ALB's DNS name** (copy it from the load balancer page).
5. Create it, then open `myapp.<your-domain>` in the browser: the instance's "Hello World" appears.

- It works, but it is **not AWS-native**. It would work the same way for any domain name.

#### 6.2 Alias record (subdomain)

1. **Create record**, name `myalias`.
2. **Type:** **A**, because the ALB has only IPv4.
3. Turn on the **Alias** toggle.
4. **Route traffic to:** **Alias to Application and Classic Load Balancer**.
5. **Region:** `eu-central-1`, then choose the load balancer.
6. **Evaluate target health:** **Yes**.
7. Create it. Opening `myalias.<your-domain>` gives the same response.

- This record is **free to query**.
- In the console, a **Network Load Balancer** is a separate option in the same dropdown ("Alias to Network Load Balancer").

#### 6.3 CNAME at the zone apex (fails)

1. **Create record** with the **name left empty** (so it is `<your-domain>` itself).
2. **Type:** **CNAME**, **value:** the ALB DNS name.
3. Result: **"Bad request. CNAME is not permitted at apex of this zone."**

#### 6.4 Alias at the zone apex (works)

1. **Create record**, name **empty**.
2. **Type:** **A**, **Alias** on, **Alias to Application and Classic Load Balancer**, region `eu-central-1`, choose the same ALB.
3. Create it. It is **accepted**.
4. Opening `<your-domain>` in a new tab returns the "Hello World" page.

**Takeaway:** the apex needs an **Alias**. The lecturer stresses this is something the exam may test.

### 7. Exam-Style Recall

| If the question says... | Think... |
|---|---|
| "Point `example.com` (root domain) to an ALB" | **Alias A record** |
| "Point `example.com` to a CloudFront distribution" | **Alias** |
| "CNAME for the root domain" | **Not allowed** (zone apex) |
| "Map `www.example.com` to another hostname" | **CNAME** (or Alias if the target is an AWS resource) |
| "Route 53 record with no query charges for AWS resources" | **Alias** |
| "Record with native health checking" | **Alias** (Evaluate target health) |
| "Can I set the TTL on an Alias record?" | **No**, Route 53 sets it |
| "Alias record types" | **A and AAAA** |
| "Alias target: EC2 instance DNS name" | **Not supported** |
| "Alias target: S3 bucket" | Only if **static website hosting** is enabled |
| "Alias to another record in the same hosted zone" | **Supported** |
| "DNS extension that is specific to Route 53" | **Alias** |
| "Error: CNAME not permitted at apex of this zone" | Use an **Alias** instead |

---

## Routing Policy - Simple

### TL;DR

- A Route 53 **routing policy** decides **how Route 53 answers DNS queries**. It is **not traffic routing** like a load balancer. **No traffic flows through DNS.** Route 53 only returns an answer, and the client then connects to the endpoint itself.
- Route 53 supports these policies: **simple, weighted, failover, latency-based, geolocation, multi-value answer, geoproximity** (and IP-based routing).
- **Simple routing** returns the value(s) of a record to the client. It is typically used for **a single resource**.
- You can put **multiple values** in one simple record. Route 53 returns **all of them**, and the **client picks one at random**.
- A simple record with an **Alias** can target **only one AWS resource**.
- Simple routing **can't be associated with health checks**.

### 1. Routing Policies: What They Are (and Aren't)

- A routing policy **helps Route 53 respond to DNS queries**.
- The word "routing" is misleading:
  - A **load balancer** receives traffic and forwards it to backend instances.
  - **DNS never sees the traffic.** It only translates a hostname into an endpoint (an IP or another name).
  - The **client** then sends its HTTP request to that endpoint directly.

```
Client --"foo.example.com?"--> [Route 53]
Client <--------- answer ------ [Route 53]     <- the policy decides this answer
Client --HTTP request---------> the endpoint   <- Route 53 is not in this path
```

**Policies in this section:**

| Policy | One-line idea |
|---|---|
| **Simple** | Return the record's value(s), no logic (this lecture) |
| **Weighted** | Split traffic by percentage |
| **Failover** | Primary and secondary, driven by health checks |
| **Latency-based** | Send users to the lowest-latency region |
| **Geolocation** | Answer based on the user's location |
| **Multi-value answer** | Return several healthy values |
| **Geoproximity** | Route by geographic distance, with an adjustable bias |
| **IP-based** | Route by the client's IP range (CIDR). Not in the lecture. |

- The lecture covers each in the following lectures.

### 2. Simple Routing Policy

#### 2.1 What it does

- Routes to **a single resource** (typically).
- This is the policy used in the earlier demos (the default when you create a record).
- Example: the client asks for `foo.example.com`, and Route 53 answers with an **A record** pointing to one IP.

#### 2.2 Multiple values in one record

- A simple record **can hold several values** (for example three IP addresses).
- Route 53 **returns all values** in the response.
- The **client picks one at random** (client-side choice).

```
Client --"foo.example.com?"--> [Route 53]
Client <-- A record: 1.1.1.1, 2.2.2.2, 3.3.3.3 --
Client picks ONE of them at random and connects
```

- This is **crude load distribution**, with no server-side control and no health awareness. If one IP is dead, the client may still pick it.
- Route 53 also **shuffles the order** of the values it returns.

#### 2.3 Alias with simple routing

- With an **Alias** record under simple routing, you can specify **only one AWS resource** as the target.
- Multiple values only work for **non-alias** records (A, AAAA, and so on, with explicit values).

#### 2.4 No health checks

- It is called "simple" because it is. You **can't attach health checks** to a simple record.
- Route 53 will keep returning the value even if the endpoint is down.
- For health-aware behavior use **failover**, **weighted**, **latency**, **geolocation**, or **multi-value answer**.

### 3. Demo: Simple Routing in the Console

#### 3.1 Create the record

1. Hosted zone, **Create record**.
2. **Name:** `simple`, so the full name is `simple.<your-domain>`.
3. **Type:** **A**.
4. **Value:** the public IP of the **Singapore (`ap-southeast-1`)** instance.
5. **TTL:** **20 seconds** (low on purpose, so changes show up quickly).
6. **Routing policy:** **Simple routing**.
7. Create it.

- The console shows the routing policy choices in the dropdown. The lecturer says there are six there, with a seventh handled elsewhere in the UI (**geoproximity** in **Traffic Flow**). The exact list varies with the console version.

#### 3.2 Test with the browser and `dig`

- Opening `simple.<your-domain>` returns "Hello World" from **`ap-southeast-1b`**.
- In CloudShell, `dig` was missing again because the session had been restarted, so reinstall it:

```bash
sudo yum install -y bind-utils
dig simple.<your-domain>
```

- The ANSWER SECTION shows an **A record, TTL 20**, with the one IP.

#### 3.3 Add a second value

1. Edit the record.
2. In the **Value** box enter **two IPs**, one per line: the Singapore instance and the **N. Virginia (`us-east-1`)** instance.
3. Save.
4. After the old **20 s TTL** expires, run `dig` again:

```
;; ANSWER SECTION:
simple.<your-domain>.   20   IN   A   <singapore-ip>
simple.<your-domain>.   20   IN   A   <virginia-ip>
```

- `dig` now shows **two A answers**. Route 53 returns both.
- **The client chooses.** Refreshing the browser gives about a **one in two chance** of each instance.

#### 3.4 Result

- First refresh: still **`ap-southeast-1b`** (by chance, or the old cached answer).
- After waiting out the 20 s TTL and refreshing: **"Hello from `us-east-1a`"**.
- This shows simple routing with multiple values: **all values returned, random client-side pick.**

### 4. Exam-Style Recall

| If the question says... | Think... |
|---|---|
| "Route 53 returns the record value with no special logic" | **Simple routing** |
| "A record with multiple IP values, client chooses" | **Simple routing** |
| "Who picks among multiple values returned by simple routing?" | The **client**, at random |
| "Routing policy that can't use health checks" | **Simple** |
| "Simple routing with an Alias: how many targets?" | **One** AWS resource |
| "Does Route 53 route the actual traffic?" | **No.** It only answers DNS queries. |
| "Return multiple IPs, but only healthy ones" | **Multi-value answer**, not simple |
| "Is multi-value answer a replacement for an ELB?" | **No** |
| "Which policy would you use for one web server?" | **Simple** |

---

## Routing Policy - Weighted

### TL;DR

- **Weighted routing** lets you control the **percentage of DNS responses** that go to each resource by assigning each record a **weight**.
- Traffic share for a record = **its weight ÷ the sum of all weights** (for records with the same name and type). Weights **don't need to add up to 100**.
- Records in a weighted set must have the **same name and the same type**. Each record has a **Record ID** (set identifier) to tell them apart.
- Each record can have a **health check**. Unhealthy records are skipped.
- A weight of **0** stops sending traffic to that record. If **all** records have weight 0, Route 53 returns them **with equal weights**.
- **Use cases:** load balancing across regions, **testing a new application version** with a small share of traffic, and gradually **shifting traffic** over time.
- It is still **DNS-level**. Route 53 only varies the **answers**. Each answer is cached for the **TTL**, so the split is approximate.

### 1. What Is Weighted Routing?

- You assign a **relative weight** to each record. Route 53 answers queries in proportion to those weights.
- Lecture example: three EC2 instances with weights **70, 20, 10**.

| Instance | Weight | Share of DNS responses |
|---|---|---|
| EC2 #1 | 70 | **70%** |
| EC2 #2 | 20 | **20%** |
| EC2 #3 | 10 | **10%** |

```
                         70%  --> EC2 #1
Client --> [Route 53] -- 20%  --> EC2 #2     (percent of DNS ANSWERS, not of traffic)
                         10%  --> EC2 #3
```

- The weights above sum to 100 only for convenience. **They don't have to.**
- Example: weights **1, 1, 2** give 25%, 25%, 50%.
- **Formula:** `share = record weight / sum of all weights in the set`.

### 2. Rules and Requirements

| Rule | Detail |
|---|---|
| **Same name and type** | All records in the weighted set share the **same DNS name** and **record type** (for example all `weighted.example.com` type A) |
| **One value per record** | Each weighted record is **its own record** with its own value. This differs from a simple record, which holds several values in one record. |
| **Record ID** | A **unique identifier** for each record within the set (the console calls it **Record ID**, the API calls it **SetIdentifier**) |
| **Weight range** | **0 to 255** per record |
| **Health checks** | **Optional**, one per record |
| **TTL** | Set on each record. Use the **same TTL** across the set. |
| **Alias** | Weighted records can be **Alias records** (for example to different ALBs) |

- The share is of **DNS responses**, not of actual requests or bytes.
- Because of **caching**, one client or resolver gets the same answer until the TTL expires. Real traffic splits approach the weights only across **many clients**.

### 3. Special Weight Behavior

| Situation | What happens |
|---|---|
| **Weight = 0** | Route 53 **stops returning** that record, so no traffic is sent to it |
| **All records weight = 0** | All records are returned **with equal weights** |
| **Unhealthy record (health check fails)** | It is **skipped**, and the remaining records share its traffic by weight |
| **All records unhealthy** | Route 53 treats them all as **healthy** and answers anyway (fail-open) |

- Setting a weight to **0** is a common way to **drain** a resource without deleting its record.
- **Shifting weight over time** gives a gradual migration: for example 100/0, then 90/10, then 50/50, then 0/100.

### 4. Use Cases

| Use case | How |
|---|---|
| **Load balancing across regions or endpoints** | Spread answers across several servers or ALBs |
| **Canary or blue/green testing** | Send **a small percentage (for example 5-10%)** to the new version and watch it |
| **Gradual migration** | Shift weight from the old stack to the new one over time |
| **Pause a resource** | Set its weight to **0** |
| **Cost or capacity control** | Send more traffic to the bigger or cheaper endpoint |

- It is **not** a replacement for a real load balancer. It spreads **DNS answers**, with no awareness of load, connections, or session state.

### 5. Demo: Creating Weighted Records

#### 5.1 The three records

All three use the **same name**: `weighted.<your-domain>`, **type A**, **routing policy Weighted**, **TTL 3 seconds**.

| Record ID | Value (instance) | Weight | Share |
|---|---|---|---|
| `southeast` | `ap-southeast-1` instance IP | **10** | 10% |
| `US East` | `us-east-1` instance IP | **70** | 70% |
| `EU` | `eu-central-1` instance IP | **20** | 20% |

#### 5.2 Steps

1. Hosted zone, **Create record**.
2. **Name:** `weighted`, **type:** A, **routing policy:** **Weighted**.
3. **Value:** the Singapore instance IP. **Weight:** `10`. **TTL:** `3`. **Record ID:** `southeast`. **Health check:** none for now.
4. Click **Add another record**. Repeat with the **same name**, value = the US East IP, **weight 70**, **Record ID** `US East`.
5. Add the third: value = the Frankfurt IP, **weight 20**, **Record ID** `EU`.
6. **Create records**.

- The hosted zone now lists **three records** with the same name. Compare simple routing: **one record** with multiple values.
- **TTL 3 s** is for the demo only. In real life that causes a lot of DNS queries and cost.

#### 5.3 Testing

- **Browser:** opening `weighted.<your-domain>` first returned **`us-east-1a`**, which fits the 70% weight. Refreshing (about every 3 s, once the TTL expires) occasionally returned another region.
- **`dig`:**

```bash
dig weighted.<your-domain>
```

- Each `dig` returns **one record** (TTL 3). The first answers were the US East IP. A later one returned a different IP (the Frankfurt one, the 20% weight), and the browser also landed on **`eu-central-1c`**.
- Takeaway: most answers go to the **heaviest record**, but **every so often** you get the others.

**Why the browser doesn't change on every refresh:** the answer is **cached for the TTL**, browsers also cache DNS and reuse connections, and with a **70% weight** most answers are the same anyway. Use `dig` repeatedly (or a script) to see the distribution.

- Lower the **TTL** before shifting weights so the change takes effect faster.

### 6. Weighted vs Simple (and Other Policies)

| | **Simple** | **Weighted** |
|---|---|---|
| **Records** | **One** record with one or more values | **Several records**, same name and type, one value each |
| **Who chooses** | The **client**, at random (if multiple values) | **Route 53**, by weight |
| **Control over the split** | None | **Percentage control** |
| **Health checks** | **No** | **Yes** |
| **Record ID needed** | No | **Yes** |

### 7. Exam-Style Recall

| If the question says... | Think... |
|---|---|
| "Send 10% of traffic to a new version" | **Weighted routing** |
| "Control the percentage of traffic to each resource" | **Weighted routing** |
| "Weights must sum to 100" | **False** |
| "Stop sending traffic to one endpoint without deleting the record" | Set its **weight to 0** |
| "All records have weight 0" | Returned **with equal weights** |
| "What must the records in a weighted set share?" | The same **name and type** |
| "Identifies each record in a weighted set" | **Record ID** (SetIdentifier) |
| "Weight 70, 20, 10: share of the weight-20 record" | **20%** |
| "Weights 1, 1, 2: share of the weight-2 record" | **50%** |
| "Weighted routing with health checks" | **Supported** |
| "Gradually shift traffic between regions or versions" | **Weighted routing**, with a low TTL |

---

## Routing Policy - Latency

### TL;DR

- **Latency-based routing** answers DNS queries with the record for the **AWS region that gives the user the lowest latency**. Use it when **latency is your main concern**.
- Latency is **measured between the user (their network or DNS resolver) and AWS regions**. It is **not the same as geographic distance**, and it can change over time.
- Example from the lecture: a user in Germany whose lowest latency is to a US region is sent to the US.
- Records in the set share the **same name and type**. Each needs a **Region** and a **Record ID** (set identifier).
- For records with a **plain IP value**, you must **specify the region yourself**. Route 53 can't tell which region an IP belongs to.
- Can be combined with **health checks**. If the lowest-latency record is unhealthy, Route 53 answers with the **next-best healthy region**.
- Still **DNS-level**: Route 53 only chooses the **answer**. It carries no traffic.

### 1. What Is Latency-Based Routing?

- Route 53 returns the resource that has the **lowest latency** for the client, meaning the one "closest" in network terms.
- It is useful for **global applications** deployed in multiple regions.

| Property | Detail |
|---|---|
| **Decision** | The region with the **lowest measured latency** to the user |
| **What it measures** | Latency between **user networks** and **AWS regions** (Route 53 maintains this data) |
| **Region per record** | **Required.** You choose which AWS region each record represents. |
| **Health checks** | **Optional**, one per record |
| **Alias support** | **Yes** |
| **Record requirements** | Same **name and type**, a unique **Record ID** each, and one **Region** each |

**Lecture map example:**

```
Deployed in: us-east-1 and ap-southeast-1
Users near/lower latency to us-east-1       --> answered with the us-east-1 record
Users near/lower latency to ap-southeast-1  --> answered with the ap-southeast-1 record
```

### 2. Latency Is Not the Same as Geography

- The **closest region on a map** is **usually**, but **not always**, the lowest-latency one. Internet routing, peering, and congestion all affect it.
- Latency measurements are **updated over time**, so the same user can be sent to a different region later.
- Compare with **geolocation** routing (next lectures), which uses the user's **location**, not measured latency.

### 3. Important Detail: Whose Latency Is Used?

- Route 53 normally sees the **DNS resolver's** address, not the end user's.
  - If the user's resolver is far from the user (for example a public resolver), the answer may be tuned to the **resolver's** location.
  - If the resolver supports **EDNS Client Subnet**, Route 53 can use part of the **client's** IP range instead.
- This is why the lecture's test location matters (section 5).

### 4. Demo: Creating Latency Records

#### 4.1 The three records

All use the **same name**: `latency.<your-domain>`, **type A**, **routing policy Latency**.

| Record ID | Value (instance) | Region setting |
|---|---|---|
| `ap-southeast-1` | Singapore instance IP | **Asia Pacific (Singapore) `ap-southeast-1`** |
| `us-east-1` | N. Virginia instance IP | **US East (N. Virginia) `us-east-1`** |
| `eu-central-1` | Frankfurt instance IP | **Europe (Frankfurt) `eu-central-1`** |

#### 4.2 Steps

1. Hosted zone, **Create record**.
2. **Name:** `latency`, **type:** A, **value:** the Singapore IP.
3. **Routing policy:** **Latency**.
4. **Region:** `ap-southeast-1` (Singapore). Required, because the record holds a **raw IP**.
5. **Record ID:** `ap-southeast-1` (just a label). **Health check:** none for now.
6. **Add another record** and repeat for `us-east-1`, and again for `eu-central-1`.
7. **Create records.** (The lecturer briefly picked "Weighted" for the second record by mistake and corrected it to Latency.)

**Why you must specify the Region:**
- The record value is just an IP, and an IP **can be anywhere in the world**.
- Route 53 can't tell it is an EC2 instance in Singapore, so **you** declare which region the endpoint is in.
- The lecturer put this as "Alias is not smart enough". More precisely, **Route 53 doesn't infer a region from an IP**, and the Region field tells it where the endpoint lives.

### 5. Demo: Testing It

| Test location | Method | Result |
|---|---|---|
| **Europe** (lecturer's real location) | Browser | **Hello from `eu-central-1c`** |
| **Europe** | `dig` in **CloudShell** (which runs in `eu-central-1`) | **One** answer: the Frankfurt IP. Repeating gives the same value. |
| **Canada** (via VPN) | Browser refresh | **Hello from `us-east-1a`** (lowest latency to the US) |
| **Canada** (via VPN) | `dig` in CloudShell | **Still Frankfurt**, because CloudShell hasn't moved |
| **Hong Kong** (via VPN) | Browser refresh | **Hello from `ap-southeast-1b`** |

**What this shows:**
- Unlike simple routing with several values, **each DNS answer contains only one record**: the lowest-latency one.
- Answers **change with the user's location**, not at random.
- **The VPN worked** because changing location also **cleared the local DNS cache**, so the browser asked Route 53 again right away.
- **`dig` from CloudShell didn't change** because CloudShell sits in `eu-central-1` and is still closest to Frankfurt. To see a different answer from the command line, run `dig` from a machine in another region (for example CloudShell in `us-east-1`).

**Other ways to test:**
- Run CloudShell or an EC2 instance in **different regions** and use `dig`.
- Use an online **multi-location DNS checker**.
- Use `dig +subnet=<client-ip>/24 <name>` against a resolver or Route 53 name server that supports **EDNS Client Subnet**.
- Answers can change as **latency measurements change** and when the **TTL cache** expires.

### 6. Health Checks and Failover Behavior

- Attach a **health check** to each latency record.
- If the **lowest-latency** record is **unhealthy**, Route 53 returns the **next-lowest-latency healthy** record.
- If **all** records are unhealthy, Route 53 **fails open** and returns an answer anyway.
- Health checks are covered in the **next lecture**.
- Alias records can use **Evaluate target health** instead of a separate health check.

### 7. Routing Policies Compared

| Policy | Chooses the answer by | Typical use |
|---|---|---|
| **Simple** | Nothing. The client picks among the values. | One resource |
| **Weighted** | **Percentages** you set | Splits, canaries, migrations |
| **Latency** | **Lowest measured latency** to a region | **Fast global performance** |
| **Failover** | **Health** (primary and secondary) | Active-passive DR |
| **Geolocation** | The user's **location** (country or continent) | Localization, legal or content restrictions |
| **Geoproximity** | **Distance** with an adjustable **bias** | Shift load between regions |
| **Multi-value answer** | Up to 8 **healthy** records | Client-side balancing with health awareness |
| **IP-based** | The client's **IP range (CIDR)** you define | Known networks and ISPs |

- **Latency** = fastest experience. **Geolocation** = content rules by location. They are often confused on the exam.
- Latency is **measured**, so it is **not strictly geography**.

### 8. Exam-Style Recall

| If the question says... | Think... |
|---|---|
| "Route users to the region with the lowest latency" | **Latency routing** |
| "Global app deployed in multiple regions, performance is the priority" | **Latency routing** |
| "Direct users by country or continent" | **Geolocation**, not latency |
| "Percentage-based split" | **Weighted** |
| "Primary and standby with health checks" | **Failover** |
| "What must you set on a latency record with an IP value?" | The **Region** |
| "Lowest-latency region is unhealthy" | Route 53 returns the **next lowest-latency healthy** record |
| "Is latency routing based on geographic distance?" | **No.** It is based on **measured network latency**. |
| "How many values does a latency answer contain?" | **One** record |
| "Does Route 53 forward the user's traffic to the closest region?" | **No.** It only returns the DNS answer. |
| "Can a latency record be an Alias?" | **Yes** |

---

## Route 53 Health Checks

### TL;DR

- **Route 53 health checks** monitor the health of **mainly public resources**. They enable **automated DNS failover**: unhealthy endpoints stop being returned in DNS answers.
- You attach a health check to a **DNS record** (failover, weighted, latency, geolocation, multi-value, and so on). **Simple routing records can't use them.**
- **Three types:**
  1. **Endpoint health check:** monitors a public application, server, or AWS resource.
  2. **Calculated health check:** combines the results of **other health checks** (child checks) into one parent.
  3. **CloudWatch alarm health check:** follows the state of a **CloudWatch alarm**. This is the way to monitor **private resources**.
- **Endpoint checks** come from **about 15 global health checkers**. Healthy if **more than 18%** of them report healthy.
- **Interval:** **30 s** (standard) or **10 s** (fast, higher cost). **Protocols:** **HTTP, HTTPS, TCP**.
- **Pass condition (HTTP/HTTPS):** status **2xx or 3xx**. Optional **text matching** in the first **5,120 bytes** of the response.
- You must **allow the health checker IP ranges** in your firewall or security group, or the check fails.
- Health checks publish **CloudWatch metrics**.

### 1. Why Health Checks?

- **Scenario from the lecture:** two public load balancers in **different regions**, each fronting the same app, for **multi-region high availability**.
- Route 53 DNS records (for example **latency** records) send users to the closest load balancer.
- **Problem:** if one region goes down, Route 53 would still send users there.
- **Solution:** create a **health check for each endpoint** and **associate it with the matching DNS record**.
  - A **healthy** record is returned in answers.
  - An **unhealthy** record is **left out**, and users get the other region.
- Result: **automated DNS failover** with no manual change.

```
                     +--> health check A --> ALB (region 1)
Route 53 records ----+
 (with health checks)+--> health check B --> ALB (region 2)

Unhealthy endpoint's record is not returned in DNS answers.
```

- Route 53 still only **changes the DNS answer**. Clients with the old answer cached keep using it until the **TTL** expires, so use a **low TTL** (for example 60 s) on records that fail over.

### 2. The Three Types of Health Check

| Type | Monitors | Typical use |
|---|---|---|
| **Endpoint** | A **public endpoint**: application, server, or AWS resource (by IP or domain name) | Public ALB, EC2, website |
| **Calculated** | **Other health checks** (children), combined into one result | Combine many checks, or do maintenance |
| **CloudWatch alarm** | A **CloudWatch alarm's state** | **Private resources**, or any custom metric |

- Health checks have **their own CloudWatch metrics**, visible in CloudWatch.
  - Examples: **`HealthCheckStatus`** (1 healthy, 0 unhealthy) and **`HealthCheckPercentageHealthy`**.
  - Route 53 metrics are in the **`us-east-1` (N. Virginia)** region.
- You can attach **CloudWatch alarms and SNS notifications** to a health check, to be alerted when it fails.

### 3. Endpoint Health Checks

#### 3.1 How they work

- Health checkers are located **around the world**. The lecture says **about 15 health checkers**, not just one.
- Each sends requests to your **public endpoint** on the path and port you define.
- If it gets the expected response (for example **200 OK** or another 2xx/3xx), that checker counts the endpoint as healthy.
- Route 53 then combines all the checkers' results.

```
       ~15 global health checkers
   (Americas, Europe, Asia Pacific, ...)
          |  |  |  |  |
          v  v  v  v  v
       [ Public endpoint (ALB / EC2 / site) ]

Healthy if MORE THAN 18% of checkers say healthy
```

#### 3.2 Settings

| Setting | Detail |
|---|---|
| **Endpoint** | **IP address** or **domain name** (public) |
| **Protocol** | **HTTP, HTTPS, TCP** |
| **Port / path** | For example port `80`, path `/health` |
| **Request interval** | **30 seconds** (standard) or **10 seconds** (**fast health check**, costs more) |
| **Failure threshold** | How many **consecutive** failures mark the endpoint unhealthy. Range **1-10**, default **3**. |
| **Health checker locations** | You can **choose which regions** the checkers run from |
| **String matching** | Optional text to look for in the response |
| **Invert health check status** | Flips the result (healthy becomes unhealthy and the reverse) |
| **Latency graph** | Records latency measurements so you can chart latency over time (extra cost) |
| **Disabled** | Stops checking, and the check is treated as healthy |

#### 3.3 The 18% rule

- Route 53 considers the endpoint **healthy** if **more than 18%** of the health checkers report it healthy. Otherwise it is **unhealthy**.
- The threshold is **low on purpose**: if a few checkers have network trouble, a healthy endpoint isn't marked down. It also means an endpoint reachable from only a few places can still count as healthy.

#### 3.4 What counts as healthy

| Protocol | Healthy when |
|---|---|
| **HTTP / HTTPS** | Response status is **2xx or 3xx** |
| **HTTP / HTTPS with string matching** | **2xx/3xx** and the text is found in the response |
| **TCP** | The checker can **open a TCP connection** |

- **String matching (text-based responses):** Route 53 checks the **first 5,120 bytes** of the response body for your text. If the text isn't in that part, the check **fails**. Use it to confirm the app is really working, not just that the web server answers.
- **HTTPS checks** don't verify the certificate by default. Route 53 **doesn't require a valid certificate** unless you enable the SNI option.

#### 3.5 Network requirements (important)

- The checkers come from the **public internet**, so they must be able to **reach your endpoint**.
- You must **allow incoming requests from the Route 53 health checker IP ranges** in your **security group**, **NACL**, or firewall.
- Find the ranges in the **AWS IP address ranges file** (`ip-ranges.json`), where the **service is `ROUTE53_HEALTHCHECKS`**. The lecture shows the URL on screen.
- If the ranges are blocked, the check **fails and the record is marked unhealthy**, even if the app is fine.
- Note that **many global checkers hitting your endpoint** causes **a lot of access-log entries**, which is normal.

### 4. Calculated Health Checks

- **Idea:** combine the results of **multiple health checks into a single health check**.
- Structure:

```
                 [ Parent health check ]
                  /        |          \
          [child 1]    [child 2]    [child 3]
              |            |            |
            EC2 #1       EC2 #2       EC2 #3
```

| Property | Detail |
|---|---|
| **Children** | **Up to 255** child health checks |
| **Condition** | **OR**, **AND**, or "**at least N** children must pass" |
| **NOT** | Use **Invert health check status** to flip a result |
| **Child checks** | Can be **endpoint checks**, and so on |

- You choose **how many children must be healthy** for the parent to be healthy. "Any one" is **OR**. "All" is **AND**.
- The lecture lists "OR, AND, or NOT". In the console, the AND/OR logic comes from the **threshold count**, and NOT comes from **inversion**.
- **Use case from the lecture:** do **maintenance** on your site without making every health check fail.
  - Example: take child checks offline one at a time while the **parent stays healthy** (for example "at least 2 of 3 must pass").
  - Attach the **parent** to the DNS record, so DNS doesn't fail over during planned work.
- Another use: say "the site is healthy only if the **web, API, and database** checks all pass" (AND).

### 5. Monitoring Private Resources (CloudWatch Alarm Health Checks)

#### 5.1 The problem

- The Route 53 health checkers are on the **public internet, outside your VPC**.
- They **can't reach private endpoints**: resources in a **private subnet**, a **private VPC**, or **on premises**.

#### 5.2 The solution

```
Private EC2 instance (private subnet)
        |  emits metric
        v
[ CloudWatch metric ] --> [ CloudWatch alarm ] --> [ Route 53 health check ]
                              |                           |
                      state = ALARM  ----------------->  health check = UNHEALTHY
```

1. **Monitor** the private resource with a **CloudWatch metric**. This can be a built-in metric (CPU, status check) or a **custom metric**.
2. Create a **CloudWatch alarm** on that metric.
3. Create a Route 53 **health check that monitors the alarm**.
4. When the metric breaches the threshold and the alarm goes into **ALARM**, the **health check becomes unhealthy**.
5. Attach the health check to the DNS record, so Route 53 **stops returning it**.

- This is the **most common way** to health check a **private resource**.
- **State mapping:** `OK` means healthy and `ALARM` means unhealthy. For **`INSUFFICIENT_DATA`** you choose healthy, unhealthy, or last known status.
- It gives **more control**, because any metric can drive health: queue depth, error rate, application metrics, and so on.
- The CloudWatch alarm must be in a region that **Route 53 can read**. The alarm and the health check are linked by **alarm name and region**.

### 6. Health Checks and DNS Records

| Topic | Detail |
|---|---|
| **Which routing policies** | **Failover, weighted, latency, geolocation, geoproximity, multi-value answer** (and IP-based). **Not simple.** |
| **Attaching** | Select the health check when creating the record |
| **Alias records** | Use **Evaluate target health** (instead of a separate health check) for supported AWS targets |
| **Effect** | Unhealthy records are **omitted** from answers |
| **All unhealthy** | Route 53 **fails open** and returns **all records** anyway |
| **Caching** | Clients keep the old answer until the **TTL** expires |

- A health check can be **shared** by several records.
- **Failover routing** (next lecture) is the policy built around health checks: **primary** and **secondary** records.

### 7. Cost Notes

- Health checks are **billed per check per month**, with higher prices for **non-AWS endpoints**, **fast (10 s) interval**, **HTTPS**, **string matching**, and **latency measurement** options.
- **Calculated** and **CloudWatch alarm** health checks have their own (lower) pricing.
- Check the current Route 53 pricing page for numbers.

### 8. Exam-Style Recall

| If the question says... | Think... |
|---|---|
| "Automatically stop sending users to an unhealthy region" | **Route 53 health check** on the record |
| "Route 53 health check for a private EC2 instance / on-premises resource" | **CloudWatch alarm health check** |
| "Why can't Route 53 health checkers reach my private instance?" | They run on the **public internet**, outside the VPC |
| "Combine multiple health checks into one" | **Calculated health check** |
| "Maximum child health checks in a calculated check" | **255** |
| "Perform maintenance without failing all health checks" | **Calculated (parent) health check** |
| "Percentage of health checkers that must report healthy" | **More than 18%** |
| "Health check interval options" | **30 s** (standard) and **10 s** (fast) |
| "Protocols for Route 53 health checks" | **HTTP, HTTPS, TCP** |
| "Status codes considered healthy" | **2xx and 3xx** |
| "How many bytes are checked for text matching?" | **First 5,120 bytes** |
| "Health check fails but the app is fine" | Health checker **IP ranges blocked** by the SG/firewall |
| "Where do you find the health checker IP ranges?" | **`ip-ranges.json`**, service **`ROUTE53_HEALTHCHECKS`** |
| "View health check status as metrics" | **CloudWatch** (`us-east-1`) |
| "Health check for an Alias record to an ELB" | **Evaluate target health** |
| "Health check state when its CloudWatch alarm is in ALARM" | **Unhealthy** |
| "Check that the response contains specific text" | **String matching** (first 5,120 bytes) |
| "Check faster than every 30 seconds" | **Fast interval (10 s)**, at higher cost |
| "Mark unhealthy only after repeated failures" | **Failure threshold** |
| "See how latency to the endpoint changes over time" | **Enable latency measurements** (latency graph) |
| "Temporarily stop a health check without deleting it" | **Disable** it (it is then treated as healthy) |
| "Reverse a check's result" | **Invert health check status** |
| "Be alerted by email when a health check fails" | Create the **alarm and SNS notification** on the health check |
| "Parent healthy only if all children are healthy" | **Calculated health check** (AND) |
| "Parent healthy if at least one child is healthy" | **Calculated health check** (OR) |
| "Does creating a health check change DNS answers?" | **No.** It must be **attached to a record**. |

---

## Route 53 - Health Checks Hands On

### 1. Starting Point

- Reuses the 3 EC2 instances from the EC2 setup lecture:

| Region | Role in this demo |
|---|---|
| `us-east-1` (N. Virginia) | Health check target #1 |
| `ap-southeast-1` (Singapore) | Health check target #2 (the one we break on purpose) |
| `eu-central-1` (Frankfurt) | Health check target #3 |

- Each instance already runs a web server and has **HTTP (80) open to the world** in its security group. That is what lets the health checkers reach it.
- Console path: **Route 53, Health checks, Create health check**.

### 2. Creating an Endpoint Health Check

#### 2.1 Configuration used

| Setting | Demo value | Notes |
|---|---|---|
| **Name** | e.g. `us-east-1` | Just a label. The lecturer names each check after its region. |
| **What to monitor** | **Endpoint** | The other two choices are covered in sections 5 and 6 |
| **Specify endpoint by** | **IP address** | The other choice is **domain name** |
| **IP address** | The instance's public IPv4 | |
| **Protocol** | HTTP | HTTPS and TCP are also available |
| **Port** | **80** | The HTTP port |
| **Path** | `/` | The website root. Real apps often use a dedicated path such as `/health`. |

- **Path `/`:** the lecturer notes `/` is the same as the root of the site. In a real app, `/health` is common, because it can return the real health of the app and its dependencies.
- **IP vs domain name:** an EC2 public IP **changes on stop/start**, which would break the check. Use an **Elastic IP**, or check by **domain name**.

- Advanced options were left at defaults: standard **30 s** interval, failure threshold **3**, no string matching, latency graph, invert, or disable, and the recommended checker regions. A fast interval or the extra options cost more.

#### 2.2 Alarm notification (last step)

- The wizard offers to **notify you when the check fails** (a CloudWatch alarm with an SNS topic). The demo chose **No**.

### 3. Creating the Three Checks

| Health check | Endpoint | Port / path |
|---|---|---|
| `us-east-1` | N. Virginia instance IP | 80 and `/` |
| `ap-southeast-1` | Singapore instance IP | 80 and `/` |
| `eu-central-1` | Frankfurt instance IP | 80 and `/` |

- Repeat the wizard for each one: name, **IP address** (not hostname), **Next**, then **Create health check**.
- After creation, the list shows each check's **status** (Unknown, then **Healthy**) and the **monitored endpoint**.

### 4. Simulating a Failure

#### 4.1 Break the Singapore instance

1. EC2 (in `ap-southeast-1`), open the instance's **security group**.
2. **Edit inbound rules**, then **delete the HTTP rule** and save.
3. The instance is still running, but **port 80 is now blocked**.

#### 4.2 Watch the health check

- Wait a bit for the checkers to run. Because of the **failure threshold (3) and 30 s interval**, it takes **roughly a minute or two** to flip.
- Result in the console:
  - `ap-southeast-1` shows **Unhealthy**.
  - `us-east-1` and `eu-central-1` stay **Healthy**.
- Open the unhealthy check to see:
  - **Last checked** timestamps and the **status by health checker region**.
  - **View last failed check:** the error was a **connection timeout**.

#### 4.3 What the timeout tells you

- Other typical causes:

| Failure message | Likely cause |
|---|---|
| **Connection timed out** | SG, NACL, or firewall blocking the health checker IPs |
| **Connection refused** | Instance reachable but nothing listening on the port |
| **HTTP status code 5xx/4xx** | App error or wrong path |
| **String match failed** | Response didn't contain the expected text |

### 5. Calculated Health Check

#### 5.1 Steps

1. **Create health check**, name it (e.g. `calculated`).
2. **What to monitor:** **Status of other health checks (calculated health check)**.
3. **Select the child health checks:** the three created above.
4. **Report healthy when:** choose how many children must be healthy:
   - **Any one or more** of the selected checks (**OR**)
   - **At least N** of the selected checks
   - **All** of the selected checks (**AND**)
5. The demo chose **all** (**AND**).
6. **Next**, **Create**.

#### 5.2 Result

- The calculated check showed **Unhealthy**, because **one child (Singapore) is unhealthy**, and "all must be healthy" fails.

### 6. CloudWatch Alarm Health Check (Not Created)

- **Not created** in the demo: no CloudWatch alarm existed in the account (create the alarm first).
- The form asks for the **alarm's region**, the **alarm**, and what to do on **insufficient data** (healthy, unhealthy, or last known status).

---

## Routing Policy - Failover

### TL;DR

- **Failover routing** is **active-passive** disaster recovery at the DNS level. Route 53 returns the **primary** record while it is healthy, and the **secondary** record when the primary is unhealthy.
- **Exactly one primary and one secondary** per record name.
- The **primary must have a health check** (mandatory). The **secondary's health check is optional**.
- Both records share the **same name and type**, and each has a **Failover record type** (Primary or Secondary) and a **Record ID**.
- Failover and **failback** are automatic. When the primary's health check passes again, Route 53 returns the primary again.
- Use a **low TTL** (the demo used **60 s**), because clients cache the old answer until the TTL expires.
- Route 53 only changes the **DNS answer**. It never carries the traffic.

### 1. What Is Failover Routing?

- Route 53 sits in the middle, with two resources behind it:
  - A **primary** (for example an EC2 instance).
  - A **secondary** (disaster recovery), for example an EC2 instance in another region.
- The primary record is associated with a **health check**.
- If the health check becomes **unhealthy**, Route 53 **automatically fails over** and answers DNS queries with the secondary record.
- The client simply gets whichever resource is **deemed healthy**.

```
                    healthy?
Client --> [Route 53] --yes--> Primary record   (EC2, eu-central-1)
                      --no---> Secondary record (EC2, us-east-1)
```

| State | Answer returned |
|---|---|
| **Primary healthy** | **Primary** |
| **Primary unhealthy** (secondary healthy, or no health check on it) | **Secondary** |
| **Primary recovers** | **Primary** again (**failback**) |

### 2. Rules and Requirements

| Rule | Detail |
|---|---|
| **Count** | **One primary and one secondary** only |
| **Primary health check** | **Mandatory** |
| **Secondary health check** | **Optional**. If attached and the secondary is unhealthy too, Route 53 can't usefully fail over. |
| **Same name and type** | Both records use the same DNS name and the same record type (for example A) |
| **Record ID** | A unique identifier per record in the set |
| **TTL** | Set per record. Keep it **low** (for example 60 s). |
| **Alias** | Supported. For Alias records, use **Evaluate target health** instead of a separate health check. |
| **Health check types** | Endpoint, calculated, or CloudWatch alarm (the last works for private resources) |

- **Both unhealthy:** Route 53 fails open and still returns an answer (the primary, per AWS docs) rather than nothing.
- For more than two tiers or finer control, combine failover with other policies using **Traffic Flow** or **nested records** (for example weighted or latency records, each with a failover pair).
- Route 53 **doesn't proxy traffic** during failover. Clients just get a different IP.

### 3. Demo: Creating the Failover Records

Uses the **health checks** from the previous lecture (`eu-central-1`, `us-east-1`, `ap-southeast-1`).

#### 3.1 Primary record

| Setting | Value |
|---|---|
| **Name** | `failover.<your-domain>` |
| **Type** | **A** |
| **Value** | `eu-central-1` instance IP (the instance closest to the lecturer) |
| **TTL** | **60 s** |
| **Routing policy** | **Failover** |
| **Failover record type** | **Primary** |
| **Health check** | `eu-central-1` (**required**) |
| **Record ID** | `E` |

#### 3.2 Secondary record

Use **Add another record**, keeping the same name.

| Setting | Value |
|---|---|
| **Name** | `failover.<your-domain>` |
| **Type** | **A** |
| **Value** | `us-east-1` instance IP |
| **TTL** | **60 s** |
| **Routing policy** | **Failover** |
| **Failover record type** | **Secondary** |
| **Health check** | `us-east-1` (**optional**, attached in the demo) |
| **Record ID** | `US` |

- Click **Create records**.
- The primary is the one users normally get. The secondary exists only for when the primary fails.

### 4. Demo: Triggering the Failover

1. **Before:** both health checks are **Healthy**. Opening `failover.<your-domain>` returns "Hello from `eu-central-1c`", the primary.
2. **Break the primary:** go to the `eu-central-1` instance's **security group** and **remove the HTTP (port 80) inbound rule**.
   - The health checkers can no longer reach the instance.
3. **Wait** for the health check to turn **Unhealthy** (it needs several failed checks).
   - Open the health check's **Monitoring** tab. The status metric drops from **1 to 0**, and the **percentage of health checkers reporting healthy** drops to **0**.
4. **Test:** refresh `failover.<your-domain>`. The answer is now **"Hello from `us-east-1`"**, the secondary. The failover worked with no manual DNS change.
5. **Recover:** add the HTTP rule back to the security group. The health check passes again, and Route 53 **fails back** to the primary.

**Timing to expect:**
- **Detection time** is roughly interval × failure threshold (for example 30 s × 3).
- **Cache time** is up to the record **TTL** (60 s here).
- Total failover delay is detection plus TTL, so use a low TTL and a fast interval where downtime matters.

### 5. Failover vs Other Policies

- **Active-active** setups use weighted, latency, or multi-value with health checks.
- **Active-passive** is the failover policy. The secondary often sits idle (or is a static **S3 website** or a smaller site) until needed.

### 6. Exam-Style Recall

| If the question says... | Think... |
|---|---|
| "Active-passive failover with Route 53" | **Failover routing policy** |
| "Send users to a DR site only when the primary fails" | **Failover routing** |
| "Which record needs a health check in a failover pair?" | The **primary** (mandatory) |
| "How many primary/secondary records?" | **One primary, one secondary** |
| "Failover record types" | **Primary** and **Secondary** |
| "Failover is slow even after the health check fails" | **TTL caching.** Lower the TTL. |
| "Failover to a static S3 website when the app is down" | **Failover** with an **Alias** to the S3 website as secondary |
| "Active-active across regions" | **Latency**, **weighted**, or **multi-value** (not failover) |
| "Primary recovers" | Route 53 returns the **primary** again |
| "Does Route 53 redirect the traffic itself?" | **No.** It only changes the DNS answer. |

---

## Routing Policy - Geolocation

### TL;DR

- **Geolocation routing** answers DNS queries based on **where the user is located**, not on measured latency.
- You can target a **continent**, a **country**, or a **US state**. The **most specific match wins**.
- Create a **default record** for users who match no location. Without one, unmatched users get **no answer**.
- Use cases: **website localization** (language), **restricting content distribution** (licensing, legal), and **load balancing** by region.
- Records share the **same name and type**, and each has a **Location** and a **Record ID**.
- Supports **health checks** and **Alias** records.
- **Geolocation is not latency.** Latency picks the fastest region, and geolocation follows rules about the user's location. A user may be sent to a farther region on purpose.
- Route 53 still only returns a **DNS answer**. It carries no traffic.

### 1. What Is Geolocation Routing?

- Routing is based on **the user's location**, "very different from latency-based".
- Location levels you can choose:

| Level | Example |
|---|---|
| **Continent** | Asia, Europe, North America |
| **Country** | Germany, France, United States |
| **US state** | California, Texas |
| **Default** | Everything that doesn't match another record |

- **The most precise location is selected first.** A user in California matches a `California` record before a `United States` record, and a `United States` record before a `North America` record.
- You can mix levels in one record set. The lecture mixes a continent (Asia) and a country (United States).

### 2. Default Record

- **Create a default record** in case **no location matches**.
- It catches:
  - Users from locations you didn't configure.
  - Users whose location Route 53 **can't determine**.
- **Without a default record**, those users get **no answer** (the query returns no record), and the site appears unreachable to them.
- In the console the default is a geolocation record with Location = **Default**.

### 3. Use Cases

| Use case | Example |
|---|---|
| **Website localization** | German users to the German version, French users to the French version, everyone else to English |
| **Restrict content distribution** | Serve content only in licensed countries, or send others to a "not available" page |
| **Load balancing by region** | Send regions to the nearest or designated stack |
| **Regional compliance and data residency** | Keep users of a region on endpoints in that region |

**Lecture example (map of Europe):**

```
User in Germany  --> [Route 53 geolocation] --> German version of the app (IP A)
User in France   --> [Route 53 geolocation] --> French version of the app (IP B)
Anywhere else    --> [Route 53 geolocation] --> Default: English version (IP C)
```

### 4. Rules and Requirements

| Rule | Detail |
|---|---|
| **Same name and type** | All records in the set share the same DNS name and type |
| **Location** | One location per record (continent, country, state, or default) |
| **Record ID** | A unique identifier per record |
| **Health checks** | **Optional**, one per record |
| **Alias** | Supported |
| **Default record** | Strongly recommended |
| **Overlap** | Allowed (for example a country plus its continent). The most specific wins. |

**Health check behavior:** if the record that matches the user is unhealthy, Route 53 doesn't jump to a random record. It looks for the next-broader location that matches and is healthy (for example a country record fails, then the continent record, then the default). Check the Route 53 docs for exact behavior if this matters.

### 5. How Route 53 Knows the User's Location

- Route 53 maps the **IP address of the DNS query source** to a location, using a geolocation database.
- That is usually the **DNS resolver's IP**, not the user's own IP.
  - If the resolver supports **EDNS Client Subnet**, Route 53 can use part of the **client's** IP range instead.
- The mapping is **not 100% accurate**. Don't use geolocation routing as a security control.
- A VPN changes the apparent location, which is why the lecture could test it that way.

### 6. Demo: Creating the Geolocation Records

#### 6.1 The three records

All use the **same name**: `geo.<your-domain>`, **type A**, **routing policy Geolocation**.

| Record ID | Value (instance) | Location | Who gets it |
|---|---|---|---|
| (Asia record) | `ap-southeast-1` instance IP | **Asia** (continent) | Any user located in Asia |
| `US` | `us-east-1` instance IP | **United States** (country) | Users in the US |
| `Default EU` | `eu-central-1` instance IP | **Default** | Everyone else |

- The lecturer notes you can pick a **whole continent** (Asia) or **just a country** (United States). It doesn't matter.
- The lecture doesn't state the TTL. A low TTL is useful when testing.

#### 6.2 Steps

1. Hosted zone, **Create record**.
2. **Name:** `geo`, **type:** A, **value:** the Singapore instance IP.
3. **Routing policy:** **Geolocation**. **Location:** **Asia**. Add a **Record ID**. Health check optional.
4. **Add another record**, same name, value = the N. Virginia IP, **Location:** **United States**, **Record ID:** `US`.
5. **Add another record**, same name, value = the Frankfurt IP, **Location:** **Default**, **Record ID:** `Default EU`.
6. **Create records.**

### 7. Demo: Testing with a VPN

| Test location | Expected | Result |
|---|---|---|
| **Europe** (lecturer's real location) | No match, so **default** | **Hello from `eu-central-1c`** |
| **India** (VPN) | Matches **Asia** | First a **timeout**, then **Hello from `ap-southeast-1b`** after the fix below |
| **United States** (VPN) | Matches **United States** | **Hello from `us-east-1a`** |
| **Mexico** (VPN) | Not Asia, not the US, so **default** | **Hello from `eu-central-1c`** |

**The timeout in India:**
- DNS worked, but the page loaded forever, a **timeout**.
- Timeout in AWS usually means a **security group** problem.
- Cause: in the earlier health check and failover demos the **HTTP rule had been removed** from the Singapore instance's security group.
- Fix: **re-add the HTTP (80) inbound rule**. The Asia answer then worked.

**The Mexico test:**
- Mexico is **next to the US but not in the US**. It is in **North America**, and no North America record exists.
- It falls to the **default record**. This shows that a **country record matches only that country**.
- A **country record doesn't cover its neighbors**. Mexico is not in the US record.

### 8. Exam-Style Recall

| If the question says... | Think... |
|---|---|
| "Route users based on their location" | **Geolocation** |
| "Serve a different language version by country" | **Geolocation** |
| "Restrict content to certain countries" | **Geolocation** |
| "Users from unmatched locations get no answer" | The **default record** is missing |
| "Which record catches users with no matching location?" | The **default** record |
| "Most specific location wins" | **Geolocation** |
| "Route to the fastest region regardless of location" | **Latency**, not geolocation |
| "Shift traffic toward a region using a bias" | **Geoproximity** |
| "Smallest geolocation unit in the US" | **State** |
| "Can geolocation records use health checks?" | **Yes** |
| "What decides a user's location in Route 53?" | The **IP of the DNS resolver** (or the client subnet if EDNS is used) |
| "DNS resolves correctly but the page times out" | **Security group** or firewall on the target |

---

## Routing Policy - Geoproximity

### TL;DR

- **Geoproximity routing** routes users to resources based on the **geographic location of both the users and the resources**, with an adjustable **bias**.
- The **bias** grows or shrinks a resource's **geographic area of influence**:
  - **Positive bias** (expand) pulls **more traffic** to that resource.
  - **Negative bias** (shrink) sends **less traffic** to it.
- With **no bias** (0 everywhere), it behaves like "**nearest resource**".
- **AWS resources:** you specify the **AWS region**. **Non-AWS resources** (for example an on-premises data center): you specify **latitude and longitude**.
- **To use the bias you must use Route 53 Traffic Flow** (the advanced visual editor). Traffic Flow is where this policy is created in the console.
- **Exam focus:** geoproximity is for **shifting traffic from one region to another by changing the bias**.
- Route 53 still only returns a **DNS answer**. It carries no traffic.

### 1. What Is Geoproximity Routing?

- Routes traffic based on the **location of your users and your resources**.
- Its special feature is the **bias**: a number that lets you **shift traffic** toward or away from a resource.
- Think of each resource as having a **geographic region it "owns"**. The bias changes the **size** of that region.

| Bias | Effect on the resource's area | Traffic |
|---|---|---|
| **Positive** (increase) | **Expands** | **More** users and traffic attracted |
| **0** (default) | Normal, based on distance | Nearest users |
| **Negative** (decrease) | **Shrinks** | **Fewer** users and traffic |

- Bias range: **-99 to +99** (Route 53 docs).
- Supports **health checks**: an unhealthy resource is skipped (Route 53 docs).

### 2. Resource Types and Location

| Resource | What you specify |
|---|---|
| **AWS resource** (EC2, ELB, and so on) | The **AWS region** it is in. Route 53 **computes the location** automatically. |
| **Non-AWS resource** (on-premises data center, other cloud) | **Latitude and longitude**, so Route 53 knows where it is |

- Mixing both in one record set is allowed (for example AWS regions plus an on-premises site).
- Records share the **same name and type**, and each has a **Record ID** and its own **bias**.

### 3. Traffic Flow Requirement

- To use geoproximity (and the **bias**), you need the **Route 53 Traffic Flow** feature.
- Traffic Flow gives you a **visual editor** to build routing rules, as a **traffic policy**, and attach it to a **policy record** in a hosted zone.
- Traffic policies can **nest** several routing types (for example geoproximity combined with failover or weighted).
- Traffic Flow has **extra cost**: a monthly charge per **policy record**.
- Note: Route 53 has also added geoproximity as a **plain record routing policy** (no Traffic Flow) in the console. The lecture's exam point is still "Traffic Flow is needed to use the bias". Check the current console.
- **Bias 0** = plain nearest-resource routing.
- It's still **DNS-level** routing, limited by the **TTL cache**.

### 4. How the Bias Works (Lecture Diagrams)

#### 4.1 Scenario A: no bias

- Two resources: **`us-west-1`** and **`us-east-1`**.
- Bias is **0** on both.
- A **dividing line** splits the US roughly in the middle:
  - Users **left** of the line go to **`us-west-1`**.
  - Users **right** of the line go to **`us-east-1`**.
- This looks like plain "**go to the closest region**".

```
 West of line               |              East of line
 <--- us-west-1 area        |        us-east-1 area --->
                       (dividing line in the middle)
```

#### 4.2 Scenario B: bias +50 on `us-east-1`

- Same two resources.
- Bias is **0** on `us-west-1` and **+50** on `us-east-1`.
- The **dividing line moves west**, because `us-east-1`'s area has **expanded**:
  - Users **left** of the new line go to **`us-west-1`**.
  - Users **right** of the new line (now a **bigger area**) go to **`us-east-1`**.
- Result: **more users and more traffic** go to `us-east-1`, including some who were closer to `us-west-1`.

```
 us-west-1 area (smaller) |        us-east-1 area (bigger, +50 bias)
 <--- ---                 |   line moved west --- --->
```

#### 4.3 Using it in practice

- Resources placed around the world.
- You need to **shift more traffic to one region**.
- **Increase the bias for that region**: its area grows and it **attracts more users**.
- Or **decrease the bias** of an overloaded region to **push users away**.
- Adjusting the bias is a **gradual, tunable shift**, unlike geolocation, which is a fixed rule.

### 5. Use Cases

| Use case | How |
|---|---|
| **Shift traffic between regions** | Raise the bias of the region that should take more load |
| **Drain or reduce load on a region** | Lower the bias (or point it at a lower value) |
| **New region ramp-up** | Start with a small or negative bias, then increase it |
| **Hybrid cloud** | Mix AWS regions and an on-premises data center (by lat/long) |
| **Capacity-aware routing** | Bigger regions get a larger bias |

### 6. Geoproximity vs Geolocation vs Latency

| | **Geoproximity** | **Geolocation** | **Latency** |
|---|---|---|---|
| **Decided by** | **Distance** between user and resource, plus a **bias** | The user's **location** (continent, country, state) | **Measured network latency** to AWS regions |
| **Tunable** | **Yes**, with the bias | No (fixed rules) | No |
| **Same user, same answer?** | Depends on the bias | **Yes**, always | Can change as latency changes |
| **Needs a default** | No | **Yes** (recommended) | No |
| **Non-AWS endpoints** | **Yes** (lat/long) | Yes | Not directly (AWS regions only) |
| **Requires Traffic Flow** | **Yes** (per the lecture) | No | No |
| **Best for** | **Shifting traffic** between regions | Localization, content rules | Fastest response |

- **Geoproximity** = "nearest, adjustable".
- **Geolocation** = "by who and where, fixed".
- **Latency** = "fastest".

### 7. Exam-Style Recall

| If the question says... | Think... |
|---|---|
| "Route based on user and resource locations, with the ability to shift traffic" | **Geoproximity** |
| "Send more traffic to a region" | **Increase the bias** |
| "Send less traffic to a region" | **Decrease the bias** (negative) |
| "Bias = 0 on all resources" | Nearest resource wins |
| "Resources in an on-premises data center" | Specify **latitude and longitude** |
| "Resources in AWS" | Specify the **AWS region** |
| "Which feature do you need to use the bias?" | **Route 53 Traffic Flow** |
| "Routing by country/continent rules" | **Geolocation**, not geoproximity |
| "Routing to the lowest-latency region" | **Latency**, not geoproximity |
| "Visual editor for complex routing policies" | **Traffic Flow** |

---

## Routing Policy - IP-based

### TL;DR

- **IP-based routing** answers DNS queries based on the **client's IP address**. You define **CIDR blocks** (IP ranges) and say which endpoint each range should get.
- Setup has two parts: a **CIDR collection** (containing **locations**, each with one or more CIDR blocks) and **records** that reference those locations.
- Use cases: **optimize performance** (you know where certain clients are) and **reduce network costs** (you know where the traffic comes from).
- Typical example: you know a specific **ISP** uses a specific CIDR range, so you route that ISP's users to a specific endpoint.
- Add a **default record** (location = default) for clients whose IP matches no CIDR block.
- Supports **health checks** and **Alias** records.
- Route 53 still only returns a **DNS answer**. It carries no traffic.

### 1. What Is IP-Based Routing?

- "Very intuitive": routing is decided by **who the client is, by IP address**.
- You maintain a **list of CIDRs** (IP ranges of your clients) and map each range to a **location**, then each location to a **record value**.
- It is useful when **you know your clients' IP ranges ahead of time**.

| Use case | Why |
|---|---|
| **Optimize performance** | Send a known client network to the endpoint that performs best for it |
| **Reduce network costs** | Send a known network to an endpoint that avoids expensive paths (for example the same region, or a peered or private route) |
| **ISP-specific routing** | An ISP with a known CIDR block goes to a dedicated endpoint |
| **Partner or office networks** | Known corporate ranges go to a specific stack |

### 2. How It Is Configured

1. **Create a CIDR collection** (Route 53 console, **IP-based routing**, **CIDR collections**).
2. Inside it, create **locations**. Each location has a **name** and one or more **CIDR blocks**.
3. Create **DNS records** with routing policy **IP-based**, and pick the **collection** and **location** for each record.
4. Add a **default** record for everything else.

```
CIDR collection
 ├── Location 1: 203.x.x.x/24 ...
 └── Location 2: 200.x.x.x/24 ...

Records for example.com:
  Location 1  -->  1.2.3.4   (EC2 instance A)
  Location 2  -->  5.6.7.8   (EC2 instance B)
  Default     -->  (catch-all endpoint)
```

| Concept | Meaning |
|---|---|
| **CIDR collection** | A container for locations. Records point at a collection. |
| **Location** | A named group of one or more CIDR blocks |
| **CIDR block** | An IP range such as `203.0.113.0/24` |
| **Default location** | Used when the client IP matches no location |

- CIDR blocks can be **IPv4 or IPv6**.
- Records in the set share the **same name and type**, and each has a **Record ID**.
- Include a **default** record for non-matching clients.

### 3. Lecture Example

- Two locations with two CIDR blocks: one starting with **203**, the other with **200**.
- Records for `example.com`:

| Location | CIDR | Answer (public IP of an EC2 instance) |
|---|---|---|
| Location 1 | First block (203.x) | **1.2.3.4** |
| Location 2 | Second block (200.x) | **5.6.7.8** |

- **User A**, whose IP is in the location 1 block, gets a DNS answer of **1.2.3.4**.
- **User B**, whose IP is in the location 2 block, gets **5.6.7.8**.

### 4. Important Detail: Whose IP Is Matched?

- Route 53 normally sees the **DNS resolver's IP**, not the end user's.
- If the user's resolver is in a different network (for example a public resolver), the match is against the **resolver's** range.
- With **EDNS Client Subnet**, Route 53 can use the **client's** subnet instead.
- This works best when you control or know the **resolvers** the clients use (for example an ISP or corporate resolver).

### 5. IP-Based vs Other Policies

- **IP-based** is the only one where **you define the client ranges** yourself.
- It is **DNS-level**, so answers are cached for the **TTL**.

### 6. Exam-Style Recall

| If the question says... | Think... |
|---|---|
| "Route based on the client's IP address range" | **IP-based routing** |
| "Route a specific ISP's customers to a specific endpoint" | **IP-based routing** |
| "Define a list of CIDR blocks and map each to an endpoint" | **IP-based routing** (CIDR collection) |
| "Optimize performance or reduce network cost for known client networks" | **IP-based routing** |
| "What catches clients that match no CIDR?" | The **default** record |

---

## Routing Policy - Multi Value

### TL;DR

- **Multi-value answer routing** returns **multiple values (up to 8)** in response to a DNS query, and the **client picks one**. It is **client-side load balancing**.
- Each record can have a **health check**. **Only healthy records are returned.**
- Records share the **same name and type**, and each has a **Record ID**. Each record holds **one value**.
- It is **not a substitute for an ELB**. It improves availability by hiding unhealthy endpoints, but it doesn't balance by load, connections, or sessions.
- **Difference from simple routing with multiple values:** simple can't use health checks, so it can return **unhealthy** values. Multi-value filters them out.
- Demo: 3 records with 3 health checks. `dig` returned **3 IPs**. After one health check was made unhealthy (using **Invert health check status**), `dig` returned **2 IPs**.
- Route 53 still only returns a **DNS answer**. It carries no traffic.

### 1. What Is Multi-Value Answer Routing?

- Used when you want to route traffic to **multiple resources** and have Route 53 **return multiple values**.
- Each record can be associated with a **health check**.
- Route 53 returns **only records whose health check is healthy**.
- **Up to 8 healthy records** are returned per query. If you have more than 8, Route 53 returns a **random selection of 8**.
- The **client** then chooses one of the returned values (typically at random).

```
Client --"multi.example.com?"--> [Route 53]
Client <-- up to 8 HEALTHY IPs: 1.1.1.1, 2.2.2.2, 3.3.3.3 --
Client picks one and connects
```

- Combined with health checks, the client can be fairly confident that **the returned records are healthy**, so its queries are "very safe".

### 2. Not a Replacement for an ELB

| | **Multi-value answer** | **ELB** |
|---|---|---|
| **Where balancing happens** | **Client side** (the client picks from the list) | **Server side** (the load balancer picks) |
| **Awareness of load** | None | Yes (algorithms, connection counts) |
| **Health checks** | Route 53 health checks, at DNS level | Target group health checks |
| **Traffic path** | Client connects **directly** to the endpoint | Traffic goes **through** the load balancer |
| **Cached answers** | Yes (**TTL**) | N/A |

- It only gives **DNS-level availability and rough distribution**. A client that cached a now-dead IP keeps using it until the **TTL** expires.

### 3. Multi-Value vs Simple (with Multiple Values)

| | **Simple** (multiple values in one record) | **Multi-value answer** |
|---|---|---|
| **Records** | **One** record with several values | **Separate records**, one value each |
| **Health checks** | **Not supported** | **Supported** (per record) |
| **Unhealthy values returned?** | **Yes, possible** | **No**, filtered out |
| **Max values returned** | All values in the record | **Up to 8** healthy records |
| **Alias** | One alias target only | **No** alias (use A/AAAA with values) |
| **Client chooses** | Yes | Yes |

- This contrast is why multi-value is "a little more powerful".

### 4. Rules and Requirements

| Rule | Detail |
|---|---|
| **Same name and type** | All records share the same DNS name and type (for example A) |
| **One value per record** | Each multi-value record has **one** value |
| **Record ID** | A unique identifier per record |
| **Health checks** | **Optional**, but they are the point. Without one, the record is always returned. |
| **Limit** | **8** records returned per query |
| **TTL** | Per record (the demo used **60 s**) |

### 5. Demo: Creating the Multi-Value Records

All records use the **same name**: `multi.<your-domain>`, **type A**, **routing policy Multivalue answer**, **TTL 60 s**.

| Record ID | Value (instance) | Health check |
|---|---|---|
| `US` | `us-east-1` instance IP | `us-east-1` |
| `Asia` | `ap-southeast-1` instance IP | `ap-southeast-1` |
| `EU` | `eu-central-1` instance IP | `eu-central-1` |

**Steps:**
1. Hosted zone, **Create record**, name `multi`.
2. Value = the `us-east-1` IP, routing policy **Multivalue answer**, health check `us-east-1`, Record ID `US`, TTL 60.
3. **Add another record** (same name): `ap-southeast-1` IP, health check `ap-southeast-1`, Record ID `Asia`.
4. **Add another record**: `eu-central-1` IP, health check `eu-central-1`, Record ID `EU`.
5. **Create records.**

### 6. Demo: Testing with `dig`

1. Open **CloudShell** (reconnect if the session ended). Reinstall `bind-utils` if `dig` is missing.
2. Run:

```bash
dig multi.<your-domain>
```

3. **Result: three answers**, one per IP, because all three health checks are **healthy**.

#### 6.1 Making one health check unhealthy

- Instead of blocking a security group again, the lecturer uses a **shortcut**:
  1. Edit the `eu-central-1` health check.
  2. Tick **Invert health check status**. A healthy endpoint is now reported **unhealthy**.
  3. Wait for the status to update (the lecturer pauses the video).
- Run `dig` again: **only two values** are returned (the Frankfurt IP is gone).
- The multi-value answer **filtered out the unhealthy record**.

#### 6.2 Revert

- Edit the health check and **untick Invert health check status**.
- The health check returns to healthy, and the third IP reappears after the next status change and TTL expiry.

**Tip:** the record is only re-added once Route 53 sees the health check as healthy again, and resolvers may still serve the 2-IP answer until the **60 s TTL** expires.

- **Unhealthy records are excluded** from answers.
- **TTL caching** limits how fast clients see changes.

### 7. Multi-Value vs Other Policies

- Multi-value is the only policy that **returns several healthy values** at once for client-side choice.

### 8. Exam-Style Recall

| If the question says... | Think... |
|---|---|
| "Return multiple healthy IPs and let the client choose" | **Multi-value answer** |
| "Maximum records returned in a multi-value answer" | **8** |
| "Client-side load balancing with health checks" | **Multi-value answer** |
| "Simple routing returned an unhealthy IP" | Use **multi-value answer** with health checks |
| "Which policy returns several values but filters out unhealthy ones?" | **Multi-value answer** |
| "Quickly simulate an unhealthy health check" | **Invert health check status** |
| "Can a multi-value record be an Alias?" | **No** |

---

## 3rd Party Domains & Route 53

### TL;DR

- A **domain registrar** (where you **buy and own** a domain) and a **DNS service** (where the **DNS records** live) are **two different roles**. They can be different companies.
- You can buy a domain from **any registrar** (GoDaddy, Namecheap, and others) and still use **Route 53 as your DNS service**.
- To do it: create a **public hosted zone** in Route 53, copy its **4 name servers**, and enter them as the **custom name servers** at the third-party registrar.
- Registrars usually bundle a DNS service, but you aren't forced to use it.
- The reverse also works: register in Route 53 and point the domain to another DNS provider by changing the domain's name servers.
- Exam wording: "domain bought elsewhere, DNS in Route 53" means **public hosted zone + update NS at the registrar**.

### 1. Registrar vs DNS Service

| | **Domain registrar** | **DNS service** |
|---|---|---|
| **What it does** | **Sells and registers** domain names (ownership, renewal) | **Hosts DNS records** and answers DNS queries (authoritative name servers) |
| **You pay** | **Annual** registration fee | Usually a monthly or per-query fee (Route 53: $0.50 per hosted zone per month plus queries) |
| **Examples** | **Amazon Route 53 Registrar**, GoDaddy, Namecheap, Google Domains (now Squarespace) | **Route 53**, Cloudflare DNS, the registrar's own DNS |
| **Key setting** | The domain's **name server (NS) delegation** | The **records** in the zone |

- Whenever you register a domain, the registrar normally **also gives you a DNS service** for its records.
- Earlier in the course, the domain was registered through the **Route 53 console**, and a **Route 53 hosted zone** was used for its records. That is the "all-in-one AWS" setup.
- **They are separate decisions.** The registrar holds the domain, and the **NS records at the registrar** decide **which DNS service** answers for it.

### 2. Possible Combinations

| Registrar | DNS service | Works? |
|---|---|---|
| Route 53 | Route 53 | **Yes** (the setup used so far) |
| **GoDaddy** (or another third party) | **Route 53** | **Yes**, this lecture |
| Route 53 | Another DNS provider | **Yes**: change the domain's name servers in Route 53 |
| Third party | The same third party | **Yes** (their built-in DNS) |

- The lecture's example: buy `example.com` at **GoDaddy**, but manage its DNS records in **Route 53**. It is "a perfectly acceptable combination".

### 3. Steps: Third-Party Registrar with Route 53 DNS

```
1. Buy the domain at GoDaddy (registrar)
2. Route 53 --> create a PUBLIC hosted zone for example.com
3. Hosted zone details --> copy the 4 NS values (name servers)
4. GoDaddy --> domain settings --> Nameservers --> Custom --> paste the 4 Route 53 name servers
5. Manage all DNS records in Route 53 from now on
```

| Step | Where | Action |
|---|---|---|
| 1 | **Third-party registrar** (GoDaddy) | **Register** the domain (annual fee) |
| 2 | **Route 53** | Create a **public hosted zone** with the **exact domain name** |
| 3 | Route 53, hosted zone details | Find the **NS record set**: **4 name servers** (the lecture says "on the right-hand side" of the details) |
| 4 | **Registrar's** domain settings | Choose **custom name servers** and enter the **4 Route 53 name servers** |
| 5 | **Route 53** | Create your **A, AAAA, CNAME, Alias** records |

**What happens afterwards:**
- Resolvers follow the chain: root, then `.com` TLD, then **the TLD asks for the domain's name servers** (the ones you set at GoDaddy).
- Those now point to **Route 53's name servers**, so Route 53 answers: it is the **source of truth** for the records.
- This is the same lookup chain from the **What Is DNS?** lecture.

### 4. Practical Details

- **Create the public hosted zone first**, so you have the 4 name servers to paste.
- Enter **all 4** name servers, exactly as shown, with no typos. Remove the registrar's default name servers.
- **Propagation takes time.** NS changes can take **minutes to 48 hours** (NS records are cached with long TTLs).
- **Don't mix the old and new** name servers, or some resolvers will get answers from the old DNS service.
- **Before switching an existing live domain**, recreate all its records in the Route 53 hosted zone first, so nothing breaks at cutover.
- If you registered the domain in **Route 53**, its **registered domain name servers** must match the hosted zone's NS values. They do automatically when you use the registration flow, but may not if you delete and recreate the hosted zone (new zones get **new** name servers).
- The NS and SOA records created in the hosted zone are **required**. Don't delete them.
- **DNSSEC, domain lock, and WHOIS privacy** are handled at the **registrar**, while record settings stay in **Route 53**.
- A hosted zone costs **$0.50 per month** regardless of where the domain is registered.
- **Registrar ≠ DNS service.** A registrar looks similar but is a **different function**, even though most registrars include DNS features.
- You can't use a **private hosted zone** for this. It only answers inside your VPCs.

### 5. Exam-Style Recall

| If the question says... | Think... |
|---|---|
| "Domain purchased from GoDaddy, DNS managed in Route 53" | **Public hosted zone + update NS records at the registrar** |
| "Which Route 53 resource do you create for a third-party domain?" | A **public hosted zone** |
| "What do you enter at the third-party registrar?" | The **4 Route 53 name servers** (NS values) |
| "Where does a domain's authoritative DNS get decided?" | The **NS records / name servers set at the registrar** |
| "Difference between a registrar and a DNS service" | Registrar = **owns/sells the domain**. DNS service = **hosts the records**. |
| "Domain registered in Route 53, DNS hosted elsewhere" | **Change the domain's name servers** in Route 53 |
| "Which hosted zone type for internet-facing records?" | **Public** |
