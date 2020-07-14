import pickle
from datetime import datetime


def generate_lua_db(timeseries, output_path_prefix, player_class, spec, encounter_id=2329):
    """
    :param encounter_id: todo this might want to be a list, or include in timeseries object somehow
    :param timeseries: todo this should eventually include all encounters for this spec
    :param output_path:
    :param spec:
    :return:
    """
    curr_date = datetime.now()
    date_str = curr_date.strftime("%Y-%m-%d %H:%M:%S")
    length = len(timeseries)
    width = len(timeseries[0])  # assume square format (all same length)
    output_path = output_path_prefix + player_class + ".lua"

    # generate lua
    header = "".join(
        ["Database_", player_class, " = {date=\"", date_str, "\",lookup={", "[\"", spec, "\"] = {[", str(encounter_id),
         "] = {}}", "}, size = ", str(length), ", width= ", str(width), "}\n"])

    # data
    lines = []
    for i in range(len(timeseries)):  # might need to format the indexing here
        line = "".join(["F = function() Database_", player_class, ".lookup[\"", spec, "\"][", str(encounter_id), "][",
                        str(i + 1), "] = {", ", ".join([str(int(x)) for x in timeseries[i]]), "} end F() \n"])
        lines.append(line)
    lua_str = "".join([header] + lines)
    lua_str += "\nF = nil"

    with open(output_path, "w+") as f:  # doesn't seem to be able to create file if not existing
        f.write(lua_str)

    with open(output_path.replace(".lua", ".pkl"), 'wb') as f:
        pickle.dump(timeseries, f)
