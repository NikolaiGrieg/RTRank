import math

import pandas as pd


def parse_log(contents):
    df = pd.DataFrame(contents['events'])
    if 'amount' not in df.columns:
        return None
    df.dropna(inplace=True, subset=['amount'])  # drop events with no amount
    return df


def fill_missing_timesteps(grouped_ser, start, end):
    time_ser = {
        "t": [],
        "amount": []
    }
    counter = -1
    end_idx = math.floor((end - start) / 1000)
    for row in grouped_ser.iterrows():
        counter += 1
        idx = row[0]
        val = row[1]['amount']
        while counter < idx:
            time_ser["t"].append(counter)
            time_ser["amount"].append(0)
            counter += 1

        time_ser["t"].append(counter)
        time_ser["amount"].append(val)

    while counter < end_idx:  # fill in case of missing at the end
        counter += 1
        time_ser["t"].append(counter)
        time_ser["amount"].append(0)

    time_ser_df = pd.DataFrame(time_ser)
    return pd.DataFrame(time_ser_df['amount'])


def transform_to_timeseries(df, start, end):
    pd.options.mode.chained_assignment = None  # supress chained index warning
    df = df[['amount', 'timestamp']]
    df['timestamp'] = df['timestamp'].apply(lambda x: int((x - int(start)) / 1000))  # aggregate to seconds

    grouped_ser = df.groupby(['timestamp']).sum()

    # fill missing timesteps
    time_ser_df = fill_missing_timesteps(grouped_ser, start, end)

    cumul_ser = time_ser_df.cumsum().values
    return cumul_ser


# TODO remove? unused
def parse_heals_df(contents):
    df = pd.DataFrame(contents['events'])
    df_type = df['type']
    keep_ser = df_type.apply(
        lambda x: True if x in ['heal', 'absorbed'] else False)  # doesnt seem to handle smite absorb etc
    df = df[keep_ser]
    return df
