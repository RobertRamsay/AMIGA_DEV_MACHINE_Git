/// @desc scr_draw_stepper_button(_x, _y, _width, _height, _label)
/// Draws a small clickable +/- style button. Purely visual — callers
/// handle their own click detection at the same coordinates.
function scr_draw_stepper_button(_x, _y, _width, _height, _label) {
    scr_ui_button(_x, _y, _x + _width, _y + _height, _label, c_dkgray);
}

/// The top band (_y1.._band_y2) of a bevelled box _x1,_y1,_x2,_y2, filled with
/// the diagonal tone. Follows the box's top-left cut, so a header strip drawn
/// over scr_ui_box_fill of the same box lines up with it exactly.
function scr_ui_header_band(_x1, _y1, _x2, _y2, _band_y2, _fill) {
    var _b = scr_ui_bevel(_x2 + 1 - _x1, _y2 + 1 - _y1);
    var _bx2 = _x2 + 1;
    var _by2 = _band_y2 + 1;
    var _band_h = _by2 - _y1;
    var _alpha = draw_get_alpha();
    var _pts;
    if (_band_h >= _b) {
        _pts = [_x1 + _b, _y1, _bx2, _y1, _bx2, _by2, _x1, _by2, _x1, _y1 + _b];
    } else {
        _pts = [_x1 + _b, _y1, _bx2, _y1, _bx2, _by2, _x1 + _b - _band_h, _by2];
    }
    var _n = array_length(_pts) div 2;
    draw_primitive_begin(pr_trianglelist);
    var _i = 1;
    while (_i < _n - 1) {
        var _k = 0;
        repeat (3) {
            var _p = (_k == 0) ? 0 : ((_k == 1) ? _i : _i + 1);
            var _px = _pts[_p * 2];
            var _py = _pts[_p * 2 + 1];
            draw_vertex_colour(_px, _py, scr_ui_tone(_fill, _x1, _y1, _x2, _band_y2, _px, _py), _alpha);
            _k += 1;
        }
        _i += 1;
    }
    draw_primitive_end();
}

/// _text cut to fit _width pixels in the current font (".." marks a cut).
function scr_ui_fit_label(_text, _width) {
    if (string_width(_text) <= _width) return _text;
    var _cut = _text;
    while (string_length(_cut) > 1 && string_width(_cut + "..") > _width) {
        _cut = string_copy(_cut, 1, string_length(_cut) - 1);
    }
    return _cut + "..";
}
