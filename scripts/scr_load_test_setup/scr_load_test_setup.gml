/// @desc scr_load_test_setup()
function scr_load_test_setup() {
    with (obj_opcode_node) {
        instance_destroy();
    }

    with (obj_amiga_root_node) {
        instance_destroy();
    }

    var _init_x = (room_width / 2) - 80;
    var _init_y = room_height / 4;

    var _init_instance = instance_create_layer(_init_x, _init_y, "Instances", obj_amiga_root_node);
    _init_instance.root_type = "INIT";
    _init_instance.node_x = scr_snap_to_grid(_init_x, global.grid_size);
    _init_instance.node_y = scr_snap_to_grid(_init_y, global.grid_size);

    var _cursor_x = _init_instance.node_x;
    var _cursor_y = _init_instance.node_y + _init_instance.node_height;
    var _previous_uid = _init_instance.uid;

    var _steps = [
        { mnemonic : "MOVE", size : "W", src_mode : "#imm", src_val : 32767, dst_mode : "abs.L", dst_val : 14676118, label : "" },
        { mnemonic : "MOVE", size : "W", src_mode : "#imm", src_val : 32767, dst_mode : "abs.L", dst_val : 14676122, label : "" },
        { mnemonic : "MOVE", size : "W", src_mode : "#imm", src_val : 3840,  dst_mode : "abs.L", dst_val : 14676352, label : "mainloop" },
        { mnemonic : "NOP",  size : "",  src_mode : "",     src_val : 0,     dst_mode : "",       dst_val : 0,       label : "" },
        { mnemonic : "BRA",  size : "W", src_mode : "LABEL", src_val : 0,   dst_mode : "",       dst_val : 0,       label : "" }
    ];

    var _step_index = 0;
    var _step_count = array_length(_steps);

    while (_step_index < _step_count) {
        var _step_data = _steps[_step_index];

        var _new_node = instance_create_layer(_cursor_x, _cursor_y, "Instances", obj_opcode_node);
        _new_node.node_x = _cursor_x;
        _new_node.node_y = _cursor_y;
        _new_node.opcode_mnemonic = _step_data.mnemonic;
        _new_node.opcode_size = _step_data.size;
        _new_node.addressing_mode_src = _step_data.src_mode;
        _new_node.operand_src = _step_data.src_val;
        _new_node.addressing_mode_dst = _step_data.dst_mode;
        _new_node.operand_dst = _step_data.dst_val;
        _new_node.node_label = _step_data.label;
        _new_node.is_connected = true;
        _new_node.parent_uid = _previous_uid;

        if (_step_data.mnemonic == "BRA") {
            _new_node.operand_label_src = "mainloop";
        }

        _cursor_y += _new_node.node_height;
        _previous_uid = _new_node.uid;

        _step_index += 1;
    }
}