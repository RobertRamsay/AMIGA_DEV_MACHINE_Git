audio_editor_refresh();

// --- inline rename field -------------------------------------------------
if (rename_active) {
    if (keyboard_string != "") {
        var _typed = keyboard_string;
        keyboard_string = "";
        var _t = 1;
        while (_t <= string_length(_typed)) {
            var _ch = string_char_at(_typed, _t);
            var _code = ord(_ch);
            var _ok = (_code >= 65 && _code <= 90) || (_code >= 97 && _code <= 122) || (_code >= 48 && _code <= 57) || _code == 95;
            if (_ok && string_length(rename_text) < 32) rename_text += _ch;
            _t += 1;
        }
        rename_error = "";
    }
    if (keyboard_check_pressed(vk_backspace) && string_length(rename_text) > 0) {
        rename_text = string_delete(rename_text, string_length(rename_text), 1);
        rename_error = "";
    }
    if (keyboard_check_pressed(vk_enter)) audio_editor_commit_rename();
    if (keyboard_check_pressed(vk_escape)) {
        rename_active = false;
        rename_error = "";
        keyboard_string = "";
    }
} else if (keyboard_check_pressed(vk_escape)) {
    instance_destroy();
    exit;
}

var _press = mouse_check_button_pressed(mb_left);

// --- window dragging -----------------------------------------------------
if (panel_dragging) {
    if (mouse_check_button(mb_left)) {
        panel_x = clamp(mouse_x - panel_drag_dx, 0, room_width - panel_w);
        panel_y = clamp(mouse_y - panel_drag_dy, 0, room_height - panel_h);
    } else {
        panel_dragging = false;
    }
    exit;
}

controls = audio_editor_controls();

// --- buttons -------------------------------------------------------------
var _clicked = "";
if (_press) {
    var _i = 0;
    while (_i < array_length(controls)) {
        var _c = controls[_i];
        if (_c.enabled && point_in_rectangle(mouse_x, mouse_y, _c.x1, _c.y1, _c.x2, _c.y2)) _clicked = _c.id;
        _i += 1;
    }
    if (_clicked == "" && point_in_rectangle(mouse_x, mouse_y, panel_x, panel_y, panel_x + panel_w, panel_y + header_h)) {
        panel_dragging = true;
        panel_drag_dx = mouse_x - panel_x;
        panel_drag_dy = mouse_y - panel_y;
        exit;
    }
    // Clicking anywhere else ends an open rename (committing it).
    if (rename_active && _clicked != "mod_rename" && _clicked != "smp_rename") audio_editor_commit_rename();
}

var _step_size = keyboard_check(vk_shift) ? 10 : 1;
var _sample = audio_editor_sample();

switch (_clicked) {
    case "close":
        instance_destroy();
        exit;

    case "imp_rate_down":
        global.audio_import_period = min(AUDIO_PERIOD_MAX, global.audio_import_period + _step_size);
        break;
    case "imp_rate_up":
        global.audio_import_period = max(AUDIO_PERIOD_MIN, global.audio_import_period - _step_size);
        break;
    case "imp_normalise":
        global.audio_import_normalise = !global.audio_import_normalise;
        break;

    case "mod_import":
        var _mod_path = get_open_filename("ProTracker module|*.mod;mod.*|All files|*.*", "");
        if (_mod_path != "") {
            var _mod_name = scr_audio_import_mod(_mod_path);
            if (_mod_name != "") {
                audio_editor_refresh();
                mod_selected = _mod_name;
                focus_kind = "MOD";
                mod_scroll = max(0, array_length(mod_names) - list_rows);
            }
        }
        mouse_clear(mb_left);
        break;
    case "mod_play":
        if (global.audio_preview_kind == "MOD" && global.audio_preview_name == mod_selected) {
            scr_audio_preview_stop();
        } else {
            scr_audio_preview_mod(scr_asset_find_by_name(mod_selected));
        }
        focus_kind = "MOD";
        break;
    case "mod_rename":
        if (rename_active) audio_editor_commit_rename();
        else audio_editor_begin_rename("MOD");
        focus_kind = "MOD";
        break;
    case "mod_delete":
        if (show_question("Delete the music " + mod_selected + "?\nNodes that play it will stop building.")) {
            scr_audio_delete(mod_selected);
            scr_mark_workspace_dirty();
            scr_set_status_message("Deleted music " + mod_selected, c_yellow);
            mod_selected = "";
            audio_editor_refresh();
        }
        mouse_clear(mb_left);
        break;
    case "mod_export":
        var _export_asset = scr_asset_find_by_name(mod_selected);
        var _export_path = get_save_filename("ProTracker module|*.mod", mod_selected + ".mod");
        if (_export_path != "" && _export_asset != undefined) {
            var _export_bytes = scr_audio_asset_bytes(_export_asset);
            if (_export_bytes != -1) {
                buffer_save(_export_bytes, _export_path);
                buffer_delete(_export_bytes);
                scr_set_status_message("Exported " + mod_selected + " to " + _export_path, c_lime);
            }
        }
        mouse_clear(mb_left);
        break;

    case "smp_import":
        var _smp_path = get_open_filename("Sound samples|*.wav;*.8svx;*.iff;*.raw;*.smp;*.snd;*.sam|All files|*.*", "");
        if (_smp_path != "") {
            var _smp_name = scr_audio_import_sample(_smp_path);
            if (_smp_name != "") {
                audio_editor_refresh();
                smp_selected = _smp_name;
                focus_kind = "SAMPLE";
                sel_start = 0;
                sel_end = 0;
                smp_scroll = max(0, array_length(smp_names) - list_rows);
            }
        }
        mouse_clear(mb_left);
        break;
    case "smp_play":
        if (global.audio_preview_kind == "SAMPLE" && global.audio_preview_name == smp_selected) {
            scr_audio_preview_stop();
        } else {
            scr_audio_preview_sample(scr_asset_find_by_name(smp_selected));
        }
        focus_kind = "SAMPLE";
        break;
    case "smp_rename":
        if (rename_active) audio_editor_commit_rename();
        else audio_editor_begin_rename("SAMPLE");
        focus_kind = "SAMPLE";
        break;
    case "smp_delete":
        if (show_question("Delete the sample " + smp_selected + "?\nNodes that play it will stop building.")) {
            scr_audio_delete(smp_selected);
            scr_mark_workspace_dirty();
            scr_set_status_message("Deleted sample " + smp_selected, c_yellow);
            smp_selected = "";
            audio_editor_refresh();
        }
        mouse_clear(mb_left);
        break;

    // Settings edits change the stored struct in place (no data re-encode).
    case "period_down":
        _sample.period = min(AUDIO_PERIOD_MAX, _sample.period + _step_size);
        scr_mark_workspace_dirty();
        break;
    case "period_up":
        _sample.period = max(AUDIO_PERIOD_MIN, _sample.period - _step_size);
        scr_mark_workspace_dirty();
        break;
    case "note_down":
    case "note_up":
        // Jump to the next ProTracker note period (lower note = longer period).
        var _table = scr_audio_note_periods();
        var _target = _sample.period;
        var _n = 0;
        if (_clicked == "note_down") {
            _target = AUDIO_PERIOD_MAX;
            while (_n < 36) {
                if (_table[_n] > _sample.period) _target = _table[_n];
                _n += 1;
            }
            if (_target <= _sample.period) _target = AUDIO_PERIOD_MAX;
        } else {
            _target = AUDIO_PERIOD_MIN;
            _n = 35;
            while (_n >= 0) {
                if (_table[_n] < _sample.period) _target = _table[_n];
                _n -= 1;
            }
            if (_target >= _sample.period) _target = AUDIO_PERIOD_MIN;
        }
        _sample.period = clamp(_target, AUDIO_PERIOD_MIN, AUDIO_PERIOD_MAX);
        scr_mark_workspace_dirty();
        break;
    case "vol_down":
        _sample.volume = max(0, _sample.volume - _step_size);
        scr_mark_workspace_dirty();
        break;
    case "vol_up":
        _sample.volume = min(64, _sample.volume + _step_size);
        scr_mark_workspace_dirty();
        break;
    case "loop_toggle":
        _sample.loop = !_sample.loop;
        if (_sample.loop && _sample.loop_length < 2) {
            if (sel_end - sel_start >= 2) {
                _sample.loop_start = min(sel_start, sel_end);
                _sample.loop_length = abs(sel_end - sel_start);
            } else {
                _sample.loop_start = 0;
                _sample.loop_length = _sample.length;
            }
        }
        if (!_sample.loop) {
            _sample.loop_start = 0;
            _sample.loop_length = 0;
        }
        scr_mark_workspace_dirty();
        break;
    case "trim":
        scr_audio_preview_stop();
        scr_audio_sample_trim(_sample, sel_start, sel_end);
        sel_start = 0;
        sel_end = 0;
        scr_mark_workspace_dirty();
        break;
    case "normalise":
        scr_audio_sample_normalise(_sample, sel_start, sel_end);
        scr_mark_workspace_dirty();
        break;
    case "reverse":
        scr_audio_sample_reverse(_sample, sel_start, sel_end);
        scr_mark_workspace_dirty();
        break;
    case "fade_in":
        scr_audio_sample_fade(_sample, sel_start, sel_end, true);
        scr_mark_workspace_dirty();
        break;
    case "fade_out":
        scr_audio_sample_fade(_sample, sel_start, sel_end, false);
        scr_mark_workspace_dirty();
        break;
    case "sel_all":
        sel_start = 0;
        sel_end = 0;
        break;
}
if (_clicked != "") exit;

// --- lists: selection and wheel scrolling ---------------------------------
var _list_y = panel_y + 96;
var _list_bottom = _list_y + list_rows * row_h;
var _over_mod_list = point_in_rectangle(mouse_x, mouse_y, panel_x + 12, _list_y, panel_x + 312, _list_bottom);
var _over_smp_list = point_in_rectangle(mouse_x, mouse_y, panel_x + 326, _list_y, panel_x + 626, _list_bottom);
var _wheel = mouse_wheel_down() - mouse_wheel_up();
if (_over_mod_list && _wheel != 0) mod_scroll = clamp(mod_scroll + _wheel, 0, max(0, array_length(mod_names) - list_rows));
if (_over_smp_list && _wheel != 0) smp_scroll = clamp(smp_scroll + _wheel, 0, max(0, array_length(smp_names) - list_rows));
if (_press && _over_mod_list) {
    var _mod_row = mod_scroll + (mouse_y - _list_y) div row_h;
    if (_mod_row < array_length(mod_names)) mod_selected = mod_names[_mod_row];
    focus_kind = "MOD";
    exit;
}
if (_press && _over_smp_list) {
    var _smp_row = smp_scroll + (mouse_y - _list_y) div row_h;
    if (_smp_row < array_length(smp_names) && smp_names[_smp_row] != smp_selected) {
        smp_selected = smp_names[_smp_row];
        sel_start = 0;
        sel_end = 0;
    }
    focus_kind = "SAMPLE";
    exit;
}

// --- waveform: loop handles and selection ----------------------------------
if (focus_kind == "SAMPLE" && _sample != undefined) {
    var _r = audio_editor_wave_rect();
    var _len = max(2, _sample.length);
    if (_press && point_in_rectangle(mouse_x, mouse_y, _r[0] - 6, _r[1], _r[2] + 6, _r[3])) {
        var _loop_x1 = _r[0] + _sample.loop_start / _len * wave_columns;
        var _loop_x2 = _r[0] + (_sample.loop_start + _sample.loop_length) / _len * wave_columns;
        if (_sample.loop && abs(mouse_x - _loop_x1) <= 6 && mouse_y <= _r[1] + 24) {
            drag_mode = "loop_start";
        } else if (_sample.loop && abs(mouse_x - _loop_x2) <= 6 && mouse_y <= _r[1] + 24) {
            drag_mode = "loop_end";
        } else {
            drag_mode = "select";
            sel_start = audio_editor_wave_byte(mouse_x, _sample.length);
            sel_end = sel_start;
        }
        drag_changed = false;
    }
    if (drag_mode != "") {
        var _byte = audio_editor_wave_byte(mouse_x, _sample.length);
        if (drag_mode == "select") {
            sel_end = _byte;
        } else if (drag_mode == "loop_start") {
            var _loop_end = _sample.loop_start + _sample.loop_length;
            var _new_start = clamp(_byte, 0, _loop_end - 2);
            if (_new_start != _sample.loop_start) {
                _sample.loop_start = _new_start;
                _sample.loop_length = _loop_end - _new_start;
                drag_changed = true;
            }
        } else {
            var _new_end = clamp(_byte, _sample.loop_start + 2, _sample.length);
            if (_new_end != _sample.loop_start + _sample.loop_length) {
                _sample.loop_length = _new_end - _sample.loop_start;
                drag_changed = true;
            }
        }
        if (!mouse_check_button(mb_left)) {
            if (drag_changed) scr_mark_workspace_dirty();
            if (drag_mode == "select" && sel_start > sel_end) {
                var _swap = sel_start;
                sel_start = sel_end;
                sel_end = _swap;
            }
            drag_mode = "";
        }
    }
} else {
    drag_mode = "";
}

// --- VU meters fall back smoothly ---------------------------------------------
var _pos = scr_audio_preview_pos();
var _v = 0;
while (_v < 4) {
    var _level = (_pos != undefined && _pos.kind == "MOD") ? _pos.levels[_v] : 0;
    vu_display[_v] = max(_level, vu_display[_v] * 0.85);
    _v += 1;
}
