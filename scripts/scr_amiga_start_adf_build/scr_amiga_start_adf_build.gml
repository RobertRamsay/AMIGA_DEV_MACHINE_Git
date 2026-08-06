/// @desc scr_amiga_start_adf_build(_bin_path, _project_path, _volume_name, _uses_dos_loader)
/// Small programs retain the direct bootblock route. Bitmap programs are Hunk
/// executables stored on an OFS disk and launched by S/startup-sequence.
function scr_amiga_start_adf_build(_bin_path, _project_path, _volume_name, _uses_dos_loader) {
    var _build_dir = _project_path + "/build";

    if (!directory_exists(_build_dir)) {
        directory_create(_build_dir);
    }

    var _adf_path = _build_dir + "/disk.adf";

    if (file_exists(_adf_path)) {
        file_delete(_adf_path);
    }

    var _xdf_args = "\"" + _adf_path + "\" create ";

    if (_uses_dos_loader) {
        var _startup_path = _build_dir + "/startup-sequence";
        var _startup_file = file_text_open_write(_startup_path);
        file_text_write_string(_startup_file, "main\n");
        file_text_close(_startup_file);
        show_debug_message("scr_amiga_start_adf_build: writing DOS-loaded bitmap executable to " + _adf_path);
        _xdf_args += "+ format \"" + _volume_name + "\" ";
        _xdf_args += "+ makedir S ";
        _xdf_args += "+ write \"" + _startup_path + "\" S/startup-sequence ";
        _xdf_args += "+ write \"" + _bin_path + "\" main ";
        _xdf_args += "+ boot install boot1x";
    } else {
        show_debug_message("scr_amiga_start_adf_build: writing custom bootblock for " + _adf_path);
        _xdf_args += "+ format \"" + _volume_name + "\" ";
        _xdf_args += "+ boot write \"" + _bin_path + "\"";
    }

    execute_shell_simple(global.xdftool_path, _xdf_args);

    return _adf_path;
}
