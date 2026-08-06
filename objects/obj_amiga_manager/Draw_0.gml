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
draw_text(310, 2, "MACROS:");

draw_set_colour(c_maroon);
draw_rectangle(310, 20, 370, 36, false);
draw_set_colour(c_white);
draw_rectangle(310, 20, 370, 36, true);
draw_text(318, 18, "TEST");

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

if (global.status_message != "") {
    var _status_bar_height = 22;
    var _status_bar_y = room_height - _status_bar_height - 100;

    draw_set_alpha(0.85);
    draw_rectangle_colour(0, _status_bar_y, room_width, _status_bar_y + _status_bar_height, c_black, c_black, c_black, c_black, false);
    draw_set_alpha(1);
    draw_set_colour(c_white);
    draw_rectangle(0, _status_bar_y, room_width, _status_bar_y + _status_bar_height, true);
    draw_text(8, _status_bar_y + 3, global.status_message);
}