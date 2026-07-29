# AWS Architecture

## Overview

The Enterprise AWS Platform Delivery Pipeline is deployed into a custom Amazon Virtual Private Cloud.

The architecture separates public-facing infrastructure, application servers and database resources into different network tiers.

The design uses:

- public subnets for internet-facing components;
- private application subnets for EC2 instances;
- private database subnets for database resources;
- an Application Load Balancer for incoming traffic;
- an Auto Scaling Group for EC2 capacity;
- AWS Systems Manager for secure server management;
- security groups to control traffic between tiers;
- IAM roles and instance profiles for AWS permissions;
- Terraform for infrastructure management;
- Ansible for server configuration and application deployment.

The main objective of the architecture is to provide a secure, repeatable and automated AWS application platform.

---

## High-level architecture

```text
                                  Internet
                                      │
                                      ▼
                         Application Load Balancer
                           Public Subnet A and B
                                      │
                                      ▼
                         Application Security Group
                                      │
                     ┌────────────────┴────────────────┐
                     │                                 │
                     ▼                                 ▼
             EC2 Application Instance         EC2 Application Instance
              Private App Subnet A              Private App Subnet B
                     │                                 │
                     └────────────────┬────────────────┘
                                      │
                                      ▼
                           Database Security Group
                                      │
                                      ▼
                              Database Tier
                      Private Database Subnet A and B
```

Operational management follows a separate secure path:

```text
GitHub Actions
      │
      ▼
GitHub OIDC
      │
      ▼
AWS IAM Role
      │
      ▼
AWS Systems Manager
      │
      ▼
Private EC2 Instances
```

---

## Architecture goals

The architecture was designed to meet the following goals:

- keep application instances private;
- avoid exposing SSH to the internet;
- use multiple Availability Zones;
- separate public, application and database tiers;
- control traffic through security-group relationships;
- automate resource creation through Terraform;
- support automatic EC2 replacement through Auto Scaling;
- distribute application traffic through a load balancer;
- provide secure automation access through Systems Manager;
- support repeatable application deployment through Ansible;
- reduce configuration drift;
- create a foundation for high availability.

---

## AWS Region

The platform is deployed in:

```text
eu-west-2
```

This is the AWS Europe region located in London.

Using the London region provides a suitable location for a UK-based deployment and allows resources to be distributed across multiple Availability Zones.

---

## Availability Zone design

The architecture uses two Availability Zones.

A simplified layout is:

```text
Availability Zone A                  Availability Zone B
───────────────────                  ───────────────────

Public Subnet A                      Public Subnet B
Private App Subnet A                 Private App Subnet B
Private DB Subnet A                  Private DB Subnet B
```

Using more than one Availability Zone reduces dependency on one physical AWS location.

If one Availability Zone experiences a failure, resources in the second Availability Zone can continue operating where the application and service configuration support it.

---

## Virtual Private Cloud

The Amazon VPC provides the isolated network boundary for the platform.

The VPC contains:

- public subnets;
- private application subnets;
- private database subnets;
- route tables;
- an Internet Gateway;
- a NAT Gateway;
- security groups;
- load-balancing resources;
- application instances;
- database networking resources.

The VPC is created and managed through Terraform.

This means the entire network can be:

- reviewed as code;
- recreated consistently;
- version controlled;
- changed through an approved workflow;
- destroyed when no longer required.

---

## Subnet architecture

The VPC is divided into three logical tiers.

### Public subnet tier

The public subnets host components that require direct access to or from the internet.

The public tier contains:

- the Application Load Balancer;
- the NAT Gateway;
- routes to the Internet Gateway.

The public subnets are associated with a route table containing a default route to the Internet Gateway.

Example:

```text
0.0.0.0/0 → Internet Gateway
```

The EC2 application instances are not placed in the public subnets.

---

### Private application subnet tier

The private application subnets host the EC2 application servers.

These instances do not require:

- public IP addresses;
- inbound SSH access;
- direct inbound internet access.

The Application Load Balancer forwards approved traffic to the application instances.

The application instances can make outbound requests through the NAT Gateway where required.

The private application route table contains a default route through the NAT Gateway.

Example:

```text
0.0.0.0/0 → NAT Gateway
```

This allows outbound connectivity without allowing unsolicited inbound internet traffic.

---

### Private database subnet tier

The private database subnets are reserved for database infrastructure.

The database tier is designed to be isolated from the public internet.

Database resources should only receive traffic from the application tier on the approved database port.

The database subnet group spans multiple Availability Zones.

This provides the network foundation for a managed database service such as Amazon RDS.

---

## Subnet layout

```text
VPC
│
├── Public Subnet A
│   ├── Application Load Balancer
│   └── NAT Gateway
│
├── Public Subnet B
│   └── Application Load Balancer
│
├── Private Application Subnet A
│   └── EC2 Application Instance
│
├── Private Application Subnet B
│   └── EC2 Application Instance
│
├── Private Database Subnet A
│   └── Database subnet group membership
│
└── Private Database Subnet B
    └── Database subnet group membership
```

---

## Internet Gateway

The Internet Gateway provides internet connectivity for public subnet resources.

It is attached to the VPC.

The public route table directs internet-bound traffic to the Internet Gateway.

The Application Load Balancer uses the public subnets and can therefore accept approved incoming traffic from internet users.

The Internet Gateway does not automatically make private instances publicly accessible.

Public access also depends on:

- subnet routing;
- public IP assignment;
- security-group rules;
- network configuration.

The private application instances do not have direct public routes through the Internet Gateway.

---

## NAT Gateway

The NAT Gateway allows resources in private application subnets to initiate outbound internet connections.

This may be required for activities such as:

- downloading operating-system packages;
- retrieving software dependencies;
- accessing approved external services;
- installing application components.

The NAT Gateway does not allow the internet to initiate connections to the private EC2 instances.

Traffic flow:

```text
Private EC2 instance
        ↓
Private route table
        ↓
NAT Gateway
        ↓
Internet Gateway
        ↓
Internet
```

The NAT Gateway is placed in a public subnet and uses an Elastic IP address.

Because NAT Gateways can generate continuous hourly and data-processing charges, the development environment is destroyed when testing is complete.

---

## Route tables

Different route tables are used for different subnet tiers.

### Public route table

The public route table includes:

```text
Local VPC route
0.0.0.0/0 → Internet Gateway
```

It is associated with the public subnets.

### Private application route table

The private application route table includes:

```text
Local VPC route
0.0.0.0/0 → NAT Gateway
```

It is associated with the private application subnets.

### Private database routing

The private database subnets are designed to avoid direct public internet routing.

Their routing should support only the connectivity required by the platform design.

This reduces unnecessary exposure of the database tier.

---

## Application Load Balancer

The Application Load Balancer is the public entry point for the application.

It spans public subnets in multiple Availability Zones.

Its responsibilities include:

- receiving client traffic;
- forwarding traffic to healthy application targets;
- distributing traffic across EC2 instances;
- performing target health checks;
- removing unhealthy targets from traffic rotation;
- supporting future HTTPS termination.

Traffic flow:

```text
Internet
    ↓
Application Load Balancer
    ↓
Target Group
    ↓
Healthy EC2 Application Instances
```

The load balancer does not send traffic directly to every EC2 instance without checking health.

Only registered and healthy targets receive traffic.

---

## Load balancer listener

The listener accepts incoming connections on the configured application port.

For the development version, this may use HTTP.

A production-ready version should use:

- HTTPS;
- an AWS Certificate Manager certificate;
- an HTTP-to-HTTPS redirect;
- modern TLS policies.

Example future traffic flow:

```text
HTTP port 80
    ↓
Redirect to HTTPS
    ↓
HTTPS port 443
    ↓
Application target group
```

---

## Target group

The target group contains the EC2 application instances that receive traffic from the Application Load Balancer.

The Auto Scaling Group registers instances with the target group.

The target group defines:

- backend application port;
- backend protocol;
- health-check path;
- health-check interval;
- healthy threshold;
- unhealthy threshold;
- target type.

The load balancer uses the target group health checks to determine whether an instance should receive traffic.

---

## Health checks

Health checks help prevent requests from being sent to unavailable application instances.

The load balancer periodically checks the configured application endpoint.

A target is marked healthy when it returns the expected response.

A target can be marked unhealthy when:

- the application service is stopped;
- the application port is unavailable;
- the health endpoint returns an error;
- the instance cannot be reached;
- startup takes longer than expected.

Healthy traffic flow:

```text
Load balancer health check
        ↓
Application endpoint responds successfully
        ↓
Target marked healthy
        ↓
User traffic forwarded to instance
```

Unhealthy traffic flow:

```text
Load balancer health check
        ↓
Application endpoint fails
        ↓
Target marked unhealthy
        ↓
Traffic no longer forwarded to instance
```

---

## EC2 application tier

The EC2 instances run the Linux application workload.

They are created through an EC2 launch template and managed by an Auto Scaling Group.

The instances are placed in the private application subnets.

They receive:

- the application security group;
- an IAM instance profile;
- AWS Systems Manager permissions;
- application and environment tags;
- launch-template configuration.

The instances do not require direct public access.

---

## Launch template

The launch template defines how application instances are created.

It can include:

- Amazon Machine Image;
- EC2 instance type;
- security-group assignment;
- IAM instance profile;
- storage configuration;
- metadata settings;
- instance tags;
- user-data configuration where required.

The launch template provides a consistent definition for every instance created by the Auto Scaling Group.

This reduces differences between servers.

---

## Auto Scaling Group

The Auto Scaling Group maintains the desired application capacity.

Its responsibilities include:

- creating application instances;
- placing instances across private subnets;
- replacing terminated instances;
- replacing unhealthy instances;
- maintaining minimum capacity;
- maintaining desired capacity;
- enforcing maximum capacity;
- registering instances with the target group.

A simplified lifecycle is:

```text
Auto Scaling Group detects missing capacity
        ↓
Launch template is used
        ↓
New EC2 instance is created
        ↓
Instance starts in private subnet
        ↓
Instance registers with Systems Manager
        ↓
Instance registers with target group
        ↓
Health checks begin
        ↓
Instance becomes healthy
```

---

## Capacity settings

The Auto Scaling Group uses:

- minimum capacity;
- desired capacity;
- maximum capacity.

These values control how many instances may run.

Example concept:

```text
Minimum capacity: minimum number that should remain available
Desired capacity: normal target number of instances
Maximum capacity: upper scaling limit
```

The AWS account quota provides an additional capacity guardrail.

However, quotas are not a replacement for:

- AWS Budgets;
- billing alerts;
- deliberate instance sizing;
- infrastructure destruction after testing.

---

## Instance replacement

EC2 application instances should be treated as replaceable infrastructure.

If an instance fails or is manually terminated:

1. the Auto Scaling Group detects reduced capacity;
2. a replacement instance is created;
3. the launch template supplies the required configuration;
4. the IAM instance profile is attached;
5. the instance registers with Systems Manager;
6. the instance registers with the target group;
7. dynamic inventory can discover the replacement;
8. Ansible can configure and deploy to the replacement instance.

This is more reliable than depending on one manually configured long-lived server.

---

## IAM instance profile

The EC2 instances use an IAM role through an instance profile.

The instance profile gives the server permission to access required AWS services.

For example, it allows the EC2 instance to work with AWS Systems Manager.

The instance does not need permanent AWS access keys stored on disk.

The permission relationship is:

```text
EC2 instance
    ↓
IAM instance profile
    ↓
IAM role
    ↓
Attached IAM policies
    ↓
Approved AWS API permissions
```

---

## AWS Systems Manager

AWS Systems Manager provides the management channel for private EC2 instances.

It is used instead of exposing SSH to the internet.

The Systems Manager design requires:

- the SSM agent on the EC2 instance;
- an IAM instance profile;
- network connectivity to AWS Systems Manager endpoints;
- pipeline IAM permissions;
- correct Ansible connection configuration.

The connection flow is:

```text
GitHub Actions runner
        ↓
AWS API authentication
        ↓
Systems Manager session
        ↓
SSM-managed EC2 instance
        ↓
Ansible module execution
```

---

## Why Systems Manager was selected

Traditional SSH-based management may require:

- public IP addresses;
- inbound port 22;
- SSH private keys;
- bastion hosts;
- key rotation;
- key distribution.

Systems Manager avoids many of these requirements.

The benefits include:

- no public SSH port;
- no manually shared SSH key;
- IAM-controlled access;
- support for private instances;
- centralised AWS access control;
- reduced public attack surface.

---

## Security group architecture

The platform uses separate security groups for each major tier.

The main security groups are:

- Application Load Balancer security group;
- application security group;
- database security group.

Security-group references are used where possible instead of broad IP ranges.

This creates clearer trust relationships between components.

---

## Application Load Balancer security group

The load balancer security group permits approved incoming web traffic.

Typical rules include:

```text
Inbound:
Internet → HTTP port 80
Internet → HTTPS port 443

Outbound:
Load balancer → Application instances
```

For a production environment, HTTPS should be the main public protocol.

HTTP can be used only for redirection to HTTPS.

---

## Application security group

The application security group is attached to the EC2 application instances.

It permits application traffic from the load balancer security group.

Example:

```text
Inbound:
ALB security group → Application port 8080
```

This means the application port is not open to the entire internet.

Only traffic that passes through the Application Load Balancer is accepted.

The application instances do not require inbound SSH port 22.

---

## Database security group

The database security group protects the database tier.

It permits database traffic only from the application security group.

Example:

```text
Inbound:
Application security group → PostgreSQL port 5432
```

This prevents internet users and unrelated AWS resources from directly reaching the database port.

The trust path becomes:

```text
Internet
    ↓
Load balancer
    ↓
Application instance
    ↓
Database
```

---

## Security group flow

```text
Internet
    │
    │ HTTP or HTTPS
    ▼
ALB Security Group
    │
    │ Application port
    ▼
Application Security Group
    │
    │ Database port
    ▼
Database Security Group
```

Each tier only accepts the traffic required from the previous approved tier.

---

## Database subnet group

The database subnet group contains the private database subnets.

It spans multiple Availability Zones.

This provides the subnet placement required by services such as Amazon RDS.

The database subnet group does not itself provide database security.

Security is also controlled through:

- database security groups;
- route tables;
- public accessibility settings;
- IAM;
- encryption;
- database credentials;
- backup policies.

---

## Database tier

The database tier is designed for a private relational database.

A production-ready database design should include:

- private subnet placement;
- public access disabled;
- storage encryption;
- backup retention;
- deletion protection;
- managed credentials;
- restricted security groups;
- monitoring;
- Multi-AZ deployment where required;
- tested restore procedures.

The current project creates the network foundation required for the database layer.

---

## GitHub OIDC architecture

GitHub Actions authenticates to AWS through OpenID Connect.

The OIDC workflow is:

```text
GitHub Actions workflow
        ↓
GitHub issues signed OIDC token
        ↓
AWS OIDC provider validates token
        ↓
IAM role trust policy checks claims
        ↓
AWS STS issues temporary credentials
        ↓
Workflow uses AWS APIs
```

The trust relationship is restricted to the approved GitHub repository identity.

Immutable claims are used where possible.

These include:

- repository ID;
- repository-owner ID.

This reduces dependence on names that might change or be reused.

---

## GitHub Actions IAM role

The GitHub Actions workflow assumes a dedicated AWS IAM role.

The role contains permissions needed for:

- Terraform remote-state access;
- infrastructure planning;
- AWS resource discovery;
- EC2 inventory queries;
- Systems Manager connectivity;
- deployment validation.

The role is not granted unrestricted administrator access.

Permissions are added according to the actual actions required by the pipeline.

---

## Least-privilege design

The project follows a least-privilege approach.

This means:

- permissions are granted only when required;
- broad administrative policies are avoided;
- trust is limited to the approved repository;
- application instances use their own role;
- GitHub Actions uses a separate role;
- security groups restrict traffic by source;
- private instances are not directly exposed;
- temporary credentials are used.

During development, missing permissions were diagnosed from the pipeline logs and added deliberately.

This provided practical IAM troubleshooting experience.

---

## Terraform architecture management

Terraform manages the AWS architecture through reusable modules.

The modules are connected through inputs and outputs.

Example dependency flow:

```text
Networking module
        ↓
Subnet IDs and VPC ID
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
Application traffic
```

Terraform determines creation and destruction order from resource references.

---

## Infrastructure creation order

A simplified creation sequence is:

```text
1. VPC
2. Subnets
3. Internet Gateway
4. Route tables
5. NAT Gateway
6. Security groups
7. IAM roles and instance profile
8. Launch template
9. Target group
10. Application Load Balancer
11. Auto Scaling Group
12. EC2 application instances
13. Target registration
14. Application health checks
```

Terraform handles dependencies so resources are created in the correct order.

---

## Infrastructure destruction order

When the environment is destroyed, Terraform removes resources in reverse dependency order.

A simplified sequence is:

```text
1. Auto Scaling resources
2. EC2 application instances
3. Load balancer associations
4. Application Load Balancer
5. Target group
6. Launch template
7. IAM instance profile and roles
8. Security groups
9. NAT Gateway
10. Route tables
11. Internet Gateway
12. Subnets
13. VPC
```

This is safer than manually deleting resources in the AWS Console.

---

## Application request flow

A normal application request follows this path:

```text
1. A user sends an HTTP or HTTPS request.
2. DNS resolves the application endpoint.
3. The request reaches the Application Load Balancer.
4. The ALB security group checks the request.
5. The load balancer selects a healthy target.
6. The request is forwarded to the application port.
7. The application security group checks the source.
8. The EC2 application handles the request.
9. The application may query the private database.
10. The response returns through the load balancer.
```

---

## Deployment management flow

The deployment process follows a separate operational path:

```text
1. A developer pushes code to GitHub.
2. GitHub Actions starts the workflow.
3. OIDC authenticates the workflow to AWS.
4. Terraform validates and plans infrastructure.
5. Ansible queries AWS dynamic inventory.
6. Running EC2 application instances are discovered.
7. Systems Manager establishes connectivity.
8. Ansible configures the instances.
9. The application is deployed in controlled batches.
10. Validation checks confirm success.
```

---

## Dynamic inventory interaction

Ansible does not depend on manually entered instance addresses.

The inventory plugin queries AWS and filters the results using instance metadata.

The discovery flow is:

```text
Ansible
    ↓
AWS EC2 inventory plugin
    ↓
AWS API query
    ↓
Filter by region, tags and state
    ↓
Return matching EC2 instances
    ↓
Create dynamic Ansible host groups
```

This supports Auto Scaling because replacement instances can be discovered automatically.

---

## Rolling deployment interaction

The rolling deployment limits how many application instances are updated simultaneously.

Example:

```text
Application Instance A: updating
Application Instance B: still serving traffic
```

After the first instance is updated and validated:

```text
Application Instance A: serving traffic
Application Instance B: updating
```

This reduces the chance of all application capacity becoming unavailable at once.

---

## High-availability characteristics

The architecture contains several high-availability foundations:

- multiple Availability Zones;
- multiple public subnets;
- multiple private application subnets;
- Application Load Balancer;
- target health checks;
- Auto Scaling Group;
- replaceable EC2 instances;
- rolling deployment;
- database subnet group across multiple zones.

Full production high availability would also require:

- appropriate desired EC2 capacity;
- Multi-AZ database deployment;
- tested application session handling;
- highly available NAT design where required;
- resilient DNS;
- monitoring and alerting;
- backup and recovery testing.

---

## Current NAT design consideration

A single NAT Gateway may be suitable for a development environment because it reduces complexity.

However, it creates:

- a dependency on one Availability Zone;
- cross-zone routing in some designs;
- a possible availability limitation.

A production environment may use one NAT Gateway per Availability Zone.

Example:

```text
Private App Subnet A → NAT Gateway A
Private App Subnet B → NAT Gateway B
```

This improves resilience but increases cost.

The appropriate design depends on:

- availability requirements;
- budget;
- expected traffic;
- recovery objectives.

---

## Cost considerations

The main potentially billable resources include:

- NAT Gateway hourly usage;
- NAT Gateway data processing;
- Application Load Balancer hours;
- load-balancer capacity usage;
- EC2 instance hours;
- EC2 storage;
- database instance hours;
- database storage;
- Elastic IP charges in certain conditions;
- outbound data transfer;
- Systems Manager features beyond free allowances;
- S3 storage and API usage.

For this development project, the live infrastructure is destroyed after testing.

The remote state bucket and OIDC configuration may remain because their cost is minimal when lightly used.

---

## Cost-control measures

The project uses the following cost-control approach:

- development infrastructure is temporary;
- Terraform destroy is used after testing;
- account quotas remain limited;
- resource sizes are kept appropriate for a lab;
- resources are deployed into one AWS region;
- state is checked after destruction;
- AWS Console resources are reviewed after cleanup;
- expensive services are not left running unnecessarily.

Additional controls should include:

- AWS Budgets;
- email billing alerts;
- cost anomaly detection;
- tagging;
- regular cost reviews;
- automated environment expiry;
- Infracost checks.

---

## Resource tagging

AWS tags should identify the purpose and ownership of resources.

Recommended tags include:

```text
Project     = enterprise-aws-platform-delivery-pipeline
Environment = dev
ManagedBy   = terraform
Owner       = platform-team
Application = platform-demo
```

Tags support:

- dynamic inventory;
- cost allocation;
- resource discovery;
- ownership identification;
- environment separation;
- automation filters;
- operational troubleshooting.

---

## Environment separation

The project currently contains a development environment.

The Terraform structure supports future environments such as:

```text
terraform/environments/
├── dev/
├── staging/
└── prod/
```

Each environment could use:

- separate variable values;
- separate remote state;
- separate AWS accounts;
- separate IAM roles;
- separate network ranges;
- separate scaling settings;
- separate approval controls.

A mature enterprise design would normally separate production from non-production workloads.

---

## Production architecture improvements

A production-ready version could add:

- separate AWS accounts;
- AWS Organisations;
- centralised identity;
- HTTPS;
- AWS Certificate Manager;
- Route 53;
- AWS Web Application Firewall;
- one NAT Gateway per Availability Zone;
- VPC endpoints;
- private package repositories;
- RDS Multi-AZ;
- Secrets Manager;
- KMS customer-managed keys;
- CloudWatch dashboards;
- CloudWatch alarms;
- centralised logs;
- GuardDuty;
- Security Hub;
- AWS Config;
- CloudTrail;
- vulnerability scanning;
- backup policies;
- disaster recovery;
- automated patching;
- blue-green deployment;
- canary deployment.

---

## VPC endpoints as a future improvement

VPC endpoints could reduce dependency on NAT Gateway access for supported AWS services.

Possible endpoints include:

- Systems Manager;
- EC2 Messages;
- SSM Messages;
- Amazon S3;
- CloudWatch Logs;
- Secrets Manager.

A Systems Manager private-access design could use:

```text
Private EC2
    ↓
VPC Interface Endpoint
    ↓
AWS Systems Manager
```

This can improve privacy and reduce some NAT data traffic.

Interface endpoints also create their own hourly costs, so the design should be selected based on usage and requirements.

---

## Logging and monitoring improvements

The architecture should eventually include centralised operational visibility.

Recommended additions include:

- CloudWatch application logs;
- EC2 system metrics;
- Application Load Balancer access logs;
- target-group health alarms;
- Auto Scaling activity monitoring;
- Systems Manager session logging;
- Terraform pipeline alerts;
- deployment failure notifications;
- application availability checks;
- cost alarms.

Monitoring should answer:

- Is the application available?
- Are targets healthy?
- Are instances being replaced?
- Are deployments failing?
- Is CPU or memory usage too high?
- Are costs increasing unexpectedly?
- Are unauthorised changes occurring?

---

## Backup and recovery improvements

A production architecture should define recovery procedures for:

- Terraform state;
- database data;
- application configuration;
- secrets;
- logs;
- deployment artifacts.

The Terraform state bucket already benefits from versioning.

Additional measures could include:

- state-bucket replication;
- database automated backups;
- database snapshots;
- cross-region backup copies;
- tested restore procedures;
- documented recovery time objective;
- documented recovery point objective.

---

## Security improvements

Future security enhancements could include:

- HTTPS-only traffic;
- Web Application Firewall;
- restricted outbound traffic;
- VPC endpoints;
- KMS encryption;
- Secrets Manager;
- Systems Manager Parameter Store;
- CloudTrail;
- GuardDuty;
- Security Hub;
- AWS Config;
- IAM Access Analyzer;
- automated policy scanning;
- Terraform security scanning;
- regular patching;
- image vulnerability scanning.

---

## Architecture strengths

The architecture demonstrates several strong design decisions:

- clear network-tier separation;
- private application instances;
- restricted database access;
- load-balanced application traffic;
- multiple Availability Zones;
- Auto Scaling instance management;
- secure Systems Manager connectivity;
- OIDC-based CI/CD authentication;
- least-privilege IAM;
- Infrastructure as Code;
- dynamic server discovery;
- controlled rolling deployment;
- automated validation;
- cost-aware environment destruction.

---

## Architecture limitations

The development architecture also has limitations that should be recognised.

These may include:

- one development environment;
- one AWS account;
- single-region deployment;
- potentially one NAT Gateway;
- limited monitoring;
- limited production security services;
- no full disaster-recovery implementation;
- no automated scaling policy based on demand;
- no advanced deployment strategy;
- no production HTTPS configuration;
- no completed production database configuration.

Recognising these limitations demonstrates realistic engineering judgement.

The architecture is a strong development and portfolio platform, but additional controls would be needed before production use.

---

## Architecture decision summary

The major architecture decisions are:

| Decision | Reason |
|---|---|
| Custom VPC | Provides controlled and isolated networking. |
| Multiple subnet tiers | Separates public, application and database components. |
| Multiple Availability Zones | Creates a foundation for resilience. |
| Public Application Load Balancer | Provides the application entry point and traffic distribution. |
| Private EC2 instances | Reduces direct internet exposure. |
| Auto Scaling Group | Maintains capacity and replaces failed instances. |
| Security-group references | Restricts traffic between approved tiers. |
| Systems Manager | Avoids public SSH and manually managed keys. |
| GitHub OIDC | Avoids permanent AWS credentials. |
| Terraform modules | Provides reusable and maintainable infrastructure code. |
| Ansible dynamic inventory | Automatically discovers current EC2 instances. |
| Rolling deployment | Reduces deployment disruption. |
| Temporary development environment | Reduces unnecessary cloud cost. |

---

## Interview explanation

A clear interview explanation is:

> I designed the AWS environment using a three-tier VPC structure. The Application Load Balancer is placed across public subnets, while the EC2 application instances run inside private application subnets. The database networking is isolated in private database subnets. Security groups control the traffic path so that internet users can reach the load balancer, only the load balancer can reach the application instances, and only the application tier can reach the database port. The EC2 instances are managed by an Auto Scaling Group and are accessed operationally through AWS Systems Manager rather than public SSH. Terraform manages the infrastructure, and Ansible dynamically discovers and configures the private instances.

---

## One-minute architecture explanation

> The platform runs inside a custom AWS VPC spread across two Availability Zones. It contains public subnets for the Application Load Balancer and NAT Gateway, private application subnets for the EC2 servers, and private database subnets for the database layer. Incoming traffic reaches the public load balancer and is forwarded only to healthy EC2 targets. Security-group references restrict the flow between the load balancer, application and database tiers. The instances are created through a launch template and maintained by an Auto Scaling Group. They do not use public SSH; instead, GitHub Actions and Ansible connect through AWS Systems Manager. The entire architecture is created through modular Terraform and destroyed after testing to control cost.

---

## Easy architecture memory method

Remember the architecture using:

**Balance → Protect → Scale → Manage → Automate**

### Balance

The Application Load Balancer distributes traffic across healthy instances.

### Protect

Private subnets and security groups restrict access.

### Scale

The Auto Scaling Group maintains application capacity.

### Manage

Systems Manager provides secure access to private instances.

### Automate

Terraform creates the infrastructure and Ansible configures the servers.

---

## Final architecture summary

The AWS architecture separates internet-facing, application and database responsibilities into controlled network tiers.

The Application Load Balancer receives public traffic.

Private EC2 instances run the application.

Security groups enforce communication boundaries.

The Auto Scaling Group maintains application capacity.

Systems Manager provides secure operational access.

Terraform manages the infrastructure lifecycle.

Ansible configures and deploys to the application servers.

The result is a secure, automated and cost-aware AWS platform architecture that demonstrates practical cloud platform engineering principles.
