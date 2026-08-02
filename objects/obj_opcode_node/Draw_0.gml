
draw_set_colour(node_colour);
draw_rectangle(node_x, node_y, node_x + node_width, node_y + node_height, false);

draw_set_colour(c_white);
draw_rectangle(node_x, node_y, node_x + node_width, node_y + node_height, true);

var _size_suffix_display = "";

if (opcode_size != "") {
    _size_suffix_display = "." + opcode_size;
}

draw_text(node_x + 6, node_y , scr_opcode_display_label(opcode_mnemonic) + _size_suffix_display);

var _label_display_text = node_label;

if (operand_editing_slot == "node_label") {
    _label_display_text = operand_edit_text;
}

if (_label_display_text != "") {
    draw_set_colour(c_yellow);
    draw_text(node_x + node_width + 6, node_y + 2, _label_display_text);
    draw_set_colour(c_white);
}

if (operand_editing_slot == "node_label") {
    draw_set_colour(c_olive);
    draw_rectangle(node_x + node_width + 4, node_y, node_x + node_width + 84, node_y + 20, true);
    draw_set_colour(c_white);
}

var _entry_for_draw = global.opcode_map[$ opcode_mnemonic];

if (_entry_for_draw != undefined) {
    var _mode_zone_width = mode_button_width - value_box_width;

    if (_entry_for_draw.operand_count >= 1) {
        draw_set_colour(c_dkgray);
        draw_rectangle(mode_button_src_x, mode_button_src_y, mode_button_src_x + _mode_zone_width, mode_button_src_y + mode_button_height, false);
        draw_set_colour(c_white);
        draw_text(mode_button_src_x + 4, mode_button_src_y + 2, addressing_mode_src);

        var _src_value_colour = c_dkgray;

        if (operand_editing_slot == "src") {
            _src_value_colour = c_olive;
        }

        draw_set_colour(_src_value_colour);
        draw_rectangle(mode_button_src_x + _mode_zone_width, mode_button_src_y, mode_button_src_x + mode_button_width, mode_button_src_y + mode_button_height, false);
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
        draw_text(mode_button_src_x + mode_button_width - 4, mode_button_src_y + 2, _src_value_text);
        draw_set_halign(fa_left);
    }

    if (_entry_for_draw.operand_count >= 2) {
        draw_set_colour(c_dkgray);
        draw_rectangle(mode_button_dst_x, mode_button_dst_y, mode_button_dst_x + _mode_zone_width, mode_button_dst_y + mode_button_height, false);
        draw_set_colour(c_white);
        draw_text(mode_button_dst_x + 4, mode_button_dst_y + 2, addressing_mode_dst);

        var _dst_value_colour = c_dkgray;

        if (operand_editing_slot == "dst") {
            _dst_value_colour = c_olive;
        }

        draw_set_colour(_dst_value_colour);
        draw_rectangle(mode_button_dst_x + _mode_zone_width, mode_button_dst_y, mode_button_dst_x + mode_button_width, mode_button_dst_y + mode_button_height, false);
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
        draw_text(mode_button_dst_x + mode_button_width - 4, mode_button_dst_y + 2, _dst_value_text);
        draw_set_halign(fa_left);
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
draw_circle(src_validity_dot.dot_x, src_validity_dot.dot_y, 5, false);

draw_set_colour(_dst_colour);
draw_circle(dst_validity_dot.dot_x, dst_validity_dot.dot_y, 5, false);

draw_set_colour(c_white);

if (is_connected) {
    draw_set_colour(c_yellow);
    draw_line_width(node_x + (node_width / 2), node_y, node_x + (node_width / 2), node_y - 6, 3);
    draw_set_colour(c_white);
}



