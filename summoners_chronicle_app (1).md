# Summoner's Chronicle Web App - Complete App Details Document

## Executive Summary

Summoner's Chronicle is the companion web application for RiftSage AI Agent, providing League of Legends players with their personalized end-of-year insights through an experience-focused interface. Built with a magazine-inspired design aesthetic, the app transforms data-driven analysis into an engaging adventure that players explore naturally, making reflection, learning, and improvement feel like an enjoyable journey rather than a statistical review.

---

## Product Overview

### Core Purpose
Deliver RiftSage-generated insights through an experience-driven interface that feels like an adventure to explore, helping players understand their true value, recognize growth opportunities, and celebrate achievements in a meaningful way.

### Value Proposition
- **Adventure Experience**: Navigation and exploration that feels natural and engaging without gamification
- **Data-Driven Insights**: Statistics paired with clear, actionable interpretations
- **Narrative Meaning**: Achievements framed as meaningful accomplishments, not fictional stories
- **Practical Growth Tools**: Blueprint planners with measurable improvement paths
- **Professional Polish**: Top-tier design quality matching global startup standards

### Target Audience
- **Primary**: League of Legends players (16-28 years old) who use RiftSage AI Agent
- **Device Usage**: 60% mobile, 40% desktop
- **Tech Savviness**: High digital literacy, expects modern UX patterns
- **Engagement Style**: Prefers clear insights and exploration over raw data tables

---

## Product Features & Capabilities

### 1. User Authentication & Profile Management

**Authentication System**
- **Primary Method**: Email-based magic link authentication
- **Flow**:
  1. User enters email address
  2. Receives time-limited magic link (valid 15 minutes)
  3. Clicks link to access account
  4. Unique access key token generated (custom .sumvault file format)
  5. Token stored locally for persistent sessions
- **Security Features**:
  - AWS Cognito for identity management
  - JWT tokens with 30-day expiration
  - Device fingerprinting for anomaly detection
  - Option to invalidate all sessions remotely

**Profile Setup**
- **Summoner Linking**:
  - Input summoner name and region selection
  - Real-time validation against Riot API
  - Multiple account linking support (up to 3 accounts)
  - Region-specific data handling (NA, EUW, KR, etc.)
- **Preference Configuration**:
  - Report delivery frequency (annual, quarterly, monthly)
  - Focus area selection (mechanics, teamplay, strategy)
  - Notification settings (email, in-app)
  - Privacy controls (public profile, leaderboard opt-in)

### 2. Main Chronicle Dashboard (Magazine-Style Navigation)

**Layout Structure**
- **Navigation Pills**: Horizontal pill navigation for major sections
  - Overview
  - Performance
  - Champions
  - Team Impact
  - Growth
  - Achievements
  - Future Goals
- **Main Content Area**: Magazine-style article layout with clear sections
- **Top Header**: App title and user's current rank/title
- **Seamless Transitions**: Smooth page transitions for adventure-like flow

**Visual Design (Magazine Experience Theme)**
- **Color Palette**:
  - Background: Dark gradient (Oxford Blue to Navy Blue)
  - Primary: Aquamarine (#7FFFD4)
  - Accent: Peach (#FFDAB9)
  - Gold highlights: #C89B3C (LoL brand)
  - Text primary: #F0E6D2
  - Text secondary: #9D7C57
- **Typography**:
  - Headers: Nunito (clean, modern sans-serif)
  - Body: Nunito (consistent readability)
  - Stats: Nunito Bold (clear emphasis)
- **Design Principles**:
  - No gradients (solid colors only)
  - Professional global startup aesthetic
  - Clean, spacious layouts
  - Clear hierarchy and breathing room

**Content Structure (Per Page)**
1. **Stats & Metrics Section**: Key numbers with one-line insights
2. **Deeper Insights Section**: Clear bullet points explaining patterns
3. **Narrative Meaning Section**: Brief statement of achievement and significance

**Interactive Elements**
- **Pill Navigation**:
  - Click pills to switch sections instantly
  - Active state clearly indicated
  - Smooth transitions between pages
- **Inline Data Exploration**:
  - Hover over statistics for detailed tooltips
  - Click metrics to expand context
  - Progress bars show completion and targets
  - Comparison displays (player vs. benchmarks)

### 3. Statistics & Visualization Pages

**Data Presentation Formats**

**Stat Cards (Primary Metric Display)**
- Clean rectangular cards with solid backgrounds
- Large numeric value with contextual label
- One-line insight below each stat
- Consistent spacing and alignment

**Chart Styles**
- **Progress Bars**: Horizontal bars with percentage labels
- **Performance Grids**: Grid layouts for champion/role data
- **Comparative Displays**: Side-by-side stat comparisons
- **Timeline Views**: Month-by-month progression

**Page Layout Pattern (Consistent Across All Pages)**

**Section 1: Stats & Metrics**
- 4-column grid of stat cards (responsive to 2-column, 1-column on mobile)
- Each card shows: Value, Label, One-line insight
- Clean, scannable layout

**Section 2: Deeper Insights**
- Bullet point format with clear structure
- Pattern explanations
- Performance analysis
- Key observations

**Section 3: Narrative Meaning**
- Brief paragraph format (3-5 sentences)
- States what the achievement is
- Explains what it means
- No fictional storytelling, just meaningful framing

### 4. Outstanding Games Showcase

**Feature Purpose**
Highlight the player's most impactful performances with clear data and meaning.

**Content Structure**
- **Stats & Metrics**: Top 10 games ranked by impact score
- **Deeper Insights**: What made each game special (bullet points)
- **Narrative Meaning**: Brief statement of why these games matter

**Game Cards** (each includes):
- Match date and champion played
- Final KDA and key statistics
- One-line summary of impact
- Expandable details on click

**Presentation Style**
- Grid layout with ranking indicators
- Clean card design with hover effects
- Sort and filter options
- Share buttons for individual games

### 5. Improvement Blueprint Planner

**Feature Purpose**
Convert RiftSage's recommendations into trackable, measurable goals.

**Blueprint Components**

**Goal Categories**
- **Mechanical Skills**: CS targets, combos, trading patterns
- **Strategic Knowledge**: Wave management, objective timing, macro decisions
- **Champion Mastery**: Pool expansion, matchup learning
- **Mental Game**: Tilt management, consistency building
- **Team Coordination**: Communication, role flexibility

**Task Structure (Per Goal)**
- Clear objective statement
- Success criteria (measurable outcomes)
- Recommended practice methods
- External resource links
- Estimated time investment
- Progress tracking checkbox

**Progress Tracking**
- Visual progress bars for each category
- Completion percentage calculations
- Milestone markers
- Weekly/monthly review prompts

**Resource Library Integration**
- Curated educational content
- Pro player VODs matching improvement areas
- Practice tool scenarios
- Champion-specific guides

### 6. Match History Explorer

**Feature Purpose**
Provide detailed access to every match analyzed by RiftSage.

**Match List View**
- Scrollable chronological list
- Color-coded by outcome
- Quick stats summary per match
- Filter and search capabilities

**Individual Match Detail View**
- Full post-game statistics
- Performance grade based on role benchmarks
- Key moment highlights
- Comparison to personal averages
- RiftSage analysis commentary

**Analysis Tools**
- Match comparison (side-by-side)
- Streak analysis
- Champion performance trends
- Role performance breakdown

### 7. Peer Comparison & Leaderboards

**Anonymous Benchmarking**
- Percentile rankings for each metric
- Rank tier comparisons
- Strength/weakness identification
- Opt-in only participation

**Leaderboards (Opt-In)**
- Public boards for specific achievements
- Friend circle private rankings
- Achievement showcases
- Climbing progress trackers

**Privacy Controls**
- Toggle public profile visibility
- Choose which stats display publicly
- Opt out of leaderboards entirely
- Anonymous comparative viewing

### 8. Social Sharing & Community Features

**Shareable Assets**
- Achievement cards with key stats
- Performance highlights
- Stat comparison images
- Quote graphics from insights

**Sharing Platforms**
- Direct Twitter/X integration
- Discord webhook support
- Reddit-friendly formats
- Instagram story templates

### 9. Report Download & Export

**PDF Report**
- Full chronicle in formatted PDF
- Print-optimized layout
- Embedded charts and visualizations
- Bookmarked navigation

**Data Export Options**
- CSV export of all metrics
- JSON format for developers
- Excel-compatible workbook
- Third-party tool integration

### 10. Settings & Customization

**Visual Preferences**
- **Theme Toggle**: Light mode or dark mode
- **Font Size**: Adjustable for accessibility
- **Animation Settings**: Reduce motion option
- **Language**: Multi-language support

**Data Preferences**
- Report generation frequency
- Metric focus areas
- Notification settings
- Privacy controls

**Account Management**
- Update linked accounts
- Change email address
- Manage connected devices
- Download personal data
- Request account deletion

---

## Page List & Navigation Structure

### Primary Pages

1. **Landing/Welcome Page**
   - Hero section with app introduction
   - Value proposition highlights
   - "Link Your Summoner" CTA
   - Sample preview

2. **Authentication Page**
   - Email input form
   - Magic link confirmation
   - Access key upload area
   - Help section

3. **Profile Setup Page**
   - Summoner name and region input
   - Account verification
   - Preference wizard
   - Initial report trigger

4. **Overview Page**
   - Season overview stats
   - Key milestones list
   - Overall performance narrative

5. **Performance Page**
   - Performance metrics grid
   - Role performance breakdown
   - Key insights and patterns

6. **Champions Page**
   - Most played champions grid
   - Champion performance analysis
   - Mastery insights

7. **Team Impact Page**
   - Team statistics overview
   - Leadership metrics
   - Teamplay insights

8. **Growth Page**
   - Skill development tracking
   - Growth milestones
   - Key learnings summary

9. **Achievements Page**
   - Major achievements showcase
   - Badge collection
   - Special recognition

10. **Future Goals Page**
    - Short-term objectives
    - Quarterly milestones
    - Long-term vision

11. **Match History Page**
    - Filterable match list
    - Individual match details
    - Comparison tools

12. **Leaderboards Page** (Opt-In)
    - Public leaderboards
    - Friend rankings
    - Achievement showcases

13. **Settings Page**
    - Visual preferences
    - Data preferences
    - Account management
    - Privacy controls

14. **Help & Support Page**
    - FAQ section
    - Tutorial videos
    - Contact form
    - Community links

---

## Menu Structure

### Top Navigation Bar
- **Logo/Home**: Return to overview
- **Navigation Pills**: Major sections (Overview, Performance, Champions, etc.)
- **Profile Icon** (Dropdown):
  - View Profile
  - Settings
  - Help
  - Logout

### Footer Links
- About RiftSage
- Terms of Service
- Privacy Policy
- Community Guidelines
- Contact Support
- Social Media Links

---

## Page Content Layout (Standard Pattern)

### Universal Page Structure

**Article Header**
- Page title (large, clear)
- Subtitle (context or tagline)
- Centered, prominent placement

**Section 1: Stats & Metrics**
- Grid layout (4-column → 2-column → 1-column responsive)
- Stat cards showing:
  - Primary value (large)
  - Metric label
  - One-line insight
- Clean spacing, easy scanning

**Section 2: Deeper Insights**
- Bullet point format
- Clear subheadings
- Pattern explanations
- Performance breakdown
- Key observations

**Section 3: Narrative Meaning**
- Brief prose (3-5 sentences)
- States the achievement clearly
- Explains significance
- No fictional elements, just meaningful context

### Example: Performance Page Layout

**Stats & Metrics Section**
```
[Stat Card: 3.8 KDA | Average KDA | 71% improvement from last year]
[Stat Card: 7.2 | Kills per Game | Aggressive playstyle mastery]
[Stat Card: 6.8 | Assists per Game | Team-focused approach]
[Stat Card: 15.3 | CS per Minute | Farming efficiency mastery]
```

**Deeper Insights Section**
- Pattern: Low deaths enable repeated plays
- High kills + assists flow from positioning and timing
- Teamfights are your strength zone
- CS and vision expand this foundation

**Narrative Meaning Section**
"Your 3.8 KDA and 7.2 kills per game demonstrate mastery of aggressive positioning while maintaining survival. This balance between impact and safety has been crucial to your 65% win rate in ADC. The combination turns teamfights into consistent advantages, proving your ability to execute under pressure while supporting your team's objectives."

---

## Visual Design System

### Color Palette (Oxford Blue + Aquamarine + Peach)

**Primary Colors**
- Oxford Blue: #14213D (background base)
- Navy Blue Dark: #0A1421 (darker backgrounds)
- Aquamarine: #7FFFD4 (primary accent)
- Peach: #FFDAB9 (secondary accent)
- LoL Gold: #C89B3C (highlights)

**Text Colors**
- Primary: #F0E6D2
- Secondary: #9D7C57
- Muted: #6B6B6B

**UI Colors**
- Card Background: #1E2328
- Border: Aquamarine with opacity
- Success: #27AE60
- Warning: #F39C12
- Error: #DC2626

### Typography Scale (Nunito)
- **H1** (Page Titles): Nunito Bold, 3rem
- **H2** (Section Headers): Nunito SemiBold, 2rem
- **H3** (Subsections): Nunito SemiBold, 1.5rem
- **H4** (Card Titles): Nunito SemiBold, 1.3rem
- **Body Text**: Nunito Regular, 1.1rem
- **Stats/Data**: Nunito Bold, varies
- **Captions**: Nunito Regular, 0.9rem

### Spacing System (8px base unit)
- **XS**: 8px
- **S**: 16px
- **M**: 24px
- **L**: 32px
- **XL**: 48px
- **XXL**: 64px

### Border Radius
- **Small**: 8px
- **Medium**: 12px
- **Large**: 20px
- **Pills**: 50px

### Solid Color Design
- No gradients used anywhere
- Clean, flat color blocks
- Opacity variations for depth
- Consistent color application

---

## Technical Specifications

### Frontend Stack
- **HTML5**: Semantic markup with accessibility
- **CSS3**: Custom properties, Grid, Flexbox
- **Vanilla JavaScript**: ES6+, modular architecture
- **Chart Library**: Chart.js via CDN (if needed)
- **Icons**: Font Awesome (free tier)

### Backend Integration
- **AWS Amplify**: Hosting and CI/CD
- **API Gateway**: RESTful endpoints
- **Authentication**: AWS Cognito
- **Storage**: S3 for reports, CloudFront CDN

### API Endpoints
- `POST /auth/magic-link`
- `POST /auth/verify`
- `POST /summoner/link`
- `GET /report/{playerId}`
- `GET /matches/{playerId}`
- `PUT /blueprint/{playerId}`
- `GET /leaderboards`
- `POST /share`

### Performance Requirements
- Page load time: < 2 seconds on 4G
- Time to interactive: < 3 seconds
- Lighthouse score: > 90 across all metrics
- Mobile responsive: 320px to 2560px

### Browser Support
- Chrome/Edge (last 2 versions)
- Firefox (last 2 versions)
- Safari (last 2 versions)
- Mobile browsers

### Accessibility Compliance
- WCAG 2.1 Level AA
- Keyboard navigation
- Screen reader optimization
- 4.5:1 contrast ratios
- Alt text for images
- Focus indicators

---

## User Flows

### First-Time User Flow
1. Land on welcome page
2. Click "Get Started"
3. Enter email address
4. Receive and click magic link
5. Download/save .sumvault access key
6. Enter summoner name and region
7. Validate summoner account
8. Configure preferences
9. Trigger report generation (2-5 minutes)
10. Explore overview page
11. Navigate through sections via pills

### Returning User Flow
1. Land on login page
2. Enter email or upload .sumvault key
3. Automatic authentication
4. Redirect to overview
5. See "New Insights" if applicable
6. Continue exploration

### Goal Tracking Flow
1. Navigate to Future Goals page
2. Review recommended objectives
3. Check off completed tasks
4. See progress bar update
5. Receive milestone notification
6. Add reflection notes
7. Access linked resources

### Social Sharing Flow
1. Find shareable moment
2. Click share icon
3. Select platform
4. Preview generated content
5. Customize message (optional)
6. Confirm and post
7. Track engagement (optional)

---

## Success Metrics

### User Engagement
- Average session duration > 15 minutes
- Page completion rate > 70%
- Return visit rate (30 days) > 50%
- Blueprint interaction rate > 60%

### Feature Adoption
- Performance page views > 90%
- Blueprint page interactions > 60%
- Social share actions > 25%
- Report download rate > 70%

### Technical Performance
- Page load time < 2 seconds (median)
- Bounce rate < 30%
- Mobile optimization > 90% Lighthouse
- Zero critical accessibility violations

### User Satisfaction
- NPS > 50
- Feature usefulness > 4.2/5.0
- Design appeal > 4.5/5.0
- Recommendation likelihood > 75%

---

## App Name Options

1. **Summoner's Chronicle** ⭐ (Selected)
2. Rift Reflections
3. Season Stories
4. League Ledger
5. Nexus Notes
6. Valor Vault
7. Champion's Chronicle

---

## Deployment Guide

### Google Cloud Shell Deployment
1. Clone repository to Cloud Shell
2. Install dependencies: `npm install`
3. Configure environment variables
4. Build static files: `npm run build`
5. Deploy to Cloud Run or App Engine

### Local Development
1. Clone repository
2. Install Node.js dependencies
3. Run development server: `npm run dev`
4. Access at localhost:3000

### Hosting Options

**Cloud Hosting (Recommended)**
- AWS Amplify (integrated with backend)
- Vercel (free tier available)
- Netlify (free tier available)

**VPS Hosting**
- DigitalOcean Droplet
- Linode
- Vultr

**Shared Hosting**
- Upload static files to public_html
- Configure .htaccess for routing

---

## Conclusion

Summoner's Chronicle transforms RiftSage's analytical power into an experience that feels like an adventure to explore. Through magazine-inspired design, clear data presentation, and meaningful insights, players don't just see statistics—they understand their journey, celebrate their growth, and chart their path forward with clarity and motivation.