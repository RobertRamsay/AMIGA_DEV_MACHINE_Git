// The bitmap editor is modal: do not pan, build, undo, click controls or
// mutate the graph behind it.
if (instance_exists(obj_bitmap_editor)) {
    exit;
}

// Kickstart ROM clear shortcut disabled alongside the picker above —
// nothing to clear while it's off. Revisit together.
// if (keyboard_check_pressed(ord("I"))) {
//     global.kickstart_path = "";
//
//     ini_open("settings.ini");
//     ini_write_string("paths", "kickstart", "");
//     ini_close();
//
//     scr_set_status_message("Kickstart ROM cleared — you'll be prompted again on the next DOS-loader build.");
// }

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

    // Only the DOS-loader path (a BITMAP_DISPLAY macro anywhere in the
    // program) needs a real Kickstart to auto-run Startup-Sequence. Plain
    // direct-bootblock tests boot fine on FS-UAE's built-in AROS
    // replacement, so there's no reason to interrupt those with a prompt.
    var _requires_kickstart = false;
    var _node_scan_index = 0;
    var _node_count = array_length(_node_array);

    while (_node_scan_index < _node_count) {
        if (_node_array[_node_scan_index].is_macro && _node_array[_node_scan_index].macro_type == "BITMAP_DISPLAY") {
            _requires_kickstart = true;
        }
        _node_scan_index += 1;
    }

    // Kickstart ROM picker disabled for now — internal testing only,
    // boots straight to FS-UAE's bundled AROS fallback as before. Revisit
    // once a licensed ROM workflow is actually needed.
    // if (_requires_kickstart) {
    //     scr_amiga_ensure_kickstart_path();
    // }

    if (_requires_kickstart) {
        scr_set_status_message("Booting with unknown Kickstart — at CLI 1> please enter " + chr(34) + "DF0:main" + chr(34));
    }

    var _start_result = scr_amiga_start_build(_node_array, global.current_project_path, global.current_chipset_mode);

    if (_start_result.success) {
        build_project_path = global.current_project_path;
        build_volume_name = global.current_volume_name;
        build_exe_path = _start_result.exe_path;
        build_uses_dos_loader = _start_result.uses_dos_loader;
        build_state = "waiting_for_asm";
        build_wait_timer = 0;
        build_exe_last_size = -1;
        build_exe_stable_timer = 0;
    } else {
        show_debug_message("Build blocked by opcode errors — see previous debug lines.");
    }
}

if (build_state == "waiting_for_asm") {
    build_wait_timer += 1;

    if (file_exists(build_exe_path)) {
        // vasm creates main.bin before it has finished writing it. In
        // particular, the bitmap Hunk executable is about 50 KiB, so passing
        // the file to xdftool on the first visible frame can copy a truncated
        // executable and abort xdftool before it installs the boot block.
        var _exe_size = -1;
        var _exe_file = file_bin_open(build_exe_path, 0);

        // The writer may briefly have the file locked. Treat that exactly like
        // a changing size and simply try again on the next Step frame.
        if (_exe_file >= 0) {
            _exe_size = file_bin_size(_exe_file);
            file_bin_close(_exe_file);
        }

        if (_exe_size > 0 && _exe_size == build_exe_last_size) {
            build_exe_stable_timer += 1;
        } else {
            build_exe_last_size = _exe_size;
            build_exe_stable_timer = 0;
        }

        if (build_exe_stable_timer >= 30) {
            show_debug_message("obj_amiga_manager: main.bin stable at " + string(_exe_size) + " bytes after " + string(build_wait_timer) + " frames");
            build_adf_path = scr_amiga_start_adf_build(build_exe_path, build_project_path, build_volume_name, build_uses_dos_loader);
            build_state = "waiting_for_adf";
            build_wait_timer = 0;
            build_adf_ready_timer = 0;
        }
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
        // scr_amiga_start_adf_build publishes disk.adf only after xdftool has
        // completed every write and installed the boot block. Retain a short
        // filesystem settling delay, but no long guessed build delay is needed.
        build_adf_ready_timer += 1;
        var _adf_settle_frames = 30;

        if (build_adf_ready_timer >= _adf_settle_frames) {
            show_debug_message("obj_amiga_manager: disk.adf ready after " + string(build_wait_timer) + " frames — closing previous FS-UAE sessions");

            // Close any emulator left behind by an earlier F5 run. taskkill
            // returns immediately, so use a short state-machine delay before
            // launching the replacement process.
            execute_shell_simple("taskkill.exe", "/F /T /IM fs-uae.exe", "open", 0);
            build_state = "waiting_to_launch_fsuae";
            build_wait_timer = 0;
        }
    } else {
        build_adf_ready_timer = 0;

        // The bundled one-file xdftool may need extra time for extraction on
        // its first run. It now publishes disk.adf only on completion.
        var _adf_timeout_frames = build_uses_dos_loader ? 1800 : build_timeout_frames;
        if (build_wait_timer > _adf_timeout_frames) {
            show_debug_message("Build timed out waiting for xdftool to produce disk.adf.");
            build_state = "idle";
        }
    }
}

if (build_state == "waiting_to_launch_fsuae") {
    build_wait_timer += 1;

    if (build_wait_timer >= 15) {
        show_debug_message("obj_amiga_manager: previous FS-UAE sessions closed — launching new session");
        var _uae_args = "--floppy_drive_0=\"" + build_adf_path + "\" --kickstart_file=\"" + global.kickstart_path + "\"";
        execute_shell_simple(global.fsuae_path, _uae_args);
        build_state = "idle";
    }
}

var _test_button_x = 310;
var _test_button_y = 20;
var _test_button_width = 100;
var _test_button_height = 16;

var _over_test_button = point_in_rectangle(mouse_x, mouse_y, _test_button_x, _test_button_y, _test_button_x + _test_button_width, _test_button_y + _test_button_height);

if (_over_test_button && mouse_check_button_pressed(mb_left)) {
    scr_load_test_setup();
}

var _sprite_editor_button_x = 310;
var _sprite_editor_button_y = 64;
var _sprite_editor_button_width = 100;
var _sprite_editor_button_height = 16;

var _over_sprite_editor_button = point_in_rectangle(mouse_x, mouse_y, _sprite_editor_button_x, _sprite_editor_button_y, _sprite_editor_button_x + _sprite_editor_button_width, _sprite_editor_button_y + _sprite_editor_button_height);

if (_over_sprite_editor_button && mouse_check_button_pressed(mb_left)) {
    global.sprite_editor_open = !global.sprite_editor_open;
}

var _sprite_test_button_x = 310;
var _sprite_test_button_y = 84;
var _sprite_test_button_width = 100;
var _sprite_test_button_height = 16;

var _over_sprite_test_button = point_in_rectangle(mouse_x, mouse_y, _sprite_test_button_x, _sprite_test_button_y, _sprite_test_button_x + _sprite_test_button_width, _sprite_test_button_y + _sprite_test_button_height);

if (_over_sprite_test_button && mouse_check_button_pressed(mb_left)) {
    scr_amiga_run_sprite_test();
}

var _bitmap_editor_button_x = 310;
var _bitmap_editor_button_y = 104;
var _bitmap_editor_button_width = 100;
var _bitmap_editor_button_height = 16;

var _over_bitmap_editor_button = point_in_rectangle(mouse_x, mouse_y, _bitmap_editor_button_x, _bitmap_editor_button_y, _bitmap_editor_button_x + _bitmap_editor_button_width, _bitmap_editor_button_y + _bitmap_editor_button_height);

if (_over_bitmap_editor_button && mouse_check_button_pressed(mb_left)) {
    if (instance_exists(obj_bitmap_editor)) {
        with (obj_bitmap_editor) instance_destroy();
    } else {
        instance_create_layer(0, 0, "Instances", obj_bitmap_editor);
    }
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
    var _over_editor_header = point_in_rectangle(mouse_x, mouse_y, _layout.header_x, _layout.header_y, _layout.header_x + _layout.header_width, _layout.header_y + _layout.header_height);

    if (_over_editor_header && !_over_close && mouse_check_button_pressed(mb_left)) {
        global.sprite_editor_dragging = true;
        global.sprite_editor_drag_offset_x = mouse_x - global.sprite_editor_x;
        global.sprite_editor_drag_offset_y = mouse_y - global.sprite_editor_y;
    }

    if (global.sprite_editor_dragging) {
        if (mouse_check_button(mb_left)) {
            global.sprite_editor_x = clamp(mouse_x - global.sprite_editor_drag_offset_x, 0, room_width - _layout.panel_width);
            global.sprite_editor_y = clamp(mouse_y - global.sprite_editor_drag_offset_y, 0, room_height - _layout.header_height);
            _layout = scr_sprite_editor_layout();
        } else {
            global.sprite_editor_dragging = false;
        }
    }

    if (_over_close && mouse_check_button_pressed(mb_left)) {
        global.sprite_editor_open = false;
        global.sprite_editor_dragging = false;
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

            if (_swatch_index >= 1) {
                global.sprite_palette_edit_index = _swatch_index;
            }
        }

        _swatch_index += 1;
    }

    // Live 12-bit Amiga palette editor. Each slider has exactly 16 discrete
    // positions (0-F); dragging updates every sprite pixel using that swatch.
    if (mouse_check_button(mb_left) && global.sprite_palette_edit_index >= 1) {
        var _palette_array_index = global.sprite_palette_edit_index - 1;
        var _slider_value = floor((mouse_x - _layout.slider_x) / _layout.slider_step_width);
        _slider_value = clamp(_slider_value, 0, 15);

        var _over_r_slider = point_in_rectangle(mouse_x, mouse_y, _layout.slider_x, _layout.slider_r_y, _layout.slider_x + _layout.slider_width, _layout.slider_r_y + _layout.slider_height);
        var _over_g_slider = point_in_rectangle(mouse_x, mouse_y, _layout.slider_x, _layout.slider_g_y, _layout.slider_x + _layout.slider_width, _layout.slider_g_y + _layout.slider_height);
        var _over_b_slider = point_in_rectangle(mouse_x, mouse_y, _layout.slider_x, _layout.slider_b_y, _layout.slider_x + _layout.slider_width, _layout.slider_b_y + _layout.slider_height);

        if (_over_r_slider) {
            global.sprite_colour_r[_palette_array_index] = _slider_value;
        }

        if (_over_g_slider) {
            global.sprite_colour_g[_palette_array_index] = _slider_value;
        }

        if (_over_b_slider) {
            global.sprite_colour_b[_palette_array_index] = _slider_value;
        }
    }

    if ((mouse_check_button(mb_left) || mouse_check_button(mb_right)) && global.sprite_editing_field == "") {
        var _over_grid = point_in_rectangle(mouse_x, mouse_y, _layout.grid_x, _layout.grid_y, _layout.grid_x + _layout.grid_width, _layout.grid_y + _layout.grid_height);

        if (_over_grid) {
            var _cell_col = floor((mouse_x - _layout.grid_x) / _layout.cell_size);
            var _cell_row = floor((mouse_y - _layout.grid_y) / _layout.cell_size);

            if (_cell_col >= 0 && _cell_col < 16 && _cell_row >= 0 && _cell_row < global.sprite_height) {
                var _draw_index = global.sprite_paint_index;

                if (mouse_check_button(mb_right)) {
                    _draw_index = 0;
                }

                global.sprite_pixels[(_cell_row * 16) + _cell_col] = _draw_index;
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

    // Keep the build-time asset synchronized without requiring the editor to
    // close. F5 after a paint, erase, or palette drag now uses the values that
    // are visibly present in the open editor.
    if (mouse_check_button_released(mb_left) || mouse_check_button_released(mb_right)) {
        scr_asset_define_sprite(
            "TestSprite",
            global.sprite_channel,
            global.sprite_height,
            global.sprite_address,
            global.sprite_pixels,
            global.sprite_colour_r,
            global.sprite_colour_g,
            global.sprite_colour_b
        );
    }
}
