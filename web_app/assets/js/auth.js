/**
 * Summoner's Chronicle - Authentication JavaScript
 * Uses Cognito Hosted UI for OAuth authentication
 */

(function() {
    'use strict';

    // Cognito configuration will be injected from aws-config.js
    let cognitoConfig = null;
    let cognitoDomain = null;

    // Initialize on page load
    document.addEventListener('DOMContentLoaded', () => {
        if (typeof AWS_CONFIG === 'undefined') {
            showError('Configuration not loaded. Please refresh the page.');
            return;
        }

        // Build Cognito domain URL
        const accountId = AWS_CONFIG.cognito.userPoolId.split('_')[0];
        cognitoDomain = `https://summoners-chronicle-${AWS_CONFIG.app.environment}-${accountId}.auth.${AWS_CONFIG.region}.amazoncognito.com`;

        // Check if returning from OAuth callback
        handleOAuthCallback();
    });

    // Tab switching
    const authTabs = document.querySelectorAll('.auth-tab');
    const authForms = document.querySelectorAll('.auth-form-container');

    authTabs.forEach(tab => {
        tab.addEventListener('click', () => {
            const targetTab = tab.dataset.tab;

            // Update active states
            authTabs.forEach(t => t.classList.remove('active'));
            tab.classList.add('active');

            authForms.forEach(form => {
                form.classList.remove('active');
                if (form.id === `${targetTab}-form`) {
                    form.classList.add('active');
                }
            });
        });
    });

    // Email authentication - redirect to Cognito Hosted UI
    const emailAuthForm = document.getElementById('emailAuthForm');
    if (emailAuthForm) {
        emailAuthForm.addEventListener('submit', async (e) => {
            e.preventDefault();

            const email = document.getElementById('email').value;

            // Store email for later use
            sessionStorage.setItem('pendingEmail', email);

            // Redirect to Cognito Hosted UI
            redirectToCognitoHostedUI(email);
        });
    }

    function redirectToCognitoHostedUI(email = null) {
        if (!cognitoDomain) {
            showError('Authentication service not configured');
            return;
        }

        // Get current page URL for redirect
        const redirectUri = window.location.origin + window.location.pathname;

        // Build OAuth URL
        const authUrl = new URL(`${cognitoDomain}/oauth2/authorize`);
        authUrl.searchParams.append('client_id', AWS_CONFIG.cognito.clientId);
        authUrl.searchParams.append('response_type', 'code');
        authUrl.searchParams.append('scope', 'email openid profile');
        authUrl.searchParams.append('redirect_uri', redirectUri);

        if (email) {
            authUrl.searchParams.append('login_hint', email);
        }

        // Redirect to Cognito
        window.location.href = authUrl.toString();
    }

    // Handle OAuth callback
    async function handleOAuthCallback() {
        const urlParams = new URLSearchParams(window.location.search);
        const code = urlParams.get('code');
        const error = urlParams.get('error');

        if (error) {
            showError(`Authentication failed: ${error}`);
            return;
        }

        if (code) {
            // Show loading
            const authLoading = document.getElementById('authLoading');
            if (authLoading) {
                authLoading.style.display = 'block';
            }

            try {
                // Exchange code for tokens
                const tokens = await exchangeCodeForTokens(code);

                // Parse ID token to get user info
                const userInfo = parseJWT(tokens.id_token);

                // Store authentication info
                localStorage.setItem('authToken', tokens.access_token);
                localStorage.setItem('idToken', tokens.id_token);
                localStorage.setItem('refreshToken', tokens.refresh_token);
                localStorage.setItem('userId', userInfo.sub);
                localStorage.setItem('userEmail', userInfo.email);

                // Check if user needs to link summoner
                const summonerLinked = localStorage.getItem('summonerPuuid');

                if (summonerLinked) {
                    // Redirect to dashboard
                    window.location.href = 'dashboard.html';
                } else {
                    // Show setup form
                    document.querySelector('.auth-card').style.display = 'none';
                    document.getElementById('setupCard').style.display = 'block';
                }

            } catch (error) {
                console.error('OAuth callback error:', error);
                showError('Authentication failed. Please try again.');
            }
        }
    }

    async function exchangeCodeForTokens(code) {
        const redirectUri = window.location.origin + window.location.pathname;

        const response = await fetch(`${cognitoDomain}/oauth2/token`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/x-www-form-urlencoded'
            },
            body: new URLSearchParams({
                grant_type: 'authorization_code',
                client_id: AWS_CONFIG.cognito.clientId,
                code: code,
                redirect_uri: redirectUri
            })
        });

        if (!response.ok) {
            throw new Error('Failed to exchange authorization code');
        }

        return await response.json();
    }

    function parseJWT(token) {
        const base64Url = token.split('.')[1];
        const base64 = base64Url.replace(/-/g, '+').replace(/_/g, '/');
        const jsonPayload = decodeURIComponent(atob(base64).split('').map(function(c) {
            return '%' + ('00' + c.charCodeAt(0).toString(16)).slice(-2);
        }).join(''));

        return JSON.parse(jsonPayload);
    }

    // Access key authentication - simplified version
    const accessKeyForm = document.getElementById('accessKeyForm');
    if (accessKeyForm) {
        const fileInput = document.getElementById('accessKeyFile');
        const fileUploadArea = document.getElementById('fileUploadArea');
        const fileNameDisplay = document.getElementById('fileName');

        // Drag and drop handlers
        fileUploadArea.addEventListener('dragover', (e) => {
            e.preventDefault();
            fileUploadArea.style.borderColor = 'var(--gold-primary)';
        });

        fileUploadArea.addEventListener('dragleave', () => {
            fileUploadArea.style.borderColor = 'var(--glass-border)';
        });

        fileUploadArea.addEventListener('drop', (e) => {
            e.preventDefault();
            fileUploadArea.style.borderColor = 'var(--glass-border)';

            const files = e.dataTransfer.files;
            if (files.length > 0) {
                fileInput.files = files;
                handleFileSelect(files[0]);
            }
        });

        // File input change handler
        fileInput.addEventListener('change', (e) => {
            if (e.target.files.length > 0) {
                handleFileSelect(e.target.files[0]);
            }
        });

        function handleFileSelect(file) {
            if (file && file.name.endsWith('.sumvault')) {
                fileNameDisplay.textContent = `Selected: ${file.name}`;
                fileNameDisplay.style.display = 'block';
            } else {
                showError('Please select a valid .sumvault file');
            }
        }

        accessKeyForm.addEventListener('submit', async (e) => {
            e.preventDefault();

            const file = fileInput.files[0];
            if (!file) {
                showError('Please select an access key file');
                return;
            }

            const authLoading = document.getElementById('authLoading');
            const authError = document.getElementById('authError');
            const accesskeyForm = document.getElementById('accesskey-form');

            try {
                // Show loading state
                accesskeyForm.style.display = 'none';
                authLoading.style.display = 'block';
                authError.style.display = 'none';

                // Read access key file
                const accessKey = await readAccessKeyFile(file);

                // Validate and store credentials
                if (!accessKey.idToken || !accessKey.accessToken || !accessKey.email) {
                    throw new Error('Invalid access key format');
                }

                // Store authentication info
                localStorage.setItem('authToken', accessKey.accessToken);
                localStorage.setItem('idToken', accessKey.idToken);
                localStorage.setItem('userId', accessKey.userId);
                localStorage.setItem('userEmail', accessKey.email);

                if (accessKey.summonerPuuid) {
                    localStorage.setItem('summonerPuuid', accessKey.summonerPuuid);
                    localStorage.setItem('summonerName', accessKey.summonerName);
                    localStorage.setItem('region', accessKey.region);
                }

                // Redirect based on whether summoner is linked
                if (accessKey.summonerPuuid) {
                    window.location.href = 'dashboard.html';
                } else {
                    document.querySelector('.auth-card').style.display = 'none';
                    document.getElementById('setupCard').style.display = 'block';
                }

            } catch (error) {
                console.error('Access key authentication error:', error);

                // Show error message
                authLoading.style.display = 'none';
                authError.style.display = 'block';
                document.getElementById('errorMessage').textContent =
                    error.message || 'Invalid access key. Please try again.';
            }
        });
    }

    async function readAccessKeyFile(file) {
        return new Promise((resolve, reject) => {
            const reader = new FileReader();

            reader.onload = (e) => {
                try {
                    const accessKey = JSON.parse(e.target.result);
                    resolve(accessKey);
                } catch (error) {
                    reject(new Error('Failed to parse access key file'));
                }
            };

            reader.onerror = () => reject(new Error('Failed to read file'));
            reader.readAsText(file);
        });
    }

    // Summoner setup form
    const setupForm = document.getElementById('setupForm');
    if (setupForm) {
        setupForm.addEventListener('submit', async (e) => {
            e.preventDefault();

            const summonerName = document.getElementById('summonerName').value;
            const region = document.getElementById('region').value;

            try {
                // For now, just store the summoner info locally
                // In a full implementation, this would call the RiftSage API
                const summonerPuuid = generateTempPuuid();

                localStorage.setItem('summonerPuuid', summonerPuuid);
                localStorage.setItem('summonerName', summonerName);
                localStorage.setItem('region', region);

                // Redirect to dashboard
                window.location.href = 'dashboard.html';

            } catch (error) {
                console.error('Setup error:', error);
                showError(error.message || 'Failed to link account. Please try again.');
            }
        });
    }

    function generateTempPuuid() {
        // Generate a temporary PUUID for demo purposes
        return 'demo-' + Math.random().toString(36).substring(2, 15);
    }

    function showError(message) {
        const authError = document.getElementById('authError');
        const errorMessage = document.getElementById('errorMessage');

        if (authError && errorMessage) {
            errorMessage.textContent = message;
            authError.style.display = 'block';
        } else {
            alert(message);
        }
    }

    console.log('Authentication module initialized');
})();
