/// @desc scr_relink_around_node(_node_id)
/// Detaches _node_id from the chain: whatever was below it gets reparented
/// to whatever was above it, then that whole downstream chain gets its
/// positions freshly recomputed from the new anchor — never shifted by a
/// fixed amount, so it can't drift or collapse regardless of prior state.
/// Handles more than one node claiming _node_id as parent, independently.
/// Does NOT destroy _node_id — used both by delete and by drag pickup.
function scr_relink_around_node(_node_id) {
    var _parent_uid = _node_id.parent_uid;
    var _own_uid = _node_id.uid;

    var _child_uids = [];

    with (obj_opcode_node) {
        if (parent_uid == _own_uid) {
            array_push(_child_uids, uid);
        }
    }

    var _child_count = array_length(_child_uids);
    var _c = 0;

    while (_c < _child_count) {
        var _this_child_uid = _child_uids[_c];

        with (obj_opcode_node) {
            if (uid == _this_child_uid) {
                parent_uid = _parent_uid;
                is_connected = (_parent_uid != -1);
            }
        }

        if (_parent_uid != -1) {
            var _anchor_id = noone;

            with (obj_opcode_node) {
                if (uid == _parent_uid) {
                    _anchor_id = id;
                }
            }

            if (_anchor_id == noone) {
                with (obj_amiga_root_node) {
                    if (uid == _parent_uid) {
                        _anchor_id = id;
                    }
                }
            }

            if (_anchor_id != noone) {
                scr_relayout_chain_from_node(_anchor_id);
            }
        }

        _c += 1;
    }
}
