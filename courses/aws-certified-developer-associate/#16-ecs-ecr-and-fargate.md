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

- **Amazon ECR** supports Docker images and **OCI** images, **image scanning**, **lifecycle policies**, and **cross-Region and cross-account replication**.

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
