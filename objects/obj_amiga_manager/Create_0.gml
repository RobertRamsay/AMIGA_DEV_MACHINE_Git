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

// 4. Project/build state
global.current_project_path = working_directory;
global.current_volume_name = "AmigaDevDisk";
global.current_chipset_mode = "AGA";

// 5. Palette scroll + hover state
global.palette_scroll_y = 0;
global.palette_panel_bounds = {
    left : 0,
    top : 60,
    right : 300,
    bottom : room_height
};
global.palette_hover_mnemonic = "";
global.palette_hover_x = 0;
global.palette_hover_y = 0;

// 6. Palette — one obj_opcode_palette_item per defined opcode, 2-column grid
palette_start_x = 10;
palette_start_y = 20;
palette_columns = 3;
palette_column_width = 87;
palette_row_height = global.grid_size+3;

var _mnemonic_list = variable_struct_get_names(global.opcode_map);
var _mnemonic_count = array_length(_mnemonic_list);
var _i = 0;

while (_i < _mnemonic_count) {
    var _mnemonic_key = _mnemonic_list[_i];
    var _column_index = _i mod palette_columns;
    var _row_index = _i div palette_columns;

    var _item_x = palette_start_x + (_column_index * palette_column_width);
    var _item_y = palette_start_y + (_row_index * palette_row_height);

    var _palette_instance = instance_create_layer(_item_x, _item_y, "Instances", obj_opcode_palette_item);

    _palette_instance.palette_mnemonic = global.opcode_map[$ _mnemonic_key].mnemonic;
    _palette_instance.palette_x = _item_x;
    _palette_instance.base_palette_y = _item_y;

    _i += 1;
}