depth = -100000;

// The bitmap editor is a modal workspace. Hide the graph, palette, preview
// and status UI while it owns the screen; their Step events also pause.
with (obj_amiga_manager) visible = false;
with (obj_opcode_node) visible = false;
with (obj_amiga_root_node) visible = false;
with (obj_opcode_palette_item) visible = false;

bitmap_width = 320;
bitmap_height = 256;
bitmap_pixels = array_create(bitmap_width * bitmap_height, 0);
bitmap_zoom = 3;
bitmap_grid_size = 0;
bitmap_brush_size = 1;
bitmap_scroll_x = 0;
bitmap_scroll_y = 0;
bitmap_paint_index = 1;
bitmap_palette_edit_index = 1;
bitmap_surface = -1;
bitmap_surface_dirty = true;
bitmap_dirty_pixels = [];
bitmap_asset_dirty = false;
bitmap_undo_stack = [];
bitmap_redo_stack = [];
bitmap_history_max = 24;
bitmap_palette_drag_active = false;
bitmap_native_path = "";
bitmap_buffer = buffer_create(bitmap_width * bitmap_height * 4, buffer_fixed, 1);
bitmap_stroke_active = false;
bitmap_stroke_last_x = 0;
bitmap_stroke_last_y = 0;
bitmap_stroke_index = 0;
bitmap_tool = "DRAW";
bitmap_line_active = false;
bitmap_line_start_x = 0;
bitmap_line_start_y = 0;
bitmap_line_end_x = 0;
bitmap_line_end_y = 0;
bitmap_line_index = 1;
bitmap_line_use_dither = false;
bitmap_gradient_colour_1 = 1;
bitmap_gradient_colour_2 = 2;
bitmap_gradient_custom_active = false;
bitmap_gradient_custom_colours = array_create(12, bitmap_gradient_colour_1);
bitmap_gradient_custom_count = 12;
bitmap_gradient_include_edge = false;
bitmap_gradient_active = false;
bitmap_gradient_start_x = 0;
bitmap_gradient_start_y = 0;
bitmap_gradient_end_x = 0;
bitmap_gradient_end_y = 0;
bitmap_dither_pattern = "CHECKER";
bitmap_dither_use_colour_2 = false;
bitmap_dither_invert = false;
bitmap_use_dither = false;
bitmap_transparency_lock = false;

bitmap_colour_r = array_create(32, 0);
bitmap_colour_g = array_create(32, 0);
bitmap_colour_b = array_create(32, 0);

// A useful, unmistakably 12-bit starter palette. Every component is 0-F.
var _default_palette = [
    $000, $FFF, $F00, $0F0, $00F, $FF0, $0FF, $F0F,
    $888, $444, $800, $080, $008, $880, $088, $808,
    $F88, $8F8, $88F, $FC8, $8FC, $C8F, $F80, $0F8,
    $08F, $80F, $F08, $8F0, $0CF, $C0F, $FC0, $CCC
];

var _palette_i = 0;

while (_palette_i < 32) {
    var _colour_word = _default_palette[_palette_i];
    bitmap_colour_r[_palette_i] = (_colour_word >> 8) & 15;
    bitmap_colour_g[_palette_i] = (_colour_word >> 4) & 15;
    bitmap_colour_b[_palette_i] = _colour_word & 15;
    _palette_i += 1;
}

// Reopening the editor continues from the current named bitmap asset rather
// than silently replacing it with a blank canvas.
var _existing_bitmap = scr_asset_find_by_name("TestBitmap");
if (_existing_bitmap != undefined && _existing_bitmap.type == "BITMAP") {
    array_copy(bitmap_pixels, 0, _existing_bitmap.pixels, 0, 320 * 256);
    array_copy(bitmap_colour_r, 0, _existing_bitmap.colour_r, 0, 32);
    array_copy(bitmap_colour_g, 0, _existing_bitmap.colour_g, 0, 32);
    array_copy(bitmap_colour_b, 0, _existing_bitmap.colour_b, 0, 32);
    if (variable_struct_exists(_existing_bitmap, "gradient_custom_active")) {
        bitmap_gradient_custom_active = _existing_bitmap.gradient_custom_active;
    }
    if (variable_struct_exists(_existing_bitmap, "gradient_custom_colours")
    && is_array(_existing_bitmap.gradient_custom_colours)
    && array_length(_existing_bitmap.gradient_custom_colours) == 12) {
        array_copy(bitmap_gradient_custom_colours, 0, _existing_bitmap.gradient_custom_colours, 0, 12);
    }
    if (variable_struct_exists(_existing_bitmap, "gradient_custom_count")) {
        bitmap_gradient_custom_count = clamp(_existing_bitmap.gradient_custom_count, 1, 12);
    }
}

panel_width = min(1600, room_width - 20);
panel_height = min(1024, room_height - 40);
panel_x = floor((room_width - panel_width) / 2);
panel_y = max(0, floor((room_height - panel_height) / 2) - 20);
panel_dragging = false;
panel_drag_offset_x = 0;
panel_drag_offset_y = 0;
canvas_panning = false;
canvas_pan_with_space = false;
pan_mouse_x = 0;
pan_mouse_y = 0;

scr_asset_define_bitmap("TestBitmap", bitmap_pixels, bitmap_colour_r, bitmap_colour_g, bitmap_colour_b,
    bitmap_gradient_custom_active, bitmap_gradient_custom_colours, bitmap_gradient_custom_count);
