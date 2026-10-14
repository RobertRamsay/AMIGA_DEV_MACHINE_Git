/// @description TRACKER: ProTracker / OctaMED style music editor
// Full-screen modal. Edits a song struct (scr_tracker_song) and saves it as
// a 4-channel M.K. MOD asset, which PLAY MUSIC nodes play on the Amiga.
// Every clickable control comes from tracker_controls() and every area from
// tracker_layout(), shared by Step, Draw and the tour.
depth = -400000;

song = scr_tracker_song_new();
song_name = scr_audio_unique_name("song");
dirty = false;

// Cursor: order position, row, channel and column inside the cell
// (0 note, 1-2 instrument digits, 3 effect, 4-5 parameter digits).
cur_pos = 0;
cur_row = 0;
cur_ch = 0;
cur_col = 0;
cur_inst = 1;
octave = 1;                 // lower keyboard row = this octave, upper = +1
edit_step = 1;
edit_mode = true;
follow = true;
mute = [false, false, false, false];

order_scroll = 0;
inst_scroll = 0;
open_index = 0;             // MOD asset chosen in the OPEN selector
sample_index = 0;           // SAMPLE asset chosen in the instrument panel

field_active = "";          // "", "name", "title" or "inst"
field_text = "";
message = "";
message_colour = c_white;

undo_stack = [];
redo_stack = [];
clip_track = undefined;
clip_pattern = undefined;
vu_display = [0, 0, 0, 0];

/// Every area of the editor (room coordinates).
tracker_layout = function() {
    var _l = {
        x1 : 8, y1 : 8, x2 : room_width - 8, y2 : room_height - 8,
        header_h : 30,
        song : [16, 48, 436, 318],
        order : [446, 48, 666, 318],
        insts : [676, 48, 1106, 318],
        inst : [1116, 48, room_width - 16, 318],
        transport : [16, 326, room_width - 16, 352],
        tools : [16, 358, room_width - 16, 384],
        pattern : [16, 392, room_width - 16, 1028],
        row_h : 20,
        list_row_h : 20,
        rownum_w : 60,
        chan_header_h : 30
    };
    _l.order_rows = 8;
    _l.inst_rows = 10;
    _l.rows_y = _l.pattern[1] + _l.chan_header_h + 4;
    _l.visible_rows = floor((_l.pattern[3] - _l.rows_y) / _l.row_h);
    _l.chan_w = (_l.pattern[2] - _l.pattern[0] - _l.rownum_w) div 4;
    _l.wave = [_l.inst[0] + 420, _l.inst[1] + 36, _l.inst[2] - 12, _l.inst[1] + 130];
    return _l;
};

/// Left x of channel _c's column in the pattern view.
tracker_chan_x = function(_l, _c) {
    return _l.pattern[0] + _l.rownum_w + _c * _l.chan_w;
};

/// Every clickable control: { id, x1, y1, x2, y2, label, on, enabled }.
/// Value buttons (kind "value") step down on their left half, up on the right.
tracker_controls = function() {
    var _l = tracker_layout();
    var _list = [];
    var _playing = global.audio_preview_kind == "TRACKER";
    array_push(_list, { id : "close", x1 : _l.x2 - 30, y1 : _l.y1 + 5, x2 : _l.x2 - 8, y2 : _l.y1 + 25, label : "X", on : false, enabled : true });

    // SONG panel.
    var _sx = _l.song[0];
    var _sy = _l.song[1];
    array_push(_list, { id : "field_name", x1 : _sx + 80, y1 : _sy + 36, x2 : _sx + 408, y2 : _sy + 60, label : "", on : field_active == "name", enabled : true, kind : "field" });
    array_push(_list, { id : "field_title", x1 : _sx + 80, y1 : _sy + 66, x2 : _sx + 408, y2 : _sy + 90, label : "", on : field_active == "title", enabled : true, kind : "field" });
    array_push(_list, { id : "new", x1 : _sx + 12, y1 : _sy + 100, x2 : _sx + 140, y2 : _sy + 126, label : "NEW SONG", on : false, enabled : true });
    array_push(_list, { id : "save", x1 : _sx + 146, y1 : _sy + 100, x2 : _sx + 274, y2 : _sy + 126, label : "SAVE", on : false, enabled : true });
    array_push(_list, { id : "build", x1 : _sx + 280, y1 : _sy + 100, x2 : _sx + 408, y2 : _sy + 126, label : "SAVE + F5", on : false, enabled : true });
    var _mods = scr_audio_list("MOD");
    array_push(_list, { id : "open_prev", x1 : _sx + 12, y1 : _sy + 134, x2 : _sx + 36, y2 : _sy + 158, label : "<", on : false, enabled : array_length(_mods) > 0 });
    array_push(_list, { id : "open_next", x1 : _sx + 270, y1 : _sy + 134, x2 : _sx + 294, y2 : _sy + 158, label : ">", on : false, enabled : array_length(_mods) > 0 });
    array_push(_list, { id : "open", x1 : _sx + 300, y1 : _sy + 134, x2 : _sx + 408, y2 : _sy + 158, label : "OPEN", on : false, enabled : array_length(_mods) > 0 });

    // ORDER panel.
    var _ox = _l.order[0];
    var _oy = _l.order[1] + 36 + _l.order_rows * _l.list_row_h + 8;
    var _bw = 64;
    array_push(_list, { id : "ord_ins", x1 : _ox + 8, y1 : _oy, x2 : _ox + 8 + _bw, y2 : _oy + 24, label : "INS", on : false, enabled : array_length(song.order) < 128 });
    array_push(_list, { id : "ord_del", x1 : _ox + 78, y1 : _oy, x2 : _ox + 78 + _bw, y2 : _oy + 24, label : "DEL", on : false, enabled : array_length(song.order) > 1 });
    array_push(_list, { id : "ord_new", x1 : _ox + 148, y1 : _oy, x2 : _ox + 148 + _bw, y2 : _oy + 24, label : "NEW", on : false, enabled : array_length(song.patterns) < TRACKER_MAX_PATTERNS && array_length(song.order) < 128 });
    array_push(_list, { id : "ord_pat", x1 : _ox + 8, y1 : _oy + 30, x2 : _ox + 142, y2 : _oy + 54, label : "PATTERN " + scr_tracker_hex2(song.order[cur_pos]), on : false, enabled : true, kind : "value" });
    array_push(_list, { id : "ord_clone", x1 : _ox + 148, y1 : _oy + 30, x2 : _ox + 148 + _bw, y2 : _oy + 54, label : "CLONE", on : false, enabled : array_length(song.patterns) < TRACKER_MAX_PATTERNS && array_length(song.order) < 128 });

    // INSTRUMENT panel.
    var _ix = _l.inst[0];
    var _iy = _l.inst[1];
    var _smp = song.samples[cur_inst - 1];
    array_push(_list, { id : "field_inst", x1 : _ix + 80, y1 : _iy + 36, x2 : _ix + 400, y2 : _iy + 60, label : "", on : field_active == "inst", enabled : true, kind : "field" });
    array_push(_list, { id : "inst_vol", x1 : _ix + 12, y1 : _iy + 68, x2 : _ix + 140, y2 : _iy + 92, label : "VOL " + string(_smp.volume), on : false, enabled : true, kind : "value" });
    array_push(_list, { id : "inst_fine", x1 : _ix + 146, y1 : _iy + 68, x2 : _ix + 274, y2 : _iy + 92, label : "FINE " + string(_smp.finetune), on : false, enabled : true, kind : "value" });
    array_push(_list, { id : "inst_loop", x1 : _ix + 280, y1 : _iy + 68, x2 : _ix + 400, y2 : _iy + 92, label : "LOOP " + (_smp.loop_length >= 2 ? "ON" : "OFF"), on : _smp.loop_length >= 2, enabled : _smp.length >= 4 });
    array_push(_list, { id : "inst_play", x1 : _ix + 12, y1 : _iy + 100, x2 : _ix + 140, y2 : _iy + 124, label : "PLAY", on : false, enabled : _smp.length >= 2 });
    array_push(_list, { id : "inst_clear", x1 : _ix + 146, y1 : _iy + 100, x2 : _ix + 274, y2 : _iy + 124, label : "CLEAR", on : false, enabled : _smp.length > 0 });
    array_push(_list, { id : "inst_save", x1 : _ix + 280, y1 : _iy + 100, x2 : _ix + 400, y2 : _iy + 124, label : "TO SAMPLE", on : false, enabled : _smp.length >= 2 });
    var _kinds = scr_tracker_synth_kinds();
    var _kw = (_l.inst[2] - _ix - 24 - 4 * 6) / 5;
    for (var _k = 0; _k < array_length(_kinds); _k += 1) {
        var _kx = _ix + 12 + (_k mod 5) * (_kw + 6);
        var _ky = _iy + 158 + (_k div 5) * 30;
        array_push(_list, { id : "synth_" + _kinds[_k], x1 : _kx, y1 : _ky, x2 : _kx + _kw, y2 : _ky + 24, label : _kinds[_k], on : false, enabled : true });
    }
    var _samples = scr_audio_list("SAMPLE");
    var _ry = _iy + 228;
    array_push(_list, { id : "smp_prev", x1 : _ix + 160, y1 : _ry, x2 : _ix + 184, y2 : _ry + 24, label : "<", on : false, enabled : array_length(_samples) > 0 });
    array_push(_list, { id : "smp_next", x1 : _ix + 470, y1 : _ry, x2 : _ix + 494, y2 : _ry + 24, label : ">", on : false, enabled : array_length(_samples) > 0 });
    array_push(_list, { id : "smp_use", x1 : _ix + 500, y1 : _ry, x2 : _l.inst[2] - 12, y2 : _ry + 24, label : "USE SAMPLE", on : false, enabled : array_length(_samples) > 0 });

    // Transport bar.
    var _tx = _l.transport[0];
    var _ty = _l.transport[1];
    var _row = [
        ["play_song", "PLAY SONG", 130, _playing && global.audio_preview_name == "song", ""],
        ["play_pattern", "PLAY PATTERN", 150, _playing && global.audio_preview_name == "pattern", ""],
        ["stop", "STOP", 90, false, ""],
        ["edit", edit_mode ? "EDIT ON" : "EDIT OFF", 110, edit_mode, ""],
        ["follow", follow ? "FOLLOW ON" : "FOLLOW OFF", 130, follow, ""],
        ["inst_sel", "INSTR " + scr_tracker_hex2(cur_inst), 130, false, "value"],
        ["octave", "OCTAVE " + string(octave), 130, false, "value"],
        ["step", "STEP " + string(edit_step), 110, false, "value"],
        ["speed", "SPEED " + string(tracker_start_value(false)), 130, false, "value"],
        ["bpm", "BPM " + string(tracker_start_value(true)), 130, false, "value"],
        ["undo", "UNDO", 90, false, ""],
        ["redo", "REDO", 90, false, ""]
    ];
    for (var _i = 0; _i < array_length(_row); _i += 1) {
        var _e = _row[_i];
        array_push(_list, { id : _e[0], x1 : _tx, y1 : _ty, x2 : _tx + _e[2], y2 : _ty + 26, label : _e[1], on : _e[3],
            enabled : (_e[0] != "undo" || array_length(undo_stack) > 0) && (_e[0] != "redo" || array_length(redo_stack) > 0), kind : _e[4] });
        _tx += _e[2] + 6;
    }

    // Track and pattern tools.
    _tx = _l.tools[0];
    _ty = _l.tools[1];
    var _tools = [
        ["trk_copy", "COPY TRACK", 130], ["trk_paste", "PASTE TRACK", 140], ["trk_clear", "CLEAR TRACK", 140],
        ["trk_down12", "TRACK -12", 110], ["trk_down1", "TRACK -1", 100], ["trk_up1", "TRACK +1", 100], ["trk_up12", "TRACK +12", 110],
        ["pat_copy", "COPY PATTERN", 150], ["pat_paste", "PASTE PATTERN", 160], ["pat_clear", "CLEAR PATTERN", 160]
    ];
    for (var _j = 0; _j < array_length(_tools); _j += 1) {
        var _t = _tools[_j];
        var _en = (_t[0] != "trk_paste" || clip_track != undefined) && (_t[0] != "pat_paste" || clip_pattern != undefined);
        array_push(_list, { id : _t[0], x1 : _tx, y1 : _ty, x2 : _tx + _t[2], y2 : _ty + 26, label : _t[1], on : false, enabled : _en });
        _tx += _t[2] + 6;
    }

    // Channel mutes in the channel headers.
    for (var _c = 0; _c < 4; _c += 1) {
        var _cx = tracker_chan_x(_l, _c);
        array_push(_list, { id : "mute" + string(_c), x1 : _cx + 150, y1 : _l.pattern[1] + 4, x2 : _cx + 230, y2 : _l.pattern[1] + 26,
            label : mute[_c] ? "MUTED" : "MUTE", on : mute[_c], enabled : true });
    }
    return _list;
};

/// The pattern at the cursor's order position.
tracker_pattern = function() {
    return song.patterns[song.order[cur_pos]];
};

/// Saves the cells of pattern _index for undo (call before changing them).
tracker_push_undo_cells = function(_index) {
    var _copy = array_create(array_length(song.patterns[_index]), 0);
    array_copy(_copy, 0, song.patterns[_index], 0, array_length(_copy));
    array_push(undo_stack, { kind : "cells", index : _index, cells : _copy });
    if (array_length(undo_stack) > 200) array_delete(undo_stack, 0, 1);
    redo_stack = [];
    dirty = true;
};

/// Saves the order list for undo (call before changing it).
tracker_push_undo_order = function() {
    var _copy = array_create(array_length(song.order), 0);
    array_copy(_copy, 0, song.order, 0, array_length(_copy));
    array_push(undo_stack, { kind : "order", order : _copy, restart : song.restart });
    if (array_length(undo_stack) > 200) array_delete(undo_stack, 0, 1);
    redo_stack = [];
    dirty = true;
};

/// Undo (_from = undo_stack, _to = redo_stack) or redo (the other way).
tracker_undo_step = function(_redo) {
    var _from = _redo ? redo_stack : undo_stack;
    if (array_length(_from) == 0) return;
    var _entry = array_pop(_from);
    var _back;
    if (_entry.kind == "cells") {
        var _cells = song.patterns[_entry.index];
        var _now = array_create(array_length(_cells), 0);
        array_copy(_now, 0, _cells, 0, array_length(_cells));
        _back = { kind : "cells", index : _entry.index, cells : _now };
        // Copy back in place: the player holds the same array.
        array_copy(_cells, 0, _entry.cells, 0, array_length(_cells));
    } else {
        var _order_now = array_create(array_length(song.order), 0);
        array_copy(_order_now, 0, song.order, 0, array_length(song.order));
        _back = { kind : "order", order : _order_now, restart : song.restart };
        song.order = _entry.order;
        song.restart = _entry.restart;
        cur_pos = clamp(cur_pos, 0, array_length(song.order) - 1);
    }
    if (_redo) array_push(undo_stack, _back);
    else array_push(redo_stack, _back);
    dirty = true;
};

/// Speed (false) or tempo (true) the song starts with: an F effect on row 0
/// of the first pattern played, else ProTracker's 6 / 125.
tracker_start_value = function(_tempo) {
    var _cells = song.patterns[song.order[0]];
    var _value = _tempo ? 125 : 6;
    for (var _c = 0; _c < 4; _c += 1) {
        var _at = scr_tracker_cell_at(0, _c);
        var _prm = _cells[_at + 3];
        if (_cells[_at + 2] == 15 && _prm > 0 && (_prm >= 32) == _tempo) _value = _prm;
    }
    return _value;
};

/// Writes the start speed / tempo as an F effect on row 0 of the first
/// pattern (its existing F effect, else the first free effect column).
tracker_set_start_value = function(_tempo, _value) {
    var _index = song.order[0];
    var _cells = song.patterns[_index];
    var _slot = -1;
    for (var _c = 0; _c < 4; _c += 1) {
        var _at = scr_tracker_cell_at(0, _c);
        if (_cells[_at + 2] == 15 && _cells[_at + 3] > 0 && (_cells[_at + 3] >= 32) == _tempo) _slot = _c;
    }
    if (_slot < 0) {
        for (var _c2 = 3; _c2 >= 0; _c2 -= 1) {
            var _at2 = scr_tracker_cell_at(0, _c2);
            if (_cells[_at2 + 2] == 0 && _cells[_at2 + 3] == 0) _slot = _c2;
        }
    }
    if (_slot < 0) {
        tracker_message("Row 0 of pattern " + scr_tracker_hex2(_index) + " has no free effect column for F" + (_tempo ? " (tempo)" : " (speed)"), c_orange);
        return;
    }
    tracker_push_undo_cells(_index);
    var _at3 = scr_tracker_cell_at(0, _slot);
    _cells[@ _at3 + 2] = 15;
    _cells[@ _at3 + 3] = _tempo ? clamp(_value, 32, 255) : clamp(_value, 1, 31);
};

tracker_message = function(_text, _colour) {
    message = _text;
    message_colour = _colour;
};

/// Saves the song as its MOD asset. Returns true on success.
tracker_save = function() {
    var _error = scr_tracker_song_save(song, song_name);
    if (_error != "") {
        tracker_message(_error, c_red);
        return false;
    }
    dirty = false;
    global.tracker_last_name = song_name;
    var _asset = scr_asset_find_by_name(song_name);
    tracker_message("Saved MOD " + song_name + " (" + string(_asset.length) + " bytes) - PLAY MUSIC nodes can use it.", c_lime);
    return true;
};

/// Loads the MOD asset _name.
tracker_load = function(_name) {
    var _asset = scr_asset_find_by_name(_name);
    var _loaded = scr_tracker_song_from_asset(_asset);
    if (_loaded == undefined) {
        tracker_message("Can't open " + _name + ": not a 4-channel ProTracker module", c_red);
        return false;
    }
    scr_audio_preview_stop();
    song = _loaded;
    song_name = _name;
    global.tracker_last_name = _name;
    cur_pos = 0;
    cur_row = 0;
    order_scroll = 0;
    undo_stack = [];
    redo_stack = [];
    dirty = false;
    tracker_message("Opened " + _name + ": " + string(array_length(song.order)) + " positions, " + string(array_length(song.patterns)) + " patterns.", c_lime);
    return true;
};

/// Moves the cursor _rows rows (wrapping within the pattern).
tracker_move_rows = function(_rows) {
    cur_row = ((cur_row + _rows) mod TRACKER_ROWS + TRACKER_ROWS) mod TRACKER_ROWS;
};

/// Sets fields of the cell under the cursor (undefined = unchanged).
tracker_set_cell = function(_period, _sample, _fx, _prm) {
    var _index = song.order[cur_pos];
    tracker_push_undo_cells(_index);
    var _cells = song.patterns[_index];
    var _at = scr_tracker_cell_at(cur_row, cur_ch);
    if (_period != undefined) _cells[@ _at] = _period;
    if (_sample != undefined) _cells[@ _at + 1] = _sample;
    if (_fx != undefined) _cells[@ _at + 2] = _fx;
    if (_prm != undefined) _cells[@ _at + 3] = _prm;
};

/// Transposes the notes of the cursor's track by _semitones.
tracker_transpose_track = function(_semitones) {
    var _index = song.order[cur_pos];
    tracker_push_undo_cells(_index);
    var _cells = song.patterns[_index];
    var _table = scr_audio_note_periods();
    var _lost = 0;
    for (var _r = 0; _r < TRACKER_ROWS; _r += 1) {
        var _at = scr_tracker_cell_at(_r, cur_ch);
        var _note = scr_tracker_note_index(_cells[_at]);
        if (_note < 0) continue;
        var _to = _note + _semitones;
        if (_to < 0 || _to > 35) {
            _lost += 1;
            continue;
        }
        _cells[@ _at] = _table[_to];
    }
    if (_lost > 0) tracker_message(string(_lost) + " note(s) would leave C-1..B-3 and were kept as they were.", c_orange);
};

/// Track (cursor channel) and pattern tools: copy, paste, clear.
tracker_tool = function(_id) {
    var _index = song.order[cur_pos];
    var _cells = song.patterns[_index];
    switch (_id) {
        case "trk_copy":
            clip_track = array_create(TRACKER_ROWS * 4, 0);
            for (var _r = 0; _r < TRACKER_ROWS; _r += 1) array_copy(clip_track, _r * 4, _cells, scr_tracker_cell_at(_r, cur_ch), 4);
            tracker_message("Copied track " + string(cur_ch + 1) + ".", c_lime);
            break;
        case "trk_paste":
            if (clip_track == undefined) break;
            tracker_push_undo_cells(_index);
            for (var _r2 = 0; _r2 < TRACKER_ROWS; _r2 += 1) array_copy(_cells, scr_tracker_cell_at(_r2, cur_ch), clip_track, _r2 * 4, 4);
            break;
        case "trk_clear":
            tracker_push_undo_cells(_index);
            for (var _r3 = 0; _r3 < TRACKER_ROWS; _r3 += 1) array_copy(_cells, scr_tracker_cell_at(_r3, cur_ch), [0, 0, 0, 0], 0, 4);
            break;
        case "trk_down12": tracker_transpose_track(-12); break;
        case "trk_down1": tracker_transpose_track(-1); break;
        case "trk_up1": tracker_transpose_track(1); break;
        case "trk_up12": tracker_transpose_track(12); break;
        case "pat_copy":
            clip_pattern = array_create(array_length(_cells), 0);
            array_copy(clip_pattern, 0, _cells, 0, array_length(_cells));
            tracker_message("Copied pattern " + scr_tracker_hex2(_index) + ".", c_lime);
            break;
        case "pat_paste":
            if (clip_pattern == undefined) break;
            tracker_push_undo_cells(_index);
            array_copy(_cells, 0, clip_pattern, 0, array_length(_cells));
            break;
        case "pat_clear":
            tracker_push_undo_cells(_index);
            array_copy(_cells, 0, scr_tracker_pattern_empty(), 0, array_length(_cells));
            break;
    }
};

/// Pressed, or held for a moment (then repeating): for the cursor keys.
key_hold = {};
tracker_kp = function(_key) {
    var _name = string(_key);
    if (keyboard_check_pressed(_key)) {
        key_hold[$ _name] = 0;
        return true;
    }
    if (!keyboard_check(_key)) return false;
    var _t = variable_struct_exists(key_hold, _name) ? key_hold[$ _name] + 1 : 1;
    key_hold[$ _name] = _t;
    return _t > 16 && (_t mod 2) == 0;
};

/// Shared font for the pattern view (Consolas, else Courier New, else the UI font).
if (!variable_global_exists("tracker_font")) global.tracker_font = -1;
if (global.tracker_font == -1) {
    var _paths = ["C:/Windows/Fonts/consola.ttf", "C:/Windows/Fonts/cour.ttf", "C:/Windows/Fonts/lucon.ttf"];
    for (var _p = 0; _p < array_length(_paths) && global.tracker_font == -1; _p += 1) {
        if (!file_exists(_paths[_p])) continue;
        try {
            global.tracker_font = font_add(_paths[_p], 15, true, false, 32, 127);
        } catch (_err) {
            global.tracker_font = -1;
        }
    }
    if (global.tracker_font == -1) global.tracker_font = UI_FONT;
}
if (!variable_global_exists("tracker_last_name")) global.tracker_last_name = "";

scr_audio_preview_stop();
tracker_message("Space: edit on/off or stop. Enter: play pattern, Shift+Enter: play song. Keys Z-M / Q-P play notes. Esc saves and closes.", c_white);
