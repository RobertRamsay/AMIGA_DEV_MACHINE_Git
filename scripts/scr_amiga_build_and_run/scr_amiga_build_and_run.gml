function scr_amiga_build_and_run(_node_array, _project_path, _chipset_mode, _volume_name) {
    var _asm_text = "";
    var _i = 0;
    var _count = array_length(_node_array);

    // Emit header block, chipset-specific
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

    if (_build_has_errors) {
        show_debug_message("Build aborted — " + string(array_length(_error_list)) + " opcode error(s).");
        return _error_list;
    }

    var _asm_path = _project_path + "/build/main.s";
    var _file = file_text_open_write(_asm_path);
    file_text_write_string(_file, _asm_text);
    file_text_close(_file);

    // Assemble via vasm (external process)
    var _vasm_cmd = "vasmm68k_mot -Fhunkexe -o \"" + _project_path + "/build/main.exe\" \"" + _asm_path + "\"";
    execute_shell_command(_vasm_cmd);

    // Build ADF containing the assembled executable
    scr_build_adf(_project_path + "/build/main.exe", _project_path, _volume_name);

    // Launch FS-UAE pointing at the built ADF
    var _uae_cmd = "fs-uae --floppy_drive_0=\"" + _project_path + "/build/disk.adf\"";
    execute_shell_command(_uae_cmd);
}