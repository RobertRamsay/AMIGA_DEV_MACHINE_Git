// obj_code_editor Draw - room coordinates (room 1920x1080, no views).
// Chrome (panel, bars, buttons, fields, popups) uses the house style
// (scr_ui_style); the code area, gutter, highlights and scrollbars stay square.

draw_set_font(UI_FONT);
draw_set_halign(fa_left);
draw_set_valign(fa_top);

// ---- backdrop and panel ----
draw_set_alpha(0.78);
draw_set_colour(c_black);
draw_rectangle(0, 0, room_width, room_height, false);
draw_set_alpha(1);

scr_ui_box(panel_x1, panel_y1, panel_x2, panel_y2, col_bg, col_panel_edge);

// ---- title bar ----
draw_set_font(UI_FONT);
scr_ui_box_fill(panel_x1 + 3, title_y1 + 3, panel_x2 - 3, title_y2, make_colour_rgb(26, 34, 58));
draw_set_colour(c_white);
scr_ui_text_mid(panel_x1 + 16, title_y1 + 3, title_y2, editor_title + (is_dirty ? "  *" : ""));
draw_set_colour(make_colour_rgb(120, 135, 170));
var _hint_x = panel_x1 + 36 + string_width(editor_title + "  *  ");
var _hint = "Esc / Ctrl+Enter close   F5 build   Ctrl+Space complete   F12 definition   F8 next problem"
    + (font_is_mono ? "" : "   (no monospace font found)");
var _hint_max = ((array_length(buttons) > 0) ? buttons[0].x1 : panel_x2) - 16 - _hint_x;
if (string_width(_hint) > _hint_max) {
    while (string_length(_hint) > 3 && string_width(_hint + "...") > _hint_max) _hint = string_copy(_hint, 1, string_length(_hint) - 1);
    _hint += "...";
}
scr_ui_text_mid(_hint_x, title_y1 + 3, title_y2, _hint);

// ---- toolbar ----
draw_set_colour(make_colour_rgb(150, 165, 200));
scr_ui_text_mid(panel_x1 + 16, toolbar_y1, toolbar_y2, "INSERT:");

var _bi = 0;
while (_bi < array_length(buttons)) {
    var _b = buttons[_bi];
    var _hover = mouse_x >= _b.x1 && mouse_x < _b.x2 && mouse_y >= _b.y1 && mouse_y < _b.y2;
    var _fill = _b.active ? make_colour_rgb(70, 110, 170) : make_colour_rgb(38, 48, 78);
    if (_b.id == "close") _fill = make_colour_rgb(110, 42, 48);
    if (_b.id == "build") _fill = make_colour_rgb(35, 95, 58);
    scr_ui_button(_b.x1, _b.y1, _b.x2, _b.y2, _b.label, _fill, _hover);
    _bi += 1;
}

// ---- find / goto bar ----
var _draw_field = function(_rect, _text, _focused) {
    scr_ui_box(_rect[0], _rect[1], _rect[2], _rect[3], _focused ? make_colour_rgb(20, 28, 48) : make_colour_rgb(16, 20, 34),
        _focused ? make_colour_rgb(120, 170, 255) : make_colour_rgb(70, 85, 120));
    draw_set_font(code_font);
    var _maxc = max(1, floor((_rect[2] - _rect[0] - 20) / char_w));
    var _shown = (string_length(_text) > _maxc) ? string_copy(_text, string_length(_text) - _maxc + 1, _maxc) : _text;
    // Code glyphs sit high in line_h (room for descenders): nudge them down to look centred.
    var _ty = _rect[1] + ((_rect[3] - _rect[1]) - line_h) * 0.5 + 1 + round(line_h * 0.12);
    if (_focused && field_fresh && _shown != "") {
        draw_set_colour(col_selection);
        draw_rectangle(_rect[0] + 9, _ty, _rect[0] + 10 + string_length(_shown) * char_w, _ty + line_h - 2, false);
    }
    draw_set_colour(c_white);
    ed_draw_code(_rect[0] + 10, _ty, _shown);
    if (_focused && (blink_timer div 30) mod 2 == 0) {
        var _cx = _rect[0] + 10 + string_length(_shown) * char_w;
        draw_rectangle(_cx, _ty, _cx + 1, _ty + line_h - 2, false);
    }
    draw_set_font(UI_FONT);
};

if (find_open || goto_open) {
    draw_set_font(UI_FONT);
    draw_set_colour(make_colour_rgb(150, 165, 200));
    if (goto_open) {
        scr_ui_text_mid(panel_x1 + 16, findbar_y1, findbar_y2, "GO TO LINE:");
        _draw_field(goto_field_rect, goto_text, focus == "goto");
    } else {
        scr_ui_text_mid(panel_x1 + 16, findbar_y1, findbar_y2, "FIND:");
        _draw_field(find_field_rect, find_text, focus == "find");
        if (replace_open) {
            draw_set_colour(make_colour_rgb(150, 165, 200));
            scr_ui_text_mid(replace_field_rect[0] - string_width("REPLACE:") - 8, findbar_y1, findbar_y2, "REPLACE:");
            _draw_field(replace_field_rect, replace_text, focus == "replace");
        }
        var _match_label = (find_text == "") ? "" : string(array_length(find_matches)) + " match" + ((array_length(find_matches) == 1) ? "" : "es");
        if (array_length(buttons) > 0) {
            var _lastb = buttons[array_length(buttons) - 1];
            draw_set_colour((array_length(find_matches) == 0 && find_text != "") ? col_error : make_colour_rgb(150, 165, 200));
            scr_ui_text_mid(_lastb.x2 + 12, findbar_y1, findbar_y2, _match_label);
        }
    }
}

// ---- code area ----
var _n = array_length(lines);
var _first = scroll_line;
var _last = min(_n - 1, scroll_line + vis_lines);

draw_set_colour(col_gutter_bg);
draw_rectangle(gutter_x, text_top, gutter_x + gutter_w, text_bottom, false);
draw_set_colour(make_colour_rgb(10, 13, 22));
draw_rectangle(text_x - 6, text_top, text_right, text_bottom, false);

var _prev_scissor = gpu_get_scissor();
gpu_set_scissor(gutter_x, text_top, text_right - gutter_x, text_bottom - text_top);

draw_set_font(code_font);

var _has_sel = ed_has_sel();
var _sel = ed_sel_range();
var _vis_end_col = scroll_col + vis_cols + 1;

// bracket match on the caret line
var _br_a = -1;
var _br_b = -1;
var _cl_text = lines[caret_line];
var _cl_len = string_length(_cl_text);
var _bc = -1;
if (caret_col < _cl_len && (string_char_at(_cl_text, caret_col + 1) == "(" || string_char_at(_cl_text, caret_col + 1) == ")")) {
    _bc = caret_col;
} else if (caret_col > 0 && (string_char_at(_cl_text, caret_col) == "(" || string_char_at(_cl_text, caret_col) == ")")) {
    _bc = caret_col - 1;
}
if (_bc >= 0) {
    var _bch = string_char_at(_cl_text, _bc + 1);
    var _bdir = (_bch == "(") ? 1 : -1;
    var _bdepth = 0;
    var _bp = _bc;
    while (_bp >= 0 && _bp < _cl_len) {
        var _pc = string_char_at(_cl_text, _bp + 1);
        if (_pc == "(") _bdepth += 1;
        if (_pc == ")") _bdepth -= 1;
        if (_bdepth == 0) {
            _br_a = _bc;
            _br_b = _bp;
            break;
        }
        _bp += _bdir;
    }
    if (_br_a == -1) _br_a = _bc; // unmatched: highlight it alone
}

var _l = _first;
while (_l <= _last) {
    var _y = text_top + (_l - scroll_line) * line_h;
    var _s = lines[_l];
    var _len = string_length(_s);

    // current line
    if (_l == caret_line && !_has_sel) {
        draw_set_colour(col_current_line);
        draw_rectangle(text_x - 6, _y, text_right, _y + line_h - 1, false);
    }

    // selection
    if (_has_sel && _l >= _sel[0] && _l <= _sel[2]) {
        var _sc1 = (_l == _sel[0]) ? _sel[1] : 0;
        var _sc2 = (_l == _sel[2]) ? _sel[3] : _len + 1;
        var _sx1 = text_x + (_sc1 - scroll_col) * char_w;
        var _sx2 = text_x + (_sc2 - scroll_col) * char_w;
        if (_sx2 > _sx1) {
            draw_set_colour(col_selection);
            draw_rectangle(max(text_x - 2, _sx1), _y, _sx2, _y + line_h - 1, false);
        }
    }

    // find matches
    if (find_open && find_text != "") {
        var _fm = find_by_line[$ string(_l)];
        if (_fm != undefined) {
            var _fl = string_length(find_text);
            var _fi = 0;
            while (_fi < array_length(_fm)) {
                var _fx = text_x + (_fm[_fi] - scroll_col) * char_w;
                draw_set_alpha(0.55);
                draw_set_colour(col_find);
                draw_rectangle(_fx, _y, _fx + _fl * char_w, _y + line_h - 1, false);
                draw_set_alpha(1);
                draw_set_colour(make_colour_rgb(200, 170, 60));
                draw_rectangle(_fx, _y, _fx + _fl * char_w, _y + line_h - 1, true);
                _fi += 1;
            }
        }
    }

    // bracket highlight
    if (_l == caret_line && _br_a >= 0) {
        draw_set_colour((_br_b >= 0) ? make_colour_rgb(170, 170, 210) : col_error);
        var _bx1 = text_x + (_br_a - scroll_col) * char_w;
        draw_rectangle(_bx1, _y, _bx1 + char_w, _y + line_h - 1, true);
        if (_br_b >= 0) {
            var _bx2 = text_x + (_br_b - scroll_col) * char_w;
            draw_rectangle(_bx2, _y, _bx2 + char_w, _y + line_h - 1, true);
        }
    }

    // tokens
    if (_len > 0) {
        var _tk = scr_asm_tokenize_line(_s);
        var _ti = 0;
        var _tn = array_length(_tk);
        while (_ti < _tn) {
            var _t = _tk[_ti];
            _ti += 1;
            if (_t.kind == "whitespace") continue;
            var _ts = _t.start_col;
            var _te = _ts + string_length(_t.text);
            if (_te <= scroll_col) continue;
            if (_ts >= _vis_end_col) break;
            var _from = max(_ts, scroll_col);
            var _to = min(_te, _vis_end_col);
            var _piece = (_from == _ts && _to == _te) ? _t.text : string_copy(_t.text, _from - _ts + 1, _to - _from);
            draw_set_colour(ed_token_colour(_t));
            ed_draw_code(text_x + (_from - scroll_col) * char_w, _y + 1, _piece);
        }
    }

    // diagnostics underline
    var _dl = diag_by_line[$ string(_l)];
    if (_dl != undefined) {
        var _di = 0;
        while (_di < array_length(_dl)) {
            var _d = _dl[_di];
            var _dx1 = text_x + (_d.col - scroll_col) * char_w;
            var _dx2 = text_x + (_d.col + _d.len - scroll_col) * char_w;
            if (_dx2 > text_x && _dx1 < text_right) {
                var _dcol = (_d.severity == "error") ? col_error : col_warning;
                if (variable_struct_exists(_d, "build")) {
                    draw_set_colour(_dcol);
                    draw_line(max(_dx1, text_x), _y + line_h - 2, min(_dx2, text_right), _y + line_h - 2);
                } else {
                    ed_draw_wave(max(_dx1, text_x), min(_dx2, text_right), _y + line_h - 3, _dcol);
                }
            }
            _di += 1;
        }
    }

    // gutter
    var _num = string(_l + 1);
    draw_set_colour((_l == caret_line) ? make_colour_rgb(210, 220, 245) : make_colour_rgb(85, 98, 130));
    ed_draw_code(gutter_x + gutter_w - 6 - string_length(_num) * char_w, _y + 1, _num);
    if (_dl != undefined) {
        var _worst = col_warning;
        var _wi = 0;
        while (_wi < array_length(_dl)) {
            if (_dl[_wi].severity == "error") _worst = col_error;
            _wi += 1;
        }
        draw_set_colour(_worst);
        draw_rectangle(gutter_x + 3, _y + 3, gutter_x + 8, _y + line_h - 4, false);
    }

    _l += 1;
}

// caret
if (focus == "text" && (blink_timer div 30) mod 2 == 0 && caret_line >= _first && caret_line <= _last) {
    var _cx = text_x + (caret_col - scroll_col) * char_w;
    if (_cx >= text_x - 1 && _cx <= text_right) {
        var _cy = text_top + (caret_line - scroll_line) * line_h;
        draw_set_colour(c_white);
        draw_rectangle(_cx - 1, _cy, _cx, _cy + line_h - 1, false);
    }
}

gpu_set_scissor(_prev_scissor);

// gutter separator
draw_set_colour(make_colour_rgb(40, 50, 75));
draw_line(gutter_x + gutter_w, text_top, gutter_x + gutter_w, text_bottom);

// ---- scrollbars ----
var _vm = ed_vbar_metrics();
draw_set_colour(make_colour_rgb(20, 26, 42));
draw_rectangle(vbar_x1, text_top, vbar_x2, text_bottom, false);
draw_set_colour(vbar_drag ? make_colour_rgb(120, 140, 200) : make_colour_rgb(70, 85, 125));
draw_rectangle(vbar_x1 + 2, _vm[0], vbar_x2 - 2, _vm[0] + _vm[1], false);

// diagnostic ticks on the vertical track
if (_n > 0) {
    var _dti = 0;
    var _track_h = text_bottom - text_top;
    while (_dti < array_length(diag_all)) {
        var _dd = diag_all[_dti];
        var _ty2 = text_top + _track_h * (_dd.line / max(1, _n));
        draw_set_colour((_dd.severity == "error") ? col_error : col_warning);
        draw_rectangle(vbar_x1, _ty2, vbar_x1 + 3, _ty2 + 2, false);
        _dti += 1;
    }
}

var _hm = ed_hbar_metrics();
draw_set_colour(make_colour_rgb(20, 26, 42));
draw_rectangle(text_x, hbar_y1, text_right, hbar_y2, false);
if (_hm[3] > 0) {
    draw_set_colour(hbar_drag ? make_colour_rgb(120, 140, 200) : make_colour_rgb(70, 85, 125));
    draw_rectangle(_hm[0], hbar_y1 + 2, _hm[0] + _hm[1], hbar_y2 - 2, false);
}

// ---- status bar ----
draw_set_font(UI_FONT);
scr_ui_box(panel_x1 + 3, status_y1, panel_x2 - 3, panel_y2 - 3, make_colour_rgb(20, 26, 44), make_colour_rgb(50, 62, 95));

var _prev_scissor2 = gpu_get_scissor();
gpu_set_scissor(panel_x1 + 8, status_y1, panel_x2 - panel_x1 - 16 - scr_ui_bevel(panel_x2 - panel_x1, panel_y2 - status_y1), panel_y2 - status_y1);

// line 1: diagnostic on the caret line, or the latest note / status message
var _msg = "";
var _msg_col = c_white;
var _cdl = diag_by_line[$ string(caret_line)];
if (_cdl != undefined && array_length(_cdl) > 0) {
    var _cd = _cdl[0];
    _msg = ((_cd.severity == "error") ? "ERROR: " : "WARNING: ") + _cd.message;
    _msg_col = (_cd.severity == "error") ? col_error : col_warning;
    if (array_length(_cdl) > 1) _msg += "   (+" + string(array_length(_cdl) - 1) + " more on this line)";
} else if (status_note != "" && current_time - status_note_time < 5000) {
    _msg = status_note;
    _msg_col = status_note_colour;
} else if (variable_global_exists("status_message_log") && is_array(global.status_message_log) && array_length(global.status_message_log) > 0) {
    var _entry = global.status_message_log[array_length(global.status_message_log) - 1];
    if (is_struct(_entry)) {
        _msg = string(_entry.text);
        _msg_col = (variable_struct_exists(_entry, "colour") && _entry.colour != undefined) ? _entry.colour : c_yellow;
    }
}
draw_set_colour(_msg_col);
draw_text(panel_x1 + 14, status_y1 + 6, _msg);

// line 2: position, counts and opcode help
var _counts = string(diag_error_count) + " error" + ((diag_error_count == 1) ? "" : "s") + ", "
    + string(diag_warning_count) + " warning" + ((diag_warning_count == 1) ? "" : "s");
var _pos_text = "Ln " + string(caret_line + 1) + ", Col " + string(caret_col + 1) + "   |   " + string(_n) + " lines   |   ";
var _y2 = status_y1 + ui_h + 10;
draw_set_colour(make_colour_rgb(170, 180, 205));
draw_text(panel_x1 + 14, _y2, _pos_text);
var _cx2 = panel_x1 + 14 + string_width(_pos_text);
draw_set_colour((diag_error_count > 0) ? col_error : ((diag_warning_count > 0) ? col_warning : make_colour_rgb(120, 220, 120)));
draw_text(_cx2, _y2, _counts);
_cx2 += string_width(_counts);

var _help = "";
var _ctk = scr_asm_tokenize_line(lines[caret_line]);
var _ck = 0;
while (_ck < array_length(_ctk)) {
    var _ct = _ctk[_ck];
    if (_ct.field == "op" && (_ct.kind == "mnemonic" || _ct.kind == "directive")) {
        _help = scr_asm_symbol_help(_ct.text);
        break;
    }
    _ck += 1;
}
if (_help != "") {
    draw_set_colour(make_colour_rgb(130, 185, 255));
    draw_text(_cx2, _y2, "   |   " + _help);
}
gpu_set_scissor(_prev_scissor2);

// ---- autocomplete popup ----
if (ac_open) {
    var _count = array_length(ac_items);
    var _rows = min(ac_rows, _count);
    draw_set_font(code_font);
    var _tw = 0;
    var _ai = ac_scroll;
    while (_ai < min(_count, ac_scroll + _rows)) {
        _tw = max(_tw, string_length(ac_items[_ai].text));
        _ai += 1;
    }
    var _text_w = max(10, _tw + 2) * char_w;
    draw_set_font(UI_FONT);
    var _badge_w = string_width("LVO") + 20;
    draw_set_font(code_font);
    var _detail_w = 560;
    var _pw = _badge_w + _text_w + _detail_w;
    var _ph = _rows * ac_row_h + 4;
    var _px = text_x + (ac_start_col - scroll_col) * char_w - _badge_w - 4;
    _px = clamp(_px, panel_x1 + 4, panel_x2 - _pw - 4);
    var _py = text_top + (ac_line - scroll_line + 1) * line_h + 2;
    if (_py + _ph > text_bottom) _py = text_top + (ac_line - scroll_line) * line_h - _ph - 2;
    _py = max(panel_y1 + 2, _py);
    ac_rect = [_px, _py, _px + _pw, _py + _ph];

    draw_set_alpha(0.97);
    scr_ui_box_fill(_px, _py, _px + _pw, _py + _ph, make_colour_rgb(20, 26, 44));
    draw_set_alpha(1);

    var _r = 0;
    while (_r < _rows) {
        var _idx = ac_scroll + _r;
        if (_idx >= _count) break;
        var _it = ac_items[_idx];
        var _ry = _py + 2 + _r * ac_row_h;
        if (_idx == ac_index) {
            draw_set_colour(make_colour_rgb(50, 75, 135));
            scr_te_rect_in_bevel(_px + 1, _ry, _px + _pw - 1, _ry + ac_row_h - 1, _px, _py, _px + _pw, _py + _ph);
        }
        var _kc = col_text;
        var _badge = "";
        switch (_it.kind) {
            case "mnemonic": _kc = col_mnemonic; _badge = "OP"; break;
            case "directive": _kc = col_directive; _badge = "DIR"; break;
            case "size": _kc = col_size; _badge = "SZ"; break;
            case "register": _kc = col_register; _badge = "REG"; break;
            case "hwreg": _kc = col_hwreg; _badge = "HW"; break;
            case "lvo": _kc = col_hwreg; _badge = "LVO"; break;
            case "const": _kc = col_number; _badge = "EQU"; break;
            case "label": _kc = col_label; _badge = "LBL"; break;
            case "symbol": _kc = col_symbol_known; _badge = "SYM"; break;
        }
        draw_set_font(UI_FONT);
        draw_set_colour(_kc);
        scr_ui_text_mid(_px + 10, _ry, _ry + ac_row_h, _badge);
        draw_set_font(code_font);
        draw_set_colour((_idx == ac_index) ? c_white : _kc);
        ed_draw_code(_px + _badge_w, _ry + (ac_row_h - line_h) * 0.5 + 1 + round(line_h * 0.12), _it.text);
        draw_set_font(UI_FONT);
        draw_set_colour(make_colour_rgb(150, 160, 190));
        var _detail = _it.detail;
        var _maxd = _detail_w - 12;
        if (string_width(_detail) > _maxd) {
            while (string_length(_detail) > 3 && string_width(_detail + "...") > _maxd) _detail = string_copy(_detail, 1, string_length(_detail) - 4);
            _detail += "...";
        }
        scr_ui_text_mid(_px + _badge_w + _text_w + 6, _ry, _ry + ac_row_h, _detail);
        _r += 1;
    }

    if (_count > _rows) {
        var _sbh = _ph * _rows / _count;
        var _sby = _py + (_ph - _sbh) * (ac_scroll / max(1, _count - _rows));
        draw_set_colour(make_colour_rgb(90, 110, 170));
        scr_te_rect_in_bevel(_px + _pw - 5, _sby, _px + _pw - 2, _sby + _sbh, _px, _py, _px + _pw, _py + _ph);
    }
    scr_ui_box_outline(_px, _py, _px + _pw, _py + _ph, make_colour_rgb(100, 125, 190));
} else {
    ac_rect = [0, 0, 0, 0];
}

// ---- hover tooltip ----
if (hover_text != "" && !ac_open) {
    draw_set_font(UI_FONT);
    var _tw2 = min(760, string_width_ext(hover_text, ui_h + 2, 760)) + 24;
    var _th2 = string_height_ext(hover_text, ui_h + 2, 760) + 16;
    var _tx = clamp(hover_x + 14, panel_x1 + 4, panel_x2 - _tw2 - 4);
    var _ty3 = hover_y + 20;
    if (_ty3 + _th2 > panel_y2 - 4) _ty3 = hover_y - _th2 - 8;
    draw_set_alpha(0.95);
    scr_ui_box_fill(_tx, _ty3, _tx + _tw2, _ty3 + _th2, make_colour_rgb(12, 14, 22));
    draw_set_alpha(1);
    scr_ui_box_outline(_tx, _ty3, _tx + _tw2, _ty3 + _th2, c_yellow);
    draw_set_colour(c_white);
    draw_text_ext(_tx + 12, _ty3 + 8, hover_text, ui_h + 2, 760);
}

draw_set_font(UI_FONT);
draw_set_colour(c_white);
draw_set_alpha(1);
