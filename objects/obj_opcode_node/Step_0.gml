// World-space mouse — mouse minus the current pan offset, since node_x/node_y
// are always stored in true world space regardless of how far the view has panned.
var _world_mouse_x = mouse_x - global.pan_x;
var _world_mouse_y = mouse_y - global.pan_y;

// Validity dot positions — sit outside the node's left edge, clear of the value text
src_validity_dot.dot_x = node_x - 12;
src_validity_dot.dot_y = node_y + 30;
dst_validity_dot.dot_x = node_x - 12;
dst_validity_dot.dot_y = node_y + 50;

// Dragging — matches C64DM's actual mechanism: detach the INSTANT any real
// movement happens (not a threshold), and every frame restore all wedge
// shifts then recompute fresh (real position mutation, not a render-only
// offset). Order is never stored as a link — it's always just Y-position.
if (is_dragging) {
    depth = -1000;

    var _new_x = _world_mouse_x + drag_offset_x;
    var _new_y = _world_mouse_y + drag_offset_y;

    if ((_new_x != node_x || _new_y != node_y) && !was_dragged) {
        was_dragged = true;

        var _old_root_uid = root_uid;
        var _old_y = node_y;

        is_connected = false;
        root_uid = -1;

        if (_old_root_uid != -1) {
            scr_amiga_close_gap_after_detach(id, _old_root_uid, _old_y);
        }
    }

    node_x = _new_x;
    node_y = _new_y;

    scr_amiga_restore_wedge_shifts();

    wedge_target_found = false;

    if (was_dragged) {
        var _insert_result = scr_amiga_find_insert_point(id, node_x, node_y);

        wedge_target_found = _insert_result.found;
        wedge_target_root_uid = _insert_result.root_uid;
        wedge_target_y = _insert_result.insert_y;
        wedge_target_anchor_x = _insert_result.anchor_x;

        if (wedge_target_found) {
            scr_amiga_apply_wedge_preview(id, wedge_target_root_uid, wedge_target_y);
        }
    }

    if (mouse_check_button_released(mb_left)) {
        is_dragging = false;
        depth = 0;

        scr_amiga_restore_wedge_shifts();

        if (was_dragged) {
            node_x = scr_snap_to_grid(node_x, global.grid_size);
            node_y = scr_snap_to_grid(node_y, global.grid_size);

            var _final_insert = scr_amiga_find_insert_point(id, node_x, node_y);

            if (_final_insert.found) {
                scr_amiga_commit_insert(id, _final_insert.root_uid, _final_insert.insert_y, _final_insert.anchor_x);
            } else {
                is_connected = false;
                root_uid = -1;

                var _would_overlap = scr_check_node_overlap(id, node_x, node_y);

                if (_would_overlap) {
                    node_x = scr_snap_to_grid(node_x + node_width, global.grid_size);
                }
            }
        }

        was_dragged = false;
        wedge_target_found = false;
    }
} else {
    var _over_body = point_in_rectangle(_world_mouse_x, _world_mouse_y, node_x, node_y, node_x + node_width, node_y + node_height);

    if (_over_body && mouse_check_button_pressed(mb_left) && !global.left_click_pickup_handled_this_frame) {
        global.left_click_pickup_handled_this_frame = true;

        scr_push_undo_snapshot();

        was_dragged = false;
        is_dragging = true;
        drag_offset_x = node_x - _world_mouse_x;
        drag_offset_y = node_y - _world_mouse_y;
        is_selected = true;
    }

    if (_over_body && mouse_check_button_released(mb_right) && !global.right_click_delete_handled_this_frame) {
        global.right_click_delete_handled_this_frame = true;

        scr_push_undo_snapshot();

        if (global.operand_edit_owner_uid == uid) {
            global.operand_edit_owner_uid = -1;
        }

        scr_amiga_delete_and_close_gap(id);
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
