// The editor tour is presenting this screen: its input belongs to the tour.
if (instance_exists(obj_editor_tour)) exit;

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

// Close box or Esc.
if ((_left_press && point_in_rectangle(_mx, _my, panel_x + panel_w - 25, panel_y + 3, panel_x + panel_w - 4, panel_y + 21)) || keyboard_check_pressed(vk_escape)) {
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
    // Off the grid the end sticks to its edge, so the line is never dropped.
    if (mouse_check_button(bob_line_button)) {
        bob_line_current_x = scr_shape_clamp_pixel(floor((_mx - _gx) / cell_size), bob_width);
        bob_line_current_y = scr_shape_clamp_pixel(floor((_my - _gy) / cell_size), bob_height);
    } else {
        bob_apply_line(bob_line_start_x, bob_line_start_y, bob_line_current_x, bob_line_current_y, bob_line_value);
        bob_line_active = false;
        bob_commit();
    }
}

// CIRCLE / FILLED CIRCLE: press sets the centre, drag sets the radius.
if (_grid_press && (bob_tool == "CIRCLE" || bob_tool == "DISC")) {
    bob_anim_playing = false;
    bob_circle_active = true;
    bob_circle_cx = clamp(floor((_mx - _gx) / cell_size), 0, bob_width - 1);
    bob_circle_cy = clamp(floor((_my - _gy) / cell_size), 0, bob_height - 1);
    bob_circle_r = 0;
    bob_circle_value = _right_press ? 0 : pen_index;
    bob_circle_button = _right_press ? mb_right : mb_left;
}
if (bob_circle_active) {
    if (mouse_check_button(bob_circle_button)) {
        bob_circle_r = scr_shape_circle_radius(bob_circle_cx, bob_circle_cy,
            floor((_mx - _gx) / cell_size), floor((_my - _gy) / cell_size));
    } else {
        var _circle = scr_shape_circle_pixels(bob_circle_cx, bob_circle_cy, bob_circle_r, bob_tool == "DISC", bob_width, bob_height);
        for (var _ci = 0; _ci < array_length(_circle); _ci += 2) {
            bob_pixels[_circle[_ci + 1] * bob_width + _circle[_ci]] = bob_circle_value;
        }
        bob_circle_active = false;
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

var _palette_x = panel_x + column_x_offset;
var _palette_y = panel_y + 58;
for (var _i = 0; _i < 32; _i += 1) {
    var _sx = _palette_x + ((_i mod 8) * swatch_step);
    var _sy = _palette_y + ((_i div 8) * swatch_step);
    if (_left_press && point_in_rectangle(_mx, _my, _sx, _sy, _sx + swatch_size - 1, _sy + swatch_size - 1)) pen_index = _i;
}

// Three genuine Amiga 4-bit component sliders. Palette edits are committed
// immediately, so the bitmap editor sees them next time it draws/opens.
// A slider only follows a drag that started on it, so a paint stroke or a
// line passing over the sliders cannot recolour the pen.
var _slider_y = panel_y + 250;
if (!_left) slider_drag = -1;
for (var _component = 0; _component < 3; _component += 1) {
    var _sy2 = _slider_y + _component * 42;
    if (_left_press && point_in_rectangle(_mx, _my, _palette_x + slider_track_x, _sy2, _palette_x + slider_track_x + 15 * slider_step, _sy2 + 20)) {
        slider_drag = _component;
    }
    if (_left && slider_drag == _component) {
        var _v = clamp(round((_mx - (_palette_x + slider_track_x)) / slider_step), 0, 15);
        if (_component == 0) colour_r[pen_index] = _v;
        if (_component == 1) colour_g[pen_index] = _v;
        if (_component == 2) colour_b[pen_index] = _v;
        scr_amiga_commit_shared_bitmap_palette(colour_r, colour_g, colour_b);
    }
}

var _asset_row_y = panel_y + 370;
if (_left_press && point_in_rectangle(_mx, _my, _palette_x, _asset_row_y, _palette_x + 28, _asset_row_y + 26)) bob_navigate(-1);
if (_left_press && point_in_rectangle(_mx, _my, _palette_x + 196, _asset_row_y, _palette_x + 224, _asset_row_y + 26)) bob_navigate(1);
if (_left_press && point_in_rectangle(_mx, _my, _palette_x + 2 * button_step, _asset_row_y, _palette_x + column_width, _asset_row_y + 26)) bob_add_asset();

// Match the hardware-sprite editor's frame controls. Modified keys are ignored
// so application-level shortcuts such as Ctrl+S keep their existing meaning.
var _bob_shortcut_plain = !keyboard_check(vk_control) && !keyboard_check(vk_alt);
if (_bob_shortcut_plain) {
    if (keyboard_check_pressed(ord("A"))) bob_navigate(-1);
    if (keyboard_check_pressed(ord("D"))) bob_navigate(1);
    if (keyboard_check_pressed(ord("W"))) bob_add_asset();

    if (keyboard_check_pressed(ord("Q"))) {
        bob_anim_playing = false;
        bob_commit();
        bob_rebuild_asset_names();
        if (array_length(bob_asset_names) > 0) {
            bob_asset_index = 0;
            bob_load_asset(bob_asset_names[0]);
        }
    }

    if (keyboard_check_pressed(ord("E"))) {
        bob_anim_playing = false;
        bob_commit();
        bob_rebuild_asset_names();
        var _bob_last_frame = array_length(bob_asset_names) - 1;
        if (_bob_last_frame >= 0) {
            bob_asset_index = _bob_last_frame;
            bob_load_asset(bob_asset_names[_bob_last_frame]);
        }
    }

    if (keyboard_check_pressed(ord("S"))) {
        bob_anim_playing = !bob_anim_playing;
        if (bob_anim_playing) {
            bob_commit();
            bob_rebuild_asset_names();
            if (array_length(bob_asset_names) > 0) {
                bob_asset_index = bob_anim_start;
                bob_load_asset(bob_asset_names[bob_asset_index]);
                bob_anim_next_time = current_time + (1000 / bob_anim_rate);
            } else {
                bob_anim_playing = false;
            }
        }
    }
}

var _col_2 = _palette_x + button_step;
var _col_3 = _palette_x + 2 * button_step;
var _bob_tools = ["DRAW", "LINE", "FILL", "CIRCLE", "DISC"];
for (var _tool_i = 0; _tool_i < 5; _tool_i += 1) {
    var _tool_rect = bob_tool_rect(_tool_i);
    if (_left_press && point_in_rectangle(_mx, _my, _tool_rect[0], _tool_rect[1], _tool_rect[2], _tool_rect[3])) {
        bob_tool = _bob_tools[_tool_i];
        bob_line_active = false;
        bob_circle_active = false;
    }
}

var _anim_y = panel_y + 490;
if (_left_press && point_in_rectangle(_mx, _my, _palette_x, _anim_y, _palette_x + button_w, _anim_y + 30)) {
    bob_anim_playing = !bob_anim_playing;
    if (bob_anim_playing) {
        bob_commit(); bob_rebuild_asset_names();
        bob_asset_index = bob_anim_start;
        bob_load_asset(bob_asset_names[bob_asset_index]);
        bob_anim_next_time = current_time + (1000 / bob_anim_rate);
    }
}
if (_left_press && point_in_rectangle(_mx, _my, _col_2, _anim_y, _col_2 + button_w, _anim_y + 30)) bob_anim_loop = !bob_anim_loop;

// Value buttons: the left half steps down, the right half steps up.
var _anim_value_y = panel_y + 530;
var _half_w = button_w div 2;
var _frame_max = max(0, array_length(bob_asset_names) - 1);
if (_left_press && point_in_rectangle(_mx, _my, _palette_x, _anim_value_y, _palette_x + button_w, _anim_value_y + 30)) {
    bob_anim_rate = clamp(bob_anim_rate + (_mx < _palette_x + _half_w ? -1 : 1), 1, 60);
}
if (_left_press && point_in_rectangle(_mx, _my, _col_2, _anim_value_y, _col_2 + button_w, _anim_value_y + 30)) {
    bob_anim_start = clamp(bob_anim_start + (_mx < _col_2 + _half_w ? -1 : 1), 0, bob_anim_end);
}
if (_left_press && point_in_rectangle(_mx, _my, _col_3, _anim_value_y, _col_3 + button_w, _anim_value_y + 30)) {
    bob_anim_end = clamp(bob_anim_end + (_mx < _col_3 + _half_w ? -1 : 1), bob_anim_start, _frame_max);
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

var _test_w = (column_width - 12) div 2;
if (_left_press && point_in_rectangle(_mx, _my, _palette_x, panel_y + 570, _palette_x + button_w, panel_y + 600)) {
    bob_pixels = array_create(bob_width * bob_height, 0);
    bob_commit();
}
if (_left_press && point_in_rectangle(_mx, _my, _palette_x, panel_y + 620, _palette_x + _test_w, panel_y + 654)) {
    bob_commit();
    global.current_bob_anim_rate = bob_anim_rate;
    global.current_bob_anim_start = bob_anim_start;
    global.current_bob_anim_end = bob_anim_end;
    global.current_bob_anim_loop = bob_anim_loop;
    scr_amiga_run_bob_bitmap_test();
    instance_destroy();
}
if (_left_press && point_in_rectangle(_mx, _my, _palette_x + column_width - _test_w, panel_y + 620, _palette_x + column_width, panel_y + 654)) {
    bob_commit();
    scr_amiga_run_sprite_bitmap_test();
    instance_destroy();
}
