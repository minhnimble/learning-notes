# IAM & AWS CLI

## IAM Introduction: Users, Groups, Policies

### 1. Root Account
- **Usage**: The root account should be reserved for initial setup only. Regular AWS operations should be done with individual user accounts.

### 2. User Grouping
- **Organization**: Users can be grouped based on their roles within the organization (e.g., developers, operations).

### 3. Permissions Management
- **IAM Policies**: Permissions for users and groups are defined using IAM policies, which are JSON documents. These outline what users or groups can perform in AWS.

### 4. Security Best Practices
- **Least Privilege Principle**: Users should be granted only the permissions necessary for their specific tasks to enhance security and control costs.

### 5. Multi-Factor Authentication (MFA)
- **Security Enhancement**: Enabling MFA adds an additional layer of security for user accounts.

### 6. Access Keys and CLI
- **Access Management**: Users can create access keys to use the AWS Command Line Interface (CLI) or SDK for service management.

### 7. Audit and Report
- **IAM Credentials Report**: Users can audit IAM usage by generating credentials reports and utilizing the IAM Access Advisor service.

### 8. Next Steps
- **Practical Exercises**: The lecture concludes with preparation for the next session focused on creating IAM users and groups.

## IAM Users & Groups Hands On

### 1. IAM Console Access
- **Global Service**: IAM is accessible globally, meaning users created are available across all regions.
  - *Example*: If you create a user in the US West region, they can access AWS services in the US East region.

### 2. Root Account Usage
- **Best Practice**: Do not use the root account for everyday tasks; instead, use IAM users to enhance security.
  - *Example*: Use an IAM user account named "DevUser" for developing applications while keeping the root account secured for initial setups.

### 3. Creating IAM Users
- **Process**: Demonstration of creating a new IAM user, including inputting a username and setting management console access.
  - *Example*: Creating a user named "Alice" with a custom password and requiring her to change it upon first login.

### 4. Permissions Management
- **Admin Group Creation**: Easiest way to manage permissions by assigning users to groups.
  - *Example*: Create an "AdminGroup" with full administrative permissions, allowing all members to perform administrative tasks.

### 5. Resource Tagging
- **Tagging Usage**: Tags help in organizing and managing AWS resources effectively.
  - *Example*: Tag all resources created by the "DevTeam" with a tag "Department: Development" for easier tracking.

### 6. Signing In
- **Signing in Process**: Instructions on signing in to the console with the new IAM account, using a private browser for security.
  - *Example*: When logging in as "Alice", use the URL specific to your AWS account to access the AWS Management Console.

### 7. Credential Management
- **Important Reminder**: Keep track of both root credentials and IAM user credentials to prevent access issues.
  - *Example*: Store both root and IAM user credentials in a secure password manager.

### 8. Next Steps
- **Practical Exercises**: Upcoming exercises will focus on creating IAM users and groups.

## AWS Console Simultaneous Sign-in

### 1. Enabling Multi-Session Support
- **Feature Activation**: Users can enable multi-session support within their AWS Console settings.
  - *Example*: Click to turn on the feature, allowing you to manage multiple accounts or roles in a single browser.

### 2. Simultaneous Sign-In
- **Access Multiple Accounts**: This feature allows you to log in to multiple AWS accounts or roles simultaneously without needing separate browser windows.
  - *Example*: You can be signed into both a development and production account at the same time.

### 3. Practical Demonstration
- **Resource Management**: Demonstrated the creation of resources in different accounts.
  - *Example*: An EBS volume can be created in one account while another account remains visible in a separate window, showcasing the separation of resources.

### 4. Efficiency Benefits
- **Improved Management**: This capability enhances efficiency for users handling multiple accounts or roles within the same AWS environment.

### 5. Encouragement to Explore
- **Next Steps**: The presenter encourages participants to explore this new feature for better AWS resource management.

## IAM Policies

### 1. Overview of IAM Policies
- **Definition**: IAM policies describe permissions for users and groups in plain English.
- **Principle of Least Privilege**: Permissions should not exceed what a user needs to perform their job, minimizing potential security risks.

### 2. Group-Level Policies
- **Group Application**: When a policy is attached to a group (e.g., a group of developers), all members of the group inherit those permissions.
- **Example Groups**: Different groups can have different policies. For instance, the developers can have access to certain services while the operations team has different permissions.

### 3. Inline Policies
- **Specific to Users**: Inline policies can be created for individual users, allowing for unique permissions irrespective of group memberships.

### 4. Policy Structure
- **Components**: Understanding the structure of IAM policies is crucial. This includes:
  - **Version Number**
  - **Statements**: Each statement carries key elements like Effect, Principal, Action, Resource, and Conditions.

### 5. Security Tools in IAM
- **IAM Credentials Report**: A report at the account level showing user credentials and their statuses.
- **IAM Access Advisor**: Provides user-level insights into service permissions and last access times, assisting in applying the principle of least privilege by identifying unused permissions.

### 6. Closing Encouragement
- **Practical Hands-On**: The lecture highlights the importance of understanding these concepts thoroughly and encourages practicing IAM policy creation in upcoming sessions.

## IAM Policies Hands-on

### 1. User Permissions Management
- **Example**: A user named Stephane has administrator access as part of the admin group. 
- **Demonstration**: Removing him from the group results in an 'access denied' message when he tries to list users.

### 2. Restoring Access with Policies
- To restore access, add the **IAMReadOnlyAccess** policy to Stephane, enabling him to view users and groups but not create them.

### 3. Permission Inheritance and Management
- Permissions can be inherited from groups, allowing a user to have multiple policies attached, showcasing IAM's flexibility.

### 4. Types of IAM Policies
- Discusses specific policies:
  - **AdministratorAccess**: Full access to all AWS services.
  - **IAMReadOnlyAccess**: Allows limited read and list actions.
- **JSON Representation**: Explanation of the components of the policies, including the use of wildcards (e.g., `*`) to cover multiple actions.

### 5. Creating Custom Policies
- **Hands-On Example**: Covers how to create custom policies using both the visual editor and JSON editor to tailor permissions.

### 6. Maintaining IAM Cleanliness
- **Action**: Demonstrates deleting unnecessary groups and policies to maintain an efficient IAM setup.

### 7. Security Tools in IAM
- **IAM Credentials Report**: Generated at the account level providing statuses of all users' credentials.
- **IAM Access Advisor**: Provides user-level insights into service permissions and last access times, assisting in applying the principle of least privilege.

### Conclusion
- The lecture reinforces practical knowledge on effectively managing IAM policies in AWS, preparing students for future sessions and hands-on applications.

## IAM Multi-Factor Authentication (MFA)

### 1. Importance of Password Policy
- A robust password policy is crucial for protecting users and groups from compromises.
  - Key elements include:
    - Minimum password length
    - Requirement for specific character types (uppercase, lowercase, numbers, special characters)
    - Control over user-initiated password changes
    - Periodic password changes (e.g., every 90 days)
    - Prevention of password reuse
  - These measures help defend against brute force attacks.

### 2. Multi-Factor Authentication (MFA)
- MFA serves as a second layer of security by requiring something the user knows (password) and something they own (security device).
- Enhances account protection significantly, ensuring that access remains secure even if a password is compromised.

### 3. Types of MFA Devices
- **Virtual MFA Device**: Applications like Google Authenticator or Authy that manage multiple tokens.
- **Universal 2nd Factor (U2F) Security Key**: Physical devices, like YubiKey, for multi-account support.
- **Hardware Key Fob MFA Devices**: Third-party options and specific key fobs for AWS GovCloud users.

### 4. Conclusion
- The lecture emphasizes the necessity of implementing a strong password policy and MFA for effective AWS account security.
- Prepares students for the next lecture, which will cover practical implementation of these security measures.

## IAM MFA Hands On

### 1. Password Policy Settings
- Access the password policy settings through the IAM console.
- Options to use the default policy or customize it:
  - Minimum password length
  - Requirements for uppercase, lowercase, numbers, and non-alphanumeric characters
- Discussion on password expiration and preventing password reuse.
- Emphasis on the importance of a strong password policy for account security.

### 2. Enabling MFA for the Root Account
- How to enable MFA, crucial for protecting the most sensitive AWS account.
- Step-by-step guide on assigning an MFA device for secure account access.
- Introduction of different types of MFA devices, including:
  - Authenticator apps
  - Security keys
  - Hardware tokens

### 3. Setup Process
- Use of the Twilio Authenticator app to demonstrate the setup process.
- Scanning a QR code with the authenticator app to generate real-time MFA codes.

### 4. Conclusion
- Demonstration of logging into AWS using the root account and entering the MFA code for enhanced security.
- Overall emphasis on implementing strong password policies and MFA to significantly improve account security in AWS.

## AWS Access Keys, CLI and SDK

### 1. Management Console
- A web-based user interface for accessing AWS services.
- Requires username and password for login.
- Multi-factor authentication (MFA) can be used for enhanced security.

### 2. Command Line Interface (CLI)
- Allows users to interact with AWS services using command-line commands.
- Authentication is done using access keys, which must be kept secure and private.
- Enables automation of tasks, providing a faster and more efficient way to manage resources than the Management Console.

### 3. Software Development Kit (SDK)
- SDKs are libraries designed for various programming languages to facilitate interaction with AWS services programmatically.
- Supports languages such as JavaScript, Python, PHP, .NET, Ruby, Java, Go, as well as mobile SDKs for Android and iOS.
- Ideal for developers looking to integrate AWS services directly into their applications.

### 4. Conclusion
- Choosing the right method to access AWS services depends on user needs and comfort level.
- The next session will involve practical exercises on setting up the CLI and managing access keys.

## AWS CLI Installation on Mac OS X (don't touch other platform in my learning course like Windows or Linux)

### 1. Finding the Installation Link
- Begin by searching for the official AWS CLI version 2 installation link.

### 2. Downloading the Installer
- Download the `.pkg` file, which serves as a graphical installer for the AWS CLI.

### 3. Installation Process
- Open the downloaded file.
- Follow the on-screen prompts and click 'Continue'.
- Agree to the terms and select the option to install for all users.

### 4. Verifying Installation
- After installation, open the terminal.
- Run the command: `aws --version`.
- A successful installation will display the version of the AWS CLI.

### 5. Troubleshooting
- For any installation issues, refer back to the installation guide for troubleshooting tips.

**Note**: The lecture emphasizes the importance of ensuring the CLI is properly installed to utilize AWS services efficiently.

## Using AWS CLI Hands On

### 1. Creating Access Keys
- Begin by creating access keys for CLI access through the Security Credentials in the AWS Management Console.
- Recommended to use CloudShell or CLI V2 for specific use cases.

### 2. Configuring the AWS CLI
- Configuration includes entering:
  - Access Key ID
  - Secret Access Key
  - Default Region (e.g., 'eu-west-1')
  - Output Format
- Choose a region based on proximity.

### 3. Using CLI Commands
- Execute commands, such as `aws iam list-users`, to gather information similar to what is available in the Management Console.

### 4. Managing User Permissions
- Removing a user from an admin group leads to denied permissions when executing commands.
- Demonstrates the dependence on IAM permissions for both Management Console and CLI.

### 5. Restoring User Permissions
- Remind to reinstate user permissions by adding them back to the admin group for future operations.

### Key Takeaway
Access methods (Management Console and CLI) require consistent IAM permission management for functionality.

## Using AWS CloudShell

### 1. Finding CloudShell
- Locate the CloudShell icon in the AWS Management Console.
- Availability may vary by region, so check if it's accessible in your region.

### 2. What is CloudShell?
- A free, cloud-based terminal that allows direct execution of AWS CLI commands.
- The default region for API calls is determined by the user’s login region.

### 3. File Management
- Users can create and manage files within CloudShell.
- Files persist even after the environment restarts, enhancing usability.

### 4. Customization Options
- Customize the font size and theme (light or dark), improving user experience.
- Supports file upload and download, useful for handling scripts and resources.

### 5. Working with Multiple Sessions
- Ability to open multiple tabs or split the terminal view for concurrent work.

### 6. Conclusion
- Both CloudShell and traditional terminals serve as valid options for executing AWS commands.

## IAM Roles in AWS

### 1. What are IAM Roles?
- IAM Roles function like user accounts but are specifically designed for AWS services instead of individual users.

### 2. Importance of Permissions
- AWS services, such as EC2 Instances, require specific permissions to perform actions on behalf of the user.

### 3. Role Functionality
- IAM Roles enable AWS services to gain the necessary permissions to access AWS resources.
- For instance, an EC2 Instance accesses information through its assigned IAM Role.

### 4. Common Roles
- Common IAM Roles include those for:
  - EC2 Instances
  - Lambda Functions
  - CloudFormation

### 5. Creating an IAM Role
- The process involves attaching policies to define the specific permissions assigned to the role.
- In a practical demonstration, an IAM Role created for EC2 Instances is assigned permissions for read-only access to IAM resources.

### 6. Conclusion
- The lecture concludes by indicating that creating the role sets up the groundwork for using it in future AWS tasks and emphasizes the relevance of accurate permissions.

## Creating IAM Roles in AWS Hands On

### 1. Accessing the IAM Roles Section
- Navigate to the roles section in the AWS Management Console to view existing roles.

### 2. Creating a New Role
- The goal is to create a new IAM role that grants AWS entities the permissions needed to access AWS resources.

### 3. Importance for Certification
- Emphasizes the importance of understanding IAM roles, especially for those preparing for AWS certification exams.

### 4. Focusing on EC2
- The role creation is specifically geared towards AWS EC2 (Elastic Compute Cloud) services.

### 5. Selecting Service and Use Case
- Choose EC2 as the service and specify its use case for the role.

## Security Tools in IAM

### 1. IAM Credentials Report
- Provides an account-level overview of all user accounts and the status of their credentials.
- Helps in understanding account-level security.

### 2. IAM Access Advisor
- Operates at the user level, showing service permissions assigned to individual users and their last accessed times.
- Aids in identifying unused permissions to manage access in line with the principle of least privilege.

### 3. Implementing Least Privilege
- The Access Advisor is instrumental in adhering to the principle of least privilege by allowing administrators to reduce user permissions effectively.

### 4. Conclusion
- The lecture indicates that the next session will include practical demonstrations on utilizing these security tools.

## Practical IAM Security Tools Hands On

### 1. Generating a Credentials Report
- **Scope**: The report is a CSV file detailing user account information.
- **Contents**: 
  - Includes account creation dates, password status, last password usage, and next expected password rotation.
  - Highlights the significance of Multi-Factor Authentication (MFA) and access keys' history (creation and rotation).
- **Purpose**: Essential for identifying users needing attention due to inactivity or outdated credentials.

### 2. IAM Access Advisor
- **Functionality**: Reviews AWS service access history for specific accounts.
- **Usage**: Helps determine which services have been utilized and which have not, aiding in permission management.
- **Benefit**: Streamlines permissions based on actual service usage, promoting security by ensuring appropriate user access.

### 3. Conclusion
- **Importance**: The lecture embodies the necessity of employing IAM security tools to enhance account security and manage user permissions effectively within AWS.

### 6. Attaching Policies
- Attach a policy to the role; for example, the IAM read-only access policy allows the EC2 instance to read IAM information.

### 7. Naming the Role
- The new IAM role is named "DemoRoleForEC2," with trusted entities selected to define that EC2 can assume it.

### 8. Verifying Permissions
- Verify that the role has the correct permissions before finalizing its creation.

### 9. Role Creation
- Successfully created role now appears in the roles list, although it cannot be utilized until the EC2 section of the course is completed.

### 10. Conclusion
- Recaps that the creation of the IAM role prepares for further lessons involving its application with EC2 instances.

## Best Practices for IAM in AWS

### 1. Avoid Using the Root Account
- The root account should be reserved for the initial setup of your AWS account and not used for daily operations.

### 2. Create Individual User Accounts
- Each user should have their own account rather than sharing credentials to enhance security.

### 3. Group Management
- Users should be organized into groups, and permissions should be managed at the group level for easier administration.

### 4. Strong Password Policy
- Implement a strong password policy to protect user accounts from unauthorized access.

### 5. Enforcing Multi-Factor Authentication (MFA)
- MFA should be enabled to add an additional layer of security for user accounts.

### 6. Using IAM Roles
- Create and use IAM roles to grant permissions to AWS services, such as EC2 instances.

### 7. Programmatic Access
- Generate access keys for programmatic access via the CLI or SDK, ensuring they are kept confidential.

### 8. Tools for Management
- Utilize tools like IAM credentials reports and IAM Access Advisor to audit and review permissions regularly.

### 9. Avoid Sharing Credentials
- Sharing IAM user credentials and access keys poses significant security risks and should be avoided.

## Shared Responsibility Model for IAM in AWS

### 1. Division of Responsibilities
- **AWS Responsibilities**:
  - AWS secures its infrastructure, including global network security, service configuration, vulnerability analysis, and compliance.

- **User Responsibilities**:
  - Users are responsible for creating and managing IAM entities such as users, groups, roles, and policies.
  - Users must monitor these IAM elements to ensure security.

### 2. Multi-Factor Authentication (MFA)
- Users are required to enable Multi-Factor Authentication (MFA) on all accounts to enhance security.

### 3. Key Rotation
- Regularly rotating access keys is essential for maintaining security.

### 4. Infrastructure Utilization
- Users must analyze access patterns and review permissions to manage how they utilize AWS infrastructure.

### 5. Importance of Clarity
- Understanding the division of responsibilities is vital for effective IAM security management in AWS.

This model emphasizes that while AWS takes care of the infrastructure, the security and management of identities and access fall squarely on the users. If you have any questions or need specific clarifications, feel free to ask!

## IAM in AWS - Summary

### 1. IAM Users
- Each IAM user should correspond to a real individual within your organization, equipped with a password for accessing the AWS console.

### 2. User Groups
- Users should be organized into groups, allowing for simplified permission management through policies or JSON documents.

### 3. Creation of Roles
- IAM roles serve as identities for AWS services (like EC2 instances) providing more flexibility in managing access.

### 4. Security Measures
- Enabling Multi-Factor Authentication (MFA) and establishing a password policy are essential for enhancing user security.

### 5. Managing Services
- AWS services can be managed via the AWS CLI or SDK, allowing for command line commands or integration with programming languages.

### 6. Access Keys
- Create access keys to securely access AWS using the CLI or SDK.

### 7. Auditing IAM Usage
- Important to audit IAM usage by generating an IAM credentials report and utilizing the IAM Access Advisor to review permissions.

This lecture provides foundational insights into managing IAM effectively, thereby enhancing security and access control in AWS.
