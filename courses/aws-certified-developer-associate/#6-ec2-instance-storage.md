# EC2 Instance Storage

## Elastic Block Store (EBS) Overview

### 1. Overview of EBS Volumes
- **Elastic Block Store (EBS)**: A network-based storage solution for EC2 instances that provides persistency, allowing users to retain data even after instance termination. EBS functions as a virtual hard drive for EC2.

### 2. Attachment Limitations
- An EBS volume can attach to only one EC2 instance at a time and is bound to a specific **Availability Zone (AZ)** (e.g., a volume in us-east-1a cannot attach to an instance in us-east-1b).

### 3. Functionality
- EBS volumes can be detached from one instance and attached to another quickly, similar to swapping USB drives, which assists in scenarios such as failovers.

### 4. Provisioning Capacity
- Users must provision capacity in advance by defining size (in GB) and **IOPS (Input/Output Operations Per Second)**, which determines the volume's performance characteristics. Billing is based on the provisioned capacity.

### 5. Snapshots
- Snapshots are point-in-time backups of EBS volumes that allow data recovery and movement between different Availability Zones.

### 6. Multiple Volumes
- Multiple EBS volumes can be attached to a single EC2 instance. This flexibility allows users to enhance storage capabilities as needed.

### 7. Delete on Termination Attribute
- The root volume usually deletes when the instance is terminated, while additional volumes typically remain. Users can configure this setting according to their needs.

### 8. Volume Types
- EBS volumes come in six different types:
  - **gp2/gp3**: General-purpose SSDs balancing price and performance, suitable for diverse workloads.
  - **io1/io2**: High-performance SSDs for mission-critical applications that require low latency and high throughput.
  - **st1**: Low-cost HDDs optimized for frequently accessed, throughput-intensive workloads.
  - **sc1**: Lowest-cost HDDs designed for less frequently accessed data.

## Elastic Block Store (EBS) Demo

### 1. Accessing EBS Volumes
- The lecture highlights how to access EBS volumes via the AWS console, noting the visibility of volumes depending on the account used.

### 2. Creating New EBS Volumes
- Steps to create a new EBS volume are discussed, including specification of size and type (e.g., GP2) within the same Availability Zone (AZ) as the EC2 instance.

### 3. Importance of Availability Zones
- EBS volumes must be associated with a specific AZ, affecting their usability with EC2 instances.

### 4. Attaching EBS Volumes
- Demonstrates how to attach an EBS volume to an EC2 instance, showcasing the process of updating storage configurations.

### 5. Delete on Termination Attribute
- Discusses the 'delete on termination' setting, which determines whether an EBS volume is automatically deleted when the associated EC2 instance is terminated.

## EBS Snapshots

### 1. Definition of EBS Snapshots
- EBS Snapshots serve as point-in-time backups of EBS volumes, which can be created without detaching the volume from an EC2 instance, although detaching is recommended for consistency.

### 2. Cross-AZ and Cross-Region Functionality
- Snapshots can be copied between different Availability Zones (AZs) and across Regions, facilitating disaster recovery and backup.

### 3. Key Features of EBS Snapshots
- **EBS Snapshot Archive**: Snapshots can be archived for cost savings (up to 75% cheaper) but may take 24 to 72 hours for restoration.
- **Recycle Bin for Deleted Snapshots**: Rather than permanent deletion, snapshots moved to a Recycle Bin can be recovered within a retention period of one day to one year.
- **Fast Snapshot Restore**: This feature enables quick initialization of snapshots, reducing latency for first access but comes at a higher cost.

## EBS Snapshots Demo

### 1. Creating a Snapshot
- Overview of creating a snapshot from a two-gigabyte GP2 EBS Volume.
- Guidance on adding descriptions and initiating the snapshot process.

### 2. Importance for Backup and Recovery
- Snapshots are crucial for data backup and disaster recovery.
- They can be copied to different AWS regions for enhanced safety.

### 3. Recreating a Volume from a Snapshot
- Instructions on how to recreate a volume from a snapshot, including options for encryption and selecting the target Availability Zone.

### 4. Managing EBS Volumes Across AZs
- Snapshots assist in managing EBS volumes effectively across multiple Availability Zones.

### 5. Recycle Bin for Deleted Snapshots
- Introduction of the Recycle Bin to prevent permanent deletion of EBS Snapshots.
- Deleted snapshots can be recovered within a retention period of one day to one year.

### 6. Storage Tiers for Snapshots
- Discussion on different storage tiers for snapshots with cost implications.
- Archived snapshots take longer to restore, estimated between 24 to 72 hours.

### 7. Fast Snapshot Restore
- Fast Snapshot Restore feature allows for quick initialization of snapshots to minimize latency on first use.
- Useful for large snapshots but incurs additional costs.

## Amazon Machine Images (AMIs)

### 1. Definition of AMIs
- An AMI is a customizable image that specifies the software configurations, operating system, and monitoring tools for EC2 instances.

### 2. Benefits of Custom AMIs
- Custom AMIs allow for faster boot and configuration times as all necessary software can be pre-packaged within the image.

### 3. Types of AMIs
- **Public AMIs**: Provided by AWS, like the Amazon Linux 2 AMI.
- **Custom AMIs**: Users can create and maintain their own AMIs for specific needs.
- **Marketplace AMIs**: Pre-configured AMIs available for purchase from AWS Marketplace.

### 4. Creating an AMI
- Involves launching and customizing an EC2 instance, stopping the instance for data integrity, and building the AMI, which simultaneously creates EBS snapshots.

### 5. Practical Example
- The lecture includes a step-by-step demonstration of launching an EC2 instance, customizing it, creating a custom AMI, and launching another instance from that AMI in a different region.

### 6. Importance of AMIs
- AMIs simplify the process of deploying consistent environments and can be copied across regions, leveraging the AWS global infrastructure. 
- An AMI is regional, meaning an AMI that exists in N. Virginia / us-east-1 can only be used directly to launch EC2 instances in us-east-1. If you want to launch an EC2 instance from that AMI in another AWS Region, you must first copy the AMI to the target Region, then launch the instance from the copied AMI there.

## AMI Hands On

### 1. Launching an EC2 Instance
- The session begins with the instructor launching an EC2 instance using **Amazon Linux 2** and **t2.micro** instance type.
- Key steps include selecting a key pair and configuring network settings with an existing security group.

### 2. User Data for Initialization
- User data is edited to install the **Apache web server (HTTPD)** automatically. 
  - **Example**: The user data script includes commands to install HTTPD without creating an index file upon startup.
- The instructor emphasizes the importance of patience as the user data script may take time to execute.

### 3. Verification of Installation
- After the script completion, the instructor verifies the successful installation of HTTPD by accessing a test page at the server's public IP address.

### 4. Creating an AMI
- The lecture demonstrates creating an AMI from the running instance. 
  - **Example**: The instructor gives the AMI a specific name and monitors its status until it is ready for use, showcasing the simplicity of AMI creation.

### 5. Launching Instances from AMI
- After the AMI is created, the instructor details how to launch new instances from this AMI. 
  - **Example**: This process excludes the need to reinstall HTTPD, speeding up deployment significantly.

### 6. Benefits of Using AMIs
- Discussion includes benefits such as faster boot-up times and the ability to package instances with pre-installed software which streamlines deployment processes.

### 7. Termination of Instances
- The session concludes with instructions on terminating the instances created during the demonstration, wrapping up the hands-on experience.

## EC2 Instance Store

### Definition
- The Instance Store is a high-performance storage solution directly attached to physical servers that host EC2 Instances.

### Ephemeral Nature
- Data stored in the Instance Store is temporary. If the EC2 instance is stopped or terminated, all data in the Instance Store is lost, making this storage unsuitable for long-term data retention.

### Ideal Use Cases
- The Instance Store is best for temporary data requirements, such as:
  - Caches
  - Buffers
  - Scratch data

### Alternatives for Long-Term Storage
- For data that requires persistence and reliability, options like **EBS (Elastic Block Store)** are recommended.

### Risks and Data Management
- Highlighted risks include potential data loss due to hardware failure. It’s essential to back up and replicate data when utilizing Instance Stores.

### Performance Comparison
- The lecture compares IOPS (Input/Output Operations Per Second) of high-performance EC2 Instance types with Instance Stores versus EBS volumes, illustrating the superior performance of the Instance Store for certain workloads.

## Amazon Elastic Block Store (EBS) Volumes

### General-Purpose SSDs
- **gp2 and gp3 Volumes**: 
  - Balances price and performance.
  - gp3 offers a baseline of 3,000 IOPS and 125 MB/s throughput, with a scalable maximum of 80,000 IOPS and 2,000 MB/s.
  - gp2 volumes link size and IOPS, allowing a maximum of 16,000 IOPS based on volume size.

### High-Performance SSDs
- **io1 and io2 Block Express Volumes**:
  - Designed for mission-critical applications needing low latency and high throughput.
  - io1 supports up to 64,000 IOPS for Nitro EC2 instances, while io2 Block Express can achieve up to 256,000 IOPS, with up to 1,000 IOPS per gigabyte.

### Low-Cost HDD Options
- **st1 and sc1 Volumes**:
  - **st1**: Optimized for throughput-intensive workloads with a maximum throughput of 500 MB/s and 500 IOPS, ideal for big data and log processing.
  - **sc1**: Suitable for infrequently accessed data, offering the lowest cost with a maximum throughput of 250 MB/s and 250 IOPS.

### Takeaway
- The EBS volume types for EC2 instances are:
  - General Purpose SSD: gp2, gp3
  - Provisioned IOPS SSD: io1, io2
  - Throughput Optimized HDD: st1
  - Cold HDD: sc1
  - Magnetic / Standard: previous-generation EBS volume type
General Purpose SSD and Provisioned IOPS SSD are expected to be used as boot volumes, in other words:
- p2 / gp3 — commonly used boot volumes
- io1 / io2 — can also be used as boot volumes when high IOPS is needed
- and Magnetic / Standard can be used.
- st1 and sc1 CANNOT be used as boot volumes.
- Mount EBS volumes in RAID 0 means: Combine multiple EBS volumes into one striped volume to increase IOPS and throughput.
- For an 8 TB gp2 EBS volume, the thing that is NOT a way to increase performance is to increase the volume size, because gp2 performance scales with size, but only up to a maximum of 16,000 IOPS. An 8 TB gp2 volume already reaches the maximum gp2 IOPS limit, so making it larger will not increase IOPS further.
- For 310,000 IOPS, the best recommendation is: Use multiple EBS volumes in a RAID 0 configuration, because a single EBS volume cannot provide 310,000 IOPS by itself in the common AWS exam context. For example: io1 / io2 Provisioned IOPS SSD volumes can provide high IOPS, but a single volume has an IOPS limit. To reach 310,000 IOPS, you need to stripe multiple EBS volumes together using RAID 0. RAID 0 combines the performance of multiple volumes, giving you higher aggregate IOPS. So the answer is: Create a RAID 0 array with multiple EBS volumes to increase IOPS.
  - Can use EC2 Instance Store because it provides extremely high IOPS and low latency (hardware on server), but its main downside is that the data is ephemeral and can be lost when the instance stops, terminates, or the hardware fails.

## Multi-Attach Feature of Amazon Elastic Block Store (EBS) Volumes

### Overview
- The Multi-Attach feature allows a single EBS volume to be attached to multiple EC2 instances within the same availability zone.
- This feature is available only for io1 and io2 EBS volume types.

### Key Points
1. **Concurrent Access**:
   - Each EC2 instance attached to the EBS volume has full read and write permissions, allowing multiple instances to read from and write to the volume simultaneously.

2. **Use Cases**:
   - Ideal for applications requiring higher availability, such as clustered applications (e.g., Teradata) that need to manage concurrent write operations.

3. **Limitations**:
   - The maximum number of EC2 instances that can attach to the same EBS volume is 16. This is critical information for exams.
   - Multi-Attach is limited to instances within the same availability zone, meaning you cannot attach an EBS volume across different availability zones.

4. **File System Requirements**:
   - To utilize the Multi-Attach feature, a cluster-aware file system must be used, which differs from standard file systems like XFS or EXT4.

## Amazon Elastic File System (EFS)

### Overview
- Amazon EFS is a managed network file system (NFS) that supports multiple EC2 instances connecting simultaneously across different availability zones.

### Key Features
- **High Availability and Scalability**: Offers a scalable file storage solution without the need for pre-provisioning.
- **Pay-per-Use Pricing**: Costs are incurred only for the storage used, with EFS being approximately three times the cost of GP2 EBS volumes.
- **Linux Compatibility**: Specifically designed for Linux-based AMIs.

### Architecture
- **Security Groups**: Essential for access control; must be configured correctly for EFS to function properly.
- **Automatic Scaling**: Automatically scales to support thousands of concurrent NFS clients and can extend to petabyte levels.

### Performance Modes
- **General-Purpose Mode**: Best for latency-sensitive applications.
- **Max I/O Mode**: Suitable for high-throughput applications that can tolerate higher latency.

### Throughput Modes
- **Bursting, Provisioned, and Elastic**: These modes optimize performance based on the workload needs.

### Storage Classes and Lifecycle Management
- **Automatic File Movement**: Enables migration of files between storage tiers (standard, EFS-IA, archive) for significant cost savings of up to 90%. 

### Availability and Durability
- **Multi-AZ Setup**: Recommended for production workloads, with a one-zone option available for development purposes.

## Hands-On Demonstration of Amazon Elastic File System (EFS)

### 1. Creating a File System
- Begin by selecting a **VPC** where the file system will be connected, typically using the default VPC.
- File system types:
  - **Regional**: High availability across multiple availability zones; ideal for production (e.g., shared applications).
  - **One-Zone**: Lower cost but limited to a single availability zone; suitable for development (e.g., staging environments).

### 2. Backup and Lifecycle Management
- Enable automatic backups to protect data.
- **Lifecycle Management**: Automatically moves files between storage tiers, suitable for applications with varying access frequencies.

### 3. Performance Settings
- Choose throughput modes:
  - **Bursts**: Scales with storage use.
  - **Provisioned**: Fixes throughput, suitable for steady workloads.
  - **Elastic**: Automatically adjusts based on demand.

### 4. Performance Modes
- **General Purpose Mode**: 
  - Default setting for latency-sensitive applications like web servers or content management systems.
  
- **Max I/O Mode**: 
  - For workloads that require higher throughput, such as big data analytics, where higher latency can be tolerated.

### 5. Network Access Settings
- Configure network settings and create security groups for access control.

### 6. Linking EC2 Instances
- Create multiple EC2 instances (e.g., "Instance A") and link them with EFS, allowing concurrent access.

### 7. Multi-AZ Access
- Multiple EC2 instances across different availability zones can access the same EFS file system, demonstrating high availability.

### 8. Resource Cleanup
- Instructions on terminating EC2 instances and deleting the EFS file system to manage AWS resources efficiently.

### **Important Use Cases for EFS**
- **Content Management**: Sharing files for websites or applications.
- **Web Serving**: Hosting files that can be accessed concurrently by multiple users.
- **Data Sharing**: Allowing multiple applications on different EC2 instances to access the same data.

## Comparison of Amazon EBS and EFS

### 1. Amazon EBS (Elastic Block Store) Volumes
- **Attachment**: 
  - Can be attached to a single EC2 instance at a time (multi-attach for specific volume types).
  - Restricted to a single Availability Zone (AZ).
- **Access**: 
  - Cannot be accessed by instances in different AZs.
- **Performance**: 
  - Performance varies by volume type (e.g., gp2 performance increases with size, gp3 and io1 allow independent IOPS scaling).
- **Migration**: 
  - Requires creating and restoring snapshots to migrate across AZs, potentially impacting performance during high traffic.
- **Termination**: 
  - Volumes typically terminate with the associated EC2 instance, but this can be changed.

### 2. Amazon EFS (Elastic File System)
- **Type**: 
  - A network file system shared across multiple EC2 instances in different AZs.
- **Use Cases**: 
  - Suitable for applications requiring shared access, e.g., web servers hosting websites like WordPress.
- **Scalability**: 
  - Offers high availability, supporting multiple mount targets.
- **Cost**: 
  - Higher pricing with options for cost-saving storage tiers.

### 3. Instance Store Volumes
- **Type**: 
  - Physically attached to EC2 instances.
- **Limitation**: 
  - Data is lost when the instance is terminated.

### Conclusion
- **EBS** is best for block-level storage needs with performance characteristics dependent on volume type, while **EFS** is ideal for scalable, shared file storage across multiple instances.

## EBS & EFS Section Cleanup - Main Points

### 1. Deleting the File System
- Demonstration of how to delete an entire file system by entering the file system ID into the action menu.

### 2. Terminating EC2 Instances
- Emphasis on the need to terminate all running EC2 instances to achieve a clean slate.

### 3. Managing Volumes
- Instructions to delete all available volumes by right-clicking and selecting the delete option.

### 4. Deleting Snapshots
- Advice to remove any created snapshots to avoid unnecessary storage costs.

### 5. Cleaning Up Security Groups
- Guidance on deleting unnecessary security groups, while retaining the default group.
- Note that security groups can only be deleted after all associated EC2 instances have been terminated.

### 6. Practical Examples
- Examples of attempting to delete security groups, noting some deletions require patience as instances shut down.
- **Example**: When trying to delete a security group that still has EC2 instances associated with it, the user will receive an error stating that the security group cannot be deleted until those instances are terminated.
