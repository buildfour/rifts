# Summoner's Chronicle

**Your Personalized League of Legends Journey**

Summoner's Chronicle is the companion web application for RiftSage AI Agent, providing League of Legends players with their personalized end-of-year insights through an experience-focused interface. Built with a magazine-inspired design aesthetic, the app transforms data-driven analysis into an engaging adventure.

![Version](https://img.shields.io/badge/version-1.0.0-blue.svg)
![License](https://img.shields.io/badge/license-MIT-green.svg)
![AWS](https://img.shields.io/badge/AWS-Amplify-orange.svg)

---

## Table of Contents

- [Features](#features)
- [Quick Start](#quick-start)
- [Technology Stack](#technology-stack)
- [Project Structure](#project-structure)
- [Development](#development)
- [Deployment](#deployment)
- [Documentation](#documentation)
- [License](#license)

---

## Features

### Core Capabilities

- **📊 Dashboard Overview** - Season statistics, win rate, ranks climbed, LP gained
- **📈 Performance Analytics** - KDA, kills/assists per game, CS per minute, role performance
- **⚔️ Champion Mastery** - Most played champions, win rates, champion-specific insights
- **👥 Team Impact** - Team fight participation, objectives, positioning analysis
- **📈 Personal Growth** - Mechanics, game knowledge, mental resilience, decision making
- **🏆 Achievements** - Major milestones, badges, accomplishments
- **🌅 Future Goals** - Quarterly goals, improvement roadmap, target metrics

### User Experience

- **Magazine-Style Design** - Clean, professional global startup aesthetic
- **Responsive Layout** - 60% mobile, 40% desktop optimized
- **Sidebar + Topbar Navigation** - Modern SaaS dashboard layout
- **Smooth Animations** - Engaging transitions and hover effects
- **Progress Tracking** - Visual progress bars with shimmer effects

### Technical Features

- **Static Site** - Pure HTML/CSS/JavaScript (no build step required)
- **AWS Amplify Hosting** - Automatic CI/CD and global CDN
- **RESTful API Integration** - Ready for backend API connection
- **Authentication Ready** - AWS Cognito integration prepared
- **Mobile First** - Fully responsive design

---

## Quick Start

### Prerequisites

- Modern web browser (Chrome, Firefox, Safari, Edge)
- AWS Account (for deployment)
- AWS CLI installed and configured
- Git

### Local Development

1. **Clone the repository**
   ```bash
   git clone https://github.com/buildfour/rifts.git
   cd rifts
   ```

2. **Open the application**
   ```bash
   # Simply open index.html in your browser
   open index.html
   # or
   python -m http.server 8000
   # Then visit http://localhost:8000
   ```

3. **Start developing**
   - Edit `index.html` for structure and content
   - Modify inline CSS for styling
   - Update JavaScript for interactivity
   - All changes are immediately visible on refresh

### Quick Deploy to AWS

```bash
# Make deploy script executable
chmod +x deploy.sh

# Deploy to development environment
./deploy.sh dev

# Deploy to production
./deploy.sh production
```

See [DEPLOYMENT.md](DEPLOYMENT.md) for detailed deployment instructions.

---

## Technology Stack

### Frontend

- **HTML5** - Semantic markup
- **CSS3** - Custom properties, Grid, Flexbox
- **JavaScript (ES6+)** - Vanilla JS, no frameworks
- **Font** - Nunito (Google Fonts)

### Hosting & Infrastructure

- **AWS Amplify** - Hosting, CI/CD, global CDN
- **AWS S3** - Static file storage
- **AWS CloudFront** - Content delivery network
- **AWS Cognito** - User authentication
- **AWS API Gateway** - RESTful API endpoints

### Backend (RiftSage AI Agent)

- **Python 3.11+** - Core language
- **FastAPI** - Web framework
- **AWS Lambda** - Serverless compute
- **PostgreSQL** - Database
- **Redis** - Caching

---

## Project Structure

```
rifts/
├── index.html                          # Main application file
├── bg.jpg                              # Background image
├── deploy.sh                           # Deployment script
├── requirements.txt                    # Python dependencies
│
├── docs/                               # Documentation
│   ├── README.md                       # This file
│   ├── DEPLOYMENT.md                   # Deployment guide
│   └── AWS_STACK.md                    # AWS resources & costs
│
├── config/                             # Configuration files
│   ├── amplify.yml                     # Amplify build config
│   └── cloudfront.json                 # CloudFront config
│
├── lambda_functions/                   # AWS Lambda functions
│   ├── auth/                           # Authentication
│   ├── reports/                        # Report generation
│   └── analytics/                      # Analytics processing
│
├── database_seeds/                     # Database seed data
│   └── initial_data.sql
│
├── deployment/                         # Deployment templates
│   ├── cloudformation.yaml
│   └── terraform/
│
├── prompt_templates/                   # AI prompt templates
│   └── riftsage_prompts.md
│
└── summoners_chronicle_app.md          # Complete app specifications
```

---

## Development

### Color Palette

```css
/* Brand Colors */
--oxford-blue: #14213D;      /* Primary background */
--navy-dark: #0A1421;        /* Darker backgrounds */
--aquamarine: #7FFFD4;       /* Primary accent */
--peach: #FFDAB9;            /* Secondary accent */
--lol-gold: #C89B3C;         /* Highlights */

/* Text Colors */
--text-primary: #F0E6D2;     /* Primary text */
--text-secondary: #9D7C57;   /* Secondary text */
--text-muted: #6B6B6B;       /* Muted text */
```

### Design Principles

1. **No Gradients** - Solid colors only for clean aesthetic
2. **Professional Polish** - Global startup quality standards
3. **Clear Hierarchy** - Visual structure and breathing room
4. **Responsive First** - Mobile-optimized, desktop-enhanced
5. **Accessibility** - WCAG 2.1 Level AA compliance

### Page Structure (Consistent Pattern)

Each page follows this structure:

1. **Stats & Metrics Section**
   - 4-column grid of stat cards (responsive)
   - Large value, label, one-line insight

2. **Deeper Insights Section**
   - Bullet point format
   - Pattern explanations
   - Key observations

3. **Narrative Meaning Section**
   - Brief prose (3-5 sentences)
   - Achievement significance
   - No fictional storytelling

### Adding a New Page

1. **Add navigation item** in sidebar
   ```html
   <a class="nav-item" data-page="new-page">
       <span class="nav-icon">🎯</span>
       <span>New Page</span>
   </a>
   ```

2. **Add page content**
   ```html
   <div id="new-page" class="page-content">
       <!-- Your content here -->
   </div>
   ```

3. **Update page data** in JavaScript
   ```javascript
   const pageData = {
       'new-page': {
           title: 'New Page Title',
           subtitle: 'Page description'
       }
   };
   ```

---

## Deployment

### Deployment Environments

- **Development** - `dev` environment for testing
- **Staging** - `staging` for pre-production validation
- **Production** - `production` for live users

### Deployment Methods

1. **AWS Amplify** (Recommended)
   - Automatic CI/CD from Git
   - Built-in CDN
   - Custom domains
   - SSL certificates

2. **S3 + CloudFront**
   - Manual deployment
   - Full control
   - Custom caching rules

### Deploy Commands

```bash
# Deploy to development
./deploy.sh dev

# Deploy to staging
./deploy.sh staging

# Deploy to production
./deploy.sh production
```

For detailed deployment instructions, see [DEPLOYMENT.md](DEPLOYMENT.md).

---

## Documentation

- **[DEPLOYMENT.md](DEPLOYMENT.md)** - Complete deployment guide
- **[AWS_STACK.md](AWS_STACK.md)** - AWS resources and cost breakdown
- **[summoners_chronicle_app.md](summoners_chronicle_app.md)** - Full app specification
- **[QUICKSTART.md](QUICKSTART.md)** - Quick start guide

---

## API Integration

The frontend is designed to integrate with RiftSage AI Agent backend:

```javascript
// Example API call structure
const API_BASE = 'https://api.riftsage.com/v1';

async function fetchPlayerReport(playerId) {
    const response = await fetch(`${API_BASE}/report/${playerId}`, {
        headers: {
            'Authorization': `Bearer ${accessToken}`
        }
    });
    return response.json();
}
```

### API Endpoints (Backend Required)

- `POST /auth/magic-link` - Send magic link email
- `POST /auth/verify` - Verify magic link token
- `POST /summoner/link` - Link summoner account
- `GET /report/{playerId}` - Get player report
- `GET /matches/{playerId}` - Get match history
- `PUT /blueprint/{playerId}` - Update improvement blueprint

---

## Browser Support

- **Chrome/Edge** - Last 2 versions
- **Firefox** - Last 2 versions
- **Safari** - Last 2 versions
- **Mobile Browsers** - iOS Safari, Chrome Android

---

## Performance

### Lighthouse Scores (Target)

- **Performance**: > 90
- **Accessibility**: > 90
- **Best Practices**: > 90
- **SEO**: > 90

### Load Times

- **Page Load**: < 2 seconds on 4G
- **Time to Interactive**: < 3 seconds
- **First Contentful Paint**: < 1.5 seconds

---

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

---

## Support

- **Documentation**: [docs/](docs/)
- **Issues**: [GitHub Issues](https://github.com/buildfour/rifts/issues)
- **Email**: support@riftsage.com

---

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## Acknowledgments

- **League of Legends** - Riot Games
- **Design Inspiration** - Modern SaaS dashboards
- **Font** - Nunito by Vernon Adams
- **Hosting** - AWS Amplify

---

## Roadmap

### Version 1.1 (Q1 2025)
- [ ] Real-time data updates
- [ ] Social sharing features
- [ ] Achievement animations
- [ ] Dark/Light theme toggle

### Version 1.2 (Q2 2025)
- [ ] Match history explorer
- [ ] Peer comparison features
- [ ] Improvement blueprint planner
- [ ] PDF report export

### Version 2.0 (Q3 2025)
- [ ] Live match tracking
- [ ] Team analytics
- [ ] Custom coaching insights
- [ ] Mobile app (React Native)

---

**Built with ⚔️ for League of Legends players by the RiftSage team**
