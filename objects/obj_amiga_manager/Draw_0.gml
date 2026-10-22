draw_set_font(UI_FONT);
draw_set_halign(fa_left);
draw_set_valign(fa_top);

var _has_hover = (global.palette_hover_mnemonic != "");

if (_has_hover) {
    var _tooltip_data = scr_opcode_lookup(global.palette_hover_mnemonic);

    if (_tooltip_data != undefined) {
        var _tip_x = global.palette_hover_x + 16;
        var _tip_y = global.palette_hover_y + 16;
        var _tip_width = 800;
        var _tip_height = 100;

        draw_set_alpha(0.85);
        scr_ui_box_fill(_tip_x, _tip_y, _tip_x + _tip_width, _tip_y + _tip_height, make_colour_rgb(12, 14, 24));
        draw_set_alpha(1);
        scr_ui_box_outline(_tip_x, _tip_y, _tip_x + _tip_width, _tip_y + _tip_height, c_yellow);

        draw_set_colour(c_white);
        draw_text(_tip_x + 10, _tip_y + 8, _tooltip_data.format);
        draw_text(_tip_x + 10, _tip_y + 28, _tooltip_data.mode);
        draw_text(_tip_x + 10, _tip_y + 50, "Use: " + _tooltip_data.use);
        if (variable_struct_exists(_tooltip_data, "generated_help") && _tooltip_data.generated_help) {
            draw_text(_tip_x + 10, _tip_y + 72, "Cost: " + string(_tooltip_data.cycles) + ", size: " + string(_tooltip_data.bytes));
        } else {
            draw_text(_tip_x + 10, _tip_y + 72, "~" + string(_tooltip_data.cycles) + " cycles, " + string(_tooltip_data.bytes) + "+ bytes");
        }
    }
}

// Type to find over the palette: the letters typed so far and the match count.
if (global.palette_find != "") {
    var _find_count = scr_palette_find_count();
    var _find_text = "FIND: " + global.palette_find + (string_length(global.palette_find) < 2 ? "_" : "")
        + "   " + (_find_count == 1 ? "1 match" : string(_find_count) + " matches")
        + (string_length(global.palette_find) >= 2 ? "   (the next letter starts again)" : "   (type a second letter to narrow it)");
    var _find_w = string_width(_find_text) + 24;
    var _find_y = 806;
    draw_set_alpha(0.85);
    scr_ui_box_fill(272, _find_y, 272 + _find_w, _find_y + 34, make_colour_rgb(12, 14, 24));
    draw_set_alpha(1);
    scr_ui_box_outline(272, _find_y, 272 + _find_w, _find_y + 34, _find_count > 0 ? c_yellow : c_red);
    draw_set_colour(_find_count > 0 ? c_yellow : c_red);
    scr_ui_text_mid(284, _find_y, _find_y + 34, _find_text);
    draw_set_colour(c_white);
}

var _panel_x = room_width - 360;
// Starts below the toolbar buttons; the bottom edge sits 2 px above the room
// edge (one pixel to spare), level with the message panel.
var _panel_y = 72;
var _panel_width = 350;
var _panel_height = room_height - 2 - _panel_y;
// The bottom of the panel is a footer (logo, version, FPS); code lines and
// the scrollbar stop above it. Step uses the same content bottom.
var _footer_height = 64;
var _content_top = _panel_y + 56;
var _content_bottom = _panel_y + _panel_height - _footer_height - 8;

draw_set_alpha(0.8);
scr_ui_box_fill(_panel_x, _panel_y, _panel_x + _panel_width, _panel_y + _panel_height, make_colour_rgb(6, 8, 16));
draw_set_alpha(1);
scr_ui_box_outline(_panel_x, _panel_y, _panel_x + _panel_width, _panel_y + _panel_height, c_white);
draw_set_colour(c_white);
scr_ui_text_mid(_panel_x + 8, _panel_y + 2, _panel_y + 22, "COMPILED PROGRAM PREVIEW");

var _collapse_x = _panel_x + 6;
var _collapse_y = _panel_y + 24;
var _collapse_x2 = _panel_x + _panel_width - 16;
var _collapse_hover = point_in_rectangle(mouse_x, mouse_y, _collapse_x, _collapse_y, _collapse_x2, _collapse_y + 17);
scr_ui_button(_collapse_x, _collapse_y, _collapse_x2, _collapse_y + 17, "COLLAPSE ALL", make_colour_rgb(55, 65, 90), _collapse_hover);

// Row 1 is the title, row 2 is COLLAPSE ALL, row 3 is intentionally blank.
// Code begins on row 4.
var _line_y = _content_top + global.preview_scroll_y;
var _line_height = 16;
var _preview_line_count = array_length(preview_line_cache);

if (_preview_line_count == 0) {
    draw_set_colour(c_red);
    draw_text(_panel_x + 6, _content_top, "(NO CODE ADDED YET)");
    draw_set_colour(c_white);
} else {
    var _p = 0;

    while (_p < _preview_line_count) {
        var _line_data = preview_line_cache[_p];
        var _is_visible = (_line_y >= _content_top) && (_line_y + _line_height <= _content_bottom);

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
var _track_y1 = _content_top;
var _track_y2 = _content_bottom;
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

// Footer: logo, copyright, version and FPS (fading in with the splash).
var _footer_y = _panel_y + _panel_height - _footer_height;
var _brand_alpha = instance_exists(obj_flashSplash) ? clamp(1 - obj_flashSplash.fade, 0, 1) : 1;
draw_set_colour(make_colour_rgb(70, 80, 110));
draw_line(_panel_x + 8, _footer_y - 1, _panel_x + _panel_width - 8, _footer_y - 1);
draw_sprite_ext(spr_ADM_SmallLogo, 0, _panel_x + 10, _footer_y + 3, 0.58, 0.58, 0, c_white, _brand_alpha);
draw_set_alpha(_brand_alpha);
draw_set_font(UI_FONT_SMALL);
draw_set_colour(c_white);
draw_set_halign(fa_right);
draw_text(_panel_x + _panel_width - 14, _footer_y + 8, "(C) POLYTRICITY 2026");
draw_text(_panel_x + _panel_width - 14, _footer_y + 24, "VERSION: " + string(GM_version));
draw_text(_panel_x + _panel_width - 14, _footer_y + 40, "FPS: " + string(round(fps_real)));
draw_set_halign(fa_left);
draw_set_alpha(1);

// Top tool strip. SYSTEM and workspace I/O share the left cluster; ORG sits
// alone in the former SYSTEM position to the right of the editor controls.
// Group headings use UI_FONT; the buttons use UI_FONT_SMALL like the macro
// buttons beside them, with their labels centred.
var _machine_profile = scr_amiga_machine_profile();
var _run_busy = build_state != "idle";
var _group_headers = [
    { hx : top_ui_system_x, text : "SYSTEM:" },
    { hx : top_ui_test_x, text : "TEST MACROS:" },
    { hx : top_ui_macro_x, text : "MACROS:" },
    { hx : top_ui_audio_x, text : "AUDIO / CODE:" },
    { hx : top_ui_editor_x, text : "EDITORS:" },
    { hx : top_ui_tutorial_x, text : "GAME KIT:" }
];
draw_set_font(UI_FONT);
draw_set_colour(c_white);
var _header_i = 0;
while (_header_i < array_length(_group_headers)) {
    draw_text(_group_headers[_header_i].hx, 2, _group_headers[_header_i].text);
    _header_i += 1;
}
var _machine_header = "AMIGA: " + _machine_profile.chipset + " " + string(_machine_profile.chip_kb div 1024) + "MB CHIP";
if (string_width(_machine_header) > top_ui_tutorial_x - top_ui_machine_x - 10) {
    _machine_header = "AMIGA: " + _machine_profile.chipset + " " + string(_machine_profile.chip_kb div 1024) + "MB";
}
draw_text(top_ui_machine_x, 2, _machine_header);

var _bw = top_ui_button_width;
var _toolbar_buttons = [
    { bx : top_ui_system_x, by : top_ui_row_1_y, bw : _bw, colour : make_color_rgb(90, 20, 20), text : "QUIT" },
    { bx : top_ui_system_x, by : top_ui_row_2_y, bw : _bw, colour : make_color_rgb(140, 30, 30), text : "KILL FSUAE" },
    { bx : top_ui_workspace_x, by : top_ui_row_1_y, bw : top_ui_workspace_width, colour : make_color_rgb(40, 100, 40), text : "LOAD WORKSPACE" },
    { bx : top_ui_workspace_x, by : top_ui_row_2_y, bw : top_ui_workspace_width, colour : make_color_rgb(35, 55, 85), text : "SAVE WORKSPACE" },
    { bx : top_ui_test_x, by : top_ui_row_1_y, bw : _bw, colour : c_maroon, text : "T: SETUP" },
    { bx : top_ui_test_x, by : top_ui_row_2_y, bw : _bw, colour : c_maroon, text : "T: SPRITE" },
    { bx : top_ui_test_2_x, by : top_ui_row_1_y, bw : _bw, colour : c_maroon, text : "T: BOB-BMP" },
    { bx : top_ui_test_2_x, by : top_ui_row_2_y, bw : _bw, colour : c_maroon, text : "T: SPR-BMP" },
    { bx : top_ui_editor_x, by : top_ui_row_1_y, bw : _bw, colour : make_color_rgb(120, 60, 160), text : "SPR-EDIT" },
    { bx : top_ui_editor_x, by : top_ui_row_2_y, bw : _bw, colour : make_color_rgb(35, 55, 85), text : "BMP-EDIT" },
    { bx : top_ui_editor_2_x, by : top_ui_row_1_y, bw : _bw, colour : make_color_rgb(75, 65, 35), text : "BOB-EDIT" },
    { bx : top_ui_editor_2_x, by : top_ui_row_2_y, bw : _bw, colour : make_color_rgb(30, 90, 95), text : "SND-EDIT" },
    { bx : top_ui_tutorial_x, by : top_ui_row_1_y, bw : _bw, colour : make_color_rgb(60, 95, 40), text : "TILE-EDIT" },
    { bx : top_ui_tutorial_x + 104, by : top_ui_row_1_y, bw : _bw, colour : make_color_rgb(40, 80, 150), text : "TOUR (F1)" },
    { bx : top_ui_tutorial_x, by : top_ui_row_2_y, bw : _bw, colour : make_color_rgb(120, 70, 20), text : "TUTORIALS" },
    { bx : top_ui_tutorial_x + 104, by : top_ui_row_2_y, bw : _bw, colour : make_color_rgb(50, 70, 90), text : global.window_is_fullscreen ? "WINDOWED" : "FULL SCREEN" },
    { bx : top_ui_course_x, by : top_ui_row_1_y, bw : top_ui_course_width, colour : make_color_rgb(110, 40, 110), text : "68K COURSE" },
    { bx : top_ui_org_x, by : top_ui_row_2_y, bw : _bw, colour : make_color_rgb(25, 105, 105), text : "TRACKER" },
    // Machine, run and boot controls.
    { bx : top_ui_machine_x, by : top_ui_row_1_y, bw : _bw, colour : make_color_rgb(70, 60, 110), text : "MACH: " + _machine_profile.name },
    { bx : top_ui_machine_x, by : top_ui_row_2_y, bw : _bw, colour : _run_busy ? make_color_rgb(110, 90, 20) : make_color_rgb(30, 120, 50), text : _run_busy ? "BUILDING.." : "RUN (F5)" },
    { bx : top_ui_machine_2_x, by : top_ui_row_1_y, bw : _bw, colour : make_color_rgb(60, 60, 70), text : scr_amiga_kickstart_current() == "" ? "ROM: AROS" : "ROM: KICK" },
    { bx : top_ui_machine_2_x, by : top_ui_row_2_y, bw : _bw, colour : make_color_rgb(60, 60, 70), text : "BOOT: " + global.build_boot_mode }
];
draw_set_font(UI_FONT_SMALL);
var _toolbar_hover_ok = !scr_amiga_modal_open();
var _toolbar_i = 0;
while (_toolbar_i < array_length(_toolbar_buttons)) {
    var _tb = _toolbar_buttons[_toolbar_i];
    var _tb_hover = _toolbar_hover_ok && point_in_rectangle(mouse_x, mouse_y, _tb.bx, _tb.by, _tb.bx + _tb.bw, _tb.by + top_ui_button_height);
    scr_ui_button(_tb.bx, _tb.by, _tb.bx + _tb.bw, _tb.by + top_ui_button_height, scr_ui_fit_label(_tb.text, _tb.bw - 6), _tb.colour, _tb_hover);
    _toolbar_i += 1;
}
draw_set_font(UI_FONT);

if (keyboard_check(vk_control)) {
    var _hud_text = "Undo: " + string(array_length(global.undo_stack)) + "   Redo: " + string(array_length(global.redo_stack));
    var _hud_x = mouse_x + 16;
    var _hud_y = mouse_y + 16;
    var _hud_width = string_width(_hud_text) + 16;
    var _hud_height = 22;

    draw_set_alpha(0.85);
    scr_ui_box_fill(_hud_x, _hud_y, _hud_x + _hud_width, _hud_y + _hud_height, make_colour_rgb(12, 14, 24));
    draw_set_alpha(1);
    scr_ui_box_outline(_hud_x, _hud_y, _hud_x + _hud_width, _hud_y + _hud_height, c_white);
    draw_set_colour(c_white);
    scr_ui_text_mid(_hud_x + 8, _hud_y, _hud_y + _hud_height, _hud_text);
}

if (array_length(global.status_message_log) > 0) {
    var _status_bar_height = 122;
    var _status_bar_y = room_height - _status_bar_height;
    var _status_line_height = 18;
    var _status_bar_x = 272;
    var _status_bar_width = 1280;

    draw_set_alpha(0.8);
    scr_ui_box_fill(_status_bar_x, _status_bar_y, _status_bar_x + _status_bar_width, room_height - 2, make_colour_rgb(6, 8, 16));
    draw_set_alpha(1);
    scr_ui_box_outline(_status_bar_x, _status_bar_y, _status_bar_x + _status_bar_width, room_height - 2, c_white);

    var _log_count = array_length(global.status_message_log);
    var _status_line_y = _status_bar_y + 6;
    var _i = _log_count - 1;

    while (_i >= 0 && _status_line_y <= room_height - _status_line_height - 2) {
        var _log_entry = global.status_message_log[_i];
        var _status_colour = c_white;

        if (_log_entry.colour != undefined) {
            _status_colour = _log_entry.colour;
        } else if (_i == _log_count - 1) {
            _status_colour = c_yellow;
        }

        draw_set_colour(_status_colour);
        draw_text(_status_bar_x + 12, _status_line_y, scr_ui_fit_label(_log_entry.text, _status_bar_width - 24));

        _status_line_y += _status_line_height;
        _i -= 1;
    }

    draw_set_colour(c_white);
}

if (global.sprite_editor_open) {
    var _layout = scr_sprite_editor_layout();
    var _px1 = _layout.panel_x;
    var _py1 = _layout.panel_y;
    var _px2 = _layout.panel_x + _layout.panel_width;
    var _py2 = _layout.panel_y + _layout.panel_height;
    var _field_colour = make_colour_rgb(45, 65, 85);
    var _on_colour = make_colour_rgb(35, 110, 75);

    draw_set_alpha(0.92);
    scr_ui_box_fill(_px1, _py1, _px2, _py2, make_colour_rgb(8, 10, 18));
    scr_ui_header_band(_px1, _py1, _px2, _py2, _py1 + _layout.header_height, make_colour_rgb(40, 50, 80));
    draw_set_alpha(1);
    scr_ui_box_outline(_px1, _py1, _px2, _py2, c_white);

    var _over_editor_header = point_in_rectangle(mouse_x, mouse_y, _layout.header_x, _layout.header_y, _layout.header_x + _layout.header_width, _layout.header_y + _layout.header_height);
    var _over_editor_close = point_in_rectangle(mouse_x, mouse_y, _layout.close_x, _layout.close_y, _layout.close_x + 16, _layout.close_y + 16);
    var _header_text = "SPRITE EDITOR - " + global.sprite_asset_name;

    if ((_over_editor_header && !_over_editor_close) || global.sprite_editor_dragging) {
        _header_text = "SPRITE EDITOR - Grab to drag";
    }

    draw_set_colour(c_white);
    scr_ui_text_mid(_px1 + 12, _py1, _py1 + _layout.header_height, scr_ui_fit_label(_header_text, _layout.close_x - _px1 - 18));

    scr_ui_button(_layout.close_x, _layout.close_y, _layout.close_x + 16, _layout.close_y + 16, "X", make_colour_rgb(170, 30, 30), _over_editor_close);

    // Asset row: < name > ADD SPRITE.
    var _asset_y2 = _layout.asset_row_y + 20;
    scr_ui_button(_layout.asset_prev_x, _layout.asset_row_y, _layout.asset_prev_x + 28, _asset_y2, "<", _field_colour,
        point_in_rectangle(mouse_x, mouse_y, _layout.asset_prev_x, _layout.asset_row_y, _layout.asset_prev_x + 28, _asset_y2));
    scr_ui_box(_layout.asset_prev_x + 34, _layout.asset_row_y, _layout.asset_next_x - 6, _asset_y2, make_colour_rgb(20, 28, 40), make_colour_rgb(90, 110, 140));
    draw_set_colour(c_white);
    scr_ui_text_mid(_layout.asset_prev_x + 42, _layout.asset_row_y, _asset_y2, scr_ui_fit_label(global.sprite_asset_name, _layout.asset_next_x - _layout.asset_prev_x - 54));
    scr_ui_button(_layout.asset_next_x, _layout.asset_row_y, _layout.asset_next_x + 28, _asset_y2, ">", _field_colour,
        point_in_rectangle(mouse_x, mouse_y, _layout.asset_next_x, _layout.asset_row_y, _layout.asset_next_x + 28, _asset_y2));
    scr_ui_button(_layout.asset_add_x, _layout.asset_row_y, _layout.asset_add_x + _layout.asset_add_width, _asset_y2, "ADD SPRITE", _field_colour,
        point_in_rectangle(mouse_x, mouse_y, _layout.asset_add_x, _layout.asset_row_y, _layout.asset_add_x + _layout.asset_add_width, _asset_y2));

    // Channel, height and address rows: labels at +12, controls at +108.
    draw_set_colour(c_white);
    scr_ui_text_mid(_px1 + 12, _layout.channel_row_y, _layout.channel_row_y + 16, "CHANNEL:");
    scr_ui_button(_layout.channel_minus_x, _layout.channel_row_y, _layout.channel_minus_x + 16, _layout.channel_row_y + 16, "<", _field_colour);
    draw_set_colour(c_white);
    scr_ui_text_centred((_layout.channel_minus_x + 16 + _layout.channel_plus_x) * 0.5, _layout.channel_row_y + 8, string(global.sprite_channel));
    scr_ui_button(_layout.channel_plus_x, _layout.channel_row_y, _layout.channel_plus_x + 16, _layout.channel_row_y + 16, ">", _field_colour);

    var _pair_index = global.sprite_channel div 2;
    var _base_colour_index = 17 + (_pair_index * 4);
    draw_set_colour(c_white);
    scr_ui_text_mid(_layout.channel_plus_x + 28, _layout.channel_row_y, _layout.channel_row_y + 16, "COLOR" + string(_base_colour_index) + "-" + string(_base_colour_index + 2));

    scr_ui_text_mid(_px1 + 12, _layout.height_row_y, _layout.height_row_y + 16, "HEIGHT:");
    var _height_display = string(global.sprite_height);
    var _height_colour = c_dkgray;

    if (global.sprite_editing_field == "height") {
        _height_display = global.sprite_edit_text;
        _height_colour = c_olive;
    }

    scr_ui_box(_layout.height_field_x, _layout.height_row_y, _layout.height_field_x + 60, _layout.height_row_y + 16, _height_colour, c_white);
    draw_set_colour(c_white);
    scr_ui_text_mid(_layout.height_field_x + 6, _layout.height_row_y, _layout.height_row_y + 16, _height_display);

    scr_ui_text_mid(_px1 + 12, _layout.addr_row_y, _layout.addr_row_y + 16, "ADDR:");
    var _addr_display = "$" + scr_number_to_hex_string(global.sprite_address);
    var _addr_colour = c_dkgray;

    if (global.sprite_editing_field == "address") {
        _addr_display = "$" + global.sprite_edit_text;
        _addr_colour = c_olive;
    }

    scr_ui_box(_layout.addr_field_x, _layout.addr_row_y, _layout.addr_field_x + 80, _layout.addr_row_y + 16, _addr_colour, c_white);
    draw_set_colour(c_white);
    scr_ui_text_mid(_layout.addr_field_x + 6, _layout.addr_row_y, _layout.addr_row_y + 16, _addr_display);

    // Colour swatches are data: plain squares.
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

    draw_set_colour(make_colour_rgb(180, 190, 210));
    draw_text(_layout.swatch_x, _layout.swatch_row_y + _layout.swatch_height + 4, "LEFT: paint / pick   RIGHT: erase");

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

    var _sprite_tool_names = ["DRAW", "LINE", "FILL", "CIRCLE", "DISC"];
    var _sprite_tool_labels = ["DRAW", "LINE", "FILL", "CIRCLE", "FILL CIRCLE"];
    var _sprite_tool_i = 0;
    while (_sprite_tool_i < _layout.tool_count) {
        var _sprite_tool_y = _layout.tool_y + _sprite_tool_i * _layout.tool_step;
        var _tool_on = global.sprite_tool == _sprite_tool_names[_sprite_tool_i];
        scr_ui_button(_layout.tool_x, _sprite_tool_y, _layout.tool_x + _layout.tool_width, _sprite_tool_y + _layout.tool_height, scr_ui_fit_label(_sprite_tool_labels[_sprite_tool_i], _layout.tool_width - 8), _tool_on ? _on_colour : _field_colour,
            point_in_rectangle(mouse_x, mouse_y, _layout.tool_x, _sprite_tool_y, _layout.tool_x + _layout.tool_width, _sprite_tool_y + _layout.tool_height));
        _sprite_tool_i += 1;
    }

    var _anim_x2 = _layout.anim_x + _layout.anim_width;
    scr_ui_button(_layout.anim_x, _layout.anim_play_y, _anim_x2, _layout.anim_play_y + _layout.anim_height, global.sprite_anim_playing ? "STOP" : "PLAY", global.sprite_anim_playing ? _on_colour : _field_colour,
        point_in_rectangle(mouse_x, mouse_y, _layout.anim_x, _layout.anim_play_y, _anim_x2, _layout.anim_play_y + _layout.anim_height));
    scr_ui_button(_layout.anim_x, _layout.anim_loop_y, _anim_x2, _layout.anim_loop_y + _layout.anim_height, "LOOP " + (global.sprite_anim_loop ? "ON" : "OFF"), global.sprite_anim_loop ? _on_colour : _field_colour,
        point_in_rectangle(mouse_x, mouse_y, _layout.anim_x, _layout.anim_loop_y, _anim_x2, _layout.anim_loop_y + _layout.anim_height));

    var _sprite_anim_values = [
        "RATE " + string(global.sprite_anim_rate),
        "START " + string(global.sprite_anim_start),
        "END " + string(global.sprite_anim_end)
    ];
    var _sprite_anim_y = [_layout.anim_rate_y, _layout.anim_start_y, _layout.anim_end_y];
    var _sprite_anim_i = 0;
    while (_sprite_anim_i < 3) {
        var _ay1 = _sprite_anim_y[_sprite_anim_i];
        var _ay2 = _ay1 + _layout.anim_height;
        scr_ui_button(_layout.anim_x, _ay1, _anim_x2, _ay2, _sprite_anim_values[_sprite_anim_i], _field_colour,
            point_in_rectangle(mouse_x, mouse_y, _layout.anim_x, _ay1, _anim_x2, _ay2));
        // The left half steps down, the right half up.
        draw_set_colour(c_white);
        scr_ui_text_mid(_layout.anim_x + 6, _ay1, _ay2, "<");
        draw_set_halign(fa_right);
        scr_ui_text_mid(_anim_x2 - 6, _ay1, _ay2, ">");
        draw_set_halign(fa_left);
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

    if (global.sprite_circle_active) {
        var _circle_colour = c_black;
        if (global.sprite_circle_value >= 1) {
            var _circle_index = global.sprite_circle_value - 1;
            _circle_colour = make_color_rgb(global.sprite_colour_r[_circle_index] * 17,
                global.sprite_colour_g[_circle_index] * 17, global.sprite_colour_b[_circle_index] * 17);
        }
        var _circle = scr_shape_circle_pixels(global.sprite_circle_cx, global.sprite_circle_cy, global.sprite_circle_r,
            global.sprite_tool == "DISC", 16, global.sprite_height);
        draw_set_colour(_circle_colour);
        for (var _ci = 0; _ci < array_length(_circle); _ci += 2) {
            var _circle_x = _layout.grid_x + _circle[_ci] * _layout.cell_size;
            var _circle_y = _layout.grid_y + _circle[_ci + 1] * _layout.cell_size;
            draw_rectangle(_circle_x, _circle_y, _circle_x + _layout.cell_size, _circle_y + _layout.cell_size, false);
        }
        draw_set_colour(c_yellow);
        var _centre_x = _layout.grid_x + global.sprite_circle_cx * _layout.cell_size;
        var _centre_y = _layout.grid_y + global.sprite_circle_cy * _layout.cell_size;
        draw_rectangle(_centre_x, _centre_y, _centre_x + _layout.cell_size, _centre_y + _layout.cell_size, true);
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
    draw_text(_px1 + 12, _layout.palette_y - 2, "PALETTE EDITOR  COLOR" + string(_edit_register) + "  #" + _edit_hex);

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
        scr_ui_text_centred(_layout.slider_x - 12, _slider_y + _layout.slider_height * 0.5, _slider_label);

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
        scr_ui_text_mid(_layout.slider_x + _layout.slider_width + 8, _slider_y, _slider_y + _layout.slider_height, string_char_at(_hex_digits, _slider_selected_value + 1));

        _slider_channel += 1;
    }

    draw_set_colour(c_white);
}
