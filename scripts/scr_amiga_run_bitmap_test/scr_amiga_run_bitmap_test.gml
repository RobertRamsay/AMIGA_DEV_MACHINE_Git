/// @desc scr_amiga_run_bitmap_test()
/// Replaces the graph with a minimal current-bitmap display test.
function scr_amiga_run_bitmap_test() {
    with (obj_opcode_node) instance_destroy();
    with (obj_amiga_root_node) instance_destroy();

    var _init_x = (room_width / 2) - 260;
    var _init_y = room_height / 4;
    var _init = instance_create_layer(_init_x, _init_y, "Instances", obj_amiga_root_node);
    _init.root_type = "INIT";
    _init.node_x = scr_snap_to_grid(_init_x, global.grid_size);
    _init.node_y = scr_snap_to_grid(_init_y, global.grid_size);

    var _org_x = _init.node_x + 240;
    var _org = instance_create_layer(_org_x, _init.node_y, "Instances", obj_amiga_root_node);
    _org.root_type = "ORG";
    _org.node_x = scr_snap_to_grid(_org_x, global.grid_size);
    _org.node_y = _init.node_y;
    _org.continues_from_root_uid = _init.uid;

    var _cursor_y = _org.node_y + _org.node_height;
    var _macro = instance_create_layer(_org.node_x, _cursor_y, "Instances", obj_opcode_node);
    _macro.node_x = _org.node_x;
    _macro.node_y = _cursor_y;
    _macro.node_height = 100;
    _macro.is_macro = true;
    _macro.macro_type = "BITMAP_DISPLAY";
    _macro.macro_asset_name = "TestBitmap";
    _macro.is_connected = true;
    _macro.root_uid = _org.uid;
    _cursor_y += _macro.node_height;

    var _nop = instance_create_layer(_org.node_x, _cursor_y, "Instances", obj_opcode_node);
    _nop.node_x = _org.node_x;
    _nop.node_y = _cursor_y;
    _nop.opcode_mnemonic = "NOP";
    _nop.node_label = "mainloop";
    _nop.is_connected = true;
    _nop.root_uid = _org.uid;
    _cursor_y += _nop.node_height;

    var _bra = instance_create_layer(_org.node_x, _cursor_y, "Instances", obj_opcode_node);
    _bra.node_x = _org.node_x;
    _bra.node_y = _cursor_y;
    _bra.opcode_mnemonic = "BRA";
    _bra.opcode_size = "W";
    _bra.addressing_mode_src = "LABEL";
    _bra.operand_label_src = "mainloop";
    _bra.is_connected = true;
    _bra.root_uid = _org.uid;

    scr_set_status_message("Bitmap test loaded — 320x256, five bitplanes, 32 colours. Press F5 to run.");
}
