/// @desc scr_capture_snapshot()
/// Same data shape as scr_save_layout, kept in memory rather than written to disk.
function scr_capture_snapshot() {
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
            index_register_is_address_dst : operand_extra_dst.index_register_is_address
        };

        array_push(_node_array, _node_data);
    }

    return { roots : _root_array, nodes : _node_array };
}
