# ECS, ECR & Fargate - Docker in AWS

---

## Docker Introduction

### TL;DR

- **Docker** is a software development platform that packages apps into standardized **containers**. A containerized app **runs the same way everywhere**, with no compatibility issues.
- Docker use cases: **microservice architectures**, **lift and shift** of apps from on premises to the cloud, and **anytime you need to run a container**.
- A **Docker image** is stored in a **repository**: **Docker Hub** (public), **Amazon ECR** (private), or the **Amazon ECR Public Gallery** (public, on AWS).
- A **container shares the host OS**, whereas a **VM (EC2)** gets its own guest OS on a **hypervisor**. So containers are **lighter**, and one server runs **many more** of them, but isolation is **weaker**.
- Workflow: write a **Dockerfile**, **build** an image, **push** it to a repository, **pull** it, **run** it (a running image is a **container**).
- AWS container services: **ECS** (AWS's own orchestration), **EKS** (managed Kubernetes), **Fargate** (serverless containers, works with ECS and EKS), and **ECR** (image registry).

### 1. What Is Docker?

| Aspect | Detail |
|---|---|
| **What** | A platform to **package and deploy apps** as **containers** |
| **Standardized** | The same container runs on **any machine**, so behavior is **predictable** and there is **less work** to maintain and deploy |
| **Flexibility** | Works with **any language, OS, and technology** |
| **Use cases** | **Microservices** (a good exam keyword), **lift and shift** from on premises to the cloud, and **running containers** in general |

- Containers use the **host's kernel**. Linux containers need a Linux kernel, so on a Mac or Windows laptop Docker runs them inside a **small Linux VM**.

### 2. How Docker Runs on a Server

```
Server (for example an EC2 instance)
  Host OS
    Docker agent (daemon)
      Container 1: Java app      Container 2: Java app (same image, second copy)
      Container 3: Node.js app   Container 4: MySQL database
```

- Any server can host Docker (**EC2 instances** in the lecture's example).
- You can run **many copies of the same container**, and **different apps and databases** (Java, Node.js, MySQL) side by side. To the server, they are all just containers.

### 3. Where Docker Images Are Stored

| Repository | Type | Notes |
|---|---|---|
| **Docker Hub** | **Public** | Very popular. Has **base images** for many technologies and OSes (Ubuntu, MySQL, and so on). |
| **Amazon ECR** (Elastic Container Registry) | **Private** | **AWS-managed** registry. Access is controlled with **IAM**, and it integrates with **ECS and EKS**. |
| **Amazon ECR Public Gallery** | **Public** | The **public** repository option within ECR |

- ECR features and how ECS pulls from it are covered in **Amazon ECR**.

### 4. Docker vs Virtual Machines

```
Virtual machine (EC2)              Docker
  Apps + Guest OS (each VM)          Containers (lightweight)
  Hypervisor                         Docker daemon
  Host OS                            Host OS (for example an EC2 instance)
  Infrastructure                     Infrastructure
```

| | **Virtual machine** | **Docker container** |
|---|---|---|
| **Virtualization** | **Hardware level**, through a **hypervisor** | **OS level**. Resources are **shared with the host**. |
| **OS per workload** | Each VM has its **own guest OS** | **Shares the host OS** |
| **Isolation** | **Strong**: separate, isolated, no shared resources | **Weaker**: containers can share networking and data |
| **Weight** | Heavier | **Lightweight**, so **more per server** |
| **AWS example** | An **EC2 instance** is a VM running on a hypervisor, so AWS can host many customers' instances on one machine | Containers run **on top of** an EC2 instance (or Fargate) |

- Lecture caveat: Docker is "sort of" virtualization, not exactly. The key point is **shared host resources**, which is why **many containers fit on one server**.

### 5. Getting Started: The Docker Workflow

```
Dockerfile --docker build--> Docker image --push--> Repository (Docker Hub or ECR)
                                                          |
                                                        pull
                                                          v
                                          docker run: image becomes a running CONTAINER
```

| Step | Detail |
|---|---|
| **1. Write a Dockerfile** | Defines how the container looks: a **base image**, plus the files and commands you add |
| **2. Build** | Turns the Dockerfile into a **Docker image** |
| **3. Push** | Upload the image to a **repository**: **Docker Hub** (public) or **Amazon ECR** (AWS's version) |
| **4. Pull** | Download the image from the repository |
| **5. Run** | A running image becomes a **container** that runs your code |

### 6. Docker Container Management on AWS

| Service | What it is |
|---|---|
| **Amazon ECS** (Elastic Container Service) | **AWS's own** platform for managing Docker containers |
| **Amazon EKS** (Elastic Kubernetes Service) | AWS's **managed Kubernetes** (an **open-source** project) |
| **AWS Fargate** | AWS's **serverless container** platform. It works with **both ECS and EKS**. |
| **Amazon ECR** | Stores **container images** |

- The following lectures dive into **ECS, Fargate, and ECR**, with a quick look at EKS.

### 7. Exam-Style Recall

| If the question says... | Think... |
|---|---|
| "Package an app so it runs the same everywhere" | **Docker container** |
| "Microservice architecture" | **Docker containers** |
| "Move (lift and shift) an app from on premises to AWS, standardizing its runtime" | **Docker** |
| "Where to store private Docker images on AWS" | **Amazon ECR** |
| "Public repository for Docker images" | **Docker Hub**, or the **ECR Public Gallery** |
| "Docker vs a VM" | Containers **share the host OS** and are **lighter**. VMs have a **guest OS per VM** on a **hypervisor** and are **more isolated**. |
| "Which one is an EC2 instance, a VM or a container?" | A **virtual machine** on a hypervisor |
| "AWS's own container orchestration service" | **Amazon ECS** |
| "Managed Kubernetes on AWS" | **Amazon EKS** |
| "Run containers without managing servers" | **AWS Fargate** (works with **ECS and EKS**) |
| "Dockerfile becomes what after a build?" | A **Docker image**. Running it creates a **container**. |

---

## Amazon ECS

### TL;DR

- **ECS (Elastic Container Service)** is AWS's own container platform. You launch containers as **ECS tasks** (from a **task definition**) in an **ECS cluster**.
- **EC2 launch type:** the cluster is **EC2 instances you provision and maintain**. Each one runs the **ECS agent** that registers it with the cluster.
- **Fargate launch type:** **serverless**. No instances to manage. You define the task (**CPU and RAM**) and AWS runs it. To scale, **increase the number of tasks**.
- The exam loves **Fargate**: serverless and easier to manage than the EC2 launch type.
- Three IAM roles to tell apart: **EC2 instance (container instance) profile** (EC2 only, used by the agent), **task execution role** (ECS pulls images, writes logs, reads secrets), and **task role** (permissions for your **app code**, one per task).
- **ALB** is the default choice for ECS (works with EC2 and Fargate). **NLB** for very high throughput or **PrivateLink**.
- **Data persistence:** **EFS** is the classic choice (works with **EC2 and Fargate**, shared across AZs). **S3 Files** can mount an S3 bucket as a file system.

### 1. ECS Concepts

| Concept | Detail |
|---|---|
| **Cluster** | A **logical grouping** of tasks or services, running on the capacity registered to it |
| **Task definition** | A **JSON blueprint**: image, CPU and memory, ports, **IAM task role**, volumes, one or more containers |
| **Task** | **One running instance of a task definition** in a cluster (standalone or part of a service) |
| **Service** | Keeps a **desired number of tasks** running. It **replaces failed tasks** and can attach a **load balancer**. |
| **ECS agent** | Runs on each **EC2 container instance**. Reports task state and starts/stops tasks when ECS asks. |

### 2. Launch Types (Capacity)

| | **EC2 launch type** | **Fargate launch type** | **ECS Managed Instances** (newer) |
|---|---|---|---|
| **Infrastructure** | **You** provision and maintain EC2 instances | **None to manage** (serverless) | **AWS manages** the EC2 instances in your account (provisioning, patching, scaling) |
| **Each instance runs** | The **ECS agent**, which **registers it into the cluster** | n/a | n/a |
| **Scaling** | Add **instances** and tasks | **Increase the number of tasks** | Managed by AWS |
| **Placement** | Containers are **placed on your instances** as tasks start or stop | AWS runs the task for you, and you **don't know where** | Placed on AWS-managed instances |
| **Choose it when** | You need **GPU/special hardware**, specific instance types, privileged mode, or custom AMIs | You want **no infrastructure**, variable workloads, the simplest option | You want **Fargate-like simplicity with more control** over the instances |

- Fargate still runs on servers, you just **don't see or manage them**, and **no EC2 instance appears in your account**.
- You also choose the **launch type in the task definition**.

### 3. IAM Roles for ECS

```
EC2 instance (EC2 launch type only)            Tasks (EC2 and Fargate)
  ECS agent                                      Task A --> task role A (S3 API calls)
    uses the EC2 INSTANCE PROFILE                Task B --> task role B (DynamoDB API calls)
    to call ECS, CloudWatch Logs, ECR, Secrets   defined in the TASK DEFINITION
```

| Role | Used by | Needed for | Launch type |
|---|---|---|---|
| **EC2 instance profile** (container instance role) | The **ECS agent** | **Register the instance with ECS**, send **logs** to CloudWatch Logs, **pull images** from ECR | **EC2 only** |
| **Task execution role** | **ECS / Fargate** on your behalf | **Pull images from a private ECR repository**, write **CloudWatch Logs**, read **Secrets Manager / SSM Parameter Store** secrets referenced in the task definition | **Required on Fargate** for these. On EC2 it is needed for **secrets**, private registry auth, and similar. |
| **Task role** | Your **application code in the container** | Calls to **other AWS services** (S3, DynamoDB, and so on). **One role per task** gives **least privilege**. | **Both** |

- The **task role** is set in the **task definition**. The agent hands the task **temporary credentials** automatically (the SDK finds them through `AWS_CONTAINER_CREDENTIALS_RELATIVE_URI`).
- Remember the split: **instance profile = the EC2 host/agent**, **task execution role = ECS setting up the task**, **task role = the app**.
- The lecture lists ECR pulls, logs, and secrets under the **instance profile**. On **Fargate** there is no instance, so those permissions come from the **task execution role** (the exam-relevant role for Fargate).

### 4. Load Balancer Integration

```
Users --> ALB --> ECS tasks (EC2 or Fargate), exposed as an HTTP/HTTPS endpoint
```

| Load balancer | Use with ECS |
|---|---|
| **Application Load Balancer (ALB)** | **Recommended**: HTTP/HTTPS, **path-based routing**, **dynamic port mapping** (several tasks of a service on one instance), works with **Fargate and EC2** |
| **Network Load Balancer (NLB)** | **Very high throughput or performance**, or with **AWS PrivateLink** (TCP/UDP) |
| **Gateway Load Balancer** | Virtual appliances (firewalls, inspection). Supported on Fargate. |
| **Classic Load Balancer** | **Not recommended**: no advanced features, and **not usable with Fargate** (per the lecture) |

### 5. Data Persistence

| Volume | Launch types | Notes |
|---|---|---|
| **Amazon EFS** | **Fargate, EC2, ECS Managed Instances** (Linux) | **Persistent, shared** network file system. Tasks in **any AZ** mount the **same data**, so they can share files. **Serverless** and pay as you go, so **Fargate + EFS** is the classic serverless combo. |
| **Amazon EBS** | Fargate, EC2, Managed Instances | Block storage for one task (persisted only for **standalone** tasks, ephemeral for service tasks) |
| **Amazon S3 Files** (newer) | **Fargate, ECS Managed Instances** | Mount an **S3 bucket as a file system** for containers that need shared file access to data **already in S3**. The lecture says changes **sync back to the bucket**. |
| **Bind mounts** | All | **Ephemeral**, share data between containers in a task |
| **Docker volumes** | EC2 only | Persistent on the host |

- **EFS use case:** **persistent, multi-AZ, shared** storage for containers.

### 6. Exam-Style Recall

| If the question says... | Think... |
|---|---|
| "Run Docker containers on AWS" | **ECS task** in an **ECS cluster** |
| "ECS with no infrastructure to manage" | **Fargate launch type** |
| "Scale a Fargate workload" | Increase the **number of tasks** |
| "EC2 launch type: what must run on each instance?" | The **ECS agent**, to register it into the cluster |
| "Give a container permission to call S3 or DynamoDB" | **ECS task role** (set in the **task definition**) |
| "Different permissions for each task" | A separate **task role** per task |
| "ECS agent needs permission to register the instance, send logs, pull from ECR (EC2)" | **EC2 instance profile** |
| "Fargate task must pull from private ECR and write CloudWatch logs" | **Task execution role** |
| "Task definition references a Secrets Manager secret" | **Task execution role** |
| "Expose ECS tasks as an HTTP/HTTPS endpoint" | **Application Load Balancer** |
| "Very high throughput, or PrivateLink with ECS" | **Network Load Balancer** |
| "Persistent shared storage across tasks in multiple AZs" | **Amazon EFS** (works with Fargate and EC2) |
| "Containers need file access to data already in S3" | **S3 Files** volume (Fargate or Managed Instances) |
| "Specialized hardware, GPUs, custom AMI" | **EC2 launch type** |

---

## Creating ECS Cluster - Hands On

### 1. Creating the Cluster

1. ECS console, **Clusters**, **Create cluster**.
2. **Cluster name:** `DemoCluster`.
3. Under **Infrastructure**, choose how the cluster gets capacity:

| Option | What it means | Demo |
|---|---|---|
| **Fargate only** | **Serverless**: AWS provides the servers | Not used |
| **Fargate and Managed Instances** | Fargate **plus** EC2 instances that **AWS manages** | Walked through, then not created (section 2) |
| **Fargate and Self-managed instances** | **Old way**: you manage the EC2 instances, **Auto Scaling group**, AMI, and instance type | **Created** (section 3). AWS is **steering people away** from this option. |

- The console creates the cluster through a **CloudFormation stack**.

### 2. Managed Instances Option (Viewed Only)

| Setting | Demo value |
|---|---|
| **Instance profile** | **Create new instance profile**, choose **EC2 role for ECS Managed Instances**, name **`ecsInstanceRole`**, **Create role**. (The role already existed in the demo account, so the existing one was selected.) |
| **Infrastructure role** | **Create new infrastructure role**, choose **Infrastructure for ECS Managed Instances**, **Next**, **Create role**, then select it back in the cluster form |
| **Instance selection** | **ECS default**: ECS picks instances from the **task definition and service requirements** (right for **production**). Or **Custom**: set **vCPU** and **memory** min/max, and an **allowed instance type** (for example only `t3.micro`). |

- AWS then manages the instances behind the scenes, so no Auto Scaling group is needed.

### 3. Self-Managed Instances Option (Created)

Chosen so the following lectures match. The settings:

| Setting | Demo value |
|---|---|
| **Provisioning model** | **On-demand**, with a **new Auto Scaling group** |
| **Instance type** | `t3.micro` |
| **EC2 instance role** | The **default** role |
| **Maximum** | **2** instances |
| **SSH key pair** | None (**no SSH** needed) |
| **Root EBS volume size** | **30 GB** (minimum) |
| **Network settings** | **Defaults** |

- Choose **Create**. The console builds the **Auto Scaling group** (`Infra-ECS-Cluster...`) in the **EC2 console**: capacity **0**, the subnets it spans are the **AZs** where tasks can be placed.

### 4. Exploring the Cluster

Open `DemoCluster`: **Services** and **Tasks** both show **0** (nothing launched yet). Open the **Infrastructure** tab, which shows **three capacity providers**:

| Capacity provider | Meaning |
|---|---|
| **FARGATE** | Launch **Fargate tasks** on this cluster |
| **FARGATE_SPOT** | Launch Fargate tasks in **Spot mode**: **cheaper**, but tasks can be **interrupted** (two-minute warning) |
| **ASG provider** | Launch tasks on **EC2 container instances** from the **Auto Scaling group**. **Managed scaling** is on, current size **0**. |

- A **capacity provider strategy** can't mix **Fargate** and **ASG** providers, so a task runs on one or the other.

### 5. Adding an EC2 Container Instance

1. In the **Infrastructure** tab, open the ASG provider's **Details** and **edit the desired capacity to `1`**.
2. The ASG launches an **EC2 instance** (check **Auto Scaling Groups** until it is **in service**). The lecture saw it listed as `t2.micro` even though `t3.micro` was selected.
3. The instance **registers itself** with `DemoCluster` and appears under **Container instances**.

| Container instance (demo) | Value |
|---|---|
| **Running tasks** | **0** |
| **CPU available** | **1024** (units) |
| **Memory available** | **982** (MiB) |

- This is the **capacity** left for tasks: a task can be placed on this instance **until its CPU or memory runs out**.
- A task launched in this cluster can use **Fargate or Fargate Spot** capacity, or **the container instances** from the ASG.

---

## Creating ECS Service - Hands On

### 1. Creating the Task Definition

ECS console, **Task definitions**, **Create new task definition**.

| Setting | Demo value | Notes |
|---|---|---|
| **Task definition family** | `nginxdemos-hello` | Named after the Docker Hub image |
| **Infrastructure** | **AWS Fargate** (serverless) | Enabling **Amazon EC2 instances** too would allow launching on the cluster's instances. Fargate only, for simplicity. |
| **OS / architecture** | **Linux** | |
| **Task size** | **0.5 vCPU**, **1 GB** memory | Cheapest and enough. Fargate offers more (the lecture says up to 16 vCPU and 120 GB, the docs now list up to **32 vCPU and 244 GB** for Linux). |
| **Task role** | **None** | Needed only when the containers call AWS APIs. **Critical** when they do. |
| **Task execution role** | **Default** | **Created automatically by ECS** if it doesn't exist yet |
| **Container name** | `nginxdemos-hello` | |
| **Image URI** | `nginxdemos/hello` | **Pulled automatically from Docker Hub** |
| **Port mapping** | Container port **80** (TCP) | Others (more ports, resource limits, environment variables, logging) left as **default** |
| **Ephemeral storage** | **Default** (the console showed **21 GiB**) | Fargate's built-in task storage |

- Choose **Create**. The first registration is **revision 1** (the lecture showed revision 2 because he had created it twice).

### 2. Creating the Service

`DemoCluster`, **Services**, **Create**.

| Section | Demo value |
|---|---|
| **Task definition family / revision** | `nginxdemos-hello`, **latest** revision |
| **Service name** | Default (or your own) |
| **Compute configuration** | **Capacity provider strategy** (default), **FARGATE**. **Platform version:** **LATEST** |
| **Deployment configuration** | **Replica**, **desired tasks: 1** (keep cost low, use more for more containers) |
| **AZ rebalancing** | Left as default (rebalances tasks if too many land in one AZ) |
| **Networking** | Default VPC **subnets**, **new security group** allowing **HTTP (80) from anywhere**, **public IP: on** |
| **Load balancing** | **Application Load Balancer**, **create new**: name `DemoALBForECS`, **listener 80**, **new target group** `nginxdemosTG` on **port 80** (container `nginxdemos-hello:80`) |
| **Left untouched** | **VPC Lattice**, **service auto scaling**, **volumes** |

- Choose **Create**.

### 3. Verifying the Service

| Check | Result |
|---|---|
| **Service status** | **Active**, **1 desired / 1 running** |
| **Target group** | Linked to `DemoALBForECS`, with **one IP registered**: the **container's private IP** |
| **Load balancer** | **Active**. Copy its **DNS name** into a new tab: the **nginx welcome page** loads. The **server address** shown equals the registered private IP. |
| **Another path** | `/test` works too (the URI changes, nginx responds) |
| **Tasks tab** | One running task. Opening it shows its **configuration, revision, private IP, containers**, and **Logs** (the nginx container's logs) |
| **Events tab** | Task **started**, **registered in the target group**, deployment **complete**, then **steady state** |

### 4. Scaling Out

1. **Update service**, set **desired tasks to 3** (one per AZ). Leave the task definition, **Fargate** compute, and load balancer settings, then **Update**.
2. Two more tasks go **Pending**, **Activating**, **Running** within a minute or so. **Fargate provisions the capacity** behind the scenes.
3. Refresh the ALB URL repeatedly: the **server address changes** each time, so the **ALB spreads requests across all the tasks**.

### 5. Scaling Down

1. **Update service**, **desired tasks = 0**. The **service stays**, but no containers run (**Events** shows what ECS did).
2. In **EC2, Auto Scaling Groups**, set the cluster's ASG **desired capacity to 0** so no EC2 instances keep running.
3. Verify the tasks are gone.

---

## Amazon ECS - Auto Scaling

### TL;DR

- **ECS Service Auto Scaling** automatically changes the **number of tasks** in a service, using **AWS Application Auto Scaling**.
- Exam metrics: **ECS service CPU utilization**, **ECS service memory utilization**, and **ALB request count per target**.
- Scaling types: **target tracking** (hold a metric at a target value), **step scaling** (CloudWatch alarm with step adjustments), and **scheduled scaling** (for predictable changes).
- **Scaling tasks is not scaling the cluster.** With the **EC2 launch type** you also need to scale the **EC2 instances**. With **Fargate** there are no instances, so auto scaling is much simpler (a reason the exam favors Fargate).
- To scale EC2 instances, prefer an **ECS cluster capacity provider** (managed scaling) over plain **Auto Scaling group scaling** (for example on CPU).

### 1. Service Auto Scaling (Task Level)

```
More users --> service CPU rises --> CloudWatch metric --> CloudWatch alarm
           --> Application Auto Scaling raises the service's DESIRED TASK COUNT --> a new task starts
```

| Metric (predefined) | What it measures |
|---|---|
| **`ECSServiceAverageCPUUtilization`** | **CPU** use of the service |
| **`ECSServiceAverageMemoryUtilization`** | **Memory (RAM)** use of the service |
| **`ALBRequestCountPerTarget`** | **Requests per task** behind the **ALB** |

| Scaling policy | How it works |
|---|---|
| **Target tracking** | Pick a **target value** for a metric (like a **thermostat**). ECS adds or removes tasks to hold it. **Easiest.** |
| **Step scaling** | A **CloudWatch alarm** with **step adjustments** that vary with the size of the breach. Reacts faster. |
| **Scheduled scaling** | Change the task count on a **date and time**, for predictable load |

- You also set **minimum and maximum** task counts. A minimum of **0** lets the service scale to **zero** tasks.
- Scaling policies have a **cooldown** (wait for the last activity to take effect), and scale-in is blocked while a **deployment** is in progress.
- Beyond the lecture: **predictive scaling** (from historical patterns), **SQS queue backlog** scaling, and other CloudWatch **custom metrics**.

### 2. Scaling the EC2 Instances (EC2 Launch Type Only)

Scaling **tasks** doesn't add **instances**. If the cluster runs out of CPU or RAM, tasks stay **pending**.

| Option | How it works | Verdict |
|---|---|---|
| **Auto Scaling group scaling** | Scale the ASG on a metric such as **CPU utilization**, adding instances when CPU rises | Older approach |
| **ECS cluster capacity provider** (managed scaling) | Paired with an **ASG**. When you **lack CPU or RAM to place tasks**, it **scales the ASG automatically** (and scales in when instances are unused) | **Smarter, use this** |

- With managed scaling, ECS creates the **CloudWatch alarms and a target tracking policy** on the ASG for you (a **`CapacityProviderReservation`** metric against a **target capacity**, default 100%). Don't manage that ASG's desired capacity yourself.
- **Fargate** needs none of this: no instances to scale.

### 3. Exam-Style Recall

| If the question says... | Think... |
|---|---|
| "Automatically scale the number of ECS tasks" | **ECS Service Auto Scaling** (Application Auto Scaling) |
| "Which service performs ECS service auto scaling?" | **AWS Application Auto Scaling** |
| "Metrics to scale an ECS service on" | **CPU utilization, memory utilization, ALB request count per target** |
| "Keep average CPU at 50%" | **Target tracking** scaling policy |
| "Scale ahead of a known traffic spike" | **Scheduled scaling** |
| "Task count scaling vs instance scaling (EC2 launch type)" | They are **different**: you must also scale the **EC2 instances** |
| "Simplest ECS auto scaling, no instances to scale" | **Fargate** |
| "Scale EC2 instances when ECS lacks capacity to place tasks" | **ECS cluster capacity provider** with managed scaling (not plain ASG scaling) |

---

## Amazon ECS - Rolling Updates

### TL;DR

- A **rolling update** replaces an ECS service's tasks with a new task definition revision (v1 to v2), a few at a time. Two settings control the pace: **minimum healthy percent** and **maximum percent**.
- **Defaults: minimum healthy percent 100, maximum percent 200.**
- **Minimum healthy percent** = the **lowest** number of running, healthy tasks allowed during the update (as a % of the desired count). Below 100 means old tasks can be **stopped first**.
- **Maximum percent** = the **highest** number of tasks allowed during the update. Above 100 means new tasks can be **started first**.
- The lecture warns this may appear in **only one exam question**, so know the two worked examples below.

### 1. The Two Settings

The desired task count is **100%**.

| Setting | Meaning | Effect on the update |
|---|---|---|
| **Minimum healthy percent** (default **100**) | **Lower limit** of running and healthy tasks, as % of desired. Rounded **up**. | **Below 100**: ECS may **stop old tasks** before starting new ones. **At 100**: it can't stop anything until new tasks are healthy. |
| **Maximum percent** (default **200**) | **Upper limit** of tasks (old plus new), as % of desired. Rounded **down**. | **Above 100**: ECS may **start new tasks** before stopping old ones. **At 100**: it must stop old tasks first. |

- Set them so ECS can **stop or start at least one task**, or the deployment gets **stuck** (ECS sends a service event saying it was unable to stop or start tasks).
- The default pair (100 / 200) starts the new tasks **first**, then stops the old ones: no capacity loss, but it needs room for **up to double** the tasks (on the EC2 launch type, enough spare instance capacity).

### 2. Worked Examples (4 Tasks)

**Example A: minimum 50%, maximum 100%** (stop first, never exceed 4 tasks)

| Step | Old tasks | New tasks | Total / capacity |
|---|---|---|---|
| Start | 4 | 0 | 4 (100%) |
| 1. Stop 2 old (down to the minimum) | 2 | 0 | 2 (**50%**) |
| 2. Start 2 new | 2 | 2 | 4 (100%) |
| 3. Stop 2 old | 0 | 2 | 2 (**50%**) |
| 4. Start 2 new | 0 | 4 | 4 (100%) |

**Example B: minimum 100%, maximum 150%** (start first, never drop below 4)

| Step | Old tasks | New tasks | Total / capacity |
|---|---|---|---|
| Start | 4 | 0 | 4 (100%) |
| 1. Start 2 new (up to the maximum) | 4 | 2 | 6 (**150%**) |
| 2. Stop 2 old | 2 | 2 | 4 (100%) |
| 3. Start 2 new | 2 | 4 | 6 (**150%**) |
| 4. Stop 2 old | 0 | 4 | 4 (100%) |

- Example A **trades capacity for speed and cost** (it dips to 50%, no extra tasks needed). Example B **keeps full capacity** but needs **extra room**.
- The lecture's opening line for Example A says "lose four tasks", it means **two**.

### 3. Detecting a Failed Rolling Update

| Method | Use it when | Notes |
|---|---|---|
| **Deployment circuit breaker** | Tasks **can't start** | Stops the failing deployment and can **roll back** to the previous revision |
| **CloudWatch alarms** | You want to stop based on **application metrics** | Can also **roll back** |

- You can use both. The deployment is marked failed when **either** criterion is met.
- If an unhealthy task appears mid-deployment, ECS **replaces it** to hold the minimum healthy percent.

### 4. Exam-Style Recall

| If the question says... | Think... |
|---|---|
| "Update an ECS service from v1 to v2 gradually" | **Rolling update** (new task definition revision) |
| "Settings that control a rolling update" | **Minimum healthy percent** and **maximum percent** |
| "Default minimum healthy and maximum percent" | **100** and **200** |
| "Replace tasks without ever dropping below full capacity" | Minimum healthy **100%**, maximum **above 100%** (for example 150%) |
| "Update with no spare capacity, accept running fewer tasks" | Minimum healthy **below 100%** (for example 50%), maximum **100%** |
| "Rolling update is stuck, no tasks start or stop" | The min and max settings **don't let ECS stop or start a task**. Adjust them. |
| "Automatically roll back a failed ECS deployment" | **Deployment circuit breaker** (or CloudWatch alarms) with rollback |

---

## Amazon ECS - Solutions Architectures

### TL;DR

- **EventBridge + ECS (event-driven):** an S3 upload event triggers an EventBridge rule that **runs a Fargate task**. The task (with an **ECS task role**) processes the object and writes to **DynamoDB**. Fully **serverless**.
- **EventBridge schedule + ECS (batch):** a **scheduled rule** (for example every hour) runs a Fargate task for **batch processing**.
- **SQS + ECS (queue workers):** a service's tasks **poll an SQS queue**. **Service Auto Scaling** adds tasks as the queue grows.
- **ECS events to EventBridge:** ECS publishes **task and service state changes** (for example a task **stopped**). A rule can alert an **SNS topic** to email admins.

### 1. S3 Event Triggers an ECS Task

```
User --upload--> S3 bucket --event--> EventBridge rule --run task--> ECS task on Fargate
                                                                      (ECS task role)
                                                                       | get object from S3
                                                                       | process it
                                                                       +--> DynamoDB (results)
```

| Piece | Detail |
|---|---|
| **S3 to EventBridge** | **Enable EventBridge notifications** on the bucket. S3 then sends events such as **Object Created**, and the rule filters them. |
| **Rule target** | The rule **runs an ECS task** on the **Fargate** cluster. It needs an **IAM role** that lets EventBridge run the task. |
| **ECS task role** | Lets the container **read from S3** and **write to DynamoDB** |
| **Result** | A **serverless** way to process images or objects with a **Docker container** |

### 2. Scheduled ECS Task

```
EventBridge schedule (every 1 hour) --run task--> ECS task on Fargate (task role: S3 access)
                                                   batch-processes files in S3
```

- A **new task** starts on each trigger and exits when done. Nothing runs between runs, so it is **fully serverless** and you pay only while the task runs.
- Use **EventBridge Scheduler** (the newer, more scalable scheduler, with **rate**, **cron**, and **one-time** schedules in any time zone) or a scheduled rule.

### 3. SQS Queue with an ECS Service

```
Producers --> SQS queue <--poll-- ECS service (tasks = workers)
                                    ^
              Service Auto Scaling: more messages in the queue --> more tasks
```

- The service's tasks **pull messages from the queue** and process them.
- **Scale the service on the queue**: the docs recommend scaling on **backlog per task** (queue depth divided by running tasks, computed with CloudWatch **metric math**), which needs **Container Insights** for the running-task count. Scaling on raw queue depth can over-scale.
- Messages a stopped task didn't finish **return to the queue** (mind the **visibility timeout**), and **task scale-in protection** keeps a busy task from being stopped.

### 4. Reacting to ECS Events

```
ECS cluster --task state change (for example STOPPED, with a stopped reason)--> EventBridge rule --> SNS topic --> email to admins
```

- ECS sends **task state change**, **service action**, **deployment state change**, and **container instance state change** events to EventBridge.
- A rule can match, for example, **tasks that stopped** (the event carries the **stopped reason**) and notify **SNS**, Lambda, and so on.
- EventBridge gives you visibility into the **lifecycle of your containers**.

### 5. Exam-Style Recall

| If the question says... | Think... |
|---|---|
| "Process S3 uploads with a container, serverless" | S3, **EventBridge**, **ECS task on Fargate** with a **task role**, then DynamoDB |
| "Run a container every hour" | **EventBridge schedule** (Scheduler or a scheduled rule) that runs a **Fargate task** |
| "Containers that consume messages from a queue and scale with the queue" | **ECS service** polling **SQS**, with **Service Auto Scaling** |
| "Notify admins when an ECS task stops" | **ECS task state change event**, **EventBridge** rule, **SNS** |
| "How does the container access S3 and DynamoDB?" | **ECS task role** |
| "S3 object created should start an ECS task" | **Enable EventBridge** notifications on the bucket, then an **EventBridge rule** with an ECS task target |

---

## Amazon ECS Task Definitions - Deep Dive

### TL;DR

- A **task definition** is **JSON** (the console has a UI that builds it) that tells ECS **how to run one or more Docker containers**. You can define **up to 10 containers** per task definition.
- Key contents: **image name**, **container port** (and **host port** on EC2), **CPU and memory**, **environment variables**, **networking**, the **IAM task role**, and **logging** (for example CloudWatch).
- **EC2 launch type + ALB:** leave the host port unset (**0**) for **dynamic host port mapping**. The ALB finds the random ports itself (not the Classic Load Balancer), so the instance security group must allow **all ports from the ALB's security group**.
- **Fargate:** each task gets its own **ENI and private IP**, so only the **container port** matters, and the ALB hits **port 80** on every task.
- The **IAM task role is set in the task definition**, not on the service. Every task of that definition inherits it.
- **Environment variables:** hard-coded, **secrets from SSM Parameter Store or Secrets Manager** (resolved at launch), or **bulk from a file in S3**.
- **Sharing data between containers** (sidecars): use a **bind mount** volume. On EC2 it lives on the **instance's storage**, on Fargate it is **ephemeral task storage** (20 to 200 GiB).

### 1. What a Task Definition Contains

| Setting | Detail |
|---|---|
| **Image name** | The container image (for example from **Docker Hub** or **ECR**) |
| **Port mappings** | **Container port**, plus **host port** on EC2 |
| **CPU and memory** | Required resources |
| **Environment variables** | Plain values, secrets, or a file from S3 |
| **Networking** | Network mode (Fargate uses **`awsvpc`**) |
| **IAM role** | The **task role** (and the **execution role**) |
| **Logging** | For example **CloudWatch Logs** |
| **Volumes** | Shared storage between the task's containers |

- The same task definition can hold **several containers**: your application plus **sidecars** (logging, metrics, tracing). **Limit: 10 containers per task definition**.

### 2. Port Mappings on the EC2 Launch Type

```
Internet --> EC2 instance port 8080 (host port) --> container port 80 (Apache HTTP server)
```

| Setting | Meaning |
|---|---|
| **Container port** | The port the **app listens on inside the container** (for example 80) |
| **Host port** | The port on the **EC2 instance** that maps to it (for example 8080). It **doesn't have to equal the container port**. **Not relevant on Fargate.** |

**Dynamic host port mapping** (EC2 launch type with a load balancer):

```
Task definition: container port 80, host port 0 (not set)
EC2 instance:  task 1 --> host port 32768, task 2 --> host port 32769, task 3 --> host port 32770 ...
ALB (linked to the ECS service) discovers each task's random port and registers it in the target group
```

| Point | Detail |
|---|---|
| **How** | Define **only the container port** (host port **0** or unset). The host port becomes **random**, so **several tasks of one service fit on one instance**. |
| **Who handles the random ports** | The **ALB**, because it is linked to the ECS service. It works with the **ALB only** (not the Classic Load Balancer, the older generation). |
| **Security group** | The **EC2 instance's security group must allow any port from the ALB's security group**, because the host ports are unknown in advance |
| **Network mode** | This is **bridge** mode on EC2 (dynamic host ports are **not** possible in `awsvpc` mode) |

### 3. Port Mappings on Fargate

```
Internet --(80/443)--> ALB --(80)--> task 1 (ENI, private IP A)
                                  --> task 2 (ENI, private IP B)   same container port on every task
                                  --> task 3 (ENI, private IP C)
```

| Point | Detail |
|---|---|
| **No host** | There is no EC2 host, so you define **only the container port** |
| **Networking** | Each task gets its **own ENI and private IP** (`awsvpc` mode, the only mode on Fargate) |
| **ALB** | Connects to **every task on the same port** (for example 80) |
| **Security groups** | The **task (ENI) security group allows port 80 from the ALB's security group**. The **ALB's security group allows 80 or 443 from the internet**. |

### 4. IAM Roles: Defined in the Task Definition

```
Task definition A --(task role A: S3)-->        all tasks of service A can call S3
Task definition B --(task role B: DynamoDB)-->  all tasks of service B can call DynamoDB
```

- The **task role** is assigned **per task definition**, **not per service**. Every task launched from it **assumes the role automatically**.
- Different task definitions can have **different roles** (least privilege).
- Exam question: "Where do you define the IAM role for an ECS task?" The answer is the **task definition**.
- Don't confuse it with the **task execution role** (ECS pulling images, writing logs, reading secrets) or the **EC2 instance profile** (see **Amazon ECS**).

### 5. Environment Variables

| Source | Use for | Detail |
|---|---|---|
| **Hard-coded** (`environment`) | **Non-secret fixed values** such as a plain URL | Set directly in the task definition |
| **SSM Parameter Store** or **Secrets Manager** (`secrets`) | **Sensitive values**: API keys, shared config, database passwords | The task definition **references** them. They are **fetched and resolved at launch** and **injected as environment variables**. Needs the **task execution role**. |
| **Bulk file from S3** (`environmentFiles`) | Loading many variables at once | A **`.env`** file in S3 (UTF-8, **up to 10 files** per task definition). The **task execution role** needs S3 read access. |

- If a variable is in both `environment` and a file, the **`environment` value wins**.
- AWS recommends **Secrets Manager or Parameter Store** for sensitive data (S3 env files are ordinary S3 objects).

### 6. Sharing Data Between Containers in a Task

- A task can run **several containers**. **Sidecars** (also called side cars) help with **logging, metrics, and tracing**, and often need to **read what the app writes**.
- Mount a **data volume** (a **bind mount**) into **both** containers. It works on **EC2 and Fargate**.

```
Task
  app container(s)  --write--> /var/logs (shared bind mount)
  sidecar container (metrics and logs) --read--> /var/logs
```

| Launch type | Where the bind mount lives | Lifecycle |
|---|---|---|
| **EC2** | The **EC2 instance's storage** | Tied to the **EC2 instance** |
| **Fargate** | **Ephemeral task storage**. Default **20 GiB**, up to **200 GiB** (the lecture's 20 to 200 GB). | Tied to the **task**: when the task goes away, the storage goes too |

- Bind mounts are **ephemeral**. For **persistent, shared** data across tasks, use **EFS**.
- **Exam use case:** share data between containers, especially a **sidecar that ships metrics or logs** to another destination.

### 7. Exam-Style Recall

| If the question says... | Think... |
|---|---|
| "Maximum containers in one task definition" | **10** |
| "Multiple tasks of one service on the same EC2 instance behind an ALB" | **Dynamic host port mapping** (host port **0**), bridge mode, **ALB** |
| "Dynamic port mapping with a Classic Load Balancer" | **Not supported**. Use the **ALB**. |
| "EC2 security group for dynamic host ports" | Allow **all ports** from the **ALB's security group** |
| "Fargate task networking" | **`awsvpc`**: one **ENI and private IP** per task, only the **container port** is defined |
| "Where is the IAM role for an ECS task defined?" | The **task definition** (the **task role**) |
| "Store DB passwords for an ECS container" | **Secrets Manager** or **SSM Parameter Store**, referenced in the task definition |
| "Load many environment variables from a file" | A **`.env` file in S3** (`environmentFiles`) |
| "Share files between an app container and a logging sidecar" | A **bind mount** volume in the task |
| "Fargate bind mount storage" | **Ephemeral storage**, lives and dies with the **task** |
| "Persistent data shared across tasks and AZs" | **EFS** |

---

## Amazon ECS Task Definitions - Hands On

Console tour of **Task definitions**, **Create new task definition**. Concepts (roles, ports, env vars, bind mounts) are in the previous lectures.

### 1. Task Definition and Infrastructure

| Setting | Demo value / options | Notes |
|---|---|---|
| **Family** | `wordpress` | |
| **Infrastructure** | **AWS Fargate**, **Amazon EC2 instances**, or **both** | |
| **CPU and memory** | **Fargate:** pick from **compatible CPU/memory combinations**. **EC2:** enter **any value**. | |
| **Network mode** | **Fargate:** must be **`awsvpc`**. **EC2 only:** more options (bridge, host, and so on). | |
| **Task role** | An IAM role for your containers' **AWS API calls** (the role the application uses) | Heavily tested |
| **Task execution role** | An IAM role for the **container agent** to make AWS API requests **on your behalf** (pull images, logs) | The standard ECS role |

### 2. Containers

**Container 1:**

| Setting | Demo value | Notes |
|---|---|---|
| **Name** | `wordpress` | |
| **Image URI** | `wordpress` | A public image by default |
| **Essential container** | **Yes** | At least **one** essential container is required. A task may have as many containers as needed. |
| **Private registry authentication** | The **Secrets Manager ARN** of a secret holding the registry credentials | Pull images from a **private repository** instead of a public one |

- Choose **Add container** to add more (the demo showed **Container 2**).
- **Essential:** if an essential container fails or is killed, **the whole task stops**. A non-essential container can stop while the **task keeps running**. (An omitted setting means essential.)

**Container settings:**

| Section | What you can set |
|---|---|
| **Port mappings** | **Container port**, **protocol**, **port name**, and **app protocol** (**HTTP, HTTP2, gRPC**, or none), as many mappings as the app needs. The app protocol applies to **Service Connect**. |
| **Resource allocation limits** | Container-level **vCPU** and **memory**, with **hard and soft limits** (useful when several containers share a task) |
| **Environment variables** | **Key + value** (for example `FOO=BAR`), or **value from** the **ARN** of a **Secrets Manager** secret (for example `SECRET_DB_PASSWORD`) or an **SSM Parameter Store** parameter. Or **add from a file** hosted in **S3**. |
| **Logging** | **Log collection**: natively to **CloudWatch** (set the **log group**, **region**, **stream prefix**, and **create group** option), or through **AWS FireLens** to **Splunk, Firehose, Kinesis, OpenSearch, S3**. Extra log configuration values can be added. |
| **HealthCheck** | A container-level health command to confirm the container is still healthy |
| **Timeouts** | **Start timeout** and **stop timeout** (see below) |
| **Docker configuration, labels, resource limits** | Available, less important |

- **Stop timeout:** how long ECS waits for the container to exit **before it is force-killed** (default **30 s**, maximum **120 s**).
- **Start timeout:** how long to wait for a container to reach its **dependency condition** before giving up on **containers that depend on it**. (The lecture describes it as killing a container that doesn't start fast enough.)

### 3. Storage

- Add **volumes**: **bind mount** (give it a **volume name**) or **EFS**, as many as needed.
- In each container, add a **mount point**: the **path** to mount the volume on, and the **volume (or another container's volume) it comes from**.
- So data can be mounted from **EFS or a file system onto containers**, and **shared between containers**.

### 4. Monitoring

| Option | What it does |
|---|---|
| **Trace collection** | Sends traces to **AWS X-Ray** through a **sidecar**, the **AWS Distro for OpenTelemetry (ADOT)**. CPU and memory are **adjusted automatically** to fit the sidecar. |
| **Metric collection** | Sends metrics to **CloudWatch** or **Amazon Managed Service for Prometheus**, using different libraries |

### 5. Creating and Reviewing

1. Choose **Create**.
2. Review the settings in the **JSON** view of the task definition.
3. To change anything, **create a new revision** and edit the settings one by one (task definitions are **versioned by revision**, not edited in place).

---

## Amazon ECS - Task Placements

### TL;DR

- **Task placement** decides **which EC2 instance a new task goes on**, and **which task to stop** when a service scales in. It applies to the **EC2 launch type**. **Fargate** has no placement strategies or constraints (AWS places the tasks).
- **Strategies** (best effort): **binpack** (fill instances, **cost saving**), **random**, and **spread** (spread by AZ or instance ID, **high availability**). You can **mix** them.
- **Constraints** (binding): **distinctInstance** (one task per instance) and **memberOf** (only instances matching a **cluster query language** expression).
- Process: find instances with enough **CPU, memory, and ports**, apply **constraints**, then pick by **strategy**.
- Exam focus: the difference between **binpack, spread, and random**.

### 1. The Placement Process

```
New task (EC2 launch type)
  1. Instances with enough CPU, memory, and ports for the task definition
  2. ... that satisfy the placement CONSTRAINTS
  3. ... best matching the placement STRATEGY
  4. Place the task there
```

| | **Strategy** | **Constraint** |
|---|---|---|
| **Nature** | **Best effort**: ECS still places the task if the ideal spot isn't available | **Binding**: if no instance matches, the task stays **`PENDING`** |
| **Used for** | Placing tasks **and choosing which to terminate** on scale-in | Restricting where tasks may run |

- You set them in the **service definition** (or when running a task, via `placementStrategy` / `placementConstraints`).
- The **default** for a **service** is **spread by Availability Zone**.

### 2. Placement Strategies

| Strategy | Behavior | Goal |
|---|---|---|
| **binpack** | Place tasks so the **least CPU or memory is left unused**. Fills one instance **before** using the next. Field: **`cpu`** or **`memory`**. | **Minimize the number of instances** = **lowest cost** |
| **random** | Place tasks **randomly** | Simple, no logic |
| **spread** | Spread tasks **evenly by a field**: `attribute:ecs.availability-zone`, `instanceId`, or another attribute | **High availability** (tasks across AZs or instances) |

```
binpack on memory:   [ task task task task ] [ task ] [        ]    fills instance 1, then 2, ...
spread on AZ:        AZ-A [task]   AZ-B [task]   AZ-C [task]   then repeats
```

- **Scale-in behavior:** with **binpack**, ECS ends the task on the instance that would have the **most resources left** afterward. With **spread**, it keeps a **balance across AZs** (random within an AZ).
- **Mix strategies in order**: for example **spread on AZ**, then **binpack on memory** within each AZ (the first strategy takes priority). Another example: spread on AZ, then spread on instance ID. The exam tests only the basics.

### 3. Placement Constraints

| Constraint | Behavior |
|---|---|
| **distinctInstance** | Each task goes on a **different container instance**. You never get two tasks of the service on one instance. |
| **memberOf** | Place tasks only on instances that satisfy an **expression** in the **cluster query language**. |

- Example `memberOf` expression: `attribute:ecs.instance-type =~ t2.*` (**only t2 instances**).
- Built-in attributes include **instance type**, **Availability Zone**, **AMI ID**, **OS type**, and **CPU architecture**. You can add **custom attributes** too (for example `stack = prod`).

### 4. Where It Applies

| Capacity | Strategies | Constraints |
|---|---|---|
| **EC2 launch type** | Yes | Yes |
| **ECS Managed Instances** | **No** (ECS spreads across AZs on a best-effort basis) | Yes |
| **Fargate** | **No** (AWS finds the spot and spreads across AZs) | **No** |

### 5. Exam-Style Recall

| If the question says... | Think... |
|---|---|
| "Place ECS tasks on specific instances or control which task is terminated" | **Task placement strategies and constraints** (EC2 launch type) |
| "Minimize cost / number of EC2 instances in the cluster" | **binpack** (on CPU or memory) |
| "Maximize availability across AZs" | **spread** on `attribute:ecs.availability-zone` |
| "No placement logic needed" | **random** |
| "Never put two tasks of a service on the same instance" | **distinctInstance** constraint |
| "Run tasks only on t2 instances" | **memberOf** with a cluster query expression |
| "Placement strategies with Fargate" | **Not supported**. AWS manages placement. |
| "Strategy vs constraint" | Strategies are **best effort**. Constraints are **binding**. |
| "Default placement strategy for a service" | **Spread across Availability Zones** |

---

## Amazon ECR

### TL;DR

- **Amazon ECR (Elastic Container Registry)** stores and manages **Docker images** on AWS. Whenever the exam says **storing Docker images**, think **ECR**.
- Two kinds: a **private** repository (your account or accounts) and a **public** repository on the [Amazon ECR Public Gallery](https://gallery.ecr.aws).
- **Fully integrated with ECS.** Images are stored behind the scenes in **Amazon S3**.
- **All access is protected by IAM.** ECS needs the right IAM role to pull images, and permission errors mean you should check the policies.
- ECR also provides **image vulnerability scanning**, **versioning and image tags**, and **image lifecycle** management.

### 1. Private vs Public Repositories

| | **Private repository** | **Public repository** |
|---|---|---|
| **Visible to** | Your **account(s)** only (access via IAM and repository policies) | Anyone: published on the [Amazon ECR Public Gallery](https://gallery.ecr.aws) |
| **Use for** | Your own application images | Sharing images publicly |
| **Alternative** | | **Docker Hub** (also public) |

- Image references use the **full name**: `<account-id>.dkr.ecr.<region>.amazonaws.com/<repository>:<tag>`.

### 2. How ECS Pulls Images from ECR

```
ECR repository (images stored in S3 behind the scenes)
        ^  pull (IAM-authorized)
        |
ECS cluster: EC2 instance / Fargate task  --> starts the container after the pull
```

| Launch type | The pull is authorized by | AWS managed policy |
|---|---|---|
| **EC2** | The **EC2 instance (container instance) role** | `AmazonEC2ContainerServiceforEC2Role` |
| **Fargate** | The **task execution role** | `AmazonECSTaskExecutionRolePolicy` |

- Minimum permissions to pull: **`ecr:GetAuthorizationToken`**, **`ecr:BatchGetImage`**, **`ecr:GetDownloadUrlForLayer`**.
- The lecture shows only the EC2 case (an IAM role on the instance). On **Fargate** it is the **task execution role**.

### 3. ECR Features

| Feature | Detail |
|---|---|
| **Image scanning** | **Basic**: OS vulnerabilities, **on push** or manual. **Enhanced**: **Amazon Inspector**, OS and language packages, **continuous**. |
| **Versioning and tags** | Multiple image versions per repository, identified by **tags** |
| **Lifecycle policies** | Rules that **clean up unused images** automatically |
| **Replication** | **Cross-Region and cross-account** replication |
| **Formats** | **Docker** and **OCI** images and artifacts |

### 4. Exam-Style Recall

| If the question says... | Think... |
|---|---|
| "Store and manage Docker images on AWS" | **Amazon ECR** |
| "Private Docker registry integrated with ECS" | **Amazon ECR** (private repository) |
| "Publish container images publicly on AWS" | **ECR Public Gallery** |
| "Scan container images for vulnerabilities" | **ECR image scanning** (basic or Inspector-based enhanced) |
| "EC2 instance can't pull images from ECR" | The **instance role** lacks the **ECR permissions** (IAM) |
| "Fargate task can't pull from private ECR" | The **task execution role** lacks the ECR permissions |
| "Automatically delete old images" | **ECR lifecycle policy** |

---

## Amazon ECR - Hands On

Goal: host the `nginxdemos/hello` image (until now pulled by ECS from **Docker Hub**) in a **private ECR repository**, using the CLI.

### 1. Creating the Private Repository

ECR console, **Create repository** (**Private**), name `demostephane`. Options (all left **disabled**):

| Option | Meaning |
|---|---|
| **Tag immutability** | Prevents pushing the **same tag twice** (the push fails with `ImageTagAlreadyExistsException`) |
| **Scan on push** | Scans each pushed image for vulnerabilities. The lecture says this repository-level setting is being phased out in favor of **registry-level scan settings** (**Amazon Inspector** enhanced scanning, or basic scanning with filters). The docs call registry-level the best practice. |
| **Encryption (KMS)** | Encrypt the repository with **KMS**. **Can't be changed** after creation. |

- **Private repositories** are pullable only with the right **IAM permissions**. **Public repositories** let **anyone** pull.
- The new repository shows **0 images**. The **View push commands** button gives the commands for **macOS/Linux** or **Windows**.

### 2. Prerequisites

- **Docker** installed and **running** (`docker version` works).
- **AWS CLI** installed and configured. The IAM principal needs **`ecr:GetAuthorizationToken`**, plus push or pull permissions on the repository. Without them, push and pull fail with an **IAM permission error**.

### 3. Authenticate, Pull, Tag, and Push

```
# 1. Log in: the AWS CLI prints an ECR password, docker login uses it with the username AWS
aws ecr get-login-password --region <region> \
  | docker login --username AWS --password-stdin <account-id>.dkr.ecr.<region>.amazonaws.com
# -> Login Succeeded

# 2. Get an image (nothing of our own to build, so pull a public one)
docker pull nginxdemos/hello

# 3. Tag it with the ECR repository URI (this is how docker knows where to push)
docker tag nginxdemos/hello:latest <account-id>.dkr.ecr.<region>.amazonaws.com/demostephane:latest

# 4. Push
docker push <account-id>.dkr.ecr.<region>.amazonaws.com/demostephane:latest
```

| Step | Detail |
|---|---|
| **`get-login-password`** | Returns a **temporary password** (token). Piped into `docker login` with the username **`AWS`**. Repeat per registry. |
| **`docker tag`** | **Renames** the local image so its name includes the **ECR registry, repository, and tag** |
| **`docker push`** | Docker sees the ECR address in the name and pushes **to ECR**. It works because the login was valid, otherwise you get an **IAM permission error**. |
| **Pull from ECR** | `docker pull <account-id>.dkr.ecr.<region>.amazonaws.com/demostephane:latest` (same login and same permissions) |

### 4. Result

- Refresh the repository: it now shows the **`latest`** image, and you can open it for details.
- A **task definition** can now use this ECR image URI instead of the Docker Hub image, so ECS would **pull from ECR**.

---

## Amazon EKS

### TL;DR

- **Amazon EKS (Elastic Kubernetes Service)** launches and manages **Kubernetes** clusters on AWS. **Kubernetes** is an **open-source**, **cloud-agnostic** system for automated deployment, scaling, and management of containerized apps.
- EKS is the **alternative to ECS**: same goal (run containers), **different API**. ECS is **AWS-specific**, Kubernetes is **open source** and runs on any cloud (Azure, Google Cloud, on premises).
- **Use EKS when** the company already runs Kubernetes (on premises or another cloud), wants the **Kubernetes API**, or wants **easier migration between clouds**.
- In EKS the unit of work is a **Pod** (like an ECS task). Pods run on **nodes**. The keyword **pods** means Kubernetes/EKS.
- Node types: **managed node groups**, **self-managed nodes**, and **Fargate** (no nodes at all). Newer: **EKS Auto Mode**.
- Storage uses a **StorageClass** and a **CSI driver**: **EBS, EFS, FSx for Lustre, FSx for NetApp ONTAP**. **EFS** is the one that works with **Fargate**.

### 1. ECS vs EKS

| | **Amazon ECS** | **Amazon EKS** |
|---|---|---|
| **Based on** | **AWS's own** container orchestration | **Kubernetes** (open source) |
| **Portability** | AWS only | **Cloud agnostic**: the same Kubernetes API on any cloud |
| **Unit of work** | **Task** | **Pod** |
| **Compute** | EC2 or Fargate | EC2 (managed or self-managed nodes) or Fargate |
| **Choose when** | You want the simplest AWS-native option | You already use **Kubernetes**, want its API, or may **migrate between clouds** |

- EKS runs **certified Kubernetes-conformant** clusters, so Kubernetes apps and tooling work without refactoring. AWS manages the **control plane**.

### 2. Architecture

```
VPC (3 AZs, public and private subnets)
  EKS worker nodes (EC2 instances, in an Auto Scaling group)
     each node runs EKS Pods  (like ECS tasks)
  Expose a Kubernetes service through a private or a public load balancer
```

### 3. Node Types

| Option | Who manages the nodes | Details |
|---|---|---|
| **Managed node groups** | **AWS** creates and manages the nodes (EC2 instances) | Nodes belong to an **Auto Scaling group** managed by EKS. **On-Demand and Spot** supported. |
| **Self-managed nodes** | **You** | **Most customization and control**. You create the nodes and **register** them to the cluster, in your own ASG. Use the prebuilt **EKS-optimized AMI** or build your own (harder). **On-Demand and Spot**. |
| **AWS Fargate** | **No nodes to manage** | **Serverless**: no maintenance, you just run Pods |
| **EKS Auto Mode** (newer) | **AWS manages the nodes and more** | Automatically provisions and scales instances, patches the OS, and optimizes cost |

- **Hybrid Nodes** let you attach on-premises machines as nodes.

### 4. Data Volumes

- Create a **StorageClass** manifest on the cluster. It uses a **Container Storage Interface (CSI)** compliant driver (a keyword to know).

| Storage | Notes |
|---|---|
| **Amazon EBS** | Block storage for a Pod |
| **Amazon EFS** | Shared file system. The lecture says it is the **only** storage class that works with **Fargate**. |
| **Amazon FSx for Lustre** | High-performance file system |
| **Amazon FSx for NetApp ONTAP** | Managed NetApp file system |

- AWS also provides CSI drivers for S3 (Mountpoint), S3 Files, FSx for OpenZFS, and File Cache.

### 5. Exam-Style Recall

| If the question says... | Think... |
|---|---|
| "Managed Kubernetes on AWS" | **Amazon EKS** |
| "Company already uses Kubernetes on premises or in another cloud" | **Amazon EKS** |
| "Containers portable across cloud providers" | **Kubernetes / EKS** (cloud agnostic) |
| "Pods" | **Kubernetes / EKS** (the equivalent of ECS tasks) |
| "EKS with no servers to manage" | **EKS on Fargate** |
| "AWS-managed worker nodes in an ASG, Spot or On-Demand" | **EKS managed node groups** |
| "Full control over worker nodes and the AMI" | **Self-managed nodes** |
| "Persistent storage for EKS Pods" | A **StorageClass** with a **CSI driver** (EBS, EFS, FSx) |
| "Shared storage for EKS Pods on Fargate" | **Amazon EFS** |
