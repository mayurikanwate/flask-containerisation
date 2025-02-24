# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"  # Change this to your preferred region
}

# Create an AWS Elastic Container Registry (ECR) Repository
resource "aws_ecr_repository" "flask_repo" {
  name = "flask-containerization"

  lifecycle {
    ignore_changes = [ name ]
  }
}

# Create an ECS Cluster
resource "aws_ecs_cluster" "flask_cluster" {
  name = "flask-cluster"
}

# IAM Role for ECS Task Execution
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "ecsTaskExecutionRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

# Attach the required IAM policy to the role
resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Create an ECS Task Definition
resource "aws_ecs_task_definition" "flask_task" {
  family                   = "flask-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  cpu                      = "256"
  memory                   = "512"

  container_definitions = jsonencode([
    {
      name  = "flask-container"
      image = aws_ecr_repository.flask_repo.repository_url
      cpu   = 256
      memory = 512
      essential = true
      portMappings = [
        {
          containerPort = 5000
          hostPort      = 5000
        }
      ]
    }
  ])
}

# Create a Security Group for ECS Service
resource "aws_security_group" "ecs_sg" {
  name        = "ecs-flask-sg"
  description = "Allow inbound access to Flask ECS service"
  vpc_id      = "vpc-05cd74aa2c8a296eb"  # Replace with your actual VPC ID

  ingress {
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Open access to Flask app (can be restricted)
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Deploy an ECS Service (Without Load Balancer)
resource "aws_ecs_service" "flask_service" {
  name            = "flask-service"
  cluster         = aws_ecs_cluster.flask_cluster.id
  task_definition = aws_ecs_task_definition.flask_task.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = ["subnet-0bbbe9ee7629c0bc5", "subnet-05f39844d40a14989"]  # Replace with actual Subnet IDs
    security_groups = [aws_security_group.ecs_sg.id]
    assign_public_ip = true  # This allows the service to be accessible via public IP
  }
}

