function scr_build_adf(_exe_path, _project_path, _volume_name) {
    var _adf_path = _project_path + "/build/disk.adf";
    var _startup_path = _project_path + "/build/startup-sequence";

    // Minimal startup-sequence so the disk autoboots into running the program
    var _file = file_text_open_write(_startup_path);
    file_text_write_string(_file, "main\n");
    file_text_close(_file);

    var _xdf_cmd = "xdftool \"" + _adf_path + "\" create ";
    _xdf_cmd += "+ format \"" + _volume_name + "\" ";
    _xdf_cmd += "+ write \"" + _exe_path + "\" main ";
    _xdf_cmd += "+ makedir s ";
    _xdf_cmd += "+ write \"" + _startup_path + "\" s/startup-sequence ";
    _xdf_cmd += "+ boot install";

    execute_shell_command(_xdf_cmd);

    return _adf_path;
}