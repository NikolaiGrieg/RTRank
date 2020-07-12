import json


def get_wcl_key():
    with open("secrets.json", "r") as f:
        return json.load(f)['wcl_key']