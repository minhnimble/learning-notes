# AWS CloudFormation

---

## CloudFormation - Overview

### TL;DR

- **CloudFormation** defines your AWS infrastructure **as code** in a **declarative template**: you say what should exist and how it is linked, and CloudFormation creates it **in the right order** with the **exact configuration** you specify.
- Benefits: **no manual resource creation**, **version control** (Git) and **code review** for infrastructure, **cost tracking** per stack, **repeatable** and **disposable** environments, and **separation of concerns** (many stacks).
- A **template** (YAML or JSON) creates a **stack**: a collection of AWS resources managed **as one unit**. **Deleting a stack deletes every resource it created.**
- To change a stack, **update the template** (you don't edit the old one in place) and **update the stack**.
- Template sections: `AWSTemplateFormatVersion`, `Description`, **`Resources`** (the **only required** section), `Parameters`, `Mappings`, `Outputs`, `Conditions`, plus helpers such as **references** and **functions**.

### 1. What CloudFormation Does

Example: a template says "I want a security group, two EC2 instances using it, Elastic IPs for them, an S3 bucket, and a load balancer in front of the instances". CloudFormation:

- provisions them **in the right order** (it works out dependencies, you don't orchestrate),
- with the **exact configuration** you declared,
- removing the need for manual configuration and manual work.

- A template is **declarative code** describing what the infrastructure is composed of.
- **Infrastructure Composer** visualizes a template, showing how the components relate to each other, and can generate **diagrams** automatically.

### 2. Why Use CloudFormation

| Benefit | Detail |
|---|---|
| **Infrastructure as code** | No resources are created by hand, which is **better for control**. Templates go in **version control** (for example Git), and **changes are reviewed as code changes**. |
| **Cost** | Resources in a stack are **tagged** with the stack's identifiers, so you can see **what a stack costs**. You can also **estimate the cost** of a template's resources. |
| **Savings strategy** | For example, **delete a dev environment at 5 PM and recreate it at 8 AM** automatically, because everything is automated |
| **Productivity** | **Destroy and recreate** infrastructure on the fly, which uses the cloud's pay-as-you-go model. Diagrams are generated from the template. |
| **Declarative** | You don't figure out the **order of creation** or the orchestration, CloudFormation does |
| **Separation of concerns** | Many stacks for many applications and layers (for example a **network/VPC stack** and **application stacks**) |
| **No reinventing the wheel** | Reuse **existing templates** and the documentation's examples |

### 3. How It Works

```
Template (YAML/JSON) --upload to S3--> CloudFormation references it --> creates a STACK
                                                                          (AWS resources)
Change needed?  Upload a NEW version of the template --> update the stack
Delete the stack --> every resource it created is deleted
```

| Concept | Detail |
|---|---|
| **Template storage** | Templates are **uploaded to Amazon S3** and referenced from CloudFormation (the console handles the upload for you) |
| **Stack** | A set of AWS resources (anything you can create on AWS), **identified by a name within the Region** |
| **Updating** | You **can't edit the previous template**: **upload a new version** and **update the stack**. CloudFormation changes **only what differs**, and **change sets** let you preview the changes first. |
| **Deleting** | Deleting a stack **deletes all the artifacts and resources** CloudFormation created. Resources are created or deleted **as a unit**, and a failed creation **rolls back**. |

**Deploying templates:**

| Way | Detail |
|---|---|
| **Manual** | Build the template in **Infrastructure Composer** or a **code editor**, then use the **console** to enter parameters. Used mostly in this course for learning. |
| **Automated** | Edit the template in a **YAML** file, deploy with the **CLI** or a **continuous delivery tool**. **Recommended** for a fully automated flow. |

### 4. Template Building Blocks

| Section | Purpose |
|---|---|
| **`AWSTemplateFormatVersion`** | The template format version (internal, tells AWS how to read it) |
| **`Description`** | Comments about the template |
| **`Resources`** | The AWS resources to create. **The only mandatory section.** |
| **`Parameters`** | **Dynamic inputs** supplied when you create or update the stack |
| **`Mappings`** | **Static variables** (lookup tables, for example by Region) |
| **`Outputs`** | Values you can **reference** from the created resources (for example a URL or resource ID) |
| **`Conditions`** | Conditions that control **whether resources are created** |
| **Helpers** | **References** (`Ref`) and **functions** (`Fn::...`) |

- **Parameters vs Mappings:** parameters are **inputs chosen at deployment**, mappings are **fixed values written in the template** (the next lectures show the difference).
- Other optional sections: `Metadata`, `Rules`, and `Transform` (for example **AWS SAM**).

### 5. Exam-Style Recall

| If the question says... | Think... |
|---|---|
| "Infrastructure as code, declarative, provisioned in the right order" | **CloudFormation** |
| "Collection of resources created from a template" | A **stack** |
| "Only required section of a template" | **`Resources`** |
| "Dynamic inputs vs static variables" | **`Parameters`** vs **`Mappings`** |
| "Export values from a template" | **`Outputs`** |
| "Create a resource only in some environments" | **`Conditions`** |
| "Update a deployed stack" | Upload the **updated template** and **update the stack** (use **change sets** to preview) |
| "Delete a stack" | **All its resources are deleted** |
| "Visualize a template as a diagram" | **Infrastructure Composer** |
| "Delete dev at night and recreate in the morning, automatically" | **CloudFormation** templates (automate create/delete of stacks) |

---

## CloudFormation - Create Stack - Hands On

### 1. Before Starting

- Select the **US East (N. Virginia) `us-east-1`** Region. The course templates are written for it, especially the **AMI IDs, which are Region-specific**.
- The CloudFormation console lists your stacks (you may already have some from Beanstalk, it doesn't matter).

### 2. Looking at a Sample Template (Not Deployed)

1. **Create stack**: the options are **Choose an existing template**, **Use a sample template**, or **Build from Infrastructure Composer** (called Application Composer in the lecture).
2. Pick a **sample template** (for example **Multi-AZ simple WordPress blog**) and choose **View in Infrastructure Composer** (don't launch it: it would cost money).
3. The **Template** tab shows the full template as **YAML** or **JSON** (YAML is preferred in the course for readability). The **Canvas** shows the same template as components (a web server security group, a launch configuration, an Auto Scaling group, a database instance, a database security group, and so on).
4. Selecting a component shows its resource configuration from the template.

- Bottom line: the template is a **code representation that maps directly to AWS resources**, with a visual view alongside. You don't need to understand the code yet.

### 3. Creating a Stack from a Template File

The course file `cloudformation/0-just-ec2.yaml`:

```yaml
Resources:
  MyInstance:
    Type: AWS::EC2::Instance
    Properties:
      AvailabilityZone: us-east-1a
      ImageId: ami-0453ec754f44f9a4a
      InstanceType: t3.micro
```

| Part | Meaning |
|---|---|
| **`Resources`** | The **mandatory** section |
| **`MyInstance`** | The **logical name** of the resource |
| **`Type: AWS::EC2::Instance`** | The resource type: an EC2 instance |
| **`Properties`** | The Availability Zone (`us-east-1a`), the **AMI ID** (Amazon Linux 2023), and the **instance type** (the lecture says `t2.micro`, the current file says `t3.micro`) |

- Nothing is defined in the EC2 console, only in the template.

**Steps:**

1. **Create stack**, **Upload a template file**, choose `0-just-ec2.yaml`, **Next**.
2. **Stack name:** `EC2InstanceDemo`.
3. Skip tags, permissions, and the other settings (covered later), **Next**, then **Submit**.
4. The template is **uploaded to Amazon S3 by AWS**, and CloudFormation references that S3 object.

### 4. Following the Stack

| Where | What you see |
|---|---|
| **Events** | "Stack creation in progress", then `MyInstance` **`CREATE_IN_PROGRESS`**, then **`CREATE_COMPLETE`** (very quick) |
| **Resources** | One resource. Its **Physical ID** links to the **EC2 console** instance. |
| **EC2 instance** | The requested **instance type**, **Availability Zone** (`us-east-1a`), and **AMI** (Amazon Linux 2023) |
| **EC2 instance, Tags** | Tagged **by CloudFormation** with the **stack ID**, the **logical ID** (`MyInstance`), and the **stack name** (`EC2InstanceDemo`) |
| **Outputs, Parameters** | Empty |
| **Template** | The exact template you uploaded |

---

## CloudFormation - Update & Delete Stack - Hands On

### 1. Updating the Stack

- The only way to update a stack is to **provide a template**: **replace the current template** with a new one. **Use current template** keeps the same template and can't modify it.
- The new template is the course file `1-ec2-with-sg-eip.yaml`, an update of the first one:

```yaml
Parameters:
  SecurityGroupDescription:
    Description: Security Group Description
    Type: String

Resources:
  MyInstance:
    Type: AWS::EC2::Instance
    Properties:
      AvailabilityZone: us-east-1a
      ImageId: ami-0453ec754f44f9a4a
      InstanceType: t3.micro
      SecurityGroups:
        - !Ref SSHSecurityGroup
        - !Ref ServerSecurityGroup
  MyEIP:                                   # an Elastic IP attached to the instance
    Type: AWS::EC2::EIP
    Properties:
      InstanceId: !Ref MyInstance
  SSHSecurityGroup:                        # inbound SSH (22) from anywhere
    Type: AWS::EC2::SecurityGroup
    ...
  ServerSecurityGroup:                     # HTTP (80) from anywhere, SSH from one address
    Type: AWS::EC2::SecurityGroup
    Properties:
      GroupDescription: !Ref SecurityGroupDescription
    ...
Outputs:
  ElasticIP:
    Value: !Ref MyEIP
```

| New in this template | Meaning |
|---|---|
| **`Parameters`** | `SecurityGroupDescription`, a value entered **at deployment** |
| **`!Ref`** | References another resource or a parameter (the instance references the two security groups, the EIP references the instance) |
| **`Outputs`** | `ElasticIP` returns the Elastic IP |

**Steps:**

1. Stack, **Update**, **Replace current template**, **Upload a template file**: `1-ec2-with-sg-eip.yaml`, **Next**.
2. The template has a parameter, so the console prompts for **`SecurityGroupDescription`**. Enter any text (the demo used "This is a cool security group"), **Next**.
3. On the review page, the **Change set preview** lists what will change:

| Resource | Action | Replacement |
|---|---|---|
| Elastic IP | **Add** | |
| SSH security group | **Add** | |
| Server security group | **Add** | |
| `MyInstance` (the EC2 instance) | **Modify** | **True** |

- **Replacement: True** means the old resource is **terminated and a new one created**. **False** means the resource changes **in place**. CloudFormation decides, based on which properties changed. If you don't want a replacement, change your template and review again.

4. **Submit**.

### 2. Watching the Update

| Where | What happens |
|---|---|
| **Events** | The two security groups are created first, then the instance: "requested update requires the creation of a new physical resource" (because of the replacement) |
| **EC2 instances** | The old instance **and** a new one (pending, then running): the new instance **replaces** the old one |
| **Elastic IP** | A new EIP is created (tagged by CloudFormation with the **logical ID, stack ID, and stack name**) and attached to the **new** instance. Its associated instance ID is the one CloudFormation created. |
| **Old instance** | Shuts down and terminates once the replacement is in place |
| **Security groups** | Two are attached to the new instance. The SSH one has inbound port **22**. The server one has HTTP and SSH rules, and its **description is the parameter value** you entered, which shows what a **parameter** does at runtime. |
| **Stack** | **`UPDATE_COMPLETE`**, now with **four resources** |

- Nothing was done by hand: **the template was updated and uploaded, and CloudFormation worked out how to reach the final state**.

### 3. Deleting the Stack

- Terminating the instance by hand would leave the security groups and the Elastic IP behind. Instead, **Delete** the stack from CloudFormation: it deletes **all the stack's resources**.
- Events show the **Elastic IP** deleted first, then the **EC2 instance** (shutting down), and finally the **security groups**. CloudFormation **works out the correct deletion order itself**.
- Summary: you have now seen how to **create, update, and delete** all the resources of a stack.

---

## YAML Crash Course

### TL;DR

- CloudFormation templates are written in **YAML** or **JSON**. This course uses **YAML**: it is far more **readable** and avoids JSON's string-interpolation mess.
- YAML is built from **key-value pairs**, **nested objects** (by **indentation**), **lists** (a **dash** per item), **multi-line strings** (`|`), and **comments** (`#`).
- Use **spaces** for indentation, never tabs.

### 1. The Building Blocks

```yaml
invoice: 34843                    # key: value (a number)
date: 2001-01-23                  # a string / date
bill-to:                          # a nested object (indented keys)
  given: Chris
  family: Dumars
  address:                        # nested again
    lines: |                      # | = a multi-line string
      458 Walkman Dr.
      Suite #292
products:                         # a list: one dash per item
  - sku: BL394D
    quantity: 4
    description: Basketball
    price: 450.00
  - sku: BL4438H
    quantity: 1
    description: Super Hoop
    price: 2392.00
```

| YAML feature | Syntax | Example in a template |
|---|---|---|
| **Key-value pair** | `key: value` | `Type: AWS::EC2::Instance` |
| **Nested object** | Child keys **indented** under a key | `Resources:` then `MyInstance:` then `Properties:` |
| **List (array)** | One **`- item`** per element (a list can have one element) | `SecurityGroups:` then `- !Ref SSHSecurityGroup` |
| **Multi-line string** | `key: \|` followed by indented lines | Long descriptions, scripts |
| **Comment** | `# text` | `# an elastic IP for our instance` |

### 2. Reading a CloudFormation Template

```yaml
Resources:                          # nested object
  MyInstance:                       # nested object (the logical name)
    Type: AWS::EC2::Instance        # key-value (string)
    Properties:                     # nested object
      AvailabilityZone: us-east-1a
      SecurityGroups:               # list of two elements
        - !Ref SSHSecurityGroup
        - !Ref ServerSecurityGroup
  # an elastic IP for our instance   <- comment
```

- `Resources` holds a nested object; each resource has a **`Type`** (a string) and **`Properties`** (another nested object).
- `!Ref` is a **short-form function** (covered in the intrinsic functions lecture).

### 3. Exam-Style Recall

| If the question says... | Think... |
|---|---|
| "Formats for CloudFormation templates" | **YAML** and **JSON** |
| "Write a list in a YAML template" | One **dash (`-`)** per element |
| "Add a comment in a YAML template" | **`#`** (JSON doesn't support comments) |
| "Nested properties in YAML" | **Indentation** (spaces) |

---

## CloudFormation - Resources

### TL;DR

- **Resources** are the **core** of a template and its **only mandatory section**. Each one is an AWS component to create and configure.
- Resources are declared and can **reference each other**. CloudFormation works out the order of **creation, updates, and deletes**.
- Resource types follow **`service-provider::service-name::data-type-name`** (for example `AWS::EC2::Instance`). There are **hundreds** of types (the lecture says over 700) and the list keeps growing. Learn to **read the documentation** instead of memorizing them.
- Anything you can set in the console can **usually** be set through CloudFormation.
- **FAQ answers:** a **dynamic number** of resources needs **Macros / Transform** (out of scope), and an **unsupported service** is handled with **CloudFormation Custom Resources** (the exam expects this).

### 1. Anatomy of a Resource

```yaml
Resources:
  MyInstance:                      # logical ID (alphanumeric, unique in the template)
    Type: AWS::EC2::Instance       # service-provider::service-name::data-type-name
    Properties:                    # key-value pairs (some required, some optional)
      AvailabilityZone: us-east-1a
      SecurityGroups:              # an Array of strings
        - !Ref SSHSecurityGroup
```

| Part | Detail |
|---|---|
| **Logical ID** | The resource's name **in the template**: **alphanumeric** and **unique**. Other sections reference it. |
| **Type** | `AWS::<Service>::<ResourceType>` (for example `AWS::S3::Bucket`) |
| **Properties** | The configuration of that type. Values can be literals, lists, booleans, parameter references, or function results. |
| **Physical ID** | The **real** ID created by AWS (for example `i-1234567890abcdef0`). CloudFormation generates it, and it appears after creation. |

- A resource can reference another with **`!Ref`** (the other resource's ID/name) or **`!GetAtt`** (another attribute), covered in the intrinsic functions lecture.

### 2. Reading the Documentation

1. Open the [AWS resource and property types reference](https://docs.aws.amazon.com/AWSCloudFormation/latest/TemplateReference/aws-template-resource-type-ref.html) (the page that lists every type) and pick a service, for example **Amazon EC2** or **Kinesis** (two types).
2. Open the type, for example [`AWS::EC2::Instance`](https://docs.aws.amazon.com/AWSCloudFormation/latest/TemplateReference/aws-resource-ec2-instance.html). It shows the **syntax** in **YAML or JSON**, the **properties**, the **return values**, and **examples**.
3. Each property shows:

| Field | Example (`IamInstanceProfile`, `ImageId`) |
|---|---|
| **Required** | `IamInstanceProfile` is **not required**, which is why the earlier template doesn't set it |
| **Type** | String, or **Array of String** (for example `SecurityGroups`) |
| **Update requires** | **No interruption** (adding `IamInstanceProfile` doesn't stop or replace the instance) or **Replacement** (changing `ImageId`, the AMI, replaces the instance) |

- Some types, like an **Elastic IP**, have their own page ([`AWS::EC2::EIP`](https://docs.aws.amazon.com/AWSCloudFormation/latest/TemplateReference/aws-resource-ec2-eip.html)) with the declaration and its **examples**. Searching "elastic IP CloudFormation" finds it too.
- **Update requires** tells you in advance whether an edit **replaces** the resource (see the Update stack lecture).

- More AWS references: [Resources section syntax](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/resources-section-structure.html) and [custom resources](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/template-custom-resources.html).

### 3. Common Questions

| Question | Answer |
|---|---|
| **Can I create a dynamic number of resources?** | **Yes**, with **CloudFormation Macros and Transform**, but that is **out of scope**. In this course **what you write in the template is what is created**. |
| **Is every AWS service supported?** | **Almost.** A few things aren't there yet. The **workaround the exam expects** is **CloudFormation Custom Resources**: custom provisioning logic backed by a **Lambda function** (or an **SNS topic**) that CloudFormation calls on create, update, and delete. |

### 4. Exam-Style Recall

| If the question says... | Think... |
|---|---|
| "Only required section of a template" | **`Resources`** |
| "Format of a resource type" | **`service-provider::service-name::data-type-name`** (`AWS::EC2::Instance`) |
| "Where to find the properties of a resource" | The **AWS resource and property types reference** |
| "Does changing this property replace the resource?" | Check **Update requires** in the docs (**No interruption** / **Some interruption** / **Replacement**) |
| "Create a resource CloudFormation doesn't support" | **Custom resource** (Lambda-backed) |
| "Create a variable number of resources" | **Macros / Transform** |
