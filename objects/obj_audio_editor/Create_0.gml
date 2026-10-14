/// @description SOUND & MUSIC window: MOD and SAMPLE assets
// Modal window drawn over a dimmed backdrop. The window lays out every
// clickable control in one list (audio_editor_controls) that both the Step
// (hit testing) and Draw events use, so they can never disagree.
depth = -400000;

panel_w = 1240;
panel_h = 760;
panel_x = (room_width - panel_w) div 2;
panel_y = (room_height - panel_h) div 2;
header_h = 28;
panel_dragging = false;
panel_drag_dx = 0;
panel_drag_dy = 0;

row_h = 22;
list_rows = 14;
mod_scroll = 0;
smp_scroll = 0;
mod_names = [];
smp_names = [];
mod_selected = "";
smp_selected = "";
focus_kind = "MOD";                 // which details panel is shown

rename_active = false;
rename_kind = "";
rename_old = "";
rename_text = "";
rename_error = "";

// Sample waveform cache, keyed by the asset struct itself: every data edit
// stores a new struct, so a changed reference means the cache is stale.
wave_ref = undefined;
wave_values = [];
wave_minmax = [[], []];
wave_columns = 560;
sel_start = 0;
sel_end = 0;
drag_mode = "";                     // "", "select", "loop_start", "loop_end"
drag_changed = false;

// MOD header details cache.
mod_info_ref = undefined;
mod_info = undefined;

vu_display = [0, 0, 0, 0];
controls = [];

/// Rebuilds the two name lists and keeps the selections valid.
audio_editor_refresh = function() {
    mod_names = scr_audio_list("MOD");
    smp_names = scr_audio_list("SAMPLE");
    if (!array_contains(mod_names, mod_selected)) mod_selected = array_length(mod_names) > 0 ? mod_names[0] : "";
    if (!array_contains(smp_names, smp_selected)) {
        smp_selected = array_length(smp_names) > 0 ? smp_names[0] : "";
        sel_start = 0;
        sel_end = 0;
    }
    mod_scroll = clamp(mod_scroll, 0, max(0, array_length(mod_names) - list_rows));
    smp_scroll = clamp(smp_scroll, 0, max(0, array_length(smp_names) - list_rows));
};

/// The selected sample asset (or undefined), refreshing the waveform cache.
audio_editor_sample = function() {
    if (smp_selected == "") return undefined;
    var _asset = scr_asset_find_by_name(smp_selected);
    if (_asset == undefined || _asset.type != "SAMPLE") return undefined;
    if (_asset != wave_ref) {
        wave_ref = _asset;
        wave_values = scr_audio_sample_values(_asset);
        wave_minmax = scr_audio_sample_minmax(wave_values, wave_columns);
        sel_start = clamp(sel_start, 0, _asset.length);
        sel_end = clamp(sel_end, 0, _asset.length);
    }
    return _asset;
};

/// The selected MOD asset (or undefined), refreshing the header cache.
audio_editor_mod = function() {
    if (mod_selected == "") return undefined;
    var _asset = scr_asset_find_by_name(mod_selected);
    if (_asset == undefined || _asset.type != "MOD") return undefined;
    if (_asset != mod_info_ref) {
        mod_info_ref = _asset;
        var _bytes = scr_audio_asset_bytes(_asset);
        mod_info = (_bytes == -1) ? undefined : scr_audio_mod_info(_bytes);
        if (_bytes != -1) buffer_delete(_bytes);
    }
    return _asset;
};

/// Waveform rectangle (room coordinates).
audio_editor_wave_rect = function() {
    var _x = panel_x + 652;
    var _y = panel_y + 92;
    return [_x, _y, _x + wave_columns, _y + 200];
};

/// Every clickable control: { id, x1, y1, x2, y2, label, on, enabled }.
audio_editor_controls = function() {
    var _list = [];
    var _px = panel_x;
    var _py = panel_y;
    var _playing_mod = global.audio_preview_kind == "MOD" && global.audio_preview_name == mod_selected && mod_selected != "";
    var _playing_smp = global.audio_preview_kind == "SAMPLE" && global.audio_preview_name == smp_selected && smp_selected != "";
    var _has_mod = mod_selected != "";
    var _has_smp = smp_selected != "";

    array_push(_list, { id : "close", x1 : _px + panel_w - 26, y1 : _py + 4, x2 : _px + panel_w - 6, y2 : _py + 24, label : "X", on : false, enabled : true });

    // Import settings.
    var _rate = round(scr_audio_period_rate(global.audio_import_period));
    array_push(_list, { id : "imp_rate_down", x1 : _px + 12, y1 : _py + 36, x2 : _px + 34, y2 : _py + 58, label : "<", on : false, enabled : true });
    array_push(_list, { id : "imp_rate_up", x1 : _px + 290, y1 : _py + 36, x2 : _px + 312, y2 : _py + 58, label : ">", on : false, enabled : true });
    array_push(_list, { id : "imp_normalise", x1 : _px + 324, y1 : _py + 36, x2 : _px + 520, y2 : _py + 58,
        label : "NORMALISE WAV " + (global.audio_import_normalise ? "ON" : "OFF"), on : global.audio_import_normalise, enabled : true });

    // MUSIC list buttons.
    var _bx = _px + 12;
    var _by = _py + 96 + list_rows * row_h + 8;
    array_push(_list, { id : "mod_import", x1 : _bx, y1 : _by, x2 : _bx + 96, y2 : _by + 26, label : "IMPORT", on : false, enabled : true });
    array_push(_list, { id : "mod_play", x1 : _bx + 102, y1 : _by, x2 : _bx + 198, y2 : _by + 26, label : _playing_mod ? "STOP" : "PLAY", on : _playing_mod, enabled : _has_mod });
    array_push(_list, { id : "mod_rename", x1 : _bx + 204, y1 : _by, x2 : _bx + 300, y2 : _by + 26, label : "RENAME", on : rename_active && rename_kind == "MOD", enabled : _has_mod });
    array_push(_list, { id : "mod_delete", x1 : _bx, y1 : _by + 32, x2 : _bx + 96, y2 : _by + 58, label : "DELETE", on : false, enabled : _has_mod });
    array_push(_list, { id : "mod_export", x1 : _bx + 102, y1 : _by + 32, x2 : _bx + 300, y2 : _by + 58, label : "EXPORT .MOD", on : false, enabled : _has_mod });

    // SAMPLES list buttons.
    _bx = _px + 326;
    array_push(_list, { id : "smp_import", x1 : _bx, y1 : _by, x2 : _bx + 96, y2 : _by + 26, label : "IMPORT", on : false, enabled : true });
    array_push(_list, { id : "smp_play", x1 : _bx + 102, y1 : _by, x2 : _bx + 198, y2 : _by + 26, label : _playing_smp ? "STOP" : "PLAY", on : _playing_smp, enabled : _has_smp });
    array_push(_list, { id : "smp_rename", x1 : _bx + 204, y1 : _by, x2 : _bx + 300, y2 : _by + 26, label : "RENAME", on : rename_active && rename_kind == "SAMPLE", enabled : _has_smp });
    array_push(_list, { id : "smp_delete", x1 : _bx, y1 : _by + 32, x2 : _bx + 96, y2 : _by + 58, label : "DELETE", on : false, enabled : _has_smp });

    // SAMPLE details controls.
    if (focus_kind == "SAMPLE" && _has_smp) {
        var _dx = _px + 652;
        var _dy = _py + 340;
        array_push(_list, { id : "period_down", x1 : _dx + 120, y1 : _dy, x2 : _dx + 142, y2 : _dy + 22, label : "<", on : false, enabled : true });
        array_push(_list, { id : "period_up", x1 : _dx + 470, y1 : _dy, x2 : _dx + 492, y2 : _dy + 22, label : ">", on : false, enabled : true });
        array_push(_list, { id : "note_down", x1 : _dx + 500, y1 : _dy, x2 : _dx + 528, y2 : _dy + 22, label : "<<", on : false, enabled : true });
        array_push(_list, { id : "note_up", x1 : _dx + 532, y1 : _dy, x2 : _dx + 560, y2 : _dy + 22, label : ">>", on : false, enabled : true });
        _dy += 30;
        array_push(_list, { id : "vol_down", x1 : _dx + 120, y1 : _dy, x2 : _dx + 142, y2 : _dy + 22, label : "<", on : false, enabled : true });
        array_push(_list, { id : "vol_up", x1 : _dx + 230, y1 : _dy, x2 : _dx + 252, y2 : _dy + 22, label : ">", on : false, enabled : true });
        _dy += 30;
        var _sample = scr_asset_find_by_name(smp_selected);
        var _looping = _sample != undefined && _sample.loop;
        array_push(_list, { id : "loop_toggle", x1 : _dx + 120, y1 : _dy, x2 : _dx + 252, y2 : _dy + 22, label : "LOOP " + (_looping ? "ON" : "OFF"), on : _looping, enabled : true });
        _dy += 44;
        var _ops = [["trim", "TRIM"], ["normalise", "NORMALISE"], ["reverse", "REVERSE"], ["fade_in", "FADE IN"], ["fade_out", "FADE OUT"]];
        var _i = 0;
        while (_i < array_length(_ops)) {
            var _ox = _dx + _i * 113;
            array_push(_list, { id : _ops[_i][0], x1 : _ox, y1 : _dy, x2 : _ox + 107, y2 : _dy + 26, label : _ops[_i][1], on : false,
                enabled : _ops[_i][0] != "trim" || sel_end != sel_start });
            _i += 1;
        }
        array_push(_list, { id : "sel_all", x1 : _dx, y1 : _dy + 32, x2 : _dx + 220, y2 : _dy + 58, label : "CLEAR SELECTION", on : false, enabled : sel_end != sel_start });
    }
    return _list;
};

/// Starts renaming the selected asset of _kind.
audio_editor_begin_rename = function(_kind) {
    var _name = (_kind == "MOD") ? mod_selected : smp_selected;
    if (_name == "") return;
    rename_active = true;
    rename_kind = _kind;
    rename_old = _name;
    rename_text = _name;
    rename_error = "";
    keyboard_string = "";
};

/// Applies the rename; keeps the field open with an error when invalid.
audio_editor_commit_rename = function() {
    var _error = scr_audio_rename(rename_old, rename_text);
    if (_error != "") {
        rename_error = _error;
        return;
    }
    if (rename_old != rename_text) {
        if (rename_kind == "MOD") mod_selected = rename_text;
        else smp_selected = rename_text;
        scr_mark_workspace_dirty();
        scr_set_status_message("Renamed " + rename_old + " to " + rename_text, c_lime);
    }
    rename_active = false;
    rename_error = "";
    keyboard_string = "";
    audio_editor_refresh();
};

/// Byte offset in the selected sample under room x (snapped to even).
audio_editor_wave_byte = function(_mx, _length) {
    var _r = audio_editor_wave_rect();
    var _byte = round((clamp(_mx, _r[0], _r[2]) - _r[0]) / wave_columns * _length);
    return clamp(_byte - (_byte mod 2), 0, _length);
};

audio_editor_refresh();
focus_kind = (array_length(mod_names) == 0 && array_length(smp_names) > 0) ? "SAMPLE" : "MOD";
