/// Sound & music assets (SAMPLE and MOD) for global.asset_list.
///
/// SAMPLE asset:
///   { type : "SAMPLE", name, data_b64, length, period, volume, loop,
///     loop_start, loop_length, source_name }
///   data_b64 = base64 of raw signed 8-bit PCM, length = byte count (even,
///   2..AUDIO_MAX_SAMPLE_BYTES), period = Paula period (124..1016), volume 0-64,
///   loop_start / loop_length in bytes (even).
/// MOD asset:
///   { type : "MOD", name, data_b64, length, title, positions, patterns,
///     samples_used, source_name }
///   data_b64 = base64 of the original 4-channel ProTracker module bytes.
///
/// Every global used by the audio scripts is created in scr_audio_init().

#macro AUDIO_PAULA_CLOCK 3546895
#macro AUDIO_MAX_SAMPLE_BYTES 131070
#macro AUDIO_PERIOD_MIN 124
#macro AUDIO_PERIOD_MAX 1016
#macro AUDIO_MIX_RATE 22050
#macro AUDIO_MOD_HEADER_SIZE 1084
#macro AUDIO_MOD_PATTERN_SIZE 1024

/// @desc scr_audio_init()
/// Creates every global the sound/music code uses. Call once at startup
/// (obj_amiga_manager Create) before any other scr_audio_* function.
function scr_audio_init() {
    // Import settings (the editor exposes both).
    global.audio_import_period = 322;          // 3546895 / 322 = 11015 Hz
    global.audio_import_normalise = true;
    global.audio_last_import_name = "";

    // Preview state shared by the sample and module players.
    global.audio_preview_kind = "";            // "", "SAMPLE" or "MOD"
    global.audio_preview_name = "";
    global.audio_preview_sound = -1;           // buffer sound (one-shot samples)
    global.audio_preview_inst = -1;
    global.audio_preview_buffer = -1;
    global.audio_preview_t0 = 0;
    global.audio_preview_rate = 0;             // source bytes per second
    global.audio_preview_length = 0;           // source bytes
    global.audio_preview_loop_start = 0;
    global.audio_preview_loop_length = 0;

    // Streaming queue used for modules and looping samples.
    global.audio_player = undefined;
    global.audio_queue = -1;
    global.audio_queue_inst = -1;
    global.audio_queue_bufs = [];
    global.audio_dead_bufs = [];
    global.audio_frames_queued = 0;
    global.audio_queue_t0 = 0;
    global.audio_streaming = false;
}

/// @desc scr_audio_service_ensure()
/// The persistent obj_audio_service feeds the preview queue every Step and
/// frees played buffers in its Async - Audio Playback event.
function scr_audio_service_ensure() {
    if (!instance_exists(obj_audio_service)) {
        instance_create_depth(0, 0, 0, obj_audio_service);
    }
}

/// @desc scr_audio_editor_open()
/// Opens the SOUND & MUSIC window (once). Returns its instance id.
function scr_audio_editor_open() {
    if (instance_exists(obj_audio_editor)) return instance_find(obj_audio_editor, 0);
    return instance_create_depth(0, 0, -400000, obj_audio_editor);
}

/// @desc scr_audio_asset_bytes(_asset)
/// Decodes an asset's data_b64 into a new buffer_fixed (alignment 1) of
/// exactly _asset.length bytes. The caller deletes it. Returns -1 when the
/// asset holds no data.
function scr_audio_asset_bytes(_asset) {
    if (!is_struct(_asset)) return -1;
    var _length = floor(_asset.length);
    if (_length <= 0 || !is_string(_asset.data_b64) || _asset.data_b64 == "") return -1;
    var _out = buffer_create(_length, buffer_fixed, 1);
    buffer_fill(_out, 0, buffer_u8, 0, _length);
    var _decoded = buffer_base64_decode(_asset.data_b64);
    if (_decoded != -1 && buffer_exists(_decoded)) {
        buffer_copy(_decoded, 0, min(_length, buffer_get_size(_decoded)), _out, 0);
        buffer_delete(_decoded);
    }
    return _out;
}

/// @desc scr_audio_buffer_b64(_buffer, _length)
/// Base64 of the first _length bytes of a buffer ("" when empty).
function scr_audio_buffer_b64(_buffer, _length) {
    if (_length <= 0) return "";
    return buffer_base64_encode(_buffer, 0, _length);
}

/// Replaces the asset called _name or appends _asset.
function scr_audio_store_asset(_asset) {
    var _i = 0;
    while (_i < array_length(global.asset_list)) {
        if (global.asset_list[_i].name == _asset.name) {
            global.asset_list[_i] = _asset;
            return _asset;
        }
        _i += 1;
    }
    array_push(global.asset_list, _asset);
    return _asset;
}

/// @desc scr_audio_define_sample(_name, _data_b64, _length, _period, _volume, _loop, _loop_start, _loop_length, _source_name)
/// Adds or replaces a SAMPLE asset. Values are clamped to what Paula can
/// play: even length up to 131070 bytes, period 124-1016, volume 0-64 and an
/// even loop of at least 2 bytes inside the sample. Returns the struct.
function scr_audio_define_sample(_name, _data_b64, _length, _period, _volume, _loop, _loop_start, _loop_length, _source_name) {
    var _len = clamp(floor(_length), 0, AUDIO_MAX_SAMPLE_BYTES);
    _len -= _len mod 2;
    var _ls = clamp(floor(_loop_start), 0, _len);
    _ls -= _ls mod 2;
    var _ll = clamp(floor(_loop_length), 0, _len - _ls);
    _ll -= _ll mod 2;
    var _looping = (_loop == true || _loop == 1) && _ll >= 2;
    if (!_looping) {
        _ls = 0;
        _ll = 0;
    }
    var _asset = {
        type : "SAMPLE",
        name : _name,
        data_b64 : _data_b64,
        length : _len,
        period : clamp(round(_period), AUDIO_PERIOD_MIN, AUDIO_PERIOD_MAX),
        volume : clamp(round(_volume), 0, 64),
        loop : _looping,
        loop_start : _ls,
        loop_length : _ll,
        source_name : _source_name
    };
    return scr_audio_store_asset(_asset);
}

/// @desc scr_audio_define_mod(_name, _data_b64, _length, _title, _positions, _patterns, _samples_used, _source_name)
/// Adds or replaces a MOD asset. Returns the struct.
function scr_audio_define_mod(_name, _data_b64, _length, _title, _positions, _patterns, _samples_used, _source_name) {
    var _asset = {
        type : "MOD",
        name : _name,
        data_b64 : _data_b64,
        length : floor(_length),
        title : _title,
        positions : floor(_positions),
        patterns : floor(_patterns),
        samples_used : floor(_samples_used),
        source_name : _source_name
    };
    return scr_audio_store_asset(_asset);
}

/// @desc scr_audio_list(_type)
/// Names of the assets of _type ("SAMPLE" or "MOD") in list order.
function scr_audio_list(_type) {
    var _names = [];
    var _i = 0;
    while (_i < array_length(global.asset_list)) {
        var _asset = global.asset_list[_i];
        if (is_struct(_asset) && _asset.type == _type) array_push(_names, _asset.name);
        _i += 1;
    }
    return _names;
}

/// True when _name is a valid assembler label: a letter first, then
/// letters, digits or underscores.
function scr_audio_name_is_valid(_name) {
    if (!is_string(_name) || string_length(_name) < 1 || string_length(_name) > 32) return false;
    var _i = 1;
    while (_i <= string_length(_name)) {
        var _c = ord(string_char_at(_name, _i));
        var _letter = (_c >= 65 && _c <= 90) || (_c >= 97 && _c <= 122);
        var _digit = _c >= 48 && _c <= 57;
        if (_i == 1 && !_letter) return false;
        if (!_letter && !_digit && _c != 95) return false;
        _i += 1;
    }
    return true;
}

/// True when another asset (any type) already uses _name, ignoring case
/// (labels that differ only by case are too easy to confuse). _except is a
/// name to ignore (the asset being renamed).
function scr_audio_name_taken(_name, _except = "") {
    var _lower = string_lower(_name);
    var _i = 0;
    while (_i < array_length(global.asset_list)) {
        var _other = global.asset_list[_i].name;
        if (_other != _except && string_lower(_other) == _lower) return true;
        _i += 1;
    }
    return false;
}

/// Turns any text (e.g. a file name) into a valid label base.
function scr_audio_label_from_text(_text, _fallback) {
    var _out = "";
    var _i = 1;
    while (_i <= string_length(_text) && string_length(_out) < 24) {
        var _ch = string_char_at(_text, _i);
        var _c = ord(_ch);
        var _ok = (_c >= 65 && _c <= 90) || (_c >= 97 && _c <= 122) || (_c >= 48 && _c <= 57) || _c == 95;
        _out += _ok ? _ch : "_";
        _i += 1;
    }
    if (_out == "" || !scr_audio_name_is_valid(string_char_at(_out, 1))) _out = _fallback + _out;
    return string_copy(_out, 1, 24);
}

/// @desc scr_audio_unique_name(_base)
/// _base made into a valid label that no asset uses yet (_2, _3 ... added).
function scr_audio_unique_name(_base) {
    var _clean = scr_audio_label_from_text(_base, "Snd");
    if (!scr_audio_name_taken(_clean)) return _clean;
    var _n = 2;
    while (scr_audio_name_taken(_clean + "_" + string(_n))) _n += 1;
    return _clean + "_" + string(_n);
}

/// Renames asset _old to _new. Returns "" on success or an error message.
function scr_audio_rename(_old, _new) {
    if (_old == _new) return "";
    if (!scr_audio_name_is_valid(_new)) return "Names must start with a letter and use only letters, digits and _";
    if (scr_audio_name_taken(_new, _old)) return "An asset called " + _new + " already exists";
    var _asset = scr_asset_find_by_name(_old);
    if (_asset == undefined) return "Asset " + _old + " not found";
    _asset.name = _new;
    if (global.audio_preview_name == _old) global.audio_preview_name = _new;
    return "";
}

/// Removes the asset called _name. Returns true when one was removed.
function scr_audio_delete(_name) {
    var _i = 0;
    while (_i < array_length(global.asset_list)) {
        if (global.asset_list[_i].name == _name) {
            if (global.audio_preview_name == _name) scr_audio_preview_stop();
            array_delete(global.asset_list, _i, 1);
            return true;
        }
        _i += 1;
    }
    return false;
}

/// Paula playback rate (Hz) of a period.
function scr_audio_period_rate(_period) {
    return AUDIO_PAULA_CLOCK / max(1, _period);
}

/// ProTracker periods C-1..B-3 at finetune 0.
function scr_audio_note_periods() {
    static _table = [
        856, 808, 762, 720, 678, 640, 604, 570, 538, 508, 480, 453,
        428, 404, 381, 360, 339, 320, 302, 285, 269, 254, 240, 226,
        214, 202, 190, 180, 170, 160, 151, 143, 135, 127, 120, 113
    ];
    return _table;
}

/// Nearest ProTracker note name (C-1..B-3) for a period; "~" marks a
/// period that is not exactly on the note.
function scr_audio_period_note_name(_period) {
    static _names = ["C-", "C#", "D-", "D#", "E-", "F-", "F#", "G-", "G#", "A-", "A#", "B-"];
    var _table = scr_audio_note_periods();
    var _best = 0;
    var _best_distance = 1000000;
    var _i = 0;
    while (_i < 36) {
        var _distance = abs(ln(_period / _table[_i]));
        if (_distance < _best_distance) {
            _best_distance = _distance;
            _best = _i;
        }
        _i += 1;
    }
    var _name = _names[_best mod 12] + string(1 + (_best div 12));
    return (_table[_best] == round(_period)) ? _name : "~" + _name;
}

/// Reads 4 bytes at _pos as ASCII text (non-printable bytes become '?').
function scr_audio_peek_tag(_buffer, _pos) {
    var _tag = "";
    var _i = 0;
    while (_i < 4) {
        var _c = (_pos + _i < buffer_get_size(_buffer)) ? buffer_peek(_buffer, _pos + _i, buffer_u8) : 0;
        _tag += (_c >= 32 && _c <= 126) ? chr(_c) : "?";
        _i += 1;
    }
    return _tag;
}

/// Big-endian 16 / 32-bit reads.
function scr_audio_peek_be16(_buffer, _pos) {
    return (buffer_peek(_buffer, _pos, buffer_u8) << 8) | buffer_peek(_buffer, _pos + 1, buffer_u8);
}

function scr_audio_peek_be32(_buffer, _pos) {
    return (scr_audio_peek_be16(_buffer, _pos) << 16) | scr_audio_peek_be16(_buffer, _pos + 2);
}

/// Zero-terminated printable ASCII text field.
function scr_audio_peek_text(_buffer, _pos, _length) {
    var _text = "";
    var _i = 0;
    while (_i < _length && _pos + _i < buffer_get_size(_buffer)) {
        var _c = buffer_peek(_buffer, _pos + _i, buffer_u8);
        if (_c == 0) break;
        if (_c >= 32 && _c <= 126) _text += chr(_c);
        _i += 1;
    }
    return _text;
}
