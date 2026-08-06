/// @desc scr_is_valid_hex_colour(_text)
/// True if _text is 1-3 hex digits — a valid OCS/ECS 12-bit colour value
/// ($0RGB, e.g. "000", "F00", "0FA"). Shared by scr_emit_macro_setbkg
/// (build-time error text) and obj_opcode_node (live validity dots and the
/// colour picker's initial R/G/B round-trip).
function scr_is_valid_hex_colour(_text) {
    var _text_length = string_length(_text);
    var _is_valid = (_text_length >= 1) && (_text_length <= 3);
    var _char_index = 1;

    while (_char_index <= _text_length && _is_valid) {
        var _this_char = string_upper(string_copy(_text, _char_index, 1));

        if (string_pos(_this_char, "0123456789ABCDEF") == 0) {
            _is_valid = false;
        }

        _char_index += 1;
    }

    return _is_valid;
}
