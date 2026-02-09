#!/bin/bash

# Deployment script for XAI Dashboard to AWS
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
TERRAFORM_DIR="$SCRIPT_DIR"

# Functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    if ! command -v terraform &> /dev/null; then
        log_error "Terraform is not installed. Please install it from https://www.terraform.io/downloads"
        exit 1
    fi
    
    if ! command -v aws &> /dev/null; then
        log_error "AWS CLI is not installed. Please install it from https://aws.amazon.com/cli/"
        exit 1
    fi
    
    if ! command -v docker &> /dev/null; then
        log_error "Docker is not installed. Please install it from https://www.docker.com/get-started"
        exit 1
    fi
    
    # Check AWS credentials
    if ! aws sts get-caller-identity &> /dev/null; then
        log_error "AWS credentials not configured. Run 'aws configure'"
        exit 1
    fi
    
    log_info "All prerequisites met!"
}

# Initialize Terraform
init_terraform() {
    log_info "Initializing Terraform..."
    cd "$TERRAFORM_DIR"
    
    if [ ! -f "terraform.tfvars" ]; then
        log_warn "terraform.tfvars not found. Copying from example..."
        cp terraform.tfvars.example terraform.tfvars
        log_warn "Please edit terraform.tfvars with your configuration before continuing."
        exit 1
    fi
    
    terraform init
    log_info "Terraform initialized successfully!"
}

# Plan infrastructure
plan_infrastructure() {
    log_info "Planning infrastructure..."
    cd "$TERRAFORM_DIR"
    terraform plan -out=tfplan
    
    read -p "Do you want to continue with this plan? (yes/no): " confirm
    if [ "$confirm" != "yes" ]; then
        log_warn "Deployment cancelled."
        exit 0
    fi
}

# Apply infrastructure
apply_infrastructure() {
    log_info "Applying infrastructure..."
    cd "$TERRAFORM_DIR"
    terraform apply tfplan
    rm tfplan
    log_info "Infrastructure deployed successfully!"
}

# Build and push Docker image
build_and_push_image() {
    log_info "Building Docker image..."
    
    # Get ECR repository URL from Terraform output
    ECR_URL=$(terraform output -raw ecr_repository_url)
    AWS_REGION=$(terraform output -json | jq -r '.vpc_id.value' | cut -d':' -f4)
    
    log_info "ECR Repository: $ECR_URL"
    
    # Login to ECR
    log_info "Logging in to ECR..."
    aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin $ECR_URL
    
    # Build Docker image
    log_info "Building Docker image..."
    cd "$SCRIPT_DIR/.."
    docker build -t xai-dashboard:latest -f "$SCRIPT_DIR/Dockerfile" .
    
    # Tag image
    docker tag xai-dashboard:latest $ECR_URL:latest
    docker tag xai-dashboard:latest $ECR_URL:$(date +%Y%m%d-%H%M%S)
    
    # Push to ECR
    log_info "Pushing image to ECR..."
    docker push $ECR_URL:latest
    docker push $ECR_URL:$(date +%Y%m%d-%H%M%S)
    
    log_info "Docker image pushed successfully!"
}

# Update ECS service
update_ecs_service() {
    log_info "Updating ECS service..."
    
    CLUSTER_NAME=$(cd "$TERRAFORM_DIR" && terraform output -raw ecs_cluster_name)
    SERVICE_NAME=$(cd "$TERRAFORM_DIR" && terraform output -raw ecs_service_name)
    
    if [ -z "$CLUSTER_NAME" ] || [ -z "$SERVICE_NAME" ]; then
        log_warn "ECS cluster or service not found. Skipping service update."
        return
    fi
    
    aws ecs update-service \
        --cluster "$CLUSTER_NAME" \
        --service "$SERVICE_NAME" \
        --force-new-deployment \
        --region us-east-1
    
    log_info "ECS service updated successfully!"
}

# Upload models to S3
upload_models() {
    log_info "Uploading ML models to S3..."
    
    MODEL_BUCKET=$(cd "$TERRAFORM_DIR" && terraform output -raw s3_model_bucket)
    
    if [ -d "$SCRIPT_DIR/../models" ]; then
        aws s3 sync "$SCRIPT_DIR/../models/" "s3://$MODEL_BUCKET/models/"
        log_info "Models uploaded successfully!"
    else
        log_warn "Models directory not found. Skipping model upload."
    fi
}

# Display deployment info
display_info() {
    log_info "Deployment complete!"
    echo ""
    log_info "Dashboard URL: $(cd "$TERRAFORM_DIR" && terraform output -raw dashboard_url)"
    log_info "CloudWatch Logs: $(cd "$TERRAFORM_DIR" && terraform output -raw cloudwatch_dashboard_url)"
    echo ""
    log_info "To view logs:"
    echo "  aws logs tail $(cd "$TERRAFORM_DIR" && terraform output -json | jq -r '.ecs_cluster_name.value') --follow"
    echo ""
    log_info "Next steps:"
    echo "  1. Confirm SNS email subscription for alerts"
    echo "  2. Upload your data to S3: $(cd "$TERRAFORM_DIR" && terraform output -raw s3_data_bucket)"
    echo "  3. Configure your custom domain (if needed)"
}

# Main deployment flow
main() {
    log_info "Starting deployment process..."
    
    check_prerequisites
    init_terraform
    plan_infrastructure
    apply_infrastructure
    build_and_push_image
    update_ecs_service
    upload_models
    display_info
    
    log_info "Deployment completed successfully!"
}

# Parse command line arguments
case "${1:-}" in
    init)
        check_prerequisites
        init_terraform
        ;;
    plan)
        check_prerequisites
        init_terraform
        plan_infrastructure
        ;;
    apply)
        check_prerequisites
        init_terraform
        apply_infrastructure
        ;;
    build)
        build_and_push_image
        ;;
    update)
        update_ecs_service
        ;;
    destroy)
        log_warn "This will destroy all infrastructure!"
        read -p "Are you sure? Type 'yes' to confirm: " confirm
        if [ "$confirm" = "yes" ]; then
            cd "$TERRAFORM_DIR"
            terraform destroy
        fi
        ;;
    full)
        main
        ;;
    *)
        echo "Usage: $0 {init|plan|apply|build|update|destroy|full}"
        echo ""
        echo "Commands:"
        echo "  init    - Initialize Terraform"
        echo "  plan    - Plan infrastructure changes"
        echo "  apply   - Apply infrastructure changes"
        echo "  build   - Build and push Docker image"
        echo "  update  - Update ECS service"
        echo "  destroy - Destroy all infrastructure"
        echo "  full    - Run complete deployment"
        exit 1
        ;;
esac
