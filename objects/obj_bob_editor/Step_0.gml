var _mx = mouse_x;
var _my = mouse_y;
var _left_press = mouse_check_button_pressed(mb_left);
var _left = mouse_check_button(mb_left);
var _right_press = mouse_check_button_pressed(mb_right);
var _right = mouse_check_button(mb_right);

if (_left_press && point_in_rectangle(_mx, _my, panel_x, panel_y, panel_x + panel_w - 28, panel_y + header_h)) {
    dragging_panel = true;
    drag_dx = _mx - panel_x;
    drag_dy = _my - panel_y;
}
if (dragging_panel) {
    if (_left) {
        panel_x = clamp(_mx - drag_dx, 0, room_width - panel_w);
        panel_y = clamp(_my - drag_dy, 0, room_height - panel_h);
    } else dragging_panel = false;
}

if (_left_press && point_in_rectangle(_mx, _my, panel_x + panel_w - 25, panel_y + 3, panel_x + panel_w - 4, panel_y + 21)) {
    instance_destroy();
    exit;
}

var _gx = panel_x + grid_x_offset;
var _gy = panel_y + grid_y_offset;
var _over_grid = point_in_rectangle(_mx, _my, _gx, _gy, _gx + bob_width * cell_size - 1, _gy + bob_height * cell_size - 1);
var _grid_press = _over_grid && (_left_press || _right_press);
if (_grid_press && bob_tool == "DRAW") {
    bob_anim_playing = false;
    drawing = _left_press;
    erasing = _right_press;
    last_px = -1;
    last_py = -1;
}
if (drawing || erasing) {
    var _held = drawing ? _left : _right;
    if (_held && _over_grid) {
        var _px = clamp(floor((_mx - _gx) / cell_size), 0, bob_width - 1);
        var _py = clamp(floor((_my - _gy) / cell_size), 0, bob_height - 1);
        var _value = erasing ? 0 : pen_index;
        if (last_px < 0) {
            bob_pixels[_py * bob_width + _px] = _value;
        } else {
            bob_apply_line(last_px, last_py, _px, _py, _value);
        }
        last_px = _px;
        last_py = _py;
    } else {
        bob_commit();
        drawing = false;
        erasing = false;
    }
}

if (_grid_press && bob_tool == "LINE") {
    bob_anim_playing = false;
    var _line_x = clamp(floor((_mx - _gx) / cell_size), 0, bob_width - 1);
    var _line_y = clamp(floor((_my - _gy) / cell_size), 0, bob_height - 1);
    var _line_value = _right_press ? 0 : pen_index;
    bob_line_active = true;
    bob_line_start_x = _line_x; bob_line_start_y = _line_y;
    bob_line_current_x = _line_x; bob_line_current_y = _line_y;
    bob_line_value = _line_value;
    bob_line_button = _right_press ? mb_right : mb_left;
}
if (bob_line_active) {
    if (mouse_check_button(bob_line_button)) {
        if (_over_grid) {
            bob_line_current_x = clamp(floor((_mx - _gx) / cell_size), 0, bob_width - 1);
            bob_line_current_y = clamp(floor((_my - _gy) / cell_size), 0, bob_height - 1);
        }
    } else {
        bob_apply_line(bob_line_start_x, bob_line_start_y, bob_line_current_x, bob_line_current_y, bob_line_value);
        bob_line_active = false;
        bob_commit();
    }
}

if (_grid_press && bob_tool == "FILL") {
    bob_anim_playing = false;
    var _fill_x = clamp(floor((_mx - _gx) / cell_size), 0, bob_width - 1);
    var _fill_y = clamp(floor((_my - _gy) / cell_size), 0, bob_height - 1);
    bob_apply_fill(_fill_x, _fill_y, _right_press ? 0 : pen_index);
    bob_commit();
}

var _palette_x = panel_x + 560;
var _palette_y = panel_y + 58;
for (var _i = 0; _i < 32; _i += 1) {
    var _sx = _palette_x + ((_i mod 8) * 38);
    var _sy = _palette_y + ((_i div 8) * 38);
    if (_left_press && point_in_rectangle(_mx, _my, _sx, _sy, _sx + 31, _sy + 31)) pen_index = _i;
}

// Three genuine Amiga 4-bit component sliders. Palette edits are committed
// immediately, so the bitmap editor sees them next time it draws/opens.
var _slider_y = panel_y + 250;
for (var _component = 0; _component < 3; _component += 1) {
    var _sy2 = _slider_y + _component * 42;
    if (_left && point_in_rectangle(_mx, _my, _palette_x + 22, _sy2, _palette_x + 262, _sy2 + 20)) {
        var _v = clamp(round((_mx - (_palette_x + 22)) / 16), 0, 15);
        if (_component == 0) colour_r[pen_index] = _v;
        if (_component == 1) colour_g[pen_index] = _v;
        if (_component == 2) colour_b[pen_index] = _v;
        scr_amiga_commit_shared_bitmap_palette(colour_r, colour_g, colour_b);
    }
}

var _asset_row_y = panel_y + 370;
if (_left_press && point_in_rectangle(_mx, _my, _palette_x, _asset_row_y, _palette_x + 28, _asset_row_y + 26)) bob_navigate(-1);
if (_left_press && point_in_rectangle(_mx, _my, _palette_x + 190, _asset_row_y, _palette_x + 218, _asset_row_y + 26)) bob_navigate(1);
if (_left_press && point_in_rectangle(_mx, _my, _palette_x + 228, _asset_row_y, _palette_x + 320, _asset_row_y + 26)) bob_add_asset();

var _tool_y = panel_y + 410;
if (_left_press && point_in_rectangle(_mx, _my, _palette_x, _tool_y, _palette_x + 92, _tool_y + 30)) { bob_tool = "DRAW"; bob_line_active = false; }
if (_left_press && point_in_rectangle(_mx, _my, _palette_x + 104, _tool_y, _palette_x + 196, _tool_y + 30)) { bob_tool = "LINE"; bob_line_active = false; }
if (_left_press && point_in_rectangle(_mx, _my, _palette_x + 208, _tool_y, _palette_x + 300, _tool_y + 30)) { bob_tool = "FILL"; bob_line_active = false; }

var _anim_y = panel_y + 450;
if (_left_press && point_in_rectangle(_mx, _my, _palette_x, _anim_y, _palette_x + 92, _anim_y + 30)) {
    bob_anim_playing = !bob_anim_playing;
    if (bob_anim_playing) {
        bob_commit(); bob_rebuild_asset_names();
        bob_asset_index = bob_anim_start;
        bob_load_asset(bob_asset_names[bob_asset_index]);
        bob_anim_next_time = current_time + (1000 / bob_anim_rate);
    }
}
if (_left_press && point_in_rectangle(_mx, _my, _palette_x + 104, _anim_y, _palette_x + 196, _anim_y + 30)) bob_anim_loop = !bob_anim_loop;

var _anim_value_y = panel_y + 490;
var _frame_max = max(0, array_length(bob_asset_names) - 1);
if (_left_press && point_in_rectangle(_mx, _my, _palette_x, _anim_value_y, _palette_x + 92, _anim_value_y + 30)) {
    bob_anim_rate = clamp(bob_anim_rate + (_mx < _palette_x + 46 ? -1 : 1), 1, 60);
}
if (_left_press && point_in_rectangle(_mx, _my, _palette_x + 104, _anim_value_y, _palette_x + 196, _anim_value_y + 30)) {
    bob_anim_start = clamp(bob_anim_start + (_mx < _palette_x + 150 ? -1 : 1), 0, bob_anim_end);
}
if (_left_press && point_in_rectangle(_mx, _my, _palette_x + 208, _anim_value_y, _palette_x + 300, _anim_value_y + 30)) {
    bob_anim_end = clamp(bob_anim_end + (_mx < _palette_x + 254 ? -1 : 1), bob_anim_start, _frame_max);
}

if (bob_anim_playing && current_time >= bob_anim_next_time) {
    bob_asset_index += 1;
    if (bob_asset_index > bob_anim_end) {
        if (bob_anim_loop) bob_asset_index = bob_anim_start;
        else { bob_asset_index = bob_anim_end; bob_anim_playing = false; }
    }
    bob_load_asset(bob_asset_names[bob_asset_index]);
    bob_anim_next_time = current_time + (1000 / bob_anim_rate);
}

if (_left_press && point_in_rectangle(_mx, _my, _palette_x, panel_y + 530, _palette_x + 130, panel_y + 560)) {
    bob_pixels = array_create(bob_width * bob_height, 0);
    bob_commit();
}
if (_left_press && point_in_rectangle(_mx, _my, _palette_x, panel_y + 580, _palette_x + 145, panel_y + 614)) {
    bob_commit();
    scr_amiga_run_bob_bitmap_test();
    instance_destroy();
}
if (_left_press && point_in_rectangle(_mx, _my, _palette_x + 160, panel_y + 580, _palette_x + 305, panel_y + 614)) {
    bob_commit();
    scr_amiga_run_sprite_bitmap_test();
    instance_destroy();
}
