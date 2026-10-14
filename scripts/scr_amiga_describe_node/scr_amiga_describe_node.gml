/// @desc scr_amiga_describe_node(_node_id)
/// Returns a short readable descriptor for a node — its mnemonic and size
/// for a normal opcode node, or "MACRO: <type>" for a macro node. Used for
/// status log messages (drop, delete, etc).
function scr_amiga_describe_node(_node_id) {
    if (_node_id.is_macro) {
        if (_node_id.macro_type == "CODE") return "CODE BLOCK";
        if (scr_gk_is_node_type(_node_id.macro_type)) return scr_gk_node_label(_node_id.macro_type);
        if (_node_id.macro_type == "PLAY_MOD") return "PLAY MOD " + _node_id.macro_asset_name;
        if (_node_id.macro_type == "STOP_MOD") return "STOP MUSIC";
        if (_node_id.macro_type == "PLAY_SFX") return "PLAY SFX " + _node_id.macro_asset_name;
        return "MACRO: " + _node_id.macro_type;
    }

    var _descriptor = scr_opcode_display_label(_node_id.opcode_mnemonic);

    if (_node_id.opcode_size != "") {
        _descriptor += "." + _node_id.opcode_size;
    }

    return _descriptor;
}
