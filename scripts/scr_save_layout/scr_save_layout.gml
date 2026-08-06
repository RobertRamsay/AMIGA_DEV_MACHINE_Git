/// @desc scr_save_layout()
/// Quick autosave to a fixed path (Ctrl+S). For a named, user-chosen save
/// file, see the SAVE WORKSPACE button, which calls the same underlying
/// scr_save_workspace_to_path with a path from a file dialog instead.
function scr_save_layout() {
    var _save_path = global.current_project_path + "/autosave_layout.json";
    scr_save_workspace_to_path(_save_path);
}
