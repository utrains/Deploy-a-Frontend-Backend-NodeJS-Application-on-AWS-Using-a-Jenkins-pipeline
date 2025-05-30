
# ~~~~~~~~~~~~~~~ Get the ID of the current aws account ~~~~~~~~~~~~~~

data "aws_caller_identity" "current" {}

# ~~~~~~~~ Set the command we will later as a locals variables ~~~~~~~

locals {
  ecr-login             = "aws ecr get-login-password --region ${var.region} | docker login --username AWS --password-stdin ${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.region}.amazonaws.com"
  docker-build-frontend = "docker build -t ${aws_ecr_repository.repository-frontend.repository_url}:latest frontend"
  docker-push-frontend  = "docker push ${aws_ecr_repository.repository-frontend.repository_url}:latest"
  docker-build-backend  = "docker build -t ${aws_ecr_repository.repository-backend.repository_url}:latest backend"
  docker-push-backend   = "docker push ${aws_ecr_repository.repository-backend.repository_url}:latest"
}

# ~~~~ Log in to the aws ECR service of the current account to have enough rights to push images in ecr ~~~~

# Build script
resource "local_file" "docker_build_script" {
  content = <<-EOT
    #!/bin/bash
    
    # Build The Frontend Image from the Dockerfile of the frontend
    echo "Building frontend Docker image from the Dockerfile of the frontend"
    ${local.docker-build-frontend}

    # Build The Backend Image from the Dockerfile of the backend
    echo "Building backend Docker image from the Dockerfile of the backend"
    ${local.docker-build-backend}
  EOT

  filename        = "${path.module}/docker-build-script.sh"
  file_permission = "0755"
}

# Push script
resource "local_file" "docker_push_script" {
  content = <<-EOT
    #!/bin/bash
    
    echo "Logging in to ECR"
    ${local.ecr-login}

    # Push The Frontend Image to the frontend ECR repository
    echo "Pushing frontend Docker image to the frontend ECR repository"
    ${local.docker-push-frontend}

    # Push The Backend Image to the backend ECR repositor
    echo "Pushing backend Docker image. to the backend ECR repository"
    ${local.docker-push-backend}
  EOT

  filename        = "${path.module}/docker-push-script.sh"
  file_permission = "0755"
}
