# CloudFront Origin Access Identity
resource "aws_cloudfront_origin_access_identity" "static" {
  count   = var.enable_cloudfront && var.enable_s3_static_hosting ? 1 : 0
  comment = "OAI for ${var.project_name} static assets"
}

# S3 Bucket Policy for CloudFront
resource "aws_s3_bucket_policy" "cloudfront_static" {
  count  = var.enable_cloudfront && var.enable_s3_static_hosting ? 1 : 0
  bucket = aws_s3_bucket.static_assets[0].id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudFrontAccess"
        Effect = "Allow"
        Principal = {
          AWS = aws_cloudfront_origin_access_identity.static[0].iam_arn
        }
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.static_assets[0].arn}/*"
      }
    ]
  })
}

# CloudFront Distribution
resource "aws_cloudfront_distribution" "dashboard" {
  count   = var.enable_cloudfront ? 1 : 0
  enabled = true
  comment = "${var.project_name}-${var.environment} CDN"
  
  # S3 Origin for static assets
  dynamic "origin" {
    for_each = var.enable_s3_static_hosting ? [1] : []
    content {
      domain_name = aws_s3_bucket.static_assets[0].bucket_regional_domain_name
      origin_id   = "S3-static-assets"
      
      s3_origin_config {
        origin_access_identity = aws_cloudfront_origin_access_identity.static[0].cloudfront_access_identity_path
      }
    }
  }
  
  # ALB Origin for dynamic content
  dynamic "origin" {
    for_each = var.deployment_type == "ecs-fargate" ? [1] : []
    content {
      domain_name = aws_lb.dashboard[0].dns_name
      origin_id   = "ALB-dashboard"
      
      custom_origin_config {
        http_port              = 80
        https_port             = 443
        origin_protocol_policy = var.ssl_certificate_arn != "" ? "https-only" : "http-only"
        origin_ssl_protocols   = ["TLSv1.2"]
      }
    }
  }
  
  # Default cache behavior (for static assets)
  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = var.enable_s3_static_hosting ? "S3-static-assets" : "ALB-dashboard"
    
    forwarded_values {
      query_string = false
      
      cookies {
        forward = "none"
      }
    }
    
    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
    compress               = true
  }
  
  # Cache behavior for dynamic dashboard content
  dynamic "ordered_cache_behavior" {
    for_each = var.deployment_type == "ecs-fargate" ? [1] : []
    content {
      path_pattern     = "/api/*"
      allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
      cached_methods   = ["GET", "HEAD"]
      target_origin_id = "ALB-dashboard"
      
      forwarded_values {
        query_string = true
        headers      = ["Host", "Origin", "Referer"]
        
        cookies {
          forward = "all"
        }
      }
      
      viewer_protocol_policy = "redirect-to-https"
      min_ttl                = 0
      default_ttl            = 0
      max_ttl                = 0
      compress               = true
    }
  }
  
  # Cache behavior for Streamlit WebSocket connections
  dynamic "ordered_cache_behavior" {
    for_each = var.deployment_type == "ecs-fargate" ? [1] : []
    content {
      path_pattern     = "/_stcore/*"
      allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
      cached_methods   = ["GET", "HEAD"]
      target_origin_id = "ALB-dashboard"
      
      forwarded_values {
        query_string = true
        headers      = ["*"]
        
        cookies {
          forward = "all"
        }
      }
      
      viewer_protocol_policy = "redirect-to-https"
      min_ttl                = 0
      default_ttl            = 0
      max_ttl                = 0
    }
  }
  
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
  
  viewer_certificate {
    cloudfront_default_certificate = var.ssl_certificate_arn == ""
    acm_certificate_arn            = var.ssl_certificate_arn != "" ? var.ssl_certificate_arn : null
    ssl_support_method             = var.ssl_certificate_arn != "" ? "sni-only" : null
    minimum_protocol_version       = var.ssl_certificate_arn != "" ? "TLSv1.2_2021" : "TLSv1"
  }
  
  price_class = "PriceClass_100"  # US, Canada, Europe
  
  tags = {
    Name = "${var.project_name}-${var.environment}-cdn"
  }
}

# Output CloudFront URL
output "cloudfront_domain_name" {
  description = "CloudFront distribution domain name"
  value       = var.enable_cloudfront ? aws_cloudfront_distribution.dashboard[0].domain_name : null
}

output "cloudfront_url" {
  description = "CloudFront distribution URL"
  value       = var.enable_cloudfront ? "https://${aws_cloudfront_distribution.dashboard[0].domain_name}" : null
}
