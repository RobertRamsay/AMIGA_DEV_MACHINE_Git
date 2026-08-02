/// @description Amiga Dev Machine — World Bootstrap Manager

// 0. Grid constant — must be set before anything below reads it
global.grid_size = 20;

// 1. Addressing mode bitflags — must run before any opcode table definitions
scr_define_addressing_modes();

// 2. Opcode table — all five banks
global.opcode_map = {};
scr_define_opcodes_68k_part1();
scr_define_opcodes_68k_part2();
scr_define_opcodes_68k_part3();
scr_define_opcodes_68k_part4();
scr_define_opcodes_68k_part5();

// 3. Canvas bounds — the droppable node-graph area, fully specified up front
global.canvas_bounds = {
    left : 220,
    top : 60,
    right : room_width - 20,
    bottom : room_height - 20
};

global.value_display_mode = "HEX";

// 4. Project/build state
global.current_project_path = "C:/AmigaDevMachine/build_output";
global.current_volume_name = "AmigaDevDisk";
global.current_chipset_mode = "AGA";

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

// 5. Palette scroll + hover state
global.palette_scroll_y = 0;
global.preview_scroll_y = 0;
preview_line_cache = [];
global.palette_panel_bounds = {
    left : 0,
    top : 60,
    right : 300,
    bottom : room_height
};
global.palette_hover_mnemonic = "";
global.palette_hover_x = 0;
global.palette_hover_y = 0;

// 6. Palette — one obj_opcode_palette_item per defined opcode, 3-column grid
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

    var _item_x = palette_start_x + (_column_index * palette_column_width);
    var _item_y = palette_start_y + (_row_index * palette_row_height);

    var _palette_instance = instance_create_layer(_item_x, _item_y, "Instances", obj_opcode_palette_item);

    _palette_instance.palette_mnemonic = _mnemonic_key;
    _palette_instance.palette_display_label = scr_opcode_display_label(_mnemonic_key);
    _palette_instance.palette_x = _item_x;
    _palette_instance.base_palette_y = _item_y;

    _i += 1;
}

// 7. ORG palette entry — on its own, well clear of the mnemonic grid below it
var _org_palette_instance = instance_create_layer(palette_start_x, 20, "Instances", obj_opcode_palette_item);
_org_palette_instance.palette_mnemonic = "ORG";
_org_palette_instance.palette_x = palette_start_x;
_org_palette_instance.base_palette_y = 20;

// 7b. MACROS panel — CPRBAR lives here now, not in the ORG row. The "MACROS:"
// header text and the TEST button are drawn/handled in the manager itself.
var _cprbar_palette_instance = instance_create_layer(310, 40, "Instances", obj_opcode_palette_item);
_cprbar_palette_instance.palette_mnemonic = "CPRBAR";
_cprbar_palette_instance.palette_display_label = "CPRBAR";
_cprbar_palette_instance.palette_x = 310;
_cprbar_palette_instance.base_palette_y = 40;

// 8. Build state machine
build_state = "idle";
build_project_path = "";
build_volume_name = "";
build_exe_path = "";
build_adf_path = "";
build_wait_timer = 0;
build_timeout_frames = 600;

global.vasm_path = "C:/Users/me/Downloads/vasmm68k_mot.exe";
global.xdftool_path = "C:/Users/me/AppData/Local/Python/pythoncore-3.14-64/Scripts/xdftool.exe";
global.fsuae_path = "C:/Users/me/OneDrive/Documents/AMIGA/TheSettlers/fsuae/fs-uae.exe";
global.kickstart_path = "";

// 9. The one fixed INIT node — program entry point, spawned once, home position
var _init_x = (room_width / 2) - 80;
var _init_y = room_height / 4;

var _init_instance = instance_create_layer(_init_x, _init_y, "Instances", obj_amiga_root_node);
_init_instance.root_type = "INIT";
_init_instance.node_x = scr_snap_to_grid(_init_x, global.grid_size);
_init_instance.node_y = scr_snap_to_grid(_init_y, global.grid_size);

// 10. Asset list — named byte-data assets that macro nodes look up by name,
// same pattern as C64DM's obj_asset_manager.asset_list. One default Copper
// Bar asset is registered up front so there's immediately something to use.
global.asset_list = [];
scr_asset_define_copper_bar("SunriseWater", 4, 44, 110, 13, 2, 0, 15, 12, 6, 4, 110, 200, 15, 8, 4, 0, 1, 6);