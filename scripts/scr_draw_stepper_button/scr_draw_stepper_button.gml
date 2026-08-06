/// @desc scr_draw_stepper_button(_x, _y, _width, _height, _label)
/// Draws a small clickable +/- style button. Purely visual — callers
/// handle their own click detection at the same coordinates.
function scr_draw_stepper_button(_x, _y, _width, _height, _label) {
    draw_set_colour(c_dkgray);
    draw_rectangle(_x, _y, _x + _width, _y + _height, false);
    draw_set_colour(c_white);
    draw_rectangle(_x, _y, _x + _width, _y + _height, true);
    draw_text(_x + (_width / 2) - 4, _y + 2, _label);
}
