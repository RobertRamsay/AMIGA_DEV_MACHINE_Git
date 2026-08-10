draw_set_font(font_Future_OpCode);

var _body_colour = make_color_rgb(40, 70, 240);



if (palette_mnemonic == "CPRBAR") {
    _body_colour = make_color_rgb(200, 110, 20);
}

if (palette_mnemonic == "SETBKG") {
    _body_colour = make_color_rgb(150, 150, 40);
}

draw_set_colour(_body_colour);

draw_rectangle_colour(palette_x, palette_y, palette_x + palette_width, palette_y + palette_height, col1,col2,col1,col2, false);

if (palette_mnemonic == "ORG") {
    _body_colour = make_color_rgb(160, 40, 160);
	draw_rectangle_colour(palette_x, palette_y, palette_x + palette_width, palette_y + palette_height, org_col1,org_col2,org_col1,org_col2, false);
}


draw_set_colour(c_white);
draw_text(palette_x + 3, palette_y+5, palette_display_label);