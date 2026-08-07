var _body_colour = make_color_rgb(40, 70, 240);

if (palette_mnemonic == "ORG") {
    _body_colour = make_color_rgb(160, 40, 160);
}

if (palette_mnemonic == "CPRBAR") {
    _body_colour = make_color_rgb(200, 110, 20);
}

if (palette_mnemonic == "SETBKG") {
    _body_colour = make_color_rgb(150, 150, 40);
}

draw_set_colour(_body_colour);
draw_rectangle(palette_x, palette_y, palette_x + palette_width, palette_y + palette_height, false);
draw_set_colour(c_white);
draw_text(palette_x + 3, palette_y, palette_display_label);