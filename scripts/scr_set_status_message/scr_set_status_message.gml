/// @desc scr_set_status_message(_text)
/// Appends _text to the status message log, drawn at the bottom of the
/// screen with newest on top. Empty strings are ignored (harmless no-op)
/// rather than clearing the log — this is a history now, not a single
/// transient line, so there's nothing to "clear" on commit/cancel.
function scr_set_status_message(_text) {
    if (_text == "") {
        return;
    }

    array_push(global.status_message_log, _text);

    var _max_log_lines = 20;

    if (array_length(global.status_message_log) > _max_log_lines) {
        array_delete(global.status_message_log, 0, 1);
    }
}
