var _layout = scr_bitmap_editor_layout(id);

// Rebuild the native 320x256 preview only after pixels or palette change.
if (!surface_exists(bitmap_surface)) {
    bitmap_surface = surface_create(bitmap_width, bitmap_height);
    bitmap_surface_dirty = true;
    bitmap_dirty_pixels = [];
}

// Full refreshes (palette edits, clear, or a recovered surface) are uploaded
// as one packed RGBA texture instead of 81,920 individual draw calls.
if (surface_exists(bitmap_surface) && bitmap_surface_dirty) {
    buffer_seek(bitmap_buffer, buffer_seek_start, 0);

    var _pixel_y = 0;
    while (_pixel_y < bitmap_height) {
        var _pixel_x = 0;
        while (_pixel_x < bitmap_width) {
            var _pixel_index = bitmap_pixels[(_pixel_y * bitmap_width) + _pixel_x];
            var _pixel_r = bitmap_colour_r[_pixel_index] * 17;
            var _pixel_g = bitmap_colour_g[_pixel_index] * 17;
            var _pixel_b = bitmap_colour_b[_pixel_index] * 17;
            var _packed_rgba = _pixel_r + (_pixel_g << 8) + (_pixel_b << 16) + 4278190080;
            buffer_write(bitmap_buffer, buffer_u32, _packed_rgba);
            _pixel_x += 1;
        }
        _pixel_y += 1;
    }

    buffer_set_surface(bitmap_buffer, bitmap_surface, 0);
    bitmap_surface_dirty = false;
    bitmap_dirty_pixels = [];
}

// Ordinary brush strokes update only the changed RGBA buffer entries, then
// upload through the same path used by palette refreshes. Keeping one texture
// path avoids the one-texel disagreement between draw_point and buffer pixels.
if (surface_exists(bitmap_surface) && array_length(bitmap_dirty_pixels) > 0) {
    var _dirty_index = 0;

    while (_dirty_index < array_length(bitmap_dirty_pixels)) {
        var _pixel_offset = bitmap_dirty_pixels[_dirty_index];
        var _pixel_index = bitmap_pixels[_pixel_offset];
        var _pixel_r = bitmap_colour_r[_pixel_index] * 17;
        var _pixel_g = bitmap_colour_g[_pixel_index] * 17;
        var _pixel_b = bitmap_colour_b[_pixel_index] * 17;
        var _packed_rgba = _pixel_r + (_pixel_g << 8) + (_pixel_b << 16) + 4278190080;
        buffer_poke(bitmap_buffer, _pixel_offset * 4, buffer_u32, _packed_rgba);
        _dirty_index += 1;
    }

    buffer_set_surface(bitmap_buffer, bitmap_surface, 0);
    bitmap_dirty_pixels = [];
}

draw_set_alpha(0.97);
draw_set_colour(c_black);
draw_rectangle(_layout.panel_x, _layout.panel_y, _layout.panel_x + _layout.panel_width, _layout.panel_y + _layout.panel_height, false);
draw_set_alpha(1);
draw_set_colour(c_white);
draw_rectangle(_layout.panel_x, _layout.panel_y, _layout.panel_x + _layout.panel_width, _layout.panel_y + _layout.panel_height, true);

draw_set_colour(make_color_rgb(35, 55, 85));
draw_rectangle(_layout.header_x + 1, _layout.header_y + 1, _layout.header_x + _layout.header_width - 1, _layout.header_y + _layout.header_height, false);
draw_set_colour(c_white);
var _header_text = "BITMAP EDITOR - 320x256 LOWRES, 5 BITPLANES, 32 COLOURS";
if (point_in_rectangle(mouse_x, mouse_y, _layout.header_x, _layout.header_y, _layout.header_x + _layout.header_width, _layout.header_y + _layout.header_height) || panel_dragging) {
    _header_text += " - Grab to drag";
}
draw_text(_layout.panel_x + 8, _layout.panel_y + 3, _header_text);

draw_set_colour(c_red);
draw_rectangle(_layout.close_x, _layout.close_y, _layout.close_x + 18, _layout.close_y + 18, false);
draw_set_colour(c_white);
draw_rectangle(_layout.close_x, _layout.close_y, _layout.close_x + 18, _layout.close_y + 18, true);
draw_text(_layout.close_x + 5, _layout.close_y, "X");

// Left tool rail.
draw_text(_layout.left_x, _layout.left_y, "TOOLS");
draw_text(_layout.left_x, _layout.left_y + 18, "ZOOM " + string(bitmap_zoom) + "x");
var _zoom_level = 1;
while (_zoom_level <= 6) {
    var _zoom_x = _layout.zoom_x + ((_zoom_level - 1) mod 3) * 42;
    var _zoom_y = _layout.zoom_y + ((_zoom_level - 1) div 3) * 22;
    draw_set_colour(bitmap_zoom == _zoom_level ? c_olive : c_dkgray);
    draw_rectangle(_zoom_x, _zoom_y, _zoom_x + 36, _zoom_y + 18, false);
    draw_set_colour(c_white);
    draw_rectangle(_zoom_x, _zoom_y, _zoom_x + 36, _zoom_y + 18, true);
    draw_text(_zoom_x + 10, _zoom_y, string(_zoom_level) + "x");
    _zoom_level += 1;
}

draw_set_colour(c_maroon);
draw_rectangle(_layout.clear_x, _layout.clear_y, _layout.clear_x + 120, _layout.clear_y + 20, false);
draw_set_colour(c_white);
draw_rectangle(_layout.clear_x, _layout.clear_y, _layout.clear_x + 120, _layout.clear_y + 20, true);
draw_text(_layout.clear_x + 8, _layout.clear_y + 1, "CLEAR TO COLOR00");
draw_text_ext(_layout.left_x, _layout.clear_y + 36, "LEFT: paint\nRIGHT: COLOR00\nMIDDLE: pan\nSPACE+LEFT: pan\nWHEEL: zoom", 18, 130);
draw_text_ext(_layout.left_x, _layout.clear_y + 142, "1x shows the native image. 3x is the default editing view.", 18, 130);

// Clipped viewport by selecting only the visible source region.
draw_set_colour(make_color_rgb(22, 22, 22));
draw_rectangle(_layout.canvas_x, _layout.canvas_y, _layout.canvas_x + _layout.canvas_width, _layout.canvas_y + _layout.canvas_height, false);
draw_set_colour(c_white);
draw_rectangle(_layout.canvas_x, _layout.canvas_y, _layout.canvas_x + _layout.canvas_width, _layout.canvas_y + _layout.canvas_height, true);

if (surface_exists(bitmap_surface)) {
    var _source_x = bitmap_scroll_x / bitmap_zoom;
    var _source_y = bitmap_scroll_y / bitmap_zoom;
    var _source_width = min(bitmap_width - _source_x, _layout.canvas_width / bitmap_zoom);
    var _source_height = min(bitmap_height - _source_y, _layout.canvas_height / bitmap_zoom);
    // Nearest-neighbour sampling keeps Amiga pixels hard-edged at every zoom.
    gpu_set_texfilter(false);
    draw_surface_part_ext(bitmap_surface, _source_x, _source_y, _source_width, _source_height, _layout.display_x, _layout.display_y, bitmap_zoom, bitmap_zoom, c_white, 1);
    // Restore filtered rendering for UI textures and anything drawn later.
    gpu_set_texfilter(true);
}

// Pixel grid only at useful editing magnifications.
if (bitmap_zoom >= 3) {
    draw_set_alpha(0.22);
    draw_set_colour(c_white);
    var _first_col = floor(bitmap_scroll_x / bitmap_zoom);
    var _last_col = min(bitmap_width, _first_col + ceil(_layout.canvas_width / bitmap_zoom) + 1);
    var _grid_col = _first_col;
    while (_grid_col <= _last_col) {
        var _line_x = _layout.display_x + (_grid_col * bitmap_zoom) - bitmap_scroll_x;
        if (_line_x >= _layout.canvas_x && _line_x <= _layout.canvas_x + _layout.canvas_width) draw_line(_line_x, _layout.canvas_y, _line_x, _layout.canvas_y + min(_layout.canvas_height, _layout.content_height));
        _grid_col += 1;
    }
    var _first_row = floor(bitmap_scroll_y / bitmap_zoom);
    var _last_row = min(bitmap_height, _first_row + ceil(_layout.canvas_height / bitmap_zoom) + 1);
    var _grid_row = _first_row;
    while (_grid_row <= _last_row) {
        var _line_y = _layout.display_y + (_grid_row * bitmap_zoom) - bitmap_scroll_y;
        if (_line_y >= _layout.canvas_y && _line_y <= _layout.canvas_y + _layout.canvas_height) draw_line(_layout.canvas_x, _line_y, _layout.canvas_x + min(_layout.canvas_width, _layout.content_width), _line_y);
        _grid_row += 1;
    }
    draw_set_alpha(1);
}

// Right palette rail: all 32 OCS/ECS colour registers.
draw_set_colour(c_white);
draw_text(_layout.right_x, _layout.right_y, "AMIGA 12-BIT PALETTE");
var _swatch_index = 0;
while (_swatch_index < 32) {
    var _swatch_col = _swatch_index mod 4;
    var _swatch_row = _swatch_index div 4;
    var _swatch_x = _layout.swatch_x + _swatch_col * (_layout.swatch_width + _layout.swatch_gap);
    var _swatch_y = _layout.swatch_y + _swatch_row * (_layout.swatch_height + _layout.swatch_gap);
    draw_set_colour(make_color_rgb(bitmap_colour_r[_swatch_index] * 17, bitmap_colour_g[_swatch_index] * 17, bitmap_colour_b[_swatch_index] * 17));
    draw_rectangle(_swatch_x, _swatch_y, _swatch_x + _layout.swatch_width, _swatch_y + _layout.swatch_height, false);
    draw_set_colour(bitmap_paint_index == _swatch_index ? c_yellow : c_white);
    draw_rectangle(_swatch_x, _swatch_y, _swatch_x + _layout.swatch_width, _swatch_y + _layout.swatch_height, true);
    draw_text(_swatch_x + 3, _swatch_y + 2, string(_swatch_index));
    _swatch_index += 1;
}

var _edit_index = bitmap_palette_edit_index;
var _hex_digits = "0123456789ABCDEF";
var _hex_text = string_char_at(_hex_digits, bitmap_colour_r[_edit_index] + 1)
    + string_char_at(_hex_digits, bitmap_colour_g[_edit_index] + 1)
    + string_char_at(_hex_digits, bitmap_colour_b[_edit_index] + 1);
draw_set_colour(c_white);
draw_text(_layout.right_x, _layout.slider_r_y - 24, "COLOR" + string(_edit_index) + "  #" + _hex_text);
draw_set_colour(make_color_rgb(bitmap_colour_r[_edit_index] * 17, bitmap_colour_g[_edit_index] * 17, bitmap_colour_b[_edit_index] * 17));
draw_rectangle(_layout.preview_x, _layout.preview_y, _layout.preview_x + _layout.preview_width, _layout.preview_y + _layout.preview_height, false);
draw_set_colour(c_white);
draw_rectangle(_layout.preview_x, _layout.preview_y, _layout.preview_x + _layout.preview_width, _layout.preview_y + _layout.preview_height, true);

var _channel = 0;
while (_channel < 3) {
    var _slider_y = _layout.slider_r_y;
    var _selected = bitmap_colour_r[_edit_index];
    var _label = "R";
    if (_channel == 1) { _slider_y = _layout.slider_g_y; _selected = bitmap_colour_g[_edit_index]; _label = "G"; }
    if (_channel == 2) { _slider_y = _layout.slider_b_y; _selected = bitmap_colour_b[_edit_index]; _label = "B"; }
    draw_set_colour(c_white);
    draw_text(_layout.slider_x - 18, _slider_y, _label);
    var _step = 0;
    while (_step < 16) {
        var _segment_x = _layout.slider_x + _step * _layout.slider_step_width;
        var _segment_colour = make_color_rgb(_step * 17, 0, 0);
        if (_channel == 1) _segment_colour = make_color_rgb(0, _step * 17, 0);
        if (_channel == 2) _segment_colour = make_color_rgb(0, 0, _step * 17);
        draw_set_colour(_segment_colour);
        draw_rectangle(_segment_x, _slider_y, _segment_x + _layout.slider_step_width, _slider_y + _layout.slider_height, false);
        draw_set_colour(_step == _selected ? c_yellow : c_dkgray);
        draw_rectangle(_segment_x, _slider_y, _segment_x + _layout.slider_step_width, _slider_y + _layout.slider_height, true);
        _step += 1;
    }
    draw_set_colour(c_white);
    draw_text(_layout.slider_x + _layout.slider_width + 4, _slider_y, string_char_at(_hex_digits, _selected + 1));
    _channel += 1;
}

draw_text_ext(_layout.right_x, _layout.slider_b_y + 38, "32 colours = five hardware bitplanes. Bitmap payload export will use a loader rather than the current 1 KB boot block.", 18, 225);
draw_set_colour(c_white);
