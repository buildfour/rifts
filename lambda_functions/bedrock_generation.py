"""
RiftSage AI Agent - Bedrock Generation Lambda Function
Generates personalized insights using Amazon Bedrock (Llama 3.1 70B)
"""

import json
import os
import boto3
import logging
from datetime import datetime
from typing import Dict, List, Any
from decimal import Decimal

logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Initialize AWS clients
bedrock_runtime = boto3.client('bedrock-runtime', region_name='us-east-1')
dynamodb = boto3.resource('dynamodb')
s3_client = boto3.client('s3')

# Environment variables
ENVIRONMENT = os.environ.get('ENVIRONMENT', 'development')
METRICS_TABLE_NAME = os.environ.get('METRICS_TABLE')
INSIGHTS_TABLE_NAME = os.environ.get('INSIGHTS_TABLE')
REPORTS_BUCKET = os.environ.get('REPORTS_BUCKET')

# Bedrock model configuration
BEDROCK_MODEL_ID = 'meta.llama3-1-70b-instruct-v1:0'
MAX_TOKENS = 4000
TEMPERATURE = 0.3


class BedrockInsightGenerator:
    """Generates insights using Amazon Bedrock"""

    def __init__(self):
        self.model_id = BEDROCK_MODEL_ID

    def call_bedrock(self, prompt: str, max_tokens: int = MAX_TOKENS) -> str:
        """Call Bedrock API with Llama 3.1 70B model"""
        try:
            # Format prompt for Llama 3.1 with instruction template
            formatted_prompt = f"<|begin_of_text|><|start_header_id|>user<|end_header_id|>\n\n{prompt}<|eot_id|><|start_header_id|>assistant<|end_header_id|>\n\n"

            request_body = {
                'prompt': formatted_prompt,
                'max_gen_len': max_tokens,
                'temperature': TEMPERATURE,
                'top_p': 0.9
            }

            response = bedrock_runtime.invoke_model(
                modelId=self.model_id,
                body=json.dumps(request_body)
            )

            response_body = json.loads(response['body'].read())
            return response_body['generation']

        except Exception as e:
            logger.error(f"Error calling Bedrock: {str(e)}")
            raise

    def generate_role_performance_snapshot(self, player_data: Dict) -> str:
        """Generate Role Performance Snapshot section"""

        prompt = f"""You are RiftSage, an AI performance analyst for League of Legends. Generate a Role Performance Snapshot analysis using the player's data.

PLAYER DATA:
{json.dumps(player_data, indent=2)}

Generate the complete Role Performance Snapshot section following this 4-part structure:

1. INTRO OVERVIEW (2-3 sentences):
   - Identify their PRIMARY performance pattern
   - Mention their SECONDARY characteristic
   - Reference a specific trend
   - End with: "Your key [category] ratios show:"

2. STATS & METRICS:
   Present their top 4 performing metrics with format:
   - Metric Name: [Exact Value] ([Contextual insight in 5-8 words])

3. DEEPER INSIGHTS:
   Write 4-5 bullet points explaining:
   - What their win rate REVEALS about gameplay approach
   - What their KDA MEANS in terms of actual behavior
   - How other metrics CONNECT to create success patterns
   - Use specific numbers from their data

4. NARRATIVE MEANING (3-5 sentences):
   - Synthesize what the COMBINATION of metrics reveals
   - Explain WHY this approach is effective
   - Connect to their rank and potential
   - Reference at least 3 specific numbers

CRITICAL RULES:
- Every sentence must be unique to THIS player's data
- Use ONLY numbers from the provided data
- Make connections between metrics that reveal gameplay patterns
- Write as if you deeply understand THIS player's unique playstyle"""

        return self.call_bedrock(prompt)

    def generate_improvement_blueprint(self, player_data: Dict, champion_recs: List[Dict]) -> str:
        """Generate Improvement Blueprint section"""

        prompt = f"""You are RiftSage, an AI performance analyst for League of Legends. Generate an Improvement Blueprint for this player.

PLAYER DATA:
{json.dumps(player_data, indent=2)}

CHAMPION RECOMMENDATIONS:
{json.dumps(champion_recs, indent=2)}

Generate the complete Improvement Blueprint section following this structure:

1. INTRO OVERVIEW (2-3 sentences):
   - Acknowledge their primary strength first
   - Identify the 2 specific areas for improvement
   - Frame improvement as building on existing success
   - End with: "The goal: make your [strength] work harder by [what improvements enable]"

2. STATS & METRICS (Current Baseline):
   Present their current state for improvement metrics

3. DEEPER INSIGHTS (Data Alignment for Growth):
   Write 2-3 bullet points explaining:
   - HOW the improvement metrics extend their current impact
   - WHY their existing pattern needs these additions
   - WHAT enabling factors these improvements provide

4. RECOMMENDED CHAMPION POOL:
   Create a table with the 3 recommended champions showing:
   - Champion name
   - Win rate pattern
   - CS/min potential
   - Vision support
   - 15-20 word explanation of fit

5. PHASE-BY-PHASE EXECUTION:
   Create a table with 3 game phases (0-10min, 10-20min, 20+min) showing:
   - Priority goal
   - Core action
   - Gold & Impact gain

6. 30-DAY MEASURABLE TARGETS:
   Create a table showing current value, target value, and growth outcome

7. NARRATIVE MEANING (3-4 sentences):
   Synthesize how current strengths + improvements = superior performance

CRITICAL: Be specific to this player's situation with exact numbers."""

        return self.call_bedrock(prompt, max_tokens=5000)

    def generate_mental_resilience_section(self, player_data: Dict) -> str:
        """Generate Mental Resilience & Consistency section"""

        prompt = f"""You are RiftSage. Generate a Mental Resilience & Consistency analysis for this player.

PLAYER DATA:
{json.dumps(player_data, indent=2)}

Use the 4-part structure:
1. Intro Overview - frame their mental game strengths
2. Stats & Metrics - resilience score, consistency rating, comeback performance
3. Deeper Insights - what the patterns reveal
4. Narrative Meaning - how mental game contributes to success

Be specific to their data. Include exact numbers."""

        return self.call_bedrock(prompt)

    def generate_champion_mastery_section(self, player_data: Dict) -> str:
        """Generate Champion Mastery Analysis section"""

        prompt = f"""You are RiftSage. Generate a Champion Mastery Analysis for this player.

PLAYER DATA:
{json.dumps(player_data, indent=2)}

Use the 4-part structure:
1. Intro Overview - their champion pool characteristics
2. Stats & Metrics - most played, pool depth, highest win rate
3. Deeper Insights - what their pool reveals about playstyle
4. Narrative Meaning - strategic recommendations

Include specific champion names and win rates from their data."""

        return self.call_bedrock(prompt)


def prepare_section_data_package(player_puuid: str, year: int, section_type: str) -> Dict:
    """Prepare data package for a specific section"""
    try:
        metrics_table = dynamodb.Table(METRICS_TABLE_NAME)

        response = metrics_table.get_item(
            Key={
                'player_puuid': player_puuid,
                'year': year
            }
        )

        if 'Item' not in response:
            raise ValueError("Metrics not found")

        metrics = response['Item']

        # Convert Decimal to float for JSON serialization
        def convert_decimals(obj):
            if isinstance(obj, Decimal):
                return float(obj)
            elif isinstance(obj, dict):
                return {k: convert_decimals(v) for k, v in obj.items()}
            elif isinstance(obj, list):
                return [convert_decimals(item) for item in obj]
            return obj

        metrics = convert_decimals(metrics)

        # Get ML inference results if available
        ml_inference = metrics.get('ml_inference', {})

        # Build data package based on section type
        if section_type == 'role_performance':
            data_package = {
                'player_metrics': {
                    'win_rate': metrics.get('win_rate', 0),
                    'kda': metrics.get('kda', 0),
                    'kills_per_game': metrics.get('kills_per_game', 0),
                    'deaths_per_game': metrics.get('deaths_per_game', 0),
                    'assists_per_game': metrics.get('assists_per_game', 0),
                    'cs_per_min': metrics.get('avg_cs_per_min', 0),
                    'vision_per_min': metrics.get('avg_vision_score_per_min', 0),
                    'primary_role': metrics.get('primary_role', 'UNKNOWN'),
                    'total_games': metrics.get('total_games', 0)
                },
                'context': {
                    'performance_pattern': ml_inference.get('performance_pattern', {}).get('pattern', 'unknown'),
                    'playstyle_archetype': ml_inference.get('playstyle', {}).get('archetype', 'Unknown')
                }
            }

        elif section_type == 'improvement_blueprint':
            data_package = {
                'player_metrics': metrics,
                'ml_inference': ml_inference,
                'improvement_opportunities': [
                    {'metric': 'cs_per_min', 'current': metrics.get('avg_cs_per_min', 0)},
                    {'metric': 'vision_per_min', 'current': metrics.get('avg_vision_score_per_min', 0)}
                ]
            }

        elif section_type == 'mental_resilience':
            data_package = {
                'player_metrics': metrics,
                'resilience': ml_inference.get('mental_resilience', {}),
                'comeback_wins': metrics.get('comeback_wins', 0)
            }

        elif section_type == 'champion_mastery':
            data_package = {
                'player_metrics': metrics,
                'most_played': metrics.get('most_played_champion', 'Unknown'),
                'unique_champions': metrics.get('unique_champions', 0)
            }

        else:
            data_package = {'player_metrics': metrics}

        return data_package

    except Exception as e:
        logger.error(f"Error preparing data package: {str(e)}")
        raise


def generate_section(player_puuid: str, year: int, section_type: str) -> Dict:
    """Generate a single section using Bedrock"""
    try:
        # Prepare data
        data_package = prepare_section_data_package(player_puuid, year, section_type)

        # Initialize generator
        generator = BedrockInsightGenerator()

        # Generate content based on section type
        if section_type == 'role_performance':
            content = generator.generate_role_performance_snapshot(data_package)

        elif section_type == 'improvement_blueprint':
            # Get champion recommendations
            champion_recs = []  # Would query champion recommendations table
            content = generator.generate_improvement_blueprint(data_package, champion_recs)

        elif section_type == 'mental_resilience':
            content = generator.generate_mental_resilience_section(data_package)

        elif section_type == 'champion_mastery':
            content = generator.generate_champion_mastery_section(data_package)

        else:
            raise ValueError(f"Unknown section type: {section_type}")

        # Validate content
        if not content or len(content) < 100:
            raise ValueError("Generated content is too short")

        # Save to DynamoDB
        insights_table = dynamodb.Table(INSIGHTS_TABLE_NAME)
        insights_table.put_item(
            Item={
                'player_puuid': player_puuid,
                'section_id': f"{year}_{section_type}",
                'section_type': section_type,
                'year': year,
                'content': content,
                'generated_at': datetime.utcnow().isoformat(),
                'data_package': json.dumps(data_package)
            }
        )

        return {
            'success': True,
            'section_type': section_type,
            'content_length': len(content),
            'player_puuid': player_puuid
        }

    except Exception as e:
        logger.error(f"Error generating section: {str(e)}")
        return {
            'success': False,
            'error': str(e)
        }


def lambda_handler(event, context):
    """
    Lambda handler for Bedrock generation

    Event format:
    {
        "player_puuid": "string",
        "year": 2025,
        "section_type": "role_performance" | "improvement_blueprint" | "mental_resilience" | "champion_mastery"
    }

    OR generate all sections:
    {
        "player_puuid": "string",
        "year": 2025,
        "generate_all": true
    }
    """

    try:
        logger.info(f"Event: {json.dumps(event, default=str)}")

        player_puuid = event.get('player_puuid')
        year = event.get('year', datetime.utcnow().year)
        section_type = event.get('section_type')
        generate_all = event.get('generate_all', False)

        if not player_puuid:
            return {
                'statusCode': 400,
                'body': json.dumps({'error': 'player_puuid is required'})
            }

        if generate_all:
            # Generate all sections
            sections = ['role_performance', 'improvement_blueprint', 'mental_resilience', 'champion_mastery']
            results = []

            for section in sections:
                result = generate_section(player_puuid, year, section)
                results.append(result)

            success_count = sum(1 for r in results if r['success'])

            return {
                'statusCode': 200,
                'body': json.dumps({
                    'success': success_count == len(sections),
                    'sections_generated': success_count,
                    'total_sections': len(sections),
                    'results': results
                })
            }

        elif section_type:
            # Generate single section
            result = generate_section(player_puuid, year, section_type)

            if result['success']:
                return {
                    'statusCode': 200,
                    'body': json.dumps(result)
                }
            else:
                return {
                    'statusCode': 500,
                    'body': json.dumps(result)
                }

        else:
            return {
                'statusCode': 400,
                'body': json.dumps({'error': 'section_type or generate_all required'})
            }

    except Exception as e:
        logger.error(f"Lambda handler error: {str(e)}", exc_info=True)
        return {
            'statusCode': 500,
            'body': json.dumps({
                'error': str(e),
                'type': type(e).__name__
            })
        }
