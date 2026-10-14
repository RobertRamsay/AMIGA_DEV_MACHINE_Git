/// @desc Operand modes typed as text rather than a number: LABEL (a branch
/// target or symbol) and regs (a MOVEM register list such as d0-d7/a0-a6).
/// Both keep their text in operand_label_src / operand_label_dst.

function scr_operand_mode_is_text(_mode) {
    return _mode == "LABEL" || _mode == "regs";
}

/// True for a 68000 register list: Dn / An / Rm-Rn items joined by "/".
function scr_reglist_valid(_text) {
    var _items = string_split(string_lower(string_trim(_text)), "/");
    if (array_length(_items) == 0) return false;
    var _i = 0;
    while (_i < array_length(_items)) {
        var _range = string_split(_items[_i], "-");
        if (array_length(_range) < 1 || array_length(_range) > 2) return false;
        var _r = 0;
        while (_r < array_length(_range)) {
            var _reg = _range[_r];
            if (string_length(_reg) != 2) return false;
            var _kind = string_char_at(_reg, 1);
            var _num = string_char_at(_reg, 2);
            if ((_kind != "d" && _kind != "a") || _num < "0" || _num > "7") return false;
            _r += 1;
        }
        _i += 1;
    }
    return true;
}

/// Problem with a text operand ("" = fine). _legal_flags are the entry's
/// src_modes or dst_modes; _side is "source" or "destination".
function scr_operand_text_problem(_mnemonic, _mode, _text, _legal_flags, _side) {
    if (_mode == "regs") {
        if ((scr_addressing_mode_flag("regs") & _legal_flags) == 0) return _mnemonic + " does not take a register list as " + _side;
        if (!scr_reglist_valid(_text)) return "register list needs d0-d7 / a0-a7 items joined by /, e.g. d0-d3/a0";
        return "";
    }
    if (_text == "") return _mnemonic + " has no label target set";
    return "";
}
