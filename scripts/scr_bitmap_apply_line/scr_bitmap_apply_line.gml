/// @desc scr_bitmap_apply_line(_editor, _x0, _y0, _x1, _y1, _colour_index, [_use_dither])
/// Applies one exact Bresenham line using the editor's odd circular brush.
function scr_bitmap_apply_line(_editor, _x0, _y0, _x1, _y1, _colour_index, _use_dither = false) {
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
    var _dither_level = 0;
    var _bayer_8 = [];

    if (_use_dither && string_copy(_editor.bitmap_dither_pattern, 1, 5) == "BAYER") {
        _dither_level = real(string_delete(_editor.bitmap_dither_pattern, 1, 5));
        _bayer_8 = [
             0, 32,  8, 40,  2, 34, 10, 42,
            48, 16, 56, 24, 50, 18, 58, 26,
            12, 44,  4, 36, 14, 46,  6, 38,
            60, 28, 52, 20, 62, 30, 54, 22,
             3, 35, 11, 43,  1, 33,  9, 41,
            51, 19, 59, 27, 49, 17, 57, 25,
            15, 47,  7, 39, 13, 45,  5, 37,
            63, 31, 55, 23, 61, 29, 53, 21
        ];
    }

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
                        var _stamp_colour = _colour_index;

                        if (_use_dither) {
                            var _dither_first = false;

                            if (_editor.bitmap_dither_pattern == "CHECKER") {
                                _dither_first = ((_stamp_x + _stamp_y) mod 2) == 0;
                            } else if (_editor.bitmap_dither_pattern == "INTERLACE") {
                                _dither_first = (_stamp_y mod 2) == 0;
                            } else {
                                var _threshold = _dither_level * 8;
                                var _bayer_value = _bayer_8[((_stamp_y mod 8) * 8) + (_stamp_x mod 8)];
                                _dither_first = _bayer_value < _threshold;
                            }

                            if (_editor.bitmap_dither_invert) {
                                _dither_first = !_dither_first;
                            }

                            var _dither_second = _editor.bitmap_dither_use_colour_2
                                ? _editor.bitmap_gradient_colour_2
                                : 0;
                            _stamp_colour = _dither_first
                                ? _editor.bitmap_gradient_colour_1
                                : _dither_second;
                        }

                        if (_editor.bitmap_pixels[_pixel_offset] != _stamp_colour) {
                            _editor.bitmap_pixels[_pixel_offset] = _stamp_colour;
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
