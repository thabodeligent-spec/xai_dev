# AWS Infrastructure for XAI Student Suicide Prediction Dashboard

This Terraform configuration deploys a complete, production-ready infrastructure for the ML-powered dashboard on AWS.

## 🏗️ Architecture Overview

### Components Deployed:

1. **Networking**
   - VPC with public and private subnets across 2 AZs
   - NAT Gateways for private subnet internet access
   - VPC Endpoints for S3 and ECR (cost optimization)

2. **Compute (ECS Fargate)**
   - ECS Cluster for container orchestration
   - Fargate tasks (serverless containers)
   - Auto-scaling based on CPU/Memory
   - Application Load Balancer for traffic distribution

3. **Storage**
   - S3 bucket for ML models (versioned, encrypted)
   - S3 bucket for processed data
   - S3 bucket for static assets (optional)
   - S3 bucket for logs with lifecycle policies

4. **Container Registry**
   - ECR repository for Docker images
   - Automatic image scanning
   - Lifecycle policies (keep last 10 images)

5. **Database (Optional)**
   - RDS PostgreSQL for storing predictions/logs
   - Multi-AZ deployment option
   - Automated backups
   - Credentials stored in Secrets Manager

6. **CDN (Optional)**
   - CloudFront distribution for global content delivery
   - S3 origin for static assets
   - ALB origin for dynamic content

7. **Monitoring**
   - CloudWatch Logs for application logs
   - CloudWatch Metrics for performance monitoring
   - CloudWatch Alarms for critical events
   - SNS notifications for alerts
   - Custom dashboard for metrics visualization

## 📋 Prerequisites

1. **AWS Account** with appropriate permissions
2. **Terraform** >= 1.0 ([Download](https://www.terraform.io/downloads))
3. **AWS CLI** configured with credentials ([Setup Guide](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-configure.html))
4. **Docker** for building container images ([Download](https://www.docker.com/get-started))

### AWS Permissions Required

Your AWS user/role needs these permissions:
- VPC, Subnet, Route Table, Internet Gateway, NAT Gateway
- ECS, ECR
- S3
- CloudWatch, CloudWatch Logs
- IAM (for creating roles and policies)
- Application Load Balancer
- CloudFront (optional)
- RDS (optional)
- Secrets Manager (optional)

## 🚀 Quick Start

### 1. Configure Variables

Copy the example variables file:
```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` with your configuration:
```hcl
aws_region      = "us-east-1"
environment     = "dev"
project_name    = "xai-dashboard"
deployment_type = "ecs-fargate"

# Set a unique bucket name (must be globally unique)
model_bucket_name = "my-company-xai-models-12345"

# Optional: Add SSL certificate ARN for HTTPS
# ssl_certificate_arn = "arn:aws:acm:us-east-1:123456789:certificate/xxx"
```

### 2. Initialize Terraform

```bash
terraform init
```

### 3. Plan Infrastructure

```bash
terraform plan
```

Review the planned changes carefully.

### 4. Deploy Infrastructure

```bash
terraform apply
```

Type `yes` when prompted to confirm.

### 5. Build and Push Docker Image

After infrastructure is deployed:

```bash
# Get ECR repository URL
ECR_URL=$(terraform output -raw ecr_repository_url)

# Login to ECR
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin $ECR_URL

# Build and push image
docker build -t $ECR_URL:latest .
docker push $ECR_URL:latest
```

### 6. Update ECS Service

```bash
aws ecs update-service \
  --cluster $(terraform output -raw ecs_cluster_name) \
  --service $(terraform output -raw ecs_service_name) \
  --force-new-deployment
```

### 7. Access Your Dashboard

```bash
terraform output dashboard_url
```

## 🛠️ Using the Deployment Script

We've included a convenient deployment script:

```bash
# Full deployment
./deploy.sh full

# Individual steps
./deploy.sh init     # Initialize Terraform
./deploy.sh plan     # Plan changes
./deploy.sh apply    # Apply changes
./deploy.sh build    # Build and push Docker image
./deploy.sh update   # Update ECS service
./deploy.sh destroy  # Destroy infrastructure
```

## 📊 Monitoring and Logs

### View Application Logs

```bash
# Tail logs in real-time
aws logs tail /ecs/xai-dashboard-dev --follow

# Filter for errors
aws logs tail /ecs/xai-dashboard-dev --filter-pattern "ERROR"
```

### CloudWatch Dashboard

Access your CloudWatch dashboard:
```bash
terraform output cloudwatch_dashboard_url
```

### Alerts

Configure SNS email notifications in `monitoring.tf` and confirm the subscription email.

## 🔐 Security Best Practices

### 1. Restrict Access

Update `allowed_cidr_blocks` in `terraform.tfvars`:
```hcl
allowed_cidr_blocks = ["YOUR_IP/32"]  # Replace with your IP
```

### 2. Enable HTTPS

1. Request an ACM certificate in AWS Console
2. Add certificate ARN to `terraform.tfvars`:
```hcl
ssl_certificate_arn = "arn:aws:acm:us-east-1:123456789:certificate/xxx"
```
3. Run `terraform apply`

### 3. Enable Deletion Protection (Production)

Set environment to "prod":
```hcl
environment = "prod"
```

This enables:
- RDS deletion protection
- ALB deletion protection
- Extended backup retention

## 💰 Cost Optimization

### Estimated Monthly Costs (us-east-1):

**Development Environment:**
- ECS Fargate (2 tasks, 0.5 vCPU, 1GB): ~$30
- ALB: ~$20
- NAT Gateway (2 AZs): ~$65
- S3 Storage (50GB): ~$1
- CloudWatch Logs (10GB): ~$5
- **Total: ~$121/month**

**Production Environment (with RDS):**
- Add RDS db.t3.micro: ~$15
- Add CloudFront: ~$20 (with 100GB transfer)
- **Total: ~$156/month**

### Cost Reduction Tips:

1. **Use Single AZ for Dev:**
   ```hcl
   availability_zones_count = 1
   ```

2. **Disable NAT Gateways for Non-Production:**
   - Use public subnets for ECS tasks
   - Remove NAT Gateways

3. **Reduce Task Count:**
   ```hcl
   ecs_desired_count = 1
   ```

4. **Use S3 Lifecycle Policies:**
   - Already configured for logs bucket
   - Consider adding for data bucket

## 🔄 CI/CD Integration

### GitHub Actions Example

Create `.github/workflows/deploy.yml`:

```yaml
name: Deploy to AWS

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      
      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v1
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: us-east-1
      
      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v1
      
      - name: Terraform Init
        run: terraform init
      
      - name: Terraform Apply
        run: terraform apply -auto-approve
      
      - name: Build and Push Docker
        run: |
          ECR_URL=$(terraform output -raw ecr_repository_url)
          aws ecr get-login-password | docker login --username AWS --password-stdin $ECR_URL
          docker build -t $ECR_URL:latest .
          docker push $ECR_URL:latest
      
      - name: Update ECS Service
        run: |
          aws ecs update-service \
            --cluster $(terraform output -raw ecs_cluster_name) \
            --service $(terraform output -raw ecs_service_name) \
            --force-new-deployment
```

## 📦 Uploading ML Models

### Upload Models to S3

```bash
# Get bucket name
MODEL_BUCKET=$(terraform output -raw s3_model_bucket)

# Upload models
aws s3 cp models/random_forest.pkl s3://$MODEL_BUCKET/models/
aws s3 cp models/xgboost.pkl s3://$MODEL_BUCKET/models/

# Upload entire directory
aws s3 sync models/ s3://$MODEL_BUCKET/models/
```

### Access Models in Application

Models are accessible via environment variables:
```python
import boto3
import os

s3 = boto3.client('s3')
bucket = os.environ['MODEL_BUCKET']

# Download model
s3.download_file(bucket, 'models/random_forest.pkl', '/tmp/model.pkl')
```

## 🗄️ Database Usage (Optional)

### Enable Database

In `terraform.tfvars`:
```hcl
enable_rds = true
db_instance_class = "db.t3.micro"  # or larger for production
```

### Connect to Database

Credentials are stored in AWS Secrets Manager:

```python
import boto3
import json

def get_db_credentials():
    secret_name = "xai-dashboard-dev-db-password"
    client = boto3.client('secretsmanager')
    response = client.get_secret_value(SecretId=secret_name)
    return json.loads(response['SecretString'])

# Use credentials
creds = get_db_credentials()
connection_string = f"postgresql://{creds['username']}:{creds['password']}@{creds['host']}:{creds['port']}/{creds['dbname']}"
```

## 🧹 Cleanup

### Destroy All Resources

```bash
terraform destroy
```

**Warning:** This will permanently delete:
- All ECS services and tasks
- Load balancers
- RDS databases (unless deletion protection enabled)
- S3 buckets (must be empty first)
- All networking components

### Empty S3 Buckets First

```bash
# List buckets
terraform output

# Empty each bucket
aws s3 rm s3://bucket-name --recursive
```

## 🔧 Troubleshooting

### ECS Tasks Not Starting

1. Check CloudWatch Logs:
```bash
aws logs tail /ecs/xai-dashboard-dev --follow
```

2. Verify Docker image exists in ECR:
```bash
aws ecr describe-images --repository-name xai-dashboard-dev
```

3. Check ECS task definition:
```bash
aws ecs describe-task-definition --task-definition xai-dashboard-dev
```

### High Costs

1. Check for idle NAT Gateways
2. Review CloudWatch Logs retention
3. Check S3 storage usage
4. Review ECS task count and size

### Cannot Access Dashboard

1. Check security group rules
2. Verify ALB health checks are passing
3. Check target group health
4. Review CloudWatch Alarms

## 📚 Additional Resources

- [Terraform AWS Provider Docs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [ECS Best Practices](https://docs.aws.amazon.com/AmazonECS/latest/bestpracticesguide/)
- [Streamlit Documentation](https://docs.streamlit.io/)
- [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Test changes in a dev environment
4. Submit a pull request

## 📄 License

[Your License Here]

## 💡 Support

For issues or questions:
1. Check the troubleshooting section
2. Review CloudWatch Logs
3. Open an issue on GitHub
4. Contact the DevOps team
