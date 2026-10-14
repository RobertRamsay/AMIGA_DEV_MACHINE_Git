/// @desc "Pixel Hearts": the demo song of tutorials 10 and 15 and the editor
/// tour (TutorialTune / Chiptune), written with the TRACKER's song model so
/// it opens in the tracker like any song a user makes. Original music, built
/// with the classic ProTracker techniques of the well-known Amiga modules:
///   - an I-V-vi-IV hook (C G Am F) with a call-and-response lead, then a
///     B section (F G Em Am / F G C G) that climbs back into the hook;
///   - an echo channel: the lead again 3 rows later, quieter (Cxx);
///   - delayed, light vibrato (4A2) on held lead notes, a tone-portamento
///     slide (3xx), and every lead note fades out (Axy / 6xy) and is cut (C00)
///     before a rest, so nothing rings on;
///   - an octave-bouncing synth bass;
///   - chip chord stabs: arpeggio 0xy on a tiny looped square, gated by C00;
///   - a one-channel chip drum kit with accents (Cxx) and fills;
///   - an intro that builds over two patterns, restart at the hook.
/// Speed 6 at 140 BPM; channels: 0 lead, 1 echo / stabs, 2 bass, 3 drums.

#macro TB_SONG_LEAD 1
#macro TB_SONG_BASS 2
#macro TB_SONG_KICK 4
#macro TB_SONG_SNARE 5
#macro TB_SONG_HAT 6
#macro TB_SONG_STAB 7

/// Note index (0 = C-1 .. 35 = B-3) of a name such as "C3", "F#2", "A#1".
function scr_tb_note(_name) {
    var _letters = "C D EF G A B";
    var _index = string_pos(string_char_at(_name, 1), _letters) - 1;
    var _sharp = string_char_at(_name, 2) == "#";
    var _octave = real(string_char_at(_name, _sharp ? 3 : 2));
    return clamp(_index + (_sharp ? 1 : 0) + (_octave - 1) * 12, 0, 35);
}

/// Writes one cell; _note -1 = no note.
function scr_tb_song_cell(_cells, _row, _ch, _note, _sample, _fx, _prm) {
    if (_row < 0 || _row > 63) return;
    var _at = scr_tracker_cell_at(_row, _ch);
    if (_note >= 0) {
        var _periods = scr_audio_note_periods();
        _cells[@ _at] = _periods[clamp(_note, 0, 35)];
        _cells[@ _at + 1] = _sample;
    }
    _cells[@ _at + 2] = _fx;
    _cells[@ _at + 3] = _prm;
}

/// Lead line on channel 0: events [row, "note", length(, "slide")]. Notes of
/// 6 rows or more get a light, quick vibrato from their third row on (delayed
/// vibrato). Every note ends: its last row fades out (Axy, or 6xy to keep the
/// vibrato going), and the row after it is cut (C00) unless the next note
/// starts there - the looped lead wave never rings on into a rest.
/// _expression false writes the bare notes only (tutorial 16's stage 4, where
/// the ringing notes show why the fades and cuts are needed).
function scr_tb_song_lead(_cells, _events, _expression = true) {
    var _i = 0;
    while (_i < array_length(_events)) {
        var _e = _events[_i];
        var _start = _e[0];
        var _len = _e[2];
        var _note = scr_tb_note(_e[1]);
        if (!_expression) {
            scr_tb_song_cell(_cells, _start, 0, _note, TB_SONG_LEAD, 12, 50);
            _i += 1;
            continue;
        }
        var _vibrato = _len >= 6;
        if (array_length(_e) > 3 && _e[3] == "slide") {
            scr_tb_song_cell(_cells, _start, 0, _note, TB_SONG_LEAD, 3, $28);
            scr_tb_song_cell(_cells, _start + 1, 0, -1, 0, 3, 0);
        } else {
            scr_tb_song_cell(_cells, _start, 0, _note, TB_SONG_LEAD, 12, 50);
        }
        if (_vibrato) {
            var _r = _start + 2;
            while (_r < _start + _len - 1) {
                scr_tb_song_cell(_cells, _r, 0, -1, 0, 4, _r == _start + 2 ? $A2 : 0);
                _r += 1;
            }
        }
        // Fade on the last row: 5 slide ticks a row at speed 6. Long notes
        // fade a bit more slowly than the short, plucky ones.
        if (_len >= 2) {
            var _last = _start + _len - 1;
            if (_vibrato) scr_tb_song_cell(_cells, _last, 0, -1, 0, 6, $08);
            else scr_tb_song_cell(_cells, _last, 0, -1, 0, 10, _len >= 4 ? $08 : $04);
        }
        // The rest after the note (a later event's note overwrites this cut).
        scr_tb_song_cell(_cells, _start + _len, 0, -1, 0, 12, 0);
        _i += 1;
    }
}

/// Channel 1 echoes channel 0 _delay rows later: its notes at _volume, its
/// fades (gentler, as the echo is quieter) and its cuts, so echoes end too.
function scr_tb_song_echo(_cells, _delay, _volume) {
    var _row = 63 - _delay;
    while (_row >= 0) {
        var _src = scr_tracker_cell_at(_row, 0);
        var _dst = scr_tracker_cell_at(_row + _delay, 1);
        var _fx = _cells[_src + 2];
        var _prm = _cells[_src + 3];
        if (_cells[_src] != 0) {
            _cells[@ _dst] = _cells[_src];
            _cells[@ _dst + 1] = TB_SONG_LEAD;
            _cells[@ _dst + 2] = 12;
            _cells[@ _dst + 3] = _volume;
        } else if (_fx == 10 || _fx == 6) {
            _cells[@ _dst + 2] = 10;
            _cells[@ _dst + 3] = $03;
        } else if (_fx == 12 && _prm == 0) {
            _cells[@ _dst + 2] = 12;
            _cells[@ _dst + 3] = 0;
        }
        _row -= 1;
    }
}

/// Chord stabs on channel 1, one chord per bar: _chords = [["C", true], ...]
/// (root name in octave 2, major?). Hits on rows 0, 3, 6, 10 and 12 of the
/// bar, two rows of arpeggio each, gated off with C00.
function scr_tb_song_stabs(_cells, _chords) {
    var _hits = [0, 3, 6, 10, 12];
    var _bar = 0;
    while (_bar < 4) {
        var _root = scr_tb_note(_chords[_bar][0] + "2");
        var _arp = _chords[_bar][1] ? $47 : $37;
        var _h = 0;
        while (_h < array_length(_hits)) {
            var _r = _bar * 16 + _hits[_h];
            scr_tb_song_cell(_cells, _r, 1, _root, TB_SONG_STAB, 0, _arp);
            scr_tb_song_cell(_cells, _r + 1, 1, -1, 0, 0, _arp);
            var _next = _h + 1 < array_length(_hits) ? _hits[_h + 1] : 16;
            if (_hits[_h] + 2 < _next) scr_tb_song_cell(_cells, _r + 2, 1, -1, 0, 12, 0);
            _h += 1;
        }
        _bar += 1;
    }
}

/// Octave-bouncing bass on channel 2: _roots = 4 root names (one per bar).
/// _whole: one long note per bar instead (the intro).
function scr_tb_song_bass(_cells, _roots, _whole) {
    var _bar = 0;
    while (_bar < 4) {
        var _low = scr_tb_note(_roots[_bar] + "1") + 12;      // BASS sounds an octave lower
        var _step = 0;
        while (_step < 8) {
            var _r = _bar * 16 + _step * 2;
            if (_whole) {
                if (_step == 0) scr_tb_song_cell(_cells, _r, 2, _low, TB_SONG_BASS, 12, 52);
            } else {
                var _high = (_step mod 2) == 1;
                // Bar end: a little run up into the next bar.
                if (_step == 7 && _bar == 3) _high = true;
                scr_tb_song_cell(_cells, _r, 2, _high ? _low + 12 : _low, TB_SONG_BASS, 12, _high ? 32 : 46);
            }
            _step += 1;
        }
        _bar += 1;
    }
}

/// Drums on channel 3. _style "hats" (closed hats only), "four" (kick and
/// hats), "groove" (kick, snare, hats); _fill: a snare roll in the last bar.
function scr_tb_song_drums(_cells, _bars_style, _fill) {
    var _bar = 0;
    while (_bar < 4) {
        var _style = _bars_style[_bar];
        var _step = 0;
        while (_step < 16) {
            var _r = _bar * 16 + _step;
            var _sample = 0;
            var _vol = 0;
            if (_style == "hats") {
                if ((_step mod 4) == 2) { _sample = TB_SONG_HAT; _vol = 30; }
            } else if (_style == "four") {
                if ((_step mod 4) == 0) { _sample = TB_SONG_KICK; _vol = 64; }
                else if ((_step mod 2) == 0) { _sample = TB_SONG_HAT; _vol = 30; }
            } else {
                switch (_step) {
                    case 0: case 8: case 11: _sample = TB_SONG_KICK; _vol = _step == 11 ? 48 : 64; break;
                    case 4: case 12: _sample = TB_SONG_SNARE; _vol = 60; break;
                    case 2: case 6: case 10: case 14: _sample = TB_SONG_HAT; _vol = (_step == 6 || _step == 14) ? 36 : 24; break;
                    case 15: _sample = TB_SONG_HAT; _vol = 14; break;     // ghost hat
                }
            }
            // Fill: the second half of the last bar becomes a rising snare roll.
            if (_fill && _bar == 3 && _step >= 8) {
                if (_step == 8) { _sample = TB_SONG_KICK; _vol = 64; }
                else if (_step == 10 || _step >= 12) { _sample = TB_SONG_SNARE; _vol = 28 + (_step - 10) * 6; }
                else { _sample = 0; }
            }
            if (_sample != 0) {
                var _drum_note = scr_tb_note("C2");
                scr_tb_song_cell(_cells, _r, 3, _drum_note, _sample, 12, min(_vol, 64));
            }
            _step += 1;
        }
        _bar += 1;
    }
}

/// Number of the last build stage (the finished song).
#macro TB_SONG_STAGES 9

/// Builds "Pixel Hearts" and saves it as the MOD asset _name. Returns the
/// name, or "" when it could not be saved.
/// _stage builds it only up to a step of tutorial 16 ("Write a tracker
/// song"), the hook first:
///   1 kit + tempo   2 drums   3 bass   4 hook melody (plain notes)
///   5 vibrato, fades and cuts   6 echo channel   7 the answer pattern
///   8 the B section   9 intro, last hook and order list = the whole song.
function scr_tb_hook_song(_name, _stage = TB_SONG_STAGES) {
    var _song = scr_tracker_song_new();
    _song.title = "pixel hearts";
    // Instruments: the starter kit (1 pulse lead, 2 bass, 3 organ, 4 kick,
    // 5 snare, 6 hi-hat) plus a quiet square for the chord stabs.
    _song.samples[TB_SONG_LEAD - 1].name = "lead (pulse)";
    _song.samples[TB_SONG_LEAD - 1].volume = 44;
    _song.samples[TB_SONG_STAB - 1] = scr_tracker_synth("SQUARE");
    _song.samples[TB_SONG_STAB - 1].name = "chord stab";
    _song.samples[TB_SONG_STAB - 1].volume = 22;

    var _p = 0;
    while (_p < 7) {
        if (_p > 0) array_push(_song.patterns, scr_tracker_pattern_empty());
        _p += 1;
    }
    var _hook_chords = [["C", true], ["G", true], ["A", false], ["F", true]];
    var _hook_roots = ["C", "G", "A", "F"];
    var _groove = ["groove", "groove", "groove", "groove"];
    var _expression = _stage >= 5;

    // The hook: call (bars 1-2) and answer (bars 3-4).
    var _hook_call = [
        [0, "E3", 2], [2, "E3", 2], [4, "D3", 2], [6, "C3", 4], [10, "D3", 2], [12, "E3", 4],
        [16, "D3", 4], [20, "B2", 2], [22, "G2", 4], [26, "G2", 2], [28, "A2", 2], [30, "B2", 2]
    ];
    var _answer_1 = [[32, "C3", 2], [34, "C3", 2], [36, "B2", 2], [38, "A2", 4], [42, "E3", 4], [46, "D3", 2],
                     [48, "C3", 6], [54, "A2", 2], [56, "C3", 8]];
    var _answer_2 = [[32, "C3", 2], [34, "C3", 2], [36, "B2", 2], [38, "A2", 2], [40, "E3", 2], [42, "G3", 2], [44, "A3", 4],
                     [48, "G3", 8], [56, "F3", 2], [58, "E3", 2], [60, "D3", 4]];

    // 2: hook A1 - built first, layer by layer (stages 1-6).
    var _c = _song.patterns[2];
    scr_tb_song_cell(_c, 0, 1, -1, 0, 15, 140);             // 140 BPM (the echo starts on row 3)
    if (_stage >= 2) scr_tb_song_drums(_c, _groove, false);
    if (_stage >= 3) scr_tb_song_bass(_c, _hook_roots, false);
    if (_stage >= 4) {
        scr_tb_song_lead(_c, _hook_call, _expression);
        scr_tb_song_lead(_c, _answer_1, _expression);
    }
    if (_stage >= 6) scr_tb_song_echo(_c, 3, 16);

    // 3: hook A2 - the answer climbs instead, a fill hands over to B.
    if (_stage >= 7) {
        _c = _song.patterns[3];
        scr_tb_song_lead(_c, _hook_call);
        scr_tb_song_lead(_c, _answer_2);
        scr_tb_song_echo(_c, 3, 16);
        scr_tb_song_bass(_c, _hook_roots, false);
        scr_tb_song_drums(_c, _groove, true);
    }

    if (_stage >= 8) {
        // 4: B1 - longer, higher notes over F G Em Am, stabs instead of the echo.
        _c = _song.patterns[4];
        scr_tb_song_lead(_c, [[0, "A3", 6], [6, "G3", 2], [8, "F3", 4], [12, "C3", 4],
                              [16, "D3", 6], [22, "E3", 2], [24, "F3", 2], [26, "E3", 2], [28, "D3", 4],
                              [32, "B2", 6], [38, "C3", 2], [40, "D3", 4], [44, "E3", 4],
                              [48, "A2", 8], [56, "C3", 4], [60, "E3", 4]]);
        scr_tb_song_stabs(_c, [["F", true], ["G", true], ["E", false], ["A", false]]);
        scr_tb_song_bass(_c, ["F", "G", "E", "A"], false);
        scr_tb_song_drums(_c, _groove, false);

        // 5: B2 - a slide up to the top note, then the build back into the hook.
        _c = _song.patterns[5];
        scr_tb_song_lead(_c, [[0, "A3", 6], [6, "G3", 2], [8, "F3", 4], [12, "A3", 4],
                              [16, "B3", 6, "slide"], [22, "A3", 2], [24, "G3", 8],
                              [32, "E3", 4], [36, "G3", 4], [40, "C3", 4], [44, "E3", 4],
                              [48, "D3", 4], [52, "G2", 2], [54, "B2", 2], [56, "D3", 2], [58, "G3", 6]]);
        scr_tb_song_stabs(_c, [["F", true], ["G", true], ["C", true], ["G", true]]);
        scr_tb_song_bass(_c, ["F", "G", "C", "G"], false);
        scr_tb_song_drums(_c, _groove, true);
    }

    if (_stage >= 9) {
        // 0: intro - stabs over hats, the bass enters, then kicks and a roll.
        _c = _song.patterns[0];
        scr_tb_song_stabs(_c, _hook_chords);
        scr_tb_song_bass(_c, _hook_roots, true);
        scr_tb_song_drums(_c, ["hats", "hats", "four", "four"], true);
        scr_tb_song_cell(_c, 0, 0, -1, 0, 15, 140);         // 140 BPM from the first row

        // 1: intro 2 - the full groove, the lead's pick-up into the hook.
        _c = _song.patterns[1];
        scr_tb_song_stabs(_c, _hook_chords);
        scr_tb_song_bass(_c, _hook_roots, false);
        scr_tb_song_drums(_c, _groove, true);
        scr_tb_song_lead(_c, [[56, "G2", 2], [58, "A2", 2], [60, "C3", 2], [62, "D3", 2]]);

        // 6: the last hook - A2's lead over the stabs (no echo), round to the hook.
        _c = _song.patterns[6];
        scr_tb_song_lead(_c, _hook_call);
        scr_tb_song_lead(_c, _answer_2);
        scr_tb_song_stabs(_c, _hook_chords);
        scr_tb_song_bass(_c, _hook_roots, false);
        scr_tb_song_drums(_c, _groove, true);
    }

    // The order list grows with the song; the finished one restarts at the hook.
    if (_stage >= 9) {
        _song.order = [0, 1, 2, 3, 4, 5, 2, 6];
        _song.restart = 2;
    } else if (_stage >= 8) {
        _song.order = [2, 3, 4, 5];
    } else if (_stage >= 7) {
        _song.order = [2, 3];
    } else {
        _song.order = [2];
    }
    var _error = scr_tracker_song_save(_song, _name);
    if (_error != "") {
        show_debug_message("[tutorial] song not saved: " + _error);
        return "";
    }
    return _name;
}

/// Where SHOW ME puts the tracker's cursor for build stage _stage:
/// [order position, channel, row].
function scr_tb_hook_song_cursor(_stage) {
    switch (_stage) {
        case 2: return [0, 3, 0];
        case 3: return [0, 2, 0];
        case 4: return [0, 0, 0];
        case 5: return [0, 0, 48];
        case 6: return [0, 1, 0];
        case 7: return [1, 0, 32];
        case 8: return [2, 0, 0];
        case 9: return [0, 1, 0];
    }
    return [0, 0, 0];
}

/// Tutorial 16's SHOW ME: rebuilds MySong up to _stage, links it to the
/// PLAY MUSIC node and opens it in the TRACKER at that stage's work, with
/// _hint in the tracker's message panel.
function scr_tutorial_song_show(_stage, _hint) {
    scr_audio_preview_stop();
    scr_tb_hook_song("MySong", _stage);
    with (obj_opcode_node) {
        if (is_macro && macro_type == "PLAY_MOD") macro_asset_name = "MySong";
    }
    var _editor = scr_tracker_open("MySong");
    var _cursor = scr_tb_hook_song_cursor(_stage);
    with (_editor) {
        tracker_load("MySong");
        cur_pos = min(_cursor[0], array_length(song.order) - 1);
        cur_ch = _cursor[1];
        cur_row = _cursor[2];
        cur_col = 0;
        tracker_message(_hint, c_lime);
    }
    return _editor;
}
