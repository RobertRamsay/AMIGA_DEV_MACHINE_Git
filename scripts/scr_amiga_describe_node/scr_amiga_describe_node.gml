/// @desc scr_amiga_describe_node(_node_id)
/// Returns a short readable descriptor for a node — its mnemonic and size
/// for a normal opcode node, or "MACRO: <type>" for a macro node. Used for
/// status log messages (drop, delete, etc).
function scr_amiga_describe_node(_node_id) {
    if (_node_id.is_macro) {
        return "MACRO: " + _node_id.macro_type;
    }

    var _descriptor = scr_opcode_display_label(_node_id.opcode_mnemonic);

    if (_node_id.opcode_size != "") {
        _descriptor += "." + _node_id.opcode_size;
    }

    return _descriptor;
}
