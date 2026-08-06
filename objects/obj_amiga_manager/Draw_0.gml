var _has_hover = (global.palette_hover_mnemonic != "");

if (_has_hover) {
    var _tooltip_data = scr_opcode_lookup(global.palette_hover_mnemonic);

    if (_tooltip_data != undefined) {
        var _tip_x = global.palette_hover_x + 16;
        var _tip_y = global.palette_hover_y + 16;
        var _tip_width = 700;
        var _tip_height = 100;

        draw_set_alpha(0.9);
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
var _panel_height = room_height - 80;

draw_set_alpha(0.85);
draw_rectangle_colour(_panel_x, _panel_y, _panel_x + _panel_width, _panel_y + _panel_height, c_black, c_black, c_black, c_black, false);
draw_set_alpha(1);
draw_set_colour(c_white);
draw_rectangle(_panel_x, _panel_y, _panel_x + _panel_width, _panel_y + _panel_height, true);
draw_text(_panel_x + 6, _panel_y + 4, "COMPILED PROGRAM PREVIEW");

var _line_y = _panel_y + 24 + global.preview_scroll_y;
var _line_height = 16;
var _preview_line_count = array_length(preview_line_cache);

if (_preview_line_count == 0) {
    draw_set_colour(c_red);
    draw_text(_panel_x + 6, _panel_y + 24, "(NO CODE ADDED YET)");
    draw_set_colour(c_white);
} else {
    var _p = 0;

    while (_p < _preview_line_count) {
        var _line_data = preview_line_cache[_p];
        var _is_visible = (_line_y >= _panel_y + 20) && (_line_y <= _panel_y + _panel_height - _line_height);

        if (_is_visible) {
            var _line_colour = c_white;

            if (_line_data.is_error) {
                _line_colour = c_red;
            } else if (_line_data.is_macro_header) {
                _line_colour = make_color_rgb(220, 160, 255);
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

draw_set_colour(c_white);

var _macro_but_width = 100;
var _macro_xpos = 310;

draw_text(_macro_xpos, 2, "MACROS:");
draw_set_colour(c_maroon);
draw_rectangle(_macro_xpos, 20, _macro_xpos+_macro_but_width, 36, false);
draw_set_colour(c_white);
draw_rectangle(_macro_xpos, 20, _macro_xpos+_macro_but_width, 36, true);
draw_text(318, 18, "TEST");

draw_set_colour(make_color_rgb(120, 60, 160));
draw_rectangle(_macro_xpos, 64, _macro_xpos+_macro_but_width, 80, false);
draw_set_colour(c_white);
draw_rectangle(_macro_xpos, 64, _macro_xpos+_macro_but_width, 80, true);
draw_text(312, 62, "SPR EDIT");

draw_set_colour(c_maroon);
draw_rectangle(_macro_xpos, 84, _macro_xpos+_macro_but_width, 100, false);
draw_set_colour(c_white);
draw_rectangle(_macro_xpos, 84, _macro_xpos+_macro_but_width, 100, true);
draw_text(312, 82, "TEST SPR");

if (keyboard_check(vk_control)) {
    var _hud_text = "Undo: " + string(array_length(global.undo_stack)) + "   Redo: " + string(array_length(global.redo_stack));
    var _hud_x = mouse_x + 16;
    var _hud_y = mouse_y + 16;
    var _hud_width = 160;
    var _hud_height = 20;

    draw_set_alpha(0.85);
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

    draw_set_alpha(0.85);
    draw_rectangle_colour(0, _status_bar_y, room_width, room_height, c_black, c_black, c_black, c_black, false);
    draw_set_alpha(1);
    draw_set_colour(c_white);
    draw_rectangle(0, _status_bar_y, room_width, room_height, true);

    var _log_count = array_length(global.status_message_log);
    var _line_y = _status_bar_y + 4;
    var _i = _log_count - 1;

    while (_i >= 0 && _line_y <= room_height - _status_line_height) {
        var _line_colour = c_white;

        if (_i == _log_count - 1) {
            _line_colour = c_yellow;
        }

        draw_set_colour(_line_colour);
        draw_text(8, _line_y, global.status_message_log[_i]);

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
    draw_text(_layout.panel_x + 6, _layout.panel_y + 2, "SPRITE EDITOR");

    draw_set_colour(c_red);
    draw_rectangle(_layout.close_x, _layout.close_y, _layout.close_x + 16, _layout.close_y + 16, false);
    draw_set_colour(c_white);
    draw_rectangle(_layout.close_x, _layout.close_y, _layout.close_x + 16, _layout.close_y + 16, true);
    draw_text(_layout.close_x + 4, _layout.close_y - 1, "X");

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

        if (global.sprite_editing_field == ("colour" + string(_swatch_index))) {
            draw_text(_swatch_x, _layout.swatch_row_y - 14, global.sprite_edit_text);
        }

        _swatch_index += 1;
    }

    draw_set_colour(c_white);
    draw_text(_layout.swatch_x, _layout.swatch_row_y + _layout.swatch_height + 2, "click=paint  right-click swatch=edit colour");

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

    draw_set_colour(c_white);
}