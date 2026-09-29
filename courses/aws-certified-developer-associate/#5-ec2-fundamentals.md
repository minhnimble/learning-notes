# EC2 Fundamentals

## AWS Budget Setup

### 1. Importance of Monitoring Expenses
- Setting a budget prevents overspending and helps in managing unforeseen costs.

### 2. Accessing the Billing Console
- Navigate to the AWS Billing and Cost Management console to manage budgets effectively.
- Ensure IAM users have access to billing information, switching to the root account if needed.

### 3. Viewing Costs
- Check month-to-date costs, forecasted costs, and last month's expenses.
- Example: Break down costs using services like Elastic Compute Cloud (EC2).

### 4. Monitoring the AWS Free Tier
- Keep an eye on usage within the AWS Free Tier to avoid unexpected charges.

### 5. Setting Up Budgets
- Create budgets (e.g., zero spend budget) with email alerts at specific thresholds:
  - Email notification when actual spending reaches set percentages (e.g., 85%, 100%).

### 6. Using AWS Tools for Cost Management
- Utilize the provided budget tools to identify and manage issues related to spending.
- Emphasizes the necessity of mastering these skills when using AWS.

### 7. Conclusion
- The lecture stresses the importance of monitoring both budgets and resources to maintain control over AWS spending.

## Amazon EC2 Basics

### Key Concepts

1. **What is EC2?**
   - Amazon EC2 (Elastic Compute Cloud) is an essential AWS service providing resizable compute capacity in the cloud, allowing users to run virtual machines (instances).

2. **Components of EC2:**
   - **Instances:** Virtual machines that you can launch in the cloud.
   - **EBS Volumes:** Elastic Block Store offers persistent storage that can be linked to instances.
   - **Elastic Load Balancer (ELB):** Distributes incoming traffic across multiple instances.
   - **Auto Scaling Groups (ASG):** Automatically adjusts the number of instances according to demand.

3. **Instance Configuration:**
   - Users can select various operating systems (Linux, Windows, macOS) and instance types based on CPU, RAM, and storage requirements. Instance types range from general-purpose to compute-optimized and memory-optimized.

4. **Networking:**
   - Supports public IP addresses and security settings via Security Groups, acting as firewalls to control inbound and outbound traffic.

5. **User Data Script:**
   - Allows for automatic execution of user-defined commands at the first launch. For example, a script to install a web server and create an HTML file can be specified upon setup:
   ```bash
   # Sample user data
   #!/bin/bash
   yum update -y
   yum install httpd -y
   echo "<h1>Hello, World!</h1>" > /var/www/html/index.html
   service httpd start
   ```

6. **Monitoring and Debugging:**
   - Lambda functions can log events and monitor requests. This is crucial for understanding how the Application Load Balancer (ALB) passes data to Lambda functions and troubleshooting any issues.

7. **Free Tier Offerings:**
   - New users can access **750 hours** of a t2.micro instance and **30GB** of EBS storage free for the first year.

### Practical Application
- Hands-on experience with launching an EC2 instance and utilizing user data scripts is emphasized. Learners are encouraged to use provided scripts for easy automation.

## EC2 Instance Launch Hands On

### 1. Introduction to EC2 Instances
- Introduces launching an EC2 instance running Amazon Linux.
- Discusses the critical parameters for instance setup, emphasizing the importance of configurations.

### 2. Step-by-Step Launch Process
- Access the EC2 console, select “Instances,” and click “Launch Instances.”
- Name the instance (e.g., "My First Instance") and add necessary tags. 
- Choose the Amazon Linux 2 AMI as the operating system.

### 3. User Data Feature
- User data can be passed during the first launch to automate tasks. For instance, a script can be used to update packages, install the HTTPD web server, and create an HTML file.
- This script installs the HTTPD web server and creates a simple HTML page displaying "Hello World."

   ```bash
   # Sample User Data Script
   #!/bin/bash
   yum update -y
   yum install httpd -y
   echo "<h1>Hello World</h1>" > /var/www/html/index.html
   service httpd start
   ```

### 4. Post-Launch Management
- Learn how to start, stop, and terminate the EC2 instance effectively.
- Understand the significance of monitoring alarms; for example, an EC2 instance may be terminated if an alarm is triggered.

### 5. Cloud Computing Flexibility
- Highlights the ease of creating and managing instances in the cloud, which eliminates the need for physical hardware.

### 6. IP Address Management
- Understanding public and private IP addresses is crucial; note that the public IP may change when the instance is stopped and started.

### 7. Free Tier Offerings
- New users receive **750 hours** of t2.micro instance usage and **30GB** of EBS storage for free during the first year.
- If a t2.micro is unavailable in your region, a t3.micro will be used instead.

## EC2 Instance Types Basics

### 1. Types of EC2 Instances and Their Use Cases
- **General Purpose**: Balanced resources for various workloads. 
  - **Use Cases**: Web servers, small databases, and development environments. Example: T2 Micro for low-traffic web applications.

- **Compute Optimized**: Designed for compute-intensive tasks.
  - **Use Cases**: Media transcoding, high-performance web servers, batch processing, and dedicated gaming servers. Example: C5 instances are suitable for complex computations in scientific simulations.

- **Memory Optimized**: High memory throughput for big data applications.
  - **Use Cases**: In-memory databases (like Amazon ElastiCache), real-time big data analytics, and high-performance databases. Example: R5 instances support large-scale database workloads with ample RAM for complex queries.

- **Storage Optimized**: High disk throughput for I/O-intensive applications.
  - **Use Cases**: NoSQL databases, data warehousing, and Elasticsearch workloads. Example: I3 instances provide high-speed storage capabilities for data-intensive applications.

- **Accelerated Computing**: Instances that leverage hardware accelerators for specific applications.
  - **Use Cases**: Machine learning inference, graphics rendering, and data analysis. Example: P3 instances are excellent for deep learning tasks due to GPU acceleration.

- **HPC Optimized**: Tailored for High-Performance Computing applications.
  - **Use Cases**: Scientific simulation, financial modeling, and any workload requiring rapid computation across multiple nodes. Example: HPC instances suitable for parallel processing tasks that require low-latency networking.


### 2. Naming Convention
- The instance name follows a specific convention: `m5.2xlarge`. 
  - **m**: Indicates the instance class, which is general-purpose in this case.
  - **5**: Represents the generation of the instance, implying improvements in hardware over time. For instance, m5 is the latest iteration with better performance than m4.
  - **2xlarge**: Denotes the size within the instance class. The "2xlarge" size means it has more resources compared to sizes like "small" or "large," offering 8 vCPUs and 32 GB of memory.

### 3. Comparison and Cost Considerations
- Understanding on-demand vs. reserved pricing is crucial, along with examples like m4.large in US-East-1. Spot and reserved instances can provide cost savings.

### 4. Resources for Further Exploration
- Comprehensive details about EC2 instance types can be found on:
  - [AWS EC2 Instance Types](https://aws.amazon.com/ec2/instance-types/)
  - [ec2instances.info](https://ec2instances.info) for a comparison of costs and specifications.

## Security Groups and Classic Ports

## Summary of Security Groups and Classic Ports Lecture

### 1. Functionality of Security Groups
- Security groups serve as virtual firewalls for EC2 instances, controlling both inbound and outbound traffic.

### 2. Structure of Security Group Rules
- Each security group rule consists of:
  - **Traffic Type**: TCP/UDP
  - **Port Number**: Designated for application access
  - **Source IP Address**: Defines where the traffic can come from
- Default behavior blocks all inbound traffic and allows all outbound traffic.

### 3. Multiple Instances and Regions
- Security groups can be linked to multiple EC2 instances, and an instance can belong to several security groups.
- They are region/VPC specific, necessitating recreation when switching regions or creating new VPCs.

### 4. Common Ports
- **Port 22**: SSH (Linux instances)
- **Port 21**: FTP
- **Port 80**: HTTP
- **Port 443**: HTTPS
- **Port 3389**: RDP (Windows instances)

### 5. Advanced Features
- **Referencing Security Groups**: You can create a security group to allow traffic between instances without specifying IP addresses. For instance, if you have a web server and a database server, you can create a security group that allows inbound traffic on port 3306 (MySQL) from the web server's security group, ensuring only web servers can communicate with your database.
  
- **Multiple Security Groups**: You can attach multiple security groups to a single EC2 instance. For example, an EC2 instance could have one security group that allows HTTP traffic and another that allows SSH traffic. This modular approach simplifies management, as you can configure different rules for different situations.
  
- **Temporary Security Credentials (Roles)**: Though roles are not directly security groups, they provide temporary access to AWS resources. You can attach a role that allows an EC2 instance to pull images from an S3 bucket, which enhances security by not embedding long-term access keys in your application.


### 6. Good to Know
- Security groups must be configured correctly to allow access to other services, such as RDS databases or Elastic Cache clusters.
- Ensure you verify AWS Regional Services availability for specific services you plan to use, as not all services are available in every region. This can help avoid confusion and ensure you have the correct permissions set up.

## Security Groups Hands On

### 1. Overview of Security Groups
- Security groups function as virtual firewalls for EC2 instances, managing inbound and outbound traffic.

### 2. Identification of Security Groups
- Each security group is assigned a unique ID and can be accessed from the AWS Management Console.

### 3. Inbound Rules
- The importance of configuring inbound rules is highlighted, such as allowing SSH access on port 22 and HTTP traffic on port 80. For example:
  - If you want to allow your web application hosted on an EC2 instance to communicate with users, you must ensure that port 80 (HTTP) is open in the inbound rules. If this rule is missing, users will experience connection timeouts when trying to access the application.

### 4. Timeout and Troubleshooting
- Timeouts often occur due to improper security group settings. For example:
  - If a user tries to SSH into an instance but port 22 is not open, the connection attempt will time out, indicating a potential security group misconfiguration.

### 5. Adding Inbound Rules
- The lecture demonstrates how to add inbound rules to a security group:
  - If a database is running on port 3306 (MySQL), you can add an inbound rule allowing traffic on that port from a specific IP range to ensure secure access for your application.

### 6. Outbound Rules
- The default setting for outbound traffic allows all connections, meaning instances can connect freely to the internet. However:
  - If you want to restrict outbound access, you could modify rules to only allow certain ports, such as:
    - Allowing outbound HTTPS traffic on port 443 while blocking all other outbound connections, useful in environments where data exfiltration is a concern.

### 7. Multiple Security Groups
- An EC2 instance can have multiple security groups applied. For instance:
  - You might assign one security group that allows traffic on port 80 for web servers and another for port 443 for secure HTTPS traffic, giving you granular control over traffic flows.

## Connecting to Linux Servers via SSH

### 1. Overview of SSH
- The lecture highlights how to connect to Linux servers in the Cloud using SSH (Secure Shell).

### 2. SSH Methods by Operating System
- **Mac and Linux**: Users can access SSH directly through the command line.
- **Windows**: 
  - For Windows 10 and later, native SSH support is available.
  - For earlier versions, tools like PuTTY can be used for the SSH connection.

### 3. EC2 Instance Connect
- EC2 Instance Connect is introduced as a simpler alternative for SSH, working across all operating systems without the need for command line knowledge.
- This method allows for browser-based SSH sessions, automatically managing temporary SSH keys.
- When accessing the EC2 instance via this method, it automatically uses "ec2-user" as the default username for Amazon Linux 2 instances.

### 4. Common Issues with SSH
- Typical challenges include misconfigurations of security group rules or command errors.
- A troubleshooting guide is provided for assistance, and re-watching the SSH lecture may help if issues arise.

### 5. Conclusion
- Different methods exist for connecting to servers via SSH, and users should choose based on their comfort level.
- It's important to remember that SSH is a fundamental tool when working with AWS.


## Using SSH to Connect to an EC2 Instance in Linux/Mac (ignored Window courses )

### 1. Importance of SSH
- SSH (Secure Shell) is essential for managing remote servers in Amazon Cloud services.

### 2. Prerequisites
- Ensure your EC2 instance has a public IP address.
- The security group must allow traffic through Port 22 (default for SSH).

### 3. Preparing the PEM File
- Remove any spaces from the PEM file name (e.g., `EC2Tutorial.pem`) and place it in a desired directory.

### 4. Retrieving the Public IPv4 Address
- Access the EC2 instance overview page to obtain the public IPv4 address for connection.

### 5. Initiating the SSH Connection
- Use the command format:

  ```
  ssh ec2-user@<public-ip>
  ```

where `ec2-user` is the default user for Amazon Linux 2 AMI instances.
- If there is an authentication failure, make sure you're using the correct PEM file.

### 6. Navigating to the Directory
- Use commands like `ls` and `cd` to change to the directory containing your PEM file.
- Connect using:

  ```
  ssh -i EC2_Tutorial.pem ec2-user@<public-ip>
  ```

### 7. Handling Permission Errors
- If facing permission errors, adjust file permissions with:


  ```
  chmod 0400 EC2Tutorial.pem
  ```

### 8. Testing the Connection
- Verify the connection by executing commands like `whoami` and `ping google.com`.

### 9. Exiting the SSH Session
- End the session properly, keeping in mind the public IP may change upon stopping and restarting the instance.

## SSH Troubleshooting

### Connection Timeout
- Usually caused by a **security group or firewall issue**.
- Check that your EC2 security group allows SSH and is attached to the instance.

### Timeout Still Happens
- If the security group is correct, a **corporate or personal firewall** may be blocking SSH.
- Use **EC2 Instance Connect**.

### SSH Not Working on Windows
- If you see `ssh command not found`, use **PuTTY**.
- If PuTTY does not work, use **EC2 Instance Connect**.

### Connection Refused
- The instance is reachable, but SSH is not running.
- Restart the instance.
- If it still fails, recreate the instance using **Amazon Linux 2**.

### Permission Denied
- Usually caused by:
  - Wrong SSH key
  - Wrong username
- Check the assigned key pair.
- For Amazon Linux 2, use:

```bash
ssh ec2-user@<public-ip>
```

### Nothing Works
- Use **EC2 Instance Connect**.
- Make sure the instance uses **Amazon Linux 2**.

### Worked Yesterday, Not Today
- Stopping and starting an EC2 instance can change its public IP.
- Update your SSH command or PuTTY config with the new public IP.

## Using EC2 Instance Connect to Connect to EC2 Instances

### Browser-Based SSH Connection
   - Connect to EC2 instances directly through web browsers for ease of access.

### Instance Selection and Connection
   - Select an instance and click on 'connect' to access EC2 Instance Connect features.

### Default Username
   - The default username is typically 'EC2 user', which can be customized if necessary.

### No SSH Key Management
   - Eliminates the need to manage SSH keys by using a temporary key uploaded at connection time.

### Executing Commands
   - Users can run commands like `whoami` and `ping google.com` once connected.

### Security Group Configuration
   - Important to configure security groups to allow inbound SSH traffic on port 22 for connectivity.

### Efficiency and Convenience
   - EC2 Instance Connect streamlines access and reduces the burden of SSH key management.

## IAM Roles for EC2 Instances Demo

### Connecting to EC2 Instances
   - Demonstrates how to connect to an EC2 Instance using EC2 Instance Connect via a web browser.

### Introduction to Basic Commands
   - Basic Linux commands are introduced once connected, showcasing terminal functionality in the cloud (e.g., `whoami`, `ping google.com`).

### Security Risks of Personal Credentials
   - AWS credentials should never be entered directly into the EC2 Instance due to security risks. Instead, using IAM roles helps mitigate this.

### Utilizing IAM Roles
   - IAM roles are recommended for securing access without exposing sensitive information. For example, an IAM role can be created for EC2 that allows read-only access to IAM resources.

### Attaching IAM Roles
   - A step-by-step guide on how to attach an IAM role (e.g., a demo role with read-only access to IAM) to the EC2 Instance is provided.
   - Example: The role “demoRoleForEC2” is created with IAM read-only access, allowing the EC2 instance to interact securely with the IAM service.

### Executing AWS Commands without Personal Credentials
   - Once the IAM role is attached, users can run AWS commands without needing personal credentials, demonstrating the advantage of IAM roles. For instance, the EC2 instance can list IAM users through the AWS CLI without hard-coded credentials.

### Best Practices Reminder
   - Emphasizes that IAM roles should be the only method for providing credentials to EC2 Instances to ensure security and compliance with best practices (e.g., enabling multi-factor authentication and using temporary credentials).

## Purchasing Options for EC2 Instances

### On-Demand Instances
- **Description:** Ideal for short-term workloads; billed by the second for Linux and Windows.
- **Cost:** No upfront payments, but the highest pricing option.
  
### Reserved Instances
- **Description:** Best for long-term workloads; significant discounts (up to 72%) available.
- **Types:** 
  - Standard: One or three-year commitment.
  - Convertible: Flexibility to change instance types.
  
### Savings Plans
- **Description:** Offers discounts for a commitment to a specific dollar amount of usage.
- **Flexibility:** Can apply across various instance types and sizes within a family or region.

### Spot Instances
- **Description:** Cost-effective; can save up to 90% compared to on-demand pricing.
- **Considerations:** Interruptible and can be terminated if the spot price exceeds the maximum set by the user.

### Dedicated Hosts and Instances
- **Dedicated Hosts:** Provide exclusive use of an entire physical server; necessary for compliance needs.
- **Dedicated Instances:** Run on hardware reserved for the user, but may share the physical server.

### Capacity Reservations
- **Description:** Allows users to reserve on-demand instances in a specific availability zone.
- **Cost:** Billed at on-demand rates, regardless of usage.

### Pricing Comparison Example
- **Instance Example:** An m4.large instance might cost:
  - On-Demand: $0.10/hour
  - Spot: Up to 61% off from on-demand pricing.
  - Reserved Instances and Savings Plans provide similar discounts for longer commitments.
