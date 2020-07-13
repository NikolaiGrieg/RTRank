import math
import pickle
import random

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt

from rootfile import ROOT_DIR

with open(ROOT_DIR + "\\testdata\\Database.pkl", 'rb') as f:
    timeser = pickle.load(f)


def rmse(predictions, targets):
    return np.sqrt(((predictions - targets) ** 2).mean())


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


def cumulative_mat_to_aps(square_timeser):
    norm_mat = []
    for ser in square_timeser:
        norm_ser = []
        for t, val in enumerate(ser):
            norm_val = val / t
            norm_ser.append(norm_val)
        norm_mat.append(np.array(norm_ser))
    return norm_mat


def process(matrix):
    # 1 vs rest validation
    all_preds = []  # list of lists with y_hat for each t(index)
    all_loss_at_t = []  # list of lists with abs loss for each t(index)
    all_pred_rank_at_t = []

    # todo this needs to be function
    for j in range(len(matrix)):
        current = matrix[j]

        current_yhat_at_t = []
        abs_loss_at_t = []
        pred_rank_at_t = []

        current_y = matrix[j][-1]

        # prediction algorithm here
        for t in range(len(current)):
            curr_val = current[t]

            # if t == len(current) - 5:
            #     print(t)
            # print()

            # find closest cumulative match O(len(timeser))
            closest_dist = math.inf
            closest_idx = -1
            for i in range(len(matrix)):
                if i != j:
                    # if len(timeser[i]) > t:  # else skip
                    matching_val = matrix[i][t]
                    matching_dist = math.fabs(curr_val - matching_val)
                    if matching_dist < closest_dist:
                        closest_dist = matching_dist
                        closest_idx = i

            final_cumul_amount = matrix[closest_idx][-1]
            current_yhat_at_t.append(final_cumul_amount)
            abs_loss_at_t.append(math.fabs(final_cumul_amount - current_y))
            pred_rank_at_t.append(closest_idx + 1)

        all_preds.append(np.array(current_yhat_at_t))
        all_loss_at_t.append(np.array(abs_loss_at_t))
        all_pred_rank_at_t.append(np.array(pred_rank_at_t))
    return all_preds, all_loss_at_t, all_pred_rank_at_t


# plot
def plot_results(all_preds, ytitle='y_hat', num_traces=5, truncate_at=400):
    # pad
    maxlen = min(truncate_at, max([len(x) for x in all_preds]))
    preds_fixed_len = []
    for pred in all_preds:
        preds_fixed_len.append(pred[:truncate_at])
    x = np.linspace(0, maxlen, maxlen)

    sampled_preds = random.sample(preds_fixed_len, min(len(preds_fixed_len), num_traces))
    for pred in sampled_preds:
        plt.plot(x, pred)
    plt.ylabel(ytitle)
    plt.xlabel('t')
    plt.show()


def plot_aggregates(arrays, truncate_at=400):
    maxlen = min(truncate_at, max([len(x) for x in arrays]))
    arr_fixed_len = []
    for arr in arrays:
        arr_fixed_len.append(arr[:truncate_at])
    x = np.linspace(0, maxlen, maxlen)

    for i, pred in enumerate(arr_fixed_len):
        plt.plot(x, pred, label=str(i))
    plt.ylabel('statistic')
    plt.xlabel('t')
    plt.legend(loc="upper left")
    plt.show()


def get_abs_rank_diff_at_t(all_pred_ranks):
    all_rank_diffs = []
    for i, ser in enumerate(all_pred_ranks):
        cur_rank_diffs = []
        actual_rank = i + 1
        for y_hat in ser:
            cur_rank_diffs.append(math.fabs(y_hat - actual_rank))  # rank = idx + 1
        all_rank_diffs.append(cur_rank_diffs)
    return all_rank_diffs


def moving_average(a, n):
    ret = np.cumsum(a, dtype=float)
    ret[n:] = ret[n:] - ret[:-n]
    return ret[n - 1:] / n


def smooth_series(jagged_matrix, window):
    smooth_mat = []
    if type(jagged_matrix) == list:  # more than 1 dim
        for ser in jagged_matrix:
            smooth_mat.append(moving_average(ser, window))
    else:
        return moving_average(jagged_matrix, window)
    return smooth_mat


def get_mae_at_t(arrays):
    matrix = np.stack(arrays, axis=0)
    mae = matrix.mean(axis=1)
    return mae


# config
window_size = 10

# preprocess
square_timeser = extrapolate_aps_linearly(timeser)

# time_normalized_mat = cumulative_mat_to_aps(square_timeser)

# process
all_preds, all_loss_at_t, all_pred_rank_at_t = process(square_timeser)

all_rank_diffs = get_abs_rank_diff_at_t(all_pred_rank_at_t)


plot_results(smooth_series(all_rank_diffs, window_size), ytitle=f'Abs rank diff (smoothed w={window_size})',
             num_traces=20)
plot_results(smooth_series(all_loss_at_t, window_size), f"Abs loss (smoothed w={window_size})", num_traces=20)

# aggregates:
ma_rank_at_t = get_mae_at_t(smooth_series(all_rank_diffs, window_size))
ma_loss_at_t = get_mae_at_t(smooth_series(all_loss_at_t, window_size))

ma_rank_at_t_smooth = smooth_series(ma_rank_at_t, 10)
ma_loss_at_t_smooth = smooth_series(ma_loss_at_t, 10)

plot_aggregates([ma_rank_at_t_smooth])  # appears to rise significantly after a while
plot_aggregates([ma_loss_at_t_smooth])  # todo refactor
