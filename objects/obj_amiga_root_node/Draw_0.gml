var _dx = node_x + global.pan_x;
var _dy = node_y + global.pan_y;

draw_set_font(UI_FONT);

var _body_colour = c_orange;

if (root_type == "INIT") {
    _body_colour = make_color_rgb(100, 150, 250);
}
var _is_orphaned = (root_type == "ORG") && (continues_from_root_uid == -1);

if (_is_orphaned) {
    _body_colour = c_red;
}

scr_ui_box(_dx + 1, _dy + 1, _dx + node_width - 1, _dy + node_height - 1, _body_colour, c_white);

var _root_display_text = root_type;

if (root_type == "INIT") {
    _root_display_text = "INIT/BUILD";
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
