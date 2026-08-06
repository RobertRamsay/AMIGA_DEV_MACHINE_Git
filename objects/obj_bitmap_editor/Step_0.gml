var _layout = scr_bitmap_editor_layout(id);
var _over_close = point_in_rectangle(mouse_x, mouse_y, _layout.close_x, _layout.close_y, _layout.close_x + 18, _layout.close_y + 18);
var _over_header = point_in_rectangle(mouse_x, mouse_y, _layout.header_x, _layout.header_y, _layout.header_x + _layout.header_width, _layout.header_y + _layout.header_height);

if (_over_close && mouse_check_button_pressed(mb_left)) {
    instance_destroy();
    exit;
}

if (_over_header && !_over_close && mouse_check_button_pressed(mb_left)) {
    panel_dragging = true;
    panel_drag_offset_x = mouse_x - panel_x;
    panel_drag_offset_y = mouse_y - panel_y;
}

if (panel_dragging) {
    if (mouse_check_button(mb_left)) {
        panel_x = clamp(mouse_x - panel_drag_offset_x, 0, room_width - panel_width);
        panel_y = clamp(mouse_y - panel_drag_offset_y, 0, room_height - 20);
        _layout = scr_bitmap_editor_layout(id);
    } else {
        panel_dragging = false;
    }
}

var _over_canvas = point_in_rectangle(mouse_x, mouse_y, _layout.canvas_x, _layout.canvas_y, _layout.canvas_x + _layout.canvas_width, _layout.canvas_y + _layout.canvas_height);

// Sixteen direct zoom buttons. Mouse wheel changes one level at a time.
var _zoom_level = 1;

while (_zoom_level <= 16) {
    var _zoom_button_x = _layout.zoom_x + ((_zoom_level - 1) mod 4) * (_layout.zoom_button_width + _layout.zoom_button_gap_x);
    var _zoom_button_y = _layout.zoom_y + ((_zoom_level - 1) div 4) * (_layout.zoom_button_height + _layout.zoom_button_gap_y);

    if (point_in_rectangle(mouse_x, mouse_y, _zoom_button_x, _zoom_button_y, _zoom_button_x + _layout.zoom_button_width, _zoom_button_y + _layout.zoom_button_height)
    && mouse_check_button_pressed(mb_left)) {
        bitmap_zoom = _zoom_level;
        _layout = scr_bitmap_editor_layout(id);
    }

    _zoom_level += 1;
}

if (_over_canvas) {
    var _old_zoom = bitmap_zoom;

    if (mouse_wheel_up()) bitmap_zoom = min(16, bitmap_zoom + 1);
    if (mouse_wheel_down()) bitmap_zoom = max(1, bitmap_zoom - 1);

    if (bitmap_zoom != _old_zoom) {
        var _image_mouse_x = (mouse_x - _layout.display_x + bitmap_scroll_x) / _old_zoom;
        var _image_mouse_y = (mouse_y - _layout.display_y + bitmap_scroll_y) / _old_zoom;
        _layout = scr_bitmap_editor_layout(id);
        bitmap_scroll_x = clamp((_image_mouse_x * bitmap_zoom) - (mouse_x - _layout.canvas_x), 0, _layout.max_scroll_x);
        bitmap_scroll_y = clamp((_image_mouse_y * bitmap_zoom) - (mouse_y - _layout.canvas_y), 0, _layout.max_scroll_y);
        _layout = scr_bitmap_editor_layout(id);
    }
}

if (point_in_rectangle(mouse_x, mouse_y, _layout.grid_toggle_x, _layout.grid_toggle_y, _layout.grid_toggle_x + 120, _layout.grid_toggle_y + 20)
&& mouse_check_button_pressed(mb_left)) {
    bitmap_grid_enabled = !bitmap_grid_enabled;
}

var _tool_names = ["DRAW", "LINE", "FILL"];
var _tool_index = 0;

while (_tool_index < array_length(_tool_names)) {
    var _tool_x = _layout.tool_x + _tool_index * (_layout.tool_width + _layout.tool_gap);

    if (point_in_rectangle(mouse_x, mouse_y, _tool_x, _layout.tool_y, _tool_x + _layout.tool_width, _layout.tool_y + _layout.tool_height)
    && mouse_check_button_pressed(mb_left)) {
        bitmap_tool = _tool_names[_tool_index];
        bitmap_stroke_active = false;
        bitmap_line_active = false;
        bitmap_gradient_active = false;
    }

    _tool_index += 1;
}

if (point_in_rectangle(mouse_x, mouse_y, _layout.gradient_tool_x, _layout.gradient_tool_y, _layout.gradient_tool_x + _layout.gradient_tool_width, _layout.gradient_tool_y + _layout.tool_height)
&& mouse_check_button_pressed(mb_left)) {
    bitmap_tool = "GRADIENT";
    bitmap_stroke_active = false;
    bitmap_line_active = false;
    bitmap_gradient_active = false;
}

var _gradient_colour_1_x = _layout.gradient_tool_x;
var _gradient_colour_2_x = _layout.gradient_tool_x + _layout.gradient_colour_width + _layout.tool_gap;

if (point_in_rectangle(mouse_x, mouse_y, _gradient_colour_1_x, _layout.gradient_colour_y, _gradient_colour_1_x + _layout.gradient_colour_width, _layout.gradient_colour_y + _layout.tool_height)
&& mouse_check_button_pressed(mb_left)) {
    bitmap_gradient_colour_1 = bitmap_paint_index;
}

if (point_in_rectangle(mouse_x, mouse_y, _gradient_colour_2_x, _layout.gradient_colour_y, _gradient_colour_2_x + _layout.gradient_colour_width, _layout.gradient_colour_y + _layout.tool_height)
&& mouse_check_button_pressed(mb_left)) {
    bitmap_gradient_colour_2 = bitmap_paint_index;
}

if (point_in_rectangle(mouse_x, mouse_y, _layout.gradient_edge_x, _layout.gradient_edge_y, _layout.gradient_edge_x + _layout.gradient_edge_width, _layout.gradient_edge_y + _layout.tool_height)
&& mouse_check_button_pressed(mb_left)) {
    bitmap_gradient_include_edge = !bitmap_gradient_include_edge;
}

// Middle-drag, or Space + left-drag, pans the magnified image.
var _pan_pressed = mouse_check_button_pressed(mb_middle)
    || (keyboard_check(vk_space) && mouse_check_button_pressed(mb_left));

if (_over_canvas && _pan_pressed) {
    canvas_panning = true;
    pan_mouse_x = mouse_x;
    pan_mouse_y = mouse_y;
}

if (canvas_panning) {
    var _pan_held = mouse_check_button(mb_middle)
        || (keyboard_check(vk_space) && mouse_check_button(mb_left));

    if (_pan_held) {
        bitmap_scroll_x = clamp(bitmap_scroll_x - (mouse_x - pan_mouse_x), 0, _layout.max_scroll_x);
        bitmap_scroll_y = clamp(bitmap_scroll_y - (mouse_y - pan_mouse_y), 0, _layout.max_scroll_y);
        pan_mouse_x = mouse_x;
        pan_mouse_y = mouse_y;
    } else {
        canvas_panning = false;
    }
}

// Palette selection: 4 columns by 8 rows, covering COLOR00-COLOR31.
var _swatch_index = 0;

while (_swatch_index < 32) {
    var _swatch_col = _swatch_index mod 4;
    var _swatch_row = _swatch_index div 4;
    var _swatch_x = _layout.swatch_x + _swatch_col * (_layout.swatch_width + _layout.swatch_gap);
    var _swatch_y = _layout.swatch_y + _swatch_row * (_layout.swatch_height + _layout.swatch_gap);

    if (point_in_rectangle(mouse_x, mouse_y, _swatch_x, _swatch_y, _swatch_x + _layout.swatch_width, _swatch_y + _layout.swatch_height)
    && mouse_check_button_pressed(mb_left)) {
        bitmap_paint_index = _swatch_index;
        bitmap_palette_edit_index = _swatch_index;
    }

    _swatch_index += 1;
}

// Live 12-bit RGB sliders for the selected COLOR register.
if (mouse_check_button(mb_left)) {
    var _slider_value = clamp(floor((mouse_x - _layout.slider_x) / _layout.slider_step_width), 0, 15);
    var _palette_index = bitmap_palette_edit_index;

    if (point_in_rectangle(mouse_x, mouse_y, _layout.slider_x, _layout.slider_r_y, _layout.slider_x + _layout.slider_width, _layout.slider_r_y + _layout.slider_height)) {
        if (bitmap_colour_r[_palette_index] != _slider_value) {
            bitmap_colour_r[_palette_index] = _slider_value;
            bitmap_surface_dirty = true;
            bitmap_asset_dirty = true;
        }
    }

    if (point_in_rectangle(mouse_x, mouse_y, _layout.slider_x, _layout.slider_g_y, _layout.slider_x + _layout.slider_width, _layout.slider_g_y + _layout.slider_height)) {
        if (bitmap_colour_g[_palette_index] != _slider_value) {
            bitmap_colour_g[_palette_index] = _slider_value;
            bitmap_surface_dirty = true;
            bitmap_asset_dirty = true;
        }
    }

    if (point_in_rectangle(mouse_x, mouse_y, _layout.slider_x, _layout.slider_b_y, _layout.slider_x + _layout.slider_width, _layout.slider_b_y + _layout.slider_height)) {
        if (bitmap_colour_b[_palette_index] != _slider_value) {
            bitmap_colour_b[_palette_index] = _slider_value;
            bitmap_surface_dirty = true;
            bitmap_asset_dirty = true;
        }
    }
}

var _canvas_pixel_x = floor((mouse_x - _layout.display_x + bitmap_scroll_x) / bitmap_zoom);
var _canvas_pixel_y = floor((mouse_y - _layout.display_y + bitmap_scroll_y) / bitmap_zoom);
var _canvas_pixel_valid = _canvas_pixel_x >= 0 && _canvas_pixel_x < bitmap_width
    && _canvas_pixel_y >= 0 && _canvas_pixel_y < bitmap_height;

// Alt + left-click picks both the paint pen and palette-edit swatch.
if (_over_canvas && _canvas_pixel_valid && keyboard_check(vk_alt)
&& mouse_check_button_pressed(mb_left)) {
    var _picked_index = bitmap_pixels[(_canvas_pixel_y * bitmap_width) + _canvas_pixel_x];
    bitmap_paint_index = _picked_index;
    bitmap_palette_edit_index = _picked_index;
    bitmap_stroke_active = false;
}

// DRAW: continuous freehand using the same exact line routine as LINE.
var _stroke_can_draw = _over_canvas && _canvas_pixel_valid
    && !canvas_panning && !keyboard_check(vk_space)
    && !keyboard_check(vk_alt) && bitmap_tool == "DRAW"
    && (mouse_check_button(mb_left) || mouse_check_button(mb_right));

if (_stroke_can_draw) {
    var _draw_index = bitmap_paint_index;
    if (mouse_check_button(mb_right)) _draw_index = 0;

    if (!bitmap_stroke_active || bitmap_stroke_index != _draw_index) {
        bitmap_stroke_active = true;
        bitmap_stroke_last_x = _canvas_pixel_x;
        bitmap_stroke_last_y = _canvas_pixel_y;
        bitmap_stroke_index = _draw_index;
    }

    scr_bitmap_apply_line(id, bitmap_stroke_last_x, bitmap_stroke_last_y, _canvas_pixel_x, _canvas_pixel_y, _draw_index);

    bitmap_stroke_last_x = _canvas_pixel_x;
    bitmap_stroke_last_y = _canvas_pixel_y;
} else {
    // Do not bridge across the tool rails or outside the image on re-entry.
    bitmap_stroke_active = false;
}

// LINE: remember the start, show a live preview, then commit on release.
if (bitmap_tool == "LINE" && _over_canvas && _canvas_pixel_valid
&& !keyboard_check(vk_alt) && !keyboard_check(vk_space)
&& (mouse_check_button_pressed(mb_left) || mouse_check_button_pressed(mb_right))) {
    bitmap_line_active = true;
    bitmap_line_start_x = _canvas_pixel_x;
    bitmap_line_start_y = _canvas_pixel_y;
    bitmap_line_end_x = _canvas_pixel_x;
    bitmap_line_end_y = _canvas_pixel_y;
    bitmap_line_index = mouse_check_button_pressed(mb_right) ? 0 : bitmap_paint_index;
}

if (bitmap_line_active && (mouse_check_button(mb_left) || mouse_check_button(mb_right))) {
    if (_over_canvas && _canvas_pixel_valid) {
        bitmap_line_end_x = _canvas_pixel_x;
        bitmap_line_end_y = _canvas_pixel_y;
    }
}

if (bitmap_line_active && (mouse_check_button_released(mb_left) || mouse_check_button_released(mb_right))) {
    scr_bitmap_apply_line(id, bitmap_line_start_x, bitmap_line_start_y, bitmap_line_end_x, bitmap_line_end_y, bitmap_line_index);
    bitmap_line_active = false;
}

// FILL: iterative four-way flood fill, safe for the complete 320x256 image.
if (bitmap_tool == "FILL" && _over_canvas && _canvas_pixel_valid
&& !keyboard_check(vk_alt)
&& (mouse_check_button_pressed(mb_left) || mouse_check_button_pressed(mb_right))) {
    var _fill_index = mouse_check_button_pressed(mb_right) ? 0 : bitmap_paint_index;
    var _fill_start_offset = (_canvas_pixel_y * bitmap_width) + _canvas_pixel_x;
    var _fill_target_index = bitmap_pixels[_fill_start_offset];

    if (_fill_target_index != _fill_index) {
        var _fill_queue = [_fill_start_offset];
        var _fill_read = 0;
        bitmap_pixels[_fill_start_offset] = _fill_index;
        array_push(bitmap_dirty_pixels, _fill_start_offset);

        while (_fill_read < array_length(_fill_queue)) {
            var _fill_offset = _fill_queue[_fill_read];
            var _fill_x = _fill_offset mod bitmap_width;
            var _fill_y = _fill_offset div bitmap_width;

            if (_fill_x > 0) {
                var _fill_left = _fill_offset - 1;
                if (bitmap_pixels[_fill_left] == _fill_target_index) {
                    bitmap_pixels[_fill_left] = _fill_index;
                    array_push(bitmap_dirty_pixels, _fill_left);
                    array_push(_fill_queue, _fill_left);
                }
            }

            if (_fill_x < bitmap_width - 1) {
                var _fill_right = _fill_offset + 1;
                if (bitmap_pixels[_fill_right] == _fill_target_index) {
                    bitmap_pixels[_fill_right] = _fill_index;
                    array_push(bitmap_dirty_pixels, _fill_right);
                    array_push(_fill_queue, _fill_right);
                }
            }

            if (_fill_y > 0) {
                var _fill_up = _fill_offset - bitmap_width;
                if (bitmap_pixels[_fill_up] == _fill_target_index) {
                    bitmap_pixels[_fill_up] = _fill_index;
                    array_push(bitmap_dirty_pixels, _fill_up);
                    array_push(_fill_queue, _fill_up);
                }
            }

            if (_fill_y < bitmap_height - 1) {
                var _fill_down = _fill_offset + bitmap_width;
                if (bitmap_pixels[_fill_down] == _fill_target_index) {
                    bitmap_pixels[_fill_down] = _fill_index;
                    array_push(bitmap_dirty_pixels, _fill_down);
                    array_push(_fill_queue, _fill_down);
                }
            }

            _fill_read += 1;
        }

        bitmap_asset_dirty = true;
    }
}

// GRADIENT: first point chooses the contiguous area and gradient origin;
// release chooses direction/length, then an 8x8 Bayer threshold fills it.
if (bitmap_tool == "GRADIENT" && _over_canvas && _canvas_pixel_valid
&& !keyboard_check(vk_alt) && !keyboard_check(vk_space)
&& mouse_check_button_pressed(mb_left)) {
    bitmap_gradient_active = true;
    bitmap_gradient_start_x = _canvas_pixel_x;
    bitmap_gradient_start_y = _canvas_pixel_y;
    bitmap_gradient_end_x = _canvas_pixel_x;
    bitmap_gradient_end_y = _canvas_pixel_y;
}

if (bitmap_gradient_active && mouse_check_button(mb_left)) {
    if (_over_canvas && _canvas_pixel_valid) {
        bitmap_gradient_end_x = _canvas_pixel_x;
        bitmap_gradient_end_y = _canvas_pixel_y;
    }
}

if (bitmap_gradient_active && mouse_check_button_released(mb_left)) {
    var _gradient_target = bitmap_pixels[(bitmap_gradient_start_y * bitmap_width) + bitmap_gradient_start_x];
    var _gradient_start_offset = (bitmap_gradient_start_y * bitmap_width) + bitmap_gradient_start_x;
    var _gradient_queue = [_gradient_start_offset];
    var _gradient_region = [];
    var _gradient_visited = array_create(bitmap_width * bitmap_height, false);
    var _gradient_read = 0;
    _gradient_visited[_gradient_start_offset] = true;

    while (_gradient_read < array_length(_gradient_queue)) {
        var _gradient_offset = _gradient_queue[_gradient_read];
        var _gradient_x = _gradient_offset mod bitmap_width;
        var _gradient_y = _gradient_offset div bitmap_width;
        array_push(_gradient_region, _gradient_offset);

        if (_gradient_x > 0) {
            var _gradient_left = _gradient_offset - 1;
            if (!_gradient_visited[_gradient_left] && bitmap_pixels[_gradient_left] == _gradient_target) {
                _gradient_visited[_gradient_left] = true;
                array_push(_gradient_queue, _gradient_left);
            }
        }

        if (_gradient_x < bitmap_width - 1) {
            var _gradient_right = _gradient_offset + 1;
            if (!_gradient_visited[_gradient_right] && bitmap_pixels[_gradient_right] == _gradient_target) {
                _gradient_visited[_gradient_right] = true;
                array_push(_gradient_queue, _gradient_right);
            }
        }

        if (_gradient_y > 0) {
            var _gradient_up = _gradient_offset - bitmap_width;
            if (!_gradient_visited[_gradient_up] && bitmap_pixels[_gradient_up] == _gradient_target) {
                _gradient_visited[_gradient_up] = true;
                array_push(_gradient_queue, _gradient_up);
            }
        }

        if (_gradient_y < bitmap_height - 1) {
            var _gradient_down = _gradient_offset + bitmap_width;
            if (!_gradient_visited[_gradient_down] && bitmap_pixels[_gradient_down] == _gradient_target) {
                _gradient_visited[_gradient_down] = true;
                array_push(_gradient_queue, _gradient_down);
            }
        }

        _gradient_read += 1;
    }

    var _bayer_8 = [
         0, 32,  8, 40,  2, 34, 10, 42,
        48, 16, 56, 24, 50, 18, 58, 26,
        12, 44,  4, 36, 14, 46,  6, 38,
        60, 28, 52, 20, 62, 30, 54, 22,
         3, 35, 11, 43,  1, 33,  9, 41,
        51, 19, 59, 27, 49, 17, 57, 25,
        15, 47,  7, 39, 13, 45,  5, 37,
        63, 31, 55, 23, 61, 29, 53, 21
    ];

    var _gradient_dx = bitmap_gradient_end_x - bitmap_gradient_start_x;
    var _gradient_dy = bitmap_gradient_end_y - bitmap_gradient_start_y;
    var _gradient_length_sq = (_gradient_dx * _gradient_dx) + (_gradient_dy * _gradient_dy);
    if (_gradient_length_sq < 1) _gradient_length_sq = 1;

    var _region_index = 0;

    while (_region_index < array_length(_gradient_region)) {
        var _region_offset = _gradient_region[_region_index];
        var _region_x = _region_offset mod bitmap_width;
        var _region_y = _region_offset div bitmap_width;
        var _is_edge = (_region_x == 0 || _region_x == bitmap_width - 1 || _region_y == 0 || _region_y == bitmap_height - 1);

        if (!_is_edge) {
            // Test against the completed region map, not pixels already
            // recoloured earlier in this loop.
            _is_edge = !_gradient_visited[_region_offset - 1]
                || !_gradient_visited[_region_offset + 1]
                || !_gradient_visited[_region_offset - bitmap_width]
                || !_gradient_visited[_region_offset + bitmap_width];
        }

        if (bitmap_gradient_include_edge || !_is_edge) {
            var _gradient_projection = (((_region_x - bitmap_gradient_start_x) * _gradient_dx)
                + ((_region_y - bitmap_gradient_start_y) * _gradient_dy)) / _gradient_length_sq;
            _gradient_projection = clamp(_gradient_projection, 0, 1);
            var _bayer_value = (_bayer_8[((_region_y mod 8) * 8) + (_region_x mod 8)] + 0.5) / 64;
            var _gradient_colour = (_gradient_projection >= _bayer_value) ? bitmap_gradient_colour_2 : bitmap_gradient_colour_1;

            if (bitmap_pixels[_region_offset] != _gradient_colour) {
                bitmap_pixels[_region_offset] = _gradient_colour;
                array_push(bitmap_dirty_pixels, _region_offset);
                bitmap_asset_dirty = true;
            }
        }

        _region_index += 1;
    }

    bitmap_gradient_active = false;
}

if (point_in_rectangle(mouse_x, mouse_y, _layout.clear_x, _layout.clear_y, _layout.clear_x + 120, _layout.clear_y + 20)
&& mouse_check_button_pressed(mb_left)) {
    bitmap_pixels = array_create(bitmap_width * bitmap_height, 0);
    bitmap_surface_dirty = true;
    bitmap_dirty_pixels = [];
    bitmap_asset_dirty = true;
}

// Commit after a stroke or palette adjustment, matching the sprite editor.
if (bitmap_asset_dirty && (mouse_check_button_released(mb_left) || mouse_check_button_released(mb_right))) {
    scr_asset_define_bitmap("TestBitmap", bitmap_pixels, bitmap_colour_r, bitmap_colour_g, bitmap_colour_b);
    bitmap_asset_dirty = false;
}
