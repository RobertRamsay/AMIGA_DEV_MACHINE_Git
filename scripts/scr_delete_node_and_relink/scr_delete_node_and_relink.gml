/// @desc scr_delete_node_and_relink(_deleted_id)
/// Reconnects whatever was below _deleted_id to whatever was above it,
/// shifting the rest of the chain up so it stays visually contiguous, then destroys it.
function scr_delete_node_and_relink(_deleted_id) {
    scr_relink_around_node(_deleted_id);
    instance_destroy(_deleted_id);
}
