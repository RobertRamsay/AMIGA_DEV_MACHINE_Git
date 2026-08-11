/// @desc scr_redo()
function scr_redo() {
    var _redo_count = array_length(global.redo_stack);

    if (_redo_count == 0) {
        show_debug_message("Nothing to redo.");
        return;
    }

    var _current_snapshot = scr_capture_snapshot();
    array_push(global.undo_stack, _current_snapshot);

    if (array_length(global.undo_stack) > global.undo_stack_max) {
        array_delete(global.undo_stack, 0, 1);
    }

    var _next_snapshot = global.redo_stack[_redo_count - 1];
    array_delete(global.redo_stack, _redo_count - 1, 1);

    scr_restore_snapshot(_next_snapshot);
    scr_mark_workspace_dirty();
}
