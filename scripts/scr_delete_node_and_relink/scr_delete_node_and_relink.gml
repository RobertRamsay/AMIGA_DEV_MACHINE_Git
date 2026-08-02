/// @desc scr_delete_node_and_relink(_deleted_id)
/// Reconnects whatever was below _deleted_id to whatever was above it,
/// shifting the rest of the chain up so it stays visually contiguous, then destroys it.
function scr_delete_node_and_relink(_deleted_id) {
    var _deleted_parent_uid = _deleted_id.parent_uid;
    var _deleted_height = _deleted_id.node_height;
    var _deleted_uid = _deleted_id.uid;

    var _child_id = noone;

    with (obj_opcode_node) {
        if (parent_uid == _deleted_uid) {
            _child_id = id;
        }
    }

    if (_child_id != noone) {
        _child_id.parent_uid = _deleted_parent_uid;
        _child_id.is_connected = true;

        var _shift_cursor_uid = _child_id.uid;
        var _still_shifting = true;

        while (_still_shifting) {
            _still_shifting = false;

            with (obj_opcode_node) {
                if (uid == _shift_cursor_uid) {
                    node_y -= _deleted_height;
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

    instance_destroy(_deleted_id);
}