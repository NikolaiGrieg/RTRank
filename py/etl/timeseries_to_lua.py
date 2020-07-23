import pickle
from datetime import datetime

from py.globals import base_path_to_lua_dbs, base_path_to_masterframes


def get_master_frame_exists(output_path):
    try:
        with open(output_path, 'rb') as f:
            master_frames = pickle.load(f)
            exists = True
    except FileNotFoundError:
        return False
    has_data = master_frames.values() is not None
    return exists and has_data


def generate_lua_db(timeseries, names, player_class, spec, encounter_id, append=None):
    """
    Main function for generating lua to file for one encounter,
     can overwrite, append, or append if exists based on the append parameter.
    :param encounter_id:
    :param player_class:
    :param output_path_prefix:
    :param append: boolean, True = append, False = truncate insert, None = append if exists
    :param timeseries:
    :param spec:
    :return:
    """
    output_path_lua = base_path_to_lua_dbs + player_class + ".lua"
    output_path_py = base_path_to_masterframes + player_class + ".pkl"

    if append is None:
        append = get_master_frame_exists(output_path_py)

    if not append:
        init_create_datafiles(encounter_id, output_path_lua, output_path_py, player_class, spec, timeseries, names)
    else:
        extend_datafiles(encounter_id, output_path_lua, output_path_py, player_class, spec, timeseries, names)


def extend_datafiles(encounter_id, output_path_lua, output_path_py, player_class, spec, timeseries, names):
    # read prev pickled matrix
    with open(output_path_py, 'rb') as f:
        master_frames = pickle.load(f)
    recorded_specs = master_frames.keys()

    #  maybe refactor to default dict
    encounter_base = {  # overwrite with these values
        "data": timeseries,
        "names": names,
        "processed_date": datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    }
    if spec in recorded_specs:
        master_frames[spec][encounter_id] = encounter_base
    else:
        master_frames[spec] = {
            encounter_id: encounter_base
        }

    # generate lua header from scratch
    lua_header = generate_lua_db_metadata(player_class, recorded_specs, master_frames)

    # generate lua body as separate strings
    new_lua_body = []
    for spec_key in master_frames.keys():
        new_lua_body += generate_lua_db_body(player_class, spec_key, master_frames)

    lua_str = join_lua_strings([lua_header] + new_lua_body)

    # overwrite both files
    with open(output_path_lua, "w+", encoding='utf-8') as f:  # doesn't seem to be able to create file if not existing
        f.write(lua_str)
    with open(output_path_py, 'wb') as f:
        pickle.dump(master_frames, f)


def init_create_datafiles(encounter_id, output_path_lua, output_path_py, player_class, spec, timeseries, names):
    master_frames = {
        spec: {
            encounter_id: {
                "data": timeseries,
                "names": names
            }
        }
    }

    # generate lua
    header = generate_lua_db_metadata(player_class, [spec], master_frames)

    # data
    lines = generate_lua_db_body(player_class, spec, master_frames)
    lua_str = join_lua_strings([header] + lines)

    # commit to files
    with open(output_path_lua, "w+", encoding='utf-8') as f:  # doesn't seem to be able to create file if not existing
        f.write(lua_str)
    with open(output_path_py, 'wb') as f:
        pickle.dump(master_frames, f)


def generate_lua_body_for_encounter(player_class, spec, encounter_id, frame, names):
    lines = []

    for i in range(len(frame)):  # TODO inject names here
        name_str = "[\"name\"] = \"" + names[i] + "\""
        line = "".join(["F = function() Database_", player_class, ".lookup[\"", spec, "\"][", str(encounter_id), "][",
                        str(i + 1), "] = {", ", ".join([str(int(x)) for x in frame[i]]), ", ", name_str, "} end F() \n"])
        lines.append(line)
    return lines


def generate_lua_encounter_metadata(player_class, spec, encounter_id, frame):
    frame_len = len(frame[0])
    rank_count = len(frame)
    line = "".join(["F = function() Database_", player_class, ".lookup[\"", spec, "\"][", str(encounter_id),
                    "] = {[\"length\"] = ", str(frame_len),
                    ", [\"rank_count\"] = ", str(rank_count), "}", " end F() \n"])

    return line


def generate_lua_db_body(player_class, spec, master_frames):
    final_strings = []
    for encounter_id, entry in master_frames[spec].items():
        frame = entry["data"]
        names = entry["names"]
        encounter_meta = generate_lua_encounter_metadata(player_class, spec, encounter_id, frame)
        body_strs = generate_lua_body_for_encounter(player_class, spec, encounter_id, frame, names)
        final_strings.append(encounter_meta)
        final_strings += body_strs
    return final_strings


def join_lua_strings(string_arr):
    lua_str = "".join(string_arr)
    lua_str += "\nF = nil"
    return lua_str


def generate_encounter_id_init_table(encounter_ids):
    num_encounters = len(encounter_ids)
    full_str = ""
    for i, encounter in enumerate(encounter_ids):
        cur_str = f"[{encounter}] = " + "{}"
        if i < num_encounters - 1:  # skip last
            cur_str += ", "
        full_str += cur_str
    return full_str


def generate_lookup_init(specs, master_frames):
    spec_strings = []
    for spec in specs:
        encounter_arr = master_frames[spec].keys()

        encounter_id_inits = generate_encounter_id_init_table(encounter_arr)
        spec_strings.append("".join(["[\"", spec, "\"] = {", encounter_id_inits, "}"]))
    return ",".join(spec_strings)


def generate_lua_db_metadata(player_class, specs, master_frames):
    curr_date = datetime.now()
    date_str = curr_date.strftime("%Y-%m-%d %H:%M:%S")
    length = sum([sum([len(x) for x in master_frames[spec].values()]) for spec in specs])  # total length along 2d

    header = "".join(
        ["Database_", player_class, " = {date=\"", date_str, "\",lookup={", generate_lookup_init(specs, master_frames),
         "}, size = ", str(length), "}\n"])
    return header
