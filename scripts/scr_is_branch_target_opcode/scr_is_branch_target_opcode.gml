/// @desc scr_is_branch_target_opcode(_mnemonic)
function scr_is_branch_target_opcode(_mnemonic) {
    var _is_target = false;

    if (_mnemonic == "JMP" || _mnemonic == "JSR") {
        _is_target = true;
    }

    var _starts_with_b = (string_char_at(_mnemonic, 1) == "B");
    var _is_length_3 = (string_length(_mnemonic) == 3);

    if (_starts_with_b && _is_length_3) {
        _is_target = true;
    }

    return _is_target;
}