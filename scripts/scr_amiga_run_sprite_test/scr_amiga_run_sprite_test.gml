/// @desc scr_amiga_run_sprite_test()
/// Saves the sprite editor's current state as a named asset, clears the
/// canvas, and builds a minimal INIT+ORG program: disable DMA/interrupts,
/// display the sprite via a SPRITE_DISPLAY macro, then idle forever.
function scr_amiga_run_sprite_test() {
    scr_asset_define_sprite("TestSprite", global.sprite_channel, global.sprite_height, global.sprite_address, global.sprite_pixels, global.sprite_colour_r, global.sprite_colour_g, global.sprite_colour_b);

    with (obj_opcode_node) {
        instance_destroy();
    }

    with (obj_amiga_root_node) {
        instance_destroy();
    }

    var _init_x = (room_width / 2) - 260;
    var _init_y = room_height / 4;

    var _init_instance = instance_create_layer(_init_x, _init_y, "Instances", obj_amiga_root_node);
    _init_instance.root_type = "INIT";
    _init_instance.node_x = scr_snap_to_grid(_init_x, global.grid_size);
    _init_instance.node_y = scr_snap_to_grid(_init_y, global.grid_size);

    var _org_x = _init_instance.node_x + 240;
    var _org_y = _init_instance.node_y;

    var _org_instance = instance_create_layer(_org_x, _org_y, "Instances", obj_amiga_root_node);
    _org_instance.root_type = "ORG";
    _org_instance.node_x = scr_snap_to_grid(_org_x, global.grid_size);
    _org_instance.node_y = scr_snap_to_grid(_org_y, global.grid_size);
    // Link it now so an immediate F5 build includes the sprite macro. Do not
    // depend on the ORG Step event running before the manager's build handler.
    _org_instance.continues_from_root_uid = _init_instance.uid;

    var _init_cursor_y = _init_instance.node_y + _init_instance.node_height;

    var _dmacon_node = instance_create_layer(_init_instance.node_x, _init_cursor_y, "Instances", obj_opcode_node);
    _dmacon_node.node_x = _init_instance.node_x;
    _dmacon_node.node_y = _init_cursor_y;
    _dmacon_node.opcode_mnemonic = "MOVE";
    _dmacon_node.opcode_size = "W";
    _dmacon_node.addressing_mode_src = "#imm";
    _dmacon_node.operand_src = 32767;
    _dmacon_node.addressing_mode_dst = "abs.L";
    _dmacon_node.operand_dst = 14676118;
    _dmacon_node.is_connected = true;
    _dmacon_node.root_uid = _init_instance.uid;

    _init_cursor_y += _dmacon_node.node_height;

    var _intena_node = instance_create_layer(_init_instance.node_x, _init_cursor_y, "Instances", obj_opcode_node);
    _intena_node.node_x = _init_instance.node_x;
    _intena_node.node_y = _init_cursor_y;
    _intena_node.opcode_mnemonic = "MOVE";
    _intena_node.opcode_size = "W";
    _intena_node.addressing_mode_src = "#imm";
    _intena_node.operand_src = 32767;
    _intena_node.addressing_mode_dst = "abs.L";
    _intena_node.operand_dst = 14676122;
    _intena_node.is_connected = true;
    _intena_node.root_uid = _init_instance.uid;

    var _org_cursor_y = _org_instance.node_y + _org_instance.node_height;

    var _sprite_macro_node = instance_create_layer(_org_instance.node_x, _org_cursor_y, "Instances", obj_opcode_node);
    _sprite_macro_node.node_x = _org_instance.node_x;
    _sprite_macro_node.node_y = _org_cursor_y;
    _sprite_macro_node.node_height = 100;
    _sprite_macro_node.is_macro = true;
    _sprite_macro_node.macro_type = "SPRITE_DISPLAY";
    _sprite_macro_node.macro_asset_name = "TestSprite";
    _sprite_macro_node.is_connected = true;
    _sprite_macro_node.root_uid = _org_instance.uid;

    _org_cursor_y += _sprite_macro_node.node_height;

    var _nop_node = instance_create_layer(_org_instance.node_x, _org_cursor_y, "Instances", obj_opcode_node);
    _nop_node.node_x = _org_instance.node_x;
    _nop_node.node_y = _org_cursor_y;
    _nop_node.opcode_mnemonic = "NOP";
    _nop_node.node_label = "mainloop";
    _nop_node.is_connected = true;
    _nop_node.root_uid = _org_instance.uid;

    _org_cursor_y += _nop_node.node_height;

    var _bra_node = instance_create_layer(_org_instance.node_x, _org_cursor_y, "Instances", obj_opcode_node);
    _bra_node.node_x = _org_instance.node_x;
    _bra_node.node_y = _org_cursor_y;
    _bra_node.opcode_mnemonic = "BRA";
    _bra_node.opcode_size = "W";
    _bra_node.addressing_mode_src = "LABEL";
    _bra_node.operand_label_src = "mainloop";
    _bra_node.is_connected = true;
    _bra_node.root_uid = _org_instance.uid;

    scr_set_status_message("Sprite test loaded — channel " + string(global.sprite_channel) + ", " + string(global.sprite_height) + " rows.");
}
