import json
import pandas as pd
import requests


def generate_url(fight_id, sourceid, start, end, key):
    url = f"https://www.warcraftlogs.com/v1/report/events/healing/{fight_id}?start={start}&end={end}&sourceid={sourceid}&api_key={key}"
    return url


def query_wcl(fight_id, sourceid, start, end, key):
    url = generate_url(fight_id, sourceid, start, end, key)

    response = requests.get(url)
    contents = json.loads(response.text)
    return contents


def parse_heals_df(contents):
    df = pd.DataFrame(contents['events'])
    df_type = df['type']
    keep_ser = df_type.apply(
        lambda x: True if x in ['heal', 'absorbed'] else False)  # doesnt seem to handle smite absorb etc
    df = df[keep_ser]
    return df


def generate_metadata(df, start, end):
    total_heals = sum(df['amount'])

    fight_len = (int(end) - int(start)) / 1000
    hps = int(total_heals / fight_len)
    return total_heals, fight_len, hps


def convert_to_timeser(df, start):  # todo move out
    df = df[['amount', 'timestamp']]
    df['timestamp'].apply(lambda x: int((x - int(start)) / 1000))  # aggregate to seconds
    heal_ser = df.groupby(['timestamp']).sum()

    heal_ser_cumul = heal_ser.cumsum().values
    return heal_ser_cumul


def get_rankings_raw(role, encounter_id, player_spec, key, num_pages):
    base_url = "https://www.warcraftlogs.com/v1/rankings/encounter/"
    difficulty = 5  # mythic

    # todo extract
    player_class = 4  # mage
    player_spec = 2  # fire

    full_url = base_url + f"{encounter_id}?metric={role.name.lower()}&difficulty={difficulty}&class={player_class}&" \
                          f"spec={player_spec}&api_key={key}"

    response = requests.get(full_url)
    contents = json.loads(response.text)

    # syncronously handle paging:
    pages = [contents]
    if contents['hasMorePages']:
        for i in range(2, num_pages + 1):  # start i = 2
            next_page_url = full_url + f"&page={i}"
            pages.append(json.loads(requests.get(next_page_url).text))

    rankings = []
    for page in pages:
        rankings += page['rankings']

    return rankings
