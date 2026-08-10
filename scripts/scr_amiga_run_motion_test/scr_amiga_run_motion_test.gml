/// Creates the minimal graph used by the two bitmap motion demonstrations.
function scr_amiga_run_motion_test(_macro_type, _asset_name, _message) {
    with (obj_opcode_node) instance_destroy();
    with (obj_amiga_root_node) instance_destroy();

    var _ix = (room_width / 2) - 260;
    var _iy = room_height / 4;
    var _init = instance_create_layer(_ix, _iy, "Instances", obj_amiga_root_node);
    _init.root_type = "INIT";
    _init.node_x = scr_snap_to_grid(_ix, global.grid_size);
    _init.node_y = scr_snap_to_grid(_iy, global.grid_size);

    var _org = instance_create_layer(_init.node_x + 240, _init.node_y, "Instances", obj_amiga_root_node);
    _org.root_type = "ORG";
    _org.node_x = scr_snap_to_grid(_init.node_x + 240, global.grid_size);
    _org.node_y = _init.node_y;
    _org.continues_from_root_uid = _init.uid;

    var _cy = _org.node_y + _org.node_height;
    var _macro = instance_create_layer(_org.node_x, _cy, "Instances", obj_opcode_node);
    _macro.node_x = _org.node_x; _macro.node_y = _cy; _macro.node_height = 100;
    _macro.is_macro = true; _macro.macro_type = _macro_type; _macro.macro_asset_name = _asset_name;
    _macro.is_connected = true; _macro.root_uid = _org.uid;
    _cy += _macro.node_height;

    var _nop = instance_create_layer(_org.node_x, _cy, "Instances", obj_opcode_node);
    _nop.node_x = _org.node_x; _nop.node_y = _cy; _nop.opcode_mnemonic = "NOP";
    _nop.node_label = "mainloop"; _nop.is_connected = true; _nop.root_uid = _org.uid;
    _cy += _nop.node_height;
    var _bra = instance_create_layer(_org.node_x, _cy, "Instances", obj_opcode_node);
    _bra.node_x = _org.node_x; _bra.node_y = _cy; _bra.opcode_mnemonic = "BRA"; _bra.opcode_size = "W";
    _bra.addressing_mode_src = "LABEL"; _bra.operand_label_src = "mainloop"; _bra.is_connected = true; _bra.root_uid = _org.uid;
    scr_set_status_message(_message);
}

function scr_amiga_run_bob_bitmap_test() {
    var _bob = scr_asset_find_by_name("TestBob");
    if (_bob == undefined || _bob.type != "BOB") scr_asset_define_bob("TestBob", 32, 32, array_create(1024, 0));
    scr_amiga_get_shared_bitmap_palette();
    scr_amiga_run_motion_test("BOB_BITMAP_TEST", "TestBob", "BOB-BMP test loaded — masked BOB, background restored, one pixel per frame.");
}

function scr_amiga_run_sprite_bitmap_test() {
    scr_asset_define_sprite("TestSprite", global.sprite_channel, global.sprite_height, global.sprite_address, global.sprite_pixels, global.sprite_colour_r, global.sprite_colour_g, global.sprite_colour_b);
    scr_amiga_get_shared_bitmap_palette();
    scr_amiga_run_motion_test("SPRITE_BITMAP_TEST", "TestSprite", "SPR-BMP test loaded — hardware sprite over bitmap, one pixel per frame.");
}
