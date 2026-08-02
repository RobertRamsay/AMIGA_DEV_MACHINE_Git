/// @desc scr_find_nearest_left_root(_self_id)
/// Finds the nearest INIT/ORG root strictly to the left of _self_id. Returns its uid, or -1 if none.
function scr_find_nearest_left_root(_self_id) {
    var _best_uid = -1;
    var _best_x = -100000;

    with (obj_amiga_root_node) {
        var _is_self = (id == _self_id);

        if (!_is_self) {
            var _is_left = (node_x < _self_id.node_x);

            if (_is_left && node_x > _best_x) {
                _best_x = node_x;
                _best_uid = uid;
            }
        }
    }

    return _best_uid;
}
