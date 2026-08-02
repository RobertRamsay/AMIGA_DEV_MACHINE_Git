var _dx = node_x + global.pan_x;
var _dy = node_y + global.pan_y;

var _body_colour = c_orange;

if (root_type == "INIT") {
    _body_colour = make_color_rgb(100, 150, 250);
}
var _is_orphaned = (root_type == "ORG") && (continues_from_root_uid == -1);

if (_is_orphaned) {
    _body_colour = c_red;
}

draw_set_colour(_body_colour);
draw_rectangle(_dx + 1, _dy + 1, _dx + node_width - 1, _dy + node_height - 1, false);

draw_set_colour(c_white);
draw_rectangle(_dx + 1, _dy + 1, _dx + node_width - 1, _dy + node_height - 1, true);
draw_set_halign(fa_center);
draw_set_valign(fa_middle);
draw_text(_dx + (node_width / 2), _dy + (node_height / 2), root_type);
draw_set_halign(fa_left);
draw_set_valign(fa_top);

if (_is_orphaned) {
    draw_text(_dx + 6, _dy + 18, "not connected");
}
