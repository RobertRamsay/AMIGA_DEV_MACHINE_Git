// Chrome uses the house style (scr_ui_style); the pattern grid, lists,
// waveform and scopes are data and stay square.
draw_set_font(UI_FONT);
draw_set_halign(fa_left);
draw_set_valign(fa_top);

var _l = tracker_layout();
var _col_panel = make_colour_rgb(16, 19, 27);
var _col_header = make_colour_rgb(30, 92, 96);
var _col_button = make_colour_rgb(45, 65, 85);
var _col_on = make_colour_rgb(35, 110, 75);
var _col_box = make_colour_rgb(8, 10, 15);
var _col_dim = make_colour_rgb(150, 160, 175);
var _col_edge = make_colour_rgb(90, 104, 128);
var _playing = global.audio_preview_kind == "TRACKER";
var _heard = _playing ? scr_audio_preview_pos() : undefined;

// Backdrop and window.
draw_set_alpha(0.75);
draw_set_colour(c_black);
draw_rectangle(0, 0, room_width, room_height, false);
draw_set_alpha(0.98);
scr_ui_box_fill(_l.x1, _l.y1, _l.x2, _l.y2, _col_panel);
draw_set_alpha(1);
scr_ui_box_outline(_l.x1, _l.y1, _l.x2, _l.y2, _col_edge);
scr_ui_box_fill(_l.x1 + 3, _l.y1 + 3, _l.x2 - 3, _l.y1 + _l.header_h, _col_header);
draw_set_colour(c_white);
scr_ui_text_mid(_l.x1 + 16, _l.y1 + 3, _l.y1 + _l.header_h, "TRACKER - " + song_name + (dirty ? " *" : ""));
draw_set_colour(_col_dim);
scr_ui_text_mid(_l.x1 + 420, _l.y1 + 3, _l.y1 + _l.header_h,
    "4 channels, 31 instruments, ProTracker M.K.   Esc saves and closes   F5 saves and runs   F11 window");

// Section boxes with titles.
var _sections = [
    [_l.song, "SONG"], [_l.order, "ORDER"], [_l.insts, "INSTRUMENTS"], [_l.inst, "INSTRUMENT " + scr_tracker_hex2(cur_inst)]
];
for (var _s = 0; _s < array_length(_sections); _s += 1) {
    var _r = _sections[_s][0];
    scr_ui_box(_r[0], _r[1], _r[2], _r[3], make_colour_rgb(22, 27, 38), make_colour_rgb(60, 72, 92));
    draw_set_colour(c_yellow);
    scr_ui_text_mid(_r[0] + 12, _r[1] + 4, _r[1] + 28, _sections[_s][1]);
}

// SONG panel labels and details.
var _sx = _l.song[0];
var _sy = _l.song[1];
draw_set_colour(_col_dim);
scr_ui_text_mid(_sx + 12, _sy + 36, _sy + 60, "NAME");
scr_ui_text_mid(_sx + 12, _sy + 66, _sy + 90, "TITLE");
var _mods = scr_audio_list("MOD");
var _open_name = array_length(_mods) > 0 ? _mods[clamp(open_index, 0, array_length(_mods) - 1)] : "(no MOD assets)";
scr_ui_box(_sx + 40, _sy + 134, _sx + 266, _sy + 158, _col_box, c_gray);
draw_set_colour(c_white);
scr_ui_text_mid(_sx + 48, _sy + 134, _sy + 158, scr_ui_fit_label(_open_name, 214));
var _bytes = AUDIO_MOD_HEADER_SIZE + array_length(song.patterns) * AUDIO_MOD_PATTERN_SIZE;
var _used = 0;
for (var _i = 0; _i < 31; _i += 1) {
    var _n = scr_tracker_sample_bytes(song.samples[_i]);
    _bytes += _n;
    if (_n > 2) _used += 1;
}
draw_set_colour(_col_dim);
scr_ui_text_mid(_sx + 12, _sy + 168, _sy + 190, "Positions " + string(array_length(song.order)) + "   Patterns " + string(array_length(song.patterns))
    + "   Instruments " + string(_used));
scr_ui_text_mid(_sx + 12, _sy + 192, _sy + 214, "Size " + string(_bytes) + " bytes (" + string_format(_bytes / 1024, 1, 1) + " KB of chip RAM)");
scr_ui_text_mid(_sx + 12, _sy + 216, _sy + 238, "SAVE, then pick it in a PLAY MUSIC node.");
draw_set_colour(message_colour);
// At most four lines, so a long message never runs into the transport bar.
var _msg = message;
while (string_height_ext(_msg, 18, _l.song[2] - _sx - 24) > 72 && string_length(_msg) > 4) _msg = string_copy(_msg, 1, string_length(_msg) - 5) + "..";
draw_text_ext(_sx + 12, _sy + 240, _msg, 18, _l.song[2] - _sx - 24);

// ORDER list.
var _ox = _l.order[0] + 8;
var _oy = _l.order[1] + 36;
var _ox2 = _l.order[2] - 8;
var _oy2 = _oy + _l.order_rows * _l.list_row_h;
scr_ui_box_fill(_ox, _oy, _ox2, _oy2, _col_box);
for (var _o = 0; _o < _l.order_rows; _o += 1) {
    var _op = order_scroll + _o;
    if (_op >= array_length(song.order)) break;
    var _ry = _oy + _o * _l.list_row_h;
    if (_op == cur_pos) {
        draw_set_colour(_col_on);
        scr_te_rect_in_bevel(_ox + 1, _ry + 1, _ox2 - 1, _ry + _l.list_row_h - 1, _ox, _oy, _ox2, _oy2);
    }
    var _is_heard = _heard != undefined && global.audio_preview_name == "song" && _heard.position == _op;
    draw_set_colour(_is_heard ? c_lime : c_white);
    scr_ui_text_mid(_ox + 10, _ry, _ry + _l.list_row_h, "POS " + string_replace_all(string_format(_op, 3, 0), " ", "0")
        + "   PAT " + scr_tracker_hex2(song.order[_op]) + ((_op == song.restart && array_length(song.order) > 1) ? "  <" : ""));
}
scr_ui_box_outline(_ox, _oy, _ox2, _oy2, c_gray);

// INSTRUMENTS list.
var _ix = _l.insts[0] + 8;
var _iy = _l.insts[1] + 36;
var _ix2 = _l.insts[2] - 8;
var _iy2 = _iy + _l.inst_rows * _l.list_row_h;
scr_ui_box_fill(_ix, _iy, _ix2, _iy2, _col_box);
for (var _k = 0; _k < _l.inst_rows; _k += 1) {
    var _slot = inst_scroll + _k;
    if (_slot >= 31) break;
    var _smp = song.samples[_slot];
    var _ky = _iy + _k * _l.list_row_h;
    if (_slot + 1 == cur_inst) {
        draw_set_colour(_col_on);
        scr_te_rect_in_bevel(_ix + 1, _ky + 1, _ix2 - 1, _ky + _l.list_row_h - 1, _ix, _iy, _ix2, _iy2);
    }
    draw_set_colour(_smp.length > 0 ? c_white : _col_dim);
    scr_ui_text_mid(_ix + 8, _ky, _ky + _l.list_row_h, scr_tracker_hex2(_slot + 1));
    scr_ui_text_mid(_ix + 44, _ky, _ky + _l.list_row_h, scr_ui_fit_label(_smp.name == "" ? (_smp.length > 0 ? "(unnamed)" : "") : _smp.name, 200));
    if (_smp.length > 0) {
        draw_set_colour(_col_dim);
        scr_ui_text_mid(_ix + 258, _ky, _ky + _l.list_row_h, string(_smp.length) + (_smp.loop_length >= 2 ? " L" : ""));
        scr_ui_text_mid(_ix + 350, _ky, _ky + _l.list_row_h, "v" + string(_smp.volume));
    }
}
scr_ui_box_outline(_ix, _iy, _ix2, _iy2, c_gray);
draw_set_colour(_col_dim);
scr_ui_text_mid(_ix, _iy2 + 4, _iy2 + 24, "Numpad + / - picks the instrument for new notes.");

// INSTRUMENT detail: name label, waveform, synth and sample rows.
var _cur = song.samples[cur_inst - 1];
var _dx = _l.inst[0];
var _dy = _l.inst[1];
draw_set_colour(_col_dim);
scr_ui_text_mid(_dx + 12, _dy + 36, _dy + 60, "NAME");
scr_ui_text_mid(_dx + 12, _dy + 132, _dy + 156, "SYNTH (replaces this instrument):");
scr_ui_text_mid(_dx + 12, _dy + 228, _dy + 252, "FROM SAMPLE");
var _samples = scr_audio_list("SAMPLE");
var _smp_name = array_length(_samples) > 0 ? _samples[clamp(sample_index, 0, array_length(_samples) - 1)] : "(import WAV / IFF in SND-EDIT)";
scr_ui_box(_dx + 188, _dy + 228, _dx + 466, _dy + 252, _col_box, c_gray);
draw_set_colour(c_white);
scr_ui_text_mid(_dx + 196, _dy + 228, _dy + 252, scr_ui_fit_label(_smp_name, 262));
var _w = _l.wave;
draw_set_colour(_col_box);
draw_rectangle(_w[0], _w[1], _w[2], _w[3], false);
draw_set_colour(make_colour_rgb(40, 48, 62));
draw_line(_w[0], (_w[1] + _w[3]) / 2, _w[2], (_w[1] + _w[3]) / 2);
if (_cur.length > 1) {
    var _ww = _w[2] - _w[0];
    var _mid = (_w[1] + _w[3]) / 2;
    var _amp = (_w[3] - _w[1]) / 2 - 2;
    if (_cur.loop_length >= 2) {
        draw_set_colour(make_colour_rgb(30, 70, 50));
        draw_rectangle(_w[0] + _ww * _cur.loop_start / _cur.length, _w[1] + 1, _w[0] + _ww * (_cur.loop_start + _cur.loop_length) / _cur.length, _w[3] - 1, false);
    }
    draw_set_colour(c_aqua);
    var _prev_value = _cur.data[0];
    for (var _x = 0; _x < _ww; _x += 1) {
        var _a = floor(_x * _cur.length / _ww);
        var _b = max(_a + 1, floor((_x + 1) * _cur.length / _ww));
        // Start from the previous column's last value so edges are joined.
        var _lo = _prev_value;
        var _hi = _prev_value;
        _prev_value = _cur.data[min(_b, _cur.length) - 1];
        for (var _j = _a; _j < _b && _j < _cur.length; _j += 1) {
            _lo = min(_lo, _cur.data[_j]);
            _hi = max(_hi, _cur.data[_j]);
        }
        draw_line(_w[0] + _x, _mid - _hi / 128 * _amp, _w[0] + _x, _mid - _lo / 128 * _amp + 1);
    }
} else {
    draw_set_colour(_col_dim);
    scr_ui_text_centred((_w[0] + _w[2]) / 2, (_w[1] + _w[3]) / 2, "empty - pick a SYNTH or a SAMPLE");
}
draw_set_colour(c_gray);
draw_rectangle(_w[0], _w[1], _w[2], _w[3], true);

// ---------------------------------------------------------------------------
// Pattern view.
// ---------------------------------------------------------------------------
var _p = _l.pattern;
var _pattern_index = song.order[cur_pos];
var _cells = song.patterns[_pattern_index];
draw_set_colour(_col_box);
draw_rectangle(_p[0], _p[1], _p[2], _p[3], false);

// Channel headers: name, mute (a control), scope and level.
var _levels = (_heard != undefined) ? _heard.levels : [0, 0, 0, 0];
var _scopes = (_heard != undefined) ? _heard.scopes : [[], [], [], []];
for (var _ch = 0; _ch < 4; _ch += 1) {
    var _cx = tracker_chan_x(_l, _ch);
    draw_set_colour(make_colour_rgb(24, 30, 42));
    draw_rectangle(_cx + 2, _p[1] + 2, _cx + _l.chan_w - 2, _p[1] + _l.chan_header_h, false);
    draw_set_colour(_ch == cur_ch ? c_yellow : c_white);
    scr_ui_text_mid(_cx + 12, _p[1] + 2, _p[1] + _l.chan_header_h, "CHANNEL " + string(_ch + 1) + ((_ch == 0 || _ch == 3) ? " L" : " R"));
    // Scope.
    var _sx1 = _cx + 244;
    var _sx2 = _cx + _l.chan_w - 40;
    var _smid = _p[1] + 2 + _l.chan_header_h / 2;
    draw_set_colour(make_colour_rgb(12, 16, 22));
    draw_rectangle(_sx1, _p[1] + 4, _sx2, _p[1] + _l.chan_header_h - 2, false);
    var _trace = _scopes[_ch];
    if (is_array(_trace) && array_length(_trace) > 1 && !mute[_ch]) {
        draw_set_colour(c_lime);
        var _tn = array_length(_trace);
        for (var _t = 1; _t < _tn; _t += 1) {
            draw_line(_sx1 + (_sx2 - _sx1) * (_t - 1) / (_tn - 1), _smid - _trace[_t - 1] * 12,
                _sx1 + (_sx2 - _sx1) * _t / (_tn - 1), _smid - _trace[_t] * 12);
        }
    }
    // Level meter (falls back slowly).
    vu_display[_ch] = max(_levels[_ch], vu_display[_ch] * 0.85);
    var _vh = (_l.chan_header_h - 6) * clamp(vu_display[_ch] * 2, 0, 1);
    draw_set_colour(vu_display[_ch] > 0.4 ? c_red : c_yellow);
    draw_rectangle(_sx2 + 10, _p[1] + _l.chan_header_h - 2 - _vh, _sx2 + 24, _p[1] + _l.chan_header_h - 2, false);
}

// Rows: the cursor row stays in the middle (ProTracker style).
draw_set_font(global.tracker_font);
var _char_w = string_width("0");
var _first = cur_row - (_l.visible_rows div 2);
var _heard_row = (_heard != undefined && _heard.pattern == _pattern_index) ? _heard.row : -1;
for (var _v = 0; _v < _l.visible_rows; _v += 1) {
    var _row = _first + _v;
    if (_row < 0 || _row >= TRACKER_ROWS) continue;
    var _y = _l.rows_y + _v * _l.row_h;
    // Beat bands every 4 rows, the cursor row, the row being heard.
    if (_row == cur_row) {
        draw_set_colour(edit_mode ? make_colour_rgb(70, 30, 30) : make_colour_rgb(40, 50, 75));
        draw_rectangle(_p[0] + 2, _y, _p[2] - 2, _y + _l.row_h - 1, false);
    } else if (_row == _heard_row) {
        draw_set_colour(make_colour_rgb(25, 60, 35));
        draw_rectangle(_p[0] + 2, _y, _p[2] - 2, _y + _l.row_h - 1, false);
    } else if ((_row mod 4) == 0) {
        draw_set_colour(make_colour_rgb(20, 24, 34));
        draw_rectangle(_p[0] + 2, _y, _p[2] - 2, _y + _l.row_h - 1, false);
    }
    draw_set_colour(((_row mod 16) == 0) ? c_yellow : (((_row mod 4) == 0) ? c_white : _col_dim));
    draw_text(_p[0] + 14, _y + 1, string_replace_all(string_format(_row, 2, 0), " ", "0"));
    for (var _ch2 = 0; _ch2 < 4; _ch2 += 1) {
        var _at = scr_tracker_cell_at(_row, _ch2);
        var _period = _cells[_at];
        var _smp_no = _cells[_at + 1];
        var _fx = _cells[_at + 2];
        var _prm = _cells[_at + 3];
        var _tx = tracker_chan_x(_l, _ch2) + 16;
        if (_row == cur_row && _ch2 == cur_ch) {
            // The cursor: one column of "C-2 01 C20".
            var _starts = [0, 4, 5, 7, 8, 9];
            var _widths = [3, 1, 1, 1, 1, 1];
            draw_set_colour(edit_mode ? c_red : c_aqua);
            draw_rectangle(_tx + _starts[cur_col] * _char_w - 1, _y, _tx + (_starts[cur_col] + _widths[cur_col]) * _char_w, _y + _l.row_h - 1, true);
        }
        var _muted = mute[_ch2];
        draw_set_colour(_period > 0 ? (_muted ? _col_dim : c_white) : make_colour_rgb(70, 78, 92));
        draw_text(_tx, _y + 1, scr_tracker_note_text(_period));
        draw_set_colour(_smp_no > 0 ? (_muted ? _col_dim : make_colour_rgb(120, 200, 255)) : make_colour_rgb(70, 78, 92));
        draw_text(_tx + 4 * _char_w, _y + 1, _smp_no > 0 ? scr_tracker_hex2(_smp_no) : "..");
        var _has_fx = _fx != 0 || _prm != 0;
        draw_set_colour(_has_fx ? (_muted ? _col_dim : make_colour_rgb(255, 180, 90)) : make_colour_rgb(70, 78, 92));
        draw_text(_tx + 7 * _char_w, _y + 1, _has_fx ? scr_tracker_hex1(_fx) + scr_tracker_hex2(_prm) : "...");
    }
}
// Channel separators.
draw_set_colour(make_colour_rgb(50, 60, 78));
for (var _sep = 0; _sep <= 4; _sep += 1) {
    var _lx = tracker_chan_x(_l, _sep);
    draw_line(_lx, _p[1], _lx, _p[3]);
}
draw_set_colour(c_gray);
draw_rectangle(_p[0], _p[1], _p[2], _p[3], true);

// Controls (after the pattern view, so the MUTE buttons sit on the channel headers).
draw_set_font(UI_FONT);
var _controls = tracker_controls();
for (var _c = 0; _c < array_length(_controls); _c += 1) {
    var _ctl = _controls[_c];
    var _hover = point_in_rectangle(mouse_x, mouse_y, _ctl.x1, _ctl.y1, _ctl.x2, _ctl.y2);
    var _kind = variable_struct_exists(_ctl, "kind") ? _ctl.kind : "";
    if (_kind == "field") {
        var _text = "";
        if (_ctl.id == "field_name") _text = song_name;
        if (_ctl.id == "field_title") _text = song.title;
        if (_ctl.id == "field_inst") _text = _cur.name;
        if (_ctl.on) _text = field_text + ((current_time div 400) mod 2 == 0 ? "_" : "");
        scr_ui_box(_ctl.x1, _ctl.y1, _ctl.x2, _ctl.y2, _ctl.on ? c_black : _col_box, _ctl.on ? c_yellow : (_hover ? c_white : c_gray));
        draw_set_colour(c_white);
        scr_ui_text_mid(_ctl.x1 + 8, _ctl.y1, _ctl.y2, scr_ui_fit_label(_text, _ctl.x2 - _ctl.x1 - 16));
        continue;
    }
    scr_ui_button(_ctl.x1, _ctl.y1, _ctl.x2, _ctl.y2, _ctl.label, _ctl.on ? _col_on : _col_button, _hover && _ctl.enabled, _ctl.enabled);
    if (_kind == "value") {
        draw_set_colour(make_colour_rgb(190, 205, 225));
        scr_ui_text_centred(_ctl.x1 + 9, (_ctl.y1 + _ctl.y2) / 2, "<");
        scr_ui_text_centred(_ctl.x2 - 8, (_ctl.y1 + _ctl.y2) / 2, ">");
    }
}

// Footer: what the cell under the cursor does, and the keys.
draw_set_font(UI_FONT);
var _cat = scr_tracker_cell_at(cur_row, cur_ch);
var _help = scr_tracker_effect_help(_cells[_cat + 2], _cells[_cat + 3]);
draw_set_colour(c_white);
scr_ui_text_mid(_p[0] + 4, _p[3] + 4, _p[3] + 22, "POS " + string(cur_pos) + "  PATTERN " + scr_tracker_hex2(_pattern_index) + "  ROW " + string(cur_row)
    + "  CHANNEL " + string(cur_ch + 1) + (_help != "" ? "   " + _help : ""));
draw_set_colour(_col_dim);
scr_ui_text_mid(_p[0] + 4, _p[3] + 20, _p[3] + 40, scr_ui_fit_label(
    "Notes Z-M / Q-P (Numpad / * octave)   Hex in other columns   Del clear (Shift: cell)   Ins / Bksp push / pull"
    + "   Ctrl+C/V/X track (Shift: pattern)   Ctrl+Up/Down transpose   Alt+Left/Right position   Ctrl+Z/Y undo", _p[2] - _p[0] - 8));
