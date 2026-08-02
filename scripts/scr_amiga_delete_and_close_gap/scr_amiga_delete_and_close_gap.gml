/// @desc scr_amiga_delete_and_close_gap(_deleted_id)
/// Destroys _deleted_id and permanently pulls everyone below it (in the
/// same root's column) up by its height. No relinking needed — order is
/// pure Y-position, so closing the gap is the only thing required.
function scr_amiga_delete_and_close_gap(_deleted_id) {
    var _root_uid = _deleted_id.root_uid;
    var _deleted_y = _deleted_id.node_y;
    var _deleted_height = _deleted_id.node_height;

    with (obj_opcode_node) {
        var _is_self = (id == _deleted_id);
        var _in_this_root = (root_uid == _root_uid) && is_connected;

        if (!_is_self && _in_this_root && node_y > _deleted_y) {
            node_y -= _deleted_height;
        }
    }

    instance_destroy(_deleted_id);
}
