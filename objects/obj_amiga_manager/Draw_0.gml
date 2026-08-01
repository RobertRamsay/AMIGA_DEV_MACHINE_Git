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