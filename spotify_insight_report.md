# What Does It Take to Break Out on Spotify?
## A Creator Growth Analysis Across 86,000 Artists and 124,000 Tracks

**Author:** Ayushi Desai  
**Date:** June 2026  
**Data:** Kaggle Spotify Dataset — 1.16M artists, 586K tracks (through 2021)  
**Framework:** Music Mission Creator Health Measurement Framework  
**Stack:** dbt + DuckDB + Python  
**GitHub:** github.com/ayushid543/spotify-creator-analytics  

---

## Executive Summary

This report analyzes 86,000 Spotify artists across 10 genres to identify what separates breaking artists from those who plateau. Three findings stand out:

1. **The music industry has a profound middle-class problem.** 87% of artists on Spotify have fewer than 100K followers. Only 0.1% are superstars. The vast majority of creators exist in a long tail that the platform's current product suite may not be reaching effectively.

2. **Indie/Alt and Hip-Hop produce the most hidden gems** — artists with disproportionately high popularity relative to their follower count. These are the creators most likely to break out with the right promotional support.

3. **Popular music has gotten more danceable, more acoustic, and less energetic every year since 2015** — a consistent trend that has significant implications for how the Music Mission team should think about creator tool design and audience matching.

---

## Finding 1 — The Creator Middle Class Problem

### What the data shows

Of 86,000 artists with meaningful activity on Spotify:

| Follower Tier | Artists | Share |
|---|---|---|
| Emerging (1K–10K) | 45,765 | **52.8%** |
| Mid-Tier (10K–100K) | 29,566 | **34.1%** |
| Established (100K–1M) | 9,570 | 11.0% |
| Major (1M–10M) | 1,617 | 1.9% |
| Superstar (10M+) | 99 | **0.1%** |

The numbers are stark: **87% of active Spotify artists have fewer than 100K followers.** Only 99 artists — out of 86,000 — have crossed 10 million followers.

This is not a distribution unique to Spotify, but it has direct implications for the Music Mission. The products that get the most attention — Marquee, Showcase, Discovery Mode — are primarily designed for artists who already have some audience momentum. The 45,000 Emerging artists in this dataset are largely outside the reach of these tools.

### Why this matters for the Music Mission

The creator funnel has a massive leakage problem between Emerging and Mid-Tier. If Spotify's goal is to help music creators "grow, engage, and monetize their fan bases," then the measurement framework needs to answer: **what interventions actually help artists move from 1K to 10K followers?** That transition is where the majority of the creator population lives.

**Implication for analytics engineering:** The `mart_artist_growth_tiers` model in this framework flags all 45,765 Emerging artists and scores them by health tier. The Music Mission team should be tracking the conversion rate from Emerging → Mid-Tier as a north star metric for the overall creator proposition — not just the performance of individual products.

---

## Finding 2 — Hidden Gems: Indie/Alt and Hip-Hop Punch Above Their Weight

### What the data shows

A "hidden gem" is an artist with fewer than 100K followers but a popularity score of 60 or higher — meaning their music is resonating with listeners far beyond what their follower count suggests. These are creators whose audience has not yet caught up with their cultural moment.

**Hidden gem rate by genre:**

| Genre | Total Artists | Hidden Gems | Hidden Gem Rate |
|---|---|---|---|
| **Classical** | 2,638 | 58 | **2.20%** |
| **Hip-Hop** | 18,643 | 373 | **2.00%** |
| **Electronic** | 8,897 | 165 | **1.85%** |
| R&B | 3,579 | 45 | 1.26% |
| Latin | 3,574 | 44 | 1.23% |
| Indie/Alt | 15,044 | 156 | 1.04% |
| Pop | 17,034 | 172 | 1.01% |
| Country | 2,025 | 20 | 0.99% |
| K-Pop | 683 | 2 | 0.29% |
| Rock | 14,499 | 20 | **0.14%** |

**The most surprising finding:** Classical has the highest hidden gem rate at 2.2% — nearly double Hip-Hop. This likely reflects the niche but highly engaged nature of classical music listeners, who stream specific artists intensively without those artists having large social followings.

**Hip-Hop and Electronic** have the highest absolute hidden gem counts — 373 and 165 respectively. These are the genres where the Discovery Mode and Showcase products have the most opportunity to accelerate existing momentum.

**Rock has the lowest hidden gem rate at 0.14%** — suggesting the genre is either fully discovered (most popular Rock artists already have large followings) or in structural decline on the platform.

### Sample hidden gems from the data

These are real artists from the dataset with under 5,000 followers but popularity scores of 60+:

| Artist | Genre | Followers | Popularity Score |
|---|---|---|---|
| Dillan Witherow | Indie/Alt | 1,201 | 67 |
| Flow La Movie | Latin | 3,667 | 77 |
| Yuridope | Hip-Hop | 1,115 | 64 |
| Project AER | Indie/Alt | 1,665 | 65 |
| Arman Aydin | Electronic | 1,496 | 63 |
| Kizzy | Hip-Hop | 1,676 | 65 |

Flow La Movie is the standout: 3,667 followers with a popularity score of 77 — higher than many artists with millions of followers. This is exactly the kind of creator Discovery Mode should be prioritizing for enrollment.

### Why this matters for the Music Mission

The hidden gem detection model built in this framework (`is_hidden_gem` flag in `mart_artist_growth_tiers`) identifies these artists automatically. This flag should be used by the Discovery Mode product team to proactively reach out to artists who are already generating listener engagement but haven't yet converted that engagement into followers.

**A key measurement question the Music Mission should be answering:** Of the hidden gems that enrolled in Discovery Mode in a given quarter, what percentage crossed from Emerging to Mid-Tier within 90 days? That conversion rate is a direct measure of Discovery Mode's effectiveness for the creator segment most in need of it.

---

## Finding 3 — The Sound of Popular Music Has Shifted Dramatically Since 2015

### What the data shows

Analyzing 18,951 popular tracks (popularity score ≥ 60) released between 2010 and 2021 reveals a clear and consistent directional shift in what makes music successful on Spotify:

| Year | Danceability | Energy | Valence (Mood) | Acousticness | Speechiness |
|---|---|---|---|---|---|
| 2010 | 0.613 | **0.708** | **0.554** | 0.194 | 0.078 |
| 2013 | 0.594 | 0.659 | 0.486 | 0.249 | 0.085 |
| 2015 | 0.600 | 0.625 | 0.453 | 0.274 | 0.094 |
| 2017 | 0.633 | 0.596 | 0.465 | **0.315** | 0.098 |
| 2019 | 0.670 | 0.628 | 0.520 | 0.311 | 0.113 |
| 2021 | **0.682** | 0.647 | 0.517 | 0.264 | **0.143** |

**Four clear trends:**

**1. Danceability has risen every year (+11% from 2010 to 2021)**
Popular music is consistently getting more rhythmically engaging. This correlates with the rise of streaming as the primary consumption format — music optimized for repeat listening tends to be more rhythmically structured.

**2. Energy peaked in 2010 and declined through 2017 before recovering**
The 2015–2017 dip corresponds with the mainstream rise of trap music and lo-fi hip-hop — genres that score low on raw energy but high on listener engagement. Energy is rebounding post-2018.

**3. Acousticness rose 63% between 2010 and 2017**
The most dramatic shift in the dataset. Popular music became significantly more acoustic through the mid-2010s — driven by the folk pop wave (Ed Sheeran, Hozier, Mumford & Sons) and the rise of bedroom pop. It has since declined as electronic production resurged.

**4. Speechiness has risen 84% since 2010**
The clearest signal of hip-hop's dominance. Speechiness measures the degree to which a track resembles speech — rap, podcasts, and spoken word all score high. The consistent year-over-year rise reflects hip-hop's growing share of popular music consumption.

### What popular tracks do differently from the average

Comparing popular tracks (60+) against all tracks from the same period:

| Feature | Popular Tracks | All Tracks | Difference |
|---|---|---|---|
| Danceability | 0.649 | 0.618 | **+0.031** |
| Energy | 0.635 | 0.654 | -0.019 |
| Speechiness | 0.107 | 0.096 | **+0.011** |
| Acousticness | 0.280 | 0.285 | -0.005 |
| Valence | 0.502 | 0.511 | -0.010 |

**The counterintuitive finding:** Popular tracks are actually *lower energy* than the average track, but significantly *more danceable*. High energy ≠ high popularity. Rhythmic engagement drives streaming behavior more than raw intensity.

### Why this matters for the Music Mission

This finding has direct implications for how the Music Mission team should think about algorithmic matching in products like Discovery Mode and Marquee. 

**Key implication:** If an artist's catalog skews high-energy but low-danceability, they may be systematically underserved by audience matching algorithms optimized for the features that correlate with streaming behavior. The Music Mission analytics team should be testing whether audio feature alignment between an artist's catalog and a listener's historical preferences predicts Discovery Mode conversion better than popularity score alone.

---

## Finding 4 — K-Pop's Structural Advantage: Followers First, Streams Second

### What the data shows

K-Pop has the highest median follower count of any genre by a significant margin:

| Genre | Median Followers |
|---|---|
| **K-Pop** | **97,531** |
| Latin | 27,703 |
| R&B | 15,279 |
| Country | 14,162 |
| Pop | 8,794 |
| Hip-Hop | 9,929 |

The median K-Pop artist on Spotify has 97,531 followers — **10x the median for Pop and Hip-Hop artists.**

This reflects K-Pop's unique fan mobilization model: fandoms actively cultivate Spotify follows as a coordinated activity, driving follower counts that are structurally disconnected from organic streaming behavior. K-Pop artists enter Spotify's ecosystem already at the Established tier, bypassing the Emerging → Mid-Tier journey entirely.

### Why this matters for the Music Mission

K-Pop represents a measurement edge case that standard creator health metrics don't handle well. An artist with 97,531 followers and a popularity score of 45 looks "healthy" by follower count but is actually underperforming relative to their audience size.

**Recommendation:** The Creator Health Score model should include a genre-normalized adjustment that accounts for the K-Pop follower inflation effect. Scoring K-Pop artists relative to their genre peers (as this framework does via `percent_rank() OVER (PARTITION BY primary_genre, follower_tier)`) partially addresses this — but the metric framework should explicitly flag K-Pop artists for separate analysis given their structurally different growth dynamics.

---

## What I'd Build Next: Three Measurement Gaps to Close

These findings surface three areas where the current data is insufficient to answer the Music Mission's most important questions. Here's what I'd prioritize building:

**Gap 1 — Stream-level engagement data**
This analysis uses followers and popularity scores as proxies for creator health. The real metrics — stream-to-listener ratio, save rate, skip rate — require event-level stream data. Connecting artist-level data to stream events in BigQuery would unlock the full Creator Health Score defined in the measurement framework.

*How I'd build it:* Design a `fact_stream_events` table in BigQuery with artist_id, listener_id, track_id, stream_date, and seconds_played. Build an intermediate model that aggregates to weekly artist-level metrics. This becomes the foundation for all product-specific measurement (Discovery Mode lift, Marquee conversion rate).

**Gap 2 — Longitudinal growth tracking**
This dataset is a point-in-time snapshot. To measure creator growth trajectories — and to identify whether artists are accelerating, plateauing, or declining — we need weekly snapshots over time.

*How I'd build it:* A weekly snapshot table (`int_artist_weekly_snapshots`) that stores follower count, popularity score, and health score per artist per week. This enables follower velocity calculation and trajectory classification.

**Gap 3 — Product attribution**
The most important unanswered question: does Discovery Mode enrollment actually cause artists to cross from Emerging to Mid-Tier? Without a campaign enrollment table joined to growth outcomes, we can't measure this.

*How I'd build it:* An `int_campaign_attribution` model that joins Discovery Mode enrollment dates to pre/post follower and stream metrics, using a 28-day pre/post comparison window and a matched control group of non-enrolled artists with similar health scores.

---

## Methodology

**Data source:** Kaggle Spotify Dataset (yamaerenay/spotify-dataset-19212020-600k-tracks). 1.16M artists, 586K tracks through 2021.

**Artist filtering:** Artists with fewer than 1,000 followers or popularity below 10 were excluded as inactive. Final analysis set: 86,000 artists across 10 genres.

**Genre classification:** Rule-based keyword matching on Spotify's genre tags. Artists whose genre tags matched multiple categories were assigned to the first matching genre in a priority hierarchy (K-Pop > Latin > Hip-Hop > R&B > Electronic > Country > Classical > Indie/Alt > Rock > Pop).

**Creator Health Score:** Composite metric weighted as follows — popularity within peer group (40%), breakout signal/popularity vs follower rank difference (35%), follower percentile within genre (25%). Scored relative to genre + follower tier peer group to control for structural differences between genres.

**Audio feature analysis:** Limited to tracks released 2010–2021 with popularity score ≥ 0. "Popular tracks" defined as popularity ≥ 60. Trends smoothed across years with minimum 100 tracks per year.

**Limitations:**
- Follower and popularity data reflects a single point in time, not growth trajectories
- Audio features (danceability, energy, valence) are Spotify's proprietary calculations — exact methodology not public
- Genre classification is approximate; many artists span multiple genres
- Dataset covers through 2021; streaming landscape has shifted since

---

*This analysis was conducted as a speculative exercise to explore the kinds of measurement frameworks the Music Mission analytics team builds. All data is from public sources. No Spotify internal data was used.*

*Built by Ayushi Desai — [github.com/ayushid543](https://github.com/ayushid543) · [linkedin.com/in/ayushi-desai](https://linkedin.com/in/ayushi-desai)*
