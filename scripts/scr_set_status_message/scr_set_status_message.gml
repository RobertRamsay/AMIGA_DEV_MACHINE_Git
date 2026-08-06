/// @desc scr_set_status_message(_text)
/// Sets the reusable status/hint text drawn at the bottom of the screen.
/// Pass "" to clear it.
function scr_set_status_message(_text) {
    global.status_message = _text;
}
