draw_set_font(UI_FONT_SMALL);

// Each family keeps its colour; the old two-colour gradients become one
// fill (their midpoint) with the house diagonal tone.
var _grad_1 = col1;
var _grad_2 = col2;
if (palette_mnemonic == "PLAY_MOD" || palette_mnemonic == "STOP_MOD" || palette_mnemonic == "PLAY_SFX") {
    _grad_1 = make_colour_rgb(20, 170, 90);
    _grad_2 = make_colour_rgb(10, 80, 45);
} else if (scr_gk_is_node_type(palette_mnemonic)) {
    _grad_1 = make_colour_rgb(220, 110, 30);
    _grad_2 = make_colour_rgb(110, 50, 10);
} else if (palette_mnemonic == "CODE") {
    _grad_1 = make_colour_rgb(20, 160, 180);
    _grad_2 = make_colour_rgb(10, 70, 90);
} else if (palette_mnemonic == "ORG") {
    _grad_1 = org_col1;
    _grad_2 = org_col2;
}

var _fill = merge_colour(_grad_1, _grad_2, 0.45);
var _x2 = palette_x + palette_width;
var _y2 = palette_y + palette_height;
var _hover = point_in_rectangle(mouse_x, mouse_y, palette_x, palette_y, _x2, _y2) && !scr_amiga_modal_open();

if (palette_top_strip) {
    scr_ui_button(palette_x, palette_y, _x2, _y2, scr_ui_fit_label(palette_display_label, palette_width - 6), _fill, _hover);
} else {
    if (_hover) _fill = merge_colour(_fill, c_white, 0.15);
    scr_ui_box(palette_x, palette_y, _x2, _y2, _fill, _hover ? c_yellow : merge_colour(_fill, c_white, 0.35));
    draw_set_colour(c_white);
    scr_ui_text_mid(palette_x + 5, palette_y, _y2, scr_ui_fit_label(palette_display_label, palette_width - 8));
}
