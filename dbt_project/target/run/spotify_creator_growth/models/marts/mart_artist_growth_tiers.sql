
  
    
    

    create  table
      "spotify_creator"."main"."mart_artist_growth_tiers__dbt_tmp"
  
    as (
      -- mart_artist_growth_tiers.sql
-- Final mart: artist-level creator health scores
-- Designed for self-service analytics by Music Mission product teams

with health_scores as (
    select * from "spotify_creator"."main"."int_creator_health_score"
),

final as (
    select
        artist_id,
        artist_name,
        primary_genre,
        follower_tier,
        popularity_tier,
        health_tier,
        followers,
        popularity,
        round(creator_health_score, 1)                  as creator_health_score,
        round(breakout_signal, 1)                       as breakout_signal,
        round(popularity_pct_in_peer_group, 1)          as popularity_pct_in_peer_group,
        round(follower_pct_in_genre, 1)                 as follower_pct_in_genre,
        round(popularity_pct_in_genre, 1)               as popularity_pct_in_genre,
        recommended_action,

        -- Flags for product team filtering
        case when health_tier = 'Breakout' then true else false end  as is_breakout,
        case when follower_tier = 'Emerging'
             and health_tier in ('Breakout', 'Breaking')
             then true else false end                   as is_emerging_breakout,
        case when follower_tier in ('Underground', 'Emerging')
             and popularity_tier in ('Viral', 'Popular')
             then true else false end                   as is_hidden_gem

    from health_scores
)

select * from final
order by creator_health_score desc
    );
  
  