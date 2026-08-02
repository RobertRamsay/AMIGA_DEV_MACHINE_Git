/// @desc scr_check_node_overlap(_self_id, _test_x, _test_y)
/// Returns true if a node of _self_id's size, placed at (_test_x, _test_y),
/// would overlap any other obj_opcode_node or obj_amiga_root_node.
/// Exact edge-touching (normal stacking) is NOT counted as overlap.
function scr_check_node_overlap(_self_id, _test_x, _test_y) {
    var _has_overlap = false;

    with (obj_opcode_node) {
        var _is_self = (id == _self_id);

        if (!_is_self) {
            var _overlap_x = (_test_x < node_x + node_width) && (_test_x + _self_id.node_width > node_x);
            var _overlap_y = (_test_y < node_y + node_height) && (_test_y + _self_id.node_height > node_y);

            if (_overlap_x && _overlap_y) {
                _has_overlap = true;
            }
        }
    }

    if (!_has_overlap) {
        with (obj_amiga_root_node) {
            var _overlap_x = (_test_x < node_x + node_width) && (_test_x + _self_id.node_width > node_x);
            var _overlap_y = (_test_y < node_y + node_height) && (_test_y + _self_id.node_height > node_y);

            if (_overlap_x && _overlap_y) {
                _has_overlap = true;
            }
        }
    }

    return _has_overlap;
}
