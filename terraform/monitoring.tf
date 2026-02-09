# SNS Topic for Alerts
resource "aws_sns_topic" "alerts" {
  name = "${var.project_name}-${var.environment}-alerts"
  
  tags = {
    Name = "${var.project_name}-${var.environment}-alerts"
  }
}

# SNS Topic Subscription (update with your email)
resource "aws_sns_topic_subscription" "alerts_email" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = "your-email@example.com"  # CHANGE THIS
}

# CloudWatch Alarms for ECS
resource "aws_cloudwatch_metric_alarm" "ecs_cpu_high" {
  count               = var.deployment_type == "ecs-fargate" ? 1 : 0
  alarm_name          = "${var.project_name}-${var.environment}-ecs-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 300
  statistic           = "Average"
  threshold           = var.cpu_threshold_high
  alarm_description   = "This metric monitors ECS CPU utilization"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  
  dimensions = {
    ClusterName = aws_ecs_cluster.main[0].name
    ServiceName = aws_ecs_service.dashboard[0].name
  }
  
  tags = {
    Name = "${var.project_name}-${var.environment}-ecs-cpu-high"
  }
}

resource "aws_cloudwatch_metric_alarm" "ecs_memory_high" {
  count               = var.deployment_type == "ecs-fargate" ? 1 : 0
  alarm_name          = "${var.project_name}-${var.environment}-ecs-memory-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "This metric monitors ECS memory utilization"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  
  dimensions = {
    ClusterName = aws_ecs_cluster.main[0].name
    ServiceName = aws_ecs_service.dashboard[0].name
  }
  
  tags = {
    Name = "${var.project_name}-${var.environment}-ecs-memory-high"
  }
}

# CloudWatch Alarm for ALB Target Health
resource "aws_cloudwatch_metric_alarm" "alb_unhealthy_targets" {
  count               = var.deployment_type == "ecs-fargate" ? 1 : 0
  alarm_name          = "${var.project_name}-${var.environment}-unhealthy-targets"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "UnHealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Average"
  threshold           = 0
  alarm_description   = "Alert when there are unhealthy targets"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  
  dimensions = {
    LoadBalancer = aws_lb.dashboard[0].arn_suffix
    TargetGroup  = aws_lb_target_group.dashboard[0].arn_suffix
  }
  
  tags = {
    Name = "${var.project_name}-${var.environment}-unhealthy-targets"
  }
}

# CloudWatch Alarm for ALB 5XX Errors
resource "aws_cloudwatch_metric_alarm" "alb_5xx_errors" {
  count               = var.deployment_type == "ecs-fargate" ? 1 : 0
  alarm_name          = "${var.project_name}-${var.environment}-alb-5xx-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "HTTPCode_Target_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 300
  statistic           = "Sum"
  threshold           = 10
  alarm_description   = "Alert on high 5XX error rate"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  
  dimensions = {
    LoadBalancer = aws_lb.dashboard[0].arn_suffix
  }
  
  tags = {
    Name = "${var.project_name}-${var.environment}-alb-5xx-errors"
  }
}

# CloudWatch Dashboard
resource "aws_cloudwatch_dashboard" "main" {
  count          = var.deployment_type == "ecs-fargate" ? 1 : 0
  dashboard_name = "${var.project_name}-${var.environment}"
  
  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/ECS", "CPUUtilization", { stat = "Average" }],
            [".", "MemoryUtilization", { stat = "Average" }]
          ]
          period = 300
          stat   = "Average"
          region = var.aws_region
          title  = "ECS Service Metrics"
          yAxis = {
            left = {
              min = 0
              max = 100
            }
          }
        }
      },
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/ApplicationELB", "RequestCount", { stat = "Sum" }],
            [".", "TargetResponseTime", { stat = "Average" }]
          ]
          period = 300
          stat   = "Average"
          region = var.aws_region
          title  = "ALB Metrics"
        }
      },
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/ApplicationELB", "HealthyHostCount", { stat = "Average" }],
            [".", "UnHealthyHostCount", { stat = "Average" }]
          ]
          period = 300
          stat   = "Average"
          region = var.aws_region
          title  = "Target Health"
        }
      },
      {
        type = "log"
        properties = {
          query   = "SOURCE '${aws_cloudwatch_log_group.ecs[0].name}' | fields @timestamp, @message | sort @timestamp desc | limit 100"
          region  = var.aws_region
          title   = "Recent Logs"
        }
      }
    ]
  })
}

# Custom Metrics for ML Model Performance (example)
resource "aws_cloudwatch_log_metric_filter" "prediction_count" {
  count          = var.deployment_type == "ecs-fargate" ? 1 : 0
  name           = "PredictionCount"
  pattern        = "[time, request_id, level=INFO, msg=\"Prediction made\"]"
  log_group_name = aws_cloudwatch_log_group.ecs[0].name
  
  metric_transformation {
    name      = "PredictionCount"
    namespace = "${var.project_name}/${var.environment}"
    value     = "1"
  }
}

resource "aws_cloudwatch_log_metric_filter" "high_risk_predictions" {
  count          = var.deployment_type == "ecs-fargate" ? 1 : 0
  name           = "HighRiskPredictions"
  pattern        = "[time, request_id, level=INFO, msg=\"High risk detected\"]"
  log_group_name = aws_cloudwatch_log_group.ecs[0].name
  
  metric_transformation {
    name      = "HighRiskPredictions"
    namespace = "${var.project_name}/${var.environment}"
    value     = "1"
  }
}

# Alarm for High Risk Predictions
resource "aws_cloudwatch_metric_alarm" "high_risk_spike" {
  count               = var.deployment_type == "ecs-fargate" ? 1 : 0
  alarm_name          = "${var.project_name}-${var.environment}-high-risk-spike"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "HighRiskPredictions"
  namespace           = "${var.project_name}/${var.environment}"
  period              = 300
  statistic           = "Sum"
  threshold           = 20  # Alert if >20 high-risk predictions in 5 minutes
  alarm_description   = "Alert on unusual spike in high-risk predictions"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  treat_missing_data  = "notBreaching"
  
  tags = {
    Name = "${var.project_name}-${var.environment}-high-risk-spike"
  }
}
