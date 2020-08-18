import json
import os

from rootfile import ROOT_DIR


def get_wcl_key():
    key = os.getenv("wcl_key", None)
    if key is None:
        with open(ROOT_DIR + "/secrets.json", "r") as f:
            return json.load(f)['wcl_key']
    return key


def get_deploy_key():
    key = os.getenv("deploy_token", None)
    if key is None:
        with open(ROOT_DIR + "/secrets.json", "r") as f:
            return json.load(f)['deploy_token']
    return key
