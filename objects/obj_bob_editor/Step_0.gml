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
if (_over_grid && (_left_press || _right_press)) {
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
            var _dx = abs(_px - last_px), _sx = last_px < _px ? 1 : -1;
            var _dy = -abs(_py - last_py), _sy = last_py < _py ? 1 : -1;
            var _err = _dx + _dy, _cx = last_px, _cy = last_py;
            repeat (64) {
                bob_pixels[_cy * bob_width + _cx] = _value;
                if (_cx == _px && _cy == _py) break;
                var _e2 = 2 * _err;
                if (_e2 >= _dy) { _err += _dy; _cx += _sx; }
                if (_e2 <= _dx) { _err += _dx; _cy += _sy; }
            }
        }
        last_px = _px;
        last_py = _py;
    } else {
        bob_commit();
        drawing = false;
        erasing = false;
    }
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

if (_left_press && point_in_rectangle(_mx, _my, _palette_x, panel_y + 410, _palette_x + 130, panel_y + 440)) {
    bob_pixels = array_create(bob_width * bob_height, 0);
    bob_commit();
}
if (_left_press && point_in_rectangle(_mx, _my, _palette_x, panel_y + 460, _palette_x + 145, panel_y + 494)) {
    bob_commit();
    scr_amiga_run_bob_bitmap_test();
    instance_destroy();
}
if (_left_press && point_in_rectangle(_mx, _my, _palette_x + 160, panel_y + 460, _palette_x + 305, panel_y + 494)) {
    bob_commit();
    scr_amiga_run_sprite_bitmap_test();
    instance_destroy();
}
