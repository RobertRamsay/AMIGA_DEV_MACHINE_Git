/// @desc scr_amiga_find_insert_point(_dragged_id, _test_x, _test_y)
/// Finds the nearest root (INIT/ORG) column to _test_x, then the node
/// immediately above _test_y within that root's membership — purely by
/// Y-position, nothing stored as a link. Returns
/// { found, root_uid, insert_y, anchor_x }.
function scr_amiga_find_insert_point(_dragged_id, _test_x, _test_y) {
    var _result = { found : false, root_uid : -1, insert_y : 0, anchor_x : 0 };

    var _best_root_id = noone;
    var _best_dx = 999999;

    with (obj_amiga_root_node) {
        var _dx = abs(node_x - _test_x);

        if (_dx < _best_dx) {
            _best_dx = _dx;
            _best_root_id = id;
        }
    }

    if (_best_root_id == noone) {
        return _result;
    }

    var _column_threshold = (_best_root_id.node_width / 2) + 40;

    if (_best_dx > _column_threshold) {
        return _result;
    }

    var _root_uid = _best_root_id.uid;
    var _above_y = _best_root_id.node_y;
    var _above_height = _best_root_id.node_height;

    with (obj_opcode_node) {
        var _is_self = (id == _dragged_id);
        var _in_this_root = (root_uid == _root_uid) && is_connected;

        if (!_is_self && _in_this_root && node_y <= _test_y && node_y >= _above_y) {
            _above_y = node_y;
            _above_height = node_height;
        }
    }

    _result.found = true;
    _result.root_uid = _root_uid;
    _result.insert_y = _above_y + _above_height;
    _result.anchor_x = _best_root_id.node_x;

    return _result;
}
