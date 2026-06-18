import spotipy
from spotipy.oauth2 import SpotifyClientCredentials
import pandas as pd
import time
from dotenv import load_dotenv
import os

load_dotenv()

sp = spotipy.Spotify(auth_manager=SpotifyClientCredentials(
    client_id=os.getenv("SPOTIFY_CLIENT_ID"),
    client_secret=os.getenv("SPOTIFY_CLIENT_SECRET")
))

print("Connected to Spotify API ✓")

GENRE_ARTISTS = {
    "Pop": ["Taylor Swift", "Olivia Rodrigo", "Sabrina Carpenter", "Chappell Roan",
            "Billie Eilish", "Dua Lipa", "Gracie Abrams", "Benson Boone",
            "Teddy Swims", "Tate McRae", "Zach Bryan", "Charlie Puth"],
    "Hip-Hop": ["Kendrick Lamar", "Drake", "Tyler the Creator", "Doechii",
                "GloRilla", "Sexyy Red", "Latto", "Ice Spice",
                "Central Cee", "Gunna", "Playboi Carti", "Don Toliver"],
    "R&B": ["SZA", "Summer Walker", "Victoria Monet", "Ari Lennox",
            "Lucky Daye", "Daniel Caesar", "Tems", "Brent Faiyaz",
            "Giveon", "H.E.R.", "Jhene Aiko", "Emotional Oranges"],
    "Electronic": ["Fred again", "Four Tet", "Disclosure", "Flume",
                   "Kaytranada", "Peggy Gou", "Dom Dolla", "Fisher",
                   "John Summit", "Anyma", "Chris Lake", "Lane 8"],
    "Indie": ["Hozier", "Phoebe Bridgers", "Noah Kahan", "Mitski",
              "boygenius", "Japanese Breakfast", "Sufjan Stevens", "Snail Mail",
              "Soccer Mommy", "Big Thief", "Weyes Blood", "Ethel Cain"],
    "Latin": ["Bad Bunny", "Karol G", "Peso Pluma", "Feid",
              "Rauw Alejandro", "Myke Towers", "Jhayco", "Anuel AA",
              "Bizarrap", "Shakira", "J Balvin", "Maluma"]
}

def get_artist_data(artist_name, genre):
    try:
        results = sp.search(q=f"artist:{artist_name}", type="artist", limit=1)
        if not results['artists']['items']:
            print(f"  Not found: {artist_name}")
            return None

        a = results['artists']['items'][0]

        # Albums count — works with client credentials
        albums = sp.artist_albums(a['id'], album_type='album', limit=20)
        album_count = albums['total']

        # Related artists — works with client credentials
        related = sp.artist_related_artists(a['id'])
        related_followers = [r['followers']['total'] for r in related['artists']]
        avg_related_followers = sum(related_followers) / len(related_followers) if related_followers else 0

        data = {
            'artist_name': a['name'],
            'genre': genre,
            'artist_id': a['id'],
            'followers': a['followers']['total'],
            'popularity': a['popularity'],
            'album_count': album_count,
            'related_artist_count': len(related['artists']),
            'avg_related_followers': int(avg_related_followers),
            'spotify_genres': ', '.join(a['genres'][:3]),
            'image_url': a['images'][0]['url'] if a['images'] else '',
        }

        print(f"  ✓ {a['name']} — {a['followers']['total']:,} followers, popularity {a['popularity']}")
        return data

    except Exception as e:
        print(f"  Error: {artist_name}: {e}")
        return None

all_artists = []
for genre, artists in GENRE_ARTISTS.items():
    print(f"\nFetching {genre}...")
    for name in artists:
        data = get_artist_data(name, genre)
        if data:
            all_artists.append(data)
        time.sleep(0.3)

df = pd.DataFrame(all_artists)

# Derived metrics
df['followers_millions'] = (df['followers'] / 1_000_000).round(2)
df['followers_rank'] = df['followers'].rank(pct=True) * 100
df['popularity_rank'] = df['popularity'].rank(pct=True) * 100

# Breakout score: high popularity relative to followers = trending
df['breakout_score'] = (
    df['popularity_rank'] * 0.6 +
    (100 - df['followers_rank']) * 0.4
).round(1)

df['popularity_tier'] = pd.cut(df['popularity'],
    bins=[0, 50, 65, 75, 85, 100],
    labels=['Emerging', 'Rising', 'Established', 'Major', 'Superstar']
)

df['breakout_tier'] = pd.cut(df['breakout_score'],
    bins=[0, 40, 60, 75, 100],
    labels=['Plateau', 'Growing', 'Breaking', 'Breakout']
)

df.to_csv('artists_data.csv', index=False)
print(f"\nDone! Saved {len(df)} artists")
print(df.groupby('genre')[['followers_millions', 'popularity', 'breakout_score']].mean().round(2))