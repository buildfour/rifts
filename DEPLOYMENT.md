# Summoner's Chronicle - Deployment Guide

Complete guide for deploying Summoner's Chronicle to AWS infrastructure.

---

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Environment Setup](#environment-setup)
3. [Deployment Methods](#deployment-methods)
4. [AWS Amplify Deployment](#aws-amplify-deployment)
5. [S3 + CloudFront Deployment](#s3--cloudfront-deployment)
6. [Domain Configuration](#domain-configuration)
7. [SSL/TLS Certificates](#ssltls-certificates)
8. [Backend Integration](#backend-integration)
9. [Monitoring & Logging](#monitoring--logging)
10. [Rollback Procedures](#rollback-procedures)
11. [Troubleshooting](#troubleshooting)

---

## Prerequisites

### Required Tools

1. **AWS CLI**
   ```bash
   # Install AWS CLI
   curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
   unzip awscliv2.zip
   sudo ./aws/install

   # Verify installation
   aws --version
   ```

2. **Git**
   ```bash
   # Ubuntu/Debian
   sudo apt-get install git

   # macOS
   brew install git

   # Verify
   git --version
   ```

3. **Node.js (Optional for build tools)**
   ```bash
   # Using nvm (recommended)
   curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
   nvm install 20
   nvm use 20

   # Verify
   node --version
   npm --version
   ```

### AWS Account Setup

1. **Create AWS Account**
   - Visit https://aws.amazon.com/
   - Sign up for new account
   - Complete verification

2. **Configure AWS CLI**
   ```bash
   aws configure
   # AWS Access Key ID: <your-access-key>
   # AWS Secret Access Key: <your-secret-key>
   # Default region name: us-east-1
   # Default output format: json
   ```

3. **Verify Credentials**
   ```bash
   aws sts get-caller-identity
   ```

### Required AWS Permissions

Your IAM user/role needs these permissions:
- `amplify:*` - Full Amplify access
- `s3:*` - S3 bucket management
- `cloudfront:*` - CloudFront distribution management
- `route53:*` - DNS management
- `acm:*` - Certificate management
- `iam:PassRole` - Role assignment

---

## Environment Setup

### 1. Clone Repository

```bash
git clone https://github.com/buildfour/rifts.git
cd rifts
```

### 2. Environment Variables

Create `.env` file for each environment:

```bash
# .env.dev
ENVIRONMENT=development
AWS_REGION=us-east-1
APP_NAME=summoners-chronicle
DOMAIN_NAME=dev.summoners-chronicle.com

# .env.staging
ENVIRONMENT=staging
AWS_REGION=us-east-1
APP_NAME=summoners-chronicle
DOMAIN_NAME=staging.summoners-chronicle.com

# .env.production
ENVIRONMENT=production
AWS_REGION=us-east-1
APP_NAME=summoners-chronicle
DOMAIN_NAME=summoners-chronicle.com
```

### 3. Verify Files

```bash
# Check all required files exist
ls -la index.html deploy.sh requirements.txt

# Make deploy script executable
chmod +x deploy.sh
```

---

## Deployment Methods

### Method 1: Automated Deployment Script (Recommended)

```bash
# Deploy to development
./deploy.sh dev

# Deploy to staging
./deploy.sh staging

# Deploy to production
./deploy.sh production
```

### Method 2: Manual AWS Amplify

See [AWS Amplify Deployment](#aws-amplify-deployment)

### Method 3: Manual S3 + CloudFront

See [S3 + CloudFront Deployment](#s3--cloudfront-deployment)

---

## AWS Amplify Deployment

### Step 1: Create Amplify App (Console)

1. **Navigate to AWS Amplify Console**
   - Open https://console.aws.amazon.com/amplify
   - Click "New app" → "Host web app"

2. **Connect Repository**
   - Choose "GitHub" as source
   - Authorize AWS Amplify
   - Select repository: `buildfour/rifts`
   - Select branch: `web-app`

3. **Configure Build Settings**
   ```yaml
   version: 1
   frontend:
     phases:
       build:
         commands:
           - echo "No build step required for static site"
     artifacts:
       baseDirectory: /
       files:
         - '**/*'
     cache:
       paths: []
   ```

4. **Deploy**
   - Click "Save and deploy"
   - Wait for deployment to complete

### Step 2: Create Amplify App (CLI)

```bash
# Create app
aws amplify create-app \
    --name summoners-chronicle-dev \
    --platform WEB \
    --region us-east-1

# Note the APP_ID from output
APP_ID=<your-app-id>

# Create branch
aws amplify create-branch \
    --app-id $APP_ID \
    --branch-name web-app \
    --enable-auto-build

# Create deployment
zip -r deployment.zip index.html bg.jpg

aws amplify start-deployment \
    --app-id $APP_ID \
    --branch-name web-app \
    --source-url deployment.zip
```

### Step 3: Configure Custom Domain

1. **Add Custom Domain**
   ```bash
   aws amplify create-domain-association \
       --app-id $APP_ID \
       --domain-name summoners-chronicle.com \
       --sub-domain-settings prefix=www,branchName=web-app
   ```

2. **Update DNS**
   - Copy CNAME records from Amplify console
   - Add to your DNS provider (Route 53, Cloudflare, etc.)

3. **Wait for SSL Certificate**
   - Amplify automatically provisions SSL certificate
   - Verification can take 15-30 minutes

### Step 4: Configure Build Settings

Create `amplify.yml` in project root:

```yaml
version: 1
frontend:
  phases:
    preBuild:
      commands:
        - echo "Starting build for Summoner's Chronicle"
    build:
      commands:
        - echo "No build step required - static HTML site"
  artifacts:
    baseDirectory: /
    files:
      - '**/*'
  cache:
    paths: []
```

### Step 5: Set Environment Variables

```bash
# Set environment variables in Amplify
aws amplify update-app \
    --app-id $APP_ID \
    --environment-variables \
        ENVIRONMENT=production \
        API_ENDPOINT=https://api.riftsage.com
```

---

## S3 + CloudFront Deployment

### Step 1: Create S3 Bucket

```bash
# Set variables
BUCKET_NAME="summoners-chronicle-prod"
REGION="us-east-1"

# Create bucket
aws s3 mb s3://$BUCKET_NAME --region $REGION

# Enable static website hosting
aws s3 website s3://$BUCKET_NAME \
    --index-document index.html \
    --error-document index.html
```

### Step 2: Configure Bucket Policy

```bash
# Create bucket policy file
cat > bucket-policy.json <<EOF
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

# Apply bucket policy
aws s3api put-bucket-policy \
    --bucket $BUCKET_NAME \
    --policy file://bucket-policy.json
```

### Step 3: Upload Files

```bash
# Sync all files
aws s3 sync . s3://$BUCKET_NAME \
    --exclude ".git/*" \
    --exclude "*.sh" \
    --exclude "*.md" \
    --exclude "deployment/*" \
    --cache-control "max-age=3600"

# Set cache control for HTML
aws s3 cp index.html s3://$BUCKET_NAME/index.html \
    --cache-control "max-age=300, must-revalidate" \
    --content-type "text/html"
```

### Step 4: Create CloudFront Distribution

```bash
# Create distribution config
cat > cloudfront-config.json <<EOF
{
    "CallerReference": "summoners-chronicle-$(date +%s)",
    "Comment": "Summoner's Chronicle CDN",
    "Origins": {
        "Quantity": 1,
        "Items": [
            {
                "Id": "S3-$BUCKET_NAME",
                "DomainName": "$BUCKET_NAME.s3.amazonaws.com",
                "S3OriginConfig": {
                    "OriginAccessIdentity": ""
                }
            }
        ]
    },
    "DefaultRootObject": "index.html",
    "DefaultCacheBehavior": {
        "TargetOriginId": "S3-$BUCKET_NAME",
        "ViewerProtocolPolicy": "redirect-to-https",
        "AllowedMethods": {
            "Quantity": 2,
            "Items": ["GET", "HEAD"]
        },
        "ForwardedValues": {
            "QueryString": false,
            "Cookies": {
                "Forward": "none"
            }
        },
        "MinTTL": 0,
        "Compress": true
    },
    "Enabled": true
}
EOF

# Create distribution
aws cloudfront create-distribution \
    --distribution-config file://cloudfront-config.json
```

### Step 5: Configure Custom Domain

1. **Request SSL Certificate (ACM)**
   ```bash
   # Request certificate (must be in us-east-1 for CloudFront)
   CERT_ARN=$(aws acm request-certificate \
       --domain-name summoners-chronicle.com \
       --subject-alternative-names www.summoners-chronicle.com \
       --validation-method DNS \
       --region us-east-1 \
       --query CertificateArn \
       --output text)

   # Get DNS validation records
   aws acm describe-certificate \
       --certificate-arn $CERT_ARN \
       --region us-east-1
   ```

2. **Add DNS Validation Records**
   - Copy CNAME records from ACM
   - Add to your DNS provider

3. **Wait for Validation**
   ```bash
   aws acm wait certificate-validated \
       --certificate-arn $CERT_ARN \
       --region us-east-1
   ```

4. **Update CloudFront Distribution**
   - Add alternate domain names
   - Attach SSL certificate
   - Update viewer protocol policy

---

## Domain Configuration

### Using Route 53

1. **Create Hosted Zone**
   ```bash
   aws route53 create-hosted-zone \
       --name summoners-chronicle.com \
       --caller-reference $(date +%s)
   ```

2. **Get Name Servers**
   ```bash
   aws route53 get-hosted-zone --id <hosted-zone-id>
   ```

3. **Update Domain Registrar**
   - Copy name servers from Route 53
   - Update at your domain registrar

4. **Create DNS Records**
   ```bash
   # A record for root domain (points to CloudFront)
   # CNAME for www subdomain
   ```

### Using External DNS Provider

1. **Get CloudFront Domain**
   ```bash
   aws cloudfront get-distribution --id <distribution-id>
   ```

2. **Add CNAME Record**
   - Name: `www` or `@`
   - Type: `CNAME`
   - Value: `<cloudfront-domain>.cloudfront.net`

---

## SSL/TLS Certificates

### Automatic (AWS Amplify)

Amplify automatically provisions SSL certificates. No action required.

### Manual (CloudFront)

1. **Request Certificate in ACM**
   ```bash
   aws acm request-certificate \
       --domain-name summoners-chronicle.com \
       --validation-method DNS \
       --region us-east-1
   ```

2. **Validate Certificate**
   - Add DNS records provided by ACM
   - Wait for validation

3. **Attach to CloudFront**
   - Update distribution settings
   - Add certificate ARN

---

## Backend Integration

### API Gateway Setup

```bash
# Create REST API
aws apigateway create-rest-api \
    --name summoners-chronicle-api \
    --description "RiftSage API for Summoner's Chronicle"

# Create resources and methods
# Deploy to stage
```

### CORS Configuration

Add to API Gateway:
```json
{
    "Access-Control-Allow-Origin": "https://summoners-chronicle.com",
    "Access-Control-Allow-Methods": "GET,POST,PUT,DELETE,OPTIONS",
    "Access-Control-Allow-Headers": "Content-Type,Authorization"
}
```

### Environment-Specific Endpoints

```javascript
const API_ENDPOINTS = {
    dev: 'https://dev-api.riftsage.com/v1',
    staging: 'https://staging-api.riftsage.com/v1',
    production: 'https://api.riftsage.com/v1'
};

const API_BASE = API_ENDPOINTS[process.env.ENVIRONMENT || 'production'];
```

---

## Monitoring & Logging

### CloudWatch Setup

1. **Enable CloudFront Logging**
   ```bash
   # Create logging bucket
   aws s3 mb s3://summoners-chronicle-logs

   # Enable logging on CloudFront distribution
   aws cloudfront update-distribution \
       --id <distribution-id> \
       --logging \
       Bucket=summoners-chronicle-logs.s3.amazonaws.com,Prefix=cloudfront/
   ```

2. **Create CloudWatch Dashboard**
   ```bash
   aws cloudwatch put-dashboard \
       --dashboard-name summoners-chronicle \
       --dashboard-body file://dashboard.json
   ```

3. **Set Up Alarms**
   ```bash
   # 5xx errors alarm
   aws cloudwatch put-metric-alarm \
       --alarm-name summoners-chronicle-5xx-errors \
       --alarm-description "Alert on 5xx errors" \
       --metric-name 5xxErrorRate \
       --namespace AWS/CloudFront \
       --statistic Average \
       --period 300 \
       --threshold 1 \
       --comparison-operator GreaterThanThreshold
   ```

### Application Monitoring

1. **Google Analytics**
   - Add GA4 tracking code to `index.html`
   - Configure goals and events

2. **Custom Metrics**
   - Page load times
   - User interactions
   - Error tracking

---

## Rollback Procedures

### Amplify Rollback

```bash
# List deployments
aws amplify list-jobs --app-id $APP_ID --branch-name web-app

# Redeploy previous version
aws amplify start-job \
    --app-id $APP_ID \
    --branch-name web-app \
    --job-type RELEASE \
    --job-reason "Rollback to previous version"
```

### S3 + CloudFront Rollback

```bash
# Enable versioning (if not already enabled)
aws s3api put-bucket-versioning \
    --bucket $BUCKET_NAME \
    --versioning-configuration Status=Enabled

# List versions
aws s3api list-object-versions --bucket $BUCKET_NAME

# Restore previous version
aws s3api copy-object \
    --copy-source $BUCKET_NAME/index.html?versionId=<version-id> \
    --bucket $BUCKET_NAME \
    --key index.html

# Invalidate CloudFront cache
aws cloudfront create-invalidation \
    --distribution-id <distribution-id> \
    --paths "/*"
```

---

## Troubleshooting

### Common Issues

#### 1. 403 Forbidden Errors

**Cause**: Incorrect S3 bucket policy or CloudFront permissions

**Solution**:
```bash
# Check bucket policy
aws s3api get-bucket-policy --bucket $BUCKET_NAME

# Verify CloudFront OAI
aws cloudfront get-cloud-front-origin-access-identity --id <oai-id>
```

#### 2. SSL Certificate Not Validated

**Cause**: DNS records not properly configured

**Solution**:
```bash
# Check certificate status
aws acm describe-certificate --certificate-arn $CERT_ARN

# Verify DNS records
dig CNAME _<validation-hash>.summoners-chronicle.com
```

#### 3. CloudFront Caching Old Content

**Cause**: Browser or CDN cache

**Solution**:
```bash
# Create invalidation
aws cloudfront create-invalidation \
    --distribution-id <distribution-id> \
    --paths "/*"

# Check invalidation status
aws cloudfront get-invalidation \
    --distribution-id <distribution-id> \
    --id <invalidation-id>
```

#### 4. CORS Errors

**Cause**: Missing or incorrect CORS headers

**Solution**:
- Add CORS policy to S3 bucket
- Configure CORS on API Gateway
- Add appropriate headers in CloudFront

#### 5. Slow Load Times

**Cause**: Not using CDN, large file sizes

**Solution**:
```bash
# Enable compression in CloudFront
# Optimize images
# Use lazy loading
# Enable browser caching
```

### Debug Commands

```bash
# Check Amplify app status
aws amplify get-app --app-id $APP_ID

# Check S3 bucket
aws s3 ls s3://$BUCKET_NAME

# Check CloudFront distribution
aws cloudfront get-distribution --id <distribution-id>

# Test DNS resolution
dig summoners-chronicle.com

# Test SSL certificate
openssl s_client -connect summoners-chronicle.com:443 -servername summoners-chronicle.com
```

---

## Best Practices

1. **Always deploy to dev/staging first**
2. **Run smoke tests after deployment**
3. **Enable versioning on S3 buckets**
4. **Use CloudFront for production**
5. **Monitor CloudWatch metrics**
6. **Set up automated backups**
7. **Document all configuration changes**
8. **Use infrastructure as code (CloudFormation/Terraform)**

---

## Additional Resources

- [AWS Amplify Documentation](https://docs.aws.amazon.com/amplify/)
- [S3 Static Website Hosting](https://docs.aws.amazon.com/AmazonS3/latest/userguide/WebsiteHosting.html)
- [CloudFront Documentation](https://docs.aws.amazon.com/cloudfront/)
- [Route 53 Documentation](https://docs.aws.amazon.com/route53/)
- [ACM Documentation](https://docs.aws.amazon.com/acm/)

---

## Support

For deployment issues:
- Check [Troubleshooting](#troubleshooting) section
- Review AWS service health dashboard
- Contact AWS Support
- Open GitHub issue

---

**Last Updated**: November 2025
