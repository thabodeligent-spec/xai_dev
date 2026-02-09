# Quick Start Guide - Deploy in 10 Minutes

## Prerequisites
- AWS Account with admin access
- AWS CLI configured (`aws configure`)
- Terraform installed
- Docker installed

## Step-by-Step Deployment

### 1. Configure (2 minutes)
```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars`:
```hcl
model_bucket_name = "your-unique-bucket-name-12345"  # MUST BE GLOBALLY UNIQUE
aws_region        = "us-east-1"
environment       = "dev"
```

### 2. Deploy Infrastructure (5 minutes)
```bash
# Option A: Use deployment script (recommended)
./deploy.sh full

# Option B: Manual steps
terraform init
terraform plan
terraform apply
```

### 3. Build and Deploy Application (3 minutes)
```bash
# Get ECR URL
ECR_URL=$(terraform output -raw ecr_repository_url)

# Login to ECR
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin $ECR_URL

# Build and push
docker build -t $ECR_URL:latest .
docker push $ECR_URL:latest

# Update ECS
aws ecs update-service \
  --cluster $(terraform output -raw ecs_cluster_name) \
  --service $(terraform output -raw ecs_service_name) \
  --force-new-deployment
```

### 4. Access Dashboard
```bash
# Get URL
terraform output dashboard_url

# Or use CloudFront (if enabled)
terraform output cloudfront_url
```

## Common Issues

### "Bucket name already exists"
- Change `model_bucket_name` in terraform.tfvars to a unique value

### "Docker build failed"
- Ensure you're in the project root directory
- Check that Dockerfile exists

### "ECS tasks not starting"
- Check CloudWatch Logs: `aws logs tail /ecs/xai-dashboard-dev --follow`
- Verify Docker image was pushed successfully

### "Cannot access dashboard"
- Wait 2-3 minutes for ECS tasks to start
- Check ALB target health in AWS Console
- Verify security group allows your IP

## Cost Estimate
- Development: ~$120/month
- Production: ~$160/month (with RDS)

## Cleanup
```bash
# Destroy everything
terraform destroy

# Or use script
./deploy.sh destroy
```

## Next Steps
1. Upload ML models: `aws s3 cp models/ s3://$(terraform output -raw s3_model_bucket)/models/ --recursive`
2. Configure custom domain (optional)
3. Enable HTTPS with ACM certificate
4. Set up monitoring alerts
5. Configure CI/CD pipeline

## Support
- Check README.md for detailed documentation
- Review CloudWatch Logs for errors
- Check Terraform state: `terraform show`
