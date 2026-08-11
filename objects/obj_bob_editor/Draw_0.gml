draw_set_alpha(0.94);
draw_set_colour(make_colour_rgb(18, 22, 30));
draw_rectangle(panel_x, panel_y, panel_x + panel_w, panel_y + panel_h, false);
draw_set_alpha(1);
draw_set_colour(make_colour_rgb(65, 82, 105));
draw_rectangle(panel_x, panel_y, panel_x + panel_w, panel_y + header_h, false);
draw_set_colour(c_white);
draw_text(panel_x + 8, panel_y + 4, "BOB EDITOR - " + bob_asset_name + " 32x32     Grab to drag");
draw_set_colour(c_red);
draw_text(panel_x + panel_w - 21, panel_y + 4, "X");

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
    draw_set_colour(c_yellow);
    draw_line(_gx + bob_line_start_x * cell_size + cell_size div 2, _gy + bob_line_start_y * cell_size + cell_size div 2, mouse_x, mouse_y);
}

var _palette_x = panel_x + 560;
var _palette_y = panel_y + 58;
draw_set_colour(c_white);
draw_text(_palette_x, panel_y + 36, "SHARED BITMAP / BOB PALETTE");
for (var _i = 0; _i < 32; _i += 1) {
    var _sx = _palette_x + ((_i mod 8) * 38);
    var _sy = _palette_y + ((_i div 8) * 38);
    draw_set_colour(make_colour_rgb(colour_r[_i] * 17, colour_g[_i] * 17, colour_b[_i] * 17));
    draw_rectangle(_sx, _sy, _sx + 31, _sy + 31, false);
    draw_set_colour(_i == pen_index ? c_white : c_gray);
    draw_rectangle(_sx - 1, _sy - 1, _sx + 32, _sy + 32, true);
    if (_i == 0) { draw_line(_sx, _sy, _sx + 31, _sy + 31); draw_line(_sx + 31, _sy, _sx, _sy + 31); }
}

var _names = ["R", "G", "B"];
var _values = [colour_r[pen_index], colour_g[pen_index], colour_b[pen_index]];
for (var _c = 0; _c < 3; _c += 1) {
    var _sy2 = panel_y + 250 + _c * 42;
    draw_set_colour(c_white); draw_text(_palette_x, _sy2, _names[_c]);
    draw_set_colour(make_colour_rgb(80, 80, 80)); draw_rectangle(_palette_x + 22, _sy2 + 8, _palette_x + 262, _sy2 + 12, false);
    draw_set_colour(c_white); draw_rectangle(_palette_x + 19 + _values[_c] * 16, _sy2 + 2, _palette_x + 25 + _values[_c] * 16, _sy2 + 18, false);
    draw_text(_palette_x + 275, _sy2, string(_values[_c]));
}

var _asset_y = panel_y + 370;
draw_set_colour(make_colour_rgb(45, 65, 85));
draw_rectangle(_palette_x, _asset_y, _palette_x + 28, _asset_y + 26, false);
draw_rectangle(_palette_x + 34, _asset_y, _palette_x + 184, _asset_y + 26, false);
draw_rectangle(_palette_x + 190, _asset_y, _palette_x + 218, _asset_y + 26, false);
draw_rectangle(_palette_x + 228, _asset_y, _palette_x + 320, _asset_y + 26, false);
draw_set_colour(c_white);
draw_text(_palette_x + 9, _asset_y + 4, "<");
draw_text(_palette_x + 42, _asset_y + 4, bob_asset_name);
draw_text(_palette_x + 199, _asset_y + 4, ">");
draw_text(_palette_x + 240, _asset_y + 4, "ADD BOB");

var _tool_y = panel_y + 410;
var _tool_names = ["DRAW", "LINE", "FILL"];
for (var _tool_i = 0; _tool_i < 3; _tool_i += 1) {
    var _tx = _palette_x + _tool_i * 104;
    draw_set_colour(bob_tool == _tool_names[_tool_i] ? make_colour_rgb(35, 110, 75) : make_colour_rgb(45, 65, 85));
    draw_rectangle(_tx, _tool_y, _tx + 92, _tool_y + 30, false);
    draw_set_colour(c_white); draw_text(_tx + 20, _tool_y + 7, _tool_names[_tool_i]);
}

draw_set_colour(make_colour_rgb(90, 45, 45)); draw_rectangle(_palette_x, panel_y + 450, _palette_x + 130, panel_y + 480, false);
draw_set_colour(c_white); draw_text(_palette_x + 30, panel_y + 457, "CLEAR (0)");
draw_set_colour(make_colour_rgb(25, 95, 65)); draw_rectangle(_palette_x, panel_y + 500, _palette_x + 145, panel_y + 534, false);
draw_rectangle(_palette_x + 160, panel_y + 500, _palette_x + 305, panel_y + 534, false);
draw_set_colour(c_white); draw_text(_palette_x + 14, panel_y + 510, "TEST BOB-BMP"); draw_text(_palette_x + 172, panel_y + 510, "TEST SPR-BMP");
draw_text(_palette_x, panel_y + 548, "LMB uses pen   RMB uses transparent 0");
