
# ~~~~~~~~~~~~~~~~ Create a Load Balancer for the frontend app ~~~~~~~~~~~~~~~~

resource "aws_lb" "frontend_lb" {
  name            = "${var.frontend_app_name}-lb"
  subnets         = [module.vpc.public_subnets[0], module.vpc.public_subnets[1]]
  security_groups = [aws_security_group.frontend_sg.id]
}

# ~~~~~~~~~~~~~~~~ Create a Load Balancer for the backend app ~~~~~~~~~~~~~~~~

resource "aws_lb" "backend_lb" {
  name            = "${var.backend_app_name}-lb"
  subnets         = [module.vpc.public_subnets[0], module.vpc.public_subnets[1]]
  security_groups = [aws_security_group.backend_sg.id]
}

# ~~~~~~~~~~~~~~~~ Create a target Group for the backend~~~~~~~~~~~~~~

resource "aws_lb_target_group" "backend_target_group" {

  name        = "${var.backend_app_name}-targets-group"
  port        = var.backend_port
  protocol    = "HTTP"
  vpc_id      = module.vpc.vpc_id
  target_type = "ip"
}
# ~~~~~~~~~~~~~~~~ Create a listener for the backend ~~~~~~~~~~~~~~~~

resource "aws_lb_listener" "backend_listener" {

  load_balancer_arn = aws_lb.backend_lb.arn
  port              = var.backend_port
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend_target_group.arn
  }
}

# ~~~~~~~~~~~~~~~~ Create a target Group for the frontend ~~~~~~~~~~~~~

resource "aws_lb_target_group" "frontend_target_group" {

  name        = "${var.frontend_app_name}-targets-group"
  port        = var.frontend_port
  protocol    = "HTTP"
  vpc_id      = module.vpc.vpc_id
  target_type = "ip"

}

# ~~~~~~~~~~~~~~~~ Create a listener for the frontend ~~~~~~~~~~~~~

resource "aws_lb_listener" "frontend_listener" {

  load_balancer_arn = aws_lb.frontend_lb.arn
  port              = var.frontend_port
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend_target_group.arn
  }
}

# ~~~~~~~~~~~~~~~~~~ Create ECS EXECUTION Role ~~~~~~~~~~~~~~~~~~~~

module "ecs_execution_role" {
  source = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"

  create_role = true

  role_requires_mfa = false

  role_name = "${var.project_name}-ecs-execution-role"

  trusted_role_services = [
    "ecs-tasks.amazonaws.com"
  ]

  custom_role_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
     "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess",
  ]
}

# ~~~~~~~~~~~~~~~~~~~~~ Creating ECS Cluster ~~~~~~~~~~~~~~~~~~~~~~~

resource "aws_ecs_cluster" "cluster" {
  name = var.cluster_name
}

# ~~~~~~~~ Create the ECR Repository for the Frontend app ~~~~~~~~~

resource "aws_ecr_repository" "repository-frontend" {
  name = "${var.frontend_app_name}-repo"

  image_scanning_configuration {
    scan_on_push = false
  }
  
  force_delete = true
}

# ~~~~~~~~ Create the ECR Repository for the Backend app ~~~~~~~~~
resource "aws_ecr_repository" "repository-backend" {
  name = "${var.backend_app_name}-repo"

  image_scanning_configuration {
    scan_on_push = false
  }
  
  force_delete = true
}

# ~~~~~~~~~~ Clean Up docker images too when the infrastructure is destoyed ~~~~~~~~~

# resource "null_resource" "clean-up-images" {
	
#	  provisioner "local-exec" {

#      when = destroy
#	     command =<<EOF
#		          docker rmi `docker image ls | grep "end-repo" | awk '{print $1}'`
#		          EOF
#       interpreter = [
#           "bash",
#           "-c"
#         ]
#	  }
#	
#}

output "INFO" {
  value = "AWS Resources  has been provisioned. Go to ${aws_ecr_repository.repository-backend.repository_url} and ${aws_ecr_repository.repository-frontend.repository_url}"
}
