draw_set_font(UI_FONT);
draw_set_halign(fa_left);
draw_set_valign(fa_top);

var _panel_x2 = panel_x + panel_w;
var _panel_y2 = panel_y + panel_h;
var _button_fill = make_colour_rgb(45, 65, 85);
var _active_fill = make_colour_rgb(35, 110, 75);

draw_set_alpha(0.94);
scr_ui_box_fill(panel_x, panel_y, _panel_x2, _panel_y2, make_colour_rgb(18, 22, 30));
draw_set_alpha(1);
// Header strip, inset so it stays inside the panel's bevelled corner.
scr_ui_box_fill(panel_x + 4, panel_y + 4, _panel_x2 - 4, panel_y + header_h, make_colour_rgb(65, 82, 105));
scr_ui_box_outline(panel_x, panel_y, _panel_x2, _panel_y2, make_colour_rgb(150, 165, 190));
draw_set_colour(c_white);
scr_ui_text_mid(panel_x + 12, panel_y + 4, panel_y + header_h, "BOB EDITOR - " + bob_asset_name + " 32x32     Grab to drag");
var _close_x1 = _panel_x2 - 24;
var _close_y1 = panel_y + 5;
scr_ui_button(_close_x1, _close_y1, _panel_x2 - 6, panel_y + 21, "X", make_colour_rgb(170, 30, 30),
    point_in_rectangle(mouse_x, mouse_y, _close_x1, _close_y1, _panel_x2 - 6, panel_y + 21));

var _gx = panel_x + grid_x_offset;
var _gy = panel_y + grid_y_offset;
for (var _y = 0; _y < bob_height; _y += 1) {
    for (var _x = 0; _x < bob_width; _x += 1) {
        var _index = bob_pixels[_y * bob_width + _x];
        var _col = _index == 0 ? make_colour_rgb(38, 38, 38) : make_colour_rgb(colour_r[_index] * 17, colour_g[_index] * 17, colour_b[_index] * 17);
        draw_set_colour(_col);
        draw_rectangle(_gx + _x * cell_size, _gy + _y * cell_size, _gx + (_x + 1) * cell_size - 1, _gy + (_y + 1) * cell_size - 1, false);
    }
}
draw_set_colour(make_colour_rgb(70, 70, 70));
for (var _line = 0; _line <= 32; _line += 1) {
    draw_line(_gx + _line * cell_size, _gy, _gx + _line * cell_size, _gy + 512);
    draw_line(_gx, _gy + _line * cell_size, _gx + 512, _gy + _line * cell_size);
}
if (bob_line_active) {
    var _preview_colour = bob_line_value == 0 ? make_colour_rgb(38, 38, 38)
        : make_colour_rgb(colour_r[bob_line_value] * 17, colour_g[bob_line_value] * 17, colour_b[bob_line_value] * 17);
    var _lx = bob_line_start_x, _ly = bob_line_start_y;
    var _ldx = abs(bob_line_current_x - _lx), _lsx = _lx < bob_line_current_x ? 1 : -1;
    var _ldy = -abs(bob_line_current_y - _ly), _lsy = _ly < bob_line_current_y ? 1 : -1;
    var _lerr = _ldx + _ldy;
    repeat (128) {
        draw_set_colour(_preview_colour);
        draw_rectangle(_gx + _lx * cell_size, _gy + _ly * cell_size, _gx + (_lx + 1) * cell_size - 1, _gy + (_ly + 1) * cell_size - 1, false);
        draw_set_colour(c_yellow);
        draw_rectangle(_gx + _lx * cell_size, _gy + _ly * cell_size, _gx + (_lx + 1) * cell_size - 1, _gy + (_ly + 1) * cell_size - 1, true);
        if (_lx == bob_line_current_x && _ly == bob_line_current_y) break;
        var _le2 = 2 * _lerr;
        if (_le2 >= _ldy) { _lerr += _ldy; _lx += _lsx; }
        if (_le2 <= _ldx) { _lerr += _ldx; _ly += _lsy; }
    }
}
if (bob_circle_active) {
    draw_set_colour(bob_circle_value == 0 ? make_colour_rgb(38, 38, 38)
        : make_colour_rgb(colour_r[bob_circle_value] * 17, colour_g[bob_circle_value] * 17, colour_b[bob_circle_value] * 17));
    var _circle = scr_shape_circle_pixels(bob_circle_cx, bob_circle_cy, bob_circle_r, bob_tool == "DISC", bob_width, bob_height);
    for (var _ci = 0; _ci < array_length(_circle); _ci += 2) {
        var _cx1 = _gx + _circle[_ci] * cell_size;
        var _cy1 = _gy + _circle[_ci + 1] * cell_size;
        draw_rectangle(_cx1, _cy1, _cx1 + cell_size - 1, _cy1 + cell_size - 1, false);
    }
    draw_set_colour(c_yellow);
    var _ccx = _gx + bob_circle_cx * cell_size;
    var _ccy = _gy + bob_circle_cy * cell_size;
    draw_rectangle(_ccx, _ccy, _ccx + cell_size - 1, _ccy + cell_size - 1, true);
}

// Right-hand column: palette, sliders, then three columns of buttons.
var _palette_x = panel_x + column_x_offset;
var _palette_y = panel_y + 58;
var _col_2 = _palette_x + button_step;
var _col_3 = _palette_x + 2 * button_step;
draw_set_colour(c_white);
scr_ui_text_mid(_palette_x, panel_y + 32, _palette_y - 4, "SHARED BITMAP / BOB PALETTE");
for (var _i = 0; _i < 32; _i += 1) {
    var _sx = _palette_x + ((_i mod 8) * swatch_step);
    var _sy = _palette_y + ((_i div 8) * swatch_step);
    draw_set_colour(make_colour_rgb(colour_r[_i] * 17, colour_g[_i] * 17, colour_b[_i] * 17));
    draw_rectangle(_sx, _sy, _sx + swatch_size - 1, _sy + swatch_size - 1, false);
    draw_set_colour(_i == pen_index ? c_white : c_gray);
    draw_rectangle(_sx - 1, _sy - 1, _sx + swatch_size, _sy + swatch_size, true);
    if (_i == pen_index) draw_rectangle(_sx - 2, _sy - 2, _sx + swatch_size + 1, _sy + swatch_size + 1, true);
    if (_i == 0) {
        draw_set_colour(c_gray);
        draw_line(_sx, _sy, _sx + swatch_size - 1, _sy + swatch_size - 1);
        draw_line(_sx + swatch_size - 1, _sy, _sx, _sy + swatch_size - 1);
    }
}

var _names = ["R", "G", "B"];
var _values = [colour_r[pen_index], colour_g[pen_index], colour_b[pen_index]];
var _track_x1 = _palette_x + slider_track_x;
var _track_x2 = _track_x1 + 15 * slider_step;
for (var _c = 0; _c < 3; _c += 1) {
    var _sy2 = panel_y + 250 + _c * 42;
    draw_set_colour(c_white);
    scr_ui_text_mid(_palette_x, _sy2, _sy2 + 20, _names[_c]);
    draw_set_colour(make_colour_rgb(80, 80, 80));
    draw_rectangle(_track_x1, _sy2 + 8, _track_x2, _sy2 + 12, false);
    var _knob_x = _track_x1 + _values[_c] * slider_step;
    draw_set_colour(c_white);
    draw_rectangle(_knob_x - 3, _sy2 + 2, _knob_x + 3, _sy2 + 18, false);
    scr_ui_text_mid(_track_x2 + 14, _sy2, _sy2 + 20, string(_values[_c]));
}

// Asset row: < name > and ADD BOB.
var _asset_y = panel_y + 370;
var _asset_y2 = _asset_y + 26;
scr_ui_button(_palette_x, _asset_y, _palette_x + 28, _asset_y2, "<", _button_fill,
    point_in_rectangle(mouse_x, mouse_y, _palette_x, _asset_y, _palette_x + 28, _asset_y2));
scr_ui_box(_palette_x + 34, _asset_y, _palette_x + 190, _asset_y2, make_colour_rgb(28, 36, 48), make_colour_rgb(90, 105, 130));
var _shown_name = bob_asset_name;
while (string_length(_shown_name) > 1 && string_width(_shown_name) > 140) {
    _shown_name = string_copy(_shown_name, 1, string_length(_shown_name) - 1);
}
if (_shown_name != bob_asset_name) _shown_name += "..";
draw_set_colour(c_white);
scr_ui_text_mid(_palette_x + 42, _asset_y, _asset_y2, _shown_name);
scr_ui_button(_palette_x + 196, _asset_y, _palette_x + 224, _asset_y2, ">", _button_fill,
    point_in_rectangle(mouse_x, mouse_y, _palette_x + 196, _asset_y, _palette_x + 224, _asset_y2));
scr_ui_button(_col_3, _asset_y, _palette_x + column_width, _asset_y2, "ADD BOB", _button_fill,
    point_in_rectangle(mouse_x, mouse_y, _col_3, _asset_y, _palette_x + column_width, _asset_y2));

var _tool_names = ["DRAW", "LINE", "FILL", "CIRCLE", "DISC"];
var _tool_labels = ["DRAW", "LINE", "FILL", "CIRCLE", "FILLED CIRCLE"];
for (var _tool_i = 0; _tool_i < 5; _tool_i += 1) {
    var _tr = bob_tool_rect(_tool_i);
    scr_ui_button(_tr[0], _tr[1], _tr[2], _tr[3], _tool_labels[_tool_i],
        bob_tool == _tool_names[_tool_i] ? _active_fill : _button_fill,
        point_in_rectangle(mouse_x, mouse_y, _tr[0], _tr[1], _tr[2], _tr[3]));
}

var _anim_y = panel_y + 490;
scr_ui_button(_palette_x, _anim_y, _palette_x + button_w, _anim_y + 30, bob_anim_playing ? "STOP" : "PLAY",
    bob_anim_playing ? _active_fill : _button_fill,
    point_in_rectangle(mouse_x, mouse_y, _palette_x, _anim_y, _palette_x + button_w, _anim_y + 30));
scr_ui_button(_col_2, _anim_y, _col_2 + button_w, _anim_y + 30, "LOOP " + (bob_anim_loop ? "ON" : "OFF"),
    bob_anim_loop ? _active_fill : _button_fill,
    point_in_rectangle(mouse_x, mouse_y, _col_2, _anim_y, _col_2 + button_w, _anim_y + 30));

// Value buttons: left half steps down, right half steps up, so the arrows
// sit at the two ends with the value centred between them.
var _anim_value_y = panel_y + 530;
var _anim_labels = ["RATE " + string(bob_anim_rate), "START " + string(bob_anim_start), "END " + string(bob_anim_end)];
for (var _anim_i = 0; _anim_i < 3; _anim_i += 1) {
    var _ax = _palette_x + _anim_i * button_step;
    scr_ui_button(_ax, _anim_value_y, _ax + button_w, _anim_value_y + 30, _anim_labels[_anim_i], _button_fill,
        point_in_rectangle(mouse_x, mouse_y, _ax, _anim_value_y, _ax + button_w, _anim_value_y + 30));
    draw_set_colour(make_colour_rgb(190, 205, 225));
    scr_ui_text_centred(_ax + 8, _anim_value_y + 15, "<");
    scr_ui_text_centred(_ax + button_w - 7, _anim_value_y + 15, ">");
}

scr_ui_button(_palette_x, panel_y + 570, _palette_x + button_w, panel_y + 600, "CLEAR (0)", make_colour_rgb(90, 45, 45),
    point_in_rectangle(mouse_x, mouse_y, _palette_x, panel_y + 570, _palette_x + button_w, panel_y + 600));
var _test_w = (column_width - 12) div 2;
var _test_x2 = _palette_x + column_width - _test_w;
scr_ui_button(_palette_x, panel_y + 620, _palette_x + _test_w, panel_y + 654, "TEST BOB-BMP", make_colour_rgb(25, 95, 65),
    point_in_rectangle(mouse_x, mouse_y, _palette_x, panel_y + 620, _palette_x + _test_w, panel_y + 654));
scr_ui_button(_test_x2, panel_y + 620, _palette_x + column_width, panel_y + 654, "TEST SPR-BMP", make_colour_rgb(25, 95, 65),
    point_in_rectangle(mouse_x, mouse_y, _test_x2, panel_y + 620, _palette_x + column_width, panel_y + 654));
draw_set_colour(make_colour_rgb(190, 200, 215));
scr_ui_text_mid(_palette_x, panel_y + 664, panel_y + 684, "LMB: pen    RMB: transparent 0");
