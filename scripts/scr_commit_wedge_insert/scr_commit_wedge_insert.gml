/// @desc scr_commit_wedge_insert(_self_id, _wedge_parent_uid, _wedge_child_uid, _wedge_x, _wedge_y)
/// Permanently inserts _self_id at a wedge point: takes over the child's old
/// position/parent, then relays out the whole downstream chain from the
/// inserted node so it can't drift or overlap regardless of prior state.
function scr_commit_wedge_insert(_self_id, _wedge_parent_uid, _wedge_child_uid, _wedge_x, _wedge_y) {
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
        scr_relayout_chain_from_node(_self_id);
    }

    with (obj_opcode_node) {
        wedge_preview_shift_y = 0;
    }
}
