/// @desc scr_amiga_collect_program_nodes()
/// For INIT, then each continuing ORG in turn: gather every connected node
/// that belongs to that root (flat membership via root_uid, matching
/// C64DM's org_parent model) and sort by Y-position — position IS the
/// order, nothing is stored as a link between adjacent nodes.
function scr_amiga_collect_program_nodes() {
    var _ordered_nodes = [];
    var _init_uid = -1;

    with (obj_amiga_root_node) {
        if (root_type == "INIT") {
            _init_uid = uid;
        }
    }

    if (_init_uid == -1) {
        show_debug_message("scr_amiga_collect_program_nodes: no INIT node found");
        return _ordered_nodes;
    }

    var _current_root_uid = _init_uid;
    var _guard_count = 0;
    var _guard_limit = 1000;

    while (_current_root_uid != -1 && _guard_count < _guard_limit) {
        var _members = [];

        with (obj_opcode_node) {
            if (root_uid == _current_root_uid && is_connected) {
                array_push(_members, id);
            }
        }

        array_sort(_members, function(_a, _b) {
            return _a.node_y - _b.node_y;
        });

        var _m = 0;
        var _member_count = array_length(_members);

        while (_m < _member_count) {
            array_push(_ordered_nodes, _members[_m]);
            _m += 1;
        }

        var _next_root_uid = -1;

        with (obj_amiga_root_node) {
            if (root_type == "ORG" && continues_from_root_uid == _current_root_uid) {
                _next_root_uid = uid;
            }
        }

        _current_root_uid = _next_root_uid;
        _guard_count += 1;
    }

    return _ordered_nodes;
}
