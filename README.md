# Spotify Creator Growth Analytics
### A Music Mission Measurement Framework & Research Report

> *"What does it take to break out on Spotify — and how would you build the data infrastructure to track it at scale?"*

This project proposes a creator growth measurement framework for Spotify's Music Mission team, backed by analysis of **86,000 artists and 124,000 tracks** using a production-ready dbt + DuckDB analytics stack.

Built by [Ayushi Desai](https://linkedin.com/in/ayushi-desai) as a speculative exercise exploring the analytics engineering work behind Spotify's creator products.

---

## What's Inside

| File | Description |
|---|---|
| [`insight_report.md`](./insight_report.md) | Research report: 4 findings on creator growth, genre breakouts, and the sound of popular music 2010–2021 |
| [`metric_definitions.md`](./metric_definitions.md) | Full measurement framework: metric definitions, SQL, dbt model designs for all 6 Music Mission products |
| [`dbt_project/`](./dbt_project/) | 7 working dbt models (staging → intermediate → marts) built on DuckDB |

---

## Key Findings

**1. The Creator Middle Class Problem**
87% of active Spotify artists have fewer than 100K followers. Only 99 out of 86,000 are superstars. The Music Mission's biggest opportunity is the 45,000 Emerging artists (1K–10K followers) who are largely outside the reach of current promotional products.

**2. Hidden Gems: Indie/Alt and Hip-Hop Punch Above Their Weight**
Artists with disproportionately high popularity relative to their follower count — the clearest signal of imminent breakout. Hip-Hop has 373 hidden gems; Indie/Alt has 156. These are the artists Discovery Mode should be prioritizing for proactive enrollment.

**3. Popular Music Has Gotten More Danceable Every Year Since 2015**
Danceability of popular tracks rose 11% from 2010 to 2021. Energy declined through 2017 before recovering. Speechiness — the clearest signal of hip-hop's dominance — rose 84%. Counterintuitively, popular tracks are *lower energy* than average tracks but significantly more danceable.

**4. K-Pop's Structural Follower Advantage**
Median K-Pop artist has 97,531 followers — 10x the median for Pop and Hip-Hop. K-Pop fandoms actively coordinate Spotify follows, meaning standard creator health metrics don't apply. Any measurement framework needs genre-normalized scoring.

---

## The Measurement Framework

The [`metric_definitions.md`](./metric_definitions.md) document proposes a Creator Health Score and product-specific metrics for each Music Mission product:

| Product | North Star Metric |
|---|---|
| Discovery Mode | Incremental new listeners per enrolled track |
| Marquee | 14-day streaming conversion rate |
| Showcase | Profile-to-follow conversion rate |
| Music Videos / Clips | Video completion rate |
| Listening Parties | Fan participation rate + 7-day stream lift |
| Concert Listings | Click-to-ticket conversion rate |

The **Creator Health Score** combines 5 signals into a single composite metric, normalized within genre + follower tier peer groups:

```
Creator Health Score =
  Popularity within peer group  × 40%
  Breakout signal               × 35%  (popularity rank − follower rank)
  Follower percentile in genre  × 25%
```

---

## dbt Project Structure

```
dbt_project/
├── models/
│   ├── staging/
│   │   ├── stg_artists.sql          # 1.16M artists cleaned + validated
│   │   └── stg_tracks.sql           # 586K tracks with audio features
│   ├── intermediate/
│   │   ├── int_artist_genre_classification.sql   # Genre + follower tier assignment
│   │   └── int_creator_health_score.sql          # Composite health score model
│   └── marts/
│       ├── mart_artist_growth_tiers.sql          # Artist-level scores + flags
│       ├── mart_genre_breakout_signals.sql       # Genre-level aggregation
│       └── mart_audio_feature_trends.sql         # Audio feature trends 2010–2021
```

**7 models · PASS=7 WARN=0 ERROR=0 · Processes 1.7M rows in under 3 seconds**

---

## How to Run

```bash
# 1. Clone the repo
git clone https://github.com/ayushid543/spotify-creator-analytics.git
cd spotify-creator-analytics

# 2. Set up environment
python -m venv venv
venv\Scripts\activate        # Windows
pip install dbt-duckdb pandas plotly

# 3. Download the data
# Artists + Tracks CSVs from:
# https://www.kaggle.com/datasets/yamaerenay/spotify-dataset-19212020-600k-tracks
# Place in data/raw/

# 4. Run dbt
cd dbt_project
dbt debug
dbt run
dbt test
```

---

## What I'd Build With Full Data Access

The three measurement gaps this analysis surfaces — and what I'd build to close them:

**Stream-level engagement** → `fact_stream_events` table in BigQuery enabling save rate, skip rate, and stream-to-listener ratio per artist per week

**Longitudinal growth tracking** → `int_artist_weekly_snapshots` to calculate follower velocity and trajectory classification over time

**Product attribution** → `int_campaign_attribution` model joining Discovery Mode enrollment dates to pre/post growth outcomes using matched control groups

These three models would unlock the full Creator Health Score as defined in the metric framework — moving from popularity proxies to real engagement signals.

---

## Stack

![dbt](https://img.shields.io/badge/dbt-FF694B?style=flat&logo=dbt&logoColor=white)
![DuckDB](https://img.shields.io/badge/DuckDB-FCD234?style=flat)
![Python](https://img.shields.io/badge/Python-3776AB?style=flat&logo=python&logoColor=white)
![SQL](https://img.shields.io/badge/SQL-4479A1?style=flat)

---

*Data: Kaggle Spotify Dataset through 2021. No Spotify internal data used. Built as a speculative analytics engineering exercise.*

*[LinkedIn](https://linkedin.com/in/ayushi-desai) · [GitHub](https://github.com/ayushid543)*
