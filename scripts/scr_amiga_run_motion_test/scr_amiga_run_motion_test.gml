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

    var _loop_node = instance_create_layer(_org.node_x, _cy, "Instances", obj_opcode_node);
    _loop_node.node_x = _org.node_x; _loop_node.node_y = _cy;
    _loop_node.node_label = "mainloop"; _loop_node.is_connected = true; _loop_node.root_uid = _org.uid;
    if (_macro_type == "SPRITE_BITMAP_TEST") {
        _loop_node.is_macro = true; _loop_node.macro_type = "MOVE_SPR"; _loop_node.node_height = 100;
        _loop_node.macro_object_id = 0; _loop_node.macro_speed_x = 1; _loop_node.macro_speed_y = 0;
    } else {
        _loop_node.opcode_mnemonic = "NOP";
    }
    _cy += _loop_node.node_height;
    if (_macro_type == "SPRITE_BITMAP_TEST") {
        var _anim_node = instance_create_layer(_org.node_x, _cy, "Instances", obj_opcode_node);
        _anim_node.node_x = _org.node_x; _anim_node.node_y = _cy; _anim_node.node_height = 120;
        _anim_node.is_macro = true; _anim_node.macro_type = "ANIM_SPR";
        _anim_node.macro_object_id = 0; _anim_node.macro_anim_rate = global.sprite_anim_rate;
        _anim_node.macro_anim_start = global.sprite_anim_start; _anim_node.macro_anim_end = global.sprite_anim_end;
        _anim_node.macro_anim_loop = global.sprite_anim_loop;
        _anim_node.is_connected = true; _anim_node.root_uid = _org.uid;
        _cy += _anim_node.node_height;
    }
    var _bra = instance_create_layer(_org.node_x, _cy, "Instances", obj_opcode_node);
    _bra.node_x = _org.node_x; _bra.node_y = _cy; _bra.opcode_mnemonic = "BRA"; _bra.opcode_size = "W";
    _bra.addressing_mode_src = "LABEL"; _bra.operand_label_src = "mainloop"; _bra.is_connected = true; _bra.root_uid = _org.uid;
    scr_set_status_message(_message);
}

function scr_amiga_run_bob_bitmap_test() {
    var _bob_name = global.current_bob_asset_name;
    var _bob = scr_asset_find_by_name(_bob_name);
    if (_bob == undefined || _bob.type != "BOB") {
        _bob_name = "TestBob";
        scr_asset_define_bob(_bob_name, 32, 32, array_create(1024, 0));
    }
    scr_amiga_get_shared_bitmap_palette();
    with (obj_opcode_node) instance_destroy();
    with (obj_amiga_root_node) instance_destroy();
    var _ix = (room_width / 2) - 320;
    var _iy = room_height / 4;
    var _init = instance_create_layer(_ix, _iy, "Instances", obj_amiga_root_node);
    _init.root_type = "INIT"; _init.node_x = scr_snap_to_grid(_ix, global.grid_size); _init.node_y = scr_snap_to_grid(_iy, global.grid_size);
    var _org = instance_create_layer(_init.node_x + 240, _init.node_y, "Instances", obj_amiga_root_node);
    _org.root_type = "ORG"; _org.node_x = scr_snap_to_grid(_init.node_x + 240, global.grid_size); _org.node_y = _init.node_y; _org.continues_from_root_uid = _init.uid;
    var _cy = _org.node_y + _org.node_height;
    var _types = ["GET_BITMAP_BOB", "DRAW_BOB", "REPLACE_BITMAP_BOB", "MOVE_BOB", "ANIM_BOB"];
    for (var _i = 0; _i < 5; _i += 1) {
        var _m = instance_create_layer(_org.node_x, _cy, "Instances", obj_opcode_node);
        _m.node_x = _org.node_x; _m.node_y = _cy; _m.node_height = 100; _m.is_macro = true;
        _m.macro_type = _types[_i]; _m.macro_asset_name = _bob_name; _m.is_connected = true; _m.root_uid = _org.uid;
        _m.macro_object_id = 0; _m.macro_speed_x = 1; _m.macro_speed_y = 0;
        if (_types[_i] == "ANIM_BOB") {
            _m.node_height = 120;
            _m.macro_anim_rate = global.current_bob_anim_rate;
            _m.macro_anim_start = global.current_bob_anim_start;
            _m.macro_anim_end = global.current_bob_anim_end;
            _m.macro_anim_loop = global.current_bob_anim_loop;
        }
        if (_i == 1) _m.node_label = "bobloop";
        _cy += _m.node_height;
    }
    var _bra = instance_create_layer(_org.node_x, _cy, "Instances", obj_opcode_node);
    _bra.node_x = _org.node_x; _bra.node_y = _cy; _bra.opcode_mnemonic = "BRA"; _bra.opcode_size = "W";
    _bra.addressing_mode_src = "LABEL"; _bra.operand_label_src = "bobloop"; _bra.is_connected = true; _bra.root_uid = _org.uid;
    scr_set_status_message("BOB-BMP test loaded — GetBitmap, ReplaceBitmap and DrawBOB are individually expandable.");
}

/// Pushes every node of root _root_uid at or below _y down by _dy.
function scr_amiga_motion_shift_column(_root_uid, _y, _dy) {
    with (obj_opcode_node) {
        if (is_connected && root_uid == _root_uid && node_y >= _y) node_y += _dy;
    }
}

/// With the BOB test loaded, T: SPR-BMP adds the sprite to that scene
/// instead of replacing it: SPRITE BITMAP TEST under GET BITMAP BOB (same
/// screen), MOVE SPR + ANIM SPR after REPLACE BITMAP BOB (same frame).
function scr_amiga_add_sprite_to_bob_scene() {
    var _get = noone;
    var _replace = noone;
    with (obj_opcode_node) {
        if (is_macro && macro_type == "GET_BITMAP_BOB" && is_connected) _get = id;
        if (is_macro && macro_type == "REPLACE_BITMAP_BOB" && is_connected) _replace = id;
    }
    if (_get == noone || _replace == noone) return false;
    scr_push_undo_snapshot();
    with (obj_opcode_node) if (is_macro && (macro_type == "SPRITE_BITMAP_TEST" || macro_type == "MOVE_SPR" || macro_type == "ANIM_SPR")) instance_destroy();

    var _root = _get.root_uid;
    var _x = _get.node_x;
    // SPRITE BITMAP TEST right under GET BITMAP BOB.
    var _at = _get.node_y + _get.node_height;
    scr_amiga_motion_shift_column(_root, _at, 100);
    var _spr = instance_create_layer(_x, _at, "Instances", obj_opcode_node);
    _spr.node_x = _x; _spr.node_y = _at; _spr.node_height = 100;
    _spr.is_macro = true; _spr.macro_type = "SPRITE_BITMAP_TEST"; _spr.macro_asset_name = global.sprite_asset_name;
    _spr.macro_object_id = 0; _spr.is_connected = true; _spr.root_uid = _root;

    // MOVE SPR and ANIM SPR right after REPLACE BITMAP BOB.
    _at = _replace.node_y + _replace.node_height;
    scr_amiga_motion_shift_column(_root, _at, 220);
    var _move = instance_create_layer(_x, _at, "Instances", obj_opcode_node);
    _move.node_x = _x; _move.node_y = _at; _move.node_height = 100;
    _move.is_macro = true; _move.macro_type = "MOVE_SPR"; _move.macro_object_id = 0;
    _move.macro_speed_x = 2; _move.macro_speed_y = 1;
    _move.is_connected = true; _move.root_uid = _root;
    var _anim = instance_create_layer(_x, _at + 100, "Instances", obj_opcode_node);
    _anim.node_x = _x; _anim.node_y = _at + 100; _anim.node_height = 120;
    _anim.is_macro = true; _anim.macro_type = "ANIM_SPR"; _anim.macro_object_id = 0;
    _anim.macro_anim_rate = global.sprite_anim_rate; _anim.macro_anim_start = global.sprite_anim_start;
    _anim.macro_anim_end = global.sprite_anim_end; _anim.macro_anim_loop = global.sprite_anim_loop;
    _anim.is_connected = true; _anim.root_uid = _root;
    scr_mark_workspace_dirty();
    scr_set_status_message("Sprite added to the BOB scene: same screen, moved by MOVE SPR in the same frame.");
    return true;
}

function scr_amiga_run_sprite_bitmap_test() {
    scr_asset_define_sprite(global.sprite_asset_name, global.sprite_channel, global.sprite_height, global.sprite_address, global.sprite_pixels, global.sprite_colour_r, global.sprite_colour_g, global.sprite_colour_b);
    scr_amiga_get_shared_bitmap_palette();
    if (scr_amiga_add_sprite_to_bob_scene()) return;
    scr_amiga_run_motion_test("SPRITE_BITMAP_TEST", global.sprite_asset_name, "SPR-BMP test loaded — MOVE_SPR controls its signed X/Y speed.");
}
