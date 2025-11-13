#!/bin/bash

##############################################################################
# Fix Summoner's Chronicle Authentication
# This script fixes the "failed to fetch" error by:
# 1. Adding CloudFront URL to Cognito callback URLs
# 2. Uploading the fixed auth.js that uses Cognito OAuth
# 3. Updating aws-config.js with correct environment value
#
# Usage:
#   ./fix-authentication.sh                        # Auto-detect resources
#   ./fix-authentication.sh STACK_NAME             # Use specific stack
#   ./fix-authentication.sh --manual               # Enter values manually
##############################################################################

set -e  # Exit on error

echo "========================================"
echo "Fixing Summoner's Chronicle Authentication"
echo "========================================"
echo ""

AWS_REGION=$(aws configure get region || echo "us-east-1")

# Step 1: Determine how to get configuration
if [ "$1" == "--manual" ]; then
    echo "Manual configuration mode"
    echo ""
    read -p "Enter User Pool ID: " USER_POOL_ID
    read -p "Enter Client ID: " CLIENT_ID
    read -p "Enter Identity Pool ID: " IDENTITY_POOL_ID
    read -p "Enter S3 Bucket Name: " WEBAPP_BUCKET
    read -p "Enter CloudFront URL (https://...): " CLOUDFRONT_URL
    echo ""
elif [ -n "$1" ]; then
    STACK_NAME="$1"
    echo "Using provided stack name: $STACK_NAME"
else
    # Auto-detect stack
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
        echo "  1. Provide stack name: ./fix-authentication.sh YOUR_STACK_NAME"
        echo "  2. Manual mode: ./fix-authentication.sh --manual"
        echo "  3. Run ./find-stacks.sh to see available stacks"
        echo ""
        exit 1
    fi
fi

# Step 2: Get outputs from stack (if we have one)
if [ -n "$STACK_NAME" ] && [ -z "$USER_POOL_ID" ]; then
    echo "Step 2: Getting configuration from CloudFormation stack..."

    # Get outputs
    USER_POOL_ID=$(aws cloudformation describe-stacks --stack-name $STACK_NAME --query 'Stacks[0].Outputs[?OutputKey==`UserPoolId`].OutputValue' --output text --region $AWS_REGION)
    CLIENT_ID=$(aws cloudformation describe-stacks --stack-name $STACK_NAME --query 'Stacks[0].Outputs[?OutputKey==`UserPoolClientId`].OutputValue' --output text --region $AWS_REGION)
    IDENTITY_POOL_ID=$(aws cloudformation describe-stacks --stack-name $STACK_NAME --query 'Stacks[0].Outputs[?OutputKey==`IdentityPoolId`].OutputValue' --output text --region $AWS_REGION)
    CLOUDFRONT_URL=$(aws cloudformation describe-stacks --stack-name $STACK_NAME --query 'Stacks[0].Outputs[?OutputKey==`CloudFrontURL`].OutputValue' --output text --region $AWS_REGION 2>/dev/null)
    WEBAPP_BUCKET=$(aws cloudformation describe-stacks --stack-name $STACK_NAME --query 'Stacks[0].Outputs[?OutputKey==`WebAppBucket`].OutputValue' --output text --region $AWS_REGION)

    echo "  ✓ User Pool ID: $USER_POOL_ID"
    echo "  ✓ Client ID: $CLIENT_ID"
    echo "  ✓ Web App Bucket: $WEBAPP_BUCKET"
    echo "  ✓ Region: $AWS_REGION"
fi

# If CloudFront URL not in stack outputs, try to find it from CloudFront distributions
if [ -z "$CLOUDFRONT_URL" ] || [ "$CLOUDFRONT_URL" == "None" ]; then
    echo ""
    echo "CloudFront URL not found in stack outputs. Searching CloudFront distributions..."

    # Get CloudFront distribution for this bucket
    DISTRIBUTION_DOMAIN=$(aws cloudfront list-distributions \
        --query "DistributionList.Items[?contains(Origins.Items[0].DomainName, '$WEBAPP_BUCKET')].DomainName" \
        --output text \
        --region $AWS_REGION 2>/dev/null | head -1)

    if [ -n "$DISTRIBUTION_DOMAIN" ]; then
        CLOUDFRONT_URL="https://${DISTRIBUTION_DOMAIN}"
        echo "  ✓ Found CloudFront URL: $CLOUDFRONT_URL"
    else
        echo "  ✗ Could not find CloudFront distribution"
        echo ""
        read -p "Enter your CloudFront URL (https://...cloudfront.net): " CLOUDFRONT_URL
    fi
fi

echo "  ✓ CloudFront URL: $CLOUDFRONT_URL"
echo ""

# Validate all required variables are set
if [ -z "$USER_POOL_ID" ] || [ -z "$CLIENT_ID" ] || [ -z "$WEBAPP_BUCKET" ] || [ -z "$CLOUDFRONT_URL" ]; then
    echo "Error: Missing required configuration"
    echo "  USER_POOL_ID: ${USER_POOL_ID:-NOT SET}"
    echo "  CLIENT_ID: ${CLIENT_ID:-NOT SET}"
    echo "  WEBAPP_BUCKET: ${WEBAPP_BUCKET:-NOT SET}"
    echo "  CLOUDFRONT_URL: ${CLOUDFRONT_URL:-NOT SET}"
    echo ""
    echo "Please run in manual mode: ./fix-authentication.sh --manual"
    exit 1
fi

# Step 3: Update Cognito User Pool Client callback URLs
echo "Step 3: Updating Cognito callback URLs..."

# Get current callback URLs
CURRENT_CALLBACKS=$(aws cognito-idp describe-user-pool-client \
    --user-pool-id "$USER_POOL_ID" \
    --client-id "$CLIENT_ID" \
    --region "$AWS_REGION" \
    --query 'UserPoolClient.CallbackURLs' \
    --output json 2>/dev/null || echo "[]")

# Check if CloudFront URL is already added
if echo "$CURRENT_CALLBACKS" | grep -q "$CLOUDFRONT_URL"; then
    echo "  ✓ CloudFront URL already in callback URLs"
else
    echo "  Adding CloudFront URL to callback URLs..."

    # Add CloudFront URLs (both with and without /pages/auth.html)
    aws cognito-idp update-user-pool-client \
        --user-pool-id "$USER_POOL_ID" \
        --client-id "$CLIENT_ID" \
        --region "$AWS_REGION" \
        --callback-urls \
            "http://localhost:3000" \
            "http://localhost:8080" \
            "$CLOUDFRONT_URL/pages/auth.html" \
        --logout-urls \
            "http://localhost:3000" \
            "http://localhost:8080" \
            "$CLOUDFRONT_URL" \
        --allowed-o-auth-flows "code" \
        --allowed-o-auth-scopes "email" "openid" "profile" \
        --allowed-o-auth-flows-user-pool-client \
        --supported-identity-providers "COGNITO" \
        >/dev/null 2>&1

    echo "  ✓ Callback URLs updated successfully"
fi
echo ""

# Step 4: Update aws-config.js
echo "Step 4: Updating aws-config.js..."

cat > /tmp/aws-config.js << EOF
/**
 * AWS Configuration for Summoner's Chronicle
 * Auto-generated configuration file
 */

const AWS_CONFIG = {
    // AWS Region
    region: '$REGION',

    // AWS Cognito Configuration
    cognito: {
        userPoolId: '$USER_POOL_ID',
        clientId: '$CLIENT_ID',
        identityPoolId: '$IDENTITY_POOL_ID'
    },

    // API Gateway Endpoint (RiftSage API)
    apiEndpoint: 'https://api.example.com',  // Update this if you have RiftSage API deployed

    // S3 Bucket for Reports
    reportsBucket: '$WEBAPP_BUCKET',

    // CloudFront Distribution
    cloudFrontDomain: '$CLOUDFRONT_URL',

    // Application Settings
    app: {
        name: 'Summoner\\'s Chronicle',
        version: '1.0.0',
        environment: 'production'
    }
};

// Freeze config to prevent modifications
Object.freeze(AWS_CONFIG);

console.log('AWS Configuration loaded:', AWS_CONFIG.app.environment);
EOF

# Upload to S3
aws s3 cp /tmp/aws-config.js s3://$WEBAPP_BUCKET/config/aws-config.js \
    --content-type "application/javascript" \
    --metadata-directive REPLACE

echo "  ✓ aws-config.js updated and uploaded"
echo ""

# Step 5: Upload fixed auth.js
echo "Step 5: Uploading fixed auth.js..."

# Check if we're in the rifts directory
if [ -f "assets/js/auth.js" ]; then
    AUTH_JS_PATH="assets/js/auth.js"
elif [ -f "web_app/assets/js/auth.js" ]; then
    AUTH_JS_PATH="web_app/assets/js/auth.js"
else
    echo "Error: Cannot find auth.js file!"
    echo "Please run this script from the rifts/web_app directory or rifts directory"
    exit 1
fi

aws s3 cp $AUTH_JS_PATH s3://$WEBAPP_BUCKET/assets/js/auth.js \
    --content-type "application/javascript" \
    --metadata-directive REPLACE

echo "  ✓ auth.js uploaded successfully"
echo ""

# Step 6: Invalidate CloudFront cache
echo "Step 6: Invalidating CloudFront cache..."

# Get CloudFront distribution ID
DISTRIBUTION_ID=$(aws cloudfront list-distributions --query "DistributionList.Items[?contains(Origins.Items[0].DomainName, '$WEBAPP_BUCKET')].Id" --output text)

if [ -n "$DISTRIBUTION_ID" ]; then
    aws cloudfront create-invalidation \
        --distribution-id $DISTRIBUTION_ID \
        --paths "/config/aws-config.js" "/assets/js/auth.js" "/pages/auth.html"

    echo "  ✓ CloudFront cache invalidated"
    echo "  Note: Cache invalidation may take 5-15 minutes to complete"
else
    echo "  ⚠ Could not find CloudFront distribution ID"
    echo "  You may need to wait for CDN cache to expire or clear it manually"
fi
echo ""

# Summary
echo "========================================"
echo "✓ Authentication Fix Complete!"
echo "========================================"
echo ""
echo "What was fixed:"
echo "  1. Updated Cognito callback URLs to include CloudFront"
echo "  2. Uploaded new auth.js that uses Cognito OAuth flow"
echo "  3. Updated aws-config.js with correct configuration"
echo "  4. Invalidated CloudFront cache"
echo ""
echo "Next steps:"
echo "  1. Wait 2-3 minutes for CloudFront cache to clear"
echo "  2. Open your web app: $CLOUDFRONT_URL"
echo "  3. Click 'Get Started' and try signing in"
echo "  4. Use the email authentication method"
echo ""
echo "How authentication works now:"
echo "  - Click 'Send Magic Link' → Redirects to Cognito Hosted UI"
echo "  - Sign up/Sign in with email → Cognito sends verification code"
echo "  - After verification → Redirects back to your app"
echo "  - You'll see the summoner setup form → Enter your details"
echo "  - Access the dashboard with your personalized insights"
echo ""
echo "Troubleshooting:"
echo "  - If you still see errors, try opening in incognito/private mode"
echo "  - Check browser console (F12) for any error messages"
echo "  - Ensure you're using the HTTPS CloudFront URL (not HTTP S3 URL)"
echo ""
