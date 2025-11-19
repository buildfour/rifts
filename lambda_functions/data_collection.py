"""
RiftSage AI Agent - Data Collection Lambda Function
Fetches match history from Riot API and stores in S3
"""

import json
import os
import boto3
import requests
import time
from datetime import datetime
from typing import Dict, List, Any
import logging

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Initialize AWS clients
s3_client = boto3.client('s3')
dynamodb = boto3.resource('dynamodb')
secrets_client = boto3.client('secretsmanager')

# Environment variables
ENVIRONMENT = os.environ.get('ENVIRONMENT', 'development')
DATA_BUCKET = os.environ.get('DATA_BUCKET')
PLAYERS_TABLE_NAME = os.environ.get('PLAYERS_TABLE')
CACHE_TABLE_NAME = os.environ.get('CACHE_TABLE')
RIOT_API_SECRET_NAME = os.environ.get('RIOT_API_SECRET')

# Dataset configuration
TARGET_PLAYER_COUNT = 500  # Target dataset size for ML training and analysis
MATCHES_PER_PLAYER = 200   # Target matches per player for quality insights

# Rate limiting configuration
RATE_LIMITS = {
    'requests_per_second': 20,
    'requests_per_two_minutes': 100
}


class RiotAPIClient:
    """Client for interacting with Riot Games API"""

    BASE_URLS = {
        'na1': 'https://na1.api.riotgames.com',
        'euw1': 'https://euw1.api.riotgames.com',
        'kr': 'https://kr.api.riotgames.com',
        'americas': 'https://americas.api.riotgames.com',
        'europe': 'https://europe.api.riotgames.com',
        'asia': 'https://asia.api.riotgames.com'
    }

    def __init__(self, api_key: str):
        self.api_key = api_key
        self.request_timestamps = []

    def _rate_limit(self):
        """Implement rate limiting"""
        current_time = time.time()

        # Remove timestamps older than 2 minutes
        self.request_timestamps = [
            ts for ts in self.request_timestamps
            if current_time - ts < 120
        ]

        # Check if we're at the limit
        if len(self.request_timestamps) >= RATE_LIMITS['requests_per_two_minutes']:
            sleep_time = 120 - (current_time - self.request_timestamps[0])
            if sleep_time > 0:
                logger.info(f"Rate limit reached, sleeping for {sleep_time:.2f} seconds")
                time.sleep(sleep_time)
                self.request_timestamps = []

        # Add current timestamp
        self.request_timestamps.append(current_time)

    def get_summoner_by_puuid(self, region: str, puuid: str) -> Dict:
        """Get summoner information by PUUID"""
        self._rate_limit()

        url = f"{self.BASE_URLS[region]}/lol/summoner/v4/summoners/by-puuid/{puuid}"
        headers = {'X-Riot-Token': self.api_key}

        response = requests.get(url, headers=headers, timeout=10)
        response.raise_for_status()

        return response.json()

    def get_match_history(self, region: str, puuid: str, start_time: int = None,
                         end_time: int = None, queue: int = 420, count: int = 100, start: int = 0) -> List[str]:
        """Get match IDs for a player"""
        self._rate_limit()

        # Convert region to routing value
        routing = self._get_routing_value(region)
        url = f"{self.BASE_URLS[routing]}/lol/match/v5/matches/by-puuid/{puuid}/ids"

        params = {
            'queue': queue,  # 420 = Ranked Solo/Duo
            'count': min(count, 100),  # API max is 100 per request
            'start': start
        }

        if start_time:
            params['startTime'] = start_time
        if end_time:
            params['endTime'] = end_time

        headers = {'X-Riot-Token': self.api_key}

        response = requests.get(url, headers=headers, params=params, timeout=10)
        response.raise_for_status()

        return response.json()

    def get_match_details(self, region: str, match_id: str) -> Dict:
        """Get detailed match information"""
        self._rate_limit()

        routing = self._get_routing_value(region)
        url = f"{self.BASE_URLS[routing]}/lol/match/v5/matches/{match_id}"
        headers = {'X-Riot-Token': self.api_key}

        response = requests.get(url, headers=headers, timeout=10)
        response.raise_for_status()

        return response.json()

    def _get_routing_value(self, region: str) -> str:
        """Convert platform region to routing value"""
        routing_map = {
            'na1': 'americas',
            'br1': 'americas',
            'la1': 'americas',
            'la2': 'americas',
            'euw1': 'europe',
            'eun1': 'europe',
            'tr1': 'europe',
            'ru': 'europe',
            'kr': 'asia',
            'jp1': 'asia'
        }
        return routing_map.get(region, 'americas')


def get_riot_api_key() -> str:
    """Retrieve Riot API key from AWS Secrets Manager"""
    try:
        response = secrets_client.get_secret_value(SecretId=RIOT_API_SECRET_NAME)
        secret = json.loads(response['SecretString'])
        return secret['api_key']
    except Exception as e:
        logger.error(f"Error retrieving API key: {str(e)}")
        raise


def check_cache(match_id: str) -> Dict:
    """Check if match data is already cached in DynamoDB"""
    try:
        cache_table = dynamodb.Table(CACHE_TABLE_NAME)
        response = cache_table.get_item(Key={'match_id': match_id})

        if 'Item' in response:
            # Check if cache is still valid
            ttl = response['Item'].get('ttl', 0)
            if int(time.time()) < ttl:
                return response['Item'].get('match_data')

        return None
    except Exception as e:
        logger.warning(f"Error checking cache: {str(e)}")
        return None


def save_to_cache(match_id: str, match_data: Dict):
    """Save match data to DynamoDB cache"""
    try:
        cache_table = dynamodb.Table(CACHE_TABLE_NAME)

        # Set TTL to 24 hours from now
        ttl = int(time.time()) + (24 * 60 * 60)

        cache_table.put_item(
            Item={
                'match_id': match_id,
                'match_data': match_data,
                'ttl': ttl,
                'cached_at': datetime.utcnow().isoformat()
            }
        )
    except Exception as e:
        logger.warning(f"Error saving to cache: {str(e)}")


def save_to_s3(player_puuid: str, match_data: Dict, match_id: str):
    """Save match data to S3"""
    try:
        year = datetime.utcnow().year
        key = f"raw-matches/{player_puuid}/{year}/{match_id}.json"

        s3_client.put_object(
            Bucket=DATA_BUCKET,
            Key=key,
            Body=json.dumps(match_data, indent=2),
            ContentType='application/json',
            Metadata={
                'player_puuid': player_puuid,
                'match_id': match_id,
                'collected_at': datetime.utcnow().isoformat()
            }
        )

        logger.info(f"Saved match {match_id} to S3: {key}")
        return key
    except Exception as e:
        logger.error(f"Error saving to S3: {str(e)}")
        raise


def update_player_record(player_puuid: str, match_count: int):
    """Update player record in DynamoDB"""
    try:
        players_table = dynamodb.Table(PLAYERS_TABLE_NAME)

        players_table.update_item(
            Key={'player_puuid': player_puuid},
            UpdateExpression='SET last_collection = :timestamp, match_count = :count',
            ExpressionAttributeValues={
                ':timestamp': datetime.utcnow().isoformat(),
                ':count': match_count
            }
        )
    except Exception as e:
        logger.error(f"Error updating player record: {str(e)}")


def collect_player_matches(puuid: str, region: str, year: int = None) -> Dict:
    """Collect all matches for a player"""

    if year is None:
        year = datetime.utcnow().year

    # Get API key
    api_key = get_riot_api_key()
    riot_client = RiotAPIClient(api_key)

    # Calculate time range for the year
    start_time = int(datetime(year, 1, 1).timestamp())
    end_time = int(datetime(year, 12, 31, 23, 59, 59).timestamp())

    try:
        # Get match history with pagination to fetch up to MATCHES_PER_PLAYER
        logger.info(f"Fetching match history for {puuid} in {region} for year {year}")
        match_ids = []

        # Fetch in batches of 100 (API limit) until we reach target or no more matches
        for start_index in range(0, MATCHES_PER_PLAYER, 100):
            batch = riot_client.get_match_history(
                region=region,
                puuid=puuid,
                start_time=start_time,
                end_time=end_time,
                count=100,
                start=start_index
            )

            if not batch:
                break  # No more matches available

            match_ids.extend(batch)
            logger.info(f"Fetched batch {start_index//100 + 1}: {len(batch)} matches")

            if len(batch) < 100:
                break  # Last batch, no more matches available

        logger.info(f"Found {len(match_ids)} total matches")

        # Collect each match
        collected_matches = []
        s3_keys = []

        for i, match_id in enumerate(match_ids):
            logger.info(f"Processing match {i+1}/{len(match_ids)}: {match_id}")

            # Check cache first
            cached_data = check_cache(match_id)
            if cached_data:
                logger.info(f"Match {match_id} found in cache")
                match_data = cached_data
            else:
                # Fetch from API
                match_data = riot_client.get_match_details(region, match_id)

                # Save to cache
                save_to_cache(match_id, match_data)

            # Save to S3
            s3_key = save_to_s3(puuid, match_data, match_id)
            s3_keys.append(s3_key)
            collected_matches.append(match_id)

        # Update player record
        update_player_record(puuid, len(collected_matches))

        return {
            'success': True,
            'player_puuid': puuid,
            'region': region,
            'year': year,
            'matches_collected': len(collected_matches),
            'match_ids': collected_matches,
            's3_keys': s3_keys
        }

    except Exception as e:
        logger.error(f"Error collecting matches: {str(e)}")
        return {
            'success': False,
            'error': str(e),
            'player_puuid': puuid,
            'region': region
        }


def lambda_handler(event, context):
    """
    Lambda handler for data collection

    Expected event format:
    {
        "player_puuid": "string",
        "region": "na1",
        "year": 2025
    }
    """

    try:
        logger.info(f"Event: {json.dumps(event)}")

        # Extract parameters
        puuid = event.get('player_puuid')
        region = event.get('region', 'na1')
        year = event.get('year', datetime.utcnow().year)

        if not puuid:
            return {
                'statusCode': 400,
                'body': json.dumps({
                    'error': 'player_puuid is required'
                })
            }

        # Validate region
        valid_regions = ['na1', 'euw1', 'eun1', 'kr', 'br1', 'jp1', 'la1', 'la2', 'tr1', 'ru']
        if region not in valid_regions:
            return {
                'statusCode': 400,
                'body': json.dumps({
                    'error': f'Invalid region. Must be one of: {valid_regions}'
                })
            }

        # Collect matches
        result = collect_player_matches(puuid, region, year)

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

    except Exception as e:
        logger.error(f"Lambda handler error: {str(e)}", exc_info=True)
        return {
            'statusCode': 500,
            'body': json.dumps({
                'error': str(e),
                'type': type(e).__name__
            })
        }
