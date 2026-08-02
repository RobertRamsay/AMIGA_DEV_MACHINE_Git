// World-space mouse — mouse minus the current pan offset, since node_x/node_y
// are always stored in true world space regardless of how far the view has panned.
var _world_mouse_x = mouse_x - global.pan_x;
var _world_mouse_y = mouse_y - global.pan_y;

// Validity dot positions — sit outside the node's left edge, clear of the value text
src_validity_dot.dot_x = node_x - 12;
src_validity_dot.dot_y = node_y + 30;
dst_validity_dot.dot_x = node_x - 12;
dst_validity_dot.dot_y = node_y + 50;

// Dragging — smooth (unsnapped) while held, so wedge-insert can detect
// proximity continuously instead of only landing on 20px grid steps.
// Grid-snap happens once, at release.
if (is_dragging) {
    node_x = _world_mouse_x + drag_offset_x;
    node_y = _world_mouse_y + drag_offset_y;

    scr_clear_wedge_preview();

    var _wedge_result = scr_find_nearest_wedge_point(id, node_x, node_y);

    wedge_target_found = _wedge_result.found;
    wedge_target_parent_uid = _wedge_result.parent_uid;
    wedge_target_child_uid = _wedge_result.child_uid;
    wedge_target_x = _wedge_result.wedge_x;
    wedge_target_y = _wedge_result.wedge_y;

    if (wedge_target_found) {
        scr_apply_wedge_preview(wedge_target_child_uid, node_height);
    }

    if (mouse_check_button_released(mb_left)) {
        is_dragging = false;

        node_x = scr_snap_to_grid(node_x, global.grid_size);
        node_y = scr_snap_to_grid(node_y, global.grid_size);

        scr_push_undo_snapshot();

        if (wedge_target_found) {
            scr_commit_wedge_insert(id, wedge_target_parent_uid, wedge_target_child_uid, wedge_target_x, wedge_target_y);
        } else {
            var _would_overlap = scr_check_node_overlap(id, node_x, node_y);

            if (_would_overlap) {
                node_x = grab_start_x;
                node_y = grab_start_y;
            }

            scr_try_stack_connect(id);
        }

        scr_clear_wedge_preview();
        wedge_target_found = false;
    }
} else {
    var _over_body = point_in_rectangle(_world_mouse_x, _world_mouse_y, node_x, node_y, node_x + node_width, node_y + node_height);

    if (_over_body && mouse_check_button_pressed(mb_left)) {
        scr_push_undo_snapshot();

        // Condense: whatever was below this node closes the gap and re-links
        // to whatever was above it, before this node floats free.
        scr_relink_around_node(id);

        is_dragging = true;
        drag_offset_x = node_x - _world_mouse_x;
        drag_offset_y = node_y - _world_mouse_y;
        grab_start_x = node_x;
        grab_start_y = node_y;
        is_selected = true;
        is_connected = false;
        parent_uid = -1;
    }

    if (_over_body && mouse_check_button_released(mb_right) && !global.right_click_delete_handled_this_frame) {
        global.right_click_delete_handled_this_frame = true;

        scr_push_undo_snapshot();

        if (global.operand_edit_owner_uid == uid) {
            global.operand_edit_owner_uid = -1;
        }

        scr_delete_node_and_relink(id);
    }
}

mode_button_width = node_width;
mode_button_src_x = node_x;
mode_button_src_y = node_y + 20;
mode_button_dst_x = node_x;
mode_button_dst_y = node_y + 40;

if (scr_is_branch_target_opcode(opcode_mnemonic)) {
    addressing_mode_src = "LABEL";
}

if (scr_is_dbcc_opcode(opcode_mnemonic)) {
    addressing_mode_dst = "LABEL";
}

var _entry_for_validity = global.opcode_map[$ opcode_mnemonic];

if (_entry_for_validity == undefined) {
    slot_src_is_valid = false;
    slot_dst_is_valid = false;
} else {
    if (_entry_for_validity.operand_count >= 1) {
        if (addressing_mode_src == "LABEL") {
            slot_src_is_valid = (operand_label_src != "");
        } else {
            var _src_flag = scr_addressing_mode_flag(addressing_mode_src);
            slot_src_is_valid = (_src_flag & _entry_for_validity.src_modes) != 0;
        }
    } else {
        slot_src_is_valid = true;
    }

    if (_entry_for_validity.operand_count >= 2) {
        if (addressing_mode_dst == "LABEL") {
            slot_dst_is_valid = (operand_label_dst != "");
        } else {
            var _dst_flag = scr_addressing_mode_flag(addressing_mode_dst);
            slot_dst_is_valid = (_dst_flag & _entry_for_validity.dst_modes) != 0;
        }
    } else {
        slot_dst_is_valid = true;
    }
}

var _entry_for_modes = global.opcode_map[$ opcode_mnemonic];

if (_entry_for_modes != undefined) {
    var _mode_zone_width = mode_button_width - value_box_width;

    if (_entry_for_modes.operand_count >= 1) {
        var _over_src_mode = point_in_rectangle(_world_mouse_x, _world_mouse_y, mode_button_src_x, mode_button_src_y, mode_button_src_x + _mode_zone_width, mode_button_src_y + mode_button_height);
        var _over_src_value = point_in_rectangle(_world_mouse_x, _world_mouse_y, mode_button_src_x + _mode_zone_width, mode_button_src_y, mode_button_src_x + mode_button_width, mode_button_src_y + mode_button_height);
        var _src_mode_locked = scr_is_branch_target_opcode(opcode_mnemonic);

        if (_over_src_mode && mouse_check_button_pressed(mb_left) && !_src_mode_locked) {
            scr_push_undo_snapshot();
            addressing_mode_src = scr_cycle_addressing_mode(addressing_mode_src, _entry_for_modes.src_modes);
        }

        var _can_start_src_edit = (global.operand_edit_owner_uid == -1) || (global.operand_edit_owner_uid == uid);

        if (_over_src_value && mouse_check_button_pressed(mb_left) && _can_start_src_edit) {
            global.operand_edit_owner_uid = uid;
            operand_editing_slot = "src";

            if (addressing_mode_src == "LABEL") {
                operand_edit_text = operand_label_src;
            } else {
                var _src_is_register_seed = scr_operand_mode_uses_register_index(addressing_mode_src);

                if (global.value_display_mode == "HEX" && !_src_is_register_seed) {
                    operand_edit_text = scr_number_to_hex_string(operand_src);
                } else {
                    operand_edit_text = string(operand_src);
                }
            }

            keyboard_string = "";
        }
    }

    if (_entry_for_modes.operand_count >= 2) {
        var _over_dst_mode = point_in_rectangle(_world_mouse_x, _world_mouse_y, mode_button_dst_x, mode_button_dst_y, mode_button_dst_x + _mode_zone_width, mode_button_dst_y + mode_button_height);
        var _over_dst_value = point_in_rectangle(_world_mouse_x, _world_mouse_y, mode_button_dst_x + _mode_zone_width, mode_button_dst_y, mode_button_dst_x + mode_button_width, mode_button_dst_y + mode_button_height);
        var _dst_mode_locked = scr_is_dbcc_opcode(opcode_mnemonic);

        if (_over_dst_mode && mouse_check_button_pressed(mb_left) && !_dst_mode_locked) {
            scr_push_undo_snapshot();
            addressing_mode_dst = scr_cycle_addressing_mode(addressing_mode_dst, _entry_for_modes.dst_modes);
        }

        var _can_start_dst_edit = (global.operand_edit_owner_uid == -1) || (global.operand_edit_owner_uid == uid);

        if (_over_dst_value && mouse_check_button_pressed(mb_left) && _can_start_dst_edit) {
            global.operand_edit_owner_uid = uid;
            operand_editing_slot = "dst";

            if (addressing_mode_dst == "LABEL") {
                operand_edit_text = operand_label_dst;
            } else {
                var _dst_is_register_seed = scr_operand_mode_uses_register_index(addressing_mode_dst);

                if (global.value_display_mode == "HEX" && !_dst_is_register_seed) {
                    operand_edit_text = scr_number_to_hex_string(operand_dst);
                } else {
                    operand_edit_text = string(operand_dst);
                }
            }

            keyboard_string = "";
        }
    }
}

var _label_button_x = node_x + node_width + 6;
var _label_button_y = node_y;
var _label_button_width = 80;
var _label_button_height = 20;

var _over_label_button = point_in_rectangle(_world_mouse_x, _world_mouse_y, _label_button_x, _label_button_y, _label_button_x + _label_button_width, _label_button_y + _label_button_height);
var _can_start_label_edit = (global.operand_edit_owner_uid == -1) || (global.operand_edit_owner_uid == uid);

if (_over_label_button && mouse_check_button_pressed(mb_left) && _can_start_label_edit) {
    global.operand_edit_owner_uid = uid;
    operand_editing_slot = "node_label";
    operand_edit_text = node_label;
    keyboard_string = "";
}

if (operand_editing_slot != "" && global.operand_edit_owner_uid == uid) {
    var _typed_chars = keyboard_string;
    keyboard_string = "";

    var _is_text_field = (operand_editing_slot == "node_label");

    if (operand_editing_slot == "src" && addressing_mode_src == "LABEL") {
        _is_text_field = true;
    }

    if (operand_editing_slot == "dst" && addressing_mode_dst == "LABEL") {
        _is_text_field = true;
    }

    var _uses_register_index = false;

    if (!_is_text_field) {
        _uses_register_index = scr_operand_mode_uses_register_index(addressing_mode_src);

        if (operand_editing_slot == "dst") {
            _uses_register_index = scr_operand_mode_uses_register_index(addressing_mode_dst);
        }
    }

    var _char_index = 1;
    var _typed_length = string_length(_typed_chars);

    while (_char_index <= _typed_length) {
        var _this_char = string_char_at(_typed_chars, _char_index);
        var _accept_char = false;

        if (_is_text_field) {
            var _is_letter_lower = (_this_char >= "a") && (_this_char <= "z");
            var _is_letter_upper = (_this_char >= "A") && (_this_char <= "Z");
            var _is_digit_char = (_this_char >= "0") && (_this_char <= "9");
            var _is_underscore = (_this_char == "_");

            _accept_char = _is_letter_lower || _is_letter_upper || _is_digit_char || _is_underscore;
        } else {
            var _is_hex_entry = (global.value_display_mode == "HEX") && (!_uses_register_index);

            if (_is_hex_entry) {
                var _is_hex_digit = ((_this_char >= "0") && (_this_char <= "9")) || ((_this_char >= "A") && (_this_char <= "F")) || ((_this_char >= "a") && (_this_char <= "f"));
                _accept_char = _is_hex_digit;
            } else {
                var _is_digit = (_this_char >= "0") && (_this_char <= "9");
                var _is_minus = (_this_char == "-") && (string_length(operand_edit_text) == 0) && (!_uses_register_index);

                _accept_char = _is_digit || _is_minus;
            }
        }

        if (_accept_char) {
            operand_edit_text += _this_char;
        }

        _char_index += 1;
    }

    if (keyboard_check_pressed(vk_backspace) && string_length(operand_edit_text) > 0) {
        operand_edit_text = string_copy(operand_edit_text, 1, string_length(operand_edit_text) - 1);
    }

    if (keyboard_check_pressed(vk_enter)) {
        scr_push_undo_snapshot();

        if (_is_text_field) {
            if (operand_editing_slot == "node_label") {
                node_label = operand_edit_text;
            } else {
                if (operand_editing_slot == "src") {
                    operand_label_src = operand_edit_text;
                } else {
                    operand_label_dst = operand_edit_text;
                }
            }
        } else {
            var _parsed_value = 0;
            var _is_hex_entry = (global.value_display_mode == "HEX") && (!_uses_register_index);

            if (_is_hex_entry) {
                if (string_length(operand_edit_text) > 0) {
                    _parsed_value = scr_hex_string_to_number(operand_edit_text);
                }
            } else {
                if (string_length(operand_edit_text) > 0 && operand_edit_text != "-") {
                    _parsed_value = real(operand_edit_text);
                }
            }

            if (_uses_register_index) {
                if (_parsed_value < 0) {
                    _parsed_value = 0;
                }

                if (_parsed_value > 7) {
                    _parsed_value = 7;
                }
            }

            if (operand_editing_slot == "src") {
                operand_src = _parsed_value;
            } else {
                operand_dst = _parsed_value;
            }
        }

        operand_editing_slot = "";
        global.operand_edit_owner_uid = -1;
    }

    if (keyboard_check_pressed(vk_escape)) {
        operand_editing_slot = "";
        global.operand_edit_owner_uid = -1;
    }
}
