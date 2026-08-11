/// @desc scr_load_workspace_from_path(_path)
/// Reverses scr_save_workspace_to_path — rebuilds every root, every node
/// (all macro fields included), and restores global.asset_list. Falls
/// back to sensible defaults for any field an older save file predates,
/// so pre-macro saves still load without erroring.
function scr_load_workspace_from_path(_path) {
    if (!file_exists(_path)) {
        show_debug_message("No workspace file found at " + _path);
        return;
    }

    var _file = file_text_open_read(_path);
    var _json_text = "";

    while (!file_text_eof(_file)) {
        _json_text += file_text_read_string(_file);
        file_text_readln(_file);
    }

    file_text_close(_file);

    var _save_data = json_parse(_json_text);

    with (obj_opcode_node) {
        instance_destroy();
    }

    with (obj_amiga_root_node) {
        instance_destroy();
    }

    var _root_array = _save_data.roots;
    var _root_count = array_length(_root_array);
    var _r = 0;

    while (_r < _root_count) {
        var _root_data = _root_array[_r];
        var _new_root = instance_create_layer(_root_data.node_x, _root_data.node_y, "Instances", obj_amiga_root_node);

        _new_root.uid = _root_data.uid;
        _new_root.root_type = _root_data.root_type;
        _new_root.node_x = _root_data.node_x;
        _new_root.node_y = _root_data.node_y;

        _r += 1;
    }

    var _node_array = _save_data.nodes;
    var _node_count = array_length(_node_array);
    var _n = 0;

    while (_n < _node_count) {
        var _node_data = _node_array[_n];
        var _new_node = instance_create_layer(_node_data.node_x, _node_data.node_y, "Instances", obj_opcode_node);

        _new_node.uid = _node_data.uid;
        _new_node.node_x = _node_data.node_x;
        _new_node.node_y = _node_data.node_y;
        _new_node.is_connected = _node_data.is_connected;
        _new_node.root_uid = _node_data.root_uid;
        _new_node.opcode_mnemonic = _node_data.opcode_mnemonic;
        _new_node.opcode_size = _node_data.opcode_size;
        _new_node.addressing_mode_src = _node_data.addressing_mode_src;
        _new_node.addressing_mode_dst = _node_data.addressing_mode_dst;
        _new_node.operand_src = _node_data.operand_src;
        _new_node.operand_dst = _node_data.operand_dst;
        _new_node.operand_label_src = _node_data.operand_label_src;
        _new_node.operand_label_dst = _node_data.operand_label_dst;
        _new_node.node_label = _node_data.node_label;

        _new_node.operand_extra_src.displacement = _node_data.displacement_src;
        _new_node.operand_extra_src.index_register = _node_data.index_register_src;
        _new_node.operand_extra_src.index_register_is_address = _node_data.index_register_is_address_src;

        _new_node.operand_extra_dst.displacement = _node_data.displacement_dst;
        _new_node.operand_extra_dst.index_register = _node_data.index_register_dst;
        _new_node.operand_extra_dst.index_register_is_address = _node_data.index_register_is_address_dst;

        // Older saves predate macro fields entirely — fall back to
        // Create_0.gml's own defaults rather than erroring on a missing key.
        if (variable_struct_exists(_node_data, "is_macro")) {
            _new_node.is_macro = _node_data.is_macro;
            _new_node.macro_type = _node_data.macro_type;
            _new_node.macro_asset_name = _node_data.macro_asset_name;
            if (variable_struct_exists(_node_data, "macro_object_id")) _new_node.macro_object_id = _node_data.macro_object_id;
            if (variable_struct_exists(_node_data, "macro_speed_x")) _new_node.macro_speed_x = _node_data.macro_speed_x;
            if (variable_struct_exists(_node_data, "macro_speed_y")) _new_node.macro_speed_y = _node_data.macro_speed_y;
        }

        if (variable_struct_exists(_node_data, "macro_cprbar_band_count")) {
            _new_node.macro_cprbar_band_count = _node_data.macro_cprbar_band_count;
            _new_node.macro_cprbar_target_register = _node_data.macro_cprbar_target_register;
            _new_node.macro_cprbar_equidistant = _node_data.macro_cprbar_equidistant;
            _new_node.macro_cprbar_vp_start = _node_data.macro_cprbar_vp_start;
            _new_node.macro_cprbar_vp_end = _node_data.macro_cprbar_vp_end;
            _new_node.macro_cprbar_bands = _node_data.macro_cprbar_bands;
        }

        // node_height for SETBKG/CPRBAR is normally set once, at
        // palette-spawn time — loading skips that path entirely, so it
        // would otherwise sit at the generic default (60) forever. Snap it
        // back to the correct taller height here instead.
        if (_new_node.is_macro) {
            _new_node.node_height = 100;
        }

        _n += 1;
    }

    if (variable_struct_exists(_save_data, "assets")) {
        global.asset_list = _save_data.assets;
    }

    global.workspace_dirty = false;
    show_debug_message("Loaded workspace from " + _path);
}
