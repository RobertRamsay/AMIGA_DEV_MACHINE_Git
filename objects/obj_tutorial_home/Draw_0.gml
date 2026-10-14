draw_set_font(UI_FONT_GUIDE);
draw_set_halign(fa_left);
draw_set_valign(fa_top);
draw_set_alpha(1);

var _col_text = make_colour_rgb(205, 212, 225);
var _col_edge = make_colour_rgb(85, 95, 125);
var _col_done = make_colour_rgb(70, 170, 100);

// Opaque backdrop: the ADM background, darkened a little for contrast.
draw_sprite_stretched(spr_ADM_Bkg, 0, 0, 0, room_width, room_height);
draw_set_alpha(0.35);
draw_set_colour(c_black);
draw_rectangle(0, 0, room_width, room_height, false);
draw_set_alpha(1);

// --- tutorial cards (drawn first; the strips above/below the list are
// redrawn over them, which clips the list when it scrolls) ---------------------
var _defs = scr_tutorial_defs();
var _c = 0;
while (_c < array_length(home_controls)) {
    var _ctl = home_controls[_c];
    if (_ctl.kind == "card" && _ctl.y2 >= home_list_top && _ctl.y1 <= home_list_bottom) {
        var _def = _defs[_ctl.index];
        var _hover = home_hover == _c;
        var _done = scr_tutorial_is_done(_def.id);
        var _is_current = global.tutorial_current == _ctl.index;
        var _level_col = scr_tutorial_level_colour(_def.level);
        var _x1 = _ctl.x1, _y1 = _ctl.y1, _x2 = _ctl.x2, _y2 = _ctl.y2;
        var _bevel = scr_ui_bevel(_x2 - _x1, _y2 - _y1);

        // Card, with the level colour as a stripe down the left edge (below
        // the corner cut).
        draw_set_alpha(0.92);
        scr_ui_box_fill(_x1, _y1, _x2, _y2, _hover ? home_col_card_hover : home_col_card);
        draw_set_alpha(1);
        draw_set_colour(_level_col);
        draw_rectangle(_x1 + 1, _y1 + _bevel + 2, _x1 + 4, _y2 - 1, false);
        scr_ui_box_outline(_x1, _y1, _x2, _y2, _hover ? c_yellow : (_done ? _col_done : _col_edge));

        // Number box, level-coloured, as tall as the title row plus the
        // first summary line.
        var _row_y1 = _y1 + home_pad;
        var _row_y2 = _row_y1 + home_badge_h;
        var _nx = _x1 + home_pad + 6;
        var _ns = home_badge_h + 8 + home_text_h * 2;
        scr_ui_box(_nx, _row_y1, _nx + _ns, _row_y1 + _ns, merge_colour(_level_col, c_black, 0.45), _level_col);
        draw_set_font(UI_FONT_TITLE);
        draw_set_colour(c_white);
        scr_ui_text_centred(_nx + _ns * 0.5, _row_y1 + _ns * 0.5, string(_def.id));

        // Title, vertically centred on the badge row.
        var _tx = _nx + _ns + 16;
        draw_set_colour(c_white);
        scr_ui_text_mid(_tx, _row_y1, _row_y2, _def.title);

        // Level badge, then DONE / LOADED, right-aligned on the title row.
        var _bx2 = _x2 - home_pad;
        var _bw = scr_tutorial_ui_badge_w(_def.level);
        scr_tutorial_ui_draw_badge(_bx2 - _bw, _row_y1, _row_y2, _def.level, _level_col);
        _bx2 -= _bw + 8;
        if (_done) {
            // Room on the left of the word for the tick.
            var _tick = home_text_h - 6;
            _bw = scr_tutorial_ui_badge_w("DONE") + _tick + 6;
            scr_ui_box(_bx2 - _bw, _row_y1, _bx2, _row_y2, make_colour_rgb(25, 90, 50), _col_done);
            scr_tutorial_ui_draw_tick(_bx2 - _bw + 9, (_row_y1 + _row_y2) * 0.5 - _tick * 0.5, _tick, make_colour_rgb(120, 255, 150));
            draw_set_font(UI_FONT_GUIDE);
            draw_set_colour(make_colour_rgb(170, 255, 190));
            scr_ui_text_centred(_bx2 - (_bw - _tick - 6) * 0.5, (_row_y1 + _row_y2) * 0.5, "DONE");
            _bx2 -= _bw + 8;
        }
        if (_is_current) {
            _bw = scr_tutorial_ui_badge_w("LOADED");
            scr_tutorial_ui_draw_badge(_bx2 - _bw, _row_y1, _row_y2, "LOADED", make_colour_rgb(20, 90, 110), c_aqua);
        }

        // Summary (two lines).
        draw_set_font(UI_FONT_GUIDE);
        draw_set_colour(_col_text);
        draw_text_ext(_tx, _row_y2 + 8, _def.summary, home_text_h, _x2 - _tx - home_pad);

        // START button, bottom right; the feature chips (up to two rows) sit
        // on its left, sharing its bottom edge.
        draw_set_font(UI_FONT_GUIDE);
        var _start_w = max(string_width("START"), string_width("AGAIN")) + 44;
        var _start_x1 = _x2 - home_pad - _start_w;
        var _start_y2 = _y2 - home_pad;
        scr_tutorial_ui_draw_button(_start_x1, _start_y2 - home_button_h, _x2 - home_pad, _start_y2, _done ? "AGAIN" : "START",
            make_colour_rgb(30, 120, 50), _hover, true);

        draw_set_font(UI_FONT_SMALL);
        var _chip_x = _tx;
        var _chip_y = _start_y2 - home_chip_h * 2 - 4;
        var _chip_limit = _start_x1 - 12;
        var _chip_row = 0;
        var _f = 0;
        while (_f < array_length(_def.features)) {
            var _feature = _def.features[_f];
            var _chip_w = string_width(_feature) + 14;
            if (_chip_x + _chip_w > _chip_limit && _chip_x > _tx) {
                _chip_row += 1;
                if (_chip_row >= 2) break;
                _chip_x = _tx;
                _chip_y += home_chip_h + 4;
            }
            scr_ui_box(_chip_x, _chip_y, _chip_x + _chip_w, _chip_y + home_chip_h, make_colour_rgb(35, 45, 70), make_colour_rgb(80, 100, 145));
            draw_set_colour(make_colour_rgb(175, 195, 235));
            scr_ui_text_centred(_chip_x + _chip_w * 0.5, _chip_y + home_chip_h * 0.5, _feature);
            _chip_x += _chip_w + 6;
            _f += 1;
        }
    }
    _c += 1;
}

// Clip the list: redraw the backdrop above and below it.
var _clip_x = home_list_x - 8;
draw_sprite_part(spr_ADM_Bkg, 0, _clip_x, 0, room_width - _clip_x, home_list_top - 6, _clip_x, 0);
draw_sprite_part(spr_ADM_Bkg, 0, _clip_x, home_list_bottom + 4, room_width - _clip_x, room_height - home_list_bottom - 4, _clip_x, home_list_bottom + 4);
draw_set_alpha(0.35);
draw_set_colour(c_black);
draw_rectangle(_clip_x, 0, room_width, home_list_top - 7, false);
draw_rectangle(_clip_x, home_list_bottom + 4, room_width, room_height, false);
draw_set_alpha(1);

// MORE indicators between the columns: a label and three flat chevrons that
// light up in a travelling wave and bob in the scroll direction.
_c = 0;
while (_c < array_length(home_controls)) {
    var _m = home_controls[_c];
    if (_m.kind == "more") {
        var _down = _m.action == "more_down";
        var _mx = (_m.x1 + _m.x2) * 0.5;
        var _t = current_time / 1000;
        var _bob = round(sin(_t * 4) * 4) * (_down ? 1 : -1);
        var _hot = home_hover == _c;
        draw_set_alpha(0.75);
        scr_ui_box(_m.x1, _m.y1, _m.x2, _m.y2, _hot ? make_colour_rgb(35, 50, 85) : make_colour_rgb(14, 18, 32), _hot ? c_yellow : make_colour_rgb(60, 80, 130));
        draw_set_alpha(1);
        draw_set_font(UI_FONT_SMALL);
        draw_set_colour(_hot ? c_yellow : make_colour_rgb(160, 200, 255));
        // "SCROLL / DOWN / (MORE)" stacked to fit the gap, then the chevrons.
        var _words = ["SCROLL", _down ? "DOWN" : "UP", "(MORE)"];
        var _w = 0;
        while (_w < 3) {
            scr_ui_text_centred(_mx, _down ? _m.y1 + 14 + _w * 17 : _m.y2 - 48 + _w * 17, _words[_w]);
            _w += 1;
        }
        var _half = (_m.x2 - _m.x1) * 0.5 - 8;
        var _k = 0;
        while (_k < 3) {
            // Chevron k: from the label outwards in the scroll direction.
            var _cy = _down ? _m.y1 + 70 + _k * 22 + _bob : _m.y2 - 70 - _k * 22 + _bob;
            var _glow = 0.3 + 0.7 * (0.5 + 0.5 * sin(_t * 5 - _k * 1.2));
            draw_set_alpha(_glow);
            draw_set_colour(_hot ? c_yellow : make_colour_rgb(90, 200, 255));
            if (_down) draw_triangle(_mx - _half, _cy, _mx + _half, _cy, _mx, _cy + 11, false);
            else draw_triangle(_mx - _half, _cy, _mx + _half, _cy, _mx, _cy - 11, false);
            _k += 1;
        }
        draw_set_alpha(1);
    }
    _c += 1;
}

// --- header ------------------------------------------------------------------
draw_sprite_ext(spr_ADM_SmallLogo, 0, 36, 16, 0.85, 0.85, 0, c_white, 1);
draw_set_font(font_Future);
draw_set_colour(c_white);
draw_text(170, 30, "AMIGA DEV MACHINE");
draw_set_font(UI_FONT_GUIDE);
draw_set_colour(home_col_dim);
draw_text(170, 64, "Node-based 68000 assembler for the Amiga. Press F5 and your program boots in FS-UAE.");
// Copyright and version, right-aligned beside the close box.
var _close = home_controls[array_length(home_controls) - 1];
draw_set_halign(fa_right);
draw_text(_close.x1 - 16, _close.y1 - 2, "(C) POLYTRICITY 2026");
draw_text(_close.x1 - 16, _close.y1 - 2 + home_text_h, "VERSION: " + string(GM_version));
draw_set_halign(fa_left);
draw_set_colour(make_colour_rgb(70, 90, 140));
draw_line_width(36, 120, room_width - 36, 120, 2);

// --- section headings, centred in the band above the columns -------------------
var _head_y1 = 132;
var _head_y2 = home_list_top - 8;
draw_set_font(UI_FONT_TITLE);
draw_set_colour(c_white);
scr_ui_text_mid(home_left_x, _head_y1, _head_y2, "START");
scr_ui_text_mid(home_list_x, _head_y1, _head_y2, "TUTORIALS");
var _hint_x = home_list_x + string_width("TUTORIALS") + 20;
draw_set_font(UI_FONT_GUIDE);
draw_set_colour(home_col_dim);
scr_ui_text_mid(_hint_x, _head_y1, _head_y2, "Simplest first - each one is a complete program: load it, read the guide, press F5.");

// --- start column --------------------------------------------------------------
_c = 0;
while (_c < array_length(home_controls)) {
    var _b = home_controls[_c];
    var _over = home_hover == _c;
    if (_b.kind == "start") {
        // Heading and description, left-aligned and centred as a block.
        var _fill = _b.action == "continue" ? make_colour_rgb(30, 110, 60) : home_col_button;
        draw_set_alpha(0.95);
        scr_ui_box(_b.x1, _b.y1, _b.x2, _b.y2, _over ? merge_colour(_fill, c_white, 0.2) : _fill, _over ? c_yellow : merge_colour(_fill, c_white, 0.55));
        draw_set_alpha(1);
        var _block_y = round((_b.y1 + _b.y2 - (home_title_h + 3 + home_text_h)) * 0.5);
        draw_set_font(UI_FONT_TITLE);
        draw_set_colour(c_white);
        draw_text(_b.x1 + home_pad + 4, _block_y, _b.label);
        draw_set_font(UI_FONT_GUIDE);
        draw_set_colour(make_colour_rgb(190, 200, 220));
        draw_text(_b.x1 + home_pad + 4, _block_y + home_title_h + 3, _b.sub);
    } else if (_b.kind == "check") {
        var _size = _b.y2 - _b.y1;
        scr_tutorial_ui_draw_checkbox(_b.x1, _b.y1, _size, scr_tutorial_home_show_at_startup(), _over);
        draw_set_font(UI_FONT_GUIDE);
        draw_set_colour(_over ? c_yellow : c_white);
        scr_ui_text_mid(_b.x1 + _size + 10, _b.y1, _b.y2, _b.label);
    } else if (_b.kind == "closebox") {
        scr_tutorial_ui_draw_button(_b.x1, _b.y1, _b.x2, _b.y2, "X", make_colour_rgb(150, 30, 30), _over, true);
    }
    _c += 1;
}

// Progress: heading and count on one line, then the bar.
var _done_count = scr_tutorial_done_count();
var _total = array_length(_defs);
var _py = home_left_bottom + 16;
draw_set_font(UI_FONT_TITLE);
draw_set_colour(c_white);
var _progress_w = string_width("PROGRESS");
scr_ui_text_mid(home_left_x, _py, _py + home_badge_h, "PROGRESS");
draw_set_font(UI_FONT_GUIDE);
draw_set_colour(home_col_dim);
scr_ui_text_mid(home_left_x + _progress_w + 14, _py, _py + home_badge_h, string(_done_count) + " of " + string(_total) + " tutorials done");
_py += home_badge_h + 6;
draw_set_colour(home_col_card);
draw_rectangle(home_left_x, _py, home_left_x + home_left_w, _py + 10, false);
if (_total > 0 && _done_count > 0) {
    draw_set_colour(make_colour_rgb(40, 170, 90));
    draw_rectangle(home_left_x, _py, home_left_x + floor(home_left_w * _done_count / _total), _py + 10, false);
}
draw_set_colour(_col_edge);
draw_rectangle(home_left_x, _py, home_left_x + home_left_w, _py + 10, true);

// How it works: fills the column down to the bottom of the card list.
_py += 10 + 16;
var _help_y2 = home_list_bottom;
if (_help_y2 - _py > 120) {
    draw_set_alpha(0.85);
    scr_ui_box_fill(home_left_x, _py, home_left_x + home_left_w, _help_y2, home_col_panel);
    draw_set_alpha(1);
    scr_ui_box_outline(home_left_x, _py, home_left_x + home_left_w, _help_y2, _col_edge);
    draw_set_font(UI_FONT_TITLE);
    draw_set_colour(c_white);
    draw_text(home_left_x + home_pad + 4, _py + home_pad, "HOW IT WORKS");
    draw_set_font(UI_FONT_GUIDE);
    var _help = [
        "Drag opcodes from the left palette and macros from the top strip onto the workspace.",
        "Nodes stacked under the INIT block run from top to bottom: position is program order.",
        "Every program needs a core loop - a branch back to an earlier label.",
        "Hover a node for help. Right-click deletes, Ctrl+Z undoes.",
        "F5 (or RUN) assembles with vasm, writes a bootable disk and boots it in FS-UAE.",
        "ALL TUTORIALS on the guide panel brings this page back."
    ];
    var _text_x = home_left_x + home_pad + 16;
    var _text_w = home_left_x + home_left_w - home_pad - _text_x;
    var _hy = _py + home_pad + home_title_h + 12;
    var _h = 0;
    while (_h < array_length(_help)) {
        var _text_h = string_height_ext(_help[_h], home_text_h, _text_w);
        if (_hy + _text_h > _help_y2 - home_pad) break;
        // Bullet, centred on the first line.
        var _dot_y = _hy + home_text_h div 2;
        draw_set_colour(make_colour_rgb(110, 170, 255));
        draw_rectangle(home_left_x + home_pad + 4, _dot_y - 2, home_left_x + home_pad + 8, _dot_y + 2, false);
        draw_set_colour(_col_text);
        draw_text_ext(_text_x, _hy, _help[_h], home_text_h, _text_w);
        _hy += _text_h + 6;
        _h += 1;
    }
}

// Scroll hint.
if (home_scroll_max > 0) {
    var _track_x = home_list_x + home_list_w + 12;
    var _track_h = home_list_bottom - home_list_top;
    var _thumb_h = max(30, floor(_track_h * _track_h / (_track_h + home_scroll_max)));
    var _thumb_y = home_list_top + floor((_track_h - _thumb_h) * home_scroll / home_scroll_max);
    draw_set_colour(make_colour_rgb(25, 30, 45));
    draw_rectangle(_track_x, home_list_top, _track_x + 8, home_list_bottom, false);
    draw_set_colour(make_colour_rgb(105, 120, 165));
    draw_rectangle(_track_x, _thumb_y, _track_x + 8, _thumb_y + _thumb_h, false);
}

draw_set_colour(c_white);
draw_set_alpha(1);
