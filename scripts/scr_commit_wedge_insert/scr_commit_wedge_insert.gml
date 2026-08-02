/// @desc scr_commit_wedge_insert(_self_id, _wedge_parent_uid, _wedge_child_uid, _wedge_x, _wedge_y)
/// Permanently inserts _self_id at a wedge point. Uses the target child's
/// LIVE current position rather than _wedge_x/_wedge_y — those were
/// captured mid-drag and can be stale by the time this runs, since
/// detaching from the origin slot (which happens right before this is
/// called) may have already shifted the target if it sat further down
/// the same chain. _wedge_x/_wedge_y stay as a fallback only.
function scr_commit_wedge_insert(_self_id, _wedge_parent_uid, _wedge_child_uid, _wedge_x, _wedge_y) {
    var _child_id = noone;

    with (obj_opcode_node) {
        if (uid == _wedge_child_uid) {
            _child_id = id;
        }
    }

    if (_child_id != noone) {
        _self_id.node_x = _child_id.node_x;
        _self_id.node_y = _child_id.node_y;
    } else {
        _self_id.node_x = _wedge_x;
        _self_id.node_y = _wedge_y;
    }

    _self_id.parent_uid = _wedge_parent_uid;
    _self_id.is_connected = true;

    if (_child_id != noone) {
        _child_id.parent_uid = _self_id.uid;
        scr_relayout_chain_from_node(_self_id);
    }

    with (obj_opcode_node) {
        wedge_preview_shift_y = 0;
    }
}