# Summoner's Chronicle - AWS Compatibility Issues

**Document Created:** 2025-11-13
**Status:** Comprehensive audit of web app code for AWS compatibility issues

## Executive Summary

The Summoner's Chronicle web application has multiple critical compatibility issues with AWS services. The primary issues stem from the frontend calling **non-existent backend API endpoints** and relying on the RiftSage AI backend that is not integrated with the web app.

---

## Critical Issues (Blocks Core Functionality)

### 1. **Non-Existent Backend API Endpoints**

**Location:** `assets/js/dashboard.js`
**Lines:** 39, 65, 435
**Severity:** CRITICAL

The dashboard makes API calls to endpoints that don't exist:

```javascript
// Line 39-43: User profile endpoint
const response = await fetch(`${AWS_CONFIG.apiEndpoint}/user/profile`, {
    headers: {
        'Authorization': `Bearer ${authToken}`
    }
});

// Line 64-71: Report data endpoint
const response = await fetch(
    `${AWS_CONFIG.apiEndpoint}/report/${summonerPuuid}?year=${new Date().getFullYear()}`,
    {
        headers: {
            'Authorization': `Bearer ${authToken}`
        }
    }
);

// Line 434-441: Download report endpoint
const response = await fetch(
    `${AWS_CONFIG.apiEndpoint}/report/${summonerPuuid}/download?format=pdf`,
    {
        headers: {
            'Authorization': `Bearer ${authToken}`
        }
    }
);
```

**Impact:**
- Dashboard will fail to load any data
- Users will see "Failed to load user data" and "Failed to load report data" errors
- Download report button will not work

**Root Cause:**
- The web app assumes a REST API exists at `AWS_CONFIG.apiEndpoint`
- RiftSage AI backend is not exposed via API Gateway
- No Lambda functions are configured to handle these HTTP requests

---

### 2. **Summoner Account Linking Not Implemented**

**Location:** `assets/js/auth.js`
**Lines:** 298-324
**Severity:** CRITICAL

The summoner setup form does NOT call any AWS service to link the account:

```javascript
// Lines 308-317
// For now, just store the summoner info locally
// In a full implementation, this would call the RiftSage API
const summonerPuuid = generateTempPuuid();

localStorage.setItem('summonerPuuid', summonerPuuid);
localStorage.setItem('summonerName', summonerName);
localStorage.setItem('region', region);

// Redirect to dashboard
window.location.href = 'dashboard.html';
```

**Impact:**
- Summoner account is not actually linked to RiftSage
- Generates fake PUUID (`demo-xyz123`)
- No actual Riot API validation
- No data will be collected for this summoner

**Root Cause:**
- Missing integration with RiftSage summoner linking functionality
- No API endpoint to validate summoner name and get real PUUID
- No DynamoDB user-summoner mapping

---

### 3. **Access Key File (.sumvault) Format Undefined**

**Location:** `assets/js/auth.js`
**Lines:** 177-296
**Severity:** HIGH

The access key authentication expects a `.sumvault` file with specific fields:

```javascript
// Lines 244-246
if (!accessKey.idToken || !accessKey.accessToken || !accessKey.email) {
    throw new Error('Invalid access key format');
}

// Lines 248-258
localStorage.setItem('authToken', accessKey.accessToken);
localStorage.setItem('idToken', accessKey.idToken);
localStorage.setItem('userId', accessKey.userId);
localStorage.setItem('userEmail', accessKey.email);

if (accessKey.summonerPuuid) {
    localStorage.setItem('summonerPuuid', accessKey.summonerPuuid);
    localStorage.setItem('summonerName', accessKey.summonerName);
    localStorage.setItem('region', accessKey.region);
}
```

**Impact:**
- No system exists to generate `.sumvault` files
- Users cannot use this authentication method
- Feature is non-functional

**Root Cause:**
- No backend endpoint to generate access key files
- No specification for `.sumvault` file format
- No Lambda function to create and sign these files

---

### 4. **Cognito Token Validation Missing**

**Location:** `assets/js/dashboard.js`
**Lines:** 14-19, 36-43
**Severity:** HIGH

The dashboard only checks if `authToken` exists in localStorage but doesn't validate it:

```javascript
// Lines 14-19
const authToken = localStorage.getItem('authToken');
if (!authToken) {
    window.location.href = 'auth.html';
    return;
}

// Lines 36-43
const authToken = localStorage.getItem('authToken');
const response = await fetch(`${AWS_CONFIG.apiEndpoint}/user/profile`, {
    headers: {
        'Authorization': `Bearer ${authToken}`
    }
});
```

**Impact:**
- Expired tokens are not detected client-side
- No token refresh logic
- User will see errors instead of being redirected to login

**Root Cause:**
- No JWT validation on client side
- No token expiration checking
- No refresh token flow implemented

---

## High Priority Issues (Degrades User Experience)

### 5. **No Error Handling for AWS Service Failures**

**Location:** `assets/js/dashboard.js`
**Lines:** Various throughout file
**Severity:** HIGH

All AWS API calls have minimal error handling:

```javascript
// Lines 22-34
try {
    await loadUserData();
    await loadReportData();
    setupNavigation();
    setupActions();
} catch (error) {
    console.error('Dashboard initialization error:', error);
    if (error.message === 'Unauthorized') {
        localStorage.clear();
        window.location.href = 'auth.html';
    }
}
```

**Impact:**
- Generic error messages shown to users
- No retry logic for transient failures
- No loading states for slow requests
- Poor user experience during network issues

---

### 6. **CORS Configuration Not Specified**

**Location:** N/A (Infrastructure issue)
**Severity:** HIGH

**Impact:**
- API calls from CloudFront domain to API Gateway may be blocked by CORS
- Browser will show CORS errors in console
- API requests will fail

**Root Cause:**
- No API Gateway CORS configuration in CloudFormation
- No CORS headers in Lambda responses
- RiftSage backend not configured for web app domain

---

### 7. **No API Gateway Integration**

**Location:** CloudFormation templates
**Severity:** CRITICAL

**Impact:**
- RiftSage Lambda functions are not exposed via HTTP
- No REST API for web app to call
- All dashboard functionality is broken

**Root Cause:**
- CloudFormation template creates Cognito only
- No API Gateway resources defined
- No Lambda function HTTP triggers

---

## Medium Priority Issues (Feature Gaps)

### 8. **Settings Button Has No Implementation**

**Location:** `assets/js/dashboard.js`
**Lines:** 123-127
**Severity:** MEDIUM

```javascript
// Settings button
document.getElementById('settingsBtn').addEventListener('click', () => {
    // TODO: Implement settings modal
    console.log('Settings clicked');
});
```

**Impact:**
- Settings button does nothing
- Users cannot change preferences
- No account management

---

### 9. **Share Report Only Uses Browser API**

**Location:** `assets/js/dashboard.js`
**Lines:** 463-480
**Severity:** MEDIUM

```javascript
// TODO: Implement sharing functionality
const shareData = {
    title: 'My Summoner\'s Chronicle',
    text: 'Check out my League of Legends performance insights!',
    url: window.location.href
};

if (navigator.share) {
    navigator.share(shareData).catch(err => console.error('Share error:', err));
} else {
    // Fallback: copy link
    navigator.clipboard.writeText(window.location.href).then(() => {
        alert('Link copied to clipboard!');
    });
}
```

**Impact:**
- Shares current page URL, not a shareable report
- No social media integration
- No image preview generation

---

### 10. **No Offline Support / Service Worker**

**Location:** N/A (Not implemented)
**Severity:** MEDIUM

**Impact:**
- Web app requires internet connection
- No cached data for offline viewing
- Poor experience on slow connections

---

## Low Priority Issues (Nice to Have)

### 11. **No Analytics / Monitoring**

**Location:** N/A (Not implemented)
**Severity:** LOW

**Impact:**
- No user behavior tracking
- No error monitoring
- Can't measure feature usage
- Can't detect production issues

**Suggested Solution:**
- Add AWS CloudWatch RUM (Real User Monitoring)
- Add custom CloudWatch metrics for API calls
- Add error logging to CloudWatch Logs

---

### 12. **No Rate Limiting on Client Side**

**Location:** `assets/js/dashboard.js`
**Severity:** LOW

**Impact:**
- Users can spam API requests
- Could trigger AWS throttling
- Increased costs

---

### 13. **Hardcoded Placeholder API Endpoint**

**Location:** `config/aws-config.js`
**Line:** 206
**Severity:** LOW (informational)

```javascript
// API Gateway Endpoint (RiftSage API)
apiEndpoint: 'https://api.example.com',  // Update this if you have RiftSage API deployed
```

**Impact:**
- All API calls will fail with DNS errors
- Must be updated during deployment

---

## Infrastructure Issues

### 14. **Missing API Gateway in CloudFormation**

**Location:** `cloudformation-template.yaml`
**Severity:** CRITICAL

The CloudFormation template only creates:
- Cognito User Pool
- Cognito User Pool Client
- Cognito Identity Pool
- IAM Roles

**Missing:**
- API Gateway REST API
- API Gateway Resources and Methods
- Lambda function integrations
- CORS configuration
- API Gateway deployment and stage

---

### 15. **No Lambda Functions for Web App Endpoints**

**Location:** N/A (Not implemented)
**Severity:** CRITICAL

Required Lambda functions that don't exist:
1. `GET /user/profile` - Get user profile data
2. `GET /report/{puuid}` - Get report data for summoner
3. `POST /report/{puuid}/download` - Generate PDF report
4. `POST /summoner/link` - Link summoner account to user
5. `POST /summoner/validate` - Validate summoner exists in Riot API
6. `POST /auth/token/refresh` - Refresh expired tokens
7. `POST /user/settings` - Update user settings

---

### 16. **No S3 Bucket for Report PDFs**

**Location:** N/A (Not implemented)
**Severity:** MEDIUM

**Impact:**
- Cannot store generated PDF reports
- Download report feature won't work

**Required:**
- S3 bucket for report storage
- Lambda with S3 write permissions
- Pre-signed URL generation for downloads

---

### 17. **No DynamoDB Table for User-Summoner Mapping**

**Location:** N/A (Not implemented)
**Severity:** CRITICAL

**Impact:**
- Cannot link Cognito users to summoner PUUIDs
- Cannot track which users have linked accounts
- No user profile data storage

**Required:**
- DynamoDB table: `users` with schema:
  ```
  userId (PK) | email | summonerPuuid | summonerName | region | createdAt
  ```

---

### 18. **No CloudWatch Logs Configuration**

**Location:** CloudFormation
**Severity:** LOW

**Impact:**
- Cannot debug API errors
- No audit trail
- Cannot monitor application health

---

## Authentication Issues

### 19. **Token Storage in localStorage (Security Concern)**

**Location:** `assets/js/auth.js`
**Lines:** 119-123, 249-252
**Severity:** MEDIUM (Security)

```javascript
localStorage.setItem('authToken', tokens.access_token);
localStorage.setItem('idToken', tokens.id_token);
localStorage.setItem('refreshToken', tokens.refresh_token);
localStorage.setItem('userId', userInfo.sub);
localStorage.setItem('userEmail', userInfo.email);
```

**Impact:**
- Tokens are vulnerable to XSS attacks
- Tokens persist across browser sessions
- No automatic token cleanup

**Better Practice:**
- Use httpOnly cookies for tokens
- Or use sessionStorage for session-only storage
- Implement token cleanup on logout

---

### 20. **No Token Refresh Logic**

**Location:** N/A (Not implemented)
**Severity:** HIGH

**Impact:**
- Access tokens expire after 1 hour
- Users get logged out after 1 hour
- Must re-authenticate every hour

**Required:**
- Implement token refresh flow using refresh tokens
- Automatically refresh tokens before expiration
- Handle refresh token expiration gracefully

---

## Summary by Severity

| Severity | Count | Issues |
|----------|-------|--------|
| CRITICAL | 6 | #1, #2, #7, #14, #15, #17 |
| HIGH | 4 | #3, #4, #5, #6, #20 |
| MEDIUM | 4 | #8, #9, #10, #16, #19 |
| LOW | 3 | #11, #12, #13, #18 |

---

## Recommended Action Plan

### Phase 1: Make Dashboard Functional (Critical Path)
1. Create API Gateway with REST API
2. Create Lambda functions for core endpoints:
   - `/user/profile`
   - `/report/{puuid}`
   - `/summoner/link`
3. Update CloudFormation to include API Gateway
4. Configure CORS properly
5. Deploy and test basic data flow

### Phase 2: Fix Authentication
1. Implement real summoner linking with Riot API
2. Add token refresh logic
3. Fix access key file generation
4. Improve error handling

### Phase 3: Additional Features
1. Implement PDF report generation
2. Add settings functionality
3. Implement proper sharing with preview
4. Add analytics and monitoring

---

## Files Requiring Updates

### Frontend (JavaScript)
- `assets/js/dashboard.js` - Add error handling, loading states, token refresh
- `assets/js/auth.js` - Implement real summoner linking, token refresh
- `config/aws-config.js` - Update with actual API endpoint

### Infrastructure (CloudFormation)
- `cloudformation-template.yaml` - Add API Gateway, Lambda integrations, DynamoDB tables

### Backend (Lambda Functions - TO BE CREATED)
- `lambda/user-profile.js` - Get user profile
- `lambda/get-report.js` - Get report data
- `lambda/link-summoner.js` - Link summoner account
- `lambda/generate-pdf.js` - Generate report PDF
- `lambda/refresh-token.js` - Refresh auth tokens

---

## Conclusion

The Summoner's Chronicle web application has a well-designed frontend with excellent UI/UX, but **lacks critical backend infrastructure**. The main blocker is that the RiftSage AI backend is not exposed via API Gateway, and the web app cannot communicate with it.

**Immediate Priority:** Create API Gateway and Lambda function wrappers to expose RiftSage functionality to the web app.

Without these changes, the web app is essentially a **non-functional prototype** - it looks great but cannot load or display any real data.
