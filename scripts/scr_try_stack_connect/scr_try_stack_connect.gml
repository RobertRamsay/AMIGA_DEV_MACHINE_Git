function scr_try_stack_connect(_self_id) {
    var _snap_distance = global.grid_size;
    var _best_target_id = noone;
    var _best_distance = 999999;

    with (obj_opcode_node) {
        var _is_self = (id == _self_id);

        if (!_is_self) {
            var _target_bottom_y = node_y + node_height;
            var _dx = abs(node_x - _self_id.node_x);
            var _dy = abs(_target_bottom_y - _self_id.node_y);
            var _close_enough = (_dx <= _snap_distance) && (_dy <= _snap_distance);

            if (_close_enough) {
                if (_dy < _best_distance) {
                    _best_distance = _dy;
                    _best_target_id = id;
                }
            }
        }
    }

    with (obj_amiga_root_node) {
        var _target_bottom_y = node_y + node_height;
        var _dx = abs(node_x - _self_id.node_x);
        var _dy = abs(_target_bottom_y - _self_id.node_y);
        var _close_enough = (_dx <= _snap_distance) && (_dy <= _snap_distance);

        if (_close_enough) {
            if (_dy < _best_distance) {
                _best_distance = _dy;
                _best_target_id = id;
            }
        }
    }

    var _found_target = (_best_target_id != noone);

    if (_found_target) {
        _self_id.node_x = _best_target_id.node_x;
        _self_id.node_y = _best_target_id.node_y + _best_target_id.node_height;
        _self_id.is_connected = true;
        _self_id.parent_uid = _best_target_id.uid;
    } else {
        _self_id.is_connected = false;
        _self_id.parent_uid = -1;
    }
}