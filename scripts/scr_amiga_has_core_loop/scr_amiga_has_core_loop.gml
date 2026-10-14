/// @desc scr_amiga_has_core_loop(_node_array)
/// True if at least one branch/jump instruction in _node_array targets a
/// label defined by some node in that same array — meaning execution can
/// return to an earlier point and hold there forever, rather than running
/// off the end into unowned memory. Unlike C64 (which falls back to BASIC
/// via the kernal on RTS), a plain Amiga boot program has nowhere to fall
/// back to — with no loop, it just keeps executing whatever garbage bytes
/// follow it until the CPU traps on an illegal instruction.
function scr_amiga_has_core_loop(_node_array) {
    var _label_set = {};
    var _count = array_length(_node_array);
    var _i = 0;

    while (_i < _count) {
        if (_node_array[_i].node_label != "") {
            _label_set[$ _node_array[_i].node_label] = true;
        }

        _i += 1;
    }

    _i = 0;

    while (_i < _count) {
        var _node = _node_array[_i];

        // A CODE block holding its own BRA/JMP is trusted to loop; vasm checks
        // that the target exists.
        if (_node.is_macro && _node.macro_type == "CODE" && scr_amiga_code_has_jump(_node.macro_code_text)) {
            return true;
        }

        if (!_node.is_macro) {
            var _target_label = "";

            if (scr_is_branch_target_opcode(_node.opcode_mnemonic) && _node.addressing_mode_src == "LABEL") {
                _target_label = _node.operand_label_src;
            } else if (scr_is_dbcc_opcode(_node.opcode_mnemonic) && _node.addressing_mode_dst == "LABEL") {
                _target_label = _node.operand_label_dst;
            }

            if (_target_label != "" && variable_struct_exists(_label_set, _target_label)) {
                return true;
            }
        }

        _i += 1;
    }

    return false;
}

/// True if _text has an unconditional BRA or JMP instruction (not in a comment).
function scr_amiga_code_has_jump(_text) {
    var _lines = string_split(string_replace_all(_text, "\r", ""), "\n");
    var _l = 0;
    while (_l < array_length(_lines)) {
        var _line = _lines[_l];
        var _semi = string_pos(";", _line);
        if (_semi > 0) _line = string_copy(_line, 1, _semi - 1);
        var _first_char = string_char_at(_line, 1);
        if (_first_char == "*") _line = "";
        var _tokens = string_split_ext(string_lower(string_replace_all(_line, "\t", " ")), [" "], true);
        var _t = 0;
        // Skip a column-1 label (with or without colon).
        if (array_length(_tokens) > 0 && _first_char != " " && _first_char != "\t") _t = 1;
        if (array_length(_tokens) > 0 && string_char_at(_tokens[0], string_length(_tokens[0])) == ":") _t = 1;
        // A column-1 BRA/JMP is auto-indented at emit time, so it counts too.
        if (_t == 1 && (string_copy(_tokens[0], 1, 3) == "bra" || string_copy(_tokens[0], 1, 3) == "jmp")) _t = 0;
        if (_t < array_length(_tokens)) {
            var _mnemonic = _tokens[_t];
            var _dot = string_pos(".", _mnemonic);
            if (_dot > 1) _mnemonic = string_copy(_mnemonic, 1, _dot - 1);
            if (_mnemonic == "bra" || _mnemonic == "jmp") return true;
        }
        _l += 1;
    }
    return false;
}
