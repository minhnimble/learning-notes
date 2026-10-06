# Advanced Amazon S3

---

## S3 Lifecycle Rules (with S3 Analytics)

### TL;DR

- **Lifecycle rules** automate what happens to objects over time. They have two kinds of action: **transition** (move to another storage class) and **expiration** (delete).
- **Transition example:** move to **Standard-IA 60 days after creation**, or to **Glacier after 6 months**.
- **Expiration examples:**
  - Delete **access logs after 365 days**.
  - Delete **old (noncurrent) versions** in a versioned bucket.
  - Delete **incomplete multipart uploads** older than about 2 weeks.
- Rules can apply to the **whole bucket**, a **prefix** (a path), or **object tags** (for example only the finance department).
- Objects move **down a one-way waterfall** from hot to cold. Moving back up needs a copy or restore.
- **S3 Analytics (Storage Class Analysis)** recommends **when to move Standard to Standard-IA**. It does **not** cover One Zone-IA or Glacier. It produces a **daily CSV report**, and the first data takes **24 to 48 hours**.
- Expect **scenario questions** that combine storage classes, prefixes, versioning, and lifecycle rules.

### 1. Moving Between Storage Classes

- You can move objects **manually** (edit the storage class, which copies the object) or **automatically with lifecycle rules**.
- The lecture shows a **transition diagram** with the allowed moves, and says all the permutations are on the graph.
- Heuristics from the lecture:
  - Objects will be **infrequently accessed**: move them to **Standard-IA**.
  - Objects will be **archived**: move them to a **Glacier** tier or **Deep Archive**.

**The waterfall (the direction you can go):**

```
Standard
   -> Standard-IA
   -> Intelligent-Tiering
   -> One Zone-IA
   -> Glacier Instant Retrieval
   -> Glacier Flexible Retrieval
   -> Glacier Deep Archive
```

- You can **skip steps**. For example, Standard straight to Glacier Flexible Retrieval or Deep Archive.
- **Transitions only go colder.** To go back to Standard, **copy the object** (or restore it first, for Flexible and Deep Archive).
- **Some moves are not allowed** (extra). Examples: any class back to **Standard**, **Intelligent-Tiering to Standard-IA**, and **One Zone-IA to Standard-IA or Intelligent-Tiering**. The lecture's description of the diagram is loose, so check the current "supported transitions" table in the S3 docs.

**Constraints the console enforces (extras):**

| Rule | Detail |
|---|---|
| **Standard to Standard-IA or One Zone-IA** | The object must be at least **30 days old** |
| **Standard-IA to a colder class** | The object must have spent at least **30 days in Standard-IA** |
| **Small objects** | By default, objects **under 128 KB** are **not** transitioned to IA or Glacier classes |
| **Spacing** | Each later transition must happen **after** the earlier one |
| **Early deletion fees** | Moving or deleting before the class's **minimum storage duration** can bill the remaining days |

### 2. Lifecycle Rule Components

| Component | What it does | Lecture example |
|---|---|---|
| **Transition action** | Moves objects to another storage class after N days | Standard-IA **60 days** after creation. Glacier after **6 months**. |
| **Expiration action** | **Deletes** objects after N days | Delete **access logs after 365 days** |
| **Scope (prefix)** | Limits the rule to a **path** | The rule applies to `thumbnails/` only |
| **Scope (tags)** | Limits the rule to objects with **specific tags** | Only objects tagged `department=finance` |

- A rule can apply to the **entire bucket** or to a **subset** (prefix, tags, and optionally object size).
- Days are counted from **object creation** (for current versions) or from when a version **became noncurrent** (for old versions).
- Lifecycle runs **once a day** in the background. Actions can lag by a day or so.

#### 2.1 Expiration action types

| Action | Use |
|---|---|
| **Expire current versions** | Delete objects after N days. In a **versioned** bucket this adds a **delete marker**. |
| **Permanently delete noncurrent versions** | Remove **old versions** after N days (the lecture's "delete old versions if versioning is enabled") |
| **Delete expired object delete markers** | Clean up **delete markers** with no versions left behind them |
| **Abort incomplete multipart uploads** | Delete **partial uploads** older than N days (lecture: **more than two weeks old**, since they "should have been fully uploaded by now") |

- **Incomplete multipart uploads** cost storage but don't show in normal listings, so this rule is an easy saving.

#### 2.2 Transition actions for versioned buckets

- **Current versions** and **noncurrent versions** have **separate** transition and expiration settings.
- **Noncurrent versions** are the older versions (not the top-level one).

### 3. Scenario 1: Thumbnails and Source Images

**Situation:**
- An application on **EC2** creates **image thumbnails** after **profile photos** are uploaded to S3.
- **Thumbnails** can be **easily recreated** from the original, and only need to be kept **60 days**.
- **Source images** must be **retrievable immediately for 60 days**. Afterwards, users can **wait up to 6 hours**.

**Design:**

| Data | Storage class | Lifecycle rule |
|---|---|---|
| **Source images** (for example `source/`) | **S3 Standard** | **Transition to Glacier after 60 days** |
| **Thumbnails** (for example `thumbnails/`) | **One Zone-IA** (infrequently accessed and re-creatable) | **Expire (delete) after 60 days** |

- **Prefixes** (or tags) separate the two kinds of object, so each gets its own rule.
- **Which Glacier:** "wait up to 6 hours" fits **Glacier Flexible Retrieval**. Its **Standard** retrieval takes **3 to 5 hours**, and Bulk takes 5 to 12. **Deep Archive (12+ hours)** would be too slow.
- **Why One Zone-IA for thumbnails:** it is the **cheapest rapid-access** class, and losing one AZ doesn't matter because the thumbnails can be **regenerated**.

### 4. Scenario 2: Recovering Deleted Objects

**Situation:**
- A company rule: deleted S3 objects must be **recoverable immediately for 30 days** (this rarely happens).
- After that, for up to **365 days**, deleted objects must be **recoverable within 48 hours**.

**Design:**

1. **Enable S3 versioning.** A delete just adds a **delete marker**, which hides the object, and it can be **recovered**.
2. **Lifecycle rule on noncurrent versions:** transition them to **Standard-IA**. They stay **instantly retrievable** and cost less.
3. A **second transition** moves the noncurrent versions to **Glacier Deep Archive** for archival.
4. Optionally **expire** them after the retention requirement (365 days or longer).

- Deep Archive fits the "**within 48 hours**" rule (Standard retrieval is about 12 hours, Bulk about 48).
- **Noncurrent versions** are the versions that are **not the top-level (current) version**.
- The lecture describes the pattern at a high level. The exact day counts on each transition depend on the 30-day minimums in section 1.
- **Recovery:** delete the **delete marker** to restore the object. For versions in Deep Archive, first **restore** them.

### 5. S3 Analytics (Storage Class Analysis)

**Question:** how do you pick the **optimal number of days** before transitioning objects?

**Answer:** use **Amazon S3 Analytics (Storage Class Analysis)**.

| Property | Detail |
|---|---|
| **Gives recommendations for** | **Standard** to **Standard-IA** |
| **Not supported for** | **One Zone-IA** and **Glacier** classes |
| **Output** | A **CSV report** with recommendations and statistics |
| **Update frequency** | Updated **daily** |
| **Time to first data** | **24 to 48 hours** after you enable it |
| **Scope** | A bucket, or a **prefix or tag filter** (extra) |
| **Destination** | The report is written to an **S3 bucket** you choose (extra) |

```
Enable Storage Class Analysis on a bucket
        |
        v   (24 to 48 hours)
Daily CSV report: access patterns and how much data is infrequently accessed
        |
        v
Use it to create or improve lifecycle rules (when to move to Standard-IA)
```

- The lecturer calls the CSV a "good first step" to put together **lifecycle rules that make sense**, or to **improve existing ones**.
- It looks at **access patterns by object age**, so you can see when objects become cold.
- It has a small **monitoring charge** per million objects (extra).
- It is for **tuning lifecycle rules**. **Intelligent-Tiering** is the alternative when you can't predict access patterns.

### 6. Lifecycle Rules vs Intelligent-Tiering

| | **Lifecycle rules** | **Intelligent-Tiering** |
|---|---|---|
| **Based on** | **Age** (days) that you set | **Actual access** (S3 monitors it) |
| **Best when** | Access pattern is **known and predictable** | Access pattern is **unknown or changing** |
| **Cost model** | No monitoring fee | **Per-object monitoring and auto-tiering fee** |
| **Can delete objects?** | **Yes** (expiration) | No |

- They work **together**: a lifecycle rule can transition objects **into** Intelligent-Tiering.

### 7. Key Facts to Remember

- **Lifecycle rules = transition actions + expiration actions.**
- Rules apply to the **whole bucket**, a **prefix**, or **tags**.
- Transitions go **down the waterfall** only, from hot to cold.
- **Expiration** can delete **logs**, **old versions**, and **incomplete multipart uploads**.
- **Versioned bucket:** use **noncurrent version** actions for old versions.
- **S3 Analytics** recommends **Standard to Standard-IA** timing only, with a **daily CSV** after **24 to 48 hours**.
- Re-creatable data that is rarely read: **One Zone-IA**.
- "Immediate for N days, then wait hours": **Standard, then Glacier Flexible Retrieval**.
- "Recoverable deletes": **versioning + delete markers**, with older versions moved to cheaper classes.
- Rules live in the bucket's **Management** tab.

### 8. Exam-Style Recall

| If the question says... | Think... |
|---|---|
| "Automatically move objects to a cheaper class after N days" | **Lifecycle transition action** |
| "Delete objects (for example logs) after 365 days" | **Lifecycle expiration action** |
| "Clean up incomplete multipart uploads" | Lifecycle rule to **abort incomplete multipart uploads** |
| "Delete old versions in a versioned bucket" | Lifecycle on **noncurrent versions** |
| "Apply a rule to only some objects" | **Prefix** and/or **tag** filter |
| "Re-creatable thumbnails kept 60 days" | **One Zone-IA** plus **expire after 60 days** |
| "Immediate access for 60 days, then wait up to 6 hours" | **Standard**, then **Glacier Flexible Retrieval** after 60 days |
| "Recover deleted objects immediately for 30 days, then within 48 hours up to 365 days" | **Versioning**, **noncurrent to Standard-IA**, then **Deep Archive** |
| "Find the optimal number of days to move to Standard-IA" | **S3 Analytics (Storage Class Analysis)** |
| "S3 Analytics supports which classes?" | **Standard and Standard-IA** only |
| "How soon does S3 Analytics show data?" | **24 to 48 hours** (report updated daily) |
| "S3 Analytics output format" | **CSV report** |
| "Access pattern unknown, no manual tuning" | **Intelligent-Tiering** |
| "Move an object back to Standard" | **Copy it** (lifecycle can't transition up) |

---

## S3 Lifecycle Rules - Hands On

### TL;DR

- Created a lifecycle rule (`DemoRule`) from the bucket's **Management** tab. Scope: **all objects in the bucket** (with the acknowledgment ticked).
- The console offers **five rule actions**:
  1. **Move current versions** between storage classes
  2. **Move noncurrent versions** between storage classes
  3. **Expire current versions** of objects
  4. **Permanently delete noncurrent versions**
  5. **Delete expired object delete markers or incomplete multipart uploads**
- The demo configured actions 1 to 4 and left action 5 unconfigured. The console then shows a **timeline** of everything that will happen to current and noncurrent versions.
- Creating the rule starts it **in the background**. Nothing visible changes during the demo, because transitions take days.

### 1. Create the Rule

1. Open the bucket, **Management** tab, **Lifecycle rules**, **Create lifecycle rule**.
2. **Lifecycle rule name:** `DemoRule`.
3. **Choose a rule scope:** **Apply to all objects in the bucket**.
4. Tick the acknowledgment that the rule applies to **all objects in the bucket**.

| Scope option | Meaning |
|---|---|
| **Limit the scope using filters** | Restrict the rule by **prefix**, **object tags**, or **object size** |
| **Apply to all objects in the bucket** | The rule covers everything. The console asks you to **acknowledge** this, because it is broad. |

- The demo used the **whole bucket**. In real buckets, filter by **prefix or tag** so a rule doesn't touch data you didn't intend (for example `logs/` only).

### 2. The Five Rule Actions

| # | Action | Applies to | Purpose |
|---|---|---|---|
| 1 | **Move current versions of objects between storage classes** | Current versions | **Transition** to colder classes |
| 2 | **Move noncurrent versions of objects between storage classes** | Old versions | Transition **old versions** to colder classes |
| 3 | **Expire current versions of objects** | Current versions | **Delete** objects after N days |
| 4 | **Permanently delete noncurrent versions of objects** | Old versions | Remove **old versions** after N days |
| 5 | **Delete expired object delete markers or incomplete multipart uploads** | Housekeeping | Clean up **leftover delete markers** and **abandoned multipart uploads** |

- Actions 1 and 3 act on the **current version**. Actions 2 and 4 act on **noncurrent versions** (the old ones).
- The lecturer says "five different use cases" and goes through them one by one.

**What "current" and "noncurrent" mean:**
- The **current version** is the most recent one, the one a normal GET returns.
- A **noncurrent version** is an older one, **overwritten by a newer version** (or hidden behind a delete marker).
- The lecturer explains current versions with a **versioned bucket**. In an **unversioned** bucket every object is simply the current version, so actions 1 and 3 still apply, while actions 2 and 4 have nothing to act on.

### 3. Action 1: Move Current Versions Between Storage Classes

The demo's transitions (days counted **from object creation**):

| Step | Storage class | After (days) |
|---|---|---|
| 1 | **Standard-IA** | **30** |
| 2 | **Intelligent-Tiering** | **60** |
| 3 | **Glacier Instant Retrieval** | **90** |
| 4 | **Glacier Flexible Retrieval** | **180** |
| 5 | **Glacier Deep Archive** | **365** |

- Click **Add transition** for each step. "You can have as many transitions as you want."
- **Tick the acknowledgment** the console shows about transition costs and small objects. The lecturer mentions it.
- The ladder only goes **colder**, and each step must be **after** the previous one. See the constraints below.

### 4. Action 2: Move Noncurrent Versions Between Storage Classes

- Demo transition: **Glacier Flexible Retrieval after 90 days**.
- Reason from the lecture: old versions are rarely retrieved ("after 90 days we won't need it for retrieval"), so archive them.
- Days are counted **from when the version became noncurrent** (that is, when a newer version replaced it), not from its original creation.
- You can add more transitions, and there is an option to **keep the N newest noncurrent versions** untouched (extra).

### 5. Actions 3 and 4: Expiration

| Action | Demo value | Effect |
|---|---|---|
| **Expire current versions** | After **700 days** | Deletes current objects. In a **versioned** bucket this **adds a delete marker**. In an **unversioned** bucket it **deletes permanently**. |
| **Permanently delete noncurrent versions** | After **700 days** | **Permanently removes** old versions |

- **Expiration must come after the last transition.** The demo's last transition is at 365 days, and expiry is at 700.
- The lecturer notes the field allows a maximum-style value at the bottom of the page. Treat **700** as just his example.
- In a versioned bucket, expiring current versions only **hides** the object behind a delete marker. To really free space you also need action 4 and action 5.

### 6. Action 5: Delete Markers and Incomplete Multipart Uploads (Not Configured)

| Option | Purpose |
|---|---|
| **Delete expired object delete markers** | Remove **delete markers** that no longer have any versions behind them |
| **Delete incomplete multipart uploads** | **Abort** partial uploads older than N days (for example **7 days**). The previous lecture suggested about **2 weeks**. |

- The lecturer showed the action but didn't set it. It is cheap to turn on, since **incomplete multipart uploads** cost storage but don't appear in normal listings.
- **Expired object delete markers** and **expiring current versions** can't be combined in the same rule in some console versions. Check what your console allows.

### 7. Review the Timeline and Create

- The console shows a **timeline** for the rule, with separate lines for **current versions** and **noncurrent versions**.

| Timeline item (demo) | Day |
|---|---|
| Current: Standard-IA | 30 |
| Current: Intelligent-Tiering | 60 |
| Current: Glacier Instant Retrieval | 90 |
| Current: Glacier Flexible Retrieval | 180 |
| Current: Glacier Deep Archive | 365 |
| Current: **expire** | 700 |
| Noncurrent: Glacier Flexible Retrieval | 90 |
| Noncurrent: **permanently delete** | 700 |

- Click **Create rule**. The rule "will act in the background to do what it's supposed to be doing".
- Lifecycle runs **once a day**, so actions happen with up to about a day of delay.
- You can **edit, disable, or delete** the rule later from the same page.

### 8. Constraints and Warnings (Extras)

| Constraint | Detail |
|---|---|
| **Minimum age for IA classes** | Transition to **Standard-IA or One Zone-IA** needs the object to be at least **30 days old** |
| **Waterfall order** | Only transitions to **colder** classes. You can skip steps. |
| **Spacing** | Each later transition must be **later** than the previous one |
| **Small objects** | By default, objects **under 128 KB** aren't transitioned to IA or Glacier classes (the console warns about this) |
| **Early deletion fees** | Moving or deleting before a class's **minimum storage duration** (30 / 90 / 180 days) can bill the remaining days |
| **Transition cost** | Each transition is a **request charge**, so moving millions of tiny objects can cost more than it saves |
| **Expiration is irreversible** | In an **unversioned** bucket, expired objects are **gone**. In a **versioned** one they are recoverable until noncurrent versions are deleted. |
| **Glacier Flexible and Deep Archive** | Objects there need a **restore** before they can be read |

### 9. Key Facts to Remember

- Lifecycle rules live in the bucket's **Management** tab.
- A rule can have **five action types**: transition current, transition noncurrent, expire current, delete noncurrent, and clean up delete markers or incomplete multipart uploads.
- **Current** = latest version. **Noncurrent** = overwritten or older versions.
- Demo ladder: **Standard-IA 30, Intelligent-Tiering 60, Glacier Instant 90, Glacier Flexible 180, Deep Archive 365**, expire at **700**.
- **Noncurrent** transitions and deletions count days from when the version **became noncurrent**.
- The **timeline view** lets you check the whole plan before creating the rule.
- The rule works in the **background**, daily.
- Scope the rule with **prefix, tags, or size** in real buckets.
- Use **S3 Analytics** to choose the number of days for Standard to Standard-IA (previous lecture).

### 10. Exam-Style Recall

| If the question says... | Think... |
|---|---|
| "Automatically move objects between storage classes" | **Lifecycle rule**, transition action |
| "Where do you create lifecycle rules?" | Bucket **Management** tab |
| "Delete objects automatically after N days" | **Expiration** action |
| "Old versions of overwritten objects" | **Noncurrent versions** |
| "Remove old versions to save cost" | **Permanently delete noncurrent versions** |
| "Clean up abandoned multipart uploads" | **Delete incomplete multipart uploads** action |
| "Expire current versions in a versioned bucket" | Adds a **delete marker** |
| "Apply a rule only to a folder or department" | **Prefix** or **tag** filter |
| "Which classes can a lifecycle transition to?" | Colder classes only (the waterfall) |
| "Minimum days before moving to Standard-IA" | **30** |
| "Does a lifecycle rule run immediately?" | No, **daily in the background** |

### 11. Hands-On Checklist

- [x] Open your bucket, **Management**, **Lifecycle rules**, **Create lifecycle rule**
- [x] Name it `DemoRule`, choose **Apply to all objects in the bucket**, and tick the acknowledgment
- [x] Review the **five rule actions**
- [x] Tick **Move current versions of objects between storage classes** and add: **Standard-IA at 30**, **Intelligent-Tiering at 60**, **Glacier Instant Retrieval at 90**, **Glacier Flexible Retrieval at 180**, **Glacier Deep Archive at 365**, then tick the acknowledgment
- [x] Tick **Move noncurrent versions of objects between storage classes** and add **Glacier Flexible Retrieval at 90**
- [x] Tick **Expire current versions of objects** and set **700 days**
- [x] Tick **Permanently delete noncurrent versions of objects** and set **700 days**
- [x] Look at (but you don't need to set) **Delete expired object delete markers or incomplete multipart uploads**
- [x] Review the **timeline** for current and noncurrent versions
- [x] Click **Create rule**
- [x] **Clean up:** if this is a throwaway bucket, **delete the lifecycle rule**, **empty** the bucket (all versions), and **delete** it. A broad rule on a real bucket can transition or delete data you wanted.

---

## S3 Event Notifications

### TL;DR

- **S3 Event Notifications** let you **react automatically to events** in a bucket: an object **created, removed, restored**, **replication** activity, and more.
- You can **filter** events, for example only objects whose key **ends with `.jpg`** (prefix and suffix filters).
- **Classic destinations:** **SNS topic**, **SQS queue**, **Lambda function**.
- **Fourth integration: Amazon EventBridge.** All bucket events can go to EventBridge, which then routes them with **rules** to **18+ AWS services**, with **advanced filtering**, **archive and replay**, and more reliable delivery.
- Delivery is usually **within seconds**, but can take **a minute or longer**.
- **Permissions:** S3 does **not** use an IAM role here. You attach a **resource policy** to the **destination** (SNS access policy, SQS access policy, or Lambda resource-based policy) that allows S3 to send or invoke.
- **Classic use case:** generate a **thumbnail** whenever an image is uploaded.

### 1. What Are S3 Events?

| Event type | Examples |
|---|---|
| **Object created** | `s3:ObjectCreated:*` (Put, Post, Copy, CompleteMultipartUpload) |
| **Object removed** | `s3:ObjectRemoved:*` (Delete, DeleteMarkerCreated) |
| **Object restored** | `s3:ObjectRestore:*` (restore from Glacier started or completed) |
| **Replication** | `s3:Replication:*` (missed threshold, failed, and so on) |
| **Others (extra)** | Lifecycle expiration and transition, Intelligent-Tiering, object tagging, ACL put, Object Lock |

- You can create **as many notification configurations as you like** and send them to whichever targets you want.
- Notifications are configured **per bucket** (Properties, **Event notifications**).

### 2. Filtering

- Filter on the **object key**:

| Filter | Example |
|---|---|
| **Prefix** | `images/` |
| **Suffix** | `.jpg` (the lecture: "only objects that end with JPEG") |

- Prefix and suffix can be **combined**.
- Don't create **overlapping** prefix/suffix rules for the same event type in one bucket. S3 rejects ambiguous configurations.
- For richer filtering (object size, metadata, and so on), use **EventBridge** (section 5).

### 3. Use Case: Thumbnails

```
User uploads photo.jpg --> [S3 bucket] --(ObjectCreated, suffix .jpg)--> [Lambda] --> writes thumbnail
```

- On every upload, the event triggers a **Lambda function** that creates a thumbnail.
- **Write thumbnails to a different bucket or prefix.** If the output lands in the same bucket and prefix that triggers the event, you create an **infinite loop**.
- Other uses: virus scan, metadata extraction, indexing, queue work for processing, notify a team.

### 4. The Three Classic Destinations

| Destination | What it does |
|---|---|
| **SNS topic** | **Fan out** to many subscribers (email, SMS, HTTP, Lambda, SQS) |
| **SQS queue** | **Buffer** events for a consumer to process at its own pace |
| **Lambda function** | **Run code** right away |

- The lecturer says not to worry if you don't know these yet. They are covered in later sections.
- Delivery is **at least once**, so a notification can occasionally be **duplicated**. Make handlers **idempotent**.
- Event ordering isn't guaranteed (extra).
- Also **not supported** as a direct S3 destination: **SQS FIFO queues** and **SNS FIFO topics** (extra).

### 5. Permissions: Resource Policies, Not IAM Roles

S3 sends data to another service, so that service must **allow S3**. You attach a **resource-based policy** to the **destination**:

| Destination | Policy you attach |
|---|---|
| **SNS topic** | **SNS access policy** (allows S3 to publish) |
| **SQS queue** | **SQS access policy** (allows S3 to send messages) |
| **Lambda function** | **Lambda resource-based policy** (allows S3 to invoke the function) |

- "Here we don't use IAM roles for Amazon S3. Instead, we define resource access policies" on the topic, queue, or function.
- They work **like an S3 bucket policy**, but in the other direction.
- **Typical policy shape (SNS example):**

```json
{
  "Effect": "Allow",
  "Principal": { "Service": "s3.amazonaws.com" },
  "Action": "SNS:Publish",
  "Resource": "arn:aws:sns:eu-west-1:123456789012:my-topic",
  "Condition": {
    "ArnLike": { "aws:SourceArn": "arn:aws:s3:::my-bucket" }
  }
}
```

- The **`aws:SourceArn`** condition limits it to **your bucket**, which prevents the **confused deputy** problem. Add `aws:SourceAccount` as well (extra).
- **EventBridge** needs **no** destination policy for the S3 to EventBridge hop. You just **enable** it on the bucket.

### 6. Amazon EventBridge Integration

- **All bucket events** can be sent to **EventBridge**. Turn it on in the bucket's **Properties**, **Event notifications**, **Amazon EventBridge**, **On**.
- In EventBridge you create **rules** that match events and route them to **targets**.

```
S3 bucket --(all events)--> [EventBridge] --rules--> 18+ services (Step Functions, Kinesis Data Streams, Firehose, Lambda, SQS, SNS, ...)
```

| EventBridge advantage | Detail |
|---|---|
| **Advanced filtering** | Filter on **metadata, object size, name**, and more, using JSON event patterns |
| **Multiple destinations** | One event can go to **several targets** at once |
| **Many targets** | **18+ AWS services**, for example **Step Functions**, **Kinesis Data Streams**, **Firehose** |
| **Archive and replay** | **Archive** events and **replay** them later |
| **Reliable delivery** | Better delivery guarantees and retries than direct notifications |

- EventBridge is covered later in the course. The lecturer's framing: focus on **S3 Event Notifications** now.
- You can use **direct notifications and EventBridge together** on the same bucket (extra).

### 7. Direct Notifications vs EventBridge

| | **Direct (SNS, SQS, Lambda)** | **EventBridge** |
|---|---|---|
| **Destinations** | **3** | **18+ services** |
| **Filtering** | **Prefix and suffix** only | **Advanced** (metadata, size, name, and more) |
| **Multiple targets per event** | Limited | **Yes** |
| **Archive and replay** | No | **Yes** |
| **Setup** | Bucket config plus a **resource policy** on the target | Turn on EventBridge for the bucket, then create **rules** |
| **Latency** | Typically **seconds** | Typically seconds, a little higher |
| **Best for** | Simple, direct reactions | Complex routing and many consumers |

### 8. Delivery Behavior

- Events are usually delivered **within seconds**, but can take **a minute or longer**.
- Delivery is **at least once**. Handle **duplicates**.
- If the destination is **misconfigured** (missing policy, wrong ARN), **the notification configuration fails to save**, because S3 tests the destination when you create it (SNS, SQS).
- For **Lambda**, S3 invokes the function **asynchronously**. Failed invocations follow Lambda's retry and **dead-letter** settings (extra).

### 9. Key Facts to Remember

- S3 events: **created, removed, restored, replication**, and more.
- Filter by **prefix and suffix** (direct) or **richer patterns** (EventBridge).
- Direct targets: **SNS, SQS, Lambda**. Fourth path: **EventBridge**.
- **Permissions come from resource policies** on SNS, SQS, and Lambda. **Not IAM roles.**
- All events can go to **EventBridge**, with **18+ targets**, **advanced filtering**, **archive and replay**.
- Delivery: usually **seconds**, sometimes **a minute or longer**, **at least once**.
- Use case: **thumbnail generation**. Avoid **recursive triggers**.
- You can create **many notification configurations** per bucket.

### 10. Exam-Style Recall

| If the question says... | Think... |
|---|---|
| "Run code automatically when a file is uploaded to S3" | **S3 Event Notification to Lambda** |
| "Generate thumbnails for uploaded images" | **S3 event to Lambda** |
| "Which services can S3 send event notifications to directly?" | **SNS, SQS, Lambda** |
| "S3 notification can't publish to my SNS topic or SQS queue" | Missing **resource access policy** on the topic or queue |
| "S3 can't invoke my Lambda function" | Missing **Lambda resource-based policy** |
| "Do S3 event notifications use an IAM role?" | **No**, **resource policies** on the destination |
| "Filter notifications to `.jpg` files only" | **Suffix filter** |
| "Send S3 events to Step Functions, Kinesis, or Firehose" | **EventBridge** |
| "Advanced filtering on object size or metadata" | **EventBridge** |
| "Archive and replay S3 events" | **EventBridge** |
| "Send one S3 event to multiple destinations" | **SNS fan-out** or **EventBridge** |
| "How fast are events delivered?" | **Within seconds**, sometimes a minute or longer |
| "Thumbnail function triggers itself forever" | Output to the **same bucket and prefix** as the trigger. Use a **separate bucket or prefix**. |
| "Events delivered more than once" | **At-least-once** delivery. Make the consumer **idempotent**. |

---

## S3 Event Notifications - Hands On

### TL;DR

- Created a bucket, then went to **Properties**, **Event notifications**. There are two options: **Create event notification** (SNS, SQS, or Lambda), or turn on the **Amazon EventBridge** integration to send all events to EventBridge.
- Built an event notification (`DemoEventNotification`) for **all object create events**, with **SQS** as the destination and a queue named `DemoS3Notification`.
- **The first save failed**: S3 tests the destination, and the queue's **access policy** didn't allow S3 to send messages.
- **Fix:** edit the queue's **access policy** (the demo used the **Policy Generator**: SQS queue policy, Allow, `SendMessage`, the queue ARN). After that, the save succeeded.
- S3 sent a **test event** message to the queue, which the lecturer deleted.
- Uploaded `coffee.jpg`, then polled the queue. The message had **`eventName: ObjectCreated:Put`** and the object **key `coffee.jpg`**. A consumer (for example a thumbnail generator) would process it from there.
- The demo policy used **`Principal: *`**, which is **very permissive**. Use a tighter policy outside demos (see section 4.3).

### 1. Create the Bucket

1. S3 console, **Create bucket**.
2. Name: your own unique name (the lecturer used `stephane-v3-events-notifications`), region `eu-west-1` (Ireland).
3. Keep the defaults and **Create bucket**.

- The **SQS queue must be in the same region as the bucket**, so note the region you pick.

### 2. Event Notifications in the Bucket

- Bucket, **Properties** tab, scroll to **Event notifications**.
- Two options:

| Option | What it does |
|---|---|
| **Create event notification** | A **direct** notification to **Lambda, SNS, or SQS** (the demo's path) |
| **Amazon EventBridge** | Set to **On**, and **all events** go to EventBridge. Then use **rules** to route them to **18+ services**. |

- The lecturer says the EventBridge path is "a bit more complicated" and shows only the direct path.
- You can use **both** at the same time.

### 3. Create the Event Notification

#### 3.1 General configuration

| Setting | Demo value | Notes |
|---|---|---|
| **Event name** | `DemoEventNotification` | |
| **Prefix** | Not set | Filter by key **prefix** (for example `images/`) |
| **Suffix** | Not set | Filter by key **suffix** (for example `.jpg`) |

#### 3.2 Event types

| Choice | Demo |
|---|---|
| **All object create events** | **Selected.** Fires whenever an object is created (Put, Post, Copy, multipart upload complete). |
| Object removal events | Not selected |
| Object restore events | Not selected |
| Replication, lifecycle, tagging, and more | Not selected |

- You can pick **individual event types** for finer control (for example only `Put`).
- The console lists all the event types on the right-hand side. The lecturer notes there are many.

#### 3.3 Destination

- Three options: **Lambda function**, **SNS topic**, **SQS queue**.
- The demo chose **SQS queue**, which needs a queue to exist first.
- Choose the queue from the **dropdown** (after creating it and refreshing), or **enter its ARN**.

### 4. Create the SQS Queue and Fix Permissions

#### 4.1 Create the queue

1. **Amazon SQS** console, **Create queue**.
2. Name: `DemoS3Notification`. Keep the defaults (standard queue).
3. **Create queue**.
4. Back in the S3 tab, **refresh** the page, then reopen the notification setup to see the queue in the dropdown.

- It must be a **Standard** queue. **FIFO queues aren't supported** as S3 event destinations.

#### 4.2 The error (the problem)

1. Back in S3, choose **DemoS3Notification** as the SQS destination and click **Save changes**.
2. **Error:** the console can't **validate the destination configuration** (the lecturer calls it an "unknown error").
3. **Why:** when you save, S3 **sends a test message** to the queue. The queue's access policy doesn't allow S3 to write, so it is **denied**.

- This is the **exam-relevant lesson**: S3 needs permission **on the destination**, through a **resource policy**, **not an IAM role**.

#### 4.3 The fix: edit the queue's access policy

**What the lecturer did:**
1. SQS, open the queue, **Edit**, scroll to **Access policy**.
2. Open the **Policy Generator**.
3. Type: **SQS Queue Policy**. Effect: **Allow**. Principal: `*` ("anyone, just to be very permissive"). Action: **SendMessage**. Resource: the **queue ARN** (copy it from the queue details).
4. **Add Statement**, **Generate Policy**, and paste the JSON into the access policy box.
5. **Save**.

**Resulting policy (demo, too permissive):**

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": "*",
      "Action": "SQS:SendMessage",
      "Resource": "arn:aws:sqs:eu-west-1:123456789012:DemoS3Notification"
    }
  ]
}
```

**Recommended version (restricts to your bucket):**

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": { "Service": "s3.amazonaws.com" },
      "Action": "SQS:SendMessage",
      "Resource": "arn:aws:sqs:eu-west-1:123456789012:DemoS3Notification",
      "Condition": {
        "ArnLike": { "aws:SourceArn": "arn:aws:s3:::<your-bucket>" },
        "StringEquals": { "aws:SourceAccount": "123456789012" }
      }
    }
  ]
}
```

- `Principal: *` lets **anyone** send messages to your queue. That is fine for a throwaway demo, but **unsafe in real use**.
- The **`aws:SourceArn`** and **`aws:SourceAccount`** conditions limit it to your bucket and account, which prevents the **confused deputy** problem.

**Then:**
1. Return to the S3 notification page and **Save changes** again.
2. It **succeeds** this time.

### 5. The Test Event

- After a successful save, S3 sends a **test message** to confirm the connection.
1. SQS, the queue, **Send and receive messages**, **Poll for messages**.
2. A message from S3 appears: the **test event** (`s3:TestEvent`).
3. **Delete** the message. It is not a real object event.

```json
{
  "Service": "Amazon S3",
  "Event": "s3:TestEvent",
  "Bucket": "<your-bucket>",
  "RequestId": "...",
  "HostId": "..."
}
```

### 6. Test with a Real Upload

1. In the bucket, **Upload**, **Add files**, choose `coffee.jpg`, and upload.
2. Confirm `coffee.jpg` is in the bucket.
3. SQS, the queue, **Poll for messages**.
4. A **new message** appears. Open it (the lecturer enlarges the message window) and read the body.

**Fields to find:**

| Field | Value in the demo |
|---|---|
| **`eventName`** | **`ObjectCreated:Put`** (an object was created by a PUT) |
| **`s3.object.key`** | **`coffee.jpg`** |

**Message body (abridged):**

```json
{
  "Records": [
    {
      "eventSource": "aws:s3",
      "awsRegion": "eu-west-1",
      "eventTime": "2026-10-06T09:45:00.000Z",
      "eventName": "ObjectCreated:Put",
      "s3": {
        "bucket": { "name": "<your-bucket>", "arn": "arn:aws:s3:::<your-bucket>" },
        "object": { "key": "coffee.jpg", "size": 102400 }
      }
    }
  ]
}
```

- Imagine **automating a thumbnail**: a worker (for example Lambda or an EC2 app) **reads this message** from the queue, downloads `coffee.jpg`, and creates the thumbnail.
- The event is delivered **within seconds**, and **at least once**, so the same message can occasionally appear twice.
- **Delete the message** when done. A consumer must delete it after processing, or it reappears after the **visibility timeout**.

### 7. Troubleshooting

| Symptom | Likely cause |
|---|---|
| **Unable to validate destination configuration** on save | The queue's **access policy** doesn't allow S3. Add the `SendMessage` statement. |
| Error mentions the **region** | The queue is in a **different region** from the bucket |
| Queue doesn't show in the S3 dropdown | **Refresh** the page, or enter the **ARN** |
| Upload works but **no message** arrives | The **event type, prefix, or suffix** filter doesn't match, or you didn't wait long enough. Poll again. |
| Only the **test event** appears | The notification works, but no new object matched. Upload a file. |
| Duplicate messages | **At-least-once** delivery. Make the consumer **idempotent**. |
| **FIFO queue** can't be selected | **FIFO is not supported** as an S3 destination |
| **KMS-encrypted queue** fails | The key policy must also allow `s3.amazonaws.com` to use the key |
| Notifications stop after editing the policy | A condition (`SourceArn`, `SourceAccount`) doesn't match your bucket or account |

### 8. Key Facts to Remember

- Configure events in the bucket's **Properties, Event notifications**.
- Direct destinations: **Lambda, SNS, SQS**. Or turn on **EventBridge** to send all events there.
- **S3 needs a resource policy** on the destination. The error "**unable to validate destination**" means the policy is missing.
- S3 sends a **test event** (`s3:TestEvent`) when you save a notification.
- A real event message carries **`eventName`** (for example `ObjectCreated:Put`) and the **object key**.
- Filters: **prefix and suffix**. Event types: create, remove, restore, replication, and more.
- **Never use `Principal: *`** in production. Use the **S3 service principal** plus **`aws:SourceArn`**.
- Destination queue must be **Standard** and **in the same region** as the bucket.
- The use case: **react to uploads automatically** (thumbnails, processing pipelines).

### 9. Exam-Style Recall

| If the question says... | Think... |
|---|---|
| "S3 event notification to SQS fails to save" | **Missing SQS access policy** allowing S3 |
| "Permission model for S3 event notifications" | **Resource policy on the destination**, not an IAM role |
| "First message in the queue after setup" | The **S3 test event** |
| "Event name for an upload" | **`ObjectCreated:Put`** (or `Post`, `Copy`, `CompleteMultipartUpload`) |
| "Find which object triggered the event" | **`s3.object.key`** in the message |
| "React to uploads and generate thumbnails" | **S3 event to SQS or Lambda** |
| "Send S3 events to many AWS services" | **EventBridge** integration |
| "Restrict an SQS policy to a specific bucket" | **`aws:SourceArn`** condition |
| "Notifications can be duplicated" | **At-least-once** delivery |
| "Which queue types work as S3 destinations?" | **Standard** SQS only |

### 10. Hands-On Checklist

- [x] **Create a bucket** (for example in `eu-west-1`) with a unique name
- [x] Bucket, **Properties**, scroll to **Event notifications** and review the two options (**Create event notification** and **Amazon EventBridge**)
- [x] **Create event notification**: name `DemoEventNotification`, no prefix or suffix
- [x] Event types: **All object create events**
- [x] Destination: **SQS queue** (leave the form open, or come back later)
- [x] In **SQS** (same region), **create a Standard queue** `DemoS3Notification`
- [x] Back in S3, **refresh**, choose the queue, and **Save changes**. Confirm the **validation error**.
- [x] In the **queue's access policy**, add a statement allowing S3 to `SQS:SendMessage` (the **Policy Generator**, or the tighter policy with `aws:SourceArn`), then **Save**
- [x] Return to the S3 notification and **Save changes**. Confirm it **succeeds**.
- [x] In SQS, **Send and receive messages**, **Poll for messages**, find the **test event**, and **delete** it
- [x] **Upload `coffee.jpg`** to the bucket
- [x] **Poll** the queue and open the new message. Find **`eventName: ObjectCreated:Put`** and **key `coffee.jpg`**.
- [x] **Delete** the message
- [x] (Optional) Turn on the **EventBridge** integration and see that it adds a second path
- [x] **Clean up:** delete the event notification, **delete the SQS queue**, **empty and delete** the bucket, and remove the permissive policy

---

## S3 Performance

### TL;DR

- **Baseline:** S3 scales automatically to very high request rates, with **100-200 ms latency to the first byte**.
- **Per prefix, per second:** **3,500 PUT/COPY/POST/DELETE** and **5,500 GET/HEAD**. There is **no limit on the number of prefixes** in a bucket.
- **More prefixes means more throughput.** Example: reads spread evenly over **4 prefixes** give 4 × 5,500 = **22,000 GET/HEAD per second**.
- **Speed up uploads:**
  - **Multipart upload:** **recommended above 100 MB**, **required above 5 GB**. Parts upload **in parallel**.
  - **S3 Transfer Acceleration:** upload to the **nearest edge location**, which forwards over the **AWS private network**. It is **compatible with multipart upload**.
- **Speed up downloads:** **S3 Byte-Range Fetches** parallelize GETs by requesting **specific byte ranges**. They also give **better resilience** (retry only a failed range) and let you fetch **just part of a file** (for example a header).
- The lecturer's closing line mentions "the KMS limits". They aren't in this transcript (see the notes at the end).

### 1. Baseline Performance

| Property | Detail |
|---|---|
| **Scaling** | **Automatic**, to a very high number of requests. No capacity planning. |
| **Latency** | **100 to 200 ms** to get the **first byte** (for S3 Standard) |
| **Write requests** | **3,500 per second per prefix**: PUT, COPY, POST, DELETE |
| **Read requests** | **5,500 per second per prefix**: GET, HEAD |
| **Prefixes per bucket** | **Unlimited** |

- The lecturer says the AWS wording is "not very clear", so he explains what **per prefix** means (section 2).
- Exceed a rate and S3 returns **503 Slow Down**. Use **exponential backoff** (see the earlier backoff lecture), or **spread load across more prefixes**.

### 2. What "Per Prefix" Means

The **prefix** is everything **between the bucket name and the file name**.

| Object key | Prefix |
|---|---|
| `bucket/folder1/sub1/file` | `/folder1/sub1` |
| `bucket/folder1/sub2/file` | `/folder1/sub2` |
| `bucket/folder2/sub1/file` | `/folder2/sub1` |
| `bucket/folder2/sub2/file` | `/folder2/sub2` |

- Each of these four is a **different prefix**, so **each** gets its own **3,500 writes and 5,500 reads per second**.
- **Spread reads evenly across all 4:** 4 × 5,500 = **22,000 GET/HEAD per second**.
- To scale further, **use more prefixes**, for example by date, user ID, or a hash.
- **Extras:**
  - Prefix rates are **independent**. Heavy load on one prefix doesn't use up another's budget.
  - Old advice said to add a **random hash prefix** to the key to avoid hot partitions. That is **no longer needed** for the baseline, though more prefixes still help raise the ceiling.
  - Objects at the **bucket root** share one prefix (the empty prefix).

### 3. Optimizing Uploads

#### 3.1 Multipart upload

| Rule | Detail |
|---|---|
| **Recommended** | Files **over 100 MB** |
| **Required** | Files **over 5 GB** |
| **How it works** | Split the file into **parts**, upload them **in parallel**, then S3 **assembles** them into one object |
| **Benefit** | **Parallel uploads** speed up the transfer and **maximize bandwidth** |

```
Big file --> [part 1] [part 2] [part 3] ... [part N]
                |        |        |           |     (uploaded in PARALLEL)
                +--------+--------+-----------+--> S3 puts the parts back together
```

- **Extras (not in the lecture):**
  - Each part is **5 MB to 5 GB** (the last can be smaller), with up to **10,000 parts**.
  - If one part fails, you **retry only that part**.
  - The **CLI and SDKs** do multipart automatically above a threshold.
  - Incomplete multipart uploads still **cost storage**. Clean them up with a **lifecycle rule** (see the lifecycle lecture).

#### 3.2 S3 Transfer Acceleration

- Works for **uploads and downloads**.
- It **increases transfer speed** by sending the file to the **nearest AWS edge location**, which forwards the data to the **S3 bucket in the target region**.
- There are **more edge locations than regions**. The lecture says **over 200**, and growing.
- **Compatible with multipart upload.**

**Lecture example:** a file in the **USA**, a bucket in **Australia**.

```
User (USA) --public internet (short)--> Edge location (USA) --fast private AWS network--> S3 bucket (Australia)
```

1. The client uploads to the **nearby US edge location**. This is quick, because the public internet leg is short.
2. The edge location sends it to the Australian bucket over the **private AWS backbone**.
3. Result: **less public internet, more private AWS network**, and faster transfers.

| Detail (extras) | Value |
|---|---|
| **Enable** | Bucket, **Properties**, **Transfer acceleration**, **Enabled** |
| **Endpoint** | `<bucket>.s3-accelerate.amazonaws.com` (or dual-stack `s3-accelerate.dualstack`) |
| **Bucket name rule** | Must be **DNS-compliant** and **contain no dots** |
| **Cost** | **Extra per-GB fee**. AWS charges only if it was actually faster. |
| **Best for** | **Long distances** between client and bucket, and large files |
| **Speed test tool** | The **S3 Transfer Acceleration Speed Comparison** tool |

- It helps most when the user is **far from the bucket's region**. Close to the bucket, it gives little or nothing.

### 4. Optimizing Downloads: Byte-Range Fetches

- Request **specific byte ranges** of an object, using the HTTP **`Range`** header.
- Two benefits:

| Benefit | How |
|---|---|
| **Speed up downloads** | Request several ranges **in parallel** (first part, second part, last part) and reassemble |
| **Better resilience** | If one range fails, **retry just that smaller range** |

```
Big S3 object:  [ bytes 0-1MB ][ bytes 1-2MB ][ bytes 2-3MB ] ...
                      |              |              |       (parallel GETs, each with a Range header)
                      +--------------+--------------+--> client combines the parts
```

**Second use case: partial retrieval.**
- You only need part of the file. Lecture example: the **first 50 bytes** are a **header** with information about the file. Request **just that range** and get the info **very quickly**, without downloading the whole object.

```bash
aws s3api get-object --bucket my-bucket --key big.bin \
  --range bytes=0-49 header.bin
```

```http
GET /big.bin HTTP/1.1
Range: bytes=0-49
```

- A successful range request returns **HTTP 206 Partial Content**.
- The mirror image for uploads is **multipart upload**. Range fetches are the **download side**.

### 5. Upload vs Download Optimization

| Goal | Technique | Idea |
|---|---|---|
| **Faster upload of big files** | **Multipart upload** | Parallel parts |
| **Faster upload over long distance** | **Transfer Acceleration** | Nearest edge, then the AWS backbone |
| **Faster download of big files** | **Byte-range fetches** | Parallel ranges |
| **Read only part of a file** | **Byte-range fetches** | Fetch just the header or slice |
| **Higher request rate** | **More prefixes** | 3,500 and 5,500 per prefix |
| **Throttled requests** | **Exponential backoff** | Retry with growing delays |

- **Combine them:** Transfer Acceleration with multipart upload gives the biggest gain for large, far-away uploads.
- **Extras:** for global reads of the same content, use **CloudFront** (caching at the edge). For very high-throughput, low-latency workloads, there is **S3 Express One Zone**. Neither is covered in this lecture.

### 6. Key Facts to Remember

- S3 baseline: **100-200 ms first-byte latency**.
- **3,500 PUT/COPY/POST/DELETE** and **5,500 GET/HEAD** per second **per prefix**.
- **Unlimited prefixes**, so total throughput scales with prefixes (4 prefixes = **22,000 reads per second**).
- **Prefix** = the path between the bucket and the file name.
- **Multipart upload:** **recommended above 100 MB**, **mandatory above 5 GB**, **parallel** uploads.
- **Transfer Acceleration:** **edge location** to S3 over the **private AWS network**. Works for **upload and download**. **Compatible with multipart**.
- **Byte-range fetches:** **parallel GETs**, **retry smaller ranges**, or fetch **only a portion** (for example a header).
- Over **200 edge locations** (per the lecture), more than regions.

### 7. Exam-Style Recall

| If the question says... | Think... |
|---|---|
| "Increase S3 request throughput" | **Spread objects across more prefixes** |
| "Max GET requests per second per prefix" | **5,500** |
| "Max PUT/POST/COPY/DELETE per second per prefix" | **3,500** |
| "4 prefixes, evenly spread reads: total?" | **22,000** GET/HEAD per second |
| "Upload a 6 GB file" | **Multipart upload** (required above 5 GB) |
| "Speed up uploading a large file" | **Multipart upload** (parallel) |
| "Speed up upload from a far-away region to a bucket" | **S3 Transfer Acceleration** |
| "How does Transfer Acceleration work?" | **Edge location**, then the **AWS private network** to the bucket |
| "Can Transfer Acceleration be combined with multipart?" | **Yes** |
| "Speed up downloading a large object" | **Byte-range fetches** (parallel) |
| "Read only the first few bytes (header) of a big file" | **Byte-range fetch** |
| "Retry only the failed part of a download" | **Byte-range fetches** |
| "Receiving 503 Slow Down from S3" | **Exponential backoff** and **more prefixes** |
| "Cache S3 content close to global users" | **CloudFront** |

---

## S3 Object Tags & Metadata

### TL;DR

- Both **metadata** and **tags** are **key-value pairs** attached to an S3 object. They serve different purposes.
- **User-defined metadata:** the key **must start with `x-amz-meta-`** (for example `x-amz-meta-origin: paris`). It is returned with the object on retrieval and describes the object.
- **System-defined metadata** is set by AWS, for example **`Content-Length`** and **`Content-Type`**.
- **Object tags** are key-value pairs (for example `Project: Blue`, `PHI: True`). They can drive **fine-grained permissions** and **analytics grouping**.
- **Most important exam fact: neither metadata nor tags are searchable in S3.** You can't filter or query objects by them.
- To search by metadata or tags, **build an external index**, typically in **DynamoDB**. Store each object's key plus its metadata and tags there, search DynamoDB, then fetch the matching objects from S3.

### 1. Metadata

#### 1.1 What it is

- When you upload an object you can attach **metadata**: "just a fancy name for key-value pairs attached to your objects".
- It is **returned when you retrieve the object** (GET or HEAD), so it gives you information about the object itself.

| Type | Who sets it | Naming | Example |
|---|---|---|---|
| **System-defined** | **AWS** | Standard HTTP-style names | `Content-Length: 7.5 KB`, `Content-Type: text/html` |
| **User-defined** | **You** | Must **begin with `x-amz-meta-`** | `x-amz-meta-origin: paris` |

- The prefix is required because **AWS generates its own metadata**, and the prefix keeps yours separate from it.
- The lecture's example object has three entries: `Content-Length` (about 7.5 KB), `Content-Type` (HTML), and `x-amz-meta-origin: paris`.

#### 1.2 Details (extras)

| Topic | Detail |
|---|---|
| **Set when** | **At upload.** To change it later, you must **copy the object onto itself** with new metadata. |
| **In HTTP** | User metadata travels as `x-amz-meta-*` **headers** |
| **Case** | Keys are returned in **lowercase** |
| **Size limit** | User-defined metadata is limited to **2 KB** in total |
| **Encoding** | Values should be **US-ASCII**, or use MIME encoding for other characters |
| **Versioning** | Metadata belongs to **each version** |
| **Other system metadata** | `Last-Modified`, `ETag`, `x-amz-server-side-encryption`, `x-amz-storage-class`, `Cache-Control`, `Content-Encoding` |

**CLI example:**

```bash
aws s3 cp index.html s3://my-bucket/index.html --metadata origin=paris
aws s3api head-object --bucket my-bucket --key index.html
```

- The CLI adds the `x-amz-meta-` prefix for you. Reading it back shows `Metadata: { "origin": "paris" }`.

### 2. Object Tags

#### 2.1 What they are

- **Key-value pairs** on S3 objects, like tags on other AWS resources.
- The lecture: tags are **more common** than custom metadata, "because this is tags as you've seen them in AWS".
- Example for one object: **`Project: Blue`** and **`PHI: True`** (PHI = personal health information).

#### 2.2 Why tags exist (versus metadata)

| Use | How tags help |
|---|---|
| **Fine-grained permissions** | Allow access **only to objects with certain tags**, using IAM or bucket policy conditions |
| **Analytics** | Group results by tag. For example **S3 Analytics (Storage Class Analysis)** can filter and group by tags. |
| **Lifecycle rules** | Apply a lifecycle rule **only to tagged objects** (earlier lectures) |
| **Cost allocation** | Track storage cost by tag (extra) |
| **Replication filters** | Replicate only tagged objects (extra) |

- Metadata describes the object. **Tags can control access and drive S3 features.**

**Permission example (extra):**

```json
{
  "Effect": "Allow",
  "Action": "s3:GetObject",
  "Resource": "arn:aws:s3:::my-bucket/*",
  "Condition": {
    "StringEquals": { "s3:ExistingObjectTag/Project": "Blue" }
  }
}
```

**Tag limits (extras):**

| Limit | Value |
|---|---|
| **Tags per object** | **10** |
| **Key length** | Up to 128 Unicode characters |
| **Value length** | Up to 256 Unicode characters |
| **Changeable after upload** | **Yes**, without rewriting the object |

### 3. Metadata vs Tags

| | **User-defined metadata** | **Object tags** |
|---|---|---|
| **Format** | Key-value pairs | Key-value pairs |
| **Naming** | **`x-amz-meta-`** prefix | Free-form keys |
| **Returned with the object?** | **Yes** (GET and HEAD) | **No**, retrieved by a **separate call** (`GetObjectTagging`) |
| **Editable after upload?** | Only by **copying** the object | **Yes**, directly |
| **Used for permissions?** | **No** | **Yes** (tag conditions) |
| **Used for analytics and lifecycle?** | No | **Yes** |
| **Searchable in S3?** | **No** | **No** |
| **Limit** | About **2 KB** total | **10** tags |

### 4. Neither Is Searchable

- **You can't filter or search S3 objects by metadata or by tags.** There is no query for "objects where origin = paris".
- This is the lecture's **most important point**, and a common exam question.
- S3 itself can only **list by key prefix**.
- **Then how do you find objects by attribute?** Build an **external index**.

### 5. The Search Architecture (Exam Pattern)

```
Upload object --> S3 bucket --(S3 Event Notification)--> Lambda
                                                           |
                                              reads key + metadata + tags
                                                           v
                                                [DynamoDB table (searchable index)]
                                                           ^
Application: "find objects where Project = Blue" ----------+
        |
        v   gets the S3 keys from DynamoDB
   GetObject from S3 for the matching keys
```

1. **Index:** when an object is uploaded, record its **S3 key plus metadata and tags** in a **DynamoDB** table.
2. **Search:** query DynamoDB (for example by `Project = Blue`, using a **GSI** if needed).
3. **Fetch:** use the returned keys to **read the objects from S3**.

- The lecturer says DynamoDB is the common choice but "it could be whatever you want". It comes later in the course.
- **Keeping the index up to date:** use **S3 Event Notifications** (earlier lecture) to trigger a **Lambda** that writes to DynamoDB on each upload.
- **Other options (extras):** **OpenSearch/Elasticsearch** for full-text or complex search, **Athena** over **S3 Inventory** (the list of all objects and some metadata) for batch queries, and **S3 Metadata** (newer feature) for queryable metadata tables.
- **S3 Select / Athena** look **inside** an object's contents. They don't search by tags or metadata across objects.

### 6. Key Facts to Remember

- **Metadata** = key-value pairs on the object. **User-defined metadata must start with `x-amz-meta-`.**
- **System metadata** (for example `Content-Type`, `Content-Length`) is **set by AWS**.
- **Tags** = key-value pairs for **permissions, analytics, lifecycle**.
- **Neither metadata nor tags can be searched** in S3.
- To search, **build an external index**, for example in **DynamoDB**.
- Metadata comes back **with the object**. Tags need a **separate call**.
- Object limits: **10 tags**, and about **2 KB** of user metadata.
- To change metadata after upload, **copy the object**. Tags can be edited **directly**.

### 7. Exam-Style Recall

| If the question says... | Think... |
|---|---|
| "Prefix for user-defined S3 metadata" | **`x-amz-meta-`** |
| "Who sets `Content-Type` and `Content-Length`?" | **AWS** (system-defined metadata) |
| "Search or filter S3 objects by tag or metadata" | **Not possible in S3.** Build an **external index (DynamoDB)**. |
| "Find all objects with `Project = Blue`" | Query a **DynamoDB index** of keys, tags, and metadata |
| "Allow access only to objects with a certain tag" | **Object tags** with an IAM or bucket policy condition |
| "Group S3 Analytics results by a label" | **Object tags** |
| "Maximum number of tags per object" | **10** |
| "Keep a DynamoDB index in sync with S3 uploads" | **S3 Event Notification, then Lambda** writes to DynamoDB |
| "Where do tags help besides permissions?" | **Analytics, lifecycle rules, replication, cost allocation** |
| "Change user metadata on an existing object" | **Copy the object** with new metadata |
