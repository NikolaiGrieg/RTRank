import json
import pandas as pd
import requests

from py.secret_handler import get_wcl_key


def generate_url(fight_id, sourceid, start, end, key, type):
    url = f"https://www.warcraftlogs.com/v1/report/events/{type}/{fight_id}?" \
          f"start={start}&end={end}&sourceid={sourceid}&api_key={key}"
    return url


def query_wcl(fight_id, sourceid, start, end, type="healing", key=get_wcl_key()):
    url = generate_url(fight_id, sourceid, start, end, key, type)

    response = requests.get(url)
    contents = json.loads(response.text)
    return contents


# def query_wcl_full_event_log(event_type, report_id, start, end, source_row):
#     key = get_wcl_key()
#     url = f"https://www.warcraftlogs.com/v1/report/events/{event_type}/{report_id}?start={start}&end={end}&api_key={key}"
#
#     response = requests.get(url)
#     contents = json.loads(response.text)
#
#     # from first 300 rows => get sourceID if found, else query next recursively until found
#     name = source_row[1]['name']
#
#     # Then query the rest by sourceID
#     # and handle extra pages
#
#     return contents


def parse_heals_df(contents):  # todo move out
    df = pd.DataFrame(contents['events'])
    df_type = df['type']
    keep_ser = df_type.apply(
        lambda x: True if x in ['heal', 'absorbed'] else False)  # doesnt seem to handle smite absorb etc
    df = df[keep_ser]
    return df


def generate_metadata(df, start, end):  # todo move out
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


def get_rankings_raw(role, encounter_id, player_spec, key, num_pages):  # todo handle key in this class
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


def get_fight_metadata(row):
    key = get_wcl_key()  # todo singleton probably

    code = row[1]['reportID']
    full_url = f"https://www.warcraftlogs.com:443/v1/report/fights/{code}?api_key={key}"
    response = requests.get(full_url)
    contents = json.loads(response.text)
    return contents


def get_report_source_id(row):
    key = get_wcl_key()
    name = row[1]['name']
    report_id = row[1]['reportID']

    full_url = f"https://www.warcraftlogs.com:443/v1/report/fights/{report_id}?api_key={key}"
    response = requests.get(full_url)
    contents = json.loads(response.text)

    source_id = None
    for player in contents['friendlies']:
        cur_name = player['name']
        if cur_name == name:
            source_id = player['id']

    return source_id


def get_fight_metadata_bulk(df):
    start_times = []
    end_times = []
    source_ids = []
    for i, row in enumerate(df.iterrows()):
        if i % 10 == 0:
            print(f"processing fight metadata for rank {i}")

        fight_data = get_fight_metadata(row)
        fight_id = row[1]['fightID']
        matching_fight = None
        for fight in fight_data['fights']:  # todo could do something better than linear search here
            if fight['id'] == fight_id:
                matching_fight = fight
                break
        if matching_fight:
            start_times.append(matching_fight['start_time'])
            end_times.append(matching_fight['end_time'])
        else:
            start_times.append(None)
            end_times.append(None)

        # get sourceID for event queries
        source_id = get_report_source_id(row)
        source_ids.append(source_id)

    df['start_time'] = start_times
    df['end_time'] = end_times
    df['source_id'] = source_ids
    return df
