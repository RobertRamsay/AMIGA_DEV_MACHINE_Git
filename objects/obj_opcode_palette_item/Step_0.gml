var _over_item = point_in_rectangle(mouse_x, mouse_y, palette_x, palette_y, palette_x + palette_width, palette_y + palette_height);

if (_over_item && mouse_check_button_pressed(mb_left)) {
    is_being_dragged = true;
}

if (is_being_dragged) {
    drag_ghost_x = mouse_x;
    drag_ghost_y = mouse_y;

    if (mouse_check_button_released(mb_left)) {
        var _dropped_on_canvas = point_in_rectangle(mouse_x, mouse_y, global.canvas_bounds.left, global.canvas_bounds.top, global.canvas_bounds.right, global.canvas_bounds.bottom);

         if (_dropped_on_canvas && palette_mnemonic == "ORG") {
            var _new_org = instance_create_layer(mouse_x, mouse_y, "Instances", obj_amiga_root_node);
            _new_org.root_type = "ORG";
            _new_org.node_x = scr_snap_to_grid(mouse_x, global.grid_size);
            _new_org.node_y = scr_snap_to_grid(mouse_y, global.grid_size);
        }

        if (_dropped_on_canvas && palette_mnemonic != "ORG") {
            var _new_node = instance_create_layer(mouse_x, mouse_y, "Instances", obj_opcode_node);
            _new_node.node_x = scr_snap_to_grid(mouse_x, global.grid_size);
            _new_node.node_y = scr_snap_to_grid(mouse_y, global.grid_size);
            _new_node.opcode_mnemonic = palette_mnemonic;

            var _entry = global.opcode_map[$ palette_mnemonic];
            var _default_size = "W";

            if (array_length(_entry.sizes) > 0) {
                _default_size = _entry.sizes[0];
            } else {
                _default_size = "";
            }

            _new_node.opcode_size = _default_size;
        }

        is_being_dragged = false;
    }
}

palette_y = base_palette_y + global.palette_scroll_y;

var _is_hovering_palette = point_in_rectangle(mouse_x, mouse_y, palette_x, palette_y, palette_x + palette_width, palette_y + palette_height);

if (_is_hovering_palette) {
    global.palette_hover_mnemonic = palette_mnemonic;
    global.palette_hover_x = mouse_x;
    global.palette_hover_y = mouse_y;
}