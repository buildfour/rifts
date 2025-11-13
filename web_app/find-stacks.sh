#!/bin/bash

##############################################################################
# Find Existing CloudFormation Stacks for Summoner's Chronicle
##############################################################################

echo "========================================"
echo "Finding CloudFormation Stacks"
echo "========================================"
echo ""

AWS_REGION=$(aws configure get region || echo "us-east-1")

echo "Searching for CloudFormation stacks in region: $AWS_REGION"
echo ""

# List all active stacks
echo "All active CloudFormation stacks:"
echo "----------------------------------------"
aws cloudformation list-stacks \
    --stack-status-filter CREATE_COMPLETE UPDATE_COMPLETE \
    --query 'StackSummaries[*].[StackName,CreationTime,StackStatus]' \
    --output table \
    --region $AWS_REGION

echo ""
echo "Searching for stacks related to 'summoner' or 'chronicle'..."
echo "----------------------------------------"

MATCHING_STACKS=$(aws cloudformation list-stacks \
    --stack-status-filter CREATE_COMPLETE UPDATE_COMPLETE \
    --query 'StackSummaries[?contains(StackName, `summoner`) || contains(StackName, `chronicle`) || contains(StackName, `webapp`)].StackName' \
    --output text \
    --region $AWS_REGION)

if [ -z "$MATCHING_STACKS" ]; then
    echo "No matching stacks found."
    echo ""
    echo "Possible reasons:"
    echo "  1. Stack was created in a different region"
    echo "  2. Stack has a different name"
    echo "  3. Stack was deleted or is in failed state"
    echo "  4. Deployment was done manually without CloudFormation"
    echo ""
    echo "To check all regions, run:"
    echo "  for region in us-east-1 us-west-2 eu-west-1; do"
    echo "    echo \"Region: \$region\""
    echo "    aws cloudformation list-stacks --region \$region --stack-status-filter CREATE_COMPLETE --query 'StackSummaries[*].StackName' --output text"
    echo "  done"
else
    echo "Found matching stacks:"
    for stack in $MATCHING_STACKS; do
        echo ""
        echo "Stack Name: $stack"
        echo "----------------------------------------"

        # Get stack details
        aws cloudformation describe-stacks \
            --stack-name "$stack" \
            --query 'Stacks[0].[StackStatus,CreationTime,Description]' \
            --output text \
            --region $AWS_REGION

        echo ""
        echo "Stack Outputs:"
        aws cloudformation describe-stacks \
            --stack-name "$stack" \
            --query 'Stacks[0].Outputs[*].[OutputKey,OutputValue]' \
            --output table \
            --region $AWS_REGION

        echo ""
    done
fi

echo ""
echo "========================================"
echo "Web App Resources Check"
echo "========================================"
echo ""

# Check for S3 buckets
echo "S3 buckets related to summoner/chronicle:"
echo "----------------------------------------"
aws s3 ls | grep -i "summoner\|chronicle" || echo "No matching S3 buckets found"

echo ""

# Check for Cognito User Pools
echo "Cognito User Pools:"
echo "----------------------------------------"
aws cognito-idp list-user-pools --max-results 20 --region $AWS_REGION \
    --query 'UserPools[*].[Name,Id]' \
    --output table

echo ""
echo "If you deployed manually, you may need to:"
echo "  1. Identify your S3 bucket name"
echo "  2. Identify your Cognito User Pool ID"
echo "  3. Run create-cloudfront.sh with manual values"
echo ""
