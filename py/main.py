from py.enums.PlayerClass import PlayerSpec
from py.enums.Role import Role
from py.etl.eventlog_to_timeseries import parse_log, transform_to_timeseries
from py.etl.rankings_to_encounters import process_rankings
from py.etl.timeseries_to_lua import generate_lua_db
from py.secret_handler import get_wcl_key
from py.wcl.wcl_repository import query_wcl, parse_heals_df, generate_metadata, convert_to_timeser, get_rankings_raw, \
    get_fight_metadata_bulk
from rootfile import ROOT_DIR


# def get_and_print():
#     key = get_wcl_key()
#
#     # sample data
#     start = "2436824"
#     end = "2969349"
#     fight_id = "TBGDkbJvdz48P3Na"  # report
#     sourceid = "7"  # matching target
#
#     # Load
#     contents = query_wcl(fight_id, sourceid, start, end, key)
#
#     # Coerce to df
#     df = parse_heals_df(contents)
#
#     # Get metadata to check correctness
#     total_heals, fight_len, hps = generate_metadata(df, start, end)
#     print(f"meta: {total_heals/1000=}k, {fight_len=}, {hps/1000=}k")  # python 3.8+
#
#     # Cast to time-series and print as lua table
#     heal_ser_cumul = convert_to_timeser(df, start)
#     print("{", ", ".join([str(int(x[0])) for x in heal_ser_cumul]), "}")


def get_top_x_rankings(role, encounter_id, player_spec):
    key = get_wcl_key()

    rankings_raw = get_rankings_raw(role, encounter_id, None, key, 2)

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

        time_ser = transform_to_timeseries(df, start)
        data.append(time_ser)

    return data


if __name__ == '__main__':
    df = get_top_x_rankings(Role.DPS, 2329, PlayerSpec.Fire_Mage)  # wrathion #  floor(x/100) requests
    df = df[:100]  # todo remove

    df = get_fight_metadata_for_rankings(df)  # 2 * len(df) requests
    timeseries = get_events_for_all_rankings(df)  # len(df) requests
    generate_lua_db(timeseries, ROOT_DIR + "\\testdata\\Database.lua")
    # todo add some metadata for each series
