def generate_metadata(df, start, end):
    total_heals = sum(df['amount'])

    fight_len = (int(end) - int(start)) / 1000
    hps = int(total_heals / fight_len)
    return total_heals, fight_len, hps
