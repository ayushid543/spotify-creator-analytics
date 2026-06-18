-- stg_artists.sql
-- Cleans and standardizes raw artist data
-- Source: Kaggle Spotify Dataset (1.16M artists)

with source as (
    select * from read_csv_auto('C:/Users/ayude/spotify-creator-analytics/data/raw/artists.csv')
),

cleaned as (
    select
        id                                              as artist_id,
        name                                            as artist_name,
        cast(followers as bigint)                       as followers,
        cast(popularity as integer)                     as popularity,
        genres                                          as genres_raw,

        -- Data quality flags
        case
            when followers is null then true
            when followers < 0 then true
            else false
        end                                             as is_invalid_followers,

        case
            when popularity < 0 or popularity > 100 then true
            else false
        end                                             as is_invalid_popularity

    from source
    where id is not null
      and name is not null
      and name != ''
)

select * from cleaned
where not is_invalid_followers
  and not is_invalid_popularity