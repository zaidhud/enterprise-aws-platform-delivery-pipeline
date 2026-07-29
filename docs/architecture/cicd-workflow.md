# CI/CD Workflow Architecture

## Overview

The Enterprise AWS Platform Delivery Pipeline uses GitHub Actions to automate infrastructure validation, AWS authentication, server discovery, secure connectivity, application deployment and post-deployment verification.

The workflow connects four main engineering layers:

```text
Source Control
    ↓
CI/CD Orchestration
    ↓
Infrastructure Management
    ↓
Configuration and Application Deployment
```

The main technologies are:

- GitHub;
- GitHub Actions;
- GitHub OpenID Connect;
- AWS Identity and Access Management;
- Terraform;
- Amazon S3 remote state;
- Ansible;
- AWS EC2 dynamic inventory;
- AWS Systems Manager;
- Amazon EC2;
- Application Load Balancer;
- Auto Scaling Group.

The workflow was designed to provide a secure, repeatable and auditable delivery process.

---

## Main objective

The objective of the CI/CD workflow is to automate the delivery process from a Git push through to a validated AWS application deployment.

The workflow must be able to:

- detect a source-code change;
- start automatically;
- authenticate securely to AWS;
- verify the AWS identity being used;
- initialize Terraform;
- access remote state;
- validate Terraform code;
- calculate proposed infrastructure changes;
- prepare the Ansible environment;
- install required Ansible collections;
- discover EC2 instances dynamically;
- verify Systems Manager connectivity;
- configure Linux application servers;
- deploy the application;
- perform a rolling deployment;
- detect unreachable hosts;
- detect failed tasks;
- report the final result.

---

## High-level pipeline

```text
Developer makes a change
        ↓
Git commit
        ↓
Git push
        ↓
GitHub Actions workflow starts
        ↓
Repository is checked out
        ↓
GitHub OIDC token is issued
        ↓
AWS IAM role is assumed
        ↓
AWS identity is verified
        ↓
Terraform is installed
        ↓
Terraform remote state is initialized
        ↓
Terraform code is validated
        ↓
Terraform plan is created
        ↓
Python and Ansible are prepared
        ↓
Ansible collections are installed
        ↓
AWS EC2 dynamic inventory runs
        ↓
Application instances are discovered
        ↓
SSM connectivity is verified
        ↓
Ansible playbook runs
        ↓
Application role is applied
        ↓
Rolling deployment completes
        ↓
Validation checks pass
        ↓
GitHub Actions reports success
```

---

## Easy workflow memory method

The workflow can be remembered using:

**Trigger → Authenticate → Inspect → Prepare → Discover → Connect → Deploy → Validate**

### Trigger

A Git push starts the workflow.

### Authenticate

GitHub Actions uses OIDC to assume an AWS IAM role.

### Inspect

Terraform validates the infrastructure and creates a plan.

### Prepare

The workflow installs Terraform, Python, Ansible and required collections.

### Discover

Ansible queries AWS and finds the current EC2 application instances.

### Connect

AWS Systems Manager provides secure access to the private instances.

### Deploy

Ansible configures the servers and deploys the application.

### Validate

The workflow confirms that no hosts were unreachable and no tasks failed.

---

## Workflow location

The workflow definition is stored in:

```text
.github/workflows/platform-delivery.yml
```

Because the workflow is stored inside the repository, it is version controlled alongside:

- Terraform code;
- Ansible configuration;
- application files;
- scripts;
- tests;
- documentation.

Any change to the pipeline is visible in Git history.

---

## Workflow trigger

The workflow starts when its configured GitHub event occurs.

For the current project, the main delivery event is a push to the repository.

A simplified trigger looks like:

```yaml
on:
  push:
    branches:
      - main
```

This means that a change pushed to the main branch can start the platform delivery workflow.

A production environment may use additional controls such as:

- pull-request validation;
- manual approval;
- GitHub environments;
- protected branches;
- required reviews;
- deployment windows;
- separate staging and production workflows.

---

## Why Git push was used as the trigger

Using Git as the entry point provides a controlled change process.

Instead of logging into AWS and making changes manually, the engineer:

1. edits the project code;
2. reviews the change;
3. commits the change;
4. pushes it to GitHub;
5. allows the automated workflow to process it.

This provides:

- version history;
- change attribution;
- repeatability;
- workflow logs;
- rollback reference points;
- reduced manual intervention.

---

## Repository checkout

The first major workflow step checks out the repository.

A typical step uses:

```yaml
- name: Checkout repository
  uses: actions/checkout@v4
```

This downloads the repository content into the GitHub-hosted runner.

The runner can then access:

- Terraform configuration;
- Terraform variable files;
- Ansible playbooks;
- Ansible roles;
- dynamic inventory configuration;
- application source;
- shell scripts;
- project tests.

Without checkout, the workflow would not have the project files required for the later stages.

---

## GitHub Actions runner

The workflow runs on a GitHub Actions runner.

A runner is the temporary execution environment used to perform the pipeline steps.

The runner provides:

- an operating system;
- temporary filesystem storage;
- environment variables;
- command-line execution;
- access to GitHub Actions;
- access to external services where permitted.

The runner is temporary.

After the job finishes, the hosted runner is removed.

This means the workflow must install or configure any required tools during the job.

---

## Workflow permissions

GitHub Actions requires specific permissions to request an OIDC token.

The workflow commonly includes:

```yaml
permissions:
  id-token: write
  contents: read
```

### `id-token: write`

This allows the workflow to request a GitHub OIDC identity token.

It does not directly grant permission to change AWS resources.

AWS still validates the token and decides whether the IAM role can be assumed.

### `contents: read`

This allows the workflow to read the repository content.

It supports the checkout stage.

---

## Secure authentication requirement

The pipeline needed access to AWS without storing long-lived AWS credentials in GitHub.

A less secure design might use repository secrets containing:

```text
AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY
```

This project avoids that design.

Instead, GitHub Actions uses OpenID Connect.

---

## OIDC authentication flow

The authentication flow works as follows:

```text
GitHub Actions job starts
        ↓
Workflow requests an OIDC token
        ↓
GitHub issues a signed token
        ↓
Token contains identity claims
        ↓
AWS validates the token
        ↓
IAM trust policy checks the claims
        ↓
Approved IAM role is assumed
        ↓
AWS STS issues temporary credentials
        ↓
Workflow uses AWS services
```

The temporary credentials expire automatically.

---

## AWS credential configuration

The workflow uses the AWS credentials action to assume the approved IAM role.

A simplified example is:

```yaml
- name: Configure AWS credentials
  uses: aws-actions/configure-aws-credentials@v4
  with:
    role-to-assume: ${{ secrets.AWS_GITHUB_ACTIONS_ROLE_ARN }}
    aws-region: eu-west-2
```

The role ARN identifies the IAM role that GitHub Actions is allowed to assume.

The AWS region defines where the workflow performs its regional operations.

---

## OIDC token claims

The GitHub OIDC token contains claims describing the workflow identity.

These can include information such as:

- repository;
- repository owner;
- repository ID;
- repository-owner ID;
- branch or reference;
- workflow name;
- actor;
- audience;
- subject.

AWS evaluates these claims through the IAM role trust policy.

The project used immutable GitHub identity values where possible.

These included:

- repository ID;
- repository-owner ID.

Immutable values are stronger than relying only on repository names because names may be changed or reused.

---

## IAM trust policy

The GitHub Actions IAM role contains a trust policy.

The trust policy determines who is allowed to assume the role.

The trust relationship checks:

- the GitHub OIDC provider;
- the expected token audience;
- the approved repository identity;
- the approved repository owner;
- the relevant workflow context.

A simplified trust flow is:

```text
GitHub OIDC provider
        ↓
Token audience accepted
        ↓
Repository identity accepted
        ↓
Repository owner identity accepted
        ↓
Role assumption allowed
```

If the claims do not match, AWS rejects the request.

---

## Temporary OIDC diagnostics

During implementation, temporary diagnostics were added to inspect the GitHub OIDC token claims.

This was necessary because the initial IAM trust policy did not match the actual claims presented by the workflow.

The troubleshooting process was:

1. request the GitHub OIDC token;
2. inspect non-secret identity claims;
3. compare the claims with the IAM trust policy;
4. identify the mismatch;
5. update the trust conditions;
6. test role assumption again;
7. confirm authentication success;
8. remove the temporary diagnostics.

The diagnostic step was removed after the issue was fixed.

This ensured the final workflow remained clean and did not include unnecessary token inspection.

---

## AWS identity verification

After authentication, the pipeline verifies the AWS identity.

A common command is:

```bash
aws sts get-caller-identity
```

This returns information about the identity currently being used.

It confirms:

- the AWS account;
- the assumed-role session;
- the role used by GitHub Actions.

This is useful because it proves that:

- OIDC authentication succeeded;
- the expected IAM role was assumed;
- the workflow is operating in the intended AWS account.

---

## Why identity verification matters

A workflow may obtain valid AWS credentials but assume the wrong role or target the wrong account.

Identity verification provides an early check before Terraform or Ansible performs further operations.

The pipeline can stop before infrastructure actions if the authentication context is incorrect.

---

## Terraform setup

The workflow installs the required Terraform version.

A typical step is:

```yaml
- name: Set up Terraform
  uses: hashicorp/setup-terraform@v3
```

Terraform must be available before the pipeline can run:

- `terraform init`;
- `terraform fmt`;
- `terraform validate`;
- `terraform plan`;
- `terraform apply`;
- `terraform destroy`.

Pinning or controlling the Terraform version improves consistency between local development and CI/CD.

---

## Terraform working directory

The development environment is located in:

```text
terraform/environments/dev
```

The workflow can either:

- change into that directory;
- use Terraform's `-chdir` option;
- define a workflow working directory.

Example:

```bash
terraform -chdir=terraform/environments/dev init
```

Using the correct working directory ensures Terraform loads:

- the development backend;
- development variables;
- module references;
- provider configuration;
- environment outputs.

---

## Terraform initialization

The workflow initializes Terraform before validation and planning.

Example:

```bash
terraform -chdir=terraform/environments/dev init
```

Initialization performs several tasks:

- downloads providers;
- initializes modules;
- reads backend configuration;
- connects to remote state;
- prepares the working directory.

For this project, the backend is stored in Amazon S3.

---

## Remote-state access

GitHub Actions requires permission to read the Terraform state from the S3 backend.

The workflow uses the temporary OIDC credentials to access the state bucket.

The state allows Terraform to understand which AWS resources are already managed.

Without remote-state access, Terraform may be unable to:

- identify current infrastructure;
- compare desired and current state;
- calculate a correct plan;
- update state after changes.

---

## S3 IAM troubleshooting

During implementation, Terraform required additional S3 read permissions.

The workflow encountered permission errors related to S3 bucket configuration checks.

Required actions included:

```text
s3:GetAccelerateConfiguration
s3:GetReplicationConfiguration
```

These permissions were added to the GitHub Actions IAM role.

The issue was resolved without granting broad administrator access.

This demonstrated a least-privilege troubleshooting approach:

1. run the pipeline;
2. inspect the denied AWS API action;
3. verify why Terraform requires it;
4. add the specific required permission;
5. rerun the pipeline;
6. confirm the stage succeeds.

---

## Terraform formatting

Terraform formatting can be checked using:

```bash
terraform fmt -check -recursive
```

This verifies that Terraform files follow the standard Terraform formatting convention.

Formatting checks improve:

- readability;
- code consistency;
- code review quality;
- repository professionalism.

A future pipeline improvement would make formatting a required validation stage.

---

## Terraform validation

The pipeline runs Terraform validation.

Example:

```bash
terraform -chdir=terraform/environments/dev validate
```

Validation checks:

- Terraform syntax;
- internal references;
- provider configuration structure;
- module input compatibility;
- resource configuration structure.

Validation does not prove that the planned AWS resources will work correctly, but it catches many configuration problems before planning.

---

## Development variable file

The development environment uses:

```text
terraform/environments/dev/dev.tfvars
```

The workflow must explicitly provide the file when required.

Example:

```bash
terraform -chdir=terraform/environments/dev plan \
  -var-file="dev.tfvars"
```

The variable file supplies environment-specific values.

These may include:

- AWS region;
- VPC CIDR range;
- subnet ranges;
- environment name;
- instance type;
- Auto Scaling capacity;
- application port;
- tags.

The file was committed because the values were required by the CI workflow and did not contain secrets.

---

## Terraform plan

The workflow creates a Terraform execution plan.

Example:

```bash
terraform -chdir=terraform/environments/dev plan \
  -var-file="dev.tfvars"
```

Terraform compares:

```text
Configuration code
        +
Remote state
        +
Current AWS environment
        ↓
Proposed infrastructure changes
```

The plan reports whether resources will be:

- added;
- changed;
- replaced;
- destroyed.

---

## Why plan is important

The Terraform plan provides visibility before infrastructure changes occur.

It allows engineers to detect:

- accidental destruction;
- unexpected replacement;
- missing resources;
- configuration drift;
- incorrect variable values;
- unintended scaling changes.

A professional production workflow would normally save and review the plan before applying it.

---

## No-change result

When the live AWS environment already matches the Terraform code, Terraform reports that no changes are required.

This demonstrates idempotent infrastructure management.

A repeated workflow should not recreate unchanged resources.

A no-change result means:

```text
Desired infrastructure
        =
Current infrastructure
```

The pipeline can still continue to Ansible deployment because application or configuration changes may exist even when infrastructure does not change.

---

## Terraform apply stage

The completed platform supports infrastructure provisioning, but the pipeline design should distinguish between plan and apply.

A plan-only stage is safer for automatic execution because it does not immediately change AWS infrastructure.

A production workflow may use:

```text
Pull request
    ↓
Terraform plan
    ↓
Engineer review
    ↓
Approval
    ↓
Terraform apply
```

GitHub environments can be used to require approval before production apply.

---

## Python setup

Ansible requires Python.

The GitHub Actions workflow prepares a Python environment before installing Ansible.

A typical step may use:

```yaml
- name: Set up Python
  uses: actions/setup-python@v5
  with:
    python-version: "3.12"
```

Python is required for:

- Ansible;
- AWS SDK libraries;
- inventory plugins;
- connection plugins;
- supporting automation scripts.

---

## Ansible installation

The workflow installs Ansible into the runner environment.

Example:

```bash
python -m pip install --upgrade pip
python -m pip install ansible-core
```

Additional Python packages may be required depending on the Ansible plugins used.

These can include AWS SDK libraries such as:

```text
boto3
botocore
```

---

## Ansible configuration environment

The workflow exports the Ansible configuration path.

Example:

```bash
export ANSIBLE_CONFIG="$GITHUB_WORKSPACE/ansible/ansible.cfg"
```

The workflow also exports the roles path.

Example:

```bash
export ANSIBLE_ROLES_PATH="$GITHUB_WORKSPACE/ansible/roles"
```

These settings ensure Ansible can locate:

- the correct configuration file;
- inventory plugins;
- roles;
- connection settings;
- callback configuration;
- defaults.

---

## Why `ANSIBLE_CONFIG` was required

Without the correct `ANSIBLE_CONFIG` value, Ansible may use:

- a system configuration;
- a user configuration;
- default settings;
- no project-specific configuration.

This can cause:

- wrong inventory behaviour;
- missing connection settings;
- plugin resolution issues;
- inconsistent local and CI behaviour.

Exporting the path makes the workflow explicit and predictable.

---

## Why `ANSIBLE_ROLES_PATH` was required

The application playbook references project roles.

The GitHub Actions runner must know where those roles are stored.

Without the roles path, Ansible may report that a role cannot be found.

Exporting:

```text
ANSIBLE_ROLES_PATH
```

ensures the runner can load roles from:

```text
ansible/roles
```

---

## Ansible collection installation

The project defines required collections in:

```text
ansible/requirements.yml
```

The workflow installs them using:

```bash
ansible-galaxy collection install \
  -r ansible/requirements.yml
```

Collections provide plugins and modules not included directly in `ansible-core`.

The project uses AWS-related functionality that depends on the required collection being installed.

---

## Missing collection troubleshooting

The workflow initially failed because the required Ansible collection was not available on the GitHub runner.

Local installations do not automatically exist in GitHub Actions.

The fix was to add:

```bash
ansible-galaxy collection install \
  -r ansible/requirements.yml
```

This ensures every runner prepares the same collection dependencies before running the inventory or playbook.

---

## Dependency management principle

CI/CD environments should not depend on software manually installed on one engineer's machine.

Required dependencies should be defined as code.

Examples include:

- Terraform version;
- Python version;
- Python packages;
- Ansible version;
- Ansible collections;
- provider versions;
- module versions.

This improves reproducibility.

---

## Dynamic inventory stage

After preparing Ansible, the workflow runs AWS EC2 dynamic inventory.

Dynamic inventory queries AWS and returns the current EC2 instances that match the configured filters.

A typical command is:

```bash
ansible-inventory \
  -i ansible/inventory/aws_ec2.yml \
  --graph
```

The output shows:

- dynamic host groups;
- discovered instances;
- group relationships;
- inventory structure.

---

## Why dynamic inventory is needed

The application instances are created by an Auto Scaling Group.

They are replaceable and may change over time.

A static inventory could contain:

```text
10.0.10.25
10.0.20.41
```

These addresses may become invalid if instances are replaced.

Dynamic inventory instead asks AWS:

```text
Which running EC2 instances currently belong to this environment?
```

The answer is generated at runtime.

---

## Dynamic inventory filters

The inventory plugin can filter instances using:

- AWS region;
- EC2 running state;
- environment tag;
- project tag;
- application-role tag;
- VPC;
- Auto Scaling Group;
- other EC2 metadata.

This reduces the risk of deploying to unrelated instances.

---

## Dynamic host groups

Ansible can create groups from EC2 tags and metadata.

Example logical groups may include:

```text
environment_dev
application_web
project_enterprise_platform
```

The playbook targets the appropriate group instead of all AWS instances.

This supports controlled deployment boundaries.

---

## Inventory validation

The workflow checks inventory before deployment.

This provides early confirmation that:

- AWS API access works;
- the collection is installed;
- the inventory file is valid;
- the filters match the EC2 instances;
- the expected host group exists;
- application instances are available.

If inventory returns no matching hosts, the deployment should not continue without investigation.

---

## Systems Manager connectivity stage

After discovering the EC2 instances, the workflow verifies that Ansible can connect through AWS Systems Manager.

The EC2 instances are private and do not expose SSH.

The connection path is:

```text
GitHub Actions runner
        ↓
Temporary AWS credentials
        ↓
AWS Systems Manager
        ↓
SSM-managed EC2 instance
        ↓
Ansible execution
```

---

## Ansible ping test

A connectivity check may use:

```bash
ansible all \
  -i ansible/inventory/aws_ec2.yml \
  -m ansible.builtin.ping
```

The Ansible ping module does not send an ICMP network ping.

It verifies that Ansible can:

- connect to the managed host;
- execute Python;
- run an Ansible module;
- return a successful response.

A successful result returns:

```text
pong
```

---

## Requirements for SSM connectivity

The following components must work together:

### EC2 instance requirements

- SSM agent installed;
- SSM agent running;
- IAM instance profile attached;
- required SSM permissions;
- outbound network access;
- correct instance registration.

### GitHub Actions requirements

- AWS role successfully assumed;
- SSM session permissions;
- EC2 discovery permissions;
- required Ansible collection;
- required connection plugin;
- correct inventory variables.

### Network requirements

The EC2 instance must reach Systems Manager services through either:

- NAT Gateway;
- VPC endpoints.

---

## Why SSM is better than public SSH for this project

Using SSM avoids:

- inbound TCP port 22;
- public EC2 IP addresses;
- SSH key-pair management;
- private-key storage in GitHub;
- bastion-host maintenance;
- direct internet-based administrative access.

Access is controlled through IAM and temporary AWS credentials.

---

## Application playbook stage

After inventory and connectivity checks pass, the workflow runs the Ansible application playbook.

A simplified command is:

```bash
ansible-playbook \
  -i ansible/inventory/aws_ec2.yml \
  ansible/playbooks/deploy-application.yml
```

The playbook defines:

- the target host group;
- privilege escalation where required;
- deployment order;
- serial batch size;
- application role;
- pre-deployment checks;
- post-deployment checks.

---

## Ansible application role

The application role contains the tasks required to configure the server and deploy the application.

The role may perform:

- package installation;
- directory creation;
- application-file copying;
- configuration templating;
- ownership management;
- permission management;
- service configuration;
- service enablement;
- service startup;
- restart handling;
- endpoint validation.

Separating these tasks into a role improves:

- reuse;
- readability;
- testing;
- maintenance;
- responsibility separation.

---

## Privilege escalation

Some Linux configuration tasks require elevated privileges.

Ansible can use privilege escalation with:

```yaml
become: true
```

This allows tasks to perform approved administrative actions such as:

- installing packages;
- creating system directories;
- writing service files;
- managing system services.

Privilege escalation should only be enabled where required.

---

## Idempotent deployment

The Ansible role should be idempotent.

This means that after the server reaches the desired state, running the playbook again should not create unnecessary changes.

Example:

```text
First run:
changed=8

Second run with no code changes:
changed=0
```

Idempotency makes repeated CI/CD execution safer and more predictable.

---

## Rolling deployment

The playbook uses a rolling strategy.

A rolling deployment updates a controlled number of application instances at one time.

A playbook can use:

```yaml
serial: 1
```

This updates one instance at a time.

With two application instances, the process becomes:

```text
Instance A remains available
Instance B is updated
Instance B is validated
Instance B returns to service
Instance A is updated
Instance A is validated
Deployment completes
```

The exact order may vary, but the key principle is that not all capacity is changed simultaneously.

---

## Why rolling deployment was used

Updating all application instances at the same time can create complete downtime.

A rolling deployment reduces that risk.

Benefits include:

- controlled change scope;
- continued service from healthy instances;
- easier failure isolation;
- safer restart behaviour;
- compatibility with load balancing;
- foundation for zero-downtime delivery.

---

## Load balancer interaction during deployment

The Application Load Balancer monitors target health.

During a rolling deployment:

1. one instance is updated;
2. the application service may restart;
3. the load balancer health check observes the target;
4. other healthy instances continue receiving traffic;
5. the updated target becomes healthy;
6. deployment proceeds.

A more advanced workflow could explicitly:

- deregister a target;
- wait for connection draining;
- deploy;
- validate;
- re-register the target.

---

## Application validation

The workflow should confirm that the application is functioning after deployment.

Validation may include:

- service status;
- process state;
- listening port;
- HTTP response;
- expected status code;
- expected response body;
- target-group health;
- load-balancer endpoint response.

A simple service validation can check that the service is active.

A stronger validation checks the application endpoint itself.

---

## Ansible play recap

At the end of the playbook, Ansible prints a play recap.

Example:

```text
PLAY RECAP
application-instance-1 : ok=18 changed=4 unreachable=0 failed=0
application-instance-2 : ok=18 changed=3 unreachable=0 failed=0
```

The most important values are:

```text
unreachable=0
failed=0
```

### `unreachable`

This shows whether Ansible failed to connect to a host.

A non-zero value may indicate:

- SSM failure;
- IAM issue;
- instance unavailable;
- network problem;
- inventory problem;
- Python problem.

### `failed`

This shows whether an Ansible task failed.

A non-zero value may indicate:

- package error;
- permission problem;
- invalid template;
- service failure;
- missing file;
- failed validation.

---

## Workflow success criteria

The workflow is successful when:

- repository checkout succeeds;
- OIDC authentication succeeds;
- the correct AWS role is assumed;
- AWS identity verification succeeds;
- Terraform initialization succeeds;
- remote state is accessible;
- Terraform validation succeeds;
- Terraform plan succeeds;
- Python setup succeeds;
- Ansible installs correctly;
- required collections install successfully;
- dynamic inventory finds the EC2 instances;
- SSM connectivity succeeds;
- the application playbook completes;
- no hosts are unreachable;
- no Ansible tasks fail;
- application validation passes.

---

## Workflow failure behaviour

GitHub Actions marks the job as failed when a required command returns a non-zero exit code.

The pipeline should stop when a critical stage fails.

This prevents later stages from running on an invalid foundation.

Examples:

```text
OIDC failure
    ↓
Do not run Terraform

Terraform validation failure
    ↓
Do not run deployment

No inventory hosts
    ↓
Do not run application playbook

SSM connection failure
    ↓
Do not attempt configuration

Application validation failure
    ↓
Mark deployment as failed
```

---

## Pipeline troubleshooting method

A structured troubleshooting method was used throughout the project.

### Step 1: Identify the failed stage

Determine whether the error occurred in:

- checkout;
- authentication;
- Terraform;
- Ansible setup;
- inventory;
- connectivity;
- deployment;
- validation.

### Step 2: Read the exact error

The specific error message often reveals:

- denied AWS API action;
- missing file;
- missing collection;
- incorrect path;
- invalid trust claim;
- unreachable instance;
- failed Ansible task.

### Step 3: Reproduce locally where possible

Commands can be tested locally before rerunning the complete workflow.

### Step 4: Apply the smallest justified fix

Avoid broad permissions or unrelated changes.

### Step 5: Run the workflow again

Confirm whether the failed stage now succeeds.

### Step 6: Remove temporary diagnostics

Temporary debug steps should not remain once the issue is resolved.

---

## OIDC troubleshooting completed

The initial OIDC configuration did not successfully assume the AWS role.

The investigation included:

- checking workflow permissions;
- confirming `id-token: write`;
- inspecting OIDC token claims;
- comparing claims with IAM trust-policy conditions;
- updating the trust policy;
- using repository ID;
- using repository-owner ID;
- testing AWS role assumption;
- verifying with `sts get-caller-identity`;
- removing temporary diagnostics.

The final OIDC stage passed successfully.

---

## Terraform troubleshooting completed

Terraform CI issues included:

- development variable file availability;
- incorrect variable-file handling;
- remote-state access;
- missing S3 IAM actions.

Fixes included:

- committing `dev.tfvars`;
- using `-var-file="dev.tfvars"`;
- confirming backend access;
- adding specific S3 read permissions;
- rerunning Terraform plan.

The final Terraform plan stage passed.

---

## Ansible troubleshooting completed

Ansible CI issues included:

- missing Ansible collections;
- configuration-path resolution;
- role-path resolution;
- dynamic inventory validation;
- Systems Manager connectivity.

Fixes included:

```text
ansible-galaxy collection install -r ansible/requirements.yml
```

and exporting:

```text
ANSIBLE_CONFIG
ANSIBLE_ROLES_PATH
```

The final deployment completed with no unreachable hosts and no failed tasks.

---

## Temporary diagnostic cleanup

Temporary debugging should not become permanent production workflow logic.

After OIDC authentication was fixed, the token-inspection step was removed.

The cleanup was committed with:

```text
Remove temporary OIDC diagnostics
```

The workflow was then rerun to prove that the pipeline still passed without the diagnostic block.

This confirmed that the fix was permanent and not dependent on debugging logic.

---

## Pipeline audit trail

GitHub Actions records:

- workflow name;
- trigger event;
- branch;
- commit;
- actor;
- start time;
- job duration;
- step logs;
- step result;
- final status.

Git records:

- the workflow change;
- the author;
- the commit message;
- the previous version;
- the current version.

Together, these provide a traceable deployment history.

---

## Security controls in the pipeline

The CI/CD workflow includes several security controls.

### No long-lived AWS keys

OIDC provides temporary credentials.

### Restricted IAM trust

Only the approved GitHub identity can assume the role.

### Least-privilege permissions

The role contains the actions required by the pipeline.

### Private EC2 instances

Application servers are not directly exposed to the internet.

### No public SSH

Systems Manager provides management connectivity.

### Version-controlled automation

Terraform, Ansible and workflow definitions are reviewed through Git.

### Temporary runner

GitHub-hosted runners are discarded after job completion.

---

## Secrets management

The workflow should avoid storing secrets directly in YAML files.

Appropriate storage locations may include:

- GitHub Actions secrets;
- GitHub environment secrets;
- AWS Secrets Manager;
- AWS Systems Manager Parameter Store.

Secrets should not be stored in:

- Terraform variable files committed to Git;
- Ansible playbooks;
- shell scripts;
- workflow logs;
- repository documentation;
- screenshots.

OIDC reduces the number of AWS credentials that need to be stored as secrets.

---

## Environment variables

The workflow uses environment variables for reusable paths and configuration.

Examples include:

```text
AWS_REGION
TF_WORKING_DIR
ANSIBLE_CONFIG
ANSIBLE_ROLES_PATH
```

Environment variables reduce repeated hard-coded values.

They also make the workflow easier to maintain.

---

## Working-directory consistency

CI failures frequently occur because commands run from the wrong directory.

The workflow must be explicit about:

- Terraform working directory;
- Ansible configuration path;
- inventory path;
- playbook path;
- roles path;
- requirements file path.

Using paths based on:

```text
$GITHUB_WORKSPACE
```

helps make the locations predictable.

---

## Recommended workflow stage names

Clear stage names make pipeline logs easier to understand.

Recommended names include:

```text
Checkout repository
Configure AWS credentials
Verify AWS identity
Set up Terraform
Terraform init
Terraform format check
Terraform validate
Terraform plan
Set up Python
Install Ansible dependencies
Install Ansible collections
Validate dynamic inventory
Verify SSM connectivity
Deploy application
Validate deployment
```

The engineer should be able to identify the failed responsibility directly from the step name.

---

## Suggested pipeline separation

A mature pipeline could be separated into several jobs.

### Job 1: Validate

```text
Checkout
Terraform format
Terraform validate
Ansible lint
YAML lint
Application tests
```

### Job 2: Plan

```text
OIDC authentication
Terraform init
Terraform plan
Upload plan artifact
```

### Job 3: Deploy

```text
Approval
Terraform apply
Dynamic inventory
SSM connectivity
Ansible deployment
Application validation
```

### Job 4: Report

```text
Publish summary
Notify success or failure
Store evidence
```

Job separation improves clarity and allows approval controls between stages.

---

## Pull-request workflow improvement

A future pull-request workflow could run:

- Terraform formatting;
- Terraform validation;
- Terraform plan;
- Ansible lint;
- YAML lint;
- application tests;
- security scanning.

The pull request would show the proposed result before merge.

After review and merge, the delivery workflow could deploy the approved change.

---

## GitHub environment protection

A production deployment should use a GitHub environment.

Example:

```text
Environment: production
```

The environment can require:

- named reviewers;
- manual approval;
- restricted branches;
- protected secrets;
- deployment history;
- wait timers.

This prevents an ordinary push from automatically changing production without approval.

---

## Terraform plan artifact

A future enhancement would save the Terraform plan as an artifact.

Example:

```bash
terraform plan \
  -var-file="dev.tfvars" \
  -out="tfplan"
```

The saved plan could then be applied using:

```bash
terraform apply "tfplan"
```

This ensures the reviewed plan is the same plan that is applied.

---

## Concurrency control

Multiple workflow runs should not change the same environment simultaneously.

GitHub Actions concurrency can prevent overlapping deployments.

Example concept:

```yaml
concurrency:
  group: platform-dev
  cancel-in-progress: false
```

This reduces the risk of:

- competing Terraform operations;
- overlapping Ansible deployments;
- inconsistent environment changes;
- confusing workflow results.

---

## Terraform state locking

Terraform state locking protects against concurrent state modification.

The exact locking mechanism depends on the Terraform backend and version.

The project remote-state design should ensure that two workflows do not update the same state simultaneously.

GitHub Actions concurrency provides an additional workflow-level safeguard.

---

## Retry behaviour

Some cloud operations take time.

Examples include:

- EC2 startup;
- SSM registration;
- target-group health;
- application-service startup;
- DNS propagation.

A robust workflow should use bounded retries rather than immediate failure or endless waiting.

Example:

```text
Attempt connectivity
    ↓
Wait
    ↓
Retry
    ↓
Stop after defined limit
```

Retries should have:

- a maximum attempt count;
- a delay;
- useful logging;
- a clear failure message.

---

## Deployment timeout

Each workflow job should have a sensible timeout.

A timeout prevents a job from running indefinitely.

Example concept:

```yaml
timeout-minutes: 45
```

The value should allow normal Terraform and deployment operations while still protecting against stuck processes.

---

## Logging approach

Workflow logs should make it easy to identify:

- what command ran;
- which stage is active;
- which environment is targeted;
- which AWS identity is used;
- whether inventory found hosts;
- whether connectivity worked;
- whether deployment changed anything;
- why a task failed.

Logs must not reveal:

- credentials;
- tokens;
- secrets;
- sensitive application values.

---

## GitHub Actions summary

A future improvement could write a concise deployment report to the GitHub Actions job summary.

The summary could include:

```text
Environment: dev
AWS region: eu-west-2
Terraform validation: passed
Terraform plan: passed
EC2 hosts discovered: 2
SSM connectivity: passed
Ansible unreachable: 0
Ansible failed: 0
Deployment result: successful
```

This would provide a quick overview without reading the complete logs.

---

## Notification improvements

The pipeline could send notifications when:

- a deployment succeeds;
- a deployment fails;
- Terraform proposes destruction;
- no EC2 instances are discovered;
- application validation fails;
- production approval is required.

Notifications could integrate with:

- email;
- Slack;
- Microsoft Teams;
- incident-management systems.

---

## Security-scanning improvements

Future CI stages could include:

- Checkov;
- tfsec;
- Trivy;
- secret scanning;
- dependency scanning;
- Ansible lint;
- ShellCheck;
- YAML lint;
- policy-as-code.

These checks would detect issues before deployment.

---

## Terraform linting improvement

Terraform linting can be added using TFLint.

It can detect:

- provider-specific issues;
- deprecated syntax;
- unused declarations;
- invalid configuration patterns;
- naming problems.

A future validation chain could be:

```text
terraform fmt
    ↓
terraform validate
    ↓
tflint
    ↓
checkov
    ↓
terraform plan
```

---

## Ansible linting improvement

The workflow can include:

```bash
ansible-lint
```

This checks playbooks and roles for:

- risky commands;
- non-idempotent patterns;
- naming issues;
- deprecated syntax;
- best-practice violations;
- formatting problems.

The Ansible project should also use:

```bash
yamllint
```

for YAML consistency.

---

## Application testing improvement

Application tests should run before deployment.

These may include:

- unit tests;
- syntax tests;
- dependency checks;
- container tests;
- integration tests;
- endpoint tests.

The pipeline should not deploy an application that has already failed its test stage.

---

## Infrastructure test improvement

Terraform infrastructure can be tested through:

- Terraform validation;
- plan inspection;
- policy checks;
- Terratest;
- post-deployment AWS checks;
- endpoint testing;
- security-group verification;
- target-health verification.

---

## Drift-detection workflow

A scheduled workflow could run Terraform plan without applying changes.

The workflow would detect whether manually changed AWS resources differ from Terraform code.

Example:

```text
Scheduled GitHub Actions run
        ↓
OIDC authentication
        ↓
Terraform init
        ↓
Terraform plan
        ↓
No changes = environment aligned
Changes detected = possible drift
```

This would provide continuous infrastructure assurance.

---

## Cost-control workflow improvement

A future workflow could automatically destroy development resources after a set period.

Possible design:

```text
Deploy development environment
        ↓
Run tests
        ↓
Capture evidence
        ↓
Wait for approved testing window
        ↓
Terraform destroy
        ↓
Verify cleanup
```

This would reduce the risk of leaving billable infrastructure running.

---

## Manual destroy workflow

A protected GitHub Actions workflow could allow an engineer to manually destroy the development environment.

It should include:

- manual trigger;
- environment selection;
- confirmation input;
- OIDC authentication;
- Terraform destroy plan;
- approval;
- Terraform destroy;
- state verification;
- cleanup report.

Production destroy should require much stronger controls.

---

## Current infrastructure cleanup

After successful pipeline testing, the AWS development infrastructure was destroyed.

This stopped ongoing costs from:

- NAT Gateway;
- Application Load Balancer;
- EC2 instances;
- Auto Scaling resources;
- Elastic IP usage;
- database-related resources.

The retained bootstrap components may include:

- remote-state S3 bucket;
- GitHub OIDC provider;
- GitHub Actions IAM role;
- state-locking resources where applicable.

---

## Current pipeline status

The pipeline has successfully completed the full delivery process.

The successful workflow confirmed:

- GitHub push trigger;
- repository checkout;
- OIDC authentication;
- AWS IAM role assumption;
- AWS identity verification;
- Terraform initialization;
- remote-state access;
- Terraform validation;
- Terraform plan;
- development variable-file loading;
- Ansible installation;
- Ansible collection installation;
- Ansible configuration resolution;
- Ansible role resolution;
- AWS EC2 dynamic inventory;
- Systems Manager connectivity;
- rolling application deployment;
- final Ansible validation;
- zero unreachable hosts;
- zero failed tasks.

---

## Business value

The CI/CD workflow provides several business benefits.

### Repeatable delivery

Every deployment follows the same defined process.

### Reduced manual work

Engineers do not need to run a long series of commands manually.

### Improved security

GitHub uses temporary AWS credentials, and EC2 instances do not expose SSH.

### Faster feedback

Validation errors are reported automatically.

### Better traceability

Git commits and workflow logs record the delivery history.

### Reduced configuration drift

Terraform and Ansible reapply the approved desired state.

### Improved recovery

The platform can be recreated from source-controlled code.

### Safer deployment

Rolling deployment reduces the risk of losing all application capacity at once.

---

## Interview explanation

A clear interview explanation is:

> I built a GitHub Actions pipeline that starts when code is pushed to the repository. The workflow checks out the code and authenticates to AWS using GitHub OIDC, which allows it to assume an IAM role with temporary credentials instead of storing permanent AWS keys. It then verifies the AWS identity, initializes the Terraform remote state, validates the configuration and creates a plan using the development variable file. After the infrastructure stage, the workflow installs Ansible and its required collections, loads the project configuration and dynamically discovers the EC2 instances. It verifies connectivity through AWS Systems Manager, runs the application playbook as a rolling deployment and checks the Ansible recap to confirm there are no unreachable hosts or failed tasks.

---

## 30-second interview answer

> A Git push triggers GitHub Actions. GitHub authenticates to AWS through OIDC and receives temporary credentials. Terraform then initializes the remote state, validates the infrastructure and creates a plan. Ansible installs its dependencies, dynamically discovers the EC2 application servers and connects through Systems Manager because the instances are private. It configures the servers, performs a rolling application deployment and validates that the play completed with zero unreachable hosts and zero failed tasks.

---

## One-line workflow

```text
Git Push → GitHub Actions → OIDC → Terraform → Dynamic Inventory → SSM → Ansible → Deploy → Validate → Platform Ready
```

---

## Tool responsibility table

| Tool or service | Pipeline responsibility |
|---|---|
| Git | Records and versions changes. |
| GitHub | Stores the project repository. |
| GitHub Actions | Orchestrates the delivery workflow. |
| GitHub OIDC | Supplies the workflow identity token. |
| AWS IAM | Authorises role assumption and AWS operations. |
| AWS STS | Issues temporary role credentials. |
| Terraform | Validates and manages infrastructure. |
| Amazon S3 | Stores remote Terraform state. |
| Python | Provides the Ansible runtime. |
| Ansible | Configures servers and deploys the application. |
| Ansible Galaxy | Installs required collections. |
| EC2 dynamic inventory | Discovers current application instances. |
| AWS Systems Manager | Connects securely to private EC2 instances. |
| Auto Scaling Group | Maintains application capacity. |
| Application Load Balancer | Routes traffic to healthy instances. |
| Validation checks | Prove whether delivery succeeded. |

---

## Final pipeline memory card

```text
TRIGGER
A developer pushes a change to GitHub.

CHECKOUT
GitHub Actions downloads the repository.

AUTHENTICATE
OIDC allows the workflow to assume an AWS IAM role.

VERIFY
The pipeline confirms the AWS identity.

INITIALIZE
Terraform connects to providers, modules and remote state.

VALIDATE
Terraform checks the infrastructure configuration.

PLAN
Terraform calculates the proposed AWS changes.

PREPARE
Python, Ansible and required collections are installed.

DISCOVER
Dynamic inventory finds the current EC2 application instances.

CONNECT
Systems Manager provides secure private-instance access.

DEPLOY
Ansible configures the servers and updates the application.

VALIDATE
The pipeline confirms unreachable=0 and failed=0.

REPORT
GitHub Actions records the successful result.
```

---

## Final summary

The CI/CD workflow joins source control, secure cloud authentication, Infrastructure as Code, configuration management and application deployment into one automated process.

GitHub Actions provides the orchestration layer.

GitHub OIDC and AWS IAM provide temporary and controlled authentication.

Terraform validates and manages the AWS infrastructure.

Ansible discovers the current EC2 instances and connects through AWS Systems Manager.

The application is deployed through a controlled rolling strategy.

Validation checks confirm that the workflow completed without unreachable hosts or failed tasks.

The result is a secure, repeatable, auditable and interview-ready AWS platform delivery pipeline.
