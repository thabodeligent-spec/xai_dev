# ECS Cluster
resource "aws_ecs_cluster" "main" {
  count = var.deployment_type == "ecs-fargate" ? 1 : 0
  name  = "${var.project_name}-${var.environment}-cluster"
  
  setting {
    name  = "containerInsights"
    value = var.enable_detailed_monitoring ? "enabled" : "disabled"
  }
  
  tags = {
    Name = "${var.project_name}-${var.environment}-ecs-cluster"
  }
}

# CloudWatch Log Group for ECS
resource "aws_cloudwatch_log_group" "ecs" {
  count             = var.deployment_type == "ecs-fargate" ? 1 : 0
  name              = "/ecs/${var.project_name}-${var.environment}"
  retention_in_days = var.log_retention_days
  
  tags = {
    Name = "${var.project_name}-${var.environment}-ecs-logs"
  }
}

# ECS Task Execution Role
resource "aws_iam_role" "ecs_task_execution" {
  count = var.deployment_type == "ecs-fargate" ? 1 : 0
  name  = "${var.project_name}-${var.environment}-ecs-task-execution"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
  
  tags = {
    Name = "${var.project_name}-${var.environment}-ecs-task-execution-role"
  }
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution" {
  count      = var.deployment_type == "ecs-fargate" ? 1 : 0
  role       = aws_iam_role.ecs_task_execution[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# ECS Task Role (for application permissions)
resource "aws_iam_role" "ecs_task" {
  count = var.deployment_type == "ecs-fargate" ? 1 : 0
  name  = "${var.project_name}-${var.environment}-ecs-task"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
  
  tags = {
    Name = "${var.project_name}-${var.environment}-ecs-task-role"
  }
}

# Policy for ECS Task to access S3 buckets
resource "aws_iam_role_policy" "ecs_task_s3" {
  count = var.deployment_type == "ecs-fargate" ? 1 : 0
  name  = "s3-access"
  role  = aws_iam_role.ecs_task[0].id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.models.arn,
          "${aws_s3_bucket.models.arn}/*",
          aws_s3_bucket.data.arn,
          "${aws_s3_bucket.data.arn}/*"
        ]
      }
    ]
  })
}

# ECS Task Definition
resource "aws_ecs_task_definition" "dashboard" {
  count                    = var.deployment_type == "ecs-fargate" ? 1 : 0
  family                   = "${var.project_name}-${var.environment}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.ecs_task_cpu
  memory                   = var.ecs_task_memory
  execution_role_arn       = aws_iam_role.ecs_task_execution[0].arn
  task_role_arn            = aws_iam_role.ecs_task[0].arn
  
  container_definitions = jsonencode([
    {
      name  = "dashboard"
      image = var.docker_image != "" ? var.docker_image : "${aws_ecr_repository.dashboard.repository_url}:latest"
      
      portMappings = [
        {
          containerPort = var.container_port
          protocol      = "tcp"
        }
      ]
      
      environment = [
        {
          name  = "ENVIRONMENT"
          value = var.environment
        },
        {
          name  = "AWS_REGION"
          value = var.aws_region
        },
        {
          name  = "MODEL_BUCKET"
          value = aws_s3_bucket.models.id
        },
        {
          name  = "DATA_BUCKET"
          value = aws_s3_bucket.data.id
        }
      ]
      
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.ecs[0].name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }
      
      healthCheck = {
        command     = ["CMD-SHELL", "curl -f http://localhost:${var.container_port}${var.health_check_path} || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 60
      }
    }
  ])
  
  tags = {
    Name = "${var.project_name}-${var.environment}-task-definition"
  }
}

# Security Group for ECS Tasks
resource "aws_security_group" "ecs_tasks" {
  count       = var.deployment_type == "ecs-fargate" ? 1 : 0
  name_prefix = "${var.project_name}-${var.environment}-ecs-tasks-"
  description = "Security group for ECS tasks"
  vpc_id      = aws_vpc.main.id
  
  ingress {
    from_port       = var.container_port
    to_port         = var.container_port
    protocol        = "tcp"
    security_groups = [aws_security_group.alb[0].id]
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = {
    Name = "${var.project_name}-${var.environment}-ecs-tasks-sg"
  }
  
  lifecycle {
    create_before_destroy = true
  }
}

# ECS Service
resource "aws_ecs_service" "dashboard" {
  count           = var.deployment_type == "ecs-fargate" ? 1 : 0
  name            = "${var.project_name}-${var.environment}"
  cluster         = aws_ecs_cluster.main[0].id
  task_definition = aws_ecs_task_definition.dashboard[0].arn
  desired_count   = var.ecs_desired_count
  launch_type     = "FARGATE"
  
  network_configuration {
    subnets          = aws_subnet.private[*].id
    security_groups  = [aws_security_group.ecs_tasks[0].id]
    assign_public_ip = false
  }
  
  load_balancer {
    target_group_arn = aws_lb_target_group.dashboard[0].arn
    container_name   = "dashboard"
    container_port   = var.container_port
  }
  
  deployment_configuration {
    maximum_percent         = 200
    minimum_healthy_percent = 100
  }
  
  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }
  
  depends_on = [
    aws_lb_listener.dashboard_http,
    aws_iam_role_policy_attachment.ecs_task_execution
  ]
  
  tags = {
    Name = "${var.project_name}-${var.environment}-ecs-service"
  }
}

# Auto Scaling Target
resource "aws_appautoscaling_target" "ecs" {
  count              = var.deployment_type == "ecs-fargate" ? 1 : 0
  max_capacity       = var.ecs_autoscaling_max
  min_capacity       = var.ecs_autoscaling_min
  resource_id        = "service/${aws_ecs_cluster.main[0].name}/${aws_ecs_service.dashboard[0].name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

# Auto Scaling Policy - CPU
resource "aws_appautoscaling_policy" "ecs_cpu" {
  count              = var.deployment_type == "ecs-fargate" ? 1 : 0
  name               = "${var.project_name}-${var.environment}-cpu-autoscaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs[0].resource_id
  scalable_dimension = aws_appautoscaling_target.ecs[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs[0].service_namespace
  
  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value       = var.cpu_threshold_high
    scale_in_cooldown  = 300
    scale_out_cooldown = 60
  }
}

# Auto Scaling Policy - Memory
resource "aws_appautoscaling_policy" "ecs_memory" {
  count              = var.deployment_type == "ecs-fargate" ? 1 : 0
  name               = "${var.project_name}-${var.environment}-memory-autoscaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs[0].resource_id
  scalable_dimension = aws_appautoscaling_target.ecs[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs[0].service_namespace
  
  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }
    target_value       = 80
    scale_in_cooldown  = 300
    scale_out_cooldown = 60
  }
}
