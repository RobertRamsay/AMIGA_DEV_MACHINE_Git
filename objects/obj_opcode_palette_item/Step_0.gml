if (instance_exists(obj_bitmap_editor) || instance_exists(obj_bob_editor) || instance_exists(obj_colour_picker) || instance_exists(obj_cprbar_editor)) {
    exit;
}

var _over_item = point_in_rectangle(mouse_x, mouse_y, palette_x, palette_y, palette_x + palette_width, palette_y + palette_height);

if (_over_item && mouse_check_button_pressed(mb_left) && !global.left_click_pickup_handled_this_frame) {
    global.left_click_pickup_handled_this_frame = true;

    scr_push_undo_snapshot();

    var _spawn_world_x = mouse_x - global.pan_x;
    var _spawn_world_y = mouse_y - global.pan_y;

    if (palette_mnemonic == "ORG") {
        var _new_org = instance_create_layer(_spawn_world_x, _spawn_world_y, "Instances", obj_amiga_root_node);
        _new_org.root_type = "ORG";
        _new_org.node_x = _spawn_world_x - (_new_org.node_width / 2);
        _new_org.node_y = _spawn_world_y - (_new_org.node_height / 2);
        _new_org.drag_offset_x = _new_org.node_x - _spawn_world_x;
        _new_org.drag_offset_y = _new_org.node_y - _spawn_world_y;
        _new_org.is_dragging = true;
    } else {
        var _new_node = instance_create_layer(_spawn_world_x, _spawn_world_y, "Instances", obj_opcode_node);

        if (palette_mnemonic == "CPRBAR") {
            _new_node.node_height = 100;
            _new_node.is_macro = true;
            _new_node.macro_type = "COPPER_BAR";
        } else if (palette_mnemonic == "SETBKG") {
            _new_node.node_height = 100;
            _new_node.is_macro = true;
            _new_node.macro_type = "SETBKG";
            _new_node.macro_asset_name = "000";
        } else if (palette_mnemonic == "MOVE_BOB" || palette_mnemonic == "MOVE_SPR") {
            _new_node.node_height = 100;
            _new_node.is_macro = true;
            _new_node.macro_type = palette_mnemonic;
            _new_node.macro_object_id = 0;
            _new_node.macro_speed_x = 1;
            _new_node.macro_speed_y = 0;
        } else if (palette_mnemonic == "ANIM_BOB" || palette_mnemonic == "ANIM_SPR") {
            _new_node.node_height = 120;
            _new_node.is_macro = true;
            _new_node.macro_type = palette_mnemonic;
            _new_node.macro_object_id = 0;
            _new_node.macro_anim_rate = 8;
            _new_node.macro_anim_start = 0;
            var _frame_type = palette_mnemonic == "ANIM_BOB" ? "BOB" : "SPRITE";
            var _frame_count = 0;
            var _asset_i = 0;
            while (_asset_i < array_length(global.asset_list)) {
                if (global.asset_list[_asset_i].type == _frame_type) _frame_count += 1;
                _asset_i += 1;
            }
            _new_node.macro_anim_end = max(0, _frame_count - 1);
            _new_node.macro_anim_loop = true;
        } else {
            _new_node.opcode_mnemonic = palette_mnemonic;

            var _entry = global.opcode_map[$ palette_mnemonic];
            _new_node.opcode_size = scr_pick_default_size(_entry.sizes);
        }

        _new_node.node_x = _spawn_world_x - (_new_node.node_width / 2);
        _new_node.node_y = _spawn_world_y - (_new_node.node_height / 2);
        _new_node.drag_offset_x = _new_node.node_x - _spawn_world_x;
        _new_node.drag_offset_y = _new_node.node_y - _spawn_world_y;
        _new_node.is_selected = true;

        // Brand new — nothing to detach from, so skip straight past the
        // "first movement" origin-close step and go directly into live
        // wedge detection, exactly like an existing node mid-drag.
        _new_node.was_dragged = true;
        _new_node.is_dragging = true;
    }
}

// Top-strip entries are fixed controls, not part of the scrolling opcode list.
if (palette_mnemonic == "ORG" || palette_mnemonic == "CPRBAR" || palette_mnemonic == "SETBKG" || palette_mnemonic == "MOVE_BOB" || palette_mnemonic == "MOVE_SPR" || palette_mnemonic == "ANIM_BOB" || palette_mnemonic == "ANIM_SPR") {
    palette_y = base_palette_y;
} else {
    palette_y = base_palette_y + global.palette_scroll_y;
}
