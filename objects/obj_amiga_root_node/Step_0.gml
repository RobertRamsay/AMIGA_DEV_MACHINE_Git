if (instance_exists(obj_bitmap_editor) || instance_exists(obj_colour_picker)) {
    exit;
}

var _world_mouse_x = mouse_x - global.pan_x;
var _world_mouse_y = mouse_y - global.pan_y;

if (root_type == "ORG") {
    if (is_dragging) {
        var _prev_x = node_x;
        var _prev_y = node_y;

        node_x = _world_mouse_x + drag_offset_x;
        node_y = _world_mouse_y + drag_offset_y;

        var _delta_x = node_x - _prev_x;
        var _delta_y = node_y - _prev_y;

        if (_delta_x != 0 || _delta_y != 0) {
            scr_drag_children_with_root(id, _delta_x, _delta_y);
        }

        if (mouse_check_button_released(mb_left)) {
            is_dragging = false;

            var _snapped_x = scr_snap_to_grid(node_x, global.grid_size);
            var _snapped_y = scr_snap_to_grid(node_y, global.grid_size);

            var _snap_delta_x = _snapped_x - node_x;
            var _snap_delta_y = _snapped_y - node_y;

            node_x = _snapped_x;
            node_y = _snapped_y;

            if (_snap_delta_x != 0 || _snap_delta_y != 0) {
                scr_drag_children_with_root(id, _snap_delta_x, _snap_delta_y);
            }
        }
    } else {
        var _over_body = point_in_rectangle(_world_mouse_x, _world_mouse_y, node_x, node_y, node_x + node_width, node_y + node_height);

        if (_over_body && mouse_check_button_pressed(mb_left) && !global.left_click_pickup_handled_this_frame) {
            global.left_click_pickup_handled_this_frame = true;
            scr_push_undo_snapshot();
            is_dragging = true;
            drag_offset_x = node_x - _world_mouse_x;
            drag_offset_y = node_y - _world_mouse_y;
        }
    }

    continues_from_root_uid = scr_find_nearest_left_root(id);
}
