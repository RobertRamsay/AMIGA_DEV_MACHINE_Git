/// @desc scr_emit_macro_setbkg(_node)
/// Writes _node.macro_asset_name — a 1-4 digit OCS/ECS hex colour, e.g.
/// "000" for black or "F00" for red — straight into COLOR00 ($DFF180).
/// Amiga has no separate border register the way C64 splits $D020/$D021:
/// COLOR00 covers both background and border at once. Returns a struct
/// { text, is_valid }, same shape as scr_emit_opcode_line.
function scr_emit_macro_setbkg(_node) {
    var _colour_text = _node.macro_asset_name;
    var _text_length = string_length(_colour_text);
    var _is_valid_hex = (_text_length >= 1) && (_text_length <= 4);
    var _char_index = 1;

    while (_char_index <= _text_length && _is_valid_hex) {
        var _this_char = string_upper(string_copy(_colour_text, _char_index, 1));

        if (string_pos(_this_char, "0123456789ABCDEF") == 0) {
            _is_valid_hex = false;
        }

        _char_index += 1;
    }

    if (!_is_valid_hex) {
        var _error_result = { text : "; ERROR: SETBKG colour must be 1-4 hex digits, e.g. 000 or F00 (asset field is currently '" + _colour_text + "')", is_valid : false };
        return _error_result;
    }

    var _colour_value = scr_hex_string_to_number(_colour_text);

    var _lines = "";

    if (_node.node_label != "") {
        _lines += _node.node_label + ":\n";
    }

    // 14676352 = $DFF180 = COLOR00, matching the decimal-literal convention
    // every other macro emitter in this codebase already uses for absolute
    // custom-chip addresses.
    _lines += "\tMOVE.W #" + string(_colour_value) + ",14676352.L";

    var _result = { text : _lines, is_valid : true };
    return _result;
}
