terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  
  # backend "s3" {
  #   # Uncomment and configure for remote state
  #   # bucket         = "your-terraform-state-bucket"
  #   # key            = "xai-dashboard/terraform.tfstate"
  #   # region         = "us-east-1"
  #   # encrypt        = true
  #   # dynamodb_table = "terraform-state-lock"
  # }
}

provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      Project     = "XAI-Student-Suicide-Prediction"
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}

# Data sources
data "aws_caller_identity" "current" {}
data "aws_availability_zones" "available" {
  state = "available"
}
