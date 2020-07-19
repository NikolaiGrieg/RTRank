import json

import numpy as np

from rootfile import ROOT_DIR


def generate_metadata(df, start, end):
    total_heals = sum(df['amount'])

    fight_len = (int(end) - int(start)) / 1000
    hps = int(total_heals / fight_len)
    return total_heals, fight_len, hps


def extrapolate_aps_linearly(jagged_matrix):  # aps = amount per sec (dps/hps)
    """
    Will extrapolate hps/dps to cover a longer period while maintaining the same hps/dps.
    :param jagged_matrix:
    :return: square matrix as list of list
    """
    maxlen = max([len(x) for x in jagged_matrix])
    square_mat = []
    for ser in jagged_matrix:
        if ser.shape[1] > 1:
            pad_ser = list(ser[:, 1])
        else:
            pad_ser = [x[0] for x in ser]
        aps = pad_ser[-1] / len(ser)
        while len(pad_ser) < maxlen:
            prev_val = pad_ser[-1]
            pad_ser.append(int(prev_val + aps))
        square_mat.append(np.array(pad_ser))
    return square_mat


def get_encounter_id_map():
    with open(ROOT_DIR + "\\py\\static\\Encounters.json") as f:
        encounters = json.load(f)['encounters']
    encounters_reversed = {}
    for d in encounters:
        encounters_reversed[d['name']] = d['id']

    return encounters_reversed
