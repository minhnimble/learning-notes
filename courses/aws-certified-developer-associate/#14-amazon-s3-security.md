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
  - It is **not available in the console**. Use the **CLI, SDKs, or the API**.
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

### 8. Enforcing Encryption on Upload (Extras)

- **Default encryption** (bucket setting) applies **SSE-S3** or **SSE-KMS** to every new object without the header.
- To **require** a specific method, use a **bucket policy** that **denies `PutObject`** unless the right header is present:

```json
{
  "Effect": "Deny",
  "Principal": "*",
  "Action": "s3:PutObject",
  "Resource": "arn:aws:s3:::my-bucket/*",
  "Condition": {
    "StringNotEquals": { "s3:x-amz-server-side-encryption": "aws:kms" }
  }
}
```

- The earlier **bucket policy lecture** mentions this use case.

### 9. Comparison

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

### 10. Key Facts to Remember

- **SSE-S3** = S3-owned keys, **AES-256**, header **`AES256`**, **default** on new buckets and objects.
- **SSE-KMS** = KMS keys, **user control**, **CloudTrail audit**, header **`aws:kms`**.
- **SSE-KMS read** = needs permission on **the object and the KMS key**.
- **SSE-KMS quota** = **GenerateDataKey** and **Decrypt** count toward **KMS requests per second**. Throttling is possible. Raise it with **Service Quotas**. **Bucket Keys** reduce calls.
- **DSSE-KMS** = **dual-layer**, header **`aws:kms:dsse`**, for multilayer requirements.
- **SSE-C** = **your key**, sent with **each request** over **HTTPS only**. **S3 never stores it.**
- **Client-side** = **encrypt before upload**, the client manages keys and the whole cycle.
- **In transit** = **HTTPS (TLS)**. Force it with a **Deny when `aws:SecureTransport` is false**.
- All server-side methods give encryption **at rest**. Client-side encrypts **before** S3 receives anything.

### 11. Exam-Style Recall

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


