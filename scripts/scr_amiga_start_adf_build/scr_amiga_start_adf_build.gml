/// @desc scr_amiga_start_adf_build(_exe_path, _project_path, _volume_name)
/// Kicks off xdftool via execute_shell_simple. Returns the adf_path to poll for.
function scr_amiga_start_adf_build(_exe_path, _project_path, _volume_name) {
    var _adf_path = _project_path + "/build/disk.adf";
    var _startup_path = _project_path + "/build/startup-sequence";

    if (file_exists(_adf_path)) {
        file_delete(_adf_path);
    }

    var _file = file_text_open_write(_startup_path);
    file_text_write_string(_file, "main\n");
    file_text_close(_file);

    var _xdf_args = "\"" + _adf_path + "\" create ";
    _xdf_args += "+ format \"" + _volume_name + "\" ";
    _xdf_args += "+ write \"" + _exe_path + "\" main ";
    _xdf_args += "+ makedir s ";
    _xdf_args += "+ write \"" + _startup_path + "\" s/startup-sequence ";
    _xdf_args += "+ boot install";

    execute_shell_simple("xdftool", _xdf_args);

    return _adf_path;
}