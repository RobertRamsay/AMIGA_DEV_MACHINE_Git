/// @desc scr_relink_around_node(_node_id)
/// Detaches _node_id from the chain: whatever was below it gets reparented
/// to whatever was above it, and shifts up to close the gap. Does NOT destroy
/// _node_id — used both by delete (which destroys afterward) and by picking
/// a node up to drag (which doesn't).
function scr_relink_around_node(_node_id) {
    var _parent_uid = _node_id.parent_uid;
    var _own_height = _node_id.node_height;
    var _own_uid = _node_id.uid;

    var _child_id = noone;

    with (obj_opcode_node) {
        if (parent_uid == _own_uid) {
            _child_id = id;
        }
    }

    if (_child_id != noone) {
        _child_id.parent_uid = _parent_uid;
        _child_id.is_connected = (_parent_uid != -1);

        var _shift_cursor_uid = _child_id.uid;
        var _still_shifting = true;

        while (_still_shifting) {
            _still_shifting = false;

            with (obj_opcode_node) {
                if (uid == _shift_cursor_uid) {
                    node_y -= _own_height;
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
