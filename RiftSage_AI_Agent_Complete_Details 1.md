# RiftSage AI Agent - Complete App Details Document 1 (Updated)

## Executive Summary

RiftSage is an AI-powered agent that leverages AWS AI services and the League of Legends Developer API to deliver personalized, data-driven end-of-year insights for League of Legends players. Using machine learning models trained on match data, RiftSage uncovers performance patterns, identifies growth opportunities, and provides clear, actionable recommendations that help players understand their true value and improve their gameplay. The agent delivers insights through a standardized three-tier framework that adapts dynamically to each player's unique performance data.

---

## Product Overview

### Core Purpose
Transform raw match data into meaningful insights that help players understand their performance patterns, recognize growth opportunities, and receive practical guidance—all delivered in a clear, engaging style that respects data integrity while providing narrative meaning.

### Value Proposition
- **Data-Driven Clarity**: Reveals performance patterns with statistical backing
- **Meaningful Insights**: Transforms numbers into understanding without fictional embellishment
- **Actionable Guidance**: Specific, measurable recommendations based on analysis
- **Adaptive Framework**: Standardized structure that personalizes to each player's strengths
- **Professional Presentation**: Delivers insights through Summoner's Chronicle web app

### Target Audience
- **Primary**: League of Legends players (16-28 years old) who play 50+ ranked games annually
- **Secondary**: Casual players seeking to understand their impact and improve
- **Psychographics**: Players who value clear insights, practical advice, and measurable growth

---

## Product Features & Capabilities

### 1. Intelligent Data Collection & Processing

**Match Data Ingestion**
- Connects to Riot Games Developer API via summoner ID and region
- Retrieves comprehensive match history for 2025 season
- Collects data points including:
  - Champion selections and role distribution
  - KDA across all matches
  - Vision scores and ward placement patterns
  - Objective participation
  - Gold earned and CS efficiency
  - Damage dealt vs. damage taken ratios
  - Game duration and outcome
  - Team composition and matchups
  - Comeback scenarios
  - Critical game moments
  - CS per minute tracking
  - Gold differential analysis
  - Ward placement timing and locations
  - Teamfight positioning data

**Data Storage & Management**
- AWS S3 for raw match data storage
- DynamoDB for player profiles and processed metrics
- Automated data pipeline via AWS Lambda
- Rate limit management (respecting Riot's API limits)
- Historical data retention for year-over-year comparisons

---

### 2. Advanced Analytics & Pattern Recognition

**Machine Learning Models via AWS Lambda**

**Model 1: Performance Pattern Analyzer**
- **Algorithm**: K-Means Clustering with 3 clusters
- **Training Data**: Historical match data with performance characteristics
- **Features Used**:
  - Assist-to-kill ratio
  - Deaths in losses vs. team average
  - Vision score relative to role
  - Objective participation rate
  - Team fight presence percentage
  - CS efficiency metrics
  - Gold differential contribution
- **Output**: Classification of high-impact games, performance consistency levels, player archetype identification
- **Adaptation Logic**: Identifies player's strongest performance dimensions and emphasizes those in output

**Model 2: Mental Resilience Calculator**
- **Algorithm**: Random Forest Classifier
- **Training Data**: Performance metrics correlated with comeback scenarios and pressure situations
- **Features Used**:
  - Performance variance after team deaths
  - KDA improvement in deficit situations
  - Consistency across losing streaks
  - Pressure game performance (promos, series)
  - Tilt recovery patterns
- **Output**: Resilience score (0-100), tilt resistance rating, consistency grade
- **Adaptation Logic**: Calibrates score relative to rank tier and game volume

**Model 3: Growth Trajectory Analyzer**
- **Algorithm**: Time Series Analysis (LSTM Neural Network)
- **Training Data**: Month-over-month performance metrics across player base
- **Features Used**:
  - Rolling 30-day averages for core metrics
  - Champion mastery progression curves
  - Role adaptation patterns over time
  - Meta adaptation speed
  - Improvement velocity calculations
- **Output**: Predicted improvement areas, skill progression forecasts, plateau identification, acceleration metrics
- **Adaptation Logic**: Projects personalized growth targets based on historical improvement rate

**Model 4: Play Style Profiler**
- **Algorithm**: Principal Component Analysis (PCA) + K-Means Clustering
- **Training Data**: Comprehensive gameplay patterns across 100,000+ players
- **Features Used**:
  - Aggression index (early game activity, first blood participation)
  - Teamwork orientation (assists, objective focus, sacrifice plays)
  - Mechanical execution (CS efficiency, damage optimization)
  - Strategic positioning (deaths, vision control, map awareness)
- **Output**: Playstyle archetype (e.g., "Strategic Enabler", "Mechanical Carry", "Late-Game Scaler"), archetype-specific recommendations
- **Adaptation Logic**: Matches player to closest archetype cluster, identifies archetype-specific improvement paths

---

### 3. Comprehensive Metric Tracking (25+ Measurements)

**Core Performance Metrics**
1. **Win Rate**: Overall and role-specific win percentages
2. **KDA Ratio**: Kills/Deaths/Assists performance index
3. **Kills per Game**: Average champion eliminations
4. **Assists per Game**: Team contribution through assists
5. **Deaths per Game**: Survival and positioning metric
6. **CS per Minute**: Farming efficiency across game phases
7. **Vision Score per Minute**: Vision control effectiveness
8. **Gold per Minute**: Economic efficiency

**Macro Game Intelligence**
9. **Objective Participation Rate**: Dragon/Baron/Herald presence vs. team
10. **Map Pressure Creation**: Solo pressure while team secures objectives
11. **Vision Efficiency Score**: Ward placements leading to successful plays
12. **Rotation Timing**: Response speed to map state changes
13. **Side Lane Farm Efficiency**: Gold collection from side lanes post-laning

**Performance Under Pressure**
14. **Comeback Contribution**: Performance improvement in gold-deficit games
15. **Late Game Decision Making**: Success rate in 35+ minute matches
16. **Teamfight Positioning**: Damage dealt/taken ratio in major engagements
17. **Clutch Moment Success**: Performance in critical game-deciding moments
18. **Pressure Game Performance**: Stats in promos and ranked series

**Mental Resilience Indicators**
19. **Tilt Resistance Score**: Consistency after negative events (0-100 scale)
20. **Adaptability Index**: Improvement against counter-matchups over time
21. **Consistency Rating**: Standard deviation of performance metrics
22. **Streak Recovery**: Performance bounce-back after losing streaks

**Skill Expression Metrics**
23. **CS Efficiency Under Pressure**: Farming accuracy when harassed
24. **Damage Optimization**: Damage dealt while maintaining survival
25. **Positioning Intelligence**: Safety index during high-pressure moments
26. **Resource Management**: Mana/energy efficiency in extended engagements

**Team Synergy Metrics**
27. **Follow-up Success Rate**: Team capitalize rate on player initiations
28. **Enablement Factor**: Teammates' performance correlation with player
29. **Sacrifice Play Value**: Deaths directly leading to objectives/advantages
30. **Communication Proxy**: Win rate in coordinated plays vs. solo queue

**Champion & Role Mastery**
31. **Champion Pool Depth**: Number of champions with 55%+ win rate
32. **Role Flexibility**: Performance variance across multiple positions
33. **Meta Adaptation Speed**: Performance with newly buffed/nerfed champions
34. **Signature Champion Mastery**: Win rate on most-played champions

**Comparative Benchmarks**
35. **Rank Percentile**: Performance vs. same-rank players
36. **Role Percentile**: Performance vs. same-role players
37. **Improvement Velocity**: Growth rate vs. player base average

---

### 4. Standardized Output Framework (Three-Tier Structure with Intro Overview)

**CRITICAL UNDERSTANDING ABOUT CONTENT GENERATION**:

RiftSage does NOT use pre-written templates. The structures shown below are **instructions for the AI** on how to analyze data and what to generate. Think of them as a recipe, not a menu - the AI follows the recipe but creates unique dishes for each player.

**What the AI receives**: Player metrics, benchmarks, patterns
**What the AI generates**: 100% unique content analyzing that specific player
**What users see**: Insights that could ONLY apply to them

---

RiftSage delivers all insights using a consistent four-part framework that adapts content to each player's unique data while maintaining structural consistency.

#### **Framework Overview**

Every section follows this structure:
0. **Intro Overview**: Contextual introduction paragraph that frames the data story
1. **Stats & Metrics**: Quantitative data with one-line key insights
2. **Deeper Insights**: Pattern explanations in clear bullet points
3. **Narrative Meaning**: Brief contextual statement (3-5 sentences) explaining significance

**The structure stays the same, but the content is 100% unique per player.**

#### **Section 1: Role Performance Snapshot**

**Purpose**: Establish player's primary role strength and core statistics

**Adaptation Logic**:
- Identifies player's highest win rate role as primary focus
- Selects top 4 metrics that best represent player's strengths
- Compares to rank-appropriate benchmarks
- Calculates year-over-year improvements if historical data available

**AI Generation Instructions (NOT a Fill-in Template)**:

**IMPORTANT**: The structure below is NOT a template with placeholders to fill. It is a set of instructions that tells the AI **how to analyze the data and what to generate**. The AI creates every word dynamically based on the player's unique performance profile.

```
PROMPT TO AI:

Generate a Role Performance Snapshot using this structure:

PART 1 - INTRO OVERVIEW:
Analyze the player's data and write 2-3 sentences that:
- Identify their PRIMARY performance pattern (e.g., "aggressive combat + survival discipline")
- Mention their SECONDARY characteristic (e.g., "year-over-year improvement")
- Reference a specific trend (e.g., "consistent kill participation above rank average")
- End with: "Your key [category] ratios show:"

PART 2 - STATS & METRICS:
Present their top 4 performing metrics (based on percentiles) with format:
- Metric Name: [Exact Value] ([Contextual insight in 5-8 words])
- Use their actual numbers from the data
- Choose metrics where they exceed rank average most

PART 3 - DEEPER INSIGHTS:
Write 4-5 bullet points that explain:
- What their win rate REVEALS about gameplay approach (not just "it's high")
- What their KDA MEANS in terms of actual behavior (e.g., "extracting four impacts per death")
- How other metrics CONNECT to create success patterns
- Use specific numbers from their data
- Each bullet should explain a mechanism, not just restate a stat

PART 4 - NARRATIVE MEANING:
Write 3-5 sentences that:
- Synthesize what the COMBINATION of metrics reveals
- Explain WHY this approach is effective for this player
- Connect to their rank and potential
- Reference at least 3 specific numbers
- Avoid generic statements that could apply to any player

CRITICAL RULES:
- Every sentence must be unique to THIS player's data
- Do not use generic templates or fill-in-the-blank structures
- Adapt insights to their specific strengths/weaknesses
- Make connections between metrics that reveal gameplay patterns
- Write as if you deeply understand THIS player's unique playstyle
```

**Data Provided to AI**:
```json
{
  "player_metrics": {
    "win_rate": 65.0,
    "rank_avg_win_rate": 52.0,
    "win_rate_percentile": 87,
    "kda": 3.8,
    "kda_2024": 2.2,
    "kills_per_game": 7.2,
    "assists_per_game": 6.8,
    "deaths_per_game": 3.5,
    "cs_min": 6.8,
    "vision_min": 0.6
  },
  "comparative_analysis": {
    "top_strengths": ["KDA", "Win Rate", "Kills per Game", "Assists per Game"],
    "improvement_areas": ["CS/min", "Vision Score/min"],
    "overall_percentile": 84
  },
  "context": {
    "primary_pattern": "aggressive_combat_with_survival",
    "playstyle_archetype": "Strategic Enabler",
    "rank": "Platinum III"
  }
}
```

**Example with Real Data**:

```
INTRO OVERVIEW:
Your recent games show a clear pattern of consistent survival paired with high 
combat output, with increases in teamfight presence and significant alignment 
for late-game scaling achievement. Your key survival and impact ratios show:

STATS & METRICS:
- Win Rate: 65% (13% above Platinum average)
- KDA Ratio: 3.8 (71% improvement from 2024)
- Kills per Game: 7.2 (Consistent aggressive impact)
- Assists per Game: 6.8 (Strong team contribution)

DEEPER INSIGHTS (What the Numbers Build On - Pattern Insights):
• Your 65% win rate reflects strong game-closing power — more than half your 
  games end in victory, creating a solid base for rank growth
• Your 3.8 KDA ratio means you stay in the fight longer, turning each life 
  into nearly four impacts
• Your 7.2 kills per game show you consistently find and finish targets
• Your 6.8 assists per game prove you're not just carrying — you're 
  connecting with teammates to close fights
• Low death count opens the door to repeated plays — high kills and assists 
  flow from sharp positioning and timing

NARRATIVE MEANING (Core Data Pattern):
Your 65% win rate on ADC combined with 3.8 KDA demonstrates mastery of 
aggressive positioning while maintaining survival. This balance between impact 
and safety turns teamfights into your strength zone. The combination of 7.2 
kills and 6.8 assists shows you're executing both solo plays and team 
coordination. Adding CS/min and vision score/min to this foundation will 
expand your already strong results into even more consistent climbing power.
```

#### **Section 2: Upgraded Path / Improvement Blueprint**

**Purpose**: Provide actionable, data-driven improvement recommendations

**Adaptation Logic**:
- Identifies 2-3 metrics where player is below rank average
- Selects improvement areas with highest climb correlation
- Recommends 3 champions that align with player's playstyle + address weaknesses
- Provides phase-by-phase targets based on player's current baseline
- Sets 30-day measurable targets scaled to player's current performance

**AI Generation Instructions (NOT a Fill-in Template)**:

```
PROMPT TO AI:

Generate an Improvement Blueprint using this structure:

PART 1 - INTRO OVERVIEW:
Write 2-3 sentences that:
- Acknowledge their primary strength first
- Identify the 2 specific areas for improvement
- Frame improvement as building on existing success
- Use language like "layer in X and Y to turn [short-term] into [long-term]"
- End with: "The goal: make your [strength] work harder by [what improvements enable]"

PART 2 - STATS & METRICS (Current Baseline):
Restate the opportunity in 1-2 sentences, then present their current state

PART 3 - DEEPER INSIGHTS (Data Alignment for Growth):
Write 2-3 bullet points explaining:
- HOW the improvement metrics extend their current impact
- WHY their existing pattern needs these additions
- WHAT enabling factors these improvements provide

PART 4 - RECOMMENDED CHAMPION POOL:
Generate a table with 3 champions that:
- Match their playstyle archetype
- Address their weakness metrics
- Leverage their strength metrics
- Include specific numbers (win rate, CS/min potential, vision support)
- For each champion, write a unique 15-20 word explanation of fit

PART 5 - PHASE-BY-PHASE EXECUTION:
Create a table with 3 game phases showing:
- Specific, measurable priority goals
- Actionable behaviors tied to exact game times
- Quantified benefits (gold gains, percentage improvements)
- Tailored to their role and weaknesses

PART 6 - 30-DAY MEASURABLE TARGETS:
Create a table showing:
- Current value for each improvement metric
- Target value (calculated as current × 1.20 or 80% to rank average)
- Gameplay outcome description
- Projected win rate improvement

PART 7 - NARRATIVE MEANING:
Write 3-4 sentences that:
- Synthesize how current strengths + improvements = superior performance
- Reference specific metrics and their compounding effect
- End with an aspirational but achievable outcome
- Be specific to this player's situation

CRITICAL RULES:
- Champion recommendations must be dynamically selected from database
- Phase-by-phase actions must be specific to their role and weaknesses
- Targets must be calculated, not guessed
- Every word unique to this player's profile
```

**Data Provided to AI**:
```json
{
  "player_metrics": {
    "win_rate": 65.0,
    "cs_min": 6.8,
    "rank_avg_cs_min": 7.8,
    "vision_min": 0.6,
    "rank_avg_vision_min": 0.85,
    "kda": 3.8,
    "primary_role": "ADC"
  },
  "improvement_opportunities": [
    {
      "metric": "cs_min",
      "current": 6.8,
      "rank_avg": 7.8,
      "gap": 1.0,
      "target": 8.0,
      "climb_correlation": 0.42
    },
    {
      "metric": "vision_min",
      "current": 0.6,
      "rank_avg": 0.85,
      "gap": 0.25,
      "target": 0.8,
      "climb_correlation": 0.38
    }
  ],
  "champion_recommendations": [
    {
      "champion": "Ashe",
      "win_rate_pattern": "53%+ in similar play",
      "cs_min_potential": 7.8,
      "vision_support": 0.92,
      "fit_score": 87,
      "strengths": ["Global vision (E)", "High range", "Catch potential"]
    },
    {
      "champion": "Jinx",
      "win_rate_pattern": "52%+ in scaling games",
      "cs_min_potential": 8.4,
      "vision_support": 0.78,
      "fit_score": 85,
      "strengths": ["Rocket waveclear", "Hyperscaling", "Reset potential"]
    },
    {
      "champion": "Sivir",
      "win_rate_pattern": "52%+ in farm-heavy lanes",
      "cs_min_potential": 8.7,
      "vision_support": 0.81,
      "fit_score": 82,
      "strengths": ["Spell shield safety", "Waveclear", "Utility ultimate"]
    }
  ],
  "playstyle_archetype": "Strategic Enabler"
}
```

**Example with Real Data**:

```
INTRO OVERVIEW:
Your 65% win rate already proves your strength — now layer in farm efficiency 
and vision control to turn short-term wins into long-term climbing consistency. 
The goal: make your positioning work harder by giving it more gold and map 
control to work with.

STATS & METRICS (Current Baseline):
Your 65% win rate already proves your strength — now layer in farm efficiency 
and vision control to turn short-term wins into long-term climbing consistency.

DEEPER INSIGHTS (Data Alignment for Growth):
Games where you secure 8+ CS/min and 0.8+ vision/min extend your impact 
beyond teamfights — they keep you ahead in gold and map awareness. Your 
current pattern (high KDA + kills) thrives when you have items and safety. 
Farm and vision deliver both.

RECOMMENDED CHAMPION POOL:

| Champion | Win Rate Pattern | CS/min Potential | Vision Support | Fit for Your Playstyle |
|----------|------------------|------------------|----------------|------------------------|
| Ashe | 53%+ in similar play | 7.8 | 0.92 | Global vision (E) and arrows turn your positioning into team-wide picks and control |
| Jinx | 52%+ in scaling games | 8.4 | 0.78 | Rockets clear waves fast — more gold, more items, more late-game power |
| Sivir | 52%+ in farm-heavy lanes | 8.7 | 0.81 | Spell shield blocks danger; waveclear keeps you rich and safe |

PHASE-BY-PHASE EXECUTION (15-Min Win Focus):

| Game Phase | Priority Goal | Core Action | Gold & Impact Gain |
|------------|---------------|-------------|---------------------|
| 0–10 min (Laning) | 7.5+ CS/min | Freeze near tower or mirror-push; fight only at power spikes (lvl 2/6) with support | +1,000 gold — same as one extra kill, but guaranteed |
| 10–20 min (Mid) | Vision + Side Farm | Place 2 control wards per recall; farm side lanes after T1 falls | +15% gold lead; forces enemies to react to you |
| 20+ min (Late) | Teamfight Control | Stay backline, use utility to start fights. Split only with teleport up | Turns your 65% late-game strength into 67-70% consistent wins |

30-DAY MEASURABLE TARGETS:

| Metric | Your Current Base | Week 4 Target | Growth Outcome |
|--------|-------------------|---------------|----------------|
| CS/min | 6.8 | 8.0+ | +1,200 gold every 10 minutes |
| Vision Score/min | 0.6 | 0.8+ | More picks, safer plays, objective control |
| Win Rate (next 50 games) | 65% | 67-70% | Smoother, faster climb with more consistency |

NARRATIVE MEANING (Final Pattern Insight):
Your 3.8 KDA and 65% win rate are already elite performance markers. Adding 
8 CS/min and 0.8 vision/min means every fight starts with you ahead in items 
and information. Your positioning becomes unstoppable when backed by gold 
advantage and vision control. The combination transforms your already strong 
teamfighting into a comprehensive climbing engine. The nexus becomes routine.
```

#### **Section 3: Mental Resilience & Consistency**

**Purpose**: Highlight psychological strengths and tilt management

**Adaptation Logic**:
- Calculates tilt resistance score from performance variance
- Identifies comeback game performance patterns
- Measures consistency across different game states
- Compares pressure game performance to average games

**Output Template**:

```
INTRO OVERVIEW:
Your mental game shows [primary resilience characteristic] across [context - 
e.g., "difficult match situations", "comeback scenarios"], with [specific 
pattern observed]. Your consistency and pressure performance metrics reveal:

STATS & METRICS:
- Tilt Resistance Score: [0-100 value] ([grade: Low/Medium/High/Elite])
- Consistency Rating: [Value] ([interpretation])
- Comeback Game Win Rate: [%] ([comparison to overall win rate])
- Pressure Performance: [%] in promos/series ([comparison])

DEEPER INSIGHTS (Pattern Identification):
• Your [tilt resistance score] indicates [pattern explanation]
• Performance in [X] comeback games shows [specific behavior pattern]
• [Consistency metric] reveals [what this says about playstyle]
• [Additional pattern from mental game analysis]

NARRATIVE MEANING:
[3-4 sentences explaining player's mental game strengths, how it contributes 
to their success, and what this predicts for future performance improvement.]
```

#### **Section 4: Champion Mastery Analysis**

**Purpose**: Identify champion pool strengths and optimization opportunities

**Adaptation Logic**:
- Ranks champions by win rate and games played
- Identifies champion pool depth (number of champions with 55%+ win rate)
- Analyzes performance by champion class/role
- Recommends pool expansion or specialization based on data

**Output Template**:

```
INTRO OVERVIEW:
Your champion pool demonstrates [primary mastery characteristic] with 
[specific pattern - e.g., "strong specialization", "versatile flexibility"], 
showing [notable trend]. Your champion performance breakdown reveals:

STATS & METRICS (Champion Performance):
- Most Played Champion: [Champion] ([games played], [win rate]%)
- Champion Pool Depth: [X] champions with 55%+ win rate
- Highest Win Rate: [Champion] ([win rate]% over [X] games)
- Role Distribution: [Primary role %], [Secondary role %]

DEEPER INSIGHTS (Champion Analysis):
• Your [X]% win rate on [champion] demonstrates [mastery aspect]
• Champion pool shows preference for [archetype/playstyle]
• [Performance pattern across champion types]
• [Meta adaptation or champion mastery trend]

RECOMMENDED POOL ACTIONS:
[Bullet points with specific recommendations]
• Specialize: [Champion(s)] — your [metric] excels here
• Expand: [Champion(s)] — fills gaps in your pool while matching playstyle
• Practice: [Champion(s)] — high potential based on your strengths

NARRATIVE MEANING:
[3-4 sentences synthesizing champion mastery patterns, what it reveals about 
player skill expression, and strategic recommendations for pool optimization.]
```

#### **Section 5: Outstanding Games Showcase**

**Purpose**: Celebrate exceptional performances with data backing

**Adaptation Logic**:
- Identifies top 10 games by impact score (weighted formula of KDA, objective participation, comeback factor, vision score)
- Categorizes games by type (comeback, carry performance, team enablement, clutch moment)
- Provides context for why each game was exceptional

**Output Template**:

```
INTRO OVERVIEW:
Your standout performances throughout the year reveal [primary excellence 
characteristic], with [specific pattern - e.g., "exceptional clutch factor", 
"consistent high-impact play"], particularly strong in [context]. Your 
exceptional game metrics show:

STATS & METRICS (Top Performance Games):
- Games Analyzed: [Total games]
- Outstanding Impact Games: [Number] ([% of total])
- Highest Impact Score: [Value] ([date, champion, outcome])
- Most Common Excellence Type: [Category]

GAME HIGHLIGHTS (Top 5 by Impact Score):

[For each game, provide:]

Game #[X] - [Date] - [Champion] - [Outcome]
• Impact Score: [Value]/100
• KDA: [K/D/A] ([KDA ratio])
• [2-3 standout metrics specific to why this game was exceptional]
• Excellence Category: [Comeback/Carry/Enabler/Clutch]
• Key Moment: [Brief 1-sentence description of pivotal play]

DEEPER INSIGHTS (What Made These Special):
• [Pattern across outstanding games]
• [Common factors in highest-impact performances]
• [What triggers peak performance for this player]

NARRATIVE MEANING:
[3-4 sentences explaining what these outstanding games reveal about player's 
ceiling, clutch factor, and potential for high-level performance. Connects to 
improvement recommendations.]
```

#### **Section 6: Year-Over-Year Growth (If Applicable)**

**Purpose**: Show measurable improvement trajectory

**Adaptation Logic**:
- Only included if player has 2024 data available
- Calculates percentage improvements across all key metrics
- Identifies breakthrough moments and acceleration periods
- Projects continued growth trajectory

**Output Template**:

```
INTRO OVERVIEW:
Your growth trajectory from 2024 to 2025 demonstrates [primary improvement 
characteristic], with [specific achievements - e.g., "consistent skill 
acceleration", "breakthrough performance gains"], particularly in [strongest 
growth area]. Your year-over-year progress shows:

STATS & METRICS (Year-Over-Year Comparison):
- Rank Improvement: [2024 rank] → [2025 rank] ([X] divisions)
- Win Rate Change: [2024 %] → [2025 %] ([+/-X]% improvement)
- KDA Improvement: [2024 KDA] → [2025 KDA] ([+X]% growth)
- [Top 2-3 metrics with largest improvements]

DEEPER INSIGHTS (Growth Patterns):
• [Largest area of improvement and what enabled it]
• [Skill development trajectory observation]
• [Acceleration periods identified - months of fastest growth]
• [Plateau periods and what changed to break through]

GROWTH TRAJECTORY PROJECTION:
If current improvement rate continues:
• Estimated 2026 Rank: [Projection based on trend]
• Key Metrics to Reach Target: [Specific numbers needed]
• Timeline to Next Rank: [Estimated months based on LP gain rate]

NARRATIVE MEANING:
[3-4 sentences celebrating tangible growth, explaining what the trajectory 
reveals about player's learning curve, and forecasting realistic future 
achievement with continued dedication.]
```

---


