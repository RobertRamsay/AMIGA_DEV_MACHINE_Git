home_layout();

draw_set_font(font_CyberVerse);
draw_set_halign(fa_left);
draw_set_valign(fa_top);
draw_set_alpha(1);

// Opaque backdrop: the ADM background, darkened a little for contrast.
draw_sprite_stretched(spr_ADM_Bkg, 0, 0, 0, room_width, room_height);
draw_set_alpha(0.35);
draw_set_colour(c_black);
draw_rectangle(0, 0, room_width, room_height, false);
draw_set_alpha(1);

// --- tutorial cards (drawn first; the strips above/below the list are
// redrawn over them, which clips the list when it scrolls) ---------------------
var _defs = scr_tutorial_defs();
var _line_h = string_height("Ag");
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

        draw_set_alpha(0.92);
        draw_set_colour(_hover ? home_col_card_hover : home_col_card);
        draw_rectangle(_x1, _y1, _x2, _y2, false);
        draw_set_alpha(1);
        draw_set_colour(_level_col);
        draw_rectangle(_x1, _y1, _x1 + 4, _y2, false);
        draw_set_colour(_hover ? c_yellow : (_done ? make_colour_rgb(70, 170, 100) : make_colour_rgb(85, 95, 125)));
        draw_rectangle(_x1, _y1, _x2, _y2, true);

        // Number box.
        var _nx = _x1 + 16, _ny = _y1 + 14;
        draw_set_colour(merge_colour(_level_col, c_black, 0.45));
        draw_rectangle(_nx, _ny, _nx + 54, _ny + 54, false);
        draw_set_colour(_level_col);
        draw_rectangle(_nx, _ny, _nx + 54, _ny + 54, true);
        draw_set_font(font_Future);
        draw_set_colour(c_white);
        draw_set_halign(fa_center);
        draw_set_valign(fa_middle);
        draw_text(_nx + 27, _ny + 28, string(_def.id));
        draw_set_halign(fa_left);
        draw_set_valign(fa_top);

        // Title.
        var _tx = _x1 + 86;
        draw_text(_tx, _y1 + 12, _def.title);

        // Level badge and done mark, right-aligned on the title row.
        draw_set_font(font_CyberVerse);
        var _badge_w = string_width(_def.level) + 16;
        var _badge_x2 = _x2 - 14;
        var _badge_x1 = _badge_x2 - _badge_w;
        draw_set_colour(_level_col);
        draw_rectangle(_badge_x1, _y1 + 12, _badge_x2, _y1 + 12 + _line_h + 4, false);
        draw_set_colour(c_white);
        draw_text(_badge_x1 + 8, _y1 + 14, _def.level);
        if (_done) {
            var _done_x2 = _badge_x1 - 8;
            var _done_x1 = _done_x2 - (string_width("DONE") + 36);
            draw_set_colour(make_colour_rgb(25, 90, 50));
            draw_rectangle(_done_x1, _y1 + 12, _done_x2, _y1 + 12 + _line_h + 4, false);
            scr_tutorial_ui_draw_tick(_done_x1 + 7, _y1 + 15, _line_h - 3, make_colour_rgb(120, 255, 150));
            draw_set_colour(make_colour_rgb(170, 255, 190));
            draw_text(_done_x1 + 28, _y1 + 14, "DONE");
            _badge_x1 = _done_x1;
        }
        if (_is_current) {
            var _cur_x2 = _badge_x1 - 8;
            var _cur_x1 = _cur_x2 - (string_width("LOADED") + 16);
            draw_set_colour(make_colour_rgb(20, 90, 110));
            draw_rectangle(_cur_x1, _y1 + 12, _cur_x2, _y1 + 12 + _line_h + 4, false);
            draw_set_colour(c_aqua);
            draw_text(_cur_x1 + 8, _y1 + 14, "LOADED");
        }

        // Summary.
        draw_set_colour(make_colour_rgb(205, 212, 225));
        draw_text_ext(_tx, _y1 + 44, _def.summary, _line_h, _x2 - _tx - 16);

        // Feature chips (up to two rows), left of the START button.
        draw_set_font(font_CyberVerse_OpCode);
        var _chip_h = string_height("Ag") + 4;
        var _chip_x = _tx;
        var _chip_y = _y2 - 14 - _chip_h * 2 - 4;
        var _chip_limit = _x2 - 120;
        var _chip_row = 0;
        var _f = 0;
        while (_f < array_length(_def.features)) {
            var _feature = _def.features[_f];
            var _chip_w = string_width(_feature) + 12;
            if (_chip_x + _chip_w > _chip_limit && _chip_x > _tx) {
                _chip_row += 1;
                if (_chip_row >= 2) break;
                _chip_x = _tx;
                _chip_y += _chip_h + 4;
            }
            draw_set_colour(make_colour_rgb(35, 45, 70));
            draw_rectangle(_chip_x, _chip_y, _chip_x + _chip_w, _chip_y + _chip_h, false);
            draw_set_colour(make_colour_rgb(80, 100, 145));
            draw_rectangle(_chip_x, _chip_y, _chip_x + _chip_w, _chip_y + _chip_h, true);
            draw_set_colour(make_colour_rgb(175, 195, 235));
            draw_text(_chip_x + 6, _chip_y + 2, _feature);
            _chip_x += _chip_w + 6;
            _f += 1;
        }
        draw_set_font(font_CyberVerse);

        // START button (the whole card is clickable too).
        scr_tutorial_ui_draw_button(_x2 - 104, _y2 - 40, _x2 - 14, _y2 - 14, _done ? "AGAIN" : "START",
            make_colour_rgb(30, 120, 50), _hover, true);
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

// --- header ------------------------------------------------------------------
draw_sprite_ext(spr_ADM_SmallLogo, 0, 36, 16, 0.85, 0.85, 0, c_white, 1);
draw_set_font(font_Future);
draw_set_colour(c_white);
draw_text(170, 30, "AMIGA DEV MACHINE");
draw_set_font(font_CyberVerse);
draw_set_colour(home_col_dim);
draw_text(170, 64, "Node-based 68000 assembler for the Amiga. Press F5 and your program boots in FS-UAE.");
draw_set_halign(fa_right);
draw_text(1840, 24, "(C) POLYTRICITY 2026");
draw_text(1840, 42, "VERSION: " + string(GM_version));
draw_set_halign(fa_left);
draw_set_colour(make_colour_rgb(70, 90, 140));
draw_line_width(36, 120, room_width - 36, 120, 2);

// --- start column --------------------------------------------------------------
draw_set_colour(c_white);
draw_text(home_left_x, 144, "START");
draw_set_colour(c_white);
draw_text(home_list_x, 144, "TUTORIALS");
draw_set_colour(home_col_dim);
draw_text(home_list_x + 130, 144, "Simplest first - each one is a complete program: load it, read the guide, press F5.");

_c = 0;
while (_c < array_length(home_controls)) {
    var _b = home_controls[_c];
    var _over = home_hover == _c;
    if (_b.kind == "start") {
        var _fill = _b.action == "continue" ? make_colour_rgb(30, 110, 60) : home_col_button;
        draw_set_alpha(0.95);
        draw_set_colour(_over ? merge_colour(_fill, c_white, 0.2) : _fill);
        draw_rectangle(_b.x1, _b.y1, _b.x2, _b.y2, false);
        draw_set_alpha(1);
        draw_set_colour(_over ? c_yellow : c_white);
        draw_rectangle(_b.x1, _b.y1, _b.x2, _b.y2, true);
        draw_set_colour(c_white);
        draw_text(_b.x1 + 14, _b.y1 + 9, _b.label);
        draw_set_colour(make_colour_rgb(185, 195, 215));
        draw_text(_b.x1 + 14, _b.y1 + 9 + _line_h + 4, _b.sub);
    } else if (_b.kind == "check") {
        var _on = scr_tutorial_home_show_at_startup();
        draw_set_colour(home_col_card);
        draw_rectangle(_b.x1, _b.y1, _b.x1 + 20, _b.y1 + 20, false);
        draw_set_colour(_over ? c_yellow : c_white);
        draw_rectangle(_b.x1, _b.y1, _b.x1 + 20, _b.y1 + 20, true);
        if (_on) scr_tutorial_ui_draw_tick(_b.x1 + 4, _b.y1 + 4, 13, make_colour_rgb(120, 255, 150));
        draw_set_colour(_over ? c_yellow : c_white);
        draw_text(_b.x1 + 30, _b.y1 + 2, _b.label);
    } else if (_b.kind == "closebox") {
        scr_tutorial_ui_draw_button(_b.x1, _b.y1, _b.x2, _b.y2, "X", make_colour_rgb(150, 30, 30), _over, true);
    }
    _c += 1;
}

// Progress.
var _done_count = scr_tutorial_done_count();
var _total = array_length(_defs);
var _py = home_left_bottom + 20;
draw_set_colour(c_white);
draw_text(home_left_x, _py, "PROGRESS");
draw_set_colour(home_col_dim);
draw_text(home_left_x + 110, _py, string(_done_count) + " of " + string(_total) + " tutorials done");
_py += _line_h + 8;
draw_set_colour(home_col_card);
draw_rectangle(home_left_x, _py, home_left_x + home_left_w, _py + 12, false);
if (_total > 0 && _done_count > 0) {
    draw_set_colour(make_colour_rgb(40, 170, 90));
    draw_rectangle(home_left_x, _py, home_left_x + floor(home_left_w * _done_count / _total), _py + 12, false);
}
draw_set_colour(make_colour_rgb(85, 95, 125));
draw_rectangle(home_left_x, _py, home_left_x + home_left_w, _py + 12, true);

// How it works.
_py += 40;
var _help_h = 1048 - _py;
if (_help_h > 120) {
    draw_set_alpha(0.85);
    draw_set_colour(home_col_panel);
    draw_rectangle(home_left_x, _py, home_left_x + home_left_w, _py + _help_h, false);
    draw_set_alpha(1);
    draw_set_colour(make_colour_rgb(85, 95, 125));
    draw_rectangle(home_left_x, _py, home_left_x + home_left_w, _py + _help_h, true);
    draw_set_colour(c_white);
    draw_text(home_left_x + 12, _py + 10, "HOW IT WORKS");
    var _help = [
        "Drag opcodes from the left palette and macros from the top strip onto the workspace.",
        "Nodes stacked under the INIT block run from top to bottom: position is program order.",
        "Every program needs a core loop - a branch back to an earlier label.",
        "Hover a node for help. Right-click deletes, Ctrl+Z undoes.",
        "F5 (or RUN) assembles with vasm, writes a bootable disk and boots it in FS-UAE.",
        "ALL TUTORIALS on the guide panel brings this page back."
    ];
    var _hy = _py + 10 + _line_h + 10;
    var _h = 0;
    while (_h < array_length(_help)) {
        var _text_h = string_height_ext(_help[_h], _line_h, home_left_w - 40);
        if (_hy + _text_h > _py + _help_h - 8) break;
        draw_set_colour(make_colour_rgb(110, 170, 255));
        draw_rectangle(home_left_x + 14, _hy + 6, home_left_x + 19, _hy + 11, false);
        draw_set_colour(make_colour_rgb(205, 212, 225));
        draw_text_ext(home_left_x + 28, _hy, _help[_h], _line_h, home_left_w - 40);
        _hy += _text_h + 8;
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
