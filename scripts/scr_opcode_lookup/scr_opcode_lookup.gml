/// @desc scr_opcode_lookup(_key)
/// Combined lookup across both tooltip banks. Falls back to the base mnemonic
/// (text before an underscore) for privileged variants like MOVE_SR, and to
/// the generic bcc/dbcc/scc entry for any of the 14 condition-code variants
/// (BEQ, DBNE, SGT, etc. — all 42 of them share the same underlying text).
/// Returns a struct or undefined.
function scr_opcode_lookup(_key) {
    var _lower_key = string_lower(_key);
    var _result_first = scr_opcode_helper_68k(_lower_key);

    if (_result_first != undefined) {
        return _result_first;
    }

    var _result_second = scr_opcode_helper_68k_part2(_lower_key);

    if (_result_second != undefined) {
        return _result_second;
    }

    var _result_third = scr_opcode_helper_68k_part3(_lower_key);

    if (_result_third != undefined) {
        return _result_third;
    }

    var _underscore_pos = string_pos("_", _lower_key);

    if (_underscore_pos > 0) {
        var _base_key = string_copy(_lower_key, 1, _underscore_pos - 1);
        var _result_base_first = scr_opcode_helper_68k(_base_key);

        if (_result_base_first != undefined) {
            return _result_base_first;
        }

        var _result_base_second = scr_opcode_helper_68k_part2(_base_key);

        if (_result_base_second != undefined) {
            return _result_base_second;
        }
    }

    var _condition_family_key = scr_opcode_condition_family_key(_lower_key);

    if (_condition_family_key != "") {
        return scr_opcode_helper_68k_part2(_condition_family_key);
    }

    return undefined;
}