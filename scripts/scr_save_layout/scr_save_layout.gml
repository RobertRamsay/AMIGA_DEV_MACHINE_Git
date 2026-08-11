/// @desc scr_save_layout()
/// Quick autosave to a fixed path (Ctrl+S). For a named, user-chosen save
/// file, see the SAVE WORKSPACE button, which calls the same underlying
/// scr_save_workspace_to_path with a path from a file dialog instead.
function scr_save_layout() {
    var _save_path = global.current_project_path + "/autosave_layout.json";
    scr_save_workspace_to_path(_save_path);
    scr_set_status_message("Quick workspace saved: " + _save_path, make_colour_rgb(0, 255, 255));
}

/// Marks a user-visible mutation and restarts the five-second autosave delay.
/// Keeping this in one helper means every editor and undo system follows the
/// same debounce rule instead of each maintaining its own timer.
function scr_mark_workspace_dirty() {
    global.workspace_dirty = true;
    global.autosave_due_time = current_time + global.autosave_delay_ms;
}

/// Writes through a staging file so a shutdown during JSON output cannot
/// replace the last usable recovery file with a partially-written document.
function scr_write_temp_autosave() {
    var _target_path = global.autosave_workspace_path;
    var _staging_path = _target_path + ".writing";

    if (file_exists(_staging_path)) file_delete(_staging_path);
    scr_save_workspace_to_path(_staging_path, false);

    if (!file_exists(_staging_path)) return false;
    if (file_exists(_target_path)) file_delete(_target_path);
    file_rename(_staging_path, _target_path);

    if (!file_exists(_target_path)) return false;

    global.workspace_dirty = false;
    global.autosave_due_time = -1;
    scr_set_status_message("Temporary workspace autosaved.", make_colour_rgb(0, 255, 255));
    return true;
}
