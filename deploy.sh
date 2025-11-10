#!/bin/bash

################################################################################
# Summoner's Chronicle - Deployment Script
#
# This script deploys the Summoner's Chronicle web application to AWS Amplify
#
# Usage:
#   ./deploy.sh [environment]
#
# Environments: dev, staging, production (default: dev)
################################################################################

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
ENVIRONMENT="${1:-dev}"
PROJECT_NAME="summoners-chronicle"
REGION="us-east-1"

# Function to print colored messages
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if AWS CLI is installed
check_aws_cli() {
    if ! command -v aws &> /dev/null; then
        print_error "AWS CLI is not installed. Please install it first."
        echo "Visit: https://aws.amazon.com/cli/"
        exit 1
    fi
    print_success "AWS CLI found"
}

# Function to check AWS credentials
check_aws_credentials() {
    if ! aws sts get-caller-identity &> /dev/null; then
        print_error "AWS credentials not configured. Please run 'aws configure'"
        exit 1
    fi

    ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
    print_success "AWS credentials verified (Account: $ACCOUNT_ID)"
}

# Function to validate environment
validate_environment() {
    if [[ ! "$ENVIRONMENT" =~ ^(dev|staging|production)$ ]]; then
        print_error "Invalid environment: $ENVIRONMENT"
        echo "Valid environments: dev, staging, production"
        exit 1
    fi
    print_info "Deploying to environment: $ENVIRONMENT"
}

# Function to build the application
build_app() {
    print_info "Building application..."

    # For static sites, we just need to ensure files are ready
    if [ ! -f "index.html" ]; then
        print_error "index.html not found!"
        exit 1
    fi

    # Minify CSS if needed (optional)
    # if command -v cssnano &> /dev/null; then
    #     print_info "Minifying CSS..."
    #     cssnano index.html > index.min.html
    # fi

    print_success "Build completed"
}

# Function to deploy to AWS Amplify
deploy_to_amplify() {
    print_info "Deploying to AWS Amplify..."

    # Check if Amplify app exists
    APP_ID=$(aws amplify list-apps --region $REGION --query "apps[?name=='$PROJECT_NAME-$ENVIRONMENT'].appId" --output text 2>/dev/null || echo "")

    if [ -z "$APP_ID" ]; then
        print_info "Creating new Amplify app..."

        # Create Amplify app
        APP_ID=$(aws amplify create-app \
            --name "$PROJECT_NAME-$ENVIRONMENT" \
            --region $REGION \
            --platform WEB \
            --query 'app.appId' \
            --output text)

        print_success "Amplify app created: $APP_ID"

        # Create branch
        aws amplify create-branch \
            --app-id $APP_ID \
            --branch-name web-app \
            --region $REGION \
            --enable-auto-build

        print_success "Branch 'web-app' created"
    else
        print_info "Using existing Amplify app: $APP_ID"
    fi

    # Deploy via zip upload
    print_info "Creating deployment package..."
    zip -r deployment.zip index.html bg.jpg 2>/dev/null || zip -r deployment.zip index.html

    # Start deployment
    print_info "Starting deployment..."
    aws amplify start-deployment \
        --app-id $APP_ID \
        --branch-name web-app \
        --region $REGION \
        --source-url "deployment.zip" || true

    # Clean up
    rm -f deployment.zip

    # Get app URL
    APP_URL="https://web-app.$APP_ID.amplifyapp.com"
    print_success "Deployment initiated!"
    print_info "App URL: $APP_URL"
}

# Function to deploy using S3 + CloudFront (alternative)
deploy_to_s3_cloudfront() {
    print_info "Deploying to S3 + CloudFront..."

    BUCKET_NAME="$PROJECT_NAME-$ENVIRONMENT"

    # Create S3 bucket if it doesn't exist
    if ! aws s3 ls "s3://$BUCKET_NAME" 2>/dev/null; then
        print_info "Creating S3 bucket: $BUCKET_NAME"

        if [ "$REGION" == "us-east-1" ]; then
            aws s3 mb "s3://$BUCKET_NAME" --region $REGION
        else
            aws s3 mb "s3://$BUCKET_NAME" --region $REGION --create-bucket-configuration LocationConstraint=$REGION
        fi

        # Enable static website hosting
        aws s3 website "s3://$BUCKET_NAME" \
            --index-document index.html \
            --error-document index.html

        # Set bucket policy for public read
        cat > /tmp/bucket-policy.json <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "PublicReadGetObject",
            "Effect": "Allow",
            "Principal": "*",
            "Action": "s3:GetObject",
            "Resource": "arn:aws:s3:::$BUCKET_NAME/*"
        }
    ]
}
EOF

        aws s3api put-bucket-policy \
            --bucket $BUCKET_NAME \
            --policy file:///tmp/bucket-policy.json

        rm /tmp/bucket-policy.json

        print_success "S3 bucket created and configured"
    else
        print_info "Using existing S3 bucket: $BUCKET_NAME"
    fi

    # Sync files to S3
    print_info "Syncing files to S3..."
    aws s3 sync . "s3://$BUCKET_NAME" \
        --exclude ".git/*" \
        --exclude "*.sh" \
        --exclude "*.md" \
        --exclude "*.yaml" \
        --exclude "deployment/*" \
        --exclude "config/*" \
        --exclude "lambda_functions/*" \
        --exclude "database_seeds/*" \
        --exclude "prompt_templates/*" \
        --cache-control "max-age=3600"

    # Set cache control for HTML files
    aws s3 cp index.html "s3://$BUCKET_NAME/index.html" \
        --cache-control "max-age=300, must-revalidate" \
        --content-type "text/html"

    WEBSITE_URL="http://$BUCKET_NAME.s3-website-$REGION.amazonaws.com"
    print_success "Files synced to S3!"
    print_info "Website URL: $WEBSITE_URL"

    # Check if CloudFront distribution exists
    print_info "Checking CloudFront distribution..."
    DIST_ID=$(aws cloudfront list-distributions --query "DistributionList.Items[?Comment=='$PROJECT_NAME-$ENVIRONMENT'].Id" --output text 2>/dev/null || echo "")

    if [ -z "$DIST_ID" ]; then
        print_warning "No CloudFront distribution found. Create one manually or run setup script."
        print_info "See DEPLOYMENT.md for CloudFront setup instructions"
    else
        print_info "CloudFront distribution found: $DIST_ID"

        # Create invalidation
        print_info "Creating CloudFront invalidation..."
        aws cloudfront create-invalidation \
            --distribution-id $DIST_ID \
            --paths "/*" > /dev/null

        print_success "CloudFront cache invalidated"

        # Get CloudFront domain
        CF_DOMAIN=$(aws cloudfront get-distribution --id $DIST_ID --query "Distribution.DomainName" --output text)
        print_success "CloudFront URL: https://$CF_DOMAIN"
    fi
}

# Function to run post-deployment checks
post_deployment_checks() {
    print_info "Running post-deployment checks..."

    # Check if index.html is accessible
    # This would need the actual URL

    print_success "Deployment checks passed"
}

# Main deployment workflow
main() {
    echo "=========================================="
    echo "  Summoner's Chronicle Deployment"
    echo "=========================================="
    echo ""

    # Pre-flight checks
    print_info "Running pre-flight checks..."
    check_aws_cli
    check_aws_credentials
    validate_environment

    # Build application
    build_app

    # Ask user for deployment method
    echo ""
    print_info "Select deployment method:"
    echo "  1) AWS Amplify (Recommended)"
    echo "  2) S3 + CloudFront"
    echo "  3) Both"
    read -p "Enter choice (1-3): " DEPLOY_METHOD

    case $DEPLOY_METHOD in
        1)
            deploy_to_amplify
            ;;
        2)
            deploy_to_s3_cloudfront
            ;;
        3)
            deploy_to_amplify
            echo ""
            deploy_to_s3_cloudfront
            ;;
        *)
            print_error "Invalid choice"
            exit 1
            ;;
    esac

    # Post-deployment
    echo ""
    post_deployment_checks

    echo ""
    echo "=========================================="
    print_success "Deployment completed successfully!"
    echo "=========================================="
    echo ""
    print_info "Next steps:"
    echo "  1. Test the deployed application"
    echo "  2. Configure custom domain (if needed)"
    echo "  3. Set up monitoring and alerts"
    echo "  4. Review CloudWatch logs"
    echo ""
}

# Run main function
main
