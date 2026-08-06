/// @desc obj_colour_picker Step
/// Modal — sliders write straight into colour_r/g/b, closing (the Close
/// button or Enter) commits the combined hex value back onto whichever
/// node opened this picker and destroys it. Right-click or Escape cancels
/// without committing, matching the label/operand edit convention used
/// elsewhere on nodes.
if (mouse_check_button(mb_left)) {
    var _slider_value = clamp(floor((mouse_x - slider_x) / slider_step_width), 0, 15);

    if (point_in_rectangle(mouse_x, mouse_y, slider_x, slider_r_y, slider_x + slider_width, slider_r_y + slider_height)) {
        colour_r = _slider_value;
    }

    if (point_in_rectangle(mouse_x, mouse_y, slider_x, slider_g_y, slider_x + slider_width, slider_g_y + slider_height)) {
        colour_g = _slider_value;
    }

    if (point_in_rectangle(mouse_x, mouse_y, slider_x, slider_b_y, slider_x + slider_width, slider_b_y + slider_height)) {
        colour_b = _slider_value;
    }
}

var _over_close_button = point_in_rectangle(mouse_x, mouse_y, close_button_x, close_button_y, close_button_x + close_button_width, close_button_y + close_button_height);
var _should_commit = false;

if (_over_close_button && mouse_check_button_pressed(mb_left)) {
    _should_commit = true;
}

if (keyboard_check_pressed(vk_enter)) {
    _should_commit = true;
}

var _should_cancel = false;

if (keyboard_check_pressed(vk_escape) || mouse_check_button_pressed(mb_right)) {
    _should_cancel = true;
}

if (_should_commit) {
    var _hex_digits = "0123456789ABCDEF";
    var _hex_text = string_char_at(_hex_digits, colour_r + 1) + string_char_at(_hex_digits, colour_g + 1) + string_char_at(_hex_digits, colour_b + 1);

    if (instance_exists(target_instance_id)) {
        scr_push_undo_snapshot();

        if (target_array_index == -1) {
            variable_instance_set(target_instance_id, target_variable_name, _hex_text);
        } else {
            var _target_array = variable_instance_get(target_instance_id, target_variable_name);
            _target_array[@ target_array_index] = _hex_text;
        }

        scr_set_status_message("Colour set: #" + _hex_text);
    }

    instance_destroy();
} else if (_should_cancel) {
    scr_set_status_message("Colour edit cancelled.");
    instance_destroy();
}
