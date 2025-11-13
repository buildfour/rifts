/**
 * Lambda Function: Link Summoner Account
 * Endpoint: POST /summoner/link
 * Body: { summonerName: string, region: string }
 *
 * Validates summoner exists via Riot API and links to user account
 */

const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const { DynamoDBDocumentClient, PutCommand, GetCommand } = require('@aws-sdk/lib-dynamodb');
const https = require('https');

const dynamoClient = new DynamoDBClient({});
const docClient = DynamoDBDocumentClient.from(dynamoClient);

const USERS_TABLE = process.env.USERS_TABLE_NAME;
const RIOT_API_KEY = process.env.RIOT_API_KEY;

// Region to platform mapping
const REGION_TO_PLATFORM = {
    'na1': 'na1',
    'euw1': 'euw1',
    'eun1': 'eun1',
    'kr': 'kr',
    'br1': 'br1',
    'la1': 'la1',
    'la2': 'la2',
    'oc1': 'oc1',
    'tr1': 'tr1',
    'ru': 'ru',
    'jp1': 'jp1'
};

/**
 * Parse auth token
 */
function parseAuthToken(event) {
    const authHeader = event.headers?.Authorization || event.headers?.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
        throw new Error('Missing or invalid Authorization header');
    }
    const token = authHeader.substring(7);
    const parts = token.split('.');
    if (parts.length !== 3) {
        throw new Error('Invalid JWT format');
    }
    const payload = JSON.parse(Buffer.from(parts[1], 'base64').toString());
    if (payload.exp && payload.exp < Date.now() / 1000) {
        throw new Error('Token expired');
    }
    return payload;
}

/**
 * Make HTTPS request to Riot API
 */
function makeRiotApiRequest(hostname, path, headers) {
    return new Promise((resolve, reject) => {
        const options = {
            hostname,
            path,
            method: 'GET',
            headers
        };

        const req = https.request(options, (res) => {
            let data = '';

            res.on('data', (chunk) => {
                data += chunk;
            });

            res.on('end', () => {
                if (res.statusCode === 200) {
                    try {
                        resolve(JSON.parse(data));
                    } catch (e) {
                        reject(new Error('Failed to parse Riot API response'));
                    }
                } else if (res.statusCode === 404) {
                    reject(new Error('Summoner not found'));
                } else if (res.statusCode === 429) {
                    reject(new Error('Rate limit exceeded'));
                } else {
                    reject(new Error(`Riot API error: ${res.statusCode}`));
                }
            });
        });

        req.on('error', (error) => {
            reject(error);
        });

        req.setTimeout(5000, () => {
            req.destroy();
            reject(new Error('Request timeout'));
        });

        req.end();
    });
}

/**
 * Get summoner data from Riot API
 */
async function getSummonerByName(summonerName, region) {
    if (!RIOT_API_KEY) {
        // For demo purposes, return mock data if no API key configured
        console.warn('No Riot API key configured, returning mock data');
        return {
            puuid: `mock-${summonerName.toLowerCase()}-${Date.now()}`,
            name: summonerName,
            summonerLevel: 100,
            profileIconId: 1
        };
    }

    const platform = REGION_TO_PLATFORM[region];
    if (!platform) {
        throw new Error(`Invalid region: ${region}`);
    }

    const hostname = `${platform}.api.riotgames.com`;
    const path = `/lol/summoner/v4/summoners/by-name/${encodeURIComponent(summonerName)}`;
    const headers = {
        'X-Riot-Token': RIOT_API_KEY
    };

    return await makeRiotApiRequest(hostname, path, headers);
}

/**
 * Get summoner rank from Riot API
 */
async function getSummonerRank(summonerId, region) {
    if (!RIOT_API_KEY) {
        // Return mock rank for demo
        return {
            tier: 'GOLD',
            rank: 'II',
            leaguePoints: 67
        };
    }

    const platform = REGION_TO_PLATFORM[region];
    const hostname = `${platform}.api.riotgames.com`;
    const path = `/lol/league/v4/entries/by-summoner/${summonerId}`;
    const headers = {
        'X-Riot-Token': RIOT_API_KEY
    };

    try {
        const leagues = await makeRiotApiRequest(hostname, path, headers);

        // Find ranked solo queue
        const rankedSolo = leagues.find(league => league.queueType === 'RANKED_SOLO_5x5');
        if (rankedSolo) {
            return {
                tier: rankedSolo.tier,
                rank: rankedSolo.rank,
                leaguePoints: rankedSolo.leaguePoints
            };
        }

        return null;
    } catch (error) {
        console.warn('Failed to get rank:', error);
        return null;
    }
}

/**
 * Main Lambda handler
 */
exports.handler = async (event) => {
    console.log('Event:', JSON.stringify(event, null, 2));

    const headers = {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers': 'Content-Type,Authorization',
        'Access-Control-Allow-Methods': 'POST,OPTIONS'
    };

    // Handle OPTIONS for CORS
    if (event.httpMethod === 'OPTIONS') {
        return {
            statusCode: 200,
            headers,
            body: JSON.stringify({ message: 'OK' })
        };
    }

    try {
        // Parse auth token
        const tokenPayload = parseAuthToken(event);
        const userId = tokenPayload.sub;
        const email = tokenPayload.email;

        // Parse request body
        const body = JSON.parse(event.body || '{}');
        const { summonerName, region } = body;

        if (!summonerName || !region) {
            return {
                statusCode: 400,
                headers,
                body: JSON.stringify({
                    error: 'Missing required fields: summonerName, region'
                })
            };
        }

        // Validate region
        if (!REGION_TO_PLATFORM[region]) {
            return {
                statusCode: 400,
                headers,
                body: JSON.stringify({
                    error: 'Invalid region',
                    validRegions: Object.keys(REGION_TO_PLATFORM)
                })
            };
        }

        // Get summoner from Riot API
        console.log(`Looking up summoner: ${summonerName} in ${region}`);
        const summonerData = await getSummonerByName(summonerName, region);

        // Get rank data
        const rankData = await getSummonerRank(summonerData.id, region);
        const rankString = rankData
            ? `${rankData.tier} ${rankData.rank}`
            : 'Unranked';

        // Save to DynamoDB
        const now = new Date().toISOString();
        await docClient.send(new PutCommand({
            TableName: USERS_TABLE,
            Item: {
                userId,
                email,
                summonerName: summonerData.name,
                summonerPuuid: summonerData.puuid,
                summonerId: summonerData.id,
                region,
                rank: rankString,
                summonerLevel: summonerData.summonerLevel,
                profileIconId: summonerData.profileIconId,
                createdAt: now,
                updatedAt: now
            }
        }));

        console.log(`Successfully linked summoner ${summonerName} to user ${userId}`);

        // Return success response
        return {
            statusCode: 200,
            headers,
            body: JSON.stringify({
                success: true,
                summoner: {
                    name: summonerData.name,
                    puuid: summonerData.puuid,
                    region,
                    rank: rankString,
                    level: summonerData.summonerLevel
                }
            })
        };

    } catch (error) {
        console.error('Error:', error);

        // Handle specific errors
        if (error.message.includes('Summoner not found')) {
            return {
                statusCode: 404,
                headers,
                body: JSON.stringify({
                    error: 'Summoner not found',
                    message: 'Please check the summoner name and region'
                })
            };
        }

        if (error.message.includes('Rate limit')) {
            return {
                statusCode: 429,
                headers,
                body: JSON.stringify({
                    error: 'Rate limit exceeded',
                    message: 'Please try again in a few moments'
                })
            };
        }

        if (error.message.includes('Token expired')) {
            return {
                statusCode: 401,
                headers,
                body: JSON.stringify({ error: 'Token expired', code: 'TOKEN_EXPIRED' })
            };
        }

        if (error.message.includes('Authorization')) {
            return {
                statusCode: 401,
                headers,
                body: JSON.stringify({ error: 'Unauthorized', code: 'UNAUTHORIZED' })
            };
        }

        return {
            statusCode: 500,
            headers,
            body: JSON.stringify({
                error: 'Internal server error',
                message: error.message
            })
        };
    }
};
