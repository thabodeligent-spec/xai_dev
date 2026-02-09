output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "IDs of public subnets"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs of private subnets"
  value       = aws_subnet.private[*].id
}

output "s3_model_bucket" {
  description = "S3 bucket name for ML models"
  value       = aws_s3_bucket.models.id
}

output "s3_data_bucket" {
  description = "S3 bucket name for data"
  value       = aws_s3_bucket.data.id
}

output "s3_static_bucket" {
  description = "S3 bucket name for static assets"
  value       = var.enable_s3_static_hosting ? aws_s3_bucket.static_assets[0].id : null
}

output "s3_logs_bucket" {
  description = "S3 bucket name for logs"
  value       = aws_s3_bucket.logs.id
}

output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = var.deployment_type == "ecs-fargate" ? aws_ecs_cluster.main[0].name : null
}

output "ecs_service_name" {
  description = "Name of the ECS service"
  value       = var.deployment_type == "ecs-fargate" ? aws_ecs_service.dashboard[0].name : null
}

output "dashboard_url" {
  description = "URL to access the dashboard"
  value = var.enable_cloudfront ? (
    "https://${aws_cloudfront_distribution.dashboard[0].domain_name}"
  ) : (
    var.deployment_type == "ecs-fargate" ? "http://${aws_lb.dashboard[0].dns_name}" : null
  )
}

output "cloudwatch_dashboard_url" {
  description = "URL to CloudWatch dashboard"
  value       = var.deployment_type == "ecs-fargate" ? "https://console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards:name=${aws_cloudwatch_dashboard.main[0].dashboard_name}" : null
}

output "sns_topic_arn" {
  description = "ARN of SNS topic for alerts"
  value       = aws_sns_topic.alerts.arn
}

output "deployment_instructions" {
  description = "Next steps for deployment"
  value = <<-EOT
    
    ============================================
    DEPLOYMENT INSTRUCTIONS
    ============================================
    
    1. Build and push Docker image:
       aws ecr get-login-password --region ${var.aws_region} | docker login --username AWS --password-stdin ${aws_ecr_repository.dashboard.repository_url}
       docker build -t ${aws_ecr_repository.dashboard.repository_url}:latest .
       docker push ${aws_ecr_repository.dashboard.repository_url}:latest
    
    2. Update ECS service (if already running):
       aws ecs update-service --cluster ${var.deployment_type == "ecs-fargate" ? aws_ecs_cluster.main[0].name : "N/A"} --service ${var.deployment_type == "ecs-fargate" ? aws_ecs_service.dashboard[0].name : "N/A"} --force-new-deployment
    
    3. Access your dashboard:
       ${var.enable_cloudfront ? "https://${aws_cloudfront_distribution.dashboard[0].domain_name}" : (var.deployment_type == "ecs-fargate" ? "http://${aws_lb.dashboard[0].dns_name}" : "N/A")}
    
    4. Upload ML models to S3:
       aws s3 cp models/ s3://${aws_s3_bucket.models.id}/models/ --recursive
    
    5. Monitor logs:
       aws logs tail ${var.deployment_type == "ecs-fargate" ? aws_cloudwatch_log_group.ecs[0].name : "N/A"} --follow
    
    6. Update SNS email subscription:
       Check your email and confirm the SNS subscription for alerts
    
    ${var.enable_rds ? "7. Database credentials stored in AWS Secrets Manager: ${aws_secretsmanager_secret.db_password[0].arn}" : ""}
    
    ============================================
    EOT
}
