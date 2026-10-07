# Amazon S3 Introduction

---

## S3 Overview

### TL;DR

- **Amazon S3 (Simple Storage Service)** is **object storage** and one of the main building blocks of AWS. It is advertised as **infinitely scaling storage**.
- Much of the web relies on it, and many AWS services use S3 for integrations.
- **Buckets** hold **objects** (files). Buckets are created in a **region**, even though the console lists all buckets together.
- **Naming:** bucket names used to be **globally unique**. A newer **account regional namespace** option lets you reuse names (AWS adds a suffix to keep them unique). Keep names simple: lowercase letters, numbers, and hyphens.
- **Object key** = the **full path** of the object. It is made of a **prefix** and an **object name**. S3 has **no real directories**, only keys with slashes.
- **Max object size: 50 TB** (per the lecture). Objects **over 5 GB must use multipart upload**.
- Objects can have **metadata**, up to **10 tags**, and a **version ID** (if versioning is on).

### 1. What Is S3?

| Property | Detail |
|---|---|
| **Type** | **Object storage** (not block or file storage) |
| **Scaling** | "Infinitely scaling", with no capacity planning |
| **Scope** | **Regional** for data. The console shows a **global** view of buckets. |
| **Importance** | A core AWS building block, used by websites and by many AWS services |

- The lecturer calls this section "very important". S3 appears throughout the exam (security, events, Lambda, CloudFront, and more).
- The section teaches S3 **step by step** through the main features.

### 2. Use Cases

At its core S3 is storage, so the use cases are broad:

| Use case | Example |
|---|---|
| **Backup and storage** | Files, disk backups |
| **Disaster recovery** | Replicate data to **another region**, so it survives a regional outage |
| **Archival** | Archive files and retrieve them later at a **much lower cost** (S3 Glacier classes) |
| **Hybrid cloud storage** | Extend **on-premises** storage into the cloud |
| **Application hosting** | Host app assets and data |
| **Media hosting** | Videos, images |
| **Data lake and big data analytics** | Store large amounts of data and analyze it |
| **Software delivery** | Distribute **software updates** |
| **Static website hosting** | Serve a website straight from a bucket |

**Customer examples from the lecture:**
- **NASDAQ** stores **7 years of data** in **S3 Glacier**, the archival tier of S3.
- **Sysco** runs **analytics** on its data in S3 to gain **business insights**.

### 3. Buckets

#### 3.1 What a bucket is

- S3 stores **objects (files) in buckets**.
- A bucket is like a **top-level directory in the cloud**.
- Buckets are **defined at the region level**: you create a bucket **for a specific AWS region**.
- S3 shows a **global interface** (you see all your buckets from all regions in one list), but **each bucket lives in one region**.
- **Pick the region close to your users** or to the services that use the data. It affects latency, cost, and compliance.

#### 3.2 Bucket naming

**Classic behavior:** a bucket name had to be **globally unique** across **all regions and all accounts**. Once you owned a name, nobody else could use it.

**New feature (account regional namespace):**
- Lets you **reuse the same bucket name** across regions and accounts.
- Even if someone else has used the same name, AWS **adds a suffix** to your bucket name so it stays unique.
- Because of this, "you can pretty much use whatever you want" for a bucket name.
- The exact suffix format and which bucket types support it can change, so check the current S3 docs.
- If the exam describes the classic behavior, the expected answer is still "**bucket names are globally unique**".

**Naming rules (from the lecture):**

| Rule | Detail |
|---|---|
| **No uppercase letters** | Lowercase only |
| **No underscores** | Use hyphens |
| **Not formatted as an IP address** | For example not `192.168.1.1` |
| **First character** | Must be a **lowercase letter or number** |
| **Must not start with** | `xn--` |
| **Must not end with** | `-s3alias` |

- Extra rules from the S3 docs: **3 to 63 characters**, only lowercase letters, numbers, dots, and hyphens. Some other prefixes and suffixes are also reserved (for example `sthree-`, `--ol-s3`, `--x-s3`).
- The lecture's advice: **keep it simple** with letters and numbers.

### 4. Objects

#### 4.1 Object keys

- Every object has a **key**, which is the **full path** of the object within the bucket.
- The key is made of a **prefix** and an **object name**.

| Object location | Key |
|---|---|
| At the top level of the bucket | `my_file.txt` |
| Nested in "folders" | `my_folder1/another_folder/my_file.txt` |

**Breaking down the nested example:**

| Part | Value |
|---|---|
| **Prefix** | `my_folder1/another_folder/` |
| **Object name** | `my_file.txt` |
| **Key** (prefix + name) | `my_folder1/another_folder/my_file.txt` |

#### 4.2 S3 has no directories

- S3 has **no concept of directories**. The console UI makes it look like it does, and lets you "create folders".
- **Everything is a key.** Keys are **very long names that contain slashes**.
- "Folders" in the console are just **prefixes**. The console creates an empty object ending in `/` to show an empty folder.
- Why it matters: operations like **list by prefix**, **lifecycle rules by prefix**, and **IAM policy conditions by prefix** all work on key prefixes.
- Related: request performance scales **per prefix** (at least 3,500 PUT/POST/DELETE and 5,500 GET/HEAD requests per second per prefix). This isn't in the lecture.

#### 4.3 Object value, size, and multipart upload

| Property | Detail |
|---|---|
| **Value** | The **content of the body**. You can upload any type of data. |
| **Max object size** | **50 TB** (per the lecture) |
| **Single upload limit** | A single PUT supports up to **5 GB** |
| **Over 5 GB** | You **must use multipart upload**, which splits the file into **parts** |

- **Lecture example:** a **5 TB** file, with each part at most 5 GB, needs **at least 1,000 parts**. That is 5 TB ÷ 5 GB.
- Multipart details (extras): each part is **5 MB to 5 GB** (the last part can be smaller), and an upload can have up to **10,000 parts**.
- AWS **recommends multipart for objects over about 100 MB**, because it gives **parallel uploads, faster throughput, and retry of just a failed part**.
- The 50 TB figure is the newer limit. Older material (and older exam prep) says **5 TB**. If an exam question says 5 TB, that is the older number.

#### 4.4 Metadata and tags

- **Metadata:** key-value pairs, **system-defined** or **user-defined** (`x-amz-meta-*`), set at upload.
- **Tags:** up to **10** Unicode key-value pairs per object, used for security conditions and lifecycle rules.
- Both are covered in detail in the S3 Object Tags & Metadata section.

#### 4.5 Version ID

- If **versioning is enabled** on the bucket, each object also has a **version ID**.
- With versioning off, the version ID is `null`.
- Versioning comes in a later lecture.

#### 4.6 Object anatomy

```
Object
 ├── Key       : my_folder1/another_folder/my_file.txt   (prefix + name)
 ├── Value     : the data (up to 50 TB, multipart if > 5 GB)
 ├── Metadata  : system and user key-value pairs
 ├── Tags      : up to 10 Unicode key-value pairs
 └── Version ID: (only if versioning is enabled)
```

### 5. Related Facts (Beyond the Lecture)

| Topic | Detail |
|---|---|
| **Durability** | **99.999999999% (11 nines)** for most storage classes |
| **Availability** | **99.99%** for S3 Standard |
| **Consistency** | **Strong read-after-write consistency** for all PUTs, DELETEs, and lists (since Dec 2020) |
| **Access** | Over **HTTPS** by default, via the console, CLI, SDKs, or REST API |
| **Bucket types** | General purpose buckets (this lecture), plus directory buckets and others (not exam focus) |
| **Security default** | New buckets are **private**, with **Block Public Access** on by default |
| **Pricing** | Pay for **storage**, **requests**, **data transfer out**, and **optional features**. Upload into S3 is free. |
| **Storage classes** | Standard, Intelligent-Tiering, Standard-IA, One Zone-IA, Glacier Instant/Flexible/Deep Archive (later lectures) |

### 6. Exam-Style Recall

| If the question says... | Think... |
|---|---|
| "Infinitely scaling object storage" | **Amazon S3** |
| "Is an S3 bucket regional or global?" | **Regional** (created in one region, but listed globally) |
| "S3 bucket names must be unique..." | **Globally unique** (classic). The new account regional namespace adds a suffix. |
| "Valid S3 bucket name" | Lowercase letters, numbers, and hyphens (no uppercase, no underscores, not an IP) |
| "Full path of an object in a bucket" | **Object key** |
| "`folder1/folder2/file.txt`: what is `folder1/folder2/`?" | The **prefix** |
| "Does S3 have folders?" | **No.** Only keys with prefixes (the console simulates folders). |
| "Upload a file larger than 5 GB" | **Multipart upload** |
| "Maximum object size" | **50 TB** (older: 5 TB) |
| "Maximum number of tags per object" | **10** |
| "Tags are useful for..." | **Security and lifecycle** |
| "What identifies a particular version of an object?" | **Version ID** (needs versioning) |
| "Replicate data to another region for disaster recovery" | **S3 cross-region replication** (later lecture) |
| "Archive data cheaply for years" | **S3 Glacier** storage classes |
| "Host a static website without servers" | **S3 static website hosting** |
| "Bucket creation fails: name already exists" | Bucket names are **globally unique** (use the **Account Regional namespace** to avoid it) |
| "Use the same bucket name in multiple regions or accounts" | **Account Regional namespace** |
| "Default access on a new bucket" | **Private**, with **Block Public Access on** |
| "Object URL returns AccessDenied" | Object or bucket is **not public** |
| "Pre-signed URL permissions" | Same as the **identity that generated it** |
| "Pre-signed URL expires" | **Yes**, after the set time |
| "Create a pre-signed URL from the CLI" | `aws s3 presign` |
| "Default encryption for new buckets" | **SSE-S3** |
| "Bucket type for low-latency use cases" | **Directory bucket** |
| "Are S3 folders real?" | **No.** They are **key prefixes**. |
| "S3 URI format" | `s3://bucket/key` |
| "Where do you see buckets from all regions?" | The **S3 console list** (global view) |

---

## S3 Hands On

### 1. Creating the Bucket

#### 1.1 Settings used

| Setting | Demo value | Notes |
|---|---|---|
| **Region** | `eu-west-1` (Europe, Ireland) | A bucket is created in **one region**. Change it with the region selector (top right) first. |
| **Bucket type** | **General purpose** | The most common and recommended type for most access patterns. **Directory** buckets are for **low-latency** use cases, and weren't used. |
| **Namespace** | **Global** (classic) or **Account Regional** | See section 1.2 |
| **Bucket name** | `stephane-demo-s3-v12` | Unique name, lowercase, hyphens only |
| **Object Ownership** | **ACLs disabled** (recommended) | Default. A security setting, and the bucket owner owns every object. |
| **Block Public Access** | **Block all public access** (ON) | Default. Maximum security, so only you can access the objects. |
| **Bucket Versioning** | **Disabled** | Covered in a later lecture |
| **Tags** | None | |
| **Default encryption** | **SSE-S3** (Amazon S3 managed keys) | All objects are encrypted at rest. Encryption is covered later. |
| **Bucket Key** | **Enabled** | Reduces KMS request costs. It only matters for SSE-KMS, but is on by default. |

- Everything except the **name** was left at its default.
- Click **Create bucket**.

#### 1.2 Name collisions

**Demo of the problem:**
1. Name the bucket `test` and click **Create bucket**.
2. Error: **a bucket with the same name already exists**. Someone else owns `test`.
3. Trying `stephane-demo-s3-v6` also failed (taken). The lecturer kept incrementing (v7 ... v12) until one worked.
4. The Account Regional option avoids this loop. You can name it `demo`, and the full name becomes the name plus the account and region suffix.

### 2. Viewing Your Buckets

- The bucket list shows your **general purpose buckets**. **Directory buckets** appear in a separate tab if you use them.
- The list includes buckets from **all AWS regions**, not just the current one (the lecturer's list included Ireland, London, `us-east-1`, Frankfurt, and so on, and he had 33 in total).
- Use the **search box** to filter by name (for example `stephane-demo`).
- S3 has a **global console view**, but **each bucket belongs to one region**. The region is shown in a column.
- Click a bucket name to open it.

### 3. Uploading an Object

1. Open the bucket. It shows **zero objects**.
2. Click **Upload**, then **Add files**, and pick `coffee.jpg` from the course's `s3` folder.
3. The upload page shows the file:
   - Type: **image/jpeg**.
   - Size: about **100 KB**.
   - **Destination:** `s3://<your-bucket>`.
4. Click **Upload**. When it finishes, close the status panel.
5. `coffee.jpg` now appears under **Objects**.

- The `s3://bucket/key` form is the **S3 URI**, which is what the CLI uses.
- Console uploads are fine for small files. For **larger than 5 GB** you need **multipart upload** (the CLI and SDKs handle it automatically).

### 4. The Object Page

Click the object to open its details:

| Section | What it shows |
|---|---|
| **Properties / Overview** | Owner, **region**, last modified, **size**, **type**, **key**, **S3 URI**, **ARN**, ETag, and the **Object URL** |
| **Object URL** | The **public** URL of the object. It is only reachable if the object is **public**. |
| **Open** button | Opens the object in a new tab using a **pre-signed URL** |
| **Permissions / Versions / Metadata** tabs | Covered in later lectures |

### 5. Open vs Object URL: Pre-Signed URL vs Public URL

#### 5.1 What happened

| Action | Result | Why |
|---|---|---|
| Click **Open** | **The image shows** | The console generates a **pre-signed URL** |
| Copy the **Object URL** and open it in the browser | **AccessDenied** | The URL is **public**, and the bucket **blocks public access**, so an anonymous request is denied |

#### 5.2 Comparing the URLs

- Both URLs start the same way (`https://<bucket>.s3.<region>.amazonaws.com/<key>`).
- The **Open** URL continues with a **long query string**. That is the **signature**.

```
Public URL:      https://my-bucket.s3.eu-west-1.amazonaws.com/coffee.jpg
Pre-signed URL:  https://my-bucket.s3.eu-west-1.amazonaws.com/coffee.jpg
                 ?X-Amz-Algorithm=...&X-Amz-Credential=...&X-Amz-Date=...
                 &X-Amz-Expires=...&X-Amz-Signature=...
```

- A pre-signed URL carries a **signature** and the **permissions of the identity that created it**, and it **expires**. Anyone holding it can use it until then (details in the S3 Pre-signed URLs section).

### 6. Folders (Prefixes)

#### 6.1 Create a folder and upload into it

1. In the bucket, click **Create folder** and name it `images`, then **Create folder**.
2. Open `images`, click **Upload**, and add `beach.jpg`.
3. The destination now reads `s3://<bucket>/images/`.
4. Go up one level: you see the `images/` folder, and inside it `beach.jpg`.

- The object's key is **`images/beach.jpg`**. `images/` is just a **prefix**.

#### 6.2 Delete a folder

1. Select the `images/` folder, click **Delete**.
2. The page warns it will delete **everything inside the folder**.
3. Type **`permanently delete`** in the confirmation box, then confirm.

- Deleting a folder deletes **every object under that prefix**.
- With **versioning off**, deletion is **permanent**. With versioning on, a delete only adds a **delete marker**.

---

## Security: Bucket Policy

### TL;DR

- S3 security has **four layers**: **user-based** (IAM policies), **resource-based** (bucket policies, plus ACLs), **encryption**, and **Block Public Access** as a safety net.
- **Bucket policies** are **JSON, bucket-wide, resource-based** policies. They are the **most common** way to secure S3 today.
- Use them to **make a bucket public**, **grant cross-account access**, or **force encryption on upload**.
- **Access rule:** an IAM principal can access an object if **IAM allows it OR the bucket policy allows it, AND there is no explicit deny**.
- **EC2 instances** should use **IAM roles**, not IAM users.
- **Cross-account access** needs a **bucket policy**.
- **Block Public Access** overrides public bucket policies. It can be set at the **bucket** and **account** level.
- **ACLs** (object and bucket) are finer-grained but **rarely used and can be disabled**.

### 1. Four Ways to Secure S3

| Layer | Mechanism | Controls |
|---|---|---|
| **User-based** | **IAM policies** | Which S3 API calls a specific IAM user, group, or role may make |
| **Resource-based** | **Bucket policies** | Bucket-wide rules. Can allow other accounts or the public. |
| **Resource-based** | **Object ACL** / **Bucket ACL** | Finer-grained per-object or per-bucket access. **Can be disabled.** |
| **Encryption** | Encryption keys | Protect the data itself (SSE and client-side, later lectures) |
| **Safety net** | **Block Public Access** | Prevents accidental public exposure (section 7) |

- **Bucket policies are the most common** approach.
- **Object ACLs** are finer-grained but **ACLs are disabled by default** on new buckets (Object Ownership: bucket owner enforced). **Bucket ACLs** are "way less common" and can also be disabled.
- AWS recommends **ACLs disabled** and using **IAM and bucket policies** instead.

### 2. When Can a Principal Access an Object?

An IAM principal (user or role) can perform an API call on an S3 object if:

1. The **IAM permissions allow it**, **OR** the **resource policy (bucket policy) allows it**, **AND**
2. There is **no explicit deny** in any applicable policy.

```
Allow in IAM policy          \
        OR                    >--> and NO explicit Deny anywhere --> ACCESS GRANTED
Allow in bucket policy       /
```

- **Explicit Deny always wins.**
- **Default is deny.** No allow means no access.
- **Same account:** one allow (IAM **or** bucket policy) is enough.
- **Cross-account (extra detail):** **both sides** must allow it. The bucket policy must allow the other account's principal, and that principal's own IAM policy must also allow the S3 action.

### 3. Anatomy of a Bucket Policy

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "PublicRead",
      "Effect": "Allow",
      "Principal": "*",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::example-bucket/*"
    }
  ]
}
```

| Element | Meaning | In this example |
|---|---|---|
| **Resource** | The **buckets and objects** the policy applies to | `arn:aws:s3:::example-bucket/*`: **every object** in `example-bucket` |
| **Effect** | **Allow** or **Deny** | **Allow** |
| **Action** | The **set of API calls** allowed or denied | `s3:GetObject` (retrieve an object) |
| **Principal** | The **account, user, or role** the policy applies to | `*`: **anyone** |
| **Sid** (optional) | A statement ID | `PublicRead` |
| **Condition** (optional) | Extra requirements (extra detail) | Not used here |

- This policy sets **public reads on all objects** in the bucket.
- **`*` in the Resource ARN** means **any object** in the bucket.
- **Resource ARN detail (extra):**
  - `arn:aws:s3:::example-bucket` = **the bucket itself** (for bucket-level actions such as `s3:ListBucket`).
  - `arn:aws:s3:::example-bucket/*` = **the objects** (for object-level actions such as `s3:GetObject`).
- Bucket policies are **limited to 20 KB** (extra detail).
- Written in the **same JSON policy language as IAM**, which is why the lecturer calls it easy to read.

### 4. What Bucket Policies Are Used For

| Use case | How |
|---|---|
| **Grant public access** | `Principal: "*"` with `s3:GetObject`. This is how the bucket is made public in the next lecture. |
| **Force objects to be encrypted at upload** | **Deny** `s3:PutObject` unless the request has the required encryption setting (via a **Condition**) |
| **Grant access to another account** | `Principal` set to the **other account's** ARN (**cross-account access**) |
| **Require HTTPS** (extra) | **Deny** when `aws:SecureTransport` is `false` |

- Force-encryption policy examples (`StringNotEquals` on `s3:x-amz-server-side-encryption`, `Null` on the SSE-C header) are in the S3 Default Encryption section.

### 5. Access Scenarios (Lecture Diagrams)

#### 5.1 Public access: bucket policy

```
Website visitor (internet) --> [S3 bucket + bucket policy: Allow GetObject to *] --> object returned
```

- Attach a **bucket policy that allows public access**.
- Then anyone can read the objects. The hands-on in the next lecture shows this.
- It also needs **Block Public Access turned off** (section 7).

#### 5.2 IAM user in your account: IAM policy

```
IAM user + IAM policy (allow s3 actions) --> S3 bucket
```

- Assign an **IAM policy** to the user.
- Because the policy allows access to the bucket, the user gets in.

#### 5.3 EC2 instance: IAM role

```
EC2 instance + instance role (IAM permissions for S3) --> S3 bucket
```

- **IAM users are not appropriate** for EC2 (you would have to store access keys on the instance).
- Create an **EC2 instance role** with the right permissions and attach it through an **instance profile**.
- The instance gets **temporary credentials** automatically.

#### 5.4 Cross-account: bucket policy

```
IAM user in Account B --> [Bucket policy in Account A: allow that principal] --> S3 bucket (Account A)
```

- To allow **cross-account access**, you **must use a bucket policy**.
- The policy names the **IAM user (or account)** from the other AWS account as the principal.
- Remember (section 2): the other account's IAM user also needs IAM permissions for the S3 actions.

#### 5.5 Summary

| Who needs access | Use |
|---|---|
| **The public** | **Bucket policy** (`Principal: *`) plus Block Public Access off |
| **IAM user in the same account** | **IAM policy** (or bucket policy) |
| **EC2 instance** | **IAM role** |
| **Another AWS account** | **Bucket policy** (naming the other account's principal) |

### 6. Other Principals (Extras)

| Principal type | Example |
|---|---|
| **Everyone** | `"Principal": "*"` |
| **An account** | `"Principal": {"AWS": "arn:aws:iam::123456789012:root"}` |
| **A user or role** | `"Principal": {"AWS": "arn:aws:iam::123456789012:role/MyRole"}` |
| **An AWS service** | `"Principal": {"Service": "cloudfront.amazonaws.com"}` |

- **CloudFront** (later in the course) reads private buckets through a bucket policy that names the CloudFront service principal (OAC).

### 7. Block Public Access

#### 7.1 What it is

- A set of **bucket settings** (the ones left **on** when the bucket was created).
- AWS added them as an **extra layer of security to prevent company data leaks**.
- **Even if a bucket policy makes the bucket public, with Block Public Access on the bucket will never be public.**
- Think of it as **protection against someone writing the wrong bucket policy**.

#### 7.2 Levels

| Level | When to use it |
|---|---|
| **Bucket level** | A specific bucket must never be public |
| **Account level** | **None** of your buckets should ever be public. Set it once for the whole account. |

- **Account-level settings override** bucket-level settings.
- To make a bucket public on purpose, you must **turn off Block Public Access** (account level first, if it is on) and **then** add the public bucket policy.

#### 7.3 The four settings (extra detail)

| Setting | Effect |
|---|---|
| `BlockPublicAcls` | Rejects requests that add public ACLs |
| `IgnorePublicAcls` | Ignores existing public ACLs |
| `BlockPublicPolicy` | Rejects bucket policies that grant public access |
| `RestrictPublicBuckets` | Restricts access to buckets with public policies to AWS services and authorized users |

- The console's single toggle **Block all public access** turns on all four.
- The lecture's rule: if the bucket should never be public, **leave these on**.
- Public buckets cause **data leaks**, so use them only for intended public content.

### 8. Exam-Style Recall

| If the question says... | Think... |
|---|---|
| "Make all objects in a bucket publicly readable" | **Bucket policy** with `s3:GetObject` and `Principal: *` |
| "Grant access to a user in another AWS account" | **Bucket policy** (cross-account) |
| "EC2 instance needs access to S3" | **IAM role** (instance profile) |
| "IAM user in the same account needs S3 access" | **IAM policy** |
| "Force all uploads to be encrypted" | **Bucket policy** with a **Deny** and an encryption condition |
| "Bucket policy makes the bucket public but it is still private" | **Block Public Access** is on |
| "Prevent any bucket in the account from being public" | **Account-level Block Public Access** |
| "Access allowed by IAM, denied by the bucket policy" | **Denied** (explicit deny wins) |
| "Access allowed by IAM, no bucket policy (same account)" | **Allowed** |
| "Most common way to manage S3 access" | **Bucket policies** |
| "Fine-grained per-object permissions (legacy)" | **Object ACLs** (can be disabled) |
| "In a bucket policy, what does `Principal: *` mean?" | **Anyone** |
| "In a bucket policy, what does the `*` in the Resource ARN mean?" | **All objects** in the bucket |
| "Format of a bucket policy" | **JSON** |
| "Make an S3 object readable by anyone via its URL" | **Bucket policy** (`s3:GetObject`, `Principal: *`) plus **Block Public Access off** |
| "Resource ARN for all objects in a bucket" | `arn:aws:s3:::bucket-name/*` |
| "Which action lets users download an object?" | **`s3:GetObject`** |
| "Which action lets users list a bucket?" | **`s3:ListBucket`** (on the bucket ARN, no `/*`) |
| "Tool that helps write a bucket policy" | **AWS Policy Generator** |
| "Safest way to give temporary access to a private object" | **Pre-signed URL** |
| "Block public access across the whole account" | **Account-level Block Public Access** |
| "Principal `*` in a bucket policy" | **Anyone**, including anonymous users |
| "Prevent accidental public exposure" | Keep **Block Public Access** on |

---

## S3 Security: Bucket Policy Hands On

### 1. Why Two Steps?

Two independent controls must both allow public access:

| Control | State at the start | What the demo did |
|---|---|---|
| **Block Public Access** (safety net) | **ON** (blocks everything) | **Turned off** |
| **Bucket policy** (the actual permission) | **None** | **Added** an Allow `GetObject` for `*` |

- **Turning off Block Public Access alone grants nothing.** The bucket policy is what grants access.
- Order: turn off Block Public Access **first**. With `BlockPublicPolicy` on, the console won't even let you save a public bucket policy.

### 2. Step 1: Turn Off Block Public Access

1. Open the bucket, then the **Permissions** tab.
2. Under **Block public access (bucket settings)**, click **Edit**.
3. **Untick "Block all public access"** (this unticks all four sub-settings).
4. **Save changes**, type **confirm** in the warning box, and confirm.

- The lecturer calls this a **dangerous action**: put real company data in a public bucket and you get a **data leak**. Only do this if you **know** you want a public bucket policy.
- After saving, the **Permissions overview** shows that objects **can be public**.
- Note: this alone doesn't make anything public. It only **allows** a public policy or ACL to take effect.

### 3. Step 2: Create the Bucket Policy

#### 3.1 Where to find it

- Same **Permissions** tab, scroll to **Bucket policy**. It shows **no policy**.
- Click **Edit**.
- Two helpers:
  - **Policy examples**: AWS documentation with sample policies for common use cases.
  - **Policy generator**: the **AWS Policy Generator** tool, used in this demo.

#### 3.2 AWS Policy Generator settings

| Field | Value | Why |
|---|---|---|
| **Select Type of Policy** | **S3 Bucket Policy** | |
| **Effect** | **Allow** | |
| **Principal** | `*` | **Anyone** |
| **AWS Service** | **Amazon S3** | |
| **Actions** | **GetObject** | Read objects |
| **Amazon Resource Name (ARN)** | `arn:aws:s3:::<your-bucket>/*` | See section 3.3 |

Steps:
1. Fill in the fields above.
2. Click **Add Statement**.
3. Click **Generate Policy**.
4. **Copy the JSON** it produces.

#### 3.3 The ARN: why `/*`

- Copy the **bucket ARN** from the bucket's **Properties** tab (or from the policy editor, which shows it).
- It looks like `arn:aws:s3:::<your-bucket>`.
- **Append `/*`** to it.

- Without `/*`, the `GetObject` statement matches nothing and **access stays denied**.
- To scope it down, use a prefix: `arn:aws:s3:::my-bucket/images/*`.

#### 3.4 The resulting policy

```json
{
  "Id": "Policy1234567890",
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "Stmt1234567890",
      "Action": ["s3:GetObject"],
      "Effect": "Allow",
      "Resource": "arn:aws:s3:::<your-bucket>/*",
      "Principal": "*"
    }
  ]
}
```

- Paste it into the **Bucket policy** editor.
- The lecturer noticed a **stray space** in the pasted ARN and removed it. A space or typo in the ARN gives an **invalid resource** error or a policy that matches nothing.
- Click **Save changes**.
- The Bucket policy section now shows the policy, and a **Publicly accessible** badge appears on the bucket.

#### 3.5 What the policy means

- It allows reading objects. It does **not** allow listing, uploading, or deleting.
- Anonymous visitors can fetch an object **only if they know its URL**.

### 4. Testing

1. Open the bucket, click `coffee.jpg`, and copy the **Object URL**.
2. Paste it into a browser tab.
3. **Before the policy:** **AccessDenied**. **After:** the **coffee image displays**.

- The lecturer notes **any other object** in the bucket would be public now too.
- The earlier **Open** button (pre-signed URL) worked before the policy, because it carried your credentials.
- Anonymous **listing** the bucket (`https://<bucket>.s3.<region>.amazonaws.com/`) still returns **AccessDenied**, since the policy only allows `GetObject`.

### 5. Troubleshooting

| Symptom | Likely cause |
|---|---|
| Can't save the policy: "**Policy has invalid resource**" | Typo or stray space in the ARN, or missing `arn:aws:s3:::` |
| Can't save the policy: **public policy blocked** | **Block Public Access** is still on (bucket or account level) |
| Policy saved but Object URL still **AccessDenied** | Missing **`/*`** in the Resource, wrong bucket name, or Block Public Access still on |
| Image works for you but not others | You were using a **pre-signed** URL. Test the plain Object URL in a private window. |
| Object still denied | An **explicit deny** elsewhere, or the object is **encrypted with SSE-KMS** and anonymous users can't use the key |
| Object **uploaded by another account** is denied | Object ownership. Keep **ACLs disabled** (bucket owner enforced). |

- Stray spaces or typos in the ARN break the policy.

---

## S3 Website Overview

### TL;DR

- **S3 can host static websites** (HTML, CSS, JavaScript, images) and make them reachable on the internet.
- The **website URL depends on the AWS region**. There are two formats that differ only by a **dash** or a **dot** after `s3-website`. You don't need to memorize which region uses which.
- You enable **static website hosting** on the bucket, and the bucket holds the site's files.
- It **only works if the objects are publicly readable**. A **403 Forbidden** after enabling website hosting means the bucket isn't public.
- Fix for 403: turn off **Block Public Access** and attach a **bucket policy** that allows `s3:GetObject` (previous lecture).
- The next lecture is the hands-on.

### 1. What Is S3 Static Website Hosting?

| Property | Detail |
|---|---|
| **What it hosts** | **Static** content: HTML, CSS, client-side JavaScript, images, and other files |
| **Server-side code?** | **No.** No PHP, Node.js, or database queries. Dynamic behavior must come from client-side JavaScript calling APIs. |
| **Accessible from** | The **internet** |
| **Server management** | None. S3 serves the files. |
| **Scaling** | Automatic, like the rest of S3 |

- Typical contents of the bucket: **HTML files, images**, and other assets.
- Enable the **static website hosting** feature in the bucket's **Properties** tab to make the bucket "compatible with hosting a website".
- Common uses: landing pages, documentation, single-page apps (React, Vue, Angular builds), and a **failover** target (for example a "site is down" page for Route 53 failover).

### 2. Website URL Formats

The URL depends on the **region** where the bucket was created. Two patterns exist:

| Style | Format |
|---|---|
| **Dash** | `http://<bucket-name>.s3-website-<region>.amazonaws.com` |
| **Dot** | `http://<bucket-name>.s3-website.<region>.amazonaws.com` |

Examples (illustrative):

```
http://my-bucket.s3-website-us-west-2.amazonaws.com     (dash style)
http://my-bucket.s3-website.eu-west-1.amazonaws.com     (dot style)
```

- The lecturer: they look very similar, and "it doesn't really matter for you to remember this". The console shows the **exact URL** for your bucket.
- Which style a region uses depends on when the region launched (older regions use the dash, newer regions use the dot).
- This is the **website endpoint**. It is different from the normal **REST endpoint** (`<bucket>.s3.<region>.amazonaws.com`) that you used for the Object URL earlier.

| | **REST endpoint** | **Website endpoint** |
|---|---|---|
| **Format** | `bucket.s3.region.amazonaws.com` | `bucket.s3-website[-.]region.amazonaws.com` |
| **Protocol** | **HTTPS** supported | **HTTP only** |
| **Index and error pages** | No | **Yes** (index document, custom error document, redirects) |
| **Access control** | Pre-signed URLs, bucket policy, IAM, OAC | **Public reads only** |
| **Use for** | API access and file downloads | **Static website** |

### 3. How It Works

```
User --> http://bucket.s3-website-region.amazonaws.com --> [S3 bucket: index.html, images, ...]
                                                              (needs public read access)
```

1. Create a bucket and **upload the site files** (for example `index.html`).
2. **Enable static website hosting** on the bucket and set the **index document** (usually `index.html`). Optionally set an **error document** (for example `error.html`).
3. Make the objects **publicly readable** (section 4).
4. Open the **bucket website endpoint** shown in the console.

### 4. Public Read Access Is Required

- The website **will not work without public reads** on the bucket.
- This is why the **previous lecture** covered **bucket policies**.

**Required for a public website:**

| Requirement | Detail |
|---|---|
| **Block Public Access** | Turn **off** (at least the bucket-policy-related settings) |
| **Bucket policy** | Allow **`s3:GetObject`** to `Principal: *` on `arn:aws:s3:::<bucket>/*` |

#### 4.1 The 403 Forbidden rule

- If you get **403 Forbidden** after enabling website hosting, then **the bucket isn't public**.
- Fix: **attach a bucket policy** that allows public reads (and make sure **Block Public Access** is off).
- This is the lecture's key troubleshooting point, and a likely exam question.

| Error | Likely cause |
|---|---|
| **403 Forbidden** | Bucket or objects **not public** (policy missing, Block Public Access on, or wrong `/*` resource) |
| **404 Not Found** | The **object key doesn't exist**, or no **index document** is set and you requested the root |
| **Browser warns "Not secure"** | Website endpoints are **HTTP only** |

### 5. Beyond the Lecture (Useful Exam Context)

| Topic | Detail |
|---|---|
| **HTTPS** | The S3 website endpoint **doesn't support HTTPS**. Put **CloudFront** in front for HTTPS and a custom domain certificate (ACM). |
| **Private bucket with CloudFront** | CloudFront can serve a **private** bucket with **Origin Access Control (OAC)**, using the REST endpoint. Then the bucket doesn't need to be public. |
| **Custom domain** | Use a **Route 53 Alias record** to the S3 website endpoint. The **bucket name must match the domain name** (for example `www.example.com`). Alias to an **S3 website** is a valid target (but not a plain S3 bucket). |
| **CORS** | If the site's pages load assets from a **different bucket or origin**, enable **CORS** (later lecture). |
| **Redirects** | Website hosting can **redirect all requests** to another host, or apply **routing rules**. |
| **Costs** | Pay for storage, requests, and data transfer out. Static hosting itself has no extra fee. |
| **Not for** | Server-side rendering, databases, or secret handling. Use **EC2, Lambda, or Amplify** for those. |

### 6. Exam-Style Recall

| If the question says... | Think... |
|---|---|
| "S3 website returns 403 Forbidden" | The bucket isn't **public**. Add a **bucket policy** (and turn off Block Public Access). |
| "S3 website needs HTTPS" | Put **CloudFront** in front |
| "Does the S3 website endpoint support HTTPS?" | **No**, HTTP only |
| "Dynamic server-side rendering on S3" | **Not supported** (static only) |
| "Website URL format" | `bucket.s3-website-region.amazonaws.com` or `bucket.s3-website.region.amazonaws.com` (depends on the region) |
| "Point `www.example.com` at an S3 website" | **Route 53 Alias record**, with a bucket named the same as the domain |
| "Serve a private bucket's content publicly without making the bucket public" | **CloudFront with OAC** |
| "Policy needed so website visitors can read objects" | **`s3:GetObject`** for `Principal: *` on `bucket/*` |
| "Where do you enable S3 static website hosting?" | Bucket **Properties**, **Static website hosting** |
| "Required setting for a static website bucket" | An **index document** (and the file must exist) |
| "Default page shown for the root URL" | The **index document** |
| "Website shows 404 on the root" | **Index document is missing** |
| "Custom page for errors" | The **error document** |
| "Serve the site over HTTPS" | **CloudFront** in front of the bucket |
| "Redirect all requests to another host" | Hosting type **Redirect requests for an object** |
| "Files hosted must be..." | **Publicly readable** (for the website endpoint) |

---

## S3 Website Hands On

### 1. Starting Point

- Bucket from the earlier S3 lectures, with:
  - `coffee.jpg` already uploaded.
  - **Block Public Access off** and a **bucket policy** allowing `s3:GetObject` for `*` on `<bucket-arn>/*` (previous hands-on).
- If you removed the public policy or re-enabled Block Public Access after that lecture, **redo those steps first**, or the website will return **403 Forbidden**.

### 2. Upload a Second Image

1. Open the bucket, click **Upload**, **Add files**, and choose `beach.jpg`.
2. **Upload**, then close.
3. The bucket now has **two objects**: `coffee.jpg` and `beach.jpg`.

### 3. Enable Static Website Hosting

#### 3.1 Steps

1. Bucket, **Properties** tab, scroll to the bottom to **Static website hosting**.
2. Click **Edit**.
3. **Static website hosting:** **Enable**.
4. **Hosting type:** **Host a static website**.
5. **Index document:** `index.html`.
6. (Optional) **Error document:** for example `error.html`. The lecture left it empty.
7. **Save changes**.

#### 3.2 Settings explained

| Setting | Value | Notes |
|---|---|---|
| **Hosting type** | **Host a static website** | The other option, **Redirect requests for an object**, sends all traffic to another host name. |
| **Index document** | `index.html` | The **default page (homepage)**. Served for `/` and for any folder path ending in `/`. |
| **Error document** | Optional | Served on errors such as a 404. |
| **Redirection rules** | Optional | JSON routing rules, an advanced option. |

- The index document **name is just a setting**. The file isn't created for you, so you upload it.

### 4. Upload `index.html`

- After saving, the lecturer noticed the **index file was missing** from the bucket.
- Upload `index.html` from the course files: **Upload**, **Add files**, select it, **Upload**, close.

A minimal equivalent (the course file isn't in the transcript, so this is my version):

```html
<html>
  <head><title>My First Website</title></head>
  <body>
    <h1>I love coffee</h1>
    <p>Hello world!</p>
    <img src="coffee.jpg" width="500" />
  </body>
</html>
```

- The page references `coffee.jpg` by a **relative path**, so the image must sit next to `index.html` in the bucket.

### 5. Open the Website

1. Back in **Properties**, scroll to **Static website hosting**.
2. A **Bucket website endpoint** now appears. Copy it.
3. Paste it into a new browser tab.
4. The page shows **"I love coffee. Hello world!"** and the **`coffee.jpg`** image.

**Further checks from the demo:**

| Test | Result |
|---|---|
| **Right-click the image, open in a new tab** | Loads the **public URL** of `coffee.jpg` (the REST-style object URL) |
| **Open `beach.jpg`** (its object URL) | The beach image displays |
| **Swap the image** in `index.html` from coffee to beach | Would show the beach (the lecturer points out `beach.jpg` is available) |

- This confirms: static hosting is on, and the **public bucket policy** lets anyone read every object.

### 6. Troubleshooting

| Symptom | Likely cause |
|---|---|
| **404 on an image** | Wrong file name or path in the HTML (keys are case-sensitive) |
| Old content after an update | Browser cache, or a **CloudFront** cache if you use one |
| **No website endpoint shown** | Static website hosting wasn't saved, or you are in the wrong bucket |

---

## S3 Versioning

### TL;DR

- **Versioning** keeps **multiple versions of the same object (key)** in a bucket. It lets you **update files safely**, for example the static website from the last lecture.
- It is a **bucket-level setting** that you must **enable**.
- Each upload to the same key creates a **new version** (v1, v2, v3, and so on). The previous versions are **kept**, not overwritten.
- **Best practice:** version your buckets. It **protects against unintended deletes** and makes **rollback** easy.
- A normal **delete** adds a **delete marker**. It doesn't remove data, so you can **restore** the object.
- Objects that existed **before** versioning was enabled get the version ID **`null`**.
- **Suspending** versioning **does not delete** existing versions. It is a safe operation.

### 1. What Is S3 Versioning?

- Without versioning, uploading to an existing key **overwrites** the object. The old content is lost.
- With versioning, S3 **stores every version**, and each one has its own **version ID**.

| Without versioning | With versioning |
|---|---|
| Upload `index.html` again | Creates **version 2** of `index.html` (version 1 is kept) |
| Version ID is `null` | Each upload gets a **unique, S3-generated version ID** |
| Delete removes the object | Delete adds a **delete marker** (older versions remain) |

```
Key: index.html
  Version 3  (current / latest)   <- GET returns this one
  Version 2                       <- kept (noncurrent)
  Version 1                       <- kept (noncurrent)
```

- A **GET without a version ID** returns the **current (latest) version**.
- You can GET, copy, or delete a **specific version** by supplying its **version ID**.
- Lecture link to the previous topic: "we've seen how to create a website, but it would be nice to **update it in a safe way**".

### 2. Enabling Versioning

- It's a setting you **enable at the bucket level**.
- Console path: bucket, **Properties**, **Bucket Versioning**, **Edit**, **Enable**. (The demo is in the next lecture.)
- Versioning applies to **all objects in the bucket**, not per prefix.

| Bucket versioning state | Meaning |
|---|---|
| **Unversioned** (default) | Versioning has never been turned on. Objects have version ID `null`. |
| **Enabled** | Every new upload or overwrite creates a **new version** |
| **Suspended** | **No new versions are created**. Existing versions are **kept**. |

- **Once enabled, you can't return to "unversioned".** You can only **suspend**.
- The lecture's example: the bucket "is enabled with versioning", and every upload at the same key adds **version 1, then 2, then 3**.

### 3. Why Version Your Buckets?

| Benefit | How |
|---|---|
| **Protect against unintended deletes** | A delete only adds a **delete marker**. The data is still there, and you can restore it. |
| **Easy rollback** | Go back to a previous version. Lecture example: "go back to what happened **two days ago**". |
| **Safe updates** | Overwriting a file no longer destroys the old one |
| **Audit trail** | You can see the history of changes to each object |
| **Prerequisite for other features** | **Replication** (CRR/SRR) and **S3 Object Lock** require versioning |

### 4. Deletes and Delete Markers

#### 4.1 Delete without a version ID

- In the console, selecting an object and clicking **Delete** (or an API `DELETE` with no version ID) **adds a delete marker**.
- The delete marker becomes the **current version**, so the object **appears deleted**: a GET returns **404 Not Found**, and it disappears from the normal list.
- **All older versions still exist.**
- The lecture's wording: "if you delete a file version, actually you just add a delete marker". More precisely, **deleting the object** adds the marker.

```
Before delete:   v3 (current), v2, v1
After delete:    DELETE MARKER (current), v3, v2, v1
```

**Restore a deleted object:** **delete the delete marker** (permanently, by its version ID). The previous version becomes current again.

#### 4.2 Delete with a specific version ID

- Deleting **a specific version ID** removes that version **permanently** and **can't be undone**.
- Deleting a **delete marker** by its version ID **restores** the object.

| Action | Result |
|---|---|
| **Delete** (no version ID) | Adds a **delete marker**. Reversible. |
| **Delete a specific version** | **Permanent** removal of that version |
| **Delete the delete marker** | Object is **restored** |

- **MFA Delete** (optional) requires an **MFA code** to permanently delete versions or change the versioning state. It can only be turned on by the **root user**, through the CLI or API. It isn't in the lecture.

### 5. Rolling Back to a Previous Version

Two common ways to "roll back" (extras beyond the lecture):

| Method | How | Effect |
|---|---|---|
| **Delete the latest version** | Permanently delete the bad current version by its ID | The previous version becomes current again. The bad version is gone. |
| **Copy the old version over the key** | Copy an older version onto the same key | Creates a **new** latest version with the old content. **History is kept.** |

- The second method is safer, because nothing is lost.

### 6. Notes Highlighted in the Lecture

1. **Objects uploaded before versioning was enabled** have the version ID **`null`**.
   - They stay as the `null` version. They aren't deleted or changed.
   - After you enable versioning, a new upload creates a **real version ID**, and the old `null` object is kept as an older version.
2. **Suspending versioning doesn't delete previous versions.**
   - It is a **safe** operation. Nothing is lost.
   - All existing versions **stay** in the bucket, and you keep paying for their storage.

**What suspension does (extra detail):**
- New uploads get the version ID **`null`**.
- An upload while suspended **overwrites the existing `null` version**, but it doesn't touch versions that have real IDs.
- Existing versions with real version IDs are still retrievable.

### 7. Costs and Management (Extras)

| Topic | Detail |
|---|---|
| **Storage cost** | **Every version is billed** as a full object. Heavily updated large objects add up. |
| **Lifecycle rules** | Use them to **expire noncurrent versions** after N days, or move them to cheaper classes (for example Glacier). |
| **Delete markers** | **Expired object delete markers** can be cleaned up by lifecycle rules. |
| **Listing versions** | Console: turn on **Show versions**. CLI: `aws s3api list-object-versions`. |
| **Replication** | Needs versioning on **both** the source and destination buckets |
| **Static website** | A new `index.html` upload creates a new version, and the site serves the latest one right away |

### 8. Exam-Style Recall

| If the question says... | Think... |
|---|---|
| "Protect against accidental deletion of objects" | **Enable versioning** (and optionally **MFA Delete**) |
| "Roll back to a previous version of a file" | **S3 versioning** |
| "What happens when you delete an object in a versioned bucket?" | A **delete marker** is added |
| "Restore a deleted object in a versioned bucket" | **Delete the delete marker** |
| "Permanently delete a version" | **Delete it by its version ID** |
| "Version ID of objects uploaded before versioning was enabled" | **`null`** |
| "What happens to existing versions when versioning is suspended?" | They are **kept**, nothing is deleted |
| "Can you turn versioning off completely after enabling it?" | **No**, only **suspend** it |
| "Versioning scope" | **Bucket level** |
| "Cost impact of versioning" | **Each version is stored and billed** |
| "Reduce the cost of old versions" | **Lifecycle rule** on **noncurrent versions** |
| "Which features require versioning?" | **Replication** and **Object Lock** |
| "A GET without a version ID returns..." | The **current (latest) version** |
| "Undo an overwrite of an S3 object" | **Versioning**, then delete the latest version or copy the old one back |
| "Console toggle to see versions and delete markers" | **Show versions** |
| "GET on an object whose latest version is a delete marker" | **404 Not Found** |
| "Update a static website without losing the old page" | **Versioning** plus re-upload |
| "Why is storage cost rising in a versioned bucket?" | **All versions are stored** (add lifecycle rules) |
| "Console prompt `permanently delete`" | A delete of a **specific version** or **delete marker** |

---

## S3 Versioning - Hands On

### 1. Enable Versioning

1. Open the bucket, **Properties** tab.
2. Find **Bucket Versioning**, click **Edit**.
3. Select **Enable**, then **Save changes**.

- From now on, **overwriting a file adds a new version** instead of replacing it.

### 2. Update the Website (Create a New Version)

#### 2.1 Steps

1. Open the website endpoint (**Properties**, **Static website hosting**). It shows "I love coffee".
2. Edit your local `index.html`: change the text to **"I really love coffee"**, and save it.
3. In the bucket, **Upload**, **Add files**, select the **same `index.html`**, then **Upload**.
4. Refresh the website. It now shows **"I REALLY love coffee"**.

- The new upload used the **same key** (`index.html`), so S3 stored it as a **new version** and made it the **current** one.
- The site always serves the **current version**, so the update appears immediately (subject to browser caching).

#### 2.2 What happened behind the scenes

Turn on the **Show versions** toggle in the object list:

| Object | Versions | Version ID |
|---|---|---|
| `beach.jpg` | 1 | **`null`** (uploaded before versioning) |
| `coffee.jpg` | 1 | **`null`** (uploaded before versioning) |
| `index.html` | **2** | The original is **`null`**. The new upload has a **generated version ID**. |

- Objects uploaded **before** versioning keep the **`null`** version ID.
- Each upload **after** enabling versioning gets a **unique version ID**.
- You only see versions when **Show versions** is on. Otherwise the console shows just the current objects.

### 3. Roll Back a Version (Delete a Specific Version ID)

Goal: return the site from "I really love coffee" to "I love coffee".

1. Make sure **Show versions** is **on**.
2. Select the **newest `index.html`** (the one with the real version ID).
3. Click **Delete**.
4. Because a **specific version ID** is selected, the console says this is a **permanent delete**.
5. Type **`permanently delete`** in the box, then click **Delete objects**.
6. Refresh the website. It shows **"I love coffee"** again.

- Deleting a **specific version** is **permanent and cannot be undone**. The lecturer calls it **destructive**.
- The **previous version** (the `null` one) automatically **becomes the current version**.

### 4. Delete Without a Version ID (Delete Marker)

1. Turn **Show versions** **off**.
2. Select `coffee.jpg`, then click **Delete**.
3. This time the box asks you to type **`delete`**, not `permanently delete`.
4. Confirm.

**What you see:**
- With **Show versions off**: `coffee.jpg` **disappears** from the list. It looks deleted.
- With **Show versions on**: `coffee.jpg` now has a **delete marker** with its own version ID, **on top** of the real `coffee.jpg` version.
- The **underlying object still exists**. The delete marker just sits above it as the **current version**.

```
Before:  coffee.jpg (null)
After:   DELETE MARKER (current, new version ID)
         coffee.jpg (null)           <- still stored, but hidden
```

**Effect on the website:**
- Force-refresh the page (**Cmd+Shift+R** on Mac, **Ctrl+Shift+R** on Windows). The **coffee image is gone**.
- Opening the image URL directly gives **404 Not Found**.

### 5. Restore the Object (Delete the Delete Marker)

1. Turn **Show versions** **on**.
2. Select the **delete marker** on `coffee.jpg`.
3. Click **Delete**, type **`permanently delete`**, and confirm.
4. Refresh the website. The **coffee image is back**.

- Deleting the delete marker **restores the previous version** as the current one.

### 6. Troubleshooting

| Symptom | Likely cause |
|---|---|
| Website still shows the **old text** after uploading | **Browser cache.** Force-refresh. Also check you uploaded to the **same key** and the right bucket. |
| New upload didn't create a version | Versioning is **off or suspended** (it would overwrite the `null` version) |
| Can't see old versions in the console | **Show versions** is **off** |
| Image 404 after a delete | A **delete marker** is the current version. Delete the marker to restore. |
| Can't delete the bucket | It must be **empty of all versions and delete markers**. Use **Empty bucket** or a lifecycle rule. |

---

## S3 Replication

### TL;DR

- S3 replication **asynchronously copies objects** from a **source bucket** to a **destination bucket**. There are two flavors:
  - **CRR (Cross-Region Replication):** source and destination are in **different regions**.
  - **SRR (Same-Region Replication):** source and destination are in the **same region**.
- **Versioning must be enabled on both the source and the destination buckets.**
- The buckets can be in **different AWS accounts**.
- Copying is **asynchronous**, in the background.
- S3 needs an **IAM role** with permission to **read from the source and write to the destination**.
- **CRR use cases:** compliance, lower-latency access to data, and cross-account replication.
- **SRR use cases:** aggregating logs from multiple buckets, and live replication between production and test accounts.

### 1. What Is S3 Replication?

- You set up a **replication configuration** on the source bucket. S3 then automatically copies matching objects to the target bucket.
- The lecture's picture: a bucket in one region, a target bucket in another, and **asynchronous replication** between them.

```
[Source bucket, region A]  --- asynchronous replication --->  [Destination bucket, region B (CRR)
        (versioning ON)           (IAM role used by S3)                or region A (SRR)]
                                                                       (versioning ON)
```

| Flavor | Regions | Typical goal |
|---|---|---|
| **CRR** | **Different** | Compliance, latency, DR, cross-account |
| **SRR** | **Same** | Log aggregation, prod-to-test copies |

### 2. Requirements

| Requirement | Detail |
|---|---|
| **Versioning** | **Enabled on both** source and destination buckets |
| **Regions** | **Different** for CRR. **Same** for SRR. |
| **Accounts** | Source and destination **can be in different AWS accounts** |
| **IAM permissions** | An **IAM role** that S3 assumes. It needs permission to **read from the source** and **write to the destination**. |
| **Replication rule** | Configured on the source bucket. It can cover **the whole bucket** or be filtered by **prefix or tags**. |

- **Asynchronous** means the source write succeeds first, and the copy happens **after**. The replica is **eventually consistent**, not instant.
- The console creates the IAM role for you when you set up the rule.
- **Cross-account:** the destination bucket's **bucket policy** must allow the replication role to write. Without it, replication fails.

### 3. Use Cases

#### 3.1 CRR (cross-region)

| Use case | Why |
|---|---|
| **Compliance** | Rules that require a copy of data in **another geographic region** |
| **Lower-latency access** | Keep a copy **closer to users** in another region |
| **Cross-account replication** | Copy data to a **separate account** (for example a backup or security account) |
| **Disaster recovery** | Survive the loss of a whole region (extra) |

#### 3.2 SRR (same-region)

| Use case | Why |
|---|---|
| **Aggregate logs** | Collect logs from **multiple S3 buckets** into **one bucket** |
| **Live replication between production and test accounts** | Give a **test environment** a continuously updated copy of production data |
| **Data sovereignty** (extra) | Keep a copy in the same region but a different account or owner |

### 4. Behaviors Worth Knowing (Beyond the Lecture)

| Topic | Detail |
|---|---|
| **Filtering** | A rule can target a **prefix** and/or **tags**. |
| **Storage class** | The destination can use a **different storage class** (for example Glacier) to save cost. |
| **Encryption** | SSE-S3 objects replicate. **SSE-KMS** objects need extra setup (a KMS key for the destination and role permissions). |
| **Replication Time Control (RTC)** | Optional feature with an SLA: **99.9% of objects within 15 minutes**, with metrics and notifications. (The S3 features page also quotes 99.99% as the typical result.) |
| **Lifecycle actions** | Lifecycle transitions and expirations are **not replicated**. Configure them on each bucket. |
| **Same-account vs cross-account ownership** | In cross-account setups, you can change **object ownership** to the destination bucket owner. |

### 5. Exam-Style Recall

| If the question says... | Think... |
|---|---|
| "Replicate S3 objects to another region" | **CRR** |
| "Replicate objects within the same region" | **SRR** |
| "What must be enabled before configuring replication?" | **Versioning** on **both** buckets |
| "Is S3 replication synchronous?" | **No**, **asynchronous** |
| "What lets S3 copy objects between buckets?" | An **IAM role** with read and write permissions |
| "Replicate between two AWS accounts" | Supported. Needs a **bucket policy** on the destination. |
| "Aggregate logs from several buckets into one" | **SRR** |
| "Keep a live copy of production data in a test account" | **SRR** |
| "Lower latency for users in another region" | **CRR** |
| "Compliance requires data in another region" | **CRR** |
| "Existing objects aren't in the destination" | Use **S3 Batch Replication** |
| "Replicate within 15 minutes with an SLA" | **S3 Replication Time Control (RTC)** |

---

## S3 Replication Notes

### TL;DR

- After you enable replication, **only new objects are replicated**. Existing objects are not copied automatically.
- To copy **existing objects** and objects that **failed replication**, use **S3 Batch Replication**.
- **Delete markers** can be replicated from source to target. This is an **optional setting**.
- A **delete by version ID** (a permanent delete) is **not replicated**. This protects against **malicious deletes** spreading between buckets.
- **No chaining:** if bucket 1 replicates to bucket 2, and bucket 2 replicates to bucket 3, objects from bucket 1 do **not** reach bucket 3.

### 1. Only New Objects Are Replicated

- Replication applies to objects **created after the rule is enabled**.
- Objects that were already in the source bucket are **not** copied by default.

| Object | Replicated automatically? |
|---|---|
| Uploaded **after** the rule is enabled | **Yes** |
| Already in the bucket **before** the rule | **No** |

### 2. S3 Batch Replication

- A feature for objects that normal replication skipped.
- It replicates:
  - **Existing objects** that were in the source bucket before the rule.
  - Objects that **failed replication** earlier.
- It runs as a **one-time job** that you start. It isn't continuous.
- Console: **Create replication rule**, then choose to **replicate existing objects**. Or create a **Batch Operations** job.
- Typical use: a new rule on an old bucket, or retrying objects after fixing a permissions problem.

### 3. Delete Behavior

| Operation on the source | Replicated to the target? |
|---|---|
| **Delete without a version ID** (adds a **delete marker**) | **Optional.** You enable **delete marker replication** on the rule. |
| **Delete with a version ID** (a **permanent delete**) | **No, never** |

- **Why version-ID deletes aren't replicated:** to **avoid malicious deletes** spreading from one bucket to the other. A bad actor, or a mistake, can't permanently wipe the replica by deleting in the source.
- If delete markers are replicated, the target object **appears deleted** too (a GET returns 404), but older versions remain, so it is **recoverable**.
- If delete marker replication is **off** (the default for the console's basic rule), deleting in the source leaves the target object **untouched**.
- **Not replicated either (extra):** lifecycle actions (transitions and expirations). Configure lifecycle on each bucket separately.

### 4. No Chaining of Replication

```
Bucket 1 --replication--> Bucket 2 --replication--> Bucket 3

Objects written to Bucket 1:   copied to Bucket 2   (yes)
                               copied to Bucket 3   (NO)
Objects written to Bucket 2:   copied to Bucket 3   (yes)
```

- **Replicas aren't re-replicated.** Only objects **written directly** to a bucket go through that bucket's rules.
- To get data into bucket 3 as well, add a **second rule from bucket 1 to bucket 3**. One source can replicate to **multiple destinations**.
- Extra: **bidirectional (two-way) replication** between two buckets is possible, and S3 doesn't loop, because replicas aren't re-replicated.

### 5. Exam-Style Recall

| If the question says... | Think... |
|---|---|
| "Replicate objects that existed before the replication rule" | **S3 Batch Replication** |
| "Retry objects that failed to replicate" | **S3 Batch Replication** |
| "Are existing objects replicated when you enable a rule?" | **No**, new objects only |
| "Does a delete in the source delete the object in the target?" | Only if **delete marker replication** is on, and never for **version ID deletes** |
| "Why aren't permanent deletes replicated?" | To **avoid malicious deletes** |
| "Bucket 1 to 2 to 3: does an object from 1 reach 3?" | **No**, there is **no chaining** |
| "Get the same objects into three buckets" | **Multiple rules** from the one source |
| "Replication copies delete markers by default" | **No**, it is an **optional** setting |
| "After enabling replication, which objects are copied?" | **New objects only** |
| "Delete markers aren't appearing in the destination" | Enable **delete marker replication** |
| "Delete a specific version in the source: what happens in the target?" | **Not replicated** (prevents malicious deletes) |
| "What must be enabled on source and destination?" | **Versioning** |
| "How does S3 get permission to copy the objects?" | An **IAM role** (created by the console) |
| "Version ID of a replicated object" | **Same** as the source |
| "Replicate to a bucket in another account" | Supported, with a **destination bucket policy** |
| "Where do you configure replication?" | Source bucket, **Management**, **Replication rules** |
| "Replicate only objects under a prefix" | A rule **filter** (prefix and/or tags) |

---

## S3 Replication - Hands On

### 1. Create the Two Buckets

| | **Origin (source) bucket** | **Replica (destination) bucket** |
|---|---|---|
| **Name** | `s3-<name>-bucket-origin-v2` | `s3-<name>-bucket-replica-v2` |
| **Region** | `eu-west-1` (Ireland) | `us-east-1` (N. Virginia) |
| **Versioning** | **Enabled** | **Enabled** |
| **Other settings** | Defaults | Defaults |

- Create each bucket separately (the lecturer used two browser tabs). **Versioning is required on both**, because replication only works with versioning.
- Bucket names must be unique. Use your own names (or the Account Regional namespace).
- Enable versioning when you create the bucket (the **Bucket Versioning** section of the create page), or later in **Properties**.

### 2. Upload a File Before Setting Up Replication

- In the **origin** bucket, upload `beach.jpg`.
- Nothing replicates yet, because no rule exists. The replica bucket stays **empty**.
- This sets up the "existing object" case shown later.

### 3. Create the Replication Rule

#### 3.1 Steps

1. Origin bucket, **Management** tab.
2. Scroll to **Replication rules** (currently **0**).
3. Click **Create replication rule**.
4. Fill in the settings (section 3.2).
5. **Create rule** (or **Save**).

#### 3.2 Settings used

| Setting | Demo value | Notes |
|---|---|---|
| **Rule name** | `DemoReplicationRule` | |
| **Status** | **Enabled** | |
| **Source bucket** | The origin bucket (default) | Source region is shown |
| **Rule scope** | **Apply to all objects in the bucket** | The alternative is a **filter** by **prefix** and/or **tags** |
| **Destination** | **Choose a bucket in this account** | The other option is a bucket in **another account** |
| **Bucket name** | The replica bucket | Type or paste the exact name |
| **Destination region** | Detected as **`us-east-1`** | The console shows **Cross-Region Replication** when regions differ |
| **IAM role** | **Create new role** | S3 assumes this role to read from the source and write to the destination |
| **Additional options** | Left at defaults | Encryption, replica storage class, **RTC**, metrics, **delete marker replication** (see section 6) |

- **CRR vs SRR is detected from the buckets' regions.** You don't pick the type.
- If the destination bucket **doesn't have versioning**, the console warns you and offers to enable it.

#### 3.3 The "replicate existing objects?" prompt

After saving, the console asks: **Replicate existing objects?**

| Choice | What happens |
|---|---|
| **No, do not replicate existing objects** | Only objects uploaded **from now on** are replicated. **Chosen in the demo.** |
| **Yes, replicate existing objects** | Creates an **S3 Batch Operations** job that copies the **existing** objects (and can retry failed ones) |

- The lecturer's point: when you enable replication, it **only replicates new uploads**.
- Replicating existing objects is **separate from the replication rule itself**, done with a Batch Operations job (**S3 Batch Replication**).
- Batch Operations jobs are billed separately and need their own IAM role (the console can create it).

### 4. Test: New Uploads Replicate

1. Check the **replica bucket**: still **empty**. `beach.jpg` was **not** replicated (it existed before the rule).
2. In the **origin** bucket, upload `coffee.jpg`.
3. Turn **Show versions** on in the origin bucket. `coffee.jpg` has a **version ID** (for example `GBk...`).
4. Go to the **replica** bucket and **refresh**. After about **5-10 seconds**, `coffee.jpg` appears.
5. Turn **Show versions** on in the replica bucket. The version ID is **the same** as in the origin bucket.

**Takeaways:**
- **Version IDs are preserved** in the replica.
- The replica object also carries the metadata and tags of the source object.

### 5. Test: Existing Objects Don't Replicate

- `beach.jpg` was already in the origin bucket **before** the rule, so it **was not replicated**.
- To replicate it without Batch Operations: **upload a new version** of `beach.jpg` to the origin bucket.
- Result: the new upload shows a **new version ID** (for example `DK2...`) in the origin bucket, and it **replicates** to the replica bucket.
- Only the **new version** replicates. The older pre-rule version of `beach.jpg` still isn't in the replica.

### 6. Delete Marker Replication

#### 6.1 Setting

1. Origin bucket, **Management**, select the rule, **Edit rule**.
2. Scroll to **Additional replication options**.
3. Check **Delete marker replication**.
4. **Save**.

#### 6.2 Test: replicated delete marker

1. In the **origin** bucket, select `coffee.jpg` and **Delete** (type `delete`).
2. Because the bucket is **versioned**, this **adds a delete marker**.
3. Wait a few seconds and check the **replica** bucket:
   - With **Show versions off**: `coffee.jpg` is **gone** from the list.
   - With **Show versions on**: the **delete marker** is there, above the old `coffee.jpg` version.
4. The same view is true in the origin bucket.

#### 6.3 Test: permanent delete is not replicated

1. In the **origin** bucket, turn **Show versions** on.
2. Select a **specific version ID** of an object (for example `beach.jpg`) and **Delete** (type `permanently delete`).
3. That version is **permanently removed** from the origin bucket.
4. Check the **replica** bucket: the same version is **still there**.

### 7. Troubleshooting

| Symptom | Likely cause |
|---|---|
| Object not showing in the replica after a minute | Replication is **asynchronous**. Refresh, and check the object's **replication status** in its Properties (PENDING, COMPLETED, FAILED). |
| Replication status **FAILED** | Missing **IAM** permissions, a missing **destination bucket policy** (cross-account), or **SSE-KMS** setup missing |
| Can't create the rule | **Versioning isn't enabled** on the source or destination |
| Object in the replica shows status **REPLICA** | Normal. That is how replicated objects are labelled. |

---

## S3 Storage Classes Overview

### TL;DR

- You choose a **storage class** per object at upload. You can **change it manually later**, or let **S3 Lifecycle rules** move objects between classes automatically.
- **Durability is the same for every class: 11 nines (99.999999999%)**. **Availability and cost differ** by class.
- The 7 classes from the lecture: **Standard, Standard-IA, One Zone-IA, Glacier Instant Retrieval, Glacier Flexible Retrieval, Glacier Deep Archive, Intelligent-Tiering**.
- Rough ladder: **Standard** (hot, most expensive to store), then **IA** (cheaper to store, retrieval fee), then **Glacier classes** (archive, cheapest to store, retrieval fee and time), with **Deep Archive** the cheapest.
- **One Zone-IA** stores data in **one AZ only**. If the AZ is destroyed, the data is lost.
- **Glacier** retrieval time: **Instant** is milliseconds, **Flexible** is minutes to 12 hours, **Deep Archive** is 12 to 48 hours.
- **Intelligent-Tiering** moves objects between tiers automatically, with **no retrieval charges** but a small **monitoring and auto-tiering fee**.
- The lecturer says the comparison tables are **for understanding, not memorizing**. You must know the **names, use cases, and key traits**.

### 1. The Storage Classes

| Class | One-line idea |
|---|---|
| **S3 Standard (General Purpose)** | Frequently accessed data. The default. |
| **S3 Standard-Infrequent Access (Standard-IA)** | Less frequent access, but rapid when needed. Cheaper storage, retrieval fee. |
| **S3 One Zone-Infrequent Access (One Zone-IA)** | Same as IA, but in **one AZ**, so cheaper and less resilient |
| **S3 Glacier Instant Retrieval** | Archive with **millisecond** retrieval |
| **S3 Glacier Flexible Retrieval** | Archive where you can wait **minutes to hours** |
| **S3 Glacier Deep Archive** | **Long-term** archive, the **lowest cost**, retrieval in **hours** |
| **S3 Intelligent-Tiering** | **Automatic** movement between tiers based on usage |

- When you create an object you **pick its class**. You can later **change the class manually**, or use a **Lifecycle configuration** to transition objects automatically (covered in a later lecture).
- You must know all of these for the exam.

### 2. Durability vs Availability

| Term | Meaning | Value |
|---|---|---|
| **Durability** | The chance your data is **not lost** | **11 nines (99.999999999%)**, the **same for all classes** |
| **Availability** | How **readily the service is reachable** to serve requests | **Varies by class** |

- **Durability example from the lecture:** store **10 million objects** and you can expect to lose **one object every 10,000 years**.
- **Availability example:** **Standard is 99.99%**, which is about **53 minutes of unavailability per year**. During that time you may get **errors**, so **build retry logic** into your applications.
- Durability is about **losing data**. Availability is about **being able to reach it**.

### 3. S3 Standard (General Purpose)

| Property | Detail |
|---|---|
| **Availability** | **99.99%** |
| **Use for** | **Frequently accessed data** |
| **Performance** | **Low latency, high throughput** |
| **Resilience** | Data is stored across **at least 3 AZs**. It can **sustain 2 concurrent facility failures**. |
| **Retrieval fee** | None |
| **Minimum duration / size** | None |
| **Use cases** | **Big data analytics, mobile and gaming applications, content distribution** |

- This is the **default** class when you don't choose one.

### 4. Infrequent Access Classes

#### 4.1 S3 Standard-IA

| Property | Detail |
|---|---|
| **Use for** | Data **less frequently accessed**, but needing **rapid access** when requested |
| **Cost** | **Lower storage cost** than Standard, **plus a retrieval cost** |
| **Availability** | **99.9%** (a bit lower than Standard) |
| **Resilience** | Multiple AZs |
| **Use cases** | **Disaster recovery, backups** |
| **Minimums (extra)** | **30 days** minimum storage, and **128 KB** minimum billable object size |

#### 4.2 S3 One Zone-IA

| Property | Detail |
|---|---|
| **Durability** | **11 nines, but within a single AZ only** |
| **Risk** | Data is **lost if that AZ is destroyed** |
| **Availability** | **99.5%** (lower again) |
| **Cost** | Cheaper than Standard-IA |
| **Use cases** | A **secondary copy of backups** (for example of on-premises data), or **data you can recreate** |
| **Minimums (extra)** | **30 days** and **128 KB**, same as Standard-IA |

- The lecturer's slip: "as well as durability, it's even lower, so it's 99.5% availability". He means **availability**. Durability is still stated as 11 nines, but with the single-AZ caveat.

### 5. The Glacier Classes

- "Glacier, as the name says, gets very cold": **low-cost object storage for archiving and backup**.
- Pricing: you pay for **storage** plus a **retrieval cost**. Retrieval cost and time depend on the class and option.

#### 5.1 Glacier Instant Retrieval

| Property | Detail |
|---|---|
| **Retrieval time** | **Milliseconds** |
| **Best for** | Data accessed about **once a quarter** |
| **Minimum storage duration** | **90 days** |
| **Idea** | Backup/archive that you may still need **immediately** |

#### 5.2 Glacier Flexible Retrieval

- Formerly just "**S3 Glacier**". It was renamed when more tiers were added.
- Three retrieval options:

| Option | Retrieval time | Cost |
|---|---|---|
| **Expedited** | **1 to 5 minutes** | Highest |
| **Standard** | **3 to 5 hours** | Medium |
| **Bulk** | **5 to 12 hours** | **Free** (per the lecture) |

- **Minimum storage duration: 90 days.**

#### 5.3 Glacier Deep Archive

| Property | Detail |
|---|---|
| **Use for** | **Long-term storage** (compliance, rarely read archives) |
| **Cost** | **Lowest** of all classes |
| **Retrieval options** | **Standard: 12 hours**, **Bulk: 48 hours** |
| **Minimum storage duration** | **180 days** |

- **Memory aid from the lecture:** **Instant** means you get data instantly. **Flexible** means you are willing to wait up to about **12 hours**. **Deep Archive** means you are willing to wait **a lot longer** for the lowest price.
- **Restoring from Flexible or Deep Archive** needs a **restore request**. The object is temporarily made readable, and you can't read it directly (extra).
- **Availability (extra):** Glacier Instant Retrieval is **99.9%**. Flexible Retrieval and Deep Archive are **99.99%** (once restored).

### 6. S3 Intelligent-Tiering

#### 6.1 What it does

- **Moves objects between access tiers automatically** based on **usage patterns**, so you can "sit back and relax while S3 moves objects for you".

| Fees | Detail |
|---|---|
| **Monitoring fee** | **Small monthly** fee per object |
| **Auto-tiering fee** | Small fee for moving objects |
| **Retrieval charges** | **None** |

#### 6.2 The tiers

| Tier | Type | Objects move here when not accessed for... |
|---|---|---|
| **Frequent Access** | **Automatic**, the default tier | New objects start here |
| **Infrequent Access** | **Automatic** | **30 days** |
| **Archive Instant Access** | **Automatic** | **90 days** |
| **Archive Access** | **Optional** (you enable it) | Configurable: **90 days to 700+ days** |
| **Deep Archive Access** | **Optional** (you enable it) | Configurable: **180 days to 700+ days** |

- When an object is **accessed again**, it moves back to the **Frequent Access** tier.
- **Extras:**
  - Objects **smaller than 128 KB** aren't monitored or auto-tiered (they stay in the Frequent tier).
  - Intelligent-Tiering has **no minimum storage duration** and no retrieval fee.
  - Best for **unknown or changing access patterns**.

### 7. Comparison Table

The lecturer says **you don't need to memorize the numbers**, just understand how the classes relate. Values below match the lecture, with a few extras.

| Class | Durability | Availability | AZs | Min storage duration | Retrieval fee | Retrieval time |
|---|---|---|---|---|---|---|
| **Standard** | 11 nines | **99.99%** | ≥3 | None | None | Milliseconds |
| **Standard-IA** | 11 nines | **99.9%** | ≥3 | 30 days | Yes | Milliseconds |
| **One Zone-IA** | 11 nines | **99.5%** | **1** | 30 days | Yes | Milliseconds |
| **Glacier Instant Retrieval** | 11 nines | 99.9% | ≥3 | **90 days** | Yes | **Milliseconds** |
| **Glacier Flexible Retrieval** | 11 nines | 99.99% | ≥3 | **90 days** | Yes | **1 min to 12 hours** |
| **Glacier Deep Archive** | 11 nines | 99.99% | ≥3 | **180 days** | Yes | **12 to 48 hours** |
| **Intelligent-Tiering** | 11 nines | 99.9% | ≥3 | None | **None** (monitoring fee instead) | Milliseconds (frequent tiers) |

- **Pricing (lecture):** it shows a table of per-GB prices in `us-east-1`. The pattern is that **storage price falls** as you move from Standard to Deep Archive, while **retrieval fees and minimum durations grow**. Check the current S3 pricing page for numbers.

### 8. Choosing a Class

| Situation | Class |
|---|---|
| **Frequently accessed**, low latency | **Standard** |
| **Infrequently accessed**, needs rapid access, important data | **Standard-IA** |
| **Secondary backup copy** or **re-creatable data** | **One Zone-IA** |
| **Archive, accessed rarely, but needs milliseconds** (for example once a quarter) | **Glacier Instant Retrieval** |
| **Archive, can wait minutes to hours** | **Glacier Flexible Retrieval** |
| **Long-term archive, lowest cost, can wait up to 48 hours** | **Glacier Deep Archive** |
| **Unknown or changing access patterns** | **Intelligent-Tiering** |

### 9. Moving Between Classes

| Method | Detail |
|---|---|
| **Choose at upload** | Set the storage class when creating the object |
| **Change manually** | Edit the object's storage class (this **copies** the object to the new class) |
| **Lifecycle configuration** | Rules that **automatically transition** objects (for example Standard to Standard-IA after 30 days, then Glacier after 90 days) or **expire** them |

- Lifecycle rules are the topic of an upcoming lecture.
- **Transition order:** you can move **down** the ladder (hot to cold). Moving back up needs a **restore or copy**.

### 10. Exam-Style Recall

| If the question says... | Think... |
|---|---|
| "Frequently accessed data, low latency, high throughput" | **S3 Standard** |
| "Infrequently accessed, but rapid access when needed" | **S3 Standard-IA** |
| "Secondary backup copy, data can be recreated, lowest IA cost" | **S3 One Zone-IA** |
| "Which class stores data in only one AZ?" | **One Zone-IA** |
| "Archive, retrieval in milliseconds" | **Glacier Instant Retrieval** |
| "Archive, expedited retrieval in 1-5 minutes" | **Glacier Flexible Retrieval** |
| "Free bulk retrieval, 5-12 hours" | **Glacier Flexible Retrieval** (Bulk) |
| "Lowest-cost storage, can wait 12-48 hours" | **Glacier Deep Archive** |
| "Minimum storage duration of 180 days" | **Glacier Deep Archive** |
| "Minimum storage duration of 90 days" | **Glacier Instant** or **Flexible Retrieval** |
| "Unknown or unpredictable access pattern, no retrieval fees" | **S3 Intelligent-Tiering** |
| "Durability of S3 classes" | **11 nines, all the same** |
| "Availability of S3 Standard" | **99.99%** |
| "Automatically transition objects to cheaper classes over time" | **S3 Lifecycle rules** |
| "Store for 7 years for compliance at lowest cost" | **Glacier Deep Archive** |
| "Backup in DR that is accessed rarely, but rapidly when needed" | **Standard-IA** |
| "Automatically move objects to cheaper storage over time" | **S3 Lifecycle rule** (transition actions) |
| "Where do you configure lifecycle rules?" | Bucket **Management** tab |
| "Change an object's storage class manually" | Edit **storage class** in the object's **Properties** (it **copies** the object) |
| "Deprecated storage class" | **Reduced Redundancy** |
| "Delete objects after 365 days automatically" | Lifecycle **expiration** action |
| "Move old versions to Glacier in a versioned bucket" | Lifecycle on **noncurrent versions** |
| "Minimum age to transition to Standard-IA" | **30 days** |
| "Clean up incomplete multipart uploads" | Lifecycle rule action for **incomplete multipart uploads** |
| "Don't know the access pattern, want automatic tiering" | **Intelligent-Tiering** |
| "Default storage class for new objects" | **Standard** |

---

## S3 Storage Classes Hands On

### 1. Create the Bucket and Upload an Object

1. S3 console, **Create bucket**, any region, and a unique name (the lecturer used `s3-storage-classes-demos-2022`). Keep the defaults.
2. Open the bucket, click **Upload**, **Add files**, and choose `coffee.jpg`.
3. **Don't click Upload yet.** Expand **Properties** on the upload page to see the **Storage class** options.

- The storage class is chosen **per object**, at upload time. If you don't choose, it is **Standard**.
- The bucket itself has **no default storage class**. Each object has its own.

### 2. The Storage Class Options in the Console

- The upload page lists every class with a comparison table (designed for, number of AZs, minimum storage duration, minimum billable object size, monitoring fees). It shows the same facts as the Storage Classes Overview.
- **Reduced Redundancy** also appears in the list. It is **deprecated** and not covered.

### 3. Upload as Standard-IA

1. In the upload page, set **Storage class** to **Standard-IA**.
2. Click **Upload**, then close the status panel.
3. Back in the bucket, the object's list shows **Storage class: Standard-IA**.

- **Cost note:** Standard-IA bills a **minimum of 128 KB per object** and a **30-day minimum storage duration**. A tiny test object still costs a little. Delete the bucket after the demo.

### 4. Change the Storage Class Manually

#### 4.1 Steps

1. Click the object, then the **Properties** tab.
2. Scroll to **Storage class**, click **Edit**.
3. Choose another class, for example **One Zone-IA**.
4. **Save changes**.
5. The object now shows **One Zone-IA**.

- You can repeat it with other targets:
  - **Glacier Instant Retrieval**: the object is **archived**.
  - **Intelligent-Tiering**: S3 **sets the right tier from the access pattern**.
- The lecturer's message: "a lot of power using storage classes".

#### 4.2 What this really does

| Point | Detail |
|---|---|
| **It is a copy** | S3 **copies the object over itself** with the new class. The **last modified** date changes. |
| **Versioning on** | The change creates a **new version** (the old version stays in its old class) |
| **Early deletion fees** | Moving out of a class before its **minimum duration** (30 or 90 or 180 days) can still **bill the remaining days** |
| **Glacier Flexible and Deep Archive** | Objects there aren't directly readable. You must **restore** them first. |
| **Large objects or many objects** | For many objects use **Lifecycle rules** or **S3 Batch Operations** (copy) instead of editing one by one |

### 5. Automate with Lifecycle Rules

#### 5.1 Steps

1. Bucket, **Management** tab, **Lifecycle rules**, **Create lifecycle rule**.
2. **Rule name:** `DemoRule`.
3. **Rule scope:** **Apply to all objects in the bucket**, then tick the acknowledgment that this applies to all objects. (The other option is a **filter** by prefix, tags, or object size.)
4. **Lifecycle rule actions:** tick **Move current versions of objects between storage classes**.
5. Add the transitions below, then review the **timeline** and create the rule.

**Transitions used in the demo:**

| Step | Storage class | After (days since creation) |
|---|---|---|
| 1 | **Standard-IA** | **30** |
| 2 | **Intelligent-Tiering** | **60** |
| 3 | **Glacier Flexible Retrieval** | **180** |

- The console shows a **review timeline** of all the transitions. The lecturer's point: it is possible to **automate moving objects between tiers**.
- The rule runs **daily in the background**. Transitions happen **after the days elapse**, so you won't see changes in this demo.
