/// @desc scr_amiga_apply_wedge_preview(_dragged_id, _root_uid, _insert_y)
/// Pushes every OTHER connected member of _root_uid at or below _insert_y
/// down by _dragged_id's height — a REAL position change (not a separate
/// render-only offset), with the old value remembered in wedge_y_stored
/// so scr_amiga_restore_wedge_shifts can put it back next frame.
function scr_amiga_apply_wedge_preview(_dragged_id, _root_uid, _insert_y) {
    var _shift_amount = _dragged_id.node_height;

    with (obj_opcode_node) {
        var _is_self = (id == _dragged_id);
        var _in_this_root = (root_uid == _root_uid) && is_connected;

        if (!_is_self && _in_this_root && node_y >= _insert_y && wedge_y_stored < 0) {
            wedge_y_stored = node_y;
            node_y += _shift_amount;
        }
    }
}
