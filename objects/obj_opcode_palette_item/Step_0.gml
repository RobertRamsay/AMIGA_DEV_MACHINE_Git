var _over_item = point_in_rectangle(mouse_x, mouse_y, palette_x, palette_y, palette_x + palette_width, palette_y + palette_height);

if (_over_item && mouse_check_button_pressed(mb_left)) {
    is_being_dragged = true;
}

if (is_being_dragged) {
    drag_ghost_x = mouse_x;
    drag_ghost_y = mouse_y;

    if (mouse_check_button_released(mb_left)) {
        var _dropped_on_canvas = point_in_rectangle(mouse_x, mouse_y, global.canvas_bounds.left, global.canvas_bounds.top, global.canvas_bounds.right, global.canvas_bounds.bottom);

        var _drop_world_x = mouse_x - global.pan_x;
        var _drop_world_y = mouse_y - global.pan_y;

         if (_dropped_on_canvas && palette_mnemonic == "ORG") {
            scr_push_undo_snapshot();
            var _new_org = instance_create_layer(_drop_world_x, _drop_world_y, "Instances", obj_amiga_root_node);
            _new_org.root_type = "ORG";
            _new_org.node_x = scr_snap_to_grid(_drop_world_x, global.grid_size);
            _new_org.node_y = scr_snap_to_grid(_drop_world_y, global.grid_size);
        }

        if (_dropped_on_canvas && palette_mnemonic == "CPRBAR") {
            scr_push_undo_snapshot();
            var _new_macro = instance_create_layer(_drop_world_x, _drop_world_y, "Instances", obj_opcode_node);
            _new_macro.node_x = scr_snap_to_grid(_drop_world_x, global.grid_size);
            _new_macro.node_y = scr_snap_to_grid(_drop_world_y, global.grid_size);
            _new_macro.node_height = 100;
            _new_macro.is_macro = true;
            _new_macro.macro_type = "COPPER_BAR";
            _new_macro.macro_asset_name = "SunriseWater";
        }

        if (_dropped_on_canvas && palette_mnemonic != "ORG" && palette_mnemonic != "CPRBAR") {
            scr_push_undo_snapshot();
            var _new_node = instance_create_layer(_drop_world_x, _drop_world_y, "Instances", obj_opcode_node);
            _new_node.node_x = scr_snap_to_grid(_drop_world_x, global.grid_size);
            _new_node.node_y = scr_snap_to_grid(_drop_world_y, global.grid_size);
            _new_node.opcode_mnemonic = palette_mnemonic;

            var _entry = global.opcode_map[$ palette_mnemonic];
            _new_node.opcode_size = scr_pick_default_size(_entry.sizes);
        }

        is_being_dragged = false;
    }
}

palette_y = base_palette_y + global.palette_scroll_y;

var _is_hovering_palette = point_in_rectangle(mouse_x, mouse_y, palette_x, palette_y, palette_x + palette_width, palette_y + palette_height);

if (_is_hovering_palette) {
    global.palette_hover_mnemonic = palette_mnemonic;
    global.palette_hover_display_label = palette_display_label;
    global.palette_hover_x = mouse_x;
    global.palette_hover_y = mouse_y;
}