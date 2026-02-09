# S3 Bucket for ML Models
resource "aws_s3_bucket" "models" {
  bucket = var.model_bucket_name != "" ? var.model_bucket_name : "${var.project_name}-${var.environment}-models-${data.aws_caller_identity.current.account_id}"
  
  tags = {
    Name    = "ML Models Storage"
    Purpose = "Store trained models and artifacts"
  }
}

resource "aws_s3_bucket_versioning" "models" {
  bucket = aws_s3_bucket.models.id
  
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "models" {
  bucket = aws_s3_bucket.models.id
  
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "models" {
  bucket = aws_s3_bucket.models.id
  
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# S3 Bucket for Static Assets (optional)
resource "aws_s3_bucket" "static_assets" {
  count  = var.enable_s3_static_hosting ? 1 : 0
  bucket = "${var.project_name}-${var.environment}-static-${data.aws_caller_identity.current.account_id}"
  
  tags = {
    Name    = "Static Assets"
    Purpose = "Dashboard static files, visualizations, reports"
  }
}

resource "aws_s3_bucket_website_configuration" "static_assets" {
  count  = var.enable_s3_static_hosting ? 1 : 0
  bucket = aws_s3_bucket.static_assets[0].id
  
  index_document {
    suffix = "index.html"
  }
  
  error_document {
    key = "error.html"
  }
}

resource "aws_s3_bucket_cors_configuration" "static_assets" {
  count  = var.enable_s3_static_hosting ? 1 : 0
  bucket = aws_s3_bucket.static_assets[0].id
  
  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "HEAD"]
    allowed_origins = ["*"]
    expose_headers  = ["ETag"]
    max_age_seconds = 3000
  }
}

resource "aws_s3_bucket_public_access_block" "static_assets" {
  count  = var.enable_s3_static_hosting ? 1 : 0
  bucket = aws_s3_bucket.static_assets[0].id
  
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "static_assets" {
  count  = var.enable_s3_static_hosting && !var.enable_cloudfront ? 1 : 0
  bucket = aws_s3_bucket.static_assets[0].id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.static_assets[0].arn}/*"
      }
    ]
  })
}

# S3 Bucket for Application Logs
resource "aws_s3_bucket" "logs" {
  bucket = "${var.project_name}-${var.environment}-logs-${data.aws_caller_identity.current.account_id}"
  
  tags = {
    Name    = "Application Logs"
    Purpose = "Store application and access logs"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id
  
  rule {
    id     = "delete-old-logs"
    status = "Enabled"
    
    expiration {
      days = 90
    }
    
    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id
  
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "logs" {
  bucket = aws_s3_bucket.logs.id
  
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# S3 Bucket for Data Processing
resource "aws_s3_bucket" "data" {
  bucket = "${var.project_name}-${var.environment}-data-${data.aws_caller_identity.current.account_id}"
  
  tags = {
    Name    = "Data Storage"
    Purpose = "Processed datasets, predictions, exports"
  }
}

resource "aws_s3_bucket_versioning" "data" {
  bucket = aws_s3_bucket.data.id
  
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "data" {
  bucket = aws_s3_bucket.data.id
  
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "data" {
  bucket = aws_s3_bucket.data.id
  
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
