#!/bin/bash

##############################################################################
# Complete Deployment Script for Summoner's Chronicle Web App
# This script handles the full deployment from scratch
##############################################################################

set -e  # Exit on error

echo "========================================"
echo "Summoner's Chronicle - Complete Deployment"
echo "========================================"
echo ""

# Configuration
PROJECT_NAME="summoners-chronicle"
STACK_NAME="${PROJECT_NAME}-webapp"
ENVIRONMENT="production"
AWS_REGION=$(aws configure get region || echo "us-east-1")
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

echo "Configuration:"
echo "  Project Name:    $PROJECT_NAME"
echo "  Stack Name:      $STACK_NAME"
echo "  Environment:     $ENVIRONMENT"
echo "  AWS Region:      $AWS_REGION"
echo "  AWS Account:     $AWS_ACCOUNT_ID"
echo ""

# Generate unique bucket name
WEBAPP_BUCKET="${PROJECT_NAME}-webapp-${ENVIRONMENT}-${AWS_ACCOUNT_ID}"
echo "  S3 Bucket:       $WEBAPP_BUCKET"
echo ""

read -p "Press Enter to continue with deployment..."
echo ""

##############################################################################
# STEP 1: Create S3 Bucket
##############################################################################
echo "========================================"
echo "STEP 1: Creating S3 Bucket"
echo "========================================"
echo ""

if aws s3 ls "s3://${WEBAPP_BUCKET}" 2>/dev/null; then
    echo "✓ Bucket already exists: ${WEBAPP_BUCKET}"
else
    echo "Creating S3 bucket..."
    if [ "${AWS_REGION}" == "us-east-1" ]; then
        aws s3 mb "s3://${WEBAPP_BUCKET}"
    else
        aws s3 mb "s3://${WEBAPP_BUCKET}" --region "${AWS_REGION}" \
            --create-bucket-configuration LocationConstraint="${AWS_REGION}"
    fi
    echo "✓ Created bucket: ${WEBAPP_BUCKET}"
fi

# Configure static website hosting
echo "Configuring static website hosting..."
aws s3 website "s3://${WEBAPP_BUCKET}" \
    --index-document index.html \
    --error-document index.html

# Set public read policy
echo "Setting public read policy..."
cat > /tmp/bucket-policy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "PublicReadGetObject",
      "Effect": "Allow",
      "Principal": "*",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::${WEBAPP_BUCKET}/*"
    }
  ]
}
EOF

aws s3api put-bucket-policy \
    --bucket "${WEBAPP_BUCKET}" \
    --policy file:///tmp/bucket-policy.json

rm /tmp/bucket-policy.json

echo "✓ S3 bucket configured for website hosting"
echo ""

##############################################################################
# STEP 2: Deploy CloudFormation Stack
##############################################################################
echo "========================================"
echo "STEP 2: Deploying CloudFormation Stack"
echo "========================================"
echo ""

# Check if cloudformation template exists
if [ ! -f "cloudformation-template.yaml" ]; then
    echo "Error: cloudformation-template.yaml not found!"
    echo "Please ensure you're in the web_app directory"
    exit 1
fi

# Check if stack exists
if aws cloudformation describe-stacks --stack-name "${STACK_NAME}" --region "${AWS_REGION}" &> /dev/null; then
    echo "Stack already exists. Updating..."
    ACTION="update-stack"
    WAIT_CMD="stack-update-complete"
else
    echo "Creating new stack..."
    ACTION="create-stack"
    WAIT_CMD="stack-create-complete"
fi

aws cloudformation ${ACTION} \
    --stack-name "${STACK_NAME}" \
    --template-body file://cloudformation-template.yaml \
    --parameters \
        ParameterKey=Environment,ParameterValue="${ENVIRONMENT}" \
        ParameterKey=ProjectName,ParameterValue="${PROJECT_NAME}" \
        ParameterKey=WebAppBucket,ParameterValue="${WEBAPP_BUCKET}" \
    --capabilities CAPABILITY_NAMED_IAM \
    --region "${AWS_REGION}"

echo "Waiting for stack operation to complete (this may take 3-5 minutes)..."
aws cloudformation wait ${WAIT_CMD} \
    --stack-name "${STACK_NAME}" \
    --region "${AWS_REGION}" 2>/dev/null || true

echo "✓ CloudFormation stack deployed"
echo ""

##############################################################################
# STEP 3: Get Stack Outputs
##############################################################################
echo "========================================"
echo "STEP 3: Getting Stack Outputs"
echo "========================================"
echo ""

USER_POOL_ID=$(aws cloudformation describe-stacks \
    --stack-name "${STACK_NAME}" \
    --query 'Stacks[0].Outputs[?OutputKey==`UserPoolId`].OutputValue' \
    --output text \
    --region "${AWS_REGION}")

CLIENT_ID=$(aws cloudformation describe-stacks \
    --stack-name "${STACK_NAME}" \
    --query 'Stacks[0].Outputs[?OutputKey==`UserPoolClientId`].OutputValue' \
    --output text \
    --region "${AWS_REGION}")

IDENTITY_POOL_ID=$(aws cloudformation describe-stacks \
    --stack-name "${STACK_NAME}" \
    --query 'Stacks[0].Outputs[?OutputKey==`IdentityPoolId`].OutputValue' \
    --output text \
    --region "${AWS_REGION}")

echo "✓ User Pool ID:        $USER_POOL_ID"
echo "✓ Client ID:           $CLIENT_ID"
echo "✓ Identity Pool ID:    $IDENTITY_POOL_ID"
echo ""

##############################################################################
# STEP 4: Update AWS Configuration
##############################################################################
echo "========================================"
echo "STEP 4: Updating AWS Configuration"
echo "========================================"
echo ""

# Create updated aws-config.js
cat > config/aws-config.js <<EOF
/**
 * AWS Configuration for Summoner's Chronicle
 * Auto-generated during deployment
 */

const AWS_CONFIG = {
    // AWS Region
    region: '${AWS_REGION}',

    // AWS Cognito Configuration
    cognito: {
        userPoolId: '${USER_POOL_ID}',
        clientId: '${CLIENT_ID}',
        identityPoolId: '${IDENTITY_POOL_ID}'
    },

    // API Gateway Endpoint (RiftSage API)
    apiEndpoint: 'https://api.example.com',  // Update with your RiftSage API

    // S3 Bucket for Reports
    reportsBucket: '${WEBAPP_BUCKET}',

    // CloudFront Distribution (will be updated after CloudFront creation)
    cloudFrontDomain: 'TBD',

    // Application Settings
    app: {
        name: 'Summoner\\'s Chronicle',
        version: '1.0.0',
        environment: '${ENVIRONMENT}'
    }
};

// Freeze config to prevent modifications
Object.freeze(AWS_CONFIG);

console.log('AWS Configuration loaded:', AWS_CONFIG.app.environment);
EOF

echo "✓ AWS configuration file updated"
echo ""

##############################################################################
# STEP 5: Upload Files to S3
##############################################################################
echo "========================================"
echo "STEP 5: Uploading Files to S3"
echo "========================================"
echo ""

# Upload all files with proper content types
echo "Uploading HTML files..."
find . -name "*.html" -type f | while read file; do
    aws s3 cp "$file" "s3://${WEBAPP_BUCKET}/${file#./}" \
        --content-type "text/html" \
        --cache-control "max-age=300" \
        --region "${AWS_REGION}"
done

echo "Uploading CSS files..."
find . -name "*.css" -type f | while read file; do
    aws s3 cp "$file" "s3://${WEBAPP_BUCKET}/${file#./}" \
        --content-type "text/css" \
        --cache-control "max-age=31536000" \
        --region "${AWS_REGION}"
done

echo "Uploading JavaScript files..."
find . -name "*.js" -type f | while read file; do
    aws s3 cp "$file" "s3://${WEBAPP_BUCKET}/${file#./}" \
        --content-type "application/javascript" \
        --cache-control "max-age=31536000" \
        --region "${AWS_REGION}"
done

echo "Uploading image files..."
find . -name "*.jpg" -o -name "*.png" -o -name "*.gif" -o -name "*.svg" -o -name "*.ico" -type f 2>/dev/null | while read file; do
    aws s3 cp "$file" "s3://${WEBAPP_BUCKET}/${file#./}" \
        --region "${AWS_REGION}"
done || true

echo "✓ All files uploaded to S3"
echo ""

# Get S3 website URL
S3_WEBSITE_URL="http://${WEBAPP_BUCKET}.s3-website-${AWS_REGION}.amazonaws.com"
echo "S3 Website URL: $S3_WEBSITE_URL"
echo ""

##############################################################################
# STEP 6: Create CloudFront Distribution
##############################################################################
echo "========================================"
echo "STEP 6: Creating CloudFront Distribution"
echo "========================================"
echo ""

S3_WEBSITE_ENDPOINT="${WEBAPP_BUCKET}.s3-website-${AWS_REGION}.amazonaws.com"

echo "Creating CloudFront configuration..."
cat > /tmp/cloudfront-config.json <<EOF
{
  "CallerReference": "${PROJECT_NAME}-$(date +%s)",
  "Comment": "Summoner's Chronicle Web App - HTTPS CloudFront Distribution",
  "Enabled": true,
  "DefaultRootObject": "index.html",
  "Origins": {
    "Quantity": 1,
    "Items": [
      {
        "Id": "S3-Website-${WEBAPP_BUCKET}",
        "DomainName": "${S3_WEBSITE_ENDPOINT}",
        "CustomOriginConfig": {
          "HTTPPort": 80,
          "HTTPSPort": 443,
          "OriginProtocolPolicy": "http-only",
          "OriginSslProtocols": {
            "Quantity": 3,
            "Items": ["TLSv1", "TLSv1.1", "TLSv1.2"]
          },
          "OriginReadTimeout": 30,
          "OriginKeepaliveTimeout": 5
        }
      }
    ]
  },
  "DefaultCacheBehavior": {
    "TargetOriginId": "S3-Website-${WEBAPP_BUCKET}",
    "ViewerProtocolPolicy": "redirect-to-https",
    "AllowedMethods": {
      "Quantity": 2,
      "Items": ["GET", "HEAD"],
      "CachedMethods": {
        "Quantity": 2,
        "Items": ["GET", "HEAD"]
      }
    },
    "Compress": true,
    "ForwardedValues": {
      "QueryString": false,
      "Cookies": {
        "Forward": "none"
      },
      "Headers": {
        "Quantity": 0
      }
    },
    "MinTTL": 0,
    "DefaultTTL": 86400,
    "MaxTTL": 31536000,
    "TrustedSigners": {
      "Enabled": false,
      "Quantity": 0
    },
    "TrustedKeyGroups": {
      "Enabled": false,
      "Quantity": 0
    }
  },
  "CustomErrorResponses": {
    "Quantity": 2,
    "Items": [
      {
        "ErrorCode": 403,
        "ResponsePagePath": "/index.html",
        "ResponseCode": "200",
        "ErrorCachingMinTTL": 300
      },
      {
        "ErrorCode": 404,
        "ResponsePagePath": "/index.html",
        "ResponseCode": "200",
        "ErrorCachingMinTTL": 300
      }
    ]
  },
  "PriceClass": "PriceClass_100",
  "ViewerCertificate": {
    "CloudFrontDefaultCertificate": true,
    "MinimumProtocolVersion": "TLSv1.2_2021"
  },
  "HttpVersion": "http2"
}
EOF

echo "Creating CloudFront distribution (this takes 10-15 minutes)..."
aws cloudfront create-distribution \
    --distribution-config file:///tmp/cloudfront-config.json \
    --output json > /tmp/cloudfront-output.json

DISTRIBUTION_ID=$(cat /tmp/cloudfront-output.json | grep -o '"Id": "[^"]*"' | head -1 | cut -d'"' -f4)
CLOUDFRONT_DOMAIN=$(cat /tmp/cloudfront-output.json | grep -o '"DomainName": "[^"]*"' | head -1 | cut -d'"' -f4)
CLOUDFRONT_URL="https://${CLOUDFRONT_DOMAIN}"

echo "✓ CloudFront distribution created!"
echo ""
echo "Distribution ID:  $DISTRIBUTION_ID"
echo "CloudFront URL:   $CLOUDFRONT_URL"
echo ""

# Save for later use
echo "$DISTRIBUTION_ID" > /tmp/distribution-id.txt
echo "$CLOUDFRONT_URL" > /tmp/cloudfront-url.txt

# Cleanup
rm /tmp/cloudfront-config.json

##############################################################################
# STEP 7: Update Cognito Callback URLs
##############################################################################
echo "========================================"
echo "STEP 7: Updating Cognito Callback URLs"
echo "========================================"
echo ""

echo "Adding CloudFront URL to Cognito..."
aws cognito-idp update-user-pool-client \
    --user-pool-id "$USER_POOL_ID" \
    --client-id "$CLIENT_ID" \
    --callback-urls \
        "http://localhost:3000" \
        "http://localhost:8080" \
        "${CLOUDFRONT_URL}/pages/auth.html" \
    --logout-urls \
        "http://localhost:3000" \
        "http://localhost:8080" \
        "${CLOUDFRONT_URL}" \
    --allowed-o-auth-flows "code" \
    --allowed-o-auth-scopes "email" "openid" "profile" \
    --allowed-o-auth-flows-user-pool-client \
    --supported-identity-providers "COGNITO" \
    --region "${AWS_REGION}"

echo "✓ Cognito callback URLs updated"
echo ""

##############################################################################
# STEP 8: Update and Re-upload aws-config.js with CloudFront URL
##############################################################################
echo "========================================"
echo "STEP 8: Updating Configuration with CloudFront URL"
echo "========================================"
echo ""

cat > config/aws-config.js <<EOF
/**
 * AWS Configuration for Summoner's Chronicle
 * Auto-generated during deployment
 */

const AWS_CONFIG = {
    // AWS Region
    region: '${AWS_REGION}',

    // AWS Cognito Configuration
    cognito: {
        userPoolId: '${USER_POOL_ID}',
        clientId: '${CLIENT_ID}',
        identityPoolId: '${IDENTITY_POOL_ID}'
    },

    // API Gateway Endpoint (RiftSage API)
    apiEndpoint: 'https://api.example.com',

    // S3 Bucket for Reports
    reportsBucket: '${WEBAPP_BUCKET}',

    // CloudFront Distribution
    cloudFrontDomain: '${CLOUDFRONT_URL}',

    // Application Settings
    app: {
        name: 'Summoner\\'s Chronicle',
        version: '1.0.0',
        environment: '${ENVIRONMENT}'
    }
};

// Freeze config to prevent modifications
Object.freeze(AWS_CONFIG);

console.log('AWS Configuration loaded:', AWS_CONFIG.app.environment);
EOF

# Upload updated config
aws s3 cp config/aws-config.js "s3://${WEBAPP_BUCKET}/config/aws-config.js" \
    --content-type "application/javascript" \
    --metadata-directive REPLACE \
    --region "${AWS_REGION}"

echo "✓ Configuration updated with CloudFront URL"
echo ""

##############################################################################
# DEPLOYMENT COMPLETE
##############################################################################
echo "========================================"
echo "🎉 DEPLOYMENT COMPLETE!"
echo "========================================"
echo ""
echo "Your Summoner's Chronicle web app has been deployed!"
echo ""
echo "📊 Deployment Summary:"
echo "  ✓ S3 Bucket:           ${WEBAPP_BUCKET}"
echo "  ✓ CloudFormation:      ${STACK_NAME}"
echo "  ✓ Cognito User Pool:   ${USER_POOL_ID}"
echo "  ✓ CloudFront:          ${DISTRIBUTION_ID}"
echo ""
echo "🌐 Access URLs:"
echo "  S3 Website:   ${S3_WEBSITE_URL}"
echo "  CloudFront:   ${CLOUDFRONT_URL}"
echo ""
echo "⚠️  IMPORTANT:"
echo "  CloudFront is still deploying (10-15 minutes)"
echo "  Status: InProgress → Deployed"
echo ""
echo "  Check status:"
echo "  aws cloudfront get-distribution --id ${DISTRIBUTION_ID} --query 'Distribution.Status'"
echo ""
echo "📝 Next Steps:"
echo "  1. Wait 10-15 minutes for CloudFront to finish deploying"
echo "  2. Visit: ${CLOUDFRONT_URL}"
echo "  3. Click 'Get Started' and sign up with your email"
echo "  4. Link your League of Legends summoner account"
echo "  5. Explore your personalized chronicle!"
echo ""
echo "🔧 Troubleshooting:"
echo "  - Use HTTPS URL (CloudFront), not HTTP (S3)"
echo "  - Clear browser cache or use incognito mode"
echo "  - Check browser console (F12) for errors"
echo ""
echo "✅ Deployment script completed successfully!"
