/// @desc scr_amiga_close_gap_after_detach(_dragged_id, _old_root_uid, _old_y)
/// The instant a node detaches (any real movement while dragging), whoever
/// was below it in the same column permanently shifts up to close the gap
/// — for real, immediately, matching "the whole spine stays tidy" rather
/// than leaving a visual hole that's only harmless for compile order.
function scr_amiga_close_gap_after_detach(_dragged_id, _old_root_uid, _old_y) {
    var _shift_amount = _dragged_id.node_height;

    with (obj_opcode_node) {
        var _is_self = (id == _dragged_id);
        var _in_old_root = (root_uid == _old_root_uid) && is_connected;

        if (!_is_self && _in_old_root && node_y > _old_y) {
            node_y -= _shift_amount;
        }
    }
}
