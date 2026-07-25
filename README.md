# Enterprise AWS Platform Delivery Pipeline

A Git-driven enterprise Platform Engineering project that provisions AWS
infrastructure with Terraform, configures Linux servers with Ansible, deploys
applications through GitHub Actions, validates the resulting environment and
reports deployment outcomes.

## Delivery objective

A developer pushes code to GitHub. The platform automatically:

1. Validates the change.
2. Provisions or updates AWS infrastructure.
3. Generates configuration-management inventory.
4. Configures Linux servers.
5. Deploys the application.
6. Runs automated health checks.
7. Reports the deployment result.

## Core technologies

- GitHub
- GitHub Actions
- AWS
- Terraform
- Ansible
- Linux
- Nginx
- PowerShell
- Bash
- Python
