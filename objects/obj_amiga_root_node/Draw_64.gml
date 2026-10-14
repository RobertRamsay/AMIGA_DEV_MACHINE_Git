// Hover help for INIT / ORG blocks in the panel under the workspace (the same
// panel as the nodes' help, scr_amiga_hover_tip).
var _dx = node_x + global.pan_x;
var _dy = node_y + global.pan_y;

if (!is_dragging && global.operand_edit_owner_uid == -1 && !scr_amiga_modal_open() && !scr_tutorial_guide_mouse_over()
    && point_in_rectangle(mouse_x, mouse_y, _dx, _dy, _dx + node_width, _dy + node_height)) {
    scr_amiga_hover_tip(scr_amiga_explain_root(id));
}
