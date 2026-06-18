-- mart_audio_feature_trends.sql
-- Tracks how the "sound" of popular music has shifted over time
-- Key insight for Music Mission: what audio signatures define creator success by era?

with tracks as (
    select * from "spotify_creator"."main"."stg_tracks"
    where release_year between 2010 and 2021
      and release_year is not null
),

yearly_all as (
    select
        release_year,
        'All Tracks'                                    as track_segment,
        count(*)                                        as track_count,
        round(avg(popularity), 2)                       as avg_popularity,
        round(avg(danceability), 3)                     as avg_danceability,
        round(avg(energy), 3)                           as avg_energy,
        round(avg(valence), 3)                          as avg_valence,
        round(avg(acousticness), 3)                     as avg_acousticness,
        round(avg(tempo_bpm), 1)                        as avg_tempo,
        round(avg(speechiness), 3)                      as avg_speechiness,
        round(avg(instrumentalness), 3)                 as avg_instrumentalness,
        round(avg(duration_minutes), 2)                 as avg_duration_minutes
    from tracks
    group by 1
),

yearly_popular as (
    select
        release_year,
        'Popular Tracks (60+)'                          as track_segment,
        count(*)                                        as track_count,
        round(avg(popularity), 2)                       as avg_popularity,
        round(avg(danceability), 3)                     as avg_danceability,
        round(avg(energy), 3)                           as avg_energy,
        round(avg(valence), 3)                          as avg_valence,
        round(avg(acousticness), 3)                     as avg_acousticness,
        round(avg(tempo_bpm), 1)                        as avg_tempo,
        round(avg(speechiness), 3)                      as avg_speechiness,
        round(avg(instrumentalness), 3)                 as avg_instrumentalness,
        round(avg(duration_minutes), 2)                 as avg_duration_minutes
    from tracks
    where popularity >= 60
    group by 1
)

select * from yearly_all
union all
select * from yearly_popular
order by release_year, track_segment