/// @description Amiga Dev Machine — World Bootstrap Manager

window_set_size(display_get_width(),display_get_height()); // ensure full screen
window_set_position(0,0);

// ============================================================================
// 0. GRID CONSTANT
// Must be set before anything below reads it.
// ============================================================================

global.grid_size = 20;


// ============================================================================
// 1. ADDRESSING MODES
// Must run before any opcode table definitions.
// ============================================================================

scr_define_addressing_modes();


// ============================================================================
// 2. OPCODE TABLE — ALL FIVE BANKS
// ============================================================================

global.opcode_map = {};

scr_define_opcodes_68k_part1();
scr_define_opcodes_68k_part2();
scr_define_opcodes_68k_part3();
scr_define_opcodes_68k_part4();
scr_define_opcodes_68k_part5();


// ============================================================================
// 3. CANVAS BOUNDS
// The droppable node-graph area.
// ============================================================================

global.canvas_bounds = {
    left   : 220,
    top    : 60,
    right  : room_width - 20,
    bottom : room_height - 20
};

global.value_display_mode = "HEX";


// ============================================================================
// 4. PROJECT AND BUILD SETTINGS
// Keep generated projects out of GameMaker's disposable GMS2TEMP directory.
// LOCALAPPDATA is stable and writable for both IDE and installed Windows runs.
// ============================================================================

var _local_app_data = environment_get_variable("LOCALAPPDATA");

if (_local_app_data == "") {
    _local_app_data = working_directory;
}

var _amiga_dev_data_path = _local_app_data + "/AmigaDevMachine";

if (!directory_exists(_amiga_dev_data_path)) {
    directory_create(_amiga_dev_data_path);
}

global.current_project_path = _amiga_dev_data_path + "/build_output";
global.current_volume_name = "AmigaDevDisk";
global.current_chipset_mode = "AGA";

// Create the build-output directory when it does not already exist.
if (!directory_exists(global.current_project_path)) {
    directory_create(global.current_project_path);
}


// ============================================================================
// 5. EDITING, PAN AND UNDO STATE
// ============================================================================

global.operand_edit_owner_uid = -1;

global.pan_x = 0;
global.pan_y = 0;
global.pan_active = false;
global.pan_last_mouse_x = 0;
global.pan_last_mouse_y = 0;

global.undo_stack = [];
global.redo_stack = [];
global.undo_stack_max = 100;

global.right_click_delete_handled_this_frame = false;
global.left_click_pickup_handled_this_frame = false;


// ============================================================================
// 6. PALETTE SCROLL AND HOVER STATE
// ============================================================================

global.palette_scroll_y = 0;
global.preview_scroll_y = 0;

preview_line_cache = [];
preview_scrollbar_dragging = false;
preview_scrollbar_drag_offset = 0;

global.status_message_log = [];

// True whenever anything has changed since the last save (or since start,
// if nothing has been saved yet). Set by the two undo-snapshot chokepoints
// every mutation already goes through — see scr_push_undo_snapshot and
// scr_bitmap_push_undo — and cleared by both save paths.
global.workspace_dirty = false;
global.autosave_delay_ms = 5000;
global.autosave_due_time = -1;
global.autosave_workspace_path = global.current_project_path + "/temp_autosave_workspace.json";

// Recent colours picked in obj_colour_picker, most-recent-first, capped at
// 8. Global and shared across every picker open (SETBKG, any CPRBAR band,
// anything else later) rather than per-instance.
global.colour_picker_recent_hex = [];

global.palette_panel_bounds = {
    left   : 0,
    top    : 60,
    right  : 300,
    bottom : room_height
};

global.palette_hover_mnemonic = "";
global.palette_hover_x = 0;
global.palette_hover_y = 0;

depth=-100000
// ============================================================================
// 7. OPCODE PALETTE
// One obj_opcode_palette_item per defined opcode, arranged in three columns.
// ============================================================================

palette_start_x = 10;
palette_start_y = 82;
palette_columns = 3;
palette_column_width = 85;
palette_row_height = global.grid_size + 5;

var _mnemonic_list = variable_struct_get_names(global.opcode_map);

array_sort(_mnemonic_list, true);

var _mnemonic_count = array_length(_mnemonic_list);
var _i = 0;

while (_i < _mnemonic_count) {
    var _mnemonic_key = _mnemonic_list[_i];
    var _column_index = _i mod palette_columns;
    var _row_index = _i div palette_columns;

    var _item_x = palette_start_x
        + (_column_index * palette_column_width);

    var _item_y = palette_start_y
        + (_row_index * palette_row_height);

    var _palette_instance = instance_create_layer(
        _item_x,
        _item_y,
        "Instances",
        obj_opcode_palette_item
    );

    _palette_instance.palette_mnemonic = _mnemonic_key;

    _palette_instance.palette_display_label =
        scr_opcode_display_label(_mnemonic_key);

    _palette_instance.palette_x = _item_x;
    _palette_instance.base_palette_y = _item_y;

    _i += 1;
}


// ============================================================================
// 8. ORG PALETTE ENTRY
// ============================================================================

// Shared top-strip geometry. ORG and LOAD/SAVE retain their established
// positions; the remaining controls are grouped by purpose from left to right.
top_ui_row_1_y = 20;
top_ui_row_2_y = 44;
top_ui_button_width = 100;
top_ui_button_height = 16;
top_ui_test_x = 310;
top_ui_test_2_x = 414;
top_ui_macro_x = 530;
top_ui_editor_x = 842;
top_ui_editor_2_x = 946;
top_ui_system_x = 1062;

var _org_palette_instance = instance_create_layer(
    palette_start_x,
    20,
    "Instances",
    obj_opcode_palette_item
);

_org_palette_instance.palette_mnemonic = "ORG";
_org_palette_instance.palette_x = palette_start_x;
_org_palette_instance.base_palette_y = 20;


// ============================================================================
// 9. MACROS PANEL
// CPRBAR and SETBKG occupy the dedicated MACROS column.
// ============================================================================

var _cprbar_palette_instance = instance_create_layer(
    top_ui_macro_x,
    top_ui_row_1_y,
    "Instances",
    obj_opcode_palette_item
);

_cprbar_palette_instance.palette_mnemonic = "CPRBAR";
_cprbar_palette_instance.palette_display_label = "CPRBAR";
_cprbar_palette_instance.palette_x = top_ui_macro_x;
_cprbar_palette_instance.base_palette_y = top_ui_row_1_y;

var _setbkg_palette_instance = instance_create_layer(
    top_ui_macro_x,
    top_ui_row_2_y,
    "Instances",
    obj_opcode_palette_item
);

_setbkg_palette_instance.palette_mnemonic = "SETBKG";
_setbkg_palette_instance.palette_display_label = "SETBKG";
_setbkg_palette_instance.palette_x = top_ui_macro_x;
_setbkg_palette_instance.base_palette_y = top_ui_row_2_y;

var _move_bob_palette_instance = instance_create_layer(top_ui_macro_x + 104, top_ui_row_1_y, "Instances", obj_opcode_palette_item);
_move_bob_palette_instance.palette_mnemonic = "MOVE_BOB";
_move_bob_palette_instance.palette_display_label = "MOVE BOB";
_move_bob_palette_instance.palette_x = top_ui_macro_x + 104;
_move_bob_palette_instance.base_palette_y = top_ui_row_1_y;

var _move_spr_palette_instance = instance_create_layer(top_ui_macro_x + 104, top_ui_row_2_y, "Instances", obj_opcode_palette_item);
_move_spr_palette_instance.palette_mnemonic = "MOVE_SPR";
_move_spr_palette_instance.palette_display_label = "MOVE SPR";
_move_spr_palette_instance.palette_x = top_ui_macro_x + 104;
_move_spr_palette_instance.base_palette_y = top_ui_row_2_y;

var _anim_bob_palette_instance = instance_create_layer(top_ui_macro_x + 208, top_ui_row_1_y, "Instances", obj_opcode_palette_item);
_anim_bob_palette_instance.palette_mnemonic = "ANIM_BOB";
_anim_bob_palette_instance.palette_display_label = "ANIM BOB";
_anim_bob_palette_instance.palette_x = top_ui_macro_x + 208;
_anim_bob_palette_instance.base_palette_y = top_ui_row_1_y;

var _anim_spr_palette_instance = instance_create_layer(top_ui_macro_x + 208, top_ui_row_2_y, "Instances", obj_opcode_palette_item);
_anim_spr_palette_instance.palette_mnemonic = "ANIM_SPR";
_anim_spr_palette_instance.palette_display_label = "ANIM SPR";
_anim_spr_palette_instance.palette_x = top_ui_macro_x + 208;
_anim_spr_palette_instance.base_palette_y = top_ui_row_2_y;


// ============================================================================
// 10. BUILD STATE MACHINE
// ============================================================================

build_state = "idle";
build_project_path = "";
build_volume_name = "";
build_exe_path = "";
build_adf_path = "";
build_uses_dos_loader = false;
build_wait_timer = 0;
build_timeout_frames = 600;
build_adf_ready_timer = 0;
build_exe_last_size = -1;
build_exe_stable_timer = 0;


// ============================================================================
// 11. EXTERNAL TOOL PATHS
//
// These paths resolve relative to GameMaker's Included Files/datafiles
// directory. They therefore work regardless of where the user installs or
// runs Amiga Dev Machine.
// ============================================================================

global.vasm_path =
    working_directory
    + "vasmm68k_mot_Win64/vasmm68k_mot.exe";

global.xdftool_path =
    working_directory
    + "xdftool/xdftool.exe";

global.fsuae_path =
    working_directory
    + "fsuae/fs-uae.exe";


// ============================================================================
// 12. LOAD USER SETTINGS
//
// The Kickstart ROM is not bundled. Its location is selected by the user and
// stored in settings.ini.
// ============================================================================

ini_open("settings.ini");

global.kickstart_path = ini_read_string(
    "paths",
    "kickstart",
    ""
);

ini_close();


// If the saved Kickstart file has been moved or deleted, clear the path.
if (global.kickstart_path != "") {
    if (!file_exists(global.kickstart_path)) {
        global.kickstart_path = "";
    }
}


// ============================================================================
// 13. VALIDATE BUNDLED TOOLS
// Collect all missing tools and display a single message.
// ============================================================================

var _missing_tools = "";

if (!file_exists(global.vasm_path)) {
    _missing_tools +=
        "\n\nVASM:\n"
        + global.vasm_path;
}

if (!file_exists(global.xdftool_path)) {
    _missing_tools +=
        "\n\nxdftool:\n"
        + global.xdftool_path;
}

if (!file_exists(global.fsuae_path)) {
    _missing_tools +=
        "\n\nFS-UAE:\n"
        + global.fsuae_path;
}

if (_missing_tools != "") {
    show_message(
        "One or more required tools could not be found:"
        + _missing_tools
        + "\n\nCheck that the tools are present in "
        + "GameMaker's Included Files."
    );
}


// ============================================================================
// 14. FIXED INIT NODE
// Program entry point, spawned once at its home position.
// ============================================================================

var _init_x = (room_width / 2) - 80;
var _init_y = room_height / 4;

var _init_instance = instance_create_layer(
    _init_x,
    _init_y,
    "Instances",
    obj_amiga_root_node
);

_init_instance.root_type = "INIT";

_init_instance.node_x = scr_snap_to_grid(
    _init_x,
    global.grid_size
);

_init_instance.node_y = scr_snap_to_grid(
    _init_y,
    global.grid_size
);


// ============================================================================
// 15. ASSET LIST
//
// Named byte-data assets that macro nodes look up by name. One default Copper
// Bar asset is registered so there is immediately something available.
// ============================================================================

global.asset_list = [];

scr_asset_define_copper_bar(
    "SunriseWater",
    4,
    44,
    110,
    13,
    2,
    0,
    15,
    12,
    6,
    4,
    110,
    200,
    15,
    8,
    4,
    0,
    1,
    6
);


// ============================================================================
// 16. SPRITE EDITOR STATE
//
// 16-pixel-wide, eight-channel hardware sprite editor. Height is capped at
// 64. The pixel array is allocated at full capacity and only the first
// height * 16 entries are used.
// ============================================================================

global.sprite_editor_open = false;
global.sprite_editor_x = 380;
global.sprite_editor_y = 60;
global.sprite_editor_dragging = false;
global.sprite_editor_drag_offset_x = 0;
global.sprite_editor_drag_offset_y = 0;
global.sprite_channel = 0;
global.sprite_height = 16;
global.sprite_address = 262144;

global.sprite_pixels = array_create(
    64 * 16,
    0
);

global.sprite_colour_r = [15, 0, 0];
global.sprite_colour_g = [0, 15, 0];
global.sprite_colour_b = [0, 0, 15];

global.sprite_paint_index = 1;
global.sprite_palette_edit_index = 1;
global.sprite_editing_field = "";
global.sprite_edit_text = "";
global.sprite_asset_name = "TestSprite";
global.current_bob_asset_name = "TestBob";
global.current_bob_anim_rate = 8;
global.current_bob_anim_start = 0;
global.current_bob_anim_end = 0;
global.current_bob_anim_loop = true;
global.sprite_asset_names = [];
global.sprite_asset_index = 0;
global.sprite_tool = "DRAW";
global.sprite_line_active = false;
global.sprite_line_start_x = 0;
global.sprite_line_start_y = 0;
global.sprite_line_value = 1;
global.sprite_line_current_x = 0;
global.sprite_line_current_y = 0;
global.sprite_line_button = mb_left;
global.sprite_drawing = false;
global.sprite_drawing_value = 1;
global.sprite_drawing_button = mb_left;
global.sprite_last_px = -1;
global.sprite_last_py = -1;
global.sprite_anim_playing = false;
global.sprite_anim_rate = 8;
global.sprite_anim_start = 0;
global.sprite_anim_end = 0;
global.sprite_anim_loop = true;
global.sprite_anim_next_time = 0;

sprite_editor_commit_asset = function() {
    scr_asset_define_sprite(global.sprite_asset_name, global.sprite_channel, global.sprite_height, global.sprite_address,
        global.sprite_pixels, global.sprite_colour_r, global.sprite_colour_g, global.sprite_colour_b);
    scr_mark_workspace_dirty();
};

sprite_editor_load_shared_colours = function() {
    var _palette = scr_amiga_get_shared_bitmap_palette();
    var _base = 17 + ((global.sprite_channel div 2) * 4);
    var _i = 0;
    while (_i < 3) {
        global.sprite_colour_r[_i] = _palette.colour_r[_base + _i];
        global.sprite_colour_g[_i] = _palette.colour_g[_base + _i];
        global.sprite_colour_b[_i] = _palette.colour_b[_base + _i];
        _i += 1;
    }
};

sprite_editor_commit_shared_colours = function() {
    var _palette = scr_amiga_get_shared_bitmap_palette();
    var _base = 17 + ((global.sprite_channel div 2) * 4);
    var _i = 0;
    while (_i < 3) {
        _palette.colour_r[_base + _i] = global.sprite_colour_r[_i];
        _palette.colour_g[_base + _i] = global.sprite_colour_g[_i];
        _palette.colour_b[_base + _i] = global.sprite_colour_b[_i];
        _i += 1;
    }
    scr_amiga_commit_shared_bitmap_palette(_palette.colour_r, _palette.colour_g, _palette.colour_b);
};

sprite_editor_rebuild_assets = function() {
    global.sprite_asset_names = [];
    var _i = 0;
    while (_i < array_length(global.asset_list)) {
        if (global.asset_list[_i].type == "SPRITE") array_push(global.sprite_asset_names, global.asset_list[_i].name);
        _i += 1;
    }
    var _max_frame = max(0, array_length(global.sprite_asset_names) - 1);
    global.sprite_anim_start = clamp(global.sprite_anim_start, 0, _max_frame);
    global.sprite_anim_end = clamp(global.sprite_anim_end, global.sprite_anim_start, _max_frame);
};

sprite_editor_load_asset = function(_name) {
    var _asset = scr_asset_find_by_name(_name);
    if (_asset == undefined || _asset.type != "SPRITE") exit;
    global.sprite_asset_name = _name;
    global.sprite_channel = _asset.channel;
    global.sprite_height = clamp(_asset.height, 1, 64);
    global.sprite_address = _asset.address;
    global.sprite_pixels = array_create(64 * 16, 0);
    array_copy(global.sprite_pixels, 0, _asset.pixels, 0, min(array_length(_asset.pixels), 64 * 16));
    global.sprite_colour_r = [_asset.colour_r[0], _asset.colour_r[1], _asset.colour_r[2]];
    global.sprite_colour_g = [_asset.colour_g[0], _asset.colour_g[1], _asset.colour_g[2]];
    global.sprite_colour_b = [_asset.colour_b[0], _asset.colour_b[1], _asset.colour_b[2]];
    sprite_editor_load_shared_colours();
    global.sprite_line_active = false;
};

sprite_editor_navigate = function(_delta) {
    global.sprite_anim_playing = false;
    sprite_editor_commit_asset();
    sprite_editor_rebuild_assets();
    if (array_length(global.sprite_asset_names) <= 0) exit;
    global.sprite_asset_index = (global.sprite_asset_index + _delta + array_length(global.sprite_asset_names)) mod array_length(global.sprite_asset_names);
    sprite_editor_load_asset(global.sprite_asset_names[global.sprite_asset_index]);
};

sprite_editor_add_asset = function() {
    global.sprite_anim_playing = false;
    sprite_editor_commit_asset();
    var _number = 1;
    var _name = "Sprite01";
    while (scr_asset_find_by_name(_name) != undefined) {
        _number += 1;
        _name = "Sprite" + (_number < 10 ? "0" : "") + string(_number);
    }
    global.sprite_asset_name = _name;
    global.sprite_pixels = array_create(64 * 16, 0);
    global.sprite_height = 16;
    sprite_editor_commit_asset();
    sprite_editor_rebuild_assets();
    global.sprite_asset_index = array_length(global.sprite_asset_names) - 1;
    global.sprite_anim_end = max(0, array_length(global.sprite_asset_names) - 1);
    global.sprite_line_active = false;
};

sprite_editor_apply_line = function(_x0, _y0, _x1, _y1, _value) {
    var _dx = abs(_x1 - _x0), _sx = _x0 < _x1 ? 1 : -1;
    var _dy = -abs(_y1 - _y0), _sy = _y0 < _y1 ? 1 : -1;
    var _err = _dx + _dy;
    repeat (128) {
        global.sprite_pixels[_y0 * 16 + _x0] = _value;
        if (_x0 == _x1 && _y0 == _y1) break;
        var _e2 = 2 * _err;
        if (_e2 >= _dy) { _err += _dy; _x0 += _sx; }
        if (_e2 <= _dx) { _err += _dx; _y0 += _sy; }
    }
};

sprite_editor_apply_fill = function(_x, _y, _value) {
    var _target = global.sprite_pixels[_y * 16 + _x];
    if (_target == _value) exit;
    var _qx = [_x], _qy = [_y], _head = 0;
    global.sprite_pixels[_y * 16 + _x] = _value;
    while (_head < array_length(_qx)) {
        var _cx = _qx[_head], _cy = _qy[_head]; _head += 1;
        var _nx = [_cx - 1, _cx + 1, _cx, _cx];
        var _ny = [_cy, _cy, _cy - 1, _cy + 1];
        var _n = 0;
        while (_n < 4) {
            if (_nx[_n] >= 0 && _nx[_n] < 16 && _ny[_n] >= 0 && _ny[_n] < global.sprite_height) {
                var _index = _ny[_n] * 16 + _nx[_n];
                if (global.sprite_pixels[_index] == _target) {
                    global.sprite_pixels[_index] = _value;
                    array_push(_qx, _nx[_n]); array_push(_qy, _ny[_n]);
                }
            }
            _n += 1;
        }
    }
};

sprite_editor_rebuild_assets();
if (array_length(global.sprite_asset_names) == 0) {
    sprite_editor_commit_asset();
    sprite_editor_rebuild_assets();
}
var _sprite_find = 0;
while (_sprite_find < array_length(global.sprite_asset_names)) {
    if (global.sprite_asset_names[_sprite_find] == "TestSprite") global.sprite_asset_index = _sprite_find;
    _sprite_find += 1;
}
sprite_editor_load_asset(global.sprite_asset_names[global.sprite_asset_index]);
global.sprite_anim_end = max(0, array_length(global.sprite_asset_names) - 1);

// Default bootstrap assets are not a user edit. Once the manager is fully
// initialized, recover the most recent temporary testing session when one is
// available and report the I/O event in cyan in the message window.
global.workspace_dirty = false;
global.autosave_due_time = -1;
if (file_exists(global.autosave_workspace_path)) {
    try {
        scr_load_workspace_from_path(global.autosave_workspace_path);
        scr_set_status_message("Previous session auto-loaded.", make_colour_rgb(0, 255, 255));
    } catch (_autosave_error) {
        show_debug_message("Temporary autosave recovery failed: " + string(_autosave_error));
        scr_set_status_message("Previous temporary session could not be loaded.", c_red);
    }
}
