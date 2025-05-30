# Deploy a Node.js App on ECS using GitHub Actions with OIDC role

The following lines will guide you through using the GitHub Actions pipeline to deploy a Node.js application on AWS. The pipeline leverages AWS OIDC Roles for secure and passwordless authentication.

Before lauching this pipeline, ensure the following are in place:

## AWS Account

- Create an IAM Role (`github-actions-oidc-role` in this case) with appropriate permissions to manage ECR, ECS, and Terraform.
- Configure the IAM Role trust policy to allow GitHub’s OIDC provider for your repository.

### Create an AWS IAM role that GitHub Actions can assume using OpenID Connect (OIDC)

This setup allows GitHub Actions to authenticate with AWS without requiring long-lived credentials.

We need to create an IAM role named `github-actions-oidc-role` with the following AWS managed policies:

* `AmazonEC2ContainerRegistryFullAccess`
* `AmazonEC2ContainerRegistryPowerUser`
* `AmazonEC2FullAccess`
* `AmazonECS_FullAccess`
* `IAMFullAccess`

The role will trust GitHub’s OIDC provider to allow workflows from thr repository to assume the role.

**Prerequisites**

* Access to an AWS account with permissions to create IAM roles and identity providers.
* A GitHub repository where this role will be used.
* Basic knowledge of GitHub Actions and AWS IAM.


#### Step 1: Create the OIDC Identity Provider in AWS

1. Sign in to the AWS Management Console.

2. Navigate to **IAM** > **Identity Providers**.

3. Click **Add provider**.

4. Set the **Provider type** to `OIDC`.

5. For **Provider URL**, enter:

   ```
   https://token.actions.githubusercontent.com
   ```

6. For **Audience**, enter:

   ```
   sts.amazonaws.com
   ```

7. Click **Add provider** to save.


#### Step 2: Create the IAM Role `github-actions-oidc-role`

1. Go to **IAM** > **Roles**.

2. Click **Create role**.

3. Select **Web identity** as the trusted entity type.

4. Choose the OIDC provider you created: `token.actions.githubusercontent.com`.

5. Set the **Audience** to `sts.amazonaws.com`.

6. Replace:

   * `<OWNER>` with your GitHub username or organization: utrains
   * `<REPO>` with your repository name: Deploy-a-NodeJS-Application-on-AWS-Using-GithubActions
   * `<BRANCH>` with the branch name: GithubAction

7. Click **Next** to proceed.


#### Step 3: Attach Permissions

Attach the following AWS managed policies to the role:

* `AmazonEC2ContainerRegistryFullAccess`
* `AmazonEC2ContainerRegistryPowerUser`
* `AmazonEC2FullAccess`
* `AmazonECS_FullAccess`
* `IAMFullAccess`

Then click **Next**.


#### Step 4: Name the Role

* **Role name**: `github-actions-oidc-role`
* Add tags as needed (optional)
* Click **Create role**


#### Step 5: Save the Role ARN

After creation, copy the **Role ARN** from the role summary page. It will look like this:

```
arn:aws:iam::123456789012:role/github-actions-oidc-role
```


## GitHub Repository

- Contains the Node.js app source code.
- Includes Terraform configuration for infrastructure (under `infra/` directory).
- Includes Dockerfiles for backend and frontend under `infra/backend` and `infra/frontend`.

## GitHub Repository Settings

- Enable GitHub Actions.
- Grant the workflow permission to request OIDC tokens (`id-token: write`).
- Set repository environment for manual approvals (for destroy jobs).

### Configure GitHub Actions

1. In your GitHub repository, go to **Settings** > **Secrets and variables** > **Actions**.

2. Add a new secret:

   * Name: `AWS_ROLE_ARN`
   * Value: Paste the Role ARN you copied earlier.

3. Use the role in your GitHub Actions workflow like this:

```yaml
name: Deploy to AWS

on:
  push:
    branches:
      - main

permissions:
  id-token: write
  contents: read

jobs:
  deploy:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout repository
        uses: actions/checkout@v4

      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: ${{ secrets.AWS_ROLE_ARN }}
          aws-region: us-east-1

      - name: Display caller identity
        run: aws sts get-caller-identity
```

### Using Manual Approval in GitHub Actions Workflows

In some CI/CD scenarios when dealing with destructive infrastructure operations like tearing down environments, it's important to require **manual approval** before executing. GitHub Actions provides this functionality via **Environments** with required reviewers. We will see now  how to implement manual approval step-by-step:


#### 1. Create an Environment with Required Reviewers

1. Navigate to your GitHub repository.
2. Go to **Settings > Environments**.
3. Create a new environment named `destroy-approval`.
4. Under **Deployment protection rules**, add required reviewers (your GitHub username or a team).
5. Save the environment.

> This ensures any job using this environment will pause for approval before execution.

---

### 2. Define Workflow Jobs in `destroy.yml`

#### Apply Job

This job is assumed to run prior and generate a `terraform.tfstate` file saved as an artifact.

##### Manual Approval Job

```yaml
wait-for-ecs-destroy-approval:
  runs-on: ubuntu-latest
  needs: Apply-the-terraform-code-to-Launch-the-frontend-and-the-backend-app
  environment:
    name: destroy-approval  # Triggers manual approval
  steps:
    - name: Wait for Approval
      run: echo "Waiting for manual approval to destroy resources"
```

This job will not run until a GitHub reviewer approves it in the Actions tab.

##### Destroy Job

```yaml
destroy-ecs:
  runs-on: ubuntu-latest
  needs: wait-for-ecs-destroy-approval
  permissions:
    id-token: write
    contents: read

  steps:
    - name: Checkout Code
      uses: actions/checkout@v3

    - name: Setup Terraform
      uses: hashicorp/setup-terraform@v2
      with:
        terraform_version: 1.5.0

    - name: Install AWS CLI
      uses: unfor19/install-aws-cli-action@v1
      with:
        version: 2
        verbose: false
        arch: amd64

    - name: Configure AWS Credentials Using OIDC
      uses: aws-actions/configure-aws-credentials@v4
      with:
        role-to-assume: ${{ env.OIDC_ROLE_ARN }}
        aws-region: ${{ env.AWS_REGION }}

    - name: Download Artifact
      uses: actions/download-artifact@v4
      with:
        name: ecs-terraform-state-file

    - name: Use the terraform-state artifact
      run: |
        terraform init -input=false
        terraform refresh
        terraform destroy -auto-approve
```

---

#### How to Trigger Manual Approval?

1. Push code or trigger the workflow manually.
2. The workflow will pause at the `wait-for-ecs-destroy-approval` job.
3. Go to **Actions > Workflow Run > Approval Job**.
4. Click **Review deployments**.
5. Click **Approve and deploy**.

Once approved, the `destroy-ecs` job will run.


## Pipeline Environment Variables

In your workflow, the following environment variables are set globally:

```yaml
env:
  AWS_REGION: us-east-2
  FRONTEND_REPO: 885684264653.dkr.ecr.us-east-2.amazonaws.com/node-frontend-repo
  BACKEND_REPO: 885684264653.dkr.ecr.us-east-2.amazonaws.com/node-backend-repo
  TAG: latest
  OIDC_ROLE_ARN: ${{ secrets.AWS_ROLE_ARN }}
```
 - Replace the AWS Account ID and role ARN with your own values.
