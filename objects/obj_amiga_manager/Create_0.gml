/// @description Amiga Dev Machine — World Bootstrap Manager

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

global.status_message_log = [];

global.palette_panel_bounds = {
    left   : 0,
    top    : 60,
    right  : 300,
    bottom : room_height
};

global.palette_hover_mnemonic = "";
global.palette_hover_x = 0;
global.palette_hover_y = 0;


// ============================================================================
// 7. OPCODE PALETTE
// One obj_opcode_palette_item per defined opcode, arranged in three columns.
// ============================================================================

palette_start_x = 10;
palette_start_y = 100;
palette_columns = 3;
palette_column_width = 87;
palette_row_height = global.grid_size + 3;

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
// CPRBAR lives here rather than in the ORG row.
// The MACROS header and TEST button are handled by the manager.
// ============================================================================

var _cprbar_palette_instance = instance_create_layer(
    310,
    40,
    "Instances",
    obj_opcode_palette_item
);

_cprbar_palette_instance.palette_mnemonic = "CPRBAR";
_cprbar_palette_instance.palette_display_label = "CPRBAR";
_cprbar_palette_instance.palette_x = 310;
_cprbar_palette_instance.base_palette_y = 40;


// ============================================================================
// 10. BUILD STATE MACHINE
// ============================================================================

build_state = "idle";
build_project_path = "";
build_volume_name = "";
build_exe_path = "";
build_adf_path = "";
build_wait_timer = 0;
build_timeout_frames = 600;
build_adf_ready_timer = 0;


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
