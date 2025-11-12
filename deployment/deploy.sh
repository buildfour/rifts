#!/bin/bash

# RiftSage AI Agent - Deployment Script
# Deploys the complete infrastructure and Lambda functions to AWS

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
PROJECT_NAME="riftsage"
AWS_REGION="${AWS_REGION:-us-east-1}"
ENVIRONMENT="${ENVIRONMENT:-production}"
STACK_NAME="${PROJECT_NAME}-${ENVIRONMENT}"

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}RiftSage AI Agent Deployment${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "Project: $PROJECT_NAME"
echo "Environment: $ENVIRONMENT"
echo "Region: $AWS_REGION"
echo "Stack Name: $STACK_NAME"
echo ""

# Check for required parameters
if [ -z "$RIOT_API_KEY" ]; then
    echo -e "${RED}ERROR: RIOT_API_KEY environment variable is required${NC}"
    echo "Set it with: export RIOT_API_KEY='your-api-key'"
    exit 1
fi

# Step 1: Create S3 bucket for Lambda code if it doesn't exist
LAMBDA_BUCKET="${PROJECT_NAME}-lambda-${ENVIRONMENT}-$(aws sts get-caller-identity --query Account --output text)"

echo -e "${YELLOW}Step 1: Creating S3 bucket for Lambda functions...${NC}"

if aws s3 ls "s3://${LAMBDA_BUCKET}" 2>/dev/null; then
    echo "Bucket already exists: ${LAMBDA_BUCKET}"
else
    aws s3 mb "s3://${LAMBDA_BUCKET}" --region "${AWS_REGION}"
    echo -e "${GREEN}Created bucket: ${LAMBDA_BUCKET}${NC}"
fi

# Step 2: Package Lambda functions
echo -e "${YELLOW}Step 2: Packaging Lambda functions...${NC}"

# Get the project root directory (parent of deployment directory)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

cd "${PROJECT_ROOT}/lambda_functions"

# Package each function
for func in data_collection feature_engineering model_inference bedrock_generation report_compilation resource_manager; do
    echo "Packaging ${func}..."

    # Create temporary directory
    mkdir -p /tmp/${func}_package

    # Copy function code
    cp ${func}.py /tmp/${func}_package/index.py

    # Create zip
    cd /tmp/${func}_package
    zip -r ${func}.zip . > /dev/null 2>&1

    # Upload to S3
    aws s3 cp ${func}.zip "s3://${LAMBDA_BUCKET}/functions/${func}.zip"

    echo -e "${GREEN}✓ ${func} packaged and uploaded${NC}"

    # Cleanup
    cd -
    rm -rf /tmp/${func}_package
done

cd "${PROJECT_ROOT}"

# Step 3: Create ML dependencies layer
echo -e "${YELLOW}Step 3: Creating ML dependencies layer...${NC}"

if [ ! -f "/tmp/ml-dependencies.zip" ]; then
    echo "Building ML dependencies layer..."
    mkdir -p /tmp/python

    pip install -r "${PROJECT_ROOT}/deployment/requirements.txt" -t /tmp/python/ --quiet

    cd /tmp
    zip -r ml-dependencies.zip python > /dev/null 2>&1
    cd -

    aws s3 cp /tmp/ml-dependencies.zip "s3://${LAMBDA_BUCKET}/layers/ml-dependencies.zip"

    echo -e "${GREEN}✓ ML dependencies layer created${NC}"
else
    echo "ML dependencies layer already exists"
fi

# Step 4: Deploy CloudFormation stack
echo -e "${YELLOW}Step 4: Deploying CloudFormation stack...${NC}"

# Check if stack exists
if aws cloudformation describe-stacks --stack-name "${STACK_NAME}" --region "${AWS_REGION}" >/dev/null 2>&1; then
    echo "Stack exists, updating..."
    ACTION="update-stack"
else
    echo "Creating new stack..."
    ACTION="create-stack"
fi

aws cloudformation ${ACTION} \
    --stack-name "${STACK_NAME}" \
    --template-body file://"${PROJECT_ROOT}/infrastructure.yaml" \
    --parameters \
        ParameterKey=Environment,ParameterValue="${ENVIRONMENT}" \
        ParameterKey=RiotAPIKey,ParameterValue="${RIOT_API_KEY}" \
        ParameterKey=ProjectName,ParameterValue="${PROJECT_NAME}" \
        ParameterKey=AutoShutdownEnabled,ParameterValue="true" \
        ParameterKey=IdleThresholdMinutes,ParameterValue="60" \
    --capabilities CAPABILITY_NAMED_IAM \
    --region "${AWS_REGION}"

# Wait for stack to complete
echo "Waiting for stack operation to complete..."

if [ "$ACTION" == "create-stack" ]; then
    aws cloudformation wait stack-create-complete \
        --stack-name "${STACK_NAME}" \
        --region "${AWS_REGION}"
else
    aws cloudformation wait stack-update-complete \
        --stack-name "${STACK_NAME}" \
        --region "${AWS_REGION}" 2>/dev/null || true
fi

echo -e "${GREEN}✓ CloudFormation stack deployed${NC}"

# Step 5: Update Lambda function code
echo -e "${YELLOW}Step 5: Updating Lambda function code...${NC}"

for func in DataCollection FeatureEngineering ModelInference BedrockGeneration ReportCompilation ResourceManager; do
    FUNCTION_NAME="${PROJECT_NAME}-${func}-${ENVIRONMENT}"

    # Convert to lowercase with underscores for zip file name
    ZIP_NAME=$(echo ${func} | sed 's/\([A-Z]\)/_\L\1/g' | sed 's/^_//')

    echo "Updating ${FUNCTION_NAME}..."

    aws lambda update-function-code \
        --function-name "${FUNCTION_NAME}" \
        --s3-bucket "${LAMBDA_BUCKET}" \
        --s3-key "functions/${ZIP_NAME}.zip" \
        --region "${AWS_REGION}" > /dev/null

    echo -e "${GREEN}✓ ${FUNCTION_NAME} updated${NC}"
done

# Step 6: Seed champion database
echo -e "${YELLOW}Step 6: Seeding champion database...${NC}"

if [ -f "${PROJECT_ROOT}/database_seeds/seed_champions.py" ]; then
    python "${PROJECT_ROOT}/database_seeds/seed_champions.py" --environment "${ENVIRONMENT}" --region "${AWS_REGION}"
    echo -e "${GREEN}✓ Champion database seeded${NC}"
else
    echo -e "${YELLOW}Champion seed script not found, skipping...${NC}"
fi

# Step 7: Get stack outputs
echo -e "${YELLOW}Step 7: Retrieving stack outputs...${NC}"

API_ENDPOINT=$(aws cloudformation describe-stacks \
    --stack-name "${STACK_NAME}" \
    --query 'Stacks[0].Outputs[?OutputKey==`APIEndpoint`].OutputValue' \
    --output text \
    --region "${AWS_REGION}")

USER_POOL_ID=$(aws cloudformation describe-stacks \
    --stack-name "${STACK_NAME}" \
    --query 'Stacks[0].Outputs[?OutputKey==`UserPoolId`].OutputValue' \
    --output text \
    --region "${AWS_REGION}")

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Deployment Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "API Endpoint: ${API_ENDPOINT}"
echo "User Pool ID: ${USER_POOL_ID}"
echo ""
echo "Next steps:"
echo "1. Configure your frontend with the API endpoint"
echo "2. Test the system with a sample player"
echo "3. Monitor CloudWatch logs for any issues"
echo ""
echo -e "${GREEN}Happy analyzing!${NC}"
