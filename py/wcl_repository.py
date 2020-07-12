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


def convert_to_timeser(df, start):
    df = df[['amount', 'timestamp']]
    df['timestamp'].apply(lambda x: int((x - int(start)) / 1000))  # aggregate to seconds
    heal_ser = df.groupby(['timestamp']).sum()

    heal_ser_cumul = heal_ser.cumsum().values
    return heal_ser_cumul

