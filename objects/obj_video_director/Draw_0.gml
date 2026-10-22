// The end card: the whole screen.
if (end_card) {
    draw_set_alpha(1);
    draw_rectangle_colour(0, 0, room_width, room_height, make_colour_rgb(8, 10, 30), make_colour_rgb(8, 10, 30),
        make_colour_rgb(40, 12, 50), make_colour_rgb(40, 12, 50), false);
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_set_font(UI_FONT_TITLE);
    draw_set_colour(c_yellow);
    draw_text_transformed(room_width / 2, 420, "AMIGA DEV MACHINE", 4, 4, 0);
    draw_set_font(UI_FONT);
    draw_set_colour(c_white);
    draw_text_transformed(room_width / 2, 560, "Nodes, sprites, music and raw 68000 - built, booted and played", 1.6, 1.6, 0);
    draw_set_colour(make_colour_rgb(150, 200, 255));
    draw_text_transformed(room_width / 2, 640, "17 tutorials  -  a guided tour  -  A600 and A1200", 1.4, 1.4, 0);
    draw_set_colour(make_colour_rgb(170, 170, 190));
    draw_text_transformed(room_width / 2, 780, "Polytricity Ltd", 1.4, 1.4, 0);
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    exit;
}

// A caption band near the bottom, fading in.
if (caption == "") exit;
var _fade = clamp((get_timer() - caption_since) / 300000, 0, 1);
draw_set_font(UI_FONT_TITLE);
var _tw = string_width(caption) * 1.6;
draw_set_font(UI_FONT);
var _sw = string_width(caption_sub) * 1.15;
var _w = max(_tw, _sw) + 80;
var _x1 = (room_width - _w) / 2;
var _y1 = 930;
var _y2 = _y1 + (caption_sub == "" ? 70 : 112);
draw_set_alpha(0.88 * _fade);
scr_ui_box_fill(_x1, _y1, _x1 + _w, _y2, make_colour_rgb(10, 12, 28));
draw_set_alpha(_fade);
scr_ui_box_outline(_x1, _y1, _x1 + _w, _y2, c_yellow);
draw_set_halign(fa_center);
draw_set_valign(fa_middle);
draw_set_font(UI_FONT_TITLE);
draw_set_colour(c_yellow);
draw_text_transformed(room_width / 2, _y1 + 36, caption, 1.6, 1.6, 0);
if (caption_sub != "") {
    draw_set_font(UI_FONT);
    draw_set_colour(c_white);
    draw_text_transformed(room_width / 2, _y1 + 82, caption_sub, 1.15, 1.15, 0);
}
draw_set_alpha(1);
draw_set_halign(fa_left);
draw_set_valign(fa_top);
