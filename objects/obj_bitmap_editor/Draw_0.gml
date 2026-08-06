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
while (_zoom_level <= 16) {
    var _zoom_x = _layout.zoom_x + ((_zoom_level - 1) mod 4) * (_layout.zoom_button_width + _layout.zoom_button_gap_x);
    var _zoom_y = _layout.zoom_y + ((_zoom_level - 1) div 4) * (_layout.zoom_button_height + _layout.zoom_button_gap_y);
    draw_set_colour(bitmap_zoom == _zoom_level ? c_olive : c_dkgray);
    draw_rectangle(_zoom_x, _zoom_y, _zoom_x + _layout.zoom_button_width, _zoom_y + _layout.zoom_button_height, false);
    draw_set_colour(c_white);
    draw_rectangle(_zoom_x, _zoom_y, _zoom_x + _layout.zoom_button_width, _zoom_y + _layout.zoom_button_height, true);
    draw_text(_zoom_x + 4, _zoom_y, string(_zoom_level) + "x");
    _zoom_level += 1;
}

draw_set_colour(c_maroon);
draw_rectangle(_layout.clear_x, _layout.clear_y, _layout.clear_x + 120, _layout.clear_y + 20, false);
draw_set_colour(c_white);
draw_rectangle(_layout.clear_x, _layout.clear_y, _layout.clear_x + 120, _layout.clear_y + 20, true);
draw_text(_layout.clear_x + 8, _layout.clear_y + 1, "CLEAR (0)");

draw_set_colour(bitmap_grid_size > 0 ? c_olive : c_dkgray);
draw_rectangle(_layout.grid_toggle_x, _layout.grid_toggle_y, _layout.grid_toggle_x + 120, _layout.grid_toggle_y + 20, false);
draw_set_colour(c_white);
draw_rectangle(_layout.grid_toggle_x, _layout.grid_toggle_y, _layout.grid_toggle_x + 120, _layout.grid_toggle_y + 20, true);
draw_text(_layout.grid_toggle_x + 8, _layout.grid_toggle_y + 1, bitmap_grid_size > 0 ? "GRID: " + string(bitmap_grid_size) + "x" + string(bitmap_grid_size) : "GRID: OFF");

draw_set_colour(c_white);
draw_text(_layout.brush_label_x, _layout.brush_label_y, "BRUSH");
var _brush_sizes = [1, 3, 5, 7, 9];
var _brush_button_index = 0;

while (_brush_button_index < array_length(_brush_sizes)) {
    var _brush_size = _brush_sizes[_brush_button_index];
    var _brush_button_x = _layout.brush_x + _brush_button_index * (_layout.brush_button_width + _layout.brush_button_gap);
    draw_set_colour(bitmap_brush_size == _brush_size ? c_olive : c_dkgray);
    draw_rectangle(_brush_button_x, _layout.brush_y, _brush_button_x + _layout.brush_button_width, _layout.brush_y + _layout.brush_button_height, false);
    draw_set_colour(c_white);
    draw_rectangle(_brush_button_x, _layout.brush_y, _brush_button_x + _layout.brush_button_width, _layout.brush_y + _layout.brush_button_height, true);
    draw_text(_brush_button_x + 6, _layout.brush_y + 1, string(_brush_size));
    _brush_button_index += 1;
}

var _tool_names = ["DRAW", "LINE", "FILL"];
var _tool_index = 0;

while (_tool_index < array_length(_tool_names)) {
    var _tool_x = _layout.tool_x + _tool_index * (_layout.tool_width + _layout.tool_gap);
    var _tool_name = _tool_names[_tool_index];
    draw_set_colour(bitmap_tool == _tool_name ? c_olive : c_dkgray);
    draw_rectangle(_tool_x, _layout.tool_y, _tool_x + _layout.tool_width, _layout.tool_y + _layout.tool_height, false);
    draw_set_colour(c_white);
    draw_rectangle(_tool_x, _layout.tool_y, _tool_x + _layout.tool_width, _layout.tool_y + _layout.tool_height, true);
    draw_text(_tool_x + 10, _layout.tool_y + 3, _tool_name);
    _tool_index += 1;
}

draw_set_colour(bitmap_tool == "GRADIENT" ? c_olive : c_dkgray);
draw_rectangle(_layout.gradient_tool_x, _layout.gradient_tool_y, _layout.gradient_tool_x + _layout.gradient_tool_width, _layout.gradient_tool_y + _layout.tool_height, false);
draw_set_colour(c_white);
draw_rectangle(_layout.gradient_tool_x, _layout.gradient_tool_y, _layout.gradient_tool_x + _layout.gradient_tool_width, _layout.gradient_tool_y + _layout.tool_height, true);
draw_text(_layout.gradient_tool_x + 10, _layout.gradient_tool_y + 3, "GRADIENT FILL");

var _gradient_colour_1_x = _layout.gradient_tool_x;
var _gradient_colour_2_x = _layout.gradient_tool_x + _layout.gradient_colour_width + _layout.tool_gap;
var _gradient_colour_1 = make_color_rgb(bitmap_colour_r[bitmap_gradient_colour_1] * 17, bitmap_colour_g[bitmap_gradient_colour_1] * 17, bitmap_colour_b[bitmap_gradient_colour_1] * 17);
var _gradient_colour_2 = make_color_rgb(bitmap_colour_r[bitmap_gradient_colour_2] * 17, bitmap_colour_g[bitmap_gradient_colour_2] * 17, bitmap_colour_b[bitmap_gradient_colour_2] * 17);

draw_set_colour(c_white);
draw_text(_gradient_colour_1_x, _layout.gradient_colour_label_y, "COL1: " + string(bitmap_gradient_colour_1));
draw_text(_gradient_colour_2_x, _layout.gradient_colour_label_y, "COL2: " + string(bitmap_gradient_colour_2));

draw_set_colour(_gradient_colour_1);
draw_rectangle(_gradient_colour_1_x, _layout.gradient_colour_y, _gradient_colour_1_x + _layout.gradient_colour_width, _layout.gradient_colour_y + _layout.tool_height, false);
draw_set_colour(c_white);
draw_rectangle(_gradient_colour_1_x, _layout.gradient_colour_y, _gradient_colour_1_x + _layout.gradient_colour_width, _layout.gradient_colour_y + _layout.tool_height, true);

draw_set_colour(_gradient_colour_2);
draw_rectangle(_gradient_colour_2_x, _layout.gradient_colour_y, _gradient_colour_2_x + _layout.gradient_colour_width, _layout.gradient_colour_y + _layout.tool_height, false);
draw_set_colour(c_white);
draw_rectangle(_gradient_colour_2_x, _layout.gradient_colour_y, _gradient_colour_2_x + _layout.gradient_colour_width, _layout.gradient_colour_y + _layout.tool_height, true);

draw_set_colour(bitmap_gradient_include_edge ? c_olive : c_dkgray);
draw_rectangle(_layout.gradient_edge_x, _layout.gradient_edge_y, _layout.gradient_edge_x + _layout.gradient_edge_width, _layout.gradient_edge_y + _layout.tool_height, false);
draw_set_colour(c_white);
draw_rectangle(_layout.gradient_edge_x, _layout.gradient_edge_y, _layout.gradient_edge_x + _layout.gradient_edge_width, _layout.gradient_edge_y + _layout.tool_height, true);
draw_text(_layout.gradient_edge_x + 10, _layout.gradient_edge_y + 3, bitmap_gradient_include_edge ? "EAT EDGE (GROW)" : "KEEP EDGE (STOP)");

var _utility_x_2 = _layout.left_x + _layout.utility_button_width + _layout.utility_button_gap;
draw_set_colour(array_length(bitmap_undo_stack) > 0 ? c_olive : c_dkgray);
draw_rectangle(_layout.left_x, _layout.history_y, _layout.left_x + _layout.utility_button_width, _layout.history_y + _layout.utility_button_height, false);
draw_set_colour(c_white);
draw_rectangle(_layout.left_x, _layout.history_y, _layout.left_x + _layout.utility_button_width, _layout.history_y + _layout.utility_button_height, true);
draw_text(_layout.left_x + 8, _layout.history_y + 3, "UNDO (" + string(array_length(bitmap_undo_stack)) + ")");

draw_set_colour(array_length(bitmap_redo_stack) > 0 ? c_olive : c_dkgray);
draw_rectangle(_utility_x_2, _layout.history_y, _utility_x_2 + _layout.utility_button_width, _layout.history_y + _layout.utility_button_height, false);
draw_set_colour(c_white);
draw_rectangle(_utility_x_2, _layout.history_y, _utility_x_2 + _layout.utility_button_width, _layout.history_y + _layout.utility_button_height, true);
draw_text(_utility_x_2 + 8, _layout.history_y + 3, "REDO (" + string(array_length(bitmap_redo_stack)) + ")");

draw_set_colour(make_color_rgb(35, 70, 95));
draw_rectangle(_layout.left_x, _layout.file_y, _layout.left_x + _layout.utility_button_width, _layout.file_y + _layout.utility_button_height, false);
draw_rectangle(_utility_x_2, _layout.file_y, _utility_x_2 + _layout.utility_button_width, _layout.file_y + _layout.utility_button_height, false);
draw_set_colour(c_white);
draw_rectangle(_layout.left_x, _layout.file_y, _layout.left_x + _layout.utility_button_width, _layout.file_y + _layout.utility_button_height, true);
draw_rectangle(_utility_x_2, _layout.file_y, _utility_x_2 + _layout.utility_button_width, _layout.file_y + _layout.utility_button_height, true);
draw_text(_layout.left_x + 8, _layout.file_y + 3, "SAVE EDITABLE");
draw_text(_utility_x_2 + 8, _layout.file_y + 3, "LOAD EDITABLE");

draw_set_colour(make_color_rgb(55, 85, 55));
draw_rectangle(_layout.left_x, _layout.output_y, _layout.left_x + _layout.utility_button_width, _layout.output_y + _layout.utility_button_height, false);
draw_set_colour(make_color_rgb(105, 55, 25));
draw_rectangle(_utility_x_2, _layout.output_y, _utility_x_2 + _layout.utility_button_width, _layout.output_y + _layout.utility_button_height, false);
draw_set_colour(c_white);
draw_rectangle(_layout.left_x, _layout.output_y, _layout.left_x + _layout.utility_button_width, _layout.output_y + _layout.utility_button_height, true);
draw_rectangle(_utility_x_2, _layout.output_y, _utility_x_2 + _layout.utility_button_width, _layout.output_y + _layout.utility_button_height, true);
draw_text(_layout.left_x + 8, _layout.output_y + 3, "EXPORT PNG");
draw_text(_utility_x_2 + 8, _layout.output_y + 3, "TEST BITMAP");

// Canvas contents are GPU-clipped to the viewport. This prevents the final
// scaled texel or grid line leaking over either edge.
draw_set_colour(make_color_rgb(22, 22, 22));
draw_rectangle(_layout.canvas_x, _layout.canvas_y, _layout.canvas_x + _layout.canvas_width, _layout.canvas_y + _layout.canvas_height, false);
draw_set_colour(c_white);
draw_rectangle(_layout.canvas_x, _layout.canvas_y, _layout.canvas_x + _layout.canvas_width, _layout.canvas_y + _layout.canvas_height, true);

var _previous_scissor = gpu_get_scissor();
gpu_set_scissor(_layout.canvas_x + 1, _layout.canvas_y + 1, _layout.canvas_width - 2, _layout.canvas_height - 2);

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

// Exact pixel-stepped LINE preview. The committed result uses the same
// Bresenham decisions in scr_bitmap_apply_line().
if (bitmap_tool == "LINE" && bitmap_line_active) {
    var _preview_line_x = bitmap_line_start_x;
    var _preview_line_y = bitmap_line_start_y;
    var _preview_target_x = bitmap_line_end_x;
    var _preview_target_y = bitmap_line_end_y;
    var _preview_dx = abs(_preview_target_x - _preview_line_x);
    var _preview_sx = (_preview_line_x < _preview_target_x) ? 1 : -1;
    var _preview_dy = -abs(_preview_target_y - _preview_line_y);
    var _preview_sy = (_preview_line_y < _preview_target_y) ? 1 : -1;
    var _preview_error = _preview_dx + _preview_dy;
    var _preview_done = false;
    var _preview_colour_index = bitmap_line_index;
    var _preview_brush_radius = bitmap_brush_size div 2;
    var _preview_brush_limit = bitmap_brush_size * 0.5;
    var _preview_brush_limit_sq = _preview_brush_limit * _preview_brush_limit;

    draw_set_alpha(0.78);
    draw_set_colour(make_color_rgb(bitmap_colour_r[_preview_colour_index] * 17, bitmap_colour_g[_preview_colour_index] * 17, bitmap_colour_b[_preview_colour_index] * 17));

    while (!_preview_done) {
        var _preview_brush_y = -_preview_brush_radius;

        while (_preview_brush_y <= _preview_brush_radius) {
            var _preview_brush_x = -_preview_brush_radius;

            while (_preview_brush_x <= _preview_brush_radius) {
                if ((_preview_brush_x * _preview_brush_x) + (_preview_brush_y * _preview_brush_y) <= _preview_brush_limit_sq) {
                    var _preview_stamp_x = _preview_line_x + _preview_brush_x;
                    var _preview_stamp_y = _preview_line_y + _preview_brush_y;

                    if (_preview_stamp_x >= 0 && _preview_stamp_x < bitmap_width
                    && _preview_stamp_y >= 0 && _preview_stamp_y < bitmap_height) {
                        var _preview_cell_x = _layout.display_x + (_preview_stamp_x * bitmap_zoom) - bitmap_scroll_x;
                        var _preview_cell_y = _layout.display_y + (_preview_stamp_y * bitmap_zoom) - bitmap_scroll_y;
                        draw_rectangle(_preview_cell_x, _preview_cell_y, _preview_cell_x + bitmap_zoom, _preview_cell_y + bitmap_zoom, false);
                    }
                }

                _preview_brush_x += 1;
            }

            _preview_brush_y += 1;
        }

        if (_preview_line_x == _preview_target_x && _preview_line_y == _preview_target_y) {
            _preview_done = true;
        } else {
            var _preview_error_2 = 2 * _preview_error;
            if (_preview_error_2 >= _preview_dy) { _preview_error += _preview_dy; _preview_line_x += _preview_sx; }
            if (_preview_error_2 <= _preview_dx) { _preview_error += _preview_dx; _preview_line_y += _preview_sy; }
        }
    }

    draw_set_alpha(1);
}

// Gradient direction preview. The first endpoint is also the flood-fill seed.
if (bitmap_tool == "GRADIENT" && bitmap_gradient_active) {
    var _gradient_preview_x1 = _layout.display_x + (bitmap_gradient_start_x * bitmap_zoom) - bitmap_scroll_x + (bitmap_zoom * 0.5);
    var _gradient_preview_y1 = _layout.display_y + (bitmap_gradient_start_y * bitmap_zoom) - bitmap_scroll_y + (bitmap_zoom * 0.5);
    var _gradient_preview_x2 = _layout.display_x + (bitmap_gradient_end_x * bitmap_zoom) - bitmap_scroll_x + (bitmap_zoom * 0.5);
    var _gradient_preview_y2 = _layout.display_y + (bitmap_gradient_end_y * bitmap_zoom) - bitmap_scroll_y + (bitmap_zoom * 0.5);
    draw_set_alpha(0.9);
    draw_set_colour(c_yellow);
    draw_line_width(_gradient_preview_x1, _gradient_preview_y1, _gradient_preview_x2, _gradient_preview_y2, 2);
    draw_circle(_gradient_preview_x1, _gradient_preview_y1, max(2, bitmap_zoom * 0.35), false);
    draw_circle(_gradient_preview_x2, _gradient_preview_y2, max(2, bitmap_zoom * 0.35), true);
    draw_set_alpha(1);
}

// Optional 4, 8, 16 or 32-pixel tile grid, disabled by default.
if (bitmap_grid_size > 0) {
    draw_set_alpha(0.22);
    draw_set_colour(c_white);
    var _first_col = floor(floor(bitmap_scroll_x / bitmap_zoom) / bitmap_grid_size) * bitmap_grid_size;
    var _last_col = min(bitmap_width, _first_col + ceil(_layout.canvas_width / bitmap_zoom) + 1);
    var _grid_top = max(_layout.canvas_y, _layout.display_y - bitmap_scroll_y);
    var _grid_bottom = min(_layout.canvas_y + _layout.canvas_height, _layout.display_y - bitmap_scroll_y + _layout.content_height);
    var _grid_col = _first_col;
    while (_grid_col <= _last_col) {
        var _line_x = _layout.display_x + (_grid_col * bitmap_zoom) - bitmap_scroll_x;
        if (_line_x >= _layout.canvas_x && _line_x <= _layout.canvas_x + _layout.canvas_width) draw_line(_line_x, _grid_top, _line_x, _grid_bottom);
        _grid_col += bitmap_grid_size;
    }
    var _first_row = floor(floor(bitmap_scroll_y / bitmap_zoom) / bitmap_grid_size) * bitmap_grid_size;
    var _last_row = min(bitmap_height, _first_row + ceil(_layout.canvas_height / bitmap_zoom) + 1);
    var _grid_left = max(_layout.canvas_x, _layout.display_x - bitmap_scroll_x);
    var _grid_right = min(_layout.canvas_x + _layout.canvas_width, _layout.display_x - bitmap_scroll_x + _layout.content_width);
    var _grid_row = _first_row;
    while (_grid_row <= _last_row) {
        var _line_y = _layout.display_y + (_grid_row * bitmap_zoom) - bitmap_scroll_y;
        if (_line_y >= _layout.canvas_y && _line_y <= _layout.canvas_y + _layout.canvas_height) draw_line(_grid_left, _line_y, _grid_right, _line_y);
        _grid_row += bitmap_grid_size;
    }
    draw_set_alpha(1);
}

gpu_set_scissor(_previous_scissor);

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

draw_text_ext(_layout.right_x, _layout.slider_b_y + 38, "32 colours = five hardware bitplanes. TEST BITMAP builds a bootable OFS disk and loads the 51,200-byte display through AmigaDOS.", 18, 225);

draw_set_colour(c_white);
draw_text(_layout.panel_x + 12, _layout.help_line_1_y, "LEFT: use selected tool     RIGHT: use COLOR00     ALT+LEFT: pick pen     HOLD SPACE: pan     CTRL+Z/Y: undo/redo     CTRL+S/L: save/load");
draw_text(_layout.panel_x + 12, _layout.help_line_2_y, "WHEEL: zoom     DRAW: freehand     LINE: drag/release     FILL: connected area     GRADIENT: drag direction");
draw_set_colour(c_white);
