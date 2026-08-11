/// @description GUI-layer hover help
// All palette, macro and placed-node help is drawn once here. Draw GUI runs
// after normal instance drawing, so overlapping nodes and instance depth can
// never cover the helper or cause several node instances to fight over it.

draw_set_font(font_Future);

var _tip_x = 272;
var _tip_y = 850;
var _tip_width = 800;
var _tip_height = 100;
var _drew_helper = false;

// Fixed palette and macro controls get first refusal when they are hovered.
if (global.palette_hover_mnemonic != "") {
    var _tooltip_data = scr_opcode_lookup(global.palette_hover_mnemonic);

    if (_tooltip_data != undefined) {
        _tip_x = global.palette_hover_x + 16;
        _tip_y = global.palette_hover_y + 16;

        draw_set_alpha(0.65);
        draw_set_colour(c_black);
        draw_rectangle(_tip_x, _tip_y, _tip_x + _tip_width, _tip_y + _tip_height, false);
        draw_set_alpha(1);
        draw_set_colour(c_yellow);
        draw_rectangle(_tip_x, _tip_y, _tip_x + _tip_width, _tip_y + _tip_height, true);
        draw_set_colour(c_white);
        draw_text(_tip_x + 8, _tip_y + 6, _tooltip_data.format);
        draw_text(_tip_x + 8, _tip_y + 24, _tooltip_data.mode);
        draw_text(_tip_x + 8, _tip_y + 50, "Use: " + _tooltip_data.use);

        if (variable_struct_exists(_tooltip_data, "generated_help") && _tooltip_data.generated_help) {
            draw_text(_tip_x + 8, _tip_y + 72, "Cost: " + string(_tooltip_data.cycles) + ", size: " + string(_tooltip_data.bytes));
        } else {
            draw_text(_tip_x + 8, _tip_y + 72, "~" + string(_tooltip_data.cycles) + " cycles, " + string(_tooltip_data.bytes) + "+ bytes");
        }

        _drew_helper = true;
    }
}

// Otherwise explain the one placed node selected by normal Draw order. This
// keeps hit testing in the same coordinate/depth context that drew the node,
// while the helper itself remains safely above the world in Draw GUI.
if (!_drew_helper
&& global.operand_edit_owner_uid == -1
&& !instance_exists(obj_bitmap_editor)
&& !instance_exists(obj_bob_editor)
&& !instance_exists(obj_colour_picker)
&& !instance_exists(obj_cprbar_editor)) {
    if (global.hovered_help_node != noone && instance_exists(global.hovered_help_node)) {
        var _explanation = scr_amiga_explain_node(global.hovered_help_node);

        if (_explanation != "") {
            draw_set_alpha(0.65);
            draw_set_colour(c_black);
            draw_rectangle(_tip_x, _tip_y, _tip_x + _tip_width, _tip_y + _tip_height, false);
            draw_set_alpha(1);
            draw_set_colour(c_yellow);
            draw_rectangle(_tip_x, _tip_y, _tip_x + _tip_width, _tip_y + _tip_height, true);
            draw_set_colour(c_white);
            draw_text_ext(_tip_x + 8, _tip_y + 6, _explanation, 16, _tip_width - 16);
        }
    }
}

draw_set_alpha(1);
draw_set_colour(c_white);
