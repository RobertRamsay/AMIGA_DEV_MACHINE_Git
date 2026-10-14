/// @desc The house style for every button, field, panel, card and tab.
/// Boxes have their top-left and bottom-right corners cut at 45 degrees (the
/// cut is 30% of the shorter side, capped so big panels keep a small notch),
/// and filled boxes get a slight diagonal tone: darker bottom-left, lighter
/// top-right. Square shapes stay for data: pixel grids, canvases, colour
/// swatches, waveforms, slider cells.
///
/// Fonts: UI_FONT for all tool / editor text, UI_FONT_SMALL for dense node and
/// palette text, UI_FONT_GUIDE for the walkthrough panels (tutorial page,
/// step guide, editor tour), UI_FONT_TITLE for headings.

#macro UI_FONT font_CyberVerse
#macro UI_FONT_SMALL font_CyberVerse_OpCode
#macro UI_FONT_TITLE font_CyberVerse
#macro UI_FONT_GUIDE font_Future_OpCode
#macro UI_BEVEL_RATIO 0.3
#macro UI_BEVEL_MAX 14
#macro UI_TONE_DARK 0.14
#macro UI_TONE_LIGHT 0.12

/// Corner cut for a box of _w x _h.
function scr_ui_bevel(_w, _h) {
    return clamp(round(min(_w, _h) * UI_BEVEL_RATIO), 2, UI_BEVEL_MAX);
}

/// Colour of the diagonal tone at (_x, _y) inside the box.
function scr_ui_tone(_fill, _x1, _y1, _x2, _y2, _x, _y) {
    var _t = ((_x - _x1) / max(1, _x2 - _x1) + (_y2 - _y) / max(1, _y2 - _y1)) * 0.5;   // 0 bottom-left .. 1 top-right
    if (_t < 0.5) return merge_colour(_fill, c_black, UI_TONE_DARK * (1 - _t * 2));
    return merge_colour(_fill, c_white, UI_TONE_LIGHT * (_t * 2 - 1));
}

/// The six corners of a bevelled box, clockwise from the top-left cut.
function scr_ui_box_points(_x1, _y1, _x2, _y2) {
    var _b = scr_ui_bevel(_x2 - _x1, _y2 - _y1);
    return [_x1 + _b, _y1, _x2, _y1, _x2, _y2 - _b, _x2 - _b, _y2, _x1, _y2, _x1, _y1 + _b];
}

/// Filled bevelled box with the diagonal tone (_tone false: flat colour).
function scr_ui_box_fill(_x1, _y1, _x2, _y2, _fill, _tone = true) {
    if (_x2 - _x1 < 2 || _y2 - _y1 < 2) {
        draw_set_colour(_fill);
        draw_rectangle(_x1, _y1, _x2, _y2, false);
        return;
    }
    var _p = scr_ui_box_points(_x1, _y1, _x2 + 1, _y2 + 1);
    var _cx = (_x1 + _x2 + 1) * 0.5;
    var _cy = (_y1 + _y2 + 1) * 0.5;
    var _alpha = draw_get_alpha();
    var _centre = _tone ? scr_ui_tone(_fill, _x1, _y1, _x2, _y2, _cx, _cy) : _fill;
    draw_primitive_begin(pr_trianglelist);
    var _i = 0;
    while (_i < 6) {
        var _j = (_i + 1) mod 6;
        var _ax = _p[_i * 2];
        var _ay = _p[_i * 2 + 1];
        var _bx = _p[_j * 2];
        var _by = _p[_j * 2 + 1];
        draw_vertex_colour(_cx, _cy, _centre, _alpha);
        draw_vertex_colour(_ax, _ay, _tone ? scr_ui_tone(_fill, _x1, _y1, _x2, _y2, _ax, _ay) : _fill, _alpha);
        draw_vertex_colour(_bx, _by, _tone ? scr_ui_tone(_fill, _x1, _y1, _x2, _y2, _bx, _by) : _fill, _alpha);
        _i += 1;
    }
    draw_primitive_end();
}

/// Bevelled outline, _thickness pixels inwards.
function scr_ui_box_outline(_x1, _y1, _x2, _y2, _colour, _thickness = 1) {
    draw_set_colour(_colour);
    var _k = 0;
    while (_k < _thickness) {
        var _p = scr_ui_box_points(_x1 + _k, _y1 + _k, _x2 - _k, _y2 - _k);
        draw_primitive_begin(pr_linestrip);
        var _i = 0;
        while (_i <= 6) {
            var _n = (_i mod 6) * 2;
            draw_vertex(_p[_n] + 0.5, _p[_n + 1] + 0.5);
            _i += 1;
        }
        draw_primitive_end();
        _k += 1;
    }
}

/// Fill and outline in one call; pass -1 to leave either out.
function scr_ui_box(_x1, _y1, _x2, _y2, _fill, _outline, _tone = true) {
    if (_fill != -1) scr_ui_box_fill(_x1, _y1, _x2, _y2, _fill, _tone);
    if (_outline != -1) scr_ui_box_outline(_x1, _y1, _x2, _y2, _outline);
}

/// A button: bevelled box, label centred both ways in the current font.
/// _hover lightens it and outlines it yellow; disabled buttons are dimmed.
function scr_ui_button(_x1, _y1, _x2, _y2, _label, _fill, _hover = false, _enabled = true, _text_colour = c_white) {
    var _colour = _fill;
    if (!_enabled) _colour = merge_colour(_fill, make_colour_rgb(30, 32, 40), 0.65);
    else if (_hover) _colour = merge_colour(_fill, c_white, 0.2);
    scr_ui_box(_x1, _y1, _x2, _y2, _colour, _enabled ? (_hover ? c_yellow : merge_colour(_fill, c_white, 0.55)) : make_colour_rgb(80, 84, 100));
    draw_set_colour(_enabled ? _text_colour : make_colour_rgb(120, 125, 140));
    scr_ui_text_centred((_x1 + _x2) * 0.5, (_y1 + _y2) * 0.5, _label);
}

/// Text centred on (_x, _y), restoring left / top alignment afterwards.
function scr_ui_text_centred(_x, _y, _text) {
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_text(round(_x), round(_y), _text);
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
}

/// Text vertically centred in the band _y1.._y2, starting at _x.
function scr_ui_text_mid(_x, _y1, _y2, _text) {
    draw_set_valign(fa_middle);
    draw_text(round(_x), round((_y1 + _y2) * 0.5), _text);
    draw_set_valign(fa_top);
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
