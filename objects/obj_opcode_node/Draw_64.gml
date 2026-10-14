// Hover help in the panel under the workspace. Opcode nodes show their
// instruction (yellow), what it does in plain English with its values, each
// operand's addressing mode, size / cost and any hardware register meaning.
var _dx = node_x + global.pan_x;
var _dy = node_y + global.pan_y;


var _hovering_node = point_in_rectangle(mouse_x, mouse_y, _dx, _dy, _dx + node_width, _dy + node_height);

if (_hovering_node && !is_dragging && global.operand_edit_owner_uid == -1 && !scr_amiga_modal_open()) {
    if (!is_macro && build_error_text == "") {
        var _help = scr_opcode_explain_node(id);
        scr_amiga_hover_tip(_help.body, _help.title);
    } else {
        scr_amiga_hover_tip(scr_amiga_explain_node(id));
    }
}
