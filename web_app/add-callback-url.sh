#!/bin/bash

# ==============================================================================
# Post-Deployment: Add S3 Callback URL to Cognito
# ==============================================================================
# Run this after CloudFormation stack is created to add the S3 website URL
# to Cognito User Pool Client callback URLs
# ==============================================================================

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
PROJECT_NAME="${PROJECT_NAME:-summoners-chronicle}"
ENVIRONMENT="${ENVIRONMENT:-production}"
AWS_REGION="${AWS_REGION:-us-east-1}"
STACK_NAME="${PROJECT_NAME}-webapp-${ENVIRONMENT}"

echo -e "${BLUE}Adding S3 Callback URL to Cognito...${NC}"
echo ""

# Get AWS Account ID
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
WEBAPP_BUCKET="${PROJECT_NAME}-webapp-${ENVIRONMENT}-${AWS_ACCOUNT_ID}"
WEBAPP_URL="http://${WEBAPP_BUCKET}.s3-website-${AWS_REGION}.amazonaws.com"

# Get User Pool ID and Client ID from CloudFormation
USER_POOL_ID=$(aws cloudformation describe-stacks \
    --stack-name "${STACK_NAME}" \
    --query 'Stacks[0].Outputs[?OutputKey==`UserPoolId`].OutputValue' \
    --output text \
    --region "${AWS_REGION}")

CLIENT_ID=$(aws cloudformation describe-stacks \
    --stack-name "${STACK_NAME}" \
    --query 'Stacks[0].Outputs[?OutputKey==`ClientId`].OutputValue' \
    --output text \
    --region "${AWS_REGION}")

echo "User Pool ID: ${USER_POOL_ID}"
echo "Client ID: ${CLIENT_ID}"
echo "S3 Website URL: ${WEBAPP_URL}"
echo ""

# Get current callback URLs
CURRENT_CALLBACKS=$(aws cognito-idp describe-user-pool-client \
    --user-pool-id "${USER_POOL_ID}" \
    --client-id "${CLIENT_ID}" \
    --query 'UserPoolClient.CallbackURLs' \
    --region "${AWS_REGION}")

# Add S3 URL if not already present
if echo "$CURRENT_CALLBACKS" | grep -q "${WEBAPP_URL}"; then
    echo -e "${YELLOW}S3 URL already in callback URLs${NC}"
else
    # Get all current settings to preserve them
    CLIENT_CONFIG=$(aws cognito-idp describe-user-pool-client \
        --user-pool-id "${USER_POOL_ID}" \
        --client-id "${CLIENT_ID}" \
        --region "${AWS_REGION}" \
        --output json)

    # Extract current callback and logout URLs
    CURRENT_CALLBACKS_JSON=$(echo "$CLIENT_CONFIG" | jq -r '.UserPoolClient.CallbackURLs')
    CURRENT_LOGOUT_JSON=$(echo "$CLIENT_CONFIG" | jq -r '.UserPoolClient.LogoutURLs')

    # Add S3 URL to arrays
    NEW_CALLBACKS=$(echo "$CURRENT_CALLBACKS_JSON" | jq --arg url "$WEBAPP_URL" '. + [$url] | unique')
    NEW_LOGOUT=$(echo "$CURRENT_LOGOUT_JSON" | jq --arg url "$WEBAPP_URL" '. + [$url] | unique')

    # Update User Pool Client
    aws cognito-idp update-user-pool-client \
        --user-pool-id "${USER_POOL_ID}" \
        --client-id "${CLIENT_ID}" \
        --callback-urls $(echo "$NEW_CALLBACKS" | jq -r '.[]') \
        --logout-urls $(echo "$NEW_LOGOUT" | jq -r '.[]') \
        --allowed-o-auth-flows code \
        --allowed-o-auth-scopes email openid profile \
        --allowed-o-auth-flows-user-pool-client \
        --supported-identity-providers COGNITO \
        --region "${AWS_REGION}"

    echo -e "${GREEN}✓ S3 URL added to callback URLs${NC}"
fi

echo ""
echo -e "${GREEN}Configuration complete!${NC}"
echo ""
echo -e "${YELLOW}IMPORTANT NOTE:${NC}"
echo "HTTP URLs only work for localhost development."
echo "For production, you need HTTPS via CloudFront:"
echo ""
echo "1. Create CloudFront distribution pointing to S3 bucket"
echo "2. Get CloudFront domain (e.g., https://d123456.cloudfront.net)"
echo "3. Run this script again with HTTPS URL"
echo ""
echo "Web App URL: ${WEBAPP_URL}"
