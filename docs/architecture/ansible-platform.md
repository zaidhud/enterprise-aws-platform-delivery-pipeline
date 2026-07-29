# Ansible Platform and Deployment Design

## Overview

Ansible provides the configuration management and application deployment layer for the Enterprise AWS Platform Delivery Pipeline.

Terraform creates the AWS infrastructure.

Ansible then connects to the EC2 application instances, configures the Linux operating system, installs the required software, deploys the application and validates that the service is working correctly.

The platform separates infrastructure provisioning from server configuration:

```text
Terraform
    ↓
Creates AWS infrastructure

Ansible
    ↓
Configures Linux and deploys the application
```

This separation gives each tool a clear responsibility.

Terraform manages AWS resources.

Ansible manages the operating-system and application state running on those resources.

---

## Platform Objective

The objective of the Ansible layer is to replace manual server configuration with repeatable automation.

Without configuration management, an engineer might:

1. connect to each server;
2. install packages manually;
3. create directories;
4. copy application files;
5. configure services;
6. restart processes;
7. test the application;
8. repeat the same work on every server.

This approach is slow, difficult to audit and vulnerable to human error.

Ansible converts those steps into version-controlled automation.

The desired result is:

- repeatable configuration;
- consistent servers;
- reduced configuration drift;
- automated deployments;
- auditable changes;
- safer service management;
- reusable automation;
- predictable recovery;
- minimal manual access.

---

## Why Ansible Was Selected

Ansible was selected because it is well suited to Linux configuration management and application deployment.

Its key advantages include:

- agentless architecture;
- human-readable YAML;
- idempotent modules;
- reusable roles;
- dynamic inventory;
- strong AWS integration;
- privilege escalation support;
- Jinja2 templating;
- clear execution reporting;
- straightforward CI/CD integration.

Ansible also allows infrastructure engineers to describe the required system state rather than writing large procedural scripts.

---

## Configuration as Code

The Linux configuration is stored in Git alongside the Terraform and GitHub Actions workflow.

The repository therefore becomes the source of truth for both infrastructure and configuration.

The approved change process is:

```text
Edit Ansible code
        ↓
Review the change
        ↓
Commit to Git
        ↓
Push to GitHub
        ↓
GitHub Actions executes
        ↓
Servers reach the desired state
```

Engineers should not make undocumented configuration changes directly on the EC2 instances.

Any required change should be represented in Ansible so it can be reproduced.

---

## Separation of Responsibilities

The platform uses a clear boundary between Terraform and Ansible.

### Terraform responsibilities

Terraform manages resources such as:

- VPC;
- subnets;
- route tables;
- Internet Gateway;
- NAT Gateway;
- Elastic IP;
- security groups;
- IAM roles;
- IAM policies;
- instance profiles;
- launch templates;
- Auto Scaling Groups;
- Application Load Balancer;
- target groups;
- listeners;
- database subnet groups;
- resource tags.

### Ansible responsibilities

Ansible manages tasks such as:

- package installation;
- package updates;
- directory creation;
- file permissions;
- configuration-file deployment;
- application deployment;
- service management;
- operating-system validation;
- application validation;
- rolling deployments.

Terraform should not be used to manage detailed Linux configuration.

Ansible should not be used to create the core AWS network and compute architecture.

---

## End-to-End Deployment Flow

The complete platform workflow is:

```text
Developer pushes code
        ↓
GitHub Actions starts
        ↓
GitHub authenticates to AWS using OIDC
        ↓
Terraform initializes remote state
        ↓
Terraform validates the infrastructure
        ↓
Terraform produces a plan
        ↓
Ansible collections are installed
        ↓
Dynamic inventory queries AWS
        ↓
Running EC2 instances are discovered
        ↓
SSM connectivity is validated
        ↓
Ansible performs a rolling deployment
        ↓
Services and application health are checked
        ↓
Workflow reports the result
```

---

## Desired-State Configuration

Ansible follows a desired-state model.

The automation describes what the server should look like.

For example:

```text
Required state:

Application directory exists
Application files are present
Required packages are installed
Service is enabled
Service is running
Application health check succeeds
```

Ansible compares the current server against that desired state and applies only the required changes.

---

## Idempotency

Idempotency means that repeatedly running the same automation produces the same final state.

A task should make a change only when the current state differs from the desired state.

Example:

```text
First run:
Package not installed
Result: changed

Second run:
Package already installed
Result: ok
```

An idempotent playbook can run repeatedly without continually modifying correctly configured servers.

---

## Why Idempotency Matters

Idempotency improves:

- reliability;
- repeatability;
- troubleshooting;
- deployment safety;
- configuration-drift correction;
- CI/CD predictability.

Without idempotency, repeated deployments could:

- reinstall packages;
- replace unchanged files;
- restart healthy services;
- change permissions unnecessarily;
- cause avoidable downtime.

---

## Agentless Architecture

Ansible is normally described as agentless because it does not require a permanent Ansible agent on each managed host.

The control environment executes Ansible when configuration or deployment work is required.

Traditional Ansible commonly uses SSH.

This platform instead uses AWS Systems Manager.

The EC2 instances still require the AWS Systems Manager Agent, but they do not require a dedicated Ansible agent.

---

## Traditional SSH Model

A traditional Ansible architecture may use:

```text
Ansible control node
        ↓
SSH connection
        ↓
Managed Linux host
```

This generally requires:

- port 22 access;
- SSH private keys;
- user-account management;
- network reachability;
- possible bastion-host infrastructure.

---

## Systems Manager Model

This platform uses AWS Systems Manager Session Manager rather than direct SSH.

```text
GitHub Actions runner
        ↓
AWS temporary credentials
        ↓
Ansible SSM connection plugin
        ↓
AWS Systems Manager
        ↓
SSM Agent on EC2
        ↓
Linux operating system
```

No inbound SSH access is required.

---

## Why Systems Manager Was Chosen

Systems Manager provides several advantages:

- no public SSH port;
- no inbound port 22 rule;
- no SSH private-key distribution;
- no bastion host;
- IAM-controlled access;
- temporary AWS credentials;
- encrypted AWS-managed communication;
- support for private subnets;
- improved auditability;
- reduced attack surface.

This makes Systems Manager a strong fit for a private EC2 architecture.

---

## Private Instance Connectivity

The application instances run in private subnets.

They do not require public IP addresses.

They communicate outbound through the platform network where required.

The GitHub-hosted runner does not establish a direct TCP connection to the instances.

Instead, the runner communicates with AWS Systems Manager.

Systems Manager then communicates with the managed EC2 instance through the installed SSM Agent.

---

## IAM Requirements for SSM

The application instances require an IAM role that allows them to operate as Systems Manager managed nodes.

The instance role is attached through an IAM instance profile.

The EC2 launch template attaches that instance profile to every application instance.

The relationship is:

```text
EC2 instance
    ↓
IAM instance profile
    ↓
EC2 application role
    ↓
Systems Manager permissions
```

The GitHub Actions deployment role also requires the AWS permissions needed to:

- discover EC2 instances;
- inspect instance metadata;
- start and manage SSM sessions;
- use the required S3 channel for the Ansible SSM connection plugin;
- query Systems Manager managed-instance information.

Permissions should remain limited to the resources and actions required by the deployment.

---

## Dynamic Infrastructure

The application capacity is managed by an Auto Scaling Group.

Instances may be:

- created;
- terminated;
- replaced;
- scaled;
- recreated after failure.

This means instance identities are not permanent.

A configuration that depends on manually maintained IP addresses would quickly become outdated.

---

## Dynamic Inventory

Ansible dynamic inventory solves this problem by querying AWS during each workflow run.

The inventory asks AWS which EC2 instances currently match the required filters.

The sequence is:

```text
Terraform creates EC2 instances
        ↓
Terraform applies identifying tags
        ↓
AWS stores current instance metadata
        ↓
Ansible inventory plugin queries EC2
        ↓
Matching running instances are returned
        ↓
Playbook targets the discovered hosts
```

---

## Why Static Inventory Was Avoided

A static inventory might contain:

```ini
[application]
10.0.11.24
10.0.12.31
```

If the Auto Scaling Group replaces either instance, those addresses may no longer be valid.

The static inventory would then contain stale infrastructure information.

Dynamic inventory avoids this maintenance burden.

---

## Tag-Based Discovery

Terraform applies tags to the application instances.

The dynamic inventory uses those tags to select the correct hosts.

Typical filters may include:

```text
Environment = dev
Role = application
ManagedBy = terraform
```

The exact tag names must match the Terraform implementation.

Tag-based discovery prevents the playbook from targeting unrelated EC2 instances in the AWS account.

---

## Loose Coupling Between Terraform and Ansible

Terraform and Ansible integrate through AWS metadata rather than a manually generated host file.

```text
Terraform
    ↓
Creates and tags instances

AWS
    ↓
Stores current infrastructure metadata

Ansible
    ↓
Discovers matching instances
```

This is a loosely coupled design.

Terraform does not need to generate and maintain a static Ansible inventory.

Ansible does not need hard-coded IP addresses from Terraform outputs.

---

## Ansible Project Structure

The Ansible implementation is stored under:

```text
ansible/
```

A typical project structure is:

```text
ansible/
├── ansible.cfg
├── collections/
│   └── requirements.yml
├── inventories/
│   └── dev/
│       └── aws_ec2.yml
├── playbooks/
│   ├── deploy.yml
│   └── validate.yml
├── roles/
│   ├── common/
│   ├── application/
│   └── validation/
├── group_vars/
└── host_vars/
```

The exact filenames should reflect the repository implementation.

---

## Purpose of `ansible.cfg`

The project-level Ansible configuration file defines consistent execution behaviour.

It may control:

- inventory location;
- roles path;
- collections path;
- host-key checking;
- connection timeout;
- callback output;
- retry-file generation;
- Python interpreter discovery;
- privilege escalation;
- connection plugin behaviour.

Keeping this file in the repository means local and CI executions can use the same configuration.

---

## `ANSIBLE_CONFIG`

GitHub Actions explicitly identifies the project configuration file using:

```bash
export ANSIBLE_CONFIG=ansible/ansible.cfg
```

This prevents the workflow from accidentally using:

- a runner default;
- a user-level configuration;
- a system-wide configuration;
- a file from the wrong working directory.

The active configuration can be checked with:

```bash
ansible-config dump --only-changed
```

---

## `ANSIBLE_ROLES_PATH`

The pipeline also identifies the project roles directory.

Example:

```bash
export ANSIBLE_ROLES_PATH=ansible/roles
```

This ensures Ansible can locate the repository's roles regardless of the workflow working directory.

---

## Ansible Collections

Collections package Ansible modules, plugins, roles and supporting content.

The platform requires AWS-related collections for functionality such as:

- EC2 dynamic inventory;
- AWS modules;
- Systems Manager connection support.

Commonly required collections include:

```text
amazon.aws
community.aws
community.general
```

Only the collections actually used by the project should be installed.

---

## Collection Requirements File

Required collections should be defined in a version-controlled file such as:

```text
ansible/collections/requirements.yml
```

Example structure:

```yaml
---
collections:
  - name: amazon.aws
  - name: community.aws
  - name: community.general
```

For stronger reproducibility, production implementations should pin tested versions.

---

## Installing Collections

The pipeline installs the requirements using:

```bash
ansible-galaxy collection install \
  -r ansible/collections/requirements.yml
```

This is required because GitHub-hosted runners are temporary.

Each workflow begins in a clean environment and cannot rely on packages installed during an earlier run.

---

## Missing Collection Failure

One of the practical issues encountered during the project was a missing Ansible collection.

Symptoms can include errors such as:

```text
Unable to load inventory plugin
```

or:

```text
Couldn't resolve module or action
```

The correct troubleshooting process is:

1. identify the fully qualified plugin or module name;
2. identify which collection provides it;
3. add the collection to `requirements.yml`;
4. install the requirements in GitHub Actions;
5. confirm installation with `ansible-galaxy collection list`;
6. rerun the inventory or playbook command.

---

## Fully Qualified Collection Names

Using fully qualified collection names makes module ownership explicit.

Example:

```yaml
amazon.aws.aws_ec2
```

or:

```yaml
ansible.builtin.package
```

This improves clarity and reduces ambiguity when different collections provide similarly named content.

---

## Inventory Plugin Configuration

The AWS EC2 dynamic inventory configuration is stored in YAML.

A conceptual example is:

```yaml
---
plugin: amazon.aws.aws_ec2

regions:
  - eu-west-2

filters:
  instance-state-name: running
  tag:Environment: dev
  tag:Role: application
```

The repository's real filters should remain aligned with the Terraform tags.

---

## Inventory Security Boundary

Inventory filters are part of the deployment safety model.

A broad query could accidentally discover unrelated infrastructure.

For this reason, filters should be specific enough to identify:

- the project;
- the environment;
- the server role;
- the required instance state.

Example logical selection:

```text
Project matches
AND
Environment equals dev
AND
Role equals application
AND
Instance state equals running
```

---

## Inventory Validation

Before running a deployment, the inventory should be tested independently.

Useful commands include:

```bash
ansible-inventory \
  -i ansible/inventories/dev/aws_ec2.yml \
  --graph
```

and:

```bash
ansible-inventory \
  -i ansible/inventories/dev/aws_ec2.yml \
  --list
```

These commands show which hosts and groups Ansible discovered.

---

## Empty Inventory Troubleshooting

If no hosts are discovered, check:

1. AWS credentials are valid;
2. the correct AWS account is being used;
3. the inventory region is `eu-west-2`;
4. the EC2 instances are running;
5. the required tags exist;
6. the filter values match exactly;
7. the GitHub role has `ec2:DescribeInstances`;
8. the AWS collection is installed;
9. the inventory plugin name is correct;
10. the workflow is using the intended inventory file.

---

## Hostnames in Dynamic Inventory

Dynamic inventory can compose Ansible hostnames from AWS attributes.

Possible sources include:

- instance ID;
- private IP address;
- private DNS name;
- Name tag.

Using instance IDs can be useful with the SSM connection plugin because SSM manages instances by their AWS instance identifiers.

The chosen hostname strategy must be compatible with the connection plugin.

---

## Inventory Groups

Dynamic inventory can organise instances into groups based on AWS metadata.

Example groups may include:

```text
application
dev
running
```

Playbooks should target meaningful groups rather than individual hosts.

This allows the Auto Scaling Group to change capacity without requiring playbook edits.

---

## Playbooks

Playbooks define which hosts are targeted and which roles or tasks should execute.

A deployment playbook may coordinate:

- connectivity validation;
- Linux preparation;
- application configuration;
- application deployment;
- service management;
- health validation.

Playbooks should remain focused on orchestration.

Detailed implementation should live inside reusable roles.

---

## Example Playbook Structure

A conceptual deployment playbook is:

```yaml
---
- name: Deploy application servers
  hosts: application
  become: true
  gather_facts: true
  serial: 1

  roles:
    - common
    - application
    - validation
```

The exact role names should match the repository.

---

## Roles

Roles organise related automation into reusable components.

A role usually contains:

```text
roles/application/
├── defaults/
│   └── main.yml
├── files/
├── handlers/
│   └── main.yml
├── tasks/
│   └── main.yml
├── templates/
├── vars/
│   └── main.yml
└── README.md
```

Each role should have one clear responsibility.

---

## Role Responsibilities

A role should group logically related configuration.

Examples include:

### Common role

- base packages;
- directory preparation;
- time configuration;
- common utilities;
- baseline operating-system settings.

### Application role

- application user;
- deployment directories;
- application files;
- runtime dependencies;
- service configuration;
- application service state.

### Validation role

- service status;
- port checks;
- HTTP health checks;
- deployment assertions.

The project should avoid creating roles that combine unrelated responsibilities.

---

## Why Roles Matter

Roles provide:

- separation of concerns;
- reuse;
- cleaner playbooks;
- easier testing;
- easier troubleshooting;
- predictable structure;
- more focused code review.

Without roles, one large playbook can become difficult to understand and maintain.

---

## Tasks

Tasks describe individual desired-state operations.

Examples include:

- ensure a package is installed;
- ensure a directory exists;
- ensure a template is deployed;
- ensure a service is enabled;
- ensure a health endpoint responds.

Each task should have a clear descriptive name.

Good task names make pipeline logs easier to interpret.

---

## Modules Over Shell Commands

Ansible modules should be used instead of shell commands whenever a suitable module exists.

Preferred examples include:

```text
ansible.builtin.package
ansible.builtin.file
ansible.builtin.copy
ansible.builtin.template
ansible.builtin.service
ansible.builtin.systemd
ansible.builtin.user
ansible.builtin.uri
ansible.builtin.assert
```

Modules usually provide:

- idempotency;
- structured results;
- predictable error handling;
- clearer intent;
- cross-platform abstraction.

---

## Shell and Command Modules

The `shell` and `command` modules should be used only when required.

A raw command may run every time unless the task includes controls such as:

- `creates`;
- `removes`;
- `changed_when`;
- `failed_when`;
- explicit state checks.

Uncontrolled shell tasks are a common source of non-idempotent automation.

---

## Package Management

Package installation should use a package-management module.

Conceptual example:

```yaml
- name: Ensure required packages are installed
  ansible.builtin.package:
    name:
      - nginx
      - curl
    state: present
```

On a correctly configured server, a later run should report `ok` rather than reinstalling the packages.

---

## Directory Management

Directories should be managed declaratively.

Example:

```yaml
- name: Ensure application directory exists
  ansible.builtin.file:
    path: /opt/platform-application
    state: directory
    owner: app
    group: app
    mode: "0755"
```

This task controls:

- existence;
- ownership;
- group;
- permissions.

---

## File Deployment

Static files can be deployed with:

```text
ansible.builtin.copy
```

Dynamic configuration files should use:

```text
ansible.builtin.template
```

The module compares the source and destination and reports a change only when the content differs.

---

## Jinja2 Templates

Ansible uses Jinja2 to generate configuration files from variables.

A template may contain:

```jinja2
server {
    listen {{ application_port }};
    server_name {{ server_name }};

    location / {
        proxy_pass http://127.0.0.1:{{ backend_port }};
    }
}
```

The same template can be used across multiple environments by supplying different values.

---

## Why Templates Are Valuable

Without templates, a team might maintain:

```text
nginx-dev.conf
nginx-staging.conf
nginx-production.conf
```

These files would likely contain mostly duplicated content.

A template centralises the common structure and varies only the required values.

This reduces configuration duplication and drift.

---

## Variables

Variables make roles and playbooks reusable.

Examples include:

- project name;
- environment;
- application port;
- service name;
- application path;
- package list;
- health-check URL;
- deployment user.

Hard-coded values should be avoided when the value genuinely differs by environment or use case.

---

## Variable Sources

Common variable sources include:

- role defaults;
- inventory variables;
- group variables;
- host variables;
- play variables;
- role variables;
- command-line extra variables.

Ansible applies a defined precedence order.

Higher-precedence values override lower-precedence values.

---

## Role Defaults

Role defaults are stored in:

```text
roles/<role>/defaults/main.yml
```

They provide configurable fallback values.

Example:

```yaml
application_port: 8080
application_service_name: platform-app
```

Defaults are the easiest role values to override.

---

## Role Variables

Role variables are stored in:

```text
roles/<role>/vars/main.yml
```

They have higher precedence than defaults.

They should be used for implementation details that should not normally be changed by the role consumer.

Overusing role variables can make a role difficult to customise.

---

## Group Variables

Group variables apply to all hosts in a matching inventory group.

Example structure:

```text
ansible/group_vars/
├── all.yml
└── application.yml
```

They are useful for configuration shared across all application instances.

---

## Host Variables

Host variables apply to one host.

They should be used sparingly in an Auto Scaling environment because individual hosts are replaceable.

A platform that requires extensive host-specific values may be drifting away from consistent, replaceable infrastructure.

---

## Variable Precedence Troubleshooting

If Ansible uses an unexpected value:

1. run the playbook with increased verbosity;
2. inspect role defaults;
3. inspect role variables;
4. inspect `group_vars`;
5. inspect `host_vars`;
6. inspect playbook variables;
7. check GitHub Actions extra variables;
8. use the `debug` module temporarily to display the resolved non-sensitive value.

Secrets must not be printed into workflow logs.

---

## Facts

Ansible can gather system facts before running tasks.

Facts can include:

- operating system;
- distribution;
- architecture;
- interfaces;
- IP addresses;
- memory;
- processor details;
- hostname;
- date and time.

Playbooks can use facts to make conditional decisions.

---

## Fact Gathering

A playbook can enable fact gathering with:

```yaml
gather_facts: true
```

This is useful when tasks depend on operating-system information.

Fact gathering has an execution cost.

If the playbook does not use facts, it may be disabled to improve speed.

---

## Conditional Execution

Tasks can use conditions.

Example:

```yaml
when: ansible_os_family == "Debian"
```

Conditions allow one role to support different operating systems or deployment states.

Conditions should remain understandable and should not turn a simple role into a large collection of hidden branches.

---

## Registered Results

Task output can be stored with `register`.

Conceptual example:

```yaml
- name: Check application health
  ansible.builtin.uri:
    url: http://127.0.0.1:8080/health
    status_code: 200
  register: health_result
```

The result can then be used by later tasks or assertions.

---

## Assertions

Assertions allow Ansible to stop when an expected condition is not met.

Example:

```yaml
- name: Confirm application health
  ansible.builtin.assert:
    that:
      - health_result.status == 200
```

Assertions convert validation expectations into automated deployment controls.

---

## Privilege Escalation

Administrative Linux tasks often require root permissions.

The playbook uses privilege escalation rather than direct root login.

Example:

```yaml
become: true
```

This allows Ansible to run privileged tasks through the operating system's supported escalation mechanism.

---

## Why Direct Root Login Is Avoided

Direct root access:

- reduces accountability;
- increases risk;
- weakens user-level auditing;
- encourages broad privilege use.

Privilege escalation provides a clearer and more controlled approach.

---

## Handlers

Handlers are tasks that execute only when notified by a changed task.

A common use is restarting or reloading a service after its configuration changes.

Conceptual task:

```yaml
- name: Deploy application service configuration
  ansible.builtin.template:
    src: application.service.j2
    dest: /etc/systemd/system/platform-app.service
  notify:
    - Reload systemd
    - Restart application
```

---

## Handler Example

```yaml
---
- name: Reload systemd
  ansible.builtin.systemd:
    daemon_reload: true

- name: Restart application
  ansible.builtin.service:
    name: platform-app
    state: restarted
```

The handlers run only when the notifying task reports a change.

---

## Why Handlers Improve Deployments

Without handlers, a service might restart during every playbook run.

Handlers reduce unnecessary disruption by restarting the service only when required.

They improve:

- idempotency;
- efficiency;
- availability;
- clarity;
- operational safety.

---

## Service Management

Services should be managed with the appropriate module.

Example desired state:

```yaml
- name: Ensure application service is enabled and running
  ansible.builtin.service:
    name: platform-app
    enabled: true
    state: started
```

A service should not be restarted unless a deployment or configuration change requires it.

---

## Rolling Deployment Strategy

The application is deployed across multiple instances using a rolling approach.

Rather than changing every server at once, Ansible processes a limited number of hosts at a time.

The playbook uses a setting such as:

```yaml
serial: 1
```

This means one application instance is processed before the next begins.

---

## Rolling Deployment Flow

```text
Instance 1 selected
        ↓
Configuration applied
        ↓
Application deployed
        ↓
Service validated
        ↓
Instance 1 succeeds
        ↓
Instance 2 selected
        ↓
Process repeats
```

This reduces the number of simultaneously affected instances.

---

## Why Rolling Deployments Matter

Updating every instance at once can create a large failure domain.

Example:

```text
Deploy broken configuration to all instances
        ↓
Every target becomes unhealthy
        ↓
Application outage
```

A rolling strategy limits the blast radius and allows healthy instances to continue serving traffic.

---

## Interaction with the Load Balancer

The Application Load Balancer sends traffic to healthy registered targets.

During a rolling deployment:

- one target may be changing;
- other targets can remain available;
- target health checks help identify unhealthy instances;
- the deployment validates the updated host before moving on.

A mature production design may explicitly deregister and reregister targets during deployment.

The current project demonstrates the rolling-deployment principle without claiming a complete production-grade blue/green system.

---

## Failure Behaviour

If one host fails during a serial deployment, the play should stop or fail according to the configured error controls.

Conceptual result:

```text
Host 1: success
Host 2: failure
Host 3: not changed
```

This is preferable to applying a known-broken deployment to every server.

---

## `max_fail_percentage`

Ansible can control the acceptable failure threshold.

Example concept:

```yaml
max_fail_percentage: 0
```

For critical deployment stages, even one failed host may be unacceptable.

The correct value depends on environment size and service requirements.

---

## Blocks, Rescue and Always

Ansible supports structured error handling with:

- `block`;
- `rescue`;
- `always`.

Conceptual example:

```yaml
- block:
    - name: Deploy application
      ...

    - name: Validate application
      ...

  rescue:
    - name: Collect failure diagnostics
      ...

  always:
    - name: Remove temporary deployment files
      ...
```

---

## Rescue Tasks

Rescue tasks may be used to:

- collect service logs;
- show failed validation results;
- restore a previous file;
- stop further deployment;
- report useful diagnostics.

A rescue block should not hide the original failure.

The workflow must still make the deployment outcome clear.

---

## Always Tasks

Always tasks execute whether the main block succeeds or fails.

Typical uses include:

- cleanup;
- temporary file removal;
- diagnostic reporting;
- closing deployment state;
- restoring temporary settings.

---

## Deployment Validation

A deployment is not complete merely because files were copied successfully.

The platform validates the deployed system.

Validation may include:

- Ansible connectivity;
- package state;
- service state;
- listening port;
- local HTTP response;
- health endpoint;
- load-balancer target health;
- expected application content.

---

## Connectivity Validation

Before configuration begins, Ansible verifies that it can execute a basic module on the discovered instances.

Example:

```bash
ansible \
  -i ansible/inventories/dev/aws_ec2.yml \
  application \
  -m ansible.builtin.ping
```

The Ansible ping module does not send an ICMP network ping.

It validates that Ansible can connect and execute Python-based module code on the managed host.

---

## SSM Connectivity Validation

A failed Ansible ping can indicate:

- missing SSM Agent;
- SSM Agent not running;
- missing EC2 instance permissions;
- missing GitHub deployment permissions;
- incorrect connection plugin settings;
- incorrect instance identifier;
- missing S3 connection bucket permissions;
- no outbound AWS service access;
- Python unavailable on the managed host.

Connectivity should be solved before debugging application roles.

---

## Service Validation

The service manager can be queried to confirm the application service is active.

Example approaches include:

- `service_facts`;
- `systemctl is-active`;
- Ansible service modules;
- explicit status assertions.

A task should fail if the expected service is not running.

---

## HTTP Validation

The `uri` module can validate an application endpoint.

Conceptual example:

```yaml
- name: Validate application health endpoint
  ansible.builtin.uri:
    url: http://127.0.0.1:8080/health
    status_code: 200
    return_content: true
```

This tests the application from inside the instance.

---

## External Validation

Internal validation confirms that the application works locally.

External validation should also test the load-balancer endpoint.

Conceptual sequence:

```text
Local application health
        ↓
Target group health
        ↓
ALB endpoint response
```

This verifies the complete traffic path.

---

## Retry Logic

Services may require time to start.

Validation should use controlled retries rather than one immediate check.

Conceptual example:

```yaml
retries: 10
delay: 5
until: health_result.status == 200
```

Retries should have a defined limit so a failed deployment does not wait indefinitely.

---

## Deployment Evidence

Useful CI/CD evidence includes:

- inventory output;
- SSM ping results;
- play recap;
- changed-task count;
- health-check result;
- external endpoint result;
- workflow status.

Logs should prove that the process worked without exposing sensitive values.

---

## Play Recap

Ansible ends a play with a recap similar to:

```text
ok
changed
unreachable
failed
skipped
rescued
ignored
```

Important interpretation:

- `ok`: task succeeded without changing the host;
- `changed`: task modified the host;
- `unreachable`: Ansible could not connect;
- `failed`: task executed but failed;
- `skipped`: condition prevented execution;
- `rescued`: failure was handled by a rescue block;
- `ignored`: failure occurred but was explicitly ignored.

---

## Idempotency Validation

The platform should be tested by running the same playbook twice.

Expected behaviour:

```text
First run:
Changes applied

Second run:
Little or no change
```

Some tasks may legitimately report changes on every run, but each should have a clear reason.

Repeated unexpected changes indicate an idempotency problem.

---

## Common Causes of Non-Idempotency

Common causes include:

- shell commands without state checks;
- timestamps written into managed files;
- templates containing changing values;
- unconditional service restarts;
- downloaded content without checksums;
- file permissions being repeatedly altered;
- tasks with incorrect `changed_when`;
- generated random values.

Each repeated change should be investigated.

---

## GitHub Actions Integration

Ansible runs from GitHub Actions after AWS authentication and Terraform stages.

The workflow prepares the runner by:

1. checking out the repository;
2. configuring AWS OIDC credentials;
3. verifying AWS identity;
4. installing Python;
5. installing Ansible;
6. installing required collections;
7. exporting Ansible environment settings;
8. validating dynamic inventory;
9. testing SSM connectivity;
10. running the deployment playbook;
11. validating the application.

---

## Temporary Runner Environment

GitHub-hosted runners are temporary.

Each job starts with a fresh environment.

The workflow must therefore install every required dependency during the job or use a predefined execution environment.

The pipeline must not assume that:

- Ansible collections already exist;
- the Session Manager plugin is already available;
- Python packages from a previous run remain installed;
- local developer configuration is present.

---

## OIDC Authentication

GitHub Actions authenticates to AWS through OpenID Connect.

The workflow does not store long-lived AWS access keys.

The sequence is:

```text
GitHub workflow
        ↓
OIDC identity token
        ↓
AWS validates trust-policy claims
        ↓
GitHub deployment role is assumed
        ↓
Temporary AWS credentials are issued
        ↓
Ansible and Terraform use those credentials
```

---

## Shared AWS Credentials

Terraform, dynamic inventory and the SSM connection plugin use the temporary credentials made available to the GitHub Actions runner.

This provides a consistent authentication model across the pipeline.

No credentials are embedded in:

- playbooks;
- inventory files;
- Terraform files;
- repository secrets as permanent access keys.

---

## IAM Trust Policy

The GitHub Actions role trust policy restricts who may assume the role.

The project uses immutable GitHub OIDC claims to scope access.

Trust restrictions should include:

- expected GitHub organisation or account;
- expected repository;
- expected branch or environment;
- expected audience.

A broad trust policy would allow unintended repositories or workflows to request the role.

---

## Security Principles

The Ansible platform follows these security principles:

- no public SSH access;
- no long-lived AWS access keys;
- temporary OIDC credentials;
- IAM least privilege;
- private EC2 instances;
- controlled inventory filters;
- privilege escalation only when required;
- no secrets committed to Git;
- auditable workflow execution;
- version-controlled configuration.

---

## Secrets Management

Sensitive data should not be stored in plain text inside:

- playbooks;
- templates;
- variable files;
- workflow YAML;
- repository history.

Production options include:

- AWS Secrets Manager;
- AWS Systems Manager Parameter Store;
- Ansible Vault;
- GitHub environment secrets;
- short-lived identity-based access.

The preferred method depends on the system and secret lifecycle.

---

## Ansible Vault

Ansible Vault can encrypt sensitive Ansible data.

It may be suitable for encrypted variable files.

However, the vault password or identity must still be handled securely.

For AWS-native workloads, Secrets Manager or Parameter Store may provide better runtime integration and rotation.

---

## Logging and Sensitive Values

Secrets should not be printed in GitHub Actions logs.

Tasks that handle sensitive values can use:

```yaml
no_log: true
```

This must be applied carefully because it also hides useful troubleshooting information.

The goal is to protect sensitive content without making the entire deployment impossible to diagnose.

---

## Least Privilege

The GitHub deployment role should receive only the permissions required for:

- EC2 discovery;
- SSM connectivity;
- required S3 session operations;
- application-deployment actions;
- validation.

The EC2 instance role should receive only the permissions required by the instance and application.

Broad administrator permissions should not be used as a permanent troubleshooting shortcut.

---

## Real Troubleshooting: Missing Collections

### Symptom

Ansible could not load the required AWS inventory or connection plugin.

### Cause

The GitHub runner did not have the relevant Ansible collection installed.

### Resolution

The workflow was updated to install the required Galaxy collections before inventory and playbook execution.

### Lesson

A CI runner is disposable.

All runtime dependencies must be declared and installed explicitly.

---

## Real Troubleshooting: Inventory Finds No Hosts

### Symptom

The dynamic inventory command completed but returned no application instances.

### Possible causes

- wrong region;
- incorrect tag key;
- incorrect tag value;
- instances not running;
- wrong AWS account;
- missing EC2 describe permissions;
- incorrect inventory file path;
- AWS collection not installed.

### Resolution method

1. verify AWS identity;
2. query EC2 directly with the AWS CLI;
3. inspect instance tags;
4. compare exact tag values;
5. test `ansible-inventory --graph`;
6. increase Ansible verbosity;
7. correct the filter or permission.

### Lesson

Inventory debugging should be separated from playbook debugging.

---

## Real Troubleshooting: SSM Connection Failure

### Symptom

Instances appeared in inventory but Ansible could not execute modules.

### Possible causes

- instance not registered with Systems Manager;
- SSM Agent unavailable;
- instance profile missing;
- managed policy missing;
- incorrect Ansible connection configuration;
- missing Session Manager dependency;
- incorrect S3 bucket settings;
- insufficient S3 permissions;
- outbound service access unavailable;
- incorrect instance identifier.

### Resolution method

1. confirm the instance appears as a managed node;
2. inspect the attached instance profile;
3. verify the SSM Agent status;
4. test an AWS CLI SSM session where appropriate;
5. inspect Ansible connection-plugin configuration;
6. verify the required S3 bucket and IAM actions;
7. rerun Ansible ping with verbose output.

### Lesson

Inventory discovery and remote execution are separate stages.

Successful discovery does not prove SSM connectivity.

---

## Real Troubleshooting: OIDC Authentication

### Symptom

The GitHub workflow could not assume the AWS role.

### Possible causes

- incorrect repository claim;
- incorrect branch or environment claim;
- wrong audience;
- incorrect role ARN;
- missing `id-token: write`;
- trust policy mismatch;
- workflow context not matching the trust policy.

### Resolution method

1. verify workflow permissions;
2. inspect the intended repository and ref;
3. compare the claim pattern with the trust policy;
4. confirm the role ARN;
5. keep trust restrictions narrow;
6. rerun the identity verification step.

### Lesson

OIDC security depends on both successful authentication and precise claim restrictions.

---

## Real Troubleshooting: IAM Access Denied

### Symptom

A workflow stage failed with an AWS `AccessDenied` response.

### Resolution approach

1. identify the exact API action;
2. identify the resource ARN;
3. determine which role made the request;
4. confirm whether the action is genuinely required;
5. add the smallest justified permission;
6. rerun the failed stage;
7. avoid replacing the policy with administrator access.

### Lesson

Least privilege is iterative.

Real provider and plugin behaviour often reveals required read actions during implementation.

---

## Real Troubleshooting: Wrong Ansible Configuration

### Symptom

The workflow appeared to ignore inventory, role-path or connection settings.

### Possible cause

Ansible loaded a different configuration file from the one expected.

### Resolution

Set:

```bash
ANSIBLE_CONFIG=ansible/ansible.cfg
```

and verify with:

```bash
ansible-config dump --only-changed
```

### Lesson

Explicit configuration paths remove uncertainty in CI/CD environments.

---

## Real Troubleshooting: Python Interpreter

Ansible modules commonly require Python on the managed host.

Possible errors include:

- Python not found;
- unsupported interpreter;
- incorrect interpreter discovery;
- module execution failure.

The project should define or discover the correct interpreter.

A variable may be used when necessary:

```yaml
ansible_python_interpreter: /usr/bin/python3
```

The actual path must exist on the target operating system.

---

## Python Bootstrap

If a minimal image lacks Python, Ansible's `raw` module can be used for a small bootstrap step because `raw` does not require the normal Python module framework.

After Python is installed, standard idempotent modules should be used.

This should be treated as an exception rather than the default task style.

---

## Troubleshooting Methodology

The project uses a layered troubleshooting process.

```text
1. GitHub workflow started?
2. AWS OIDC authentication succeeded?
3. Correct AWS identity confirmed?
4. Required dependencies installed?
5. Dynamic inventory discovered hosts?
6. SSM connectivity succeeded?
7. Playbook syntax valid?
8. Roles executed successfully?
9. Service running?
10. Health check passed?
```

Each layer should be validated before moving to the next.

---

## Verbose Output

Ansible supports increasing levels of verbosity:

```bash
-v
-vv
-vvv
-vvvv
```

Higher verbosity can show:

- inventory decisions;
- connection behaviour;
- variable resolution;
- module execution details;
- plugin activity.

Verbose logs should be used carefully because they may expose additional environment information.

---

## Syntax Checking

Before connecting to AWS instances, playbook syntax can be checked with:

```bash
ansible-playbook \
  -i ansible/inventories/dev/aws_ec2.yml \
  ansible/playbooks/deploy.yml \
  --syntax-check
```

Syntax validation catches YAML and playbook-structure problems early.

---

## Linting

`ansible-lint` should be used to improve quality and consistency.

It can identify issues such as:

- missing task names;
- risky shell usage;
- non-fully-qualified module names;
- weak handler practices;
- formatting problems;
- idempotency concerns;
- deprecated syntax.

Linting should run before deployment.

---

## YAML Linting

`yamllint` can validate general YAML style and syntax.

Ansible linting and YAML linting serve different purposes.

A mature CI sequence includes both.

---

## Check Mode

Ansible supports check mode:

```bash
ansible-playbook deploy.yml --check
```

Check mode predicts some changes without applying them.

Not every module supports perfect check-mode behaviour.

It should be treated as a useful preview, not a complete substitute for testing.

---

## Diff Mode

Diff mode can show file changes:

```bash
ansible-playbook deploy.yml --check --diff
```

This is useful during review but must be used carefully if managed files contain sensitive content.

---

## Task Tags

Tags allow selected portions of a playbook to run.

Examples:

```bash
ansible-playbook deploy.yml --tags application
```

or:

```bash
ansible-playbook deploy.yml --skip-tags validation
```

Tags are useful for controlled operations but should not create undocumented deployment paths.

The normal pipeline should run a predictable complete sequence.

---

## Performance Considerations

Ansible can execute tasks across multiple hosts concurrently.

Performance can be influenced by:

- forks;
- fact gathering;
- serial batch size;
- task count;
- connection setup;
- module execution;
- retries;
- remote package-manager speed.

Performance tuning must not undermine deployment safety.

---

## Forks

The `forks` setting controls how many hosts Ansible can process in parallel.

A higher value can improve speed in large environments.

However, a rolling deployment using `serial: 1` intentionally limits application-host concurrency.

The deployment strategy should reflect service availability requirements rather than maximum speed.

---

## Fact-Gathering Optimisation

If a playbook does not use facts, fact gathering may be disabled:

```yaml
gather_facts: false
```

If only a small subset is needed, fact gathering can be restricted.

This can reduce execution time in larger environments.

---

## Strategy Plugins

Ansible supports different execution strategies.

The default linear strategy keeps hosts progressing through tasks in a coordinated way.

The free strategy allows hosts to progress independently.

For controlled rolling deployments, predictable linear behaviour is usually easier to reason about.

---

## Common Anti-Patterns

The project should avoid:

- one extremely large playbook;
- hard-coded instance IP addresses;
- direct root login;
- permanent SSH keys in CI;
- shell commands for tasks supported by modules;
- plaintext secrets;
- unconditional service restarts;
- ignoring failed tasks without explanation;
- broad inventory filters;
- manually edited managed servers;
- latest unpinned dependencies in production;
- storing application state on replaceable instances.

---

## Ignoring Errors

Using:

```yaml
ignore_errors: true
```

can hide important failures.

It should only be used when:

- the failure is expected;
- the reason is documented;
- later tasks can safely continue;
- the result is still inspected.

A deployment should not appear successful when a critical task failed.

---

## `changed_when`

`changed_when` allows custom control over whether a task reports a change.

It is useful for command output that does not naturally express idempotency.

Incorrect use can hide real changes or report false changes.

It should be based on reliable command behaviour.

---

## `failed_when`

`failed_when` allows custom failure conditions.

It is useful when a command returns non-standard exit codes or when output must be inspected.

It should not be used to suppress genuine errors.

---

## Replaceable Server Model

The EC2 application instances are designed to be replaceable.

If an instance fails:

```text
Auto Scaling Group launches replacement
        ↓
Replacement receives the correct IAM role and tags
        ↓
Dynamic inventory discovers the instance
        ↓
Ansible applies the required configuration
        ↓
The instance becomes a healthy application target
```

This is stronger than relying on manual repair of a specific server.

---

## Current Platform Limitations

The current implementation is a development portfolio platform.

It demonstrates enterprise principles but does not claim to be a complete production service.

Current limitations may include:

- one development environment;
- limited automated rollback;
- no AWX or Ansible Automation Platform;
- no Molecule test suite;
- no immutable machine-image pipeline;
- limited observability;
- limited deployment approval controls;
- no blue/green deployment;
- no canary release strategy;
- no production secrets lifecycle;
- no multi-account deployment.

These are documented opportunities for future development.

---

## Future Improvement: Molecule

Molecule can test Ansible roles in isolated environments.

A role test can:

1. create a temporary test instance or container;
2. apply the role;
3. verify the result;
4. rerun the role for idempotency;
5. destroy the test environment.

This would improve confidence before deploying to AWS.

---

## Future Improvement: Execution Environments

An Ansible execution environment packages:

- Ansible Core;
- collections;
- Python dependencies;
- system dependencies;
- required plugins.

Using a containerised execution environment would reduce dependency differences between:

- local development;
- GitHub Actions;
- enterprise automation platforms.

---

## Future Improvement: AWX

AWX provides a web-based automation controller.

It can offer:

- job templates;
- role-based access;
- credentials management;
- inventories;
- schedules;
- execution history;
- workflow orchestration.

It would be useful if the platform required a dedicated operations interface.

---

## Future Improvement: Red Hat Ansible Automation Platform

Ansible Automation Platform provides enterprise capabilities such as:

- supported automation controller;
- execution environments;
- private automation hub;
- event-driven automation;
- role-based access control;
- enterprise support.

The current GitHub Actions approach is appropriate for the portfolio implementation, while Ansible Automation Platform would suit a larger managed estate.

---

## Future Improvement: Automated Rollback

A more advanced deployment could retain the previous application release.

If validation fails:

```text
Deploy new version
        ↓
Health check fails
        ↓
Restore previous release
        ↓
Restart service
        ↓
Validate restored version
```

Rollback logic must be tested carefully and should not mask persistent infrastructure problems.

---

## Future Improvement: Blue/Green Deployment

A blue/green strategy would create two separate application environments.

```text
Blue = current production
Green = new release
```

The new release would be validated before traffic switches from blue to green.

This provides stronger rollback capability than an in-place rolling deployment.

---

## Future Improvement: Canary Deployment

A canary deployment would send a small percentage of traffic to the new version.

The platform would monitor:

- error rate;
- latency;
- health;
- application metrics.

Traffic would increase only after successful validation.

---

## Future Improvement: Load-Balancer Coordination

A mature rolling deployment could:

1. deregister one target;
2. wait for connection draining;
3. deploy the application;
4. validate local health;
5. reregister the target;
6. wait for ALB healthy status;
7. continue to the next target.

This would create a more controlled production deployment process.

---

## Future Improvement: Observability

Future deployments should integrate with:

- CloudWatch Logs;
- CloudWatch metrics;
- application metrics;
- deployment markers;
- alerting;
- centralised log search;
- target-health dashboards.

Automation should report not only whether tasks completed, but whether the service remained healthy after release.

---

## Future Improvement: Secrets Manager

Application secrets could be retrieved at runtime using AWS Secrets Manager.

Access would be granted through the EC2 application role or deployment role.

This would avoid storing secrets in the repository and support central rotation.

---

## Future Improvement: Event-Driven Ansible

Event-Driven Ansible can respond to events such as:

- monitoring alerts;
- instance creation;
- security findings;
- configuration drift;
- service failures.

A rulebook could trigger approved remediation automation.

This should be governed carefully to avoid uncontrolled automatic changes.

---

## Operational Commands

### Display active configuration

```bash
ANSIBLE_CONFIG=ansible/ansible.cfg \
ansible-config dump --only-changed
```

### List installed collections

```bash
ansible-galaxy collection list
```

### Install required collections

```bash
ansible-galaxy collection install \
  -r ansible/collections/requirements.yml
```

### Display dynamic inventory graph

```bash
ANSIBLE_CONFIG=ansible/ansible.cfg \
ansible-inventory \
  -i ansible/inventories/dev/aws_ec2.yml \
  --graph
```

### Display full dynamic inventory

```bash
ANSIBLE_CONFIG=ansible/ansible.cfg \
ansible-inventory \
  -i ansible/inventories/dev/aws_ec2.yml \
  --list
```

### Validate playbook syntax

```bash
ANSIBLE_CONFIG=ansible/ansible.cfg \
ansible-playbook \
  -i ansible/inventories/dev/aws_ec2.yml \
  ansible/playbooks/deploy.yml \
  --syntax-check
```

### Test managed-host connectivity

```bash
ANSIBLE_CONFIG=ansible/ansible.cfg \
ansible \
  -i ansible/inventories/dev/aws_ec2.yml \
  application \
  -m ansible.builtin.ping
```

### Run deployment

```bash
ANSIBLE_CONFIG=ansible/ansible.cfg \
ANSIBLE_ROLES_PATH=ansible/roles \
ansible-playbook \
  -i ansible/inventories/dev/aws_ec2.yml \
  ansible/playbooks/deploy.yml
```

The exact inventory group and filenames should match the repository.

---

## Deployment Lifecycle Summary

```text
DISCOVER
Query AWS for the current tagged EC2 instances.

CONNECT
Use Systems Manager rather than inbound SSH.

VALIDATE ACCESS
Run Ansible ping before configuration begins.

CONFIGURE
Apply the required Linux operating-system state.

DEPLOY
Install or update the application.

RESTART
Use handlers only when configuration changes require it.

VALIDATE
Check the service, port and health endpoint.

ROLL FORWARD
Continue to the next instance only after success.

REPORT
Use the play recap and workflow result as deployment evidence.
```

---

## Skills Demonstrated

The Ansible implementation demonstrates:

- configuration management;
- Configuration as Code;
- Linux administration;
- desired-state automation;
- idempotency;
- reusable roles;
- YAML;
- Jinja2 templates;
- variables;
- handlers;
- privilege escalation;
- service management;
- package management;
- dynamic AWS inventory;
- EC2 tag discovery;
- Systems Manager connectivity;
- IAM integration;
- GitHub Actions integration;
- rolling deployments;
- health validation;
- failure handling;
- troubleshooting;
- security-aware automation.

---

## Interview Explanation

A clear interview explanation is:

> Terraform provisions the AWS infrastructure, and Ansible manages the Linux and application configuration after the instances exist. Because the application instances are managed by an Auto Scaling Group, I avoided a static inventory. Ansible uses the AWS EC2 dynamic inventory plugin to discover the currently running instances from their project and environment tags. The instances are in private subnets, so I used AWS Systems Manager instead of exposing SSH. GitHub Actions authenticates to AWS using OIDC, installs the required Ansible collections, validates inventory and SSM connectivity, and then runs the deployment playbook with a rolling strategy. The roles install dependencies, deploy configuration and application files, manage services through handlers and validate the application before moving to the next instance.

---

## 30-Second Interview Answer

> Ansible is the configuration and deployment layer of my AWS platform. Terraform creates the infrastructure, then Ansible discovers the current Auto Scaling instances dynamically through EC2 tags. It connects through AWS Systems Manager rather than SSH, so the instances remain private and no SSH keys are required. The GitHub Actions workflow installs the Ansible dependencies, checks connectivity and performs a rolling deployment with service and health validation.

---

## Two-Minute Interview Answer

> I separated infrastructure provisioning from configuration management. Terraform creates the VPC, private application subnets, security groups, IAM instance profile, launch template, Auto Scaling Group and load balancer. Once the infrastructure exists, Ansible takes responsibility for configuring the Linux instances and deploying the application.
>
> The Auto Scaling instances are replaceable, so I did not use a static inventory. The AWS EC2 dynamic inventory plugin queries `eu-west-2` and filters instances by the tags created by Terraform. That means Ansible always targets the current instances even if Auto Scaling has replaced them.
>
> The instances are private and do not expose SSH. Ansible connects through AWS Systems Manager using temporary credentials obtained by GitHub Actions through OIDC. The workflow installs the required Ansible Galaxy collections, validates the inventory, checks SSM connectivity and runs the deployment playbook.
>
> The playbook uses roles to separate common Linux configuration, application deployment and validation. Tasks use idempotent modules, templates generate environment-specific configuration, handlers restart services only when required and `serial` provides a rolling deployment. The application is validated before the workflow reports success.

---

## Five-Minute Architecture Walkthrough

A longer explanation can follow this sequence:

1. Begin with the responsibility boundary:
   - Terraform creates AWS resources.
   - Ansible configures Linux and deploys the application.

2. Explain infrastructure discovery:
   - Auto Scaling instances are replaceable.
   - Terraform applies project and environment tags.
   - Dynamic inventory queries AWS on every run.
   - No static IP list is maintained.

3. Explain connectivity:
   - instances run in private subnets;
   - no inbound SSH rule exists;
   - no SSH keys are distributed;
   - Ansible uses the SSM connection plugin;
   - the instance profile allows the SSM Agent to register;
   - GitHub Actions receives temporary AWS credentials through OIDC.

4. Explain the Ansible structure:
   - project-level `ansible.cfg`;
   - collection requirements;
   - dynamic inventory;
   - deployment playbook;
   - reusable roles;
   - templates;
   - handlers;
   - variables;
   - validation tasks.

5. Explain deployment safety:
   - inventory is checked first;
   - connectivity is tested;
   - deployment is rolling;
   - services restart only when required;
   - health checks run before continuing;
   - failures stop further rollout.

6. Explain the engineering outcome:
   - repeatable deployment;
   - no manual server configuration;
   - no static inventory;
   - reduced attack surface;
   - auditable Git-driven changes;
   - replaceable instances;
   - easier recovery.

---

## Common Interview Questions

### Why did you use Ansible?

Ansible provides agentless, readable and idempotent configuration management with strong Linux and AWS integration. It allowed the project to automate server configuration and application deployment without maintaining a separate agent platform.

### Why not configure the EC2 instances entirely with Terraform?

Terraform is designed to manage infrastructure resources and their lifecycle. Ansible is better suited to detailed operating-system configuration, package management, templates, services and application deployment.

### What does idempotency mean?

An idempotent task changes a system only when its current state differs from the desired state. Repeated runs should produce the same final configuration without unnecessary changes.

### How did Ansible find the EC2 instances?

It used the AWS EC2 dynamic inventory plugin to query running instances in `eu-west-2` and filter them using the tags applied by Terraform.

### Why not use a static inventory?

The instances belong to an Auto Scaling Group and may be replaced. A static inventory could become stale, while dynamic inventory discovers the current instances during every workflow run.

### Why did you use Systems Manager instead of SSH?

Systems Manager allowed the instances to remain private without inbound port 22, SSH keys or a bastion host. Access is controlled through IAM and temporary AWS credentials.

### What is an Ansible role?

A role is a structured, reusable unit of automation containing tasks, handlers, templates, files, defaults and variables for a specific responsibility.

### What is a handler?

A handler is a task that runs only when notified by a changed task. It is commonly used to restart or reload services only when configuration changes.

### What is the difference between `copy` and `template`?

`copy` transfers static content. `template` renders Jinja2 content using variables before deploying it.

### What does `become: true` do?

It enables privilege escalation so tasks can run with administrative permissions without requiring direct root login.

### What is the Ansible ping module?

It validates that Ansible can connect to the managed host and execute a basic Python-based module. It is not an ICMP network ping.

### What does `serial: 1` do?

It limits the play to one host at a time, enabling a rolling deployment and reducing the number of simultaneously affected instances.

### How did you validate deployment success?

The workflow validated inventory, SSM connectivity, service state and application health. A failed validation prevented the deployment from being treated as successful.

### How did GitHub Actions authenticate?

GitHub Actions used OpenID Connect to assume a restricted AWS IAM role and receive temporary credentials.

### Where were AWS credentials stored?

Long-lived AWS access keys were not stored in the repository. Terraform and Ansible used temporary credentials issued through OIDC.

### How did you handle configuration drift?

The desired state is stored in Ansible. Rerunning the playbook corrects managed settings that differ from the approved configuration.

### What happens when Auto Scaling replaces an instance?

The replacement receives the launch-template configuration and tags. Dynamic inventory discovers it, and Ansible can apply the required Linux and application configuration.

### Why are modules preferable to shell scripts?

Modules provide clearer intent, structured output, error handling and idempotency. Shell commands often require additional logic to avoid repeated changes.

### How would you test a role?

I would run YAML and Ansible linting, syntax checks, check mode where supported, deploy to an isolated environment, verify the resulting state and use Molecule for repeatable role tests and idempotency validation.

### How would you improve the deployment for production?

I would add protected environments, approvals, pinned execution environments, Molecule tests, stronger secrets management, load-balancer deregistration, automated rollback, observability and potentially blue/green or canary deployment.

---

## Final Memory Card

```text
TERRAFORM
Creates AWS infrastructure.

ANSIBLE
Configures Linux and deploys the application.

INVENTORY
Queries AWS dynamically using EC2 tags.

CONNECTIVITY
Uses Systems Manager instead of SSH.

AUTHENTICATION
Uses temporary AWS credentials from GitHub OIDC.

ROLES
Separate common configuration, application deployment and validation.

MODULES
Provide declarative and idempotent system changes.

TEMPLATES
Generate configuration from variables.

HANDLERS
Restart services only when required.

BECOME
Provides controlled privilege escalation.

SERIAL
Enables rolling deployment.

VALIDATION
Checks connectivity, service state and application health.

IDEMPOTENCY
Allows safe repeat execution.

AUTO SCALING
Creates replaceable instances that Ansible can rediscover.

SECURITY
No public SSH, no permanent AWS keys and no plaintext secrets.
```

---

## Final Summary

Ansible provides the operating-system configuration and application deployment capability for the Enterprise AWS Platform Delivery Pipeline.

Terraform creates the AWS infrastructure and applies the metadata required for discovery.

Ansible then queries AWS dynamically to identify the current running application instances.

Because the instances are located in private subnets, the platform uses AWS Systems Manager rather than exposing SSH.

GitHub Actions authenticates through OIDC, installs the required Ansible collections, validates dynamic inventory, confirms SSM connectivity and executes the deployment.

Roles separate configuration responsibilities.

Idempotent modules maintain the required server state.

Jinja2 templates generate reusable configuration.

Handlers restart services only when a change requires it.

Privilege escalation enables controlled administrative tasks.

Rolling deployment limits the number of simultaneously affected instances.

Health validation ensures the application is operational before the workflow reports success.

The result is a secure, repeatable and scalable configuration-management layer that integrates Terraform, AWS, GitHub Actions and Linux automation into one complete delivery platform.
