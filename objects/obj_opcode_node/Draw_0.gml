// Screen-space draw position — world position plus current pan offset.
// node_y already reflects any live wedge-preview shift directly, since
// that's a real position mutation now, not a separate render-only offset.
var _dx = node_x + global.pan_x;
var _dy = node_y + global.pan_y;

draw_set_font(UI_FONT_SMALL);
draw_set_halign(fa_left);
draw_set_valign(fa_top);

var _body_colour = node_colour;

if (is_macro) {
    _body_colour = make_color_rgb(120, 60, 160);
}

// Body box: the outer shape is bevelled (top-left and bottom-right cuts);
// the header band follows the top-left cut and the rows are inset fields.
var _bx1 = _dx + 1;
var _by1 = _dy + 1;
var _bx2 = _dx + node_width - 1;
var _by2 = _dy + node_height - 1;
scr_ui_box_fill(_bx1, _by1, _bx2, _by2, _body_colour);

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

        case "BOB_BITMAP_TEST":
            _header_colour = make_color_rgb(115, 75, 25);
            break;

        case "GET_BITMAP_BOB":
            _header_colour = make_color_rgb(35, 85, 120);
            break;

        case "REPLACE_BITMAP_BOB":
            _header_colour = make_color_rgb(45, 105, 65);
            break;

        case "DRAW_BOB":
            _header_colour = make_color_rgb(125, 70, 25);
            break;

        case "SPRITE_BITMAP_TEST":
            _header_colour = make_color_rgb(75, 45, 125);
            break;

        case "MOVE_BOB":
            _header_colour = make_color_rgb(25, 110, 100);
            break;

        case "MOVE_SPR":
            _header_colour = make_color_rgb(105, 40, 120);
            break;

        case "ANIM_BOB":
            _header_colour = make_color_rgb(25, 105, 75);
            break;

        case "ANIM_SPR":
            _header_colour = make_color_rgb(100, 35, 105);
            break;

        case "SETBKG":
            _header_colour = make_color_rgb(150, 150, 40);
            break;

        case "PLAY_MOD":
        case "STOP_MOD":
        case "PLAY_SFX":
            _header_colour = make_color_rgb(20, 110, 60);
            break;

        case "CODE":
            _header_colour = make_color_rgb(15, 95, 115);
            break;

        case "GK_SCREEN": case "GK_MAP": case "GK_PLAYER": case "GK_WAIT": case "GK_INPUT":
        case "GK_PHYSICS": case "GK_EVENTS": case "GK_ENEMIES": case "GK_ANIMATE": case "GK_DRAW":
            _header_colour = make_color_rgb(150, 70, 20);
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

scr_ui_header_band(_bx1, _by1, _bx2, _by2, _dy + 19, _header_colour);

var _header_text = scr_opcode_display_label(opcode_mnemonic);

if (opcode_size != "") {
    _header_text += "." + opcode_size;
}

if (is_macro) {
    _header_text = "MACRO: " + macro_type;
    if (macro_type == "CODE") _header_text = scr_code_block_name(id) != "" ? "CODE: " + scr_code_block_name(id) : "CODE BLOCK";
    if (macro_type == "PLAY_MOD") _header_text = "PLAY MUSIC (MOD)";
    if (macro_type == "STOP_MOD") _header_text = "STOP MUSIC";
    if (macro_type == "PLAY_SFX") _header_text = "PLAY SOUND FX";
    if (scr_gk_is_node_type(macro_type)) _header_text = "GK: " + scr_gk_node_label(macro_type);
}

draw_set_colour(c_white);
scr_ui_text_mid(_dx + NODE_TEXT_PAD, _dy + 1, _dy + 20, scr_ui_fit_label(_header_text, node_width - NODE_TEXT_PAD - 8));

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

    scr_ui_box(_label_box_x1 - _label_grow, _label_box_y1 - _label_grow, _label_box_x2 + _label_grow, _label_box_y2 + _label_grow, _label_background_colour, _label_border_colour);
    draw_set_colour(_label_text_colour);
    draw_set_halign(fa_right);
    // While typing the text may run out to the left so the end stays visible.
    scr_ui_text_mid(_label_box_x2 - 6, _label_box_y1, _label_box_y2 + 1, operand_editing_slot == "node_label" ? _label_display_text : scr_ui_fit_label(_label_display_text, _lab_width - 10));
    draw_set_halign(fa_left);
    draw_set_colour(c_white);
}

if (is_macro) {
    var _asset_field_dx = node_x + global.pan_x;
    var _asset_field_dy = node_y + global.pan_y + 20;
    var _is_move_macro_draw = (macro_type == "MOVE_BOB" || macro_type == "MOVE_SPR");
    var _is_anim_macro_draw = (macro_type == "ANIM_BOB" || macro_type == "ANIM_SPR");
    var _is_bob_ref_draw = (macro_type == "GET_BITMAP_BOB" || macro_type == "DRAW_BOB" || macro_type == "REPLACE_BITMAP_BOB" || macro_type == "BOB_BITMAP_TEST");
    var _is_sprite_ref_draw = (macro_type == "SPRITE_DISPLAY" || macro_type == "SPRITE_BITMAP_TEST");
    if (scr_gk_is_node_type(macro_type)) {
        scr_gk_node_draw(id, _asset_field_dx, _asset_field_dy - 20);
    } else if (macro_type == "PLAY_MOD" || macro_type == "PLAY_SFX") {
        var _audio_asset_draw = scr_asset_find_by_name(macro_asset_name);
        var _audio_name = macro_asset_name == "" ? "(none - SND-EDIT)" : macro_asset_name;
        scr_node_row(_asset_field_dx, node_width, _asset_field_dy, _audio_name, c_dkgray, _audio_asset_draw == undefined ? c_red : c_white, true);
        if (macro_type == "PLAY_MOD") {
            scr_node_row(_asset_field_dx, node_width, _asset_field_dy + 20, "SONG POS: " + string(macro_music_pos), c_dkgray, c_white, true);
        } else {
            scr_node_row(_asset_field_dx, node_width, _asset_field_dy + 20, "CHANNEL: " + (macro_sfx_channel < 0 ? "AUTO" : string(macro_sfx_channel)), c_dkgray, c_white, true);
            var _vol_text = macro_sfx_volume < 0 ? "SAMPLE" : string(macro_sfx_volume);
            scr_node_row(_asset_field_dx, node_width, _asset_field_dy + 40, "VOLUME: " + _vol_text, c_dkgray, c_white, true);
        }
    } else if (macro_type == "STOP_MOD") {
        draw_set_colour(c_white);
        scr_ui_text_mid(_asset_field_dx + NODE_TEXT_PAD, _asset_field_dy, _asset_field_dy + 20, scr_ui_fit_label("stops music + sound fx", node_width - 2 * NODE_TEXT_PAD));
    } else if (macro_type == "CODE") {
        var _over_edit_draw = point_in_rectangle(mouse_x, mouse_y, _asset_field_dx, _asset_field_dy, _asset_field_dx + node_width, _asset_field_dy + 20);
        var _code_lines_all = string_split(macro_code_text, "\n");
        scr_node_row(_asset_field_dx, node_width, _asset_field_dy, "EDIT CODE  (" + string(array_length(_code_lines_all)) + " lines)",
            _over_edit_draw ? make_colour_rgb(30, 130, 150) : make_colour_rgb(20, 90, 110), c_white, false);

        // First few non-blank lines as a preview, on a dark code panel.
        var _code_x1 = _asset_field_dx + NODE_ROW_INSET_L;
        var _code_x2 = _asset_field_dx + node_width - NODE_ROW_INSET_R;
        scr_ui_box(_code_x1, _asset_field_dy + 21, _code_x2, _dy + node_height - 4, make_colour_rgb(14, 18, 30), make_colour_rgb(50, 70, 100));
        var _code_preview_y = _asset_field_dy + 23;
        var _code_preview_i = 0;
        var _code_preview_shown = 0;
        while (_code_preview_i < array_length(_code_lines_all) && _code_preview_shown < 4) {
            var _preview_line = string_replace_all(_code_lines_all[_code_preview_i], "\t", "  ");
            if (string_trim(_preview_line) != "") {
                var _trimmed_preview = string_trim(_preview_line);
                draw_set_colour(string_char_at(_trimmed_preview, 1) == ";" ? make_colour_rgb(90, 170, 90) : make_colour_rgb(170, 210, 255));
                while (string_length(_preview_line) > 1 && string_width(_preview_line) > _code_x2 - _code_x1 - 12) {
                    _preview_line = string_copy(_preview_line, 1, string_length(_preview_line) - 1);
                }
                draw_text(_code_x1 + 6, _code_preview_y, _preview_line);
                _code_preview_y += 18;
                _code_preview_shown += 1;
            }
            _code_preview_i += 1;
        }
        draw_set_colour(c_white);
    } else if (_is_move_macro_draw) {
        scr_node_row(_asset_field_dx, node_width, _asset_field_dy, "ID: " + string(macro_object_id), c_dkgray, c_white, true);
        scr_node_row(_asset_field_dx, node_width, _asset_field_dy + 20, "X SPEED: " + string(macro_speed_x), c_dkgray, c_white, true);
        scr_node_row(_asset_field_dx, node_width, _asset_field_dy + 40, "Y SPEED: " + string(macro_speed_y), c_dkgray, c_white, true);
    } else if (_is_anim_macro_draw) {
        scr_node_row(_asset_field_dx, node_width, _asset_field_dy, "ID: " + string(macro_object_id), c_dkgray, c_white, true);
        scr_node_row(_asset_field_dx, node_width, _asset_field_dy + 20, "RATE: " + string(macro_anim_rate) + " FPS", c_dkgray, c_white, true);
        scr_node_row(_asset_field_dx, node_width, _asset_field_dy + 40, "START: " + string(macro_anim_start), c_dkgray, c_white, true);
        scr_node_row(_asset_field_dx, node_width, _asset_field_dy + 60, "END: " + string(macro_anim_end), c_dkgray, c_white, true);
        scr_node_row(_asset_field_dx, node_width, _asset_field_dy + 80, "LOOP: " + (macro_anim_loop ? "ON" : "OFF"), c_dkgray, c_white, false);
    } else {

    var _asset_field_colour = c_dkgray;

    if (operand_editing_slot == "macro_asset") {
        _asset_field_colour = c_olive;
    }

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

    scr_node_row(_asset_field_dx, node_width, _asset_field_dy, _asset_field_text, _asset_field_colour, c_white, false);

    var _info_text = "asset not found";

    if (macro_type == "SETBKG") {
        _info_text = "000-FFF -> COLOR00";
    } else if (macro_type == "COPPER_BAR") {
        // Short enough to fit the node: the range only shows when it is set.
        var _cprbar_range_text = "";

        if (!macro_cprbar_equidistant) {
            _cprbar_range_text = " " + string(macro_cprbar_vp_start) + "-" + string(macro_cprbar_vp_end);
        }

        _info_text = string(macro_cprbar_band_count) + " bands, COLOR" + string(macro_cprbar_target_register) + _cprbar_range_text;
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

    var _info_y = _asset_field_dy + 20;
    if (_is_bob_ref_draw || _is_sprite_ref_draw) {
        scr_node_row(_asset_field_dx, node_width, _asset_field_dy + 20, "ID: " + string(macro_object_id), c_dkgray, c_white, true);
        _info_y = _asset_field_dy + 40;
    }
    draw_set_colour(c_white);
    scr_ui_text_mid(_asset_field_dx + NODE_TEXT_PAD, _info_y, _info_y + 20, scr_ui_fit_label(_info_text, node_width - 2 * NODE_TEXT_PAD));
    }
} else {
    var _mode_src_dx = mode_button_src_x + global.pan_x;
    var _mode_src_dy = mode_button_src_y + global.pan_y;
    var _mode_dst_dx = mode_button_dst_x + global.pan_x;
    var _mode_dst_dy = mode_button_dst_y + global.pan_y;

    var _entry_for_draw = global.opcode_map[$ opcode_mnemonic];

    if (_entry_for_draw != undefined) {
        var _mode_zone_width = mode_button_width - value_box_width;
        var _slots = [];

        if (_entry_for_draw.operand_count >= 1) {
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

            array_push(_slots, { sx : _mode_src_dx, sy : _mode_src_dy, mode : addressing_mode_src, value : _src_value_text, editing : operand_editing_slot == "src" });
        }

        if (_entry_for_draw.operand_count >= 2) {
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

            array_push(_slots, { sx : _mode_dst_dx, sy : _mode_dst_dy, mode : addressing_mode_dst, value : _dst_value_text, editing : operand_editing_slot == "dst" });
        }

        // Each operand row: addressing-mode field on the left, value box on
        // the right (same split as the Step hit tests), both inset fields.
        var _slot_i = 0;
        while (_slot_i < array_length(_slots)) {
            var _slot = _slots[_slot_i];
            var _sy1 = _slot.sy + 1;
            var _sy2 = _slot.sy + mode_button_height;
            var _mode_x1 = _slot.sx + NODE_ROW_INSET_L;
            var _split_x = _slot.sx + _mode_zone_width;
            var _value_x2 = _slot.sx + mode_button_width - NODE_ROW_INSET_R;

            scr_ui_box(_mode_x1, _sy1, _split_x - 2, _sy2, c_dkgray, merge_colour(c_dkgray, c_white, 0.22));
            scr_ui_box(_split_x + 1, _sy1, _value_x2, _sy2, _slot.editing ? c_olive : make_colour_rgb(40, 44, 52), _slot.editing ? c_yellow : merge_colour(c_dkgray, c_white, 0.22));
            draw_set_colour(c_white);
            scr_ui_text_mid(_mode_x1 + 6, _sy1, _sy2 + 1, scr_ui_fit_label(_slot.mode, _split_x - _mode_x1 - 10));
            draw_set_halign(fa_right);
            scr_ui_text_mid(_value_x2 - 5, _sy1, _sy2 + 1, _slot.editing ? _slot.value : scr_ui_fit_label(_slot.value, _value_x2 - _split_x - 9));
            draw_set_halign(fa_left);
            _slot_i += 1;
        }
    }
}

// Outline last, over the header band and rows.
scr_ui_box_outline(_bx1, _by1, _bx2, _by2, c_white);


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

// The last build reported an error here: red outline, message on hover.
if (build_error_text != "") {
    scr_ui_box_outline(_dx - 2, _dy - 2, _dx + node_width + 2, _dy + node_height + 2, c_red, 2);
    if (point_in_rectangle(mouse_x, mouse_y, _dx, _dy, _dx + node_width, _dy + node_height)) {
        var _err_text = string_replace(build_error_text, "; ERROR: ", "");
        var _err_w = string_width(_err_text) + 16;
        var _err_y1 = _dy + node_height + 4;
        var _err_y2 = _err_y1 + 22;
        draw_set_alpha(0.9);
        scr_ui_box_fill(_dx, _err_y1, _dx + _err_w, _err_y2, c_black);
        draw_set_alpha(1);
        scr_ui_box_outline(_dx, _err_y1, _dx + _err_w, _err_y2, c_red);
        draw_set_colour(c_red);
        scr_ui_text_mid(_dx + 8, _err_y1, _err_y2 + 1, _err_text);
    }
    draw_set_colour(c_white);
}

if (wedge_target_found && is_dragging) {
    scr_ui_box_outline(_dx - 3, _dy - 3, _dx + node_width + 3, _dy + node_height + 3, c_yellow);
    draw_set_colour(c_white);
}



// Flash after the program preview sent the user here (scr_amiga_focus_node).
var _focus_flash = scr_amiga_focus_flash(id);
if (_focus_flash > 0) {
    draw_set_alpha(_focus_flash);
    scr_ui_box_outline(_dx - 4, _dy - 4, _dx + node_width + 4, _dy + node_height + 4, make_colour_rgb(255, 220, 90), 2);
    draw_set_alpha(_focus_flash * 0.35);
    scr_ui_box_outline(_dx - 7, _dy - 7, _dx + node_width + 7, _dy + node_height + 7, make_colour_rgb(255, 200, 60), 2);
    draw_set_alpha(1);
    draw_set_colour(c_white);
}
