# AWS Architecture Documentation

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────────┐
│                              CloudFront CDN                              │
│                     (Global Content Delivery - Optional)                 │
└────────────────────────────────┬────────────────────────────────────────┘
                                 │
                    ┌────────────┴────────────┐
                    │                         │
                    ▼                         ▼
        ┌───────────────────┐     ┌──────────────────┐
        │  S3 Static Assets │     │  Application     │
        │   (Images, CSS)   │     │  Load Balancer   │
        └───────────────────┘     └────────┬─────────┘
                                           │
                                           │ HTTPS/HTTP
                    ┌──────────────────────┴──────────────────────┐
                    │                                              │
          ┌─────────▼─────────┐                          ┌────────▼──────────┐
          │   Public Subnet   │                          │   Public Subnet   │
          │   (AZ-1)          │                          │   (AZ-2)          │
          │                   │                          │                   │
          │  ┌─────────────┐  │                          │  ┌─────────────┐  │
          │  │ NAT Gateway │  │                          │  │ NAT Gateway │  │
          │  └──────┬──────┘  │                          │  └──────┬──────┘  │
          └─────────┼─────────┘                          └─────────┼─────────┘
                    │                                              │
          ┌─────────▼─────────┐                          ┌────────▼──────────┐
          │  Private Subnet   │                          │  Private Subnet   │
          │   (AZ-1)          │                          │   (AZ-2)          │
          │                   │                          │                   │
          │  ┌────────────┐   │                          │  ┌────────────┐   │
          │  │ ECS Task 1 │◄──┼──────────────────────────┤─►│ ECS Task 2 │   │
          │  │ (Fargate)  │   │                          │  │ (Fargate)  │   │
          │  └─────┬──────┘   │                          │  └─────┬──────┘   │
          │        │          │                          │        │          │
          └────────┼──────────┘                          └────────┼──────────┘
                   │                                              │
                   │              ┌──────────────┐               │
                   └──────────────┤   RDS        │───────────────┘
                                  │  PostgreSQL  │
                                  │  (Optional)  │
                                  └──────────────┘

┌──────────────────────────────────────────────────────────────────────┐
│                          Storage Layer                               │
├──────────────────────────────────────────────────────────────────────┤
│  ┌───────────────┐  ┌───────────────┐  ┌───────────────┐           │
│  │  S3: Models   │  │  S3: Data     │  │  S3: Logs     │           │
│  │  (Versioned)  │  │  (Encrypted)  │  │  (Lifecycle)  │           │
│  └───────────────┘  └───────────────┘  └───────────────┘           │
└──────────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────────┐
│                       Monitoring & Logging                           │
├──────────────────────────────────────────────────────────────────────┤
│  ┌─────────────┐  ┌──────────────┐  ┌────────────┐  ┌────────────┐ │
│  │ CloudWatch  │  │ CloudWatch   │  │ CloudWatch │  │    SNS     │ │
│  │   Logs      │  │   Metrics    │  │   Alarms   │  │   Alerts   │ │
│  └─────────────┘  └──────────────┘  └────────────┘  └────────────┘ │
└──────────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────────┐
│                      Container Registry                              │
├──────────────────────────────────────────────────────────────────────┤
│  ┌───────────────────────────────────────────────────────────────┐  │
│  │ ECR (Elastic Container Registry)                              │  │
│  │ - Docker images for dashboard application                     │  │
│  │ - Automatic vulnerability scanning                            │  │
│  │ - Lifecycle policies (keep last 10 images)                    │  │
│  └───────────────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────────────┘
```

## Data Flow

### 1. User Request Flow
```
User Browser → CloudFront → ALB → ECS Tasks → S3/RDS → Response
```

### 2. Static Asset Flow
```
User Browser → CloudFront → S3 Static Bucket → Cache → User
```

### 3. ML Prediction Flow
```
Dashboard → Load Model from S3 → Run Inference → Store Results (S3/RDS) → Display
```

### 4. Deployment Flow
```
GitHub → CI/CD Pipeline → Build Docker → Push to ECR → Update ECS → Rolling Deployment
```

## Component Details

### VPC Configuration
- **CIDR**: 10.0.0.0/16
- **Availability Zones**: 2 (for high availability)
- **Public Subnets**: 10.0.0.0/24, 10.0.1.0/24
- **Private Subnets**: 10.0.10.0/24, 10.0.11.0/24
- **NAT Gateways**: 2 (one per AZ)
- **Internet Gateway**: 1

### ECS Fargate
- **Launch Type**: Fargate (serverless)
- **CPU**: 512 units (0.5 vCPU)
- **Memory**: 1024 MB (1 GB)
- **Desired Count**: 2 tasks
- **Auto-scaling**: 1-4 tasks based on CPU/Memory
- **Health Checks**: Streamlit health endpoint

### Application Load Balancer
- **Type**: Application Load Balancer
- **Scheme**: Internet-facing
- **Listeners**: HTTP (80), HTTPS (443 - optional)
- **Target Group**: ECS tasks on port 8501
- **Health Check**: /_stcore/health

### S3 Buckets
1. **Models Bucket**
   - Versioning: Enabled
   - Encryption: AES-256
   - Access: Private (ECS tasks only)

2. **Data Bucket**
   - Versioning: Enabled
   - Encryption: AES-256
   - Purpose: Processed datasets, predictions

3. **Static Assets Bucket** (Optional)
   - Website hosting: Enabled
   - CORS: Configured
   - Access: Public (via CloudFront)

4. **Logs Bucket**
   - Lifecycle: 30 days STANDARD, then IA
   - Expiration: 90 days
   - Purpose: ALB access logs

### CloudFront (Optional)
- **Origins**: S3 (static) + ALB (dynamic)
- **Price Class**: US, Canada, Europe
- **SSL/TLS**: TLS 1.2 minimum
- **Caching**: 
  - Static assets: 1 hour default
  - API/dynamic: No caching

### RDS PostgreSQL (Optional)
- **Engine**: PostgreSQL 15.4
- **Instance**: db.t3.micro
- **Storage**: 20 GB (auto-scaling to 100 GB)
- **Encryption**: Enabled
- **Backups**: 7 days (prod), 1 day (dev)
- **Multi-AZ**: Configurable

### Security

#### Security Groups
1. **ALB Security Group**
   - Inbound: 80, 443 from 0.0.0.0/0 (configurable)
   - Outbound: All traffic

2. **ECS Tasks Security Group**
   - Inbound: 8501 from ALB
   - Outbound: All traffic (for S3, ECR, etc.)

3. **RDS Security Group**
   - Inbound: 5432 from ECS tasks
   - Outbound: None required

4. **VPC Endpoints Security Group**
   - Inbound: 443 from VPC CIDR
   - Outbound: All traffic

#### IAM Roles
1. **ECS Task Execution Role**
   - Pull images from ECR
   - Write logs to CloudWatch
   - Get secrets from Secrets Manager

2. **ECS Task Role**
   - Read/Write to S3 buckets
   - Access RDS via Secrets Manager
   - Custom application permissions

3. **RDS Monitoring Role**
   - Enhanced monitoring metrics

### Monitoring & Alarms

#### CloudWatch Metrics
- ECS CPU Utilization
- ECS Memory Utilization
- ALB Request Count
- ALB Target Response Time
- ALB 5XX Errors
- Unhealthy Target Count

#### Custom Metrics
- Prediction Count
- High Risk Prediction Count

#### Alarms
- High CPU (>70%) → Scale up
- High Memory (>80%) → Scale up
- Unhealthy Targets → SNS notification
- 5XX Error Spike → SNS notification
- High Risk Spike → SNS notification

### Auto-scaling Policies
1. **CPU-based Scaling**
   - Target: 70% utilization
   - Scale out: Add 1 task when >70% for 60s
   - Scale in: Remove 1 task when <30% for 300s

2. **Memory-based Scaling**
   - Target: 80% utilization
   - Scale out: Add 1 task when >80% for 60s
   - Scale in: Remove 1 task when <40% for 300s

## Networking Details

### VPC Endpoints
- **S3 Endpoint**: Gateway endpoint for cost-free S3 access
- **ECR API Endpoint**: Interface endpoint for Docker pulls
- **ECR DKR Endpoint**: Interface endpoint for image layers

### Route Tables
1. **Public Route Table**
   - 0.0.0.0/0 → Internet Gateway
   - Associated with public subnets

2. **Private Route Tables** (2)
   - 0.0.0.0/0 → NAT Gateway (one per AZ)
   - Associated with private subnets

## Cost Breakdown

### Monthly Costs (us-east-1, dev environment)

| Resource | Configuration | Cost/Month |
|----------|--------------|------------|
| ECS Fargate | 2 tasks, 0.5 vCPU, 1GB | $30 |
| Application Load Balancer | 1 ALB | $20 |
| NAT Gateways | 2 gateways | $65 |
| S3 Storage | 50 GB | $1 |
| CloudWatch Logs | 10 GB | $5 |
| Data Transfer | 100 GB | $9 |
| **Total (without RDS)** | | **~$130** |
| RDS db.t3.micro | Optional | +$15 |
| CloudFront | Optional, 100GB | +$20 |
| **Total (full stack)** | | **~$165** |

### Cost Optimization
- Use single AZ for dev: -$32/month
- Reduce task count to 1: -$15/month
- Use spot instances: -30%
- Remove NAT gateways (use public subnets): -$65/month

## Security Best Practices

### Implemented
✅ Private subnets for ECS tasks
✅ Security groups with minimal permissions
✅ S3 bucket encryption
✅ VPC endpoints to avoid internet traffic
✅ IAM roles with least privilege
✅ Secrets Manager for database credentials
✅ CloudWatch logging enabled
✅ HTTPS support (with certificate)
✅ RDS encryption at rest

### Recommended
🔲 Enable AWS WAF on ALB
🔲 Configure GuardDuty
🔲 Enable AWS Config for compliance
🔲 Use AWS Shield for DDoS protection
🔲 Implement VPC Flow Logs
🔲 Set up AWS Security Hub
🔲 Enable MFA for AWS account
🔲 Rotate database credentials regularly

## Disaster Recovery

### Backup Strategy
- **RDS**: Automated daily backups (7 days retention in prod)
- **S3**: Versioning enabled for models and data
- **ECS**: Stateless containers, quick recovery
- **Configuration**: Terraform state in S3 backend

### Recovery Procedures
1. **ECS Task Failure**: Auto-recovery via ECS service
2. **AZ Failure**: Traffic automatically routes to healthy AZ
3. **Complete Region Failure**: 
   - Store Terraform state in different region
   - Cross-region S3 replication for models
   - RDS cross-region read replica

### RTO/RPO Targets
- **RTO (Recovery Time Objective)**: < 15 minutes
- **RPO (Recovery Point Objective)**: < 24 hours

## Scalability

### Current Limits
- ECS Tasks: 1-4 (configurable)
- ALB: 20 targets per target group
- RDS: db.t3.micro can handle ~100 concurrent connections

### Scaling Path
1. **100 users**: Current config sufficient
2. **1,000 users**: Increase to db.t3.small, 4-8 ECS tasks
3. **10,000 users**: db.r5.large, 10-20 ECS tasks, enable caching
4. **100,000+ users**: Multi-region, Aurora, ElastiCache, larger instances

## Maintenance

### Regular Tasks
- Weekly: Review CloudWatch metrics and alarms
- Monthly: Review and optimize costs
- Monthly: Check for security updates
- Quarterly: Review and update IAM policies
- Quarterly: Test disaster recovery procedures

### Updates
- **Terraform**: Update providers quarterly
- **Docker Base Image**: Monthly security updates
- **Dependencies**: Update Python packages monthly
- **AWS Services**: Review and adopt new features

## Compliance

### HIPAA Considerations
⚠️ **Note**: This is a student mental health application. If handling PHI:
- Enable encryption in transit and at rest (✅ implemented)
- Use AWS HIPAA-eligible services (✅ ECS, RDS, S3)
- Sign AWS BAA (Business Associate Agreement)
- Implement audit logging (✅ CloudWatch)
- Enable VPC Flow Logs
- Implement data retention policies

### FERPA Compliance
For student data:
- Implement access controls (✅ IAM roles)
- Enable audit trails (✅ CloudWatch)
- Data encryption (✅ implemented)
- Secure data transmission (✅ HTTPS)
- Regular security assessments
