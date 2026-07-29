# Enterprise AWS Platform Delivery Pipeline

## Overview

The Enterprise AWS Platform Delivery Pipeline demonstrates how a modern Platform Engineering team can provision, configure and deploy cloud infrastructure using Infrastructure as Code, Configuration Management and Continuous Integration / Continuous Delivery (CI/CD).

The project provisions AWS infrastructure using Terraform, configures compute resources with Ansible and automates deployments through GitHub Actions using secure OpenID Connect (OIDC) authentication.

The objective is to demonstrate practical Platform Engineering skills including automation, cloud infrastructure, security, deployment pipelines, operational practices and documentation.

---

# Key Features

- Infrastructure as Code using Terraform
- Automated configuration management using Ansible
- GitHub Actions CI/CD pipeline
- OIDC authentication with temporary AWS credentials
- Dynamic EC2 inventory
- AWS Systems Manager (no SSH access)
- Auto Scaling Group deployment
- Application Load Balancer
- Private application subnets
- Remote Terraform state (Amazon S3)
- Terraform state locking (DynamoDB)
- Idempotent deployments
- Automated deployment validation
- Production-style documentation

---

# Architecture Overview

```
Developer

↓

Git Push

↓

GitHub Repository

↓

GitHub Actions

↓

OIDC Authentication

↓

Terraform

↓

AWS Infrastructure

↓

Dynamic Inventory

↓

Ansible

↓

Application Deployment

↓

Health Validation
```

---

# Technology Stack

| Category | Technologies |
|----------|--------------|
| Cloud | AWS |
| Infrastructure as Code | Terraform |
| Configuration Management | Ansible |
| CI/CD | GitHub Actions |
| Authentication | AWS IAM OIDC |
| Compute | Amazon EC2 |
| Load Balancing | Application Load Balancer |
| Networking | VPC, Public & Private Subnets |
| Remote Access | AWS Systems Manager |
| State Storage | Amazon S3 |
| State Locking | Amazon DynamoDB |
| Version Control | Git & GitHub |

---

# Repository Structure

```
enterprise-aws-platform-delivery-pipeline/

├── .github/
│   └── workflows/
├── ansible/
├── applications/
├── docs/
│   ├── project-summary.md
│   └── architecture/
│       ├── aws-architecture.md
│       ├── terraform-design.md
│       ├── ansible-platform.md
│       ├── cicd-workflow.md
│       ├── security-design.md
│       ├── operations-runbook.md
│       ├── cost-management.md
│       ├── troubleshooting-guide.md
│       └── future-improvements.md
├── scripts/
├── terraform/
└── README.md
```

---

# Documentation

| Document | Description |
|----------|-------------|
| `project-summary.md` | High-level overview of the platform |
| `aws-architecture.md` | AWS infrastructure design |
| `terraform-design.md` | Infrastructure as Code architecture |
| `ansible-platform.md` | Configuration management strategy |
| `cicd-workflow.md` | GitHub Actions deployment pipeline |
| `security-design.md` | Security architecture and controls |
| `operations-runbook.md` | Operational procedures and recovery |
| `cost-management.md` | Cost optimisation strategy |
| `troubleshooting-guide.md` | Common issues and resolutions |
| `future-improvements.md` | Roadmap for enterprise enhancements |

---

# Deployment Workflow

1. Developer pushes code to GitHub.
2. GitHub Actions starts automatically.
3. OIDC securely authenticates to AWS.
4. Terraform provisions or updates infrastructure.
5. Dynamic inventory discovers EC2 instances.
6. Ansible configures the platform.
7. Health checks validate the deployment.
8. Deployment completes successfully.

---

# Security Highlights

- OIDC authentication (no long-lived AWS access keys)
- IAM Roles with least privilege
- Private application subnets
- AWS Systems Manager instead of SSH
- Security Groups controlling network access
- Remote encrypted Terraform state
- Infrastructure fully defined as code

---

# Operational Model

The platform is designed to be:

- Automated
- Repeatable
- Secure
- Reproducible
- Cost-aware
- Easy to maintain

Infrastructure is provisioned when required, validated and then intentionally destroyed after testing to minimise AWS costs.

---

# Environment Status

> **Note:** The AWS development environment used for this project was intentionally destroyed after successful validation to minimise cloud costs. Because the platform is fully defined using Terraform and Ansible, it can be recreated at any time from the code in this repository.

---

# Skills Demonstrated

- Platform Engineering
- AWS Cloud
- Infrastructure as Code
- Terraform
- Ansible
- GitHub Actions
- CI/CD
- IAM & OIDC
- Linux Administration
- Automation
- Networking
- Security
- Systems Manager
- Operational Documentation
- Troubleshooting

---

# Future Enhancements

Planned improvements include:

- Docker
- Amazon EKS
- Blue-Green Deployments
- Canary Releases
- AWS Secrets Manager
- CloudWatch Observability
- Prometheus & Grafana
- Policy as Code
- Multi-Account AWS
- Disaster Recovery Automation

---

# License

This repository was developed as a portfolio project to demonstrate practical Platform Engineering skills and modern cloud infrastructure practices.

