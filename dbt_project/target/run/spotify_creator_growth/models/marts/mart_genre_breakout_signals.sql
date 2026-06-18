
  
    
    

    create  table
      "spotify_creator"."main"."mart_genre_breakout_signals__dbt_tmp"
  
    as (
      -- mart_genre_breakout_signals.sql
-- Genre-level aggregation of creator health metrics
-- Answers: which genres are producing the most breakout artists right now?

with artists as (
    select * from "spotify_creator"."main"."mart_artist_growth_tiers"
),

genre_summary as (
    select
        primary_genre,

        -- Volume
        count(*)                                        as total_artists,
        count(case when health_tier = 'Breakout'
            then 1 end)                                 as breakout_artists,
        count(case when health_tier = 'Breaking'
            then 1 end)                                 as breaking_artists,
        count(case when is_emerging_breakout
            then 1 end)                                 as emerging_breakout_artists,
        count(case when is_hidden_gem
            then 1 end)                                 as hidden_gems,

        -- Health metrics
        round(avg(creator_health_score), 1)             as avg_health_score,
        round(avg(breakout_signal), 1)                  as avg_breakout_signal,
        round(avg(popularity), 1)                       as avg_popularity,
        round(avg(followers), 0)                        as avg_followers,
        round(median(followers), 0)                     as median_followers,

        -- Rates
        round(count(case when health_tier = 'Breakout'
            then 1 end) * 100.0 / count(*), 2)         as breakout_rate_pct,
        round(count(case when is_hidden_gem
            then 1 end) * 100.0 / count(*), 2)         as hidden_gem_rate_pct,

        -- Follower distribution
        count(case when follower_tier = 'Superstar'     then 1 end) as superstar_count,
        count(case when follower_tier = 'Major'         then 1 end) as major_count,
        count(case when follower_tier = 'Established'   then 1 end) as established_count,
        count(case when follower_tier = 'Mid-Tier'      then 1 end) as mid_tier_count,
        count(case when follower_tier = 'Emerging'      then 1 end) as emerging_count

    from artists
    group by 1
)

select
    *,
    -- Middle class proxy: artists in Mid-Tier + Established tiers
    round((mid_tier_count + established_count) * 100.0 / total_artists, 1)
        as middle_class_pct
from genre_summary
order by breakout_rate_pct desc
    );
  
  