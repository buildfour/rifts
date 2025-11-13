/**
 * AWS Configuration for Summoner's Chronicle
 * This file will be automatically populated during deployment
 * DO NOT commit actual credentials to version control
 */

const AWS_CONFIG = {
    // AWS Region
    region: 'REGION_PLACEHOLDER',

    // AWS Cognito Configuration
    cognito: {
        userPoolId: 'USER_POOL_ID_PLACEHOLDER',
        clientId: 'CLIENT_ID_PLACEHOLDER',
        identityPoolId: 'IDENTITY_POOL_ID_PLACEHOLDER',
        domain: 'COGNITO_DOMAIN_PLACEHOLDER'
    },

    // API Gateway Endpoint
    apiEndpoint: 'API_ENDPOINT_PLACEHOLDER',

    // S3 Bucket for Reports
    reportsBucket: 'REPORTS_BUCKET_PLACEHOLDER',

    // CloudFront Distribution (if used)
    cloudFrontDomain: 'CLOUDFRONT_DOMAIN_PLACEHOLDER',

    // Application Settings
    app: {
        name: 'Summoner\'s Chronicle',
        version: '1.0.0',
        environment: 'ENVIRONMENT_PLACEHOLDER'
    }
};

// Freeze config to prevent modifications
Object.freeze(AWS_CONFIG);

console.log('AWS Configuration loaded:', AWS_CONFIG.app.environment);
