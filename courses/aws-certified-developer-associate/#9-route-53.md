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

### 7. Key Facts to Remember

- DNS translates **hostnames to IP addresses**.
- The hierarchy is **root, then TLD, then SLD, then subdomain**, and the **FQDN** is the full name.
- **Registrar** = where you buy the domain. **Name server** = resolves queries. **Zone file** = holds the records.
- **Root and TLD servers** return **NS referrals**. The **authoritative server** returns the **answer** (for example an **A record**).
- The **local DNS server** does the **recursive lookups** and **caches** results.
- **A record** = hostname to **IPv4**. **AAAA** = hostname to **IPv6**. **CNAME** = hostname to another hostname. **NS** = which name servers handle a domain.
- Caching duration is controlled by the record's **TTL** (Route 53 section).
- DNS runs on **port 53**.
- **Route 53** = AWS's **registrar** and **authoritative DNS** service.

### 8. Exam-Style Recall

| If the question says... | Think... |
|---|---|
| "Translate a hostname into an IP address" | **DNS** |
| "Where do you register a domain name?" | **Domain registrar** (for example Route 53) |
| "File or collection of all records for a domain" | **Zone file** |
| "Server that resolves DNS queries" | **Name server** |
| "`.com`, `.org`, `.gov`" | **Top-level domains (TLDs)** |
| "`amazon.com`" | **Second-level domain** |
| "`api.www.example.com`" | **FQDN** (fully qualified domain name) |
| "Record type that maps a name to an IPv4 address" | **A record** |
| "Record type that maps a name to an IPv6 address" | **AAAA record** |
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

### 6. Key Facts to Remember

- Route 53 = **authoritative DNS** + **domain registrar** + **health checking**.
- **100% availability SLA**. This is a classic exam fact.
- **Port 53**, which is the origin of the name.
- A record has **name, type, value, routing policy, and TTL**.
- **A** = IPv4, **AAAA** = IPv6, **CNAME** = hostname to hostname, **NS** = name servers for the hosted zone.
- **CNAME can't be used at the zone apex** (`example.com`). It works on subdomains.
- **Hosted zone** = a container of records. **Public** = internet clients. **Private** = VPC clients only.
- **TTL** is how long resolvers **cache** the answer.
- Route 53 **doesn't route actual traffic**. It responds to DNS queries, and the client then connects to the resolved address.
- Costs: **$0.50 per hosted zone per month** plus **about $12 per year** for a domain.

### 7. Exam-Style Recall

| If the question says... | Think... |
|---|---|
| "Highly available, scalable, fully managed, authoritative DNS" | **Route 53** |
| "Only AWS service with a 100% availability SLA" | **Route 53** |
| "Register a domain name in AWS" | **Route 53 (registrar)** |
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

### TL;DR

- You can **register a domain name directly in Route 53** (Route 53 acts as the **registrar**). It costs money: about **$12-13 per year** for a `.com` in the demo, depending on the TLD. **It is not free and not refundable.**
- Registering a domain gives you a **public hosted zone** for it, containing an **NS record** and an **SOA record**.
- The **NS record** points to Route 53's name servers, so **Route 53 becomes the source of truth** for the domain's DNS records.
- Key options: **duration**, **auto-renew**, **contact info**, and **privacy protection** (turn it on to hide your personal details and reduce spam).
- Registration can take **a few minutes to a few hours**.
- Following along is **optional**. If you don't want to pay, just watch.

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
9. Wait for the registration to complete, then **verify** it (section 5).

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

### 4. Cost

| Item | Detail |
|---|---|
| **Domain registration** | **About $12-13 per year** for `.com` (varies by TLD). Charged when you **submit**. |
| **Hosted zone** | **$0.50 per month** for each hosted zone |
| **Refund** | Domain registration is generally **non-refundable** |

- The lecturer's warning: **don't submit** if you don't want to pay.
- Clean up unused hosted zones. They bill monthly even if you don't use them.
- If the domain is registered, the **registration fee** is a separate, annual charge from the hosted zone fee.

### 5. Verifying the Registration

- Registration is **not instant**. It can take **a few minutes to a few hours** (occasionally longer).
- To confirm, go to **Hosted zones** and open your domain's hosted zone.

#### 5.1 What you should see

| Record | Purpose |
|---|---|
| **NS** | Lists the **4 AWS name servers** that answer DNS queries for this domain. It says "use the **AWS DNS** (Route 53) to answer queries". |
| **SOA** | **Start of Authority**. Administrative information about the zone (primary name server, contact, serial number, refresh timers). Created automatically. |

- The lecturer's own zone had **4 records** because of earlier use. A fresh one has **2**: NS and SOA.
- **Don't delete the NS or SOA records.** They are required for the zone to work.

#### 5.2 What this means

- Because the domain's NS records point to Route 53, **any DNS records you add to this hosted zone** (for example an A record) are what the internet sees.
- **Route 53 is the source of truth** for the domain's DNS.
- The next lecture covers **creating records** in the hosted zone.

### 6. Registrar vs Hosted Zone

| | **Domain registration** | **Hosted zone** |
|---|---|---|
| **What it is** | The **purchase** of the name (ownership and renewal) | The **DNS records** that say where the name points |
| **Where** | **Registered domains** | **Hosted zones** |
| **Billing** | Yearly | **$0.50 per month** |
| **Created by** | You register the domain | **Automatically** when you register through Route 53, or **manually** for external domains |

- **Registered with Route 53:** the **hosted zone is created for you**, and the domain's name servers already point to it.
- **Registered elsewhere** (for example GoDaddy):
  1. Create a **public hosted zone** in Route 53.
  2. Copy the **4 NS values** Route 53 gives you.
  3. Update the **name servers at the other registrar** to those 4 values.
- The registrar and the DNS host **can be different companies**. Route 53 doesn't require you to register the domain with AWS.

### 7. Key Facts to Remember

- Route 53 is both a **registrar** and a **DNS service**.
- Registering a domain costs about **$12-13 per year** and is **not free**.
- **Auto-renew:** keep it on for domains you want to keep.
- **Privacy protection** hides your personal contact details from WHOIS.
- A new registered domain gets a **public hosted zone** with **NS and SOA** records.
- The **NS record** points to the **Route 53 name servers**, making Route 53 the **source of truth** for the domain.
- Registration can take **minutes to hours**.
- A hosted zone costs **$0.50 per month**, separate from the registration fee.
- Domain registration is **global** (not tied to a region).
- You can **register a domain elsewhere** and still **host DNS in Route 53** by updating the name servers.

### 8. Exam-Style Recall

| If the question says... | Think... |
|---|---|
| "Register a domain name in AWS" | **Route 53 registered domains** |
| "Domain registered in Route 53, DNS records managed where?" | The **hosted zone** created for it |
| "Domain bought from another registrar, want Route 53 DNS" | Create a **hosted zone**, then update the registrar's **NS records** |
| "What two records exist in a new hosted zone?" | **NS** and **SOA** |
| "What does the NS record in a hosted zone indicate?" | The **name servers** that answer queries for the domain |
| "Hide personal contact info for a domain" | **Privacy protection** |
| "Domain must not be lost accidentally at year end" | Keep **auto-renew on** |
| "Cost of a hosted zone" | **$0.50 per month** |
| "Domain registration fee is charged how often?" | **Yearly** |
| "Registrar and DNS host must be the same company?" | **No** |

---

## Route 53 - Registering a Domain

### TL;DR

- You can **register a domain name directly in Route 53** (Route 53 acts as the **registrar**). It costs money: about **$12-13 per year** for a `.com` in the demo, depending on the TLD. **It is not free and not refundable.**
- Registering a domain gives you a **public hosted zone** for it, containing an **NS record** and an **SOA record**.
- The **NS record** points to Route 53's name servers, so **Route 53 becomes the source of truth** for the domain's DNS records.
- Key options: **duration**, **auto-renew**, **contact info**, and **privacy protection** (turn it on to hide your personal details and reduce spam).
- Registration can take **a few minutes to a few hours**.
- Following along is **optional**. If you don't want to pay, just watch.

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
9. Wait for the registration to complete, then **verify** it (section 5).

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

### 4. Cost

| Item | Detail |
|---|---|
| **Domain registration** | **About $12-13 per year** for `.com` (varies by TLD). Charged when you **submit**. |
| **Hosted zone** | **$0.50 per month** for each hosted zone |
| **Refund** | Domain registration is generally **non-refundable** |

- The lecturer's warning: **don't submit** if you don't want to pay.
- Clean up unused hosted zones. They bill monthly even if you don't use them.
- If the domain is registered, the **registration fee** is a separate, annual charge from the hosted zone fee.

### 5. Verifying the Registration

- Registration is **not instant**. It can take **a few minutes to a few hours** (occasionally longer).
- To confirm, go to **Hosted zones** and open your domain's hosted zone.

#### 5.1 What you should see

| Record | Purpose |
|---|---|
| **NS** | Lists the **4 AWS name servers** that answer DNS queries for this domain. It says "use the **AWS DNS** (Route 53) to answer queries". |
| **SOA** | **Start of Authority**. Administrative information about the zone (primary name server, contact, serial number, refresh timers). Created automatically. |

- The lecturer's own zone had **4 records** because of earlier use. A fresh one has **2**: NS and SOA.
- **Don't delete the NS or SOA records.** They are required for the zone to work.

#### 5.2 What this means

- Because the domain's NS records point to Route 53, **any DNS records you add to this hosted zone** (for example an A record) are what the internet sees.
- **Route 53 is the source of truth** for the domain's DNS.
- The next lecture covers **creating records** in the hosted zone.

### 6. Registrar vs Hosted Zone

| | **Domain registration** | **Hosted zone** |
|---|---|---|
| **What it is** | The **purchase** of the name (ownership and renewal) | The **DNS records** that say where the name points |
| **Where** | **Registered domains** | **Hosted zones** |
| **Billing** | Yearly | **$0.50 per month** |
| **Created by** | You register the domain | **Automatically** when you register through Route 53, or **manually** for external domains |

- **Registered with Route 53:** the **hosted zone is created for you**, and the domain's name servers already point to it.
- **Registered elsewhere** (for example GoDaddy):
  1. Create a **public hosted zone** in Route 53.
  2. Copy the **4 NS values** Route 53 gives you.
  3. Update the **name servers at the other registrar** to those 4 values.
- The registrar and the DNS host **can be different companies**. Route 53 doesn't require you to register the domain with AWS.

### 7. Key Facts to Remember

- Route 53 is both a **registrar** and a **DNS service**.
- Registering a domain costs about **$12-13 per year** and is **not free**.
- **Auto-renew:** keep it on for domains you want to keep.
- **Privacy protection** hides your personal contact details from WHOIS.
- A new registered domain gets a **public hosted zone** with **NS and SOA** records.
- The **NS record** points to the **Route 53 name servers**, making Route 53 the **source of truth** for the domain.
- Registration can take **minutes to hours**.
- A hosted zone costs **$0.50 per month**, separate from the registration fee.
- Domain registration is **global** (not tied to a region).
- You can **register a domain elsewhere** and still **host DNS in Route 53** by updating the name servers.

### 8. Exam-Style Recall

| If the question says... | Think... |
|---|---|
| "Register a domain name in AWS" | **Route 53 registered domains** |
| "Domain registered in Route 53, DNS records managed where?" | The **hosted zone** created for it |
| "Domain bought from another registrar, want Route 53 DNS" | Create a **hosted zone**, then update the registrar's **NS records** |
| "What two records exist in a new hosted zone?" | **NS** and **SOA** |
| "What does the NS record in a hosted zone indicate?" | The **name servers** that answer queries for the domain |
| "Hide personal contact info for a domain" | **Privacy protection** |
| "Domain must not be lost accidentally at year end" | Keep **auto-renew on** |
| "Cost of a hosted zone" | **$0.50 per month** |
| "Domain registration fee is charged how often?" | **Yearly** |
| "Registrar and DNS host must be the same company?" | **No** |

---

## Route 53 - Creating Our First Records

### TL;DR

- Created a **simple A record** in the public hosted zone: `test.<your-domain>` pointing to `11.22.33.44` (a made-up IP), **TTL 300 s**, **simple routing policy**.
- The IP doesn't belong to a real server, so **loading the URL in a browser fails**. DNS still resolves correctly, because **Route 53 only answers the DNS question** and doesn't carry traffic.
- Verified the record from the command line using **`nslookup`** (Windows) or **`dig`** (Mac/Linux), run from **AWS CloudShell**.
- `dig` is more informative: its **ANSWER SECTION** shows the **record name, TTL, record type (A), and value**.
- Later lectures route to a **real EC2 instance** and cover **routing policies**.

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

#### 1.2 Fields explained

| Field | Demo value | Notes |
|---|---|---|
| **Record name** | `test` (full name `test.<domain>`) | Enter any subdomain. Leave it **blank** for the **root/apex** domain. |
| **Record type** | **A** | Many types exist. A, AAAA, CNAME, and NS are the ones to know. |
| **Value** | `11.22.33.44` | Just a random value for the demo. Later it will be a real EC2 public IP. |
| **TTL** | **300 s** | How long **resolvers cache** the answer |
| **Routing policy** | **Simple** | Other policies come in later lectures |

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

- Windows tip: `nslookup` is built in.
- The domain's **NS records at the registrar** must match the **hosted zone's NS values**, or public queries won't reach your records.

### 5. Key Facts to Remember

- Create records in a **hosted zone**: **name, type, value, TTL, routing policy**.
- **A record** = hostname to **IPv4**. The default TTL in the console is **300 s**.
- **Simple routing** is the default policy.
- **Route 53 answers DNS queries only.** Whether the destination actually works is a separate matter.
- **`nslookup`** (Windows) and **`dig`** (Mac/Linux) are the tools to test DNS. Both come from **`bind-utils`**.
- **`dig`** shows the **TTL** and the **record type**.
- **Cached answers** persist until the **TTL** expires, so changes aren't always instant.
- **CloudShell** is a free browser-based terminal in the AWS console, with the AWS CLI preinstalled.
- The record name is relative to the **hosted zone** (you type `test`, and the result is `test.<domain>`).

### 6. Exam-Style Recall

| If the question says... | Think... |
|---|---|
| "Map a subdomain to an IPv4 address" | **A record** |
| "How long resolvers cache a record" | **TTL** |
| "Default routing policy" | **Simple routing** |
| "Tool to test DNS resolution on Windows" | **`nslookup`** |
| "Tool to test DNS resolution on Mac/Linux, shows TTL" | **`dig`** |
| "DNS resolves correctly but the website doesn't load" | **Server / security group** problem, not DNS |
| "DNS change isn't visible yet" | **Cached** until the TTL expires |
| "Where do you create DNS records?" | In the **hosted zone** |
| "Which record would you use to point to a real EC2 public IP?" | **A record** |
| "Browser-based terminal in the AWS console" | **CloudShell** |

---

## Route 53 - EC2 Setup

### TL;DR

- Prep lecture for the Route 53 routing policy demos. It builds **3 EC2 instances in 3 different regions** and **1 ALB**, so later lectures have real endpoints to route to.
- **Instances:** Frankfurt (`eu-central-1`), N. Virginia (`us-east-1`), Singapore (`ap-southeast-1`). Each is Amazon Linux 2, `t2.micro`, no key pair, with HTTP open to the world.
- **User data** installs a web server that returns "Hello World" plus the instance's **Availability Zone**. This tells you which region answered when you test later.
- **ALB:** `DemoRoute53ALB` in **Frankfurt**, internet-facing, forwarding HTTP:80 to the target group `demo-tg-route53`, which holds the Frankfurt instance.
- **Verified** each endpoint in the browser and noted its IP and region in a text file. You need these values in the next lectures.
- Key idea: **EC2 and ALB are regional. Route 53 is global.** Route 53 can point one domain name at resources in many regions.

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
| **AMI** | Amazon Linux 2 (x86) | AL2 is nearing end of support. **Amazon Linux 2023** works too (see the IMDSv2 note below). |
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

### 5. Key Facts to Remember

- **EC2, ALB, security groups, key pairs, and target groups are regional.** **Route 53 is global.**
- One Route 53 domain can point to **resources in many regions** (the whole reason for this setup).
- An **ALB can only route to targets in its own region** (and its own VPC, plus IPs reachable from it).
- **User data** sets up the web server on first boot, and the page shows the **AZ** so you can tell instances apart.
- The **instance metadata service** (`169.254.169.254`) provides the AZ, instance ID, and other details from inside the instance.
- AMI IDs **differ by region**.
- Public IPv4 addresses of EC2 instances **change on stop/start**. Use an **Elastic IP** for a stable address.
- Delete everything after the Route 53 section: **3 instances and the ALB bill while they exist**.

### 6. Exam-Style Recall

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

### 7. Key Facts to Remember

- **TTL = how long a DNS answer is cached**, in **seconds**.
- **High TTL:** fewer queries and lower cost, but **slow changes and stale data**.
- **Low TTL:** more queries and higher cost, but **fast changes**.
- **TTL is mandatory on all records except Alias records.**
- The **console default is 300 s**.
- **Lower the TTL before a planned change**, wait for the old TTL to expire, change the record, then raise it again.
- A record change in Route 53 is **not instantly visible to clients**. Resolvers serve the old answer until their cache expires.
- `dig` shows the **remaining TTL** in the ANSWER SECTION, and it **counts down**.
- Route 53 **bills per query**, so TTL directly affects cost.

### 8. Exam-Style Recall

| If the question says... | Think... |
|---|---|
| "How long DNS resolvers cache a record" | **TTL** |
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

### 7. Key Facts to Remember

- **CNAME = hostname to hostname. Alias = hostname to AWS resource.**
- **Zone apex:** CNAME **not allowed**, Alias **allowed**.
- Alias records are **A or AAAA**.
- **Alias TTL can't be set.** It is managed by Route 53. TTL is mandatory on every other record.
- **Alias queries to AWS resources are free.** CNAME queries are billed.
- **Evaluate target health** gives an Alias a built-in health check.
- **EC2 DNS names can't be Alias targets.**
- S3: **website endpoints only** (not a plain bucket).
- Alias is **Route 53-specific**. It isn't a standard DNS record type.
- The zone apex is also called the **naked domain** or **root domain**.
- An alias to an ALB, NLB, CloudFront, and so on **tracks the target's IP changes** with no action from you.
- The alias target and the hosted zone can be in **different regions** (ELB targets are regional, but Route 53 is global).

### 8. Exam-Style Recall

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

### 4. Simple vs Multi-Value Answer (Preview)

Both can return multiple IPs, but they are different:

| | **Simple** (multiple values) | **Multi-value answer** |
|---|---|---|
| **Returns** | All values in the record | **Up to 8 healthy** records (randomly chosen) |
| **Health checks** | **No** | **Yes** |
| **Alias support** | One alias target only | No alias (A/AAAA with values) |
| **Client picks** | Yes | Yes |
| **Use for** | A single resource, or basic distribution | Client-side load balancing **with health awareness** |

- **Multi-value answer is not a replacement for a load balancer.** It only improves availability by hiding unhealthy endpoints.

### 5. Key Facts to Remember

- A routing policy decides **how Route 53 answers DNS queries**. It doesn't route actual traffic.
- **DNS only translates names.** The client connects to the endpoint itself.
- **Simple** = no special logic. It is the **default policy**.
- **Multiple values** in one simple record are **all returned**, and the **client picks randomly**.
- With **Alias**, simple routing allows **one AWS resource target** only.
- **Simple records can't have health checks.**
- A **low TTL** (the demo used 20 s) makes record changes visible quickly.
- Route 53 policies: **simple, weighted, failover, latency, geolocation, multi-value answer, geoproximity** (plus IP-based).
- Changes to a record aren't visible until the **cached answer's TTL expires**.

### 6. Exam-Style Recall

| If the question says... | Think... |
|---|---|
| "Route 53 returns the record value with no special logic" | **Simple routing** |
| "Default routing policy" | **Simple** |
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

### 6. Weighted vs Simple (and Other Policies)

| | **Simple** | **Weighted** |
|---|---|---|
| **Records** | **One** record with one or more values | **Several records**, same name and type, one value each |
| **Who chooses** | The **client**, at random (if multiple values) | **Route 53**, by weight |
| **Control over the split** | None | **Percentage control** |
| **Health checks** | **No** | **Yes** |
| **Record ID needed** | No | **Yes** |

### 7. Key Facts to Remember

- **Weighted routing** = control the **% of DNS responses** per record.
- **Share = weight / sum of weights.** The weights **needn't sum to 100**.
- Records share the **same name and type**, and each has a unique **Record ID**.
- **Weight 0** = no traffic. **All weights 0** = equal distribution.
- **Health checks** can be attached to each record.
- Main uses: **multi-region load balancing**, **testing a new version with a small share**, and **gradual traffic shifts**.
- It splits **DNS answers**, so real traffic splits depend on **caching and client count**.
- Lower the **TTL** before shifting weights so the change takes effect faster.
- Weighted records can be **Alias** records.

### 8. Exam-Style Recall

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

### 6. Health Checks and Failover Behavior

- Attach a **health check** to each latency record.
- If the **lowest-latency** record is **unhealthy**, Route 53 returns the **next-lowest-latency healthy** record.
- If **all** records are unhealthy, Route 53 **fails open** and returns an answer anyway.
- Health checks are covered in the **next lecture**.
- Alias records can use **Evaluate target health** instead of a separate health check.

### 7. Latency vs Other Routing Policies

| Policy | Chooses the answer by | Typical use |
|---|---|---|
| **Simple** | Nothing. The client picks among the values. | One resource |
| **Weighted** | **Percentages** you set | Splits, canaries, migrations |
| **Latency** | **Lowest measured latency** to a region | **Fast global performance** |
| **Failover** | **Health** (primary and secondary) | Active-passive DR |
| **Geolocation** | The user's **location** (country or continent) | Localization, legal or content restrictions |
| **Geoproximity** | **Distance** with an adjustable **bias** | Shift load between regions |
| **Multi-value answer** | Up to 8 **healthy** records | Client-side balancing with health awareness |

- **Latency** = fastest experience. **Geolocation** = content rules by location. They are often confused on the exam.

### 8. Key Facts to Remember

- **Latency-based routing** = answer with the **region that has the lowest latency** to the user.
- Latency is **measured**, so it is **not strictly geography**.
- You set a **Region** and a **Record ID** on every latency record. Records share the **same name and type**.
- You **must specify the region** for records that have an **IP value**.
- Each answer is **one record**. It is not a list.
- Supports **health checks** and **Alias** records.
- Unhealthy lowest-latency record: Route 53 uses the **next best healthy** one.
- Route 53 **doesn't proxy traffic**. It only selects the DNS answer.
- Answers can change as **latency measurements change** and when the **TTL cache** expires.
- Testing needs a **different client location** (VPN, other region, or EDNS client subnet), and a **cleared cache**.

### 9. Exam-Style Recall

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
| "What do latency records in a set share?" | The same **name and type** |
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
- **Delete** health checks you no longer need.

### 8. Key Facts to Remember

- Health checks are for **mainly public resources**. For **private** ones use a **CloudWatch alarm** health check.
- **Three types:** **endpoint**, **calculated**, **CloudWatch alarm**.
- **About 15 global health checkers**. **Healthy if more than 18%** report healthy.
- **Interval:** **30 s** standard, **10 s** fast. **Protocols:** **HTTP, HTTPS, TCP**.
- **HTTP/HTTPS healthy = 2xx or 3xx.** Text matching reads the **first 5,120 bytes**.
- **Allow the Route 53 health checker IP ranges** (`ROUTE53_HEALTHCHECKS` in `ip-ranges.json`).
- **Calculated check:** up to **255 children**, with AND/OR/at-least-N logic. Useful for **maintenance**.
- **CloudWatch alarm check:** alarm in **ALARM** state means health check **unhealthy**.
- Health checks have **CloudWatch metrics** and can trigger **SNS notifications**.
- Health checks drive **automated DNS failover**, but **TTL caching** limits how fast clients switch.
- **Simple routing** can't use health checks.

### 9. Exam-Style Recall

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
| "Which routing policy can't use health checks?" | **Simple** |
| "Health check for an Alias record to an ELB" | **Evaluate target health** |
| "Health check state when its CloudWatch alarm is in ALARM" | **Unhealthy** |

---

## Route 53 - Health Checks Hands On

### TL;DR

- Created **3 endpoint health checks** (one per EC2 instance: `us-east-1`, `ap-southeast-1`, `eu-central-1`). Each uses the instance's **IP address**, **HTTP port 80**, and path `/`, with **standard (30 s)** interval and the other options left at defaults.
- **Simulated a failure** by deleting the **HTTP inbound rule** from the Singapore instance's security group. After a short wait that health check turned **unhealthy**, and **View last failed check** showed a **connection timeout**.
- Created a **calculated health check** that monitors the other 3 checks and reports healthy only when **all** of them are healthy. It turned **unhealthy** because one child was unhealthy.
- Looked at the **CloudWatch alarm health check** option (region and alarm). It wasn't created, because no alarm existed. This is the option for **private resources**.
- The health checks aren't attached to any DNS record yet. The **next lecture** uses them with Route 53 records (failover).

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

#### 2.2 Advanced configuration (all left at defaults)

| Option | What it does | Demo choice |
|---|---|---|
| **Request interval** | **Standard = every 30 s**, or **Fast = every 10 s** (costs more) | **Standard** |
| **Failure threshold** | **Consecutive failures** needed to mark the endpoint unhealthy (1-10, default **3**) | Default |
| **String matching** | Look for specific text in the **first 5,120 bytes** of the response | Off |
| **Latency graph** | Records **latency measurements** so you can chart latency over time (extra cost) | Off |
| **Invert health check status** | Flips the result: healthy becomes unhealthy and the reverse | Off |
| **Disable health check** | Stops checking. A disabled check is treated as **healthy**. | Off |
| **Health checker regions** | Which regions the checkers run from. The default is **recommended** (all regions). | **Recommended** |

- A fast interval or extra options (string matching, HTTPS, latency graph) **cost more**, which is why the lecturer keeps standard.
- **Healthy** means **more than 18%** of the global checkers see a **2xx/3xx** response (see the Health Checks lecture).

#### 2.3 Alarm notification (last step)

- The wizard asks: **Do you want to be notified when this health check fails?**
- This would create a **CloudWatch alarm** with an **SNS topic** (email or other subscription).
- The demo chose **No**.
- Useful in production, so you learn about failures without watching the console.

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

- A **timeout** (not "connection refused") means packets were **dropped**: a **security group, NACL, or firewall** problem. That matches the rule we removed.
- This is the same pattern as in the ALB lectures: a **security group block shows as a timeout**.
- Other typical causes:

| Failure message | Likely cause |
|---|---|
| **Connection timed out** | SG, NACL, or firewall blocking the health checker IPs |
| **Connection refused** | Instance reachable but nothing listening on the port |
| **HTTP status code 5xx/4xx** | App error or wrong path |
| **String match failed** | Response didn't contain the expected text |

- **Reminder:** the Route 53 health checker IP ranges must be allowed. In this demo HTTP was open to the world, so they were. The check fails once the rule is removed.

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
- The lecturer's point: you can build **as complex a rule as you want** by combining checks. This also supports the maintenance use case: with "at least 2 of 3", one child can be taken down without failing the parent.
- **Up to 255 children** are allowed.

### 6. CloudWatch Alarm Health Check (Not Created)

#### 6.1 What the form asks for

| Setting | Detail |
|---|---|
| **What to monitor** | **State of a CloudWatch alarm** |
| **CloudWatch alarm region** | The region where the alarm lives |
| **Alarm** | Pick the alarm to track |
| **When data is insufficient** | Treat as **Healthy**, **Unhealthy**, or **Last known status** |

- Use it for **private resources** (a private EC2 instance, a resource on premises). The Route 53 checkers can't reach them, but a **CloudWatch metric and alarm** can.
- Mapping: alarm **OK** means healthy. Alarm **ALARM** means unhealthy.
- **Not created in the demo:** there was **no alarm available** in the account. You must create the alarm first.

### 7. Key Facts to Remember

- Console path: **Route 53, Health checks, Create health check**.
- **Three monitor types:** **Endpoint**, **Status of other health checks (calculated)**, **State of a CloudWatch alarm**.
- Endpoint check settings: **IP or domain, protocol (HTTP/HTTPS/TCP), port, path**.
- **Standard interval 30 s, fast 10 s.** Failure threshold default **3**.
- **String matching** reads the **first 5,120 bytes**.
- **Invert** flips the status. **Disable** stops checking (treated as healthy).
- A **blocked security group** shows up as a **connection timeout** in **View last failed check**.
- A **calculated check** can require **any, at least N, or all** children to be healthy (up to **255**).
- **CloudWatch alarm checks** are the way to health check **private resources**.
- Health checks **do nothing on their own** until you **attach them to DNS records** (next lecture).
- Health checks are **billed monthly**, so delete the ones you don't need.

### 8. Exam-Style Recall

| If the question says... | Think... |
|---|---|
| "Health check shows unhealthy, instance is running fine" | **Security group/firewall** blocking the **Route 53 health checker IPs** |
| "Why connection timeout in a failed check?" | Traffic is **blocked** (SG, NACL, firewall) |
| "Check that the response contains specific text" | **String matching** (first 5,120 bytes) |
| "Check faster than every 30 seconds" | **Fast interval (10 s)**, at higher cost |
| "Mark unhealthy only after repeated failures" | **Failure threshold** |
| "See how latency to the endpoint changes over time" | **Enable latency measurements** (latency graph) |
| "Temporarily stop a health check without deleting it" | **Disable** it (it is then treated as healthy) |
| "Reverse a check's result" | **Invert health check status** |
| "Be alerted by email when a health check fails" | Create the **alarm and SNS notification** on the health check |
| "Parent healthy only if all children are healthy" | **Calculated health check** (AND) |
| "Parent healthy if at least one child is healthy" | **Calculated health check** (OR) |
| "Health check for a private EC2 instance" | **CloudWatch alarm health check** |
| "Does creating a health check change DNS answers?" | **No.** It must be **attached to a record**. |

### 9. Hands-On Checklist

- [x] Route 53, **Health checks**, **Create health check**
- [x] Create a health check for the **`us-east-1`** instance: **Endpoint**, **IP address**, port **80**, path `/`
- [x] Review the advanced options (**interval, failure threshold, string matching, latency graph, invert, disable, regions**), keep the defaults, and skip the alarm notification
- [x] Create the same health check for **`ap-southeast-1`** and **`eu-central-1`**
- [x] Confirm all three show **Healthy**
- [x] In the **Singapore instance's security group**, **delete the HTTP inbound rule**
- [x] Wait a minute or two, then confirm `ap-southeast-1` turns **Unhealthy**
- [x] Open it and use **View last failed check** to see the **connection timeout**
- [x] Create a **calculated health check** over the 3 checks, set to **healthy when all are healthy**, and confirm it shows **Unhealthy**
- [x] Open **Create health check, State of a CloudWatch alarm** to see the options (no alarm to select)
- [x] **Next lecture:** attach the health checks to Route 53 records
- [x] **Clean up:** delete the health checks, **restore the HTTP rule** on the Singapore security group if you still need that instance, and delete the instances and ALB at the end of the section

