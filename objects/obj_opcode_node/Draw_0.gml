// Screen-space draw position — world position plus current pan offset.
// node_y already reflects any live wedge-preview shift directly, since
// that's a real position mutation now, not a separate render-only offset.
var _dx = node_x + global.pan_x;
var _dy = node_y + global.pan_y;

var _body_colour = node_colour;

if (is_macro) {
    _body_colour = make_color_rgb(120, 60, 160);
}

draw_set_colour(_body_colour);
draw_rectangle(_dx + 1, _dy + 1, _dx + node_width - 1, _dy + node_height - 1, false);

// Dark category header. Every channel stays below 160 so the header remains
// clearly separate from the body without competing with white text.
var _header_colour = make_color_rgb(60, 70, 80);

if (is_macro) {
    switch (macro_type) {
        case "COPPER_BAR":
            _header_colour = make_color_rgb(135, 75, 25);
            break;

        case "SPRITE_DISPLAY":
            _header_colour = make_color_rgb(95, 45, 125);
            break;

        case "BITMAP_DISPLAY":
            _header_colour = make_color_rgb(35, 95, 125);
            break;

        case "SETBKG":
            _header_colour = make_color_rgb(150, 150, 40);
            break;

        default:
            _header_colour = make_color_rgb(90, 50, 110);
            break;
    }
} else {
    var _header_entry = global.opcode_map[$ opcode_mnemonic];

    if (_header_entry != undefined) {
        switch (_header_entry.category) {
            case "data_movement":
                _header_colour = make_color_rgb(35, 75, 120);
                break;

            case "arithmetic":
                _header_colour = make_color_rgb(120, 70, 35);
                break;

            case "logic":
                _header_colour = make_color_rgb(45, 100, 70);
                break;

            case "shift":
                _header_colour = make_color_rgb(80, 55, 120);
                break;

            case "bit":
                _header_colour = make_color_rgb(100, 90, 35);
                break;

            case "branch":
                _header_colour = make_color_rgb(125, 45, 55);
                break;

            case "system":
                _header_colour = make_color_rgb(55, 85, 100);
                break;

            case "privileged":
                _header_colour = make_color_rgb(110, 45, 95);
                break;
        }
    }
}

draw_set_colour(_header_colour);
draw_rectangle(_dx + 1, _dy + 1, _dx + node_width - 1, _dy + 19, false);

draw_set_colour(c_white);
draw_rectangle(_dx + 1, _dy + 1, _dx + node_width - 1, _dy + node_height - 1, true);

var _header_text = scr_opcode_display_label(opcode_mnemonic);

if (opcode_size != "") {
    _header_text += "." + opcode_size;
}

if (is_macro) {
    _header_text = "MACRO: " + macro_type;
}

draw_text(_dx + 6, _dy, _header_text);

var _label_display_text = node_label;
var _lab_width = 80;

if (operand_editing_slot == "node_label") {
    _label_display_text = operand_edit_text;
}

// Labels remain visible after editing. The badge is drawn before the text so
// the edit pulse cannot cover the entered name.
if (_label_display_text != "" || operand_editing_slot == "node_label") {
    // Label now lives on the left side of the node, with its text right
    // justified so it reads as hugging the node's left edge.
    var _label_box_x2 = _dx - 4;
    var _label_box_y1 = _dy;
    var _label_box_x1 = _label_box_x2 - _lab_width;
    var _label_box_y2 = _label_box_y1 + 20;
    var _label_border_colour = c_white;
    var _label_text_colour = c_white;
    var _label_background_colour = c_dkgray;
    var _label_grow = 0;

    if (operand_editing_slot == "node_label") {
        var _pulse_t = (sin(current_time * 0.006) + 1) / 2;
        _label_border_colour = merge_colour(c_black, c_yellow, _pulse_t);
        _label_text_colour = c_yellow;
        _label_background_colour = merge_colour(c_dkgray, _label_border_colour, 0.3);
        _label_grow = _pulse_t * 3;
    }

    draw_set_colour(_label_background_colour);
    draw_rectangle(_label_box_x1 - _label_grow, _label_box_y1 - _label_grow, _label_box_x2 + _label_grow, _label_box_y2 + _label_grow, false);
    draw_set_colour(_label_border_colour);
    draw_rectangle(_label_box_x1 - _label_grow, _label_box_y1 - _label_grow, _label_box_x2 + _label_grow, _label_box_y2 + _label_grow, true);
    draw_set_colour(_label_text_colour);
    draw_set_halign(fa_right);
    draw_text(_label_box_x2 - 4, _label_box_y1 + 2, _label_display_text);
    draw_set_halign(fa_left);
    draw_set_colour(c_white);
}

if (is_macro) {
    var _asset_field_dx = node_x + global.pan_x;
    var _asset_field_dy = node_y + global.pan_y + 20;

    var _asset_field_colour = c_dkgray;

    if (operand_editing_slot == "macro_asset") {
        _asset_field_colour = c_olive;
    }

    draw_set_colour(_asset_field_colour);
    draw_rectangle(_asset_field_dx, _asset_field_dy, _asset_field_dx + node_width, _asset_field_dy + 20, false);
    draw_set_colour(c_white);

    var _asset_field_label = "ASSET: ";

    if (macro_type == "SETBKG") {
        _asset_field_label = "RGB: ";
    }

    var _asset_field_text = _asset_field_label + macro_asset_name;

    if (operand_editing_slot == "macro_asset") {
        _asset_field_text = _asset_field_label + operand_edit_text;
    }

    if (macro_type == "COPPER_BAR") {
        _asset_field_text = "Click to edit colours";
    }

    draw_text(_asset_field_dx + 4, _asset_field_dy + 2, _asset_field_text);

    var _info_text = "asset not found";

    if (macro_type == "SETBKG") {
        _info_text = "hex colour 000-FFF -> COLOR00";
    } else if (macro_type == "COPPER_BAR") {
        var _cprbar_range_text = "full height";

        if (!macro_cprbar_equidistant) {
            _cprbar_range_text = "vp " + string(macro_cprbar_vp_start) + "-" + string(macro_cprbar_vp_end);
        }

        _info_text = string(macro_cprbar_band_count) + " bands, COLOR" + string(macro_cprbar_target_register) + ", " + _cprbar_range_text;
    } else {
        var _asset_for_info = scr_asset_find_by_name(macro_asset_name);

        if (_asset_for_info != undefined) {
            if (_asset_for_info.type == "SPRITE") {
                _info_text = "sprite: ch" + string(_asset_for_info.channel) + ", " + string(_asset_for_info.height) + " rows";
            } else {
                _info_text = _asset_for_info.type + " asset";
            }
        }
    }

    draw_text(_asset_field_dx + 4, _asset_field_dy + 24, _info_text);
} else {
    var _mode_src_dx = mode_button_src_x + global.pan_x;
    var _mode_src_dy = mode_button_src_y + global.pan_y;
    var _mode_dst_dx = mode_button_dst_x + global.pan_x;
    var _mode_dst_dy = mode_button_dst_y + global.pan_y;

    var _entry_for_draw = global.opcode_map[$ opcode_mnemonic];

    if (_entry_for_draw != undefined) {
        var _mode_zone_width = mode_button_width - value_box_width;

        if (_entry_for_draw.operand_count >= 1) {
            draw_set_colour(c_dkgray);
            draw_rectangle(_mode_src_dx, _mode_src_dy, _mode_src_dx + _mode_zone_width, _mode_src_dy + mode_button_height, false);
            draw_set_colour(c_white);
            draw_text(_mode_src_dx + 4, _mode_src_dy, addressing_mode_src);

            var _src_value_colour = c_dkgray;

            if (operand_editing_slot == "src") {
                _src_value_colour = c_olive;
            }

            draw_set_colour(_src_value_colour);
            draw_rectangle(_mode_src_dx + _mode_zone_width, _mode_src_dy, _mode_src_dx + mode_button_width, _mode_src_dy + mode_button_height, false);
            draw_set_colour(c_white);

            var _src_is_register_display = scr_operand_mode_uses_register_index(addressing_mode_src);
            var _src_value_text = string(operand_src);

            if (global.value_display_mode == "HEX" && !_src_is_register_display) {
                _src_value_text = "$" + scr_number_to_hex_string(operand_src);
            }

            if (addressing_mode_src == "LABEL") {
                _src_value_text = operand_label_src;
            }

            if (operand_editing_slot == "src") {
                _src_value_text = operand_edit_text;
            }

            draw_set_halign(fa_right);
            draw_text(_mode_src_dx + mode_button_width - 4, _mode_src_dy, _src_value_text);
            draw_set_halign(fa_left);
        }

        if (_entry_for_draw.operand_count >= 2) {
            draw_set_colour(c_dkgray);
            draw_rectangle(_mode_dst_dx, _mode_dst_dy, _mode_dst_dx + _mode_zone_width, _mode_dst_dy + mode_button_height, false);
            draw_set_colour(c_white);
            draw_text(_mode_dst_dx + 4, _mode_dst_dy, addressing_mode_dst);

            var _dst_value_colour = c_dkgray;

            if (operand_editing_slot == "dst") {
                _dst_value_colour = c_olive;
            }

            draw_set_colour(_dst_value_colour);
            draw_rectangle(_mode_dst_dx + _mode_zone_width, _mode_dst_dy, _mode_dst_dx + mode_button_width, _mode_dst_dy + mode_button_height, false);
            draw_set_colour(c_white);

            var _dst_is_register_display = scr_operand_mode_uses_register_index(addressing_mode_dst);
            var _dst_value_text = string(operand_dst);

            if (global.value_display_mode == "HEX" && !_dst_is_register_display) {
                _dst_value_text = "$" + scr_number_to_hex_string(operand_dst);
            }

            if (addressing_mode_dst == "LABEL") {
                _dst_value_text = operand_label_dst;
            }

            if (operand_editing_slot == "dst") {
                _dst_value_text = operand_edit_text;
            }

            draw_set_halign(fa_right);
            draw_text(_mode_dst_dx + mode_button_width - 4, _mode_dst_dy, _dst_value_text);
            draw_set_halign(fa_left);
        }
    }
}

var _src_colour = c_lime;
var _dst_colour = c_lime;

if (!slot_src_is_valid) {
    _src_colour = c_red;
}

if (!slot_dst_is_valid) {
    _dst_colour = c_red;
}

draw_set_colour(_src_colour);
draw_circle(src_validity_dot.dot_x + global.pan_x, src_validity_dot.dot_y + global.pan_y, 5, false);

draw_set_colour(_dst_colour);
draw_circle(dst_validity_dot.dot_x + global.pan_x, dst_validity_dot.dot_y + global.pan_y, 5, false);

draw_set_colour(c_white);

if (is_connected) {
    draw_set_colour(c_yellow);
    draw_line_width(_dx + (node_width / 2), _dy, _dx + (node_width / 2), _dy - 6, 3);
    draw_set_colour(c_white);
}

if (wedge_target_found && is_dragging) {
    draw_set_colour(c_yellow);
    draw_rectangle(_dx - 3, _dy - 3, _dx + node_width + 3, _dy + node_height + 3, true);
    draw_set_colour(c_white);
}

// Semantic hardware tooltip. Unknown instructions deliberately return an
// empty string so the canvas stays quiet until an explanation is authored.
var _hovering_node = point_in_rectangle(mouse_x, mouse_y, _dx, _dy, _dx + node_width, _dy + node_height);

if (_hovering_node && !is_dragging && global.operand_edit_owner_uid == -1) {
    var _explanation = scr_amiga_explain_node(id);

    if (_explanation != "") {
        var _tip_width = 460;
        var _tip_height = 100;
        var _tip_x = 272;//mouse_x + 18;
        var _tip_y = 850;//mouse_y + 18;
/*
        if (_tip_x + _tip_width > room_width - 8) {
            _tip_x = mouse_x - _tip_width - 18;
        }

        if (_tip_y + _tip_height > room_height - 8) {
            _tip_y = mouse_y - _tip_height - 18;
        }
*/
        draw_set_alpha(0.94);
        draw_set_colour(c_black);
        draw_rectangle(_tip_x, _tip_y, _tip_x + _tip_width, _tip_y + _tip_height, false);
        draw_set_alpha(1);
        draw_set_colour(c_yellow);
        draw_rectangle(_tip_x, _tip_y, _tip_x + _tip_width, _tip_y + _tip_height, true);
        draw_set_colour(c_white);
        draw_text_ext(_tip_x + 8, _tip_y + 6, _explanation, 16, _tip_width - 16);
    }
}
