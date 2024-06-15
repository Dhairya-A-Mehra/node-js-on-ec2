provider "aws" {
  region = var.aws_region
}

resource "aws_ecr_repository" "hello_world_repo" {
  name = "hello-world-repo"
}

resource "aws_ecs_cluster" "hello_world_cluster" {
  name = "hello-world-cluster"
}

resource "aws_iam_role" "ecs_task_execution_role" {
  name = "ecsTaskExecutionRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
  ]
}

resource "aws_ecs_task_definition" "hello_world_task" {
  family                   = "hello-world-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"

  container_definitions = jsonencode([
    {
      name      = "hello-world"
      image     = "${aws_ecr_repository.hello_world_repo.repository_url}:latest"
      essential = true
      portMappings = [
        {
          containerPort = 3000
          hostPort      = 3000
        }
      ]
    }
  ])

  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn
}

resource "aws_ecs_service" "hello_world_service" {
  name            = "hello-world-service"
  cluster         = aws_ecs_cluster.hello_world_cluster.id
  task_definition = aws_ecs_task_definition.hello_world_task.arn
  desired_count   = 1

  network_configuration {
    subnets         = var.subnet_ids
    security_groups = var.security_group_ids
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_alb_target_group.hello_world_tg.arn
    container_name   = "hello-world"
    container_port   = 3000
  }
}

resource "aws_alb" "hello_world_alb" {
  name               = "hello-world-alb"
  internal           = false
  load_balancer_type = "application"

  security_groups = var.security_group_ids
  subnets         = var.subnet_ids
}

resource "aws_alb_target_group" "hello_world_tg" {
  name     = "hello-world-tg"
  port     = 3000
  protocol = "HTTP"
  vpc_id   = var.vpc_id
}

resource "aws_alb_listener" "hello_world_listener" {
  load_balancer_arn = aws_alb.hello_world_alb.arn
  po
