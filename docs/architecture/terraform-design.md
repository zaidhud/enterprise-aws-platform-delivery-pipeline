# Terraform Architecture and Design

## Overview

Terraform is the Infrastructure as Code layer for the Enterprise AWS Platform Delivery Pipeline.

It defines, creates, updates and destroys the AWS infrastructure required by the platform.

Terraform is responsible for infrastructure such as:

- Amazon VPC;
- public subnets;
- private application subnets;
- private database subnets;
- route tables;
- Internet Gateway;
- NAT Gateway;
- Elastic IP;
- security groups;
- IAM roles;
- IAM policies;
- IAM instance profiles;
- EC2 launch templates;
- Auto Scaling Groups;
- Application Load Balancer;
- target groups;
- listeners;
- database subnet groups;
- resource tags;
- infrastructure outputs.

Terraform does not perform the main Linux configuration or application deployment.

Those responsibilities are handled by Ansible.

The responsibility boundary is:

```text
Terraform
    ↓
Creates and manages AWS infrastructure

Ansible
    ↓
Configures Linux servers and deploys the application
```

---

## Terraform objective

The main objective of the Terraform layer is to make the AWS environment:

- repeatable;
- version controlled;
- reviewable;
- modular;
- consistent;
- auditable;
- disposable;
- easier to reproduce;
- safer to change;
- suitable for CI/CD automation.

Instead of creating infrastructure manually through the AWS Console, the desired platform is described in Terraform configuration files.

---

## Why Terraform was selected

Terraform was selected because it provides a declarative way to manage cloud infrastructure.

The engineer defines the desired end state.

Terraform then determines which actions are required to reach that state.

Example:

```text
Desired state:
Two private application subnets

Current state:
One private application subnet

Terraform result:
Create one additional private application subnet
```

Terraform supports:

- Infrastructure as Code;
- dependency management;
- reusable modules;
- variables;
- outputs;
- remote state;
- provider integration;
- execution planning;
- change detection;
- resource destruction.

---

## Declarative infrastructure

Terraform is declarative rather than primarily procedural.

A procedural approach describes each individual action:

```text
Create a VPC
Create subnet A
Create subnet B
Create an Internet Gateway
Attach the Internet Gateway
Create a route table
Create a route
```

Terraform instead describes the intended resources and their relationships.

Terraform calculates the appropriate order.

This reduces the need to manually script every dependency step.

---

## Project structure

The Terraform structure separates bootstrap resources, environments and reusable modules.

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

The structure gives each area a clear responsibility.

---

## Bootstrap infrastructure

The bootstrap directory contains infrastructure required before the main Terraform environment can use remote state.

This includes the Amazon S3 bucket used to store Terraform state.

A simplified structure is:

```text
terraform/bootstrap/
├── main.tf
├── variables.tf
├── outputs.tf
├── providers.tf
└── versions.tf
```

The bootstrap infrastructure is managed separately from the development environment.

This is necessary because Terraform cannot initially store its state in an S3 bucket that does not yet exist.

---

## Bootstrap process

The bootstrap process follows this sequence:

```text
Local Terraform state
        ↓
Create the remote-state S3 bucket
        ↓
Enable versioning
        ↓
Enable encryption
        ↓
Block public access
        ↓
Configure the development backend
        ↓
Migrate development state to S3
        ↓
Use remote state in future runs
```

The backend bucket remains available even when the temporary development environment is destroyed.

---

## Why bootstrap is separate

If the state bucket were created inside the same Terraform state that depends on it, a circular dependency would exist.

Terraform would need the bucket before it could use the bucket.

Separating bootstrap resources solves this problem.

The bootstrap layer has a different lifecycle from the application platform.

Example:

```text
Bootstrap resources
    Long-lived

Development infrastructure
    Temporary and disposable
```

---

## Development environment

The development environment is located in:

```text
terraform/environments/dev
```

This directory composes the reusable Terraform modules into one complete AWS environment.

A typical environment structure includes:

```text
terraform/environments/dev/
├── backend.tf
├── main.tf
├── outputs.tf
├── providers.tf
├── variables.tf
├── versions.tf
└── dev.tfvars
```

The environment layer supplies:

- environment-specific values;
- module inputs;
- module relationships;
- remote backend configuration;
- provider configuration;
- final platform outputs.

---

## Environment composition

The environment configuration calls the modules and connects them together.

A simplified dependency flow is:

```text
Networking module
        ↓
VPC ID and subnet IDs
        ↓
Security module
        ↓
Security group IDs
        ↓
IAM module
        ↓
Instance profile
        ↓
Compute module
        ↓
Auto Scaling Group
        ↓
Load-balancing module
        ↓
Application endpoint
```

The environment acts as the integration layer between the reusable modules.

---

## Module design

Terraform modules group related infrastructure into reusable components.

The main benefits are:

- clearer ownership;
- reduced duplication;
- easier testing;
- easier maintenance;
- reusable patterns;
- smaller configuration files;
- simpler environment composition;
- clearer inputs and outputs.

Instead of placing every AWS resource in one large `main.tf`, the infrastructure is separated by responsibility.

---

## Networking module

The networking module creates the AWS network foundation.

Its responsibilities include:

- VPC creation;
- public subnet creation;
- private application subnet creation;
- private database subnet creation;
- Internet Gateway creation;
- Elastic IP creation;
- NAT Gateway creation;
- public route table;
- private application route table;
- route-table associations;
- resource tagging.

A simplified module structure is:

```text
terraform/modules/networking/
├── main.tf
├── variables.tf
└── outputs.tf
```

---

## Networking module inputs

Typical networking inputs include:

- project name;
- environment name;
- VPC CIDR range;
- Availability Zones;
- public subnet CIDR ranges;
- private application subnet CIDR ranges;
- private database subnet CIDR ranges;
- common tags.

Example concept:

```hcl
module "networking" {
  source = "../../modules/networking"

  project_name             = var.project_name
  environment              = var.environment
  vpc_cidr                 = var.vpc_cidr
  availability_zones       = var.availability_zones
  public_subnet_cidrs      = var.public_subnet_cidrs
  private_app_subnet_cidrs = var.private_app_subnet_cidrs
  private_db_subnet_cidrs  = var.private_db_subnet_cidrs
}
```

---

## Networking module outputs

The networking module exposes values required by other modules.

Typical outputs include:

- VPC ID;
- public subnet IDs;
- private application subnet IDs;
- private database subnet IDs;
- Internet Gateway ID;
- NAT Gateway ID;
- route-table IDs.

Example dependency:

```text
Networking output:
private_app_subnet_ids

Consumed by:
Compute module
```

---

## Security module

The security module creates the network access controls.

Its responsibilities include:

- Application Load Balancer security group;
- application security group;
- database security group;
- ingress rules;
- egress rules;
- security-group references;
- security-group tags.

The security groups are separated by tier.

```text
Internet
    ↓
ALB security group
    ↓
Application security group
    ↓
Database security group
```

---

## Security-group references

The design uses security-group references instead of broad CIDR rules where possible.

Example:

```text
Application port 8080
Source:
ALB security group
```

This is stronger than:

```text
Application port 8080
Source:
0.0.0.0/0
```

The application instances accept traffic from the load balancer rather than the entire internet.

---

## Security module inputs

Typical inputs include:

- VPC ID;
- project name;
- environment name;
- application port;
- database port;
- allowed public web ports;
- common tags.

The VPC ID comes from the networking module.

```text
Networking module
    ↓
VPC ID
    ↓
Security module
```

---

## Security module outputs

The security module exposes:

- ALB security-group ID;
- application security-group ID;
- database security-group ID.

These outputs are consumed by:

- load-balancing module;
- compute module;
- database module.

---

## IAM module

The IAM module creates AWS identities and permissions used by the application infrastructure.

Its responsibilities include:

- EC2 assume-role policy;
- application instance role;
- IAM policy attachments;
- Systems Manager permissions;
- instance profile;
- resource naming;
- IAM outputs.

The EC2 instances receive permissions through an instance profile.

They do not store permanent AWS credentials.

---

## IAM role relationship

```text
EC2 service
    ↓
Assumes application role
    ↓
Role receives attached policies
    ↓
Role is exposed through instance profile
    ↓
Launch template attaches instance profile
    ↓
EC2 instance receives temporary credentials
```

---

## Systems Manager permissions

The EC2 role includes the permissions required for Systems Manager management.

This allows the instances to:

- register as managed nodes;
- communicate with Systems Manager;
- receive commands;
- establish sessions;
- support Ansible connectivity.

The role uses managed or custom policies according to the project requirements.

---

## IAM module outputs

The IAM module exposes values such as:

- role name;
- role ARN;
- instance profile name;
- instance profile ARN.

The compute module consumes the instance profile.

```text
IAM module
    ↓
Instance profile
    ↓
Compute module
    ↓
Launch template
```

---

## Compute module

The compute module creates the EC2 application capacity.

Its responsibilities include:

- launch template;
- Auto Scaling Group;
- instance configuration;
- security-group association;
- IAM instance-profile association;
- subnet placement;
- EC2 tags;
- capacity settings;
- target-group association where configured.

---

## Launch template design

The launch template defines how each application instance is created.

It may define:

- Amazon Machine Image;
- instance type;
- security group;
- IAM instance profile;
- block-device settings;
- instance metadata options;
- user data;
- monitoring settings;
- tag specifications.

The launch template provides consistent instance creation.

---

## Auto Scaling Group design

The Auto Scaling Group uses the launch template to create and replace instances.

Terraform defines:

- minimum capacity;
- desired capacity;
- maximum capacity;
- private application subnets;
- health-check type;
- health-check grace period;
- instance tags;
- target-group association.

The Auto Scaling Group is responsible for maintaining capacity after Terraform creates it.

---

## Compute module inputs

Typical compute inputs include:

- project name;
- environment name;
- AWS region;
- private application subnet IDs;
- application security-group ID;
- IAM instance-profile name;
- instance type;
- machine image ID;
- minimum capacity;
- desired capacity;
- maximum capacity;
- target-group ARN;
- common tags.

These values come from:

- environment variables;
- networking module;
- security module;
- IAM module;
- load-balancing module.

---

## Compute module outputs

Typical outputs include:

- Auto Scaling Group name;
- launch-template ID;
- launch-template version;
- application capacity information.

These outputs support:

- documentation;
- validation;
- Ansible filters;
- operational scripts;
- future monitoring.

---

## Load-balancing module

The load-balancing module creates the public application entry point.

Its responsibilities include:

- Application Load Balancer;
- target group;
- listener;
- health-check configuration;
- subnet association;
- ALB security-group association;
- resource tags;
- DNS output.

---

## Application Load Balancer inputs

Typical inputs include:

- VPC ID;
- public subnet IDs;
- ALB security-group ID;
- application port;
- health-check path;
- project name;
- environment name;
- common tags.

The load balancer spans the public subnets.

---

## Target group design

The target group defines how the load balancer communicates with the application instances.

It includes:

- target protocol;
- target port;
- target type;
- VPC ID;
- health-check path;
- health-check protocol;
- healthy threshold;
- unhealthy threshold;
- timeout;
- interval.

The Auto Scaling Group registers application instances with the target group.

---

## Listener design

The listener receives incoming traffic.

The development version may use HTTP.

A production version should use:

- HTTPS;
- AWS Certificate Manager;
- TLS policy;
- HTTP-to-HTTPS redirect.

Terraform allows these resources to be defined consistently across environments.

---

## Load-balancing outputs

Typical outputs include:

- ALB ARN;
- ALB DNS name;
- target-group ARN;
- listener ARN;
- hosted-zone ID.

The target-group ARN may be consumed by the compute module.

The DNS name can be used for application validation.

---

## Database module

The database module creates the networking foundation for the database tier.

Its responsibilities include:

- database subnet group;
- private database subnet association;
- database-related naming;
- database outputs.

Depending on the project stage, it may also manage:

- RDS instance;
- parameter group;
- option group;
- encryption;
- backup configuration;
- monitoring;
- deletion protection.

---

## Database subnet group

The database subnet group includes private database subnets across multiple Availability Zones.

It provides the required network placement for Amazon RDS.

Example dependency:

```text
Networking module
    ↓
Private database subnet IDs
    ↓
Database module
    ↓
Database subnet group
```

---

## Module dependency relationships

The complete module relationship can be represented as:

```text
                    ┌─────────────────┐
                    │   Networking    │
                    └────────┬────────┘
                             │
              ┌──────────────┼──────────────┐
              │              │              │
              ▼              ▼              ▼
       ┌────────────┐  ┌────────────┐  ┌────────────┐
       │  Security  │  │  Database  │  │Load Balance│
       └──────┬─────┘  └────────────┘  └──────┬─────┘
              │                                │
              │          ┌────────────┐        │
              └─────────▶│  Compute   │◀───────┘
                         └──────┬─────┘
                                │
                         ┌──────▼─────┐
                         │    IAM     │
                         └────────────┘
```

The exact Terraform call order may differ because Terraform creates a dependency graph rather than following file order.

---

## Terraform dependency graph

Terraform determines resource order from references.

Example:

```hcl
subnet_id = module.networking.private_app_subnet_ids[0]
```

This creates an implicit dependency on the networking module.

Terraform understands that the subnet must exist before the dependent resource can be created.

---

## Implicit dependencies

An implicit dependency exists when one resource references another resource's value.

Example:

```hcl
vpc_id = aws_vpc.main.id
```

Terraform automatically understands:

```text
Create VPC first
Then create the dependent resource
```

Implicit dependencies are preferred because they reflect the actual data relationship.

---

## Explicit dependencies

Terraform supports explicit dependencies using:

```hcl
depends_on = []
```

This should be used only when Terraform cannot infer the relationship from references.

Overusing `depends_on` can make the configuration harder to understand and maintain.

The preferred design is:

```text
Use resource references where possible
Use depends_on only when necessary
```

---

## Variables

Variables make the Terraform code reusable.

Instead of hard-coding values in modules, the environment passes them in.

Examples include:

- region;
- environment name;
- CIDR ranges;
- instance type;
- desired capacity;
- application port;
- database port;
- project name;
- tags.

---

## Variable declarations

Variables are normally declared in:

```text
variables.tf
```

Example:

```hcl
variable "environment" {
  description = "Deployment environment name"
  type        = string
}
```

Good variable declarations include:

- a clear name;
- a description;
- a type;
- validation where appropriate;
- a default only when justified.

---

## Variable types

Terraform variable types may include:

- string;
- number;
- bool;
- list;
- set;
- map;
- object;
- tuple.

Strong typing helps detect incorrect input early.

Example:

```hcl
variable "availability_zones" {
  description = "Availability Zones used by the environment"
  type        = list(string)
}
```

---

## Variable validation

Terraform can validate variable values.

Example concept:

```hcl
variable "environment" {
  type = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging or prod."
  }
}
```

Validation reduces invalid deployments.

---

## Development variable file

Development values are stored in:

```text
terraform/environments/dev/dev.tfvars
```

This keeps environment-specific values separate from reusable module logic.

The file may define:

```hcl
environment   = "dev"
aws_region    = "eu-west-2"
instance_type = "t3.micro"
```

The exact values depend on the project configuration.

---

## Why `dev.tfvars` is committed

The development variable file is committed because it contains non-secret environment configuration required by local and CI execution.

It should not contain:

- passwords;
- API keys;
- private keys;
- database credentials;
- tokens;
- secrets.

Sensitive values should use an approved secrets-management mechanism.

---

## Terraform plan with variable file

The workflow runs:

```bash
terraform -chdir=terraform/environments/dev plan \
  -var-file="dev.tfvars"
```

This ensures the CI/CD environment uses the same development values as local execution.

Without the variable file, Terraform may report missing required values or use unintended defaults.

---

## Local values

Terraform local values can reduce repetition.

Example:

```hcl
locals {
  name_prefix = "${var.project_name}-${var.environment}"
}
```

This can be reused across resource names and tags.

Locals should simplify the configuration rather than hide important logic.

---

## Outputs

Terraform outputs expose useful resource values after planning or applying.

Examples include:

- VPC ID;
- subnet IDs;
- security-group IDs;
- load-balancer DNS name;
- Auto Scaling Group name;
- target-group ARN;
- IAM role ARN.

Outputs support:

- module integration;
- CLI verification;
- CI/CD reporting;
- operational scripts;
- documentation.

---

## Sensitive outputs

Terraform outputs can be marked as sensitive.

Example:

```hcl
output "database_password" {
  value     = var.database_password
  sensitive = true
}
```

Marking an output sensitive reduces accidental display.

However, sensitive values are still stored in Terraform state.

The state must therefore be protected.

---

## Provider configuration

Terraform uses the AWS provider to communicate with AWS.

The provider is configured with the required region.

Example:

```hcl
provider "aws" {
  region = var.aws_region
}
```

Authentication is supplied externally.

Locally, this may use an authenticated AWS CLI session.

In GitHub Actions, authentication is provided through OIDC and temporary role credentials.

---

## No credentials in Terraform code

AWS credentials are not written into Terraform files.

The provider reads temporary credentials from the execution environment.

This avoids committing credentials into Git.

The authentication relationship is:

```text
GitHub OIDC
    ↓
AWS temporary credentials
    ↓
Terraform AWS provider
    ↓
AWS APIs
```

---

## Required provider versions

Terraform provider versions are controlled in:

```text
versions.tf
```

Example concept:

```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}
```

Version constraints help prevent unexpected provider changes.

---

## Terraform version constraint

The project can also define the supported Terraform CLI version.

Example:

```hcl
terraform {
  required_version = ">= 1.9.0"
}
```

The local and CI environments should use a compatible version.

---

## Dependency lock file

Terraform creates:

```text
.terraform.lock.hcl
```

The lock file records selected provider versions and checksums.

It should normally be committed to Git.

This helps local development and CI/CD use consistent provider versions.

---

## Remote state

Terraform state records the relationship between Terraform configuration and AWS resources.

The state contains information such as:

- resource IDs;
- attributes;
- module relationships;
- dependencies;
- outputs;
- metadata.

The project stores the main state remotely in Amazon S3.

---

## Why state is required

Terraform cannot manage infrastructure reliably without state.

State allows Terraform to answer:

```text
Which AWS resources belong to this configuration?
```

It also supports:

- change calculation;
- resource updates;
- destruction;
- drift detection;
- dependency tracking;
- output retrieval.

---

## S3 remote-state backend

The development environment uses an S3 backend.

A backend configuration may define:

- bucket name;
- state key;
- region;
- encryption;
- locking settings where supported.

A conceptual state key is:

```text
enterprise-aws-platform-delivery-pipeline/dev/terraform.tfstate
```

Separate environments should use separate state keys.

---

## State bucket protections

The S3 backend includes controls such as:

- versioning;
- server-side encryption;
- blocked public access;
- restricted IAM permissions;
- private ownership;
- controlled deletion.

These protections reduce the risk of:

- public state exposure;
- accidental state loss;
- unauthorised modification;
- inability to recover a previous version.

---

## State sensitivity

Terraform state may contain sensitive infrastructure data.

Depending on the resources, this can include:

- private IP addresses;
- resource identifiers;
- database details;
- generated credentials;
- configuration values.

State files must not be:

- committed to Git;
- shared publicly;
- attached to portfolio repositories;
- pasted into documentation;
- exposed through screenshots.

---

## Git ignore protection

The repository should ignore local Terraform artifacts such as:

```text
.terraform/
*.tfstate
*.tfstate.*
crash.log
*.tfplan
```

The dependency lock file should normally remain tracked.

---

## State migration

The project migrated from local state to the S3 backend.

A command such as the following was used:

```bash
terraform init -migrate-state -force-copy
```

This moved the existing state into the configured remote backend.

After migration, future operations used the S3 state.

---

## State locking

State locking prevents multiple processes from writing to the same state simultaneously.

The exact locking approach depends on the Terraform version and backend design.

Protection can include:

- S3 backend locking capability;
- a DynamoDB locking table in older designs;
- GitHub Actions concurrency;
- restricted deployment workflows.

The main objective is to prevent concurrent state modification.

---

## CI/CD concurrency

Even with backend locking, GitHub Actions should avoid overlapping deployments to the same environment.

A future workflow can use:

```yaml
concurrency:
  group: terraform-dev
  cancel-in-progress: false
```

This prevents multiple development deployments from running at the same time.

---

## Terraform initialization process

Terraform initialization prepares the working directory.

The command is:

```bash
terraform -chdir=terraform/environments/dev init
```

It performs:

- backend initialization;
- provider installation;
- module initialization;
- lock-file processing;
- state connection;
- working-directory setup.

---

## Reinitialization

Terraform may require reinitialization when:

- backend configuration changes;
- provider configuration changes;
- module sources change;
- state is migrated;
- a fresh runner starts;
- `.terraform` is removed.

GitHub Actions uses a new runner, so initialization occurs during each workflow run.

---

## Terraform formatting

Terraform provides automatic formatting.

Run:

```bash
terraform fmt -recursive
```

To verify formatting without changing files:

```bash
terraform fmt -check -recursive
```

Formatting gives the repository a consistent coding style.

---

## Terraform validation

Validation checks the internal correctness of the Terraform configuration.

Run:

```bash
terraform -chdir=terraform/environments/dev validate
```

Validation can detect:

- syntax errors;
- invalid arguments;
- broken references;
- incorrect module inputs;
- type mismatches;
- provider configuration problems.

---

## Terraform plan

The plan calculates the proposed changes.

Run:

```bash
terraform -chdir=terraform/environments/dev plan \
  -var-file="dev.tfvars"
```

The plan may show:

```text
Plan: 14 to add, 0 to change, 0 to destroy.
```

or:

```text
No changes. Your infrastructure matches the configuration.
```

---

## Reading a Terraform plan

Important plan symbols include:

```text
+ create
~ update in place
-/+ replace
- destroy
```

A replacement should be reviewed carefully because it may cause:

- downtime;
- resource recreation;
- data loss;
- IP changes;
- new identifiers.

---

## Saved plans

Terraform can save a plan:

```bash
terraform plan \
  -var-file="dev.tfvars" \
  -out="tfplan"
```

The same plan can then be applied:

```bash
terraform apply "tfplan"
```

This helps ensure the reviewed plan is the plan that is executed.

---

## Terraform apply

Terraform apply creates or changes infrastructure.

Example:

```bash
terraform.exe -chdir=terraform/environments/dev apply \
  -var-file="dev.tfvars"
```

Terraform:

1. loads the configuration;
2. reads remote state;
3. checks the current AWS resources;
4. calculates changes;
5. requests approval unless disabled;
6. performs API operations;
7. updates state;
8. prints outputs.

---

## Automatic approval

Terraform supports:

```bash
terraform apply -auto-approve
```

This removes the interactive approval prompt.

It can be useful in controlled automation but should be protected by:

- branch controls;
- workflow approvals;
- reviewed plans;
- environment protection;
- least-privilege IAM.

Automatic production apply without approval can be risky.

---

## Terraform destroy

Terraform destroy removes the resources managed by the state.

The project used:

```bash
terraform.exe -chdir=terraform/environments/dev destroy \
  -var-file="dev.tfvars"
```

Destroy is appropriate for temporary development infrastructure.

It reduces costs from resources such as:

- NAT Gateway;
- Application Load Balancer;
- EC2 instances;
- Auto Scaling Group;
- Elastic IP;
- database resources.

---

## Destruction dependency order

Terraform destroys resources in reverse dependency order.

Example:

```text
Auto Scaling Group
    ↓
EC2 instances
    ↓
Load balancer dependencies
    ↓
Security groups
    ↓
NAT Gateway
    ↓
Subnets
    ↓
VPC
```

Terraform calculates this order from the dependency graph.

---

## Post-destroy verification

After destruction, the state can be checked with:

```bash
terraform.exe -chdir=terraform/environments/dev state list
```

An empty result indicates that no development resources remain in that state.

AWS should also be checked for:

- manually created resources;
- resources outside the Terraform state;
- retained snapshots;
- unattached Elastic IP addresses;
- remaining load balancers;
- NAT Gateways;
- database backups;
- storage volumes.

---

## Retained bootstrap resources

The development destroy should not automatically remove separately managed bootstrap resources.

Resources that may remain include:

- S3 remote-state bucket;
- state-locking resource;
- GitHub OIDC provider;
- GitHub Actions IAM role.

These resources have a different lifecycle and may be reused during the next deployment.

---

## Idempotency

Terraform is designed to be idempotent.

If the live infrastructure already matches the configuration, Terraform should report no changes.

Example:

```text
First apply:
Create 31 resources

Second plan:
No changes
```

This makes repeated pipeline execution predictable.

---

## Configuration drift

Drift occurs when AWS resources are changed outside Terraform.

Examples:

- security-group rule edited manually;
- Auto Scaling capacity changed in the Console;
- subnet tag removed;
- IAM policy changed directly;
- load-balancer listener modified manually.

The next Terraform plan compares:

```text
Terraform configuration
        vs
Remote state
        vs
Actual AWS resources
```

Terraform then proposes changes to return the environment to the declared state.

---

## Refresh behaviour

Terraform queries AWS during planning to refresh its understanding of managed resources.

This helps identify drift.

The state is not merely a static file.

Terraform combines state with provider API data to calculate the plan.

---

## Resource import

Terraform can import an existing AWS resource into state.

Example concept:

```bash
terraform import aws_security_group.example sg-0123456789abcdef0
```

Import adds the resource to state but does not automatically generate the full Terraform configuration.

The configuration must still be written to match the imported resource.

---

## State inspection

Terraform state commands include:

```bash
terraform state list
terraform state show
terraform state mv
terraform state rm
```

These commands should be used carefully.

Incorrect state manipulation can cause Terraform to lose track of infrastructure.

---

## Terraform show

The current state or saved plan can be inspected with:

```bash
terraform show
```

For machine-readable output:

```bash
terraform show -json
```

JSON output can support:

- automated checks;
- policy validation;
- reporting;
- custom tooling.

---

## Naming convention

Resource names should be predictable.

A common pattern is:

```text
project-environment-resource
```

Example:

```text
enterprise-aws-platform-dev-app-sg
```

Predictable naming supports:

- AWS Console navigation;
- troubleshooting;
- cost reporting;
- automation;
- ownership identification.

---

## Resource tagging

Common tags should be applied consistently.

Recommended tags include:

```text
Project
Environment
ManagedBy
Owner
Application
CostCentre
```

Example values:

```text
Project     = enterprise-aws-platform-delivery-pipeline
Environment = dev
ManagedBy   = terraform
Owner       = platform-team
```

---

## Centralised tags

Common tags can be created with locals.

Example:

```hcl
locals {
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}
```

Resources can then merge their own specific tags.

---

## Provider default tags

The AWS provider can apply default tags.

Example concept:

```hcl
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = local.common_tags
  }
}
```

This reduces missed tags.

Resource-specific tags can still be added separately.

---

## Lifecycle settings

Terraform resources can use lifecycle rules.

Examples include:

```hcl
lifecycle {
  create_before_destroy = true
}
```

or:

```hcl
lifecycle {
  prevent_destroy = true
}
```

These controls must be used carefully.

---

## `create_before_destroy`

This can reduce downtime for replaceable resources by creating the replacement before deleting the old resource.

However, it may require:

- unique names;
- temporary duplicate capacity;
- sufficient AWS quotas;
- additional cost during replacement.

---

## `prevent_destroy`

This can protect critical resources such as:

- production databases;
- state buckets;
- audit-log buckets.

It should not be used as a substitute for:

- backups;
- approvals;
- access control;
- deletion protection.

It can also block intentional destruction until the lifecycle rule is changed.

---

## `ignore_changes`

Terraform can ignore selected external changes.

Example concept:

```hcl
lifecycle {
  ignore_changes = [desired_capacity]
}
```

This may be useful when another system manages a value.

It should not be used to hide unmanaged drift without a clear reason.

---

## Data sources

Terraform data sources read existing information without creating it.

Examples include:

- current AWS account;
- current region;
- Availability Zones;
- latest machine image;
- existing IAM policies;
- existing Route 53 zones.

Data sources help integrate Terraform with existing AWS information.

---

## Availability Zone data

Terraform can query available zones.

Example:

```hcl
data "aws_availability_zones" "available" {
  state = "available"
}
```

The environment can then select the required number of zones.

For stable environments, explicit zone selection may be preferable to prevent unexpected changes.

---

## Machine image selection

An EC2 image can be provided as:

- a variable;
- an AWS Systems Manager public parameter;
- a Terraform data source;
- a custom image pipeline output.

Dynamic latest-image selection should be used carefully because it can cause unexpected instance replacement.

---

## Terraform functions

Terraform functions help transform values.

Common examples include:

- `merge`;
- `concat`;
- `length`;
- `cidrsubnet`;
- `lookup`;
- `toset`;
- `tomap`;
- `format`;
- `join`.

Functions should simplify data handling without making the configuration difficult to read.

---

## `for_each`

Terraform can use `for_each` to create multiple related resources.

Example concept:

```hcl
for_each = toset(var.availability_zones)
```

This can improve resource stability compared with numeric indexes when collection keys are meaningful.

---

## `count`

Terraform can use `count` to create multiple instances of a resource.

Example:

```hcl
count = length(var.public_subnet_cidrs)
```

`count` is simple but index changes can cause resource-address changes.

The choice between `count` and `for_each` should consider long-term resource stability.

---

## Conditional resources

Terraform can conditionally create resources.

Example:

```hcl
count = var.enable_database ? 1 : 0
```

This can support environment differences.

Too many conditions can make modules complex, so optional behaviour should remain understandable.

---

## Module outputs as contracts

A module's variables and outputs form its interface.

The internal resource design can change while the interface remains stable.

Example:

```text
Networking module output contract:
- vpc_id
- public_subnet_ids
- private_app_subnet_ids
- private_db_subnet_ids
```

Other modules depend on the output contract rather than internal resource names.

---

## Module cohesion

Each module should have one clear area of responsibility.

Good module boundaries include:

- networking;
- security;
- IAM;
- compute;
- load balancing;
- database.

A module should not become a random collection of unrelated resources.

---

## Avoiding excessive modules

Not every individual resource requires its own module.

Excessive module splitting can create:

- too many files;
- difficult navigation;
- unnecessary inputs and outputs;
- complex dependency chains.

Modules should represent meaningful reusable components.

---

## Environment-specific differences

Future environments may have different values.

Example:

```text
Development
- smaller instances
- lower desired capacity
- one NAT Gateway
- reduced retention
- automatic teardown

Production
- larger instances
- higher desired capacity
- resilient NAT design
- longer backups
- deletion protection
- manual approvals
```

The reusable modules remain similar while the environment values change.

---

## Multi-environment structure

A future layout may be:

```text
terraform/environments/
├── dev/
├── staging/
└── prod/
```

Each environment should have:

- separate state;
- separate variables;
- separate approvals;
- separate AWS role;
- separate cost controls;
- separate deployment protections.

---

## Separate AWS accounts

A mature enterprise platform would normally separate environments by AWS account.

Example:

```text
AWS management account
├── development account
├── staging account
├── production account
└── security account
```

This improves:

- isolation;
- billing;
- IAM boundaries;
- blast-radius control;
- compliance.

---

## Terraform in GitHub Actions

The CI/CD workflow runs Terraform after GitHub OIDC authentication.

The flow is:

```text
GitHub push
    ↓
GitHub Actions
    ↓
OIDC role assumption
    ↓
Terraform setup
    ↓
Terraform init
    ↓
Terraform validate
    ↓
Terraform plan
```

The workflow uses temporary AWS credentials supplied to the runner.

---

## CI Terraform environment

GitHub Actions must know:

- AWS region;
- Terraform working directory;
- variable file;
- backend configuration;
- Terraform version;
- role to assume.

These should be explicit in the workflow.

---

## CI plan-only approach

A plan-only CI stage is safer than immediate automatic apply.

The pipeline can:

1. validate the code;
2. produce a plan;
3. display proposed changes;
4. require approval;
5. apply the approved plan.

The development project may automate more aggressively, but production should use stronger controls.

---

## Pull-request Terraform checks

A future pull-request workflow should run:

```text
terraform fmt -check
terraform init
terraform validate
terraform plan
tflint
security scanning
```

This gives reviewers infrastructure feedback before merging.

---

## Plan review

Reviewers should inspect:

- number of resources added;
- number changed;
- number destroyed;
- replacements;
- security-group changes;
- IAM changes;
- subnet changes;
- database changes;
- cost implications.

A plan containing unexpected destruction should not be approved.

---

## Terraform IAM permissions

The GitHub Actions IAM role requires permission to:

- read remote state;
- inspect AWS resources;
- create planned resources when apply is enabled;
- update resources;
- delete resources during destroy;
- pass approved IAM roles;
- interact with required AWS services.

Permissions should be limited to the project requirements.

---

## S3 permission troubleshooting

Terraform required additional S3 read actions during planning.

The project added:

```text
s3:GetAccelerateConfiguration
s3:GetReplicationConfiguration
```

This demonstrates that Terraform providers may read configuration beyond the most obvious resource attributes.

The correct response was to add the specific required actions rather than use AdministratorAccess.

---

## `iam:PassRole`

When Terraform attaches an IAM role to an AWS service, the pipeline may require:

```text
iam:PassRole
```

This permission should be restricted to the approved application role.

Unrestricted `iam:PassRole` can allow privilege escalation.

---

## Least-privilege Terraform role

A least-privilege Terraform role should restrict:

- allowed AWS services;
- allowed resource ARNs where practical;
- IAM role creation;
- IAM role passing;
- regions;
- account;
- OIDC trust identity.

The role should not be reused for unrelated workloads.

---

## Terraform troubleshooting method

A reliable troubleshooting approach is:

1. identify the failing command;
2. read the exact error;
3. determine whether the problem is configuration, state, authentication or permission related;
4. reproduce locally where possible;
5. make the smallest justified change;
6. rerun validation;
7. rerun plan;
8. document the cause and fix.

---

## Common initialization failures

Possible `terraform init` failures include:

- backend bucket not found;
- access denied;
- wrong AWS region;
- invalid backend configuration;
- provider download failure;
- module source failure;
- state-lock failure.

Troubleshooting should begin with the exact backend or provider error.

---

## Common validation failures

Possible `terraform validate` failures include:

- missing required variable;
- unsupported argument;
- unknown resource reference;
- incorrect output reference;
- wrong variable type;
- invalid module source;
- invalid block structure.

Validation errors should be resolved before planning.

---

## Common plan failures

Possible `terraform plan` failures include:

- IAM permission denied;
- invalid AWS resource configuration;
- unavailable instance type;
- quota limit;
- missing variable file;
- incompatible CIDR range;
- invalid subnet relationship;
- backend access failure.

The AWS error message often identifies the exact API operation that failed.

---

## Quota limitations

AWS quotas can prevent Terraform from creating requested capacity.

Possible quota failures include:

- EC2 vCPU limits;
- Elastic IP limits;
- VPC limits;
- NAT Gateway limits;
- load-balancer limits;
- database limits.

The rejected quota increase in this account acts as an additional capacity guardrail.

It helps reduce the risk of accidentally creating excessive infrastructure.

However, quotas are not a complete cost-control system.

---

## Cost-aware Terraform design

Terraform supports cost control by making the environment disposable.

The project can:

- deploy infrastructure;
- test the workflow;
- capture evidence;
- destroy the environment;
- recreate it later from code.

This is safer than leaving development infrastructure running indefinitely.

---

## High-cost resources

Particular attention should be paid to:

- NAT Gateway;
- Application Load Balancer;
- database instances;
- EC2 capacity;
- storage volumes;
- snapshots;
- Elastic IP addresses;
- data transfer.

Terraform destroy should be followed by AWS resource verification.

---

## Resource cleanup evidence

A clean destroy can be verified using:

```bash
terraform.exe -chdir=terraform/environments/dev state list
```

The AWS Console or AWS CLI can also confirm that the following were removed:

- EC2 instances;
- Auto Scaling Group;
- Application Load Balancer;
- target group;
- NAT Gateway;
- Elastic IP;
- security groups;
- subnets;
- VPC;
- database resources.

---

## Terraform and Ansible handoff

Terraform creates the EC2 instances and gives them identifying tags.

Ansible dynamic inventory uses those tags to discover the instances.

The handoff is:

```text
Terraform
    ↓
Creates tagged EC2 instances
    ↓
AWS stores instance metadata
    ↓
Ansible dynamic inventory queries AWS
    ↓
Matching instances become Ansible hosts
```

This is a loose integration through AWS metadata rather than a manually generated static inventory.

---

## Why static Terraform outputs were not enough

Terraform could output instance IP addresses.

However, the Auto Scaling Group may replace instances later.

The output could become stale.

Dynamic inventory is better because it queries the current AWS environment during deployment.

Terraform remains responsible for creating the capacity.

Ansible remains responsible for discovering and configuring the current instances.

---

## Immutable infrastructure principle

The EC2 instances are treated as replaceable.

The launch template defines their initial infrastructure configuration.

Ansible applies the required operating-system and application state.

If an instance fails:

```text
Auto Scaling Group replaces it
    ↓
Dynamic inventory discovers it
    ↓
Ansible configures it
```

The platform does not depend on one manually maintained server.

---

## Terraform documentation standards

Each module should include:

- clear variable descriptions;
- clear output descriptions;
- meaningful resource names;
- comments only where they add value;
- consistent formatting;
- module README where appropriate;
- examples where useful.

The environment documentation should explain:

- required inputs;
- backend configuration;
- deployment commands;
- destruction commands;
- expected outputs;
- cost implications.

---

## Code-quality checks

Recommended Terraform quality checks include:

```text
terraform fmt -check -recursive
terraform validate
tflint
checkov
tfsec
terraform plan
```

Each tool covers a different area.

---

## TFLint

TFLint can detect:

- provider-specific problems;
- deprecated syntax;
- naming issues;
- invalid instance types;
- unused declarations;
- configuration mistakes.

It should be included in future CI validation.

---

## Terraform security scanning

Tools such as Checkov or tfsec can identify:

- public exposure;
- missing encryption;
- open security groups;
- weak logging;
- missing backup controls;
- insecure IAM policies;
- missing metadata protections.

Scanner findings should be reviewed rather than blindly accepted or ignored.

---

## Policy as Code

A mature platform can enforce infrastructure policy using:

- Open Policy Agent;
- Conftest;
- HashiCorp Sentinel;
- AWS Control Tower controls;
- Service Control Policies.

Example policies could require:

- encryption;
- approved regions;
- mandatory tags;
- no public databases;
- no unrestricted SSH;
- approved instance types;
- deletion protection in production.

---

## Automated drift detection

A scheduled workflow could run:

```bash
terraform plan \
  -var-file="dev.tfvars" \
  -detailed-exitcode
```

Terraform detailed exit codes include:

```text
0 = no changes
1 = error
2 = changes detected
```

This can support automated drift reporting.

---

## Automated cost estimation

Infracost could analyse Terraform plans and estimate cost changes.

A pull request could show:

```text
Estimated monthly cost before change
Estimated monthly cost after change
Difference
```

This would strengthen cost awareness before apply.

---

## Automated documentation

Tools such as `terraform-docs` can generate module documentation from:

- variables;
- outputs;
- requirements;
- providers;
- resources.

Generated sections can be included in module README files.

---

## Testing Terraform modules

Terraform modules can be tested through:

- `terraform validate`;
- example configurations;
- temporary test environments;
- Terratest;
- policy checks;
- integration tests;
- post-apply assertions.

Testing should confirm both resource creation and expected behaviour.

---

## Terratest improvement

Terratest can use Go tests to:

1. deploy a temporary environment;
2. query AWS;
3. verify resources;
4. test endpoints;
5. destroy the environment.

This provides stronger validation than syntax checks alone.

---

## Production protections

A production Terraform environment should include:

- protected branch;
- pull-request review;
- saved plan;
- manual approval;
- GitHub environment protection;
- state locking;
- restricted IAM role;
- backup verification;
- deletion protection;
- limited destroy permission;
- production-specific variables.

---

## Separate plan and apply roles

A mature design could use different IAM roles.

Example:

```text
Pull-request role
    Read-only planning permissions

Deployment role
    Approved write permissions
```

This reduces the privileges available during ordinary validation.

---

## Break-glass access

Emergency access should be separate from normal Terraform automation.

It should include:

- strong authentication;
- limited users;
- logging;
- approval;
- short-lived access;
- post-event review.

Terraform automation should remain the normal change path.

---

## Disaster recovery for Terraform state

State recovery should consider:

- S3 versioning;
- restricted deletion;
- backup copies;
- state-lock recovery;
- documented restore procedure;
- tested previous-version recovery.

A damaged or deleted state file can make infrastructure management dangerous.

---

## State recovery approach

A recovery process may include:

1. stop Terraform operations;
2. identify the correct S3 object version;
3. back up the current damaged state;
4. restore the approved prior version;
5. run `terraform plan`;
6. verify resource alignment;
7. resume controlled operations.

State should never be edited casually.

---

## Manual AWS changes

Manual AWS changes should normally be avoided.

When an emergency manual change is required:

1. record the change;
2. restore service;
3. update Terraform code;
4. import or reconcile state if necessary;
5. run a plan;
6. confirm the environment matches code;
7. document the incident.

Otherwise, the next Terraform run may reverse or conflict with the manual change.

---

## Terraform command reference

### Initialize

```bash
terraform.exe -chdir=terraform/environments/dev init
```

### Format

```bash
terraform.exe fmt -recursive terraform
```

### Check formatting

```bash
terraform.exe fmt -check -recursive terraform
```

### Validate

```bash
terraform.exe -chdir=terraform/environments/dev validate
```

### Plan

```bash
terraform.exe -chdir=terraform/environments/dev plan \
  -var-file="dev.tfvars"
```

### Apply

```bash
terraform.exe -chdir=terraform/environments/dev apply \
  -var-file="dev.tfvars"
```

### Destroy

```bash
terraform.exe -chdir=terraform/environments/dev destroy \
  -var-file="dev.tfvars"
```

### List state resources

```bash
terraform.exe -chdir=terraform/environments/dev state list
```

### Show state

```bash
terraform.exe -chdir=terraform/environments/dev show
```

### Display outputs

```bash
terraform.exe -chdir=terraform/environments/dev output
```

---

## Terraform lifecycle summary

```text
WRITE
Define AWS infrastructure in Terraform.

FORMAT
Apply Terraform's standard formatting.

INITIALIZE
Connect to providers, modules and remote state.

VALIDATE
Check configuration correctness.

PLAN
Calculate proposed AWS changes.

REVIEW
Inspect additions, updates, replacements and destruction.

APPLY
Create or update the infrastructure.

VERIFY
Check outputs and AWS resources.

OPERATE
Use Terraform as the approved infrastructure source.

DESTROY
Remove temporary development infrastructure.

CONFIRM
Verify state and AWS cleanup.
```

---

## Skills demonstrated

The Terraform implementation demonstrates:

- Infrastructure as Code;
- AWS provider configuration;
- modular design;
- environment composition;
- remote state;
- state migration;
- S3 backend security;
- VPC design;
- subnet design;
- routing;
- NAT Gateway;
- security groups;
- IAM;
- EC2 launch templates;
- Auto Scaling;
- load balancing;
- database networking;
- variables;
- outputs;
- tagging;
- dependency management;
- CI/CD integration;
- IAM troubleshooting;
- resource destruction;
- cost-aware engineering.

---

## Interview explanation

A clear interview explanation is:

> I organised the Terraform code into a bootstrap layer, environment layer and reusable infrastructure modules. The bootstrap configuration creates the encrypted and versioned S3 bucket used for remote state. The development environment then composes separate networking, security, IAM, compute, load-balancing and database modules. Module outputs pass values such as subnet IDs, security-group IDs and the instance profile between components. GitHub Actions authenticates to AWS using OIDC, initializes the remote state, validates the code and creates a plan using the development variable file. After testing, I use Terraform destroy to remove the temporary development resources and control AWS costs.

---

## 30-second Terraform answer

> Terraform is responsible for the complete AWS infrastructure layer. I separated the code into reusable modules for networking, security, IAM, compute, load balancing and database networking. The development environment connects those modules and stores state remotely in an encrypted, versioned S3 bucket. GitHub Actions runs Terraform through OIDC-based temporary AWS credentials. The pipeline initializes, validates and plans the infrastructure, and I destroy the development environment after testing so costly resources are not left running.

---

## Common interview questions

### Why did you use modules?

Modules separate responsibilities, reduce duplication and make the infrastructure easier to reuse and maintain.

### Why did you use remote state?

Remote state provides a shared and persistent source of truth that can be accessed by GitHub Actions and recovered through S3 versioning.

### Why was the backend created separately?

Terraform needs the backend bucket to exist before it can store state in it, so bootstrap infrastructure has a separate lifecycle.

### How does Terraform know the creation order?

Terraform builds a dependency graph from references between resources and module outputs.

### What is configuration drift?

Drift is when the live AWS environment differs from the Terraform configuration, often because of manual changes.

### What does idempotent mean in Terraform?

Repeated plans or applies should make no additional changes when the infrastructure already matches the code.

### Why did you commit `dev.tfvars`?

It contained required non-secret development configuration used by both local Terraform and GitHub Actions.

### How did you control AWS costs?

The development environment was temporary and was destroyed after testing. Account quotas also remained restricted as an additional safety guardrail.

### Why not use one large Terraform file?

Separating the infrastructure into modules makes the code easier to understand, test, reuse and change.

### How did Terraform integrate with Ansible?

Terraform created tagged EC2 instances, and Ansible dynamic inventory queried AWS to discover the current instances.

---

## Terraform strengths in this project

The strongest Terraform design choices include:

- modular infrastructure;
- separate bootstrap lifecycle;
- remote S3 state;
- encrypted and versioned backend;
- private network tiers;
- consistent security-group relationships;
- reusable environment values;
- OIDC-based CI authentication;
- least-privilege IAM troubleshooting;
- dynamic integration with Ansible;
- complete environment destruction after testing.

---

## Current limitations

The Terraform design still has areas that could be expanded.

These include:

- one primary development environment;
- one AWS account;
- limited automated policy enforcement;
- limited automated testing;
- no complete production database lifecycle;
- no automatic cost estimation;
- no full disaster-recovery test;
- no multi-region design;
- limited plan-approval process;
- limited production deletion protection.

These are suitable future improvements rather than hidden weaknesses.

---

## Future Terraform improvements

Future enhancements include:

- staging and production environments;
- separate AWS accounts;
- pull-request Terraform plans;
- approved saved-plan apply;
- GitHub environment protection;
- TFLint;
- Checkov;
- tfsec;
- Infracost;
- terraform-docs;
- Terratest;
- drift-detection workflow;
- policy as code;
- VPC endpoints;
- production HTTPS;
- Multi-AZ database;
- automated backup validation;
- state-recovery testing;
- restricted production destroy;
- reusable versioned modules.

---

## Final memory card

```text
BOOTSTRAP
Create the secure S3 remote-state backend.

COMPOSE
Use the development environment to connect modules.

NETWORK
Create the VPC, subnets, routes and gateways.

SECURE
Create tiered security groups and IAM roles.

COMPUTE
Create the launch template and Auto Scaling Group.

BALANCE
Create the load balancer, listener and target group.

STORE
Create the database networking foundation.

VALIDATE
Run Terraform format, initialization and validation.

PLAN
Review proposed infrastructure changes.

APPLY
Create or update AWS resources.

HAND OFF
Allow Ansible to discover the tagged EC2 instances.

DESTROY
Remove temporary development infrastructure.

VERIFY
Confirm state and AWS resources are clean.
```

---

## Final summary

Terraform provides the complete Infrastructure as Code foundation for the Enterprise AWS Platform Delivery Pipeline.

The code is separated into bootstrap infrastructure, reusable modules and environment-specific composition.

The S3 backend protects and centralises Terraform state.

The networking module creates the VPC and subnet tiers.

The security module controls traffic between platform components.

The IAM module gives EC2 the permissions required for Systems Manager.

The compute module creates replaceable application capacity.

The load-balancing module exposes the application through healthy targets.

The database module provides the private database networking foundation.

GitHub Actions uses temporary OIDC credentials to initialize, validate and plan the infrastructure.

Terraform and Ansible remain separated by responsibility while integrating through AWS tags and dynamic inventory.

After successful testing, Terraform destroys the temporary development environment to stop unnecessary AWS costs.

The result is a modular, repeatable, secure and cost-aware Terraform implementation suitable for a professional cloud platform engineering portfolio.
