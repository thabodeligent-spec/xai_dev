variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "xai-dashboard"
}

variable "deployment_type" {
  description = "Deployment type: ecs-fargate, elastic-beanstalk, or ec2"
  type        = string
  default     = "ecs-fargate"
  
  validation {
    condition     = contains(["ecs-fargate", "elastic-beanstalk", "ec2"], var.deployment_type)
    error_message = "deployment_type must be ecs-fargate, elastic-beanstalk, or ec2"
  }
}

# VPC Configuration
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones_count" {
  description = "Number of availability zones to use"
  type        = number
  default     = 2
}

# ECS Configuration
variable "ecs_task_cpu" {
  description = "CPU units for ECS task (256, 512, 1024, 2048, 4096)"
  type        = number
  default     = 512
}

variable "ecs_task_memory" {
  description = "Memory for ECS task in MB"
  type        = number
  default     = 1024
}

variable "ecs_desired_count" {
  description = "Desired number of ECS tasks"
  type        = number
  default     = 2
}

variable "ecs_autoscaling_min" {
  description = "Minimum number of tasks for autoscaling"
  type        = number
  default     = 1
}

variable "ecs_autoscaling_max" {
  description = "Maximum number of tasks for autoscaling"
  type        = number
  default     = 4
}

# Application Configuration
variable "container_port" {
  description = "Port the container exposes"
  type        = number
  default     = 8501  # Streamlit default
}

variable "health_check_path" {
  description = "Health check endpoint path"
  type        = string
  default     = "/_stcore/health"  # Streamlit health check
}

variable "docker_image" {
  description = "Docker image URI (ECR or Docker Hub)"
  type        = string
  default     = ""  # Will be set after building image
}

# S3 Configuration
variable "enable_s3_static_hosting" {
  description = "Enable S3 static website hosting for assets"
  type        = bool
  default     = true
}

variable "enable_cloudfront" {
  description = "Enable CloudFront CDN"
  type        = bool
  default     = true
}

# Database Configuration (Optional)
variable "enable_rds" {
  description = "Enable RDS PostgreSQL for storing predictions/logs"
  type        = bool
  default     = false
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

# Model Storage
variable "model_bucket_name" {
  description = "S3 bucket name for ML models (must be globally unique)"
  type        = string
  default     = ""  # Set this to a unique name
}

# Monitoring
variable "enable_detailed_monitoring" {
  description = "Enable detailed CloudWatch monitoring"
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 30
}

# Security
variable "allowed_cidr_blocks" {
  description = "CIDR blocks allowed to access the dashboard"
  type        = list(string)
  default     = ["0.0.0.0/0"]  # Change to restrict access
}

variable "ssl_certificate_arn" {
  description = "ARN of ACM certificate for HTTPS (optional)"
  type        = string
  default     = ""
}

# Auto Scaling
variable "cpu_threshold_high" {
  description = "CPU utilization threshold for scaling up"
  type        = number
  default     = 70
}

variable "cpu_threshold_low" {
  description = "CPU utilization threshold for scaling down"
  type        = number
  default     = 30
}

# Tags
variable "additional_tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default     = {}
}
