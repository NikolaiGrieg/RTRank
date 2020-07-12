import pandas as pd


def process_rankings(rankings):
    # contents is indexed by rank => rank = index + 1
    cols = ['name', 'reportID', 'fightID', 'exploit']

    data = {}
    for col in cols:
        data[col] = []

    for ranking in rankings:
        for col in cols:
            data[col].append(ranking[col])

    df = pd.DataFrame(data)
    return df
