/// @desc scr_clone_opcode_node(_source_node)
/// Creates a full copy of _source_node — every opcode/macro field, at the
/// same position. Arrays and structs are deep-copied (operand_extra_src/
/// dst, macro_cprbar_bands) so the clone and original never share mutable
/// state. uid is left as whatever Create_0.gml auto-generated for the new
/// instance — never copied from the source. Returns the new instance.
function scr_clone_opcode_node(_source_node) {
    var _new_node = instance_create_layer(_source_node.node_x, _source_node.node_y, "Instances", obj_opcode_node);

    _new_node.node_width = _source_node.node_width;
    _new_node.node_height = _source_node.node_height;
    _new_node.is_connected = _source_node.is_connected;
    _new_node.root_uid = _source_node.root_uid;
    _new_node.opcode_mnemonic = _source_node.opcode_mnemonic;
    _new_node.opcode_size = _source_node.opcode_size;
    _new_node.addressing_mode_src = _source_node.addressing_mode_src;
    _new_node.addressing_mode_dst = _source_node.addressing_mode_dst;
    _new_node.operand_src = _source_node.operand_src;
    _new_node.operand_dst = _source_node.operand_dst;
    _new_node.operand_label_src = _source_node.operand_label_src;
    _new_node.operand_label_dst = _source_node.operand_label_dst;
    _new_node.node_label = _source_node.node_label;

    _new_node.operand_extra_src = {
        displacement : _source_node.operand_extra_src.displacement,
        index_register : _source_node.operand_extra_src.index_register,
        index_register_is_address : _source_node.operand_extra_src.index_register_is_address
    };

    _new_node.operand_extra_dst = {
        displacement : _source_node.operand_extra_dst.displacement,
        index_register : _source_node.operand_extra_dst.index_register,
        index_register_is_address : _source_node.operand_extra_dst.index_register_is_address
    };

    _new_node.is_macro = _source_node.is_macro;
    _new_node.macro_type = _source_node.macro_type;
    _new_node.macro_asset_name = _source_node.macro_asset_name;
    _new_node.macro_cprbar_band_count = _source_node.macro_cprbar_band_count;
    _new_node.macro_cprbar_target_register = _source_node.macro_cprbar_target_register;
    _new_node.macro_cprbar_equidistant = _source_node.macro_cprbar_equidistant;
    _new_node.macro_cprbar_vp_start = _source_node.macro_cprbar_vp_start;
    _new_node.macro_cprbar_vp_end = _source_node.macro_cprbar_vp_end;

    _new_node.macro_cprbar_bands = array_create(16, "000");
    array_copy(_new_node.macro_cprbar_bands, 0, _source_node.macro_cprbar_bands, 0, 16);

    return _new_node;
}
