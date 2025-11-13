#!/bin/bash

##############################################################################
# Create CloudFront Distribution for Summoner's Chronicle
# This script properly configures and creates a CloudFront distribution
#
# Usage:
#   ./create-cloudfront.sh                    # Auto-detect stack
#   ./create-cloudfront.sh STACK_NAME         # Use specific stack name
#   ./create-cloudfront.sh --bucket BUCKET    # Use specific bucket name
##############################################################################

set -e  # Exit on error

echo "========================================"
echo "Creating CloudFront Distribution"
echo "========================================"
echo ""

AWS_REGION=$(aws configure get region || echo "us-east-1")

# Parse arguments
if [ "$1" == "--bucket" ] && [ -n "$2" ]; then
    # User provided bucket name directly
    WEBAPP_BUCKET="$2"
    echo "Using provided bucket: $WEBAPP_BUCKET"
elif [ -n "$1" ]; then
    # User provided stack name
    STACK_NAME="$1"
    echo "Using provided stack name: $STACK_NAME"
else
    # Try to auto-detect stack
    echo "Step 1: Auto-detecting CloudFormation stack..."

    # Try common stack names
    for name in "summoners-chronicle-webapp" "summoners-chronicle" "chronicle-webapp" "webapp"; do
        if aws cloudformation describe-stacks --stack-name "$name" --region $AWS_REGION &>/dev/null; then
            STACK_NAME="$name"
            echo "  ✓ Found stack: $STACK_NAME"
            break
        fi
    done

    # If still not found, search for any stack with summoner/chronicle in name
    if [ -z "$STACK_NAME" ]; then
        MATCHING_STACK=$(aws cloudformation list-stacks \
            --stack-status-filter CREATE_COMPLETE UPDATE_COMPLETE \
            --query 'StackSummaries[?contains(StackName, `summoner`) || contains(StackName, `chronicle`)].StackName' \
            --output text \
            --region $AWS_REGION | head -1)

        if [ -n "$MATCHING_STACK" ]; then
            STACK_NAME="$MATCHING_STACK"
            echo "  ✓ Found matching stack: $STACK_NAME"
        fi
    fi

    if [ -z "$STACK_NAME" ]; then
        echo ""
        echo "Error: Could not auto-detect CloudFormation stack"
        echo ""
        echo "Options:"
        echo "  1. Provide stack name: ./create-cloudfront.sh YOUR_STACK_NAME"
        echo "  2. Provide bucket name: ./create-cloudfront.sh --bucket YOUR_BUCKET_NAME"
        echo "  3. Run ./find-stacks.sh to see available stacks"
        echo ""
        exit 1
    fi
fi

# Step 2: Get the S3 bucket name (if we have a stack name)
if [ -z "$WEBAPP_BUCKET" ]; then
    echo "Step 2: Getting S3 bucket from CloudFormation stack..."
    WEBAPP_BUCKET=$(aws cloudformation describe-stacks \
        --stack-name "$STACK_NAME" \
        --query 'Stacks[0].Outputs[?OutputKey==`WebAppBucket`].OutputValue' \
        --output text \
        --region $AWS_REGION 2>/dev/null)

    if [ -z "$WEBAPP_BUCKET" ]; then
        echo "  ✗ Could not find WebAppBucket output from stack"
        echo ""
        echo "Attempting to find S3 bucket manually..."

        # Try to find bucket by naming convention
        WEBAPP_BUCKET=$(aws s3 ls | grep -i "summoner\|chronicle" | awk '{print $3}' | head -1)

        if [ -z "$WEBAPP_BUCKET" ]; then
            echo "Error: Could not find S3 bucket"
            echo ""
            echo "Please run with bucket name: ./create-cloudfront.sh --bucket YOUR_BUCKET_NAME"
            exit 1
        fi

        echo "  ✓ Found bucket: $WEBAPP_BUCKET"
    fi
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
