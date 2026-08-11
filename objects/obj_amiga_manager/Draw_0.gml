draw_set_font(font_Future);

var _has_hover = (global.palette_hover_mnemonic != "");

if (_has_hover) {
    var _tooltip_data = scr_opcode_lookup(global.palette_hover_mnemonic);

    if (_tooltip_data != undefined) {
        var _tip_x = global.palette_hover_x + 16;
        var _tip_y = global.palette_hover_y + 16;
        var _tip_width = 700;
        var _tip_height = 100;

        draw_set_alpha(0.65);
        draw_rectangle_colour(_tip_x, _tip_y, _tip_x + _tip_width, _tip_y + _tip_height, c_black, c_black, c_black, c_black, false);
        draw_set_alpha(1);
        draw_rectangle_colour(_tip_x, _tip_y, _tip_x + _tip_width, _tip_y + _tip_height, c_yellow, c_yellow, c_yellow, c_yellow, true);

        draw_set_colour(c_white);
        draw_text(_tip_x + 8, _tip_y + 6, _tooltip_data.format);
        draw_text(_tip_x + 8, _tip_y + 24, _tooltip_data.mode);
        draw_text(_tip_x + 8, _tip_y + 50, "Use: " + _tooltip_data.use);
        draw_text(_tip_x + 8, _tip_y + 72, "~" + string(_tooltip_data.cycles) + " cycles, " + string(_tooltip_data.bytes) + "+ bytes");
    }
}

var _panel_x = room_width - 360;
var _panel_y = 60;
var _panel_width = 350;
var _panel_height = room_height - 60;

draw_set_alpha(0.65);
draw_rectangle_colour(_panel_x, _panel_y, _panel_x + _panel_width, _panel_y + _panel_height, c_black, c_black, c_black, c_black, false);
draw_set_alpha(1);
draw_set_colour(c_white);
draw_rectangle(_panel_x, _panel_y, _panel_x + _panel_width, _panel_y + _panel_height, true);
draw_text(_panel_x + 6, _panel_y + 4, "COMPILED PROGRAM PREVIEW");

var _collapse_x = _panel_x + 6;
var _collapse_y = _panel_y + 24;
draw_set_colour(make_color_rgb(55, 65, 90));
draw_rectangle(_collapse_x, _collapse_y, _panel_x + _panel_width - 16, _collapse_y + 17, false);
draw_set_colour(c_white);
draw_rectangle(_collapse_x, _collapse_y, _panel_x + _panel_width - 16, _collapse_y + 17, true);
draw_text(_collapse_x + 5, _collapse_y, "COLLAPSE ALL");

// Row 1 is the title, row 2 is COLLAPSE ALL, row 3 is intentionally blank.
// Code begins on row 4.
var _line_y = _panel_y + 56 + global.preview_scroll_y;
var _line_height = 16;
var _preview_line_count = array_length(preview_line_cache);

if (_preview_line_count == 0) {
    draw_set_colour(c_red);
    draw_text(_panel_x + 6, _panel_y + 56, "(NO CODE ADDED YET)");
    draw_set_colour(c_white);
} else {
    var _p = 0;

    while (_p < _preview_line_count) {
        var _line_data = preview_line_cache[_p];
        var _is_visible = (_line_y >= _panel_y + 56) && (_line_y <= _panel_y + _panel_height - _line_height);

        if (_is_visible) {
            var _line_colour = c_white;
            var _syntax_text = string_trim(_line_data.text);

            if (_line_data.is_error) {
                _line_colour = c_red;
            } else if (_line_data.is_macro_header) {
                _line_colour = make_color_rgb(220, 160, 255);
            } else if (string_length(_syntax_text) > 0 && string_char_at(_syntax_text, 1) == ";") {
                _line_colour = make_color_rgb(30, 180, 50);
            } else if (string_length(_syntax_text) > 0 && string_char_at(_syntax_text, string_length(_syntax_text)) == ":") {
                _line_colour = make_color_rgb(235, 190, 70);
            } else {
                var _syntax_upper = string_upper(_syntax_text);
                var _first_space = string_pos(" ", _syntax_upper);
                var _syntax_opcode = _first_space > 0 ? string_copy(_syntax_upper, 1, _first_space - 1) : _syntax_upper;
                var _opcode_dot = string_pos(".", _syntax_opcode);
                var _opcode_base = _opcode_dot > 0 ? string_copy(_syntax_opcode, 1, _opcode_dot - 1) : _syntax_opcode;

                // Directives describe emitted data/layout rather than CPU
                // execution, so distinguish them from instructions.
                if (_opcode_base == "DC" || _opcode_base == "SECTION" || _opcode_base == "EVEN") {
                    _line_colour = make_color_rgb(70, 180, 220);
                }

                // Control-flow lines are the useful landmarks when scanning
                // long generated macros.
                var _is_branch = (_opcode_base == "BRA" || _opcode_base == "BSR"
                    || _opcode_base == "BCC" || _opcode_base == "BCS" || _opcode_base == "BEQ" || _opcode_base == "BGE"
                    || _opcode_base == "BGT" || _opcode_base == "BHI" || _opcode_base == "BLE" || _opcode_base == "BLT"
                    || _opcode_base == "BMI" || _opcode_base == "BNE" || _opcode_base == "BPL" || _opcode_base == "BVC"
                    || _opcode_base == "BVS" || string_copy(_opcode_base, 1, 2) == "DB"
                    || _opcode_base == "JMP" || _opcode_base == "JSR" || _opcode_base == "RTS" || _opcode_base == "RTE");
                if (_is_branch) {
                    _line_colour = make_color_rgb(230, 135, 65);
                }
            }

            var _text_x = _panel_x + 6;

            if (_line_data.indent) {
                _text_x += 12;
            }

            draw_set_colour(_line_colour);
            draw_text(_text_x, _line_y, _line_data.text);
            draw_set_colour(c_white);
        }

        _line_y += _line_height;
        _p += 1;
    }
}

// Proportional preview scrollbar. The thumb represents the visible fraction
// of the wrapped line cache and follows mouse-wheel or drag scrolling.
var _track_x1 = _panel_x + _panel_width - 11;
var _track_x2 = _panel_x + _panel_width - 3;
var _track_y1 = _panel_y + 56;
var _track_y2 = _panel_y + _panel_height - 8;
var _track_h = _track_y2 - _track_y1;
var _viewport_h = _track_h;
var _content_h = _preview_line_count * _line_height;
draw_set_colour(make_color_rgb(25, 30, 45));
draw_rectangle(_track_x1, _track_y1, _track_x2, _track_y2, false);

if (_content_h > _viewport_h) {
    var _thumb_h = max(28, floor(_track_h * (_viewport_h / _content_h)));
    var _scroll_range = _content_h - _viewport_h;
    var _thumb_range = _track_h - _thumb_h;
    var _scroll_ratio = clamp((-global.preview_scroll_y) / _scroll_range, 0, 1);
    var _thumb_y = _track_y1 + floor(_thumb_range * _scroll_ratio);
    draw_set_colour(preview_scrollbar_dragging ? make_color_rgb(180, 190, 230) : make_color_rgb(105, 120, 165));
    draw_rectangle(_track_x1, _thumb_y, _track_x2, _thumb_y + _thumb_h, false);
} else {
    draw_set_colour(make_color_rgb(65, 75, 100));
    draw_rectangle(_track_x1, _track_y1, _track_x2, _track_y2, false);
}

draw_set_colour(c_white);

// Top tool strip. ORG and LOAD/SAVE stay in their familiar positions; all
// other actions are separated into clear TEST, MACRO, EDITOR and SYSTEM groups.
draw_text(top_ui_test_x, 2, "TEST MACROS:");
draw_set_colour(c_maroon);
draw_rectangle(top_ui_test_x, top_ui_row_1_y, top_ui_test_x + top_ui_button_width, top_ui_row_1_y + top_ui_button_height, false);
draw_set_colour(c_white);
draw_rectangle(top_ui_test_x, top_ui_row_1_y, top_ui_test_x + top_ui_button_width, top_ui_row_1_y + top_ui_button_height, true);
draw_text(top_ui_test_x + 4, top_ui_row_1_y , "T: SETUP");

draw_set_colour(c_maroon);
draw_rectangle(top_ui_test_x, top_ui_row_2_y, top_ui_test_x + top_ui_button_width, top_ui_row_2_y + top_ui_button_height, false);
draw_set_colour(c_white);
draw_rectangle(top_ui_test_x, top_ui_row_2_y, top_ui_test_x + top_ui_button_width, top_ui_row_2_y + top_ui_button_height, true);
draw_text(top_ui_test_x + 4, top_ui_row_2_y , "T: SPRITE");

draw_set_colour(c_maroon);
draw_rectangle(top_ui_test_2_x, top_ui_row_1_y, top_ui_test_2_x + top_ui_button_width, top_ui_row_1_y + top_ui_button_height, false);
draw_rectangle(top_ui_test_2_x, top_ui_row_2_y, top_ui_test_2_x + top_ui_button_width, top_ui_row_2_y + top_ui_button_height, false);
draw_set_colour(c_white);
draw_rectangle(top_ui_test_2_x, top_ui_row_1_y, top_ui_test_2_x + top_ui_button_width, top_ui_row_1_y + top_ui_button_height, true);
draw_rectangle(top_ui_test_2_x, top_ui_row_2_y, top_ui_test_2_x + top_ui_button_width, top_ui_row_2_y + top_ui_button_height, true);
draw_text(top_ui_test_2_x + 4, top_ui_row_1_y , "T: BOB-BMP");
draw_text(top_ui_test_2_x + 4, top_ui_row_2_y , "T: SPR-BMP");

draw_set_colour(c_white);
draw_text(top_ui_macro_x, 2, "MACROS:");

draw_text(top_ui_editor_x, 2, "EDITORS:");
draw_set_colour(make_color_rgb(120, 60, 160));
draw_rectangle(top_ui_editor_x, top_ui_row_1_y, top_ui_editor_x + top_ui_button_width, top_ui_row_1_y + top_ui_button_height, false);
draw_set_colour(c_white);
draw_rectangle(top_ui_editor_x, top_ui_row_1_y, top_ui_editor_x + top_ui_button_width, top_ui_row_1_y + top_ui_button_height, true);
draw_text(top_ui_editor_x + 4, top_ui_row_1_y , "SPR-EDIT");

draw_set_colour(make_color_rgb(35, 55, 85));
draw_rectangle(top_ui_editor_x, top_ui_row_2_y, top_ui_editor_x + top_ui_button_width, top_ui_row_2_y + top_ui_button_height, false);
draw_set_colour(c_white);
draw_rectangle(top_ui_editor_x, top_ui_row_2_y, top_ui_editor_x + top_ui_button_width, top_ui_row_2_y + top_ui_button_height, true);
draw_text(top_ui_editor_x + 4, top_ui_row_2_y , "BMP-EDIT");

draw_set_colour(make_color_rgb(75, 65, 35));
draw_rectangle(top_ui_editor_2_x, top_ui_row_1_y, top_ui_editor_2_x + top_ui_button_width, top_ui_row_1_y + top_ui_button_height, false);
draw_set_colour(c_white);
draw_rectangle(top_ui_editor_2_x, top_ui_row_1_y, top_ui_editor_2_x + top_ui_button_width, top_ui_row_1_y + top_ui_button_height, true);
draw_text(top_ui_editor_2_x + 4, top_ui_row_1_y , "BOB-EDIT");

// SAVE/LOAD moved to their own column off to the side, and widened —
// they're used often enough to want more room and less chance of a
// mis-click against the macro buttons next to them.
var _workspace_but_width = 160;
var _workspace_xpos = 100;

draw_set_colour(make_color_rgb(40, 100, 40));
draw_rectangle(_workspace_xpos, 20, _workspace_xpos+_workspace_but_width, 36, false);
draw_set_colour(c_white);
draw_rectangle(_workspace_xpos, 20, _workspace_xpos+_workspace_but_width, 36, true);
draw_text(_workspace_xpos + 5, 20, "LOAD WORKSPACE");

draw_set_colour(make_color_rgb(35, 55, 85));
draw_rectangle(_workspace_xpos, 50, _workspace_xpos+_workspace_but_width, 66, false);
draw_set_colour(c_white);
draw_rectangle(_workspace_xpos, 50, _workspace_xpos+_workspace_but_width, 66, true);
draw_text(_workspace_xpos + 5, 50, "SAVE WORKSPACE");

draw_set_colour(c_white);
draw_text(top_ui_system_x, 2, "SYSTEM:");
draw_set_colour(make_color_rgb(140, 30, 30));
draw_rectangle(top_ui_system_x, top_ui_row_1_y, top_ui_system_x + top_ui_button_width, top_ui_row_1_y + top_ui_button_height, false);
draw_set_colour(c_white);
draw_rectangle(top_ui_system_x, top_ui_row_1_y, top_ui_system_x + top_ui_button_width, top_ui_row_1_y + top_ui_button_height, true);
draw_text(top_ui_system_x + 4, top_ui_row_1_y , "KILL FSUAE");

draw_set_colour(make_color_rgb(90, 20, 20));
draw_rectangle(top_ui_system_x, top_ui_row_2_y, top_ui_system_x + top_ui_button_width, top_ui_row_2_y + top_ui_button_height, false);
draw_set_colour(c_white);
draw_rectangle(top_ui_system_x, top_ui_row_2_y, top_ui_system_x + top_ui_button_width, top_ui_row_2_y + top_ui_button_height, true);
draw_text(top_ui_system_x + 4, top_ui_row_2_y , "QUIT");

if (keyboard_check(vk_control)) {
    var _hud_text = "Undo: " + string(array_length(global.undo_stack)) + "   Redo: " + string(array_length(global.redo_stack));
    var _hud_x = mouse_x + 16;
    var _hud_y = mouse_y + 16;
    var _hud_width = 160;
    var _hud_height = 20;

    draw_set_alpha(0.65);
    draw_rectangle_colour(_hud_x, _hud_y, _hud_x + _hud_width, _hud_y + _hud_height, c_black, c_black, c_black, c_black, false);
    draw_set_alpha(1);
    draw_set_colour(c_white);
    draw_rectangle(_hud_x, _hud_y, _hud_x + _hud_width, _hud_y + _hud_height, true);
    draw_text(_hud_x + 6, _hud_y + 2, _hud_text);
}

if (array_length(global.status_message_log) > 0) {
    var _status_bar_height = 122;
    var _status_bar_y = room_height - _status_bar_height;
    var _status_line_height = 18;
	var _status_bar_x = 272;
	var _status_bar_width = 1280;

    draw_set_alpha(0.65);
    draw_rectangle_colour(_status_bar_x, _status_bar_y, _status_bar_x+_status_bar_width, room_height, c_black, c_black, c_black, c_black, false);
    draw_set_alpha(1);
    draw_set_colour(c_white);
    draw_rectangle(_status_bar_x, _status_bar_y, _status_bar_x+_status_bar_width, room_height, true);

    var _log_count = array_length(global.status_message_log);
    var _line_y = _status_bar_y + 4;
    var _i = _log_count - 1;

    while (_i >= 0 && _line_y <= room_height - _status_line_height) {
        var _log_entry = global.status_message_log[_i];
        var _line_colour = c_white;

        if (_log_entry.colour != undefined) {
            _line_colour = _log_entry.colour;
        } else if (_i == _log_count - 1) {
            _line_colour = c_yellow;
        }

        draw_set_colour(_line_colour);
        draw_text(_status_bar_x+8, _line_y, _log_entry.text);

        _line_y += _status_line_height;
        _i -= 1;
    }

    draw_set_colour(c_white);
}

if (global.sprite_editor_open) {
    var _layout = scr_sprite_editor_layout();

    draw_set_alpha(0.9);
    draw_rectangle_colour(_layout.panel_x, _layout.panel_y, _layout.panel_x + _layout.panel_width, _layout.panel_y + _layout.panel_height, c_black, c_black, c_black, c_black, false);
    draw_set_alpha(1);
    draw_set_colour(c_white);
    draw_rectangle(_layout.panel_x, _layout.panel_y, _layout.panel_x + _layout.panel_width, _layout.panel_y + _layout.panel_height, true);

    var _over_editor_header = point_in_rectangle(mouse_x, mouse_y, _layout.header_x, _layout.header_y, _layout.header_x + _layout.header_width, _layout.header_y + _layout.header_height);
    var _over_editor_close = point_in_rectangle(mouse_x, mouse_y, _layout.close_x, _layout.close_y, _layout.close_x + 16, _layout.close_y + 16);
    var _header_text = "SPRITE EDITOR - " + global.sprite_asset_name;

    if ((_over_editor_header && !_over_editor_close) || global.sprite_editor_dragging) {
        _header_text = "SPRITE EDITOR - Grab to drag";
    }

    draw_text(_layout.panel_x + 6, _layout.panel_y + 2, _header_text);

    draw_set_colour(c_red);
    draw_rectangle(_layout.close_x, _layout.close_y, _layout.close_x + 16, _layout.close_y + 16, false);
    draw_set_colour(c_white);
    draw_rectangle(_layout.close_x, _layout.close_y, _layout.close_x + 16, _layout.close_y + 16, true);
    draw_text(_layout.close_x + 4, _layout.close_y - 1, "X");

    draw_set_colour(make_colour_rgb(45, 65, 85));
    draw_rectangle(_layout.asset_prev_x, _layout.asset_row_y, _layout.asset_prev_x + 28, _layout.asset_row_y + 20, false);
    draw_rectangle(_layout.asset_prev_x + 34, _layout.asset_row_y, _layout.asset_prev_x + 190, _layout.asset_row_y + 20, false);
    draw_rectangle(_layout.asset_next_x, _layout.asset_row_y, _layout.asset_next_x + 28, _layout.asset_row_y + 20, false);
    draw_rectangle(_layout.asset_add_x, _layout.asset_row_y, _layout.asset_add_x + 104, _layout.asset_row_y + 20, false);
    draw_set_colour(c_white);
    draw_text(_layout.asset_prev_x + 9, _layout.asset_row_y + 1, "<");
    draw_text(_layout.asset_prev_x + 42, _layout.asset_row_y + 1, global.sprite_asset_name);
    draw_text(_layout.asset_next_x + 9, _layout.asset_row_y + 1, ">");
    draw_text(_layout.asset_add_x + 14, _layout.asset_row_y + 1, "ADD SPRITE");

    draw_text(_layout.panel_x + 12, _layout.channel_row_y, "CHANNEL:");
    draw_rectangle(_layout.channel_minus_x, _layout.channel_row_y, _layout.channel_minus_x + 16, _layout.channel_row_y + 16, true);
    draw_text(_layout.channel_minus_x + 4, _layout.channel_row_y - 1, "<");
    draw_text(_layout.channel_minus_x + 22, _layout.channel_row_y, string(global.sprite_channel));
    draw_rectangle(_layout.channel_plus_x, _layout.channel_row_y, _layout.channel_plus_x + 16, _layout.channel_row_y + 16, true);
    draw_text(_layout.channel_plus_x + 4, _layout.channel_row_y - 1, ">");

    var _pair_index = global.sprite_channel div 2;
    var _base_colour_index = 17 + (_pair_index * 4);
    draw_text(_layout.panel_x + 155, _layout.channel_row_y, "COLOR" + string(_base_colour_index) + "-" + string(_base_colour_index + 2));

    draw_text(_layout.panel_x + 12, _layout.height_row_y, "HEIGHT:");
    var _height_display = string(global.sprite_height);
    var _height_colour = c_dkgray;

    if (global.sprite_editing_field == "height") {
        _height_display = global.sprite_edit_text;
        _height_colour = c_olive;
    }

    draw_set_colour(_height_colour);
    draw_rectangle(_layout.height_field_x, _layout.height_row_y, _layout.height_field_x + 60, _layout.height_row_y + 16, false);
    draw_set_colour(c_white);
    draw_rectangle(_layout.height_field_x, _layout.height_row_y, _layout.height_field_x + 60, _layout.height_row_y + 16, true);
    draw_text(_layout.height_field_x + 4, _layout.height_row_y, _height_display);

    draw_text(_layout.panel_x + 12, _layout.addr_row_y, "ADDR:");
    var _addr_display = "$" + scr_number_to_hex_string(global.sprite_address);
    var _addr_colour = c_dkgray;

    if (global.sprite_editing_field == "address") {
        _addr_display = "$" + global.sprite_edit_text;
        _addr_colour = c_olive;
    }

    draw_set_colour(_addr_colour);
    draw_rectangle(_layout.addr_field_x, _layout.addr_row_y, _layout.addr_field_x + 80, _layout.addr_row_y + 16, false);
    draw_set_colour(c_white);
    draw_rectangle(_layout.addr_field_x, _layout.addr_row_y, _layout.addr_field_x + 80, _layout.addr_row_y + 16, true);
    draw_text(_layout.addr_field_x + 4, _layout.addr_row_y, _addr_display);

    var _swatch_index = 0;

    while (_swatch_index < 4) {
        var _swatch_x = _layout.swatch_x + (_swatch_index * (_layout.swatch_width + 6));
        var _swatch_colour = c_black;

        if (_swatch_index >= 1) {
            var _sr = global.sprite_colour_r[_swatch_index - 1] * 17;
            var _sg = global.sprite_colour_g[_swatch_index - 1] * 17;
            var _sb = global.sprite_colour_b[_swatch_index - 1] * 17;
            _swatch_colour = make_color_rgb(_sr, _sg, _sb);
        }

        draw_set_colour(_swatch_colour);
        draw_rectangle(_swatch_x, _layout.swatch_row_y, _swatch_x + _layout.swatch_width, _layout.swatch_row_y + _layout.swatch_height, false);

        var _border_colour = c_white;

        if (global.sprite_paint_index == _swatch_index) {
            _border_colour = c_yellow;
        }

        draw_set_colour(_border_colour);
        draw_rectangle(_swatch_x, _layout.swatch_row_y, _swatch_x + _layout.swatch_width, _layout.swatch_row_y + _layout.swatch_height, true);

        _swatch_index += 1;
    }

    draw_set_colour(c_white);
    draw_text(_layout.swatch_x, _layout.swatch_row_y + _layout.swatch_height + 2, "left=paint/edit  right on grid=erase");

    var _row = 0;

    while (_row < global.sprite_height) {
        var _col = 0;

        while (_col < 16) {
            var _pixel_index = global.sprite_pixels[(_row * 16) + _col];
            var _cell_x = _layout.grid_x + (_col * _layout.cell_size);
            var _cell_y = _layout.grid_y + (_row * _layout.cell_size);

            var _cell_colour = c_black;

            if (_pixel_index >= 1) {
                var _cr = global.sprite_colour_r[_pixel_index - 1] * 17;
                var _cg = global.sprite_colour_g[_pixel_index - 1] * 17;
                var _cb = global.sprite_colour_b[_pixel_index - 1] * 17;
                _cell_colour = make_color_rgb(_cr, _cg, _cb);
            }

            draw_set_colour(_cell_colour);
            draw_rectangle(_cell_x, _cell_y, _cell_x + _layout.cell_size, _cell_y + _layout.cell_size, false);
            draw_set_colour(c_dkgray);
            draw_rectangle(_cell_x, _cell_y, _cell_x + _layout.cell_size, _cell_y + _layout.cell_size, true);

            _col += 1;
        }

        _row += 1;
    }

    var _sprite_tool_names = ["DRAW", "LINE", "FILL"];
    var _sprite_tool_i = 0;
    while (_sprite_tool_i < 3) {
        var _sprite_tool_y = _layout.tool_y + _sprite_tool_i * 36;
        draw_set_colour(global.sprite_tool == _sprite_tool_names[_sprite_tool_i] ? make_colour_rgb(35, 110, 75) : make_colour_rgb(45, 65, 85));
        draw_rectangle(_layout.tool_x, _sprite_tool_y, _layout.tool_x + _layout.tool_width, _sprite_tool_y + _layout.tool_height, false);
        draw_set_colour(c_white);
        draw_text(_layout.tool_x + 24, _sprite_tool_y + 5, _sprite_tool_names[_sprite_tool_i]);
        _sprite_tool_i += 1;
    }

    draw_set_colour(global.sprite_anim_playing ? make_colour_rgb(35, 110, 75) : make_colour_rgb(45, 65, 85));
    draw_rectangle(_layout.anim_x, _layout.anim_play_y, _layout.anim_x + _layout.anim_width, _layout.anim_play_y + _layout.anim_height, false);
    draw_set_colour(c_white); draw_text(_layout.anim_x + 24, _layout.anim_play_y + 5, global.sprite_anim_playing ? "STOP" : "PLAY");

    draw_set_colour(global.sprite_anim_loop ? make_colour_rgb(35, 110, 75) : make_colour_rgb(45, 65, 85));
    draw_rectangle(_layout.anim_x, _layout.anim_loop_y, _layout.anim_x + _layout.anim_width, _layout.anim_loop_y + _layout.anim_height, false);
    draw_set_colour(c_white); draw_text(_layout.anim_x + 12, _layout.anim_loop_y + 5, "LOOP " + (global.sprite_anim_loop ? "ON" : "OFF"));

    var _sprite_anim_values = [
        "RATE " + string(global.sprite_anim_rate),
        "START " + string(global.sprite_anim_start),
        "END " + string(global.sprite_anim_end)
    ];
    var _sprite_anim_y = [_layout.anim_rate_y, _layout.anim_start_y, _layout.anim_end_y];
    var _sprite_anim_i = 0;
    while (_sprite_anim_i < 3) {
        draw_set_colour(make_colour_rgb(45, 65, 85));
        draw_rectangle(_layout.anim_x, _sprite_anim_y[_sprite_anim_i], _layout.anim_x + _layout.anim_width, _sprite_anim_y[_sprite_anim_i] + _layout.anim_height, false);
        draw_set_colour(c_white);
        draw_text(_layout.anim_x + 6, _sprite_anim_y[_sprite_anim_i] + 5, "< " + _sprite_anim_values[_sprite_anim_i] + " >");
        _sprite_anim_i += 1;
    }

    if (global.sprite_line_active) {
        var _preview_colour = c_black;
        if (global.sprite_line_value >= 1) {
            var _preview_index = global.sprite_line_value - 1;
            _preview_colour = make_color_rgb(global.sprite_colour_r[_preview_index] * 17,
                global.sprite_colour_g[_preview_index] * 17, global.sprite_colour_b[_preview_index] * 17);
        }
        var _lx = global.sprite_line_start_x, _ly = global.sprite_line_start_y;
        var _ldx = abs(global.sprite_line_current_x - _lx), _lsx = _lx < global.sprite_line_current_x ? 1 : -1;
        var _ldy = -abs(global.sprite_line_current_y - _ly), _lsy = _ly < global.sprite_line_current_y ? 1 : -1;
        var _lerr = _ldx + _ldy;
        repeat (128) {
            var _preview_x = _layout.grid_x + _lx * _layout.cell_size;
            var _preview_y = _layout.grid_y + _ly * _layout.cell_size;
            draw_set_colour(_preview_colour);
            draw_rectangle(_preview_x, _preview_y, _preview_x + _layout.cell_size, _preview_y + _layout.cell_size, false);
            draw_set_colour(c_yellow);
            draw_rectangle(_preview_x, _preview_y, _preview_x + _layout.cell_size, _preview_y + _layout.cell_size, true);
            if (_lx == global.sprite_line_current_x && _ly == global.sprite_line_current_y) break;
            var _le2 = 2 * _lerr;
            if (_le2 >= _ldy) { _lerr += _ldy; _lx += _lsx; }
            if (_le2 <= _ldx) { _lerr += _ldx; _ly += _lsy; }
        }
    }

    // --------------------------------------------------------------------
    // Live 12-bit Amiga palette editor: three 0-F channel sliders.
    // --------------------------------------------------------------------
    var _edit_index = global.sprite_palette_edit_index;
    var _edit_array_index = _edit_index - 1;
    var _edit_r = global.sprite_colour_r[_edit_array_index];
    var _edit_g = global.sprite_colour_g[_edit_array_index];
    var _edit_b = global.sprite_colour_b[_edit_array_index];
    var _hex_digits = "0123456789ABCDEF";
    var _edit_hex = string_char_at(_hex_digits, _edit_r + 1)
        + string_char_at(_hex_digits, _edit_g + 1)
        + string_char_at(_hex_digits, _edit_b + 1);
    var _edit_colour = make_color_rgb(_edit_r * 17, _edit_g * 17, _edit_b * 17);
    var _edit_register = _base_colour_index + (_edit_index - 1);

    draw_set_colour(c_white);
    draw_text(_layout.panel_x + 12, _layout.palette_y, "PALETTE EDITOR  COLOR" + string(_edit_register) + "  #" + _edit_hex);

    draw_set_colour(_edit_colour);
    draw_rectangle(_layout.palette_preview_x, _layout.palette_preview_y, _layout.palette_preview_x + _layout.palette_preview_width, _layout.palette_preview_y + _layout.palette_preview_height, false);
    draw_set_colour(c_white);
    draw_rectangle(_layout.palette_preview_x, _layout.palette_preview_y, _layout.palette_preview_x + _layout.palette_preview_width, _layout.palette_preview_y + _layout.palette_preview_height, true);

    var _slider_channel = 0;

    while (_slider_channel < 3) {
        var _slider_y = _layout.slider_r_y;
        var _slider_selected_value = _edit_r;
        var _slider_label = "R";

        if (_slider_channel == 1) {
            _slider_y = _layout.slider_g_y;
            _slider_selected_value = _edit_g;
            _slider_label = "G";
        } else if (_slider_channel == 2) {
            _slider_y = _layout.slider_b_y;
            _slider_selected_value = _edit_b;
            _slider_label = "B";
        }

        draw_set_colour(c_white);
        draw_text(_layout.slider_x - 18, _slider_y, _slider_label);

        var _slider_position = 0;

        while (_slider_position < 16) {
            var _segment_x = _layout.slider_x + (_slider_position * _layout.slider_step_width);
            var _segment_colour = make_color_rgb(_slider_position * 17, 0, 0);

            if (_slider_channel == 1) {
                _segment_colour = make_color_rgb(0, _slider_position * 17, 0);
            } else if (_slider_channel == 2) {
                _segment_colour = make_color_rgb(0, 0, _slider_position * 17);
            }

            draw_set_colour(_segment_colour);
            draw_rectangle(_segment_x, _slider_y, _segment_x + _layout.slider_step_width, _slider_y + _layout.slider_height, false);

            draw_set_colour(c_dkgray);
            draw_rectangle(_segment_x, _slider_y, _segment_x + _layout.slider_step_width, _slider_y + _layout.slider_height, true);

            if (_slider_position == _slider_selected_value) {
                draw_set_colour(c_yellow);
                draw_rectangle(_segment_x - 1, _slider_y - 1, _segment_x + _layout.slider_step_width + 1, _slider_y + _layout.slider_height + 1, true);
            }

            _slider_position += 1;
        }

        draw_set_colour(c_white);
        draw_text(_layout.slider_x + _layout.slider_width + 4, _slider_y, string_char_at(_hex_digits, _slider_selected_value + 1));

        _slider_channel += 1;
    }

    draw_set_colour(c_white);
}
