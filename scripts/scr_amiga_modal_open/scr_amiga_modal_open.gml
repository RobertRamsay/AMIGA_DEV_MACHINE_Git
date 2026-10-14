/// @desc scr_amiga_modal_open()
/// True while any modal editor owns the screen and input. The manager, the
/// palette and every node stop handling input while one is open, so a click
/// or key meant for the editor can never also reach the graph behind it.
function scr_amiga_modal_open() {
    return instance_exists(obj_bitmap_editor)
        || instance_exists(obj_bob_editor)
        || instance_exists(obj_colour_picker)
        || instance_exists(obj_cprbar_editor)
        || instance_exists(obj_code_editor)
        || instance_exists(obj_audio_editor);
}
