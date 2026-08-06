/// @desc obj_colour_picker Draw
draw_set_alpha(0.75);
draw_rectangle_colour(0, 0, room_width, room_height, c_black, c_black, c_black, c_black, false);
draw_set_alpha(1);

draw_set_colour(c_dkgray);
draw_rectangle(panel_x, panel_y, panel_x + panel_width, panel_y + panel_height, false);
draw_set_colour(c_white);
draw_rectangle(panel_x, panel_y, panel_x + panel_width, panel_y + panel_height, true);

var _hex_digits = "0123456789ABCDEF";
var _hex_text = string_char_at(_hex_digits, colour_r + 1) + string_char_at(_hex_digits, colour_g + 1) + string_char_at(_hex_digits, colour_b + 1);

draw_text(panel_x + 12, panel_y + 10, picker_title);

var _preview_size = 40;
var _preview_x = panel_x + panel_width - _preview_size - 12;
var _preview_y = panel_y + 10;

draw_set_colour(make_color_rgb(colour_r * 17, colour_g * 17, colour_b * 17));
draw_rectangle(_preview_x, _preview_y, _preview_x + _preview_size, _preview_y + _preview_size, false);
draw_set_colour(c_white);
draw_rectangle(_preview_x, _preview_y, _preview_x + _preview_size, _preview_y + _preview_size, true);
draw_text(panel_x + 12, panel_y + 32, "#" + _hex_text);

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
    draw_text(slider_x - 18, _slider_y, _label);

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
    draw_text(slider_x + slider_width + 4, _slider_y, string_char_at(_hex_digits, _selected + 1));

    _channel += 1;
}

draw_set_colour(c_olive);
draw_rectangle(close_button_x, close_button_y, close_button_x + close_button_width, close_button_y + close_button_height, false);
draw_set_colour(c_white);
draw_rectangle(close_button_x, close_button_y, close_button_x + close_button_width, close_button_y + close_button_height, true);
draw_text(close_button_x + 8, close_button_y + 4, "Close");
