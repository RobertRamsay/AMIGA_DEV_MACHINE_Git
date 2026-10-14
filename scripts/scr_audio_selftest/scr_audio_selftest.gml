/// @desc scr_audio_selftest()
/// Builds tiny synthetic WAV, 8SVX and MOD files, imports them, round-trips
/// the data through base64 / scr_audio_asset_bytes and checks the module
/// parser and player. Removes everything it created. Returns an array of
/// failure descriptions (empty = all passed).
function scr_audio_selftest() {
    var _fails = [];
    var _saved_period = global.audio_import_period;
    var _saved_normalise = global.audio_import_normalise;
    var _saved_last = global.audio_last_import_name;
    var _saved_dirty = global.workspace_dirty;
    var _saved_due = global.autosave_due_time;
    var _created = [];

    // --- names ---------------------------------------------------------
    if (!scr_audio_name_is_valid("Tune_1") || scr_audio_name_is_valid("1Tune") || scr_audio_name_is_valid("Tu ne")
        || scr_audio_name_is_valid("_x") || scr_audio_name_is_valid("")) {
        array_push(_fails, "name validation");
    }
    if (!scr_audio_name_is_valid(scr_audio_unique_name("9 bad-name.wav"))) array_push(_fails, "unique name not a valid label");

    // --- 16-bit mono WAV at 22050 Hz -> resampled to period 322 -----------
    global.audio_import_period = 322;
    global.audio_import_normalise = false;
    var _frames = 1000;
    var _wav_path = game_save_id + "adm_audio_selftest.wav";
    var _wav = scr_audio_selftest_wav(_frames, 22050, 1, 16);
    buffer_save(_wav, _wav_path);
    buffer_delete(_wav);
    var _name = scr_audio_import_sample(_wav_path);
    file_delete(_wav_path);
    if (_name == "") {
        array_push(_fails, "16-bit WAV import failed");
    } else {
        array_push(_created, _name);
        var _asset = scr_asset_find_by_name(_name);
        var _step = 22050 * 322 / AUDIO_PAULA_CLOCK;
        var _expect = floor(_frames / _step);
        _expect -= _expect mod 2;
        if (_asset.type != "SAMPLE" || _asset.length != _expect || _asset.period != 322 || _asset.volume != 64) {
            array_push(_fails, "16-bit WAV fields (length " + string(_asset.length) + ", expected " + string(_expect) + ")");
        }
        var _bytes = scr_audio_asset_bytes(_asset);
        if (_bytes == -1 || buffer_get_size(_bytes) != _asset.length) {
            array_push(_fails, "asset bytes size");
        } else {
            // Output byte 100 sits at source frame 100 * _step.
            var _src_pos = 100 * _step;
            var _want = 100 * dsin(_src_pos * 360 * 441 / 22050) * 128 / 128;
            var _got = buffer_peek(_bytes, 100, buffer_s8);
            if (abs(_got - _want) > 3) array_push(_fails, "WAV resample value " + string(_got) + " vs " + string(_want));
            if (buffer_base64_encode(_bytes, 0, _asset.length) != _asset.data_b64) array_push(_fails, "base64 round trip");
        }
        if (_bytes != -1) buffer_delete(_bytes);

        // Editing operations keep an even length and a valid loop.
        _asset = scr_audio_define_sample(_name, _asset.data_b64, _asset.length, 322, 40, true, 10, 101, "x");
        if (_asset.loop_start != 10 || _asset.loop_length != 100) array_push(_fails, "loop not snapped to even bytes");
        _asset = scr_audio_sample_trim(_asset, 5, 61);  // rounds out to [4, 62)
        if (_asset.length != 58 || _asset.loop_start != 6 || _asset.loop_length != 52 || !_asset.loop) {
            array_push(_fails, "trim (" + string(_asset.length) + "/" + string(_asset.loop_start) + "/" + string(_asset.loop_length) + ")");
        }
        var _before = scr_audio_sample_values(_asset);
        _asset = scr_audio_sample_reverse(_asset, 0, 0);
        var _after = scr_audio_sample_values(_asset);
        if (_after[0] != _before[57] || _after[57] != _before[0]) array_push(_fails, "reverse");
        _asset = scr_audio_sample_normalise(_asset, 0, 0);
        var _peak = 0;
        var _values = scr_audio_sample_values(_asset);
        var _i = 0;
        while (_i < array_length(_values)) {
            _peak = max(_peak, abs(_values[_i]));
            _i += 1;
        }
        if (_peak < 126) array_push(_fails, "normalise peak " + string(_peak));
        _asset = scr_audio_sample_fade(_asset, 0, 0, true);
        _values = scr_audio_sample_values(_asset);
        if (_values[0] != 0) array_push(_fails, "fade in start");
    }

    // --- 24-bit stereo WAV, normalised --------------------------------------
    global.audio_import_normalise = true;
    _wav = scr_audio_selftest_wav(400, 44100, 2, 24);
    buffer_save(_wav, _wav_path);
    buffer_delete(_wav);
    _name = scr_audio_import_sample(_wav_path);
    file_delete(_wav_path);
    if (_name == "") {
        array_push(_fails, "24-bit stereo WAV import failed");
    } else {
        array_push(_created, _name);
        var _values24 = scr_audio_sample_values(scr_asset_find_by_name(_name));
        var _peak24 = 0;
        var _k = 0;
        while (_k < array_length(_values24)) {
            _peak24 = max(_peak24, abs(_values24[_k]));
            _k += 1;
        }
        if (_peak24 < 120) array_push(_fails, "24-bit stereo WAV not normalised (" + string(_peak24) + ")");
    }

    // --- IFF 8SVX with one-shot + repeat ----------------------------------
    var _svx_path = game_save_id + "adm_audio_selftest.8svx";
    var _svx = scr_audio_selftest_8svx(100, 50, 8287);
    buffer_save(_svx, _svx_path);
    buffer_delete(_svx);
    _name = scr_audio_import_sample(_svx_path);
    file_delete(_svx_path);
    if (_name == "") {
        array_push(_fails, "8SVX import failed");
    } else {
        array_push(_created, _name);
        var _svx_asset = scr_asset_find_by_name(_name);
        if (_svx_asset.length != 150 || _svx_asset.period != 428 || !_svx_asset.loop
            || _svx_asset.loop_start != 100 || _svx_asset.loop_length != 50 || _svx_asset.volume != 32) {
            array_push(_fails, "8SVX fields");
        }
        var _svx_values = scr_audio_sample_values(_svx_asset);
        if (_svx_values[7] != ((7 * 13) mod 200) - 100) array_push(_fails, "8SVX data");
    }

    // --- 4-channel MOD ------------------------------------------------------
    var _mod_path = game_save_id + "adm_audio_selftest.mod";
    var _mod = scr_audio_selftest_mod("M.K.");
    var _mod_size = buffer_get_size(_mod);
    buffer_save(_mod, _mod_path);
    _name = scr_audio_import_mod(_mod_path);
    file_delete(_mod_path);
    if (_name == "") {
        array_push(_fails, "MOD import failed");
    } else {
        array_push(_created, _name);
        var _mod_asset = scr_asset_find_by_name(_name);
        if (_mod_asset.type != "MOD" || _mod_asset.length != _mod_size || _mod_asset.positions != 3
            || _mod_asset.patterns != 2 || _mod_asset.samples_used != 2 || _mod_asset.title != "ADM selftest") {
            array_push(_fails, "MOD fields");
        }
        var _mod_bytes = scr_audio_asset_bytes(_mod_asset);
        var _same = buffer_get_size(_mod_bytes) == _mod_size;
        var _b = 0;
        while (_same && _b < _mod_size) {
            if (buffer_peek(_mod_bytes, _b, buffer_u8) != buffer_peek(_mod, _b, buffer_u8)) _same = false;
            _b += 1;
        }
        if (!_same) array_push(_fails, "MOD bytes round trip");
        var _song = scr_audio_mod_song(_mod_bytes);
        buffer_delete(_mod_bytes);
        if (_song == undefined) {
            array_push(_fails, "MOD song parse");
        } else {
            var _cells = _song.patterns[0];
            if (_cells[0] != 428 || _cells[1] != 1 || _cells[2] != 12 || _cells[3] != 48) array_push(_fails, "MOD cell decode");
            if (_song.samples[0].length != 32 || _song.samples[0].loop_length != 32 || _song.samples[1].loop_length != 0) {
                array_push(_fails, "MOD sample headers");
            }
            var _player = scr_audio_player_new(_song);
            var _mix = buffer_create(4096 * 4, buffer_fixed, 1);
            scr_audio_player_mix(_player, _mix, 4096);
            var _loud = 0;
            var _f = 0;
            while (_f < 4096 * 2) {
                _loud = max(_loud, abs(buffer_peek(_mix, _f * 2, buffer_s16)));
                _f += 1;
            }
            buffer_delete(_mix);
            if (_loud < 1000) array_push(_fails, "MOD player produced silence");
            if (array_length(_player.marks) < 2) array_push(_fails, "MOD player marks");
        }
    }
    var _bad = scr_audio_selftest_mod("8CHN");
    if (scr_audio_mod_info(_bad).ok) array_push(_fails, "8CHN module not rejected");
    buffer_delete(_bad);
    _bad = scr_audio_selftest_mod("FLT4");
    if (!scr_audio_mod_info(_bad).ok) array_push(_fails, "FLT4 module rejected");
    buffer_delete(_bad);
    var _short = buffer_create(1500, buffer_fixed, 1);
    buffer_copy(_mod, 0, 1500, _short, 0);
    if (scr_audio_mod_info(_short).ok) array_push(_fails, "cut-short module not rejected");
    buffer_delete(_short);
    buffer_delete(_mod);

    // --- clean up -----------------------------------------------------------
    var _c = 0;
    while (_c < array_length(_created)) {
        scr_audio_delete(_created[_c]);
        _c += 1;
    }
    global.audio_import_period = _saved_period;
    global.audio_import_normalise = _saved_normalise;
    global.audio_last_import_name = _saved_last;
    global.workspace_dirty = _saved_dirty;
    global.autosave_due_time = _saved_due;
    return _fails;
}

/// A RIFF WAVE of a 441 Hz sine at amplitude 100/128 (0.78 full scale).
function scr_audio_selftest_wav(_frames, _rate, _channels, _bits) {
    var _bps = _bits div 8;
    var _data = _frames * _channels * _bps;
    var _b = buffer_create(44 + _data, buffer_fixed, 1);
    buffer_write(_b, buffer_u8, ord("R")); buffer_write(_b, buffer_u8, ord("I"));
    buffer_write(_b, buffer_u8, ord("F")); buffer_write(_b, buffer_u8, ord("F"));
    buffer_write(_b, buffer_u32, 36 + _data);
    buffer_write(_b, buffer_u8, ord("W")); buffer_write(_b, buffer_u8, ord("A"));
    buffer_write(_b, buffer_u8, ord("V")); buffer_write(_b, buffer_u8, ord("E"));
    buffer_write(_b, buffer_u8, ord("f")); buffer_write(_b, buffer_u8, ord("m"));
    buffer_write(_b, buffer_u8, ord("t")); buffer_write(_b, buffer_u8, ord(" "));
    buffer_write(_b, buffer_u32, 16);
    buffer_write(_b, buffer_u16, 1);
    buffer_write(_b, buffer_u16, _channels);
    buffer_write(_b, buffer_u32, _rate);
    buffer_write(_b, buffer_u32, _rate * _channels * _bps);
    buffer_write(_b, buffer_u16, _channels * _bps);
    buffer_write(_b, buffer_u16, _bits);
    buffer_write(_b, buffer_u8, ord("d")); buffer_write(_b, buffer_u8, ord("a"));
    buffer_write(_b, buffer_u8, ord("t")); buffer_write(_b, buffer_u8, ord("a"));
    buffer_write(_b, buffer_u32, _data);
    var _f = 0;
    while (_f < _frames) {
        var _v = dsin(_f * 360 * 441 / _rate) * 100 / 128;
        var _c = 0;
        while (_c < _channels) {
            if (_bps == 1) {
                buffer_write(_b, buffer_u8, 128 + round(_v * 128));
            } else if (_bps == 2) {
                buffer_write(_b, buffer_s16, round(_v * 32768));
            } else {
                var _w = round(_v * 8388608);
                if (_w < 0) _w += 16777216;
                buffer_write(_b, buffer_u8, _w & 255);
                buffer_write(_b, buffer_u8, (_w >> 8) & 255);
                buffer_write(_b, buffer_u8, (_w >> 16) & 255);
            }
            _c += 1;
        }
        _f += 1;
    }
    return _b;
}

function scr_audio_selftest_poke_be16(_b, _pos, _v) {
    buffer_poke(_b, _pos, buffer_u8, (_v >> 8) & 255);
    buffer_poke(_b, _pos + 1, buffer_u8, _v & 255);
}

function scr_audio_selftest_poke_be32(_b, _pos, _v) {
    scr_audio_selftest_poke_be16(_b, _pos, (_v >> 16) & 65535);
    scr_audio_selftest_poke_be16(_b, _pos + 2, _v & 65535);
}

function scr_audio_selftest_poke_text(_b, _pos, _text) {
    var _i = 0;
    while (_i < string_length(_text)) {
        buffer_poke(_b, _pos + _i, buffer_u8, ord(string_char_at(_text, _i + 1)));
        _i += 1;
    }
}

/// FORM 8SVX: VHDR (one-shot, repeat, rate, half volume) + BODY.
function scr_audio_selftest_8svx(_one_shot, _repeat, _rate) {
    var _body = _one_shot + _repeat;
    var _size = 12 + 8 + 20 + 8 + _body + (_body mod 2);
    var _b = buffer_create(_size, buffer_fixed, 1);
    buffer_fill(_b, 0, buffer_u8, 0, _size);
    scr_audio_selftest_poke_text(_b, 0, "FORM");
    scr_audio_selftest_poke_be32(_b, 4, _size - 8);
    scr_audio_selftest_poke_text(_b, 8, "8SVX");
    scr_audio_selftest_poke_text(_b, 12, "VHDR");
    scr_audio_selftest_poke_be32(_b, 16, 20);
    scr_audio_selftest_poke_be32(_b, 20, _one_shot);
    scr_audio_selftest_poke_be32(_b, 24, _repeat);
    scr_audio_selftest_poke_be32(_b, 28, 0);
    scr_audio_selftest_poke_be16(_b, 32, _rate);
    buffer_poke(_b, 34, buffer_u8, 1);
    buffer_poke(_b, 35, buffer_u8, 0);
    scr_audio_selftest_poke_be32(_b, 36, 32768);
    scr_audio_selftest_poke_text(_b, 40, "BODY");
    scr_audio_selftest_poke_be32(_b, 44, _body);
    var _i = 0;
    while (_i < _body) {
        buffer_poke(_b, 48 + _i, buffer_s8, ((_i * 13) mod 200) - 100);
        _i += 1;
    }
    return _b;
}

/// A 3-position, 2-pattern, 2-sample module with the given tag.
function scr_audio_selftest_mod(_tag) {
    var _size = AUDIO_MOD_HEADER_SIZE + 2 * AUDIO_MOD_PATTERN_SIZE + 32 + 40;
    var _b = buffer_create(_size, buffer_fixed, 1);
    buffer_fill(_b, 0, buffer_u8, 0, _size);
    scr_audio_selftest_poke_text(_b, 0, "ADM selftest");
    // Sample 1: 16 words, volume 64, loop whole. Sample 2: 20 words, one-shot.
    scr_audio_selftest_poke_text(_b, 20, "square");
    scr_audio_selftest_poke_be16(_b, 20 + 22, 16);
    buffer_poke(_b, 20 + 25, buffer_u8, 64);
    scr_audio_selftest_poke_be16(_b, 20 + 26, 0);
    scr_audio_selftest_poke_be16(_b, 20 + 28, 16);
    scr_audio_selftest_poke_text(_b, 50, "blip");
    scr_audio_selftest_poke_be16(_b, 50 + 22, 20);
    buffer_poke(_b, 50 + 25, buffer_u8, 48);
    scr_audio_selftest_poke_be16(_b, 50 + 28, 1);
    buffer_poke(_b, 950, buffer_u8, 3);
    buffer_poke(_b, 951, buffer_u8, 127);
    buffer_poke(_b, 952, buffer_u8, 0);
    buffer_poke(_b, 953, buffer_u8, 1);
    buffer_poke(_b, 954, buffer_u8, 0);
    scr_audio_selftest_poke_text(_b, 1080, _tag);
    // Pattern 0 row 0 channel 0: period 428, sample 1, C30 (volume 48).
    var _cell = AUDIO_MOD_HEADER_SIZE;
    buffer_poke(_b, _cell, buffer_u8, (428 >> 8) & 15);
    buffer_poke(_b, _cell + 1, buffer_u8, 428 & 255);
    buffer_poke(_b, _cell + 2, buffer_u8, (1 << 4) | 12);
    buffer_poke(_b, _cell + 3, buffer_u8, 48);
    // Pattern 1 row 0 channel 1: period 214, sample 2.
    _cell = AUDIO_MOD_HEADER_SIZE + AUDIO_MOD_PATTERN_SIZE + 4;
    buffer_poke(_b, _cell, buffer_u8, (214 >> 8) & 15);
    buffer_poke(_b, _cell + 1, buffer_u8, 214 & 255);
    buffer_poke(_b, _cell + 2, buffer_u8, 2 << 4);
    var _data = AUDIO_MOD_HEADER_SIZE + 2 * AUDIO_MOD_PATTERN_SIZE;
    var _i = 0;
    while (_i < 32) {
        buffer_poke(_b, _data + _i, buffer_s8, (_i < 16) ? 100 : -100);
        _i += 1;
    }
    _i = 2;
    while (_i < 40) {
        buffer_poke(_b, _data + 32 + _i, buffer_s8, ((_i * 37) mod 255) - 127);
        _i += 1;
    }
    return _b;
}
