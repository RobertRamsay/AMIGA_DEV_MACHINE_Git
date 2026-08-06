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

// IFF ILBM uses big-endian integers and four-byte ASCII chunk identifiers.
function scr_bitmap_iff_write_u8(_buffer, _value) {
    buffer_write(_buffer, buffer_u8, _value & 255);
}

function scr_bitmap_iff_write_u16(_buffer, _value) {
    scr_bitmap_iff_write_u8(_buffer, _value >> 8);
    scr_bitmap_iff_write_u8(_buffer, _value);
}

function scr_bitmap_iff_write_u32(_buffer, _value) {
    scr_bitmap_iff_write_u8(_buffer, _value >> 24);
    scr_bitmap_iff_write_u8(_buffer, _value >> 16);
    scr_bitmap_iff_write_u8(_buffer, _value >> 8);
    scr_bitmap_iff_write_u8(_buffer, _value);
}

function scr_bitmap_iff_write_id(_buffer, _id) {
    var _i = 1;
    while (_i <= 4) {
        scr_bitmap_iff_write_u8(_buffer, ord(string_char_at(_id, _i)));
        _i += 1;
    }
}

function scr_bitmap_iff_read_u8(_buffer) {
    return buffer_read(_buffer, buffer_u8);
}

function scr_bitmap_iff_read_u16(_buffer) {
    return (scr_bitmap_iff_read_u8(_buffer) << 8) | scr_bitmap_iff_read_u8(_buffer);
}

function scr_bitmap_iff_read_u32(_buffer) {
    return (scr_bitmap_iff_read_u8(_buffer) << 24)
        | (scr_bitmap_iff_read_u8(_buffer) << 16)
        | (scr_bitmap_iff_read_u8(_buffer) << 8)
        | scr_bitmap_iff_read_u8(_buffer);
}

function scr_bitmap_iff_read_id(_buffer) {
    return chr(scr_bitmap_iff_read_u8(_buffer))
        + chr(scr_bitmap_iff_read_u8(_buffer))
        + chr(scr_bitmap_iff_read_u8(_buffer))
        + chr(scr_bitmap_iff_read_u8(_buffer));
}

/// Save the current 320x256 image as a standard uncompressed 5-plane ILBM.
function scr_bitmap_save_iff(_editor) {
    var _path = get_save_filename("Amiga IFF ILBM|*.iff", "TestBitmap.iff");
    if (_path == "") return false;
    if (string_lower(filename_ext(_path)) != ".iff") _path += ".iff";

    var _row_bytes = 40;
    var _body_size = _editor.bitmap_height * 5 * _row_bytes;
    var _total_size = 12 + 28 + 104 + 8 + _body_size;
    var _buffer = buffer_create(_total_size, buffer_fixed, 1);

    scr_bitmap_iff_write_id(_buffer, "FORM");
    scr_bitmap_iff_write_u32(_buffer, _total_size - 8);
    scr_bitmap_iff_write_id(_buffer, "ILBM");

    scr_bitmap_iff_write_id(_buffer, "BMHD");
    scr_bitmap_iff_write_u32(_buffer, 20);
    scr_bitmap_iff_write_u16(_buffer, 320);
    scr_bitmap_iff_write_u16(_buffer, 256);
    scr_bitmap_iff_write_u16(_buffer, 0);
    scr_bitmap_iff_write_u16(_buffer, 0);
    scr_bitmap_iff_write_u8(_buffer, 5);
    scr_bitmap_iff_write_u8(_buffer, 0); // no mask plane
    scr_bitmap_iff_write_u8(_buffer, 0); // uncompressed BODY
    scr_bitmap_iff_write_u8(_buffer, 0);
    scr_bitmap_iff_write_u16(_buffer, 0);
    scr_bitmap_iff_write_u8(_buffer, 10);
    scr_bitmap_iff_write_u8(_buffer, 11);
    scr_bitmap_iff_write_u16(_buffer, 320);
    scr_bitmap_iff_write_u16(_buffer, 256);

    scr_bitmap_iff_write_id(_buffer, "CMAP");
    scr_bitmap_iff_write_u32(_buffer, 32 * 3);
    var _colour = 0;
    while (_colour < 32) {
        scr_bitmap_iff_write_u8(_buffer, _editor.bitmap_colour_r[_colour] * 17);
        scr_bitmap_iff_write_u8(_buffer, _editor.bitmap_colour_g[_colour] * 17);
        scr_bitmap_iff_write_u8(_buffer, _editor.bitmap_colour_b[_colour] * 17);
        _colour += 1;
    }

    scr_bitmap_iff_write_id(_buffer, "BODY");
    scr_bitmap_iff_write_u32(_buffer, _body_size);
    var _y = 0;
    while (_y < 256) {
        var _plane = 0;
        while (_plane < 5) {
            var _byte_x = 0;
            while (_byte_x < _row_bytes) {
                var _packed = 0;
                var _bit = 0;
                while (_bit < 8) {
                    var _pixel_index = _editor.bitmap_pixels[(_y * 320) + (_byte_x * 8) + _bit];
                    if ((_pixel_index & (1 << _plane)) != 0) _packed |= 1 << (7 - _bit);
                    _bit += 1;
                }
                scr_bitmap_iff_write_u8(_buffer, _packed);
                _byte_x += 1;
            }
            _plane += 1;
        }
        _y += 1;
    }

    buffer_save(_buffer, _path);
    buffer_delete(_buffer);
    show_message("IFF ILBM saved:\n" + _path);
    return true;
}

/// Load a 320x256 ILBM with up to five planes. Raw and ByteRun1 BODY chunks
/// are accepted; an optional mask plane is decoded and discarded.
function scr_bitmap_load_iff(_editor) {
    var _path = get_open_filename("Amiga IFF ILBM|*.iff;*.ilbm", "");
    if (_path == "") return false;

    var _buffer = buffer_load(_path);
    var _buffer_size = buffer_get_size(_buffer);
    var _valid = _buffer_size >= 12;
    var _reason = "The file is too short to be an IFF ILBM.";
    var _width = 0;
    var _height = 0;
    var _planes = 0;
    var _masking = 0;
    var _compression = 0;
    var _body_pos = -1;
    var _body_size = 0;
    var _have_bmhd = false;
    var _have_cmap = false;
    var _palette_r = array_create(32, 0);
    var _palette_g = array_create(32, 0);
    var _palette_b = array_create(32, 0);

    if (_valid) {
        buffer_seek(_buffer, buffer_seek_start, 0);
        var _form_id = scr_bitmap_iff_read_id(_buffer);
        var _form_size = scr_bitmap_iff_read_u32(_buffer);
        var _form_type = scr_bitmap_iff_read_id(_buffer);
        _valid = _form_id == "FORM" && _form_type == "ILBM" && _form_size + 8 <= _buffer_size;
        _reason = "The selected file is not an ILBM FORM.";
    }

    var _chunk_pos = 12;
    while (_valid && _chunk_pos + 8 <= _buffer_size) {
        buffer_seek(_buffer, buffer_seek_start, _chunk_pos);
        var _chunk_id = scr_bitmap_iff_read_id(_buffer);
        var _chunk_size = scr_bitmap_iff_read_u32(_buffer);
        var _chunk_data = _chunk_pos + 8;
        var _chunk_next = _chunk_data + _chunk_size + (_chunk_size mod 2);

        if (_chunk_next > _buffer_size) {
            _valid = false;
            _reason = "An IFF chunk extends beyond the end of the file.";
        } else if (_chunk_id == "BMHD") {
            if (_chunk_size < 20) {
                _valid = false;
                _reason = "The ILBM BMHD chunk is incomplete.";
            } else {
                buffer_seek(_buffer, buffer_seek_start, _chunk_data);
                _width = scr_bitmap_iff_read_u16(_buffer);
                _height = scr_bitmap_iff_read_u16(_buffer);
                scr_bitmap_iff_read_u16(_buffer);
                scr_bitmap_iff_read_u16(_buffer);
                _planes = scr_bitmap_iff_read_u8(_buffer);
                _masking = scr_bitmap_iff_read_u8(_buffer);
                _compression = scr_bitmap_iff_read_u8(_buffer);
                _have_bmhd = true;
            }
        } else if (_chunk_id == "CMAP") {
            buffer_seek(_buffer, buffer_seek_start, _chunk_data);
            var _entries = min(32, _chunk_size div 3);
            var _entry = 0;
            while (_entry < _entries) {
                _palette_r[_entry] = clamp(round(scr_bitmap_iff_read_u8(_buffer) / 17), 0, 15);
                _palette_g[_entry] = clamp(round(scr_bitmap_iff_read_u8(_buffer) / 17), 0, 15);
                _palette_b[_entry] = clamp(round(scr_bitmap_iff_read_u8(_buffer) / 17), 0, 15);
                _entry += 1;
            }
            _have_cmap = _entries > 0;
        } else if (_chunk_id == "BODY") {
            _body_pos = _chunk_data;
            _body_size = _chunk_size;
        }

        _chunk_pos = _chunk_next;
    }

    if (_valid && (!_have_bmhd || !_have_cmap || _body_pos < 0)) {
        _valid = false;
        _reason = "The ILBM needs BMHD, CMAP and BODY chunks.";
    }
    if (_valid && (_width != 320 || _height != 256)) {
        _valid = false;
        _reason = "Only 320x256 ILBM images can be loaded into this editor.";
    }
    if (_valid && (_planes < 1 || _planes > 5)) {
        _valid = false;
        _reason = "The ILBM must contain between one and five bitplanes.";
    }
    if (_valid && _masking != 0 && _masking != 1) {
        _valid = false;
        _reason = "Only ILBM files with no mask or a separate mask plane are supported.";
    }
    if (_valid && _compression != 0 && _compression != 1) {
        _valid = false;
        _reason = "Only raw or ByteRun1-compressed ILBM BODY data is supported.";
    }

    var _pixels = array_create(320 * 256, 0);
    if (_valid) {
        var _body_end = _body_pos + _body_size;
        var _row_bytes = 40;
        var _stored_planes = _planes + ((_masking == 1) ? 1 : 0);
        buffer_seek(_buffer, buffer_seek_start, _body_pos);
        var _y = 0;

        while (_valid && _y < 256) {
            var _plane = 0;
            while (_valid && _plane < _stored_planes) {
                var _row = array_create(_row_bytes, 0);
                var _written = 0;

                if (_compression == 0) {
                    while (_valid && _written < _row_bytes) {
                        if (buffer_tell(_buffer) >= _body_end) {
                            _valid = false;
                            _reason = "The ILBM BODY ended before all rows were decoded.";
                        } else {
                            _row[_written] = scr_bitmap_iff_read_u8(_buffer);
                            _written += 1;
                        }
                    }
                } else {
                    while (_valid && _written < _row_bytes) {
                        if (buffer_tell(_buffer) >= _body_end) {
                            _valid = false;
                            _reason = "The ByteRun1 BODY ended before all rows were decoded.";
                        } else {
                            var _control = scr_bitmap_iff_read_u8(_buffer);
                            if (_control <= 127) {
                                var _literal_count = _control + 1;
                                while (_valid && _literal_count > 0) {
                                    if (buffer_tell(_buffer) >= _body_end || _written >= _row_bytes) {
                                        _valid = false;
                                        _reason = "Invalid ByteRun1 literal packet in ILBM BODY.";
                                    } else {
                                        _row[_written] = scr_bitmap_iff_read_u8(_buffer);
                                        _written += 1;
                                        _literal_count -= 1;
                                    }
                                }
                            } else if (_control >= 129) {
                                if (buffer_tell(_buffer) >= _body_end) {
                                    _valid = false;
                                    _reason = "Invalid ByteRun1 repeat packet in ILBM BODY.";
                                } else {
                                    var _repeat_count = 257 - _control;
                                    var _repeat_value = scr_bitmap_iff_read_u8(_buffer);
                                    while (_valid && _repeat_count > 0) {
                                        if (_written >= _row_bytes) {
                                            _valid = false;
                                            _reason = "A ByteRun1 packet overruns an ILBM row.";
                                        } else {
                                            _row[_written] = _repeat_value;
                                            _written += 1;
                                            _repeat_count -= 1;
                                        }
                                    }
                                }
                            }
                            // $80 is a legal ByteRun1 no-op.
                        }
                    }
                }

                if (_valid && _plane < _planes) {
                    var _byte_x = 0;
                    while (_byte_x < _row_bytes) {
                        var _packed = _row[_byte_x];
                        var _bit = 0;
                        while (_bit < 8) {
                            if ((_packed & (1 << (7 - _bit))) != 0) {
                                var _pixel_pos = (_y * 320) + (_byte_x * 8) + _bit;
                                _pixels[_pixel_pos] |= 1 << _plane;
                            }
                            _bit += 1;
                        }
                        _byte_x += 1;
                    }
                }
                _plane += 1;
            }
            _y += 1;
        }
    }

    buffer_delete(_buffer);
    if (!_valid) {
        show_message("IFF load failed:\n" + _reason);
        return false;
    }

    scr_bitmap_push_undo(_editor);
    _editor.bitmap_pixels = _pixels;
    _editor.bitmap_colour_r = _palette_r;
    _editor.bitmap_colour_g = _palette_g;
    _editor.bitmap_colour_b = _palette_b;
    _editor.bitmap_surface_dirty = true;
    _editor.bitmap_dirty_pixels = [];
    _editor.bitmap_asset_dirty = false;
    scr_asset_define_bitmap("TestBitmap", _editor.bitmap_pixels, _editor.bitmap_colour_r, _editor.bitmap_colour_g, _editor.bitmap_colour_b);
    show_message("IFF ILBM loaded:\n" + _path);
    return true;
}
