// Screen-space draw position — world position plus current pan offset.
// node_y already reflects any live wedge-preview shift directly, since
// that's a real position mutation now, not a separate render-only offset.
var _dx = node_x + global.pan_x;
var _dy = node_y + global.pan_y;

var _body_colour = node_colour;

if (is_macro) {
    _body_colour = make_color_rgb(120, 60, 160);
}

draw_set_colour(_body_colour);
draw_rectangle(_dx + 1, _dy + 1, _dx + node_width - 1, _dy + node_height - 1, false);

draw_set_colour(c_white);
draw_rectangle(_dx + 1, _dy + 1, _dx + node_width - 1, _dy + node_height - 1, true);

var _header_text = scr_opcode_display_label(opcode_mnemonic);

if (opcode_size != "") {
    _header_text += "." + opcode_size;
}

if (is_macro) {
    _header_text = "MACRO: " + macro_type;
}

draw_text(_dx + 6, _dy, _header_text);

var _label_display_text = node_label;

if (operand_editing_slot == "node_label") {
    _label_display_text = operand_edit_text;
}

if (_label_display_text != "") {
    draw_set_colour(c_yellow);
    draw_text(_dx + node_width + 6, _dy + 2, _label_display_text);
    draw_set_colour(c_white);
}

var _labWidth=140;

if (operand_editing_slot == "node_label") {
    var _pulse_t = (sin(current_time * 0.006) + 1) / 2;
    var _pulse_colour = merge_colour(c_black, c_yellow, _pulse_t);
    var _pulse_grow = _pulse_t * 3;

    draw_set_colour( merge_colour(c_dkgray, _pulse_colour, 0.3));
	draw_rectangle(_dx + node_width + 4 - _pulse_grow, _dy - _pulse_grow, _dx + node_width + _labWidth + _pulse_grow, _dy + 20 + _pulse_grow, false);
	draw_set_colour(_pulse_colour);
    draw_rectangle(_dx + node_width + 4 - _pulse_grow, _dy - _pulse_grow, _dx + node_width + _labWidth + _pulse_grow, _dy + 20 + _pulse_grow, true);
    draw_set_colour(c_white);
}

if (is_macro) {
    var _asset_field_dx = node_x + global.pan_x;
    var _asset_field_dy = node_y + global.pan_y + 20;

    var _asset_field_colour = c_dkgray;

    if (operand_editing_slot == "macro_asset") {
        _asset_field_colour = c_olive;
    }

    draw_set_colour(_asset_field_colour);
    draw_rectangle(_asset_field_dx, _asset_field_dy, _asset_field_dx + node_width, _asset_field_dy + 20, false);
    draw_set_colour(c_white);

    var _asset_field_text = "ASSET: " + macro_asset_name;

    if (operand_editing_slot == "macro_asset") {
        _asset_field_text = "ASSET: " + operand_edit_text;
    }

    draw_text(_asset_field_dx + 4, _asset_field_dy + 2, _asset_field_text);

    var _asset_for_info = scr_asset_find_by_name(macro_asset_name);
    var _info_text = "asset not found";

    if (_asset_for_info != undefined) {
        if (_asset_for_info.type == "COPPER_BAR") {
            _info_text = string(array_length(_asset_for_info.bands)) + " colour bands";
        } else if (_asset_for_info.type == "SPRITE") {
            _info_text = "sprite: ch" + string(_asset_for_info.channel) + ", " + string(_asset_for_info.height) + " rows";
        } else {
            _info_text = _asset_for_info.type + " asset";
        }
    }

    draw_text(_asset_field_dx + 4, _asset_field_dy + 24, _info_text);
} else {
    var _mode_src_dx = mode_button_src_x + global.pan_x;
    var _mode_src_dy = mode_button_src_y + global.pan_y;
    var _mode_dst_dx = mode_button_dst_x + global.pan_x;
    var _mode_dst_dy = mode_button_dst_y + global.pan_y;

    var _entry_for_draw = global.opcode_map[$ opcode_mnemonic];

    if (_entry_for_draw != undefined) {
        var _mode_zone_width = mode_button_width - value_box_width;

        if (_entry_for_draw.operand_count >= 1) {
            draw_set_colour(c_dkgray);
            draw_rectangle(_mode_src_dx, _mode_src_dy, _mode_src_dx + _mode_zone_width, _mode_src_dy + mode_button_height, false);
            draw_set_colour(c_white);
            draw_text(_mode_src_dx + 4, _mode_src_dy, addressing_mode_src);

            var _src_value_colour = c_dkgray;

            if (operand_editing_slot == "src") {
                _src_value_colour = c_olive;
            }

            draw_set_colour(_src_value_colour);
            draw_rectangle(_mode_src_dx + _mode_zone_width, _mode_src_dy, _mode_src_dx + mode_button_width, _mode_src_dy + mode_button_height, false);
            draw_set_colour(c_white);

            var _src_is_register_display = scr_operand_mode_uses_register_index(addressing_mode_src);
            var _src_value_text = string(operand_src);

            if (global.value_display_mode == "HEX" && !_src_is_register_display) {
                _src_value_text = "$" + scr_number_to_hex_string(operand_src);
            }

            if (addressing_mode_src == "LABEL") {
                _src_value_text = operand_label_src;
            }

            if (operand_editing_slot == "src") {
                _src_value_text = operand_edit_text;
            }

            draw_set_halign(fa_right);
            draw_text(_mode_src_dx + mode_button_width - 4, _mode_src_dy, _src_value_text);
            draw_set_halign(fa_left);
        }

        if (_entry_for_draw.operand_count >= 2) {
            draw_set_colour(c_dkgray);
            draw_rectangle(_mode_dst_dx, _mode_dst_dy, _mode_dst_dx + _mode_zone_width, _mode_dst_dy + mode_button_height, false);
            draw_set_colour(c_white);
            draw_text(_mode_dst_dx + 4, _mode_dst_dy, addressing_mode_dst);

            var _dst_value_colour = c_dkgray;

            if (operand_editing_slot == "dst") {
                _dst_value_colour = c_olive;
            }

            draw_set_colour(_dst_value_colour);
            draw_rectangle(_mode_dst_dx + _mode_zone_width, _mode_dst_dy, _mode_dst_dx + mode_button_width, _mode_dst_dy + mode_button_height, false);
            draw_set_colour(c_white);

            var _dst_is_register_display = scr_operand_mode_uses_register_index(addressing_mode_dst);
            var _dst_value_text = string(operand_dst);

            if (global.value_display_mode == "HEX" && !_dst_is_register_display) {
                _dst_value_text = "$" + scr_number_to_hex_string(operand_dst);
            }

            if (addressing_mode_dst == "LABEL") {
                _dst_value_text = operand_label_dst;
            }

            if (operand_editing_slot == "dst") {
                _dst_value_text = operand_edit_text;
            }

            draw_set_halign(fa_right);
            draw_text(_mode_dst_dx + mode_button_width - 4, _mode_dst_dy, _dst_value_text);
            draw_set_halign(fa_left);
        }
    }
}

var _src_colour = c_lime;
var _dst_colour = c_lime;

if (!slot_src_is_valid) {
    _src_colour = c_red;
}

if (!slot_dst_is_valid) {
    _dst_colour = c_red;
}

draw_set_colour(_src_colour);
draw_circle(src_validity_dot.dot_x + global.pan_x, src_validity_dot.dot_y + global.pan_y, 5, false);

draw_set_colour(_dst_colour);
draw_circle(dst_validity_dot.dot_x + global.pan_x, dst_validity_dot.dot_y + global.pan_y, 5, false);

draw_set_colour(c_white);

if (is_connected) {
    draw_set_colour(c_yellow);
    draw_line_width(_dx + (node_width / 2), _dy, _dx + (node_width / 2), _dy - 6, 3);
    draw_set_colour(c_white);
}

if (wedge_target_found && is_dragging) {
    draw_set_colour(c_yellow);
    draw_rectangle(_dx - 3, _dy - 3, _dx + node_width + 3, _dy + node_height + 3, true);
    draw_set_colour(c_white);
}
