/// @desc obj_cprbar_editor Step
if (!instance_exists(target_node_id)) {
    instance_destroy();
    exit;
}

// A colour picker opened on top of us for one band — let it have the
// clicks until it closes.
if (instance_exists(obj_colour_picker)) {
    exit;
}

if (mouse_check_button_pressed(mb_left)) {
    if (point_in_rectangle(mouse_x, mouse_y, band_count_minus_x, row_band_count_y, band_count_minus_x + stepper_width, row_band_count_y + stepper_height)) {
        target_node_id.macro_cprbar_band_count = clamp(target_node_id.macro_cprbar_band_count - 1, 1, 16);
    }

    if (point_in_rectangle(mouse_x, mouse_y, band_count_plus_x, row_band_count_y, band_count_plus_x + stepper_width, row_band_count_y + stepper_height)) {
        target_node_id.macro_cprbar_band_count = clamp(target_node_id.macro_cprbar_band_count + 1, 1, 16);
    }

    if (point_in_rectangle(mouse_x, mouse_y, target_register_minus_x, row_target_register_y, target_register_minus_x + stepper_width, row_target_register_y + stepper_height)) {
        target_node_id.macro_cprbar_target_register = clamp(target_node_id.macro_cprbar_target_register - 1, 0, 31);
    }

    if (point_in_rectangle(mouse_x, mouse_y, target_register_plus_x, row_target_register_y, target_register_plus_x + stepper_width, row_target_register_y + stepper_height)) {
        target_node_id.macro_cprbar_target_register = clamp(target_node_id.macro_cprbar_target_register + 1, 0, 31);
    }

    if (point_in_rectangle(mouse_x, mouse_y, equidistant_toggle_x, row_equidistant_y, equidistant_toggle_x + equidistant_toggle_width, row_equidistant_y + equidistant_toggle_height)) {
        target_node_id.macro_cprbar_equidistant = !target_node_id.macro_cprbar_equidistant;
    }

    if (!target_node_id.macro_cprbar_equidistant) {
        if (point_in_rectangle(mouse_x, mouse_y, vp_start_minus_x, row_vp_y, vp_start_minus_x + stepper_width, row_vp_y + stepper_height)) {
            target_node_id.macro_cprbar_vp_start = clamp(target_node_id.macro_cprbar_vp_start - 4, 0, 300);
        }

        if (point_in_rectangle(mouse_x, mouse_y, vp_start_plus_x, row_vp_y, vp_start_plus_x + stepper_width, row_vp_y + stepper_height)) {
            target_node_id.macro_cprbar_vp_start = clamp(target_node_id.macro_cprbar_vp_start + 4, 0, 300);
        }

        if (point_in_rectangle(mouse_x, mouse_y, vp_end_minus_x, row_vp_y, vp_end_minus_x + stepper_width, row_vp_y + stepper_height)) {
            target_node_id.macro_cprbar_vp_end = clamp(target_node_id.macro_cprbar_vp_end - 4, 0, 300);
        }

        if (point_in_rectangle(mouse_x, mouse_y, vp_end_plus_x, row_vp_y, vp_end_plus_x + stepper_width, row_vp_y + stepper_height)) {
            target_node_id.macro_cprbar_vp_end = clamp(target_node_id.macro_cprbar_vp_end + 4, 0, 300);
        }
    }

    var _swatch_index = 0;

    while (_swatch_index < target_node_id.macro_cprbar_band_count) {
        var _col = _swatch_index mod swatch_columns;
        var _row = _swatch_index div swatch_columns;
        var _swatch_x = swatch_area_x + _col * (swatch_size + swatch_gap);
        var _swatch_y = swatch_area_y + _row * (swatch_size + swatch_gap);

        if (point_in_rectangle(mouse_x, mouse_y, _swatch_x, _swatch_y, _swatch_x + swatch_size, _swatch_y + swatch_size)) {
            scr_colour_picker_open(target_node_id, "macro_cprbar_bands", _swatch_index, "Band " + string(_swatch_index + 1) + " colour");
        }

        _swatch_index += 1;
    }

    if (point_in_rectangle(mouse_x, mouse_y, close_button_x, close_button_y, close_button_x + close_button_width, close_button_y + close_button_height)) {
        instance_destroy();
    }
}

if (keyboard_check_pressed(vk_escape)) {
    instance_destroy();
}
