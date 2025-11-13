/**
 * Lambda Function: Get Report Data
 * Endpoint: GET /report/{puuid}
 * Query params: year (optional, defaults to current year)
 *
 * Returns aggregated report data for a summoner
 * NOTE: This currently returns mock data. In production, this should call RiftSage Lambda
 */

const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const { DynamoDBDocumentClient, GetCommand } = require('@aws-sdk/lib-dynamodb');
const { LambdaClient, InvokeCommand } = require('@aws-sdk/client-lambda');

const dynamoClient = new DynamoDBClient({});
const docClient = DynamoDBDocumentClient.from(dynamoClient);
const lambdaClient = new LambdaClient({});

const USERS_TABLE = process.env.USERS_TABLE_NAME;
const RIFTSAGE_FUNCTION_NAME = process.env.RIFTSAGE_FUNCTION_NAME;

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
 * Generate mock report data
 * TODO: Replace with actual RiftSage Lambda invocation
 */
function generateMockReportData(puuid, year) {
    return {
        puuid,
        year,
        generated: new Date().toISOString(),
        overview: {
            totalGames: 247,
            winRate: 54.3,
            avgKDA: 3.12,
            mainRole: 'Mid Lane',
            insights: [
                'Your win rate increased by 8% compared to last season',
                'You\'ve played 15 different champions this year',
                'Your KDA improved significantly in the last 3 months'
            ],
            narrative: 'This year has been a journey of growth and adaptation. Your performance shows consistent improvement, particularly in mid-lane matchups.'
        },
        performance: {
            avgKills: 7.2,
            avgAssists: 8.5,
            avgDeaths: 5.1,
            csPerMinute: 7.8,
            visionScore: 32.4,
            damagePerMinute: 892,
            insights: [
                'Your CS/min is above average for your rank',
                'Consider improving vision control in mid-late game',
                'High damage output in teamfights'
            ],
            narrative: 'Your mechanical skills are solid with impressive damage output. Focus on maintaining farm in difficult matchups.'
        },
        champions: {
            topChampions: [
                {
                    name: 'Ahri',
                    role: 'Mid',
                    gamesPlayed: 42,
                    winRate: 61.9,
                    kda: 3.8,
                    csPerMin: 8.2,
                    damagePerMin: 1024,
                    visionScore: 28.5,
                    description: 'Your signature champion with excellent win rate'
                },
                {
                    name: 'Syndra',
                    role: 'Mid',
                    gamesPlayed: 35,
                    winRate: 54.3,
                    kda: 3.2,
                    csPerMin: 7.9,
                    damagePerMin: 987,
                    visionScore: 31.2,
                    description: 'Strong secondary pick with good laning phase'
                },
                {
                    name: 'Orianna',
                    role: 'Mid',
                    gamesPlayed: 28,
                    winRate: 50.0,
                    kda: 2.9,
                    csPerMin: 8.1,
                    damagePerMin: 876,
                    visionScore: 34.7,
                    description: 'Reliable team-fight presence'
                }
            ],
            insights: [
                'Ahri is your most successful champion',
                'Your champion pool is well-rounded',
                'Consider adding more late-game scalers'
            ],
            narrative: 'You\'ve mastered mobile mages with excellent positioning and roaming patterns.'
        },
        teamImpact: {
            killParticipation: 68.5,
            objectiveControl: 72.3,
            teamfightPresence: 81.2,
            supportRating: 7.8,
            insights: [
                'Excellent teamfight participation',
                'Strong objective control',
                'Good at setting up plays for teammates'
            ],
            narrative: 'You\'re a valuable team player who consistently shows up for important fights and objectives.'
        },
        growth: {
            kdaImprovement: 12.5,
            rankProgress: 'Gold III → Gold I',
            newChampions: 8,
            consistency: 76,
            insights: [
                'Significant improvement in KDA',
                'Climbed 2 divisions this season',
                'Expanded champion pool effectively'
            ],
            narrative: 'Your dedication to improvement is evident. The climb from Gold III shows real progress.'
        },
        achievements: {
            list: [
                {
                    name: 'Pentakill Master',
                    description: 'Achieved 3 pentakills this season',
                    icon: 'fas fa-trophy',
                    rarity: 'legendary',
                    date: '2025-09-15'
                },
                {
                    name: 'Climb Champion',
                    description: 'Climbed 2 divisions in one season',
                    icon: 'fas fa-mountain',
                    rarity: 'epic',
                    date: '2025-10-01'
                },
                {
                    name: 'Versatile Player',
                    description: 'Played 15+ different champions',
                    icon: 'fas fa-star',
                    rarity: 'rare',
                    date: '2025-08-20'
                }
            ],
            topGames: [
                {
                    champion: 'Ahri',
                    role: 'Mid',
                    kills: 18,
                    deaths: 2,
                    assists: 12,
                    kda: 15.0,
                    duration: '34:22',
                    result: 'victory',
                    grade: 'S+'
                },
                {
                    champion: 'Syndra',
                    role: 'Mid',
                    kills: 12,
                    deaths: 3,
                    assists: 15,
                    kda: 9.0,
                    duration: '41:18',
                    result: 'victory',
                    grade: 'S'
                }
            ],
            narrative: 'Your achievements showcase dedication and skill progression throughout the season.'
        },
        futureGoals: {
            mechanical: [
                {
                    title: 'Improve Last-Hitting',
                    description: 'Achieve consistent 8+ CS/min in all matchups',
                    priority: 'High',
                    progress: 65,
                    actions: [
                        { text: 'Practice CS drills in Practice Tool', completed: true },
                        { text: 'Focus on CS under tower', completed: false },
                        { text: 'Review VODs for missed CS opportunities', completed: false }
                    ]
                }
            ],
            strategy: [
                {
                    title: 'Wave Management',
                    description: 'Master freeze, slow push, and fast push techniques',
                    priority: 'High',
                    progress: 45,
                    actions: [
                        { text: 'Watch wave management guides', completed: true },
                        { text: 'Practice in custom games', completed: false },
                        { text: 'Apply in ranked games', completed: false }
                    ]
                }
            ],
            champion: [
                {
                    title: 'Master Assassins',
                    description: 'Add 2 assassin champions to champion pool',
                    priority: 'Medium',
                    progress: 30,
                    actions: [
                        { text: 'Learn Zed basics', completed: false },
                        { text: 'Learn LeBlanc combos', completed: false },
                        { text: 'Play 20 games on each', completed: false }
                    ]
                }
            ],
            mental: [
                {
                    title: 'Tilt Management',
                    description: 'Maintain positive mindset through losses',
                    priority: 'High',
                    progress: 70,
                    actions: [
                        { text: 'Take breaks between losses', completed: true },
                        { text: 'Focus on personal improvement', completed: true },
                        { text: 'Mute toxic players immediately', completed: false }
                    ]
                }
            ],
            team: [
                {
                    title: 'Roaming Efficiency',
                    description: 'Improve roam timing and success rate',
                    priority: 'Medium',
                    progress: 55,
                    actions: [
                        { text: 'Track enemy jungle position', completed: true },
                        { text: 'Communicate roam plans', completed: false },
                        { text: 'Ward before roaming', completed: true }
                    ]
                }
            ],
            narrative: 'These personalized goals will help you reach Platinum and beyond. Focus on one area at a time for best results.'
        }
    };
}

/**
 * Main Lambda handler
 */
exports.handler = async (event) {
    console.log('Event:', JSON.stringify(event, null, 2));

    const headers = {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers': 'Content-Type,Authorization',
        'Access-Control-Allow-Methods': 'GET,OPTIONS'
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

        // Get PUUID from path
        const puuid = event.pathParameters?.puuid;
        if (!puuid) {
            return {
                statusCode: 400,
                headers,
                body: JSON.stringify({ error: 'Missing puuid parameter' })
            };
        }

        // Get year from query string
        const year = event.queryStringParameters?.year || new Date().getFullYear().toString();

        // Verify user owns this summoner
        const userResult = await docClient.send(new GetCommand({
            TableName: USERS_TABLE,
            Key: { userId }
        }));

        if (!userResult.Item || userResult.Item.summonerPuuid !== puuid) {
            return {
                statusCode: 403,
                headers,
                body: JSON.stringify({ error: 'Access denied to this summoner data' })
            };
        }

        // TODO: Call RiftSage Lambda function to get real data
        // For now, return mock data
        const reportData = generateMockReportData(puuid, year);

        return {
            statusCode: 200,
            headers,
            body: JSON.stringify(reportData)
        };

    } catch (error) {
        console.error('Error:', error);

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
