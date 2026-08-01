// Validity dot positions — sit beside the mode bands, not the node edges
src_validity_dot.dot_x = node_x + node_width - 12;
src_validity_dot.dot_y = node_y + 30;
dst_validity_dot.dot_x = node_x + node_width - 12;
dst_validity_dot.dot_y = node_y + 50;

// Dragging — snapped to grid live, stack-connects to whatever it lands under on release
if (is_dragging) {
    var _raw_x = mouse_x + drag_offset_x;
    var _raw_y = mouse_y + drag_offset_y;

    node_x = scr_snap_to_grid(_raw_x, global.grid_size);
    node_y = scr_snap_to_grid(_raw_y, global.grid_size);

    if (mouse_check_button_released(mb_left)) {
        is_dragging = false;
        scr_try_stack_connect(id);
    }
} else {
    var _over_body = point_in_rectangle(mouse_x, mouse_y, node_x, node_y, node_x + node_width, node_y + node_height);

    if (_over_body && mouse_check_button_pressed(mb_left)) {
        is_dragging = true;
        drag_offset_x = node_x - mouse_x;
        drag_offset_y = node_y - mouse_y;
        is_selected = true;
        is_connected = false;
        parent_uid = -1;
    }
}

mode_button_width = node_width;
mode_button_src_x = node_x;
mode_button_src_y = node_y + 20;
mode_button_dst_x = node_x;
mode_button_dst_y = node_y + 40;

var _entry_for_validity = global.opcode_map[$ opcode_mnemonic];

if (_entry_for_validity == undefined) {
    slot_src_is_valid = false;
    slot_dst_is_valid = false;
} else {
    if (_entry_for_validity.operand_count >= 1) {
        var _src_flag = scr_addressing_mode_flag(addressing_mode_src);
        slot_src_is_valid = (_src_flag & _entry_for_validity.src_modes) != 0;
    } else {
        slot_src_is_valid = true;
    }

    if (_entry_for_validity.operand_count >= 2) {
        var _dst_flag = scr_addressing_mode_flag(addressing_mode_dst);
        slot_dst_is_valid = (_dst_flag & _entry_for_validity.dst_modes) != 0;
    } else {
        slot_dst_is_valid = true;
    }
}

var _entry_for_modes = global.opcode_map[$ opcode_mnemonic];

if (_entry_for_modes != undefined) {
    if (_entry_for_modes.operand_count >= 1) {
        var _over_src_button = point_in_rectangle(mouse_x, mouse_y, mode_button_src_x, mode_button_src_y, mode_button_src_x + mode_button_width, mode_button_src_y + mode_button_height);

        if (_over_src_button && mouse_check_button_pressed(mb_left)) {
            addressing_mode_src = scr_cycle_addressing_mode(addressing_mode_src, _entry_for_modes.src_modes);
        }
    }

    if (_entry_for_modes.operand_count >= 2) {
        var _over_dst_button = point_in_rectangle(mouse_x, mouse_y, mode_button_dst_x, mode_button_dst_y, mode_button_dst_x + mode_button_width, mode_button_dst_y + mode_button_height);

        if (_over_dst_button && mouse_check_button_pressed(mb_left)) {
            addressing_mode_dst = scr_cycle_addressing_mode(addressing_mode_dst, _entry_for_modes.dst_modes);
        }
    }
}