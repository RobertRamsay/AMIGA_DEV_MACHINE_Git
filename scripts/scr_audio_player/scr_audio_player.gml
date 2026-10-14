/// Editor preview playback for SAMPLE and MOD assets.
///
/// Modules (and looping samples) stream through a GameMaker play queue fed
/// by a GML ProTracker player ported from ADAM (scr_music): 4 Paula voices,
/// 8-bit samples, period pitch, channels 1+4 left and 2+3 right, A500 output
/// low-pass. One-shot samples play as a buffer sound at exactly
/// 3546895 / period Hz.
///
/// obj_audio_service (persistent, created by scr_audio_service_ensure)
/// calls scr_audio_preview_step() every Step and scr_audio_preview_async()
/// from its Async - Audio Playback event.

/// Parses module bytes into the player's song struct, or undefined.
/// Cells are flat arrays per pattern: ((row * 4 + channel) * 4) ->
/// period, sample, effect, param.
function scr_audio_mod_song(_buffer) {
    var _info = scr_audio_mod_info(_buffer);
    if (!_info.ok) return undefined;
    var _size = buffer_get_size(_buffer);
    var _song = {
        title : _info.title,
        order : array_create(_info.positions, 0),
        restart : _info.restart,
        patterns : array_create(_info.patterns, undefined),
        samples : array_create(31, undefined)
    };
    var _o = 0;
    while (_o < _info.positions) {
        _song.order[_o] = min(buffer_peek(_buffer, 952 + _o, buffer_u8), _info.patterns - 1);
        _o += 1;
    }
    var _pattern_index = 0;
    while (_pattern_index < _info.patterns) {
        var _cells = array_create(1024, 0);
        buffer_seek(_buffer, buffer_seek_start, AUDIO_MOD_HEADER_SIZE + _pattern_index * AUDIO_MOD_PATTERN_SIZE);
        var _c = 0;
        while (_c < 256) {
            var _b0 = buffer_read(_buffer, buffer_u8);
            var _b1 = buffer_read(_buffer, buffer_u8);
            var _b2 = buffer_read(_buffer, buffer_u8);
            var _b3 = buffer_read(_buffer, buffer_u8);
            _cells[_c * 4] = ((_b0 & 15) << 8) | _b1;
            _cells[_c * 4 + 1] = (_b0 & 240) | (_b2 >> 4);
            _cells[_c * 4 + 2] = _b2 & 15;
            _cells[_c * 4 + 3] = _b3;
            _c += 1;
        }
        _song.patterns[_pattern_index] = _cells;
        _pattern_index += 1;
    }
    var _at = _info.data_at;
    var _s = 0;
    while (_s < 31) {
        var _p = 20 + _s * 30;
        var _len = _info.sample_lengths[_s];
        var _finetune = buffer_peek(_buffer, _p + 24, buffer_u8) & 15;
        if (_finetune > 7) _finetune -= 16;
        var _ls = scr_audio_peek_be16(_buffer, _p + 26) * 2;
        var _ll = scr_audio_peek_be16(_buffer, _p + 28) * 2;
        var _avail = max(0, _size - _at);
        if (_len > _avail) _len = _avail - (_avail mod 2);
        if (_ll <= 2 || _ls >= _len) {
            _ls = 0;
            _ll = 0;
        } else if (_ls + _ll > _len) {
            _ll = _len - _ls;
            if (_ll < 4) {
                _ls = 0;
                _ll = 0;
            }
        }
        var _data = array_create(_len, 0);
        if (_len > 0) {
            buffer_seek(_buffer, buffer_seek_start, _at);
            var _j = 0;
            while (_j < _len) {
                _data[_j] = buffer_read(_buffer, buffer_s8);
                _j += 1;
            }
        }
        _at += _info.sample_lengths[_s];
        _song.samples[_s] = {
            data : _data, length : _len,
            volume : min(buffer_peek(_buffer, _p + 25, buffer_u8), 64),
            finetune : _finetune, loop_start : _ls, loop_length : _ll
        };
        _s += 1;
    }
    return _song;
}

/// A new player for _song (undefined = a single free voice for samples).
function scr_audio_player_new(_song) {
    var _player = {
        song : _song, ord : 0, row : 0, tick : 0, speed : 6, tempo : 125, tick_left : 0,
        next_ord : -1, next_row : 0, frame : 0, marks : [], ch : [], done : false,
        mono : false, lpl : 0, lpr : 0, loop_row : 0, loop_count : 0, pattern_delay : 0,
        mute : [false, false, false, false]
    };
    var _c = 0;
    while (_c < 4) {
        array_push(_player.ch, {
            on : false, smp : 0, data : [], len : 0, pos : 0, inc : 0, vol : 0,
            period : 428, base : 428, fx : 0, prm : 0, porta_to : 0, porta_spd : 0, vib_phase : 0, vib_prm : 0,
            ls : 0, ll : 0, dnote : 0, dtick : -1, trem_phase : 0, vol_offset : 0,
            loop_row : 0, loop_count : 0
        });
        _c += 1;
    }
    return _player;
}

function scr_audio_player_trigger(_player, _ch, _period) {
    if (_ch.smp < 1 || _ch.smp > 31) return;
    var _s = _player.song.samples[_ch.smp - 1];
    _ch.data = _s.data;
    _ch.len = _s.length;
    _ch.ls = _s.loop_start;
    _ch.ll = _s.loop_length;
    _ch.pos = 0;
    _ch.on = _ch.len > 1;
    _ch.base = _period;
    _ch.period = _period;
    _ch.vib_phase = 0;
}

function scr_audio_player_volslide(_ch, _prm) {
    if ((_prm >> 4) > 0) _ch.vol = min(64, _ch.vol + (_prm >> 4));
    else _ch.vol = max(0, _ch.vol - (_prm & 15));
}

function scr_audio_player_porta(_ch) {
    if (_ch.porta_to <= 0) return;
    if (_ch.base < _ch.porta_to) _ch.base = min(_ch.porta_to, _ch.base + _ch.porta_spd);
    else _ch.base = max(_ch.porta_to, _ch.base - _ch.porta_spd);
    _ch.period = _ch.base;
}

function scr_audio_player_vibrato(_ch) {
    var _speed = _ch.vib_prm >> 4;
    var _depth = _ch.vib_prm & 15;
    _ch.vib_phase = (_ch.vib_phase + _speed) mod 64;
    _ch.period = clamp(_ch.base + dsin(_ch.vib_phase * 360 / 64) * _depth * 2, 113, 856);
}

/// Tick 0: reads the row.
function scr_audio_player_row(_player) {
    var _song = _player.song;
    var _cells = _song.patterns[_song.order[_player.ord]];
    var _row = clamp(_player.row, 0, 63);
    array_push(_player.marks, [_player.frame, _player.ord, _row, _song.order[_player.ord]]);
    var _c = 0;
    while (_c < 4) {
        var _ch = _player.ch[_c];
        var _at = (_row * 4 + _c) * 4;
        var _period = _cells[_at];
        var _sample = _cells[_at + 1];
        var _fx = _cells[_at + 2];
        var _prm = _cells[_at + 3];
        _ch.fx = _fx;
        _ch.prm = _prm;
        if (_fx != 4 && _fx != 6) _ch.period = _ch.base;
        _ch.dtick = -1;
        if (_sample > 0 && _sample <= 31) {
            _ch.smp = _sample;
            _ch.vol = _song.samples[_sample - 1].volume;
        }
        if (_period > 0) {
            var _per = _period;
            if (_ch.smp > 0) {
                var _ft = _song.samples[_ch.smp - 1].finetune;
                if (_ft != 0) _per = _per * power(2, -_ft / 96);
            }
            if (_fx == 3 || _fx == 5) {
                _ch.porta_to = _per;
                if (!_ch.on) scr_audio_player_trigger(_player, _ch, _per);
            } else if (_fx == 14 && (_prm >> 4) == 13 && (_prm & 15) > 0) {
                _ch.dnote = _per;
                _ch.dtick = _prm & 15;
            } else {
                scr_audio_player_trigger(_player, _ch, _per);
                if (_fx == 9) _ch.pos = _prm * 256;
            }
        }
        switch (_fx) {
            case 3:
                if (_prm > 0) _ch.porta_spd = _prm;
                break;
            case 4:
                if ((_prm >> 4) > 0) _ch.vib_prm = (_ch.vib_prm & 15) | (_prm & 240);
                if ((_prm & 15) > 0) _ch.vib_prm = (_ch.vib_prm & 240) | (_prm & 15);
                break;
            case 11:
                _player.next_ord = _prm;
                _player.next_row = 0;
                break;
            case 12:
                _ch.vol = min(64, _prm);
                break;
            case 13:
                if (_player.next_ord < 0) _player.next_ord = _player.ord + 1;
                _player.next_row = min(63, (_prm >> 4) * 10 + (_prm & 15));
                break;
            case 14:
                var _sub = _prm >> 4;
                var _v = _prm & 15;
                if (_sub == 1) _ch.base = max(113, _ch.base - _v);
                if (_sub == 2) _ch.base = min(856, _ch.base + _v);
                if (_sub == 6) {
                    if (_v == 0) {
                        _ch.loop_row = _row;
                    } else {
                        if (_ch.loop_count == 0) {
                            _ch.loop_count = _v;
                            _player.next_ord = _player.ord;
                            _player.next_row = _ch.loop_row;
                        } else {
                            _ch.loop_count -= 1;
                            if (_ch.loop_count > 0) {
                                _player.next_ord = _player.ord;
                                _player.next_row = _ch.loop_row;
                            }
                        }
                    }
                }
                if (_sub == 10) _ch.vol = min(64, _ch.vol + _v);
                if (_sub == 11) _ch.vol = max(0, _ch.vol - _v);
                if (_sub == 12 && _v == 0) _ch.vol = 0;
                if (_sub == 14) _player.pattern_delay = _v;
                _ch.period = _ch.base;
                break;
            case 15:
                if (_prm > 0) {
                    if (_prm < 32) _player.speed = _prm;
                    else _player.tempo = _prm;
                }
                break;
        }
        _c += 1;
    }
}

/// Ticks 1..speed-1: running effects.
function scr_audio_player_effects(_player) {
    var _t = _player.tick;
    var _c = 0;
    while (_c < 4) {
        var _ch = _player.ch[_c];
        var _prm = _ch.prm;
        switch (_ch.fx) {
            case 0:
                if (_prm != 0) {
                    var _k = _t mod 3;
                    var _semi = (_k == 1) ? (_prm >> 4) : ((_k == 2) ? (_prm & 15) : 0);
                    _ch.period = _ch.base * power(2, -_semi / 12);
                }
                break;
            case 1:
                _ch.base = max(113, _ch.base - _prm);
                _ch.period = _ch.base;
                break;
            case 2:
                _ch.base = min(856, _ch.base + _prm);
                _ch.period = _ch.base;
                break;
            case 3:
                scr_audio_player_porta(_ch);
                break;
            case 4:
                scr_audio_player_vibrato(_ch);
                break;
            case 5:
                scr_audio_player_porta(_ch);
                scr_audio_player_volslide(_ch, _prm);
                break;
            case 6:
                scr_audio_player_vibrato(_ch);
                scr_audio_player_volslide(_ch, _prm);
                break;
            case 10:
                scr_audio_player_volslide(_ch, _prm);
                break;
            case 14:
                var _sub = _prm >> 4;
                var _v = _prm & 15;
                if (_sub == 12 && _t == _v) _ch.vol = 0;
                if (_sub == 13 && _t == _v && _ch.dtick >= 0) {
                    scr_audio_player_trigger(_player, _ch, _ch.dnote);
                    _ch.dtick = -1;
                }
                if (_sub == 9 && _v > 0 && (_t mod _v) == 0) {
                    _ch.pos = 0;
                    _ch.on = _ch.len > 1;
                }
                break;
        }
        _c += 1;
    }
}

/// Advances one tick (50 Hz at tempo 125).
function scr_audio_player_tick(_player) {
    if (_player.song == undefined) return;
    if (_player.tick == 0) scr_audio_player_row(_player);
    else scr_audio_player_effects(_player);
    _player.tick += 1;
    if (_player.tick >= _player.speed * (1 + _player.pattern_delay)) {
        _player.tick = 0;
        _player.pattern_delay = 0;
        if (_player.next_ord >= 0) {
            _player.ord = _player.next_ord;
            _player.row = _player.next_row;
            _player.next_ord = -1;
            _player.next_row = 0;
        } else {
            _player.row += 1;
            if (_player.row >= 64) {
                _player.row = 0;
                _player.ord += 1;
            }
        }
        var _count = array_length(_player.song.order);
        if (_player.ord >= _count) _player.ord = clamp(_player.song.restart, 0, _count - 1);
    }
}

/// Mixes _n stereo frames (signed 16-bit) into _buffer at its position.
function scr_audio_player_mix(_player, _buffer, _n) {
    var _ml = array_create(_n, 0);
    var _mr = array_create(_n, 0);
    var _done = 0;
    var _clock = AUDIO_PAULA_CLOCK / AUDIO_MIX_RATE;
    while (_done < _n) {
        if (_player.tick_left <= 0) {
            scr_audio_player_tick(_player);
            var _c = 0;
            while (_c < 4) {
                var _cc = _player.ch[_c];
                _cc.inc = _clock / clamp(_cc.period, 100, 2000);
                _c += 1;
            }
            scr_audio_player_meter(_player);
            _player.tick_left += AUDIO_MIX_RATE * 2.5 / max(32, _player.tempo);
        }
        var _k = min(_n - _done, ceil(_player.tick_left));
        var _c2 = 0;
        while (_c2 < 4) {
            var _ch = _player.ch[_c2];
            if (_ch.on) {
                var _d = _ch.data;
                var _len = _ch.len;
                var _pos = _ch.pos;
                var _inc = _ch.inc;
                // A muted voice keeps running silently (the tracker's channel mutes).
                var _v = _player.mute[_c2] ? 0 : _ch.vol;
                var _loop = _ch.ll > 2;
                var _le = _ch.ls + _ch.ll;
                var _left = _player.mono || _c2 == 0 || _c2 == 3;
                var _right = _player.mono || !_left;
                var _i = _done;
                while (_i < _done + _k) {
                    if (_loop) {
                        while (_pos >= _le) _pos -= _ch.ll;
                    } else if (_pos >= _len) {
                        _ch.on = false;
                        break;
                    }
                    var _s = _d[floor(_pos)] * _v;
                    if (_left) _ml[_i] += _s;
                    if (_right) _mr[_i] += _s;
                    _pos += _inc;
                    _i += 1;
                }
                _ch.pos = _pos;
            }
            _c2 += 1;
        }
        _player.tick_left -= _k;
        _player.frame += _k;
        _done += _k;
    }
    // A500 fixed output low-pass (about 4.9 kHz, one pole), plus a little
    // crossfeed so Paula's hard panning is easier on headphones.
    var _a = 1 - exp(-2 * pi * 4900 / AUDIO_MIX_RATE);
    var _gain = _player.mono ? 3.5 : 2;
    var _lpl = _player.lpl;
    var _lpr = _player.lpr;
    var _j = 0;
    while (_j < _n) {
        var _ol = _ml[_j] * 0.8 + _mr[_j] * 0.2;
        var _or = _mr[_j] * 0.8 + _ml[_j] * 0.2;
        _lpl += _a * (_ol - _lpl);
        _lpr += _a * (_or - _lpr);
        buffer_write(_buffer, buffer_s16, clamp(_lpl * _gain, -32767, 32767));
        buffer_write(_buffer, buffer_s16, clamp(_lpr * _gain, -32767, 32767));
        _j += 1;
    }
    _player.lpl = _lpl;
    _player.lpr = _lpr;
}

/// Records level and a short scope trace of each voice at a tick.
function scr_audio_player_meter(_player) {
    var _levels = array_create(4, 0);
    var _scopes = array_create(4, undefined);
    var _c = 0;
    while (_c < 4) {
        var _ch = _player.ch[_c];
        var _trace = array_create(32, 0);
        if (_ch.on && _ch.len > 1) {
            var _pos = _ch.pos;
            var _peak = 0;
            var _i = 0;
            while (_i < 32) {
                var _p = floor(_pos);
                if (_ch.ll > 2) {
                    while (_p >= _ch.ls + _ch.ll) _p -= _ch.ll;
                }
                if (_p >= _ch.len) break;
                var _v = _ch.data[_p] * _ch.vol / (128 * 64);
                _trace[_i] = _v;
                _peak = max(_peak, abs(_v));
                _pos += _ch.inc * 4;
                _i += 1;
            }
            _levels[_c] = _peak;
        }
        _scopes[_c] = _trace;
        _c += 1;
    }
    array_push(_player.marks, [_player.frame, -1, _levels, _scopes]);
    if (array_length(_player.marks) > 600) array_delete(_player.marks, 0, 300);
}

/// Starts the streaming queue for _player.
function scr_audio_stream_start(_player, _kind, _name) {
    scr_audio_preview_stop();
    scr_audio_service_ensure();
    global.audio_player = _player;
    global.audio_queue = audio_create_play_queue(buffer_s16, AUDIO_MIX_RATE, audio_stereo);
    global.audio_frames_queued = 0;
    global.audio_streaming = true;
    global.audio_preview_kind = _kind;
    global.audio_preview_name = _name;
    global.audio_queue_t0 = get_timer();
    scr_audio_stream_fill(AUDIO_MIX_RATE * 0.25);
    global.audio_queue_inst = audio_play_sound(global.audio_queue, 1, false);
    global.audio_queue_t0 = get_timer();
    global.audio_preview_t0 = global.audio_queue_t0;
}

/// Mixes and queues audio until _ahead frames are waiting.
function scr_audio_stream_fill(_ahead) {
    var _elapsed = (get_timer() - global.audio_queue_t0) / 1000000 * AUDIO_MIX_RATE;
    var _guard = 0;
    while (global.audio_frames_queued < _elapsed + _ahead && _guard < 12) {
        var _n = 1024;
        var _b = buffer_create(_n * 4, buffer_fixed, 1);
        scr_audio_player_mix(global.audio_player, _b, _n);
        audio_queue_sound(global.audio_queue, _b, 0, _n * 4);
        array_push(global.audio_queue_bufs, _b);
        global.audio_frames_queued += _n;
        _guard += 1;
    }
}

/// @desc scr_audio_preview_stop()
/// Stops any sample or module preview.
function scr_audio_preview_stop() {
    if (global.audio_queue_inst != -1) {
        audio_stop_sound(global.audio_queue_inst);
        global.audio_queue_inst = -1;
    }
    if (global.audio_queue != -1) {
        audio_free_play_queue(global.audio_queue);
        global.audio_queue = -1;
    }
    var _i = 0;
    while (_i < array_length(global.audio_queue_bufs)) {
        array_push(global.audio_dead_bufs, [global.audio_queue_bufs[_i], current_time]);
        _i += 1;
    }
    global.audio_queue_bufs = [];
    global.audio_streaming = false;
    global.audio_player = undefined;
    if (global.audio_preview_inst != -1) {
        audio_stop_sound(global.audio_preview_inst);
        global.audio_preview_inst = -1;
    }
    if (global.audio_preview_sound != -1) {
        audio_free_buffer_sound(global.audio_preview_sound);
        global.audio_preview_sound = -1;
    }
    if (global.audio_preview_buffer != -1) {
        // Freed after a short delay like the queue buffers.
        array_push(global.audio_dead_bufs, [global.audio_preview_buffer, current_time]);
        global.audio_preview_buffer = -1;
    }
    global.audio_preview_kind = "";
    global.audio_preview_name = "";
}

/// @desc scr_audio_preview_sample(_asset)
/// Plays a SAMPLE asset like Paula: signed 8-bit data at 3546895 / period
/// Hz and volume / 64. A looping sample plays once to the loop end and then
/// repeats the loop until stopped.
function scr_audio_preview_sample(_asset) {
    scr_audio_preview_stop();
    if (!is_struct(_asset) || _asset.type != "SAMPLE" || _asset.length < 2) return;
    var _bytes = scr_audio_asset_bytes(_asset);
    if (_bytes == -1) return;
    var _length = _asset.length;
    var _rate = AUDIO_PAULA_CLOCK / clamp(_asset.period, AUDIO_PERIOD_MIN, AUDIO_PERIOD_MAX);
    global.audio_preview_rate = _rate;
    global.audio_preview_length = _length;
    global.audio_preview_loop_start = _asset.loop ? _asset.loop_start : 0;
    global.audio_preview_loop_length = _asset.loop ? _asset.loop_length : 0;

    if (_asset.loop && _asset.loop_length >= 2) {
        var _data = array_create(_length, 0);
        buffer_seek(_bytes, buffer_seek_start, 0);
        var _i = 0;
        while (_i < _length) {
            _data[_i] = buffer_read(_bytes, buffer_s8);
            _i += 1;
        }
        buffer_delete(_bytes);
        var _player = scr_audio_player_new(undefined);
        _player.mono = true;
        _player.tick_left = 1000000000;
        var _ch = _player.ch[0];
        _ch.data = _data;
        _ch.len = _length;
        _ch.ls = _asset.loop_start;
        _ch.ll = _asset.loop_length;
        _ch.vol = clamp(_asset.volume, 0, 64);
        _ch.period = _asset.period;
        _ch.base = _asset.period;
        _ch.inc = (AUDIO_PAULA_CLOCK / AUDIO_MIX_RATE) / _asset.period;
        _ch.on = true;
        // A loop shorter than 2 words would make the mixer spin; the
        // define function already guarantees at least 2 bytes.
        scr_audio_stream_start(_player, "SAMPLE", _asset.name);
        return;
    }

    // One-shot: a 16-bit buffer sound. GameMaker needs 8000-48000 Hz, so
    // slow periods hold each sample for k output frames (keeps the crunch).
    var _hold = max(1, ceil(8000 / _rate));
    var _out_rate = round(_rate * _hold);
    var _frames = _length * _hold;
    var _pcm = buffer_create(_frames * 2, buffer_fixed, 2);
    var _scale = 256 * clamp(_asset.volume, 0, 64) / 64;
    buffer_seek(_bytes, buffer_seek_start, 0);
    var _j = 0;
    while (_j < _length) {
        var _value = round(buffer_read(_bytes, buffer_s8) * _scale);
        repeat (_hold) buffer_write(_pcm, buffer_s16, _value);
        _j += 1;
    }
    buffer_delete(_bytes);
    scr_audio_service_ensure();
    global.audio_preview_buffer = _pcm;
    global.audio_preview_sound = audio_create_buffer_sound(_pcm, buffer_s16, _out_rate, 0, _frames * 2, audio_mono);
    global.audio_preview_inst = audio_play_sound(global.audio_preview_sound, 1, false);
    global.audio_preview_kind = "SAMPLE";
    global.audio_preview_name = _asset.name;
    global.audio_preview_t0 = get_timer();
}

/// @desc scr_audio_preview_mod(_asset)
/// Streams a MOD asset through the GML ProTracker player (loops forever
/// at the song's restart position). Returns false when it can't be parsed.
function scr_audio_preview_mod(_asset) {
    scr_audio_preview_stop();
    if (!is_struct(_asset) || _asset.type != "MOD") return false;
    var _bytes = scr_audio_asset_bytes(_asset);
    if (_bytes == -1) return false;
    var _song = scr_audio_mod_song(_bytes);
    buffer_delete(_bytes);
    if (_song == undefined) {
        scr_set_status_message("Can't play " + _asset.name + ": not a 4-channel ProTracker module", c_red);
        return false;
    }
    scr_audio_stream_start(scr_audio_player_new(_song), "MOD", _asset.name);
    return true;
}

/// @desc scr_audio_preview_step()
/// Call every Step: keeps the queue fed, ends finished one-shots and frees
/// buffers that are no longer playing.
function scr_audio_preview_step() {
    var _i = array_length(global.audio_dead_bufs) - 1;
    while (_i >= 0) {
        if (current_time - global.audio_dead_bufs[_i][1] > 1500) {
            if (buffer_exists(global.audio_dead_bufs[_i][0])) buffer_delete(global.audio_dead_bufs[_i][0]);
            array_delete(global.audio_dead_bufs, _i, 1);
        }
        _i -= 1;
    }
    if (global.audio_preview_inst != -1 && !audio_is_playing(global.audio_preview_inst)) {
        scr_audio_preview_stop();
        return;
    }
    if (!global.audio_streaming) return;
    var _elapsed = (get_timer() - global.audio_queue_t0) / 1000000 * AUDIO_MIX_RATE;
    if (_elapsed > global.audio_frames_queued) {
        // The queue ran dry (window dragged, app paused): carry on from here.
        global.audio_queue_t0 = get_timer() - global.audio_frames_queued / AUDIO_MIX_RATE * 1000000;
    }
    scr_audio_stream_fill(AUDIO_MIX_RATE * 0.3);
    if (global.audio_queue_inst == -1 || !audio_is_playing(global.audio_queue_inst)) {
        global.audio_queue_inst = audio_play_sound(global.audio_queue, 1, false);
    }
}

/// @desc scr_audio_preview_async()
/// Call from an Async - Audio Playback event: frees a played queue buffer.
function scr_audio_preview_async() {
    var _b = async_load[? "buffer_id"];
    if (is_undefined(_b)) return;
    var _i = 0;
    while (_i < array_length(global.audio_queue_bufs)) {
        if (global.audio_queue_bufs[_i] == _b) {
            array_delete(global.audio_queue_bufs, _i, 1);
            if (buffer_exists(_b)) buffer_delete(_b);
            return;
        }
        _i += 1;
    }
}

/// @desc scr_audio_preview_pos()
/// What is being heard now, or undefined when nothing plays:
///   { kind, name, position, pattern, row, byte, levels[4], scopes[4][32] }
/// MOD: position = order index, pattern, row; byte = -1.
/// SAMPLE: byte = playhead in the sample data; position/pattern/row = -1.
function scr_audio_preview_pos() {
    if (global.audio_preview_kind == "") return undefined;
    var _pos = {
        kind : global.audio_preview_kind, name : global.audio_preview_name,
        position : -1, pattern : -1, row : -1, byte : -1,
        levels : [0, 0, 0, 0], scopes : [[], [], [], []]
    };
    var _seconds = (get_timer() - global.audio_preview_t0) / 1000000;
    if (global.audio_preview_kind == "SAMPLE") {
        var _byte = _seconds * global.audio_preview_rate;
        var _ls = global.audio_preview_loop_start;
        var _ll = global.audio_preview_loop_length;
        if (_ll >= 2 && _byte >= _ls + _ll) _byte = _ls + ((_byte - _ls) mod _ll);
        _pos.byte = min(floor(_byte), global.audio_preview_length);
        return _pos;
    }
    if (!global.audio_streaming || global.audio_player == undefined) return _pos;
    var _heard = (get_timer() - global.audio_queue_t0) / 1000000 * AUDIO_MIX_RATE;
    var _marks = global.audio_player.marks;
    var _have_row = false;
    var _have_meter = false;
    var _i = array_length(_marks) - 1;
    while (_i >= 0 && !(_have_row && _have_meter)) {
        var _m = _marks[_i];
        if (_m[0] <= _heard) {
            if (_m[1] >= 0 && !_have_row) {
                _pos.position = _m[1];
                _pos.row = _m[2];
                _pos.pattern = _m[3];
                _have_row = true;
            } else if (_m[1] < 0 && !_have_meter) {
                _pos.levels = _m[2];
                _pos.scopes = _m[3];
                _have_meter = true;
            }
        }
        _i -= 1;
    }
    return _pos;
}

/// Frees everything (obj_audio_service CleanUp).
function scr_audio_preview_free() {
    scr_audio_preview_stop();
    var _i = 0;
    while (_i < array_length(global.audio_dead_bufs)) {
        if (buffer_exists(global.audio_dead_bufs[_i][0])) buffer_delete(global.audio_dead_bufs[_i][0]);
        _i += 1;
    }
    global.audio_dead_bufs = [];
}
