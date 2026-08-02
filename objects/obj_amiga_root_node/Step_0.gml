if (root_type == "ORG") {
    if (is_dragging) {
        var _raw_x = mouse_x + drag_offset_x;
        var _raw_y = mouse_y + drag_offset_y;

        node_x = scr_snap_to_grid(_raw_x, global.grid_size);
        node_y = scr_snap_to_grid(_raw_y, global.grid_size);

        if (mouse_check_button_released(mb_left)) {
            is_dragging = false;
        }
    } else {
        var _over_body = point_in_rectangle(mouse_x, mouse_y, node_x, node_y, node_x + node_width, node_y + node_height);

        if (_over_body && mouse_check_button_pressed(mb_left)) {
            is_dragging = true;
            drag_offset_x = node_x - mouse_x;
            drag_offset_y = node_y - mouse_y;
        }
    }

    continues_from_root_uid = scr_find_nearest_left_root(id);
}