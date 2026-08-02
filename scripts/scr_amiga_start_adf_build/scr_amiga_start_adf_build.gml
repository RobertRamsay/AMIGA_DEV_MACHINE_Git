/// @desc scr_amiga_start_adf_build(_bin_path, _project_path, _volume_name)
/// Writes _bin_path directly as a custom bootblock via xdftool. Returns the adf_path to poll for.
function scr_amiga_start_adf_build(_bin_path, _project_path, _volume_name) {
    var _build_dir = _project_path + "/build";

    if (!directory_exists(_build_dir)) {
        directory_create(_build_dir);
    }

    var _adf_path = _build_dir + "/disk.adf";

    if (file_exists(_adf_path)) {
        file_delete(_adf_path);
    }

    show_debug_message("scr_amiga_start_adf_build: writing custom bootblock for " + _adf_path);

    var _xdf_args = "\"" + _adf_path + "\" create ";
    _xdf_args += "+ format \"" + _volume_name + "\" ";
    _xdf_args += "+ boot write \"" + _bin_path + "\"";

    execute_shell_simple(global.xdftool_path, _xdf_args);

    return _adf_path;
}