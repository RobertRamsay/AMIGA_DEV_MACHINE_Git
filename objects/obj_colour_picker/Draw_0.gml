/// @desc obj_colour_picker Draw
draw_set_font(UI_FONT);
draw_set_halign(fa_left);
draw_set_valign(fa_top);

draw_set_alpha(0.75);
draw_rectangle_colour(0, 0, room_width, room_height, c_black, c_black, c_black, c_black, false);
draw_set_alpha(1);

scr_ui_box(panel_x, panel_y, panel_x + panel_width, panel_y + panel_height, make_colour_rgb(44, 48, 58), c_white);

var _hex_digits = "0123456789ABCDEF";
var _hex_text = string_char_at(_hex_digits, colour_r + 1) + string_char_at(_hex_digits, colour_g + 1) + string_char_at(_hex_digits, colour_b + 1);

var _preview_size = 40;
var _preview_x = panel_x + panel_width - _preview_size - 12;
var _preview_y = panel_y + 12;

// Title and #RGB value share the preview swatch's height, one line each.
draw_set_colour(c_white);
scr_ui_text_mid(panel_x + 12, _preview_y, _preview_y + _preview_size * 0.5, picker_title);
draw_set_colour(make_colour_rgb(200, 210, 225));
scr_ui_text_mid(panel_x + 12, _preview_y + _preview_size * 0.5, _preview_y + _preview_size, "#" + _hex_text);

draw_set_colour(make_color_rgb(colour_r * 17, colour_g * 17, colour_b * 17));
draw_rectangle(_preview_x, _preview_y, _preview_x + _preview_size, _preview_y + _preview_size, false);
draw_set_colour(c_white);
draw_rectangle(_preview_x, _preview_y, _preview_x + _preview_size, _preview_y + _preview_size, true);

var _channel = 0;

while (_channel < 3) {
    var _slider_y = slider_r_y;
    var _selected = colour_r;
    var _label = "R";

    if (_channel == 1) {
        _slider_y = slider_g_y;
        _selected = colour_g;
        _label = "G";
    }

    if (_channel == 2) {
        _slider_y = slider_b_y;
        _selected = colour_b;
        _label = "B";
    }

    draw_set_colour(c_white);
    scr_ui_text_mid(slider_x - 18, _slider_y, _slider_y + slider_height, _label);

    var _step = 0;

    while (_step < 16) {
        var _segment_x = slider_x + _step * slider_step_width;
        var _segment_colour = make_color_rgb(_step * 17, 0, 0);

        if (_channel == 1) {
            _segment_colour = make_color_rgb(0, _step * 17, 0);
        }

        if (_channel == 2) {
            _segment_colour = make_color_rgb(0, 0, _step * 17);
        }

        draw_set_colour(_segment_colour);
        draw_rectangle(_segment_x, _slider_y, _segment_x + slider_step_width, _slider_y + slider_height, false);

        var _outline_colour = c_dkgray;

        if (_step == _selected) {
            _outline_colour = c_yellow;
        }

        draw_set_colour(_outline_colour);
        draw_rectangle(_segment_x, _slider_y, _segment_x + slider_step_width, _slider_y + slider_height, true);

        _step += 1;
    }

    draw_set_colour(c_white);
    scr_ui_text_mid(slider_x + slider_width + 4, _slider_y, _slider_y + slider_height, string_char_at(_hex_digits, _selected + 1));

    _channel += 1;
}

draw_set_colour(c_white);
scr_ui_text_mid(recent_row_x, recent_row_y - 22, recent_row_y - 2, "RECENT:");

var _recent_draw_index = 0;
var _recent_draw_count = array_length(global.colour_picker_recent_hex);

while (_recent_draw_index < _recent_draw_count) {
    var _recent_x = recent_row_x + (_recent_draw_index * (recent_swatch_width + recent_swatch_gap));
    var _recent_hex = global.colour_picker_recent_hex[_recent_draw_index];

    var _recent_r = scr_hex_string_to_number(string_copy(_recent_hex, 1, 1));
    var _recent_g = scr_hex_string_to_number(string_copy(_recent_hex, 2, 1));
    var _recent_b = scr_hex_string_to_number(string_copy(_recent_hex, 3, 1));

    draw_set_colour(make_color_rgb(_recent_r * 17, _recent_g * 17, _recent_b * 17));
    draw_rectangle(_recent_x, recent_row_y, _recent_x + recent_swatch_width, recent_row_y + recent_swatch_height, false);
    draw_set_colour(c_white);
    draw_rectangle(_recent_x, recent_row_y, _recent_x + recent_swatch_width, recent_row_y + recent_swatch_height, true);

    _recent_draw_index += 1;
}

if (_recent_draw_count == 0) {
    draw_set_colour(c_gray);
    scr_ui_text_mid(recent_row_x, recent_row_y, recent_row_y + recent_swatch_height, "none yet");
}

scr_ui_button(close_button_x, close_button_y, close_button_x + close_button_width, close_button_y + close_button_height, "Close", c_olive,
    point_in_rectangle(mouse_x, mouse_y, close_button_x, close_button_y, close_button_x + close_button_width, close_button_y + close_button_height));
