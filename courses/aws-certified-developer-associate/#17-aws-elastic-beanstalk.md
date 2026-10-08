# AWS Elastic Beanstalk

---

## Elastic Beanstalk Overview (High level)

### TL;DR

- **Elastic Beanstalk** is a **developer-centric, managed way to deploy applications** on AWS. It reuses **EC2, ASG, ELB, RDS** and the other components you already know, from **one interface**, so you only manage the **code**.
- It handles **capacity provisioning, load balancer configuration, scaling, health monitoring, and instance configuration**. You keep **full control** over each component's configuration.
- **Beanstalk itself is free.** You pay only for the **underlying resources** (EC2, ASG, ELB, RDS, and so on).
- Concepts: **application** (a collection of environments, versions, and configurations), **application version** (an iteration of your code), **environment** (resources running **one** application version), and **environment tiers** (**web server** and **worker**).
- **Web tier** = load balancer + ASG of web servers. **Worker tier** = EC2 workers **pulling from an SQS queue**, scaling on the **number of messages**.
- Two deployment modes: **single instance** (development) and **high availability with a load balancer** (production).

### 1. Why Beanstalk

| Problem | Beanstalk's answer |
|---|---|
| Most web apps share the same architecture: **load balancer + ASG across AZs + RDS + ElastiCache** | Provision that whole stack for you, the same way every time |
| Developers don't want to configure databases, load balancers, scaling, and so on | **One service** that deploys and manages them, so you focus on the **code** |
| Many languages and environments | A **single way of deploying** all of them |

- It also provides a convenient way of **updating applications** (deployment policies, covered later).

### 2. Components

| Component | Meaning |
|---|---|
| **Application** | A **collection** of Beanstalk components: **environments, versions, and configurations** |
| **Application version** | An **iteration of your application code** (v1, v2, v3, ...) |
| **Environment** | The **resources running one application version** at a time. You can **update** an environment from v1 to v2. |
| **Environment tier** | **Web server** tier or **worker** tier (below) |
| **Multiple environments** | For example **dev, test, and prod** from the same application |

**Process:**

```
Create an application --> upload a version --> launch an environment --> manage its lifecycle
      ^                                                                         |
      +---- upload a new version and deploy it to the environment <-------------+
```

### 3. Supported Platforms

- **Go, Java (Java SE, Tomcat), .NET (.NET Core on Linux, .NET on Windows Server), Node.js, PHP, Python, Ruby**, and **Docker**.
- The lecture also lists **Packer Builder**, **Single Docker Container**, **Multi Docker Container**, and **Pre-configured Docker**. The current docs list **Docker** and **ECS-managed Docker** platforms (on **Amazon Linux 2023**) instead. Packer Builder and Multi Docker Container are no longer listed.
- Idea: you can deploy **pretty much anything**, and with Docker, any language.
- Newer: Beanstalk has two modes. **Standard** runs on **EC2**, and **Cluster** runs on **Amazon EKS**.

### 4. Environment Tiers

**Web server tier** (the traditional architecture):

```
Clients --> Load balancer --> Auto Scaling group: EC2 web servers (several AZs)
```

**Worker tier:**

```
SQS queue <--pull messages-- EC2 workers (Auto Scaling group)
```

| Point | Detail |
|---|---|
| **Clients** | **No clients access the EC2 instances directly.** Work arrives as **messages in an SQS queue**. |
| **Workers** | EC2 instances **pull messages from the queue** and process them (a daemon on each instance reads the queue and hands each message to your app). Beanstalk creates the **SQS queue** for you if you don't have one. |
| **Scaling** | Based on the **number of SQS messages**: more messages, more EC2 instances. There is **no load balancer**. |
| **Combine them** | The **web environment** can **push messages** to the **worker environment's SQS queue** |

- Not every platform supports it: **.NET on Windows Server** has **no worker environments**.

### 5. Deployment Modes (Environment Types)

| | **Single instance** | **High availability with load balancer** |
|---|---|---|
| **Layout** | **One EC2 instance** with an **Elastic IP**, **no load balancer**. The ASG exists but min, max, and desired are all **1**. | **Load balancer** across **multiple EC2 instances** in an **Auto Scaling group**, **multiple AZs** |
| **Database** | Can also launch an **RDS** database | An RDS database that is **multi-AZ** (primary and standby) |
| **Use for** | **Development**, low traffic | **Production**, scalable |

- You can **switch** an environment from one type to the other by editing its capacity configuration.

### 6. Exam-Style Recall

| If the question says... | Think... |
|---|---|
| "Deploy an app on AWS without managing the infrastructure, developer-centric" | **Elastic Beanstalk** |
| "Beanstalk pricing" | **Free**. Pay for the **underlying resources**. |
| "Collection of environments, versions, and configurations" | A Beanstalk **application** |
| "An iteration of the application code" | An **application version** |
| "Resources running one application version" | An **environment** |
| "Dev, test, and prod from the same app" | Multiple **environments** |
| "Process background jobs from a queue with Beanstalk" | **Worker environment tier** (SQS, scales on message count) |
| "Beanstalk for a normal web app behind a load balancer" | **Web server tier** |
| "Cheapest Beanstalk setup for development" | **Single instance** mode (one EC2 with an Elastic IP) |
| "Production, highly available Beanstalk" | **Load-balanced** mode with an ASG across multiple AZs |
| "Deploy a Docker container with Beanstalk" | The **Docker** platform (or ECS-managed Docker) |

---

## Beanstalk First Environment

### 1. Creating the Application and Environment

Elastic Beanstalk console, **Create application**.

| Setting | Demo value | Notes |
|---|---|---|
| **Environment tier** | **Web server environment** | Choose a **worker environment** instead to process tasks from a queue. Only web server was demoed. |
| **Application name** | `My Application` | |
| **Environment name** | `My Application Dev` | Represents the **development** environment |
| **Domain** | Auto-generated | The URL used to reach the web servers |
| **Platform** | **Node.js** (managed platform), latest defaults | The version you see may differ, the latest defaults are fine |
| **Application code** | **Sample application** | You can upload your own code, matching the platform |
| **Preset** | **Single instance** (free tier eligible) | The alternatives are **High availability** (with a load balancer) and **Custom configuration** |

### 2. Service Access (IAM Roles)

Next to **Configure service access**, no roles existed yet, so both were created from the console.

| Setting | How it was created | Notes |
|---|---|---|
| **Service role** | **Create role**, use case **Elastic Beanstalk (environment)**, keep the pre-filled permission policies, name **`aws-elasticbeanstalk-service-role`** | Lets **Beanstalk manage AWS resources** for the environment. Refresh and select it afterwards. |
| **EC2 instance profile** | **Create role**, use case **Elastic Beanstalk compute**, keep the pre-filled policies, **Create role** | The role the **EC2 instances** assume. Refresh and select it. |
| **EC2 key pair** | Left empty (optional) | |

- Skip steps 3 to 5 (networking, database, and so on) and choose **Skip to review**, since the single-instance defaults are enough.
- On the review page, confirm the **service role** and **instance profile** are selected, then **Submit**.

### 3. What Beanstalk Created

The **Events** tab shows security group created, Elastic IP created, waiting for the EC2 instance, then instance launched. These events come from **CloudFormation**.

| Where | What you see |
|---|---|
| **CloudFormation console** | A **stack** for the Beanstalk environment. **Events** go from "create in progress" to **Create complete**. **Resources** lists the Auto Scaling group, the launch configuration (see below), the Elastic IP, and more. |
| **Template, View in Application Composer** | A visual diagram of the stack: launch configuration, **security groups**, **Elastic IP**, a wait condition and its handle |
| **EC2 console** | **One instance running** (`t3.micro`) with a **public IP** |
| **Elastic IPs** | An Elastic IP **allocated to that instance** |
| **Auto Scaling groups** | An ASG managing **only that one instance**, which is why it's called a **single instance** environment |

- Newer AWS accounts get a **launch template** instead of a launch configuration (EC2 Auto Scaling stopped supporting launch configurations for new accounts on Oct 1, 2024), and Application Composer is now called Infrastructure Composer.

### 4. Result

1. When everything is launched, the events show **successfully launched** and the environment **health is OK**.
2. Click the environment's **domain name**: the sample app says "Congratulations, you are now running Elastic Beanstalk on this EC2 instance".
3. From just the **sample code**, Beanstalk generated all the infrastructure to run the web server.

### 5. Exploring the Environment

| Tab / option | What it offers |
|---|---|
| **Upload and deploy** | Upload a **new application version**, which is deployed automatically to the instances |
| **Health** | Health-check information for all instances |
| **Logs** | View the application's logs |
| **Monitoring** | Metrics for the application |
| **Alarms** | Alarms for the environment |
| **Managed updates** | Beanstalk updating the whole environment |
| **Configuration** | See, modify, and apply every setting of the environment |

- Under **My Application**, `My Application Dev` is **one environment**. You can create another one (for example `My Application Prod`) for the same application.

### 6. Beanstalk vs CloudFormation

- **Beanstalk** is centered on **your code and its environments**.
- **CloudFormation** deploys **stacks of arbitrary infrastructure**. (Beanstalk itself uses CloudFormation behind the scenes.)

---

## Beanstalk Second Environment

### 1. Creating the Production Environment

`My Application`, **Create a new environment**, **Web server environment**.

| Setting | Demo value | Notes |
|---|---|---|
| **Environment name** | `MyApplication-prod` | Next to the `dev` environment |
| **Platform** | Same managed **Node.js** platform (the lecture used Node.js 12, which is long retired, pick the latest default) | |
| **Application code** | **Sample application** | |
| **Preset** | **High availability** (not Single instance) | So there is a **load balancer** and a scalable ASG |
| **Service access** | **Use existing** service role and EC2 instance profile | Created in the first environment |

- The lecture first walked through **Configure more options** to show everything, then **cancelled** (the new console was rough around the edges) and recreated the environment using the preset with **Skip to review**, then **Submit**.
- Launching takes about **10 minutes**.

### 2. What the Optional Configuration Offers

A tour of the settings (all can be set directly in Beanstalk):

| Category | What you can set |
|---|---|
| **Networking** | **VPC**, the **subnets** to launch in (all available subnets, for high availability), and whether instances get **public IPs** (not needed behind a load balancer) |
| **Database** | Add an **RDS** database. It is **coupled to the environment's lifecycle**: delete the environment and the database goes away (see below). |
| **Instances** | Root volume, security groups |
| **Capacity (ASG)** | **Min and max** instances (for example **1 to 4**), **fleet composition** (On-Demand and/or Spot), **instance types** (`t3.micro`, `t3.small`, ...), AMI ID, **scaling triggers** (metric, thresholds) |
| **Load balancer** | **Visibility** (public), **subnets**, **type** (**ALB** or **NLB**). With an ALB: **dedicated** to the environment, or **shared** across environments to save cost. Plus listeners, processes, and rules. |
| **Health reporting** | CloudWatch custom metrics, **Enhanced** health reporting |
| **Updates and deployments** | **Managed updates**, email **notifications**, and **rolling updates** (important for the exam, covered in its own lecture) |
| **Platform software** | **X-Ray**, streaming logs to **CloudWatch Logs**, and more |

- **Coupled database:** Beanstalk can add MySQL, PostgreSQL, Oracle, or SQL Server, tied to the environment. When the environment is terminated, the **deletion policy** (**snapshot**, **retain**, or **delete**) decides what happens to the database. For production AWS recommends **decoupling** the database. You can also **snapshot and restore** it later.
- **Shared ALB:** the **load balancer type** and dedicated vs shared choice can only be made **at environment creation**.

### 3. What Beanstalk Created for High Availability

| Where | What you see |
|---|---|
| **Environment URL** | The same "Congratulations" page: **same app, run differently** |
| **Load balancers** | A new **load balancer** across **three AZs** |
| **Target group** | **One healthy** target: the EC2 instance of `MyApplication-prod` |
| **Security groups** | The **instance** security group allows **port 80 from the load balancer's security group**. The **load balancer** security group allows **port 80 from anywhere** and outbound port 80 to anywhere. |
| **Auto Scaling groups** | **Two** now: one per environment. The prod one has **min 1, max 4**, an instance **in service**, and **dynamic scaling policies set automatically** by Beanstalk. |

- Result: you uploaded code and chose **high availability**, and Beanstalk configured everything else. You now have a **dev** and a **prod** environment.

---

## Beanstalk Deployment Modes

### TL;DR

- Six ways to deploy an update: **all at once**, **rolling**, **rolling with additional batch**, **immutable**, **traffic splitting** (canary), and **blue/green** (manual).
- **All at once** = fastest, **downtime**, no extra cost. **Rolling** = a **bucket** at a time, **below capacity**, no extra cost. **Rolling with additional batch** = stays **at full capacity**, **small extra cost**. **Immutable** = new instances in a **temporary ASG**, **high cost**, **quick rollback**. **Traffic splitting** = **canary testing**. **Blue/green** = a **new environment** and a **URL swap**.
- The exam gives one or two **scenario questions** on picking a policy from the constraints (downtime, cost, speed, rollback). Learn the AWS comparison table (section 8).

### 1. Overview

| Policy | In one line |
|---|---|
| **All at once** | Deploy to **all instances in one go**. Fastest, **but downtime**. |
| **Rolling** | Update **a few instances (a bucket) at a time**, moving on once the bucket is healthy |
| **Rolling with additional batch** | Like rolling, but first **launch new instances** so you **keep full capacity** |
| **Immutable** | Deploy to **brand-new instances in a temporary ASG**, then swap out the old ones |
| **Traffic splitting** | **Canary testing**: send a **small % of traffic** to the new version first |
| **Blue/green** | A **whole new environment**, then **swap** when ready (not a built-in policy) |

### 2. All at Once

```
v1 v1 v1 v1  -->  stopped stopped stopped stopped (downtime)  -->  v2 v2 v2 v2
```

| Aspect | Detail |
|---|---|
| **Speed** | **Fastest** |
| **Downtime** | **Yes**: all instances are updating, so none can serve traffic |
| **Cost** | **No additional cost** |
| **Best for** | **Development** and quick iterations where downtime doesn't matter |

### 3. Rolling

```
bucket size 2 of 4:   [v1 v1 | v1 v1] --> [gray gray | v1 v1] --> [v2 v2 | v1 v1]
                                      --> [v2 v2 | gray gray] --> [v2 v2 | v2 v2]
```

| Aspect | Detail |
|---|---|
| **Capacity** | **Runs below capacity** during the deployment. The **bucket size** sets how far below. |
| **Versions** | **Both versions run at the same time** during the update |
| **Cost** | **No additional cost** (same number of instances) |
| **Speed** | Slower, and **very long with a small bucket and many instances** (for example bucket 2 with 100 instances) |

### 4. Rolling with Additional Batch

```
4 x v1  -->  launch 2 NEW instances running v2 (now 6, full capacity kept)
        -->  update each bucket of 2 old instances in turn (v1 stopped, then v2)
        -->  at the end, terminate the additional batch  (back to 4)
```

| Aspect | Detail |
|---|---|
| **Capacity** | **At full capacity** at all times: the minimum running is the original count (4). Sometimes it runs **over** capacity. |
| **Versions** | Both versions run at the same time |
| **Cost** | A **small additional cost** (the extra batch exists only during the deployment). The exam may ask whether there is extra cost. |
| **Speed** | **Long** |
| **Best for** | **Production** where capacity must not drop |

### 5. Immutable

```
Current ASG:   3 x v1
Temporary ASG: launch ONE v2 instance (health check) --> if healthy, launch the rest (3 x v2)
               move the v2 instances into the current ASG (6 instances)
               terminate the v1 instances, then delete the temporary ASG
```

| Aspect | Detail |
|---|---|
| **Where** | New code goes to **new instances** (from a **temporary ASG**), not existing ones |
| **Downtime** | **Zero downtime** |
| **Cost** | **High**: you **double the capacity** during the deployment |
| **Speed** | **Longest** kind of deployment |
| **Rollback** | **Quick**: Beanstalk just **terminates the temporary ASG** |
| **Best for** | **Production**, if you accept a bit more cost |

### 6. Blue/Green (Not a Built-in Policy)

```
Blue environment (v1)  <--- Route 53 weighted: 90% ---+
Green environment (v2) <--- Route 53 weighted: 10% ---+   test, then swap URLs and retire blue
```

| Aspect | Detail |
|---|---|
| **Idea** | Create a **new environment** (a clone or a new one), deploy v2 there. The other policies all work **within one environment**. |
| **Benefits** | **Zero downtime**, easy testing, **rollback** by swapping back |
| **Manual** | **Not a direct Beanstalk feature**: you do it yourself. Optionally use **Route 53 weighted records** (for example 90/10) to test the green environment with real traffic. |
| **Cutover** | In the console, **Actions, Swap environment URLs** (a **CNAME swap**). Don't terminate the old environment until DNS caches expire. |
| **Database** | The environment must run **independently of the production database** (use an external or decoupled RDS) |
| **Also needed for** | Updating to an **incompatible platform version** |

### 7. Traffic Splitting (Canary Testing)

```
ALB --90%--> main ASG (3 instances, old version)
    --10%--> temporary ASG (3 instances, new version, same capacity)  for a configurable time
```

| Aspect | Detail |
|---|---|
| **Think** | **Canary testing** = **traffic splitting** |
| **How** | The new version goes to a **temporary ASG with the same capacity**. A **small % of traffic** goes there for a **configurable amount of time** (the evaluation time). Needs an **Application Load Balancer**. |
| **Automation** | **Deployment health is monitored.** A failure or bad metric triggers an **automated rollback**: stop sending traffic to the temporary ASG. **Very quick, no downtime.** |
| **Finish** | When stable, the new instances **move into the main ASG** and the **old version is terminated** |
| **Cost** | **High**: doubles capacity temporarily |

- The lecture calls this a big improvement over manual blue/green because it is **automated**.

### 8. Comparison (AWS Table)

- AWS references: [Deploying applications to Elastic Beanstalk environments](https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/using-features.deploy-existing-version.html) (the comparison table below), [Deployment policies and settings](https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/using-features.rolling-version-deploy.html), [Immutable environment updates](https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/environmentmgmt-updates-immutable.html), and [Blue/green deployments](https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/using-features.CNAMESwap.html).

| Method | Impact of failed deployment | Deploy time | Zero downtime | No DNS change | Rollback | Code deployed to |
|---|---|---|---|---|---|---|
| **All at once** | **Downtime** | Fastest | No | Yes | **Manual redeploy** | Existing instances |
| **Rolling** | A **single batch** out of service, earlier batches already on the new version | Moderate (depends on batch size) | Yes | Yes | **Manual redeploy** | Existing instances |
| **Rolling with additional batch** | Minimal if the first batch fails, otherwise like rolling | Slower | Yes | Yes | **Manual redeploy** | New and existing instances |
| **Immutable** | Minimal | Slowest | Yes | Yes | **Terminate new instances** | New instances |
| **Traffic splitting** | A **% of traffic** temporarily affected | Slowest (depends on evaluation time) | Yes | Yes | **Reroute traffic and terminate new instances** | New instances |
| **Blue/green** | Minimal | Slowest | Yes | **No** (CNAME swap) | **Swap URL** | New instances |

- **Support:** rolling, rolling with additional batch, and traffic splitting need a **load-balanced environment**. **Single-instance** environments support only **all at once** and **immutable**.
- Immutable and traffic splitting replace instances, so **EC2 burst (CPU credit) balances are lost**.

### 9. Exam-Style Recall

| If the question says... | Think... |
|---|---|
| "Fastest deployment, downtime acceptable (development)" | **All at once** |
| "No downtime, can run below capacity, no extra cost" | **Rolling** |
| "No downtime and must keep full capacity" | **Rolling with additional batch** (small extra cost) |
| "New instances, quick rollback, accept higher cost" | **Immutable** |
| "Canary testing" | **Traffic splitting** |
| "Test the new version on a separate environment and swap" | **Blue/green** (swap environment URLs) |
| "Blue/green is a Beanstalk setting?" | **No**, it is a manual process (CNAME swap) |
| "Quickest rollback" | **Immutable** or **traffic splitting** (terminate the new instances or reroute) |
| "Does rolling with additional batch cost more?" | **Yes**, slightly (the extra batch) |

---

## Beanstalk Deployment Modes Hands On

### 1. Choosing the Deployment Policy

In the **prod** environment: **Configuration**, **Updates, monitoring, and logging**, **Edit**, then **Rolling updates and deployments**.

| Setting | What it offers |
|---|---|
| **Application deployments** (the part the exam tests) | The **deployment policy** for a new application version |
| **Configuration updates** | How changes to the **instances themselves** (EC2 or VPC settings that replace instances) are applied: **rolling** or **immutable**. The exam doesn't test this part. |

| Policy | Batch size setting |
|---|---|
| **All at once** | **Fixed / percentage options are disabled**: they don't apply (they just remain in the UI) |
| **Rolling** | Batch size becomes available: a **percentage** (for example 30% of instances at a time) or **fixed** (for example 1 instance at a time) |
| **Rolling with additional batch** | Same percentage or fixed batch size. Keeps capacity, with **increased cost** from the temporary instances. |
| **Immutable** | Batch size **disabled**: it creates a whole new set of instances and deletes the old ones |
| **Traffic splitting** | Send a **percentage of traffic** to the new version for **X minutes** before upgrading everything |

- The demo chose **Immutable** and applied it, which makes Beanstalk **update the environment** (wait for it to finish).

### 2. Getting a New Application Version

- Search for the **Elastic Beanstalk Node.js sample application** and download **`nodejs.zip`** from the AWS tutorials.
- Contents of the package:

| File | Purpose |
|---|---|
| `index.html` | The welcome page (style and the "Congratulations" text) |
| `app.js` | The Node.js server that serves the HTML |
| `cron.yaml` | Schedule regular tasks on the instances |
| `.ebextensions/` | **Customize Beanstalk** with configuration files |
| `.gitignore` | Can be ignored |

- The change: set the **background color from green to blue** in the style. The course supplies a ready zip, `nodejs-v2-blue.zip`, because **Beanstalk can be picky about how the source bundle is zipped**.

### 3. Deploying v2 as Immutable

1. Environment page, **Upload and deploy**.
2. **Choose file:** `nodejs-v2-blue.zip`. **Version label:** `MyApplication-Blue`.
3. **Deployment preferences:** defaults to **Immutable** (what is configured). You could override it with all at once, rolling, or rolling with additional batch.
4. **Deploy**, then watch **Events**.

| Event | What it shows |
|---|---|
| **Launching one instance** with the new settings to verify health | A **temporary Auto Scaling group** is created with the new instance |
| New instance added to the **load balancer** | Waiting for it to pass the **health check** (it did) |
| Instances **detached** from the temporary ASG and **attached** to the **permanent ASG** | The merge step of immutable |
| **Post-deployment** configuration on the new instances | |
| **Old instances terminated**, temporary ASG removed | Deployment complete |

- Open the environment URL: **"Congratulations" is now blue**. Prod shows **blue**, dev still shows **green**.

### 4. Swapping Environment URLs (Blue/Green)

The idea for real use: **clone prod**, deploy the new version to the clone and test it thoroughly (call it prod number two), then **swap environment domains** to make it the production URL.

1. In the demo, with prod (blue) and dev (green): environment page, **Actions**, **Swap environment domains**.
2. Choose the other environment (**dev**), then **Swap**.
3. The swap **modifies DNS entries** so each name points to the other environment. DNS updates can be slow, so it took about **5 minutes**.
4. Result: refreshing the **prod** URL now shows **green**, and the **dev** URL shows **blue**: the environments swapped.
5. The lecture then swapped them back, to keep blue as prod and green as dev.

- This demonstrated **all the deployment options**, **cloning an environment**, and **swapping URLs**.

---

## Beanstalk CLI and Deployment Process

### TL;DR

- The **EB CLI** (Elastic Beanstalk CLI) is a separate CLI that makes working with Beanstalk from the command line easier. It can do what the console does, which helps **automate deployment pipelines**.
- **Out of scope for the Developer exam** (more relevant to the DevOps exam). Just know it exists.
- **Deployment process:** describe your **dependencies** (`requirements.txt` for Python, `package.json` for Node.js), **zip** the code, **upload** it to Beanstalk (stored in **S3**), which creates an **application version**, then **deploy** it. Each EC2 instance resolves the dependencies and starts the app.

### 1. The EB CLI

| Command | What it does |
|---|---|
| `eb init` | Set up the application in the current folder |
| `eb create` | Create an environment |
| `eb status` | Show the environment's status |
| `eb health` | Show the environment's health |
| `eb events` | Show recent events |
| `eb logs` | Retrieve the logs |
| `eb open` | Open the environment URL in a browser |
| `eb deploy` | Deploy the application: **packages** it as a zip, **uploads** it, and deploys |
| `eb config` | View or edit the environment's configuration |
| `eb terminate` | Terminate the environment |

- More commands exist (`eb list`, `eb scale`, `eb swap`, `eb clone`, `eb ssh`, `eb setenv`, and others).
- The EB CLI structures the zip correctly for you.

### 2. The Deployment Process

```
1. Describe dependencies   requirements.txt (Python) or package.json (Node.js)
2. Package the code        a ZIP file containing the code and the dependency file
3. Upload the ZIP          console, or the EB CLI (eb deploy)  -->  stored in Amazon S3
                           Beanstalk creates a new APPLICATION VERSION
4. Deploy the version      console or CLI
5. Beanstalk deploys the ZIP to each EC2 instance, which resolves the dependencies and starts the app
```

| Point | Detail |
|---|---|
| **Storage** | The uploaded bundle is stored in **Amazon S3**, and Beanstalk refers to the S3 object |
| **Dependencies** | **Resolved on each EC2 instance** from the dependency file, not packaged by Beanstalk |
| **Same flow** | Console or EB CLI: the CLI creates the zip, uploads it, and deploys it |

**Source bundle rules:** a single **ZIP** (or **WAR**) file, **up to 500 MB**, with **no parent folder** (the files and subfolders go at the top level, which is why zipping the parent folder fails). Worker apps with periodic tasks add a `cron.yaml`. Hidden files such as `.ebextensions` must be included, so zip from the command line.

### 3. Exam-Style Recall

| If the question says... | Think... |
|---|---|
| "Command line tool to create and manage Beanstalk environments, automate deployments" | **EB CLI** |
| "Deploy the current folder to Beanstalk from the terminal" | `eb deploy` |
| "Where is the application bundle stored?" | **Amazon S3** |
| "How do Node.js or Python dependencies get installed?" | Listed in **`package.json` / `requirements.txt`** and **resolved on each EC2 instance** |
| "Uploading a bundle creates a new..." | **Application version** |

---

## Beanstalk Lifecycle Policy Overview + Hands On

### TL;DR

- Beanstalk allows at most **1,000 application versions per Region** (across all applications in the account, adjustable). Reach the limit and you **can't create or deploy new versions**.
- Phase out old versions with an **application version lifecycle policy**, based on **time** (**max age**) or **space** (**max count**).
- Versions **currently used by an environment are never deleted**, however old.
- You choose whether to **keep or delete the source bundle in S3**. Keeping it prevents data loss and lets you restore a version later.
- The deletion runs under a **service role** (the Beanstalk service role).

### 1. Why and How

| Point | Detail |
|---|---|
| **The problem** | Every upload creates an **application version**. The quota is **1,000 per Region**, shared by all applications, so old versions pile up. |
| **The fix** | A lifecycle policy tells Beanstalk to **delete** versions that are **too old** or that **exceed a maximum count** |
| **When it runs** | Each time you **create a new application version** (up to **100 versions deleted** per run). The new version doesn't count toward the maximum. |
| **Never deleted** | Versions **used by an environment**, and versions deployed to environments **terminated less than 10 weeks ago** |
| **Source bundle** | **Kept in S3 by default** (to prevent data loss). You can choose to **delete it too**. Without that, the policy only removes the version from Beanstalk. |
| **Role** | The **Beanstalk service role** (`aws-elasticbeanstalk-service-role` by default) performs the deletion |
| **Scope** | Beanstalk **Standard** environments |

- With several applications, set each policy so the **total stays below 1,000** (for example 10 applications with a maximum of 99 versions each).

### 2. Demo

1. **Applications**, `My Application`, **Application versions**: the list shows each version label (for example `MyApplication-Blue`), **where it was deployed**, and its **source** (clicking **Source** downloads the bundle).
2. In **S3**, find the bucket Beanstalk created for the Region (`elasticbeanstalk-<region>-<account-id>`). Every uploaded **source bundle** is stored there, while the versions are **registered in Beanstalk**.
3. In Application versions, **Settings**, enable the **application lifecycle policy**:

| Setting | Demo options |
|---|---|
| **Limit by count** | For example a maximum of **200** application versions |
| **Limit by age** | For example only versions from the last **180 days** |
| **Source bundle in S3** | **Retain** (good for recovery) or **delete** it from S3 |
| **Service role** | The **Elastic Beanstalk service role** |

- A version that is in use is **never deleted**, even if it breaks the rule.

### 3. Exam-Style Recall

| If the question says... | Think... |
|---|---|
| "Can't deploy new Beanstalk versions, too many old versions" | The **application version limit (1,000)**. Apply a **lifecycle policy**. |
| "Automatically remove old Beanstalk application versions" | **Application version lifecycle policy** (by **age** or **count**) |
| "Keep a backup of removed versions" | **Retain the source bundle in S3** |
| "Where are Beanstalk application versions stored?" | **Amazon S3** (a Beanstalk-created bucket) |
| "Will the lifecycle policy delete the version running in an environment?" | **No** |

---

## Beanstalk Extensions

### TL;DR

- **EB extensions** (`.ebextensions`) let you configure everything you set in the Beanstalk UI **with code**, by shipping **configuration files** inside your source zip.
- Requirements: a folder named **`.ebextensions/`** in the **root** of the source bundle, files in **YAML or JSON**, each ending in **`.config`** (for example `logging.config`).
- Use **`option_settings`** to modify defaults and set options (such as **environment variables**). Use **`Resources`** to add AWS resources that the console can't create (RDS, ElastiCache, DynamoDB, and so on).
- **Anything created by the extensions is deleted when the environment is deleted.**

### 1. Requirements

| Rule | Detail |
|---|---|
| **Location** | A folder named **`.ebextensions/`** at the **root** of your source bundle (hidden folder: make sure it gets zipped) |
| **Format** | **YAML or JSON** (YAML is recommended, it supports comments) |
| **File name** | Must end in **`.config`**, even though the content is YAML or JSON |
| **Keys** | Use each top-level key **once per file** (a duplicate `option_settings` section is dropped) |
| **Platforms** | **Beanstalk Standard** environments (EC2-based) |

### 2. What You Can Configure

| Section | Use |
|---|---|
| **`option_settings`** | Set **configuration options**, i.e. modify defaults: environment variables, load balancer type, health check URL, and so on |
| **`Resources`** | Add **extra AWS resources** (anything CloudFormation supports): **RDS, ElastiCache, DynamoDB**, and more |
| **Others** | `packages`, `sources`, `files`, `users`, `groups`, `commands`, `container_commands`, `services`: configure the **EC2 instances** |

- Resources and configuration from the extensions are **part of the environment** (Beanstalk uses CloudFormation), so if the environment goes away, **an ElastiCache created this way goes with it**.
- **Precedence:** options set **directly on the environment** (console wizard, `--option-settings`) **override** the same options in `.ebextensions`.

### 3. Demo: Environment Variables

Project folder `nodejs-v3-ebextensions`, containing the app plus `.ebextensions/environment-variables.config`:

```yaml
option_settings:
  aws:elasticbeanstalk:application:environment:
    DB_URL: "jdbc:postgresql://example.us-east-1.rds.amazonaws.com:5432/ebdb"
    DB_USER: "username"
```

- The file ends in **`.config`** and sits in **`.ebextensions/`**: both are required for it to work. The values are just an example (the app doesn't use them). Connecting to an external RDS database would be a real use.
- The project was zipped as `nodejs-v3-ebextensions.zip`.

**Deploy:**

1. Open the **dev** environment (single instance, faster to update).
2. **Upload and deploy** the zip, version label `MyApplication-EBExtensionsDemo`, **Deploy**.
3. After the update, check **Configuration**, **Environment properties**: `DB_URL` and `DB_USER` appear, set **from the files in the deployed version**, not by hand in the console.

### 4. Exam-Style Recall

| If the question says... | Think... |
|---|---|
| "Configure Beanstalk with code in the source bundle" | **`.ebextensions`** configuration files |
| "Directory and file name for Beanstalk config files" | **`.ebextensions/`** in the root, files ending in **`.config`** |
| "Format of EB extension files" | **YAML or JSON** |
| "Set environment variables or modify defaults from a file" | **`option_settings`** |
| "Add an RDS, ElastiCache, or DynamoDB resource through Beanstalk configuration" | **`Resources`** section of an `.ebextensions` file |
| "What happens to resources created by `.ebextensions` when the environment is deleted?" | They are **deleted too** |

---

## Beanstalk & CloudFormation

### TL;DR

- Under the hood, **Elastic Beanstalk relies on CloudFormation** (infrastructure as code) to provision the AWS resources of each environment.
- That means that with **`.ebextensions` and CloudFormation `Resources`** you can provision **anything** (ElastiCache, S3 bucket, DynamoDB table, ...), even though the Beanstalk UI only configures a few things.
- You never need to touch CloudFormation to use Beanstalk. This lecture is just a look behind the scenes.

### 1. What CloudFormation Created

Each Beanstalk environment is one **CloudFormation stack** (named `awseb-e-...`). The stack's **Template** tab shows the template, and **Resources** lists what it created.

| Environment | Stack resources (from the demo) |
|---|---|
| **Dev** (single instance) | **Auto Scaling group**, a **launch configuration**, an **Elastic IP**, an **EC2 security group**, and **wait conditions** (ignore) |
| **Prod** (high availability) | **16 resources**: **Auto Scaling group**, launch configuration, **scaling policies** (two) with the **CloudWatch alarms** that trigger them, **security groups** (two), an **Elastic Load Balancer** with a **listener**, **listener rules**, and a **target group** |

- Newer accounts show a **launch template** instead of a launch configuration (see **Beanstalk First Environment**).

### 2. Why It Matters

- **Beanstalk** = a high-level, **code-centered** service. **CloudFormation** = the general engine that deploys **arbitrary stacks** of infrastructure.
- Because Beanstalk uses CloudFormation, the **`Resources` section of `.ebextensions`** (see **Beanstalk Extensions**) can add **any CloudFormation-supported resource** to your environment.
- Resources added that way are part of the stack, so they are **deleted with the environment**.

### 3. Exam-Style Recall

| If the question says... | Think... |
|---|---|
| "What does Elastic Beanstalk use to provision resources?" | **AWS CloudFormation** |
| "Add an ElastiCache cluster or DynamoDB table to a Beanstalk environment" | **`.ebextensions`** with CloudFormation `Resources` |
| "Where can you see the resources a Beanstalk environment created?" | The environment's **CloudFormation stack** (Resources tab) |

---

## Beanstalk Cloning

### TL;DR

- **Cloning** copies an existing environment into a **new environment with the same configuration**. Typical use: you have **prod** and want an identical **test** environment.
- **Resources and configuration are preserved** (load balancer type and settings, RDS configuration, environment variables, and so on). After cloning you can **change the settings**.
- **RDS data is not copied**, only the database configuration.
- Cloning is the first step of a **blue/green deployment**: clone, deploy and test the new version, then **swap environment URLs**.

### 1. What Is Preserved (and What Isn't)

| Preserved | Not preserved |
|---|---|
| Environment settings, **environment variables**, option settings | **Data in an RDS database** (the clone gets the **configuration**, not the data) |
| The AWS resources of the original (a copy), such as the **load balancer type** and its configuration, and the **RDS configuration** | **Unmanaged changes** (resources changed outside of Beanstalk) |
| | **Ingress security group rules** (add them again, or the clone is open to all internet traffic) |

- You can only clone to a **different platform version of the same platform branch**. A different branch needs a new environment.

### 2. Demo

1. Open the environment (`My Application dev`), **Actions**, **Clone environment**.
2. In **New environment**, set the **name** (for example dev2 or test), and optionally the **URL**, **description**, **platform version**, and **service role**. The options are limited.
3. Choose **Clone**. You get an environment identical to the original.
4. Afterwards, customize it from its **Configuration** tab.

- Typical goal: **deploy a new version to the clone, test it, then swap environment URLs** (see **Beanstalk Deployment Modes**).
- The EB CLI equivalent is `eb clone` (by default it uses the **latest platform version**, `--exact` keeps the same one).

### 3. Exam-Style Recall

| If the question says... | Think... |
|---|---|
| "Create a test environment with exactly the same settings as prod" | **Clone the environment** |
| "Is the RDS data copied when cloning a Beanstalk environment?" | **No**, only the **configuration** |
| "First step of a blue/green deployment in Beanstalk" | **Clone** the environment (or create a new one), deploy and test, then **swap URLs** |

---

## Beanstalk Migrations

### TL;DR

- You **can't change an environment's load balancer type** after creation (Classic to ALB, ALB to NLB), only its configuration. To change type, **migrate to a new environment** and shift traffic with a **CNAME swap** or **Route 53**.
- You **can't use cloning for that**, because a clone copies the same load balancer type.
- An RDS database created **inside** a Beanstalk environment is fine for dev and test, but **not for production**: its lifecycle is **tied to the environment**. In production, **decouple the database** and reference it by connection string (for example an environment variable).

### 1. Changing the Load Balancer Type

```
Old environment (Classic LB)  --copy settings by hand-->  New environment (Application LB)
                                  deploy the application to the new environment
                                  shift traffic: CNAME swap  or  Route 53 DNS update
```

| Step | Detail |
|---|---|
| **1. New environment** | Create it **manually** with the **same configuration except the load balancer**. **Clone doesn't work**: it would copy the old load balancer type. |
| **2. Deploy** | Deploy your application version to the new environment |
| **3. Shift traffic** | **Swap environment URLs (CNAME swap)** or update **Route 53** DNS |

### 2. Decoupling RDS from a Beanstalk Environment

**Why:** with a Beanstalk-managed database, deleting the environment deletes the database. In production, keep the database **separate**.

```
Old environment (with RDS)                      New environment (no RDS)
   |                                                |
   +---- same RDS database (protected) <---- connection string in an environment variable
```

| Step | Detail |
|---|---|
| **1. Snapshot** | Take an **RDS snapshot** as a safeguard |
| **2. Protect** | In the RDS console, turn on **deletion protection** so the database can't be deleted |
| **3. New environment** | Create a new Beanstalk environment **without RDS**, and point the app at the **existing database** (for example with an **environment variable**) |
| **4. Cut over** | **CNAME swap** (blue/green) or **Route 53** update, then confirm it works |
| **5. Terminate the old environment** | The database **survives** (deletion protection), so the old environment's **CloudFormation stack fails to delete** and ends in **`DELETE_FAILED`** |
| **6. Clean the stack** | **Delete the stack manually** in CloudFormation. The database now exists **on its own**, outside Beanstalk. |

- **Newer, simpler way:** Beanstalk can **decouple** a database itself (**Configuration, Database, Decouple database**) with a **deletion policy**: **snapshot**, **retain**, or **delete**. Apply the deletion policy **separately and before** decoupling. This is the approach AWS documents, with the manual steps above as the lecture's version.

### 3. Exam-Style Recall

| If the question says... | Think... |
|---|---|
| "Change a Beanstalk environment from Classic to Application Load Balancer" | **Create a new environment** with the new type, deploy, then **swap CNAMEs** (or Route 53) |
| "Why can't you clone to change the load balancer type?" | A clone **copies the same load balancer type** |
| "Beanstalk database should survive environment deletion in production" | **Decouple RDS** from the environment |
| "Point the app at an external database" | A **connection string** in an **environment variable** |
| "Safeguards before decoupling RDS" | **Snapshot** and **deletion protection** |
| "Old environment's stack is in DELETE_FAILED after terminating (database protected)" | Delete the **CloudFormation stack** manually |
