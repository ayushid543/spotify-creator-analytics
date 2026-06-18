-- int_artist_genre_classification.sql
-- Assigns primary genre to each artist using keyword matching
-- This mirrors how Spotify's internal genre taxonomy works

with artists as (
    select * from "spotify_creator"."main"."stg_artists"
),

genre_classified as (
    select
        artist_id,
        artist_name,
        followers,
        popularity,
        genres_raw,

        -- Primary genre classification via keyword matching
        case
            when lower(genres_raw) like '%k-pop%'
                or lower(genres_raw) like '%korean pop%'
                then 'K-Pop'
            when lower(genres_raw) like '%latin%'
                or lower(genres_raw) like '%reggaeton%'
                or lower(genres_raw) like '%salsa%'
                or lower(genres_raw) like '%bachata%'
                then 'Latin'
            when lower(genres_raw) like '%hip hop%'
                or lower(genres_raw) like '%rap%'
                or lower(genres_raw) like '%trap%'
                or lower(genres_raw) like '%drill%'
                then 'Hip-Hop'
            when lower(genres_raw) like '%r&b%'
                or lower(genres_raw) like '%soul%'
                or lower(genres_raw) like '%neo soul%'
                or lower(genres_raw) like '%contemporary r%'
                then 'R&B'
            when lower(genres_raw) like '%edm%'
                or lower(genres_raw) like '%house%'
                or lower(genres_raw) like '%techno%'
                or lower(genres_raw) like '%electro%'
                or lower(genres_raw) like '%electronic%'
                or lower(genres_raw) like '%dance%'
                then 'Electronic'
            when lower(genres_raw) like '%country%'
                then 'Country'
            when lower(genres_raw) like '%classical%'
                or lower(genres_raw) like '%orchestra%'
                or lower(genres_raw) like '%chamber%'
                then 'Classical'
            when lower(genres_raw) like '%indie%'
                or lower(genres_raw) like '%lo-fi%'
                or lower(genres_raw) like '%bedroom pop%'
                or lower(genres_raw) like '%alternative%'
                then 'Indie/Alternative'
            when lower(genres_raw) like '%rock%'
                or lower(genres_raw) like '%metal%'
                or lower(genres_raw) like '%punk%'
                then 'Rock'
            when lower(genres_raw) like '%pop%'
                then 'Pop'
            when genres_raw = '[]' or genres_raw is null
                then 'Unknown'
            else 'Other'
        end                                             as primary_genre,

        -- Follower tiers (mirrors Spotify's internal artist tiers)
        case
            when followers >= 10000000  then 'Superstar'      -- 10M+
            when followers >= 1000000   then 'Major'          -- 1M-10M
            when followers >= 100000    then 'Established'    -- 100K-1M
            when followers >= 10000     then 'Mid-Tier'       -- 10K-100K
            when followers >= 1000      then 'Emerging'       -- 1K-10K
            else 'Underground'                                 -- < 1K
        end                                             as follower_tier,

        -- Popularity tiers
        case
            when popularity >= 80 then 'Viral'
            when popularity >= 60 then 'Popular'
            when popularity >= 40 then 'Moderate'
            when popularity >= 20 then 'Niche'
            else 'Obscure'
        end                                             as popularity_tier

    from artists
)

select * from genre_classified
where primary_genre not in ('Unknown', 'Other')