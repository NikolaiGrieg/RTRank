import math

from py.enums.PlayerClass import Priest
from py.enums.Role import Role
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


def get_events_for_all_rankings(df):
    data = []
    for row in df.iterrows():
        report_id = row[1]['reportID']
        start = row[1]['start_time']
        end = row[1]['end_time']
        source_id = row[1]['source_id']
        contents = query_wcl(report_id, source_id, start, end, type="damage-done")

        df = parse_log(contents)
        total_amount, fight_len, amount_per_s = generate_metadata(df, start, end)
        print(f"meta: {total_amount/1000=}k, {fight_len=}, {amount_per_s/1000=}k")  # python 3.8+

        time_ser = transform_to_timeseries(df, start, end)
        assert len(time_ser) == math.ceil(fight_len), f"{len(time_ser)=}, {math.ceil(fight_len)=}"
        data.append(time_ser)

    return data


def generate_data_for_spec(playerclass, playerspec):
    encounters = get_encounter_id_map()
    # cur_encounter = encounters["Maut"]
    encounter_ids = encounters.values()
    for encounter_id in encounter_ids:
        df = get_top_x_rankings(Role.DPS, encounter_id, playerclass, playerspec)

        df = df[:2]  # temp ###

        df = get_fight_metadata_for_rankings(df)  # 2 * len(df) requests
        timeseries = get_events_for_all_rankings(df)  # len(df) requests
        timeseries_as_matrix = extrapolate_aps_linearly(timeseries)

        # todo implement checkpointing, so we can resume at previously checked in value in case of error
        # this will currently replay-append the entire dataset
        generate_lua_db(timeseries_as_matrix, ROOT_DIR + "\\testdata\\Database", playerclass.name, "Shadow",
                        encounter_id=encounter_id, append=None)


if __name__ == '__main__':
    playerclass = Priest()
    playerspec = playerclass.specs["Shadow"]

    generate_data_for_spec(playerclass, playerspec)

    # todo 1: rewrite generate_lua_db to gracefully append data; to support multi-session table generation
    # todo 2: load all shadow encounters
    # todo 3: load all priest encounters (need to fix healing modules)
    # todo x: look into extending this to more classes and fix gui (infer context + user configurable target rank)
