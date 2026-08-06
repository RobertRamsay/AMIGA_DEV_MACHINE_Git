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

// Six direct zoom buttons. Mouse wheel over the canvas changes one level.
var _zoom_level = 1;

while (_zoom_level <= 6) {
    var _zoom_button_x = _layout.zoom_x + ((_zoom_level - 1) mod 3) * 42;
    var _zoom_button_y = _layout.zoom_y + ((_zoom_level - 1) div 3) * 22;

    if (point_in_rectangle(mouse_x, mouse_y, _zoom_button_x, _zoom_button_y, _zoom_button_x + 36, _zoom_button_y + 18)
    && mouse_check_button_pressed(mb_left)) {
        bitmap_zoom = _zoom_level;
        _layout = scr_bitmap_editor_layout(id);
    }

    _zoom_level += 1;
}

if (_over_canvas) {
    var _old_zoom = bitmap_zoom;

    if (mouse_wheel_up()) bitmap_zoom = min(6, bitmap_zoom + 1);
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

// Paint with left, erase to COLOR00 with right. At 1x this is exact pixels;
// at higher zoom the same mapping follows the panned viewport.
if (_over_canvas && !canvas_panning && !keyboard_check(vk_space)
&& (mouse_check_button(mb_left) || mouse_check_button(mb_right))) {
    var _pixel_x = floor((mouse_x - _layout.display_x + bitmap_scroll_x) / bitmap_zoom);
    var _pixel_y = floor((mouse_y - _layout.display_y + bitmap_scroll_y) / bitmap_zoom);

    if (_pixel_x >= 0 && _pixel_x < bitmap_width && _pixel_y >= 0 && _pixel_y < bitmap_height) {
        var _draw_index = bitmap_paint_index;
        if (mouse_check_button(mb_right)) _draw_index = 0;
        var _pixel_offset = (_pixel_y * bitmap_width) + _pixel_x;

        if (bitmap_pixels[_pixel_offset] != _draw_index) {
            bitmap_pixels[_pixel_offset] = _draw_index;
            array_push(bitmap_dirty_pixels, _pixel_offset);
            bitmap_asset_dirty = true;
        }
    }
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
