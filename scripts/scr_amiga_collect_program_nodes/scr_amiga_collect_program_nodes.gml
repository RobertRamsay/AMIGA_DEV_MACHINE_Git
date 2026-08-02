/// @desc scr_amiga_collect_program_nodes()
/// Walks INIT's chain, then each continuing ORG's chain in order.
/// Returns an ordered array of obj_opcode_node instances that are actually part of the program.
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
        var _current_link_uid = _current_root_uid;
        var _found_next = true;

        while (_found_next) {
            _found_next = false;

            with (obj_opcode_node) {
                if (parent_uid == _current_link_uid && is_connected) {
                    array_push(_ordered_nodes, id);
                    _current_link_uid = uid;
                    _found_next = true;
                }
            }

            _guard_count += 1;

            if (_guard_count >= _guard_limit) {
                _found_next = false;
            }
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