/// @desc Shape tools shared by the bitmap, sprite and BOB editors: CIRCLE and
/// FILLED CIRCLE. Press sets the centre, drag sets the radius, release draws.
/// Pixel lists are flat [x0, y0, x1, y1, ...] arrays clipped to the image.

/// Radius of a circle centred on (_cx, _cy) that reaches (_x, _y).
function scr_shape_circle_radius(_cx, _cy, _x, _y) {
    return round(point_distance(_cx, _cy, _x, _y));
}

/// Pixels of a circle (outline, midpoint algorithm) or a filled disc,
/// clipped to _width x _height.
function scr_shape_circle_pixels(_cx, _cy, _r, _filled, _width, _height) {
    var _out = [];
    if (_r <= 0) {
        if (_cx >= 0 && _cx < _width && _cy >= 0 && _cy < _height) array_push(_out, _cx, _cy);
        return _out;
    }
    if (_filled) {
        var _dy = -_r;
        while (_dy <= _r) {
            var _half = floor(sqrt(_r * _r - _dy * _dy) + 0.5);
            var _y = _cy + _dy;
            if (_y >= 0 && _y < _height) {
                var _x = max(0, _cx - _half);
                var _x_end = min(_width - 1, _cx + _half);
                while (_x <= _x_end) {
                    array_push(_out, _x, _y);
                    _x += 1;
                }
            }
            _dy += 1;
        }
        return _out;
    }
    var _seen = {};
    var _px = _r;
    var _py = 0;
    var _err = 1 - _r;
    while (_px >= _py) {
        var _pts = [_px, _py, _py, _px, -_py, _px, -_px, _py, -_px, -_py, -_py, -_px, _py, -_px, _px, -_py];
        var _k = 0;
        while (_k < 16) {
            var _sx = _cx + _pts[_k];
            var _sy = _cy + _pts[_k + 1];
            var _key = string(_sx) + "," + string(_sy);
            if (_sx >= 0 && _sx < _width && _sy >= 0 && _sy < _height && !variable_struct_exists(_seen, _key)) {
                _seen[$ _key] = true;
                array_push(_out, _sx, _sy);
            }
            _k += 2;
        }
        _py += 1;
        if (_err < 0) {
            _err += 2 * _py + 1;
        } else {
            _px -= 1;
            _err += 2 * (_py - _px) + 1;
        }
    }
    return _out;
}

/// Pointer position in image pixels, clamped to the image, so a drag that
/// leaves the canvas still ends on its edge instead of being dropped.
function scr_shape_clamp_pixel(_value, _size) {
    return clamp(_value, 0, _size - 1);
}
