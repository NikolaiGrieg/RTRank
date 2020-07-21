import math
import pickle
import time

from py.static.PlayerClass import Priest, Druid
from py.static.Role import Role
from py.etl.eventlog_to_timeseries import parse_log, transform_to_timeseries
from py.etl.rankings_to_encounters import process_rankings
from py.etl.timeseries_to_lua import generate_lua_db
from py.secret_handler import get_wcl_key
from py.utils import generate_metadata, extrapolate_aps_linearly, get_encounter_id_map
from py.wcl.wcl_repository import query_wcl, get_rankings_raw, \
    get_fight_metadata_bulk
from rootfile import ROOT_DIR


def get_top_x_rankings(role, encounter_id, player_class, player_spec):
    key = get_wcl_key()

    rankings_raw = get_rankings_raw(role, encounter_id, player_class, player_spec, key, 2)

    df = process_rankings(rankings_raw)
    print(df.head())
    return df


def get_fight_metadata_for_rankings(df):
    df = get_fight_metadata_bulk(df)
    return df


def get_events_for_all_rankings(df, role):
    data = []
    for row in df.iterrows():
        report_id = row[1]['reportID']
        start = row[1]['start_time']
        end = row[1]['end_time']
        source_id = row[1]['source_id']

        metric_type = None
        if role == Role.HPS:
            metric_type = "healing"
        elif role == Role.DPS:
            metric_type = "damage-done"

        contents = query_wcl(report_id, source_id, start, end, metric_type=metric_type)

        df = parse_log(contents)
        total_amount, fight_len, amount_per_s = generate_metadata(df, start, end)
        print(f"meta: {total_amount/1000=}k, {fight_len=}, {amount_per_s/1000=}k")  # python 3.8+

        time_ser = transform_to_timeseries(df, start, end)
        assert len(time_ser) == math.ceil(fight_len), f"{len(time_ser)=}, {math.ceil(fight_len)=}"
        data.append(time_ser)

    return data


def generate_data_for_spec(playerclass, playerspec):
    encounters = get_encounter_id_map()
    encounter_ids = encounters.values()

    encounter_ids = list(encounter_ids)[:3]  # temp cap encounters ###
    spec_name = playerclass.get_spec_name_from_idx(playerspec)

    processed_data = get_processed_data(playerclass)

    # todo handle partial spec loads (missing encounters)
    if processed_data is None or spec_name not in processed_data[0]:
        spec_role = playerclass.get_role_for_spec(spec_name)
        for encounter_id in encounter_ids:
            df = get_top_x_rankings(spec_role, encounter_id, playerclass, playerspec)

            df = df[:2]  # temp cap num ranks ###
            names = df['name']

            df = get_fight_metadata_for_rankings(df)  # 2 * len(df) requests
            timeseries = get_events_for_all_rankings(df, spec_role)  # len(df) requests
            timeseries_as_matrix = extrapolate_aps_linearly(timeseries)

            generate_lua_db(timeseries_as_matrix, names, ROOT_DIR + "\\data\\Database", playerclass.name, spec_name,
                            encounter_id=encounter_id, append=None)


def get_processed_data(playerclass):
    """
    :return: processed_specs = list over (partially) processed specs, processed_encounters = dict[spec] = [encounterIDs]
    """
    try:
        with open(ROOT_DIR + f"\\data\\Database{playerclass.name}.pkl", 'rb') as f:  # todo this needs to be in some constants file
            master_frames = pickle.load(f)
    except FileNotFoundError:
        return None
    processed_specs = master_frames.keys()
    processed_encounters = {}
    for spec in processed_specs:
        processed_encounters[spec] = []
        for encounter in master_frames[spec].keys():
            processed_encounters[spec].append(encounter)
    return processed_specs, processed_encounters  # todo need mechanism to handle freshness constraint here also


if __name__ == '__main__':
    start = time.time()
    # playerclass = Priest()
    playerclass = Druid()
    for specname, spec in playerclass.specs.items():
        print(f"Processing spec {specname}({spec})")
        generate_data_for_spec(playerclass, spec)

    print()
    print(f"Total time elapsed: {str(time.time() - start)}")
    # todo user configurable target rank + more classes
    # todo multithread loading to speedup db generation
