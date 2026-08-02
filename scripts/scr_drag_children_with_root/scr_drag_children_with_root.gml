/// @desc scr_drag_children_with_root(_root_id, _delta_x, _delta_y)
/// Matches C64DM's "ORG drags its children with it" exactly — every node
/// whose root_uid is this root moves by the identical delta. Flat
/// membership means this is a single pass, no chain-walking needed.
function scr_drag_children_with_root(_root_id, _delta_x, _delta_y) {
    var _root_uid = _root_id.uid;

    with (obj_opcode_node) {
        if (root_uid == _root_uid) {
            node_x += _delta_x;
            node_y += _delta_y;
        }
    }
}
