/// @desc scr_tracker_open(_name)
/// Opens the TRACKER on the MOD asset _name, or ("" ) on the song edited
/// last, or a new song. Closes SND-EDIT first (both are full modals).
/// Returns the editor instance.
function scr_tracker_open(_name) {
    if (instance_exists(obj_tracker_editor)) return instance_find(obj_tracker_editor, 0);
    with (obj_audio_editor) instance_destroy();
    // The click that opened it must not also press a tracker button.
    mouse_clear(mb_left);
    var _editor = instance_create_depth(0, 0, -400000, obj_tracker_editor);
    if (_name == "" && variable_global_exists("tracker_last_name")) _name = global.tracker_last_name;
    var _asset = (_name != "") ? scr_asset_find_by_name(_name) : undefined;
    if (_asset != undefined && _asset.type == "MOD") {
        with (_editor) tracker_load(_name);
    }
    return _editor;
}

/// @desc scr_tracker_open_for_node(_node)
/// EDIT on a PLAY MUSIC node: opens the tracker on the node's song, or on a
/// new song when it has none. Saving links the song to the node.
function scr_tracker_open_for_node(_node) {
    var _asset = scr_asset_find_by_name(_node.macro_asset_name);
    var _has_song = _asset != undefined && _asset.type == "MOD";
    var _editor = scr_tracker_open(_has_song ? _node.macro_asset_name : "");
    with (_editor) {
        if (!_has_song) {
            scr_audio_preview_stop();
            song = scr_tracker_song_new();
            song_name = scr_audio_unique_name("song");
            cur_pos = 0;
            cur_row = 0;
            undo_stack = [];
            redo_stack = [];
            dirty = true;
            tracker_message("New song for this PLAY MUSIC node - SAVE (or Esc) links it to the node.", c_lime);
        }
        link_node = _node;
    }
    return _editor;
}
