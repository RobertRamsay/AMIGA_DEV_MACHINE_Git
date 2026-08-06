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

        // `boot install boot1x` normally loads boot1x.bin from amitools'
        // Python package data. The standalone PyInstaller xdftool executable
        // does not reliably contain that data directory, leaving an otherwise
        // valid OFS disk with no boot code. Materialise the standard 38-byte
        // Workbench 1.x loader here and let `boot write` install/checksum it.
        var _boot1x_path = _build_dir + "/boot1x.bin";
        var _boot1x_bytes = [
             67, 250,   0,  24,  78, 172, 255, 160,
             74, 128, 103,  10,  32,  64,  32, 104,
              0,  22, 112,   0,  78, 117, 112, 255,
             96, 250, 100, 111, 115,  46, 108, 105,
             98, 114,  97, 114, 121,   0
        ];
        var _boot1x_buffer = buffer_create(array_length(_boot1x_bytes), buffer_fixed, 1);
        var _boot1x_index = 0;

        while (_boot1x_index < array_length(_boot1x_bytes)) {
            buffer_write(_boot1x_buffer, buffer_u8, _boot1x_bytes[_boot1x_index]);
            _boot1x_index += 1;
        }

        buffer_save(_boot1x_buffer, _boot1x_path);
        buffer_delete(_boot1x_buffer);

        show_debug_message("scr_amiga_start_adf_build: writing DOS-loaded bitmap executable to " + _adf_path);
        _xdf_args += "+ format \"" + _volume_name + "\" ";
        _xdf_args += "+ makedir S ";
        _xdf_args += "+ write \"" + _startup_path + "\" S/startup-sequence ";
        _xdf_args += "+ write \"" + _bin_path + "\" main ";
        _xdf_args += "+ boot write \"" + _boot1x_path + "\"";
    } else {
        show_debug_message("scr_amiga_start_adf_build: writing custom bootblock for " + _adf_path);
        _xdf_args += "+ format \"" + _volume_name + "\" ";
        _xdf_args += "+ boot write \"" + _bin_path + "\"";
    }

    execute_shell_simple(global.xdftool_path, _xdf_args);

    return _adf_path;
}
