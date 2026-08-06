/// @desc scr_save_workspace_to_path(_path)
/// Writes the full workspace — every root, every node (including all
/// macro fields, previously silently dropped by this save path), and the
/// complete global.asset_list (bitmap pixel data, sprite pixel data,
/// palettes) — to _path as JSON.
function scr_save_workspace_to_path(_path) {
    var _root_array = [];

    with (obj_amiga_root_node) {
        var _root_data = { uid : uid, root_type : root_type, node_x : node_x, node_y : node_y };
        array_push(_root_array, _root_data);
    }

    var _node_array = [];

    with (obj_opcode_node) {
        var _node_data = {
            uid : uid,
            node_x : node_x,
            node_y : node_y,
            is_connected : is_connected,
            root_uid : root_uid,
            opcode_mnemonic : opcode_mnemonic,
            opcode_size : opcode_size,
            addressing_mode_src : addressing_mode_src,
            addressing_mode_dst : addressing_mode_dst,
            operand_src : operand_src,
            operand_dst : operand_dst,
            operand_label_src : operand_label_src,
            operand_label_dst : operand_label_dst,
            node_label : node_label,
            displacement_src : operand_extra_src.displacement,
            index_register_src : operand_extra_src.index_register,
            index_register_is_address_src : operand_extra_src.index_register_is_address,
            displacement_dst : operand_extra_dst.displacement,
            index_register_dst : operand_extra_dst.index_register,
            index_register_is_address_dst : operand_extra_dst.index_register_is_address,
            is_macro : is_macro,
            macro_type : macro_type,
            macro_asset_name : macro_asset_name,
            macro_cprbar_band_count : macro_cprbar_band_count,
            macro_cprbar_target_register : macro_cprbar_target_register,
            macro_cprbar_equidistant : macro_cprbar_equidistant,
            macro_cprbar_vp_start : macro_cprbar_vp_start,
            macro_cprbar_vp_end : macro_cprbar_vp_end,
            macro_cprbar_bands : macro_cprbar_bands
        };

        array_push(_node_array, _node_data);
    }

    var _save_data = { roots : _root_array, nodes : _node_array, assets : global.asset_list };
    var _json_text = json_stringify(_save_data);

    var _file = file_text_open_write(_path);
    file_text_write_string(_file, _json_text);
    file_text_close(_file);

    global.workspace_dirty = false;
    show_debug_message("Saved workspace to " + _path);
}
