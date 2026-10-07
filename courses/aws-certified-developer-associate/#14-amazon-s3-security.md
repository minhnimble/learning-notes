# Amazon S3 Security

---

## S3 Encryption

### TL;DR

- **Server-side encryption (SSE)**: S3 encrypts the object after it arrives, and decrypts it when you read it. Four flavors:
  - **SSE-S3**: S3-managed keys. **On by default.**
  - **SSE-KMS**: keys in **AWS KMS**, with **CloudTrail audit** and your own control.
  - **DSSE-KMS**: **dual-layer** server-side encryption with KMS.
  - **SSE-C**: **customer-provided keys**. **HTTPS is required.**
- **Client-side encryption**: the **client encrypts before upload** and decrypts after download. The client manages the keys and the whole cycle.
- **Encryption in transit**: S3 has an **HTTP** endpoint (not encrypted) and an **HTTPS** endpoint (TLS). Use HTTPS. You can force it with a **bucket policy** on `aws:SecureTransport`.
- **Exam traps:**
  - **SSE-KMS** API calls (`GenerateDataKey`, `Decrypt`) count toward **KMS request quotas** and can **throttle** high-throughput buckets.
  - **SSE-C** needs **HTTPS**.
  - Reading an **SSE-KMS** object needs permission on **both the object and the KMS key**.

### 1. The Methods at a Glance

| Method | Who owns the key | Where encryption happens | Header or mechanism |
|---|---|---|---|
| **SSE-S3** | **AWS (S3)**. You never see it. | Server side | `x-amz-server-side-encryption: AES256` |
| **SSE-KMS** | **KMS key** (AWS managed or customer managed) | Server side | `x-amz-server-side-encryption: aws:kms` |
| **DSSE-KMS** | KMS keys | Server side, **two layers** | `x-amz-server-side-encryption: aws:kms:dsse` |
| **SSE-C** | **You**, outside AWS | Server side | `x-amz-server-side-encryption-customer-*` headers |
| **Client-side** | **You**, outside AWS | **On the client**, before upload | Your code or an encryption library |

- The lecturer says you must know **which is which** for the exam.
- All server-side options encrypt **data at rest**. Combine them with **HTTPS** for data in transit.
- All server-side methods give encryption **at rest**. Client-side encrypts **before** S3 receives anything.

### 2. SSE-S3 (S3-Managed Keys)

| Property | Detail |
|---|---|
| **Key** | **Handled, managed, and owned by AWS.** You never have access to it. |
| **Algorithm** | **AES-256** |
| **Where** | **Server side** |
| **Header to request it** | **`x-amz-server-side-encryption: AES256`** |
| **Default** | **Enabled by default** for **new buckets and new objects** |
| **Extra cost** | None |

**How it works:**

```
You --upload (with the header)--> [S3] --pairs the object with an S3-owned key--> encrypts --> stored encrypted
```

- You don't have to do anything. Every new object is encrypted unless you choose another method.
- **Limitation:** no key control and no key-usage audit trail. You can't restrict who may use the key.
- The default encryption applies to **all new objects**. It doesn't re-encrypt old ones. Old unencrypted objects can be re-encrypted with a **copy** (or **S3 Batch Operations**).

### 3. SSE-KMS (KMS-Managed Keys)

#### 3.1 What it is

- You manage the keys in **AWS KMS** instead of using the key owned by S3.
- **Advantages:**
  - **User control** over the key: create it yourself, set its **key policy**, **rotate** it, **disable** it.
  - **Audit** all key usage in **CloudTrail**. Every time the key is used, it is logged.
- **Header:** `x-amz-server-side-encryption: aws:kms`
- Optionally pass `x-amz-server-side-encryption-aws-kms-key-id` to choose the key. If omitted, S3 uses the **AWS managed key `aws/s3`**.

```
You --upload (header names the KMS key)--> [S3] <--gets a data key from-- [KMS]
                                             |
                                    encrypts the object --> stored encrypted
```

#### 3.2 Reading the object needs two permissions

- To **read** an SSE-KMS object you need access to:
  1. **The S3 object** (`s3:GetObject`), **and**
  2. **The KMS key** (`kms:Decrypt`) that encrypted it.
- The lecturer: "this is another level of security".
- Common mistake: a user has S3 access but gets **AccessDenied** because the **KMS key policy** doesn't allow them.
- **Cross-account:** use a **customer managed key** and allow the other account in the **key policy**. The AWS managed key `aws/s3` **can't be shared**.
- **Cost:** the AWS managed key `aws/s3` has **no monthly key fee**. A **customer managed key** costs about **$1 per month per key**, plus KMS request charges.

#### 3.3 The KMS limitation (exam-relevant)

| Point | Detail |
|---|---|
| **Upload** | S3 calls KMS **`GenerateDataKey`** |
| **Download** | S3 calls KMS **`Decrypt`** |
| **Counted toward** | **KMS API request quotas** (per second) |
| **Quota (per the lecture)** | Between **5,000 and 30,000 requests per second**, depending on the region |
| **AWS docs (extra)** | **5,500, 10,000, or 30,000 per second**, depending on the region |
| **Increase** | Via the **Service Quotas** console |

- Result: a **very high-throughput bucket** encrypted with SSE-KMS can get **throttled** by KMS. (The lecture says "threat link", meaning **throttling**.)
- **Mitigations (extras):**
  - Turn on **S3 Bucket Keys** to cut KMS calls (AWS says by up to about **99%**) and cost.
  - **Request a quota increase.**
  - Use **exponential backoff** (the SDK does it automatically).
  - Use **SSE-S3** if you don't need KMS control.
- This ties back to the **S3 Performance** lecture, where the lecturer mentions "the KMS limits".

### 4. DSSE-KMS (Dual-Layer Server-Side Encryption)

| Property | Detail |
|---|---|
| **What it is** | **Two layers of server-side encryption** applied to the same object |
| **Keys** | **KMS** keys |
| **Header** | **`x-amz-server-side-encryption: aws:kms:dsse`** (the lecture says "AWS KMS-DSSE") |
| **Why use it** | Compliance rules that **require multilayer encryption** |

```
object --> layer 1 encryption --> layer 2 encryption --> stored in S3
```

- **Exam rule:** if a question says "**multilayer** or **dual-layer** encryption is required", the answer is **DSSE-KMS**.
- The lecture says the layers use **KMS first, then S3-managed keys**. In AWS documentation, **both layers use data keys generated through KMS**. Either way, the exam answer is **DSSE-KMS**.
- Costs more than SSE-KMS, and has the same **KMS quota** considerations (extra).

### 5. SSE-C (Customer-Provided Keys)

| Property | Detail |
|---|---|
| **Key** | **Managed by you, outside AWS** |
| **Encryption** | Still **server side**, because you **send the key to S3** with each request |
| **Does S3 store the key?** | **Never.** The key is **used, then discarded.** |
| **Transport** | **HTTPS is mandatory** (the key travels in HTTP headers) |
| **Every request** | You must send the key in the **headers** on **every PUT and every GET** |

```
You --upload + your key (HTTPS headers)--> [S3] encrypts with your key --> stored encrypted
                                                 (key discarded)
You --download + the same key (HTTPS)------> [S3] decrypts --> returns the object
```

**Headers used (extras):**
- `x-amz-server-side-encryption-customer-algorithm: AES256`
- `x-amz-server-side-encryption-customer-key: <base64 key>`
- `x-amz-server-side-encryption-customer-key-MD5: <base64 MD5>`

- **Lose the key and the data is unrecoverable.** AWS can't help.
- **Limitations (extras):**
  - It is **not available in the console**. Use the **CLI, SDKs, or the API**. From the CLI, pass `--sse-c AES256 --sse-c-key <key>` (for example on `aws s3 cp`).
  - AWS has been **restricting SSE-C by default on new buckets**, so check the current S3 docs if you rely on it.
  - Features such as **replication and some analytics** have restrictions with SSE-C objects.

### 6. Client-Side Encryption

| Property | Detail |
|---|---|
| **Who encrypts** | **The client**, **before** sending data to S3 |
| **Who decrypts** | **The client**, after downloading |
| **What S3 sees** | Only **ciphertext** (it doesn't know it is encrypted) |
| **Keys** | **Fully managed by the client**, along with the **whole encryption lifecycle** |
| **Tooling** | Easier with a **client library**, for example the **Amazon S3 Encryption Client** or the **AWS Encryption SDK** |

```
file + client key (outside AWS) --> client encrypts --> encrypted file --upload--> [S3]
```

- AWS **never sees the plaintext or the key.**
- **Use when:** policy says data must be encrypted **before it leaves** your environment, or when you don't trust any server-side handling.
- **Trade-offs (extras):** more work, no S3 server-side features that need to read the content, and you must **protect the keys** (for example with KMS).

### 7. Encryption in Transit (SSL/TLS)

- **Encryption in transit** (also **in flight**) is **SSL/TLS**.
- An S3 bucket has **two endpoints**:

| Endpoint | Encrypted? |
|---|---|
| **HTTP** | **No** |
| **HTTPS** | **Yes** (TLS) |

- The browser lock icon shows an encrypted connection. The same idea applies to S3.
- **Always use HTTPS**. It is **mandatory for SSE-C**.
- In real life you rarely have to think about it, because **most clients (CLI, SDKs, browsers) use HTTPS by default**.

#### 7.1 Forcing HTTPS with a bucket policy

Attach a bucket policy that **denies** requests made without TLS:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "DenyInsecureTransport",
      "Effect": "Deny",
      "Principal": "*",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::my-bucket/*",
      "Condition": {
        "Bool": { "aws:SecureTransport": "false" }
      }
    }
  ]
}
```

- **`aws:SecureTransport`** is **true** for HTTPS and **false** for plain HTTP.
- Result: anyone using **HTTP** is **blocked**, while **HTTPS** requests are allowed (if other policies allow them).
- The lecture's example is `GetObject`. To cover everything, use `"Action": "s3:*"` and both the bucket and `/*` resources (extra).

### 8. Comparison

| | **SSE-S3** | **SSE-KMS** | **DSSE-KMS** | **SSE-C** | **Client-side** |
|---|---|---|---|---|---|
| **Key managed by** | AWS (S3) | You, in **KMS** | You, in **KMS** | **You**, outside AWS | **You**, outside AWS |
| **Key control and rotation** | No | **Yes** | **Yes** | You | You |
| **Audit key usage (CloudTrail)** | No | **Yes** | **Yes** | No | No |
| **Layers** | 1 | 1 | **2** | 1 | 1 |
| **Encryption happens** | S3 | S3 | S3 | S3 | **Client** |
| **Key sent to AWS?** | No | No (S3 asks KMS) | No | **Yes** (every request, then discarded) | **No** |
| **HTTPS required?** | Recommended | Recommended | Recommended | **Mandatory** | Recommended |
| **KMS quota impact** | None | **Yes** | **Yes** | None | None |
| **Default for new objects** | **Yes** | No | No | No | No |
| **Console support** | Yes | Yes | Yes | **No** | N/A |

### 9. Exam-Style Recall

| If the question says... | Think... |
|---|---|
| "Default encryption for new S3 objects" | **SSE-S3** |
| "S3 manages the keys, no extra configuration" | **SSE-S3** |
| "Need to control the keys and audit their usage" | **SSE-KMS** (audit in **CloudTrail**) |
| "User can read the bucket but not decrypt the object" | Missing **KMS key permission** (`kms:Decrypt`) |
| "S3 requests throttled with SSE-KMS at very high throughput" | **KMS request quota**. Increase it, or use **Bucket Keys**. |
| "KMS API calls used by S3 for upload and download" | **`GenerateDataKey`** and **`Decrypt`** |
| "Reduce KMS cost and calls for S3" | **S3 Bucket Keys** |
| "Dual-layer or multilayer encryption required" | **DSSE-KMS** |
| "Provide our own encryption keys with each request, S3 doesn't store them" | **SSE-C** |
| "Which encryption method requires HTTPS?" | **SSE-C** |
| "Client encrypts data before uploading to S3" | **Client-side encryption** |
| "AWS must never see the plaintext or the key" | **Client-side encryption** |
| "Header for SSE-S3" | **`x-amz-server-side-encryption: AES256`** |
| "Header for SSE-KMS" | **`x-amz-server-side-encryption: aws:kms`** |
| "Encryption in transit for S3" | **HTTPS (SSL/TLS)** |
| "Force all connections to S3 to use HTTPS" | **Bucket policy** denying when **`aws:SecureTransport` is `false`** |
| "Block uploads that aren't encrypted with KMS" | **Bucket policy** denying `PutObject` without the right header |
| "Algorithm used by SSE-S3" | **AES-256** |
| "Change an existing object's encryption in the console" | **Edit server-side encryption**, which **creates a new version** (if versioning is on) |
| "Re-encrypt every existing object in a bucket" | **S3 Batch Operations (copy)**. Changing the default only affects new objects. |
| "Reduce KMS requests from S3" | **Bucket Key** |
| "AWS managed key for S3" | **`aws/s3`** |
| "Console doesn't offer SSE-C" | **SSE-C is CLI/SDK/API only** |
| "Where do I tell S3 that the data is client-side encrypted?" | **Nowhere.** S3 sees ciphertext only. |
| "Override encryption for one object" | Set it at **upload** or **edit** the object's encryption |
| "Customer managed KMS key cost" | **Monthly key fee** plus request charges |
| "Share an SSE-KMS object with another account" | **Customer managed key** (the `aws/s3` key can't be shared) |

---

## S3 Encryption - Hands On

### 1. Create the Bucket

| Setting | Demo value | Notes |
|---|---|---|
| **Name** | `demo-encryption-<name>` | The lecturer used `demo-encryption-stephane-v2`. Use your own unique name. |
| **Block Public Access** | Left **on** | Defaults |
| **Object Ownership** | Left at default | ACLs disabled |
| **Bucket versioning** | **Enable** | So a re-encryption creates a visible new version |
| **Default encryption** | **SSE-S3** | Required choice on the create page |

- Click **Create bucket**. The lecturer says it now has **default encryption turned on**.

### 2. Upload and Verify

1. Open the bucket, **Upload**, **Add files**, choose `coffee.jpg`, **Upload**.
2. Click the object and scroll to **Server-side encryption settings**.
3. It shows **Server-side encryption with Amazon S3 managed keys (SSE-S3)**.

- The object was encrypted **without any header or setting from you**. This is the **bucket default** at work.
- The encryption type is also visible in the object's **properties** and via the CLI (`aws s3api head-object` shows `ServerSideEncryption: AES256`).

### 3. Change an Object's Encryption (New Version)

#### 3.1 Steps

1. Open the object, scroll to **Server-side encryption settings**, click **Edit**.
2. Choose **Override default encryption bucket settings**.
3. Select **SSE-KMS** (the lecturer skips DSSE-KMS: "just two levels of KMS encryption, a stronger KMS").
4. **Encryption key:** either **enter a KMS key ARN** or **choose from your KMS keys**.
5. Pick the **AWS managed key `aws/s3`**. This is the **default KMS key for S3**.
6. **Save changes**.

- The lecturer chose `aws/s3` to avoid cost, since "creating your own KMS key will cost you some money every month".

#### 3.2 What happens: a new version

- Changing the encryption of an existing object **rewrites it**: S3 **copies the object onto itself** with the new setting.
- Because **versioning is on**, this creates a **new version**.
- **Versions tab:** two versions of `coffee.jpg`.
  - The **older version** is still **SSE-S3**.
  - The **current version** is **SSE-KMS** with the `aws/s3` key.

### 4. Override Encryption at Upload

1. **Upload**, **Add files**, choose `beach.jpg`.
2. Expand **Properties**, then **Server-side encryption**.
3. Options:

4. **Upload**.

### 5. The Bucket's Default Encryption

1. Bucket, **Properties**, scroll to **Default encryption**, click **Edit**.
2. Choose the **encryption type**: **SSE-S3, SSE-KMS, or DSSE-KMS**.
3. For **SSE-KMS** (and DSSE-KMS), pick the key and see **Bucket Key**.

#### 5.1 Bucket Key

| Property | Detail |
|---|---|
| **What it does** | S3 uses a **bucket-level key** from KMS to create data keys, so it makes **far fewer KMS API calls** |
| **Benefit** | Lower **KMS cost and request volume** (AWS says up to about **99%** fewer requests) |
| **Default** | **Enabled** in the console when you choose SSE-KMS |
| **With SSE-S3** | **Doesn't apply** (the lecturer: "this setting doesn't count") |

- It ties directly to the **KMS quota** warning in the previous lecture (high-throughput buckets can hit KMS limits).

### 6. Not Available in the Console

- **SSE-C** (keys sent in headers on every request, so CLI/SDK/API only) and **client-side encryption** (done before upload, S3 isn't told) have no console setting. The console covers **SSE-S3, SSE-KMS, and DSSE-KMS**.

### 7. Troubleshooting

| Symptom | Likely cause |
|---|---|
| **AccessDenied** reading an SSE-KMS object | You lack **`kms:Decrypt`** on the key (or the key policy doesn't allow you) |
| **Edit encryption** option greyed out | Missing `s3:PutObject` or related permissions, or the object is in an archive class |
| Don't see two versions | **Show versions** is off, or versioning wasn't enabled before the change |
| SSE-KMS shows `aws/s3` but you wanted your own key | Choose the **customer managed key** (or enter its **ARN**) |

---

## S3 Default Encryption

### TL;DR

- **Every bucket now has default encryption: SSE-S3.** It is applied automatically to **new objects** that are uploaded without an encryption setting.
- You can **change the default** to another type, for example **SSE-KMS** (or DSSE-KMS).
- To **force** a specific encryption method, use a **bucket policy** that **denies `PutObject`** when the right encryption header is missing.
- **Bucket policies are evaluated before default encryption.** A request that doesn't carry the required header is **denied**, even though default encryption would have encrypted it.
- Remember: **default encryption = a fallback**. **Bucket policy = an enforcement rule.**

### 1. Default Encryption

| Property | Detail |
|---|---|
| **Default type** | **SSE-S3** (AES-256, S3-managed keys) |
| **Applies to** | **New objects** stored in the bucket |
| **When it applies** | When the upload request **doesn't specify** an encryption method |
| **Can you change it?** | **Yes**: SSE-S3, **SSE-KMS**, or **DSSE-KMS** |
| **Existing objects** | **Not re-encrypted** when you change the default (extra) |
| **Per-object override** | Still possible at upload by sending encryption headers |

- The lecture says "all buckets are now having a default encryption of SSE-S3".
- Changing the default to **SSE-KMS** also lets you choose the **KMS key** and the **Bucket Key** option (see the encryption lectures).
- Console path: bucket, **Properties**, **Default encryption**, **Edit**.

### 2. Forcing Encryption with a Bucket Policy

Default encryption **fills in** a missing setting. A **bucket policy** can **refuse** requests that don't meet your rule.

- Use a **Deny** statement on `s3:PutObject` with a **condition on the encryption headers**.
- Anyone trying to upload without the right header is **blocked**.

#### 2.1 Example 1: require SSE-KMS

"If you do a PutObject but you don't have the encryption header that says AWS KMS, then deny this request."

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "DenyUploadsWithoutKMS",
      "Effect": "Deny",
      "Principal": "*",
      "Action": "s3:PutObject",
      "Resource": "arn:aws:s3:::my-bucket/*",
      "Condition": {
        "StringNotEquals": {
          "s3:x-amz-server-side-encryption": "aws:kms"
        }
      }
    }
  ]
}
```

- **`StringNotEquals`** also matches when the header is **absent**, so uploads with no header are denied too.
- Key point: `x-amz-server-side-encryption: aws:kms` is the **SSE-KMS** header.

#### 2.2 Example 2: require SSE-C

"If you are uploading but there is no customer-side algorithm, so no SSE-C, then deny this object."

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "DenyUploadsWithoutSSEC",
      "Effect": "Deny",
      "Principal": "*",
      "Action": "s3:PutObject",
      "Resource": "arn:aws:s3:::my-bucket/*",
      "Condition": {
        "Null": {
          "s3:x-amz-server-side-encryption-customer-algorithm": "true"
        }
      }
    }
  ]
}
```

- **`Null: "true"`** means "the header is **not present**". The statement denies uploads that lack the **SSE-C algorithm header**.
- The two examples are **alternatives**, not a pair. Applying both together would deny almost every upload, since no request can satisfy both.
- The lecture's point: these are just examples, but they show the bucket policy can **force** the encryption you want.

#### 2.3 Related conditions (extras)

| Goal | Condition key |
|---|---|
| Require a specific encryption type | `s3:x-amz-server-side-encryption` (`AES256`, `aws:kms`, `aws:kms:dsse`) |
| Require a specific KMS key | `s3:x-amz-server-side-encryption-aws-kms-key-id` |
| Require HTTPS | `aws:SecureTransport` (see the encryption lecture) |

- `s3:x-amz-server-side-encryption` carries the **SSE type** (`AES256`, `aws:kms`, `aws:kms:dsse`). `...customer-algorithm` marks **SSE-C**.

### 3. Evaluation Order: Policy First

- **Bucket policies are always evaluated before default encryption settings.**
- Why it matters: the policy looks at the **request as sent** (its headers). Default encryption is only applied **afterwards**, by S3, when no method was given.

```
Upload request --> [Bucket policy check] --denied--> request rejected
                         |
                      allowed
                         v
                  [Default encryption applied if no method was specified] --> object stored
```

**Worked example:**

| Scenario | Result |
|---|---|
| Bucket default = **SSE-KMS**, **no** policy, upload with **no header** | Allowed. S3 applies **SSE-KMS** by default. |
| Bucket default = **SSE-KMS**, policy **denies** uploads without the KMS header, upload with **no header** | **Denied.** The policy sees no header, so default encryption never gets a chance. |
| Same policy, upload **with** `aws:kms` header | Allowed. Encrypted with SSE-KMS. |

- So changing the default alone is **not enforcement**: a client can still **override it per object** (for example with SSE-S3).
- A policy makes the rule **mandatory**. Be aware that it can **break clients** that don't send the header.

### 4. Exam-Style Recall

| If the question says... | Think... |
|---|---|
| "Make sure all uploads use SSE-KMS" | **Bucket policy** denying `PutObject` without `aws:kms` |
| "Block uploads that don't use SSE-C" | **Bucket policy** with a `Null` condition on the customer algorithm header |
| "Change the default encryption type of a bucket" | Bucket **Properties, Default encryption** |
| "Which is evaluated first: bucket policy or default encryption?" | **Bucket policy** |
| "Upload without an encryption header to a bucket with a deny-unless-KMS policy" | **Denied**, even if default encryption is on |
| "Enforce HTTPS as well as encryption at rest" | Add a deny on **`aws:SecureTransport` = false** |

---

## S3 CORS

### TL;DR

- **CORS = Cross-Origin Resource Sharing.** It is a **web browser security mechanism** that allows or denies requests to **other origins** while you are visiting a main origin.
- An **origin** = **scheme (protocol) + host (domain) + port**. Example: `https://www.example.com` has scheme **HTTPS**, host **www.example.com**, and implied port **443**.
- **Same origin** = same scheme, same host, same port. **Different origin** example: `www.example.com` vs `other.example.com`.
- A cross-origin request is **refused by the browser** unless the other origin allows it with **CORS headers**, mainly **`Access-Control-Allow-Origin`**.
- The browser first sends a **preflight request** (`OPTIONS`). The server replies with the origins and methods it allows.
- **On S3:** if a client makes a **cross-origin request to your bucket**, **enable CORS on that bucket**. You can allow **one specific origin** or **`*`** (all origins).
- This is "a very popular exam question". The lecturer says it is worth about **one question**.

### 1. What Is an Origin?

| Part | Example (`https://www.example.com`) |
|---|---|
| **Scheme / protocol** | `https` |
| **Host / domain** | `www.example.com` |
| **Port** | `443` (implied for HTTPS. HTTP implies `80`) |

**Same origin vs different origin:**

| URL A | URL B | Same origin? | Why |
|---|---|---|---|
| `https://www.example.com/app1` | `https://www.example.com/app2` | **Yes** | Same scheme, host, and port. Only the path differs. |
| `https://www.example.com` | `https://other.example.com` | **No** | Different **host** |
| `https://www.example.com` | `http://www.example.com` | **No** | Different **scheme** (and port) |
| `https://www.example.com` | `https://www.example.com:8443` | **No** | Different **port** |

- The **path doesn't matter**.
- Two subdomains of the same parent domain are still **different origins**.

### 2. What CORS Is (and Isn't)

- A **browser-based** security mechanism.
- The scenario: you visit **origin A** (the main site), and its page tries to load something from **origin B** (images, fonts, API calls, JavaScript fetches).
- **The browser blocks the request unless origin B explicitly allows origin A**, using **CORS headers**.

| Point | Detail |
|---|---|
| **Enforced by** | **The web browser**, not the server |
| **Protects** | The **user** (stops a malicious page from reading your data from another site using your logged-in session) |
| **Not a server-side access control** | `curl`, scripts, and other non-browser clients **ignore CORS**. Use IAM, bucket policies, or pre-signed URLs for real access control. |
| **Applies to** | Browser `fetch`, `XMLHttpRequest`, fonts, and some canvas and media uses |
| **Doesn't apply to** | Plain `<img src>` displays on a page (loading and showing is allowed). It matters when **JavaScript reads the response**, or for fonts and cross-origin requests with custom headers. |

### 3. How CORS Works (Lecture Diagram)

**Setup:**
- **Origin web server:** `https://www.example.com` (serves the main page).
- **Cross-origin web server:** `https://www.other.com` (hosts other content, for example images).

```
Browser                       www.example.com (origin)         www.other.com (cross-origin)
   |---- GET /index.html ------------>|                                |
   |<--- index.html (needs images from other.com) ---|                |
   |                                                                    |
   |---- PREFLIGHT: OPTIONS /image  (Origin: https://www.example.com) ->|
   |<--- Access-Control-Allow-Origin: https://www.example.com           |
   |     Access-Control-Allow-Methods: GET, PUT, DELETE ----------------|
   |                                                                    |
   |---- GET /image (Origin: https://www.example.com) ----------------->|
   |<--- image + Access-Control-Allow-Origin header --------------------|
```

**Steps:**
1. The browser requests `index.html` from **`www.example.com`**.
2. The page says: "also get images from **`www.other.com`**".
3. Built-in browser security: the browser sends a **preflight request** to the cross-origin server, using the **`OPTIONS`** method. It says "this request comes from origin `https://www.example.com`".
4. If `www.other.com` is **configured for CORS**, it answers: "**Yes, I allow `https://www.example.com`** for the **GET, PUT, DELETE** methods". These are the **CORS headers**.
5. If the browser is **happy with the headers**, it makes the **real request** and gets the files.
6. If the server isn't configured (or doesn't list that origin), the browser **blocks** the request.

**Key headers:**

| Header | Direction | Meaning |
|---|---|---|
| **`Origin`** | Browser to server | The **origin the request comes from** |
| **`Access-Control-Allow-Origin`** | Server to browser | Which **origin(s)** may access the resource (a specific origin or `*`) |
| **`Access-Control-Allow-Methods`** | Server to browser (preflight) | Allowed **HTTP methods** |
| **`Access-Control-Allow-Headers`** | Server to browser (preflight) | Allowed **request headers** |
| **`Access-Control-Max-Age`** | Server to browser | How long the browser may **cache the preflight** |
| **`Access-Control-Expose-Headers`** | Server to browser | Response headers JavaScript may read |

- **Simple requests** (for example a basic `GET`) may skip the preflight, but still need `Access-Control-Allow-Origin` in the response.

### 4. CORS and Amazon S3

- **Rule:** if a client makes a **cross-origin request to your S3 bucket**, you must **enable the correct CORS headers** on that bucket.
- **Which bucket?** The one **being requested** (the cross-origin target), not the one serving the web page.
- Two ways to set the allowed origin:

| Option | Meaning |
|---|---|
| **A specific origin** | For example `https://www.example.com`. Safest. |
| **`*`** | **All origins**. Quick, but any website can read the data from the browser. |

#### 4.1 Lecture scenario: two S3 static websites

| Bucket | Role |
|---|---|
| **Bucket 1** (for example `my-bucket-html`) | Static website with `index.html`. This is the **origin**. |
| **Bucket 2** (`my-bucket-assets`) | Static website holding **images** such as `coffee.jpg`. This is the **cross-origin** bucket. |

```
Browser --GET index.html--> [Bucket 1 website]
Browser <-- index.html (contains <img src="http://bucket2-website/images/coffee.jpg">) --
Browser --GET coffee.jpg, Origin: http://bucket1-website--> [Bucket 2 website]
```

1. The browser asks bucket 1's **static website URL** for `index.html`.
2. The page includes an image that lives on **bucket 2**.
3. The browser requests that image. The **target host is bucket 2**, but the **request origin is bucket 1**.
4. If bucket 2 has **no CORS configuration**, the **browser refuses** the cross-origin request.
5. If bucket 2 **allows bucket 1's origin**, S3 returns the **CORS headers** and the browser **allows** the request, so the image loads.

**Remember (lecturer):** CORS is **browser security** that allows images, assets, or files to be retrieved from **one S3 bucket when the request originates from another origin**.

#### 4.2 Configuring CORS on a bucket (extras)

- Console: bucket, **Permissions** tab, scroll to **Cross-origin resource sharing (CORS)**, **Edit**, paste a **JSON** configuration.
- Example allowing one origin to read assets:

```json
[
  {
    "AllowedOrigins": ["https://www.example.com"],
    "AllowedMethods": ["GET"],
    "AllowedHeaders": ["*"],
    "ExposeHeaders": [],
    "MaxAgeSeconds": 3000
  }
]
```

- Example allowing every origin (quick but permissive):

```json
[
  {
    "AllowedOrigins": ["*"],
    "AllowedMethods": ["GET", "HEAD"],
    "AllowedHeaders": ["*"],
    "MaxAgeSeconds": 3000
  }
]
```

| Field | Meaning |
|---|---|
| **AllowedOrigins** | Origins allowed (`*` for all) |
| **AllowedMethods** | `GET`, `PUT`, `POST`, `DELETE`, `HEAD` |
| **AllowedHeaders** | Request headers the browser may send |
| **ExposeHeaders** | Response headers JavaScript can read |
| **MaxAgeSeconds** | How long to cache the preflight |

- The CORS configuration is limited to **64 KB**.
- CORS settings cover **who the browser may share with**. They don't grant permission. The bucket still needs **public read access or valid credentials** (bucket policy, pre-signed URL, CloudFront).
- CORS **doesn't replace permissions**. The data still has to be accessible.

### 5. Common S3 CORS Use Cases (Extras)

| Use case | CORS needed on |
|---|---|
| A **static website** (bucket A) loads assets from **bucket B** | **Bucket B** allows bucket A's origin |
| **JavaScript on your site uploads directly to S3** with a **pre-signed URL** (`PUT`) | The **upload bucket** allows your site's origin and the `PUT` method |
| A web app **fetches JSON** or data files from S3 | The data bucket allows the app origin |
| Fonts served from S3 | The font bucket (browsers enforce CORS on fonts) |
| **CloudFront** in front of S3 | Configure CORS on S3 **and** forward the `Origin` header in CloudFront (cache policy), or use a CORS response headers policy |

- The lecturer says CORS is **one exam question** at a high level. Know what it is and where to configure it.

### 6. Troubleshooting

| Symptom (browser console) | Likely cause |
|---|---|
| "**No 'Access-Control-Allow-Origin' header is present**" | The target bucket has **no CORS configuration**, or the **origin doesn't match** |
| Works with `curl` but **fails in the browser** | CORS is enforced by the **browser** only |
| **Preflight fails** | `AllowedMethods` or `AllowedHeaders` is missing what the request uses |
| Origin mismatch | **Scheme, host, or port** differs (`http` vs `https`, trailing port, `www` vs non-`www`). Origins must match **exactly**. |
| CORS set but still **403** | The object isn't **readable** (bucket policy or Block Public Access). CORS doesn't grant access. |
| Config change not visible | **Browser cache** or **CloudFront cache** still holds the old response |

### 7. Exam-Style Recall

| If the question says... | Think... |
|---|---|
| "Browser blocks loading assets from another S3 bucket" | **Enable CORS** on the bucket holding the assets |
| "Web app on one S3 website needs to read images from a second bucket" | **CORS** on the **second** bucket, allowing the first bucket's origin |
| "Allow all origins to access an S3 bucket via CORS" | **`AllowedOrigins: ["*"]`** |
| "What defines an origin?" | **Scheme, host, and port** |
| "Are `www.example.com` and `other.example.com` the same origin?" | **No** |
| "Header that grants cross-origin access" | **`Access-Control-Allow-Origin`** |
| "Browser's pre-check before a cross-origin request" | **Preflight `OPTIONS`** request |
| "Who enforces CORS?" | **The web browser** |
| "CORS error but the request works from `curl`" | CORS is **browser-only** |
| "Where do you set CORS on S3?" | Bucket **Permissions, Cross-origin resource sharing (CORS)** |
| "CORS is configured but the object returns 403" | **Permissions** (bucket policy or Block Public Access), not CORS |
| "Page on one S3 website can't fetch a file from another S3 bucket" | Enable **CORS** on the **bucket holding the file**, allowing the page's origin |
| "Console error: `Access-Control-Allow-Origin` missing" | **CORS isn't configured** on the target, or the origin doesn't match |
| "What value goes in `AllowedOrigins`?" | The **exact origin** of the requesting site (or `*` for all) |
| "Does same-origin traffic need CORS?" | **No** |
| "Fix a CORS error but the object returns 403" | A **permissions** problem, not CORS |
| "Which header proves CORS is working?" | **`Access-Control-Allow-Origin`** in the response |
| "Can `curl` hit the bucket without CORS?" | **Yes.** CORS is **browser-enforced**. |

---

## S3 CORS Hands On

### 1. Starting Point

| Item | Detail |
|---|---|
| **Bucket 1 (origin)** | The static website bucket from the earlier S3 website lectures. It is **public** (Block Public Access off, `GetObject` bucket policy) with **static website hosting** enabled. |
| **Files** | `index.html` and `extra-page.html` (from the course resources), plus `coffee.jpg` |
| **Tools** | A browser with **developer tools** (Chrome DevTools or Firefox Web Developer Tools) |

- If you removed the public policy in a previous lecture, add it again first. Otherwise the website returns **403**.

### 2. Part 1: Same-Origin Fetch (It Works)

#### 2.1 Enable the demo code in `index.html`

- The course `index.html` has the CORS demo section **commented out** (HTML comment markers).
- Edit the file:
  1. Around **line 13**, remove the opening comment marker `<!--` before the `<div>`.
  2. After the `</script>`, remove the closing comment marker `-->`.
- This enables:
  - The page text "I love coffee" and "Hello world!" and the **coffee image**.
  - A **script** that **`fetch`es `extra-page.html`** and displays its content **underneath**.
- `extra-page.html` contains the text "This extra page has been successfully loaded."

#### 2.2 Upload and test

1. Bucket 1, **Upload**, add **`extra-page.html`** and **`index.html`**, then **Upload**.
2. **Properties**, **Static website hosting**, open the **bucket website endpoint** in a new tab.
3. The page shows "I love coffee", "Hello world!", the **coffee image**, and **"This extra page has been successfully loaded"**.

- The `fetch` worked because **`index.html` and `extra-page.html` share the same origin** (same scheme, host, and port).
- **Same-origin requests need no CORS configuration.**

### 3. Part 2: Create a Different Origin

#### 3.1 Create the second bucket

| Setting | Demo value | Notes |
|---|---|---|
| **Name** | `demo-other-origin-<name>` | Unique name (the lecturer used `demo-other-origin-stephane`) |
| **Region** | **Canada** (`ca-central-1`) | A different region, to show it is a **completely different server and endpoint** |
| **Block Public Access** | **Unblock all** | It must be public, like bucket 1 |

#### 3.2 Enable static website hosting

1. Bucket, **Properties**, scroll to **Static website hosting**, **Edit**.
2. **Enable**, **Host a static website**, **Index document** `index.html` (the file doesn't have to exist for this demo).
3. **Save changes**.

#### 3.3 Make it public with a bucket policy

1. **Permissions** tab, **Bucket policy**, **Edit**.
2. Paste the **public read policy from before** and **replace the bucket name in the `Resource` ARN** with this new bucket.

(The public read policy from the S3 bucket policy hands on, `s3:GetObject` for `*` on `<bucket-arn>/*`.)

3. The first save failed with an **"unexpected response"** error. The lecturer had **deleted the first character** while editing the pasted policy. Fix the text and save again.
- Check the policy for **stray or missing characters** and the **`/*`** at the end of the resource.

#### 3.4 Upload the extra page

1. Upload **`extra-page.html`** to the **other-origin bucket**.
2. Open its **Object URL**. The extra page loads, so the file is **public**.

### 4. Point the Main Page at the Other Origin

#### 4.1 Remove the same-origin copy

- In **bucket 1**, **delete `extra-page.html`**. It now lives only in the other bucket.
- Refresh the website. The extra page is missing, and the fetch gets **404 Not Found**. This shows "something to fix".

#### 4.2 Update `index.html`

1. Open the **other-origin bucket's website endpoint** and add `/extra-page.html`, for example:

```
http://demo-other-origin-<name>.s3-website.ca-central-1.amazonaws.com/extra-page.html
```

(Use your bucket's own endpoint. The console shows the exact URL, and the dash-or-dot style depends on the region.)

2. In `index.html`, change the `fetch` call to use this **full URL** instead of the relative `extra-page.html`.
3. **Upload `index.html` to bucket 1** again, replacing the old one.

- The fetch now goes to a **different host**, so it is a **cross-origin request**.

### 5. Part 3: See the CORS Failure

1. Open the **bucket 1 website endpoint** and open the **browser developer tools** (Chrome: **More tools, Developer tools**. Firefox: **Web Developer Tools**).
2. Refresh the page.
3. **No error appears on the page**, but the extra text is **missing**.
4. In the **Console** tab, there is a (small) message such as:

```
Cross-Origin Request Blocked: The Same Origin Policy disallows reading the remote resource ...
(Reason: CORS header 'Access-Control-Allow-Origin' missing)
```

- The request itself reaches S3 (the object is public). **The browser refuses to hand the response to the script.**

### 6. Part 4: Fix It with a CORS Configuration

#### 6.1 The configuration

Paste the lecture's block and set `AllowedOrigins` to bucket 1's **website URL**:

```json
[
  {
    "AllowedHeaders": ["Authorization"],
    "AllowedMethods": ["GET"],
    "AllowedOrigins": ["http://<bucket1-website-endpoint>"],
    "ExposeHeaders": [],
    "MaxAgeSeconds": 3000
  }
]
```

**Getting `AllowedOrigins` right:**
1. Open **bucket 1's website** and **copy the URL** from the address bar.
2. Paste it into `AllowedOrigins`.
3. **Remove the trailing slash** if there is one.
4. Keep the **`http://` scheme** (website endpoints are HTTP only).

- Save the changes.

### 7. Verify

1. **Refresh** the bucket 1 website.
2. The page now shows **"This extra page has been successfully loaded"**.
3. In developer tools, **Network** tab, click the request for **`extra-page.html`**, and open **Response headers**:

| Response header | Value |
|---|---|
| **`Access-Control-Allow-Origin`** | The **first bucket's origin** |
| **`Access-Control-Allow-Methods`** | **`GET`** |

- S3 also adds a **`Vary: Origin`** header (extra), so caches keep per-origin copies.

### 8. Troubleshooting

| Symptom | Likely cause |
|---|---|
| **404** on the extra page | Wrong URL or the file isn't in the **other** bucket |
| **"Unexpected response"** saving the bucket policy | A **typo, missing `/*`, or deleted character** in the JSON |
| Page doesn't change after you re-upload `index.html` | **Browser cache.** Hard refresh. |

---

## S3 MFA Delete

### TL;DR

- **MFA Delete** is an S3 security feature that forces users to supply an **MFA code** before performing certain **destructive operations** on a **versioned bucket**.
- **MFA** (multi-factor authentication) means generating a code on a device, such as a phone with **Google Authenticator** (or similar), or a **hardware MFA device**.
- **MFA is required to:**
  1. **Permanently delete an object version** (delete by version ID).
  2. **Suspend versioning** on the bucket.
- **MFA is not required to:** **enable versioning**, or **list deleted versions**. These aren't dangerous.
- **Prerequisites:** **versioning must be enabled** first, and **only the bucket owner (root account)** can **enable or disable MFA Delete**.
- Purpose: an **extra layer of protection against permanent deletion** of specific object versions.

### 1. What Is MFA Delete?

| Property | Detail |
|---|---|
| **What it is** | A **bucket-level** versioning setting that requires **MFA** for sensitive operations |
| **Needs** | **Versioning enabled** on the bucket |
| **MFA device types** | **Virtual** (authenticator app on a phone) or **hardware** token |
| **Who can turn it on or off** | **Only the bucket owner, using the root account** |
| **Protects against** | **Permanent deletion** of object versions, and **accidental or malicious suspension** of versioning |

- The lecturer: MFA gives a **code from a device**, and that **code must be sent to S3** before the important operation is allowed.
- This builds on the **S3 Versioning** lectures. A normal delete only adds a **delete marker**, but deleting a **specific version ID** is permanent, which is exactly what MFA Delete guards.

### 2. When Is MFA Required?

| Operation | MFA required? | Why |
|---|---|---|
| **Permanently delete an object version** (delete with a version ID) | **Yes** | Destructive and irreversible |
| **Suspend versioning** on the bucket | **Yes** | Destructive (stops protecting future overwrites and deletes) |
| **Enable versioning** | **No** | Not dangerous |
| **List deleted versions** (see delete markers and old versions) | **No** | Read-only, not dangerous |
| Normal **delete** (adds a delete marker) | **No** (extra) | Reversible, so not protected |
| Upload, read, list current objects | **No** (extra) | Unaffected |
| **Change the MFA Delete setting itself** | **Yes** (and root only) | Needs the root account and an MFA code |

- The lecturer's rule: "both of these options are quite destructive, so MFA will be required for this".

```
Delete a specific version / suspend versioning
        |
        v
Request must include: MFA device serial number + current code
        |
   valid? --yes--> operation allowed
        |
        no
        v
     denied
```

- **Enabling versioning** and **listing deleted versions** don't need MFA.

### 3. Prerequisites

1. **Enable versioning** on the bucket. MFA Delete is part of the versioning configuration.
2. Use the **root account** (the bucket owner).
3. Have an **MFA device** registered for the **root user**.
4. Use the **CLI or API**. MFA Delete **can't be enabled in the console** (extra).

| Point | Detail |
|---|---|
| **Root only** | **IAM users, even admins, can't enable or disable MFA Delete**. Only the **bucket owner account's root user** can. |
| **Why that is awkward** | Using the root account is something you should do **rarely**. The next lecture walks through it. |
| **Versioning first** | Enabling MFA Delete on an unversioned bucket isn't possible. |

- The CLI/API request carries the **`x-amz-mfa`** header, set with `--mfa "<device-arn> <code>"` (the **device ARN**, a space, and the current 6-digit code). Without it, a permanent version delete fails with **AccessDenied**.

### 4. What MFA Delete Does and Doesn't Cover

| Covered | Not covered |
|---|---|
| Deleting a **specific object version** permanently | A **normal delete** that creates a **delete marker** |
| **Suspending** versioning | **Overwriting** an object (a new version is created) |
| Changing the MFA Delete state (root only) | Reads, lists, and uploads |

- **Delete markers are still recoverable**, so S3 doesn't gate them.
- **Limitation (extra):** MFA Delete **isn't supported together with lifecycle rules** on the same bucket (lifecycle can't permanently delete versions on its own with MFA Delete on). Check the current S3 docs if you plan to combine them.
- Related protection: **S3 Object Lock** (WORM) prevents deletion for a retention period, and has its own **governance and compliance modes**. It is a separate feature.

### 5. MFA Delete vs Related Protections

| Feature | What it protects |
|---|---|
| **Versioning** | Recover overwrites and normal deletes |
| **MFA Delete** | **Stops permanent version deletion and versioning suspension** without a second factor |
| **Object Lock** | Makes versions **immutable** for a time (WORM) |
| **Bucket policy** | Can **deny `s3:DeleteObjectVersion`** to specific principals |
| **Replication** | Keeps a **second copy** (permanent deletes aren't replicated) |

### 6. Exam-Style Recall

| If the question says... | Think... |
|---|---|
| "Prevent accidental permanent deletion of object versions" | **MFA Delete** (with versioning) |
| "Require MFA to suspend versioning" | **MFA Delete** |
| "Who can enable MFA Delete?" | The **bucket owner (root account)** only |
| "What must be enabled before MFA Delete?" | **Versioning** |
| "Is MFA needed to enable versioning?" | **No** |
| "Is MFA needed to list deleted versions?" | **No** |
| "Operations that require MFA with MFA Delete on" | **Permanently delete a version** and **suspend versioning** |
| "Delete without a version ID in an MFA Delete bucket" | Adds a **delete marker**, no MFA needed |
| "Make objects immutable for a retention period" | **S3 Object Lock**, not MFA Delete |
| "Can an IAM admin turn MFA Delete off?" | **No**, **root only** |
| "Enable MFA Delete" | **CLI/API as the root user**, with `--mfa` (device ARN and code) |
| "Permanently delete a version with MFA Delete on" | Needs the **MFA code** (CLI `--mfa`) |
| "Disable MFA Delete" | Same API with **`MFADelete=Disabled`** and a code, as root |
| "What goes in the `--mfa` parameter?" | **Device ARN, space, current code** |
| "Best practice for root access keys after the demo" | **Delete them** |

---

## S3 MFA Delete Hands On

### 1. Create the Bucket

| Setting | Demo value |
|---|---|
| **Name** | `demo-<name>-mfa-delete-2020` (use your own unique name) |
| **Region** | `eu-west-1` |
| **Versioning** | **Enable** |
| **Other settings** | Defaults |

- Click **Create bucket**.

### 2. The Console Limitation

1. Open the bucket, **Properties**, **Bucket Versioning**, **Edit**.
2. **Multi-factor authentication (MFA) delete** shows **Disabled**, and you **can't change it** here.

- This is the reason for the setup steps below.

### 3. Prerequisites

- **Root user** with a registered MFA device (only the bucket owner's root can enable or disable MFA Delete), the device **ARN**, and **root access keys** so the CLI can act as root. Versioning must be enabled.

**Find the MFA ARN:**
1. Signed in as **root**, click your account name, **Security credentials**.
2. Under **Multi-factor authentication (MFA)**, copy the device's **ARN** (the identifier).

### 4. Set Up the CLI as Root (Temporary)

**Warning:** the lecturer doesn't recommend this, "except for enabling MFA Delete on your S3 bucket".

#### 4.1 Create root access keys

1. Security credentials page (as root), **Access keys**, **Create access key**.
2. **Download the key file** (or copy the key ID and secret).
3. **Never share them.** The lecturer shows his keys on screen but **deletes them** afterward.

#### 4.2 Configure a CLI profile

```bash
aws configure --profile root-mfa-delete-demo
# AWS Access Key ID:     <root access key ID>
# AWS Secret Access Key: <root secret access key>
# Default region name:   eu-west-1
# Default output format: (Enter)
```

- Using a **named profile** keeps root credentials separate from your normal setup (see the earlier **AWS CLI Profiles** lecture).
- The course provides the commands in a file, **`s3-advanced-mfa-delete.sh`**.

#### 4.3 Test the profile

```bash
aws s3 ls --profile root-mfa-delete-demo
```

- It lists the account's buckets (three in the lecturer's case), so the profile works.

### 5. Enable MFA Delete

```bash
aws s3api put-bucket-versioning \
  --bucket demo-<name>-mfa-delete-2020 \
  --versioning-configuration Status=Enabled,MFADelete=Enabled \
  --mfa "arn:aws:iam::<account-id>:mfa/root-account-mfa-device <6-digit-code>" \
  --profile root-mfa-delete-demo
```

- Edit the command from the course file: change the **bucket name**, paste the **MFA ARN**, and add the **code**.
- **The first code was rejected.** MFA codes **rotate every 30 seconds**, and the lecturer typed one that had expired (or was mistyped). He **waited for the next code** and the command succeeded. If you get an error, try a fresh code.
- The command prints nothing on success.

**Verify:**
- Console, bucket, **Properties, Bucket Versioning**: **Versioning enabled** and **Multi-factor authentication (MFA) delete enabled**.
- Or: `aws s3api get-bucket-versioning --bucket <bucket> --profile root-mfa-delete-demo` shows `"MFADelete": "Enabled"`.

### 6. Test the Behavior

| Step | Action | Result |
|---|---|---|
| 1 | **Upload** a file (a JPEG copy) | Works |
| 2 | **Delete** the object (normal delete) | Works. It only **adds a delete marker**. |
| 3 | **Show versions** | Two entries: the **delete marker** and the **original version** |
| 4 | **Delete a specific version ID** (a permanent delete) | **Blocked**: "You cannot delete object because **MFA Delete is enabled** for this bucket". Use the **CLI** or **disable MFA Delete**. |

- Deleting a specific version **from the CLI** works if you include `--mfa`:

```bash
aws s3api delete-object \
  --bucket <bucket> --key <file> --version-id <version-id> \
  --mfa "arn:aws:iam::<account-id>:mfa/root-account-mfa-device <current-code>" \
  --profile root-mfa-delete-demo
```

- The console can't pass an MFA code, so it refuses these deletes.

### 7. Disable MFA Delete

```bash
aws s3api put-bucket-versioning \
  --bucket demo-<name>-mfa-delete-2020 \
  --versioning-configuration Status=Enabled,MFADelete=Disabled \
  --mfa "arn:aws:iam::<account-id>:mfa/root-account-mfa-device <new-6-digit-code>" \
  --profile root-mfa-delete-demo
```

- Same command with **`MFADelete=Disabled`**.
- You need a **new code** (the lecturer waits for the next one).
- Keep **`Status=Enabled`**, or you will also **suspend versioning**.
- After this:
  - Delete the **delete marker** (by version ID) in the console. It **works**, which **restores the object**.
  - Confirm in **Properties, Bucket Versioning**: **MFA Delete disabled**.

### 8. Troubleshooting

| Symptom | Likely cause |
|---|---|
| **"Invalid MFA one time pass code"** or **AccessDenied** | The **code expired or was mistyped**. Use the **next** code. |
| **AccessDenied** with a valid code | You aren't using **root** credentials (an IAM user can't change MFA Delete) |
| Wrong device identifier | The **`--mfa` value must be the ARN** of root's device, then a space, then the code |
| MFA Delete didn't turn on | **Versioning** wasn't enabled, or `Status=Enabled` was missing |
| Disabling also suspended versioning | You used `Status=Suspended` or left out `Status=Enabled` |

---

## S3 Access Logs

### TL;DR

- **S3 server access logging** records **every request made to a bucket** (authorized or denied, from any account) as **log files delivered to another S3 bucket**. Use it for **audit**.
- Analyze the logs with tools such as **Amazon Athena**.
- The **target (logging) bucket must be in the same AWS region** as the source bucket.
- The log files follow a **specific format**. See the [S3 server access log format](https://docs.aws.amazon.com/AmazonS3/latest/userguide/LogFormat.html) in the AWS docs.
- **Never set the logging bucket to be the same as the monitored bucket.** It creates an **infinite logging loop**: each log write is itself a request that gets logged, so the bucket **grows exponentially** and your bill with it.

### 1. What Are S3 Access Logs?

| Property | Detail |
|---|---|
| **Purpose** | **Audit**: know who accessed what, and when |
| **What is logged** | **Any request** to the bucket, from **any account**, **whether authorized or denied** |
| **Where logs go** | **Log files** written to **another S3 bucket** (the target bucket) |
| **Analysis** | **Amazon Athena** or other data analysis tools |
| **Region rule** | The **target bucket must be in the same region** as the source bucket |

```
Requests --> [Source bucket (monitored)] --(access logging enabled)--> log files --> [Target logging bucket, same region]
                                                                                              |
                                                                                              v
                                                                                       Athena / analysis
```

- Enable it **per source bucket**: bucket, **Properties**, **Server access logging**, **Edit**, enable, and choose the **target bucket** and an optional **prefix**.
- Several source buckets can log into **one** target bucket. Use a **prefix per source** to keep them apart.

### 2. Log Format

- Each log entry is a **line of space-delimited fields** describing one request.
- The lecture points to the AWS documentation page for the **log format**:

**Typical fields (extras):**

| Field | Meaning |
|---|---|
| **Bucket owner** | Canonical ID of the owner |
| **Bucket** | The bucket name |
| **Time** | When the request was received |
| **Remote IP** | Requester's IP address |
| **Requester** | IAM identity (or `-` for anonymous) |
| **Operation** | For example `REST.GET.OBJECT`, `REST.PUT.OBJECT` |
| **Key** | The object key |
| **Request-URI / HTTP status** | The request line and the **status code** (200, 403, 404, and so on) |
| **Error code** | For example `AccessDenied` |
| **Bytes sent, object size, total time** | Transfer details |
| **Referer, User-Agent** | Client details |
| **Version ID, signature version, TLS details** | Extra context |

- Because **denied requests are logged too**, the logs show **failed access attempts**, not only successes.
- The full, current field list is on the [log format page](https://docs.aws.amazon.com/AmazonS3/latest/userguide/LogFormat.html). AWS adds fields over time, so check it before writing parsers or Athena tables.

### 3. The Logging Loop Warning

**Rule: the logging bucket must not be the same as the bucket you monitor.**

```
PUT object --> [bucket] --logged--> log file written to [same bucket]
                  ^                         |
                  +----- that write is logged too --+   (and so on, forever)
```

- Writing a log file is itself a **PutObject request** on the bucket.
- If that bucket is also the one being logged, **every log write generates another log entry**, which generates another, and so on.
- Result: the bucket **grows exponentially** and **you pay a lot of money**. The lecturer: "do not try this at home".
- **Safe setup:** use a **separate, dedicated logging bucket**, in the **same region**, with its own access controls.
- The S3 console **warns or blocks** the same-bucket choice in many cases, but don't rely on it.

### 4. Delivery and Permissions (Extras)

| Topic | Detail |
|---|---|
| **Who writes the logs** | The **S3 logging service principal** (`logging.s3.amazonaws.com`), through the **target bucket policy** |
| **Permission needed** | A **bucket policy on the target bucket** that allows `s3:PutObject` for that principal, ideally limited with `aws:SourceArn` and `aws:SourceAccount` |
| **Delivery timing** | **Best effort**. Logs usually arrive within a few hours, and some requests may be **missing or delayed**. |
| **Cost** | No extra charge for the feature. You pay **storage** for the log files and the **requests** to write them. |
| **Target bucket ACLs** | Keep **ACLs disabled** (bucket owner enforced), and use the bucket policy |
| **Log key format** | `TargetPrefix` + date/time + unique string. You can choose **date-partitioned** keys for easier Athena queries. |
| **Lifecycle** | Add a **lifecycle rule** on the logging bucket to **expire old logs** |

**Typical target bucket policy (sketch):**

```json
{
  "Effect": "Allow",
  "Principal": { "Service": "logging.s3.amazonaws.com" },
  "Action": "s3:PutObject",
  "Resource": "arn:aws:s3:::my-log-bucket/logs/*",
  "Condition": {
    "ArnLike": { "aws:SourceArn": "arn:aws:s3:::my-source-bucket" },
    "StringEquals": { "aws:SourceAccount": "123456789012" }
  }
}
```

### 5. Analyzing the Logs

- **Amazon Athena** queries the log files **in place** in S3 using SQL, after you define a table over the log format.
- Typical questions:
  - Who deleted this object?
  - Which IPs get **AccessDenied**?
  - Which objects are downloaded most?
  - Any requests over **HTTP** instead of HTTPS?
- Other tools: **OpenSearch**, **QuickSight**, or a **Lambda** reacting to new log files (extras).

### 6. Access Logs vs CloudTrail Data Events (Extras)

| | **S3 server access logs** | **CloudTrail data events** |
|---|---|---|
| **Delivery** | **Best effort**, can be delayed | Near real time |
| **Format** | **Space-delimited text** in S3 | **JSON** to S3, CloudWatch Logs, EventBridge |
| **Cost** | Storage only | **Charged per event** |
| **Detail** | Includes fields such as **bytes sent and turnaround time** | Includes full **IAM identity context** |
| **Use for** | Cheap, bulk **audit and traffic analysis** | Security investigation, alerts, compliance |

- The lecture covers server access logs. CloudTrail is a separate service.

### 7. Exam-Style Recall

| If the question says... | Think... |
|---|---|
| "Audit all requests made to an S3 bucket" | **S3 server access logging** |
| "Where do S3 access logs go?" | **Another S3 bucket** |
| "Region of the logging bucket" | The **same region** as the source |
| "Analyze S3 access logs with SQL" | **Amazon Athena** |
| "Bucket size and cost explode after enabling access logs" | The **logging bucket is the same as the source bucket** (logging loop) |
| "Are denied requests logged?" | **Yes** |
| "Are logs delivered in real time?" | **No**, **best effort** |
| "Record API-level activity with full identity context, near real time" | **CloudTrail data events** |
| "Enable server access logging for a bucket" | Bucket **Properties, Server access logging** |
| "What permission lets S3 write the logs?" | A **bucket policy on the target** allowing the **S3 logging service** to `PutObject` |
| "Logs haven't appeared after enabling logging" | **Delivery is best effort**, and can take **hours** |
| "Optional setting to organize log files" | **Prefix**, or **date-partitioned key format** |

---

## S3 Access Logs - Hands On

### 1. Create the Logging Bucket

| Setting | Demo value | Notes |
|---|---|---|
| **Name** | `<name>-access-logs-v3` | The lecturer used a `stephane-...access-log...` name. Use your own unique name. |
| **Region** | `eu-west-1` | Must be the **same region as the source bucket** |
| **Other settings** | Defaults | Keep **Block Public Access on** and **ACLs disabled** |

- Click **Create bucket**, then keep that tab open.
- This bucket is **only for logs**. Don't put other data in it.

### 2. Enable Server Access Logging on a Source Bucket

Use any existing bucket in the **same region** as the logging bucket.

1. Open the **source bucket**, **Properties** tab.
2. Scroll to **Server access logging**, click **Edit**.
3. Select **Enable**.
4. Note the message: **the bucket policy of the target bucket will be updated** so logs can be written.
5. Under **Destination**, browse or type the **logging bucket** and choose it.
6. Review the other settings (section 3), then **Save changes**.

- The console shows **Destination region** (`eu-west-1`) and the **destination bucket name** after you choose it.
- Server access logging is now **enabled** on the source bucket.

### 3. Settings Explained

- Destination: the logging bucket (same region, never the source). Prefix: not used. Log key format: **default**; the **date-partitioned** format is worth choosing if you plan to query with Athena.

### 4. Generate Some Activity

1. In the source bucket, **open an object** (a read request).
2. **Upload** a file, for example `beach.jpg` (a write request).
3. Do other actions as you like: list, download, delete, and also try something that **fails** (for example a denied request).

### 5. Check the Target Bucket Policy

- The console said the policy would be updated. Verify it:
  1. Open the **logging bucket**, **Permissions** tab, **Bucket policy**.
  2. A statement now **allows the S3 logging service to `PutObject`** into the bucket.

The statement has the same shape as the sketch in the lecture.

- If you later remove the policy, logs **stop being delivered**.

### 6. Wait for Delivery

- Refreshing the logging bucket right away shows **no objects**.
- Reason: delivery is **best effort**. Logs are batched and usually arrive **within a few hours**, and the lecturer waited **a couple of hours** before checking.

### 7. Read the Logs

1. After a while, refresh the logging bucket. **Many small log files** appear, with names like `2026-10-07-03-15-22-ABCDEF0123456789` (plus any prefix).
2. Open one (the console **Open** or download).
3. Each **line is one request**.

**What you can see in a line:**

- The lecturer: it is "quite hard to decipher" by eye, but it shows the **API call, the success or failure, who accessed it, which bucket, the time**, and more.
- The field layout is in the [S3 server access log format](https://docs.aws.amazon.com/AmazonS3/latest/userguide/LogFormat.html) page.

### 8. Troubleshooting

| Symptom | Likely cause |
|---|---|
| **No logs after a long time** | The target bucket policy is missing or wrong, the target is in a **different region**, or you didn't generate activity. Wait up to a few hours, and check the policy. |
| **Can't choose the destination bucket** | It must be in the **same region** and **same account** (for the console flow) |
| **Policy not updated** | You lack permission to edit the target bucket policy, or the console couldn't change it. Add the statement by hand. |
| **AccessDenied reading logs** | Your identity lacks `s3:GetObject` on the logging bucket |

---

## S3 Pre-signed URLs

### TL;DR

- A **pre-signed URL** gives **temporary access to one specific S3 object** without making the bucket or object public.
- Generate it with the **S3 console, the CLI, or an SDK**. The URL has an **expiration**.
- **Maximum expiration (per the lecture):**
  - **Console:** up to **12 hours**.
  - **CLI:** up to **168 hours** (7 days).
- The person who uses the URL **inherits the permissions of the user who generated it**, for **GET** (download) or **PUT** (upload).
- It works because the URL carries a **SigV4 signature** (the **query string** option from the SigV4 lecture, with `X-Amz-Signature`).
- **Use cases:**
  - Let **only logged-in users** download a **premium video** from a private bucket.
  - Give an **ever-changing list of users** download access by **generating URLs dynamically**.
  - Let a user **temporarily upload** a file to a **precise location** in a private bucket.

### 1. What Is a Pre-signed URL?

| Property | Detail |
|---|---|
| **What it is** | A URL for **one object** that includes a **signature** proving who generated it |
| **Generated with** | **S3 console, AWS CLI, or AWS SDK** |
| **Expires** | **Yes.** After the expiry time, the URL stops working. |
| **Operations** | **GET** (download) or **PUT** (upload) |
| **Permissions** | The user of the URL **inherits the generator's permissions** for that object and operation |
| **Bucket stays** | **Private** |

- The lecturer: the URL "carries over your credentials, in terms of authorization to access that file".
- More precisely, the **secret key is never in the URL**. The URL holds the **access key ID** and a **signature** computed from the secret key.
- You already saw this in the S3 hands-on: the console's **Open** button creates a **pre-signed URL**, while the plain **Object URL** returned **AccessDenied**.

### 2. Expiration Limits

| Method | Maximum (lecture) | Default (extra) |
|---|---|---|
| **S3 console** | **12 hours** | **1 hour** (configurable from 1 minute) |
| **AWS CLI** | **168 hours** (7 days) | **3,600 seconds** (1 hour) |
| **SDK** | Up to **7 days** | Varies by SDK (often 1 hour) |

**Important caveat (extras):**
- The URL **stops working when the signer's credentials expire**, even if its own expiry is later.
- **Long-term IAM user keys:** a URL can last up to **7 days**.
- **Temporary credentials** (an IAM role, EC2 or Lambda role, STS, console session): the URL lasts **only as long as those credentials**, often **1 to 12 hours**. That is why the console tops out at 12 hours.
- Lambda and EC2 roles rotate credentials, so URLs generated there usually live **a few hours at most**.

### 3. How It Works (Lecture Flow)

```
Bucket owner / app (IAM identity with S3 access)
   |  1. generate pre-signed URL for object X (GET or PUT, with an expiry)
   v
Pre-signed URL (contains the signature)
   |  2. send the URL to the target user
   v
User (no AWS account needed)
   |  3. use the URL (HTTP GET or PUT)
   v
S3 bucket (private)  --> verifies the signature and expiry --> file returned (or upload accepted)
```

**Step by step:**
1. You have a **private bucket** and want to give someone **outside AWS** access to **one file**, without making it public or weakening security.
2. You (the bucket owner or an authorized user) **generate a pre-signed URL** for that file.
3. You **send the URL** to the person for a **limited time**.
4. The person **uses the URL** and S3 serves the file (for example a **download**).

**What S3 checks when the URL is used:**
- The **signature is valid** (nothing in the URL was altered).
- The URL has **not expired**.
- The **signer's identity currently has permission** for that action on that object.

- If the signer's permissions are **removed or reduced**, **existing URLs stop working**.
- The signer doesn't need to have the object created yet for a **PUT** URL.

### 4. Use Cases

| Use case | How pre-signed URLs help |
|---|---|
| **Premium content for logged-in users** | Your app authenticates the user, then **generates a short-lived URL** for the video. Non-logged-in users never get one. |
| **Dynamic list of users who may download files** | Generate URLs **on demand**, per user and per file, instead of editing bucket policies |
| **Temporary upload to a precise location** | A **PUT URL** for one exact key (for example `uploads/user123/photo.jpg`) while the bucket stays **private** |
| **Share a file with an external partner** | One-off download link, no AWS account needed |

- It is "a very, very common use case when it comes to **temporary access to one specific file**, for download or upload".

### 5. Generating Pre-signed URLs

#### 5.1 Console

- Select the object, **Object actions**, **Share with a pre-signed URL**, set the **time interval** (up to **12 hours**), then **Create pre-signed URL**.
- The URL is copied to your clipboard.

#### 5.2 CLI (GET only)

```bash
aws s3 presign s3://my-bucket/premium/video.mp4 --expires-in 3600
```

- **`--expires-in`** is in **seconds**. The maximum is **604,800** (**168 hours**, 7 days).
- Default is **3,600** seconds (1 hour).
- The CLI's `presign` command creates **GET** URLs. For PUT URLs, use an **SDK**.
- Use `--region` for buckets outside the default region, and make sure the CLI uses **SigV4** (the default now).

#### 5.3 SDK (Python, Boto3)

```python
import boto3

s3 = boto3.client("s3", region_name="eu-west-1")

# Download URL
get_url = s3.generate_presigned_url(
    "get_object",
    Params={"Bucket": "my-bucket", "Key": "premium/video.mp4"},
    ExpiresIn=900,          # 15 minutes
)

# Upload URL
put_url = s3.generate_presigned_url(
    "put_object",
    Params={"Bucket": "my-bucket", "Key": "uploads/user123/photo.jpg"},
    ExpiresIn=900,
)
```

#### 5.3.1 Using the URLs

```bash
curl -o video.mp4 "<get_url>"
curl -X PUT --upload-file photo.jpg "<put_url>"
```

- For a PUT URL, the client must send **exactly the headers the URL was signed with** (for example `Content-Type`), or the signature check fails.
- For **large uploads**, generate a **pre-signed URL per part** (multipart) or use another approach.
- **Pre-signed POST** (`generate_presigned_post`) lets browsers upload with **form fields and policy conditions** such as **size limits** and **content types** (extra).

### 6. Anatomy of the URL

```
https://my-bucket.s3.eu-west-1.amazonaws.com/premium/video.mp4
  ?X-Amz-Algorithm=AWS4-HMAC-SHA256
  &X-Amz-Credential=AKIA.../20261007/eu-west-1/s3/aws4_request
  &X-Amz-Date=20261007T040000Z
  &X-Amz-Expires=900
  &X-Amz-SignedHeaders=host
  &X-Amz-Security-Token=<present with temporary credentials>
  &X-Amz-Signature=<signature>
```

| Parameter | Meaning |
|---|---|
| **`X-Amz-Expires`** | Validity in **seconds** from `X-Amz-Date` |
| **`X-Amz-Signature`** | The **signature** (SigV4 query string option) |
| **`X-Amz-Security-Token`** | Present when the signer used **temporary credentials** |

- This is the **query string** way of sending a SigV4 signature, from the previous **SigV4** lecture.

### 7. Security Considerations

| Risk | Mitigation |
|---|---|
| **Anyone holding the URL can use it** until it expires | Use **short expirations**, and send it over a **secure channel** |
| **URL leaks** in logs, browser history, or referer headers | Don't log them. **Use HTTPS only.** |
| **Over-privileged signer** | Generate URLs with an **identity that has least privilege** (only the needed bucket and prefix) |
| **Can't revoke a single URL** | Revoke by **removing the signer's permissions**, rotating the keys, or deleting the object |
| **Uploads to unexpected keys** | Set the **key server-side**. Never let the user choose it. |
| **Browser uploads** | The bucket needs a **CORS** configuration that allows the site's origin and the PUT method |

- Pre-signed URLs don't bypass **bucket policies or explicit denies**. If a **bucket policy denies** the signer or the request (for example a condition on **VPC endpoint** or **IP**), the URL fails.
- Block Public Access **doesn't affect** pre-signed URLs, since they are authenticated requests.

### 8. Pre-signed URLs vs Alternatives

| Need | Use |
|---|---|
| **Temporary access to one object** for someone without AWS credentials | **S3 pre-signed URL** |
| **Make content public** to everyone | **Bucket policy** (public read) |
| **Authenticated users with IAM identities** | **IAM policies** or **roles** |
| **Serve private content globally with caching** | **CloudFront signed URLs or cookies** (with **OAC** to the bucket) |
| **Many files or a prefix** under one policy | **CloudFront signed cookies**, or STS temporary credentials scoped to a prefix |
| **Cross-account access** | **Bucket policy** plus the other account's IAM permissions |

### 9. Exam-Style Recall

| If the question says... | Think... |
|---|---|
| "Give a user outside AWS temporary access to a private object" | **S3 pre-signed URL** |
| "Allow logged-in users only to download a premium video from S3" | **Pre-signed URL** generated by your app |
| "Let users upload to a precise key while the bucket stays private" | **Pre-signed PUT URL** |
| "Max pre-signed URL expiry in the console" | **12 hours** |
| "Max pre-signed URL expiry with the CLI" | **168 hours** (7 days) |
| "Whose permissions does a pre-signed URL carry?" | **The user who generated it** |
| "How do you generate a pre-signed URL?" | **Console, CLI (`aws s3 presign`), or SDK** |
| "Which operations can a pre-signed URL do?" | **GET** and **PUT** |
| "Pre-signed URL stopped working before its expiry" | The **signer's credentials expired**, or the signer **lost permissions** |
| "Where is the signature in a pre-signed URL?" | The **query string** (`X-Amz-Signature`) |
| "Serve private S3 content to users through a CDN with signed access" | **CloudFront signed URLs or cookies** |
| "Browser JavaScript upload with a pre-signed URL fails with a CORS error" | Add a **CORS configuration** to the bucket |
| "Share a private S3 object with someone temporarily, no public access" | **Pre-signed URL** |
| "Generate a pre-signed URL in the console" | **Object actions, Share with a pre-signed URL** |
| "Plain Object URL returns AccessDenied, console Open works" | **Open uses a pre-signed URL** |
| "Who can use a pre-signed URL?" | **Anyone who has it**, until it expires |
| "What happens after the expiry time?" | The URL **stops working** |
| "Does the bucket need to be public for a pre-signed URL?" | **No** |

---

## S3 Pre-signed URLs - Hands On

### 1. Starting Point

- Use any bucket that is **not public** (Block Public Access on, no public bucket policy).
- Upload an image such as `coffee.jpg` (any file works).
- Open the object's details page in the console.
- The object's plain **Object URL** returns **AccessDenied**, while the console's **Open** button works because it uses a pre-signed URL (the same comparison as in the S3 Hands On).

### 2. Generate Your Own Pre-signed URL

#### 2.1 Console steps

1. Select the object (or open its page).
2. **Object actions**, **Share with a pre-signed URL**.
3. Read the console message: **anyone with the URL can access the object until it expires**, **even if the bucket and object are private**.
4. Set **Time interval until the URL expires**: choose **minutes** or **hours**. The demo used **5 minutes**.
5. Click **Create pre-signed URL**.
6. The URL is **copied to your clipboard**. The console confirms it.

#### 2.2 Test it

1. Paste the URL into a new browser tab (a **private/incognito window** is best, so you know it isn't using your console session).
2. Press Enter. The image **displays**.
3. Send the URL to someone else. They can open it **without an AWS account**.
4. After **5 minutes**, try again. The request fails with an **expired** error (typically **AccessDenied: Request has expired**).

- The lecturer's use: "very handy if you want to share access to some files in your S3 bucket very quickly", then **let the URL expire** for maximum security.

### 3. Troubleshooting

| Symptom | Likely cause |
|---|---|
| **SignatureDoesNotMatch** | The URL was **altered** (a character lost when copying), or the region or addressing style differs |
| **Link breaks when pasted into chat** | Some apps **truncate or re-encode** long URLs. Test the pasted version. |
| **Image downloads instead of displaying** | Depends on the object's **Content-Type** and **Content-Disposition** |
| **Can't create the URL** | Your identity lacks `s3:GetObject` on the object |

---

## S3 Access Points

### TL;DR

- **S3 Access Points** simplify security management for buckets that hold **lots of data for many users or groups**. Instead of one giant, ever-growing bucket policy, each access point has **its own policy**.
- Each access point is tied to a **prefix** (for example `finance/`, `sales/`) or the whole bucket, and has **its own DNS name** that clients use to connect.
- An **access point policy** looks like a **bucket policy** and grants access (for example read/write) to the data that access point exposes.
- An access point's **network origin** is either the **internet** or a **VPC** (private only).
- For a **VPC origin**, you must create a **VPC endpoint** (interface endpoint) to reach the access point. The endpoint has its **own policy** that must allow both the **access point** and the **target bucket**.
- Result: a **simple bucket policy** plus **small, per-team access point policies**, which **scales** better.

### 1. The Problem

- One bucket holds **finance data**, **sales data**, and more.
- Different users and groups need access to **different parts**.
- A single **bucket policy** for all of them:
  - Grows with every new user, team, and prefix.
  - Becomes hard to read, review, and change safely.
  - Has a **20 KB size limit** (extra), so it can't grow forever.
- The lecturer: "the more users, the more data you have, the more unmanageable this may become".

### 2. The Solution: Access Points

| Property | Detail |
|---|---|
| **What it is** | A **named network endpoint** attached to a bucket, with **its own access policy** |
| **Scope** | Usually a **prefix** (for example `finance/`) or the whole bucket |
| **DNS name** | **Each access point has its own DNS name.** That is how you connect to it. |
| **Policy** | An **access point policy**, very similar to a **bucket policy** |
| **Network origin** | **Internet** or **VPC** |
| **Goal** | Push **security management** out of the bucket policy and into **per-access-point policies** |

**Lecture example (one bucket, three access points):**

```
                    +--> Finance access point  (policy: read/write on finance/*)  --> finance/ prefix
Users/groups -------+--> Sales access point    (policy: read/write on sales/*)    --> sales/ prefix
                    +--> Analytics access point (policy: read-only)               --> finance/ and sales/
                                              \
                                          [ S3 bucket: finance/, sales/ ]
                                          (simple bucket policy)
```

| Access point | Policy | Data it reaches |
|---|---|---|
| **Finance** | Read **and write** on the **finance** prefix | `finance/` |
| **Sales** | Read **and write** on the **sales** prefix | `sales/` |
| **Analytics** | **Read-only** | **Both** `finance/` and `sales/` |

- **Finance users** connect to the finance access point and can only reach the finance part.
- **Sales users** reach only the sales part.
- The **analytics group** can see **finance and sales at the same time**, but **read-only**.
- **Access points** make **security management at scale** simpler for a shared bucket.

### 3. How Permissions Work

| Layer | What it does |
|---|---|
| **IAM permissions** | Users or roles need IAM permission to use the **access point** |
| **Access point policy** | Allows or denies the request **at that access point** |
| **Bucket policy** | Must also allow the request. A common pattern is to **delegate to access points**. |

- Each layer must **allow** the request, with **no explicit deny** anywhere.
- **Delegation pattern (extra):** keep the bucket policy **simple**, with a statement that says "allow any access that comes **through an access point owned by this account**" (condition `s3:DataAccessPointAccount`). Then manage detailed access in the **access point policies**.
- The lecturer's summary: "a very simple bucket policy on Amazon S3" plus "policies attached to each access point".
- **Scale benefit:** adding a new team means **adding an access point**, not editing a huge bucket policy.

### 4. Connecting to an Access Point

- Each access point has its **own DNS name**:

```
https://<access-point-name>-<account-id>.s3-accesspoint.<region>.amazonaws.com
```

- In CLI and SDK calls, you can use the **access point ARN** (or alias) in place of the bucket name:

```bash
aws s3api get-object \
  --bucket arn:aws:s3:eu-west-1:123456789012:accesspoint/finance \
  --key finance/report.csv report.csv
```

- An **access point alias** looks like a bucket name, so many tools work **without code changes** (extra).
- Access points can have **names unique per account and region**.

### 5. Network Origin: Internet vs VPC

| Origin | Meaning |
|---|---|
| **Internet** | Reachable over the **public internet** (still controlled by policies and IAM) |
| **VPC** | Reachable **only from inside a specific VPC**. No internet path. |

- Set at **creation**, and it **can't be changed** afterward (extra).
- **VPC origin** is the private option, for example an **EC2 instance in a VPC** accessing the bucket **without going through the internet**.

#### 5.1 VPC origin and the VPC endpoint

```
EC2 instance (in VPC)
      |
      v
[ VPC endpoint (S3, interface or gateway) ]  -- endpoint policy --> allows access point and bucket
      |
      v
[ S3 Access Point (VPC origin) ] -- access point policy --> [ S3 bucket ] -- bucket policy
```

- To use a **VPC-origin access point**, you must create a **VPC endpoint** in that VPC.
- The **VPC endpoint has a policy**. It must **allow access to the target bucket and the access point** (the lecturer's wording).
- **Three layers of security** in this setup:
  1. **VPC endpoint policy** (network edge).
  2. **Access point policy**.
  3. **S3 bucket policy**.
- Extras: an access point with a **VPC network origin** **rejects requests from outside** that VPC. For S3, the endpoint is typically an **S3 gateway endpoint** (free) or an **interface endpoint**. Check the current docs for which type your setup supports.

### 6. Access Points vs Other Options

| Need | Use |
|---|---|
| **Many teams with different access to one bucket** | **Access points** |
| **Simple, single policy for one bucket** | **Bucket policy** |
| **Temporary access to one object** | **Pre-signed URL** |
| **Private-only access from a VPC** | **Access point with VPC origin** + **VPC endpoint** |
| **Different data views** (for example redacted for some users) | **S3 Object Lambda access point** (extra, a later topic) |
| **Multi-Region single endpoint** (extra) | **Multi-Region Access Points** |

### 7. Exam-Style Recall

| If the question says... | Think... |
|---|---|
| "Simplify managing access for many teams to one S3 bucket with different prefixes" | **S3 Access Points** |
| "Bucket policy has become too large and complex" | **Access points** (per-team policies) |
| "How do clients connect to an access point?" | Its **own DNS name** (or ARN/alias) |
| "Give analytics read-only access to finance and sales data" | An **access point with a read-only policy** |
| "Private access to S3 from EC2 without the internet, via an access point" | **VPC-origin access point** + **VPC endpoint** |
| "What must the VPC endpoint policy allow?" | The **access point** and the **target bucket** |
| "Network origin options for an access point" | **Internet** or **VPC** |
| "An access point policy is most similar to..." | An **S3 bucket policy** |
