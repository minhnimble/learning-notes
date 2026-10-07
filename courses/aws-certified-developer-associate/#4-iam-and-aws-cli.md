# IAM & AWS CLI

---

## IAM Introduction: Users, Groups, Policies

### TL;DR

- **IAM (Identity and Access Management)** controls **who** can do **what** in an AWS account. It is a **global** service and is **free**.
- The **root account** is for initial setup only. Day-to-day work uses **IAM users** (one per real person), organized into **groups**.
- **Policies** are **JSON documents** that grant or deny permissions. Attach them to groups (preferred), users, or roles.
- Follow the **least privilege principle**: grant only what a task needs.
- Add **MFA** and a **password policy**. Programmatic access uses **access keys** (CLI/SDK).
- Audit with the **IAM Credentials Report** (account level) and **IAM Access Advisor** (user level).

### 1. Building Blocks

| Concept | What it is |
|---|---|
| **Root account** | Created with the AWS account. Has unrestricted access. Use it for initial setup only |
| **User** | A person (or application) with long-term credentials |
| **Group** | A set of users. Groups contain **users only**, not other groups |
| **Policy** | JSON document that defines permissions |
| **Role** | An identity for AWS services or external principals, with temporary credentials (see the roles sections) |

- One user can belong to **several groups** (up to 10). A user doesn't have to belong to any group.
- Group-based permissions are easier to manage: put developers in a `Developers` group and operations staff in an `Operations` group, each with its own policies.

### 2. Permissions and Least Privilege

- Users and groups get permissions through **IAM policies**.
- **Least privilege:** start with nothing, add only what's required. This reduces risk and blast radius.

### 3. Security Features

| Feature | Purpose |
|---|---|
| **MFA** | Second factor on top of the password |
| **Password policy** | Minimum length, character types, expiration, reuse prevention |
| **Access keys** | Credentials for the **CLI** and **SDK** |
| **Credentials Report** | Account-wide CSV of every user's credential status |
| **Access Advisor** | Per-user view of services used and last accessed |

### 4. Exam-Style Recall

| If the question says... | Think... |
|---|---|
| "Day-to-day administration of the account" | An **IAM user**, not root |
| "Give many users the same permissions" | Attach a **policy to a group** |
| "Grant only what's needed" | **Least privilege** |
| "Can a group contain another group?" | **No.** Groups hold users only |
| "IAM is regional or global?" | **Global** |
| "Where do IAM users sign in?" | The **account sign-in URL** (ID or alias) |

---

## IAM Users & Groups Hands On

### 1. Steps

| Step | Detail |
|---|---|
| Open IAM | The console shows **Global** in place of a Region |
| Create user | Set a username, enable **console access**, choose a custom password, and require a password change at next sign-in |
| Create group | Group name (for example `admin`), attach **AdministratorAccess** |
| Add user to group | The user inherits the group's permissions |
| Tag (optional) | Key/value tags such as `Department: Development` |
| Sign in | Use the **account sign-in URL** (account ID or alias), in a private/incognito window |

- Sign-in URL format: `https://<account-id-or-alias>.signin.aws.amazon.com/console`. An **account alias** makes it friendlier.
- Keep **root** and **IAM user** credentials in a password manager.

---

## AWS Console Simultaneous Sign-in

### TL;DR

- **Multi-session support** lets you sign in to **up to 5 identities** (root, IAM, or federated roles, in the same or different accounts) in **one browser**, each in its own tab.
- Opt in from the **account menu** (Turn on multi-session). Console URLs then include a session-specific subdomain.
- Demo: created resources in one account while another stayed open in a separate tab.

### 1. Details

| Aspect | Detail |
|---|---|
| Maximum | **5** simultaneous sessions |
| Identity types | Root, IAM users, federated roles, any mix |
| Enable / disable | Account menu (Turn on multi-session) / Disable multi-session, or clear browser cookies |
| Availability | All commercial Regions (announced January 2025) |
| Best for | Working in dev and prod accounts side by side |

- Without it, signing in to a second account signs you out of the first, so people used private windows or multiple browser profiles.

### 2. Exam-Style Recall

| If the question says... | Think... |
|---|---|
| "Use multiple accounts in one browser" | Console **multi-session support** |

---

## IAM Policies

### TL;DR

- A **policy** is a JSON document that describes permissions in terms of **Effect, Action, Resource, and (optionally) Condition**.
- Attached to a **group**, all members inherit it. An **inline policy** is embedded in a single user, group, or role.
- Policy elements: **Version**, **Id** (optional), and **Statement(s)**. Each statement has **Sid**, **Effect**, **Principal** (resource-based only), **Action**, **Resource**, **Condition**.
- **Explicit Deny beats Allow. Everything else is denied by default.**
- **Credentials Report** (account level) and **Access Advisor** (user level) help enforce least privilege.

### 1. Where Policies Attach

| Attachment | Effect |
|---|---|
| **Group** | Every user in the group inherits it |
| **User (managed or inline)** | Applies to that user only, on top of group policies |
| **Role** | Applies to whoever assumes the role |
| **Inline policy** | Embedded 1:1 in one identity. Deleted with it |

- A user gets the **union** of all attached and inherited policies, subject to explicit denies.
- Prefer **managed policies** (AWS managed or customer managed) over inline. They are reusable and versioned.

| Managed policy limit (default) | Value |
|---|---|
| Groups a user can join | 10 |
| Managed policies per user or group | 10 |
| Managed policies per role | 20 (up to 25 with a quota increase) |

### 2. Policy Structure

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "ReadOneBucket",
      "Effect": "Allow",
      "Action": ["s3:GetObject", "s3:ListBucket"],
      "Resource": ["arn:aws:s3:::my-bucket", "arn:aws:s3:::my-bucket/*"]
    }
  ]
}
```

| Element | Meaning |
|---|---|
| **Version** | Policy language version. Always `2012-10-17` |
| **Id** | Optional identifier |
| **Sid** | Optional statement ID |
| **Effect** | `Allow` or `Deny` |
| **Principal** | Account, user, role, or service the policy applies to. Used in **resource-based** policies (for example S3 bucket policies, trust policies), not in identity policies |
| **Action** | API calls, for example `s3:GetObject`. `*` is a wildcard |
| **Resource** | ARNs the actions apply to |
| **Condition** | Optional rules (source IP, MFA present, tags, time, and so on) |

### 3. Evaluation Logic

1. Everything is **denied by default** (implicit deny).
2. An **Allow** in an applicable policy grants access.
3. An **explicit Deny** in any applicable policy **overrides** every Allow.

### 4. Security Tools

| Tool | Level | What it shows |
|---|---|---|
| **IAM Credentials Report** | Account | CSV of all users and the status of their credentials |
| **IAM Access Advisor** | User (also group, role, policy) | Services a principal can access and when they were last accessed, to trim unused permissions |

### 5. Exam-Style Recall

| If the question says... | Think... |
|---|---|
| "Policy that only applies to one user, deleted with the user" | **Inline policy** |
| "Which element only appears in resource-based policies?" | **Principal** |
| "Allow and Deny both match" | **Deny wins** |
| "No policy mentions the action" | **Implicit deny** |
| "Find permissions a user never used" | **IAM Access Advisor** |
| "Which users have old access keys or no MFA?" | **IAM Credentials Report** |
| "User can list but not create IAM users" | **IAMReadOnlyAccess** |
| "Full access to every service" | **AdministratorAccess** (`*` on `*`) |

---

## IAM Policies Hands-on

### 1. Demo Flow

| Step | Result |
|---|---|
| User in admin group, list users | Works |
| Remove user from group, list users | **Access denied** |
| Attach **IAMReadOnlyAccess** to the user | Can list and view users and groups, but not create them |
| Add user back to the group | Inherits **AdministratorAccess** again |

### 2. Policies Used

| Policy | Permissions |
|---|---|
| **AdministratorAccess** | `Action: "*"` on `Resource: "*"`, full access to every service |
| **IAMReadOnlyAccess** | List/get IAM actions only, using wildcards like `iam:Get*` and `iam:List*` |

- `*` wildcards cover many actions at once, for example `iam:List*`.
- The **policy simulator** and the **Policies** page let you inspect a policy's JSON and where it's attached.

### 3. Creating a Custom Policy

- **Visual editor:** pick a service, actions, and resources.
- **JSON editor:** paste or write the document directly.

---

## IAM Multi-Factor Authentication (MFA)

### TL;DR

- A **password policy** defends against weak or reused passwords. **MFA** adds a second factor: **something you know** (password) plus **something you have** (device).
- If the password leaks, the attacker still needs the device.
- AWS now **enforces MFA for root users** on all account types.
- Supported MFA types: **passkeys / security keys (FIDO2)**, **virtual authenticator apps (TOTP)**, and **hardware TOTP tokens**. You can register **up to 8 MFA devices** per root or IAM user.

### 1. Password Policy Options

| Setting | Notes |
|---|---|
| Minimum length | Default policy: **8 characters** (CIS benchmark suggests 14+) |
| Character types | Uppercase, lowercase, numbers, non-alphanumeric. Default requires **3 of 4** |
| Allow users to change their own password | On or off |
| Password expiration | Off by default. Can be set from 1 to **1,095 days** |
| Prevent password reuse | Remember previous passwords |
| Require administrator reset after expiry | Optional |

- These controls help against **brute-force** and credential-stuffing attacks.

### 2. MFA Device Types

| Type | Examples | Notes |
|---|---|---|
| **Passkey / security key (FIDO2)** | YubiKey, platform passkeys (Touch ID, Windows Hello) | **Phishing-resistant.** One key can serve many accounts. (The lecture calls these "U2F security keys".) |
| **Virtual MFA device (TOTP app)** | Google Authenticator, Authy, 1Password | Free, one app holds many tokens |
| **Hardware TOTP token** | Gemalto key fob. **GovCloud** users use a specific fob | Physical fob |

### 3. Exam-Style Recall

| If the question says... | Think... |
|---|---|
| "Two-factor: password plus something the user owns" | **MFA** |
| "Phishing-resistant MFA" | **Passkey / FIDO2 security key** |
| "MFA app on a phone" | **Virtual MFA device** (TOTP) |
| "Protect the most sensitive account" | **Root user MFA** |
| "Max MFA devices per user" | **8** |
| "Set password rules for all IAM users" | **Account password policy** |
| "MFA setup with a phone app" | Scan a **QR code**, enter two consecutive codes |

---

## IAM MFA Hands On

### 1. Password Policy

- IAM, **Account settings**, **Password policy**, **Edit**.
- Choose the IAM default or a custom policy (minimum length, uppercase/lowercase/number/symbol requirements, expiration, reuse prevention).

### 2. Enabling MFA on the Root Account

1. Open the account menu, **Security credentials**.
2. **Assign MFA device**, give it a name.
3. Choose the type (authenticator app, security key, or hardware token).
4. For an app: **scan the QR code**, enter **two consecutive codes**.
5. Sign out, sign back in as root, and enter the MFA code after the password.

---

## AWS Access Keys, CLI and SDK

### TL;DR

- Three ways to access AWS: the **Management Console**, the **CLI**, and the **SDKs**.
- The **console** uses a username and password (plus MFA). The **CLI** and **SDK** use **access keys** (Access Key ID + Secret Access Key), which are like a password.
- **Never share access keys or commit them to Git.** Prefer short-lived credentials where possible.

### 1. Access Methods

| Method | Authentication | Best for |
|---|---|---|
| **Management Console** | Username and password (+ MFA) | Exploring, one-off tasks |
| **CLI** | Access keys (or short-lived credentials) | Scripts, automation, fast repeated tasks |
| **SDK** | Access keys (or an attached role) | Integrating AWS into application code |

### 2. Access Keys

- Created in **IAM, user, Security credentials**. A user can have **at most 2** access keys (enables rotation).
- The **secret** is shown **once**. Store it securely. If lost, create a new key.
- Rotate regularly and delete unused keys.

### 3. SDKs

- Libraries for JavaScript, Python, PHP, .NET, Ruby, Java, Go, C++, plus mobile SDKs (Android, iOS).
- The **CLI itself is built on the Python SDK (boto)**.
- SDKs pick up credentials from the same **credential provider chain** as the CLI.

### 4. Credential Options (2026)

| Option | Notes |
|---|---|
| **`aws login`** (AWS CLI 2.32+) | Signs in with your console identity (root, IAM user, federation) through the browser and issues **short-lived credentials** (auto-refreshed). AWS lists it as the top choice for those identities |
| **IAM Identity Center** (`aws configure sso`) | Best practice for workforce access across accounts. Short-term credentials |
| **Long-term access keys** | Work, but have no expiry, so they are the highest risk. The lecture uses them for teaching |

### 5. Exam-Style Recall

| If the question says... | Think... |
|---|---|
| "CLI/SDK authentication" | **Access keys** (or short-term credentials / a role) |
| "Access keys per user" | **2** |
| "Secret access key lost" | Create a new key. The secret can't be retrieved |
| "Programmatic access to AWS from code" | **SDK** |
| "CLI returns access denied but the console works" | Check **which credentials/profile** the CLI is using and their permissions |
| "Where does `aws configure` store the keys?" | `~/.aws/credentials` |
| "EC2 needs AWS API access" | An **IAM role**, not stored keys |

---

## AWS CLI Installation on Mac OS X

### TL;DR

- Install **AWS CLI v2** with the official `.pkg` installer, then verify with `aws --version`.
- These notes cover **macOS only** (Windows and Linux lectures skipped).

### 1. Steps

1. Find the official **AWS CLI v2** install page.
2. Download the macOS `.pkg` installer.
3. Open it, click **Continue**, agree to the terms, and choose to install **for all users**.
4. Open a terminal and run:

   ```bash
   aws --version
   ```

5. A version string (for example `aws-cli/2.x.x ...`) means it worked.

- To upgrade later, run the newest installer again.
- If the install fails, follow the troubleshooting section of the installation guide.

---

## Using AWS CLI Hands On

### 1. Configure

```bash
aws configure
# AWS Access Key ID [None]: <key id>
# AWS Secret Access Key [None]: <secret>
# Default region name [None]: eu-west-1
# Default output format [None]: json
```

| Detail | Notes |
|---|---|
| Storage | `~/.aws/credentials` (keys) and `~/.aws/config` (Region, output) |
| Region choice | Pick the Region closest to you (or your users) |
| Named profiles | `aws configure --profile <name>`, then `--profile <name>` on commands |
| Security | Never share the keys. Delete the key when you're done with the demo |

### 2. Permission Demo

- List users: works with admin permissions.
- Remove the user from the admin group: the same command fails with **AccessDenied**.
- Add the user back to the admin group to continue with later demos.

- The CLI/SDK credential lookup order is covered in the AWS CLI Profiles section (#12).

---

## Using AWS CloudShell

### TL;DR

- **CloudShell** is a **free**, browser-based shell inside the console, **already authenticated** as the signed-in user, with the AWS CLI preinstalled.
- API calls default to the **Region you are signed in to**.
- Each Region gives **1 GB of persistent storage** in `$HOME`. Files survive restarts, and data is kept **120 days** after your last session in that Region.
- Supports upload/download, multiple tabs, split panes, and font/theme settings.

### 1. Details

| Aspect | Detail |
|---|---|
| Access | CloudShell icon in the console's top bar. Not available in every Region |
| Cost | Free (you pay only for resources you create) |
| Credentials | Inherits the console session's permissions, so no `aws configure` |
| Storage | **1 GB persistent** per Region in `$HOME`. Everything outside `$HOME` is temporary |
| Inactivity | The session shuts down after a period of inactivity. Files in `$HOME` remain |
| Files | Upload and download from the Actions menu |
| Customization | Font size, light/dark theme, multiple tabs, split view |

### 2. CloudShell vs Local CLI

| | CloudShell | Local terminal |
|---|---|---|
| Setup | None | Install CLI, configure keys |
| Credentials | Console identity | Access keys or `aws login`/SSO |
| Persistence | 1 GB `$HOME` per Region | Your machine |

### 3. Exam-Style Recall

| If the question says... | Think... |
|---|---|
| "Run CLI commands from the console with no setup" | **CloudShell** |
| "CloudShell persistent storage" | **1 GB per Region** in `$HOME` |
| "Which Region does CloudShell use by default?" | The Region you're signed in to |

---

## IAM Roles in AWS

### TL;DR

- An **IAM role** is an identity with permissions that is **assumed** by a trusted entity. It has **no long-term credentials**. It issues **temporary credentials** through **STS**.
- AWS services (EC2, Lambda, CloudFormation, and so on) use roles to call other AWS services on your behalf.
- A role has two parts: a **trust policy** (who can assume it) and **permission policies** (what it can do).

### 1. Why Roles

- Services can't sign in with a username and password. They need permissions to act on your behalf (for example an EC2 instance reading from S3).
- Roles avoid storing access keys on servers.

### 2. Common Role Uses

| Trusted entity | Example |
|---|---|
| **EC2 instance** (via an instance profile) | App on EC2 reads from S3 |
| **Lambda function** | Function writes to DynamoDB (execution role) |
| **CloudFormation** | Stack creates resources on your behalf (service role) |
| **Another account / federated user** | Cross-account and SSO access |

### 3. Anatomy

| Part | Purpose |
|---|---|
| **Trust policy** | Which **principals** (service, account, user) may assume the role |
| **Permission policies** | What the role can do once assumed |
| **Temporary credentials** | Issued by **STS**, expire automatically |

### 4. Exam-Style Recall

| If the question says... | Think... |
|---|---|
| "AWS service needs to call another AWS service" | **IAM role** |
| "Who can assume the role?" | Defined in the **trust policy** |
| "Credentials that expire automatically" | Role via **STS** |
| "Service reading S3 from EC2 without keys" | **EC2 instance profile** with a role |
| "Role for an EC2 instance" | Trusted entity: **EC2** (AWS service) |
| "What lets EC2 assume the role?" | The role's **trust policy** |

---

## Creating IAM Roles in AWS Hands On

### 1. Steps

1. IAM, **Roles**, **Create role**.
2. **Trusted entity type:** AWS service. **Use case:** EC2.
3. **Add permissions:** attach **IAMReadOnlyAccess** (lets the instance read IAM information).
4. **Role name:** `DemoRoleForEC2`. The trust policy lets **EC2** assume the role.
5. Review and **Create role**.
6. The role appears in the roles list.

---

## Security Tools in IAM

### TL;DR

- **IAM Credentials Report** is **account-level**: one CSV with every user and the status of their credentials.
- **IAM Access Advisor** is **user-level** (also group, role, policy): shows which services are allowed and when they were last accessed.
- Use Access Advisor to **remove unused permissions** (least privilege).

### 1. Comparison

| | Credentials Report | Access Advisor |
|---|---|---|
| Scope | **Account** (all users) | One **user / group / role / policy** |
| Answers | "Whose credentials need attention?" | "Which permissions are actually used?" |

### 2. Details

| Aspect | Credentials Report | Access Advisor |
|---|---|---|
| Where | IAM, **Credential report**, **Download** | IAM, user (or role/group/policy), **Access Advisor** tab |
| Contents | About 23 CSV columns: user ARN, creation time, **password enabled/last used/last changed/next rotation**, **MFA active**, **access key** status (active, last rotated, last used, last service used) | Allowed services and their **last accessed** time |
| Limits | Regenerate **at most once every 4 hours** (a recent report is reused) | Look-back up to **400 days**. Action-level detail only for some services (S3, EC2, IAM, Lambda) |
| Use | Spot inactive users, missing MFA, old or unused access keys | Remove permissions that are never used |

- Demo: generate and download the Credentials Report, then open Access Advisor on a user.

### 3. Exam-Style Recall

| If the question says... | Think... |
|---|---|
| "Account-wide listing of users and credential status" | **Credentials Report** |
| "See which services a user hasn't used" | **Access Advisor** |
| "Reduce permissions to least privilege using real usage" | **Access Advisor** |
| "Report includes MFA status and key rotation for all users" | **Credentials Report** |
| "How often can it be regenerated?" | Once every **4 hours** |
| "Access Advisor look-back period" | **400 days** |

---

## Best Practices for IAM in AWS

### TL;DR

- Don't use root for daily work. One IAM user per person. Manage permissions through groups. Enforce a password policy and MFA. Use roles for AWS services. Audit regularly. Never share credentials.

### 1. Checklist

| Practice | Why |
|---|---|
| **Avoid the root account** | Reserve it for initial setup and the few tasks only root can do. Don't create root access keys |
| **One IAM user per person** | Accountability and revocation, with no shared credentials |
| **Groups for permissions** | Simple, consistent administration |
| **Strong password policy** | Blocks weak and reused passwords |
| **Enforce MFA** | Protects against stolen passwords |
| **Roles for AWS services** | Temporary credentials, no keys on servers |
| **Access keys only when needed** | CLI/SDK access, kept confidential and rotated |
| **Audit regularly** | Credentials Report and Access Advisor |
| **Never share credentials** | Shared users and keys can't be traced or revoked cleanly |

- Modern guidance also recommends **IAM Identity Center** (SSO) for people and **temporary credentials** over long-lived keys.

### 2. Exam-Style Recall

| If the question says... | Think... |
|---|---|
| "Best practice for the root user" | Enable **MFA**, don't use it day to day, no access keys |
| "Grant an app running on EC2 access to S3" | **Role**, not keys |
| "Share access with a coworker" | Give them **their own IAM user** |

---

## Shared Responsibility Model for IAM in AWS

### TL;DR

- **AWS** secures the infrastructure (security **of** the cloud). **You** manage identities and access (security **in** the cloud).
- For IAM: AWS runs the service and global infrastructure. You configure users, groups, roles, policies, MFA, key rotation, and monitoring.

### 1. Who Does What

| AWS is responsible for | You are responsible for |
|---|---|
| Global infrastructure and network security | Creating and managing **users, groups, roles, and policies** |
| IAM service configuration, vulnerability analysis, and compliance validation | Enabling **MFA** on accounts |
| | **Rotating access keys** regularly |
| | Using appropriate **least-privilege** policies |
| | **Monitoring and auditing** access (Credentials Report, Access Advisor, CloudTrail) |

### 2. Exam-Style Recall

| If the question says... | Think... |
|---|---|
| "Who rotates IAM access keys?" | The **customer** |
| "Who secures the physical data centers?" | **AWS** |
| "Who defines IAM policies?" | The **customer** |

---

## IAM in AWS - Summary

### Quick Reference

| Concept | Remember |
|---|---|
| IAM | **Global**, free |
| User | One per person. Console password and/or access keys |
| Group | Users only. A user can be in up to 10 |
| Policy | JSON. **Deny beats Allow.** Default is deny |
| Role | Temporary credentials via STS. Trust policy plus permissions |
| MFA | Passkey/FIDO2, authenticator app, or hardware token. Up to 8 per user |
| Access keys | Max 2 per user. The CLI/SDK use them. Prefer short-lived credentials |
| CloudShell | Free browser shell, 1 GB persistent storage per Region |
| Credentials Report | Account-level CSV, at most every 4 hours |
| Access Advisor | User-level last-accessed data, up to 400 days |
