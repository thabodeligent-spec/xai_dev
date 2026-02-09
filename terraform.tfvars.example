# AWS Configuration
aws_region  = "us-east-1"
environment = "dev"

# Project Configuration
project_name    = "xai-dashboard"
deployment_type = "ecs-fargate"  # Options: ecs-fargate, elastic-beanstalk, ec2

# VPC Configuration
vpc_cidr                 = "10.0.0.0/16"
availability_zones_count = 2

# ECS Configuration
ecs_task_cpu        = 512   # CPU units (256, 512, 1024, 2048, 4096)
ecs_task_memory     = 1024  # Memory in MB
ecs_desired_count   = 2     # Number of tasks to run
ecs_autoscaling_min = 1     # Minimum tasks for autoscaling
ecs_autoscaling_max = 4     # Maximum tasks for autoscaling

# Application Configuration
container_port     = 8501  # Streamlit default port
health_check_path  = "/_stcore/health"
# docker_image     = ""    # Will use ECR image by default

# S3 Configuration
enable_s3_static_hosting = true
enable_cloudfront        = true
model_bucket_name        = ""  # Leave empty to auto-generate

# Database Configuration (Optional)
enable_rds        = false  # Set to true to enable PostgreSQL database
db_instance_class = "db.t3.micro"

# Monitoring
enable_detailed_monitoring = true
log_retention_days         = 30

# Security
allowed_cidr_blocks = ["0.0.0.0/0"]  # Restrict to your IP for production
# ssl_certificate_arn = ""           # Add ACM certificate ARN for HTTPS

# Auto Scaling
cpu_threshold_high = 70
cpu_threshold_low  = 30

# Additional Tags
additional_tags = {
  Department = "Data Science"
  Owner      = "ML Team"
  CostCenter = "Research"
}
