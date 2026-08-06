/// @desc scr_amiga_start_build(_node_array, _project_path, _chipset_mode)
/// Validates + emits all nodes, writes main.s, kicks off vasm via execute_shell_simple.
/// Returns a struct { success, error_list, exe_path }
function scr_amiga_start_build(_node_array, _project_path, _chipset_mode) {
    var _asm_text = "";
    var _i = 0;
    var _count = array_length(_node_array);
    var _uses_dos_loader = false;

    while (_i < _count) {
        if (_node_array[_i].is_macro && _node_array[_i].macro_type == "BITMAP_DISPLAY") {
            _uses_dos_loader = true;
        }
        _i += 1;
    }

    if (_uses_dos_loader) _asm_text += "\tSECTION code,CODE\n";

    if (_chipset_mode == "AGA") {
        _asm_text += "; target: AGA\n";
    } else {
        _asm_text += "; target: OCS/ECS\n";
    }

    var _build_has_errors = false;
    var _error_list = [];
    _i = 0;

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
        exe_path : "",
        uses_dos_loader : _uses_dos_loader
    };

    if (_build_has_errors) {
        show_debug_message("Build aborted — " + string(array_length(_error_list)) + " opcode error(s).");
        return _result;
    }

    var _build_dir = _project_path + "/build";

    if (!directory_exists(_build_dir)) {
        directory_create(_build_dir);
        show_debug_message("scr_amiga_start_build: created " + _build_dir);
    }

    var _asm_path = _build_dir + "/main.s";
    var _bin_path = _build_dir + "/main.bin";

    var _file = file_text_open_write(_asm_path);
    file_text_write_string(_file, _asm_text);
    file_text_close(_file);

    show_debug_message("scr_amiga_start_build: wrote " + _asm_path);

    // Delete any stale bin from a previous build — otherwise the poll loop
    // below would see the OLD file and think the NEW vasm run already finished
    if (file_exists(_bin_path)) {
        file_delete(_bin_path);
    }

    var _output_format = _uses_dos_loader ? "-Fhunkexe -kick1hunks" : "-Fbin";
    var _vasm_args = _output_format + " -o \"" + _bin_path + "\" \"" + _asm_path + "\"";
    show_debug_message("scr_amiga_start_build: launching " + global.vasm_path + " " + _vasm_args);
    execute_shell_simple(global.vasm_path, _vasm_args);
	
    _result.success = true;
    _result.exe_path = _bin_path;
    return _result;
}
