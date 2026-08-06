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
bitmap_grid_enabled = false;
bitmap_scroll_x = 0;
bitmap_scroll_y = 0;
bitmap_paint_index = 1;
bitmap_palette_edit_index = 1;
bitmap_surface = -1;
bitmap_surface_dirty = true;
bitmap_dirty_pixels = [];
bitmap_asset_dirty = false;
bitmap_buffer = buffer_create(bitmap_width * bitmap_height * 4, buffer_fixed, 1);
bitmap_stroke_active = false;
bitmap_stroke_last_x = 0;
bitmap_stroke_last_y = 0;
bitmap_stroke_index = 0;

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

panel_width = min(1600, room_width - 20);
panel_height = min(1024, room_height - 40);
panel_x = floor((room_width - panel_width) / 2);
panel_y = floor((room_height - panel_height) / 2);
panel_dragging = false;
panel_drag_offset_x = 0;
panel_drag_offset_y = 0;
canvas_panning = false;
pan_mouse_x = 0;
pan_mouse_y = 0;

scr_asset_define_bitmap("TestBitmap", bitmap_pixels, bitmap_colour_r, bitmap_colour_g, bitmap_colour_b);
