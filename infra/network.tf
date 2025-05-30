
# ~~~~~~~~~~~~~~~~ Configure the Network ~~~~~~~~~~~~~~~~~~~~~ 
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name             = var.project_name
  cidr             = var.VPC_cidr
  azs              = ["${var.AZ1}", "${var.AZ2}"]
  private_subnets  = ["${var.subnet_priv1_cidr}", "${var.subnet_priv2_cidr}"]
  public_subnets   = ["${var.subnet_pub1_cidr}", "${var.subnet_pub2_cidr}"]

  # One NAT gateway per subnet and a single NAT for all of them
  enable_nat_gateway = true
  single_nat_gateway = true

  # Enable DNS support and hostnames in the VPC
  enable_dns_support   = true
  enable_dns_hostnames = true

  private_subnet_tags = {
    Tier = "Private"
  }
  public_subnet_tags = {
    Tier = "Public"
  }
  tags = {
    Project = "${var.project_name}"
  }
}

# ~~~~~~~~~~~ Security group for the Frontend LoadBalancer ~~~~~~~~~~

resource "aws_security_group" "frontend_sg" {

  name        = "${var.frontend_app_name}-sg"
  description = "Security group for ${var.frontend_app_name} ecs"
  vpc_id      = module.vpc.vpc_id
  ingress {
    description = "allows connection from the internet"
    from_port   = var.frontend_port
    to_port     = var.frontend_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = {
    Name = "${var.frontend_app_name}-sg"
  }
}

# ~~~~~~~~~~~ Security group for the Backend LoadBalancer ~~~~~~~~~~

resource "aws_security_group" "backend_sg" {

  name        = "${var.backend_app_name}-sg"
  description = "Security group for ${var.backend_app_name} ecs"
  vpc_id      = module.vpc.vpc_id
  ingress {
    description = "allows inbound fron the front end"
    from_port   = var.backend_port
    to_port     = var.backend_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = {
    Name = "${var.backend_app_name}-sg"
  }
}