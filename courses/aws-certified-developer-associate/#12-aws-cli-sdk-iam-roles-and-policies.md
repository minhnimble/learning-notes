# AWS CLI, SDK, IAM Roles & Policies

---

## AWS EC2 Instance Metadata

### TL;DR

- **EC2 Instance Metadata Service (IMDS)** lets an EC2 instance **learn about itself** by calling a special URL, **without needing an IAM role** to do so.
- The address is **`169.254.169.254`**, a **link-local** IP that only works **from inside the instance**.
- Metadata includes the **instance ID, instance type, AZ, public and private IPs, hostname, security groups, and the IAM role name**.
- It can also return the **temporary credentials** of the attached IAM role. It does **not** reveal which **IAM policies** are attached to the role.
- **Metadata** = information about the instance. **User data** = the launch script. **Both** are served from the same IP.
- **Two versions:**
  - **IMDSv1:** call the URL directly. Simple, but less secure.
  - **IMDSv2:** **two steps**. First a **`PUT`** to get a **session token**, then **`GET`** with the token in a **header**. More secure, and the default on newer AMIs such as **Amazon Linux 2023**.

### 1. What Is IMDS?

| Property | Detail |
|---|---|
| **What it is** | A service that exposes **information about the running instance** to the instance itself |
| **Address** | **`http://169.254.169.254`** (IPv6: `http://[fd00:ec2::254]`) |
| **Reachable from** | **Only the instance itself** (link-local address, not routable) |
| **Credentials needed** | **None.** Plain HTTP requests, no IAM role or access keys needed to call it. |
| **Cost** | Free |
| **Use** | Scripts, user data, and apps that need to know their own details |

- The lecturer calls it "a very powerful feature, but not many developers know about it".
- Because the address is link-local, **you can't call it from your laptop**. Use it from a shell on the instance (for example EC2 Instance Connect).

### 2. What Metadata Contains

Examples under `/latest/meta-data/`:

| Path | Returns |
|---|---|
| `instance-id` | The instance ID |
| `instance-type` | For example `t2.micro` |
| `ami-id` | The AMI the instance launched from |
| `hostname` / `local-hostname` | The hostname |
| `local-ipv4` | The **private IP** |
| `public-ipv4` | The **public IP** (if it has one) |
| `placement/availability-zone` | The **AZ** (this was used in the Route 53 demo page) |
| `security-groups` | Names of attached security groups |
| `iam/info` | Info about the attached **instance profile** |
| `iam/security-credentials/` | The **IAM role name** |
| `iam/security-credentials/<role-name>` | **Temporary credentials** for that role |

- The lecture's list: instance name, public IP, private IP, "a lot of things", and the **IAM role name**.
- User-defined **tags** can be exposed too if you enable "Allow tags in instance metadata" (an extra).

### 3. IAM Role Information

| Question | Answer |
|---|---|
| Can I get the **IAM role name**? | **Yes** |
| Can I get **temporary credentials** for the role? | **Yes** (access key, secret key, session token, expiry) |
| Can I see **which IAM policies** are attached to the role? | **No** |

- The credentials are **temporary** and **rotate automatically**. This is how the **SDKs and CLI** on an EC2 instance find their credentials, with no config.
- To find out what the role is allowed to do, you need **IAM** (for example `iam:ListAttachedRolePolicies`), and **not** IMDS.
- Security note: **anyone who can run code on the instance** (or trick it into making requests) can read these credentials. That is why IMDSv2 exists.

### 4. Metadata vs User Data

| | **Metadata** | **User data** |
|---|---|---|
| **What it is** | **Information about the instance** | The **launch script** or data given at launch |
| **Path** | `/latest/meta-data/...` | `/latest/user-data` |
| **Set by** | AWS | **You**, at launch |
| **Example** | Instance ID, IPs, AZ | A bootstrap shell script |
| **Size limit** | N/A | **16 KB** (extra) |

- The same URL root serves **both**. This lecture focuses on **metadata**.
- User data **runs once** at first boot (as root) by default. IMDS lets you **read it back** later.
- A related path, `/latest/dynamic/instance-identity/document`, returns a JSON identity document (account ID, region, and so on) (extra).

### 5. IMDSv1 vs IMDSv2

#### 5.1 IMDSv1

- **Call the URL directly.** Everything works out of the box.

```bash
curl http://169.254.169.254/latest/meta-data/
```

- **Weakness:** any simple HTTP request works, which makes it exploitable by **SSRF** (server-side request forgery) bugs. An attacker who tricks an app into fetching the URL can steal the role's credentials.

#### 5.2 IMDSv2

- **Session-oriented, two steps.** More overhead, but **more secure**.
- Introduced for security reasons ("AWS did it for security reasons").
- It is **enabled by default** on newer AMIs such as **Amazon Linux 2023** (**IMDSv2 required**).

**Step 1: get a session token with a `PUT` request**

```bash
TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" \
  -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
```

**Step 2: call the metadata URL with the token in a header**

```bash
curl -s -H "X-aws-ec2-metadata-token: $TOKEN" \
  http://169.254.169.254/latest/meta-data/instance-id
```

| Detail | Value |
|---|---|
| **Token request** | **`PUT`** to `/latest/api/token` |
| **TTL header** | `X-aws-ec2-metadata-token-ttl-seconds`, from **1 to 21,600 s (6 hours)** |
| **Token use** | Sent as the **`X-aws-ec2-metadata-token`** header on every metadata `GET` |
| **Token scope** | Valid only on **that instance** |

- The lecturer says he will demo this "more complicated version" because it is **important to know how it works**.

#### 5.3 Why IMDSv2 is safer

| Protection | How |
|---|---|
| **Needs a `PUT` with a custom header** | Most **SSRF** bugs can only send simple `GET` requests, so they can't get a token |
| **Rejects requests with an `X-Forwarded-For` header** | Blocks requests that were relayed by a proxy |
| **Hop limit** | The token response has an **IP TTL of 1 hop by default**, so it **can't leave the instance** (for example via a forwarded or relayed request) |
| **Token required** | A plain `GET` without a token **fails** (401) when IMDSv2 is **required** |

- **Containers:** a container on the instance is one **extra network hop**. Set the **hop limit to 2** so the container can reach IMDSv2.

### 6. IMDS Settings on an Instance

| Setting | Options | Meaning |
|---|---|---|
| **Metadata accessible** | Enabled / Disabled | Turns the endpoint on or off |
| **IMDSv2 (HttpTokens)** | **Optional** (v1 and v2 both work) or **Required** (v2 only) | Choose **Required** for best security |
| **Hop limit** | 1 to 64 (default 1) | Increase for containers |

- Set at **launch** (Advanced details) or **later** with **Modify instance metadata options**. Changes apply without a reboot.
- Account-wide default: you can set the region's **default IMDS version** so new launches **require IMDSv2**.
- **Amazon Linux 2023** AMIs default to **IMDSv2 required**. Older images (for example **Amazon Linux 2**) default to **optional**.
- **Consequence:** a script that uses IMDSv1 (a plain `curl`) **returns nothing or an error** on an IMDSv2-only instance. This broke the earlier Route 53 user data AZ lookup on AL2023.

### 7. Common Uses

- Read the **instance ID or AZ** in a **user data script**, and put it on a web page (as in the Route 53 demos).
- Find the **private or public IP** for **configuration or registration** (for example registering with a service).
- Let the **SDK or CLI** discover **IAM role credentials**.
- Identify the **region** (derived from the AZ) for scripts.
- Build **self-configuring AMIs**.

### 8. Exam-Style Recall

| If the question says... | Think... |
|---|---|
| "How does an EC2 instance retrieve its own instance ID or IP?" | **Instance metadata** at `169.254.169.254` |
| "Instance needs its own details without an IAM role" | **IMDS** |
| "Get the IAM role name or credentials from inside an instance" | `/latest/meta-data/iam/security-credentials/` |
| "Find which policies are attached to the role via IMDS" | **Not possible** |
| "Difference between metadata and user data" | Metadata = **info about the instance**. User data = **launch script**. |
| "More secure version of the metadata service" | **IMDSv2** |
| "IMDSv2 needs how many steps?" | **Two**: `PUT` for a token, then `GET` with the token header |
| "HTTP method to get the IMDSv2 token" | **`PUT`** |
| "Header that carries the IMDSv2 token" | **`X-aws-ec2-metadata-token`** |
| "Prevent SSRF from stealing instance credentials" | **Require IMDSv2** |
| "Script using plain `curl` to IMDS fails on a new instance" | The instance **requires IMDSv2** (use a token) |
| "Container can't reach IMDSv2" | Increase the **hop limit to 2** |
| "Access metadata from your laptop" | **Not possible** (link-local, instance only) |
| "401 Unauthorized when calling `169.254.169.254`" | The instance **requires IMDSv2**. Get a **token** first. |
| "How to get an IMDSv2 token" | **`PUT`** to `/latest/api/token` with the TTL header |
| "Where to find the IAM role credentials from inside EC2" | `/latest/meta-data/iam/security-credentials/<role-name>` |
| "Metadata call returns 404 for IAM credentials" | **No IAM role** attached |
| "Give a running instance an IAM role" | **Actions, Security, Modify IAM role** |
| "Retrieve the instance's private IP from inside" | `meta-data/local-ipv4` |
| "Is the credentials JSON permanent?" | **No**, temporary with an **expiration** |
| "Make IMDSv1 requests work on a new instance" | Choose **V1 and V2** (token optional), or use Amazon Linux 2 |

---

## AWS EC2 Instance Metadata - Hands On

### 1. Launch the Instance

| Setting | Demo value | Notes |
|---|---|---|
| **Name** | `DemoEC2` | |
| **AMI** | **Amazon Linux 2023** | The latest AL AMI in the demo |
| **Key pair** | **None** | Use EC2 Instance Connect |
| **Security group** | **Create new**, allow **SSH (22)** from anywhere | Enough for Instance Connect |
| **IAM instance profile** | **None** at first | Attached later in the demo |
| **Metadata version** | Left at the default | See section 2 |

### 2. The Metadata Version Setting

- Location: **Advanced details**, **Metadata version**: **V1 and V2 (token optional)** or **V2 only (token required)**. Amazon Linux 2023 defaults to V2 only, Amazon Linux 2 to V1 and V2. (The lecturer misspoke and said Amazon Linux 2.)
- Change it later: **Actions, Instance settings, Modify instance metadata options**. Related fields: **hop limit** (default 1) and **Allow tags in metadata**.

### 3. Connect to the Instance

1. Select the instance, **Connect**, **EC2 Instance Connect**, **Connect**.
2. You get a browser shell inside the instance.

### 4. IMDSv1 Fails (401 Unauthorized)

```bash
curl http://169.254.169.254/latest/meta-data/
```

- Result: **401 Unauthorized**. Add `-v` to see the HTTP status.
- Reason: this instance **requires IMDSv2**, so any request without a token is rejected.

### 5. IMDSv2: Get a Token, Then Query

- Ran the two commands from the lecture (copied from the IMDSv2 documentation, so keep a copy): the `PUT` for the token, then the `GET` with the `X-aws-ec2-metadata-token` header.
- `echo $TOKEN` prints a long random string. The token lives only in the shell variable, so after reconnecting you must **get a new token**.
- With the token the `GET` returns the list of metadata entries instead of **401**. A typo or wrong path gives an error or **404**.

### 6. Navigating the Metadata Tree

| Rule | Meaning |
|---|---|
| **Trailing `/`** | A **directory**. More entries inside. |
| **No trailing `/`** | A **value**. The data itself. |

```bash
# list the top level
curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/

# read a value (no trailing slash)
curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/hostname
curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/local-ipv4
```

- `hostname` returns the **instance's hostname**. The lecturer's point: "this is how the EC2 instance knows its own host name".
- `local-ipv4` returns the **private IP**.

### 7. Credentials and IAM Roles

#### 7.1 What the demo showed

1. Browse to `identity-credentials/` (with the trailing slash). It contains `ec2/`, which has **`info`** and **`security-credentials/`**.
2. `info` returned a success status.
3. `security-credentials` returned **Not Found**, which the lecturer read as "no IAM role attached".
4. **Attach a role:** select the instance, **Actions, Security, Modify IAM role**, pick any role (the choice doesn't matter), **Update IAM role**. Wait about **30 seconds**.
5. Repeat the call. A first attempt gave **Not Found** again because of a **missing trailing slash**. With the slash, `ec2-instance` appeared.
6. Calling the last path returned a **JSON** with **access key ID, secret access key, token, and expiration**.

#### 7.2 Correction: which path holds the IAM role credentials

The lecture's explanation mixes up two different paths. The **IAM role credentials** live under **`iam/`**:

```bash
# list the role name
curl -s -H "X-aws-ec2-metadata-token: $TOKEN" \
  http://169.254.169.254/latest/meta-data/iam/security-credentials/

# get temporary credentials for that role
curl -s -H "X-aws-ec2-metadata-token: $TOKEN" \
  http://169.254.169.254/latest/meta-data/iam/security-credentials/<role-name>
```

- `iam/info`, `iam/security-credentials/` (role name), and `iam/security-credentials/<role-name>` (temporary credentials) are the IAM role paths from the lecture.
- `identity-credentials/ec2/security-credentials/ec2-instance` is the instance's own **identity credentials**, used by AWS services such as Systems Manager. It is **not** your IAM role.

#### 7.3 The credentials JSON

```json
{
  "Code": "Success",
  "Type": "AWS-HMAC",
  "AccessKeyId": "ASIA...",
  "SecretAccessKey": "...",
  "Token": "...",
  "Expiration": "2026-10-06T15:04:05Z"
}
```

- `ASIA...` access keys are **temporary** (STS) credentials.
- The lecturer guesses the expiry is "maybe 24 hours, probably more like one hour". It is **hours** (typically about 6 on EC2), and AWS **rotates them automatically** before expiry.
- **Never share or paste these credentials.** Anyone holding them can act as the role until they expire.

---

## AWS CLI Profiles

### TL;DR

- A **profile** is a **named set of credentials and settings** for the AWS CLI. Use profiles to work with **multiple AWS accounts** (or roles) from one machine.
- The CLI stores them in two files in **`~/.aws/`**: **`credentials`** (access keys) and **`config`** (region, output format).
- `aws configure` sets up the **`default`** profile. **`aws configure --profile <name>`** creates or edits a **named** profile.
- Run any command against a profile by adding **`--profile <name>`**. Without the flag, the CLI uses **`default`**.
- The lecturer: **not an exam topic**, but a **real-world developer tip**. Once you have several accounts, always use `--profile` so you hit the right one.

### 1. The Problem

- `aws configure` stores **one set of credentials** as `default`, linked to **one AWS account**.
- With **several accounts** (dev, staging, prod, client accounts), a single default is not enough.
- Overwriting `default` each time is slow and risky: you can **run a command against the wrong account**.
- **Solution:** **named profiles**.

### 2. Where Profiles Live

| File | Location | Holds |
|---|---|---|
| **credentials** | `~/.aws/credentials` | **Access key ID** and **secret access key** per profile |
| **config** | `~/.aws/config` | **Region**, **output format**, and other settings per profile |

(On Windows: `%UserProfile%\.aws\`.)

#### 2.1 Before: only `default`

```ini
# ~/.aws/credentials
[default]
aws_access_key_id = AKIA...
aws_secret_access_key = ...

# ~/.aws/config
[default]
region = eu-west-1
output = json
```

#### 2.2 After adding a profile named `my-other-aws-account`

```ini
# ~/.aws/credentials
[default]
aws_access_key_id = AKIA...
aws_secret_access_key = ...

[my-other-aws-account]
aws_access_key_id = AKIA...
aws_secret_access_key = ...

# ~/.aws/config
[default]
region = eu-west-1
output = json

[profile my-other-aws-account]
region = us-west-2
```

- **Section naming differs between the files:**

| File | Default profile | Named profile |
|---|---|---|
| **credentials** | `[default]` | `[my-other-aws-account]` |
| **config** | `[default]` | **`[profile my-other-aws-account]`** (note the word `profile`) |

- The lecture shows the new brackets in **both** files: a new section in `credentials` with the new keys, and a new section in `config` with the region.

### 3. Creating a Profile

```bash
aws configure --profile my-other-aws-account
```

The CLI asks four questions:

| Prompt | Demo value | Notes |
|---|---|---|
| **AWS Access Key ID** | Dummy value | Shows **None** for a new profile. That tells you it is a **different, empty** profile. |
| **AWS Secret Access Key** | Dummy value | |
| **Default region name** | `us-west-2` | The region used when you don't pass `--region` |
| **Default output format** | (Enter) | Default is `json` |

- **Demo walkthrough:**
  1. Plain `aws configure` shows the existing **default** key ID. Pressing **Enter** keeps the current value.
  2. `aws configure --profile ...` shows **None**, so it's a fresh profile.
  3. The lecturer **pasted random dummy values** for the keys. In real life you'd use **real keys** from IAM.
- **Naming:** use any name, preferably **short** (for example `dev`, `prod`, `client-a`).
- With **dummy keys**, real commands against that profile **fail** (invalid credentials).

### 4. Using a Profile

#### 4.1 `--profile` flag

```bash
aws s3 ls                                    # uses the default profile
aws s3 ls --profile my-other-aws-account     # uses the named profile
```

- Works with **any** command, as long as the profile was configured first.
- Without `--profile`, the CLI uses **`default`**.

#### 4.2 Other ways to select a profile

| Method | Example | Scope |
|---|---|---|
| **`--profile` flag** | `aws s3 ls --profile dev` | One command |
| **`AWS_PROFILE` environment variable** | `export AWS_PROFILE=dev` | The **whole shell session** |
| **SDKs** | `AWS_PROFILE=dev python app.py` or set the profile in code | The app |

- The **flag overrides** the environment variable.
- `AWS_PROFILE` is handy when you run **many commands** against one account.

#### 4.3 Check which account you are using

```bash
aws sts get-caller-identity --profile my-other-aws-account
```

- Returns the **account ID, user or role ARN, and user ID**.
- **Run this first** when unsure, to avoid running commands in the wrong account.

#### 4.4 List what is configured

```bash
aws configure list                           # shows the resolved settings for the current profile
aws configure list --profile dev             # for a specific profile
aws configure list-profiles                  # all profile names
```

### 5. Beyond Access Keys (Extras)

| Setup | How |
|---|---|
| **Assume a role** in another account | `role_arn` and `source_profile` in `config`. The CLI calls STS for you. |
| **IAM Identity Center (SSO)** | `aws configure sso`, then `aws sso login --profile <name>`. Uses **short-lived credentials**, with no long-term keys on disk. |
| **MFA** | Profile settings (`mfa_serial`) so the CLI asks for a code |

```ini
[profile prod-admin]
role_arn = arn:aws:iam::123456789012:role/AdminRole
source_profile = default
region = eu-west-1
```

- For many accounts, **SSO or role assumption** is safer than storing long-term keys per account.
- In `config`, named profiles are written **`[profile <name>]`**. In `credentials`, **`[<name>]`**.

### 6. Credential Lookup Order (Exam-Relevant Context)

The CLI and SDKs search for credentials in this general order:

1. **Command-line options** (`--profile`, `--region`, and so on)
2. **Environment variables** (`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_SESSION_TOKEN`, `AWS_PROFILE`)
3. **Assume-role and web identity settings** from a profile
4. **The shared files**: `~/.aws/credentials`, then `~/.aws/config`
5. **Container credentials** (ECS task role)
6. **Instance profile credentials** (**EC2 role via IMDS**, as in the previous lecture)

- This lookup order **does** come up in the exam.
- On an **EC2 instance with a role**, no profile is needed, and the CLI finds credentials **through IMDS**.
- **Never put access keys on an EC2 instance** or in code. Use an **IAM role**.

### 7. Good Practices

- **Never commit** `~/.aws/credentials` or keys to Git.
- Use **clear profile names** that show the account (`prod`, `dev`).
- **Double-check the account** (`sts get-caller-identity`) before destructive commands.
- Prefer **SSO or assumed roles** over long-lived access keys.
- Set a **default region** per profile so you don't pass `--region` all the time.
- Consider a shell prompt that shows the **active profile**.

### 8. Exam-Style Recall

| If the question says... | Think... |
|---|---|
| "Use the CLI with multiple AWS accounts" | **Named profiles** (`--profile`) |
| "Create a named profile" | **`aws configure --profile <name>`** |
| "Where does the CLI store credentials?" | **`~/.aws/credentials`** |
| "Where does the CLI store region and output format?" | **`~/.aws/config`** |
| "Run a command against a non-default profile" | **`--profile <name>`** |
| "Set a profile for a whole shell session" | **`AWS_PROFILE`** environment variable |
| "Which profile is used if none is specified?" | **`default`** |
| "Check which account the CLI is using" | **`aws sts get-caller-identity`** |
| "CLI on EC2 without any configured keys" | Uses the **instance role** through **IMDS** |
| "Which wins: `--profile` or the `AWS_PROFILE` variable?" | **`--profile`** (command-line option) |

---

## AWS CLI with MFA

### TL;DR

- To use **MFA with the CLI or an SDK**, you create a **temporary session** by calling the STS API **`GetSessionToken`**. This is the exam answer.
- You pass the **MFA device serial number** (the ARN for a virtual device), the **current token code**, and optionally a **duration**.
- It returns **temporary credentials**: **AccessKeyId, SecretAccessKey, SessionToken, Expiration**.
- To use them, either set them as **environment variables**, or store them in a **profile** that includes **`aws_session_token`** in `~/.aws/credentials`.
- Every API call made with these credentials is **MFA-authenticated**, which lets you satisfy IAM policies that **require MFA**.
- The lecturer says the demo is involved and **optional**. The one thing to remember is **`sts get-session-token`**.

### 1. The Problem

- Your IAM user has an **MFA device**, and some policies **require MFA** (for example for sensitive or destructive actions).
- The CLI and SDKs normally sign requests with **long-term access keys**, and there is **no MFA prompt**.
- **Solution:** trade your long-term keys plus an **MFA code** for **temporary credentials** that carry the MFA context.

```
IAM user keys + MFA device ──> STS GetSessionToken ──> temporary credentials (MFA-authenticated)
                                                          └─> used for all further API calls
```

### 2. STS GetSessionToken

| Item | Detail |
|---|---|
| **API** | `sts:GetSessionToken` (CLI: `aws sts get-session-token`) |
| **Who calls it** | An **IAM user** (or the account root user), using long-term keys |
| **Required for MFA** | **`--serial-number`** and **`--token-code`** |
| **Optional** | **`--duration-seconds`** |
| **Returns** | **AccessKeyId, SecretAccessKey, SessionToken, Expiration** |
| **Credentials are** | **Temporary** (expire automatically) |

```bash
aws sts get-session-token \
  --serial-number arn:aws:iam::123456789012:mfa/my-user \
  --token-code 123456 \
  --duration-seconds 3600
```

| Argument | Meaning |
|---|---|
| **`--serial-number`** | The **MFA device identifier**. A **virtual MFA** uses its **ARN** (`arn:aws:iam::<account-id>:mfa/<name>`). A **hardware** token uses its **serial number**. |
| **`--token-code`** | The **6-digit code** currently shown by the MFA app or token |
| **`--duration-seconds`** | How long the credentials last (see below) |

**Duration limits (extras):**

| Caller | Min | Max | Default |
|---|---|---|---|
| **IAM user** | 900 s (15 min) | **129,600 s (36 h)** | **43,200 s (12 h)** |
| **Root user** | 900 s | **3,600 s (1 h)** | 3,600 s |

**Sample output:**

```json
{
  "Credentials": {
    "AccessKeyId": "ASIA...",
    "SecretAccessKey": "...",
    "SessionToken": "very-long-token...",
    "Expiration": "2026-10-06T10:38:00+00:00"
  }
}
```

- **`ASIA...`** access key IDs are **temporary (STS)** keys. Long-term IAM user keys start with **`AKIA...`**.
- The lecture's credentials expired **one hour** after being issued. The transcript doesn't show the command line, so that was probably set with `--duration-seconds`. Without it, the default for an IAM user is 12 hours.
- Credentials from `GetSessionToken` **can't be used to call most IAM and STS operations** unless MFA information is included, and they **can't be used to call `AssumeRole`'s IAM-user-restricted features** such as creating new users (check the STS docs for the exact rule).
- It is a **demo-heavy, optional** lecture. The exam only needs the **API name**.

### 3. Step 1: Register an MFA Device (Console)

The lecturer does this as a one-time setup. Skip it if the user already has an MFA device.

1. IAM, **Users**, select your user, **Security credentials** tab.
2. **Multi-factor authentication (MFA)**, **Assign MFA device**.
3. Choose **Authenticator app** (virtual MFA device), then **Next**.
4. **Show QR code** and scan it with your authenticator app (the lecturer uses **Authy**).
5. Enter **two consecutive MFA codes** from the app, then **Add MFA**.
6. Copy the **MFA device ARN** shown (for example `arn:aws:iam::123456789012:mfa/<user>`). **You need it as `--serial-number`.**

**MFA device types:**

| Type | Works with `GetSessionToken` in the CLI? |
|---|---|
| **Virtual MFA** (Authy, Google Authenticator, and others) | **Yes** |
| **Hardware TOTP token** | **Yes** |
| **FIDO2 security key / passkey** | Not for CLI/API token codes (**console sign-in only**) |

- The lecture's point: this ARN is the value you paste into the next command.

### 4. Step 2: Get Temporary Credentials

1. In your terminal, run `aws sts get-session-token`. Use `--help` if you forget the argument names.
2. Supply **`--serial-number`** (the MFA ARN) and **`--token-code`** (the **current** code from your app).
3. The command prints the temporary credentials.

- **Codes rotate every 30 seconds.** If you get **AccessDenied** or an invalid MFA error, wait for the next code and try again.
- The lecturer re-ran it for the demo and copied the new values to a text file. **Temporary credentials are fine to show in a demo** since they expire, but treat them as secrets in real use.

### 5. Step 3: Use the Credentials

#### 5.1 Option A: a named profile (what the demo does)

```bash
aws configure --profile mfa
# AWS Access Key ID:     <AccessKeyId from the output>
# AWS Secret Access Key: <SecretAccessKey from the output>
# Default region name:   <your region>
# Default output format: (Enter)
```

`aws configure` has **no prompt for the session token**, so edit `~/.aws/credentials` by hand and add it:

```ini
[mfa]
aws_access_key_id = ASIA...
aws_secret_access_key = ...
aws_session_token = <the long SessionToken value>
```

- The lecturer opens the file in **VS Code**.
- **The session token is required.** Temporary credentials without it fail with an invalid-token error.
- Now any call with `--profile mfa` uses the temporary, MFA-backed credentials.

```bash
aws s3 ls --profile mfa
```

- The demo output lists many S3 buckets, which confirms the call succeeded. The lecturer notes he has more buckets than you will, because he is re-recording.
- Profiles were covered in the previous lecture (**AWS CLI Profiles**).

#### 5.2 Option B: environment variables

```bash
export AWS_ACCESS_KEY_ID=ASIA...
export AWS_SECRET_ACCESS_KEY=...
export AWS_SESSION_TOKEN=...
aws s3 ls
```

- Good for a **single shell session**. The values disappear when you close it.
- Environment variables rank **above the shared credentials file** in the lookup order.

#### 5.3 Option C: a script (extra)

```bash
creds=$(aws sts get-session-token \
  --serial-number arn:aws:iam::123456789012:mfa/my-user \
  --token-code "$1" --duration-seconds 3600)

export AWS_ACCESS_KEY_ID=$(echo "$creds" | jq -r .Credentials.AccessKeyId)
export AWS_SECRET_ACCESS_KEY=$(echo "$creds" | jq -r .Credentials.SecretAccessKey)
export AWS_SESSION_TOKEN=$(echo "$creds" | jq -r .Credentials.SessionToken)
```

- Run with `source ./mfa.sh 123456`.
- Many teams use helper tools or **IAM Identity Center (SSO)** to avoid doing this by hand.
- Profile setup uses `aws configure --profile <name>`, and **you must add the session token by hand**.

### 6. Why Bother? Enforcing MFA with IAM Policies (Extras)

An IAM policy can **deny** actions unless MFA was used, using the condition key **`aws:MultiFactorAuthPresent`**:

```json
{
  "Effect": "Deny",
  "Action": "*",
  "Resource": "*",
  "Condition": {
    "BoolIfExists": { "aws:MultiFactorAuthPresent": "false" }
  }
}
```

- With long-term keys, `aws:MultiFactorAuthPresent` is **absent or false**, so the call is **denied**.
- With credentials from **`GetSessionToken` + MFA**, it is **true**, so the call **works**.
- This is the standard pattern for "**require MFA for CLI access**".

### 7. GetSessionToken vs AssumeRole (Exam Context)

| | **`GetSessionToken`** | **`AssumeRole`** |
|---|---|---|
| **Purpose** | Temporary credentials **for the same user**, optionally with **MFA** | Temporary credentials for **another role** (cross-account or elevated access) |
| **Result** | Same identity, MFA-authenticated | **Different identity** (the role's permissions) |
| **MFA** | **Yes** (`--serial-number`, `--token-code`) | **Yes** too, if the role's trust policy requires MFA |
| **Typical use** | "**Use MFA with the CLI or SDK**" | Cross-account access, least privilege |

- Exam rule of thumb: the question says **MFA with CLI or SDK**, so the answer is **STS `GetSessionToken`**.
- A question about **switching to a role in another account** points to **STS `AssumeRole`**.

### 8. Exam-Style Recall

| If the question says... | Think... |
|---|---|
| "Use MFA with the AWS CLI or SDK" | **STS `GetSessionToken`** |
| "API to get temporary credentials authenticated with MFA" | **`GetSessionToken`** |
| "Parameters needed for MFA" | **Serial number** and **token code** |
| "What does GetSessionToken return?" | **AccessKeyId, SecretAccessKey, SessionToken, Expiration** |
| "Where do you put the session token for the CLI?" | **`aws_session_token`** in the credentials file, or **`AWS_SESSION_TOKEN`** |
| "CLI call fails with temporary keys that have no token" | The **session token is missing** |
| "Require MFA for sensitive API calls" | IAM policy with **`aws:MultiFactorAuthPresent`** |
| "What identifies a virtual MFA device in the API?" | Its **ARN** |
| "Temporary credentials key prefix" | **`ASIA`** (long-term keys use `AKIA`) |
| "Cross-account access with MFA" | **STS `AssumeRole`** with MFA in the trust policy |
| "Do temporary credentials expire?" | **Yes**, at the **Expiration** time |

---

## AWS SDK Overview

### TL;DR

- An **SDK (Software Development Kit)** lets your **application code** call **AWS APIs directly**, without the CLI.
- Official AWS SDKs exist for many languages: **Java, .NET, Node.js (JavaScript), PHP, Python, Go, Ruby, C++**, and more over time.
- The **AWS CLI is written in Python** and built on the **Python SDK, Boto3** (fun fact from the lecture).
- You use an SDK whenever your code issues **API calls to AWS services** such as **S3** or **DynamoDB**.
- The exam expects you to know **when to use an SDK**. The practice comes later, mainly in the **Lambda** section.
- If you don't set a **region**, the SDK defaults to **`us-east-1`** (extra detail, a common exam gotcha).

### 1. What Is an SDK?

| Concept | Meaning |
|---|---|
| **SDK** | A **software development kit**: libraries that wrap the AWS APIs for a programming language |
| **Why** | Perform actions on AWS **from inside your application**, with no shell or CLI |
| **What it does** | Builds and **signs** requests (SigV4), handles **retries**, **pagination**, and **credentials** for you |
| **Under the hood** | Every SDK call is an **HTTPS API call** to an AWS service endpoint |

```
Your application code ──(AWS SDK)──> HTTPS API call ──> AWS service (S3, DynamoDB, ...)
```

- Without an SDK you would have to **sign and send raw HTTP requests** yourself, which is slow and error-prone.
- The lecture's question: "What if you wanted to perform actions on AWS directly from your application's code, without using the CLI?" The answer is an **SDK**.

### 2. Supported Languages

| Language | SDK name (extra) |
|---|---|
| **Python** | **Boto3** |
| **JavaScript / Node.js** | AWS SDK for JavaScript (v3) |
| **Java** | AWS SDK for Java (v2) |
| **.NET** | AWS SDK for .NET |
| **PHP** | AWS SDK for PHP |
| **Go** | AWS SDK for Go (v2) |
| **Ruby** | AWS SDK for Ruby |
| **C++** | AWS SDK for C++ |
| Others (extra) | **Kotlin, Swift, Rust**, and mobile SDKs (the **Amplify** libraries for iOS, Android, and Flutter) |

- The lecturer: "maybe the list will get longer over time". Check the AWS docs for the current list.
- For a mixed-stack team, this means each service can use its **own language's SDK**.

### 3. SDK vs CLI

| | **AWS SDK** | **AWS CLI** |
|---|---|---|
| **Used from** | **Application code** | A **terminal or shell script** |
| **Typical use** | Production apps and Lambda functions | Admin tasks, quick checks, automation |
| **Built on** | The AWS APIs | The **Python SDK (Boto3)** |
| **Credentials** | Same lookup chain | Same lookup chain |

- **The CLI is a thin layer over Boto3.** That is why the CLI and the Python SDK share the same credential and region settings (`~/.aws/credentials`, profiles, environment variables).
- "We've been using the Python SDK when we use the CLI" in the lecture means this **indirect** use.
- Both call the **same underlying AWS APIs**.

### 4. When to Use an SDK (Exam Focus)

Use an SDK when your **application** needs to talk to AWS:

| Example | SDK call (illustrative) |
|---|---|
| Upload or download files | **S3** `PutObject` or `GetObject` |
| Read and write items | **DynamoDB** `PutItem` or `Query` |
| Send or receive messages | **SQS** or **SNS** |
| Fetch secrets or parameters | **Secrets Manager** or **SSM Parameter Store** |
| Invoke another function | **Lambda** `Invoke` |

- If a question describes an **application or a Lambda function** making AWS API calls programmatically, the answer is **the AWS SDK**.
- If it describes **scripts or a human at a terminal**, the answer is usually the **CLI**.
- If it describes a **web console** action, that is the **Management Console**.

### 5. Credentials and Region

- The SDK finds credentials through the same **default credential provider chain** as the CLI (see AWS CLI Profiles), with explicit settings in code first.

- On **EC2, ECS, and Lambda**, use an **IAM role**. **Never hardcode access keys** in code.
- **Region:** the SDK needs a region. If none is configured, it uses **`us-east-1`** by default. Set it with `AWS_REGION` or `AWS_DEFAULT_REGION`, the config file, or in code.
- In **Lambda**, credentials and region come from the **execution role** and the `AWS_REGION` variable automatically.
- **Exam:** know **when** to use an SDK, namely **programmatic access from application code**.

### 6. Tiny Examples (Extras)

**Python (Boto3):**

```python
import boto3

s3 = boto3.client("s3", region_name="eu-west-1")
for bucket in s3.list_buckets()["Buckets"]:
    print(bucket["Name"])
```

**Node.js (SDK v3):**

```javascript
import { S3Client, ListBucketsCommand } from "@aws-sdk/client-s3";

const s3 = new S3Client({ region: "eu-west-1" });
const { Buckets } = await s3.send(new ListBucketsCommand({}));
console.log(Buckets.map(b => b.Name));
```

- These are the same API as `aws s3 ls`. The lecture says real code practice comes with **Lambda**.

### 7. Good Practices

- Use **IAM roles**, not long-term keys, for code running on AWS.
- Grant **least privilege** to the role your code uses.
- Rely on the SDK's built-in **retries with exponential backoff** (and tune them if needed).
- Set the **region explicitly** rather than depending on the default.
- Keep the SDK **up to date** for security fixes and new service features.
- Pin versions in production, and use **v3 modular packages** in JavaScript to keep bundles small (extra).

### 8. Exam-Style Recall

| If the question says... | Think... |
|---|---|
| "Call AWS services from application code" | **AWS SDK** |
| "What does the AWS CLI use under the hood?" | **Python SDK, Boto3** |
| "Which languages have official AWS SDKs?" | **Java, .NET, Node.js, PHP, Python, Go, Ruby, C++** and more |
| "Application on EC2 needs AWS access without keys" | **SDK + IAM role** (credentials from IMDS) |
| "SDK region when none is configured" | **`us-east-1`** |
| "Lambda function calls DynamoDB" | **AWS SDK** inside the function |
| "Script run by an admin at a terminal" | **AWS CLI** |

---

## Exponential Backoff & Service Limit Increase

### TL;DR

- AWS has **two kinds of limits (quotas)**: **API rate limits** (how many calls per second) and **service quotas** (how many resources you can run).
- **API rate limit examples:** EC2 `DescribeInstances` is **100 calls/second**. S3 `GetObject` is **5,500 GET/second per prefix**.
- Exceed an API rate limit and you get **throttled**, which shows up as **intermittent errors** (a `ThrottlingException` or similar).
- **Intermittent throttling errors:** use **exponential backoff**.
- **Consistent throttling errors** (sustained heavy use): **request an API throttling limit increase**.
- **Service quota example:** On-Demand Standard instances are capped at **1,152 vCPUs**. To run more, **request a service quota increase** (support ticket, or the **Service Quotas** console/API).
- The **AWS SDK retries with exponential backoff automatically**. If you call the **AWS API directly**, **you must implement it yourself**.

### 1. Two Types of Limits

| | **API rate limits** | **Service quotas (service limits)** |
|---|---|---|
| **What it limits** | **How many API calls** you can make in a time window | **How many resources** you can run or create |
| **Example** | EC2 `DescribeInstances`: **100 calls/s** | On-Demand Standard instances: **1,152 vCPUs** |
| **Example** | S3 `GetObject`: **5,500/s per prefix** | Number of VPCs, Elastic IPs, Lambda concurrency |
| **Symptom when exceeded** | **Throttling** (`ThrottlingException`, `RequestLimitExceeded`, HTTP **429** or **503** `SlowDown`) | **LimitExceeded** or `InstanceLimitExceeded` when creating resources |
| **Typical fix** | **Exponential backoff** (intermittent), or **raise the throttling limit** (sustained) | **Request a quota increase** |
| **Nature** | **Rate** (calls per second) | **Count or capacity** (total resources) |

- The lecturer calls them "AWS limits, or quotas".
- Limits vary by **service, account, and region**, and AWS changes the numbers over time. Check the **Service Quotas** console for current values.

### 2. API Rate Limits and Throttling

- Each AWS API has a **maximum request rate**. Too many calls in a row and AWS **throttles** the extra requests.
- Examples from the lecture:

| API | Limit |
|---|---|
| **EC2 `DescribeInstances`** | **100 calls per second** |
| **S3 `GetObject`** | **5,500 GET per second per prefix** |

- S3 limits are **per prefix**. You can scale by **spreading objects across prefixes** (extra).
- **Intermittent errors** appear when you go over the limit **now and then**, because your traffic is bursty.

#### 2.1 What to do

| Situation | Fix |
|---|---|
| **Occasional** throttling errors (bursts) | **Exponential backoff** (retry with growing delays) |
| **Consistent** throttling errors (steady heavy usage) | **Request an API throttling limit increase** (for example from 100 to 300 calls/s for `DescribeInstances`) |
| Many resources checked in a loop | **Batch**, **cache**, or **reduce** calls (extra) |

- Throttling increases come from **AWS Support**. Not every API rate limit can be raised.
- **Reduce load first (extras):** use **pagination and filters** instead of many small calls, **cache** results, or use **events** (EventBridge) instead of polling.

### 3. Service Quotas (Service Limits)

- A service quota is **how many resources of a type** you can have.
- Lecture example: for **On-Demand Standard instances**, you can run up to **1,152 vCPUs**.
- To run more, **request a service limit increase**:

| Way to request | Detail |
|---|---|
| **Open a support ticket** | The lecture's simplest path |
| **Service Quotas console** | Self-service requests, and many increases are **approved automatically** |
| **Service Quotas API** | Request increases **programmatically** (`RequestServiceQuotaIncrease`), as the lecturer notes |

- Quotas are **per region and per account**. Raising a quota in `us-east-1` doesn't raise it in `eu-west-1`.
- Some quotas are **adjustable**, others are **hard limits** you can't change.
- Plan ahead: **increases can take time** (minutes for automatic ones, days for manual review).
- **Exam note:** EC2 limits are in **vCPUs** per instance family group, not instance counts.

### 4. Exponential Backoff

#### 4.1 When to use it

- When you receive a **throttling error**: you made **too many API calls**.
- **Exam rule:** "throttling exception because of too many API calls" means **exponential backoff**.
- It applies to **intermittent** errors. For **sustained** overload, **raise the limit**.

#### 4.2 Who implements it

| You call AWS through... | Exponential backoff |
|---|---|
| **AWS SDK** | **Built in.** The SDK **retries automatically**. |
| **The AWS CLI** | Built in (it uses the SDK) |
| **Raw HTTP API calls** | **You** must implement it |

- Retry behavior is configurable in the SDK (max attempts, retry mode).
- Important: **retries don't help if the limit is exceeded all the time**. Then the answer is an **increase** or **fewer calls**.

#### 4.3 How it works

The wait time **doubles** after each failed attempt:

| Attempt | Wait before the next try |
|---|---|
| 1st request fails | **1 second** |
| 2nd request fails | **2 seconds** |
| 3rd fails | **4 seconds** |
| 4th fails | **8 seconds** |
| 5th fails | **16 seconds** |

```
request ──x──> wait 1s ──x──> wait 2s ──x──> wait 4s ──x──> wait 8s ──x──> wait 16s ──> ...
```

- **The more you retry, the more you wait.**
- **Why it works:** when many clients all back off, **load on the server drops** over time, so the service can recover and answer as many requests as possible.
- **Extras:**
  - Add **jitter** (a random amount) to each wait. Without it, many clients retry **at the same moment** and cause new spikes ("thundering herd").
  - Set a **maximum wait** (cap) and a **maximum number of retries**.
  - Only retry **retryable** errors (throttling, 5xx, timeouts). **Don't retry 4xx client errors** such as `AccessDenied` or `ValidationException`.

**Pseudocode:**

```python
import random, time

def call_with_backoff(fn, max_attempts=6, base=1.0, cap=30.0):
    for attempt in range(max_attempts):
        try:
            return fn()
        except ThrottlingError:
            if attempt == max_attempts - 1:
                raise
            delay = min(cap, base * (2 ** attempt))
            time.sleep(random.uniform(0, delay))   # full jitter
```

- Backoff doubles the wait: **1, 2, 4, 8, 16 seconds**, and so on.
- **Jitter** prevents synchronized retries.

### 5. Exam-Style Recall

| If the question says... | Think... |
|---|---|
| "ThrottlingException because of too many API calls" | **Exponential backoff** |
| "Intermittent throttling errors" | **Exponential backoff** |
| "Consistently hitting the API rate limit" | **Request an API throttling limit increase** |
| "Can't launch more EC2 instances: vCPU limit reached" | **Request a service quota increase** |
| "Increase a service limit programmatically" | **Service Quotas API** |
| "Using the AWS SDK and getting throttled" | Retries with backoff are **already built in**. Tune them, or reduce calls or raise the limit. |
| "Calling the AWS REST API directly and getting throttled" | **Implement exponential backoff yourself** |
| "Retry delay pattern: 1s, 2s, 4s, 8s" | **Exponential backoff** |
| "Prevent many clients from retrying at the same instant" | **Add jitter** |
| "S3 `GetObject` limit" | **5,500 per second per prefix** |
| "Is a service quota per region?" | **Yes** |

---

## AWS Signature v4 Signing (SigV4)

### TL;DR

- Almost every AWS API call must be **signed** so AWS knows **who you are** and that you're **authorized**. The signing process is **Signature Version 4 (SigV4)**.
- You sign with your **AWS credentials** (access key and secret key). The **secret key is never sent**. Only the computed **signature** is.
- The **CLI and SDKs sign every request automatically**, which is why you've never had to do it by hand.
- **Exam focus:** the **two ways to send the signature**:
  1. In the **`Authorization` HTTP header** (what the CLI and SDKs do by default).
  2. In the **query string** of the URL, under the key **`X-Amz-Signature`** (how **S3 pre-signed URLs** work).
- Some requests need **no signature**, for example **reading a public S3 object**.
- You don't need to know the four signing steps. You do need to know SigV4 is the signing method, and the two transmission options.

### 1. Why Requests Are Signed

- Every AWS service is an **HTTP API**. When you call it, AWS must answer two questions:
  - **Authentication:** who is making this request?
  - **Authorization:** are they allowed to do it? (checked afterwards against IAM policies)
- You answer the first by **signing the request** with your credentials.
- A signature also gives:
  - **Integrity:** if anyone changes the request in transit, the signature no longer matches.
  - **Replay protection:** the request carries a **timestamp**, and AWS rejects requests that are too old (about **5 minutes** of clock skew).

```
Your code ──> build request ──> sign with secret key (SigV4) ──> HTTPS ──> AWS verifies the signature
```

| Credential part | Role |
|---|---|
| **Access key ID** | Identifies **who** you are. It is **sent** with the request. |
| **Secret access key** | Used to **compute the signature**. **Never sent.** |
| **Session token** | Required with **temporary credentials** (STS, roles, MFA) |

### 2. When Signing Isn't Needed

- **Anonymous requests** to resources that allow it, for example a **public S3 object** (a bucket policy with `GetObject` for `*`). That was the earlier Object URL case.
- Almost everything else **must be signed**.
- Private resources return **AccessDenied** if the signature is missing or wrong.

### 3. Automatic Signing: CLI and SDK

- The **AWS CLI** and **AWS SDKs** **sign for you**, using your credential chain.
- This is why this section has not shown the process before.
- Doing it by hand is only needed when you **call the HTTP API directly** (for example `curl` or a custom HTTP client). Even then, use a helper library or the SDK's signer rather than writing it yourself.
- The lecturer says the process "is very complicated" and has **four steps**. You **don't need to know how to compute it**.

**The four steps (extra, high level):**

| Step | What happens |
|---|---|
| 1. **Canonical request** | Build a standard text form of the request (method, path, query, headers, payload hash) |
| 2. **String to sign** | Combine the algorithm, timestamp, **credential scope** (date/region/service), and a hash of the canonical request |
| 3. **Signing key** | Derive a key from the **secret key** using chained HMAC-SHA256 (date, region, service, `aws4_request`) |
| 4. **Signature** | HMAC-SHA256 of the string to sign, using the signing key, and add it to the request |

- The signature is tied to the **service, region, and date**, so it can't be reused elsewhere.
- Signatures are **time-limited** and scoped to the **date, region, and service**.

### 4. The Two Ways to Send the Signature

#### 4.1 Option 1: `Authorization` header

- Compute the signature, then send it in the **`Authorization`** HTTP header.
- This is **what the CLI and SDK do by default**.

```http
GET / HTTP/1.1
Host: my-bucket.s3.eu-west-1.amazonaws.com
X-Amz-Date: 20261006T034500Z
X-Amz-Security-Token: <session token, if temporary credentials>
Authorization: AWS4-HMAC-SHA256
  Credential=AKIAEXAMPLE/20261006/eu-west-1/s3/aws4_request,
  SignedHeaders=host;x-amz-content-sha256;x-amz-date,
  Signature=<64-hex-character signature>
```

| Part of the header | Meaning |
|---|---|
| **`AWS4-HMAC-SHA256`** | The **algorithm** (SigV4) |
| **`Credential`** | Access key ID plus the **scope** (date/region/service/`aws4_request`) |
| **`SignedHeaders`** | Which headers are covered by the signature |
| **`Signature`** | The **computed signature** |

#### 4.2 Option 2: query string

- Put the signature **in the URL itself**, as query parameters. The signature uses the key **`X-Amz-Signature`**.
- This is how **S3 pre-signed URLs** work (see the previous S3 lectures).
- It lets you give a URL to someone (or open it in a browser) **without** custom headers, because everything is in the URL.

```
https://my-bucket.s3.eu-west-1.amazonaws.com/coffee.jpg
  ?X-Amz-Algorithm=AWS4-HMAC-SHA256
  &X-Amz-Credential=AKIAEXAMPLE%2F20261006%2Feu-west-1%2Fs3%2Faws4_request
  &X-Amz-Date=20261006T034500Z
  &X-Amz-Expires=3600
  &X-Amz-SignedHeaders=host
  &X-Amz-Security-Token=<token, if temporary credentials>
  &X-Amz-Signature=<64-hex-character signature>
```

| Query parameter | Meaning |
|---|---|
| **`X-Amz-Algorithm`** | **`AWS4-HMAC-SHA256`**, which is **SigV4** |
| **`X-Amz-Credential`** | The access key ID and the credential **scope** |
| **`X-Amz-Date`** | When the request was **signed** |
| **`X-Amz-Expires`** | How long the URL stays valid, in **seconds** |
| **`X-Amz-SignedHeaders`** | Headers included in the signature |
| **`X-Amz-Security-Token`** | The **session token** (present with temporary credentials, as in the console demo) |
| **`X-Amz-Signature`** | The **signature** itself |

### 5. Demo: Looking at a Signature in the Console

1. Open the S3 console and your bucket, then click `coffee.jpg`.
2. Click **Open**. The image **displays in the browser**.
3. Copy the **URL** from the address bar into a text editor.
4. Split it at each `&` and read the parameters:
   - A **security token** (because the console uses **temporary credentials**).
   - The **algorithm**: `AWS4-HMAC-SHA256`, which is SigV4.
   - The **date**.
   - The **expires** value, so you can see when the URL **stops working**.
   - The **credential**, which includes the access key ID (the lecturer says "my account ID" but it is the **access key ID** and scope).
   - The **signature**, which is the final computed value.

**What it shows:**
- The URL was **built by the browser (console)** to read the object from S3.
- The image shows because the **signature proves who you are**. The same object without the signature (the plain Object URL) gave **AccessDenied** earlier when the bucket was private.
- This is a **pre-signed URL**, so it is the **query string option** of SigV4.
- The URL stops working at its expiry time, so showing it in the video is safe.
- **Security note:** while it is valid, **anyone with the URL** can use it. Treat it as a secret.

### 6. Header vs Query String

| | **`Authorization` header** | **Query string** |
|---|---|---|
| **Where the signature goes** | `Authorization` header | **`X-Amz-Signature`** query parameter |
| **Used by** | **CLI and SDKs** (default) | **Pre-signed URLs** |
| **Good for** | Normal API calls from code | **Sharing a link**, browser access, temporary access |
| **Expiry control** | Short validity from the timestamp (about 5 minutes) | **`X-Amz-Expires`** sets the lifetime |
| **Exposure risk** | Headers are not usually logged or shared | The **URL itself is the credential**, so it can leak in logs or history |

### 7. Good Practices

- **Use the SDK or CLI** to sign. Don't implement SigV4 yourself.
- Keep your **system clock accurate** (NTP). A skewed clock gives **`RequestTimeTooSkewed`** or **signature expired** errors.
- Use **temporary credentials** (roles) where possible, and give pre-signed URLs **short lifetimes**.
- A signature created with **temporary credentials** expires when those **credentials** expire, even if `X-Amz-Expires` is longer.
- A pre-signed URL carries **the permissions of the signer**. If the signer loses access, the URL stops working.

### 8. Troubleshooting

| Error | Likely cause |
|---|---|
| **`SignatureDoesNotMatch`** | Wrong secret key, wrong region or service in the scope, changed headers or body, or a proxy altering the request |
| **`InvalidClientTokenId`** / **`UnrecognizedClientException`** | The **access key ID** doesn't exist or is wrong |
| **`ExpiredToken`** | The **temporary credentials** expired |
| **`RequestTimeTooSkewed`** | Your **clock** is more than about 5 minutes off |
| **`AccessDenied`** after a valid signature | Authentication worked, but **IAM or the bucket policy** doesn't allow the action |
| **`Request has expired`** (pre-signed URL) | The URL's **`X-Amz-Expires`** window ended |

### 9. Exam-Style Recall

| If the question says... | Think... |
|---|---|
| "How are AWS API requests authenticated?" | **Signed with SigV4** |
| "Algorithm name in `X-Amz-Algorithm`" | **`AWS4-HMAC-SHA256`** (SigV4) |
| "Two ways to include a SigV4 signature" | **`Authorization` header** and **query string** (`X-Amz-Signature`) |
| "What does the CLI use to transmit the signature?" | The **`Authorization` header** |
| "How does an S3 pre-signed URL carry its signature?" | In the **query string** (`X-Amz-Signature`) |
| "Who signs requests when using the SDK?" | **The SDK, automatically** |
| "Does the secret access key travel with the request?" | **No** |
| "Request to a public S3 object" | **No signature needed** |
| "Pre-signed URL stops working" | **`X-Amz-Expires`** passed, or the signer's **credentials expired** |
| "Error: signature doesn't match" | `SignatureDoesNotMatch` (check keys, region, clock, request changes) |
| "Calling the raw HTTP API yourself" | **You** must sign with SigV4 |
