/// @desc scr_tracker_open(_name)
/// Opens the TRACKER on the MOD asset _name, or ("" ) on the song edited
/// last, or a new song. Closes SND-EDIT first (both are full modals).
/// Returns the editor instance.
function scr_tracker_open(_name) {
    if (instance_exists(obj_tracker_editor)) return instance_find(obj_tracker_editor, 0);
    with (obj_audio_editor) instance_destroy();
    var _editor = instance_create_depth(0, 0, -400000, obj_tracker_editor);
    if (_name == "" && variable_global_exists("tracker_last_name")) _name = global.tracker_last_name;
    var _asset = (_name != "") ? scr_asset_find_by_name(_name) : undefined;
    if (_asset != undefined && _asset.type == "MOD") {
        with (_editor) tracker_load(_name);
    }
    return _editor;
}
