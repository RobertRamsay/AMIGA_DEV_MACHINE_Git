/// @description 32x32 BOB editor sharing the bitmap's 32-colour palette
panel_x = max(20, (room_width - 920) div 2);
panel_y = max(20, (room_height - 610) div 2);
panel_w = 920;
panel_h = 670;
header_h = 24;
cell_size = 16;
grid_x_offset = 24;
grid_y_offset = 48;

bob_width = 32;
bob_height = 32;
bob_pixels = array_create(bob_width * bob_height, 0);
bob_asset_name = "TestBob";
bob_asset_names = [];
bob_asset_index = 0;

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
bob_tool = "DRAW";
bob_line_active = false;
bob_line_start_x = 0;
bob_line_start_y = 0;
bob_line_value = 1;
bob_line_current_x = 0;
bob_line_current_y = 0;
bob_line_button = mb_left;
bob_anim_playing = false;
bob_anim_rate = 8;
bob_anim_start = 0;
bob_anim_end = 0;
bob_anim_loop = true;
bob_anim_next_time = 0;

function bob_commit() {
    scr_asset_define_bob(bob_asset_name, bob_width, bob_height, bob_pixels);
    global.workspace_dirty = true;
}

function bob_rebuild_asset_names() {
    bob_asset_names = [];
    var _i = 0;
    while (_i < array_length(global.asset_list)) {
        if (global.asset_list[_i].type == "BOB") array_push(bob_asset_names, global.asset_list[_i].name);
        _i += 1;
    }
    var _max_frame = max(0, array_length(bob_asset_names) - 1);
    bob_anim_start = clamp(bob_anim_start, 0, _max_frame);
    bob_anim_end = clamp(bob_anim_end, bob_anim_start, _max_frame);
}

function bob_load_asset(_name) {
    var _asset = scr_asset_find_by_name(_name);
    bob_asset_name = _name;
    global.current_bob_asset_name = _name;
    bob_pixels = array_create(bob_width * bob_height, 0);
    if (_asset != undefined && _asset.type == "BOB") {
        var _copy_w = min(bob_width, _asset.width);
        var _copy_h = min(bob_height, _asset.height);
        var _y = 0;
        while (_y < _copy_h) {
            array_copy(bob_pixels, _y * bob_width, _asset.pixels, _y * _asset.width, _copy_w);
            _y += 1;
        }
    }
    bob_line_active = false;
}

function bob_navigate(_delta) {
    bob_anim_playing = false;
    bob_commit();
    bob_rebuild_asset_names();
    if (array_length(bob_asset_names) <= 0) exit;
    bob_asset_index = (bob_asset_index + _delta + array_length(bob_asset_names)) mod array_length(bob_asset_names);
    bob_load_asset(bob_asset_names[bob_asset_index]);
}

function bob_add_asset() {
    bob_anim_playing = false;
    bob_commit();
    var _number = 1;
    var _name = "Bob01";
    while (scr_asset_find_by_name(_name) != undefined) {
        _number += 1;
        _name = "Bob" + (_number < 10 ? "0" : "") + string(_number);
    }
    bob_asset_name = _name;
    global.current_bob_asset_name = _name;
    bob_pixels = array_create(bob_width * bob_height, 0);
    bob_commit();
    bob_rebuild_asset_names();
    bob_asset_index = array_length(bob_asset_names) - 1;
    bob_anim_end = max(0, array_length(bob_asset_names) - 1);
    bob_line_active = false;
}

function bob_apply_line(_x0, _y0, _x1, _y1, _value) {
    var _dx = abs(_x1 - _x0), _sx = _x0 < _x1 ? 1 : -1;
    var _dy = -abs(_y1 - _y0), _sy = _y0 < _y1 ? 1 : -1;
    var _err = _dx + _dy;
    repeat (128) {
        bob_pixels[_y0 * bob_width + _x0] = _value;
        if (_x0 == _x1 && _y0 == _y1) break;
        var _e2 = 2 * _err;
        if (_e2 >= _dy) { _err += _dy; _x0 += _sx; }
        if (_e2 <= _dx) { _err += _dx; _y0 += _sy; }
    }
}

function bob_apply_fill(_x, _y, _value) {
    var _target = bob_pixels[_y * bob_width + _x];
    if (_target == _value) exit;
    var _queue_x = [_x], _queue_y = [_y], _head = 0;
    bob_pixels[_y * bob_width + _x] = _value;
    while (_head < array_length(_queue_x)) {
        var _cx = _queue_x[_head], _cy = _queue_y[_head];
        _head += 1;
        var _nx = [_cx - 1, _cx + 1, _cx, _cx];
        var _ny = [_cy, _cy, _cy - 1, _cy + 1];
        var _n = 0;
        while (_n < 4) {
            if (_nx[_n] >= 0 && _nx[_n] < bob_width && _ny[_n] >= 0 && _ny[_n] < bob_height) {
                var _index = _ny[_n] * bob_width + _nx[_n];
                if (bob_pixels[_index] == _target) {
                    bob_pixels[_index] = _value;
                    array_push(_queue_x, _nx[_n]); array_push(_queue_y, _ny[_n]);
                }
            }
            _n += 1;
        }
    }
}

bob_rebuild_asset_names();
if (array_length(bob_asset_names) == 0) {
    scr_asset_define_bob("TestBob", bob_width, bob_height, bob_pixels);
    bob_rebuild_asset_names();
}
var _test_index = -1;
var _find_index = 0;
while (_find_index < array_length(bob_asset_names)) {
    if (bob_asset_names[_find_index] == "TestBob") _test_index = _find_index;
    _find_index += 1;
}
if (_test_index >= 0) bob_asset_index = _test_index;
bob_load_asset(bob_asset_names[bob_asset_index]);
bob_anim_end = max(0, array_length(bob_asset_names) - 1);

with (obj_amiga_manager) visible = false;
with (obj_opcode_node) visible = false;
with (obj_amiga_root_node) visible = false;
with (obj_opcode_palette_item) visible = false;
