/// @desc scr_draw_stepper_button(_x, _y, _width, _height, _label)
/// Draws a small clickable +/- style button. Purely visual — callers
/// handle their own click detection at the same coordinates.
function scr_draw_stepper_button(_x, _y, _width, _height, _label) {
    scr_ui_button(_x, _y, _x + _width, _y + _height, _label, c_dkgray);
}
