/// @desc scr_find_nearest_wedge_point(_self_id, _test_x, _test_y)
/// Looks for an existing connected node whose position is within 20px of
/// (_test_x, _test_y) — that node's position IS the wedge point (inserting
/// there pushes it, and everything below it, down by one node height).
/// Returns { found, parent_uid, child_uid, wedge_x, wedge_y }.
function scr_find_nearest_wedge_point(_self_id, _test_x, _test_y) {
    var _threshold = 20;
    var _result = {
        found : false,
        parent_uid : -1,
        child_uid : -1,
        wedge_x : 0,
        wedge_y : 0
    };

    var _best_distance = _threshold * 2 + 1;

    with (obj_opcode_node) {
        var _is_self = (id == _self_id);
        var _has_real_parent = (parent_uid != -1);

        if (!_is_self && _has_real_parent) {
            var _dx = abs(node_x - _test_x);
            var _dy = abs(node_y - _test_y);
            var _within_threshold = (_dx <= _threshold) && (_dy <= _threshold);

            if (_within_threshold) {
                var _distance = _dx + _dy;

                if (_distance < _best_distance) {
                    _best_distance = _distance;
                    _result.found = true;
                    _result.parent_uid = parent_uid;
                    _result.child_uid = uid;
                    _result.wedge_x = node_x;
                    _result.wedge_y = node_y;
                }
            }
        }
    }

    return _result;
}
