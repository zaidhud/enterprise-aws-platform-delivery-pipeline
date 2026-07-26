# CI/CD Pipeline Notes

## Terraform versus GitHub Actions

Terraform does not contain the instructions that execute the delivery pipeline.

Terraform creates the AWS resources and permissions that allow the pipeline to operate securely.

The CI/CD Terraform module is located at:

    terraform/modules/cicd/

It creates:

- The project-specific GitHub Actions IAM role
- The GitHub OIDC trust relationship
- Terraform remote-state permissions
- AWS infrastructure read permissions
- AWS Systems Manager session permissions
- Ansible S3 transfer-bucket permissions

The module is connected to the development environment through:

    terraform/environments/dev/main.tf

The IAM role outputs are exposed through:

    terraform/environments/dev/outputs.tf

## Pipeline instructions

The actual CI/CD pipeline instructions are not stored in Terraform.

They are stored in:

    .github/workflows/platform-delivery.yml

This GitHub Actions workflow defines:

- When the pipeline runs
- Which GitHub runner executes it
- AWS authentication through GitHub OIDC
- Terraform formatting
- Terraform validation
- Terraform planning
- Ansible installation
- Amazon AWS collection installation
- AWS Session Manager Plugin installation
- Dynamic AWS EC2 inventory discovery
- Rolling Ansible deployment
- Application health verification
- GitHub Actions deployment summaries

## Responsibility split

    Terraform
    ├── Creates AWS infrastructure
    ├── Creates the GitHub Actions IAM role
    ├── Creates IAM permissions
    └── Configures the GitHub OIDC trust relationship

    GitHub Actions
    ├── Executes the delivery pipeline
    ├── Assumes the AWS IAM role
    ├── Runs Terraform checks
    ├── Executes Ansible
    └── Produces deployment summaries

    Ansible
    ├── Discovers EC2 instances dynamically
    ├── Connects through AWS Systems Manager
    ├── Configures the EC2 instances
    ├── Deploys the application
    └── Performs rolling deployments

## End-to-end delivery flow

    Developer
        |
        v
    Git push to main
        |
        v
    GitHub Actions
        |
        v
    Authenticate to AWS through OIDC
        |
        v
    Terraform formatting
        |
        v
    Terraform validation
        |
        v
    Terraform plan
        |
        v
    Dynamic EC2 inventory
        |
        v
    Ansible rolling deployment
        |
        v
    Application health verification
        |
        v
    Deployment summary

## Important notes

- Terraform provisions the AWS resources required by the CI/CD pipeline.
- GitHub Actions contains and executes the pipeline instructions.
- Ansible owns server configuration and application deployment.
- GitHub OIDC removes the need for long-lived AWS access keys.
- AWS Systems Manager removes the need for SSH keys.
- Dynamic inventory automatically discovers EC2 instances using AWS metadata and tags.
- Rolling deployments update one instance at a time to minimise disruption.
- The pipeline currently runs Terraform validation and planning only.
- Terraform infrastructure changes are not applied automatically.
- Production approval gates and controlled Terraform apply stages can be introduced later.
