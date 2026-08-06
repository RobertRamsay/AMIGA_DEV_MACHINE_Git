/// @desc scr_colour_picker_open(_target_instance_id, _target_variable_name, _target_array_index, _title)
/// Opens the universal RGB colour picker against any instance's hex-colour
/// variable — a plain instance variable when _target_array_index is -1, or
/// that slot within a named array variable otherwise (e.g. one band inside
/// a COPPER_BAR node's macro_cprbar_bands). Pre-loads the sliders from
/// whatever hex value is already there. Committing writes back through the
/// exact same path, handled inside obj_colour_picker itself.
function scr_colour_picker_open(_target_instance_id, _target_variable_name, _target_array_index, _title) {
    var _new_picker = instance_create_layer(0, 0, "Instances", obj_colour_picker);
    _new_picker.target_instance_id = _target_instance_id;
    _new_picker.target_variable_name = _target_variable_name;
    _new_picker.target_array_index = _target_array_index;
    _new_picker.picker_title = _title;

    var _current_hex = "";

    if (_target_array_index == -1) {
        _current_hex = variable_instance_get(_target_instance_id, _target_variable_name);
    } else {
        var _source_array = variable_instance_get(_target_instance_id, _target_variable_name);
        _current_hex = _source_array[_target_array_index];
    }

    if (scr_is_valid_hex_colour(_current_hex)) {
        // Left-pad to 3 digits so a colour typed/stored as e.g. "F0" maps
        // its digits onto R/G/B in the expected order.
        while (string_length(_current_hex) < 3) {
            _current_hex = "0" + _current_hex;
        }

        _new_picker.colour_r = scr_hex_string_to_number(string_copy(_current_hex, 1, 1));
        _new_picker.colour_g = scr_hex_string_to_number(string_copy(_current_hex, 2, 1));
        _new_picker.colour_b = scr_hex_string_to_number(string_copy(_current_hex, 3, 1));
    }

    return _new_picker;
}
