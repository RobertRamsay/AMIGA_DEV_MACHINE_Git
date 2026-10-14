/// @desc scr_amiga_start_build(_node_array, _project_path, _chipset_mode)
/// Validates + emits all nodes into main.s and starts vasm asynchronously.
/// Every program is a Hunk executable now: the auto-boot loader (or, in DOS
/// boot mode, AmigaDOS) relocates it, so programs of any size share one path.
/// vasm runs in one minimised cmd /C line (no batch file), which captures its messages in vasm.log
/// and writes its exit code to asm.done when it has finished - the manager
/// polls for that file instead of guessing from main.bin's size.
/// Returns a struct { success, error_list, exe_path, uses_dos_loader, done_path, log_path, line_map }
function scr_amiga_start_build(_node_array, _project_path, _chipset_mode) {
    var _count = array_length(_node_array);
    var _uses_dos_loader = global.build_boot_mode == "DOS";
    var _scan = scr_amiga_program_scan(_node_array);

    var _result = {
        success : false,
        error_list : [],
        exe_path : "",
        uses_dos_loader : _uses_dos_loader,
        done_path : "",
        log_path : "",
        line_map : []
    };

    // main.s line bookkeeping: vasm reports "line N of main.s", and the line
    // map turns N back into the node (and CODE-block line) it came from.
    var _asm_text = "";
    var _line_cursor = 1;

    var _prologue = "\tSECTION code,CODE\n";
    if (_chipset_mode == "AGA") {
        _prologue += "; target: AGA (A1200, 68020)\n";
    } else {
        _prologue += "; target: OCS/ECS (A600, 68000)\n";
    }
    _prologue += scr_amiga_build_header_text(_scan);
    _asm_text += _prologue;
    _line_cursor += string_count("\n", _prologue);

    var _i = 0;
    while (_i < _count) {
        var _node = _node_array[_i];
        _node.build_error_text = "";
        var _emit_result = scr_emit_opcode_line(_node);

        if (!_emit_result.is_valid) {
            array_push(_result.error_list, _emit_result.text);
            _node.build_error_text = _emit_result.text;
        }

        var _code_first_line = -1;
        if (_node.is_macro && _node.macro_type == "CODE") {
            _code_first_line = _line_cursor + (scr_code_block_name(_node) != "" ? 1 : 0) + (_node.node_label != "" ? 1 : 0);
        }

        var _line_count = string_count("\n", _emit_result.text) + 1;
        array_push(_result.line_map, {
            first_line : _line_cursor,
            last_line : _line_cursor + _line_count - 1,
            node : _node,
            code_first_line : _code_first_line
        });

        _asm_text += _emit_result.text + "\n";
        _line_cursor += _line_count;
        _i += 1;
    }

    if (array_length(_result.error_list) > 0) {
        show_debug_message("Build aborted - " + string(array_length(_result.error_list)) + " node error(s).");
        return _result;
    }

    var _build_dir = _project_path + "/build";

    if (!directory_exists(_build_dir)) {
        directory_create(_build_dir);
    }

    var _footer = scr_amiga_build_footer_text(_scan, _build_dir);
    if (!_footer.ok) {
        array_push(_result.error_list, "; ERROR: " + _footer.error);
        return _result;
    }
    _asm_text += _footer.text;

    var _asm_path = _build_dir + "/main.s";
    var _bin_path = _build_dir + "/main.bin";
    var _log_path = _build_dir + "/vasm.log";
    var _done_path = _build_dir + "/asm.done";

    var _file = file_text_open_write(_asm_path);
    file_text_write_string(_file, _asm_text);
    file_text_close(_file);

    show_debug_message("scr_amiga_start_build: wrote " + _asm_path);

    // A stale bin, log or done marker would make the poll loop think the new
    // vasm run had already finished.
    if (file_exists(_bin_path)) file_delete(_bin_path);
    if (file_exists(_done_path)) file_delete(_done_path);
    if (file_exists(_log_path)) file_delete(_log_path);

    // -nosym: no HUNK_SYMBOL blocks (smaller disks). The A1200 may use 68020
    // instructions; the A600 build stays strictly 68000.
    var _cpu = _chipset_mode == "AGA" ? "-m68020" : "-m68000";
    var _vasm_args = "-Fhunkexe -kick1hunks -nosym " + _cpu + " -o main.bin main.s";

    // No batch file: antivirus behaviour shields (AVG / Avast IDP.Generic)
    // quarantined ADM for writing a .bat and running it in a hidden cmd.exe.
    // One cmd /C line instead, started minimised (not hidden), in the build
    // folder. /V:ON makes !errorlevel! expand after vasm has run (%errorlevel%
    // would be expanded when the line is parsed). "> asm.done echo" rather than
    // "echo ...> asm.done": "0>" would read as a redirect of handle 0.
    if (file_exists(_build_dir + "/build_asm.bat")) file_delete(_build_dir + "/build_asm.bat");
    var _vasm_native = string_replace_all(global.vasm_path, "/", "\\");
    var _command = "/D /V:ON /S /C \"\"" + _vasm_native + "\" " + _vasm_args
        + " > vasm.log 2>&1 & > asm.done echo exit !errorlevel!\"";

    show_debug_message("scr_amiga_start_build: launching vasm " + _vasm_args);
    // ShellExecute wants a native path: LOCALAPPDATA gives backslashes and GML
    // appends forward slashes, so normalise the working folder.
    var _build_dir_native = string_replace_all(_build_dir, "/", "\\");
    var _started = execute_shell_simple("cmd.exe", _command, "open", 7, _build_dir_native);
    if (!_started) {
        array_push(_result.error_list, "; ERROR: could not start cmd.exe to run vasm");
        return _result;
    }

    _result.success = true;
    _result.exe_path = _bin_path;
    _result.done_path = _done_path;
    _result.log_path = _log_path;
    return _result;
}
