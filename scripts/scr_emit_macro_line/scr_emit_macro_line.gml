/// @desc scr_emit_macro_line(_node)
/// Dispatches to the correct macro-type emitter. Returns { text, is_valid }.
function scr_emit_macro_line(_node) {
    if (_node.macro_type == "COPPER_BAR") {
        return scr_emit_macro_copper_bar(_node);
    }

    var _error_result = { text : "; ERROR: unknown macro type '" + _node.macro_type + "'", is_valid : false };
    return _error_result;
}
