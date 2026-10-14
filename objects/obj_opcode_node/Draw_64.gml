// Semantic hardware tooltip. Unknown instructions deliberately return an
// empty string so the canvas stays quiet until an explanation is authored.
var _dx = node_x + global.pan_x;
var _dy = node_y + global.pan_y;


var _hovering_node = point_in_rectangle(mouse_x, mouse_y, _dx, _dy, _dx + node_width, _dy + node_height);

if (_hovering_node && !is_dragging && global.operand_edit_owner_uid == -1 && !scr_amiga_modal_open()) {
    var _explanation = scr_amiga_explain_node(id);

    if (_explanation != "") {
        draw_set_font(UI_FONT);
        draw_set_halign(fa_left);
        draw_set_valign(fa_top);
        var _tip_width = 800;
        var _tip_height = 100;
        var _tip_x = 272;//mouse_x + 18;
        var _tip_y = 850;//mouse_y + 18;
        // Grow downwards for long help rather than spilling out of the box.
        _tip_height = max(_tip_height, string_height_ext(_explanation, 18, _tip_width - 20) + 16);

        draw_set_alpha(0.85);
        scr_ui_box_fill(_tip_x, _tip_y, _tip_x + _tip_width, _tip_y + _tip_height, make_colour_rgb(12, 14, 24));
        draw_set_alpha(1);
        scr_ui_box_outline(_tip_x, _tip_y, _tip_x + _tip_width, _tip_y + _tip_height, c_yellow);
        draw_set_colour(c_white);
        draw_text_ext(_tip_x + 10, _tip_y + 8, _explanation, 18, _tip_width - 20);
    }
}
