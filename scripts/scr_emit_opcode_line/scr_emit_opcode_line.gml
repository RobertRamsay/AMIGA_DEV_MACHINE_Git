/// @desc scr_emit_opcode_line(_node)
/// Returns a struct { text, is_valid }
function scr_emit_opcode_line(_node) {
    var _validation = scr_validate_node_addressing(_node);

    if (!_validation.is_valid) {
        var _error_line = { text : "; ERROR: " + _validation.error_message, is_valid : false };
        return _error_line;
    }

    var _entry = global.opcode_map[$ _node.opcode_mnemonic];
    var _size_suffix = "";

    if (array_length(_entry.sizes) > 0) {
        _size_suffix = "." + _node.opcode_size;
    }

    var _line = "";

    if (_node.node_label != "") {
        _line += _node.node_label + ":\n";
    }

    _line += "\t" + _entry.mnemonic + _size_suffix;

    if (_entry.operand_count >= 1) {
        var _src_operand_value = _node.operand_src;

        if (_node.addressing_mode_src == "LABEL") {
            _src_operand_value = _node.operand_label_src;
        }

        var _src_text = scr_format_operand(_node.addressing_mode_src, _src_operand_value, _node.operand_extra_src);
        _line += " " + _src_text;
    }

    if (_entry.operand_count >= 2) {
        var _dst_operand_value = _node.operand_dst;

        if (_node.addressing_mode_dst == "LABEL") {
            _dst_operand_value = _node.operand_label_dst;
        }

        var _dst_text = scr_format_operand(_node.addressing_mode_dst, _dst_operand_value, _node.operand_extra_dst);
        _line += "," + _dst_text;
    }

    var _result = { text : _line, is_valid : true };
    return _result;
}