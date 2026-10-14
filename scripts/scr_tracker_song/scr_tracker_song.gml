/// TRACKER song model: the GML player's song struct (scr_audio_mod_song)
///   { title, order[], restart, patterns[], samples[31] }
/// pattern = flat array of 64 rows x 4 channels x [period, sample, effect, param]
/// sample  = { name, data[] (signed 8-bit), length, volume 0-64, finetune -8..7,
///             loop_start, loop_length } (bytes, loop_length 0 = one-shot)
/// so the editor plays the song it is editing directly (edits are heard
/// live), and scr_tracker_song_to_buffer writes it as a 4-channel M.K. MOD.

#macro TRACKER_ROWS 64
#macro TRACKER_MAX_PATTERNS 100
#macro TRACKER_CELL_SIZE 4

/// An empty instrument slot.
function scr_tracker_sample_empty() {
    return { name : "", data : [], length : 0, volume : 64, finetune : 0, loop_start : 0, loop_length : 0 };
}

/// An empty pattern (64 rows x 4 channels).
function scr_tracker_pattern_empty() {
    return array_create(TRACKER_ROWS * 4 * TRACKER_CELL_SIZE, 0);
}

/// A new song with one empty pattern and a starter kit of synth instruments
/// (lead, bass, pad, kick, snare, hi-hat) so music can be made straight away.
function scr_tracker_song_new() {
    var _song = {
        title : "untitled",
        order : [0],
        restart : 0,
        patterns : [scr_tracker_pattern_empty()],
        samples : array_create(31, undefined)
    };
    var _s = 0;
    while (_s < 31) {
        _song.samples[_s] = scr_tracker_sample_empty();
        _s += 1;
    }
    var _kit = ["PULSE", "BASS", "ORGAN", "KICK", "SNARE", "HIHAT"];
    var _k = 0;
    while (_k < array_length(_kit)) {
        _song.samples[_k] = scr_tracker_synth(_kit[_k]);
        _k += 1;
    }
    return _song;
}

/// Loads a MOD asset into a song (undefined when it is not a 4-channel MOD).
function scr_tracker_song_from_asset(_asset) {
    if (!is_struct(_asset) || _asset.type != "MOD") return undefined;
    var _bytes = scr_audio_asset_bytes(_asset);
    if (_bytes == -1) return undefined;
    var _info = scr_audio_mod_info(_bytes);
    var _song = scr_audio_mod_song(_bytes);
    buffer_delete(_bytes);
    if (_song == undefined) return undefined;
    var _s = 0;
    while (_s < 31) {
        _song.samples[_s].name = _info.sample_names[_s];
        _s += 1;
    }
    _song.title = string_trim(_song.title);
    return _song;
}

/// Writes the song as a 4-channel ProTracker "M.K." module. Returns
/// { buffer, size } (the caller deletes the buffer).
function scr_tracker_song_to_buffer(_song) {
    var _positions = clamp(array_length(_song.order), 1, 128);
    var _count = clamp(array_length(_song.patterns), 1, TRACKER_MAX_PATTERNS);
    var _top = 0;
    var _o = 0;
    while (_o < _positions) {
        _song.order[_o] = clamp(_song.order[_o], 0, _count - 1);
        _top = max(_top, _song.order[_o]);
        _o += 1;
    }
    // ProTracker counts patterns from the whole 128-entry order table, so a
    // pattern not in the song yet is kept by naming it in the unused tail.
    var _tail = (_count - 1 > _top && _positions < 128) ? _count - 1 : 0;
    if (_count - 1 > _top && _positions >= 128) _count = _top + 1;

    var _sample_bytes = 0;
    var _s = 0;
    while (_s < 31) {
        _sample_bytes += scr_tracker_sample_bytes(_song.samples[_s]);
        _s += 1;
    }
    var _size = AUDIO_MOD_HEADER_SIZE + _count * AUDIO_MOD_PATTERN_SIZE + _sample_bytes;
    var _b = buffer_create(_size, buffer_fixed, 1);
    buffer_fill(_b, 0, buffer_u8, 0, _size);

    scr_tracker_poke_text(_b, 0, _song.title, 20);
    _s = 0;
    while (_s < 31) {
        var _smp = _song.samples[_s];
        var _p = 20 + _s * 30;
        var _len = scr_tracker_sample_bytes(_smp);
        scr_tracker_poke_text(_b, _p, _smp.name, 22);
        scr_tracker_poke_be16(_b, _p + 22, _len div 2);
        buffer_poke(_b, _p + 24, buffer_u8, (_smp.finetune + 16) & 15);
        buffer_poke(_b, _p + 25, buffer_u8, clamp(_smp.volume, 0, 64));
        var _looped = _smp.loop_length >= 2 && _len > 0;
        scr_tracker_poke_be16(_b, _p + 26, _looped ? (_smp.loop_start div 2) : 0);
        scr_tracker_poke_be16(_b, _p + 28, _looped ? (_smp.loop_length div 2) : 1);
        _s += 1;
    }
    buffer_poke(_b, 950, buffer_u8, _positions);
    buffer_poke(_b, 951, buffer_u8, clamp(_song.restart, 0, _positions - 1));
    _o = 0;
    while (_o < _positions) {
        buffer_poke(_b, 952 + _o, buffer_u8, _song.order[_o]);
        _o += 1;
    }
    if (_tail > 0) buffer_poke(_b, 952 + 127, buffer_u8, _tail);
    scr_tracker_poke_text(_b, 1080, "M.K.", 4);

    buffer_seek(_b, buffer_seek_start, AUDIO_MOD_HEADER_SIZE);
    var _pi = 0;
    while (_pi < _count) {
        var _cells = _song.patterns[_pi];
        var _c = 0;
        while (_c < 256) {
            var _period = clamp(_cells[_c * 4], 0, 4095);
            var _smp_no = clamp(_cells[_c * 4 + 1], 0, 31);
            buffer_write(_b, buffer_u8, (_smp_no & 240) | (_period >> 8));
            buffer_write(_b, buffer_u8, _period & 255);
            buffer_write(_b, buffer_u8, ((_smp_no & 15) << 4) | (_cells[_c * 4 + 2] & 15));
            buffer_write(_b, buffer_u8, _cells[_c * 4 + 3] & 255);
            _c += 1;
        }
        _pi += 1;
    }
    _s = 0;
    while (_s < 31) {
        var _data = _song.samples[_s].data;
        var _n = scr_tracker_sample_bytes(_song.samples[_s]);
        var _i = 0;
        while (_i < _n) {
            buffer_write(_b, buffer_s8, (_i < array_length(_data)) ? clamp(round(_data[_i]), -128, 127) : 0);
            _i += 1;
        }
        _s += 1;
    }
    return { buffer : _b, size : _size };
}

/// Bytes a sample takes in the module (even, at most 131070).
function scr_tracker_sample_bytes(_smp) {
    var _len = clamp(_smp.length, 0, AUDIO_MAX_SAMPLE_BYTES);
    return _len - (_len mod 2);
}

/// Stores the song as the MOD asset _name (replacing an older one).
/// Returns "" or an error message.
function scr_tracker_song_save(_song, _name) {
    if (!scr_audio_name_is_valid(_name)) return "Name must start with a letter: letters, digits and _ only";
    var _existing = scr_asset_find_by_name(_name);
    if (_existing != undefined && _existing.type != "MOD") return "There is already a " + _existing.type + " asset called " + _name;
    var _out = scr_tracker_song_to_buffer(_song);
    var _info = scr_audio_mod_info(_out.buffer);
    var _b64 = scr_audio_buffer_b64(_out.buffer, _out.size);
    buffer_delete(_out.buffer);
    if (!_info.ok) return "Could not write the module: " + _info.err;
    scr_audio_define_mod(_name, _b64, _out.size, _info.title, _info.positions, _info.patterns, _info.samples_used, "TRACKER");
    scr_mark_workspace_dirty();
    return "";
}

function scr_tracker_poke_be16(_b, _pos, _v) {
    buffer_poke(_b, _pos, buffer_u8, (_v >> 8) & 255);
    buffer_poke(_b, _pos + 1, buffer_u8, _v & 255);
}

/// Writes _text (ASCII, cut / zero-padded to _n bytes) at _pos.
function scr_tracker_poke_text(_b, _pos, _text, _n) {
    var _i = 0;
    while (_i < _n) {
        var _code = (_i < string_length(_text)) ? ord(string_char_at(_text, _i + 1)) : 0;
        buffer_poke(_b, _pos + _i, buffer_u8, (_code > 0 && _code < 128) ? _code : ((_code == 0) ? 0 : 63));
        _i += 1;
    }
}

// ----------------------------------------------------------------------------
// Cells and notes
// ----------------------------------------------------------------------------

/// Index of the first value of a cell in its pattern array.
function scr_tracker_cell_at(_row, _channel) {
    return (_row * 4 + _channel) * TRACKER_CELL_SIZE;
}

/// "C-2", "---" for no note, "~C-2" style for a period off the table.
function scr_tracker_note_text(_period) {
    if (_period <= 0) return "---";
    var _name = scr_audio_period_note_name(_period);
    return (string_char_at(_name, 1) == "~") ? string_copy(_name, 2, 3) : _name;
}

/// Note index 0..35 (C-1..B-3) nearest to a period, -1 for none.
function scr_tracker_note_index(_period) {
    if (_period <= 0) return -1;
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
    return _best;
}

/// Two hex digits.
function scr_tracker_hex2(_v) {
    static _digits = "0123456789ABCDEF";
    return string_char_at(_digits, ((_v >> 4) & 15) + 1) + string_char_at(_digits, (_v & 15) + 1);
}

/// One hex digit.
function scr_tracker_hex1(_v) {
    return string_char_at("0123456789ABCDEF", (_v & 15) + 1);
}

/// What an effect does, for the status line ("" for none).
function scr_tracker_effect_help(_fx, _prm) {
    if (_fx == 0 && _prm == 0) return "";
    var _x = _prm >> 4;
    var _y = _prm & 15;
    switch (_fx) {
        case 0: return "0xy arpeggio: note, +" + string(_x) + ", +" + string(_y) + " semitones";
        case 1: return "1xx slide up by " + string(_prm);
        case 2: return "2xx slide down by " + string(_prm);
        case 3: return "3xx slide to the note, speed " + string(_prm);
        case 4: return "4xy vibrato, speed " + string(_x) + " depth " + string(_y);
        case 5: return "5xy slide to note + volume slide";
        case 6: return "6xy vibrato + volume slide";
        case 7: return "7xy tremolo (not previewed)";
        case 9: return "9xx start the sample at " + string(_prm * 256) + " bytes";
        case 10: return "Axy volume slide " + ((_x > 0) ? "up " + string(_x) : "down " + string(_y));
        case 11: return "Bxx jump to position " + string(_prm);
        case 12: return "Cxx set volume " + string(min(_prm, 64));
        case 13: return "Dxx next pattern, row " + string(_x * 10 + _y);
        case 14:
            switch (_x) {
                case 1: return "E1y fine slide up " + string(_y);
                case 2: return "E2y fine slide down " + string(_y);
                case 6: return (_y == 0) ? "E60 loop start" : "E6y loop " + string(_y) + " times";
                case 9: return "E9y retrigger every " + string(_y) + " ticks";
                case 10: return "EAy fine volume up " + string(_y);
                case 11: return "EBy fine volume down " + string(_y);
                case 12: return "ECy cut the note at tick " + string(_y);
                case 13: return "EDy delay the note " + string(_y) + " ticks";
                case 14: return "EEy delay the pattern " + string(_y) + " rows";
            }
            return "E" + scr_tracker_hex1(_x) + "y extended effect";
        case 15: return (_prm < 32) ? "Fxx speed " + string(_prm) + " ticks a row" : "Fxx tempo " + string(_prm) + " BPM";
    }
    return "";
}

// ----------------------------------------------------------------------------
// Built-in synth instruments
// ----------------------------------------------------------------------------

/// Names of the built-in synth instruments, in button order.
function scr_tracker_synth_kinds() {
    return ["SQUARE", "PULSE", "SAW", "TRIANGLE", "SINE", "ORGAN", "BASS", "KICK", "SNARE", "HIHAT"];
}

/// A generated instrument. Waveforms are single looped cycles (32 bytes: C-2
/// plays middle C; BASS is 64 bytes, an octave lower); drums are one-shots
/// tuned to be played at C-2 (8287 Hz).
function scr_tracker_synth(_kind) {
    var _smp = scr_tracker_sample_empty();
    _smp.name = string_lower(_kind);
    var _n = 32;
    var _data = [];
    var _loop = true;
    switch (_kind) {
        case "SQUARE":
            _data = array_create(_n, 0);
            for (var _i = 0; _i < _n; _i += 1) _data[_i] = (_i < _n / 2) ? 90 : -90;
            _smp.volume = 40;
            break;
        case "PULSE":
            _data = array_create(_n, 0);
            for (var _i = 0; _i < _n; _i += 1) _data[_i] = (_i < _n / 4) ? 100 : -34;
            _smp.volume = 44;
            _smp.name = "pulse lead";
            break;
        case "SAW":
            _data = array_create(_n, 0);
            for (var _i = 0; _i < _n; _i += 1) _data[_i] = round(-110 + 220 * _i / (_n - 1));
            _smp.volume = 40;
            break;
        case "TRIANGLE":
            _data = array_create(_n, 0);
            for (var _i = 0; _i < _n; _i += 1) {
                var _t = _i / _n;
                _data[_i] = round(120 * ((_t < 0.5) ? (-1 + 4 * _t) : (3 - 4 * _t)));
            }
            _smp.volume = 56;
            break;
        case "SINE":
            _data = array_create(_n, 0);
            for (var _i = 0; _i < _n; _i += 1) _data[_i] = round(120 * sin(2 * pi * _i / _n));
            _smp.volume = 56;
            break;
        case "ORGAN":
            _data = array_create(_n, 0);
            for (var _i = 0; _i < _n; _i += 1) {
                var _a = 2 * pi * _i / _n;
                _data[_i] = round(70 * sin(_a) + 35 * sin(2 * _a) + 20 * sin(3 * _a) + 10 * sin(4 * _a));
            }
            _smp.volume = 40;
            _smp.name = "organ pad";
            break;
        case "BASS":
            _n = 64;
            _data = array_create(_n, 0);
            for (var _i = 0; _i < _n; _i += 1) {
                var _t = _i / _n;
                var _tri = (_t < 0.5) ? (-1 + 4 * _t) : (3 - 4 * _t);
                var _sq = (_t < 0.5) ? 1 : -1;
                _data[_i] = round(100 * _tri + 22 * _sq);
            }
            _smp.volume = 64;
            _smp.name = "synth bass";
            break;
        case "KICK":
            _loop = false;
            _n = 1600;
            _data = array_create(_n, 0);
            var _phase = 0;
            for (var _i = 2; _i < _n; _i += 1) {
                var _t = _i / 8287;
                _phase += 2 * pi * (42 + 140 * exp(-_t * 30)) / 8287;
                _data[_i] = round(120 * exp(-_t * 13) * sin(_phase));
            }
            _smp.volume = 64;
            break;
        case "SNARE":
            _loop = false;
            _n = 1800;
            _data = array_create(_n, 0);
            var _seed = 1985;
            for (var _i = 2; _i < _n; _i += 1) {
                var _t = _i / 8287;
                _seed = (_seed * 75 + 74) mod 65537;
                var _noise = _seed / 32768 - 1;
                _data[_i] = round((_noise * 95 + 40 * sin(2 * pi * 185 * _t)) * exp(-_t * 15));
            }
            _smp.volume = 52;
            break;
        case "HIHAT":
            _loop = false;
            _n = 700;
            _data = array_create(_n, 0);
            var _seed2 = 7;
            var _last = 0;
            for (var _i = 2; _i < _n; _i += 1) {
                var _t = _i / 8287;
                _seed2 = (_seed2 * 75 + 74) mod 65537;
                var _noise2 = _seed2 / 32768 - 1;
                // Differencing removes the low end: a thin, bright hat.
                _data[_i] = round((_noise2 - _last) * 60 * exp(-_t * 45));
                _last = _noise2;
            }
            _smp.volume = 40;
            _smp.name = "hi-hat";
            break;
    }
    for (var _j = 0; _j < array_length(_data); _j += 1) _data[_j] = clamp(_data[_j], -128, 127);
    _smp.data = _data;
    _smp.length = array_length(_data);
    if (_loop) {
        _smp.loop_start = 0;
        _smp.loop_length = _smp.length;
    }
    return _smp;
}

/// An instrument made from a SAMPLE asset (name, data, volume, loop).
function scr_tracker_sample_from_asset(_asset) {
    var _smp = scr_tracker_sample_empty();
    if (!is_struct(_asset) || _asset.type != "SAMPLE") return _smp;
    _smp.name = string_copy(_asset.name, 1, 22);
    _smp.data = scr_audio_sample_values(_asset);
    _smp.length = array_length(_smp.data) - (array_length(_smp.data) mod 2);
    _smp.volume = clamp(_asset.volume, 0, 64);
    if (_asset.loop && _asset.loop_length >= 2) {
        _smp.loop_start = _asset.loop_start;
        _smp.loop_length = _asset.loop_length;
    }
    return _smp;
}

// ----------------------------------------------------------------------------
// Preview
// ----------------------------------------------------------------------------

/// Plays the song from order position _position, or (_pattern_only) loops
/// the pattern at that position. The player shares the song's pattern and
/// sample arrays, so edits are heard on the next pass.
function scr_tracker_play(_song, _position, _pattern_only, _mute) {
    var _play_song = _song;
    _position = clamp(_position, 0, array_length(_song.order) - 1);
    if (_pattern_only) {
        _play_song = {
            title : _song.title, order : [_song.order[_position]], restart : 0,
            patterns : _song.patterns, samples : _song.samples
        };
        _position = 0;
    }
    var _player = scr_audio_player_new(_play_song);
    _player.ord = _position;
    _player.mute = _mute;
    scr_audio_stream_start(_player, "TRACKER", _pattern_only ? "pattern" : "song");
}

/// Plays one note of instrument _sample (1-31) on its own (keyboard jam).
function scr_tracker_jam(_song, _sample, _period) {
    if (_sample < 1 || _sample > 31) return;
    var _smp = _song.samples[_sample - 1];
    if (_smp.length < 2) return;
    var _player = scr_audio_player_new(_song);
    // A huge tick budget: the player never reads a row, the voice just plays.
    _player.tick_left = 1000000000;
    var _ch = _player.ch[0];
    _ch.smp = _sample;
    _ch.vol = _smp.volume;
    var _per = _period;
    if (_smp.finetune != 0) _per = _per * power(2, -_smp.finetune / 96);
    scr_audio_player_trigger(_player, _ch, _per);
    _ch.inc = (AUDIO_PAULA_CLOCK / AUDIO_MIX_RATE) / _per;
    _player.mono = true;
    scr_audio_stream_start(_player, "JAM", "");
}
