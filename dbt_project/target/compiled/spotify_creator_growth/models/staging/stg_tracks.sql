-- stg_tracks.sql
-- Cleans and standardizes raw track data
-- Source: Kaggle Spotify Dataset (586K tracks)

with source as (
    select * from read_csv_auto('C:/Users/ayude/spotify-creator-analytics/data/raw/tracks.csv')),

cleaned as (
    select
        id                                              as track_id,
        name                                            as track_name,
        cast(popularity as integer)                     as popularity,
        cast(duration_ms as integer)                    as duration_ms,
        cast(duration_ms as float) / 60000.0            as duration_minutes,
        cast(explicit as boolean)                       as is_explicit,
        artists                                         as artists_raw,
        id_artists                                      as artist_ids_raw,

        -- Release date handling
        try_cast(release_date as date)                  as release_date,
        case
            when length(release_date) = 4
            then cast(release_date as integer)
            else year(try_cast(release_date as date))
        end                                             as release_year,

        -- Audio features
        cast(danceability as float)                     as danceability,
        cast(energy as float)                           as energy,
        cast(key as integer)                            as musical_key,
        cast(loudness as float)                         as loudness_db,
        cast(mode as integer)                           as mode,
        cast(speechiness as float)                      as speechiness,
        cast(acousticness as float)                     as acousticness,
        cast(instrumentalness as float)                 as instrumentalness,
        cast(liveness as float)                         as liveness,
        cast(valence as float)                          as valence,
        cast(tempo as float)                            as tempo_bpm,
        cast(time_signature as integer)                 as time_signature,

        -- Derived audio feature categories
        case
            when cast(energy as float) >= 0.7 then 'High Energy'
            when cast(energy as float) >= 0.4 then 'Medium Energy'
            else 'Low Energy'
        end                                             as energy_category,

        case
            when cast(danceability as float) >= 0.7 then 'High Danceability'
            when cast(danceability as float) >= 0.4 then 'Medium Danceability'
            else 'Low Danceability'
        end                                             as danceability_category,

        case
            when cast(valence as float) >= 0.6 then 'Positive/Happy'
            when cast(valence as float) >= 0.3 then 'Neutral'
            else 'Negative/Sad'
        end                                             as mood_category,

        case
            when cast(acousticness as float) >= 0.6 then 'Acoustic'
            else 'Electronic/Produced'
        end                                             as production_style

    from source
    where id is not null
      and name is not null
      and cast(popularity as integer) between 0 and 100
      and cast(danceability as float) between 0 and 1
      and cast(energy as float) between 0 and 1
)

select * from cleaned
where release_year >= 1950
  and duration_minutes between 0.5 and 20  -- Filter out invalid durations