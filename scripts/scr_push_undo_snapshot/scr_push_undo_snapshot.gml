/// @desc scr_push_undo_snapshot()
/// Call BEFORE a mutation, so the stack holds "state right before this action."
function scr_push_undo_snapshot() {
    var _snapshot = scr_capture_snapshot();
    array_push(global.undo_stack, _snapshot);

    if (array_length(global.undo_stack) > global.undo_stack_max) {
        array_delete(global.undo_stack, 0, 1);
    }

    global.redo_stack = [];
    scr_mark_workspace_dirty();
}
