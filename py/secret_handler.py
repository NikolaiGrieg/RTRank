import json

from rootfile import ROOT_DIR


def get_wcl_key():
    with open(ROOT_DIR + "/secrets.json", "r") as f:
        return json.load(f)['wcl_key']