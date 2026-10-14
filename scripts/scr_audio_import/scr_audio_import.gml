/// Importing ProTracker modules and sound samples (WAV, IFF 8SVX, raw).

/// @desc scr_audio_mod_info(_buffer)
/// Checks a buffer holding a module. Only 4-channel 31-sample ProTracker
/// modules ("M.K.", "M!K!", "FLT4", "4CHN") are accepted. Never reads past
/// the end of the buffer. Returns
///   { ok, err, warn, tag, title, positions, restart, patterns, samples_used,
///     sample_names, sample_lengths, data_at, expected_size }
function scr_audio_mod_info(_buffer) {
    var _info = {
        ok : false, err : "", warn : "", tag : "", title : "",
        positions : 0, restart : 0, patterns : 0, samples_used : 0,
        sample_names : [], sample_lengths : [], data_at : 0, expected_size : 0
    };
    var _size = buffer_get_size(_buffer);
    if (_size < AUDIO_MOD_HEADER_SIZE + AUDIO_MOD_PATTERN_SIZE) {
        _info.err = "That file is too small to be a ProTracker module";
        return _info;
    }
    var _tag = scr_audio_peek_tag(_buffer, 1080);
    _info.tag = _tag;
    if (_tag != "M.K." && _tag != "M!K!" && _tag != "FLT4" && _tag != "4CHN") {
        var _digits_chn = string_copy(_tag, 2, 3) == "CHN" && string_digits(string_char_at(_tag, 1)) != "";
        var _digits_ch = string_copy(_tag, 3, 2) == "CH" && string_digits(string_copy(_tag, 1, 2)) == string_copy(_tag, 1, 2);
        if (_digits_chn || _digits_ch || _tag == "FLT8" || _tag == "CD81" || _tag == "OKTA" || _tag == "OCTA" || _tag == "TDZ8") {
            _info.err = "Module has more than 4 channels (" + _tag + "): Paula plays 4-channel MODs only";
        } else {
            _info.err = "Not a 31-sample ProTracker MOD (15-sample Soundtracker files: re-save as M.K. in a tracker)";
        }
        return _info;
    }
    var _positions = buffer_peek(_buffer, 950, buffer_u8);
    if (_positions < 1 || _positions > 128) {
        _info.err = "That MOD is damaged (bad song length)";
        return _info;
    }
    // Pattern count: highest entry in the whole order table, as ProTracker.
    var _top = 0;
    var _o = 0;
    while (_o < 128) {
        _top = max(_top, buffer_peek(_buffer, 952 + _o, buffer_u8));
        _o += 1;
    }
    if (_top >= 100) {
        _top = 0;
        _o = 0;
        while (_o < _positions) {
            _top = max(_top, buffer_peek(_buffer, 952 + _o, buffer_u8));
            _o += 1;
        }
    }
    if (_top >= 100) {
        _info.err = "That MOD is damaged (too many patterns)";
        return _info;
    }
    var _patterns = _top + 1;
    var _data_at = AUDIO_MOD_HEADER_SIZE + _patterns * AUDIO_MOD_PATTERN_SIZE;
    if (_data_at > _size) {
        _info.err = "That MOD is cut short (patterns missing)";
        return _info;
    }
    var _total = 0;
    var _s = 0;
    while (_s < 31) {
        var _p = 20 + _s * 30;
        var _len = scr_audio_peek_be16(_buffer, _p + 22) * 2;
        array_push(_info.sample_names, scr_audio_peek_text(_buffer, _p, 22));
        array_push(_info.sample_lengths, _len);
        if (_len > 2) _info.samples_used += 1;
        _total += _len;
        _s += 1;
    }
    _info.ok = true;
    _info.title = scr_audio_peek_text(_buffer, 0, 20);
    _info.positions = _positions;
    var _restart = buffer_peek(_buffer, 951, buffer_u8);
    _info.restart = (_restart < _positions) ? _restart : 0;
    _info.patterns = _patterns;
    _info.data_at = _data_at;
    _info.expected_size = _data_at + _total;
    if (_info.expected_size > _size) _info.warn = "Some sample data is missing from the end of that MOD";
    return _info;
}

/// Name for a module file: "mod.tune" (Amiga style) and "tune.mod" both give "tune".
function scr_audio_mod_base_name(_path) {
    var _file = filename_name(_path);
    if (string_lower(string_copy(_file, 1, 4)) == "mod.") return string_delete(_file, 1, 4);
    return filename_change_ext(_file, "");
}

/// @desc scr_audio_import_mod(_path)
/// Imports a 4-channel ProTracker module as a MOD asset (original bytes
/// kept). Returns the new asset name, or "" on failure (status message shown).
function scr_audio_import_mod(_path) {
    if (!file_exists(_path)) {
        scr_set_status_message("Can't find " + filename_name(_path), c_red);
        return "";
    }
    var _buffer = buffer_load(_path);
    if (_buffer == -1 || !buffer_exists(_buffer)) {
        scr_set_status_message("Couldn't read " + filename_name(_path), c_red);
        return "";
    }
    var _info = scr_audio_mod_info(_buffer);
    if (!_info.ok) {
        buffer_delete(_buffer);
        scr_set_status_message("MOD import failed: " + _info.err, c_red);
        return "";
    }
    var _length = buffer_get_size(_buffer);
    var _name = scr_audio_unique_name(scr_audio_mod_base_name(_path));
    scr_audio_define_mod(_name, scr_audio_buffer_b64(_buffer, _length), _length, _info.title,
        _info.positions, _info.patterns, _info.samples_used, filename_name(_path));
    buffer_delete(_buffer);
    global.audio_last_import_name = _name;
    scr_mark_workspace_dirty();
    if (_info.warn != "") scr_set_status_message(_info.warn, c_orange);
    scr_set_status_message("Imported MOD " + _name + " (" + string(_length) + " bytes, "
        + string(_info.positions) + " positions, " + string(_info.patterns) + " patterns)", c_lime);
    return _name;
}

/// One mono value (-1..1) of frame _frame of a decoded source description
/// { buffer, offset, channels, bps, format, frames } (format: "u8", "s8",
/// "int", "float"). Frames past the end read as the last frame.
function scr_audio_source_value(_src, _frame) {
    var _f = clamp(_frame, 0, _src.frames - 1);
    var _sum = 0;
    var _c = 0;
    while (_c < _src.channels) {
        var _p = _src.offset + (_f * _src.channels + _c) * _src.bps;
        var _v = 0;
        if (_src.format == "s8") {
            _v = buffer_peek(_src.buffer, _p, buffer_s8) / 128;
        } else if (_src.format == "u8") {
            _v = (buffer_peek(_src.buffer, _p, buffer_u8) - 128) / 128;
        } else if (_src.format == "float") {
            _v = buffer_peek(_src.buffer, _p, buffer_f32);
        } else if (_src.bps == 2) {
            _v = buffer_peek(_src.buffer, _p, buffer_s16) / 32768;
        } else if (_src.bps == 3) {
            var _w = buffer_peek(_src.buffer, _p, buffer_u8) | (buffer_peek(_src.buffer, _p + 1, buffer_u8) << 8)
                | (buffer_peek(_src.buffer, _p + 2, buffer_u8) << 16);
            if (_w >= 8388608) _w -= 16777216;
            _v = _w / 8388608;
        } else {
            _v = buffer_peek(_src.buffer, _p, buffer_s32) / 2147483648;
        }
        _sum += _v;
        _c += 1;
    }
    return _sum / _src.channels;
}

/// Parses a RIFF WAVE buffer into a source description, or a struct with
/// err set. Reads the first "smpl" loop when present.
function scr_audio_wav_source(_buffer) {
    var _size = buffer_get_size(_buffer);
    var _src = { err : "", buffer : _buffer, offset : -1, channels : 0, bps : 0, format : "int",
        frames : 0, rate : 0, loop : false, loop_start : 0, loop_end : 0, volume : 64, owned_buffer : -1 };
    var _format = 0;
    var _bits = 0;
    var _data_length = 0;
    var _o = 12;
    while (_o + 8 <= _size) {
        var _id = scr_audio_peek_tag(_buffer, _o);
        var _len = buffer_peek(_buffer, _o + 4, buffer_u32);
        if (_id == "fmt " && _o + 24 <= _size) {
            _format = buffer_peek(_buffer, _o + 8, buffer_u16);
            _src.channels = buffer_peek(_buffer, _o + 10, buffer_u16);
            _src.rate = buffer_peek(_buffer, _o + 12, buffer_u32);
            _bits = buffer_peek(_buffer, _o + 22, buffer_u16);
            if (_format == 65534 && _len >= 26 && _o + 34 <= _size) _format = buffer_peek(_buffer, _o + 32, buffer_u16);
        }
        if (_id == "data") {
            _src.offset = _o + 8;
            _data_length = min(_len, _size - _src.offset);
        }
        if (_id == "smpl" && _len >= 60 && _o + 68 <= _size) {
            if (buffer_peek(_buffer, _o + 8 + 28, buffer_u32) > 0) {
                _src.loop = true;
                _src.loop_start = buffer_peek(_buffer, _o + 8 + 44, buffer_u32);
                _src.loop_end = buffer_peek(_buffer, _o + 8 + 48, buffer_u32) + 1;
            }
        }
        _o += 8 + _len + (_len mod 2);
    }
    _src.bps = _bits div 8;
    if (_format != 1 && _format != 3) {
        _src.err = "Unsupported WAV encoding (only uncompressed PCM or float WAVs)";
        return _src;
    }
    if (_src.offset < 0 || _src.channels < 1 || _src.rate < 1000 || _src.bps < 1 || _src.bps > 4) {
        _src.err = "That WAV file is damaged or uses an unsupported layout";
        return _src;
    }
    if (_format == 3 && _src.bps != 4) {
        _src.err = "Only 32-bit float WAVs are supported";
        return _src;
    }
    _src.format = (_format == 3) ? "float" : ((_src.bps == 1) ? "u8" : "int");
    _src.frames = _data_length div (_src.bps * _src.channels);
    if (_src.loop && (_src.loop_end <= _src.loop_start || _src.loop_start >= _src.frames)) _src.loop = false;
    return _src;
}

/// Parses an IFF 8SVX buffer. Fibonacci-delta compressed bodies are
/// decoded into a new buffer (stored in _src.owned_buffer, caller deletes).
function scr_audio_8svx_source(_buffer) {
    var _size = buffer_get_size(_buffer);
    var _src = { err : "", buffer : _buffer, offset : -1, channels : 1, bps : 1, format : "s8",
        frames : 0, rate : 8287, loop : false, loop_start : 0, loop_end : 0, volume : 64, owned_buffer : -1 };
    var _one_shot = 0;
    var _repeat = 0;
    var _compression = 0;
    var _have_header = false;
    var _body_length = 0;
    var _o = 12;
    while (_o + 8 <= _size) {
        var _id = scr_audio_peek_tag(_buffer, _o);
        var _len = scr_audio_peek_be32(_buffer, _o + 4);
        if (_id == "VHDR" && _o + 28 <= _size) {
            _have_header = true;
            _one_shot = scr_audio_peek_be32(_buffer, _o + 8);
            _repeat = scr_audio_peek_be32(_buffer, _o + 12);
            _src.rate = scr_audio_peek_be16(_buffer, _o + 20);
            _compression = buffer_peek(_buffer, _o + 23, buffer_u8);
            var _volume = scr_audio_peek_be32(_buffer, _o + 24);
            _src.volume = clamp(round(_volume * 64 / 65536), 0, 64);
        }
        if (_id == "BODY") {
            _src.offset = _o + 8;
            _body_length = min(_len, _size - _src.offset);
        }
        _o += 8 + _len + (_len mod 2);
    }
    if (!_have_header || _src.offset < 0) {
        _src.err = "That 8SVX file has no VHDR or BODY chunk";
        return _src;
    }
    if (_src.rate < 1000) _src.rate = 8287;
    if (_compression == 1) {
        var _deltas = [-34, -21, -13, -8, -5, -3, -2, -1, 0, 1, 2, 3, 5, 8, 13, 21];
        var _count = max(0, (_body_length - 2) * 2);
        if (_count < 2) {
            _src.err = "That 8SVX file is empty";
            return _src;
        }
        var _out = buffer_create(_count, buffer_fixed, 1);
        var _x = buffer_peek(_buffer, _src.offset + 1, buffer_s8);
        var _i = 2;
        while (_i < _body_length) {
            var _byte = buffer_peek(_buffer, _src.offset + _i, buffer_u8);
            _x = ((_x + _deltas[_byte >> 4] + 128) & 255) - 128;
            buffer_write(_out, buffer_s8, _x);
            _x = ((_x + _deltas[_byte & 15] + 128) & 255) - 128;
            buffer_write(_out, buffer_s8, _x);
            _i += 1;
        }
        _src.owned_buffer = _out;
        _src.buffer = _out;
        _src.offset = 0;
        _body_length = _count;
    } else if (_compression != 0) {
        _src.err = "Unsupported 8SVX compression";
        return _src;
    }
    // Only the first (highest) octave of a multi-octave instrument is used.
    var _first_octave = _one_shot + _repeat;
    _src.frames = (_first_octave > 0) ? min(_body_length, _first_octave) : _body_length;
    if (_repeat > 0 && _one_shot < _src.frames) {
        _src.loop = true;
        _src.loop_start = _one_shot;
        _src.loop_end = min(_src.frames, _one_shot + _repeat);
    }
    return _src;
}

/// Converts _src into signed 8-bit bytes. _step source frames per output
/// byte (1 = copy), _max_bytes output limit, _normalise scales the peak to
/// full range. Returns { buffer, length, loop, loop_start, loop_length }.
function scr_audio_render_source(_src, _step, _max_bytes, _normalise) {
    var _count = (_step == 1) ? _src.frames : floor(_src.frames / _step);
    _count = min(_count, _max_bytes);
    _count -= _count mod 2;
    _count = max(2, _count);
    var _values = array_create(_count, 0);
    var _peak = 0.0001;
    var _i = 0;
    while (_i < _count) {
        var _pos = _i * _step;
        var _frame = floor(_pos);
        var _fraction = _pos - _frame;
        var _v = scr_audio_source_value(_src, _frame);
        if (_fraction > 0) {
            var _next = scr_audio_source_value(_src, _frame + 1);
            _v += (_next - _v) * _fraction;
        }
        _values[_i] = _v;
        _peak = max(_peak, abs(_v));
        _i += 1;
    }
    var _gain = _normalise ? (127 / _peak) : 128;
    var _out = buffer_create(_count, buffer_fixed, 1);
    _i = 0;
    while (_i < _count) {
        buffer_write(_out, buffer_s8, clamp(round(_values[_i] * _gain), -128, 127));
        _i += 1;
    }
    var _result = { buffer : _out, length : _count, loop : false, loop_start : 0, loop_length : 0 };
    if (_src.loop) {
        var _ls = floor(_src.loop_start / _step);
        var _le = min(_count, floor(_src.loop_end / _step));
        _ls -= _ls mod 2;
        _le -= _le mod 2;
        if (_le - _ls >= 2) {
            _result.loop = true;
            _result.loop_start = _ls;
            _result.loop_length = _le - _ls;
        }
    }
    return _result;
}

/// @desc scr_audio_import_sample(_path)
/// Imports WAV (8/16/24/32-bit PCM or float, any channels, any rate),
/// IFF 8SVX (one-shot + repeat -> loop) or headerless signed 8-bit data
/// (.raw/.smp/.8svx/.iff/.snd/.sam/no extension). WAVs are resampled with
/// linear interpolation to the rate of global.audio_import_period
/// (optionally normalised); Amiga data keeps its own rate when Paula can
/// play it. Over-long results offer to downsample or truncate. Returns
/// the new asset name, or "" on failure (status message shown).
function scr_audio_import_sample(_path) {
    if (!file_exists(_path)) {
        scr_set_status_message("Can't find " + filename_name(_path), c_red);
        return "";
    }
    var _buffer = buffer_load(_path);
    if (_buffer == -1 || !buffer_exists(_buffer)) {
        scr_set_status_message("Couldn't read " + filename_name(_path), c_red);
        return "";
    }
    var _size = buffer_get_size(_buffer);
    var _ext = string_lower(filename_ext(_path));
    var _src;
    var _is_wav = false;
    if (_size >= 12 && scr_audio_peek_tag(_buffer, 0) == "RIFF" && scr_audio_peek_tag(_buffer, 8) == "WAVE") {
        _src = scr_audio_wav_source(_buffer);
        _is_wav = true;
    } else if (_size >= 12 && scr_audio_peek_tag(_buffer, 0) == "FORM" && scr_audio_peek_tag(_buffer, 8) == "8SVX") {
        _src = scr_audio_8svx_source(_buffer);
    } else if (_ext == ".raw" || _ext == ".smp" || _ext == ".8svx" || _ext == ".iff" || _ext == ".snd"
        || _ext == ".sam" || _ext == "") {
        _src = { err : "", buffer : _buffer, offset : 0, channels : 1, bps : 1, format : "s8",
            frames : _size, rate : AUDIO_PAULA_CLOCK / 428, loop : false, loop_start : 0, loop_end : 0, volume : 64, owned_buffer : -1 };
    } else {
        buffer_delete(_buffer);
        scr_set_status_message("Unsupported sound format " + _ext + " (use WAV, IFF 8SVX or raw signed 8-bit)", c_red);
        return "";
    }
    if (_src.err == "" && _src.frames < 2) _src.err = "That sound is empty";
    if (_src.err != "") {
        if (_src.owned_buffer != -1) buffer_delete(_src.owned_buffer);
        buffer_delete(_buffer);
        scr_set_status_message("Sample import failed: " + _src.err, c_red);
        return "";
    }

    // Choose the playback period. Amiga data keeps its own rate when Paula
    // can play it; everything else is resampled to the import rate.
    var _period = clamp(global.audio_import_period, AUDIO_PERIOD_MIN, AUDIO_PERIOD_MAX);
    var _step = _src.rate * _period / AUDIO_PAULA_CLOCK;
    if (!_is_wav) {
        var _native_period = round(AUDIO_PAULA_CLOCK / _src.rate);
        if (_native_period >= AUDIO_PERIOD_MIN && _native_period <= AUDIO_PERIOD_MAX) {
            _period = _native_period;
            _step = 1;
        }
    }
    var _wanted = (_step == 1) ? _src.frames : floor(_src.frames / _step);
    if (_wanted > AUDIO_MAX_SAMPLE_BYTES) {
        var _shrink = show_question(filename_name(_path) + " needs " + string(_wanted)
            + " bytes but a Paula sample holds at most " + string(AUDIO_MAX_SAMPLE_BYTES)
            + " bytes.\n\nYES = lower the sample rate so all of it fits\nNO = keep the rate and cut off the end");
        if (_shrink) {
            var _fit_rate = (_src.rate / _step) * AUDIO_MAX_SAMPLE_BYTES / _wanted;
            _period = clamp(ceil(AUDIO_PAULA_CLOCK / _fit_rate), AUDIO_PERIOD_MIN, AUDIO_PERIOD_MAX);
            _step = _src.rate / (AUDIO_PAULA_CLOCK / _period);
            if (floor(_src.frames / _step) > AUDIO_MAX_SAMPLE_BYTES) {
                scr_set_status_message("Even the lowest Paula rate is too long: the end was cut off", c_orange);
            }
        }
    }
    var _rendered = scr_audio_render_source(_src, _step, AUDIO_MAX_SAMPLE_BYTES, _is_wav && global.audio_import_normalise);
    if (_src.owned_buffer != -1) buffer_delete(_src.owned_buffer);
    buffer_delete(_buffer);

    var _base = filename_change_ext(filename_name(_path), "");
    var _name = scr_audio_unique_name(_base);
    scr_audio_define_sample(_name, scr_audio_buffer_b64(_rendered.buffer, _rendered.length), _rendered.length,
        _period, _src.volume, _rendered.loop, _rendered.loop_start, _rendered.loop_length, filename_name(_path));
    buffer_delete(_rendered.buffer);
    global.audio_last_import_name = _name;
    scr_mark_workspace_dirty();
    scr_set_status_message("Imported sample " + _name + " (" + string(_rendered.length) + " bytes at "
        + string(round(AUDIO_PAULA_CLOCK / _period)) + " Hz, period " + string(_period) + ")", c_lime);
    return _name;
}
