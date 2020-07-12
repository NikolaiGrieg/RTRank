from py.secret_handler import get_wcl_key
from py.wcl_repository import query_wcl, parse_heals_df, generate_metadata, convert_to_timeser


def get_and_print():
    key = get_wcl_key()

    # sample data
    start = "2436824"
    end = "2969349"
    fight_id = "TBGDkbJvdz48P3Na"  # report
    sourceid = "7"  # matching target

    # Load
    contents = query_wcl(fight_id, sourceid, start, end, key)

    # Coerce to df
    df = parse_heals_df(contents)

    # Get metadata to check correctness
    total_heals, fight_len, hps = generate_metadata(df, start, end)
    print(f"meta: {total_heals/1000=}k, {fight_len=}, {hps/1000=}k")  # python 3.8+

    # Cast to time-series and print as lua table
    heal_ser_cumul = convert_to_timeser(df, start)
    print("{", ", ".join([str(int(x[0])) for x in heal_ser_cumul]), "}")


if __name__ == '__main__':
    get_and_print()