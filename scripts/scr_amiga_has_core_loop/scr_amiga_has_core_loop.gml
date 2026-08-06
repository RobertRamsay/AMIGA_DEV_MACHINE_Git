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
