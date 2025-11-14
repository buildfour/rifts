# CLAUDE.md - AI Assistant Guide for RiftSage

This document provides comprehensive guidance for AI assistants working on the RiftSage AI Agent codebase. Last updated: 2025-11-14

## Table of Contents
1. [Project Overview](#project-overview)
2. [Architecture & Technology Stack](#architecture--technology-stack)
3. [Directory Structure](#directory-structure)
4. [Development Workflows](#development-workflows)
5. [Code Conventions](#code-conventions)
6. [Key Components](#key-components)
7. [Configuration Management](#configuration-management)
8. [Testing & Debugging](#testing--debugging)
9. [Deployment Process](#deployment-process)
10. [Cost Considerations](#cost-considerations)
11. [Common Tasks](#common-tasks)
12. [Troubleshooting](#troubleshooting)

---

## Project Overview

**RiftSage** is a serverless AI agent that generates personalized end-of-year League of Legends performance reports. It combines:
- Riot Games API for match data
- AWS Lambda for serverless compute
- Amazon Bedrock (Claude 3 Sonnet) for AI-generated insights
- DynamoDB for data storage
- S3 for object storage

**Key Metrics:**
- Cost per report: ~$0.13
- Idle cost: ~$3/month
- Pipeline stages: 5 (DataCollection → FeatureEngineering → ModelInference → BedrockGeneration → ReportCompilation)
- Tracked metrics: 37+
- ML models: 4

**Important:** This is a production-ready system with real cost implications. Always consider cost optimization when making changes.

---

## Architecture & Technology Stack

### System Architecture

```
┌──────────────┐
│  Riot Games  │
│     API      │
└──────┬───────┘
       │
       ▼
┌─────────────────────────────────────────┐
│  DataCollection Lambda (512 MB, 5 min)  │
│  - Rate limiting (20/sec, 100/2min)     │
│  - Match caching in DynamoDB            │
│  - S3 storage (raw-matches/)            │
└──────────┬──────────────────────────────┘
           │
           ▼
┌─────────────────────────────────────────┐
│ FeatureEngineering Lambda (1024 MB)     │
│  - 37+ metrics calculation              │
│  - KDA, CS/min, Gold/min, Vision        │
│  - DynamoDB Metrics table               │
└──────────┬──────────────────────────────┘
           │
           ▼
┌─────────────────────────────────────────┐
│  ModelInference Lambda (2048 MB)        │
│  - 4 ML models                          │
│  - Performance patterns                 │
│  - Mental resilience scoring            │
└──────────┬──────────────────────────────┘
           │
           ▼
┌─────────────────────────────────────────┐
│ BedrockGeneration Lambda (1024 MB)      │
│  - Claude 3 Sonnet                      │
│  - 4 report sections                    │
│  - DynamoDB Insights table              │
└──────────┬──────────────────────────────┘
           │
           ▼
┌─────────────────────────────────────────┐
│  ReportCompilation Lambda (1024 MB)     │
│  - JSON/MD formats                      │
│  - S3 storage with presigned URLs       │
│  - 7-day URL validity                   │
└─────────────────────────────────────────┘
```

### Technology Stack

**Backend:**
- Python 3.11 (all Lambda functions)
- boto3 (AWS SDK)
- requests (HTTP client for Riot API)
- numpy, pandas (data processing)
- scikit-learn (ML models)

**AI/ML:**
- Amazon Bedrock (Claude 3 Sonnet: `anthropic.claude-3-sonnet-20240229-v1:0`)
- Custom ML models: Performance Pattern Analyzer, Mental Resilience Calculator, Growth Trajectory Analyzer, Playstyle Profiler

**AWS Services:**
- **Lambda:** 6 functions (Python 3.11 runtime)
- **DynamoDB:** 7 tables with PAY_PER_REQUEST billing
- **S3:** 3 buckets (data, reports, models)
- **Bedrock:** Claude 3 Sonnet for AI generation
- **Cognito:** User authentication
- **API Gateway:** HTTP API for REST endpoints
- **CloudFormation:** Infrastructure as Code
- **Secrets Manager:** Riot API key storage
- **EventBridge:** Scheduled triggers
- **KMS:** Encryption keys

**Frontend (Web App):**
- Vanilla HTML/CSS/JavaScript
- Font Awesome icons
- Responsive design (mobile-first)
- Magazine-style UI aesthetic

**DevOps:**
- CloudFormation (IaC)
- Bash deployment scripts
- AWS CLI
- Git version control

---

## Directory Structure

```
/home/user/rifts/
├── lambda_functions/              # Lambda function source code
│   ├── data_collection.py              # Riot API integration & caching
│   ├── feature_engineering.py          # Metrics calculation (37+ metrics)
│   ├── model_inference.py              # ML model application (4 models)
│   ├── bedrock_generation.py           # AI insight generation (Claude)
│   ├── report_compilation.py           # Report assembly (JSON/MD)
│   └── resource_manager.py             # Cost optimization & monitoring
│
├── config/                        # Configuration
│   └── config.yaml                     # Project settings (environments, API limits, ML config)
│
├── deployment/                    # Deployment automation
│   ├── deploy.sh                       # Main deployment script (bash)
│   └── requirements.txt                # Python dependencies
│
├── database_seeds/                # Database initialization
│   └── seed_champions.py               # Champion data seeder
│
├── prompt_templates/              # AI prompt templates
│   └── role_performance_v1.txt         # Template for AI generation
│
├── web_app/                       # Frontend application
│   ├── index.html                      # Landing page
│   ├── pages/                          # Auth and dashboard
│   │   ├── auth.html
│   │   └── dashboard.html
│   ├── assets/                         # CSS, JS, images
│   │   ├── css/
│   │   ├── js/
│   │   └── images/
│   ├── config/
│   │   └── aws-config.js               # AWS SDK configuration
│   ├── deploy.sh                       # Web app deployment script
│   ├── cloudformation-template.yaml    # Web infrastructure
│   └── DEPLOYMENT.md                   # Web deployment guide
│
├── docs/                          # Documentation
│   ├── README.md                       # Project overview & quick start
│   └── AWS_STACK.md                    # Complete AWS resource list & costs
│
├── details doc/                   # Design documents
│   ├── summoners_chronicle_app.md      # Web app specification
│   └── background.png                  # Design assets
│
├── infrastructure.yaml            # Main CloudFormation template
├── QUICKSTART.md                 # 5-minute setup guide
└── CLAUDE.md                     # This file (AI assistant guide)
```

### Key Files by Purpose

**Infrastructure:**
- `/home/user/rifts/infrastructure.yaml` - Complete AWS stack definition (KMS, S3, Lambda, DynamoDB, Cognito, API Gateway)
- `/home/user/rifts/config/config.yaml` - Runtime configuration

**Deployment:**
- `/home/user/rifts/deployment/deploy.sh` - Automated deployment (packaging, uploading, CloudFormation)
- `/home/user/rifts/web_app/deploy.sh` - Frontend deployment

**Core Logic:**
- `/home/user/rifts/lambda_functions/*.py` - All business logic

**Documentation:**
- `/home/user/rifts/QUICKSTART.md` - User onboarding
- `/home/user/rifts/docs/AWS_STACK.md` - Resource costs & details
- `/home/user/rifts/docs/README.md` - Architecture overview

---

## Development Workflows

### Initial Setup

1. **Prerequisites:**
   - AWS Account with permissions (CloudFormation, Lambda, S3, DynamoDB, Bedrock, Cognito, API Gateway, KMS, Secrets Manager)
   - Riot Games Developer API Key ([Get here](https://developer.riotgames.com/))
   - AWS CLI installed and configured
   - Python 3.11+

2. **Environment Variables:**
   ```bash
   export RIOT_API_KEY='RGAPI-your-key-here'
   export AWS_REGION='us-east-1'
   export ENVIRONMENT='production'  # or 'development', 'staging'
   ```

3. **Deploy Infrastructure:**
   ```bash
   cd /home/user/rifts
   chmod +x deployment/deploy.sh
   ./deployment/deploy.sh
   ```

### Making Code Changes

**For Lambda Functions:**

1. **Edit function code:** `/home/user/rifts/lambda_functions/{function_name}.py`

2. **Test locally (if possible):**
   ```python
   # Add to function for local testing
   if __name__ == '__main__':
       event = {'player_puuid': 'test', 'region': 'na1', 'year': 2025}
       context = None
       result = lambda_handler(event, context)
       print(result)
   ```

3. **Deploy updated function:**
   ```bash
   # Redeploy entire stack (recommended)
   ./deployment/deploy.sh

   # OR update single function
   cd lambda_functions
   zip -r data_collection.zip data_collection.py
   aws lambda update-function-code \
     --function-name riftsage-DataCollection-production \
     --zip-file fileb://data_collection.zip
   ```

4. **Test in AWS:**
   ```bash
   aws lambda invoke \
     --function-name riftsage-DataCollection-production \
     --payload '{"player_puuid":"xxx","region":"na1","year":2025}' \
     response.json

   cat response.json
   ```

5. **Check logs:**
   ```bash
   aws logs tail /aws/lambda/riftsage-DataCollection-production --follow
   ```

**For Infrastructure Changes:**

1. **Edit:** `/home/user/rifts/infrastructure.yaml`

2. **Validate:**
   ```bash
   aws cloudformation validate-template \
     --template-body file://infrastructure.yaml
   ```

3. **Deploy:**
   ```bash
   ./deployment/deploy.sh
   ```

4. **Monitor stack:**
   ```bash
   aws cloudformation describe-stack-events \
     --stack-name riftsage-production \
     --max-items 20
   ```

**For Web App Changes:**

1. **Edit files:** `/home/user/rifts/web_app/*`

2. **Deploy:**
   ```bash
   cd web_app
   chmod +x deploy.sh
   ./deploy.sh
   ```

### Git Workflow

**Branch Naming:**
- Feature: `feature/description`
- Bug fix: `fix/description`
- Documentation: `docs/description`

**Commit Messages:**
```bash
# Good examples
git commit -m "Add retry logic to Riot API client in data_collection.py"
git commit -m "Optimize DynamoDB query in feature_engineering.py"
git commit -m "Update Bedrock model to Claude 3.5 Sonnet"

# Bad examples (too vague)
git commit -m "Fix bug"
git commit -m "Update code"
```

**Current Branch:**
- Working on: `claude/claude-md-mhyr4azwzynxl6vd-01EaLzivts1ef9xebgWzQCTx`

---

## Code Conventions

### Python Style

**File Structure:**
```python
"""
RiftSage AI Agent - [Function Name] Lambda Function
Brief description of what this function does
"""

import json
import os
import boto3
from typing import Dict, List, Any
import logging

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Initialize AWS clients
s3_client = boto3.client('s3')
dynamodb = boto3.resource('dynamodb')

# Environment variables
ENVIRONMENT = os.environ.get('ENVIRONMENT', 'development')
TABLE_NAME = os.environ.get('TABLE_NAME')

# Constants
RATE_LIMITS = {
    'requests_per_second': 20
}


class SomeClass:
    """Class docstring"""

    def __init__(self):
        pass


def lambda_handler(event: Dict[str, Any], context) -> Dict[str, Any]:
    """
    Main Lambda handler function

    Args:
        event: Lambda event payload
        context: Lambda context object

    Returns:
        Dict with statusCode and body
    """
    try:
        # Implementation

        return {
            'statusCode': 200,
            'body': json.dumps({'message': 'Success'})
        }

    except Exception as e:
        logger.error(f"Error: {str(e)}", exc_info=True)
        return {
            'statusCode': 500,
            'body': json.dumps({'error': str(e)})
        }
```

**Naming Conventions:**

- **Variables:** `snake_case`
  ```python
  player_puuid = event.get('player_puuid')
  match_history = []
  total_games_count = 0
  ```

- **Functions:** `snake_case`
  ```python
  def calculate_kda(kills, deaths, assists):
      pass

  def get_match_data(match_id):
      pass
  ```

- **Classes:** `PascalCase`
  ```python
  class RiotAPIClient:
      pass

  class FeatureEngineer:
      pass
  ```

- **Constants:** `UPPER_SNAKE_CASE`
  ```python
  RATE_LIMITS = {'requests_per_second': 20}
  MAX_RETRIES = 3
  BEDROCK_MODEL_ID = 'anthropic.claude-3-sonnet-20240229-v1:0'
  ```

### AWS Resource Naming

**Pattern:** `{project}-{resource}-{environment}`

**Examples:**
```yaml
Lambda Functions:
  - riftsage-DataCollection-production
  - riftsage-FeatureEngineering-development

DynamoDB Tables:
  - riftsage-Players-production
  - riftsage-Metrics-staging

S3 Buckets:
  - riftsage-data-production-{AccountId}
  - riftsage-reports-development-{AccountId}

Secrets:
  - /riftsage/production/riot-api-key
  - /riftsage/development/riot-api-key
```

### S3 Key Naming

**Pattern:**
```
raw-matches/{puuid}/{year}/{match_id}.json
reports/{puuid}/{year}/report.{format}
models/{model_name}.pkl
```

**Examples:**
```
s3://riftsage-data-production-123456789012/raw-matches/abc123/2025/NA1_4567890123.json
s3://riftsage-reports-production-123456789012/reports/abc123/2025/report.json
s3://riftsage-models-production-123456789012/models/performance_pattern_analyzer.pkl
```

### DynamoDB Key Naming

**Use snake_case:**
```python
# Good
{
    'player_puuid': 'abc123',
    'match_id': 'NA1_4567890123',
    'section_id': 'role_performance',
    'created_at': '2025-01-01T00:00:00Z'
}

# Bad
{
    'playerPuuid': 'abc123',  # camelCase
    'MatchID': 'NA1_4567890123',  # PascalCase
}
```

### Error Handling

**Always use try-except in Lambda handlers:**
```python
def lambda_handler(event, context):
    try:
        # Main logic
        result = process_data(event)

        return {
            'statusCode': 200,
            'body': json.dumps(result)
        }

    except KeyError as e:
        logger.error(f"Missing required parameter: {str(e)}")
        return {
            'statusCode': 400,
            'body': json.dumps({'error': f'Missing parameter: {str(e)}'})
        }

    except boto3.exceptions.Boto3Error as e:
        logger.error(f"AWS error: {str(e)}", exc_info=True)
        return {
            'statusCode': 500,
            'body': json.dumps({'error': 'AWS service error'})
        }

    except Exception as e:
        logger.error(f"Unexpected error: {str(e)}", exc_info=True)
        return {
            'statusCode': 500,
            'body': json.dumps({'error': 'Internal server error'})
        }
```

### Logging Best Practices

**Use structured logging:**
```python
# Good
logger.info(f"Processing player {player_puuid} for year {year}")
logger.info(f"Fetched {len(matches)} matches for player {player_puuid}")
logger.error(f"Failed to fetch match {match_id}: {str(e)}", exc_info=True)

# Bad (too vague)
logger.info("Processing")
logger.error("Error occurred")
```

**Log Levels:**
- `DEBUG`: Detailed diagnostic information (development only)
- `INFO`: General informational messages (function entry/exit, progress)
- `WARNING`: Something unexpected but recoverable
- `ERROR`: Serious issue that prevented operation completion

---

## Key Components

### Lambda Functions

#### 1. data_collection.py
**Location:** `/home/user/rifts/lambda_functions/data_collection.py`

**Purpose:** Fetches match history from Riot Games API

**Key Features:**
- Rate limiting (20 req/sec, 100 req/2min)
- Match caching in DynamoDB (24-hour TTL)
- Regional routing (NA, EU, KR, etc.)
- S3 storage of raw match data

**Environment Variables:**
```python
ENVIRONMENT = os.environ.get('ENVIRONMENT')
DATA_BUCKET = os.environ.get('DATA_BUCKET')
PLAYERS_TABLE = os.environ.get('PLAYERS_TABLE')
CACHE_TABLE = os.environ.get('CACHE_TABLE')
RIOT_API_SECRET = os.environ.get('RIOT_API_SECRET')
```

**Input Event:**
```json
{
  "player_puuid": "abc123...",
  "region": "na1",
  "year": 2025
}
```

**Output:**
```json
{
  "statusCode": 200,
  "body": {
    "matches_fetched": 150,
    "cached_matches": 23,
    "s3_prefix": "raw-matches/abc123/2025/"
  }
}
```

**Important Considerations:**
- Always respect Riot API rate limits (20/sec, 100/2min)
- Cache matches to reduce API calls and costs
- Handle 429 (Rate Limit) and 503 (Service Unavailable) responses
- Use exponential backoff for retries

#### 2. feature_engineering.py
**Location:** `/home/user/rifts/lambda_functions/feature_engineering.py`

**Purpose:** Transforms raw match data into 37+ ML features

**Calculated Metrics:**
- **Core:** KDA, CS/min, Gold/min, Vision score/min
- **Efficiency:** Damage/gold, Gold share, Damage share
- **Positioning:** Deaths/game, Solo deaths, Team fight participation
- **Objectives:** Turret plates, Dragons, Barons, Rift Heralds
- **Mentality:** Comeback wins, Early game performance, Late game performance

**Input Event:**
```json
{
  "player_puuid": "abc123...",
  "year": 2025
}
```

**Output:** Writes to DynamoDB `Metrics` table

**Important Considerations:**
- Requires minimum 50 games for statistical significance
- Aggregates data across all ranked solo/duo games
- Calculate percentile benchmarks (25th, 50th, 75th, 90th, 95th)

#### 3. model_inference.py
**Location:** `/home/user/rifts/lambda_functions/model_inference.py`

**Purpose:** Applies 4 ML models for player classification

**Models:**
1. **Performance Pattern Analyzer** (K-Means, 3 clusters)
   - Classifies: Carry, Enabler, Specialist

2. **Mental Resilience Calculator** (Random Forest, 100 estimators)
   - Scores: 0-100 tilt resistance

3. **Growth Trajectory Analyzer** (LSTM, sequence_length=30)
   - Classifies: Improving, Plateau, Declining

4. **Playstyle Profiler** (PCA + K-Means, 4 components)
   - Identifies playstyle archetype

**Important Considerations:**
- Models stored in S3 (`models/` prefix)
- Requires feature_engineering.py output
- Memory: 2048 MB (largest function)

#### 4. bedrock_generation.py
**Location:** `/home/user/rifts/lambda_functions/bedrock_generation.py`

**Purpose:** Generates AI insights using Amazon Bedrock (Claude 3 Sonnet)

**Sections Generated:**
1. Role Performance Snapshot
2. Improvement Blueprint
3. Mental Resilience & Consistency
4. Champion Mastery Analysis

**Bedrock Configuration:**
```python
model_id = 'anthropic.claude-3-sonnet-20240229-v1:0'
max_tokens = 4000
temperature = 0.3
```

**Input Event:**
```json
{
  "player_puuid": "abc123...",
  "year": 2025,
  "generate_all": true
}
```

**Output:** Writes to DynamoDB `Insights` table

**Important Considerations:**
- **COST CRITICAL:** This is the most expensive operation (~$0.10 per report)
- Use Claude 3 Sonnet for quality, consider Haiku for cost savings
- Timeout: 15 minutes (longest of all functions)
- Validate AI output before storing
- Use prompt templates from `/home/user/rifts/prompt_templates/`

#### 5. report_compilation.py
**Location:** `/home/user/rifts/lambda_functions/report_compilation.py`

**Purpose:** Assembles sections into complete reports

**Output Formats:**
- JSON (machine-readable)
- Markdown (human-readable)

**Input Event:**
```json
{
  "player_puuid": "abc123...",
  "year": 2025
}
```

**Output:**
```json
{
  "statusCode": 200,
  "body": {
    "s3_results": {
      "urls": {
        "json": "https://s3.amazonaws.com/...",
        "markdown": "https://s3.amazonaws.com/..."
      },
      "expiry": "2025-01-08T00:00:00Z"
    }
  }
}
```

**Important Considerations:**
- Presigned URLs valid for 7 days
- Assembles sections in order: Role Performance → Improvement Blueprint → Mental Resilience → Champion Mastery

#### 6. resource_manager.py
**Location:** `/home/user/rifts/lambda_functions/resource_manager.py`

**Purpose:** Monitors system activity and optimizes costs

**Features:**
- Activity tracking (15-minute intervals via EventBridge)
- Idle detection
- Cost estimation
- State management

**Actions:**
```python
# Get system status
{'action': 'get_status'}

# Get cost estimates
{'action': 'get_costs'}
```

**Important Considerations:**
- Runs continuously (every 15 minutes)
- Low cost (~$0.10/month)
- Tracks activity in DynamoDB `ResourceState` table

### DynamoDB Tables

#### Players Table
**Table Name:** `riftsage-Players-{environment}`

**Schema:**
```python
{
  'player_puuid': 'abc123...',  # Partition Key
  'summoner_name': 'PlayerName',
  'region': 'na1',
  'email': 'player@example.com',
  'created_at': '2025-01-01T00:00:00Z',
  'updated_at': '2025-01-01T00:00:00Z'
}
```

**GSI:** EmailIndex (on `email` field)

**Use Cases:**
- Player account lookup
- Email-based authentication

#### Metrics Table
**Table Name:** `riftsage-Metrics-{environment}`

**Schema:**
```python
{
  'player_puuid': 'abc123...',  # Partition Key
  'year': 2025,                # Sort Key
  'total_games': 150,
  'kda': 3.2,
  'cs_per_min': 6.8,
  'gold_per_min': 410,
  'vision_score_per_min': 1.2,
  # ... 30+ more metrics
  'percentile_rankings': {
    'kda': 75,
    'cs_per_min': 60,
    # ...
  }
}
```

**Use Cases:**
- ML model input
- Percentile calculations
- Historical comparisons

#### Insights Table
**Table Name:** `riftsage-Insights-{environment}`

**Schema:**
```python
{
  'player_puuid': 'abc123...',        # Partition Key
  'section_id': 'role_performance',   # Sort Key
  'content': 'AI-generated text...',
  'metadata': {
    'model_id': 'claude-3-sonnet-20240229-v1:0',
    'tokens_used': 2500,
    'generation_time': 4.2
  },
  'created_at': '2025-01-01T00:00:00Z'
}
```

**Section IDs:**
- `role_performance`
- `improvement_blueprint`
- `mental_resilience`
- `champion_mastery`

**Use Cases:**
- Report compilation
- Section versioning

#### MatchCache Table
**Table Name:** `riftsage-MatchCache-{environment}`

**Schema:**
```python
{
  'match_id': 'NA1_4567890123',  # Partition Key
  'match_data': {...},           # Full match JSON
  'cached_at': '2025-01-01T00:00:00Z',
  'ttl': 1704153600             # Unix timestamp (24 hours)
}
```

**TTL:** 24 hours (automatic deletion)

**Use Cases:**
- Reduce Riot API calls
- Faster data retrieval

#### ChampionRecs Table
**Table Name:** `riftsage-ChampionRecs-{environment}`

**Schema:**
```python
{
  'champion_name': 'Ahri',       # Partition Key
  'role': 'mid',
  'difficulty': 'moderate',
  'playstyle': 'burst_mage',
  'similar_champions': ['LeBlanc', 'Zoe', 'Syndra']
}
```

**GSI:** RoleIndex (on `role` field)

**Use Cases:**
- Champion recommendations
- Similarity matching

#### RateLimit Table
**Table Name:** `riftsage-RateLimit-{environment}`

**Schema:**
```python
{
  'user_action': 'riot_api_request',  # Partition Key
  'request_timestamps': [1704067200, 1704067201, ...],
  'ttl': 1704067320  # 2 minutes
}
```

**TTL:** 2 minutes

**Use Cases:**
- Riot API rate limiting
- Prevent 429 errors

#### ResourceState Table
**Table Name:** `riftsage-ResourceState-{environment}`

**Schema:**
```python
{
  'resource_id': 'system',           # Partition Key
  'last_activity': '2025-01-01T00:00:00Z',
  'state': 'active',  # or 'idle'
  'activity_count': 150,
  'estimated_cost_today': 12.50
}
```

**Use Cases:**
- Auto-shutdown logic
- Cost tracking

---

## Configuration Management

### config.yaml Structure

**Location:** `/home/user/rifts/config/config.yaml`

**Sections:**

#### Project Settings
```yaml
project:
  name: riftsage
  version: 1.0.0
  description: AI-powered League of Legends performance analytics
```

#### Environments
```yaml
environments:
  production:
    aws_region: us-east-1
    log_level: INFO
    auto_shutdown_enabled: true
    idle_threshold_minutes: 60
```

**Important:** Use `INFO` for production, `DEBUG` only for development

#### Riot API
```yaml
riot_api:
  rate_limits:
    requests_per_second: 20
    requests_per_two_minutes: 100
  supported_regions:
    - na1
    - euw1
    - kr
  queue_types:
    ranked_solo: 420
```

**Note:** Never exceed rate limits (20/sec, 100/2min)

#### Bedrock
```yaml
bedrock:
  model_id: anthropic.claude-3-sonnet-20240229-v1:0
  max_tokens: 4000
  temperature: 0.3
  fallback_model: anthropic.claude-3-haiku-20240307-v1:0
```

**Important:** Changing model affects cost and quality

#### ML Models
```yaml
ml_models:
  performance_pattern_analyzer:
    algorithm: kmeans
    n_clusters: 3
```

#### Metrics
```yaml
metrics:
  minimum_games_required: 50
  benchmark_percentiles: [25, 50, 75, 90, 95]
```

#### Cost Management
```yaml
cost_management:
  target_cost_per_report: 0.13
  bedrock_token_limit: 10000
  lambda_memory_optimization: true
```

### Environment Variables

**Set before deployment:**
```bash
export RIOT_API_KEY='RGAPI-...'
export AWS_REGION='us-east-1'
export ENVIRONMENT='production'
```

**Lambda functions automatically receive:**
```python
ENVIRONMENT = os.environ.get('ENVIRONMENT')
DATA_BUCKET = os.environ.get('DATA_BUCKET')
PLAYERS_TABLE = os.environ.get('PLAYERS_TABLE')
# ... etc (defined in infrastructure.yaml)
```

---

## Testing & Debugging

### Local Testing

**Test Lambda function locally:**
```python
# Add to bottom of Lambda function
if __name__ == '__main__':
    test_event = {
        'player_puuid': 'test123',
        'region': 'na1',
        'year': 2025
    }
    result = lambda_handler(test_event, None)
    print(json.dumps(result, indent=2))
```

**Run:**
```bash
cd /home/user/rifts/lambda_functions
python data_collection.py
```

### AWS Testing

**Invoke Lambda function:**
```bash
aws lambda invoke \
  --function-name riftsage-DataCollection-production \
  --payload '{"player_puuid":"xxx","region":"na1","year":2025}' \
  response.json

cat response.json | jq .
```

**Test full pipeline:**
```bash
# Run all 5 functions sequentially
PLAYER_PUUID="your-puuid-here"
REGION="na1"
YEAR=2025

for func in DataCollection FeatureEngineering ModelInference BedrockGeneration ReportCompilation; do
  echo "Running riftsage-${func}-production..."
  aws lambda invoke \
    --function-name "riftsage-${func}-production" \
    --payload "{\"player_puuid\":\"$PLAYER_PUUID\",\"region\":\"$REGION\",\"year\":$YEAR,\"generate_all\":true}" \
    "response_${func}.json"

  cat "response_${func}.json" | jq .
  echo ""
done
```

### Viewing Logs

**Tail logs in real-time:**
```bash
aws logs tail /aws/lambda/riftsage-DataCollection-production --follow
```

**Filter logs:**
```bash
aws logs tail /aws/lambda/riftsage-DataCollection-production \
  --filter-pattern "ERROR" \
  --since 1h
```

**Get specific log stream:**
```bash
aws logs get-log-events \
  --log-group-name /aws/lambda/riftsage-DataCollection-production \
  --log-stream-name '2025/01/01/[$LATEST]abc123'
```

### Debugging Common Issues

**Issue: "Riot API rate limit exceeded"**
```bash
# Check RateLimit table
aws dynamodb get-item \
  --table-name riftsage-RateLimit-production \
  --key '{"user_action":{"S":"riot_api_request"}}'
```

**Issue: "DynamoDB item not found"**
```bash
# Check if item exists
aws dynamodb get-item \
  --table-name riftsage-Players-production \
  --key '{"player_puuid":{"S":"abc123"}}'
```

**Issue: "S3 object not found"**
```bash
# List S3 objects
aws s3 ls s3://riftsage-data-production-123456789012/raw-matches/abc123/2025/
```

**Issue: "Lambda timeout"**
```bash
# Increase timeout in infrastructure.yaml
Timeout: 600  # 10 minutes (was 300)

# Redeploy
./deployment/deploy.sh
```

### CloudWatch Metrics

**View Lambda metrics:**
```bash
aws cloudwatch get-metric-statistics \
  --namespace AWS/Lambda \
  --metric-name Duration \
  --dimensions Name=FunctionName,Value=riftsage-DataCollection-production \
  --start-time 2025-01-01T00:00:00Z \
  --end-time 2025-01-01T23:59:59Z \
  --period 3600 \
  --statistics Average,Maximum
```

---

## Deployment Process

### Full Deployment

**Steps:**

1. **Set environment variables:**
   ```bash
   export RIOT_API_KEY='RGAPI-...'
   export AWS_REGION='us-east-1'
   export ENVIRONMENT='production'
   ```

2. **Run deployment script:**
   ```bash
   cd /home/user/rifts
   chmod +x deployment/deploy.sh
   ./deployment/deploy.sh
   ```

3. **Script actions:**
   - Creates S3 bucket for Lambda code
   - Packages each Lambda function as ZIP
   - Uploads ZIPs to S3
   - Deploys/updates CloudFormation stack
   - Seeds champion database
   - Outputs API endpoint

4. **Verify deployment:**
   ```bash
   aws cloudformation describe-stacks \
     --stack-name riftsage-production \
     --query 'Stacks[0].StackStatus'
   ```

**Expected output:** `CREATE_COMPLETE` or `UPDATE_COMPLETE`

### Single Function Update

**Faster deployment for code-only changes:**

```bash
cd /home/user/rifts/lambda_functions

# Package function
zip -r data_collection.zip data_collection.py

# Upload to Lambda
aws lambda update-function-code \
  --function-name riftsage-DataCollection-production \
  --zip-file fileb://data_collection.zip

# Verify
aws lambda get-function \
  --function-name riftsage-DataCollection-production \
  --query 'Configuration.LastModified'
```

### Infrastructure Changes

**For changes to infrastructure.yaml:**

1. **Validate template:**
   ```bash
   aws cloudformation validate-template \
     --template-body file://infrastructure.yaml
   ```

2. **Create change set (preview changes):**
   ```bash
   aws cloudformation create-change-set \
     --stack-name riftsage-production \
     --change-set-name update-$(date +%s) \
     --template-body file://infrastructure.yaml \
     --parameters file://parameters.json \
     --capabilities CAPABILITY_IAM
   ```

3. **Review changes:**
   ```bash
   aws cloudformation describe-change-set \
     --stack-name riftsage-production \
     --change-set-name update-1704067200
   ```

4. **Execute change set:**
   ```bash
   aws cloudformation execute-change-set \
     --stack-name riftsage-production \
     --change-set-name update-1704067200
   ```

### Web App Deployment

**Deploy frontend:**

```bash
cd /home/user/rifts/web_app
chmod +x deploy.sh
./deploy.sh
```

**Script actions:**
- Creates/updates Cognito User Pool
- Creates S3 bucket for website hosting
- Enables static website hosting
- Uploads HTML/CSS/JS files
- Sets bucket policy for public read
- Outputs website URL

### Rollback

**Rollback CloudFormation stack:**

```bash
# Cancel in-progress update
aws cloudformation cancel-update-stack --stack-name riftsage-production

# Or rollback to previous version
aws cloudformation execute-change-set \
  --stack-name riftsage-production \
  --change-set-name previous-version
```

**Rollback single Lambda function:**

```bash
# List versions
aws lambda list-versions-by-function \
  --function-name riftsage-DataCollection-production

# Update alias to previous version
aws lambda update-alias \
  --function-name riftsage-DataCollection-production \
  --name production \
  --function-version 2  # Previous version
```

---

## Cost Considerations

### Cost Breakdown

**Idle State (No Reports):**
- S3 Storage: $1.20/month
- CloudWatch Logs: $1.00/month
- KMS: $1.00/month
- Secrets Manager: $0.40/month
- Resource Manager Lambda: $0.10/month
- **Total: ~$3.70/month**

**Active State (1,000 reports/month):**
- Lambda Compute: $8.00
- Bedrock (Claude): $99.00 (67% of total!)
- DynamoDB: $26.00
- S3 Storage/Transfer: $5.00
- API Gateway: $3.50
- CloudWatch: $5.00
- Other: $1.90
- **Total: ~$148/month ($0.15 per report)**

### Cost Optimization Tips

**1. Bedrock Optimization (Highest Impact):**
```yaml
# Use Haiku instead of Sonnet (60% cost reduction)
bedrock:
  model_id: anthropic.claude-3-haiku-20240307-v1:0  # Instead of Sonnet
  max_tokens: 3000  # Reduce from 4000
```

**2. Lambda Optimization:**
```yaml
# Reduce memory (affects cost)
MemorySize: 512  # Instead of 1024 (if performance allows)

# Set reserved concurrency to prevent runaway costs
ReservedConcurrentExecutions: 10
```

**3. DynamoDB Optimization:**
- Already using PAY_PER_REQUEST (best for variable traffic)
- Enable TTL on cache tables (already enabled)
- Use batch operations where possible

**4. S3 Optimization:**
- Already using Intelligent Tiering
- Already using lifecycle policies (90 days → Glacier)
- Consider shorter retention for raw match data

**5. Caching Strategy:**
- Cache champion data aggressively (rarely changes)
- Cache match data for 24 hours (already enabled)
- Cache benchmark percentiles

**6. Batch Processing:**
```python
# Process multiple reports together
event = {
  'player_puuids': ['abc123', 'def456', 'ghi789'],
  'year': 2025
}
```

### Monitoring Costs

**Set up billing alerts:**

```bash
# Create SNS topic
aws sns create-topic --name riftsage-billing-alerts

# Subscribe to topic
aws sns subscribe \
  --topic-arn arn:aws:sns:us-east-1:123456789012:riftsage-billing-alerts \
  --protocol email \
  --notification-endpoint your-email@example.com

# Create budget
aws budgets create-budget \
  --account-id 123456789012 \
  --budget file://budget.json
```

**budget.json:**
```json
{
  "BudgetName": "riftsage-monthly-budget",
  "BudgetLimit": {
    "Amount": "200",
    "Unit": "USD"
  },
  "TimeUnit": "MONTHLY",
  "BudgetType": "COST"
}
```

**Check current costs:**
```bash
aws lambda invoke \
  --function-name riftsage-ResourceManager-production \
  --payload '{"action":"get_costs"}' \
  costs.json

cat costs.json | jq .
```

---

## Common Tasks

### Adding a New Lambda Function

1. **Create function file:**
   ```bash
   cd /home/user/rifts/lambda_functions
   touch new_function.py
   ```

2. **Implement function:**
   ```python
   """
   RiftSage AI Agent - New Function Lambda
   Description of what this does
   """

   import json
   import logging

   logger = logging.getLogger()
   logger.setLevel(logging.INFO)

   def lambda_handler(event, context):
       try:
           # Implementation
           return {
               'statusCode': 200,
               'body': json.dumps({'message': 'Success'})
           }
       except Exception as e:
           logger.error(f"Error: {str(e)}", exc_info=True)
           return {
               'statusCode': 500,
               'body': json.dumps({'error': str(e)})
           }
   ```

3. **Add to infrastructure.yaml:**
   ```yaml
   NewFunction:
     Type: AWS::Lambda::Function
     Properties:
       FunctionName: !Sub '${ProjectName}-NewFunction-${Environment}'
       Runtime: python3.11
       Handler: index.lambda_handler
       MemorySize: 1024
       Timeout: 300
       Role: !GetAtt LambdaExecutionRole.Arn
       Code:
         S3Bucket: !Ref LambdaCodeBucket
         S3Key: functions/new_function.zip
       Environment:
         Variables:
           ENVIRONMENT: !Ref Environment
           # Add other env vars
   ```

4. **Update deployment script:**
   ```bash
   # Edit deployment/deploy.sh
   # Add 'new_function' to the list of functions
   for func in data_collection feature_engineering model_inference bedrock_generation report_compilation resource_manager new_function; do
   ```

5. **Deploy:**
   ```bash
   ./deployment/deploy.sh
   ```

### Adding a New DynamoDB Table

1. **Add to infrastructure.yaml:**
   ```yaml
   NewTable:
     Type: AWS::DynamoDB::Table
     Properties:
       TableName: !Sub '${ProjectName}-NewTable-${Environment}'
       BillingMode: PAY_PER_REQUEST
       AttributeDefinitions:
         - AttributeName: partition_key
           AttributeType: S
         - AttributeName: sort_key
           AttributeType: S
       KeySchema:
         - AttributeName: partition_key
           KeyType: HASH
         - AttributeName: sort_key
           KeyType: RANGE
       PointInTimeRecoverySpecification:
         PointInTimeRecoveryEnabled: true
       SSESpecification:
         SSEEnabled: true
       Tags:
         - Key: Project
           Value: !Ref ProjectName
         - Key: Environment
           Value: !Ref Environment
   ```

2. **Grant Lambda access:**
   ```yaml
   # Add to LambdaExecutionRole policies
   - PolicyName: DynamoDBNewTableAccess
     PolicyDocument:
       Statement:
         - Effect: Allow
           Action:
             - dynamodb:GetItem
             - dynamodb:PutItem
             - dynamodb:UpdateItem
             - dynamodb:Query
           Resource: !GetAtt NewTable.Arn
   ```

3. **Pass table name to Lambda:**
   ```yaml
   # In Lambda function Environment Variables
   NEW_TABLE: !Ref NewTable
   ```

4. **Deploy:**
   ```bash
   ./deployment/deploy.sh
   ```

### Updating Bedrock Model

1. **Edit config.yaml:**
   ```yaml
   bedrock:
     model_id: anthropic.claude-3-5-sonnet-20240620-v1:0  # New model
     max_tokens: 4000
     temperature: 0.3
   ```

2. **Update bedrock_generation.py:**
   ```python
   # Update model ID constant
   BEDROCK_MODEL_ID = 'anthropic.claude-3-5-sonnet-20240620-v1:0'
   ```

3. **Test with single report:**
   ```bash
   aws lambda invoke \
     --function-name riftsage-BedrockGeneration-production \
     --payload '{"player_puuid":"test","year":2025,"section":"role_performance"}' \
     response.json
   ```

4. **Monitor costs:**
   ```bash
   # Check if cost per report changed
   aws lambda invoke \
     --function-name riftsage-ResourceManager-production \
     --payload '{"action":"get_costs"}' \
     costs.json
   ```

### Adding a New Report Section

1. **Create prompt template:**
   ```bash
   cd /home/user/rifts/prompt_templates
   touch new_section_v1.txt
   ```

2. **Write prompt:**
   ```
   You are analyzing a League of Legends player's performance.

   Player Stats:
   {stats_json}

   Generate a section about [new topic]:
   - Point 1
   - Point 2
   - Point 3

   Use a friendly, encouraging tone. Be specific with numbers.
   ```

3. **Update bedrock_generation.py:**
   ```python
   SECTION_PROMPTS = {
       'role_performance': 'role_performance_v1.txt',
       'improvement_blueprint': 'improvement_blueprint_v1.txt',
       'mental_resilience': 'mental_resilience_v1.txt',
       'champion_mastery': 'champion_mastery_v1.txt',
       'new_section': 'new_section_v1.txt'  # Add here
   }
   ```

4. **Update report_compilation.py:**
   ```python
   SECTION_ORDER = [
       'role_performance',
       'improvement_blueprint',
       'mental_resilience',
       'champion_mastery',
       'new_section'  # Add here
   ]
   ```

5. **Deploy and test:**
   ```bash
   ./deployment/deploy.sh
   ```

### Seeding Champion Database

1. **Edit database_seeds/seed_champions.py:**
   ```python
   champions = [
       {
           'champion_name': 'Ahri',
           'role': 'mid',
           'difficulty': 'moderate',
           'playstyle': 'burst_mage',
           'similar_champions': ['LeBlanc', 'Zoe', 'Syndra']
       },
       # Add more champions
   ]
   ```

2. **Run seeder:**
   ```bash
   cd /home/user/rifts/database_seeds

   # Set environment
   export AWS_REGION='us-east-1'
   export ENVIRONMENT='production'

   # Run
   python seed_champions.py
   ```

3. **Verify:**
   ```bash
   aws dynamodb scan \
     --table-name riftsage-ChampionRecs-production \
     --limit 10
   ```

---

## Troubleshooting

### Common Errors

#### 1. "RIOT_API_KEY not set"

**Error:**
```
KeyError: 'RIOT_API_KEY'
```

**Solution:**
```bash
export RIOT_API_KEY='RGAPI-your-key-here'
./deployment/deploy.sh
```

#### 2. "Rate limit exceeded" (HTTP 429)

**Error:**
```
RateLimitError: 429 - Rate limit exceeded
```

**Solution:**
- Check rate limiting implementation in `data_collection.py`
- Ensure `RateLimit` DynamoDB table is working
- Add exponential backoff:
  ```python
  import time

  for attempt in range(3):
      try:
          response = requests.get(url)
          response.raise_for_status()
          break
      except requests.exceptions.HTTPError as e:
          if e.response.status_code == 429:
              wait_time = 2 ** attempt  # 1s, 2s, 4s
              logger.warning(f"Rate limit hit, waiting {wait_time}s")
              time.sleep(wait_time)
          else:
              raise
  ```

#### 3. "DynamoDB item not found"

**Error:**
```
ClientError: An error occurred (ResourceNotFoundException)
```

**Solution:**
- Check table name:
  ```bash
  aws dynamodb list-tables | grep riftsage
  ```
- Verify item exists:
  ```bash
  aws dynamodb get-item \
    --table-name riftsage-Players-production \
    --key '{"player_puuid":{"S":"abc123"}}'
  ```
- Check IAM permissions in `infrastructure.yaml`

#### 4. "Lambda timeout"

**Error:**
```
Task timed out after 300.00 seconds
```

**Solution:**
- Increase timeout in `infrastructure.yaml`:
  ```yaml
  Timeout: 600  # 10 minutes
  ```
- Optimize code (add pagination, caching)
- Consider Step Functions for long-running workflows

#### 5. "Bedrock throttling"

**Error:**
```
ThrottlingException: Rate exceeded
```

**Solution:**
- Add retry logic:
  ```python
  from botocore.exceptions import ClientError
  import time

  for attempt in range(3):
      try:
          response = bedrock_client.invoke_model(...)
          break
      except ClientError as e:
          if e.response['Error']['Code'] == 'ThrottlingException':
              time.sleep(2 ** attempt)
          else:
              raise
  ```
- Request quota increase in AWS Console → Bedrock

#### 6. "S3 access denied"

**Error:**
```
ClientError: An error occurred (AccessDenied)
```

**Solution:**
- Check bucket policy in `infrastructure.yaml`
- Verify Lambda has S3 permissions:
  ```yaml
  - PolicyName: S3Access
    PolicyDocument:
      Statement:
        - Effect: Allow
          Action:
            - s3:GetObject
            - s3:PutObject
          Resource: !Sub '${RawMatchDataBucket.Arn}/*'
  ```

#### 7. "CloudFormation stack stuck"

**Error:**
```
Stack status: UPDATE_ROLLBACK_IN_PROGRESS
```

**Solution:**
```bash
# Cancel update
aws cloudformation cancel-update-stack --stack-name riftsage-production

# Or continue rollback
aws cloudformation continue-update-rollback --stack-name riftsage-production

# Delete and recreate (CAUTION: data loss)
aws cloudformation delete-stack --stack-name riftsage-production
```

### Debugging Workflow

**Step 1: Check CloudWatch Logs**
```bash
aws logs tail /aws/lambda/riftsage-DataCollection-production \
  --filter-pattern "ERROR" \
  --since 1h
```

**Step 2: Test Lambda directly**
```bash
aws lambda invoke \
  --function-name riftsage-DataCollection-production \
  --payload '{"player_puuid":"test","region":"na1","year":2025}' \
  --log-type Tail \
  response.json

# Decode logs
cat response.json | jq -r '.LogResult' | base64 --decode
```

**Step 3: Check DynamoDB**
```bash
# Scan table (limited to 1MB)
aws dynamodb scan --table-name riftsage-Players-production

# Get specific item
aws dynamodb get-item \
  --table-name riftsage-Players-production \
  --key '{"player_puuid":{"S":"abc123"}}'
```

**Step 4: Check S3**
```bash
# List objects
aws s3 ls s3://riftsage-data-production-123456789012/raw-matches/ --recursive

# Download object
aws s3 cp s3://riftsage-data-production-123456789012/raw-matches/abc123/2025/match.json ./
```

**Step 5: Check CloudFormation**
```bash
# Stack status
aws cloudformation describe-stacks --stack-name riftsage-production

# Stack events
aws cloudformation describe-stack-events \
  --stack-name riftsage-production \
  --max-items 20
```

---

## Best Practices Summary

### For AI Assistants

**When Making Changes:**

1. ✅ **DO:**
   - Read relevant Lambda functions before modifying
   - Check `config/config.yaml` for configuration values
   - Test changes with single Lambda invocation before full deployment
   - Update this CLAUDE.md if adding new patterns or components
   - Consider cost implications (especially Bedrock usage)
   - Use structured logging with context
   - Handle errors gracefully
   - Follow existing naming conventions
   - Add docstrings to new functions
   - Check CloudWatch logs after deployment

2. ❌ **DON'T:**
   - Exceed Riot API rate limits (20/sec, 100/2min)
   - Modify infrastructure.yaml without testing with change sets
   - Change Bedrock model without cost analysis
   - Deploy to production without testing
   - Use hardcoded values (use config.yaml or environment variables)
   - Ignore error handling
   - Create Lambda functions >10 MB without layers
   - Use camelCase in Python code (use snake_case)
   - Commit API keys to git
   - Forget to update documentation

**When Debugging:**

1. Start with CloudWatch Logs
2. Test Lambda functions individually
3. Check DynamoDB for data issues
4. Verify S3 objects exist
5. Review CloudFormation events for infrastructure issues

**When Optimizing:**

1. Focus on Bedrock costs first (67% of total)
2. Use caching aggressively
3. Batch operations where possible
4. Monitor with ResourceManager
5. Set up billing alerts

---

## Quick Reference

### Important File Paths

```
/home/user/rifts/infrastructure.yaml           # CloudFormation template
/home/user/rifts/config/config.yaml            # Configuration
/home/user/rifts/lambda_functions/*.py         # Lambda code
/home/user/rifts/deployment/deploy.sh          # Deployment script
/home/user/rifts/QUICKSTART.md                 # User guide
/home/user/rifts/docs/AWS_STACK.md             # Resource costs
```

### Key AWS Resources

```
Lambda: riftsage-{Function}-{Environment}
DynamoDB: riftsage-{Table}-{Environment}
S3: riftsage-{bucket}-{Environment}-{AccountId}
Secrets: /riftsage/{Environment}/riot-api-key
```

### Common Commands

```bash
# Deploy
./deployment/deploy.sh

# Test Lambda
aws lambda invoke --function-name riftsage-DataCollection-production \
  --payload '{"player_puuid":"xxx","region":"na1","year":2025}' response.json

# View logs
aws logs tail /aws/lambda/riftsage-DataCollection-production --follow

# Check costs
aws lambda invoke --function-name riftsage-ResourceManager-production \
  --payload '{"action":"get_costs"}' costs.json
```

### Useful Links

- Riot Games Developer Portal: https://developer.riotgames.com/
- AWS Bedrock Pricing: https://aws.amazon.com/bedrock/pricing/
- CloudFormation Documentation: https://docs.aws.amazon.com/cloudformation/
- Lambda Best Practices: https://docs.aws.amazon.com/lambda/latest/dg/best-practices.html

---

**Document Version:** 1.0.0
**Last Updated:** 2025-11-14
**Maintained By:** AI Assistants working on RiftSage

For questions or updates to this document, please update the version number and last updated date.
