# Music Mission Analytics: Metric Definitions & Measurement Framework

**Author:** Ayushi Desai  
**Context:** Proposed measurement framework for the Music Mission team at Spotify  
**Scope:** Discovery Mode, Marquee, Showcase, Music Videos/Clips, Listening Parties, Concert Listings  
**Stack:** dbt + BigQuery | Python | SQL  

---

## Why Measurement Frameworks Matter for Creator Products

Creator-facing products at Spotify face a unique measurement challenge: success isn't just about listener engagement — it's about whether the product is genuinely helping artists build sustainable careers. A Marquee campaign that drives 10,000 streams but zero new followers is not a success. A Discovery Mode enrollment that adds 500 genuine new listeners who return and save tracks is.

This framework proposes metrics that measure **creator outcomes**, not just platform activity. Every metric below is designed to answer a question a product manager or artist would actually care about — not just a metric that's easy to instrument.

---

## Section 1: Core Creator Health Metrics

These are the foundational metrics that apply across all Music Mission products. They form the basis of the Creator Health Score (Section 6).

---

### 1.1 Stream-to-Listener Ratio (SLR)

**Definition:** Total streams divided by unique listeners in a given time window.

```sql
-- dbt model: int_artist_stream_listener_ratio.sql
select
    artist_id,
    date_trunc('week', stream_date)        as week,
    count(*)                               as total_streams,
    count(distinct listener_id)            as unique_listeners,
    safe_divide(
        count(*),
        count(distinct listener_id)
    )                                      as stream_listener_ratio
from {{ ref('stg_streams') }}
group by 1, 2
```

**Why it matters:** A ratio above 1.5 signals that listeners are returning to an artist's music — not just discovering and leaving. This is the clearest proxy for genuine fan engagement vs. algorithmic exposure.

**Thresholds (based on industry benchmarks):**
| Tier | SLR | Signal |
|------|-----|--------|
| Emerging | < 1.2 | One-time listeners, low retention |
| Growing | 1.2 – 1.8 | Some repeat listeners forming |
| Established | 1.8 – 2.5 | Strong returning fanbase |
| Superstar | > 2.5 | Deep fan loyalty, playlist behavior |

**Data quality note:** Exclude streams under 30 seconds (skip behavior) and flag bot-like patterns (>50 streams from single listener in 24hrs).

---

### 1.2 Save Rate

**Definition:** Tracks saved (added to library or playlist) divided by total streams, expressed as a percentage.

```sql
-- dbt model: int_artist_save_rate.sql
select
    artist_id,
    track_id,
    date_trunc('week', event_date)         as week,
    countif(event_type = 'stream')         as total_streams,
    countif(event_type = 'save')           as total_saves,
    safe_divide(
        countif(event_type = 'save'),
        countif(event_type = 'stream')
    ) * 100                                as save_rate_pct
from {{ ref('stg_user_events') }}
group by 1, 2, 3
```

**Why it matters:** Saves are the strongest intent signal on Spotify. A listener who saves a track is telling the algorithm they want to hear it again — and telling us they've converted from casual listener to engaged fan. Industry benchmark: 10–20% save rate signals lasting appeal.

**Dimensions to cut by:**
- Save rate by discovery source (editorial playlist vs. algorithmic vs. direct search)
- Save rate by listener tenure (new vs. returning listener)
- Save rate by market (to identify geographic pockets of strong engagement)

---

### 1.3 Skip Rate

**Definition:** Percentage of streams where the listener skipped before 30 seconds.

```sql
-- dbt model: int_track_skip_rate.sql
select
    artist_id,
    track_id,
    date_trunc('week', stream_date)        as week,
    count(*)                               as total_streams,
    countif(seconds_played < 30)           as skips,
    safe_divide(
        countif(seconds_played < 30),
        count(*)
    ) * 100                                as skip_rate_pct
from {{ ref('stg_streams') }}
group by 1, 2, 3
```

**Why it matters:** High skip rate is the clearest signal of misaligned placement — the algorithm is showing music to the wrong listeners. For creator products specifically: if a Marquee or Discovery Mode campaign drives high skip rates, it's delivering volume without value.

**Alert threshold:** Skip rate > 35% on a campaign should trigger a review of targeting parameters.

---

### 1.4 New Listener Rate

**Definition:** Percentage of streams in a time window coming from listeners with no prior streams of that artist.

```sql
-- dbt model: int_artist_new_listener_rate.sql
with first_streams as (
    select
        artist_id,
        listener_id,
        min(stream_date)                   as first_stream_date
    from {{ ref('stg_streams') }}
    group by 1, 2
)

select
    s.artist_id,
    date_trunc('week', s.stream_date)      as week,
    count(distinct s.listener_id)          as total_listeners,
    count(distinct case
        when fs.first_stream_date = s.stream_date
        then s.listener_id
    end)                                   as new_listeners,
    safe_divide(
        count(distinct case
            when fs.first_stream_date = s.stream_date
            then s.listener_id end),
        count(distinct s.listener_id)
    ) * 100                                as new_listener_rate_pct
from {{ ref('stg_streams') }} s
left join first_streams fs
    on s.artist_id = fs.artist_id
    and s.listener_id = fs.listener_id
group by 1, 2
```

**Why it matters:** This is the primary growth metric. A healthy creator trajectory shows increasing new listener rate during campaign periods, followed by strong save and return rates — meaning new listeners convert to fans.

---

### 1.5 Follower Velocity

**Definition:** Week-over-week change in follower count, expressed as absolute and percentage change.

```sql
-- dbt model: int_artist_follower_velocity.sql
select
    artist_id,
    week,
    followers,
    lag(followers) over (
        partition by artist_id
        order by week
    )                                      as prev_week_followers,
    followers - lag(followers) over (
        partition by artist_id
        order by week
    )                                      as follower_delta,
    safe_divide(
        followers - lag(followers) over (
            partition by artist_id order by week),
        lag(followers) over (
            partition by artist_id order by week)
    ) * 100                                as follower_growth_pct
from {{ ref('int_artist_weekly_snapshots') }}
```

**Why it matters:** Follower velocity is a lagging indicator of campaign success. It tells us whether stream activity is converting into durable fan relationships — the ultimate goal of every Music Mission product.

---

## Section 2: Product-Specific Metrics

---

### 2.1 Discovery Mode

**What it does:** Artists opt in to algorithmic promotion in exchange for a reduced royalty rate. Spotify surfaces their music to listeners algorithmically likely to enjoy it.

**North Star Metric:** Incremental new listeners acquired per enrolled track

**Measurement approach:**
```sql
-- dbt model: mart_discovery_mode_lift.sql
-- Compare 4-week window pre vs. post enrollment
-- Control for organic trend using non-enrolled similar artists
select
    dm.artist_id,
    dm.track_id,
    dm.enrollment_date,
    avg(case when s.stream_date < dm.enrollment_date
        then s.new_listener_flag end)      as pre_enrollment_new_listener_rate,
    avg(case when s.stream_date >= dm.enrollment_date
        then s.new_listener_flag end)      as post_enrollment_new_listener_rate,
    avg(case when s.stream_date >= dm.enrollment_date
        then s.new_listener_flag end) -
    avg(case when s.stream_date < dm.enrollment_date
        then s.new_listener_flag end)      as new_listener_lift
from {{ ref('stg_discovery_mode_enrollments') }} dm
join {{ ref('int_stream_enriched') }} s
    on dm.track_id = s.track_id
    and s.stream_date between
        dateadd('day', -28, dm.enrollment_date)
        and dateadd('day', 28, dm.enrollment_date)
group by 1, 2, 3
```

**Key questions this answers:**
- Is Discovery Mode driving genuine new listeners or just shifting existing streams?
- Which genres/artist tiers benefit most from enrollment?
- What's the trade-off between royalty reduction and audience growth?

**Data quality consideration:** Need to control for release cadence — artists who release new music during enrollment period will show inflated lift.

---

### 2.2 Marquee

**What it does:** Paid promotional campaign that surfaces a new release to listeners most likely to engage, via a full-screen recommendation on first app open.

**North Star Metric:** 14-day streaming conversion rate (listeners who stream the promoted track at least twice within 14 days of seeing the Marquee)

**Supporting metrics:**
- Impression-to-stream rate
- New vs. returning listener split of converters
- Save rate of Marquee-attributed streams vs. organic streams
- 30-day listener retention of Marquee-converted fans

**Measurement framework:**
```sql
-- dbt model: mart_marquee_performance.sql
select
    m.campaign_id,
    m.artist_id,
    m.track_id,
    m.campaign_start_date,
    count(distinct m.listener_id)          as impressions,
    count(distinct case
        when s.stream_count_14d >= 1
        then m.listener_id end)            as stream_converters,
    count(distinct case
        when s.stream_count_14d >= 2
        then m.listener_id end)            as deep_converters,
    safe_divide(
        count(distinct case
            when s.stream_count_14d >= 1
            then m.listener_id end),
        count(distinct m.listener_id)
    )                                      as conversion_rate,
    avg(s.save_flag)                       as save_rate,
    avg(s.is_new_listener::int)            as new_listener_pct
from {{ ref('stg_marquee_impressions') }} m
left join {{ ref('int_post_campaign_streams') }} s
    on m.listener_id = s.listener_id
    and m.track_id = s.track_id
group by 1, 2, 3, 4
```

**What I'd want to investigate:** Does Marquee performance vary significantly by artist tier? My hypothesis is that mid-tier artists (50K–500K monthly listeners) get disproportionately higher lift than superstars, since their existing fans are less saturated.

---

### 2.3 Showcase

**What it does:** Promotes an artist's profile (not a specific track) to listeners in their algorithmic affinity audience — appears as a recommendation card.

**North Star Metric:** Profile-to-follow conversion rate

**Supporting metrics:**
- Artist profile visit rate post-impression
- Track streams initiated from profile visit
- Follow conversion rate
- 90-day retention of new followers acquired via Showcase

**Key distinction from Marquee:** Marquee drives track consumption. Showcase drives artist relationship. The metrics need to reflect this — a Showcase that doesn't convert followers is underperforming regardless of stream count.

---

### 2.4 Music Videos & Clips

**What it does:** Short-form and full-length video content embedded in the Spotify listening experience.

**North Star Metric:** Video completion rate

**Supporting metrics:**
- Re-watch rate (strongest engagement signal for video)
- Audio stream initiation rate post-video view (did the video drive listening?)
- Share rate
- Skip rate at 3s, 10s, 30s (to identify where viewers drop off)

**Key question:** Does watching a music video increase the probability of saving or replaying a track? If yes, by how much? This justifies the investment in the video product for creators.

---

### 2.5 Listening Parties

**What it does:** Live, synchronized listening experience where an artist and fans listen to an album together in real time.

**North Star Metric:** Fan participation rate among existing followers

**Supporting metrics:**
- New follower acquisition during event
- Stream volume lift in 7 days post-event
- Save rate of tracks played during the party vs. pre-party baseline
- Geographic distribution of participants (to measure global reach)

**What makes this hard to measure:** Listening Parties are an awareness and relationship product, not a pure conversion product. The 7-day post-event lift in saves and return streams is more meaningful than the event attendance number itself.

---

### 2.6 Concert Listings

**What it does:** Shows fans upcoming concert dates for artists they listen to, integrated into the Spotify experience.

**North Star Metric:** Click-to-ticket-purchase conversion rate (via ticketing partner attribution)

**Supporting metrics:**
- Listing impression-to-click rate
- Geographic match rate (listener is in the market of the concert)
- Artist stream lift in 14 days post-concert (do fans who see shows stream more?)
- Revenue per artist from ticketing referrals

**Key insight opportunity:** If listeners who attend concerts stream significantly more than those who don't, that's a strong case for investing further in the concert discovery product — it deepens the fan relationship.

---

## Section 3: The Creator Health Score

A single composite metric that summarizes an artist's growth trajectory on Spotify. Designed to help the Music Mission team quickly identify which artists are thriving, which are plateauing, and which are at risk of churn from the platform.

```sql
-- dbt model: mart_creator_health_score.sql
with base_metrics as (
    select
        artist_id,
        week,
        stream_listener_ratio,
        save_rate_pct,
        skip_rate_pct,
        new_listener_rate_pct,
        follower_growth_pct
    from {{ ref('int_artist_weekly_metrics') }}
),

normalized as (
    select
        artist_id,
        week,
        -- Normalize each metric to 0-100 scale within artist tier
        percent_rank() over (
            partition by artist_tier, week
            order by stream_listener_ratio
        ) * 100                            as slr_score,
        percent_rank() over (
            partition by artist_tier, week
            order by save_rate_pct
        ) * 100                            as save_score,
        percent_rank() over (
            partition by artist_tier, week
            order by skip_rate_pct desc    -- lower skip = higher score
        ) * 100                            as skip_score,
        percent_rank() over (
            partition by artist_tier, week
            order by new_listener_rate_pct
        ) * 100                            as growth_score,
        percent_rank() over (
            partition by artist_tier, week
            order by follower_growth_pct
        ) * 100                            as follower_score
    from base_metrics
    join {{ ref('int_artist_tiers') }} using (artist_id)
)

select
    artist_id,
    week,
    -- Weighted composite score
    (slr_score      * 0.25 +
     save_score     * 0.25 +
     skip_score     * 0.20 +
     growth_score   * 0.20 +
     follower_score * 0.10)               as creator_health_score,
    slr_score,
    save_score,
    skip_score,
    growth_score,
    follower_score
from normalized
```

**Score interpretation:**
| Score | Tier | Recommended Action |
|-------|------|--------------------|
| 75–100 | Thriving | Prioritize for editorial consideration, Marquee upsell |
| 50–74 | Growing | Candidate for Discovery Mode, Showcase |
| 25–49 | Plateauing | Reach out via Spotify for Artists with growth tips |
| 0–24 | At Risk | Flag for creator success team review |

---

## Section 4: Data Quality Framework

Every metric above requires a corresponding data quality test. Below are the critical tests I'd implement in dbt.

```yaml
# schema.yml — data quality tests

models:
  - name: int_artist_weekly_metrics
    columns:
      - name: stream_listener_ratio
        tests:
          - not_null
          - dbt_utils.accepted_range:
              min_value: 0
              max_value: 100  # Flag extreme outliers for bot review
      - name: save_rate_pct
        tests:
          - not_null
          - dbt_utils.accepted_range:
              min_value: 0
              max_value: 100
      - name: skip_rate_pct
        tests:
          - not_null
          - dbt_utils.accepted_range:
              min_value: 0
              max_value: 100

  - name: mart_creator_health_score
    tests:
      - dbt_utils.recency:
          datepart: day
          field: week
          interval: 8  # Alert if data is more than 8 days stale
    columns:
      - name: artist_id
        tests:
          - unique
          - not_null
      - name: creator_health_score
        tests:
          - dbt_utils.accepted_range:
              min_value: 0
              max_value: 100
```

**Key data quality concerns specific to music streaming:**

1. **Bot streams** — need to filter streams from accounts with suspicious patterns before any metric calculation. Define a `is_legitimate_stream` flag in staging.

2. **Artist tier drift** — artists move between tiers as they grow. Metrics need to be normalized within tier at point-in-time, not retroactively.

3. **Campaign attribution windows** — overlapping campaigns (e.g., Marquee + Discovery Mode simultaneously) require careful attribution modeling to avoid double-counting lift.

4. **Market effects** — viral moments in specific markets can skew global metrics. Always segment by market before drawing conclusions about product performance.

---

## Section 5: What I'd Prioritize in My First 30 Days

**Week 1 — Understand the current state**
- Audit existing dbt models: what's documented, what's not, what's trusted
- Interview each product team (Discovery Mode, Marquee, Showcase) to understand what questions they're currently unable to answer
- Map data sources: what events are instrumented, what's missing

**Week 2 — Define the metric layer**
- Propose standardized definitions for the 5 core creator health metrics
- Get alignment from product, data science, and engineering on definitions
- Build staging models for each core data source

**Week 3 — Build the foundation**
- Implement `int_artist_weekly_metrics` as the single source of truth for creator health data
- Add data quality tests and documentation
- Build first version of `mart_creator_health_score`

**Week 4 — First insight delivery**
- Present initial findings on creator health distribution across artist tiers
- Identify the top 3 measurement gaps the team should prioritize closing
- Propose roadmap for product-specific measurement (Discovery Mode lift model, Marquee conversion model)

---

## Section 6: Questions I'd Want to Answer With Full Data Access

1. **Does Discovery Mode cannibalize organic growth?** Artists accept lower royalties for algorithmic promotion. If that promotion mostly reaches listeners who would have discovered the artist anyway, the trade-off isn't worth it. This requires incrementality testing.

2. **What is the optimal Marquee campaign timing relative to release date?** Day 0 vs. Day 3 vs. Day 7 — when does paid promotion drive the highest quality listener conversion?

3. **Which creator product drives the highest 90-day listener retention?** Short-term stream lift is easy to manufacture. Durable fan relationships are what matter. Which product genuinely converts casual listeners into long-term fans?

4. **Is there a creator health score threshold that predicts churn from the platform?** If artists below a certain score consistently stop releasing music on Spotify, that's a leading indicator the platform can act on proactively.

5. **How does creator success vary by market?** Is Spotify disproportionately helping artists in certain regions more than others? This has implications for both product investment and creator equity.

---

*This framework was developed as a speculative exercise based on public information about Spotify's Music Mission products and creator ecosystem. All SQL is illustrative — written to reflect how I'd approach modeling these metrics in a real BigQuery + dbt environment.*

*Built by Ayushi Desai — [github.com/ayushid543](https://github.com/ayushid543) · [linkedin.com/in/ayushi-desai](https://linkedin.com/in/ayushi-desai)*
