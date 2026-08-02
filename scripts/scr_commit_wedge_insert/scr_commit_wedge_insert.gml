/// @desc scr_commit_wedge_insert(_self_id, _wedge_parent_uid, _wedge_child_uid, _wedge_x, _wedge_y)
/// Permanently inserts _self_id at a wedge point: takes over the child's old
/// position/parent, and pushes the child (and everything below it) down for real.
function scr_commit_wedge_insert(_self_id, _wedge_parent_uid, _wedge_child_uid, _wedge_x, _wedge_y) {
    var _own_height = _self_id.node_height;

    _self_id.node_x = _wedge_x;
    _self_id.node_y = _wedge_y;
    _self_id.parent_uid = _wedge_parent_uid;
    _self_id.is_connected = true;

    var _child_id = noone;

    with (obj_opcode_node) {
        if (uid == _wedge_child_uid) {
            _child_id = id;
        }
    }

    if (_child_id != noone) {
        _child_id.parent_uid = _self_id.uid;

        var _shift_cursor_uid = _child_id.uid;
        var _still_shifting = true;

        while (_still_shifting) {
            _still_shifting = false;

            with (obj_opcode_node) {
                if (uid == _shift_cursor_uid) {
                    node_y += _own_height;
                    wedge_preview_shift_y = 0;
                }
            }

            var _next_uid = -1;

            with (obj_opcode_node) {
                if (parent_uid == _shift_cursor_uid) {
                    _next_uid = uid;
                }
            }

            if (_next_uid != -1) {
                _shift_cursor_uid = _next_uid;
                _still_shifting = true;
            }
        }
    }
}
