/// @desc scr_bitmap_apply_line(_editor, _x0, _y0, _x1, _y1, _colour_index)
/// Applies one exact Bresenham line using the editor's odd circular brush.
function scr_bitmap_apply_line(_editor, _x0, _y0, _x1, _y1, _colour_index) {
    var _line_x = _x0;
    var _line_y = _y0;
    var _line_dx = abs(_x1 - _line_x);
    var _line_sx = (_line_x < _x1) ? 1 : -1;
    var _line_dy = -abs(_y1 - _line_y);
    var _line_sy = (_line_y < _y1) ? 1 : -1;
    var _line_error = _line_dx + _line_dy;
    var _line_done = false;
    var _brush_radius = _editor.bitmap_brush_size div 2;
    var _brush_limit = _editor.bitmap_brush_size * 0.5;
    var _brush_limit_sq = _brush_limit * _brush_limit;

    while (!_line_done) {
        var _brush_y = -_brush_radius;

        while (_brush_y <= _brush_radius) {
            var _brush_x = -_brush_radius;

            while (_brush_x <= _brush_radius) {
                if ((_brush_x * _brush_x) + (_brush_y * _brush_y) <= _brush_limit_sq) {
                    var _stamp_x = _line_x + _brush_x;
                    var _stamp_y = _line_y + _brush_y;

                    if (_stamp_x >= 0 && _stamp_x < _editor.bitmap_width
                    && _stamp_y >= 0 && _stamp_y < _editor.bitmap_height) {
                        var _pixel_offset = (_stamp_y * _editor.bitmap_width) + _stamp_x;

                        if (_editor.bitmap_pixels[_pixel_offset] != _colour_index) {
                            _editor.bitmap_pixels[_pixel_offset] = _colour_index;
                            array_push(_editor.bitmap_dirty_pixels, _pixel_offset);
                            _editor.bitmap_asset_dirty = true;
                        }
                    }
                }

                _brush_x += 1;
            }

            _brush_y += 1;
        }

        if (_line_x == _x1 && _line_y == _y1) {
            _line_done = true;
        } else {
            var _line_error_2 = 2 * _line_error;

            if (_line_error_2 >= _line_dy) {
                _line_error += _line_dy;
                _line_x += _line_sx;
            }

            if (_line_error_2 <= _line_dx) {
                _line_error += _line_dx;
                _line_y += _line_sy;
            }
        }
    }
}
