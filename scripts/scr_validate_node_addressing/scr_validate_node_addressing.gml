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
        if (_node.addressing_mode_src == "LABEL") {
            if (_node.operand_label_src == "") {
                _result.is_valid = false;
                _result.error_message = _node.opcode_mnemonic + " has no label target set";
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
        if (_node.addressing_mode_dst == "LABEL") {
            if (_node.operand_label_dst == "") {
                _result.is_valid = false;
                _result.error_message = _node.opcode_mnemonic + " has no label target set";
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

    return _result;
}