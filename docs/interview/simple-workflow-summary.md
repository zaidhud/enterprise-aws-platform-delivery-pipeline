# Simple Workflow Summary

## Project overview

This project is an automated AWS platform delivery pipeline.

Its purpose is to take a change stored in GitHub and automatically:

1. Authenticate securely to AWS.
2. check the infrastructure.
3. discover the application servers.
4. connect to the servers securely.
5. configure the Linux operating system.
6. deploy the application.
7. validate that the deployment succeeded.

The workflow combines GitHub Actions, GitHub OIDC, Terraform, Ansible, Amazon EC2, AWS Systems Manager, an Application Load Balancer and an Auto Scaling Group.

---

## The workflow in plain English

A developer makes a change to the infrastructure code, application code or Ansible configuration.

The developer commits the change and pushes it to the GitHub repository.

GitHub Actions detects the push and automatically starts the delivery workflow.

The workflow securely authenticates to AWS using OpenID Connect, also known as OIDC.

OIDC allows GitHub Actions to request temporary AWS credentials. Permanent AWS access keys do not need to be stored as GitHub secrets.

After authentication, Terraform initializes the development environment and connects to the remote Terraform state stored in Amazon S3.

Terraform validates the configuration and creates an execution plan.

The Terraform plan compares the infrastructure defined in code with the infrastructure currently running in AWS.

It then shows whether AWS resources need to be created, changed or removed.

Once the infrastructure stage is complete, the workflow installs the required Ansible collections.

Ansible uses the AWS EC2 dynamic inventory plugin to search AWS and automatically discover the application servers.

This means the project does not depend on manually maintained IP addresses or a static inventory file.

The EC2 instances are located in private application subnets and do not require public SSH access.

Ansible connects to the instances through AWS Systems Manager Session Manager.

Systems Manager provides secure access without opening inbound SSH port 22 to the internet.

Ansible then runs the application configuration playbook.

The playbook applies the application role to the discovered EC2 instances.

The role installs the required packages, creates application directories, deploys the application files, configures the service and ensures that the application is running.

The deployment is performed as a rolling deployment.

This means the servers are updated in controlled batches rather than changing every server at exactly the same time.

The Application Load Balancer continues routing traffic to healthy application instances while the deployment takes place.

After deployment, validation checks confirm that:

- the EC2 instances were discovered;
- Systems Manager connectivity works;
- the Ansible playbook completed;
- no hosts were unreachable;
- no tasks failed;
- the application service is running;
- the deployment finished successfully.

If every stage passes, GitHub Actions reports a successful platform delivery.

---

## Workflow to remember

```text
Code change
    ↓
Git commit
    ↓
Git push
    ↓
GitHub Actions starts
    ↓
OIDC authenticates to AWS
    ↓
Terraform initializes remote state
    ↓
Terraform validates the code
    ↓
Terraform creates a plan
    ↓
Ansible collections are installed
    ↓
Dynamic inventory discovers EC2 instances
    ↓
SSM provides secure connectivity
    ↓
Ansible configures the Linux servers
    ↓
Ansible deploys the application
    ↓
Validation checks run
    ↓
Deployment succeeds
```

---

## Seven-stage memory method

The easiest way to remember the workflow is:

**Push → Authenticate → Plan → Discover → Connect → Deploy → Validate**

### 1. Push

The developer pushes a change to GitHub.

This change could include:

- Terraform infrastructure code;
- Ansible playbooks or roles;
- application files;
- GitHub Actions workflow configuration;
- project documentation.

The push triggers the automated GitHub Actions workflow.

### 2. Authenticate

GitHub Actions securely authenticates to AWS using OIDC.

AWS checks the identity claims inside the GitHub OIDC token.

The IAM trust policy confirms that the request came from the approved:

- GitHub organisation or repository owner;
- repository;
- repository ID;
- branch or workflow context.

AWS then issues temporary credentials to the GitHub Actions job.

No long-lived AWS access keys are stored in GitHub.

### 3. Plan

Terraform initializes the development environment and connects to the remote state in Amazon S3.

Terraform validates the configuration to check that the files are syntactically and structurally correct.

Terraform then creates a plan showing the proposed infrastructure changes.

The plan allows the pipeline and engineer to see what Terraform intends to:

- create;
- update;
- replace;
- destroy.

This reduces the risk of unexpected infrastructure changes.

### 4. Discover

Ansible uses the Amazon EC2 dynamic inventory plugin.

The plugin queries AWS and finds the EC2 instances that match the required tags and filters.

This avoids manually adding server IP addresses to an inventory file.

If an Auto Scaling Group replaces an instance, Ansible can discover the new instance automatically.

### 5. Connect

Ansible connects to the private EC2 instances through AWS Systems Manager.

The EC2 instances use an IAM instance profile that allows them to register with Systems Manager.

The GitHub Actions role has permission to start the required Systems Manager sessions.

This approach avoids:

- public EC2 IP addresses;
- exposed SSH ports;
- manually managed SSH keys;
- direct internet access to the application servers.

### 6. Deploy

Ansible applies the application configuration role.

The role ensures that the server reaches the required state.

Typical tasks include:

- installing operating-system packages;
- creating directories;
- copying application files;
- setting file ownership and permissions;
- configuring services;
- starting or restarting the application;
- checking that the application is available.

Because Ansible tasks are designed to be idempotent, running the playbook repeatedly should not create unnecessary changes.

The application is deployed using a rolling strategy so that instances are updated in controlled batches.

### 7. Validate

The pipeline verifies the result of the deployment.

It checks that:

- AWS authentication succeeded;
- Terraform validation passed;
- Terraform planning completed;
- Ansible discovered the correct EC2 instances;
- Systems Manager connectivity succeeded;
- Ansible reported `unreachable=0`;
- Ansible reported `failed=0`;
- the application deployment completed successfully.

GitHub Actions then displays the final workflow result.

---

## 30-second interview explanation

I built an automated AWS platform delivery pipeline where a Git push triggers GitHub Actions. GitHub securely authenticates to AWS using OIDC, so the pipeline does not need permanent AWS access keys. Terraform initializes the remote state, validates the infrastructure code and creates a plan. Ansible then dynamically discovers the EC2 application servers and connects to them through AWS Systems Manager rather than public SSH. It configures the Linux servers, performs a rolling application deployment and validates the result. This creates a secure, repeatable and fully automated delivery process.

---

## One-minute interview explanation

I built an end-to-end AWS platform delivery pipeline using Terraform, Ansible and GitHub Actions.

When code is pushed to GitHub, GitHub Actions starts the workflow and assumes an AWS IAM role using OIDC. This provides temporary AWS credentials and avoids storing permanent access keys.

Terraform connects to its remote state in Amazon S3, validates the infrastructure configuration and creates a plan showing the required AWS changes.

After the infrastructure checks complete, Ansible uses the AWS EC2 dynamic inventory plugin to discover the application instances automatically.

The EC2 instances are located in private subnets, so Ansible connects through AWS Systems Manager instead of exposing SSH to the internet.

Ansible then configures the Linux servers and carries out a controlled rolling application deployment.

The pipeline finishes by checking connectivity, the Ansible play recap and the application deployment result. A successful run confirms that there were no unreachable hosts or failed tasks.

The result is a secure and repeatable platform delivery process managed entirely through code.

---

## One-sentence explanation

A Git push starts a secure pipeline that checks the AWS infrastructure, discovers the private application servers, configures them, deploys the application and validates that everything works.

---

## Very short explanation

**GitHub starts it, OIDC secures it, Terraform builds it, Ansible configures it, SSM connects it and validation proves it works.**

---

## What each technology does

| Technology | Simple purpose |
|---|---|
| Git | Tracks project changes and provides version history. |
| GitHub | Stores the source code and provides collaboration and audit history. |
| GitHub Actions | Runs the automated delivery workflow. |
| GitHub OIDC | Allows GitHub to obtain temporary AWS credentials securely. |
| AWS IAM | Controls what GitHub Actions and EC2 instances are allowed to do. |
| Terraform | Defines and manages AWS infrastructure as code. |
| Amazon S3 | Stores the remote Terraform state. |
| Terraform modules | Organise infrastructure into reusable components. |
| Amazon VPC | Provides the isolated AWS network. |
| Public subnets | Host internet-facing infrastructure such as the load balancer and NAT Gateway. |
| Private application subnets | Host the EC2 application instances without direct public access. |
| Private database subnets | Isolate the database from the public internet. |
| Internet Gateway | Provides internet connectivity for public subnets. |
| NAT Gateway | Allows private instances to make outbound internet requests without accepting inbound internet traffic. |
| Security groups | Control permitted network traffic between platform components. |
| Application Load Balancer | Distributes incoming traffic across healthy application instances. |
| Target group | Registers the application instances and performs health checks. |
| Launch template | Defines how new EC2 application instances are created. |
| Auto Scaling Group | Maintains the required number of application instances. |
| Amazon EC2 | Runs the Linux application servers. |
| IAM instance profile | Gives EC2 instances permission to use AWS services such as Systems Manager. |
| AWS Systems Manager | Provides secure management access without public SSH. |
| Ansible | Configures the Linux servers and deploys the application. |
| AWS dynamic inventory | Automatically discovers the current EC2 instances. |
| Ansible roles | Organise configuration tasks into reusable components. |
| Rolling deployment | Updates instances in controlled batches to reduce disruption. |
| Validation checks | Confirm that the infrastructure and application deployment succeeded. |

---

## Why GitHub Actions was used

GitHub Actions was used because the project source code is stored in GitHub.

It allows the automation workflow to remain close to the code it manages.

The workflow is stored as YAML and is version controlled alongside:

- Terraform;
- Ansible;
- application code;
- documentation.

Every workflow run creates an audit trail showing:

- which commit triggered the run;
- which stages passed;
- which stages failed;
- the execution logs;
- who made the change.

---

## Why OIDC was used

OIDC was used to avoid storing permanent AWS credentials in GitHub.

Without OIDC, the repository might require an AWS access key ID and secret access key stored as GitHub secrets.

Those credentials could remain valid for a long period and would need to be rotated manually.

With OIDC:

1. GitHub creates a signed identity token.
2. AWS verifies the token.
3. AWS checks the IAM trust policy.
4. AWS issues temporary credentials.
5. The credentials expire automatically.

This improves security and reduces credential-management overhead.

---

## Why Terraform was used

Terraform was used to define AWS infrastructure as code.

Instead of creating resources manually through the AWS Console, the desired infrastructure is written in configuration files.

This provides:

- repeatability;
- version control;
- code review;
- consistency;
- audit history;
- automated planning;
- easier recreation of environments.

Terraform modules separate the platform into logical components such as:

- networking;
- security;
- IAM;
- compute;
- load balancing;
- database infrastructure.

---

## Why remote state was used

Terraform state records the relationship between the Terraform configuration and the AWS resources it manages.

The state was stored remotely in Amazon S3 rather than only on one engineer's computer.

Remote state provides:

- a central source of truth;
- persistence between pipeline runs;
- protection against losing a local state file;
- support for automated CI/CD workflows;
- state versioning through S3 bucket versioning.

The state bucket was created separately as bootstrap infrastructure so that Terraform could use it when managing the main development environment.

---

## Why Ansible was used

Terraform provisions infrastructure, but it is not primarily a server configuration-management tool.

Ansible was used after provisioning to configure the Linux operating system and deploy the application.

This separation gives each tool a clear responsibility:

```text
Terraform = infrastructure
Ansible   = server configuration and application deployment
```

Ansible playbooks and roles make the configuration:

- repeatable;
- readable;
- version controlled;
- reusable;
- testable;
- idempotent.

---

## Why dynamic inventory was used

EC2 instances created by an Auto Scaling Group are not permanent.

An instance can be terminated and replaced with a new instance that has a different instance ID or private IP address.

A static Ansible inventory could quickly become outdated.

Dynamic inventory solves this by querying AWS whenever the playbook runs.

Ansible discovers the current instances using AWS metadata such as:

- tags;
- region;
- instance state;
- security groups;
- VPC;
- Auto Scaling Group membership.

This keeps the automation aligned with the real AWS environment.

---

## Why Systems Manager was used instead of SSH

Traditional SSH access normally requires:

- inbound port 22;
- SSH key pairs;
- reachable server IP addresses;
- key storage and rotation;
- additional firewall rules.

This project instead uses AWS Systems Manager.

The application instances remain private and do not need public IP addresses.

Systems Manager uses IAM permissions and the SSM agent to manage the instances.

This reduces the public attack surface and centralises access control through AWS IAM.

---

## Why a rolling deployment was used

Updating every application instance at the same time could cause a complete service interruption.

A rolling deployment changes a limited number of instances at a time.

The remaining healthy instances can continue serving traffic through the Application Load Balancer.

This approach reduces deployment risk and provides a foundation for high availability.

---

## Why validation was included

Automation should not assume that a deployment worked simply because commands finished running.

Validation checks provide evidence that each stage completed successfully.

The pipeline verifies:

- the AWS identity assumed by GitHub Actions;
- Terraform configuration validity;
- the Terraform execution plan;
- dynamic inventory results;
- Systems Manager connectivity;
- Ansible task results;
- application deployment status.

The Ansible play recap is particularly important.

A healthy result should show:

```text
unreachable=0
failed=0
```

---

## Infrastructure workflow

Terraform manages the AWS infrastructure in dependency order.

A simplified flow is:

```text
VPC
    ↓
Subnets
    ↓
Route tables and gateways
    ↓
Security groups
    ↓
IAM roles and instance profile
    ↓
Launch template
    ↓
Auto Scaling Group
    ↓
Target group
    ↓
Application Load Balancer
    ↓
Application instances become healthy
```

Terraform calculates these dependencies from references between resources.

---

## Application deployment workflow

The application deployment stage works like this:

```text
GitHub Actions
    ↓
Install Ansible
    ↓
Install required Ansible collections
    ↓
Load AWS dynamic inventory
    ↓
Discover running application instances
    ↓
Confirm Systems Manager connectivity
    ↓
Run configuration playbook
    ↓
Apply application role
    ↓
Deploy in controlled batches
    ↓
Run validation checks
    ↓
Report the result
```

---

## Security workflow

The security model can be remembered as:

```text
GitHub identity
    ↓
OIDC token
    ↓
AWS IAM trust policy
    ↓
Temporary AWS credentials
    ↓
Least-privilege IAM permissions
    ↓
Systems Manager session
    ↓
Private EC2 instance
```

The project avoids:

- permanent AWS keys in GitHub;
- public SSH access;
- manually shared SSH private keys;
- publicly exposed application servers;
- unrestricted administrator permissions.

---

## Network traffic flow

The intended application traffic path is:

```text
Internet user
    ↓
Application Load Balancer
    ↓
ALB security group
    ↓
Application security group
    ↓
EC2 application instance
    ↓
Database security group
    ↓
Private database
```

The security groups restrict traffic so that:

- internet users can reach the load balancer;
- only the load balancer can reach the application port;
- only the application servers can reach the database port.

---

## Example change workflow

Imagine that the application configuration needs to be updated.

The workflow would be:

1. Edit the application or Ansible role.
2. Review the local changes with Git.
3. Commit the change.
4. Push the commit to GitHub.
5. GitHub Actions starts.
6. GitHub authenticates to AWS through OIDC.
7. Terraform validates and plans the infrastructure.
8. Ansible discovers the current EC2 instances.
9. Systems Manager establishes secure connectivity.
10. Ansible applies the updated configuration.
11. The rolling deployment updates the instances.
12. Validation checks confirm success.
13. GitHub Actions records the completed deployment.

---

## What happens when there are no infrastructure changes

Terraform compares the configuration with the remote state and the current AWS environment.

When the infrastructure already matches the code, the Terraform plan reports that there are no changes.

The pipeline can then continue to the configuration and application deployment stages.

This demonstrates that the Terraform code is idempotent and that repeated runs do not recreate unchanged infrastructure.

---

## What happens when an EC2 instance is replaced

The Auto Scaling Group may replace an unhealthy or terminated EC2 instance.

The replacement instance is created from the launch template.

It receives the required:

- subnet placement;
- security group;
- IAM instance profile;
- operating-system configuration;
- AWS tags.

When the pipeline runs again, Ansible dynamic inventory queries AWS and discovers the replacement instance automatically.

There is no need to manually update an inventory IP address.

---

## What happens when the pipeline fails

GitHub Actions stops or marks the workflow as failed when a required stage returns an error.

Examples include:

- OIDC authentication failure;
- missing IAM permission;
- Terraform validation failure;
- Terraform planning failure;
- no EC2 instances discovered;
- Systems Manager connectivity failure;
- missing Ansible collection;
- Ansible role resolution failure;
- unreachable host;
- failed Ansible task;
- unsuccessful application validation.

The workflow logs show the failing stage and provide information for troubleshooting.

---

## Troubleshooting experience from the project

Several real delivery-pipeline issues were diagnosed and fixed during the build.

These included:

- configuring GitHub OIDC trust conditions;
- using immutable GitHub repository identity claims;
- correcting IAM permissions for Terraform;
- adding required Amazon S3 read permissions;
- providing the correct Terraform variable file in CI;
- installing required Ansible collections;
- setting the Ansible configuration path;
- setting the Ansible roles path;
- validating dynamic inventory;
- confirming Systems Manager connectivity;
- removing temporary OIDC diagnostic output after the issue was resolved.

These problems demonstrate practical troubleshooting rather than only following a successful example.

---

## Main engineering principles demonstrated

### Infrastructure as Code

The AWS infrastructure is defined in Terraform rather than created manually.

### Configuration as Code

Linux server configuration and application deployment are defined in Ansible.

### Version control

Infrastructure, configuration, application code and pipeline definitions are stored in Git.

### Automation

A Git push starts the delivery workflow without requiring a sequence of manual deployment commands.

### Least privilege

IAM permissions were added according to the actions required by the pipeline rather than granting unrestricted administrator access.

### Secure authentication

GitHub Actions uses temporary OIDC credentials instead of permanent AWS access keys.

### Private infrastructure

Application instances remain in private subnets and are managed through Systems Manager.

### Idempotency

Terraform and Ansible are designed to produce the same desired state across repeated runs.

### Validation

The pipeline checks each stage and confirms the deployment result.

### Reusability

Terraform modules and Ansible roles allow components to be reused and maintained independently.

---

## Business value

The platform reduces manual deployment work and creates a consistent delivery process.

It improves reliability because the same workflow runs for every deployment.

It improves security by avoiding long-lived AWS credentials and public SSH access.

It improves traceability because code changes and workflow runs are recorded in GitHub.

It reduces configuration drift because infrastructure and server configuration are managed from source-controlled code.

It also makes the platform easier to reproduce, review and extend.

---

## Strong interview points

When discussing this project, emphasise that it demonstrates:

- end-to-end delivery automation;
- AWS infrastructure design;
- Terraform module development;
- remote state management;
- GitHub Actions CI/CD;
- secure OIDC authentication;
- AWS IAM troubleshooting;
- Linux configuration management;
- Ansible roles and playbooks;
- EC2 dynamic inventory;
- Systems Manager connectivity;
- private subnet architecture;
- rolling application deployment;
- automated validation;
- real-world debugging.

---

## Key distinction between the tools

A useful way to explain the tool boundaries is:

| Tool | Responsibility |
|---|---|
| GitHub | Stores and versions the code. |
| GitHub Actions | Orchestrates the workflow. |
| OIDC and IAM | Securely authorise access to AWS. |
| Terraform | Provisions and manages infrastructure. |
| Ansible | Configures servers and deploys applications. |
| Systems Manager | Provides secure connectivity to private servers. |
| Application Load Balancer | Routes traffic to healthy application instances. |
| Auto Scaling Group | Maintains the required application capacity. |

---

## Final memory card

```text
PUSH
A developer pushes a change to GitHub.

AUTHENTICATE
GitHub uses OIDC to obtain temporary AWS credentials.

PLAN
Terraform validates the infrastructure and calculates the required changes.

DISCOVER
Ansible queries AWS and finds the current EC2 application instances.

CONNECT
Systems Manager provides secure access to the private instances.

DEPLOY
Ansible configures the servers and performs a rolling deployment.

VALIDATE
The pipeline confirms that no hosts failed and the application is working.
```

---

## Final interview answer

I designed and built an automated AWS platform delivery pipeline using Terraform, Ansible and GitHub Actions.

The platform is triggered by a Git push. GitHub Actions authenticates to AWS using OIDC and assumes an IAM role with temporary credentials. Terraform connects to remote state in Amazon S3, validates the infrastructure configuration and creates an execution plan.

Ansible then uses AWS dynamic inventory to discover the current EC2 application instances. Because those instances are hosted in private subnets, Ansible connects through AWS Systems Manager rather than public SSH.

The playbook configures the Linux servers, deploys the application using a rolling strategy and performs validation checks. The workflow confirms that there are no unreachable hosts or failed tasks before reporting success.

The project demonstrates Infrastructure as Code, configuration management, CI/CD, secure cloud authentication, private networking, least-privilege IAM, automated deployment and practical troubleshooting.
