draw_set_alpha(0.94);
draw_set_colour(make_colour_rgb(18, 22, 30));
draw_rectangle(panel_x, panel_y, panel_x + panel_w, panel_y + panel_h, false);
draw_set_alpha(1);
draw_set_colour(make_colour_rgb(65, 82, 105));
draw_rectangle(panel_x, panel_y, panel_x + panel_w, panel_y + header_h, false);
draw_set_colour(c_white);
draw_text(panel_x + 8, panel_y + 4, "BOB EDITOR — TestBob 32x32     Grab to drag");
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

draw_set_colour(make_colour_rgb(90, 45, 45)); draw_rectangle(_palette_x, panel_y + 410, _palette_x + 130, panel_y + 440, false);
draw_set_colour(c_white); draw_text(_palette_x + 30, panel_y + 417, "CLEAR (0)");
draw_set_colour(make_colour_rgb(25, 95, 65)); draw_rectangle(_palette_x, panel_y + 460, _palette_x + 145, panel_y + 494, false);
draw_rectangle(_palette_x + 160, panel_y + 460, _palette_x + 305, panel_y + 494, false);
draw_set_colour(c_white); draw_text(_palette_x + 14, panel_y + 470, "TEST BOB-BMP"); draw_text(_palette_x + 172, panel_y + 470, "TEST SPR-BMP");
draw_text(_palette_x, panel_y + 525, "LMB draw   RMB erase/transparent");
