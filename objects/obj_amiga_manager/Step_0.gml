if (keyboard_check_pressed(vk_f5) && build_state == "idle") {
    var _node_array = scr_amiga_collect_program_nodes();

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
        show_debug_message("obj_amiga_manager: main.bin appeared after " + string(build_wait_timer) + " frames");
        build_adf_path = scr_amiga_start_adf_build(build_exe_path, build_project_path, build_volume_name);
        build_state = "waiting_for_adf";
        build_wait_timer = 0;
    } else {
        if (build_wait_timer > build_timeout_frames) {
            show_debug_message("Build timed out waiting for vasm to produce main.bin.");
            build_state = "idle";
        }
    }
}

if (build_state == "waiting_for_adf") {
    build_wait_timer += 1;

    if (file_exists(build_adf_path)) {
        show_debug_message("obj_amiga_manager: disk.adf appeared after " + string(build_wait_timer) + " frames — launching FS-UAE");
        var _uae_args = "--floppy_drive_0=\"" + build_adf_path + "\" --kickstart_file=\"" + global.kickstart_path + "\"";
        execute_shell_simple(global.fsuae_path, _uae_args);
        build_state = "idle";
    } else {
        if (build_wait_timer > build_timeout_frames) {
            show_debug_message("Build timed out waiting for xdftool to produce disk.adf.");
            build_state = "idle";
        }
    }
}

var _test_button_x = 8;
var _test_button_y = 2;
var _test_button_width = 60;
var _test_button_height = 16;

var _over_test_button = point_in_rectangle(mouse_x, mouse_y, _test_button_x, _test_button_y, _test_button_x + _test_button_width, _test_button_y + _test_button_height);

if (_over_test_button && mouse_check_button_pressed(mb_left)) {
    scr_load_test_setup();
}

if (keyboard_check_pressed(ord("H")) && global.operand_edit_owner_uid == -1) {
    if (global.value_display_mode == "HEX") {
        global.value_display_mode = "DEC";
    } else {
        global.value_display_mode = "HEX";
    }
}

var _ctrl_held = keyboard_check(vk_control);

if (_ctrl_held && keyboard_check_pressed(ord("S")) && global.operand_edit_owner_uid == -1) {
    scr_save_layout();
}

if (_ctrl_held && keyboard_check_pressed(ord("L")) && global.operand_edit_owner_uid == -1) {
    scr_load_layout();
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

