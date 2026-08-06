/// @desc obj_cprbar_editor Draw
if (!instance_exists(target_node_id)) {
    exit;
}

draw_set_alpha(0.75);
draw_rectangle_colour(0, 0, room_width, room_height, c_black, c_black, c_black, c_black, false);
draw_set_alpha(1);

draw_set_colour(c_dkgray);
draw_rectangle(panel_x, panel_y, panel_x + panel_width, panel_y + panel_height, false);
draw_set_colour(c_white);
draw_rectangle(panel_x, panel_y, panel_x + panel_width, panel_y + panel_height, true);

draw_text(panel_x + 16, panel_y + 12, "COPPER_BAR macro");

// Band count
draw_set_colour(c_white);
draw_text(panel_x + 20, row_band_count_y + 4, "Bands:");
scr_draw_stepper_button(band_count_minus_x, row_band_count_y, stepper_width, stepper_height, "-");
draw_text(band_count_minus_x + stepper_width + 12, row_band_count_y + 4, string(target_node_id.macro_cprbar_band_count) + " / 16");
scr_draw_stepper_button(band_count_plus_x, row_band_count_y, stepper_width, stepper_height, "+");

// Target register
draw_set_colour(c_white);
draw_text(panel_x + 20, row_target_register_y + 4, "Target:");
scr_draw_stepper_button(target_register_minus_x, row_target_register_y, stepper_width, stepper_height, "-");

var _register_text = "COLOR" + string(target_node_id.macro_cprbar_target_register);

if (target_node_id.macro_cprbar_target_register < 10) {
    _register_text = "COLOR0" + string(target_node_id.macro_cprbar_target_register);
}

draw_set_colour(c_white);
draw_text(target_register_minus_x + stepper_width + 12, row_target_register_y + 4, _register_text);
scr_draw_stepper_button(target_register_plus_x, row_target_register_y, stepper_width, stepper_height, "+");

// Equidistant toggle
draw_set_colour(c_white);
draw_text(panel_x + 20, row_equidistant_y + 4, "Equidistant:");

var _equidistant_text = "NO";

if (target_node_id.macro_cprbar_equidistant) {
    _equidistant_text = "YES";
}

draw_set_colour(c_olive);
draw_rectangle(equidistant_toggle_x, row_equidistant_y, equidistant_toggle_x + equidistant_toggle_width, row_equidistant_y + equidistant_toggle_height, false);
draw_set_colour(c_white);
draw_rectangle(equidistant_toggle_x, row_equidistant_y, equidistant_toggle_x + equidistant_toggle_width, row_equidistant_y + equidistant_toggle_height, true);
draw_text(equidistant_toggle_x + 10, row_equidistant_y + 4, _equidistant_text);

// VP range — shown either way, dimmed and inert while equidistant since
// the full-height range is used automatically instead.
var _vp_row_colour = c_white;

if (target_node_id.macro_cprbar_equidistant) {
    _vp_row_colour = c_gray;
}

draw_set_colour(_vp_row_colour);
draw_text(panel_x + 20, row_vp_y + 4, "VP range:");

scr_draw_stepper_button(vp_start_minus_x, row_vp_y, stepper_width, stepper_height, "-");
draw_set_colour(_vp_row_colour);
draw_text(vp_start_minus_x + stepper_width + 6, row_vp_y + 4, string(target_node_id.macro_cprbar_vp_start));
scr_draw_stepper_button(vp_start_plus_x, row_vp_y, stepper_width, stepper_height, "+");

draw_set_colour(_vp_row_colour);
draw_text(vp_end_minus_x - 20, row_vp_y + 4, "to");

scr_draw_stepper_button(vp_end_minus_x, row_vp_y, stepper_width, stepper_height, "-");
draw_set_colour(_vp_row_colour);
draw_text(vp_end_minus_x + stepper_width + 6, row_vp_y + 4, string(target_node_id.macro_cprbar_vp_end));
scr_draw_stepper_button(vp_end_plus_x, row_vp_y, stepper_width, stepper_height, "+");

// Band rows — all 16 always shown, no gap between them so the strip reads
// as a rough vertical preview of the actual raster bar. Only the first
// band_count are active (bright label, clickable); the rest sit dimmed.
var _swatch_index = 0;

while (_swatch_index < 16) {
    var _row_y = swatch_area_y + (_swatch_index * swatch_row_height);
    var _is_active = _swatch_index < target_node_id.macro_cprbar_band_count;
    var _band_hex = target_node_id.macro_cprbar_bands[_swatch_index];
    var _swatch_colour = c_black;

    if (scr_is_valid_hex_colour(_band_hex)) {
        var _padded_hex = _band_hex;

        while (string_length(_padded_hex) < 3) {
            _padded_hex = "0" + _padded_hex;
        }

        var _r = scr_hex_string_to_number(string_copy(_padded_hex, 1, 1));
        var _g = scr_hex_string_to_number(string_copy(_padded_hex, 2, 1));
        var _b = scr_hex_string_to_number(string_copy(_padded_hex, 3, 1));
        _swatch_colour = make_color_rgb(_r * 17, _g * 17, _b * 17);
    }

    draw_set_colour(_swatch_colour);
    draw_rectangle(swatch_bar_x, _row_y, swatch_bar_x + swatch_bar_width, _row_y + swatch_row_height, false);

    var _label_text_colour = c_gray;

    if (_is_active) {
        _label_text_colour = c_white;
    }

    draw_set_colour(_label_text_colour);
    draw_text(swatch_label_x, _row_y + 2, "< EDIT COL " + string(_swatch_index + 1));

    _swatch_index += 1;
}

draw_set_colour(c_white);
draw_rectangle(swatch_bar_x, swatch_area_y, swatch_bar_x + swatch_bar_width, swatch_area_y + (16 * swatch_row_height), true);

draw_set_colour(c_olive);
draw_rectangle(close_button_x, close_button_y, close_button_x + close_button_width, close_button_y + close_button_height, false);
draw_set_colour(c_white);
draw_rectangle(close_button_x, close_button_y, close_button_x + close_button_width, close_button_y + close_button_height, true);
draw_text(close_button_x + 8, close_button_y + 4, "Close");
