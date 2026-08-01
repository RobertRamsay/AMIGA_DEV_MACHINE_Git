
draw_set_colour(node_colour);
draw_rectangle(node_x, node_y, node_x + node_width, node_y + node_height, false);

draw_set_colour(c_white);
draw_rectangle(node_x, node_y, node_x + node_width, node_y + node_height, true);

var _size_suffix_display = "";

if (opcode_size != "") {
    _size_suffix_display = "." + opcode_size;
}

draw_text(node_x + 6, node_y , opcode_mnemonic + _size_suffix_display);

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

var _entry_for_draw = global.opcode_map[$ opcode_mnemonic];

if (_entry_for_draw != undefined) {
    if (_entry_for_draw.operand_count >= 1) {
        draw_set_colour(c_dkgray);
        draw_rectangle(mode_button_src_x, mode_button_src_y, mode_button_src_x + mode_button_width, mode_button_src_y + mode_button_height, false);
        draw_set_colour(c_white);
		
        draw_text(mode_button_src_x + 4, mode_button_src_y + 2, addressing_mode_src);
    }

    if (_entry_for_draw.operand_count >= 2) {
        draw_set_colour(c_dkgray);
        draw_rectangle(mode_button_dst_x, mode_button_dst_y, mode_button_dst_x + mode_button_width, mode_button_dst_y + mode_button_height, false);
        draw_set_colour(c_white);
		
        draw_text(mode_button_dst_x + 4, mode_button_dst_y + 2, addressing_mode_dst)
    }
}


