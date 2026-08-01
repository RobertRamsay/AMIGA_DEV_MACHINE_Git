/// @desc scr_amiga_start_build(_node_array, _project_path, _chipset_mode)
/// Validates + emits all nodes, writes main.s, kicks off vasm via execute_shell_simple.
/// Returns a struct { success, error_list, exe_path }
function scr_amiga_start_build(_node_array, _project_path, _chipset_mode) {
    var _asm_text = "";
    var _i = 0;
    var _count = array_length(_node_array);

    if (_chipset_mode == "AGA") {
        _asm_text += "; target: AGA\n";
    } else {
        _asm_text += "; target: OCS/ECS\n";
    }

    var _build_has_errors = false;
    var _error_list = [];

    while (_i < _count) {
        var _node = _node_array[_i];
        var _emit_result = scr_emit_opcode_line(_node);

        if (!_emit_result.is_valid) {
            _build_has_errors = true;
            array_push(_error_list, _emit_result.text);
        }

        _asm_text += _emit_result.text + "\n";
        _i += 1;
    }

    var _result = {
        success : false,
        error_list : _error_list,
        exe_path : ""
    };

    if (_build_has_errors) {
        show_debug_message("Build aborted — " + string(array_length(_error_list)) + " opcode error(s).");
        return _result;
    }

    var _asm_path = _project_path + "/build/main.s";
    var _exe_path = _project_path + "/build/main.exe";

    var _file = file_text_open_write(_asm_path);
    file_text_write_string(_file, _asm_text);
    file_text_close(_file);

    // Delete any stale exe from a previous build — otherwise the poll loop
    // below would see the OLD file and think the NEW vasm run already finished
    if (file_exists(_exe_path)) {
        file_delete(_exe_path);
    }

    var _vasm_args = "-Fhunkexe -o \"" + _exe_path + "\" \"" + _asm_path + "\"";
    execute_shell_simple("vasmm68k_mot", _vasm_args);

    _result.success = true;
    _result.exe_path = _exe_path;
    return _result;
}