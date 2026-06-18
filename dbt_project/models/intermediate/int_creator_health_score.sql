-- int_creator_health_score.sql
-- Computes the Creator Health Score for each artist
-- Based on the measurement framework in the Music Mission Analytics Spec
--
-- Score components (within-genre-tier normalized):
--   popularity_score  (40%) — how popular vs peers with similar followers
--   breakout_signal   (35%) — popularity disproportionate to follower count = trending
--   catalog_signal    (25%) — followers as proxy for catalog depth and longevity

with artists as (
    select * from {{ ref('int_artist_genre_classification') }}
    where followers >= 1000         -- Minimum threshold for meaningful scoring
      and popularity >= 10          -- Filter out inactive artists
),

-- Rank within genre + follower tier peer group
peer_ranked as (
    select
        *,
        percent_rank() over (
            partition by primary_genre, follower_tier
            order by popularity
        ) * 100                                         as popularity_pct_in_peer_group,

        percent_rank() over (
            partition by primary_genre
            order by followers
        ) * 100                                         as follower_pct_in_genre,

        percent_rank() over (
            partition by primary_genre
            order by popularity
        ) * 100                                         as popularity_pct_in_genre

    from artists
),

scored as (
    select
        *,

        -- Breakout signal: high popularity relative to follower count
        -- An artist punching above their follower weight = breaking out
        (popularity_pct_in_genre - follower_pct_in_genre)   as breakout_raw,

        -- Composite creator health score
        round(
            popularity_pct_in_peer_group    * 0.40 +
            greatest(0, (popularity_pct_in_genre - follower_pct_in_genre)) * 0.35 +
            follower_pct_in_genre           * 0.25
        , 1)                                                as creator_health_score

    from peer_ranked
),

final as (
    select
        artist_id,
        artist_name,
        primary_genre,
        follower_tier,
        popularity_tier,
        followers,
        popularity,
        popularity_pct_in_peer_group,
        follower_pct_in_genre,
        popularity_pct_in_genre,
        breakout_raw                                        as breakout_signal,
        creator_health_score,

        -- Health score tier
        case
            when creator_health_score >= 75 then 'Breakout'
            when creator_health_score >= 55 then 'Breaking'
            when creator_health_score >= 35 then 'Growing'
            else 'Plateau'
        end                                                 as health_tier,

        -- Recommended Music Mission action
        case
            when creator_health_score >= 75
                then 'Editorial consideration + Marquee upsell'
            when creator_health_score >= 55
                then 'Discovery Mode candidate'
            when creator_health_score >= 35
                then 'Showcase candidate'
            else
                'Spotify for Artists outreach — growth tips'
        end                                                 as recommended_action

    from scored
)

select * from final
