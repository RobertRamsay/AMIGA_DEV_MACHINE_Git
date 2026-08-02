/// @desc scr_relayout_chain_from_node(_start_id)
/// Walks the parent_uid chain starting after _start_id and re-derives each
/// descendant's position directly from its parent's position + height.
/// Unlike shifting each node by a fixed amount, this can never accumulate
/// drift or collapse nodes together, regardless of whatever state existed
/// before — each position is freshly computed from the graph structure.
function scr_relayout_chain_from_node(_start_id) {
    var _cursor_uid = _start_id.uid;
    var _cursor_x = _start_id.node_x;
    var _cursor_y = _start_id.node_y + _start_id.node_height;
    var _still_walking = true;

    while (_still_walking) {
        _still_walking = false;

        var _next_uid = -1;
        var _next_height = 0;

        with (obj_opcode_node) {
            if (parent_uid == _cursor_uid) {
                node_x = _cursor_x;
                node_y = _cursor_y;
                _next_uid = uid;
                _next_height = node_height;
            }
        }

        if (_next_uid != -1) {
            _cursor_uid = _next_uid;
            _cursor_y += _next_height;
            _still_walking = true;
        }
    }
}
