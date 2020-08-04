import os

from rootfile import ROOT_DIR


def get_newest_build_file():  # RTRank_Beta2.zip
    latest = ""
    latest_major = "alpha"
    latest_minor = 0
    major_ordering = {
        "release": 2,
        "beta": 1,
        "alpha": 0
    }
    for folderName, subfolders, filenames in os.walk(ROOT_DIR + "/build"):
        for filename in filenames:
            if "RTRank" in filename:
                cur_major = ""
                if "release" in filename.lower():
                    cur_major = "release"
                elif "beta" in filename.lower():
                    cur_major = "beta"
                elif "alpha" in filename.lower():
                    cur_major = "alpha"
                else:
                    continue

                nums = [int(s) for s in filename if s.isdigit()]
                if len(nums) == 1:
                    minor = nums[0]
                else:
                    continue

                is_gte_major = major_ordering[cur_major] >= major_ordering[latest_major]
                is_gt_major = major_ordering[cur_major] > major_ordering[latest_major]
                is_gt_minor = minor > latest_minor
                if is_gte_major:
                    if is_gt_major:
                        latest_minor = minor
                        latest_major = cur_major
                        latest = filename
                    elif is_gt_minor:
                        latest_minor = minor
                        latest_major = cur_major
                        latest = filename
    return latest, latest_major, latest_minor


def get_latest_build_and_increment():
    latest, latest_major, latest_minor = get_newest_build_file()
    next_build_name = "RTRank_" + latest_major + str(latest_minor + 1) + ".zip"
    return next_build_name
