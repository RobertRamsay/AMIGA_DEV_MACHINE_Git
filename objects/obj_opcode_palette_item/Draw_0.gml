var _body_colour = make_color_rgb(40, 70, 140);

if (palette_mnemonic == "ORG") {
    _body_colour = make_color_rgb(160, 40, 160);
}

if (palette_mnemonic == "CPRBAR") {
    _body_colour = make_color_rgb(200, 110, 20);
}

draw_set_colour(_body_colour);
draw_rectangle(palette_x, palette_y, palette_x + palette_width, palette_y + palette_height, false);
draw_set_colour(c_white);
draw_text(palette_x + 15, palette_y, palette_display_label);


if (is_being_dragged) {
    draw_set_alpha(0.6);
    draw_set_colour(_body_colour);
    draw_rectangle(drag_ghost_x, drag_ghost_y, drag_ghost_x + palette_width, drag_ghost_y + palette_height, false);
    draw_set_colour(c_white);
    draw_text(drag_ghost_x + 8, drag_ghost_y + 6, palette_mnemonic);
    draw_set_alpha(1);
}