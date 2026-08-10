/// @description 32x32 BOB editor sharing the bitmap's 32-colour palette
panel_x = max(20, (room_width - 920) div 2);
panel_y = max(20, (room_height - 610) div 2);
panel_w = 920;
panel_h = 610;
header_h = 24;
cell_size = 16;
grid_x_offset = 24;
grid_y_offset = 48;

bob_width = 32;
bob_height = 32;
bob_pixels = array_create(bob_width * bob_height, 0);
var _asset = scr_asset_find_by_name("TestBob");
if (_asset != undefined && _asset.type == "BOB" && _asset.width == bob_width && _asset.height == bob_height) {
    array_copy(bob_pixels, 0, _asset.pixels, 0, array_length(_asset.pixels));
}

var _palette = scr_amiga_get_shared_bitmap_palette();
colour_r = _palette.colour_r;
colour_g = _palette.colour_g;
colour_b = _palette.colour_b;
pen_index = 1;
dragging_panel = false;
drag_dx = 0;
drag_dy = 0;
drawing = false;
erasing = false;
last_px = -1;
last_py = -1;

function bob_commit() {
    scr_asset_define_bob("TestBob", bob_width, bob_height, bob_pixels);
    global.workspace_dirty = true;
}

with (obj_amiga_manager) visible = false;
with (obj_opcode_node) visible = false;
with (obj_amiga_root_node) visible = false;
with (obj_opcode_palette_item) visible = false;
