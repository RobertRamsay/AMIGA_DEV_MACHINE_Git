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

if (mouse_check_button_pressed(mb_left)) {
    var _recent_index = 0;
    var _recent_count = array_length(global.colour_picker_recent_hex);

    while (_recent_index < _recent_count) {
        var _recent_x = recent_row_x + (_recent_index * (recent_swatch_width + recent_swatch_gap));

        if (point_in_rectangle(mouse_x, mouse_y, _recent_x, recent_row_y, _recent_x + recent_swatch_width, recent_row_y + recent_swatch_height)) {
            var _recalled_hex = global.colour_picker_recent_hex[_recent_index];

            colour_r = scr_hex_string_to_number(string_copy(_recalled_hex, 1, 1));
            colour_g = scr_hex_string_to_number(string_copy(_recalled_hex, 2, 1));
            colour_b = scr_hex_string_to_number(string_copy(_recalled_hex, 3, 1));
        }

        _recent_index += 1;
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

        // Remove any existing copy of this colour first so re-picking a
        // recent colour bumps it back to the front instead of duplicating.
        var _existing_index = -1;
        var _search_index = 0;
        var _search_count = array_length(global.colour_picker_recent_hex);

        while (_search_index < _search_count) {
            if (global.colour_picker_recent_hex[_search_index] == _hex_text) {
                _existing_index = _search_index;
            }

            _search_index += 1;
        }

        if (_existing_index != -1) {
            array_delete(global.colour_picker_recent_hex, _existing_index, 1);
        }

        array_insert(global.colour_picker_recent_hex, 0, _hex_text);

        if (array_length(global.colour_picker_recent_hex) > 8) {
            array_delete(global.colour_picker_recent_hex, 8, array_length(global.colour_picker_recent_hex) - 8);
        }

        scr_set_status_message("Colour set: #" + _hex_text);
    }

    instance_destroy();
} else if (_should_cancel) {
    scr_set_status_message("Colour edit cancelled.");
    instance_destroy();
}
