/// @desc scr_drag_children_with_root(_root_id, _delta_x, _delta_y)
/// Same principle as C64DM's "ORG drags its children with it" — every node
/// transitively connected to _root_id moves by the identical delta, so their
/// relative spacing can never change regardless of how many there are.
function scr_drag_children_with_root(_root_id, _delta_x, _delta_y) {
    var _cursor_uid = _root_id.uid;
    var _still_walking = true;

    while (_still_walking) {
        _still_walking = false;

        var _next_uid = -1;

        with (obj_opcode_node) {
            if (parent_uid == _cursor_uid) {
                node_x += _delta_x;
                node_y += _delta_y;
                _next_uid = uid;
            }
        }

        if (_next_uid != -1) {
            _cursor_uid = _next_uid;
            _still_walking = true;
        }
    }
}
