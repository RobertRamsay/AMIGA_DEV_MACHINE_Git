/// @desc obj_cprbar_editor Draw
if (!instance_exists(target_node_id)) {
    exit;
}

draw_set_font(UI_FONT);
draw_set_halign(fa_left);
draw_set_valign(fa_top);

draw_set_alpha(0.75);
draw_rectangle_colour(0, 0, room_width, room_height, c_black, c_black, c_black, c_black, false);
draw_set_alpha(1);

scr_ui_box(panel_x, panel_y, panel_x + panel_width, panel_y + panel_height, make_colour_rgb(44, 48, 58), c_white);

draw_set_colour(c_white);
scr_ui_text_mid(panel_x + 16, panel_y + 8, panel_y + 32, "COPPER_BAR macro");

// Each settings row: label at the left, value centred between its steppers.
var _row_label_x = panel_x + 20;

// Band count
draw_set_colour(c_white);
scr_ui_text_mid(_row_label_x, row_band_count_y, row_band_count_y + stepper_height, "Bands:");
scr_draw_stepper_button(band_count_minus_x, row_band_count_y, stepper_width, stepper_height, "-");
scr_ui_text_centred((band_count_minus_x + stepper_width + band_count_plus_x) * 0.5, row_band_count_y + stepper_height * 0.5,
    string(target_node_id.macro_cprbar_band_count) + " / 16");
scr_draw_stepper_button(band_count_plus_x, row_band_count_y, stepper_width, stepper_height, "+");

// Target register
draw_set_colour(c_white);
scr_ui_text_mid(_row_label_x, row_target_register_y, row_target_register_y + stepper_height, "Target:");
scr_draw_stepper_button(target_register_minus_x, row_target_register_y, stepper_width, stepper_height, "-");

var _register_text = "COLOR" + string(target_node_id.macro_cprbar_target_register);

if (target_node_id.macro_cprbar_target_register < 10) {
    _register_text = "COLOR0" + string(target_node_id.macro_cprbar_target_register);
}

draw_set_colour(c_white);
scr_ui_text_centred((target_register_minus_x + stepper_width + target_register_plus_x) * 0.5, row_target_register_y + stepper_height * 0.5, _register_text);
scr_draw_stepper_button(target_register_plus_x, row_target_register_y, stepper_width, stepper_height, "+");

// Equidistant toggle
draw_set_colour(c_white);
scr_ui_text_mid(_row_label_x, row_equidistant_y, row_equidistant_y + equidistant_toggle_height, "Equidistant:");

var _equidistant_on = target_node_id.macro_cprbar_equidistant;
var _toggle_x2 = equidistant_toggle_x + equidistant_toggle_width;
var _toggle_y2 = row_equidistant_y + equidistant_toggle_height;
scr_ui_button(equidistant_toggle_x, row_equidistant_y, _toggle_x2, _toggle_y2, _equidistant_on ? "YES" : "NO",
    _equidistant_on ? c_olive : c_dkgray,
    point_in_rectangle(mouse_x, mouse_y, equidistant_toggle_x, row_equidistant_y, _toggle_x2, _toggle_y2));

// VP range — shown either way, dimmed and inert while equidistant since
// the full-height range is used automatically instead.
var _vp_enabled = !_equidistant_on;
var _vp_row_colour = _vp_enabled ? c_white : c_gray;
var _vp_mid_y = row_vp_y + stepper_height * 0.5;

draw_set_colour(_vp_row_colour);
scr_ui_text_mid(_row_label_x, row_vp_y, row_vp_y + stepper_height, "VP range:");

scr_ui_button(vp_start_minus_x, row_vp_y, vp_start_minus_x + stepper_width, row_vp_y + stepper_height, "-", c_dkgray, false, _vp_enabled);
draw_set_colour(_vp_row_colour);
scr_ui_text_centred((vp_start_minus_x + stepper_width + vp_start_plus_x) * 0.5, _vp_mid_y, string(target_node_id.macro_cprbar_vp_start));
scr_ui_button(vp_start_plus_x, row_vp_y, vp_start_plus_x + stepper_width, row_vp_y + stepper_height, "+", c_dkgray, false, _vp_enabled);

draw_set_colour(_vp_row_colour);
scr_ui_text_centred((vp_start_plus_x + stepper_width + vp_end_minus_x) * 0.5, _vp_mid_y, "to");

scr_ui_button(vp_end_minus_x, row_vp_y, vp_end_minus_x + stepper_width, row_vp_y + stepper_height, "-", c_dkgray, false, _vp_enabled);
draw_set_colour(_vp_row_colour);
scr_ui_text_centred((vp_end_minus_x + stepper_width + vp_end_plus_x) * 0.5, _vp_mid_y, string(target_node_id.macro_cprbar_vp_end));
scr_ui_button(vp_end_plus_x, row_vp_y, vp_end_plus_x + stepper_width, row_vp_y + stepper_height, "+", c_dkgray, false, _vp_enabled);

// Band rows — all 16 always shown, no gap between them so the strip reads
// as a rough vertical preview of the actual raster bar. Only the first
// band_count are active (bright label, clickable); the rest sit dimmed.
var _picker_open = instance_exists(obj_colour_picker);
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

        // Same hit area as Step: the bar plus its label.
        if (!_picker_open && point_in_rectangle(mouse_x, mouse_y, swatch_bar_x, _row_y, swatch_label_x + swatch_label_width, _row_y + swatch_row_height)) {
            _label_text_colour = c_yellow;
        }
    }

    draw_set_colour(_label_text_colour);
    scr_ui_text_mid(swatch_label_x, _row_y, _row_y + swatch_row_height, "< EDIT COL " + string(_swatch_index + 1));

    _swatch_index += 1;
}

draw_set_colour(c_white);
draw_rectangle(swatch_bar_x, swatch_area_y, swatch_bar_x + swatch_bar_width, swatch_area_y + (16 * swatch_row_height), true);

scr_ui_button(close_button_x, close_button_y, close_button_x + close_button_width, close_button_y + close_button_height, "Close", c_olive,
    !_picker_open && point_in_rectangle(mouse_x, mouse_y, close_button_x, close_button_y, close_button_x + close_button_width, close_button_y + close_button_height));
