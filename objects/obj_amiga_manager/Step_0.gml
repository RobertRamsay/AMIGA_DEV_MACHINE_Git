// The bitmap editor and colour picker are both modal: do not pan, build,
// undo, click controls or mutate the graph behind either of them.
if (instance_exists(obj_bitmap_editor) || instance_exists(obj_bob_editor) || instance_exists(obj_colour_picker) || instance_exists(obj_cprbar_editor)) {
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
    scr_amiga_trigger_build();
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
    }

    // Safety net — covers both "main.bin never appears" and "main.bin
    // appears but stays at 0 bytes forever" (e.g. an empty/no-op build).
    // The stability check above only ever progresses once size is > 0, so
    // without this a stuck-at-zero file would leave build_state here
    // permanently and F5 would never fire again.
    if (build_state == "waiting_for_asm" && build_wait_timer > build_timeout_frames) {
        show_debug_message("Build timed out waiting for vasm to produce a valid main.bin.");
        build_state = "idle";
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

        // Kickstart picker is disabled for now (see the F5 handler above) —
        // don't pass --kickstart_file at all, so FS-UAE always uses its own
        // bundled default rather than picking up something stale left over
        // in settings.ini from earlier testing. Revisit together.
        var _uae_args = "--floppy_drive_0=\"" + build_adf_path + "\" --fullscreen=0 --window_x=500 --window_y=200 --window_width=900 --window_height=700 --zoom=1";
execute_shell_simple(global.fsuae_path, _uae_args);
        build_state = "idle";
    }
}

var _test_button_x = top_ui_test_x;
var _test_button_y = top_ui_row_1_y;
var _test_button_width = top_ui_button_width;
var _test_button_height = top_ui_button_height;

var _over_test_button = point_in_rectangle(mouse_x, mouse_y, _test_button_x, _test_button_y, _test_button_x + _test_button_width, _test_button_y + _test_button_height);

if (_over_test_button && mouse_check_button_pressed(mb_left)) {
    scr_load_test_setup();
}

var _sprite_editor_button_x = top_ui_editor_x;
var _sprite_editor_button_y = top_ui_row_1_y;
var _sprite_editor_button_width = top_ui_button_width;
var _sprite_editor_button_height = top_ui_button_height;

var _over_sprite_editor_button = point_in_rectangle(mouse_x, mouse_y, _sprite_editor_button_x, _sprite_editor_button_y, _sprite_editor_button_x + _sprite_editor_button_width, _sprite_editor_button_y + _sprite_editor_button_height);

if (_over_sprite_editor_button && mouse_check_button_pressed(mb_left)) {
    global.sprite_editor_open = !global.sprite_editor_open;
    if (global.sprite_editor_open) {
        sprite_editor_rebuild_assets();
        if (array_length(global.sprite_asset_names) > 0) {
            var _current_sprite_index = -1;
            var _sprite_scan = 0;
            while (_sprite_scan < array_length(global.sprite_asset_names)) {
                if (global.sprite_asset_names[_sprite_scan] == global.sprite_asset_name) _current_sprite_index = _sprite_scan;
                _sprite_scan += 1;
            }
            if (_current_sprite_index < 0) _current_sprite_index = 0;
            global.sprite_asset_index = _current_sprite_index;
            sprite_editor_load_asset(global.sprite_asset_names[global.sprite_asset_index]);
        }
    }
}

var _sprite_test_button_x = top_ui_test_x;
var _sprite_test_button_y = top_ui_row_2_y;
var _sprite_test_button_width = top_ui_button_width;
var _sprite_test_button_height = top_ui_button_height;

var _over_sprite_test_button = point_in_rectangle(mouse_x, mouse_y, _sprite_test_button_x, _sprite_test_button_y, _sprite_test_button_x + _sprite_test_button_width, _sprite_test_button_y + _sprite_test_button_height);

if (_over_sprite_test_button && mouse_check_button_pressed(mb_left)) {
    scr_amiga_run_sprite_test();
}

var _bitmap_editor_button_x = top_ui_editor_x;
var _bitmap_editor_button_y = top_ui_row_2_y;
var _bitmap_editor_button_width = top_ui_button_width;
var _bitmap_editor_button_height = top_ui_button_height;

var _over_bitmap_editor_button = point_in_rectangle(mouse_x, mouse_y, _bitmap_editor_button_x, _bitmap_editor_button_y, _bitmap_editor_button_x + _bitmap_editor_button_width, _bitmap_editor_button_y + _bitmap_editor_button_height);

if (_over_bitmap_editor_button && mouse_check_button_pressed(mb_left)) {
    if (instance_exists(obj_bitmap_editor)) {
        with (obj_bitmap_editor) instance_destroy();
    } else {
        instance_create_layer(0, 0, "Instances", obj_bitmap_editor);
    }
}

var _bob_editor_button_x = top_ui_editor_2_x;
var _over_bob_editor_button = point_in_rectangle(mouse_x, mouse_y, _bob_editor_button_x, top_ui_row_1_y, _bob_editor_button_x + top_ui_button_width, top_ui_row_1_y + top_ui_button_height);
if (_over_bob_editor_button && mouse_check_button_pressed(mb_left)) {
    if (instance_exists(obj_bob_editor)) with (obj_bob_editor) instance_destroy();
    else instance_create_layer(0, 0, "Instances", obj_bob_editor);
}

var _over_bob_test = point_in_rectangle(mouse_x, mouse_y, top_ui_test_2_x, top_ui_row_1_y, top_ui_test_2_x + top_ui_button_width, top_ui_row_1_y + top_ui_button_height);
if (_over_bob_test && mouse_check_button_pressed(mb_left)) scr_amiga_run_bob_bitmap_test();

var _over_sprite_bitmap_test = point_in_rectangle(mouse_x, mouse_y, top_ui_test_2_x, top_ui_row_2_y, top_ui_test_2_x + top_ui_button_width, top_ui_row_2_y + top_ui_button_height);
if (_over_sprite_bitmap_test && mouse_check_button_pressed(mb_left)) scr_amiga_run_sprite_bitmap_test();

var _kill_fsuae_button_x = top_ui_system_x;
var _kill_fsuae_button_y = top_ui_row_1_y;
var _kill_fsuae_button_width = top_ui_button_width;
var _kill_fsuae_button_height = top_ui_button_height;

var _over_kill_fsuae_button = point_in_rectangle(mouse_x, mouse_y, _kill_fsuae_button_x, _kill_fsuae_button_y, _kill_fsuae_button_x + _kill_fsuae_button_width, _kill_fsuae_button_y + _kill_fsuae_button_height);

if (_over_kill_fsuae_button && mouse_check_button_pressed(mb_left)) {
    execute_shell_simple("taskkill.exe", "/F /T /IM fs-uae.exe", "open", 0);
    scr_set_status_message("FS-UAE killed.");
}

var _save_workspace_button_x = 110;
var _save_workspace_button_y = 44;
var _save_workspace_button_width = 150;
var _save_workspace_button_height = 16;

var _over_save_workspace_button = point_in_rectangle(mouse_x, mouse_y, _save_workspace_button_x, _save_workspace_button_y, _save_workspace_button_x + _save_workspace_button_width, _save_workspace_button_y + _save_workspace_button_height);

if (_over_save_workspace_button && mouse_check_button_pressed(mb_left)) {
    var _save_chosen_path = get_save_filename("Workspace JSON|*.json", "workspace.json");

    if (_save_chosen_path != "") {
        scr_save_workspace_to_path(_save_chosen_path);
        scr_set_status_message("Workspace saved: " + _save_chosen_path);
    }
}

var _load_workspace_button_x = 110;
var _load_workspace_button_y = 20;
var _load_workspace_button_width = 150;
var _load_workspace_button_height = 16;

var _over_load_workspace_button = point_in_rectangle(mouse_x, mouse_y, _load_workspace_button_x, _load_workspace_button_y, _load_workspace_button_x + _load_workspace_button_width, _load_workspace_button_y + _load_workspace_button_height);

if (_over_load_workspace_button && mouse_check_button_pressed(mb_left)) {
    var _load_chosen_path = get_open_filename("Workspace JSON|*.json", "");

    if (_load_chosen_path != "") {
        scr_load_workspace_from_path(_load_chosen_path);
        scr_set_status_message("Workspace loaded: " + _load_chosen_path);
    }
}

var _quit_button_x = top_ui_system_x;
var _quit_button_y = top_ui_row_2_y;
var _quit_button_width = top_ui_button_width;
var _quit_button_height = top_ui_button_height;

var _over_quit_button = point_in_rectangle(mouse_x, mouse_y, _quit_button_x, _quit_button_y, _quit_button_x + _quit_button_width, _quit_button_y + _quit_button_height);

if (_over_quit_button && mouse_check_button_pressed(mb_left)) {
    var _should_quit = true;

    if (global.workspace_dirty) {
        _should_quit = show_question("You have unsaved changes. Quit anyway?");
    }

    if (_should_quit) {
        game_end();
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

// Wrapping uses real rendered pixel widths, so select the same font used by
// Draw before rebuilding the cache. This avoids fixed character-count guesses
// with the variable-width Future font.
draw_set_font(font_Future);
preview_line_cache = scr_amiga_build_preview_lines();

var _preview_panel_x = room_width - 360;
var _preview_panel_y = 60;
var _preview_panel_width = 350;
var _preview_panel_height = room_height - 60;
var _preview_line_height = 16;
var _preview_content_top = _preview_panel_y + 56;
var _preview_content_bottom = _preview_panel_y + _preview_panel_height - 8;
var _preview_viewport_height = _preview_content_bottom - _preview_content_top;
var _preview_list_height = array_length(preview_line_cache) * _preview_line_height;
var _preview_scroll_range = max(0, _preview_list_height - _preview_viewport_height);
var _preview_min_scroll = -_preview_scroll_range;
var _preview_scroll_consumed = false;

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

    if (global.preview_scroll_y < _preview_min_scroll) {
        global.preview_scroll_y = _preview_min_scroll;
    }
}

var _collapse_x = _preview_panel_x + 6;
var _collapse_y = _preview_panel_y + 24;
if (mouse_check_button_pressed(mb_left) && point_in_rectangle(mouse_x, mouse_y, _collapse_x, _collapse_y, _preview_panel_x + _preview_panel_width - 16, _collapse_y + 17)) {
    with (obj_opcode_node) {
        if (is_macro) preview_collapsed = true;
    }
    global.preview_scroll_y = 0;
    _preview_scroll_consumed = true;
}

var _track_x1 = _preview_panel_x + _preview_panel_width - 11;
var _track_x2 = _preview_panel_x + _preview_panel_width - 3;
var _track_y1 = _preview_content_top;
var _track_y2 = _preview_content_bottom;
var _track_height = _track_y2 - _track_y1;

if (_preview_scroll_range > 0) {
    var _thumb_height = max(28, floor(_track_height * (_preview_viewport_height / _preview_list_height)));
    var _thumb_range = _track_height - _thumb_height;
    var _thumb_ratio = clamp((-global.preview_scroll_y) / _preview_scroll_range, 0, 1);
    var _thumb_y = _track_y1 + floor(_thumb_range * _thumb_ratio);

    if (mouse_check_button_pressed(mb_left) && point_in_rectangle(mouse_x, mouse_y, _track_x1, _track_y1, _track_x2, _track_y2)) {
        _preview_scroll_consumed = true;
        if (point_in_rectangle(mouse_x, mouse_y, _track_x1, _thumb_y, _track_x2, _thumb_y + _thumb_height)) {
            preview_scrollbar_drag_offset = mouse_y - _thumb_y;
        } else {
            preview_scrollbar_drag_offset = _thumb_height / 2;
        }
        preview_scrollbar_dragging = true;
    }

    if (preview_scrollbar_dragging) {
        _preview_scroll_consumed = true;
        if (mouse_check_button(mb_left)) {
            var _new_thumb_y = clamp(mouse_y - preview_scrollbar_drag_offset, _track_y1, _track_y1 + _thumb_range);
            var _new_ratio = _thumb_range > 0 ? (_new_thumb_y - _track_y1) / _thumb_range : 0;
            global.preview_scroll_y = -round(_new_ratio * _preview_scroll_range);
        } else {
            preview_scrollbar_dragging = false;
        }
    }
} else {
    preview_scrollbar_dragging = false;
    global.preview_scroll_y = 0;
}

// O spawns an ORG root node at the mouse position — workspace area only,
// not while typing into a field and not over the palette or preview panels.
if (keyboard_check_pressed(ord("O")) && global.operand_edit_owner_uid == -1 && !_over_palette && !_over_preview_panel) {
    scr_push_undo_snapshot();

    var _org_spawn_x = mouse_x - global.pan_x;
    var _org_spawn_y = mouse_y - global.pan_y;

    var _new_org = instance_create_layer(_org_spawn_x, _org_spawn_y, "Instances", obj_amiga_root_node);
    _new_org.root_type = "ORG";
    _new_org.node_x = _org_spawn_x - (_new_org.node_width / 2);
    _new_org.node_y = _org_spawn_y - (_new_org.node_height / 2);

    scr_set_status_message("ORG spawned at mouse position.");
}

if (mouse_check_button_pressed(mb_left) && !_preview_scroll_consumed) {
    var _click_line_y = _preview_content_top + global.preview_scroll_y;
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
        sprite_editor_commit_asset();
        global.sprite_anim_playing = false;
        global.sprite_editor_open = false;
        global.sprite_editor_dragging = false;
    }

    var _over_asset_prev = point_in_rectangle(mouse_x, mouse_y, _layout.asset_prev_x, _layout.asset_row_y, _layout.asset_prev_x + 28, _layout.asset_row_y + 20);
    var _over_asset_next = point_in_rectangle(mouse_x, mouse_y, _layout.asset_next_x, _layout.asset_row_y, _layout.asset_next_x + 28, _layout.asset_row_y + 20);
    var _over_asset_add = point_in_rectangle(mouse_x, mouse_y, _layout.asset_add_x, _layout.asset_row_y, _layout.asset_add_x + 104, _layout.asset_row_y + 20);
    if (_over_asset_prev && mouse_check_button_pressed(mb_left)) sprite_editor_navigate(-1);
    if (_over_asset_next && mouse_check_button_pressed(mb_left)) sprite_editor_navigate(1);
    if (_over_asset_add && mouse_check_button_pressed(mb_left)) sprite_editor_add_asset();

    var _tool_i = 0;
    var _tool_names = ["DRAW", "LINE", "FILL"];
    while (_tool_i < 3) {
        var _tool_y = _layout.tool_y + _tool_i * 36;
        if (mouse_check_button_pressed(mb_left) && point_in_rectangle(mouse_x, mouse_y, _layout.tool_x, _tool_y, _layout.tool_x + _layout.tool_width, _tool_y + _layout.tool_height)) {
            global.sprite_tool = _tool_names[_tool_i];
            global.sprite_anim_playing = false;
            global.sprite_line_active = false;
            global.sprite_drawing = false;
        }
        _tool_i += 1;
    }

    if (mouse_check_button_pressed(mb_left) && point_in_rectangle(mouse_x, mouse_y, _layout.anim_x, _layout.anim_play_y, _layout.anim_x + _layout.anim_width, _layout.anim_play_y + _layout.anim_height)) {
        global.sprite_anim_playing = !global.sprite_anim_playing;
        if (global.sprite_anim_playing) {
            sprite_editor_commit_asset(); sprite_editor_rebuild_assets();
            global.sprite_asset_index = global.sprite_anim_start;
            sprite_editor_load_asset(global.sprite_asset_names[global.sprite_asset_index]);
            global.sprite_anim_next_time = current_time + (1000 / global.sprite_anim_rate);
        }
    }
    if (mouse_check_button_pressed(mb_left) && point_in_rectangle(mouse_x, mouse_y, _layout.anim_x, _layout.anim_loop_y, _layout.anim_x + _layout.anim_width, _layout.anim_loop_y + _layout.anim_height)) {
        global.sprite_anim_loop = !global.sprite_anim_loop;
    }
    var _sprite_frame_max = max(0, array_length(global.sprite_asset_names) - 1);
    if (mouse_check_button_pressed(mb_left) && point_in_rectangle(mouse_x, mouse_y, _layout.anim_x, _layout.anim_rate_y, _layout.anim_x + _layout.anim_width, _layout.anim_rate_y + _layout.anim_height)) {
        global.sprite_anim_rate = clamp(global.sprite_anim_rate + (mouse_x < _layout.anim_x + _layout.anim_width * 0.5 ? -1 : 1), 1, 60);
    }
    if (mouse_check_button_pressed(mb_left) && point_in_rectangle(mouse_x, mouse_y, _layout.anim_x, _layout.anim_start_y, _layout.anim_x + _layout.anim_width, _layout.anim_start_y + _layout.anim_height)) {
        global.sprite_anim_start = clamp(global.sprite_anim_start + (mouse_x < _layout.anim_x + _layout.anim_width * 0.5 ? -1 : 1), 0, global.sprite_anim_end);
    }
    if (mouse_check_button_pressed(mb_left) && point_in_rectangle(mouse_x, mouse_y, _layout.anim_x, _layout.anim_end_y, _layout.anim_x + _layout.anim_width, _layout.anim_end_y + _layout.anim_height)) {
        global.sprite_anim_end = clamp(global.sprite_anim_end + (mouse_x < _layout.anim_x + _layout.anim_width * 0.5 ? -1 : 1), global.sprite_anim_start, _sprite_frame_max);
    }

    if (global.sprite_anim_playing && current_time >= global.sprite_anim_next_time) {
        global.sprite_asset_index += 1;
        if (global.sprite_asset_index > global.sprite_anim_end) {
            if (global.sprite_anim_loop) global.sprite_asset_index = global.sprite_anim_start;
            else { global.sprite_asset_index = global.sprite_anim_end; global.sprite_anim_playing = false; }
        }
        sprite_editor_load_asset(global.sprite_asset_names[global.sprite_asset_index]);
        global.sprite_anim_next_time = current_time + (1000 / global.sprite_anim_rate);
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

    var _sprite_left_press = mouse_check_button_pressed(mb_left);
    var _sprite_right_press = mouse_check_button_pressed(mb_right);
    var _sprite_grid_press = _sprite_left_press || _sprite_right_press;
    var _over_grid = point_in_rectangle(mouse_x, mouse_y, _layout.grid_x, _layout.grid_y, _layout.grid_x + _layout.grid_width, _layout.grid_y + _layout.grid_height);
    var _cell_col = clamp(floor((mouse_x - _layout.grid_x) / _layout.cell_size), 0, 15);
    var _cell_row = clamp(floor((mouse_y - _layout.grid_y) / _layout.cell_size), 0, global.sprite_height - 1);

    if (_over_grid && _sprite_grid_press && global.sprite_editing_field == "") {
        global.sprite_anim_playing = false;
        var _value = _sprite_right_press ? 0 : global.sprite_paint_index;
        if (global.sprite_tool == "DRAW") {
            global.sprite_drawing = true;
            global.sprite_drawing_value = _value;
            global.sprite_drawing_button = _sprite_right_press ? mb_right : mb_left;
            global.sprite_last_px = _cell_col; global.sprite_last_py = _cell_row;
            global.sprite_pixels[_cell_row * 16 + _cell_col] = _value;
        } else if (global.sprite_tool == "LINE") {
            global.sprite_line_active = true;
            global.sprite_line_start_x = _cell_col; global.sprite_line_start_y = _cell_row;
            global.sprite_line_current_x = _cell_col; global.sprite_line_current_y = _cell_row;
            global.sprite_line_value = _value;
            global.sprite_line_button = _sprite_right_press ? mb_right : mb_left;
        } else if (global.sprite_tool == "FILL") {
            sprite_editor_apply_fill(_cell_col, _cell_row, _value);
            sprite_editor_commit_asset();
        }
    }

    if (global.sprite_line_active) {
        if (mouse_check_button(global.sprite_line_button)) {
            if (_over_grid) {
                global.sprite_line_current_x = _cell_col;
                global.sprite_line_current_y = _cell_row;
            }
        } else {
            sprite_editor_apply_line(global.sprite_line_start_x, global.sprite_line_start_y,
                global.sprite_line_current_x, global.sprite_line_current_y, global.sprite_line_value);
            global.sprite_line_active = false;
            sprite_editor_commit_asset();
        }
    }

    if (global.sprite_drawing) {
        var _draw_held = mouse_check_button(global.sprite_drawing_button);
        if (_draw_held) {
            if (_over_grid) {
                sprite_editor_apply_line(global.sprite_last_px, global.sprite_last_py, _cell_col, _cell_row, global.sprite_drawing_value);
                global.sprite_last_px = _cell_col; global.sprite_last_py = _cell_row;
            }
        } else {
            global.sprite_drawing = false;
            sprite_editor_commit_asset();
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
        sprite_editor_commit_asset();
    }
}
