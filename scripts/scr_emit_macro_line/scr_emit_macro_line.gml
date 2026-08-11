/// @desc scr_emit_macro_line(_node)
/// Dispatches to the correct macro-type emitter. Returns { text, is_valid }.
function scr_emit_macro_line(_node) {
    if (_node.macro_type == "COPPER_BAR") {
        return scr_emit_macro_copper_bar(_node);
    }

    if (_node.macro_type == "SPRITE_DISPLAY") {
        return scr_emit_macro_sprite_display(_node);
    }

    if (_node.macro_type == "BITMAP_DISPLAY") {
        return scr_emit_macro_bitmap_display(_node);
    }

    if (_node.macro_type == "BOB_BITMAP_TEST") return scr_emit_macro_bob_bitmap_test(_node);
    if (_node.macro_type == "SPRITE_BITMAP_TEST") return scr_emit_macro_sprite_bitmap_test(_node);
    if (_node.macro_type == "GET_BITMAP_BOB") return scr_emit_macro_get_bitmap_bob(_node);
    if (_node.macro_type == "REPLACE_BITMAP_BOB") return scr_emit_macro_replace_bitmap_bob(_node);
    if (_node.macro_type == "DRAW_BOB") return scr_emit_macro_draw_bob(_node);
    if (_node.macro_type == "MOVE_BOB") return scr_emit_macro_move_bob(_node);
    if (_node.macro_type == "MOVE_SPR") return scr_emit_macro_move_spr(_node);

    if (_node.macro_type == "SETBKG") {
        return scr_emit_macro_setbkg(_node);
    }

    var _error_result = { text : "; ERROR: unknown macro type '" + _node.macro_type + "'", is_valid : false };
    return _error_result;
}
