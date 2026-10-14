/// @desc EDIT buttons on graphics nodes: open the editor of the graphic a node
/// uses, with that graphic selected. obj_opcode_node Step / Draw place the
/// buttons (scr_node_edit_row_y); Game Kit nodes use the same helpers from
/// scr_gk_node_ui.
///
///   BITMAP_DISPLAY                         -> bitmap editor (TestBitmap)
///   SPRITE_DISPLAY, SPRITE_BITMAP_TEST     -> SPR-EDIT on the node's sprite
///   GET_BITMAP_BOB, DRAW_BOB,
///   REPLACE_BITMAP_BOB, BOB_BITMAP_TEST    -> BOB editor on the node's BOB
///   ANIM_SPR / ANIM_BOB                    -> SPR-EDIT / BOB editor on the START frame
///   GK_MAP                                 -> TILE-EDIT, Map tab, the node's map
///   GK_PLAYER                              -> TILE-EDIT, Animations tab, the node's set

/// "" when the node has no graphic to edit, else what the button opens.
function scr_node_edit_kind(_node) {
    if (!_node.is_macro) return "";
    switch (_node.macro_type) {
        case "BITMAP_DISPLAY": return "bitmap";
        case "SPRITE_DISPLAY":
        case "SPRITE_BITMAP_TEST": return "sprite";
        case "GET_BITMAP_BOB":
        case "DRAW_BOB":
        case "REPLACE_BITMAP_BOB":
        case "BOB_BITMAP_TEST": return "bob";
        case "ANIM_SPR": return "sprite_anim";
        case "ANIM_BOB": return "bob_anim";
        case "GK_MAP": return "map";
        case "GK_PLAYER": return "hero";
    }
    return "";
}

/// Button label for the node's EDIT button.
function scr_node_edit_label(_node) {
    switch (scr_node_edit_kind(_node)) {
        case "bitmap": return "EDIT BITMAP";
        case "sprite": return "EDIT SPRITE";
        case "bob": return "EDIT BOB";
        case "sprite_anim":
        case "bob_anim": return "EDIT FRAMES";
        case "map": return "EDIT MAP";
        case "hero": return "EDIT HERO";
    }
    return "";
}

/// World y of the 20 px row holding a classic graphics node's EDIT button
/// (ANIM nodes share their LOOP row: LOOP left half, EDIT right half).
function scr_node_edit_row_y(_node) {
    switch (scr_node_edit_kind(_node)) {
        case "bitmap": return _node.node_y + 60;
        case "sprite":
        case "bob": return _node.node_y + 80;
        case "sprite_anim":
        case "bob_anim": return _node.node_y + 100;
    }
    return _node.node_y + _node.node_height - 20;
}

/// Draws the node's EDIT button across _x1.._x2 in the 20 px row at screen y _ry.
function scr_node_edit_draw_button(_node, _x1, _x2, _ry) {
    var _y1 = _ry + 2;
    var _y2 = _ry + 18;
    var _hover = point_in_rectangle(mouse_x, mouse_y, _x1, _y1, _x2, _y2) && !scr_amiga_modal_open();
    var _label = scr_node_edit_label(_node);
    if (string_width(_label) > _x2 - _x1 - 10) _label = "EDIT";
    scr_ui_button(_x1, _y1, _x2, _y2, _label, make_colour_rgb(25, 95, 100), _hover);
}

/// Opens the node's graphic in its editor.
function scr_node_edit_open(_node) {
    switch (scr_node_edit_kind(_node)) {
        case "bitmap":
            scr_bitmap_editor_open();
            break;
        case "sprite":
            scr_sprite_editor_open_on(_node.macro_asset_name);
            break;
        case "bob":
            scr_bob_editor_open_on(_node.macro_asset_name);
            break;
        case "sprite_anim":
            scr_sprite_editor_open_on(scr_node_edit_frame_name("SPRITE", _node.macro_anim_start));
            break;
        case "bob_anim":
            scr_bob_editor_open_on(scr_node_edit_frame_name("BOB", _node.macro_anim_start));
            break;
        case "map":
            scr_tile_editor_open_on("MAP", _node.macro_asset_name);
            break;
        case "hero":
            scr_tile_editor_open_on("ANIMATIONS", _node.macro_asset_name);
            break;
    }
}

/// Name of frame _index of the ANIM nodes' frame list (every asset of _type
/// in asset-list order, as scr_emit_macro_anim_bob / _spr count them).
function scr_node_edit_frame_name(_type, _index) {
    var _count = 0;
    var _last = "";
    var _i = 0;
    while (_i < array_length(global.asset_list)) {
        if (global.asset_list[_i].type == _type) {
            if (_count == _index) return global.asset_list[_i].name;
            _last = global.asset_list[_i].name;
            _count += 1;
        }
        _i += 1;
    }
    return _last;
}

/// The bitmap editor (it always edits TestBitmap, the shared screen).
function scr_bitmap_editor_open() {
    mouse_clear(mb_left);
    if (instance_exists(obj_bitmap_editor)) return instance_find(obj_bitmap_editor, 0);
    return instance_create_layer(0, 0, "Instances", obj_bitmap_editor);
}

/// The BOB editor with BOB _name selected (the current one when not found).
function scr_bob_editor_open_on(_name) {
    mouse_clear(mb_left);
    var _editor = instance_exists(obj_bob_editor) ? instance_find(obj_bob_editor, 0) : instance_create_layer(0, 0, "Instances", obj_bob_editor);
    var _asset = scr_asset_find_by_name(_name);
    if (_asset != undefined && _asset.type == "BOB") {
        with (_editor) {
            bob_anim_playing = false;
            bob_commit();
            bob_rebuild_asset_names();
            var _i = 0;
            while (_i < array_length(bob_asset_names)) {
                if (bob_asset_names[_i] == _name) bob_asset_index = _i;
                _i += 1;
            }
            bob_load_asset(_name);
        }
    } else if (_name != "") {
        scr_set_status_message("BOB '" + _name + "' not found - the BOB editor shows " + _editor.bob_asset_name + ".", c_orange);
    }
    return _editor;
}

/// The SPR-EDIT panel with sprite _name selected (the current one when not found).
function scr_sprite_editor_open_on(_name) {
    mouse_clear(mb_left);
    with (obj_amiga_manager) {
        if (global.sprite_editor_open) sprite_editor_commit_asset();
        global.sprite_editor_open = true;
        global.sprite_anim_playing = false;
        sprite_editor_rebuild_assets();
        var _index = -1;
        var _i = 0;
        while (_i < array_length(global.sprite_asset_names)) {
            if (global.sprite_asset_names[_i] == _name) _index = _i;
            if (_index < 0 && global.sprite_asset_names[_i] == global.sprite_asset_name) _index = _i;
            _i += 1;
        }
        if (array_length(global.sprite_asset_names) > 0) {
            global.sprite_asset_index = max(0, _index);
            sprite_editor_load_asset(global.sprite_asset_names[global.sprite_asset_index]);
        }
    }
    if (_name != "" && global.sprite_asset_name != _name) scr_set_status_message("Sprite '" + _name + "' not found - SPR-EDIT shows " + global.sprite_asset_name + ".", c_orange);
}

/// TILE-EDIT on tab _tab ("MAP" / "ANIMATIONS") with map / animation set _name.
function scr_tile_editor_open_on(_tab, _name) {
    mouse_clear(mb_left);
    var _editor = scr_tile_editor_open();
    with (_editor) {
        te_refresh();
        tab = _tab;
        stroke_active = false;
        map_drag = false;
        meta_painting = false;
        if (_tab == "MAP" && array_contains(map_names, _name)) {
            if (map_name != _name) {
                room_x = 0;
                room_y = 0;
                enemy_sel = -1;
            }
            map_name = _name;
            // Paint with the map's own tileset.
            var _map = scr_te_find("TILEMAP", _name);
            if (_map != undefined && array_contains(ts_names, _map.tileset)) ts_name = _map.tileset;
        }
        if (_tab == "ANIMATIONS" && array_contains(anim_names, _name)) {
            anim_name = _name;
            anim_frame = -1;
        }
        te_refresh();
        controls = te_controls(false);
    }
    return _editor;
}
