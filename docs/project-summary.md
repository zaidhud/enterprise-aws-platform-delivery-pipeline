# Enterprise AWS Platform Delivery Pipeline

## Project summary

The Enterprise AWS Platform Delivery Pipeline is an end-to-end cloud platform engineering project built using AWS, Terraform, Ansible and GitHub Actions.

The platform automates the delivery of cloud infrastructure, Linux server configuration and application deployment.

A developer can make a change, commit it to Git and push it to GitHub. GitHub Actions then securely authenticates to AWS, validates the Terraform infrastructure, discovers the application servers, connects to them through AWS Systems Manager, deploys the application and verifies that the deployment completed successfully.

The project was designed to demonstrate the type of automation, security, repeatability and operational control expected in a modern enterprise platform engineering environment.

---

## Project objective

The main objective was to create a secure and repeatable delivery pipeline where a Git push can trigger the complete platform delivery process.

The platform needed to automate:

- AWS authentication;
- infrastructure validation;
- Terraform planning;
- server discovery;
- secure instance connectivity;
- Linux configuration;
- application deployment;
- deployment validation;
- workflow reporting.

The project also needed to avoid insecure or overly manual practices such as:

- storing permanent AWS access keys in GitHub;
- manually maintaining server IP addresses;
- exposing SSH to the public internet;
- configuring servers by hand;
- deploying applications manually;
- creating infrastructure through the AWS Console;
- granting unnecessary administrator permissions.

---

## Business scenario

An organisation needs a reliable way to deploy an application platform into AWS.

The infrastructure team wants the AWS environment to be defined as code.

The operations team wants Linux server configuration to be automated.

The security team does not want permanent AWS credentials stored in GitHub or SSH exposed to the internet.

The development team wants application changes to be deployed through a repeatable pipeline.

The completed platform addresses these requirements by combining:

- GitHub for version control;
- GitHub Actions for workflow orchestration;
- GitHub OIDC for secure AWS authentication;
- Terraform for infrastructure provisioning;
- Amazon S3 for remote Terraform state;
- Ansible for server configuration and application deployment;
- AWS EC2 dynamic inventory for automatic server discovery;
- AWS Systems Manager for secure private-instance connectivity;
- an Application Load Balancer for traffic distribution;
- an Auto Scaling Group for application capacity and instance replacement;
- automated checks for deployment validation.

---

## Simple explanation

The project works like this:

1. A developer changes the code.
2. The developer pushes the change to GitHub.
3. GitHub Actions starts automatically.
4. GitHub securely authenticates to AWS using OIDC.
5. Terraform checks the AWS infrastructure.
6. Ansible finds the current EC2 application servers.
7. AWS Systems Manager provides secure connectivity.
8. Ansible configures the Linux servers.
9. Ansible deploys the application.
10. Validation checks confirm that the deployment succeeded.

The complete workflow can be remembered as:

**Push → Authenticate → Plan → Discover → Connect → Deploy → Validate**

---

## High-level workflow

```text
Developer
    ↓
Git commit
    ↓
Git push
    ↓
GitHub repository
    ↓
GitHub Actions
    ↓
GitHub OIDC authentication
    ↓
AWS IAM role assumption
    ↓
Terraform initialization
    ↓
Terraform validation
    ↓
Terraform plan
    ↓
Ansible collection installation
    ↓
AWS EC2 dynamic inventory
    ↓
SSM connectivity validation
    ↓
Ansible server configuration
    ↓
Rolling application deployment
    ↓
Deployment validation
    ↓
Successful workflow result
```

---

## Technologies used

### AWS

The platform uses AWS as the cloud provider.

AWS services and capabilities used include:

- Amazon VPC;
- public subnets;
- private application subnets;
- private database subnets;
- route tables;
- Internet Gateway;
- NAT Gateway;
- Elastic IP;
- security groups;
- Amazon EC2;
- launch templates;
- Auto Scaling Groups;
- Application Load Balancer;
- target groups;
- IAM roles;
- IAM policies;
- IAM instance profiles;
- AWS Systems Manager;
- Amazon S3;
- AWS Security Token Service;
- AWS OIDC identity provider integration.

### Terraform

Terraform defines and manages the AWS infrastructure as code.

It is used for:

- networking;
- security groups;
- IAM resources;
- compute resources;
- load-balancing resources;
- database networking;
- development environment composition;
- remote state configuration;
- infrastructure outputs.

### Ansible

Ansible configures the Linux servers and deploys the application.

It is used for:

- EC2 dynamic inventory;
- AWS Systems Manager connectivity;
- package installation;
- directory creation;
- file deployment;
- permissions management;
- service configuration;
- application startup;
- rolling deployment;
- deployment validation.

### GitHub Actions

GitHub Actions orchestrates the automated delivery workflow.

It is used for:

- repository checkout;
- AWS authentication;
- Terraform setup;
- Terraform validation;
- Terraform planning;
- Ansible installation;
- Ansible collection installation;
- dynamic inventory checks;
- Systems Manager connectivity checks;
- application deployment;
- workflow reporting.

### Git

Git provides version control for:

- infrastructure code;
- configuration code;
- application files;
- workflow definitions;
- documentation;
- architecture decisions.

---

## Infrastructure architecture

The infrastructure is deployed into a custom Amazon VPC.

The VPC is divided into multiple subnet tiers.

### Public subnet tier

The public subnet tier contains resources that require direct internet connectivity.

This includes:

- the Application Load Balancer;
- NAT Gateway infrastructure;
- routes to the Internet Gateway.

### Private application subnet tier

The private application subnets contain the EC2 application instances.

The instances do not require:

- public IP addresses;
- direct inbound internet access;
- public SSH access.

Outbound internet access is provided through the NAT Gateway where required.

Operational access is provided through AWS Systems Manager.

### Private database subnet tier

The private database subnet tier is designed for database infrastructure.

The database tier is isolated from direct public access.

Database traffic is restricted so that only the application tier can communicate with the database port.

---

## Network traffic flow

The expected application traffic path is:

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
Private database tier
```

The security groups enforce the following boundaries:

- internet traffic can reach the load balancer on approved web ports;
- only the load balancer can reach the application port;
- only the application tier can reach the database port;
- the database is not directly exposed to the internet.

---

## Terraform architecture

The Terraform code is organised into reusable modules.

The main modules include:

```text
terraform/
├── bootstrap/
├── environments/
│   └── dev/
└── modules/
    ├── networking/
    ├── security/
    ├── iam/
    ├── compute/
    ├── load_balancing/
    └── database/
```

The modular structure separates infrastructure responsibilities.

### Networking module

The networking module manages:

- VPC creation;
- public subnets;
- private application subnets;
- private database subnets;
- Internet Gateway;
- NAT Gateway;
- route tables;
- route-table associations.

### Security module

The security module manages:

- Application Load Balancer security group;
- application security group;
- database security group;
- permitted traffic relationships between tiers.

### IAM module

The IAM module manages:

- EC2 service roles;
- application instance role;
- instance profile;
- Systems Manager permissions;
- trust relationships;
- policy attachments.

### Compute module

The compute module manages:

- EC2 launch template;
- application instance configuration;
- Auto Scaling Group;
- instance tags;
- subnet placement;
- instance profile association.

### Load-balancing module

The load-balancing module manages:

- Application Load Balancer;
- listeners;
- target group;
- health checks;
- Auto Scaling Group target registration.

### Database module

The database module manages:

- database subnet group;
- private database subnet placement;
- database networking configuration.

---

## Terraform remote state

Terraform state is stored remotely in Amazon S3.

The remote state provides a central record of the infrastructure managed by Terraform.

The state bucket was created separately through the bootstrap configuration.

The S3 state bucket includes controls such as:

- bucket versioning;
- server-side encryption;
- blocked public access;
- protected state storage.

Remote state allows GitHub Actions to use the same Terraform state across workflow runs.

It also avoids depending on a state file stored only on one local workstation.

---

## GitHub Actions workflow

The GitHub Actions workflow is stored inside:

```text
.github/workflows/platform-delivery.yml
```

The workflow performs the following stages:

### Repository checkout

The workflow downloads the repository contents into the GitHub Actions runner.

### AWS authentication

GitHub Actions uses OIDC to request temporary AWS credentials.

The workflow assumes an AWS IAM role that contains the permissions required for the pipeline.

### AWS identity verification

The pipeline verifies the identity that was assumed using AWS Security Token Service.

This confirms that GitHub Actions is using the expected AWS role.

### Terraform setup

The workflow installs the required Terraform version.

### Terraform initialization

Terraform initializes the development environment and connects to the remote S3 state.

### Terraform validation

Terraform validates the configuration.

This checks that the Terraform code is structurally valid before planning.

### Terraform plan

Terraform compares the infrastructure code with the current AWS environment.

The plan shows whether resources need to be:

- created;
- updated;
- replaced;
- destroyed.

### Ansible setup

The workflow prepares the Python and Ansible environment.

It installs the required Ansible collections defined by the project.

### Dynamic inventory validation

Ansible queries AWS and discovers the current EC2 application instances.

This confirms that the dynamic inventory configuration can identify the required hosts.

### Systems Manager connectivity

The workflow verifies that the application instances are reachable through AWS Systems Manager.

### Application deployment

Ansible applies the application configuration role.

The application is deployed using a controlled rolling strategy.

### Deployment result

The workflow confirms that the Ansible playbook completed successfully.

A successful Ansible recap should show:

```text
unreachable=0
failed=0
```

---

## Secure AWS authentication

The project uses GitHub OIDC rather than permanent AWS access keys.

The authentication flow is:

```text
GitHub Actions job
    ↓
GitHub creates an OIDC token
    ↓
AWS validates the token
    ↓
IAM trust policy checks repository identity
    ↓
GitHub assumes the approved IAM role
    ↓
AWS issues temporary credentials
    ↓
The pipeline accesses AWS
```

The IAM trust relationship is restricted using GitHub identity claims.

These claims identify the approved repository and repository owner.

Immutable identity values were used where possible, including:

- GitHub repository ID;
- GitHub repository-owner ID.

This avoids relying only on names that could potentially change or be reused.

---

## Why OIDC improves security

OIDC removes the need to store:

- AWS access key IDs;
- AWS secret access keys;
- long-lived IAM user credentials.

Temporary credentials:

- are created only when the workflow runs;
- expire automatically;
- are scoped to the assumed IAM role;
- can be restricted through the IAM trust policy;
- reduce manual credential rotation.

---

## IAM least-privilege approach

The pipeline was not granted unrestricted administrator access.

Permissions were added according to the operations required by:

- Terraform;
- Ansible;
- Systems Manager;
- S3 remote-state access;
- AWS resource discovery.

During testing, missing permissions were identified from workflow errors and added deliberately.

Examples included additional Amazon S3 read operations required during Terraform planning.

This approach demonstrated practical least-privilege troubleshooting rather than solving problems by granting full administrative access.

---

## Ansible architecture

The Ansible directory contains:

- inventory configuration;
- playbooks;
- roles;
- variables;
- collection requirements;
- Ansible configuration.

A simplified structure is:

```text
ansible/
├── ansible.cfg
├── requirements.yml
├── inventory/
├── playbooks/
├── roles/
├── group_vars/
└── host_vars/
```

### Playbooks

The application playbook defines:

- the target host group;
- deployment order;
- rolling-deployment settings;
- the application role to apply;
- deployment validation.

### Roles

The Ansible roles organise application configuration into reusable tasks.

The role can manage:

- package installation;
- application directories;
- configuration files;
- service definitions;
- service state;
- application deployment;
- validation checks.

### Collections

Required Ansible collections are defined in:

```text
ansible/requirements.yml
```

The GitHub Actions workflow installs these collections before running inventory or deployment operations.

---

## Dynamic inventory

The project uses the AWS EC2 dynamic inventory plugin.

Instead of storing EC2 private IP addresses manually, Ansible queries AWS during the workflow.

Dynamic inventory allows the pipeline to find instances using:

- AWS region;
- EC2 state;
- instance tags;
- platform role;
- environment;
- infrastructure metadata.

This is especially important because Auto Scaling Group instances are replaceable.

When an instance is terminated and replaced, its identity and private IP address may change.

The inventory plugin discovers the current replacement instance automatically.

---

## Systems Manager connectivity

The application instances are managed using AWS Systems Manager.

Systems Manager was selected instead of traditional public SSH access.

The EC2 instances use an IAM instance profile that allows them to communicate with Systems Manager.

The pipeline also has the IAM permissions required to establish Systems Manager connectivity.

This design avoids:

- inbound SSH port 22;
- public instance IP addresses;
- manually distributed SSH keys;
- direct administrative access from the internet.

---

## Application deployment

After discovering the EC2 instances, Ansible runs the application configuration playbook.

The playbook applies the desired server state.

The deployment process can include:

1. installing required operating-system packages;
2. creating application directories;
3. copying application files;
4. applying file ownership;
5. applying file permissions;
6. configuring the application service;
7. starting or restarting the service;
8. confirming that the service is running;
9. validating the application response.

---

## Rolling deployment strategy

The application deployment is performed using a rolling strategy.

A rolling deployment updates a limited number of instances at a time.

This reduces the risk of making every application instance unavailable simultaneously.

During the deployment:

- one batch of instances is updated;
- other healthy instances remain available;
- the Application Load Balancer continues routing traffic;
- the updated instance is validated;
- deployment continues to the next batch.

This provides a foundation for maintaining application availability during changes.

---

## Auto Scaling Group

The Auto Scaling Group maintains the desired number of application instances.

It uses the launch template to create consistent EC2 instances.

The launch template defines details such as:

- machine image;
- instance type;
- IAM instance profile;
- security group;
- storage configuration;
- instance metadata;
- tags.

If an application instance becomes unhealthy or is terminated, the Auto Scaling Group can create a replacement.

Ansible dynamic inventory can then discover the replacement instance during the next workflow run.

---

## Application Load Balancer

The Application Load Balancer provides the public entry point for the application.

It distributes traffic across healthy application instances.

The load balancer uses a target group to:

- register application instances;
- perform health checks;
- route traffic only to healthy targets.

The load balancer security group controls incoming web traffic.

The application security group allows application traffic from the load balancer rather than from the whole internet.

---

## Infrastructure lifecycle

The Terraform lifecycle follows this process:

```text
Write infrastructure code
    ↓
Format and validate locally
    ↓
Commit the change
    ↓
Push to GitHub
    ↓
GitHub Actions authenticates to AWS
    ↓
Terraform initializes remote state
    ↓
Terraform validates configuration
    ↓
Terraform creates a plan
    ↓
Review proposed changes
    ↓
Apply when required
    ↓
Terraform updates remote state
```

When the development environment is no longer needed, Terraform can destroy the infrastructure in dependency order.

This reduces unnecessary AWS running costs.

---

## Cost-management approach

The development infrastructure is not intended to run permanently.

Resources are destroyed after testing to reduce AWS costs.

This is particularly important for resources that may continue generating charges, including:

- NAT Gateway;
- Application Load Balancer;
- EC2 instances;
- database resources;
- Elastic IP addresses in certain conditions;
- data transfer;
- storage.

The account service quota was also kept restricted as an additional safety guardrail.

However, quotas are not a complete cost-control mechanism.

Cost management should also include:

- AWS Budgets;
- billing alerts;
- cost monitoring;
- regular resource checks;
- Terraform destroy after testing;
- limiting deployment regions;
- avoiding oversized instance types.

---

## Infrastructure shutdown procedure

The development environment can be destroyed using Terraform.

Example:

```bash
terraform.exe -chdir=terraform/environments/dev destroy \
  -var-file="dev.tfvars"
```

After destruction, Terraform state can be checked using:

```bash
terraform.exe -chdir=terraform/environments/dev state list
```

The AWS environment should also be checked for remaining billable resources.

Bootstrap resources such as the remote-state bucket may be retained separately when required.

---

## Validation strategy

The platform uses multiple forms of validation.

### Terraform validation

Terraform checks the syntax and internal consistency of the configuration.

### Terraform planning

Terraform shows the proposed infrastructure changes before they are applied.

### AWS identity validation

The pipeline confirms which AWS role has been assumed.

### Dynamic inventory validation

The pipeline confirms that Ansible can discover the expected EC2 instances.

### Connectivity validation

The pipeline confirms that Systems Manager can reach the application instances.

### Ansible validation

The Ansible play recap confirms whether any hosts were unreachable or tasks failed.

### Application validation

The deployment checks that the application service is running and available.

---

## Idempotency

The platform was designed to support repeatable execution.

Terraform compares the desired infrastructure with the current infrastructure.

When no change is required, Terraform reports that no changes are needed.

Ansible tasks are written to enforce a desired state.

When the server already matches that state, Ansible should avoid making unnecessary changes.

Idempotency allows the workflow to be run repeatedly without rebuilding or reconfiguring unchanged resources unnecessarily.

---

## Configuration drift

Configuration drift occurs when the real environment no longer matches the approved code.

Examples include:

- a security group manually changed in the AWS Console;
- a server package installed manually;
- an application configuration edited directly on an instance;
- an IAM policy modified outside Terraform;
- a server replaced without configuration automation.

Terraform detects infrastructure differences during planning.

Ansible re-applies the approved server configuration.

This helps return the environment to the desired state defined in version control.

---

## Auditability

The project provides several audit trails.

Git records:

- file changes;
- commit history;
- author information;
- branches;
- merged changes.

GitHub Actions records:

- workflow triggers;
- commit identifiers;
- job status;
- execution logs;
- failure information;
- deployment results.

AWS records platform activity through its own service logs and API history where enabled.

Terraform state records the resources managed by the configuration.

Together, these controls make changes easier to review and troubleshoot.

---

## Troubleshooting completed during the project

The project included multiple real-world implementation and troubleshooting challenges.

### Terraform variable-file handling

The pipeline initially needed the development variable file to be committed and referenced correctly.

The workflow was updated to use:

```text
-var-file="dev.tfvars"
```

### GitHub OIDC trust configuration

OIDC authentication required the IAM trust policy to match the GitHub token claims.

Temporary diagnostic output was added to inspect the claims.

The trust policy was then corrected using immutable GitHub identity values.

After authentication was confirmed, the temporary diagnostics were removed.

### IAM policy gaps

Terraform required additional Amazon S3 read permissions.

The IAM policy was updated with only the required actions rather than granting broad administrator access.

### Missing Ansible collections

The workflow initially lacked required Ansible collections.

A collection-installation step was added using:

```text
ansible-galaxy collection install -r ansible/requirements.yml
```

### Ansible path configuration

The GitHub Actions environment needed the correct configuration and roles paths.

The workflow was updated with:

- `ANSIBLE_CONFIG`;
- `ANSIBLE_ROLES_PATH`.

### Dynamic inventory

The AWS dynamic inventory was validated to ensure application instances could be discovered automatically.

### Systems Manager connectivity

The workflow confirmed that Ansible could reach private EC2 instances using Systems Manager.

### Full workflow validation

The completed GitHub Actions job successfully performed:

- OIDC authentication;
- Terraform planning;
- dynamic inventory;
- Systems Manager connectivity;
- rolling application deployment;
- final validation.

---

## Engineering decisions

Important engineering decisions included:

- using Terraform rather than manual AWS Console creation;
- using Terraform modules rather than one large configuration;
- using remote state rather than local-only state;
- using OIDC rather than permanent AWS credentials;
- using least-privilege IAM rather than AdministratorAccess;
- using private EC2 instances rather than public application servers;
- using Systems Manager rather than public SSH;
- using dynamic inventory rather than static IP addresses;
- using Ansible roles rather than a single unstructured playbook;
- using rolling deployment rather than updating all instances simultaneously;
- using automated validation rather than assuming success;
- destroying development infrastructure after testing to control costs.

---

## Skills demonstrated

The project demonstrates practical experience with:

### Cloud engineering

- AWS networking;
- VPC architecture;
- subnet design;
- routing;
- security groups;
- load balancing;
- Auto Scaling;
- IAM;
- Systems Manager;
- S3;
- EC2.

### Infrastructure as Code

- Terraform providers;
- Terraform resources;
- Terraform modules;
- variables;
- outputs;
- remote state;
- state management;
- planning;
- destruction;
- dependency management.

### Configuration management

- Ansible inventory;
- Ansible dynamic inventory;
- playbooks;
- roles;
- variables;
- collections;
- idempotent tasks;
- rolling deployments;
- validation.

### CI/CD

- GitHub Actions;
- workflow YAML;
- environment variables;
- authentication stages;
- Terraform automation;
- Ansible automation;
- deployment orchestration;
- job troubleshooting.

### Security

- GitHub OIDC;
- temporary AWS credentials;
- IAM trust policies;
- IAM permissions;
- least privilege;
- private subnets;
- SSM access;
- restricted security-group traffic.

### Linux operations

- package installation;
- filesystem management;
- ownership and permissions;
- service configuration;
- application deployment;
- connectivity troubleshooting.

### Git

- repository management;
- commits;
- pushes;
- branches;
- change tracking;
- CI/CD triggers.

---

## Business benefits

The project provides several business benefits.

### Faster delivery

Infrastructure and application changes can be delivered through one automated workflow.

### Reduced manual effort

Engineers do not need to create infrastructure or configure servers manually.

### Improved consistency

Every deployment follows the same version-controlled process.

### Improved security

The platform avoids permanent AWS credentials and public SSH access.

### Better auditability

Changes and workflow executions are recorded in GitHub.

### Reduced configuration drift

Terraform and Ansible enforce the approved infrastructure and server state.

### Better recoverability

The platform can be recreated from code.

### Scalable server discovery

Dynamic inventory automatically finds instances created or replaced by Auto Scaling.

### Controlled deployment

Rolling deployment reduces the risk of complete application downtime.

---

## Current project status

The platform has successfully completed an end-to-end GitHub Actions workflow.

The successful workflow verified:

- GitHub OIDC authentication;
- AWS IAM role assumption;
- Terraform initialization;
- Terraform validation;
- Terraform planning;
- Ansible collection installation;
- AWS EC2 dynamic inventory;
- Systems Manager connectivity;
- Ansible role resolution;
- rolling application deployment;
- successful Ansible recap;
- final workflow completion.

The temporary AWS development infrastructure was destroyed after testing to stop unnecessary running costs.

---

## Evidence to capture

The portfolio evidence section should include screenshots or records of:

- successful GitHub Actions workflow;
- AWS identity verification;
- successful Terraform validation;
- successful Terraform plan;
- dynamic inventory output;
- Systems Manager connectivity;
- Ansible play recap;
- `unreachable=0`;
- `failed=0`;
- Application Load Balancer;
- Auto Scaling Group;
- EC2 instances;
- private subnet architecture;
- successful application response;
- Terraform destroy;
- empty Terraform state after destruction.

Sensitive values should be removed or hidden before screenshots are published.

This includes:

- AWS account IDs where appropriate;
- role ARNs where appropriate;
- session tokens;
- private IP addresses if not needed;
- repository security information;
- any credentials or secrets.

---

## Future improvements

The platform could be extended with:

- automated Terraform apply approval;
- separate development, staging and production environments;
- GitHub environment protection rules;
- pull-request Terraform plans;
- automated policy checks;
- Checkov or tfsec security scanning;
- Terraform linting;
- Ansible linting in CI;
- application unit tests;
- integration tests;
- automated load-balancer health validation;
- HTTPS listeners;
- AWS Certificate Manager certificates;
- Route 53 DNS;
- AWS Web Application Firewall;
- centralised application logs;
- CloudWatch dashboards;
- CloudWatch alarms;
- Prometheus monitoring;
- Grafana dashboards;
- blue-green deployment;
- canary deployment;
- database deployment;
- automated backups;
- disaster-recovery testing;
- multi-account AWS architecture;
- reusable GitHub Actions workflows;
- Terraform module versioning;
- secrets management through AWS Secrets Manager;
- automated cost checks;
- Infracost integration;
- AWS Budget alerts.

---

## Interview summary

A strong interview explanation is:

> I built an end-to-end AWS platform delivery pipeline using Terraform, Ansible and GitHub Actions. A Git push triggers the workflow, and GitHub securely authenticates to AWS using OIDC rather than stored access keys. Terraform initializes remote state, validates the infrastructure and creates a plan. Ansible then uses AWS dynamic inventory to discover the application instances and connects to them through Systems Manager because they are hosted in private subnets. Ansible configures the Linux servers, performs a rolling application deployment and validates that there are no unreachable hosts or failed tasks. The project demonstrates Infrastructure as Code, CI/CD, configuration management, private networking, least-privilege IAM and practical troubleshooting.

---

## One-sentence project description

A secure GitHub-driven AWS delivery pipeline that uses Terraform to manage infrastructure and Ansible to configure private EC2 instances and deploy an application through AWS Systems Manager.

---

## CV-ready project entry

**Enterprise AWS Platform Delivery Pipeline — AWS, Terraform, Ansible and GitHub Actions**

- Designed and built an automated AWS platform delivery pipeline integrating Terraform, Ansible and GitHub Actions.
- Implemented secure GitHub-to-AWS authentication using OIDC and temporary IAM role credentials.
- Developed modular Terraform infrastructure covering VPC networking, private subnets, security groups, IAM, EC2, Auto Scaling and Application Load Balancing.
- Configured remote Terraform state using an encrypted and versioned Amazon S3 bucket.
- Implemented AWS EC2 dynamic inventory and Systems Manager connectivity for private-instance management without public SSH.
- Automated Linux configuration and rolling application deployments using reusable Ansible roles.
- Applied least-privilege IAM permissions and resolved real CI/CD authentication, S3, Terraform and Ansible integration issues.
- Validated successful deployments through Terraform checks, dynamic inventory tests, SSM connectivity and Ansible results showing zero unreachable hosts and zero failed tasks.
- Destroyed temporary development resources after testing to control AWS running costs.

---

## Final project statement

This project demonstrates the complete lifecycle of an enterprise cloud platform change.

It starts with source-controlled code and continues through secure authentication, infrastructure validation, server discovery, private connectivity, configuration management, application deployment and automated validation.

The platform is secure, repeatable, auditable and designed around modern cloud engineering practices.
