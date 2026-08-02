var _body_colour = c_orange;

if (root_type == "INIT") {
    _body_colour = c_aqua;
}
var _is_orphaned = (root_type == "ORG") && (continues_from_root_uid == -1);

if (_is_orphaned) {
    _body_colour = c_red;
}

draw_set_colour(_body_colour);
draw_rectangle(node_x, node_y, node_x + node_width, node_y + node_height, false);

draw_set_colour(c_white);
draw_rectangle(node_x, node_y, node_x + node_width, node_y + node_height, true);
draw_text(node_x + 6, node_y + 6, root_type);

if (_is_orphaned) {
    draw_text(node_x + 6, node_y + 18, "not connected");
}