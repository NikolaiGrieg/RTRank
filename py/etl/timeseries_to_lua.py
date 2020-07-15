import pickle
from datetime import datetime


def get_master_frame_exists(output_path):
    try:
        with open(output_path.replace(".lua", ".pkl"), 'rb') as f:
            master_frames = pickle.load(f)
            exists = True
    except FileNotFoundError:  # todo verify
        return False
    has_data = master_frames.values() is not None
    return exists and has_data


def generate_lua_db(timeseries, output_path_prefix, player_class, spec, encounter_id=2329, append=None):
    """
    Main function for generating lua to file for one encounter,
     can overwrite, append, or append if exists based on the append parameter.
    :param player_class:
    :param output_path_prefix:
    :param append: boolean, True = append, False = truncate insert, None = append if exists
    :param encounter_id: todo this might want to be a list, or include in timeseries object somehow
    :param timeseries:
    :param spec:
    :return:
    """
    output_path = output_path_prefix + player_class + ".lua"

    if append is None:
        append = get_master_frame_exists(output_path)

    if not append:
        master_frames = {spec: {encounter_id: timeseries}}

        # generate lua
        header = generate_lua_db_metadata(player_class, spec, master_frames)

        # data
        lines = generate_lua_db_body(player_class, spec, master_frames)
        lua_str = join_lua_strings([header] + lines)


        # TODO need to create these files here
        # commit to files
        with open(output_path, "w+") as f:  # doesn't seem to be able to create file if not existing
            f.write(lua_str)

        with open(output_path.replace(".lua", ".pkl"), 'wb') as f:
            pickle.dump(master_frames, f)
    else:

        # read prev pickled matrix as m
        with open(output_path.replace(".lua", ".pkl"), 'rb') as f:
            master_frames = pickle.load(f)

        master_frames[spec][encounter_id] = timeseries

        # generate lua header from new m
        lua_header = generate_lua_db_metadata(player_class, spec, master_frames)

        # generate lua body as separate strings
        new_lua_body = generate_lua_db_body(player_class, spec, master_frames)

        # join
        lua_str = join_lua_strings([lua_header] + new_lua_body)

        # truncate insert both files
        with open(output_path, "w+") as f:  # doesn't seem to be able to create file if not existing
            f.write(lua_str)

        with open(output_path.replace(".lua", ".pkl"), 'wb') as f:
            pickle.dump(master_frames, f)


def generate_lua_body_for_encounter(player_class, spec, encounter_id, frame):
    lines = []
    for i in range(len(frame)):
        line = "".join(["F = function() Database_", player_class, ".lookup[\"", spec, "\"][", str(encounter_id), "][",
                        str(i + 1), "] = {", ", ".join([str(int(x)) for x in frame[i]]), "} end F() \n"])
        lines.append(line)
    return lines


def generate_lua_encounter_metadata(player_class, spec, encounter_id, frame):
    frame_len = len(frame[0])
    line = "".join(["F = function() Database_", player_class, ".lookup[\"", spec, "\"][", str(encounter_id), "][\"",
                    "length", "\"] = ", str(frame_len), " end F() \n"])
    return line


def generate_lua_db_body(player_class, spec, master_frames):
    final_strings = []
    for encounter_id, frame in master_frames[spec].items():
        encounter_meta = generate_lua_encounter_metadata(player_class, spec, encounter_id, frame)
        body_strs = generate_lua_body_for_encounter(player_class, spec, encounter_id, frame)
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


def generate_lua_db_metadata(player_class, spec, master_frames):
    encounter_arr = master_frames[spec].keys()
    curr_date = datetime.now()
    date_str = curr_date.strftime("%Y-%m-%d %H:%M:%S")
    length = sum([len(x) for x in master_frames[spec].values()])

    encounter_id_inits = generate_encounter_id_init_table(encounter_arr)

    header = "".join(
        ["Database_", player_class, " = {date=\"", date_str, "\",lookup={", "[\"", spec, "\"] = {", encounter_id_inits,
         "}}, size = ", str(length), "}\n"])
    return header
