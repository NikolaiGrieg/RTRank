import pandas as pd


def parse_log(contents):
    df = pd.DataFrame(contents['events'])
    return df


def transform_to_timeseries(df, start):  # todo handle cases where there are timesteps with no events
    df = df[['amount', 'timestamp']]
    df['timestamp'].apply(lambda x: int((x - int(start)) / 1000))  # aggregate to seconds
    grouped_ser = df.groupby(['timestamp']).sum()

    cumul_ser = grouped_ser.cumsum().values
    return cumul_ser


# TODO remove? unused
def parse_heals_df(contents):
    df = pd.DataFrame(contents['events'])
    df_type = df['type']
    keep_ser = df_type.apply(
        lambda x: True if x in ['heal', 'absorbed'] else False)  # doesnt seem to handle smite absorb etc
    df = df[keep_ser]
    return df
