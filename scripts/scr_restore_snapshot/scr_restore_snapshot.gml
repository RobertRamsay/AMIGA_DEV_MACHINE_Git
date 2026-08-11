/// @desc scr_restore_snapshot(_snapshot)
/// Destroys the current graph and rebuilds it from _snapshot. Original uids
/// preserve membership, then a final pass snaps and restacks the graph.
function scr_restore_snapshot(_snapshot) {
    global.operand_edit_owner_uid = -1;

    with (obj_opcode_node) {
        instance_destroy();
    }

    with (obj_amiga_root_node) {
        instance_destroy();
    }

    var _root_array = _snapshot.roots;
    var _root_count = array_length(_root_array);
    var _r = 0;

    while (_r < _root_count) {
        var _root_data = _root_array[_r];
        var _root_x = scr_snap_to_grid(_root_data.node_x, global.grid_size);
        var _root_y = scr_snap_to_grid(_root_data.node_y, global.grid_size);
        var _new_root = instance_create_layer(_root_x, _root_y, "Instances", obj_amiga_root_node);

        _new_root.uid = _root_data.uid;
        _new_root.root_type = _root_data.root_type;
        _new_root.node_x = _root_x;
        _new_root.node_y = _root_y;
        _new_root.x = _root_x;
        _new_root.y = _root_y;
        _new_root.continues_from_root_uid = _root_data.continues_from_root_uid;

        _r += 1;
    }

    var _node_array = _snapshot.nodes;
    var _node_count = array_length(_node_array);
    var _n = 0;

    while (_n < _node_count) {
        var _node_data = _node_array[_n];
        var _new_node = instance_create_layer(_node_data.node_x, _node_data.node_y, "Instances", obj_opcode_node);

        _new_node.uid = _node_data.uid;
        _new_node.node_x = _node_data.node_x;
        _new_node.node_y = _node_data.node_y;
        _new_node.node_width = _node_data.node_width;
        _new_node.node_height = _node_data.node_height;
        _new_node.is_connected = _node_data.is_connected;
        _new_node.root_uid = _node_data.root_uid;
        _new_node.is_macro = _node_data.is_macro;
        _new_node.macro_type = _node_data.macro_type;
        _new_node.macro_asset_name = _node_data.macro_asset_name;
        if (variable_struct_exists(_node_data, "macro_object_id")) _new_node.macro_object_id = _node_data.macro_object_id;
        if (variable_struct_exists(_node_data, "macro_speed_x")) _new_node.macro_speed_x = _node_data.macro_speed_x;
        if (variable_struct_exists(_node_data, "macro_speed_y")) _new_node.macro_speed_y = _node_data.macro_speed_y;
        if (variable_struct_exists(_node_data, "macro_anim_rate")) _new_node.macro_anim_rate = _node_data.macro_anim_rate;
        if (variable_struct_exists(_node_data, "macro_anim_start")) _new_node.macro_anim_start = _node_data.macro_anim_start;
        if (variable_struct_exists(_node_data, "macro_anim_end")) _new_node.macro_anim_end = _node_data.macro_anim_end;
        if (variable_struct_exists(_node_data, "macro_anim_loop")) _new_node.macro_anim_loop = _node_data.macro_anim_loop;
        _new_node.preview_collapsed = _node_data.preview_collapsed;
        _new_node.opcode_mnemonic = _node_data.opcode_mnemonic;
        _new_node.opcode_size = _node_data.opcode_size;
        _new_node.addressing_mode_src = _node_data.addressing_mode_src;
        _new_node.addressing_mode_dst = _node_data.addressing_mode_dst;
        _new_node.operand_src = _node_data.operand_src;
        _new_node.operand_dst = _node_data.operand_dst;
        _new_node.operand_label_src = _node_data.operand_label_src;
        _new_node.operand_label_dst = _node_data.operand_label_dst;
        _new_node.node_label = _node_data.node_label;

        _new_node.operand_extra_src.displacement = _node_data.displacement_src;
        _new_node.operand_extra_src.index_register = _node_data.index_register_src;
        _new_node.operand_extra_src.index_register_is_address = _node_data.index_register_is_address_src;

        _new_node.operand_extra_dst.displacement = _node_data.displacement_dst;
        _new_node.operand_extra_dst.index_register = _node_data.index_register_dst;
        _new_node.operand_extra_dst.index_register_is_address = _node_data.index_register_is_address_dst;

        _n += 1;
    }

    // A snapshot may be captured while a drag or wedge preview is active.
    // Rebuild connected stacks from their roots and snap loose nodes.
    with (obj_amiga_root_node) {
        var _stack_root_uid = uid;
        var _stack_x = scr_snap_to_grid(node_x, global.grid_size);
        var _stack_y = scr_snap_to_grid(node_y, global.grid_size);
        var _stack_members = [];

        node_x = _stack_x;
        node_y = _stack_y;
        x = _stack_x;
        y = _stack_y;

        with (obj_opcode_node) {
            if (is_connected && root_uid == _stack_root_uid) {
                array_push(_stack_members, id);
            }
        }

        array_sort(_stack_members, function(_a, _b) {
            return _a.node_y - _b.node_y;
        });

        var _stack_cursor_y = _stack_y + node_height;
        var _stack_index = 0;

        while (_stack_index < array_length(_stack_members)) {
            var _stack_node = _stack_members[_stack_index];
            _stack_node.node_x = _stack_x;
            _stack_node.node_y = _stack_cursor_y;
            _stack_node.x = _stack_x;
            _stack_node.y = _stack_cursor_y;
            _stack_cursor_y += _stack_node.node_height;
            _stack_index += 1;
        }
    }

    with (obj_opcode_node) {
        if (!is_connected) {
            node_x = scr_snap_to_grid(node_x, global.grid_size);
            node_y = scr_snap_to_grid(node_y, global.grid_size);
            x = node_x;
            y = node_y;
        }
    }
}
