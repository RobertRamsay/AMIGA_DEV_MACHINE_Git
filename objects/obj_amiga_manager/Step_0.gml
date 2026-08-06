global.right_click_delete_handled_this_frame = false;
global.left_click_pickup_handled_this_frame = false;

var _pan_trigger_held = keyboard_check(vk_space) || mouse_check_button(mb_middle);

if (_pan_trigger_held && !global.pan_active) {
    global.pan_active = true;
    global.pan_last_mouse_x = mouse_x;
    global.pan_last_mouse_y = mouse_y;
}

if (_pan_trigger_held && global.pan_active) {
    var _pan_delta_x = mouse_x - global.pan_last_mouse_x;
    var _pan_delta_y = mouse_y - global.pan_last_mouse_y;

    global.pan_x += _pan_delta_x;
    global.pan_y += _pan_delta_y;

    global.pan_last_mouse_x = mouse_x;
    global.pan_last_mouse_y = mouse_y;
}

if (!_pan_trigger_held) {
    global.pan_active = false;
}

var _ctrl_held_for_undo = keyboard_check(vk_control);

if (_ctrl_held_for_undo && keyboard_check_pressed(ord("Z")) && global.operand_edit_owner_uid == -1) {
    scr_undo();
}

if (_ctrl_held_for_undo && keyboard_check_pressed(ord("Y")) && global.operand_edit_owner_uid == -1) {
    scr_redo();
}

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
        build_adf_ready_timer = 0;
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
        // xdftool is asynchronous: `create` makes disk.adf visible before
        // the following format and boot-write commands have finished. Wait
        // for it to remain present before allowing FS-UAE to open the file.
        build_adf_ready_timer += 1;

        if (build_adf_ready_timer >= 30) {
            show_debug_message("obj_amiga_manager: disk.adf ready after " + string(build_wait_timer) + " frames — launching FS-UAE");
            var _uae_args = "--floppy_drive_0=\"" + build_adf_path + "\" --kickstart_file=\"" + global.kickstart_path + "\"";
            execute_shell_simple(global.fsuae_path, _uae_args);
            build_state = "idle";
        }
    } else {
        build_adf_ready_timer = 0;

        if (build_wait_timer > build_timeout_frames) {
            show_debug_message("Build timed out waiting for xdftool to produce disk.adf.");
            build_state = "idle";
        }
    }
}

var _test_button_x = 310;
var _test_button_y = 20;
var _test_button_width = 60;
var _test_button_height = 16;

var _over_test_button = point_in_rectangle(mouse_x, mouse_y, _test_button_x, _test_button_y, _test_button_x + _test_button_width, _test_button_y + _test_button_height);

if (_over_test_button && mouse_check_button_pressed(mb_left)) {
    scr_load_test_setup();
}

var _sprite_editor_button_x = 310;
var _sprite_editor_button_y = 64;
var _sprite_editor_button_width = 60;
var _sprite_editor_button_height = 16;

var _over_sprite_editor_button = point_in_rectangle(mouse_x, mouse_y, _sprite_editor_button_x, _sprite_editor_button_y, _sprite_editor_button_x + _sprite_editor_button_width, _sprite_editor_button_y + _sprite_editor_button_height);

if (_over_sprite_editor_button && mouse_check_button_pressed(mb_left)) {
    global.sprite_editor_open = !global.sprite_editor_open;
}

var _sprite_test_button_x = 310;
var _sprite_test_button_y = 84;
var _sprite_test_button_width = 60;
var _sprite_test_button_height = 16;

var _over_sprite_test_button = point_in_rectangle(mouse_x, mouse_y, _sprite_test_button_x, _sprite_test_button_y, _sprite_test_button_x + _sprite_test_button_width, _sprite_test_button_y + _sprite_test_button_height);

if (_over_sprite_test_button && mouse_check_button_pressed(mb_left)) {
    scr_amiga_run_sprite_test();
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

preview_line_cache = scr_amiga_build_preview_lines();

var _preview_panel_x = room_width - 360;
var _preview_panel_y = 60;
var _preview_panel_width = 350;
var _preview_panel_height = room_height - 80;
var _preview_line_height = 16;

var _over_preview_panel = point_in_rectangle(mouse_x, mouse_y, _preview_panel_x, _preview_panel_y, _preview_panel_x + _preview_panel_width, _preview_panel_y + _preview_panel_height);

if (_over_preview_panel) {
    var _preview_wheel_amount = 0;

    if (mouse_wheel_up()) {
        _preview_wheel_amount = global.grid_size;
    }

    if (mouse_wheel_down()) {
        _preview_wheel_amount = -global.grid_size;
    }

    global.preview_scroll_y += _preview_wheel_amount;

    if (global.preview_scroll_y > 0) {
        global.preview_scroll_y = 0;
    }

    var _preview_list_height = array_length(preview_line_cache) * _preview_line_height;
    var _preview_min_scroll = 0;

    if (_preview_list_height > _preview_panel_height) {
        _preview_min_scroll = -(_preview_list_height - _preview_panel_height);
    }

    if (global.preview_scroll_y < _preview_min_scroll) {
        global.preview_scroll_y = _preview_min_scroll;
    }
}

if (mouse_check_button_pressed(mb_left)) {
    var _click_line_y = _preview_panel_y + 24 + global.preview_scroll_y;
    var _click_line_index = 0;
    var _click_line_count = array_length(preview_line_cache);

    while (_click_line_index < _click_line_count) {
        var _line_data = preview_line_cache[_click_line_index];

        if (_line_data.is_macro_header) {
            var _over_this_line = point_in_rectangle(mouse_x, mouse_y, _preview_panel_x, _click_line_y, _preview_panel_x + _preview_panel_width, _click_line_y + _preview_line_height);

            if (_over_this_line) {
                _line_data.node_id.preview_collapsed = !_line_data.node_id.preview_collapsed;
            }
        }

        _click_line_y += _preview_line_height;
        _click_line_index += 1;
    }
}

global.palette_hover_mnemonic = "";

if (global.sprite_editor_open) {
    var _layout = scr_sprite_editor_layout();

    var _over_close = point_in_rectangle(mouse_x, mouse_y, _layout.close_x, _layout.close_y, _layout.close_x + 16, _layout.close_y + 16);

    if (_over_close && mouse_check_button_pressed(mb_left)) {
        global.sprite_editor_open = false;
    }

    var _over_channel_minus = point_in_rectangle(mouse_x, mouse_y, _layout.channel_minus_x, _layout.channel_row_y, _layout.channel_minus_x + 16, _layout.channel_row_y + 16);
    var _over_channel_plus = point_in_rectangle(mouse_x, mouse_y, _layout.channel_plus_x, _layout.channel_row_y, _layout.channel_plus_x + 16, _layout.channel_row_y + 16);

    if (_over_channel_minus && mouse_check_button_pressed(mb_left)) {
        global.sprite_channel -= 1;

        if (global.sprite_channel < 0) {
            global.sprite_channel = 7;
        }
    }

    if (_over_channel_plus && mouse_check_button_pressed(mb_left)) {
        global.sprite_channel += 1;

        if (global.sprite_channel > 7) {
            global.sprite_channel = 0;
        }
    }

    var _over_height_field = point_in_rectangle(mouse_x, mouse_y, _layout.height_field_x, _layout.height_row_y, _layout.height_field_x + 60, _layout.height_row_y + 16);
    var _over_addr_field = point_in_rectangle(mouse_x, mouse_y, _layout.addr_field_x, _layout.addr_row_y, _layout.addr_field_x + 80, _layout.addr_row_y + 16);

    if (_over_height_field && mouse_check_button_pressed(mb_left) && global.sprite_editing_field == "") {
        global.sprite_editing_field = "height";
        global.sprite_edit_text = string(global.sprite_height);
        keyboard_string = "";
    }

    if (_over_addr_field && mouse_check_button_pressed(mb_left) && global.sprite_editing_field == "") {
        global.sprite_editing_field = "address";
        global.sprite_edit_text = scr_number_to_hex_string(global.sprite_address);
        keyboard_string = "";
    }

    var _swatch_index = 0;

    while (_swatch_index < 4) {
        var _swatch_x = _layout.swatch_x + (_swatch_index * (_layout.swatch_width + 6));
        var _over_swatch = point_in_rectangle(mouse_x, mouse_y, _swatch_x, _layout.swatch_row_y, _swatch_x + _layout.swatch_width, _layout.swatch_row_y + _layout.swatch_height);

        if (_over_swatch && mouse_check_button_pressed(mb_left)) {
            global.sprite_paint_index = _swatch_index;
        }

        if (_over_swatch && mouse_check_button_pressed(mb_right) && _swatch_index >= 1 && global.sprite_editing_field == "") {
            global.sprite_editing_field = "colour" + string(_swatch_index);

            var _hex_r = scr_number_to_hex_string(global.sprite_colour_r[_swatch_index - 1]);
            var _hex_g = scr_number_to_hex_string(global.sprite_colour_g[_swatch_index - 1]);
            var _hex_b = scr_number_to_hex_string(global.sprite_colour_b[_swatch_index - 1]);

            global.sprite_edit_text = _hex_r + _hex_g + _hex_b;
            keyboard_string = "";
        }

        _swatch_index += 1;
    }

    if (mouse_check_button(mb_left) && global.sprite_editing_field == "") {
        var _over_grid = point_in_rectangle(mouse_x, mouse_y, _layout.grid_x, _layout.grid_y, _layout.grid_x + _layout.grid_width, _layout.grid_y + _layout.grid_height);

        if (_over_grid) {
            var _cell_col = floor((mouse_x - _layout.grid_x) / _layout.cell_size);
            var _cell_row = floor((mouse_y - _layout.grid_y) / _layout.cell_size);

            if (_cell_col >= 0 && _cell_col < 16 && _cell_row >= 0 && _cell_row < global.sprite_height) {
                global.sprite_pixels[(_cell_row * 16) + _cell_col] = global.sprite_paint_index;
            }
        }
    }

    if (global.sprite_editing_field != "") {
        var _typed = keyboard_string;
        keyboard_string = "";

        var _char_index = 1;
        var _typed_length = string_length(_typed);

        while (_char_index <= _typed_length) {
            var _this_char = string_char_at(_typed, _char_index);
            var _is_hex_digit = ((_this_char >= "0") && (_this_char <= "9")) || ((_this_char >= "A") && (_this_char <= "F")) || ((_this_char >= "a") && (_this_char <= "f"));
            var _is_digit = (_this_char >= "0") && (_this_char <= "9");
            var _accept = _is_hex_digit;

            if (global.sprite_editing_field == "height") {
                _accept = _is_digit;
            }

            if (_accept) {
                global.sprite_edit_text += _this_char;
            }

            _char_index += 1;
        }

        if (keyboard_check_pressed(vk_backspace) && string_length(global.sprite_edit_text) > 0) {
            global.sprite_edit_text = string_copy(global.sprite_edit_text, 1, string_length(global.sprite_edit_text) - 1);
        }

        if (keyboard_check_pressed(vk_enter)) {
            if (global.sprite_editing_field == "height") {
                var _new_height = real(global.sprite_edit_text);

                if (_new_height < 1) {
                    _new_height = 1;
                }

                if (_new_height > 64) {
                    _new_height = 64;
                }

                global.sprite_height = _new_height;
            } else if (global.sprite_editing_field == "address") {
                global.sprite_address = scr_hex_string_to_number(global.sprite_edit_text);
            } else if (string_pos("colour", global.sprite_editing_field) == 1) {
                var _swatch_num = real(string_copy(global.sprite_editing_field, 7, 1));
                var _hex_text = global.sprite_edit_text;

                if (string_length(_hex_text) == 3) {
                    global.sprite_colour_r[_swatch_num - 1] = scr_hex_string_to_number(string_char_at(_hex_text, 1));
                    global.sprite_colour_g[_swatch_num - 1] = scr_hex_string_to_number(string_char_at(_hex_text, 2));
                    global.sprite_colour_b[_swatch_num - 1] = scr_hex_string_to_number(string_char_at(_hex_text, 3));
                }
            }

            global.sprite_editing_field = "";
        }

        if (keyboard_check_pressed(vk_escape)) {
            global.sprite_editing_field = "";
        }
    }
}
