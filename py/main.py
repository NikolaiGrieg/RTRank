import datetime
import math
import pickle
import time
from datetime import timedelta

from py.globals import base_path_to_masterframes
from py.static.PlayerClass import Priest, Druid, Shaman, Monk, Paladin, DeathKnight, Warrior, Hunter, Mage, Rogue, \
    Warlock, DemonHunter
from py.static.Role import Role
from py.etl.eventlog_to_timeseries import parse_log, transform_to_timeseries
from py.etl.rankings_to_encounters import process_rankings
from py.etl.timeseries_to_lua import generate_lua_db
from py.secret_handler import get_wcl_key
from py.utils import generate_metadata, extrapolate_aps_linearly, get_encounter_id_map
from py.wcl.wcl_repository import query_wcl, get_rankings_raw, \
    get_fight_metadata_bulk
from rootfile import ROOT_DIR
from multiprocessing import Pool
from itertools import repeat


def get_top_x_rankings(role, encounter_id, player_class, player_spec):
    key = get_wcl_key()

    rankings_raw = get_rankings_raw(role, encounter_id, player_class, player_spec, key, 1)

    df = process_rankings(rankings_raw)
    # print(df.head())
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
        # total_amount, fight_len, amount_per_s = generate_metadata(df, start, end)
        # print(f"meta: {total_amount/1000=}k, {fight_len=}, {amount_per_s/1000=}k")  # python 3.8+

        time_ser = transform_to_timeseries(df, start, end)
        # assert len(time_ser) == math.ceil(fight_len), f"{len(time_ser)=}, {math.ceil(fight_len)=}" # TODO actually fix the problem
        data.append(time_ser)

    return data


def generate_data_for_spec(playerclass, playerspec):
    encounters = get_encounter_id_map()
    encounter_ids = encounters.values()

    # encounter_ids = list(encounter_ids)[:3]  # temp cap encounters ###
    spec_name = playerclass.get_spec_name_from_idx(playerspec)

    processed_data = get_processed_data(playerclass)
    spec_role = playerclass.get_role_for_spec(spec_name)

    valid_encounters = []
    if processed_data is None or spec_name not in processed_data[0]:  # initial load
        valid_encounters = [x for x in encounter_ids]  # add all
    else:
        for encounter_id in encounter_ids:
            if is_valid_for_processing(spec_name, encounter_id, processed_data[1]):
                valid_encounters.append(encounter_id)

    process_encounters_parallell(valid_encounters, playerclass, playerspec, spec_name, spec_role)


# Deprecated in favour of parallell below
# def process_entry(encounter_id, playerclass, playerspec, spec_name,
#                   spec_role):
#     names, timeseries_as_matrix = make_queries(encounter_id, playerclass, playerspec, spec_role)
#
#     generate_lua_db(timeseries_as_matrix, names, playerclass.name, spec_name,
#                     encounter_id=encounter_id, append=None)


def process_encounters_parallell(encounter_ids, playerclass, playerspec, spec_name, spec_role):
    if len(encounter_ids) > 0:
        with Pool(10) as pool:  # async processing of implicit job matrix
            res = pool.starmap(
                make_queries, zip(encounter_ids, repeat(playerclass), repeat(playerspec), repeat(spec_role)))

        for i, encounter_id in enumerate(encounter_ids):
            names, timeseries_as_matrix = res[i]
            generate_lua_db(timeseries_as_matrix, names, playerclass.name, spec_name,
                            encounter_id=encounter_id, append=None, generate_lua=i == len(encounter_ids) - 1)


def make_queries(encounter_id, playerclass, playerspec, spec_role):
    print(f"Processing encounter {encounter_id}")
    df = get_top_x_rankings(spec_role, encounter_id, playerclass, playerspec)
    df = df[:2]  # temp cap num ranks ###
    names = df['name']

    df = get_fight_metadata_for_rankings(df)  # 2 * len(df) requests

    print(f"Processing events for encounter {encounter_id}")
    timeseries = get_events_for_all_rankings(df, spec_role)  # len(df) requests
    timeseries_as_matrix = extrapolate_aps_linearly(timeseries)
    return names, timeseries_as_matrix


def is_valid_for_processing(spec_name, encounter_id, processed_encounters):
    if encounter_id not in processed_encounters[spec_name]:  # this already has removed stale entries at this point
        return True


def get_processed_data(playerclass):
    """
    :return: processed_specs = list over (partially) processed specs, processed_encounters = dict[spec] = [encounterIDs]
    """
    max_valid_time = timedelta(days=1)

    try:
        with open(base_path_to_masterframes + f"{playerclass.name}.pkl", 'rb') as f:
            master_frames = pickle.load(f)
    except FileNotFoundError:
        return None
    processed_specs = master_frames.keys()
    processed_encounters = {}
    for spec in processed_specs:
        processed_encounters[spec] = []
        for encounter in master_frames[spec].keys():
            if "processed_date" in master_frames[spec][encounter].keys():
                processed_date = datetime.datetime.strptime(master_frames[spec][encounter]["processed_date"],
                                                            "%Y-%m-%d %H:%M:%S")
                if datetime.datetime.now() < processed_date + max_valid_time:
                    processed_encounters[spec].append(encounter)  # we have data for encounter, and it's fresh
    return processed_specs, processed_encounters


if __name__ == '__main__':
    start = time.time()

    classes = [
        Shaman(), Priest(), Druid(), Monk(), Paladin(),
        DeathKnight(), Hunter(), Mage(), Rogue(), Warlock(), Warrior(),
        DemonHunter()
    ]
    for playerclass in classes:  # horribly slow
        for specname, spec in playerclass.specs.items():
            print(f"Processing spec {specname}({spec})")
            generate_data_for_spec(playerclass, spec)

    print()
    print(f"Total time elapsed: {str(time.time() - start)}")

    # todo improve parallell solution to process all encounters for class instead of for spec
