/// Native editable bitmap save/load and one-way PNG export.

function scr_bitmap_save_native(_editor) {
    var _path = get_save_filename("Amiga Dev Bitmap|*.admbitmap", "TestBitmap.admbitmap");
    if (_path == "") return false;
    if (string_lower(filename_ext(_path)) != ".admbitmap") _path += ".admbitmap";

    var _data = scr_bitmap_capture_snapshot(_editor);
    _data.format = "AMIGA_DEV_MACHINE_BITMAP";
    _data.version = 1;
    _data.width = _editor.bitmap_width;
    _data.height = _editor.bitmap_height;
    var _file = file_text_open_write(_path);
    file_text_write_string(_file, json_stringify(_data));
    file_text_close(_file);
    _editor.bitmap_native_path = _path;
    show_message("Bitmap saved:\n" + _path);
    return true;
}

function scr_bitmap_load_native(_editor) {
    var _path = get_open_filename("Amiga Dev Bitmap|*.admbitmap", "");
    if (_path == "") return false;

    var _file = file_text_open_read(_path);
    var _text = "";
    while (!file_text_eof(_file)) {
        _text += file_text_readln(_file);
    }
    file_text_close(_file);

    var _data = undefined;
    try {
        _data = json_parse(_text);
    } catch (_error) {
        show_message("Bitmap load failed:\n" + string(_error));
        return false;
    }
    if (!is_struct(_data)
    || !variable_struct_exists(_data, "format")
    || _data.format != "AMIGA_DEV_MACHINE_BITMAP"
    || _data.width != 320 || _data.height != 256
    || array_length(_data.pixels) != 320 * 256
    || array_length(_data.colour_r) != 32
    || array_length(_data.colour_g) != 32
    || array_length(_data.colour_b) != 32) {
        show_message("This is not a valid 320x256 Amiga Dev Machine bitmap.");
        return false;
    }

    scr_bitmap_push_undo(_editor);
    scr_bitmap_restore_snapshot(_editor, _data);
    _editor.bitmap_native_path = _path;
    show_message("Bitmap loaded:\n" + _path);
    return true;
}

function scr_bitmap_export_png(_editor) {
    var _path = get_save_filename("PNG Image|*.png", "TestBitmap.png");
    if (_path == "") return false;
    if (string_lower(filename_ext(_path)) != ".png") _path += ".png";

    var _surface = surface_create(_editor.bitmap_width, _editor.bitmap_height);
    var _buffer = buffer_create(_editor.bitmap_width * _editor.bitmap_height * 4, buffer_fixed, 1);
    buffer_seek(_buffer, buffer_seek_start, 0);
    var _i = 0;
    while (_i < array_length(_editor.bitmap_pixels)) {
        var _index = _editor.bitmap_pixels[_i];
        var _packed = (_editor.bitmap_colour_r[_index] * 17)
            + ((_editor.bitmap_colour_g[_index] * 17) << 8)
            + ((_editor.bitmap_colour_b[_index] * 17) << 16)
            + 4278190080;
        buffer_write(_buffer, buffer_u32, _packed);
        _i += 1;
    }
    buffer_set_surface(_buffer, _surface, 0);
    surface_save(_surface, _path);
    buffer_delete(_buffer);
    surface_free(_surface);
    show_message("PNG exported:\n" + _path + "\n\nPNG export is one-way; reload the .admbitmap file for further editing.");
    return true;
}
