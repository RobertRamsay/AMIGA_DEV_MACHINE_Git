/// @desc scr_split_lines(_text)
/// Splits _text on newline characters into an array of individual lines.
function scr_split_lines(_text) {
    var _lines = [];
    var _remaining = _text;
    var _newline_pos = string_pos("\n", _remaining);

    while (_newline_pos > 0) {
        var _line = string_copy(_remaining, 1, _newline_pos - 1);
        array_push(_lines, _line);
        _remaining = string_copy(_remaining, _newline_pos + 1, string_length(_remaining) - _newline_pos);
        _newline_pos = string_pos("\n", _remaining);
    }

    array_push(_lines, _remaining);
    return _lines;
}