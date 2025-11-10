# AWS Stack - Resources and Cost Analysis

Complete breakdown of AWS resources used by Summoner's Chronicle and RiftSage AI Agent, including estimated costs.

**Last Updated**: November 2025
**Region**: US East (N. Virginia) - us-east-1
**Pricing**: Based on AWS pricing as of November 2025

---

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Frontend Resources](#frontend-resources)
3. [Backend Resources](#backend-resources)
4. [Database Resources](#database-resources)
5. [Storage Resources](#storage-resources)
6. [Security & Authentication](#security--authentication)
7. [Monitoring & Logging](#monitoring--logging)
8. [Cost Summary](#cost-summary)
9. [Cost Optimization](#cost-optimization)

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                         User/Browser                             │
└────────────────┬────────────────────────────────────────────────┘
                 │
                 │ HTTPS
                 ▼
┌─────────────────────────────────────────────────────────────────┐
│                      Route 53 (DNS)                              │
│                    $0.50/month per hosted zone                   │
└────────────────┬────────────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────────────┐
│              CloudFront CDN (Global Edge)                        │
│         $0.085/GB data transfer + $0.0075/10k requests          │
└─────┬───────────────────────────────────────────────────────────┘
      │
      ├─────► Static Assets (S3 Bucket)
      │        $0.023/GB storage + $0.0004/1k GET requests
      │
      └─────► API Gateway (REST API)
               $3.50/million requests
               │
               ▼
      ┌────────────────────────────────────────────┐
      │         AWS Lambda Functions               │
      │   $0.20/million requests + compute time    │
      └────────────────┬───────────────────────────┘
                       │
                       ▼
      ┌────────────────────────────────────────────┐
      │     RDS PostgreSQL (Database)              │
      │   $0.017/hour (db.t4g.micro)              │
      └────────────────────────────────────────────┘
```

---

## Frontend Resources

### 1. AWS Amplify

**Resource**: Summoner's Chronicle Web Hosting

**Service**: AWS Amplify Console
**Type**: Static web hosting with CI/CD
**Region**: Global (CloudFront CDN)

**Resources Created**:
- Amplify App
- Branch (main)
- Build pipeline
- CloudFront distribution (auto-created)
- SSL certificate (auto-provisioned via ACM)

**Pricing**:
- **Build minutes**: $0.01 per build minute
- **Hosting**: $0.15 per GB served
- **Storage**: Free (included)

**Monthly Estimate** (10,000 users):
```
Build minutes:   10 builds × 2 min        = $0.20
Data transfer:   100 GB × $0.15          = $15.00
Total:                                    = $15.20/month
```

**Resource ARN**:
```
arn:aws:amplify:us-east-1:ACCOUNT_ID:apps/APP_ID
```

---

### 2. CloudFront (CDN)

**Resource**: Content Delivery Network

**Service**: Amazon CloudFront
**Type**: CDN Distribution
**Edge Locations**: 400+ globally

**Resources Created**:
- CloudFront Distribution
- Origin Access Identity (OAI)
- SSL/TLS Certificate (via ACM)

**Pricing**:
- **Data transfer out**: $0.085 per GB (first 10 TB/month)
- **HTTP/HTTPS requests**: $0.0075 per 10,000 requests
- **Invalidation requests**: First 1,000 paths free, then $0.005 per path

**Monthly Estimate** (10,000 users, 5 page views each):
```
Data transfer:     100 GB × $0.085       = $8.50
HTTP requests:     500k × $0.75/10k      = $37.50
Invalidations:     100 paths × $0.005    = $0.50
Total:                                    = $46.50/month
```

**Resource ARN**:
```
arn:aws:cloudfront::ACCOUNT_ID:distribution/DISTRIBUTION_ID
```

---

### 3. S3 (Static Storage)

**Resource**: Website Files Storage

**Service**: Amazon S3
**Bucket Name**: `summoners-chronicle-prod`
**Region**: us-east-1

**Storage**:
- HTML, CSS, JavaScript files
- Images and assets
- Reports (PDF exports)

**Pricing**:
- **Storage**: $0.023 per GB/month (Standard)
- **GET requests**: $0.0004 per 1,000 requests
- **PUT requests**: $0.005 per 1,000 requests
- **Data transfer OUT**: $0.09 per GB (to internet, first 10 TB)

**Monthly Estimate** (10,000 users):
```
Storage:           5 GB × $0.023          = $0.12
GET requests:      1M × $0.0004/1k       = $0.40
PUT requests:      10k × $0.005/1k       = $0.05
Total:                                    = $0.57/month
```

**Resource ARN**:
```
arn:aws:s3:::summoners-chronicle-prod
```

---

### 4. Route 53 (DNS)

**Resource**: Domain Name System

**Service**: Amazon Route 53
**Hosted Zone**: summoners-chronicle.com

**Resources Created**:
- Hosted Zone
- A Records (alias to CloudFront)
- CNAME Records (www, api)
- TXT Records (domain verification)

**Pricing**:
- **Hosted zone**: $0.50 per month
- **Standard queries**: $0.40 per million queries
- **Alias queries**: Free (to AWS resources)

**Monthly Estimate**:
```
Hosted zone:       1 × $0.50             = $0.50
Queries:           10M × $0.40/1M        = $4.00
Total:                                    = $4.50/month
```

**Resource ARN**:
```
arn:aws:route53:::hostedzone/HOSTED_ZONE_ID
```

---

### 5. ACM (SSL Certificates)

**Resource**: SSL/TLS Certificates

**Service**: AWS Certificate Manager
**Certificates**: *.summoners-chronicle.com

**Pricing**: **FREE** (when used with AWS services)

**Monthly Estimate**: $0.00

**Resource ARN**:
```
arn:aws:acm:us-east-1:ACCOUNT_ID:certificate/CERT_ID
```

---

## Backend Resources

### 1. API Gateway

**Resource**: RESTful API Endpoints

**Service**: Amazon API Gateway
**Type**: REST API
**API Name**: summoners-chronicle-api

**Endpoints**:
- `POST /auth/magic-link`
- `POST /auth/verify`
- `POST /summoner/link`
- `GET /report/{playerId}`
- `GET /matches/{playerId}`
- `PUT /blueprint/{playerId}`
- `GET /leaderboards`
- `POST /share`

**Pricing**:
- **REST API requests**: $3.50 per million requests
- **Data transfer OUT**: $0.09 per GB
- **Caching** (optional): $0.020 per hour for 0.5GB cache

**Monthly Estimate** (10,000 users, 50 API calls each):
```
API requests:      500k × $3.50/1M       = $1.75
Data transfer:     50 GB × $0.09         = $4.50
Total:                                    = $6.25/month
```

**Resource ARN**:
```
arn:aws:apigateway:us-east-1::/restapis/API_ID
```

---

### 2. AWS Lambda

**Resource**: Serverless Backend Functions

**Service**: AWS Lambda
**Runtime**: Python 3.11
**Memory**: 512 MB (average)

**Functions Created**:

#### Authentication Functions
- `summoners-chronicle-auth-magic-link` (256 MB)
- `summoners-chronicle-auth-verify` (256 MB)

#### Report Generation Functions
- `summoners-chronicle-report-generate` (1024 MB)
- `summoners-chronicle-report-fetch` (512 MB)

#### Analytics Functions
- `summoners-chronicle-analytics-process` (512 MB)
- `summoners-chronicle-analytics-aggregate` (1024 MB)

#### Utility Functions
- `summoners-chronicle-summoner-link` (256 MB)
- `summoners-chronicle-leaderboard` (512 MB)

**Pricing**:
- **Requests**: $0.20 per million requests
- **Compute**: $0.0000166667 per GB-second
- **Free tier**: 1M requests and 400,000 GB-seconds per month

**Monthly Estimate** (10,000 users):
```
Requests:          500k × $0.20/1M       = $0.10
Compute (512MB):   500k × 0.5s × 0.5GB
                   × $0.0000166667        = $2.08
Total:                                    = $2.18/month
```

**Resource ARNs**:
```
arn:aws:lambda:us-east-1:ACCOUNT_ID:function/summoners-chronicle-*
```

---

### 3. Cognito (Authentication)

**Resource**: User Authentication & Authorization

**Service**: AWS Cognito
**User Pool**: summoners-chronicle-users
**Type**: User Pool with Magic Link auth

**Resources Created**:
- User Pool
- App Client
- Identity Pool (for AWS resource access)

**Features**:
- Email-based magic link authentication
- JWT token generation
- User management
- Multi-device support

**Pricing**:
- **Monthly Active Users (MAUs)**:
  - First 50,000: Free
  - 50,001-100,000: $0.0055 per MAU
  - 100,001+: $0.0046 per MAU
- **Advanced security features**: $0.05 per MAU (optional)

**Monthly Estimate** (10,000 MAUs):
```
MAUs (under 50k):  10,000 × $0.00       = $0.00
Total:                                   = $0.00/month (Free Tier)
```

**Resource ARN**:
```
arn:aws:cognito-idp:us-east-1:ACCOUNT_ID:userpool/USER_POOL_ID
```

---

## Database Resources

### 1. RDS PostgreSQL

**Resource**: Relational Database

**Service**: Amazon RDS for PostgreSQL
**Instance**: db.t4g.micro
**Engine**: PostgreSQL 15.4
**Storage**: 20 GB SSD (gp3)

**Specifications**:
- vCPUs: 2
- RAM: 1 GB
- Network: Moderate
- Multi-AZ: No (for dev), Yes (for prod)

**Pricing**:
- **Instance**: $0.017 per hour ($12.24/month for single-AZ)
- **Multi-AZ**: $0.034 per hour ($24.48/month)
- **Storage (gp3)**: $0.115 per GB-month
- **IOPS**: Included (3,000 baseline)
- **Backup storage**: Free up to 20 GB
- **Data transfer**: $0.01 per GB (within same region)

**Monthly Estimate** (Production, Multi-AZ):
```
Instance (multi-AZ): 730 hrs × $0.034   = $24.82
Storage (gp3):       20 GB × $0.115     = $2.30
Backup storage:      20 GB × $0.00      = $0.00
Total:                                   = $27.12/month
```

**Development** (Single-AZ):
```
Instance:            730 hrs × $0.017   = $12.41
Storage:             20 GB × $0.115     = $2.30
Total:                                   = $14.71/month
```

**Resource ARN**:
```
arn:aws:rds:us-east-1:ACCOUNT_ID:db:summoners-chronicle-db
```

---

### 2. ElastiCache (Redis)

**Resource**: In-Memory Cache

**Service**: Amazon ElastiCache for Redis
**Node Type**: cache.t4g.micro
**Nodes**: 1 (dev), 2 (prod with replication)

**Use Cases**:
- Session storage
- API response caching
- Rate limiting
- Leaderboard caching

**Pricing**:
- **Node**: $0.017 per hour ($12.41/month)
- **Backup storage**: $0.085 per GB-month

**Monthly Estimate** (Production, 2 nodes):
```
Nodes:               2 × 730 × $0.017   = $24.82
Backup:              5 GB × $0.085      = $0.43
Total:                                   = $25.25/month
```

**Resource ARN**:
```
arn:aws:elasticache:us-east-1:ACCOUNT_ID:cluster:summoners-chronicle-cache
```

---

## Storage Resources

### 1. S3 (Data Storage)

**Resource**: Long-term Data Storage

**Buckets**:
- `summoners-chronicle-reports` - Generated PDF reports
- `summoners-chronicle-backups` - Database backups
- `summoners-chronicle-logs` - Application logs

**Storage Classes**:
- **Standard**: Active reports and recent logs
- **Intelligent-Tiering**: Older reports (auto-archival)
- **Glacier**: Long-term backups

**Pricing** (S3 Standard):
- **Storage**: $0.023 per GB/month
- **Requests (GET)**: $0.0004 per 1,000
- **Requests (PUT)**: $0.005 per 1,000

**Monthly Estimate**:
```
Reports storage:     100 GB × $0.023    = $2.30
Backups (Glacier):   200 GB × $0.004    = $0.80
Logs storage:        50 GB × $0.023     = $1.15
Total:                                   = $4.25/month
```

**Resource ARNs**:
```
arn:aws:s3:::summoners-chronicle-reports
arn:aws:s3:::summoners-chronicle-backups
arn:aws:s3:::summoners-chronicle-logs
```

---

## Security & Authentication

### 1. IAM Roles & Policies

**Resources**: Identity and Access Management

**Service**: AWS IAM
**Cost**: **FREE**

**Roles Created**:
- `summoners-chronicle-lambda-execution-role`
- `summoners-chronicle-api-gateway-role`
- `summoners-chronicle-amplify-backend-role`

**Policies**:
- Custom policies for least-privilege access
- Trust policies for service-to-service communication

**Monthly Estimate**: $0.00

---

### 2. Secrets Manager

**Resource**: Secret Storage

**Service**: AWS Secrets Manager
**Secrets**: API keys, database credentials, JWT secrets

**Pricing**:
- **Secret storage**: $0.40 per secret per month
- **API calls**: $0.05 per 10,000 API calls

**Monthly Estimate** (5 secrets):
```
Secrets:             5 × $0.40          = $2.00
API calls:           100k × $0.05/10k   = $0.50
Total:                                   = $2.50/month
```

**Resource ARN**:
```
arn:aws:secretsmanager:us-east-1:ACCOUNT_ID:secret:summoners-chronicle/*
```

---

### 3. WAF (Web Application Firewall)

**Resource**: Application Security

**Service**: AWS WAF (Optional for production)
**Type**: Managed rules + custom rules

**Pricing**:
- **Web ACL**: $5.00 per month
- **Rules**: $1.00 per rule per month
- **Requests**: $0.60 per million requests

**Monthly Estimate** (Optional):
```
Web ACL:             1 × $5.00          = $5.00
Rules:               5 × $1.00          = $5.00
Requests:            1M × $0.60/1M      = $0.60
Total:                                   = $10.60/month
```

---

## Monitoring & Logging

### 1. CloudWatch

**Resource**: Monitoring and Logging

**Service**: Amazon CloudWatch
**Components**: Logs, Metrics, Alarms, Dashboards

**Logs**:
- Lambda function logs
- API Gateway access logs
- Application logs

**Metrics**:
- Custom application metrics
- AWS service metrics

**Alarms**:
- 5xx error rate
- Lambda errors
- Database connections
- API latency

**Pricing**:
- **Logs ingestion**: $0.50 per GB
- **Logs storage**: $0.03 per GB/month
- **Metrics**: $0.30 per custom metric/month
- **Alarms**: $0.10 per alarm/month
- **Dashboard**: $3.00 per month

**Monthly Estimate**:
```
Logs ingestion:      10 GB × $0.50      = $5.00
Logs storage:        100 GB × $0.03     = $3.00
Custom metrics:      20 × $0.30         = $6.00
Alarms:              10 × $0.10         = $1.00
Dashboard:           1 × $3.00          = $3.00
Total:                                   = $18.00/month
```

**Resource ARNs**:
```
arn:aws:logs:us-east-1:ACCOUNT_ID:log-group:/aws/lambda/summoners-chronicle-*
```

---

### 2. X-Ray (Distributed Tracing)

**Resource**: Application Tracing (Optional)

**Service**: AWS X-Ray
**Use**: Performance analysis and debugging

**Pricing**:
- **Traces recorded**: $5.00 per million traces
- **Traces retrieved**: $0.50 per million traces
- **Free tier**: 100,000 traces per month

**Monthly Estimate** (Optional):
```
Traces (500k):       500k × $5.00/1M    = $2.50
Retrieval:           50k × $0.50/1M     = $0.03
Total:                                   = $2.53/month
```

---

## Cost Summary

### Development Environment

| Service | Monthly Cost |
|---------|-------------|
| AWS Amplify | $5.00 |
| CloudFront | $10.00 |
| S3 | $0.50 |
| Route 53 | $4.50 |
| API Gateway | $2.00 |
| Lambda | $1.00 (Free Tier) |
| Cognito | $0.00 (Free Tier) |
| RDS (Single-AZ) | $14.71 |
| ElastiCache (1 node) | $12.41 |
| CloudWatch | $5.00 |
| Secrets Manager | $2.50 |
| **TOTAL** | **$57.62/month** |

---

### Staging Environment

| Service | Monthly Cost |
|---------|-------------|
| AWS Amplify | $8.00 |
| CloudFront | $20.00 |
| S3 | $1.00 |
| Route 53 | $4.50 |
| API Gateway | $4.00 |
| Lambda | $1.50 |
| Cognito | $0.00 (Free Tier) |
| RDS (Single-AZ) | $14.71 |
| ElastiCache (1 node) | $12.41 |
| CloudWatch | $10.00 |
| Secrets Manager | $2.50 |
| **TOTAL** | **$78.62/month** |

---

### Production Environment (10,000 Active Users)

| Service | Monthly Cost |
|---------|-------------|
| AWS Amplify | $15.20 |
| CloudFront | $46.50 |
| S3 (Static Assets) | $0.57 |
| S3 (Data Storage) | $4.25 |
| Route 53 | $4.50 |
| API Gateway | $6.25 |
| Lambda | $2.18 |
| Cognito | $0.00 (Free Tier) |
| RDS (Multi-AZ) | $27.12 |
| ElastiCache (2 nodes) | $25.25 |
| CloudWatch | $18.00 |
| Secrets Manager | $2.50 |
| WAF (Optional) | $10.60 |
| X-Ray (Optional) | $2.53 |
| **TOTAL** | **$165.45/month** |

**Without Optional Services**: $152.32/month

---

### Production Environment (50,000 Active Users)

| Service | Monthly Cost |
|---------|-------------|
| AWS Amplify | $35.00 |
| CloudFront | $180.00 |
| S3 (Static Assets) | $2.00 |
| S3 (Data Storage) | $15.00 |
| Route 53 | $8.00 |
| API Gateway | $20.00 |
| Lambda | $8.50 |
| Cognito | $27.50 (MAUs over 50k) |
| RDS (db.t4g.small, Multi-AZ) | $54.24 |
| ElastiCache (cache.t4g.small, 2 nodes) | $50.48 |
| CloudWatch | $35.00 |
| Secrets Manager | $2.50 |
| WAF | $15.00 |
| X-Ray | $10.00 |
| **TOTAL** | **$463.22/month** |

---

### Projected Costs by User Count

| Users | Monthly Cost | Cost per User |
|-------|-------------|---------------|
| 1,000 | $85.00 | $0.085 |
| 5,000 | $120.00 | $0.024 |
| 10,000 | $165.45 | $0.017 |
| 25,000 | $285.00 | $0.011 |
| 50,000 | $463.22 | $0.009 |
| 100,000 | $820.00 | $0.008 |

---

## Cost Optimization

### 1. Use AWS Free Tier

**Services with Free Tier**:
- Lambda: 1M requests/month free
- Cognito: 50,000 MAUs free
- CloudWatch: 5 GB logs ingestion free
- API Gateway: N/A (no free tier for REST API)

**Estimated Savings**: $5-10/month

---

### 2. Reserved Instances

**RDS Reserved Instances** (1-year, no upfront):
- **On-Demand**: $27.12/month
- **Reserved**: $17.40/month
- **Savings**: 36% ($9.72/month)

**ElastiCache Reserved Nodes**:
- **On-Demand**: $25.25/month (2 nodes)
- **Reserved**: $16.20/month
- **Savings**: 36% ($9.05/month)

**Total RI Savings**: $18.77/month ($225/year)

---

### 3. S3 Intelligent-Tiering

Move older reports to Intelligent-Tiering:
- **Standard**: $0.023/GB
- **Intelligent-Tiering**: $0.0125/GB (archive tier)
- **Savings**: 46% on archived data

**Estimated Savings**: $2-5/month

---

### 4. CloudFront Optimization

- Enable compression
- Set appropriate cache TTLs
- Use CloudFront Functions for edge logic

**Estimated Savings**: 20-30% on data transfer

---

### 5. Lambda Optimization

- Right-size memory allocation
- Reduce cold starts
- Use Lambda Layers for shared code

**Estimated Savings**: 10-20% on Lambda costs

---

### 6. Database Optimization

- Use read replicas instead of Multi-AZ for dev/staging
- Implement connection pooling
- Use ElastiCache for frequent queries

**Estimated Savings**: $10-15/month in dev/staging

---

### 7. Development Environment Optimization

**Actions**:
- Shut down dev resources during non-business hours (nights/weekends)
- Use smaller instance sizes
- Share staging environment across multiple features

**Schedule**:
- Business hours: 9 AM - 6 PM (M-F) = 45 hours/week
- Off-hours saving: 123 hours/week (73%)

**Estimated Savings**: $30-40/month on dev environment

---

## Total Optimized Costs

### Production (10,000 users) - Optimized

| Original Cost | Optimized Cost | Savings |
|--------------|---------------|---------|
| $165.45/month | $125.00/month | $40.45/month (24%) |

### Annual Costs (Production, 10,000 users)

| Scenario | Annual Cost |
|----------|------------|
| Unoptimized | $1,985.40 |
| Optimized (with RIs) | $1,500.00 |
| **Total Savings** | **$485.40/year (24%)** |

---

## Cost Monitoring & Alerts

### Set Up Budget Alerts

```bash
# Create monthly budget
aws budgets create-budget \
    --account-id ACCOUNT_ID \
    --budget file://budget.json

# budget.json
{
    "BudgetName": "summoners-chronicle-monthly",
    "BudgetLimit": {
        "Amount": "200",
        "Unit": "USD"
    },
    "TimeUnit": "MONTHLY",
    "BudgetType": "COST"
}
```

### CloudWatch Cost Alarms

- Alert at 50% of budget
- Alert at 80% of budget
- Alert at 100% of budget
- Daily cost reports

---

## Resource Tagging Strategy

Tag all resources for cost allocation:

```json
{
    "Project": "SummonersChronicle",
    "Environment": "Production",
    "CostCenter": "Engineering",
    "Owner": "DevTeam",
    "Application": "Frontend"
}
```

---

## Additional Resources

- [AWS Pricing Calculator](https://calculator.aws/)
- [AWS Cost Explorer](https://aws.amazon.com/aws-cost-management/aws-cost-explorer/)
- [AWS Trusted Advisor](https://aws.amazon.com/premiumsupport/technology/trusted-advisor/)
- [AWS Cost Optimization Hub](https://aws.amazon.com/aws-cost-management/cost-optimization-hub/)

---

**Note**: All prices are estimates based on AWS pricing as of November 2025 and may vary based on actual usage patterns, region, and AWS pricing changes. Always verify current pricing at https://aws.amazon.com/pricing/
