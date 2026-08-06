/// @desc scr_bitmap_apply_line(_editor, _x0, _y0, _x1, _y1, _colour_index)
/// Applies one exact Bresenham line to the editor's indexed bitmap.
function scr_bitmap_apply_line(_editor, _x0, _y0, _x1, _y1, _colour_index) {
    var _line_x = _x0;
    var _line_y = _y0;
    var _line_dx = abs(_x1 - _line_x);
    var _line_sx = (_line_x < _x1) ? 1 : -1;
    var _line_dy = -abs(_y1 - _line_y);
    var _line_sy = (_line_y < _y1) ? 1 : -1;
    var _line_error = _line_dx + _line_dy;
    var _line_done = false;

    while (!_line_done) {
        var _pixel_offset = (_line_y * _editor.bitmap_width) + _line_x;

        if (_editor.bitmap_pixels[_pixel_offset] != _colour_index) {
            _editor.bitmap_pixels[_pixel_offset] = _colour_index;
            array_push(_editor.bitmap_dirty_pixels, _pixel_offset);
            _editor.bitmap_asset_dirty = true;
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
