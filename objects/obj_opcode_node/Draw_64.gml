// Semantic hardware tooltip. Unknown instructions deliberately return an
// empty string so the canvas stays quiet until an explanation is authored.
var _dx = node_x + global.pan_x;
var _dy = node_y + global.pan_y;


var _hovering_node = point_in_rectangle(mouse_x, mouse_y, _dx, _dy, _dx + node_width, _dy + node_height);

if (_hovering_node && !is_dragging && global.operand_edit_owner_uid == -1 && !scr_amiga_modal_open()) {
    scr_amiga_hover_tip(scr_amiga_explain_node(id));
}
