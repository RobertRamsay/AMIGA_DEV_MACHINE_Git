/// @desc The flow line from one column to the next: from the bottom-middle of
/// the column an ORG continues from (its lowest node, or the root itself when
/// empty), down, across into the gap between the columns, up (or down) to just
/// above the ORG, across, and down into the top of the ORG - a square S with
/// the house-style 45 degree corners. A soft glow, 2 px core, a small arrow at
/// the end and a pulse travelling along it. Green fading to orange when it
/// leaves INIT, orange from ORG to ORG. Drawn by the ORG root (depth 100, under
/// the program nodes), so it follows columns as they are dragged.

#macro ORG_FLOW_DROP 22
#macro ORG_FLOW_CUT 8
#macro ORG_FLOW_GREEN make_colour_rgb(70, 230, 120)
#macro ORG_FLOW_ORANGE make_colour_rgb(255, 150, 40)

/// Bounding box [x1, y1, x2, y2] (room coordinates) of root _root and its
/// connected nodes, plus the x of the lowest one's middle as [4].
function scr_org_flow_column(_root) {
    var _x1 = _root.node_x;
    var _y1 = _root.node_y;
    var _x2 = _root.node_x + _root.node_width;
    var _y2 = _root.node_y + _root.node_height;
    var _mid = _root.node_x + _root.node_width * 0.5;
    var _uid = _root.uid;
    with (obj_opcode_node) {
        if (is_connected && root_uid == _uid) {
            _x1 = min(_x1, node_x);
            _x2 = max(_x2, node_x + node_width);
            if (node_y + node_height > _y2) {
                _y2 = node_y + node_height;
                _mid = node_x + node_width * 0.5;
            }
        }
    }
    return [_x1 + global.pan_x, _y1 + global.pan_y, _x2 + global.pan_x, _y2 + global.pan_y, _mid + global.pan_x];
}

/// Corner points of the path with each inner corner cut at 45 degrees.
function scr_org_flow_points(_corners) {
    var _n = array_length(_corners) div 2;
    var _pts = [_corners[0], _corners[1]];
    var _i = 1;
    while (_i < _n - 1) {
        var _px = _corners[_i * 2 - 2];
        var _py = _corners[_i * 2 - 1];
        var _cx = _corners[_i * 2];
        var _cy = _corners[_i * 2 + 1];
        var _nx = _corners[_i * 2 + 2];
        var _ny = _corners[_i * 2 + 3];
        var _lin = point_distance(_px, _py, _cx, _cy);
        var _lout = point_distance(_cx, _cy, _nx, _ny);
        var _cut = min(ORG_FLOW_CUT, _lin * 0.5, _lout * 0.5);
        if (_cut < 1) {
            array_push(_pts, _cx, _cy);
        } else {
            array_push(_pts, _cx + (_px - _cx) / _lin * _cut, _cy + (_py - _cy) / _lin * _cut);
            array_push(_pts, _cx + (_nx - _cx) / _lout * _cut, _cy + (_ny - _cy) / _lout * _cut);
        }
        _i += 1;
    }
    array_push(_pts, _corners[_n * 2 - 2], _corners[_n * 2 - 1]);
    return _pts;
}

/// Colour at fraction _t (0 start .. 1 end) of the line.
function scr_org_flow_colour(_from_init, _t) {
    return _from_init ? merge_colour(ORG_FLOW_GREEN, ORG_FLOW_ORANGE, clamp(_t, 0, 1)) : ORG_FLOW_ORANGE;
}

/// Draws the flow line into ORG root _org (call from its Draw, before the body).
function scr_amiga_draw_org_flow(_org) {
    var _from_uid = _org.continues_from_root_uid;
    if (_from_uid == -1) return;
    var _from = noone;
    with (obj_amiga_root_node) if (uid == _from_uid) _from = id;
    if (_from == noone) return;

    var _src = scr_org_flow_column(_from);
    var _dst = scr_org_flow_column(_org);
    var _sx = _src[4];
    var _sy = _src[3];
    var _ex = _org.node_x + global.pan_x + _org.node_width * 0.5;
    var _ey = _org.node_y + global.pan_y;
    // The rise runs down the middle of the gap between the two columns.
    var _gx = _dst[0] > _src[2] ? (_src[2] + _dst[0]) * 0.5 : _dst[0] - ORG_FLOW_DROP;
    var _low = _sy + ORG_FLOW_DROP;
    var _high = _ey - ORG_FLOW_DROP;
    var _pts = scr_org_flow_points([_sx, _sy, _sx, _low, _gx, _low, _gx, _high, _ex, _high, _ex, _ey - 1]);

    var _n = array_length(_pts) div 2;
    var _len = [0];
    var _total = 0;
    var _i = 1;
    while (_i < _n) {
        _total += point_distance(_pts[_i * 2 - 2], _pts[_i * 2 - 1], _pts[_i * 2], _pts[_i * 2 + 1]);
        array_push(_len, _total);
        _i += 1;
    }
    if (_total < 1) return;
    var _from_init = (_from.root_type == "INIT");
    var _alpha = draw_get_alpha();

    // Glow (two soft passes), then the core.
    var _widths = [9, 5, 2];
    var _alphas = [0.10, 0.20, 0.95];
    var _pass = 0;
    while (_pass < 3) {
        draw_set_alpha(_alpha * _alphas[_pass]);
        _i = 1;
        while (_i < _n) {
            var _c1 = scr_org_flow_colour(_from_init, _len[_i - 1] / _total);
            var _c2 = scr_org_flow_colour(_from_init, _len[_i] / _total);
            draw_line_width_colour(_pts[_i * 2 - 2], _pts[_i * 2 - 1], _pts[_i * 2], _pts[_i * 2 + 1], _widths[_pass], _c1, _c2);
            if (_pass < 2 && _i < _n - 1) draw_circle_colour(_pts[_i * 2], _pts[_i * 2 + 1], _widths[_pass] * 0.5, _c2, _c2, false);
            _i += 1;
        }
        _pass += 1;
    }

    // Arrowhead pointing down into the ORG.
    var _ce = scr_org_flow_colour(_from_init, 1);
    draw_set_alpha(_alpha);
    draw_triangle_colour(_ex - 5, _ey - 8, _ex + 5, _ey - 8, _ex, _ey - 1, _ce, _ce, _ce, false);

    // A pulse travelling from start to end, roughly 160 px a second.
    var _d = (current_time * 0.16) mod (_total + 60);
    if (_d < _total) {
        _i = 1;
        while (_i < _n - 1 && _len[_i] < _d) _i += 1;
        var _seg = max(1, _len[_i] - _len[_i - 1]);
        var _f = (_d - _len[_i - 1]) / _seg;
        var _px = lerp(_pts[_i * 2 - 2], _pts[_i * 2], _f);
        var _py = lerp(_pts[_i * 2 - 1], _pts[_i * 2 + 1], _f);
        var _pc = merge_colour(scr_org_flow_colour(_from_init, _d / _total), c_white, 0.35);
        draw_set_alpha(_alpha * 0.25);
        draw_circle_colour(_px, _py, 6, _pc, _pc, false);
        draw_set_alpha(_alpha * 0.85);
        draw_circle_colour(_px, _py, 2.5, _pc, _pc, false);
    }
    draw_set_alpha(_alpha);
}
