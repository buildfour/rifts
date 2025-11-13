/**
 * Lambda Function: Get User Profile
 * Endpoint: GET /user/profile
 *
 * Returns user profile data including linked summoner information
 */

const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const { DynamoDBDocumentClient, GetCommand } = require('@aws-sdk/lib-dynamodb');

const dynamoClient = new DynamoDBClient({});
const docClient = DynamoDBDocumentClient.from(dynamoClient);

const USERS_TABLE = process.env.USERS_TABLE_NAME;

/**
 * Parse and validate JWT token from Authorization header
 */
function parseAuthToken(event) {
    const authHeader = event.headers?.Authorization || event.headers?.authorization;

    if (!authHeader || !authHeader.startsWith('Bearer ')) {
        throw new Error('Missing or invalid Authorization header');
    }

    const token = authHeader.substring(7);

    // Parse JWT (simple base64 decode - in production, verify signature)
    const parts = token.split('.');
    if (parts.length !== 3) {
        throw new Error('Invalid JWT format');
    }

    const payload = JSON.parse(Buffer.from(parts[1], 'base64').toString());

    // Check expiration
    if (payload.exp && payload.exp < Date.now() / 1000) {
        throw new Error('Token expired');
    }

    return payload;
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
        'Access-Control-Allow-Methods': 'GET,OPTIONS'
    };

    // Handle OPTIONS request for CORS
    if (event.httpMethod === 'OPTIONS') {
        return {
            statusCode: 200,
            headers,
            body: JSON.stringify({ message: 'OK' })
        };
    }

    try {
        // Parse and validate auth token
        const tokenPayload = parseAuthToken(event);
        const userId = tokenPayload.sub;

        if (!userId) {
            return {
                statusCode: 401,
                headers,
                body: JSON.stringify({ error: 'Invalid token: missing user ID' })
            };
        }

        // Get user from DynamoDB
        const result = await docClient.send(new GetCommand({
            TableName: USERS_TABLE,
            Key: { userId }
        }));

        if (!result.Item) {
            // User not found - create default profile
            return {
                statusCode: 200,
                headers,
                body: JSON.stringify({
                    userId,
                    email: tokenPayload.email,
                    summonerName: null,
                    summonerPuuid: null,
                    region: null,
                    rank: 'Unranked',
                    createdAt: new Date().toISOString()
                })
            };
        }

        // Return user profile
        return {
            statusCode: 200,
            headers,
            body: JSON.stringify({
                userId: result.Item.userId,
                email: result.Item.email,
                summonerName: result.Item.summonerName || null,
                summonerPuuid: result.Item.summonerPuuid || null,
                region: result.Item.region || null,
                rank: result.Item.rank || 'Unranked',
                createdAt: result.Item.createdAt,
                updatedAt: result.Item.updatedAt
            })
        };

    } catch (error) {
        console.error('Error:', error);

        // Handle specific error types
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
