/// @desc scr_load_test_setup()
/// Builds a copper-driven sunrise-over-water gradient: CPU writes a small
/// copper list into chip RAM, then hands control to it via COP1LC + DMACON.
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

    var _steps = [];

    array_push(_steps, { mnemonic : "MOVE", size : "W", src_mode : "#imm", src_val : 32767, dst_mode : "abs.L", dst_val : 14676118, label : "" });
    array_push(_steps, { mnemonic : "MOVE", size : "W", src_mode : "#imm", src_val : 32767, dst_mode : "abs.L", dst_val : 14676122, label : "" });

    var _copper_base = 131072;
    var _copper_offset = 0;

    var _sky_band_count = 4;
    var _sky_vp_start = 44;
    var _sky_vp_end = 110;
    var _sky_r_start = 13; var _sky_g_start = 2;  var _sky_b_start = 0;
    var _sky_r_end   = 15; var _sky_g_end   = 12; var _sky_b_end   = 6;

    var _i = 0;

    while (_i < _sky_band_count) {
        var _t = _i / (_sky_band_count - 1);
        var _vp = floor(_sky_vp_start + (_sky_vp_end - _sky_vp_start) * _t);
        var _r = floor(_sky_r_start + (_sky_r_end - _sky_r_start) * _t);
        var _g = floor(_sky_g_start + (_sky_g_end - _sky_g_start) * _t);
        var _b = floor(_sky_b_start + (_sky_b_end - _sky_b_start) * _t);
        var _colour = (_r * 256) + (_g * 16) + _b;

        var _wait_longword = ((_vp * 256 + 1) * 65536) + 65280;
        var _move_longword = (384 * 65536) + _colour;

        array_push(_steps, { mnemonic : "MOVE", size : "L", src_mode : "#imm", src_val : _wait_longword, dst_mode : "abs.L", dst_val : _copper_base + _copper_offset, label : "" });
        _copper_offset += 4;

        array_push(_steps, { mnemonic : "MOVE", size : "L", src_mode : "#imm", src_val : _move_longword, dst_mode : "abs.L", dst_val : _copper_base + _copper_offset, label : "" });
        _copper_offset += 4;

        _i += 1;
    }

    var _water_band_count = 4;
    var _water_vp_start = 110;
    var _water_vp_end = 200;
    var _water_r_start = 15; var _water_g_start = 8; var _water_b_start = 4;
    var _water_r_end   = 0;  var _water_g_end   = 1; var _water_b_end   = 6;

    _i = 0;

    while (_i < _water_band_count) {
        var _t = _i / (_water_band_count - 1);
        var _vp = floor(_water_vp_start + (_water_vp_end - _water_vp_start) * _t);
        var _r = floor(_water_r_start + (_water_r_end - _water_r_start) * _t);
        var _g = floor(_water_g_start + (_water_g_end - _water_g_start) * _t);
        var _b = floor(_water_b_start + (_water_b_end - _water_b_start) * _t);
        var _colour = (_r * 256) + (_g * 16) + _b;

        var _wait_longword = ((_vp * 256 + 1) * 65536) + 65280;
        var _move_longword = (384 * 65536) + _colour;

        array_push(_steps, { mnemonic : "MOVE", size : "L", src_mode : "#imm", src_val : _wait_longword, dst_mode : "abs.L", dst_val : _copper_base + _copper_offset, label : "" });
        _copper_offset += 4;

        array_push(_steps, { mnemonic : "MOVE", size : "L", src_mode : "#imm", src_val : _move_longword, dst_mode : "abs.L", dst_val : _copper_base + _copper_offset, label : "" });
        _copper_offset += 4;

        _i += 1;
    }

    array_push(_steps, { mnemonic : "MOVE", size : "L", src_mode : "#imm", src_val : 4294967294, dst_mode : "abs.L", dst_val : _copper_base + _copper_offset, label : "" });
    array_push(_steps, { mnemonic : "MOVE", size : "L", src_mode : "#imm", src_val : _copper_base, dst_mode : "abs.L", dst_val : 14676096, label : "" });
    array_push(_steps, { mnemonic : "MOVE", size : "W", src_mode : "#imm", src_val : 33408, dst_mode : "abs.L", dst_val : 14676118, label : "" });
    array_push(_steps, { mnemonic : "NOP", size : "", src_mode : "", src_val : 0, dst_mode : "", dst_val : 0, label : "mainloop" });
    array_push(_steps, { mnemonic : "BRA", size : "W", src_mode : "LABEL", src_val : 0, dst_mode : "", dst_val : 0, label : "" });

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