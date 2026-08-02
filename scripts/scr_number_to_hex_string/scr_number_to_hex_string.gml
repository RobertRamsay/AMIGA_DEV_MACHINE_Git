/// @desc scr_number_to_hex_string(_value)
function scr_number_to_hex_string(_value) {
    var _int_value = floor(_value);
    var _hex_digits = "0123456789ABCDEF";
    var _result = "";

    if (_int_value == 0) {
        _result = "0";
    } else {
        while (_int_value > 0) {
            var _digit_value = _int_value mod 16;
            var _digit_char = string_char_at(_hex_digits, _digit_value + 1);
            _result = _digit_char + _result;
            _int_value = _int_value div 16;
        }
    }

    return _result;
}