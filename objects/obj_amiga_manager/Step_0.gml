if (keyboard_check_pressed(vk_f5) && build_state == "idle") {
    var _all_nodes = instance_number(obj_opcode_node);
    var _node_array = array_create(_all_nodes);
    var _n = 0;

    with (obj_opcode_node) {
        _node_array[_n] = self;
        _n += 1;
    }

    var _start_result = scr_amiga_start_build(_node_array, global.current_project_path, global.current_chipset_mode);

    if (_start_result.success) {
        build_project_path = global.current_project_path;
        build_volume_name = global.current_volume_name;
        build_exe_path = _start_result.exe_path;
        build_state = "waiting_for_asm";
        build_wait_timer = 0;
    } else {
        show_debug_message("Build blocked by opcode errors — see previous debug lines.");
    }
}

if (build_state == "waiting_for_asm") {
    build_wait_timer += 1;

    if (file_exists(build_exe_path)) {
        show_debug_message("obj_amiga_manager: main.exe appeared after " + string(build_wait_timer) + " frames");
        build_adf_path = scr_amiga_start_adf_build(build_exe_path, build_project_path, build_volume_name);
        build_state = "waiting_for_adf";
        build_wait_timer = 0;
    } else {
        if (build_wait_timer > build_timeout_frames) {
            show_debug_message("Build timed out waiting for vasm to produce main.exe.");
            build_state = "idle";
        }
    }
}

if (build_state == "waiting_for_adf") {
    build_wait_timer += 1;

    if (file_exists(build_adf_path)) {
        show_debug_message("obj_amiga_manager: disk.adf appeared after " + string(build_wait_timer) + " frames — launching FS-UAE");
        var _uae_args = "--floppy_drive_0=\"" + build_adf_path + "\"";
        execute_shell_simple(global.fsuae_path, _uae_args);
        build_state = "idle";
    } else {
        if (build_wait_timer > build_timeout_frames) {
            show_debug_message("Build timed out waiting for xdftool to produce disk.adf.");
            build_state = "idle";
        }
    }
}

var _over_palette = point_in_rectangle(mouse_x, mouse_y, global.palette_panel_bounds.left, global.palette_panel_bounds.top, global.palette_panel_bounds.right, global.palette_panel_bounds.bottom);

if (_over_palette) {
    var _wheel_amount = 0;

    if (mouse_wheel_up()) {
        _wheel_amount = global.grid_size;
    }

    if (mouse_wheel_down()) {
        _wheel_amount = -global.grid_size;
    }

    global.palette_scroll_y += _wheel_amount;

    if (global.palette_scroll_y > 0) {
        global.palette_scroll_y = 0;
    }

    var _mnemonic_count = variable_struct_names_count(global.opcode_map);
    var _columns = palette_columns;
    var _rows_needed = ceil(_mnemonic_count / _columns);
    var _list_height = _rows_needed * global.grid_size;
    var _panel_height = global.palette_panel_bounds.bottom - global.palette_panel_bounds.top;
    var _min_scroll = 0;

    if (_list_height > _panel_height) {
        _min_scroll = -(_list_height - _panel_height);
    }

    if (global.palette_scroll_y < _min_scroll) {
        global.palette_scroll_y = _min_scroll;
    }
}

global.palette_hover_mnemonic = "";

build_state = "idle";
build_project_path = "";
build_volume_name = "";
build_exe_path = "";
build_adf_path = "";
build_wait_timer = 0;
build_timeout_frames = 600;