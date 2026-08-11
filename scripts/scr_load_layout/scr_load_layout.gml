/// @desc scr_load_layout()
/// Quick autoload from a fixed path (Ctrl+L). For loading a named,
/// user-chosen file, see the LOAD WORKSPACE button, which calls the same
/// underlying scr_load_workspace_from_path with a path from a file dialog
/// instead.
function scr_load_layout() {
    var _save_path = global.current_project_path + "/autosave_layout.json";
    scr_load_workspace_from_path(_save_path);
    if (file_exists(_save_path)) {
        scr_set_status_message("Quick workspace loaded: " + _save_path, make_colour_rgb(0, 255, 255));
    }
}
