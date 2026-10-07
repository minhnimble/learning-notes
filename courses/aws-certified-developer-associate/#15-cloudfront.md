# CloudFront

---

## CloudFront - Overview

### TL;DR

- **CloudFront** is AWS's **CDN (content delivery network)**. Whenever the exam says **CDN**, think CloudFront.
- It **caches content at edge locations** around the world, so users get **lower latency** and **better read performance**.
- Global distribution plus **AWS Shield Standard** (automatic, no extra cost) gives **DDoS protection**. **AWS WAF** is added by you (security section).
- **Origins** (the backends CloudFront fetches from): an **S3 bucket** (secured with **OAC**), a **VPC origin** (private resources), or a **custom HTTP origin**.
- On a request, the edge location serves from its **cache**. On a **miss**, it fetches from the origin and **caches** the result for the next user (default cache time **24 hours**).
- **CloudFront vs S3 Cross-Region Replication:** CloudFront **caches static content globally**. CRR **replicates a bucket to chosen regions** (asynchronously, with no caching) for **dynamic content needed at low latency in a few regions**.

### 1. What CloudFront Does

| Property | Detail |
|---|---|
| **Type** | **Content delivery network (CDN)** |
| **Purpose** | Improve **read performance** by caching content at the edge |
| **Network** | **750+ points of presence** in 100+ cities across 50+ countries, plus **1,140+ embedded PoPs** inside ISP networks and **15 regional edge caches** (AWS docs, 2026). The lecture says about **216**. |
| **User benefit** | Lower **latency**, better user experience |
| **Security benefit** | **DDoS protection** from serving content everywhere. **Shield Standard** is on by default for CloudFront. Add **WAF** for web-layer rules and **Shield Advanced** for extra DDoS protection. |

- Lecture example: an S3 website lives in **Australia**. A US user requests it from a **US edge location**, which fetches it from Australia. The next US user gets it **straight from the edge**, with no trip to Australia. A user in China hits a Chinese point of presence the same way.

### 2. Origins

| Origin | Used for | Security |
|---|---|---|
| **Amazon S3 bucket** (REST endpoint) | Distributing and caching files at the edge, or **uploading files into S3 through CloudFront** | **Origin Access Control (OAC)** plus a bucket policy |
| **VPC origin** | Apps in **private subnets**: a private ALB, a private NLB, or private EC2 instances | Stays inside your VPC network |
| **Custom origin (HTTP)** | Any public HTTP backend, such as a **public load balancer**, or an **S3 static website** (hosting must be enabled on the bucket) | Public HTTP. **OAC doesn't apply** to custom origins. |

- **OAC** replaces the older **Origin Access Identity (OAI)**, which is legacy. OAC supports **all S3 Regions**, **SSE-KMS**, and **PUT/DELETE** requests to S3. New distributions use OAC.
- **Uploading through CloudFront:** enable the additional **allowed HTTP methods** (`PUT`, `POST`, `DELETE`, `OPTIONS`, `PATCH`) on the cache behavior, and give the **OAC** the needed S3 permissions. By default only reads (`GET`, `HEAD`) are allowed.
- **S3 static website endpoint = custom origin**, so a bucket used this way must be public. For a **private bucket**, use the S3 **REST endpoint** with **OAC**.

### 3. How a Request Flows

```
Client --HTTP request--> [Edge location]
                            |  in cache?  yes --> return the cached copy
                            |  no
                            v
                         [Origin (S3 or HTTP server)] --> response
                            |
              edge location caches it, then returns it to the client
```

- A later client of **the same edge location** gets the cached copy, with no origin request.
- With an **S3 origin**, the edge location reaches the bucket over the **private AWS network**. The bucket stays private through **OAC** and a **bucket policy** that allows CloudFront.
- Each edge location serves its **nearby users** (for example Los Angeles, or Sao Paulo for Brazil), so one bucket in a single region is served worldwide.
- **Cache duration:** **Default TTL is 24 hours (86,400 s)** when the origin sends no `Cache-Control` or `Expires` header. Minimum TTL defaults to **0** and maximum to **1 year**. Origin headers (`max-age`, `s-maxage`, `Expires`) are honored within that range.

### 4. CloudFront vs S3 Cross-Region Replication

| | **CloudFront** | **S3 Cross-Region Replication** |
|---|---|---|
| **Network** | **Global edge network** (750+ points of presence) | Only the **regions you configure** |
| **Setup** | One distribution, worldwide | Must be set up **per destination region** |
| **Freshness** | Files **cached** (24 hours by default), so updates are not instant | **Asynchronous**, usually seconds to minutes (**RTC** adds a 15-minute SLA), with **no caching** |
| **Direction** | **Read** via the cache | **One-way** by default (the lecture treats the copy as read-only) |
| **Best for** | **Static content** available everywhere | **Dynamic content** that changes often and needs low latency in **a few regions** |

- **CloudFront** = cache content worldwide. **CRR** = replicate a whole bucket into another region.

### 5. Exam-Style Recall

| If the question says... | Think... |
|---|---|
| "Content delivery network (CDN)" | **CloudFront** |
| "Lower latency for global users by caching at edge locations" | **CloudFront** |
| "DDoS protection for a global application" | **CloudFront** with **Shield** (Standard is automatic) and **WAF** |
| "Secure access from CloudFront to an S3 bucket" | **Origin Access Control (OAC)** and a bucket policy |
| "Legacy way to restrict S3 access to CloudFront" | **Origin Access Identity (OAI)**, replaced by **OAC** |
| "CloudFront in front of a private ALB, NLB, or EC2" | **VPC origin** |
| "CloudFront in front of an S3 static website or a public ALB" | **Custom origin (HTTP)** |
| "Upload files to S3 through the CDN" | **S3 origin with OAC** and the extra **HTTP methods** (`PUT`, `POST`) enabled |
| "Cache static content in many regions worldwide" | **CloudFront** |
| "Near-real-time, read-only copy of a bucket in a few regions" | **S3 Cross-Region Replication** |
| "Content in the edge cache that isn't there yet" | The edge location **fetches it from the origin** and caches it |
| "How long does CloudFront cache by default?" | **24 hours** (default TTL, when the origin sends no cache headers) |

---

## CloudFront Hands On

### 1. Preparing the S3 Bucket

| Step | Detail |
|---|---|
| **Create bucket** | `demo-cloudfront-stephan-v4`, all defaults (so it stays **private**) |
| **Upload files** | `beach.jpeg`, `coffee.jpg`, `index.html` |

**Why S3 alone isn't enough:**
1. The **object URL** of `index.html` returns **Access Denied** (the object isn't public).
2. **Open** in the console generates a **pre-signed URL**, so the page loads ("I love coffee", "hello world").
3. The **image is still missing**, because the image request isn't pre-signed and the object is private.

CloudFront fixes this without making anything public.

### 2. Creating the Distribution

1. Open the **CloudFront console** (dismiss the pricing popup) and choose **Create distribution**.
2. **Choose a plan.** The **Free** plan was used. Pick it explicitly, because the UI can default to another plan.
3. Name it `demo new CloudFront`. The demo used a **single site or app**, with no custom domain (a domain and a free **TLS certificate** can be added here).
4. **Origin type:** **Amazon S3**, then **Browse** and select the bucket.
5. **Allow private S3 bucket access to CloudFront:** **Yes**, with the **recommended origin settings** and the **recommended cache settings** for serving S3 content.
6. **Web application firewall:** nothing enabled for the demo.
7. **Next**, review (confirm **Free** plan), then **Create distribution**.

| Plan feature (lecture) | Free plan | Needs a higher plan |
|---|---|---|
| **Usage allowance** | 1 M requests and 100 GB per month | Larger allowances on Pro, Business, Premium |
| **Included** | Global CDN, always-on DDoS protection, geographic traffic blocking, free TLS certificate, Route 53 DNS | |
| **Edge key-value store** | No | **Pro** and above |
| **Uptime SLA**, regex filtering, bot management | No | **Business** and above |
| **VPC origin** (private ALB or EC2) | No | **Business** and above (the **pay-as-you-go** option has no such limit) |

- Plan availability follows the lecture and the AWS docs (flat-rate plans, Oct 2026). **Pay-as-you-go** bills by traffic, with extra charges for some features.
- Origin choices in the console: **S3**, **Elastic Load Balancer**, **API Gateway**, **Elemental MediaPackage**, **VPC origin**, or **other**.

### 3. The Bucket Policy Added Automatically

- Under the bucket's **Permissions**, **Bucket policy** now has a statement that lets the **CloudFront distribution** read the bucket privately.
- The **console wrote it** during distribution setup (this is the **OAC** setup from the overview), so you don't write it by hand.
- The demo showed **two** such statements, one from an earlier test distribution and one from the new one.

### 4. Testing the Distribution

| Request (distribution domain name +) | Result |
|---|---|
| `/` | **Access Denied**. Expected, because no object path was given. |
| `/coffee.jpg` | Coffee image loads |
| `/beach.jpeg` | Beach image loads |
| `/index.html` | Full page: "I love coffee", "hello world" **and** the image |

- Every object is **still private**. Access works only through the **bucket policy** that trusts CloudFront.
- **Caching:** requesting `/beach.jpeg` again loads **almost instantly**, because it now comes from the edge cache.
- The distribution can take a few minutes to deploy, and it must show **Enabled** before the domain works.

---

## CloudFront - Caching & Caching Policies

### TL;DR

- Each **edge location has its own cache**. Every cached object is identified by a **cache key**, and the goal is a **high cache hit ratio** (fewer requests to the origin).
- **Default cache key** = the **distribution's domain name** + the **URL path**. Query strings, headers, and cookies are **not** in it.
- A **cache policy** controls what **extra** values go into the cache key (**headers, cookies, query strings**) and the **TTLs**. Use a **managed policy** (such as **CachingOptimized**) or create your own.
- **Everything in the cache key is automatically forwarded to the origin.** More values in the key = **worse hit ratio**.
- An **origin request policy** forwards extra values to the origin **without** adding them to the cache key (analytics, origin logic, **CloudFront headers**).
- To remove an object **before its TTL expires**, create an **invalidation** (next lecture).

### 1. How Caching Works

```
Viewer --> [Edge location cache]
              |  cache key found and not expired?  yes --> cache HIT, return it
              |  no
              v
           request goes to the origin --> response is cached at the edge --> returned to the viewer
```

| Concept | Detail |
|---|---|
| **Where** | **One cache per edge location**, so a hit at one location doesn't help another. **Regional edge caches** sit in between and hold content longer. |
| **Cache key** | The **unique identifier** of an object in the cache |
| **Hit or miss** | Hit if the key is in the cache **and** the object hasn't passed its **TTL**. Otherwise a miss goes to the origin. |
| **Cache hit ratio** | Maximize it by **caching as much as possible** and keeping the cache key **small** |
| **Early removal** | **Invalidation** (next lecture) instead of waiting for the TTL |

### 2. The Cache Key

**Default cache key:**

| Part | Example |
|---|---|
| **Distribution domain name** (the lecture calls it the host name) | `d111111abcdef8.cloudfront.net` or your own alias such as `mywebsite.com` |
| **URL path** (resource portion) | `/content/stories/example-story.html` |

- Two requests with the **same domain and path** are the **same object**, even if their **query strings, headers, or cookies differ**. The second one is a **cache hit**.
- **Customize** the key when the response **varies** by user, device, language, or location. Include **only** the values that really change the response.
- A highly variable value (such as `User-Agent`, or a session cookie unique to each user) stores **many duplicate copies** and ruins the hit ratio. Prefer **separate URLs** per variant (for example `/fr-fr/blog`).

### 3. Cache Policies

A cache policy has **TTL settings** and **cache key settings**. You attach it to a **cache behavior**.

**Cache key settings:**

| Value | Options in a cache policy |
|---|---|
| **HTTP headers** | **None**, or **include list** only. There is **no "all" and no "all except"** for headers. |
| **Cookies** | **None**, **include list**, **all except** (exclude list), or **all** |
| **Query strings** | **None**, **include list**, **all except**, or **all** |

- **None** gives the **best cache performance**. **All** gives the **worst**.
- You list headers, cookies, and query strings **by name**, and CloudFront uses their **full values** in the key (for example `Accept-Language: fr-fr`).
- **Compression:** enabling **Gzip** and **Brotli** caching adds a **normalized `Accept-Encoding`** value to the key, so compressed variants are cached separately.

**TTL settings:**

| Setting | Meaning |
|---|---|
| **Default TTL** | Used **only when the origin sends no** `Cache-Control` or `Expires` header |
| **Maximum TTL** | Caps the TTL from origin headers (**up to 1 year**, 31,536,000 s) |
| **Minimum TTL** | Floor on the TTL. When above 0, it applies **even if** the origin sends `no-cache`, `no-store`, or `private`. |
| **All three = 0** | **Caching is disabled** |

- Origin headers `Cache-Control` (`max-age`, `s-maxage`) and `Expires` set the TTL **within** the minimum/maximum range.

**Managed cache policies (examples):**

| Policy | Behavior |
|---|---|
| **CachingOptimized** | **Recommended for S3**. Default TTL **24 h**, min **1 s**, max **365 days**. **No** headers, cookies, or query strings in the key. Gzip and Brotli on. |
| **CachingDisabled** | TTLs all **0**, nothing in the key. For **dynamic or non-cacheable** content. |
| **CachingOptimizedForUncompressedObjects** | Same as CachingOptimized, with compression caching off |
| **UseOriginCacheControlHeaders** / **-QueryStrings** | Default TTL **0**, so the origin's `Cache-Control` decides. The second also keys on **all query strings**. |

### 4. Headers and Query Strings in the Cache Key

**Headers** (example: `Accept-Language: fr-fr` to get the blog in French):

| Cache policy header setting | Result |
|---|---|
| **None** | No headers in the key and **not forwarded**. Best caching, but the origin can't see the language. |
| **Include `Accept-Language`** | Header goes into the key **and is forwarded**, so each language is cached separately and the origin can answer in French |

**Query strings** (example: `/cat.jpg?border=red&size=large`, the origin customizes the image):

| Setting | Result |
|---|---|
| **None** | Not in the key, **not forwarded** |
| **Include list** | Only the named ones are in the key and forwarded |
| **All except** | Everything **but** the named ones |
| **All** | Every query string in the key and forwarded. **Worst hit ratio** when there are many. |

- **Key rule:** whatever you put in the cache key is **also forwarded** in the origin request.

### 5. Origin Request Policies

- Use an origin request policy for values the **origin needs** but that **don't change the cached object**. They are **forwarded but not part of the cache key**.
- It can forward **headers, cookies, and query strings** (with **None, all, include list, or all except** options), and **add CloudFront headers** (device type, viewer country, and so on) that the viewer never sent.
- It **requires a cache policy** on the same cache behavior.
- Use a **managed policy** or create your own.

| Managed origin request policy | Forwards |
|---|---|
| **AllViewer** | All viewer headers, cookies, and query strings |
| **AllViewerAndCloudFrontHeaders-2022-06** | All viewer values **plus** the CloudFront headers released through June 2022 |
| **AllViewerExceptHostHeader** | Everything **except `Host`**. For **API Gateway** and **Lambda function URL** origins. |
| **CORS-S3Origin** | `Origin`, `Access-Control-Request-Headers`, `Access-Control-Request-Method`, for **CORS** with S3 |
| **UserAgentRefererHeaders** | `User-Agent` and `Referer` only |

- **Static secret headers** (for example an API key sent to the origin) are configured as **Origin Custom Headers** on the **origin**, not in an origin request policy. The lecture groups them together.
- Even with no policy, every origin request carries the **URL path**, the **request body**, and `Host`, `User-Agent`, and `X-Amz-Cf-Id`.

### 6. Cache Policy vs Origin Request Policy

```
Viewer request: query strings + cookies + headers
        |
        +--> Cache policy:           builds the CACHE KEY       (host + path + authorization)
        |         \
        |          +--> forwarded to the origin automatically
        |
        +--> Origin request policy:  EXTRA values for the origin only   (user agent, session id, ref)
                      \
                       +--> forwarded to the origin, NOT used for caching
```

| | **Cache policy** | **Origin request policy** |
|---|---|---|
| **Decides** | What identifies a cached object, plus TTLs and compression | What extra the origin receives |
| **Affects the cache key** | **Yes** | **No** |
| **Forwarded to the origin** | **Yes**, everything in the key | **Yes** |
| **Needed on the behavior** | Yes | Optional, but only works with a cache policy |

- The origin request is the **union** of the cache-key values and the origin request policy values. **Caching** still uses **only the cache policy**.
- If both policies list the same value, the **cache policy's** inclusion wins, so a value in the key is always forwarded.

### 7. Exam-Style Recall

| If the question says... | Think... |
|---|---|
| "What identifies an object in the CloudFront cache?" | The **cache key** |
| "Default cache key" | **Distribution domain name + URL path** only |
| "Cache different versions by language, device, or country" | Add the header (or cookie or query string) to the **cache policy** |
| "Improve the cache hit ratio" | **Fewer** values in the cache key. Use **None** or an **include list**, not **All**. |
| "Maximum caching performance with a managed policy" | **CachingOptimized** |
| "Disable caching for dynamic content" | **CachingDisabled** (or all TTLs = 0) |
| "Which headers can a cache policy include?" | **None** or an **include list** (no all, no all except) |
| "Origin needs a header, but it must not split the cache" | **Origin request policy** |
| "Values in the cache key are sent to the origin" | **Yes**, automatically |
| "Origin request policy without a cache policy" | **Not possible**. A cache policy is required. |
| "TTL when the origin sends no cache headers" | The cache policy's **Default TTL** (24 h in CachingOptimized) |
| "Origin behind API Gateway breaks when CloudFront forwards the host" | **AllViewerExceptHostHeader** origin request policy |

---

## CloudFront - Cache Invalidations

### TL;DR

- Updating the **origin** does **not** update the edge caches. Edge locations keep serving the old copy **until the TTL expires**.
- A **cache invalidation** removes objects from the edge caches **before the TTL expires**, so the next request fetches the new version from the origin.
- You invalidate by **path**: a single file (`/index.html`), a folder (`/images/*`), or **everything** (`/*`).
- It is a **full or partial** cache refresh. It **ignores the TTL**, because the objects are simply **removed** from the cache.
- **Alternative:** **versioned file names** (`logo-v2.jpg`) avoid invalidation entirely and are what AWS recommends for frequent updates.

### 1. How an Invalidation Works

```
Admin updates S3 bucket (index.html, images/*)
Admin creates invalidation: /index.html  and  /images/*
        |
        v
CloudFront tells every edge location --> they remove those objects from their cache
        |
Next viewer request --> cache miss --> edge location fetches the new file from the origin --> caches it
```

- **Scenario:** two edge locations each cache `index.html` and the images from an **S3 origin**, with a **1-day TTL**. After you change the files, the edge locations would otherwise serve the **old** versions for up to a day.
- Each invalidation path **removes** the cached copies. Nothing is pushed to the edge: the **next request** after the removal triggers the origin fetch.
- You **can't cancel** an invalidation once it is submitted, so check the paths first.

### 2. Invalidation Paths

| Path | Invalidates |
|---|---|
| `/index.html` | One file |
| `/images/*` | Everything under `/images/` |
| `/*` | **Every file** in the distribution |
| `/images/logo.*` | All extensions of `logo` (`logo.jpg`, `logo.png`, ...) |

- Paths are **case sensitive**, and the `*` wildcard must be the **last character**.
- Via the **CLI or API**, paths start with `/` and a wildcard path needs **quotes**: `aws cloudfront create-invalidation --distribution-id <ID> --paths "/*"`. The console accepts paths without the leading slash.
- **Query strings:** if they are forwarded (in the cache key), include them in the path, or use a trailing wildcard (`/image.jpg*`).
- An invalidation removes **every cached variant** of the file (all header, cookie, and query string versions). You can't remove only some.
- **Tag invalidation (newer):** the origin returns **cache tag** headers, and `--paths "#product:electronics"` invalidates every object with that tag, whatever its URL.

### 3. Cost and Alternatives

| Topic | Detail |
|---|---|
| **Free allowance** | The **first 1,000 invalidation paths per month** (per AWS account) are free. After that, you pay **per path**. |
| **Wildcards** | `/*` counts as **one** path, however many files it removes |
| **Versioned file names** | `logo-v2.jpg`: new name = new cache key, so no invalidation and **no charge**. It also beats stale copies in **browser or proxy caches**. |
| **Short TTL** | Lower **Default TTL** so objects refresh sooner, at the cost of more origin requests |

### 4. Exam-Style Recall

| If the question says... | Think... |
|---|---|
| "Updated the origin, but users still see old content" | The edge caches hold the old copy until the **TTL expires**. Create an **invalidation**. |
| "Serve new content immediately without waiting for the TTL" | **CloudFront invalidation** |
| "Invalidate everything in the distribution" | Path **`/*`** |
| "Invalidate all the images" | Path **`/images/*`** |
| "Avoid paying for invalidations on frequent updates" | **Versioned file names** |
| "Which CloudFront setting decides how long before the cache refreshes on its own?" | The **TTL** (default 24 hours) |

---

## CloudFront - Cache Behaviors

### TL;DR

- A **cache behavior** applies its own settings (origin, cache policy, viewer protocol, allowed methods, signed access) to requests that match a **path pattern**.
- Use different behaviors to **route paths to different origins** (`/images/*` to **S3**, `/api/*` to an **ALB**) and to **tune caching per content type**.
- The **default cache behavior** has the pattern **`*`**. It **can't be changed** and is **always processed last**.
- CloudFront evaluates the patterns **in the order they are listed**, and the **first match wins**. The lecture says it looks for the "more specific match", but the docs say **listed order**, so put specific patterns **above** general ones.
- **Signed cookies** (or signed URLs) gate content: a behavior that requires them rejects unsigned viewers, and your app (for example an EC2 `/login` page) issues the cookies.
- Use separate behaviors to **maximize cache hits**: **static** content (S3) with a minimal cache key, **dynamic** content (ALB/EC2) with a cache key built from the headers and cookies it needs.

### 1. What a Cache Behavior Is

| Setting per behavior | Detail |
|---|---|
| **Path pattern** | Which requests the behavior applies to (`/api/*`, `*.jpg`, `*` for the default) |
| **Origin or origin group** | **One** origin per behavior. To use N origins, you need **at least N behaviors**. |
| **Cache policy / origin request policy** | Cache key, TTLs, and extra values for the origin (see the previous lectures) |
| **Viewer protocol policy** | **HTTP and HTTPS**, **Redirect HTTP to HTTPS**, or **HTTPS only** |
| **Allowed HTTP methods** | `GET, HEAD`, `GET, HEAD, OPTIONS`, or all methods (`PUT`, `POST`, `PATCH`, `DELETE`) |
| **Restrict viewer access** | Require **signed URLs or signed cookies** |

### 2. Path Patterns and Precedence

```
Viewer request ---> /api/*  ?   yes --> ALB origin
                      | no
                      v
                      /*  (default behavior, always last) --> S3 origin
```

| Rule | Detail |
|---|---|
| **Wildcards** | `*` matches **0 or more** characters, `?` matches **exactly 1**. A leading `/` is optional. |
| **Case** | Path patterns are **case sensitive** (`*.jpg` doesn't match `LOGO.JPG`) |
| **Order** | Patterns are checked **in the listed order**. The **first match wins**, and the default (`*`) is **last**. |
| **Not considered** | **Query strings and cookies** aren't used to match a pattern |

- **Order matters for security:** if a broad pattern without signed URLs sits above a narrower one that requires them, the narrower behavior **never applies**.
- Example: `images/*.jpg`, then `images/*`, then `*.gif`. A request for `images/sample.gif` skips the first pattern and takes the second, even though it also matches the third.
- Typical split: `/images/*` to **S3**, `/api/*` to your **application origin** (ALB), and the default `*` to the main origin.

### 3. Use Case: Gating an S3 Bucket with Signed Cookies

```
1. User --> /login  (behavior: origin = EC2 login app)
2. EC2 app authenticates the user and returns Set-Cookie headers = CloudFront signed cookies
3. User --> /anything-else  (default behavior, requires signed cookies, origin = S3 bucket)
4. CloudFront checks the cookie signature --> serves the S3 file
   No valid cookie --> request rejected --> user is sent to /login
```

| Piece | Role |
|---|---|
| **`/login` behavior** | Public (no signed cookies), routes to the **EC2** app |
| **EC2 app** | Authenticates the user and **generates the signed cookies** (CloudFront doesn't sign them for you) |
| **Default behavior** | **Restrict viewer access = Yes**, so it only accepts requests with **valid signed cookies** |
| **Trusted key group** | The **public keys** CloudFront uses to verify signatures. Your app signs with the private key. |

- Signed cookies vs signed URLs, policies, and key groups are covered in **CloudFront Signed URL / Cookies**.
- Send the user to the login page through the **error page** of the protected behavior.

### 4. Use Case: Maximizing Cache Hits

| Behavior | Origin | Cache key |
|---|---|---|
| **Static** (for example `/images/*`) | **S3** | **Minimal**: no headers, cookies, or query strings, so it caches on the **resource path** only |
| **Dynamic** (for example `/api/*`) | **ALB** with EC2 (REST/HTTP server) | **Only** the headers, cookies, and query strings the app needs (per your **cache policy**) |

- Keeping static and dynamic content in **separate behaviors** means dynamic cache-key settings never **fragment** the static cache.

### 5. Exam-Style Recall

| If the question says... | Think... |
|---|---|
| "Different origins or caching rules per URL path" | **Multiple cache behaviors** with **path patterns** |
| "Route `/api/*` to an ALB and everything else to S3" | A behavior for `/api/*` and the **default behavior (`*`)** |
| "Which behavior catches requests that match no pattern?" | The **default cache behavior** (`*`) |
| "Two patterns match the same request" | The **first one in the list** wins |
| "Require users to log in before accessing S3 content through CloudFront" | A behavior requiring **signed cookies**, plus a **login** behavior to an app that issues them |
| "Maximize cache hits for static files, but vary dynamic content by header" | **Separate behaviors** with different **cache policies** |
| "Force HTTPS for a path" | **Viewer protocol policy** on that behavior |

---

## CloudFront - Caching & Caching Invalidations - Hands On

### 1. Cache Behavior Settings

1. Open the distribution, go to **Behaviors**, and **edit** the **Default (`*`)** behavior.
2. The **path pattern** is **greyed out**, because it can't be changed on the default behavior.
3. Scroll to **Cache key and origin requests**: a **cache policy** is required, and an **origin request policy** is optional.

### 2. Creating a Cache Policy

Choose **Create cache policy** and name it `DemoCachePolicy`.

| Section | What the console offers |
|---|---|
| **TTL settings** | **Minimum**, **maximum**, and **default** TTL |
| **Headers** | Pick from the **list** of headers, or **add a custom header** |
| **Query strings** | **All**, or a **list** of names to add |
| **Cookies** | **All**, or a **list** of names to add |

- Whatever you select is **in the cache key**, and it is also **passed to the origin**.
- The demo only looked at the options and **cancelled**, so no policy was attached.

### 3. Creating an Origin Request Policy

Choose **Create origin request policy** and name it `DemoOriginPolicy`.

- It has the same three sections: **headers**, **query strings**, and **cookies**.
- Values chosen here are **added to the origin request** but **not to the cache key**.

### 4. Adding a Second Behavior

1. In **Behaviors**, choose **Create behavior**.
2. **Path pattern:** `/images/*`.
3. **Origin:** a **new origin** for the images (another S3 bucket or an EC2 instance would work).
4. Give it its **own cache policy and origin request policy** if needed.

- The two behaviors **coexist**: `/images/*` goes to the new origin, everything else to the default behavior.
- The lecture says "the most specific one is selected first". CloudFront actually uses the **listed order**, so see **CloudFront - Cache Behaviors** and put `/images/*` **above** the default.

### 5. Demo: A Stale Cached File, Then an Invalidation

| Step | Action | Result |
|---|---|---|
| 1 | Edit `index.html`: change the text to **"I really love coffee every morning"** | Local change only |
| 2 | **Upload** the new `index.html` to the S3 bucket. **Versioning is off**, so it **replaces** the old file. | Upload succeeds |
| 3 | Open the object from **S3** (**Open**, pre-signed URL) | Shows the **new** text |
| 4 | **Refresh the CloudFront URL** | Still shows the **old** text ("I really love coffee"). CloudFront cached the old file (**1 day**, the default TTL) and doesn't ask S3. |
| 5 | CloudFront console, distribution, **Invalidations** tab, **Create invalidation** | Add the path **`/*`** |
| 6 | Wait for the invalidation to show **Completed** | Every cached object is **removed** |
| 7 | **Refresh the CloudFront URL** | Shows the **new** text. CloudFront fetched the file from S3 again. |

---

## CloudFront - ALB/EC2 as an Origin

### TL;DR

- **VPC origins** (the newer, better way) let CloudFront reach an **ALB, NLB, or EC2 instance in a private subnet**. Nothing is exposed to the internet, and CloudFront is the **single entry point**.
- The older way was a **public** ALB or EC2 instance whose **security group allows only CloudFront's public IPs**. It works, but it is more tedious and easier to get wrong.
- For the older way, use the **CloudFront managed prefix list** instead of maintaining the IP list by hand.
- A VPC origin supports **ALB, NLB, and EC2**. It does **not** support **Gateway Load Balancers** or **NLBs with TLS listeners**.

### 1. Option A: VPC Origins (Recommended)

```
Users --> [CloudFront edge locations] --> VPC origin --> private subnet: ALB / NLB / EC2
                                                          (no public IP, no internet exposure)
```

| Aspect | Detail |
|---|---|
| **Origins supported** | **Application Load Balancer**, **Network Load Balancer**, **EC2 instance**, all in **private subnets** |
| **Security** | Traffic goes from CloudFront to your VPC over a **private, secure connection**. The app stays **private** and you choose what to expose through CloudFront. |
| **Setup** | **VPC origins**, **Create VPC origin**, pick the resource's **ARN**, wait for **Deployed** (up to about 15 minutes). Then use it as the **origin** of a distribution. For an EC2 instance, paste its **private IP DNS name** as the origin domain. |
| **VPC requirements** | An **internet gateway attached** to the VPC (it only marks the VPC as reachable, no route changes), and a **private subnet** with **at least one free IPv4 address** for the **ENI** CloudFront creates |
| **Security group** | The origin needs a security group allowing CloudFront: the **managed prefix list**, or the service-managed **`CloudFront-VPCOrigins-Service-SG`** (more restrictive, available after the VPC origin exists) |
| **Not supported** | **GWLB** origins, **NLB with TLS listeners**, **gRPC**, and **Lambda@Edge origin request/response** triggers |
| **Plan note** | On the **flat-rate plans**, VPC origins need **Business** or higher (see the CloudFront Hands On plan table) |

- VPC origins can be **shared across AWS accounts** (console or **AWS RAM**).

### 2. Option B: Public Origin Restricted to CloudFront IPs (Older Way)

```
Users --> [CloudFront edge locations] --> public EC2 instance
                                          security group allows only CloudFront public IPs

Users --> [CloudFront edge locations] --> public ALB (security group: CloudFront IPs only)
                                              |
                                              +--> private EC2 instances (security group: ALB only)
```

| Step | Detail |
|---|---|
| **1. Make the origin public** | The EC2 instance (or the ALB) needs a **public IP** so CloudFront can reach it. EC2 instances behind the ALB stay **private**. |
| **2. Allow only CloudFront** | Set the security group so inbound traffic is allowed **only from CloudFront's IPs** |
| **3. Find the IPs** | **`ip-ranges.json`** (service **`CLOUDFRONT`**), or better, the **CloudFront managed prefix list** `com.amazonaws.global.cloudfront.origin-facing` (IPv4) and `com.amazonaws.global.ipv6.cloudfront.origin-facing` (IPv6). AWS keeps the prefix list **up to date**. |
| **4. Protect EC2 behind an ALB** | The instances' security group references the **ALB's security group** |

- **Drawbacks:** the origin is still **public**, finding and maintaining the IP list is **tedious** (the lecture's point), and a **wrong security group change** can expose the origin to **more than CloudFront**.

### 3. Comparison

| | **VPC origin** | **Public origin + security group** |
|---|---|---|
| **Origin location** | **Private subnet** | **Public** |
| **Exposure** | Not reachable from the internet | Reachable, restricted by security group only |
| **Maintenance** | Low | Prefix list or IP ranges |
| **Risk** | Low | A bad security group change **exposes** the origin |
| **Verdict** | **Recommended** | **Older** approach |

### 4. Exam-Style Recall

| If the question says... | Think... |
|---|---|
| "CloudFront in front of an ALB, NLB, or EC2 in a **private subnet**" | **VPC origin** |
| "Keep the application private, with CloudFront as the only entry point" | **VPC origin** |
| "Origin is a public ALB or EC2, accept traffic **only from CloudFront**" | Security group allowing the **CloudFront managed prefix list** |
| "Where do I get CloudFront's IP ranges?" | **`ip-ranges.json`** (`CLOUDFRONT`), or the **managed prefix list** |
| "Can a VPC origin point to a **Gateway Load Balancer**?" | **No** (nor an NLB with TLS listeners) |
| "Why is the public-origin setup risky?" | Someone can **change the security group**, exposing the origin beyond CloudFront |

---

## CloudFront - Geo Restriction

### TL;DR

- **Geo restriction** (geo blocking) controls access to a distribution by the **viewer's country**.
- Two modes: an **allow list** (only approved countries) or a **block list** (banned countries).
- The country comes from a **third-party geo-IP database** that maps the viewer's IP address to a country.
- Blocked viewers get an **HTTP 403 (Forbidden)**, and you can show a **custom error page**.
- **Use case:** **copyright and licensing**, for example content you only have the rights to distribute in certain countries.
- It applies to the **whole distribution** and works **per country**. For a **subset of files** or **finer than country**, use a **third-party geolocation service** with **signed URLs**.

### 1. How Geo Restriction Works

```
Viewer in a banned country --> nearest edge location
                                  checks the country (geo-IP database)
                                  not allowed --> HTTP 403 Forbidden (optional custom error page)
Viewer in an allowed country --> normal caching and delivery
```

| Aspect | Detail |
|---|---|
| **Modes** | **Allow list** (approved countries only) or **block list** (banned countries). Pick one. |
| **Scope** | The **entire distribution**. For different rules on different content, use **separate distributions**. |
| **Granularity** | **Country level** |
| **Detection** | **Third-party geo-IP database**. Accuracy is high (docs: about **99.8%**), and if the location **can't be determined**, CloudFront **serves the content**. |
| **Result** | **403 Forbidden**. Optionally a **custom error page**, whose error response is **cached for 10 seconds** by default. |
| **Console path** | Distribution, **Security** tab, **Geographic restrictions**, **Edit**, choose **Allow list** or **Block list**, add countries, **Save changes** |
| **Logs** | Blocked requests appear as **403** in the access logs (not distinguishable from other 403s) |

- **Finer control:** to restrict only some files or to use city, ZIP code, or coordinates, use a **third-party geolocation service**. Your app checks the viewer's IP and issues a **signed URL** only for allowed locations. Pair it with an **S3 origin** and **OAC** so users can't bypass CloudFront.

### 2. Plans and the Console (Demo Note)

- In the lecture, the **Free plan** distribution didn't show the Geographic restrictions option. He created another distribution on **pay-as-you-go** billing, where **Security** offered the allow/block list and he blocked two countries.
- The AWS docs list **Geographic traffic blocking** as a feature of **all flat-rate plans, including Free**. The lecture saw it missing in the console, so check your own distribution's **Security** tab. On **pay-as-you-go** the option is available.

### 3. Exam-Style Recall

| If the question says... | Think... |
|---|---|
| "Block users in certain countries from a CloudFront distribution" | **Geo restriction** with a **block list** |
| "Only allow users from specific countries" | **Geo restriction** with an **allow list** |
| "Content licensed for only some countries" | **CloudFront geo restriction** |
| "What does a blocked viewer receive?" | **HTTP 403 (Forbidden)** |
| "How does CloudFront know the user's country?" | A **third-party geo-IP database** (IP address to country) |
| "Restrict only some files, or by city" | **Third-party geolocation service** with **signed URLs** |
| "Different geo rules for different parts of the content" | **Separate distributions**, since geo restriction is **per distribution** |

---

## CloudFront Signed URL / Cookies

### TL;DR

- Use a **CloudFront signed URL or signed cookie** to make a distribution **private** and give **paying or known users** access, knowing **who has access to what**.
- Both carry a **policy**: **expiration** (required), and optionally a **start time**, an **IP range**, and the **path**.
- A **signed URL** = access to **one file** (one URL per file). A **signed cookie** = access to **many files**, with **no URL changes**.
- **Your application** (using the **AWS SDK**) authenticates the user and **generates** the signed URL or cookie. CloudFront only **verifies** it.
- **Signers:** use a **trusted key group** (recommended). The lecture's "account-wide key pair, root only" is the **older** method.
- **CloudFront signed URL vs S3 pre-signed URL:** CloudFront signed URLs work for **any origin** and use **CloudFront caching**. S3 pre-signed URLs go **directly to S3** with the **signer's permissions**.

### 1. What Goes in the Policy

| Element | Detail |
|---|---|
| **Expiration** | **Required.** Short (**minutes**) for rentals and downloads. Long (**years**) for private content users revisit. |
| **Start time** | Optional (custom policy only) |
| **IP range** | Optional (custom policy only). Use it **when you know the clients' IPs**. |
| **Path** | A specific file, or a **wildcard** to reuse the policy across files (custom policy only) |
| **Signer** | The **trusted key group** (or account) whose private key signs it |

| | **Canned policy** | **Custom policy** |
|---|---|---|
| **Expiration** | Yes | Yes |
| **Start time, IP range** | No | Optional |
| **Reuse across files** (wildcards) | No | Yes |
| **URL length** | Shorter | Longer (the policy is base64-encoded in the URL) |

- CloudFront checks the expiry **when the request arrives**. A download that started before the expiry can finish.

### 2. Signed URL vs Signed Cookie

| | **Signed URL** | **Signed cookie** |
|---|---|---|
| **Access to** | **Individual files** (100 files means 100 URLs) | **Multiple files** with **one cookie**, reusable |
| **URLs** | Change (they carry the signature) | **Stay the same** |
| **Use when** | One file (an installer download), or **clients without cookie support** | A **subscriber area**, or all the files of an **HLS video** |
| **Precedence** | **Wins** if both are used on the same file | |

- A signed cookie is **three `Set-Cookie` name-value pairs** sent by your app.

### 3. Signers: Trusted Key Groups

| | **Trusted key group (recommended)** | **Trusted signer / CloudFront key pair (older)** |
|---|---|---|
| **Managed by** | **IAM users** with CloudFront permissions, through the **API and console** | The **AWS account root user**, console only |
| **Automation and rotation** | Yes, via the API | No |
| **Limits** | Up to **4 key groups** per distribution, **5 public keys** per group | **2 active key pairs** per account |

**Setup:**
1. Create an **RSA 2048** (or **ECDSA 256**) key pair.
2. Upload the **public key** to CloudFront and add it to a **key group**.
3. In the **cache behavior**, set **Restrict viewer access = Yes** and choose the **key group**. From then on CloudFront **rejects unsigned requests**.
4. Your app signs with the **private key**. The **public key ID** goes in the `Key-Pair-Id` field.

- Signers attach to **cache behaviors**, so you can protect some paths and leave others public (mind the **path pattern order**).
- Rotate keys by **adding** the new key first, and removing the old one **after** the URLs it signed expire.

### 4. How It Works with S3

```
Client --authenticates--> Your app (EC2 / Lambda, uses the AWS SDK)
Client <--signed URL / cookie-- Your app
Client --signed URL--> CloudFront --OAC--> S3 bucket (private, bucket policy allows only CloudFront)
```

- The bucket stays **private** (only CloudFront can read it through **OAC**), and the signed URL or cookie is how users get through CloudFront.
- If the bucket policy only allows CloudFront, an **S3 pre-signed URL** (direct S3) can't be used for content served this way.

### 5. CloudFront Signed URL vs S3 Pre-signed URL

| | **CloudFront signed URL** | **S3 pre-signed URL** |
|---|---|---|
| **Origin** | **Any**: S3, EC2, ALB, any HTTP backend | **S3 only** |
| **Access goes through** | **CloudFront** (edge caching, global performance) | **Directly to S3** |
| **Who signs** | A **key pair** (trusted key group), not an IAM user's credentials | An **IAM principal**, whose permissions the URL **inherits** |
| **Filter by** | **IP, path, date, and expiration** | Expiration (and the signer's permissions) |
| **Use when** | Content is **behind CloudFront** (an OAC-protected bucket) | You share S3 objects **directly**, without CloudFront |

- See **S3 Pre-signed URLs** (S3 Security) for how S3 pre-signed URLs work.

### 6. Exam-Style Recall

| If the question says... | Think... |
|---|---|
| "Private distribution, paid users, know who accesses what" | **Signed URL or signed cookie** |
| "Access to **one file**" | **Signed URL** |
| "Access to **many files**, keep the URLs unchanged" | **Signed cookie** |
| "Client doesn't support cookies" | **Signed URL** |
| "Who creates the signed URL?" | **Your application**, with the **AWS SDK** and the **private key** |
| "Recommended signer for new setups" | **Trusted key group** (not the root user's key pair) |
| "Restrict signed URLs to client IP addresses" | **Custom policy** with an **IP range** |
| "Signed URL for an **EC2 or ALB origin**" | **CloudFront signed URL** (works for any origin) |
| "Share an S3 object directly, no CloudFront" | **S3 pre-signed URL** |
| "S3 bucket behind CloudFront, give users access" | **CloudFront signed URL or cookie** (the bucket only trusts **OAC**) |

---

## CloudFront Signed URL - Key Groups + Hands On

The key group vs key pair comparison, limits, and setup flow are in **CloudFront Signed URL / Cookies** (section 3). This demo walks through the console.

### 1. Generating the Key Pair

| Step | Detail |
|---|---|
| **Where** | CloudFront console, left menu, **Public keys** and **Key groups** |
| **Generate** | An **RSA** key pair, **2,048 bits** (the key size matters: other sizes are rejected). The lecture used an **online RSA generator** and clicked **Generate new keys** until it produced a 2,048-bit pair. |
| **Private key** | Used by **your app** (for example the **EC2 instances**) to **sign** URLs. Keep it **secret** and store it **securely**. |
| **Public key** | Uploaded to **CloudFront** to **verify** signatures. It can be **regenerated from the private key**. |

- For real use, **generate the pair locally** (not on a website), for example with OpenSSL:

```
openssl genrsa -out private_key.pem 2048
openssl rsa -pubout -in private_key.pem -out public_key.pem
```

### 2. Creating the Public Key and Key Group

1. **Public keys**, **Create public key**. **Key name:** `demo key`. **Key value:** paste the **public key** (the `-----BEGIN PUBLIC KEY-----` block). **Add**.
2. If it errors, check the key is **2,048 bits**.
3. **Key groups**, **Create key group**. **Name:** `demo key group`. Add `demo key` (a group holds **up to 5 public keys**). **Create key group**.
4. The **key group** is what a **cache behavior** references (**Restrict viewer access = Yes**, **Trusted key groups**) so your app can sign URLs.

- The demo was done as the **root user**, but **any IAM user** with the right CloudFront permissions can create public keys and key groups.

### 3. The Old Way: CloudFront Key Pairs

1. Sign in as the **root user**, then account menu, **My Security Credentials**.
2. Find the **CloudFront key pairs** section.
3. **Create new key pair**, **download the private key file** (and the public key file), **Close**.
4. The pair can be set **Active**, **Inactive**, or **Deleted**, and it **applies to every distribution** in the account. You still have to **give the private key to your EC2 instances**.

| Why it's discouraged | |
|---|---|
| **Root user only** | You shouldn't use the root account for this |
| **Console only** | **No API**, so no automation or rotation |
| **Account-wide** | Not scoped to a distribution, and no IAM control |

---

## CloudFront Advanced Concepts

### TL;DR

- **Pricing (pay-as-you-go):** data transfer out **varies by region** and **drops as volume grows**. A **price class** limits which edge locations serve your distribution, to **cut cost** at some **performance** cost.
- **Price classes:** **All** (every region, best performance, highest cost), **200** (most regions, excludes the most expensive), **100** (the cheapest regions: North America and Europe).
- **Multiple origins** by path use **cache behaviors**. **Origin groups** (primary and secondary) are for **high availability and failover**.
- **Origin group + two S3 buckets in different regions with replication** gives **region-level disaster recovery**.
- **Field-level encryption** encrypts up to **10 sensitive POST fields** at the **edge** with a **public key**. Only the app with the **private key** can decrypt them.

### 1. Pricing and Price Classes

Data transfer out of CloudFront to the internet is billed **per GB**, by the **region of the edge location**. Rates fall as volume grows.

| Edge location region | First 10 TB | Over 5 PB |
|---|---|---|
| **US, Canada, Mexico, Europe** | **$0.085**/GB | **$0.02**/GB |
| **India** | **$0.109**/GB | $0.072/GB |
| **Japan** | $0.114/GB | $0.06/GB |
| **Australia, New Zealand** | $0.114/GB | $0.08/GB |
| **Asia Pacific** (other) | $0.12/GB | $0.06/GB |
| **South America, Middle East, Africa** | $0.11/GB | $0.04/GB |

- Source: AWS price list, Oct 2026 (US dollars). The lecture quotes about **$0.08** for the US and **$0.17** for India, which are older figures. The **pattern** is what matters: **US and Europe are cheapest**, **South America, Asia Pacific, and Australia** cost more, and **more volume means a lower rate**.
- **Pay-as-you-go** also includes a free allowance (the first **1 TB** of data transfer out per month). **Flat-rate plans** replace this per-GB billing.

**Price classes** (pay-as-you-go) let you **use fewer edge locations** to cut cost:

| Price class | Edge locations used | Trade-off |
|---|---|---|
| **Price Class All** | **All regions** | **Best performance**, highest cost |
| **Price Class 200** | **Most regions**: 100 plus Africa, Middle East, and most of Asia Pacific (Japan, India, Singapore, and so on) | Excludes the **most expensive** regions |
| **Price Class 100** | **Cheapest regions**: **USA, Canada, Europe, Israel** | **Lowest cost**, higher latency for users elsewhere |

- Price class 200 adds South Africa, Kenya, the Middle East, Japan, Singapore, South Korea, Taiwan, Hong Kong, the Philippines, India, Indonesia, Thailand, Malaysia, Vietnam, Nigeria, Egypt, and Turkiye. **South America and Australia/NZ** are only in **All**.
- Users outside the chosen regions are still served, just from a **farther edge location** (higher latency).

### 2. Multiple Origins and Origin Groups

| | **Multiple origins** | **Origin group** |
|---|---|---|
| **Purpose** | **Route by content type or path** | **High availability and failover** |
| **How** | **Cache behaviors** with path patterns (`/api/*` to an ALB, everything else to S3) | A **primary** and a **secondary** origin, used by a cache behavior |
| **Details** | See **CloudFront - Cache Behaviors** | See below |

**Origin failover:**

```
Viewer --> CloudFront --> primary origin A
                              | error status, connection failure, or timeout
                              v
                           secondary origin B --> response (hopefully 200)
```

| Aspect | Detail |
|---|---|
| **Group** | **One primary and one secondary** origin, and a cache behavior points at the group |
| **Failover triggers** | A **status code you choose** from **400, 403, 404, 416, 429, 500, 502, 503, 504**, a **connection failure**, or a **timeout** |
| **Methods** | Only **`GET`, `HEAD`, `OPTIONS`** requests fail over (**not** `POST`, `PUT`, and so on) |
| **Routing** | Every new request goes to the **primary first**, even after an earlier failover |
| **Speed** | By default CloudFront retries the primary for up to **30 s** (3 attempts of 10 s). Lower the **connection timeout** (1-10 s) and **attempts** (1-3) to fail over faster. |
| **Works with** | **Any origin type**: EC2, ALB, S3, and so on |

### 3. Region-Level Disaster Recovery with S3

```
CloudFront --> origin group
                 primary:   S3 bucket A (region 1)  --replication-->  S3 bucket B (region 2) :secondary
                 region 1 outage / error on A --> CloudFront retries the request on B
```

- Put **two S3 buckets in different regions** in an origin group and set up **S3 replication** from the primary to the secondary, so the secondary holds the **same data**.
- If region 1 fails (or returns an error), CloudFront retries on bucket B.
- Result: **regional disaster recovery** for CloudFront plus S3.

### 4. Field-Level Encryption

Adds protection for **sensitive fields** on top of **HTTPS** (encryption in flight).

```
User --HTTPS POST (card number field)--> Edge location: encrypts that field with the PUBLIC key
   --> CloudFront --> ALB --> web server (HTTPS throughout; the field is still encrypted)
                                 web server uses the PRIVATE key to decrypt the field
```

| Aspect | Detail |
|---|---|
| **Type** | **Asymmetric** (public key) encryption. The public key given to CloudFront **can't decrypt**. |
| **What is encrypted** | Up to **10 specific fields** of a **`POST`** request (for example a credit card number), not the whole body |
| **Where** | At the **edge**, close to the user. The field **stays encrypted** across CloudFront, the ALB, and the origin servers. |
| **Who decrypts** | Only the app holding the **private key** (your **custom application logic** at the origin, using the **AWS Encryption SDK**) |
| **Setup** | RSA **2048-bit** key pair, upload the **public key**, create a **field-level encryption profile** (which fields) and a **configuration**, then attach it to a **cache behavior** |
| **Requirements** | Viewer protocol **HTTPS** (redirect or HTTPS only), **all HTTP methods** allowed, origin protocol **match viewer or HTTPS only**, and the origin must support **chunked encoding** |

- Intermediate components (CloudFront, the ALB) **never see the plaintext** field.

### 5. Exam-Style Recall

| If the question says... | Think... |
|---|---|
| "Reduce CloudFront cost by serving from fewer edge locations" | **Price class** (100 or 200) |
| "Cheapest price class" | **Price Class 100** (US, Canada, Europe, Israel) |
| "Best performance, all edge locations" | **Price Class All** |
| "Does the edge location region affect data transfer cost?" | **Yes**. The US and Europe are cheapest, and cost falls as volume rises. |
| "Route different paths to different origins" | **Multiple origins** with **cache behaviors** |
| "High availability, failover if the origin fails" | **Origin group** (primary and secondary) |
| "Which requests fail over in an origin group?" | `GET`, `HEAD`, `OPTIONS` |
| "Region-level disaster recovery for CloudFront with S3" | **Origin group** of **two S3 buckets in different regions** with **replication** |
| "Protect a credit card field so only the backend can read it" | **Field-level encryption** |
| "Field-level encryption uses..." | **Asymmetric** encryption: public key at the edge, private key at the origin |
| "Maximum fields encrypted per request" | **10** |
| "Encryption in flight between client and origin" | **HTTPS** (field-level encryption adds to it) |

---

## CloudFront - Real Time Logs

### TL;DR

- **Real-time logs** send the requests CloudFront receives to a **Kinesis Data Stream**, **within seconds**, to **monitor, analyze, and act on** content delivery performance.
- **Kinesis Data Streams is the only destination.** Process the records with a **Lambda function** or another consumer, or add **Amazon Data Firehose** (the lecture says Kinesis Data Firehose) for **near real-time batching** into **S3, Redshift, or OpenSearch**.
- You choose the **sampling rate** (1-100% of requests), the **fields**, and the **cache behaviors (path patterns)** to log.
- For **historical analysis, audits, and cheap long-term retention**, use **standard (access) logs** instead.

### 1. How It Works

```
Viewers --> CloudFront (real-time log configuration attached to cache behaviors)
                |  sampled requests, selected fields, within seconds
                v
         Kinesis Data Stream --+--> Lambda (or your own consumer): real-time processing
                               +--> Amazon Data Firehose --> S3 / Redshift / OpenSearch / third party
                                    (batches, near real time)
```

| Setting | Detail |
|---|---|
| **Sampling rate** | A whole number from **1 to 100** (% of requests). Use a **lower rate for high-traffic** endpoints to **cut cost**. |
| **Fields** | The log fields you want (timestamp, status code, edge location, time-to-first-byte, country, cache result type, and so on) |
| **Cache behaviors** | Attach the configuration to **specific behaviors**, for example only `/images/*`, to see just those requests |
| **Endpoint** | The **Kinesis data stream** (give its ARN). Size its **shards** for your request rate (a record is about 500 bytes to 1 KB). |
| **IAM role** | Lets **CloudFront write to your data stream**. The console can **create the service role** for you. |
| **Cost** | CloudFront charges for real-time logs **plus** the Kinesis Data Streams charges |

- Delivery is **best effort**: use the logs to understand request patterns, **not** as a full accounting of every request.
- If Kinesis **throttles** the writes (too few shards), **add shards**.

### 2. Real-Time vs Standard Logs

| | **Real-time logs** | **Standard (access) logs** |
|---|---|---|
| **Delivery** | **Within seconds** | Delayed (not real time) |
| **Destination** | **Kinesis Data Streams** only (then Lambda or Firehose) | S3, CloudWatch Logs, or Firehose |
| **Control** | **Sampling rate**, fields, cache behaviors | Per distribution |
| **Use for** | **Live monitoring**, alerts, dashboards | **Historical analysis**, audits and compliance, long-term retention |
| **Cost** | CloudFront real-time charge **plus** Kinesis | **Cost-effective** for long-term retention (you pay for the destination) |

### 3. Exam-Style Recall

| If the question says... | Think... |
|---|---|
| "Get CloudFront request logs in real time" | **CloudFront real-time logs** to **Kinesis Data Streams** |
| "Where can real-time logs be delivered?" | **Kinesis Data Streams** only |
| "Process real-time logs in near real time and store in S3 or OpenSearch" | Kinesis Data Stream, then **Firehose**, then S3 or OpenSearch |
| "Process each real-time log record as it arrives" | Kinesis Data Stream with a **Lambda** consumer |
| "Only log a percentage of requests" | **Sampling rate** |
| "Log only requests for a certain path" | Attach the configuration to that **cache behavior** |
| "Long-term, cost-effective access logs for audit" | **Standard logs** to S3 |
