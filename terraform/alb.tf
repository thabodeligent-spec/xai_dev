# Application Load Balancer
resource "aws_lb" "dashboard" {
  count              = var.deployment_type == "ecs-fargate" ? 1 : 0
  name               = "${var.project_name}-${var.environment}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb[0].id]
  subnets            = aws_subnet.public[*].id
  
  enable_deletion_protection = var.environment == "prod" ? true : false
  enable_http2               = true
  
  access_logs {
    bucket  = aws_s3_bucket.logs.id
    prefix  = "alb"
    enabled = true
  }
  
  tags = {
    Name = "${var.project_name}-${var.environment}-alb"
  }
}

# Security Group for ALB
resource "aws_security_group" "alb" {
  count       = var.deployment_type == "ecs-fargate" ? 1 : 0
  name_prefix = "${var.project_name}-${var.environment}-alb-"
  description = "Security group for Application Load Balancer"
  vpc_id      = aws_vpc.main.id
  
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
    description = "Allow HTTP traffic"
  }
  
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
    description = "Allow HTTPS traffic"
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = {
    Name = "${var.project_name}-${var.environment}-alb-sg"
  }
  
  lifecycle {
    create_before_destroy = true
  }
}

# Target Group
resource "aws_lb_target_group" "dashboard" {
  count       = var.deployment_type == "ecs-fargate" ? 1 : 0
  name_prefix = substr("${var.project_name}-${var.environment}", 0, 6)
  port        = var.container_port
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"
  
  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    path                = var.health_check_path
    matcher             = "200"
  }
  
  deregistration_delay = 30
  
  tags = {
    Name = "${var.project_name}-${var.environment}-tg"
  }
  
  lifecycle {
    create_before_destroy = true
  }
}

# HTTP Listener (redirect to HTTPS if certificate provided)
resource "aws_lb_listener" "dashboard_http" {
  count             = var.deployment_type == "ecs-fargate" ? 1 : 0
  load_balancer_arn = aws_lb.dashboard[0].arn
  port              = "80"
  protocol          = "HTTP"
  
  default_action {
    type = var.ssl_certificate_arn != "" ? "redirect" : "forward"
    
    dynamic "redirect" {
      for_each = var.ssl_certificate_arn != "" ? [1] : []
      content {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }
    
    target_group_arn = var.ssl_certificate_arn == "" ? aws_lb_target_group.dashboard[0].arn : null
  }
  
  tags = {
    Name = "${var.project_name}-${var.environment}-http-listener"
  }
}

# HTTPS Listener (only if certificate provided)
resource "aws_lb_listener" "dashboard_https" {
  count             = var.deployment_type == "ecs-fargate" && var.ssl_certificate_arn != "" ? 1 : 0
  load_balancer_arn = aws_lb.dashboard[0].arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn   = var.ssl_certificate_arn
  
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.dashboard[0].arn
  }
  
  tags = {
    Name = "${var.project_name}-${var.environment}-https-listener"
  }
}

# Output ALB DNS
output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = var.deployment_type == "ecs-fargate" ? aws_lb.dashboard[0].dns_name : null
}

output "alb_url" {
  description = "URL to access the dashboard"
  value       = var.deployment_type == "ecs-fargate" ? "http://${aws_lb.dashboard[0].dns_name}" : null
}
