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