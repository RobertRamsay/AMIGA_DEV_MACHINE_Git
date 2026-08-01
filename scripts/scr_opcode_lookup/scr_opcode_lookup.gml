/// @desc scr_opcode_lookup(_key)
/// Combined lookup across both tooltip banks. Returns a struct or undefined.
function scr_opcode_lookup(_key) {
    var _lower_key = string_lower(_key);
    var _result_first = scr_opcode_helper_68k(_lower_key);

    if (_result_first != undefined) {
        return _result_first;
    } else {
        var _result_second = scr_opcode_helper_68k_part2(_lower_key);
        return _result_second;
    }
}