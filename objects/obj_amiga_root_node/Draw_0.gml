var _dx = node_x + global.pan_x;
var _dy = node_y + global.pan_y;

draw_set_font(UI_FONT);

// The flow line in from the column this ORG continues (under the nodes).
if (root_type == "ORG") {
    scr_amiga_draw_org_flow(id);
}

var _body_colour = c_orange;

if (root_type == "INIT") {
    _body_colour = make_color_rgb(100, 150, 250);
}
var _is_orphaned = (root_type == "ORG") && (continues_from_root_uid == -1);

if (_is_orphaned) {
    _body_colour = c_red;
}

// Hovering INIT/BUILD (a click builds and runs): the block pulses brighter,
// rings ripple outwards from it and it says BUILD & RUN.
var _build_hover = root_type == "INIT" && !is_dragging && !scr_amiga_modal_open() && !scr_tutorial_guide_mouse_over()
    && point_in_rectangle(mouse_x, mouse_y, _dx, _dy, _dx + node_width, _dy + node_height);
var _outline_colour = c_white;
if (_build_hover) {
    var _pulse = 0.5 + 0.5 * sin(current_time * 0.008);
    var _ring = 0;
    while (_ring < 3) {
        var _phase = frac(current_time / 900 + _ring / 3);
        var _grow = 2 + _phase * 18;
        draw_set_alpha((1 - _phase) * 0.8);
        scr_ui_box_outline(_dx + 1 - _grow, _dy + 1 - _grow, _dx + node_width - 1 + _grow, _dy + node_height - 1 + _grow,
            merge_colour(c_yellow, make_colour_rgb(120, 200, 255), _phase));
        _ring += 1;
    }
    draw_set_alpha(1);
    _body_colour = merge_colour(_body_colour, c_white, 0.12 + 0.28 * _pulse);
    _outline_colour = c_yellow;
}

scr_ui_box(_dx + 1, _dy + 1, _dx + node_width - 1, _dy + node_height - 1, _body_colour, _outline_colour);

var _root_display_text = root_type;

if (root_type == "INIT") {
    _root_display_text = _build_hover ? "BUILD & RUN" : "INIT/BUILD";
}

draw_set_colour(c_white);
if (_is_orphaned) {
    // Title in the upper half, the warning in the lower half.
    scr_ui_text_centred(_dx + (node_width / 2), _dy + (node_height * 0.3), _root_display_text);
    draw_set_font(UI_FONT_SMALL);
    scr_ui_text_centred(_dx + (node_width / 2), _dy + (node_height * 0.72), "not connected");
    draw_set_font(UI_FONT);
} else {
    scr_ui_text_centred(_dx + (node_width / 2), _dy + (node_height / 2), _root_display_text);
}
