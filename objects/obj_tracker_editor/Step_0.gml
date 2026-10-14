// The editor tour is presenting this screen: its input belongs to the tour.
if (instance_exists(obj_editor_tour)) exit;

var _l = tracker_layout();
var _mx = mouse_x;
var _my = mouse_y;
var _press = mouse_check_button_pressed(mb_left);
var _ctrl = keyboard_check(vk_control);
var _shift = keyboard_check(vk_shift);
var _alt = keyboard_check(vk_alt);
var _playing = global.audio_preview_kind == "TRACKER";

// Follow the play position.
if (_playing && follow) {
    var _heard = scr_audio_preview_pos();
    if (_heard != undefined && _heard.row >= 0) {
        if (global.audio_preview_name == "song") cur_pos = clamp(_heard.position, 0, array_length(song.order) - 1);
        cur_row = clamp(_heard.row, 0, TRACKER_ROWS - 1);
    }
}

// ---------------------------------------------------------------------------
// Text fields (song name, title, instrument name).
// ---------------------------------------------------------------------------
if (field_active != "") {
    var _max = (field_active == "title") ? 20 : ((field_active == "inst") ? 22 : 32);
    if (string_length(keyboard_string) > _max) keyboard_string = string_copy(keyboard_string, 1, _max);
    field_text = keyboard_string;
    var _commit = keyboard_check_pressed(vk_enter) || keyboard_check_pressed(vk_tab);
    var _cancel = keyboard_check_pressed(vk_escape);
    // A click anywhere else commits too.
    if (_press) {
        var _fid = "field_" + field_active;
        var _ctls = tracker_controls();
        var _inside = false;
        for (var _f = 0; _f < array_length(_ctls); _f += 1) {
            var _fc = _ctls[_f];
            if (_fc.id == _fid && point_in_rectangle(_mx, _my, _fc.x1, _fc.y1, _fc.x2, _fc.y2)) _inside = true;
        }
        if (!_inside) _commit = true;
    }
    if (_cancel) {
        field_active = "";
        keyboard_string = "";
        exit;
    }
    if (_commit) {
        var _text = string_trim(field_text);
        switch (field_active) {
            case "name":
                if (!scr_audio_name_is_valid(_text)) {
                    tracker_message("Song name: start with a letter, then letters, digits or _ (it becomes an assembler label).", c_red);
                } else {
                    var _other = scr_asset_find_by_name(_text);
                    if (_other != undefined && _other.type != "MOD") {
                        tracker_message("There is already a " + _other.type + " asset called " + _text, c_red);
                    } else {
                        if (_other != undefined && _text != song_name) tracker_message("SAVE will replace the MOD " + _text + ".", c_orange);
                        song_name = _text;
                        dirty = true;
                    }
                }
                break;
            case "title":
                song.title = _text;
                dirty = true;
                break;
            case "inst":
                song.samples[cur_inst - 1].name = _text;
                dirty = true;
                break;
        }
        field_active = "";
        keyboard_string = "";
        if (!_press) exit;
    } else {
        exit;
    }
}

// ---------------------------------------------------------------------------
// Mouse: controls.
// ---------------------------------------------------------------------------
draw_set_font(global.tracker_font);
var _char_w = string_width("0");
var _controls = tracker_controls();
var _hit = undefined;
if (_press) {
    for (var _i = 0; _i < array_length(_controls); _i += 1) {
        var _c = _controls[_i];
        if (_c.enabled && point_in_rectangle(_mx, _my, _c.x1, _c.y1, _c.x2, _c.y2)) {
            _hit = _c;
            break;
        }
    }
}
if (_hit != undefined) {
    var _is_value = variable_struct_exists(_hit, "kind") && _hit.kind == "value";
    var _dir = (_mx < (_hit.x1 + _hit.x2) / 2) ? -1 : 1;
    var _step = _shift ? 10 : 1;
    var _smp = song.samples[cur_inst - 1];
    switch (_hit.id) {
        case "close":
            if (tracker_save()) instance_destroy();
            exit;
        case "field_name":
            field_active = "name";
            keyboard_string = song_name;
            field_text = song_name;
            break;
        case "field_title":
            field_active = "title";
            keyboard_string = song.title;
            field_text = song.title;
            break;
        case "field_inst":
            field_active = "inst";
            keyboard_string = _smp.name;
            field_text = _smp.name;
            break;
        case "new":
            if (dirty) tracker_save();
            scr_audio_preview_stop();
            song = scr_tracker_song_new();
            song_name = scr_audio_unique_name("song");
            cur_pos = 0;
            cur_row = 0;
            undo_stack = [];
            redo_stack = [];
            dirty = true;
            tracker_message("New song " + song_name + " with lead, bass, pad, kick, snare and hi-hat instruments.", c_lime);
            break;
        case "save":
            tracker_save();
            break;
        case "build":
            if (tracker_save()) scr_amiga_trigger_build();
            break;
        case "open_prev":
        case "open_next":
            var _mods = scr_audio_list("MOD");
            open_index = (open_index + (_hit.id == "open_next" ? 1 : -1) + array_length(_mods)) mod array_length(_mods);
            break;
        case "open":
            var _mods2 = scr_audio_list("MOD");
            open_index = clamp(open_index, 0, array_length(_mods2) - 1);
            if (dirty && _mods2[open_index] != song_name) tracker_save();
            tracker_load(_mods2[open_index]);
            break;
        case "ord_ins":
            tracker_push_undo_order();
            array_insert(song.order, cur_pos + 1, song.order[cur_pos]);
            cur_pos += 1;
            break;
        case "ord_del":
            tracker_push_undo_order();
            array_delete(song.order, cur_pos, 1);
            cur_pos = clamp(cur_pos, 0, array_length(song.order) - 1);
            song.restart = clamp(song.restart, 0, array_length(song.order) - 1);
            break;
        case "ord_new":
        case "ord_clone":
            tracker_push_undo_order();
            var _fresh = scr_tracker_pattern_empty();
            if (_hit.id == "ord_clone") array_copy(_fresh, 0, tracker_pattern(), 0, array_length(_fresh));
            array_push(song.patterns, _fresh);
            array_insert(song.order, cur_pos + 1, array_length(song.patterns) - 1);
            cur_pos += 1;
            tracker_message((_hit.id == "ord_clone" ? "Copied pattern to " : "New pattern ") + scr_tracker_hex2(array_length(song.patterns) - 1) + " at position " + string(cur_pos) + ".", c_lime);
            break;
        case "ord_pat":
            tracker_push_undo_order();
            var _to = song.order[cur_pos] + _dir;
            if (_to >= array_length(song.patterns) && _to < TRACKER_MAX_PATTERNS) array_push(song.patterns, scr_tracker_pattern_empty());
            song.order[cur_pos] = clamp(_to, 0, array_length(song.patterns) - 1);
            break;
        case "inst_vol":
            _smp.volume = clamp(_smp.volume + _dir * _step, 0, 64);
            dirty = true;
            break;
        case "inst_fine":
            _smp.finetune = clamp(_smp.finetune + _dir, -8, 7);
            dirty = true;
            break;
        case "inst_loop":
            if (_smp.loop_length >= 2) {
                _smp.loop_start = 0;
                _smp.loop_length = 0;
            } else {
                _smp.loop_start = 0;
                _smp.loop_length = scr_tracker_sample_bytes(_smp);
            }
            dirty = true;
            break;
        case "inst_play":
            scr_tracker_jam(song, cur_inst, 428);
            break;
        case "inst_clear":
            song.samples[cur_inst - 1] = scr_tracker_sample_empty();
            dirty = true;
            break;
        case "inst_save":
            var _n = scr_tracker_sample_bytes(_smp);
            var _buf = buffer_create(_n, buffer_fixed, 1);
            for (var _b = 0; _b < _n; _b += 1) buffer_write(_buf, buffer_s8, clamp(round(_smp.data[_b]), -128, 127));
            var _base = scr_audio_label_from_text(_smp.name, "instrument");
            var _sname = scr_audio_unique_name(_base);
            scr_audio_define_sample(_sname, scr_audio_buffer_b64(_buf, _n), _n, 428, _smp.volume, _smp.loop_length >= 2,
                _smp.loop_start, _smp.loop_length, "TRACKER " + song_name);
            buffer_delete(_buf);
            scr_mark_workspace_dirty();
            tracker_message("Saved instrument " + scr_tracker_hex2(cur_inst) + " as SAMPLE " + _sname + " (PLAY SFX can use it).", c_lime);
            break;
        case "smp_prev":
        case "smp_next":
            var _samples = scr_audio_list("SAMPLE");
            sample_index = (sample_index + (_hit.id == "smp_next" ? 1 : -1) + array_length(_samples)) mod array_length(_samples);
            break;
        case "smp_use":
            var _samples2 = scr_audio_list("SAMPLE");
            sample_index = clamp(sample_index, 0, array_length(_samples2) - 1);
            song.samples[cur_inst - 1] = scr_tracker_sample_from_asset(scr_asset_find_by_name(_samples2[sample_index]));
            dirty = true;
            tracker_message("Instrument " + scr_tracker_hex2(cur_inst) + " = SAMPLE " + _samples2[sample_index] + ".", c_lime);
            break;
        case "play_song":
            scr_tracker_play(song, cur_pos, false, mute);
            break;
        case "play_pattern":
            scr_tracker_play(song, cur_pos, true, mute);
            break;
        case "stop":
            scr_audio_preview_stop();
            break;
        case "edit":
            edit_mode = !edit_mode;
            break;
        case "follow":
            follow = !follow;
            break;
        case "inst_sel":
            cur_inst = clamp(cur_inst + _dir * _step, 1, 31);
            break;
        case "octave":
            octave = clamp(octave + _dir, 1, 2);
            break;
        case "step":
            edit_step = clamp(edit_step + _dir, 0, 16);
            break;
        case "speed":
            tracker_set_start_value(false, tracker_start_value(false) + _dir);
            break;
        case "bpm":
            tracker_set_start_value(true, tracker_start_value(true) + _dir * (_shift ? 10 : 1));
            break;
        case "undo":
            tracker_undo_step(false);
            break;
        case "redo":
            tracker_undo_step(true);
            break;
        default:
            if (string_copy(_hit.id, 1, 6) == "synth_") {
                var _kind = string_delete(_hit.id, 1, 6);
                song.samples[cur_inst - 1] = scr_tracker_synth(_kind);
                dirty = true;
                scr_tracker_jam(song, cur_inst, 428);
                tracker_message("Instrument " + scr_tracker_hex2(cur_inst) + " = " + _kind + " (drums sound right at C-2).", c_lime);
            } else if (string_copy(_hit.id, 1, 4) == "mute") {
                var _mc = real(string_delete(_hit.id, 1, 4));
                mute[_mc] = !mute[_mc];
            } else if (string_copy(_hit.id, 1, 4) == "trk_" || string_copy(_hit.id, 1, 4) == "pat_") {
                tracker_tool(_hit.id);
            }
            break;
    }
    exit;
}

// ---------------------------------------------------------------------------
// Mouse: lists and the pattern grid.
// ---------------------------------------------------------------------------
var _wheel = mouse_wheel_down() - mouse_wheel_up();
var _list_x1 = _l.order[0] + 8;
var _list_y1 = _l.order[1] + 36;
var _over_order = point_in_rectangle(_mx, _my, _list_x1, _list_y1, _l.order[2] - 8, _list_y1 + _l.order_rows * _l.list_row_h - 1);
if (_over_order) {
    order_scroll = clamp(order_scroll + _wheel, 0, max(0, array_length(song.order) - _l.order_rows));
    if (_press) {
        var _op = order_scroll + floor((_my - _list_y1) / _l.list_row_h);
        if (_op < array_length(song.order)) cur_pos = _op;
    }
}
var _inst_y1 = _l.insts[1] + 36;
var _over_insts = point_in_rectangle(_mx, _my, _l.insts[0] + 8, _inst_y1, _l.insts[2] - 8, _inst_y1 + _l.inst_rows * _l.list_row_h - 1);
if (_over_insts) {
    inst_scroll = clamp(inst_scroll + _wheel * 2, 0, 31 - _l.inst_rows);
    if (_press) cur_inst = clamp(inst_scroll + 1 + floor((_my - _inst_y1) / _l.list_row_h), 1, 31);
}
var _over_grid = point_in_rectangle(_mx, _my, _l.pattern[0], _l.rows_y, _l.pattern[2], _l.rows_y + _l.visible_rows * _l.row_h - 1);
if (_over_grid) {
    if (_wheel != 0 && !(_playing && follow)) tracker_move_rows(_wheel * 2);
    if (_press) {
        var _first = cur_row - (_l.visible_rows div 2);
        var _r = _first + floor((_my - _l.rows_y) / _l.row_h);
        var _ch = floor((_mx - _l.pattern[0] - _l.rownum_w) / _l.chan_w);
        if (_r >= 0 && _r < TRACKER_ROWS && _ch >= 0 && _ch < 4) {
            cur_row = _r;
            cur_ch = _ch;
            // Column from the character under the mouse in "C-2 01 C20".
            var _char = floor((_mx - (tracker_chan_x(_l, _ch) + 16)) / _char_w);
            var _cols = [0, 0, 0, 0, 1, 2, 2, 3, 4, 5];
            cur_col = _cols[clamp(_char, 0, 9)];
        }
    }
}

// Order list follows the cursor.
if (cur_pos < order_scroll) order_scroll = cur_pos;
if (cur_pos >= order_scroll + _l.order_rows) order_scroll = cur_pos - _l.order_rows + 1;
if (cur_inst - 1 < inst_scroll) inst_scroll = cur_inst - 1;
if (cur_inst - 1 >= inst_scroll + _l.inst_rows) inst_scroll = cur_inst - _l.inst_rows;

// ---------------------------------------------------------------------------
// Keyboard.
// ---------------------------------------------------------------------------
if (keyboard_check_pressed(vk_escape)) {
    if (tracker_save()) instance_destroy();
    exit;
}
if (keyboard_check_pressed(vk_f5)) {
    if (tracker_save()) scr_amiga_trigger_build();
    exit;
}
if (_ctrl) {
    if (keyboard_check_pressed(ord("Z"))) tracker_undo_step(false);
    if (keyboard_check_pressed(ord("Y"))) tracker_undo_step(true);
    if (keyboard_check_pressed(ord("S"))) tracker_save();
    if (keyboard_check_pressed(ord("C"))) tracker_tool(_shift ? "pat_copy" : "trk_copy");
    if (keyboard_check_pressed(ord("V"))) tracker_tool(_shift ? "pat_paste" : "trk_paste");
    if (keyboard_check_pressed(ord("X"))) {
        tracker_tool(_shift ? "pat_copy" : "trk_copy");
        tracker_tool(_shift ? "pat_clear" : "trk_clear");
    }
    if (keyboard_check_pressed(vk_up)) tracker_transpose_track(_shift ? 12 : 1);
    if (keyboard_check_pressed(vk_down)) tracker_transpose_track(_shift ? -12 : -1);
    exit;
}

if (keyboard_check_pressed(vk_space)) {
    if (_playing) scr_audio_preview_stop();
    else edit_mode = !edit_mode;
}
if (keyboard_check_pressed(vk_enter)) scr_tracker_play(song, cur_pos, !_shift, mute);

// Cursor movement (held keys repeat).
if (tracker_kp(vk_up)) tracker_move_rows(-1);
if (tracker_kp(vk_down)) tracker_move_rows(1);
if (tracker_kp(vk_pageup)) cur_row = max(0, cur_row - 16);
if (tracker_kp(vk_pagedown)) cur_row = min(TRACKER_ROWS - 1, cur_row + 16);
if (keyboard_check_pressed(vk_home)) cur_row = 0;
if (keyboard_check_pressed(vk_end)) cur_row = TRACKER_ROWS - 1;
if (!_alt && tracker_kp(vk_left)) {
    cur_col -= 1;
    if (cur_col < 0) {
        cur_col = 5;
        cur_ch = (cur_ch + 3) mod 4;
    }
}
if (!_alt && tracker_kp(vk_right)) {
    cur_col += 1;
    if (cur_col > 5) {
        cur_col = 0;
        cur_ch = (cur_ch + 1) mod 4;
    }
}
if (keyboard_check_pressed(vk_tab)) {
    cur_ch = (cur_ch + (_shift ? 3 : 1)) mod 4;
    cur_col = 0;
}
// Position in the song: Alt+Left / Right also works.
if (keyboard_check_pressed(vk_add)) cur_inst = min(31, cur_inst + 1);
if (keyboard_check_pressed(vk_subtract)) cur_inst = max(1, cur_inst - 1);
if (keyboard_check_pressed(vk_divide)) octave = 1;
if (keyboard_check_pressed(vk_multiply)) octave = 2;
if (_alt && keyboard_check_pressed(vk_left)) cur_pos = max(0, cur_pos - 1);
if (_alt && keyboard_check_pressed(vk_right)) cur_pos = min(array_length(song.order) - 1, cur_pos + 1);

// Delete / Backspace / Insert.
var _cells = tracker_pattern();
if (keyboard_check_pressed(vk_delete) && edit_mode) {
    if (_shift) tracker_set_cell(0, 0, 0, 0);
    else if (cur_col == 0) tracker_set_cell(0, 0, undefined, undefined);
    else if (cur_col <= 2) tracker_set_cell(undefined, 0, undefined, undefined);
    else tracker_set_cell(undefined, undefined, 0, 0);
    tracker_move_rows(edit_step);
}
if ((keyboard_check_pressed(vk_backspace) || keyboard_check_pressed(vk_insert)) && edit_mode) {
    // Backspace pulls the track up into the row above; Insert pushes it down.
    var _index = song.order[cur_pos];
    tracker_push_undo_cells(_index);
    var _ins = keyboard_check_pressed(vk_insert);
    var _from_row = _ins ? cur_row : max(0, cur_row - 1);
    var _chs = _shift ? [0, 1, 2, 3] : [cur_ch];
    for (var _k = 0; _k < array_length(_chs); _k += 1) {
        var _cc = _chs[_k];
        if (_ins) {
            for (var _r2 = TRACKER_ROWS - 1; _r2 > _from_row; _r2 -= 1) {
                array_copy(_cells, scr_tracker_cell_at(_r2, _cc), _cells, scr_tracker_cell_at(_r2 - 1, _cc), 4);
            }
            array_copy(_cells, scr_tracker_cell_at(_from_row, _cc), [0, 0, 0, 0], 0, 4);
        } else {
            for (var _r3 = _from_row; _r3 < TRACKER_ROWS - 1; _r3 += 1) {
                array_copy(_cells, scr_tracker_cell_at(_r3, _cc), _cells, scr_tracker_cell_at(_r3 + 1, _cc), 4);
            }
            array_copy(_cells, scr_tracker_cell_at(TRACKER_ROWS - 1, _cc), [0, 0, 0, 0], 0, 4);
        }
    }
    if (!_ins) cur_row = _from_row;
}

if (_alt) exit;

// Note keys (ProTracker layout): Z S X D C V G B H N J M , L . ; / = lower
// octave, Q 2 W 3 E R 5 T 6 Y 7 U I 9 O 0 P = upper. Hex digits in the
// instrument and effect columns.
if (cur_col == 0) {
    var _note_keys = [
        [ord("Z"), 0], [ord("S"), 1], [ord("X"), 2], [ord("D"), 3], [ord("C"), 4], [ord("V"), 5], [ord("G"), 6],
        [ord("B"), 7], [ord("H"), 8], [ord("N"), 9], [ord("J"), 10], [ord("M"), 11],
        [188, 12], [ord("L"), 13], [190, 14], [186, 15], [191, 16],
        [ord("Q"), 12], [ord("2"), 13], [ord("W"), 14], [ord("3"), 15], [ord("E"), 16], [ord("R"), 17], [ord("5"), 18],
        [ord("T"), 19], [ord("6"), 20], [ord("Y"), 21], [ord("7"), 22], [ord("U"), 23],
        [ord("I"), 24], [ord("9"), 25], [ord("O"), 26], [ord("0"), 27], [ord("P"), 28]
    ];
    for (var _n = 0; _n < array_length(_note_keys); _n += 1) {
        if (!keyboard_check_pressed(_note_keys[_n][0])) continue;
        var _note = (octave - 1) * 12 + _note_keys[_n][1];
        if (_note > 35) {
            tracker_message("That note is above B-3, the top of the ProTracker range.", c_orange);
            break;
        }
        var _periods = scr_audio_note_periods();
        var _period = _periods[_note];
        if (!_playing) scr_tracker_jam(song, cur_inst, _period);
        if (edit_mode) {
            tracker_set_cell(_period, cur_inst, undefined, undefined);
            tracker_move_rows(edit_step);
        }
        break;
    }
} else if (edit_mode) {
    var _digit = -1;
    for (var _d = 0; _d < 10; _d += 1) {
        if (keyboard_check_pressed(ord(string(_d))) || keyboard_check_pressed(vk_numpad0 + _d)) _digit = _d;
    }
    for (var _h = 0; _h < 6; _h += 1) {
        if (keyboard_check_pressed(ord("A") + _h)) _digit = 10 + _h;
    }
    if (_digit >= 0) {
        var _at = scr_tracker_cell_at(cur_row, cur_ch);
        switch (cur_col) {
            case 1:
                tracker_set_cell(undefined, clamp((_digit & 1) * 16 + (_cells[_at + 1] & 15), 0, 31), undefined, undefined);
                break;
            case 2:
                tracker_set_cell(undefined, clamp((_cells[_at + 1] & 16) + _digit, 0, 31), undefined, undefined);
                break;
            case 3:
                tracker_set_cell(undefined, undefined, _digit, undefined);
                break;
            case 4:
                tracker_set_cell(undefined, undefined, undefined, (_digit << 4) | (_cells[_at + 3] & 15));
                break;
            case 5:
                tracker_set_cell(undefined, undefined, undefined, (_cells[_at + 3] & 240) | _digit);
                break;
        }
        tracker_move_rows(edit_step);
    }
}
