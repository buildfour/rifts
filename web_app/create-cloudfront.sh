#!/bin/bash

##############################################################################
# Create CloudFront Distribution for Summoner's Chronicle
# This script properly configures and creates a CloudFront distribution
##############################################################################

set -e  # Exit on error

echo "========================================"
echo "Creating CloudFront Distribution"
echo "========================================"
echo ""

# Get configuration
STACK_NAME="summoners-chronicle-webapp"
AWS_REGION=$(aws configure get region || echo "us-east-1")

# Step 1: Get the S3 bucket name
echo "Step 1: Getting S3 bucket information..."
WEBAPP_BUCKET=$(aws cloudformation describe-stacks \
    --stack-name $STACK_NAME \
    --query 'Stacks[0].Outputs[?OutputKey==`WebAppBucket`].OutputValue' \
    --output text \
    --region $AWS_REGION)

if [ -z "$WEBAPP_BUCKET" ]; then
    echo "Error: Could not find WebAppBucket output from CloudFormation stack"
    exit 1
fi

echo "  ✓ S3 Bucket: $WEBAPP_BUCKET"

# Step 2: Construct the S3 website endpoint (origin domain)
# Format: bucket-name.s3-website-region.amazonaws.com
S3_WEBSITE_ENDPOINT="${WEBAPP_BUCKET}.s3-website-${AWS_REGION}.amazonaws.com"

echo "  ✓ S3 Website Endpoint: $S3_WEBSITE_ENDPOINT"
echo ""

# Step 3: Create CloudFront distribution configuration
echo "Step 2: Creating CloudFront distribution configuration..."

cat > /tmp/cloudfront-config.json <<EOF
{
  "CallerReference": "summoners-chronicle-$(date +%s)",
  "Comment": "Summoner's Chronicle Web App - CloudFront Distribution",
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

echo "  ✓ Configuration file created"
echo ""

# Step 4: Create the CloudFront distribution
echo "Step 3: Creating CloudFront distribution..."
echo "  (This may take 10-15 minutes to deploy globally)"
echo ""

aws cloudfront create-distribution \
    --distribution-config file:///tmp/cloudfront-config.json \
    --output json > /tmp/cloudfront-output.json

# Extract distribution details
DISTRIBUTION_ID=$(cat /tmp/cloudfront-output.json | grep -o '"Id": "[^"]*"' | head -1 | cut -d'"' -f4)
CLOUDFRONT_DOMAIN=$(cat /tmp/cloudfront-output.json | grep -o '"DomainName": "[^"]*"' | head -1 | cut -d'"' -f4)
DISTRIBUTION_STATUS=$(cat /tmp/cloudfront-output.json | grep -o '"Status": "[^"]*"' | head -1 | cut -d'"' -f4)

echo "  ✓ Distribution created successfully!"
echo ""
echo "========================================"
echo "CloudFront Distribution Details"
echo "========================================"
echo "Distribution ID:  $DISTRIBUTION_ID"
echo "Domain Name:      $CLOUDFRONT_DOMAIN"
echo "Status:           $DISTRIBUTION_STATUS"
echo "HTTPS URL:        https://$CLOUDFRONT_DOMAIN"
echo ""
echo "Origin:           $S3_WEBSITE_ENDPOINT"
echo "Price Class:      US, Canada, Europe"
echo "Protocol:         Redirect HTTP to HTTPS"
echo ""

# Save for later use
echo "$DISTRIBUTION_ID" > /tmp/distribution-id.txt
echo "https://$CLOUDFRONT_DOMAIN" > /tmp/cloudfront-url.txt

echo "========================================"
echo "Next Steps"
echo "========================================"
echo ""
echo "1. WAIT for distribution to deploy (10-15 minutes)"
echo "   Check status with:"
echo "   aws cloudfront get-distribution --id $DISTRIBUTION_ID --query 'Distribution.Status'"
echo ""
echo "2. UPDATE Cognito callback URLs to include CloudFront:"
echo "   Run the fix-authentication.sh script after distribution is deployed"
echo ""
echo "3. TEST your web app at:"
echo "   https://$CLOUDFRONT_DOMAIN"
echo ""
echo "Note: The CloudFront URL has been saved to /tmp/cloudfront-url.txt"
echo ""

# Cleanup
rm /tmp/cloudfront-config.json

echo "✅ CloudFront distribution creation initiated!"
