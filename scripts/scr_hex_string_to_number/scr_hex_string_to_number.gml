/// @desc scr_hex_string_to_number(_hex_text)
function scr_hex_string_to_number(_hex_text) {
    var _hex_digits = "0123456789ABCDEF";
    var _upper_text = string_upper(_hex_text);
    var _result = 0;
    var _char_index = 1;
    var _text_length = string_length(_upper_text);

    while (_char_index <= _text_length) {
        var _this_char = string_char_at(_upper_text, _char_index);
        var _digit_pos = string_pos(_this_char, _hex_digits);

        if (_digit_pos > 0) {
            var _digit_value = _digit_pos - 1;
            _result = (_result * 16) + _digit_value;
        }

        _char_index += 1;
    }

    return _result;
}