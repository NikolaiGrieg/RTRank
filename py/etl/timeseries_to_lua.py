import pickle
from datetime import datetime
import pandas as pd


def generate_lua_db(timeseries, output_path):
    curr_date = datetime.now()
    date_str = curr_date.strftime("%Y-%m-%d %H:%M:%S")
    length = len(timeseries)

    # generate lua
    header = "".join(["Database = {date=\"", date_str, "\",lookup={}, size = ", str(length), "}\n"])

    # data
    lines = []
    for i in range(len(timeseries)):
        line = "".join(["F = function() Database.lookup[",
                        str(i + 1), "] = {", ", ".join([str(int(x[0])) for x in timeseries[i]]), "} end F() \n"])
        lines.append(line)
    lua_str = "".join([header] + lines)
    lua_str += "\nF = nil"

    with open(output_path, "w+") as f:  # doesn't seem to be able to create file if not existing
        f.write(lua_str)

    with open(output_path.replace(".lua", ".pkl"), 'wb') as f:
        pickle.dump(timeseries, f)
