# Terraform Infrastructure - File Structure

## 📁 Project Structure

```
terraform/
├── 📄 main.tf                    # Main Terraform configuration
├── 📄 variables.tf               # Input variables definitions
├── 📄 outputs.tf                 # Output values
├── 📄 terraform.tfvars.example   # Example variables file (COPY TO terraform.tfvars)
│
├── 🌐 Infrastructure Components
│   ├── networking.tf             # VPC, subnets, NAT, IGW, VPC endpoints
│   ├── s3.tf                    # S3 buckets (models, data, static, logs)
│   ├── ecr.tf                   # Container registry for Docker images
│   ├── ecs.tf                   # ECS cluster, services, task definitions
│   ├── alb.tf                   # Application Load Balancer
│   ├── cloudfront.tf            # CloudFront CDN (optional)
│   ├── rds.tf                   # PostgreSQL database (optional)
│   └── monitoring.tf            # CloudWatch logs, metrics, alarms
│
├── 🐳 Container Configuration
│   ├── Dockerfile               # Container definition for dashboard
│   └── dockerignore.txt         # Files to exclude from Docker build
│
├── 🚀 Deployment
│   ├── deploy.sh                # Automated deployment script
│   └── .github/workflows/
│       └── deploy.yml           # CI/CD pipeline configuration
│
├── 📚 Documentation
│   ├── README.md                # Complete documentation
│   ├── QUICKSTART.md           # 10-minute deployment guide
│   ├── ARCHITECTURE.md         # Architecture details & diagrams
│   └── gitignore.txt           # Git ignore patterns
```

## 🎯 Core Files Explained

### Configuration Files

**main.tf**
- Terraform provider configuration (AWS)
- Backend configuration (state storage)
- Data sources (AWS account, AZs)

**variables.tf** (107 variables)
- AWS region and environment settings
- VPC and networking configuration
- ECS task specifications
- S3, RDS, CloudFront options
- Security and monitoring settings
- Auto-scaling parameters

**terraform.tfvars.example**
- Template for your configuration
- Must be copied to `terraform.tfvars`
- Contains sensible defaults for dev environment

### Infrastructure Modules

**networking.tf** (20 resources)
- VPC with customizable CIDR
- Public/private subnets across 2 AZs
- Internet Gateway + NAT Gateways
- Route tables and associations
- VPC endpoints for S3 and ECR

**s3.tf** (4 buckets + policies)
- Models bucket (versioned, encrypted)
- Data bucket (for predictions, exports)
- Static assets bucket (optional, for web content)
- Logs bucket (with lifecycle policies)

**ecr.tf** (1 repository + policy)
- Container registry for Docker images
- Lifecycle policy (keeps last 10 images)
- Automatic vulnerability scanning

**ecs.tf** (15+ resources)
- ECS Fargate cluster
- Task definitions (CPU, memory configs)
- ECS service with rolling deployments
- IAM roles for task execution
- Auto-scaling policies
- CloudWatch log groups

**alb.tf** (5 resources)
- Application Load Balancer
- Security groups
- Target group with health checks
- HTTP/HTTPS listeners
- SSL certificate support

**cloudfront.tf** (optional, 3 resources)
- CDN distribution
- S3 + ALB origins
- Cache behaviors for static/dynamic content
- HTTPS enforcement

**rds.tf** (optional, 6 resources)
- PostgreSQL database
- Secrets Manager for credentials
- Security groups
- Automated backups
- Enhanced monitoring

**monitoring.tf** (10+ resources)
- CloudWatch log groups
- Metrics and alarms
- SNS notifications
- CloudWatch dashboard
- Custom ML metrics

## 🔧 Usage Files

**Dockerfile**
- Multi-stage Python build
- Streamlit configuration
- Health check endpoint
- Optimized for production

**deploy.sh**
- One-command deployment
- Prerequisites checking
- Infrastructure provisioning
- Docker build and push
- Service updates
- Model uploads

**.github/workflows/deploy.yml**
- Automated CI/CD pipeline
- Run tests on PR
- Build Docker on push
- Deploy to AWS
- Update ECS service
- Notifications

## 📊 Resource Count

| Component | Resources | 
|-----------|-----------|
| VPC & Networking | 20+ |
| S3 Buckets | 4 |
| ECS/Fargate | 15+ |
| Load Balancer | 5 |
| CloudFront | 3 (optional) |
| RDS | 6 (optional) |
| Monitoring | 10+ |
| IAM Roles/Policies | 8+ |
| **Total** | **70+ resources** |

## 💻 Commands Cheat Sheet

### Initial Setup
```bash
# Copy and edit config
cp terraform.tfvars.example terraform.tfvars
nano terraform.tfvars

# Initialize
terraform init
```

### Deployment
```bash
# Preview changes
terraform plan

# Deploy
terraform apply

# Or use script
./deploy.sh full
```

### Docker Operations
```bash
# Build
docker build -t dashboard .

# Push to ECR
ECR_URL=$(terraform output -raw ecr_repository_url)
docker tag dashboard:latest $ECR_URL:latest
docker push $ECR_URL:latest
```

### Monitoring
```bash
# View logs
aws logs tail /ecs/xai-dashboard-dev --follow

# Check service status
aws ecs describe-services \
  --cluster $(terraform output -raw ecs_cluster_name) \
  --services $(terraform output -raw ecs_service_name)
```

### Cleanup
```bash
# Destroy all
terraform destroy

# Or
./deploy.sh destroy
```

## 🎨 Customization Guide

### Change AWS Region
```hcl
# terraform.tfvars
aws_region = "eu-west-1"  # Change from us-east-1
```

### Increase Resources (Production)
```hcl
# terraform.tfvars
environment         = "prod"
ecs_task_cpu        = 1024      # 1 vCPU
ecs_task_memory     = 2048      # 2 GB
ecs_desired_count   = 4         # 4 tasks
ecs_autoscaling_max = 10        # Scale to 10
enable_rds          = true      # Enable database
db_instance_class   = "db.t3.small"
```

### Enable HTTPS
```hcl
# First, create ACM certificate in AWS Console
# Then add to terraform.tfvars
ssl_certificate_arn = "arn:aws:acm:us-east-1:123456789:certificate/xxx"
```

### Restrict Access
```hcl
# Only allow your IP
allowed_cidr_blocks = ["YOUR_IP/32"]
```

### Enable CloudFront
```hcl
enable_cloudfront = true
enable_s3_static_hosting = true
```

## 🔐 Security Checklist

Before production deployment:
- [ ] Change `allowed_cidr_blocks` from `0.0.0.0/0`
- [ ] Add SSL certificate ARN
- [ ] Set `environment = "prod"`
- [ ] Update SNS email in `monitoring.tf`
- [ ] Enable MFA on AWS account
- [ ] Review IAM policies
- [ ] Enable RDS deletion protection
- [ ] Configure backup retention
- [ ] Set up AWS WAF (optional)
- [ ] Enable VPC Flow Logs (optional)

## 📝 Important Notes

1. **Bucket Names Must Be Unique**
   - Set `model_bucket_name` to a globally unique value
   - AWS S3 bucket names are global across all accounts

2. **First Deployment**
   - Takes 10-15 minutes for all resources
   - NAT Gateways take ~5 minutes to create
   - ECS service takes ~3 minutes to stabilize

3. **Costs**
   - Review ARCHITECTURE.md for detailed breakdown
   - Main costs: NAT Gateway ($32/month each)
   - Use single AZ for dev to save costs

4. **State Management**
   - State stored locally by default
   - For team use, configure S3 backend in main.tf
   - Uncomment backend block and add your bucket

5. **Updates**
   - Always run `terraform plan` first
   - Review changes before applying
   - Use `deploy.sh` for safer deployments

## 🆘 Troubleshooting

See README.md for detailed troubleshooting guide.

Quick fixes:
- **"Bucket already exists"**: Change `model_bucket_name`
- **Tasks not starting**: Check CloudWatch Logs
- **Cannot access**: Wait 2-3 minutes, check security groups
- **Apply fails**: Check AWS credentials, quotas

## 📚 Additional Resources

- AWS ECS Best Practices: https://docs.aws.amazon.com/AmazonECS/latest/bestpracticesguide/
- Terraform AWS Provider: https://registry.terraform.io/providers/hashicorp/aws/latest/docs
- Streamlit in Production: https://docs.streamlit.io/knowledge-base/deploy
