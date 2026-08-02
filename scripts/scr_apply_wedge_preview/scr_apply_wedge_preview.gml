/// @desc scr_apply_wedge_preview(_child_uid, _shift_amount)
/// Temporarily nudges the node at _child_uid, and everything below it in the
/// chain, down by _shift_amount for preview only — does not touch real node_y.
function scr_apply_wedge_preview(_child_uid, _shift_amount) {
    var _cursor_uid = _child_uid;
    var _still_walking = true;

    while (_still_walking) {
        _still_walking = false;

        with (obj_opcode_node) {
            if (uid == _cursor_uid) {
                wedge_preview_shift_y = _shift_amount;
            }
        }

        var _next_uid = -1;

        with (obj_opcode_node) {
            if (parent_uid == _cursor_uid) {
                _next_uid = uid;
            }
        }

        if (_next_uid != -1) {
            _cursor_uid = _next_uid;
            _still_walking = true;
        }
    }
}
