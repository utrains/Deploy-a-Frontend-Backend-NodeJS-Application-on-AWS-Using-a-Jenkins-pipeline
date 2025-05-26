# Deploy a Node.js App on AWS using GitHub Actions with OIDC

The following lines will guide you through using the GitHub Actions pipeline to deploy a Node.js application on AWS. The pipeline leverages AWS OIDC Roles for secure and passwordless authentication.

## Prerequisites

Before you start, ensure the following are in place:

### AWS Account

- Create an IAM Role (e.g., `github-actions-oidc-role`) with appropriate permissions to manage ECR, ECS, and Terraform.
- Configure the IAM Role trust policy to allow GitHub’s OIDC provider for your repository.

### GitHub Repository

- Contains your Node.js app source code.
- Includes Terraform configuration for infrastructure (under `ecr/` directory).
- Includes Dockerfiles for backend and frontend under `ecr/backend` and `ecr/frontend`.

### GitHub Repository Settings

- Enable GitHub Actions.
- Grant the workflow permission to request OIDC tokens (`id-token: write`).
- Set repository environment for manual approvals (optional for destroy jobs).

---

## Pipeline Environment Variables

In your workflow, the following environment variables are set globally:

```yaml
env:
  AWS_REGION: us-east-2
  FRONTEND_REPO: 885684264653.dkr.ecr.us-east-2.amazonaws.com/node-frontend-repo
  BACKEND_REPO: 885684264653.dkr.ecr.us-east-2.amazonaws.com/node-backend-repo
  TAG: latest
  OIDC_ROLE_ARN: arn:aws:iam::885684264653:role/github-actions-oidc-role
```
 - Replace the AWS Account ID and role ARN with your own values.
