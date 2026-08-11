// Semantic hardware tooltip. Unknown instructions deliberately return an
// empty string so the canvas stays quiet until an explanation is authored.
var _dx = node_x + global.pan_x;
var _dy = node_y + global.pan_y;


var _hovering_node = point_in_rectangle(mouse_x, mouse_y, _dx, _dy, _dx + node_width, _dy + node_height);

if (_hovering_node && !is_dragging && global.operand_edit_owner_uid == -1) {
    var _explanation = scr_amiga_explain_node(id);

    if (_explanation != "") {
        var _tip_width = 800;
        var _tip_height = 100;
        var _tip_x = 272;//mouse_x + 18;
        var _tip_y = 850;//mouse_y + 18;

        draw_set_alpha(0.8);
        draw_set_colour(c_black);
        draw_rectangle(_tip_x, _tip_y, _tip_x + _tip_width, _tip_y + _tip_height, false);
        draw_set_alpha(1);
        draw_set_colour(c_yellow);
        draw_rectangle(_tip_x, _tip_y, _tip_x + _tip_width, _tip_y + _tip_height, true);
        draw_set_colour(c_white);
        draw_text_ext(_tip_x + 8, _tip_y + 6, _explanation, 16, _tip_width - 16);
    }
}