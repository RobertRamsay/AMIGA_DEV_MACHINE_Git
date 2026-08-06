/// @desc scr_set_status_message(_text, [_colour])
/// Appends _text to the status message log, drawn at the bottom of the
/// screen with newest on top. Empty strings are ignored (harmless no-op)
/// rather than clearing the log — this is a history now, not a single
/// transient line, so there's nothing to "clear" on commit/cancel.
/// _colour is optional — leave it unset for the normal newest-line-yellow
/// convention, or pass an explicit colour (e.g. c_red) to force this one
/// line to always draw in that colour regardless of its age in the log.
function scr_set_status_message(_text, _colour = undefined) {
    if (_text == "") {
        return;
    }

    var _log_entry = {
        text : _text,
        colour : _colour
    };

    array_push(global.status_message_log, _log_entry);

    var _max_log_lines = 20;

    if (array_length(global.status_message_log) > _max_log_lines) {
        array_delete(global.status_message_log, 0, 1);
    }
}
