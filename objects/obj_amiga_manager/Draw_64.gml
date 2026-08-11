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

// Normal Draw records hover ownership in visual draw order. Resolve directly
// as a fallback too, making this GUI event independent of event-order changes
// made by different GameMaker runners.
var _hover_mnemonic = global.palette_hover_mnemonic;
if (_hover_mnemonic == "") {
    var _palette_count = instance_number(obj_opcode_palette_item);
    var _palette_index = 0;
    while (_palette_index < _palette_count) {
        var _palette_item = instance_find(obj_opcode_palette_item, _palette_index);
        if (point_in_rectangle(mouse_x, mouse_y,
            _palette_item.palette_x, _palette_item.palette_y,
            _palette_item.palette_x + _palette_item.palette_width,
            _palette_item.palette_y + _palette_item.palette_height)) {
            _hover_mnemonic = _palette_item.palette_mnemonic;
        }
        _palette_index += 1;
    }
}

// Fixed palette and macro controls get first refusal when they are hovered.
if (_hover_mnemonic != "") {
    var _tooltip_data = scr_opcode_lookup(_hover_mnemonic);

    if (_tooltip_data != undefined) {
        if (global.palette_hover_mnemonic != "") {
            _tip_x = global.palette_hover_x + 16;
            _tip_y = global.palette_hover_y + 16;
        }

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
    var _help_node = global.hovered_help_node;

    if (_help_node == noone || !instance_exists(_help_node)) {
        var _node_count = instance_number(obj_opcode_node);
        var _node_index = 0;
        while (_node_index < _node_count) {
            var _node = instance_find(obj_opcode_node, _node_index);
            var _node_x = _node.node_x + global.pan_x;
            var _node_y = _node.node_y + global.pan_y;
            if (!_node.is_dragging
            && point_in_rectangle(mouse_x, mouse_y, _node_x, _node_y,
                _node_x + _node.node_width, _node_y + _node.node_height)) {
                _help_node = _node;
            }
            _node_index += 1;
        }
    }

    if (_help_node != noone && instance_exists(_help_node)) {
        var _explanation = scr_amiga_explain_node(_help_node);

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
