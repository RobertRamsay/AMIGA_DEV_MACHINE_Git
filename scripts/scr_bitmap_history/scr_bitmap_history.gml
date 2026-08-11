/// Bitmap editor history helpers. Snapshots preserve indexed pixels and the
/// complete 32-entry 12-bit palette, while view/tool state remains unchanged.

function scr_bitmap_capture_snapshot(_editor) {
    var _pixels = array_create(_editor.bitmap_width * _editor.bitmap_height, 0);
    var _r = array_create(32, 0);
    var _g = array_create(32, 0);
    var _b = array_create(32, 0);
    array_copy(_pixels, 0, _editor.bitmap_pixels, 0, array_length(_pixels));
    array_copy(_r, 0, _editor.bitmap_colour_r, 0, 32);
    array_copy(_g, 0, _editor.bitmap_colour_g, 0, 32);
    array_copy(_b, 0, _editor.bitmap_colour_b, 0, 32);
    return { pixels : _pixels, colour_r : _r, colour_g : _g, colour_b : _b };
}

function scr_bitmap_restore_snapshot(_editor, _snapshot) {
    _editor.bitmap_pixels = array_create(_editor.bitmap_width * _editor.bitmap_height, 0);
    _editor.bitmap_colour_r = array_create(32, 0);
    _editor.bitmap_colour_g = array_create(32, 0);
    _editor.bitmap_colour_b = array_create(32, 0);
    array_copy(_editor.bitmap_pixels, 0, _snapshot.pixels, 0, array_length(_editor.bitmap_pixels));
    array_copy(_editor.bitmap_colour_r, 0, _snapshot.colour_r, 0, 32);
    array_copy(_editor.bitmap_colour_g, 0, _snapshot.colour_g, 0, 32);
    array_copy(_editor.bitmap_colour_b, 0, _snapshot.colour_b, 0, 32);
    _editor.bitmap_surface_dirty = true;
    _editor.bitmap_dirty_pixels = [];
    _editor.bitmap_stroke_active = false;
    _editor.bitmap_line_active = false;
    _editor.bitmap_gradient_active = false;
    _editor.bitmap_asset_dirty = false;
    scr_asset_define_bitmap("TestBitmap", _editor.bitmap_pixels, _editor.bitmap_colour_r, _editor.bitmap_colour_g, _editor.bitmap_colour_b,
        _editor.bitmap_gradient_custom_active, _editor.bitmap_gradient_custom_colours, _editor.bitmap_gradient_custom_count);
}

function scr_bitmap_push_undo(_editor) {
    array_push(_editor.bitmap_undo_stack, scr_bitmap_capture_snapshot(_editor));
    if (array_length(_editor.bitmap_undo_stack) > _editor.bitmap_history_max) {
        array_delete(_editor.bitmap_undo_stack, 0, 1);
    }
    _editor.bitmap_redo_stack = [];
    scr_mark_workspace_dirty();
}

function scr_bitmap_undo(_editor) {
    if (array_length(_editor.bitmap_undo_stack) <= 0) return;
    array_push(_editor.bitmap_redo_stack, scr_bitmap_capture_snapshot(_editor));
    scr_bitmap_restore_snapshot(_editor, array_pop(_editor.bitmap_undo_stack));
    scr_mark_workspace_dirty();
}

function scr_bitmap_redo(_editor) {
    if (array_length(_editor.bitmap_redo_stack) <= 0) return;
    array_push(_editor.bitmap_undo_stack, scr_bitmap_capture_snapshot(_editor));
    scr_bitmap_restore_snapshot(_editor, array_pop(_editor.bitmap_redo_stack));
    scr_mark_workspace_dirty();
}
