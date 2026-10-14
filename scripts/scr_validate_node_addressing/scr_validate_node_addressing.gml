/// @desc scr_validate_node_addressing(_node)
/// Returns a struct { is_valid, error_message }
function scr_validate_node_addressing(_node) {
    var _entry = global.opcode_map[$ _node.opcode_mnemonic];
    var _result = { is_valid : true, error_message : "" };

    if (_entry == undefined) {
        _result.is_valid = false;
        _result.error_message = "Unknown opcode: " + _node.opcode_mnemonic;
        return _result;
    }

    var _size_ok = false;
    var _size_count = array_length(_entry.sizes);
    var _s = 0;

    if (_size_count == 0) {
        _size_ok = true;
    } else {
        while (_s < _size_count) {
            if (_entry.sizes[_s] == _node.opcode_size) {
                _size_ok = true;
            }
            _s += 1;
        }
    }

    if (!_size_ok) {
        _result.is_valid = false;
        _result.error_message = _node.opcode_mnemonic + " does not support size ." + _node.opcode_size;
        return _result;
    }

    if (_entry.operand_count >= 1) {
        if (scr_operand_mode_is_text(_node.addressing_mode_src)) {
            var _src_problem = scr_operand_text_problem(_node.opcode_mnemonic, _node.addressing_mode_src, _node.operand_label_src, _entry.src_modes, "source");
            if (_src_problem != "") {
                _result.is_valid = false;
                _result.error_message = _src_problem;
                return _result;
            }
        } else {
            var _src_flag = scr_addressing_mode_flag(_node.addressing_mode_src);
            var _src_legal = (_src_flag & _entry.src_modes) != 0;

            if (!_src_legal) {
                _result.is_valid = false;
                _result.error_message = _node.opcode_mnemonic + " does not allow " + _node.addressing_mode_src + " as source";
                return _result;
            }
        }
    }

    if (_entry.operand_count >= 2) {
        if (scr_operand_mode_is_text(_node.addressing_mode_dst)) {
            var _dst_problem = scr_operand_text_problem(_node.opcode_mnemonic, _node.addressing_mode_dst, _node.operand_label_dst, _entry.dst_modes, "destination");
            if (_dst_problem != "") {
                _result.is_valid = false;
                _result.error_message = _dst_problem;
                return _result;
            }
        } else {
            var _dst_flag = scr_addressing_mode_flag(_node.addressing_mode_dst);
            var _dst_legal = (_dst_flag & _entry.dst_modes) != 0;

            if (!_dst_legal) {
                _result.is_valid = false;
                _result.error_message = _node.opcode_mnemonic + " does not allow " + _node.addressing_mode_dst + " as destination";
                return _result;
            }
        }
    }

    var _problem = scr_opcode_value_problem(_node);
    if (_problem != "") {
        _result.is_valid = false;
        _result.error_message = _problem;
        return _result;
    }

    // MOVEM moves a register list to or from memory: exactly one side is the list.
    if (_node.opcode_mnemonic == "MOVEM" && ((_node.addressing_mode_src == "regs") == (_node.addressing_mode_dst == "regs"))) {
        _result.is_valid = false;
        _result.error_message = "MOVEM needs a register list (regs) on exactly one side";
        return _result;
    }

    return _result;
}
/// Rules on values and sizes the addressing-mode table cannot express
/// ("" = fine): MOVEQ's signed byte, ADDQ / SUBQ 1-8 and no .B on An,
/// and memory shifts / rotates, which shift one bit of a word.
function scr_opcode_value_problem(_node) {
    var _m = _node.opcode_mnemonic;
    var _src_imm = (_node.addressing_mode_src == "#imm");
    if (_m == "MOVEQ" && _src_imm && (_node.operand_src < -128 || _node.operand_src > 127)) {
        return "MOVEQ takes -128..127 (it sign-extends a byte: " + string(_node.operand_src) + " would not load as written)";
    }
    if (_m == "ADDQ" || _m == "SUBQ") {
        if (_src_imm && (_node.operand_src < 1 || _node.operand_src > 8)) return _m + " adds 1..8 only - use " + (_m == "ADDQ" ? "ADDI" : "SUBI") + " for " + string(_node.operand_src);
        if (_node.addressing_mode_dst == "An" && _node.opcode_size == "B") return _m + ".B cannot target an address register (use .W or .L)";
    }
    if (scr_opcode_is_memory_shift(_node)) {
        if (_node.opcode_size != "W") return _m + " on memory shifts a word: use size .W";
        if (!_src_imm || _node.operand_src != 1) return _m + " on memory shifts by 1 only: set the count to #1";
    } else if ((_m == "ASL" || _m == "ASR" || _m == "LSL" || _m == "LSR" || _m == "ROL" || _m == "ROR" || _m == "ROXL" || _m == "ROXR")
        && _src_imm && (_node.operand_src < 1 || _node.operand_src > 8)) {
        return _m + " #count is 1..8 - put a larger count in a data register";
    }
    return "";
}

/// Shift / rotate with a memory destination: one operand ("ASL.W (A0)").
function scr_opcode_is_memory_shift(_node) {
    var _m = _node.opcode_mnemonic;
    var _shift = (_m == "ASL" || _m == "ASR" || _m == "LSL" || _m == "LSR" || _m == "ROL" || _m == "ROR" || _m == "ROXL" || _m == "ROXR");
    return _shift && _node.addressing_mode_dst != "Dn";
}
