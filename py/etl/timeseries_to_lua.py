import pickle
from datetime import datetime


def generate_lua_db(timeseries, output_path_prefix, player_class, spec, encounter_id=2329, append=False):
    """
    TODO this function should be able to gracefully append lua so we don't
     need to get all specs/encounters in the same session.
    :param player_class:
    :param output_path_prefix:
    :param append: boolean, True = append, False = truncate insert
    :param encounter_id: todo this might want to be a list, or include in timeseries object somehow
    :param timeseries:
    :param spec:
    :return:
    """
    output_path = output_path_prefix + player_class + ".lua"

    # TODO this doesn't work for more than 2 series, as the structure doesn't support mapping old encounter IDs
    #  withour parsing the old lua file, as the information is not contained in the pkl
    if not append:
        # generate lua
        header = generate_lua_db_metadata([encounter_id], timeseries, player_class, spec)

        # data
        lines = generate_lua_db_body(encounter_id, player_class, spec, timeseries)
        lua_str = join_lua_strings([header] + lines)
        # commit to files

        with open(output_path, "w+") as f:  # doesn't seem to be able to create file if not existing
            f.write(lua_str)

        with open(output_path.replace(".lua", ".pkl"), 'wb') as f:
            pickle.dump(timeseries, f)
    else:

        # read prev pickled matrix as m
        with open(output_path.replace(".lua", ".pkl"), 'rb') as f:
            old_matrix = pickle.load(f)

        # append current matrix to m
        new_matrix = old_matrix + timeseries

        # generate lua header from new m
        lua_header = generate_lua_db_metadata([2329, encounter_id], new_matrix, player_class, spec)

        # generate lua body as separate strings
        old_lua_body = generate_lua_db_body(2329, player_class, spec, old_matrix)
        new_lua_body = generate_lua_db_body(encounter_id, player_class, spec, timeseries)

        # join
        lua_str = join_lua_strings([lua_header] + old_lua_body + new_lua_body)

        # truncate insert both files
        with open(output_path, "w+") as f:  # doesn't seem to be able to create file if not existing
            f.write(lua_str)

        # TODO can't just concatenate these, as we don't know which rows are which encounters
        # with open(output_path.replace(".lua", ".pkl"), 'wb') as f:
        #     pickle.dump(new_matrix, f)


def generate_lua_db_body(encounter_id, player_class, spec, timeseries):
    lines = []
    for i in range(len(timeseries)):  # might need to format the indexing here
        line = "".join(["F = function() Database_", player_class, ".lookup[\"", spec, "\"][", str(encounter_id), "][",
                        str(i + 1), "] = {", ", ".join([str(int(x)) for x in timeseries[i]]), "} end F() \n"])
        lines.append(line)
    return lines


def join_lua_strings(string_arr):
    lua_str = "".join(string_arr)
    lua_str += "\nF = nil"
    return lua_str


def generate_encounter_id_init_table(encounter_ids):
    num_encounters = len(encounter_ids)
    full_str = ""
    for i, encounter in enumerate(encounter_ids):
        cur_str = f"[{encounter}] = " + "{}"
        if i < num_encounters:  # skip last
            cur_str += ","
        full_str += cur_str
    return full_str


def generate_lua_db_metadata(encounter_ids, timeseries, player_class, spec):
    curr_date = datetime.now()
    date_str = curr_date.strftime("%Y-%m-%d %H:%M:%S")
    length = len(timeseries)
    width = len(
        timeseries[0])  # assume square format (all same length) TODO this no longer holds, need better structure

    encounter_id_inits = generate_encounter_id_init_table(encounter_ids)

    header = "".join(
        ["Database_", player_class, " = {date=\"", date_str, "\",lookup={", "[\"", spec, "\"] = {", encounter_id_inits,
            "}}, size = ", str(length), ", width= ", str(width), "}\n"])
    return header
