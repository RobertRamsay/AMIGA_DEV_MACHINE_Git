/// @desc scr_undo()
function scr_undo() {
    var _undo_count = array_length(global.undo_stack);

    if (_undo_count == 0) {
        show_debug_message("Nothing to undo.");
        return;
    }

    var _current_snapshot = scr_capture_snapshot();
    array_push(global.redo_stack, _current_snapshot);

    var _previous_snapshot = global.undo_stack[_undo_count - 1];
    array_delete(global.undo_stack, _undo_count - 1, 1);

    scr_restore_snapshot(_previous_snapshot);
}
