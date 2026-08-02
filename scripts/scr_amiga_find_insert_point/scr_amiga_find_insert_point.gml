/// @desc scr_amiga_find_insert_point(_dragged_id, _test_x, _test_y)
/// Finds the nearest root (INIT/ORG) column to _test_x, then whichever GAP
/// between two consecutive members (or root+first member) has its MIDPOINT
/// closest to _test_y — not a hard cutoff at each node's own top edge.
/// A midpoint-proximity search is forgiving of the live wedge preview
/// visually opening a gap wider than it really is: aiming anywhere near
/// the middle of that visual space still lands on the same true gap,
/// instead of overshooting into the next one down. Returns
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

    var _members = [];

    with (obj_opcode_node) {
        var _is_self = (id == _dragged_id);
        var _in_this_root = (root_uid == _root_uid) && is_connected;

        if (!_is_self && _in_this_root) {
            array_push(_members, id);
        }
    }

    array_sort(_members, function(_a, _b) {
        return _a.node_y - _b.node_y;
    });

    var _member_count = array_length(_members);

    // anchor_bottoms[i] = the Y you'd insert at to become the (i+1)th
    // member overall. anchor_bottoms[0] is right after the root itself.
    var _anchor_bottoms = [_best_root_id.node_y + _best_root_id.node_height];
    var _m = 0;

    while (_m < _member_count) {
        array_push(_anchor_bottoms, _members[_m].node_y + _members[_m].node_height);
        _m += 1;
    }

    var _anchor_count = array_length(_anchor_bottoms);
    var _best_gap_index = 0;
    var _best_gap_distance = 999999999;
    var _a = 0;

    while (_a < _anchor_count) {
        var _gap_top = _anchor_bottoms[_a];
        var _gap_target_y = _gap_top;

        // The member currently sitting where slot _a would be, if any —
        // that's this gap's lower bound, used only to find the midpoint.
        if (_a < _member_count) {
            var _gap_bottom = _members[_a].node_y;
            _gap_target_y = (_gap_top + _gap_bottom) / 2;
        }

        var _gap_distance = abs(_test_y - _gap_target_y);

        if (_gap_distance < _best_gap_distance) {
            _best_gap_distance = _gap_distance;
            _best_gap_index = _a;
        }

        _a += 1;
    }

    _result.found = true;
    _result.root_uid = _root_uid;
    _result.insert_y = _anchor_bottoms[_best_gap_index];
    _result.anchor_x = _best_root_id.node_x;

    return _result;
}
