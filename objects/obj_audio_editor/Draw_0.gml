// Chrome (window, header, list boxes, buttons) uses the house style
// (scr_ui_style); waveform, scopes and VU meters stay square.
draw_set_font(UI_FONT);
draw_set_halign(fa_left);
draw_set_valign(fa_top);

var _col_panel = make_colour_rgb(18, 22, 30);
var _col_header = make_colour_rgb(65, 82, 105);
var _col_button = make_colour_rgb(45, 65, 85);
var _col_button_on = make_colour_rgb(35, 110, 75);
var _col_box = make_colour_rgb(10, 12, 18);
var _col_dim_text = make_colour_rgb(150, 160, 175);
var _col_edge = make_colour_rgb(90, 104, 128);

// Dimmed backdrop over the whole workspace.
draw_set_alpha(0.6);
draw_set_colour(c_black);
draw_rectangle(0, 0, room_width, room_height, false);
draw_set_alpha(0.97);
scr_ui_box_fill(panel_x, panel_y, panel_x + panel_w, panel_y + panel_h, _col_panel);
draw_set_alpha(1);
scr_ui_box_outline(panel_x, panel_y, panel_x + panel_w, panel_y + panel_h, _col_edge);
scr_ui_box_fill(panel_x + 3, panel_y + 3, panel_x + panel_w - 3, panel_y + header_h, _col_header);
draw_set_colour(c_white);
scr_ui_text_mid(panel_x + 16, panel_y + 3, panel_y + header_h, "SOUND & MUSIC");
draw_set_colour(_col_dim_text);
scr_ui_text_mid(panel_x + 200, panel_y + 3, panel_y + header_h, "Grab to drag   Esc closes   Shift+click steps by 10");

// Import settings line (centred between the < > buttons).
draw_set_colour(c_white);
scr_ui_text_centred(panel_x + 162, panel_y + 47, "IMPORT RATE " + string(round(scr_audio_period_rate(global.audio_import_period)))
    + " Hz (" + string(global.audio_import_period) + ")");

// --- the two lists -----------------------------------------------------------
var _list_y = panel_y + 96;
var _lists = [
    ["MUSIC (MOD)", panel_x + 12, mod_names, mod_scroll, mod_selected, "MOD"],
    ["SAMPLES", panel_x + 326, smp_names, smp_scroll, smp_selected, "SAMPLE"]
];
var _l = 0;
while (_l < 2) {
    var _lx = _lists[_l][1];
    var _names = _lists[_l][2];
    var _scroll = _lists[_l][3];
    var _selected = _lists[_l][4];
    var _kind = _lists[_l][5];
    var _lb = _list_y + list_rows * row_h;
    draw_set_colour(focus_kind == _kind ? c_yellow : c_white);
    scr_ui_text_mid(_lx, panel_y + 66, _list_y, _lists[_l][0] + "  (" + string(array_length(_names)) + ")");
    scr_ui_box_fill(_lx, _list_y, _lx + 300, _lb, _col_box);
    var _r = 0;
    while (_r < list_rows && _scroll + _r < array_length(_names)) {
        var _name = _names[_scroll + _r];
        var _ry = _list_y + _r * row_h;
        if (_name == _selected) {
            draw_set_colour(focus_kind == _kind ? _col_button_on : _col_button);
            scr_te_rect_in_bevel(_lx + 1, _ry + 1, _lx + 299, _ry + row_h - 1, _lx, _list_y, _lx + 300, _lb);
        }
        var _shown = _name;
        if (rename_active && rename_kind == _kind && _name == rename_old) {
            _shown = rename_text + ((current_time div 400) mod 2 == 0 ? "_" : "");
            scr_ui_box(_lx + 1, _ry + 1, _lx + 299, _ry + row_h - 1, c_black, c_yellow, false);
        }
        draw_set_colour(global.audio_preview_name == _name ? c_lime : c_white);
        scr_ui_text_mid(_lx + 10, _ry, _ry + row_h, _shown);
        _r += 1;
    }
    if (array_length(_names) > list_rows) {
        var _bar_h = list_rows * row_h * list_rows / array_length(_names);
        var _bar_y = _list_y + (list_rows * row_h - _bar_h) * _scroll / max(1, array_length(_names) - list_rows);
        draw_set_colour(c_gray);
        scr_te_rect_in_bevel(_lx + 294, _bar_y, _lx + 299, _bar_y + _bar_h, _lx, _list_y, _lx + 300, _lb);
    }
    if (array_length(_names) == 0) {
        draw_set_colour(_col_dim_text);
        scr_ui_text_mid(_lx + 10, _list_y, _list_y + row_h + 4, "Nothing yet - press IMPORT");
    }
    scr_ui_box_outline(_lx, _list_y, _lx + 300, _lb, c_gray);
    _l += 1;
}
if (rename_active) {
    draw_set_colour(rename_error == "" ? _col_dim_text : c_red);
    draw_text(panel_x + 12, panel_y + 96 + list_rows * row_h + 106,
        rename_error == "" ? "Type a label name, Enter = OK, Esc = cancel" : rename_error);
}

// --- buttons ---------------------------------------------------------------
var _i = 0;
while (_i < array_length(controls)) {
    var _c = controls[_i];
    var _hover = point_in_rectangle(mouse_x, mouse_y, _c.x1, _c.y1, _c.x2, _c.y2);
    var _fill = (_c.id == "close") ? make_colour_rgb(120, 40, 46) : (_c.on ? _col_button_on : _col_button);
    scr_ui_button(_c.x1, _c.y1, _c.x2, _c.y2, _c.label, _fill, _hover && _c.enabled, _c.enabled);
    _i += 1;
}

// --- details panel -----------------------------------------------------------
var _dx = panel_x + 652;
var _dy = panel_y + 72;
scr_ui_box_outline(panel_x + 640, panel_y + 66, panel_x + panel_w - 12, panel_y + panel_h - 12, _col_edge);
var _pos = scr_audio_preview_pos();

if (focus_kind == "MOD") {
    var _mod = audio_editor_mod();
    if (_mod == undefined) {
        draw_set_colour(_col_dim_text);
        draw_text(_dx, _dy, "Import a 4-channel ProTracker module (M.K. / M!K! / FLT4 / 4CHN).");
        draw_text(_dx, _dy + 24, "The whole file is loaded into chip RAM when the program runs.");
    } else {
        draw_set_colour(c_yellow);
        draw_text(_dx, _dy, _mod.name);
        draw_set_colour(c_white);
        var _kb = _mod.length / 1024;
        var _lines = [
            "TITLE      " + (_mod.title == "" ? "(none)" : _mod.title),
            "FILE       " + _mod.source_name,
            "SIZE       " + string(_mod.length) + " bytes  (" + string_format(_kb, 1, 1) + " KB chip RAM)",
            "POSITIONS  " + string(_mod.positions) + "     PATTERNS " + string(_mod.patterns) + "     SAMPLES " + string(_mod.samples_used)
        ];
        var _ln = 0;
        while (_ln < array_length(_lines)) {
            draw_text(_dx, _dy + 26 + _ln * 22, _lines[_ln]);
            _ln += 1;
        }
        if (_mod.length > 400 * 1024) {
            draw_set_colour(c_orange);
            draw_text(_dx, _dy + 26 + 4 * 22, "Large module: a 512 KB chip RAM Amiga may not fit it with graphics");
        }

        // Sample names in two columns.
        var _sy = _dy + 140;
        draw_set_colour(_col_dim_text);
        draw_text(_dx, _sy, "INSTRUMENTS");
        if (mod_info != undefined && mod_info.ok) {
            var _shown_count = 0;
            var _s = 0;
            while (_s < 31) {
                var _sname = mod_info.sample_names[_s];
                var _slen = mod_info.sample_lengths[_s];
                if (_sname != "" || _slen > 2) {
                    var _col_x = _dx + (_shown_count div 15) * 285;
                    var _row_y = _sy + 24 + (_shown_count mod 15) * 18;
                    if (_shown_count < 30) {
                        draw_set_colour(_slen > 2 ? c_white : _col_dim_text);
                        draw_text(_col_x, _row_y, (_s < 9 ? "0" : "") + string(_s + 1) + " " + string_copy(_sname, 1, 16));
                        draw_set_halign(fa_right);
                        draw_text(_col_x + 270, _row_y, string(_slen));
                        draw_set_halign(fa_left);
                    }
                    _shown_count += 1;
                }
                _s += 1;
            }
            if (_shown_count == 0) {
                draw_set_colour(_col_dim_text);
                draw_text(_dx, _sy + 24, "(no sample names)");
            }
        }

        // Playback position, VU meters and scopes.
        var _py2 = panel_y + panel_h - 190;
        draw_set_colour(c_white);
        if (_pos != undefined && _pos.kind == "MOD" && _pos.name == _mod.name && _pos.position >= 0) {
            draw_text(_dx, _py2, "PLAYING  POSITION " + string(_pos.position) + "/" + string(_mod.positions - 1)
                + "   PATTERN " + string(_pos.pattern) + "   ROW " + string(_pos.row));
        } else {
            draw_set_colour(_col_dim_text);
            draw_text(_dx, _py2, "Press PLAY to preview (GML ProTracker player, A500 filter)");
        }
        var _ch = 0;
        while (_ch < 4) {
            var _bx = _dx + _ch * 142;
            var _by = _py2 + 30;
            draw_set_colour(_col_box);
            draw_rectangle(_bx, _by, _bx + 132, _by + 130, false);
            draw_set_colour(c_gray);
            draw_rectangle(_bx, _by, _bx + 132, _by + 130, true);
            draw_set_colour(_col_dim_text);
            draw_text(_bx + 4, _by + 2, "CH" + string(_ch + 1) + ((_ch == 0 || _ch == 3) ? " L" : " R"));
            // VU bar.
            var _level = clamp(vu_display[_ch] * 1.4, 0, 1);
            draw_set_colour(_level > 0.85 ? c_red : (_level > 0.6 ? c_yellow : c_lime));
            draw_rectangle(_bx + 116, _by + 128 - _level * 104, _bx + 128, _by + 128, false);
            // Scope trace.
            if (_pos != undefined && _pos.kind == "MOD") {
                var _trace = _pos.scopes[_ch];
                draw_set_colour(c_aqua);
                var _t = 1;
                while (_t < array_length(_trace)) {
                    draw_line(_bx + 4 + (_t - 1) * 3.4, _by + 76 - _trace[_t - 1] * 48, _bx + 4 + _t * 3.4, _by + 76 - _trace[_t] * 48);
                    _t += 1;
                }
            } else {
                draw_set_colour(c_dkgray);
                draw_line(_bx + 4, _by + 76, _bx + 110, _by + 76);
            }
            _ch += 1;
        }
    }
} else {
    var _sample = audio_editor_sample();
    if (_sample == undefined) {
        draw_set_colour(_col_dim_text);
        draw_text(_dx, _dy, "Import a WAV, IFF 8SVX or raw signed 8-bit sample.");
        draw_text(_dx, _dy + 24, "WAVs are converted to mono 8-bit at the import rate.");
    } else {
        draw_set_colour(c_yellow);
        draw_text(_dx, _dy, _sample.name);
        draw_set_colour(_col_dim_text);
        draw_text(_dx + 300, _dy, string_copy(_sample.source_name, 1, 30));

        // Waveform.
        var _wr = audio_editor_wave_rect();
        var _len = max(2, _sample.length);
        draw_set_colour(_col_box);
        draw_rectangle(_wr[0], _wr[1], _wr[2], _wr[3], false);
        var _mid = (_wr[1] + _wr[3]) / 2;
        var _scale = (_wr[3] - _wr[1]) / 2 / 128;
        if (sel_end != sel_start) {
            draw_set_colour(make_colour_rgb(40, 55, 90));
            draw_rectangle(_wr[0] + min(sel_start, sel_end) / _len * wave_columns, _wr[1],
                _wr[0] + max(sel_start, sel_end) / _len * wave_columns, _wr[3], false);
        }
        if (_sample.loop) {
            draw_set_colour(make_colour_rgb(30, 70, 45));
            draw_rectangle(_wr[0] + _sample.loop_start / _len * wave_columns, _wr[1] + 24,
                _wr[0] + (_sample.loop_start + _sample.loop_length) / _len * wave_columns, _wr[3], false);
        }
        draw_set_colour(c_dkgray);
        draw_line(_wr[0], _mid, _wr[2], _mid);
        draw_set_colour(c_lime);
        var _mins = wave_minmax[0];
        var _maxs = wave_minmax[1];
        var _w = 0;
        while (_w < array_length(_mins)) {
            draw_line(_wr[0] + _w, _mid - _maxs[_w] * _scale, _wr[0] + _w, _mid - _mins[_w] * _scale + 1);
            _w += 1;
        }
        if (_sample.loop) {
            var _lx1 = _wr[0] + _sample.loop_start / _len * wave_columns;
            var _lx2 = _wr[0] + (_sample.loop_start + _sample.loop_length) / _len * wave_columns;
            draw_set_colour(c_yellow);
            draw_line(_lx1, _wr[1], _lx1, _wr[3]);
            draw_line(_lx2, _wr[1], _lx2, _wr[3]);
            draw_triangle(_lx1, _wr[1], _lx1 + 10, _wr[1], _lx1, _wr[1] + 20, false);
            draw_triangle(_lx2, _wr[1], _lx2 - 10, _wr[1], _lx2, _wr[1] + 20, false);
        }
        if (_pos != undefined && _pos.kind == "SAMPLE" && _pos.name == _sample.name && _pos.byte >= 0) {
            var _hx = _wr[0] + _pos.byte / _len * wave_columns;
            draw_set_colour(c_white);
            draw_line(_hx, _wr[1], _hx, _wr[3]);
        }
        draw_set_colour(c_gray);
        draw_rectangle(_wr[0], _wr[1], _wr[2], _wr[3], true);
        draw_set_colour(_col_dim_text);
        draw_text(_wr[0], _wr[3] + 4, "Drag = select   Drag the yellow flags = loop start / end");
        if (sel_end != sel_start) {
            draw_text(_wr[0], _wr[3] + 24, "SELECTION " + string(min(sel_start, sel_end)) + " - " + string(max(sel_start, sel_end))
                + "  (" + string(abs(sel_end - sel_start)) + " bytes)   edits apply to the selection");
        } else {
            draw_text(_wr[0], _wr[3] + 24, "No selection: edits apply to the whole sample");
        }

        // Settings rows (controls drawn above).
        var _row_y = panel_y + 340;
        draw_set_colour(c_white);
        scr_ui_text_mid(_dx, _row_y, _row_y + 22, "RATE");
        scr_ui_text_centred(_dx + 306, _row_y + 11, string(round(scr_audio_period_rate(_sample.period))) + " Hz  period " + string(_sample.period)
            + "  " + scr_audio_period_note_name(_sample.period));
        scr_ui_text_mid(_dx, _row_y + 30, _row_y + 52, "VOLUME");
        scr_ui_text_centred(_dx + 186, _row_y + 41, string(_sample.volume));
        scr_ui_text_mid(_dx, _row_y + 60, _row_y + 82, "LOOP");
        if (_sample.loop) {
            scr_ui_text_mid(_dx + 264, _row_y + 60, _row_y + 82, string(_sample.loop_start) + " - " + string(_sample.loop_start + _sample.loop_length)
                + "  (" + string(_sample.loop_length) + " b)");
        }

        // Size readout.
        var _size_y = panel_y + panel_h - 110;
        var _seconds = _sample.length / scr_audio_period_rate(_sample.period);
        draw_set_colour(c_white);
        draw_text(_dx, _size_y, "LENGTH  " + string(_sample.length) + " bytes  (" + string(_sample.length div 2) + " words, "
            + string_format(_sample.length / 1024, 1, 1) + " KB chip RAM, " + string_format(_seconds, 1, 2) + " s)");
        if (_sample.length > AUDIO_MAX_SAMPLE_BYTES) {
            draw_set_colour(c_red);
            draw_text(_dx, _size_y + 24, "TOO LONG: Paula plays at most 65535 words (131070 bytes)");
        } else if (_sample.length > 65536) {
            draw_set_colour(c_orange);
            draw_text(_dx, _size_y + 24, "Over 64 KB: fine for Paula (max 131070 bytes) but heavy on chip RAM");
        } else {
            draw_set_colour(_col_dim_text);
            draw_text(_dx, _size_y + 24, "Paula limit 131070 bytes: " + string(AUDIO_MAX_SAMPLE_BYTES - _sample.length) + " bytes to spare");
        }
    }
}

draw_set_colour(c_white);
draw_set_alpha(1);
