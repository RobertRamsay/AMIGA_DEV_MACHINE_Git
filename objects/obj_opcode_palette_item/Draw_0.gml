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
    // Type to find (scr_palette_find): matches light up in pulsing gold with
    // dark text and the typed letters underlined; everything else dims.
    var _finding = global.palette_find != "";
    var _match = _finding && scr_palette_find_match(palette_display_label);
    var _outline = _hover ? c_yellow : merge_colour(_fill, c_white, 0.35);
    var _text_colour = c_white;
    if (_hover) _fill = merge_colour(_fill, c_white, 0.15);
    if (_match) {
        var _pulse = 0.5 + 0.5 * sin(current_time * 0.008);
        _fill = merge_colour(make_colour_rgb(230, 170, 20), make_colour_rgb(255, 235, 120), _pulse);
        _outline = _hover ? c_white : c_yellow;
        _text_colour = make_colour_rgb(20, 16, 40);
    }
    if (_finding && !_match) draw_set_alpha(0.3);
    scr_ui_box(palette_x, palette_y, _x2, _y2, _fill, _outline);
    var _label = scr_ui_fit_label(palette_display_label, palette_width - 8);
    draw_set_colour(_text_colour);
    scr_ui_text_mid(palette_x + 5, palette_y, _y2, _label);
    if (_match) {
        var _typed_w = string_width(string_copy(_label, 1, string_length(global.palette_find)));
        var _line_y = (palette_y + _y2) / 2 + string_height("M") / 2;
        draw_rectangle(palette_x + 5, _line_y, palette_x + 5 + _typed_w - 1, _line_y + 1, false);
    }
    draw_set_colour(c_white);
    draw_set_alpha(1);
}
