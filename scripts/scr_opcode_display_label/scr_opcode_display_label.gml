/// @desc scr_opcode_display_label(_key)
/// Converts an opcode_map key like "MOVE_SR" into a readable label "MOVE SR".
/// Plain keys with no underscore (e.g. "ADD") are returned unchanged.
function scr_opcode_display_label(_key) {
    var _label = string_replace_all(_key, "_", " ");
    return _label;
}