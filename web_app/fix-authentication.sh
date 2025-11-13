#!/bin/bash

##############################################################################
# Fix Summoner's Chronicle Authentication
# This script fixes the "failed to fetch" error by:
# 1. Adding CloudFront URL to Cognito callback URLs
# 2. Uploading the fixed auth.js that uses Cognito OAuth
# 3. Updating aws-config.js with correct environment value
##############################################################################

set -e  # Exit on error

echo "========================================"
echo "Fixing Summoner's Chronicle Authentication"
echo "========================================"
echo ""

# Step 1: Get CloudFormation stack outputs
echo "Step 1: Getting CloudFormation stack information..."
STACK_NAME="summoners-chronicle-webapp"

# Check if stack exists
if ! aws cloudformation describe-stacks --stack-name $STACK_NAME &>/dev/null; then
    echo "Error: CloudFormation stack '$STACK_NAME' not found!"
    echo "Please ensure you've deployed the web app first."
    exit 1
fi

# Get outputs
USER_POOL_ID=$(aws cloudformation describe-stacks --stack-name $STACK_NAME --query 'Stacks[0].Outputs[?OutputKey==`UserPoolId`].OutputValue' --output text)
CLIENT_ID=$(aws cloudformation describe-stacks --stack-name $STACK_NAME --query 'Stacks[0].Outputs[?OutputKey==`UserPoolClientId`].OutputValue' --output text)
IDENTITY_POOL_ID=$(aws cloudformation describe-stacks --stack-name $STACK_NAME --query 'Stacks[0].Outputs[?OutputKey==`IdentityPoolId`].OutputValue' --output text)
CLOUDFRONT_URL=$(aws cloudformation describe-stacks --stack-name $STACK_NAME --query 'Stacks[0].Outputs[?OutputKey==`CloudFrontURL`].OutputValue' --output text)
WEBAPP_BUCKET=$(aws cloudformation describe-stacks --stack-name $STACK_NAME --query 'Stacks[0].Outputs[?OutputKey==`WebAppBucket`].OutputValue' --output text)

# Get region
REGION=$(aws configure get region || echo "us-east-1")

echo "  ✓ User Pool ID: $USER_POOL_ID"
echo "  ✓ Client ID: $CLIENT_ID"
echo "  ✓ CloudFront URL: $CLOUDFRONT_URL"
echo "  ✓ Web App Bucket: $WEBAPP_BUCKET"
echo "  ✓ Region: $REGION"
echo ""

# Step 2: Update Cognito User Pool Client callback URLs
echo "Step 2: Updating Cognito callback URLs..."

# Get current callback URLs
CURRENT_CALLBACKS=$(aws cognito-idp describe-user-pool-client \
    --user-pool-id $USER_POOL_ID \
    --client-id $CLIENT_ID \
    --query 'UserPoolClient.CallbackURLs' \
    --output json)

# Check if CloudFront URL is already added
if echo "$CURRENT_CALLBACKS" | grep -q "$CLOUDFRONT_URL"; then
    echo "  ✓ CloudFront URL already in callback URLs"
else
    echo "  Adding CloudFront URL to callback URLs..."

    # Add CloudFront URLs (both with and without /pages/auth.html)
    aws cognito-idp update-user-pool-client \
        --user-pool-id $USER_POOL_ID \
        --client-id $CLIENT_ID \
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
        --supported-identity-providers "COGNITO"

    echo "  ✓ Callback URLs updated successfully"
fi
echo ""

# Step 3: Update aws-config.js
echo "Step 3: Updating aws-config.js..."

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

# Step 4: Upload fixed auth.js
echo "Step 4: Uploading fixed auth.js..."

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

# Step 5: Invalidate CloudFront cache
echo "Step 5: Invalidating CloudFront cache..."

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
