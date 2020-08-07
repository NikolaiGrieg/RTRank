import datetime
import pickle
import time
from datetime import timedelta
from itertools import repeat
from multiprocessing import Pool

from setuptools._vendor.ordered_set import OrderedSet

from py.etl.eventlog_to_timeseries import parse_log, transform_to_timeseries
from py.etl.rankings_to_encounters import process_rankings
from py.etl.timeseries_to_lua import generate_lua_db
from py.globals import base_path_to_masterframes
from py.secret_handler import get_wcl_key
from py.static.PlayerClass import Priest, Druid, Shaman, Monk, Paladin, DeathKnight, Warrior, Hunter, Mage, Rogue, \
    Warlock, DemonHunter
from py.static.Role import Role
from py.utils import extrapolate_aps_linearly, get_encounter_id_map
from py.wcl.wcl_repository import query_wcl, get_rankings_raw, \
    get_fight_metadata_bulk


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

        name = row[1]['name']

        metric_type = None
        if role == Role.HPS:
            metric_type = "healing"
        elif role == Role.DPS:
            metric_type = "damage-done"

        contents = query_wcl(report_id, source_id, start, end, metric_type=metric_type)

        df = parse_log(contents)
        if df is None:
            print(f"Error parsing data for {name}")
            data.append(None)
        else:
            time_ser = transform_to_timeseries(df, start, end)
            # assert len(time_ser) == math.ceil(fight_len), f"{len(time_ser)=}, {math.ceil(fight_len)=}" # TODO actually fix the problem
            data.append(time_ser)

    return data


def make_queries(orig_idx, encounter_id, playerclass, playerspec, spec_role):
    print(f"Processing encounter {encounter_id}-{playerspec}")
    # if playerspec == "Feral" and orig_idx == 12:
    #     print()
    df = get_top_x_rankings(spec_role, encounter_id, playerclass, playerspec) ###########
    df = df[:2]  # temp cap num ranks ###
    names = df['name']

    df = get_fight_metadata_for_rankings(df)  # 2 * len(df) requests

    print(f"Processing events for encounter {encounter_id}, idx {orig_idx}")
    timeseries = get_events_for_all_rankings(df, spec_role)  # len(df) requests
    timeseries_as_matrix = extrapolate_aps_linearly(timeseries)
    return names, timeseries_as_matrix, orig_idx


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


def generate_data_for_class(playerclass):
    # get encounters
    encounters = get_encounter_id_map()
    encounter_ids = encounters.values()

    # process valid encounters from encounters
    all_valid_encounters = get_valid_encounters(encounter_ids, playerclass)

    # proceed if last spec to be processed has any encounters to be processed
    if len(list(all_valid_encounters.values())[-1]) > 0:  # assumes ordered dict
        # create job matrix
        all_enc, job_matrix, spec_list = create_job_matrix(all_valid_encounters, playerclass)
        #j_ = list(job_matrix)
        with Pool(len(spec_list)) as pool:  # async processing of each row in the job matrix
            res = pool.starmap(make_queries, job_matrix)

        if len(res) == 0:
            raise Exception("Starmap failure")
        for tmp_idx in range(len(res)):  # res is unordered
            names, timeseries_as_matrix, i = res[tmp_idx]
            spec_name = spec_list[i]
            encounter_id = all_enc[i]
            generate_lua_db(timeseries_as_matrix, names, playerclass.name, spec_name,
                            encounter_id=encounter_id, append=None,
                            generate_lua=tmp_idx == len(all_enc) - 1)  # only generate strings when we have all the data


def create_job_matrix(all_valid_encounters, playerclass):
    all_enc = []
    all_specs = []

    for spec, enc in all_valid_encounters.items():
        all_enc += enc
        if len(enc) > 0:
            all_specs.append([spec for _ in enc])
    spec_list = [item for sublist in all_specs for item in sublist]  # flatten

    roles = []
    for spec_name in OrderedSet(spec_list):
        spec_role = playerclass.get_role_for_spec(spec_name)
        repeats = spec_list.count(spec_name)
        for _ in range(repeats):
            roles.append(spec_role)

    job_matrix = zip(range(len(all_enc)), all_enc, repeat(playerclass), spec_list, roles)
    return all_enc, job_matrix, spec_list


def get_valid_encounters(encounter_ids, playerclass):
    specs = playerclass.specs.keys()

    all_valid_encounters = {}
    for spec_name in specs:
        processed_data = get_processed_data(playerclass)
        valid_encounters = []
        if processed_data is None or spec_name not in processed_data[0]:  # initial load
            valid_encounters = [x for x in encounter_ids]  # add all
        else:
            for encounter_id in encounter_ids:
                if is_valid_for_processing(spec_name, encounter_id, processed_data[1]):
                    valid_encounters.append(encounter_id)
        all_valid_encounters[spec_name] = valid_encounters
    return all_valid_encounters


if __name__ == '__main__':
    start = time.time()

    classes = [
        Shaman(), Priest(), Druid(), Monk(), Paladin(),
        DeathKnight(), Hunter(), Mage(), Rogue(), Warlock(), Warrior(), DemonHunter()
    ]
    for playerclass in classes:  # horribly slow
        print(f"Processing class {playerclass.name}")
        generate_data_for_class(playerclass)  # if we want this to be faster, we need to starmap on the request level

    print()
    print(f"Total time elapsed: {str(time.time() - start)}")
