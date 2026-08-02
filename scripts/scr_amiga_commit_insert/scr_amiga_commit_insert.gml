/// @desc scr_amiga_commit_insert(_dragged_id, _root_uid, _insert_y, _anchor_x)
/// Permanently inserts _dragged_id into _root_uid's column at _insert_y —
/// everyone else in that root at or below _insert_y gets pushed down for
/// real. No relinking needed anywhere: order is purely Y-position, so
/// nothing else has to change.
function scr_amiga_commit_insert(_dragged_id, _root_uid, _insert_y, _anchor_x) {
    var _shift_amount = _dragged_id.node_height;

    with (obj_opcode_node) {
        var _is_self = (id == _dragged_id);
        var _in_this_root = (root_uid == _root_uid) && is_connected;

        if (!_is_self && _in_this_root && node_y >= _insert_y) {
            node_y += _shift_amount;
        }
    }

    _dragged_id.node_x = _anchor_x;
    _dragged_id.node_y = _insert_y;
    _dragged_id.root_uid = _root_uid;
    _dragged_id.is_connected = true;
}
