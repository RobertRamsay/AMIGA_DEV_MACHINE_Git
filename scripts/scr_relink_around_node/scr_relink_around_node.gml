/// @desc scr_relink_around_node(_node_id)
/// Detaches _node_id from the chain: whatever was below it gets reparented
/// to whatever was above it, and shifts up to close the gap. Handles the
/// (should-not-normally-happen) case of more than one node claiming
/// _node_id as their parent, relinking and shifting each independently.
/// Does NOT destroy _node_id — used both by delete and by drag pickup.
function scr_relink_around_node(_node_id) {
    var _parent_uid = _node_id.parent_uid;
    var _own_height = _node_id.node_height;
    var _own_uid = _node_id.uid;

    var _child_uids = [];

    with (obj_opcode_node) {
        if (parent_uid == _own_uid) {
            array_push(_child_uids, uid);
        }
    }

    var _child_count = array_length(_child_uids);
    var _c = 0;

    while (_c < _child_count) {
        var _this_child_uid = _child_uids[_c];

        with (obj_opcode_node) {
            if (uid == _this_child_uid) {
                parent_uid = _parent_uid;
                is_connected = (_parent_uid != -1);
            }
        }

        var _shift_cursor_uid = _this_child_uid;
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

        _c += 1;
    }
}
