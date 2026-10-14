/// @desc scr_tile_editor_selftest()
/// Unit test of the Tile & Map editor's data helpers (scr_tile_editor) on
/// the Game Kit model. Works on a private asset list and puts the real one
/// back afterwards. Returns an array of failure strings (empty = pass).
function scr_tile_editor_selftest() {
    var _fails = [];
    var _saved_assets = global.asset_list;
    global.asset_list = [];

    // Names.
    if (!scr_te_name_is_valid("Level_1")) array_push(_fails, "name Level_1 rejected");
    if (scr_te_name_is_valid("1Level")) array_push(_fails, "name 1Level accepted");
    if (scr_te_name_is_valid("a b")) array_push(_fails, "name with a space accepted");
    if (scr_te_name_is_valid("")) array_push(_fails, "empty name accepted");

    // Tileset with three tiles.
    scr_gk_tileset_define("te_tiles", 16);
    var _ts = scr_te_find("TILESET", "te_tiles");
    if (_ts == undefined) {
        array_push(_fails, "tileset not created");
        global.asset_list = _saved_assets;
        return _fails;
    }
    if (scr_te_name_error("te_tiles", "") == "") array_push(_fails, "duplicate asset name accepted");
    if (scr_te_unique_name("te_tiles") != "te_tiles2") array_push(_fails, "unique name not te_tiles2");
    var _t1 = scr_gk_tileset_add_tile(_ts);
    var _t2 = scr_gk_tileset_add_tile(_ts);
    var _t3 = scr_gk_tileset_add_tile(_ts);
    if (_t1 != 1 || _t2 != 2 || _t3 != 3) array_push(_fails, "tile indices not 1,2,3");
    _ts.flags[_t2] = GK_FLAG_SOLID;
    _ts.flags[_t3] = GK_FLAG_HAZARD;

    // Pixel tools; tile 0 stays empty.
    scr_te_tile_line(_ts, 1, 0, 0, 15, 15, 5);
    if (scr_gk_tile_get(_ts, 1, 7, 7) != 5 || scr_gk_tile_get(_ts, 1, 15, 15) != 5) array_push(_fails, "line not drawn");
    scr_te_tile_rect(_ts, 2, 2, 2, 5, 5, 3, false);
    if (scr_gk_tile_get(_ts, 2, 2, 4) != 3 || scr_gk_tile_get(_ts, 2, 3, 3) != 0) array_push(_fails, "rect outline wrong");
    scr_te_tile_fill(_ts, 2, 3, 3, 7);
    if (scr_gk_tile_get(_ts, 2, 4, 4) != 7 || scr_gk_tile_get(_ts, 2, 0, 0) != 0) array_push(_fails, "fill leaked or missed");
    scr_te_tile_line(_ts, 0, 0, 0, 3, 0, 9);
    scr_te_tile_fill(_ts, 0, 0, 0, 9);
    if (scr_gk_tile_get(_ts, 0, 0, 0) != 0) array_push(_fails, "tile 0 was painted");

    // Duplicate copies pixels and flags.
    var _dup = scr_te_tileset_duplicate_tile(_ts, 2);
    if (_dup != 4 || scr_gk_tile_get(_ts, 4, 4, 4) != 7 || _ts.flags[4] != GK_FLAG_SOLID) array_push(_fails, "duplicate tile wrong");
    _ts.tiles[4][0] = 1;
    if (scr_gk_tile_get(_ts, 2, 0, 0) != 0) array_push(_fails, "duplicate shares pixels with the original");

    // Metatile + resize.
    var _meta = scr_gk_metatile_add(_ts, "block", 2, 2);
    if (_meta == undefined) {
        array_push(_fails, "metatile not added");
    } else {
        _meta.cells = [1, 2, 3, 0];
        if (!scr_te_metatile_resize(_meta, 3, 2, 16)) array_push(_fails, "metatile resize 3x2 refused");
        if (_meta.w != 3 || array_length(_meta.cells) != 6 || _meta.cells[0] != 1 || _meta.cells[1] != 2 || _meta.cells[2] != 0 || _meta.cells[3] != 3) array_push(_fails, "metatile resize lost cells");
        if (scr_te_metatile_resize(_meta, 9, 1, 16)) array_push(_fails, "metatile 9 tiles of 16 px allowed");
        if (scr_te_metatile_index(_ts, "block") != 0) array_push(_fails, "metatile not found by name");
        if (scr_te_metatile_name_error(_ts, "block", "") == "") array_push(_fails, "duplicate metatile name accepted");
    }

    // Map, stamping and rectangles.
    scr_gk_map_define("te_map", "te_tiles", 2, 1);
    var _map = scr_te_find("TILEMAP", "te_map");
    if (_map == undefined) {
        array_push(_fails, "map not created");
    } else {
        if (_map.room_cols != 20 || _map.room_rows != 16 || _map.width != 40) array_push(_fails, "map size wrong");
        // Stamp at the right edge of room 0: column 19 inside, column 20+ clipped.
        if (_meta != undefined) {
            scr_te_map_stamp_clipped(_map, _meta, 19, 0, 0, 0, 19, 15, true);
            if (scr_gk_map_get(_map, 19, 0) != 1 || scr_gk_map_get(_map, 20, 0) != 0 || scr_gk_map_get(_map, 19, 1) != 3) array_push(_fails, "clipped stamp wrong");
            scr_gk_map_set(_map, 5, 5, 4);
            scr_te_map_stamp_clipped(_map, _meta, 4, 4, 0, 0, 19, 15, true);
            if (scr_gk_map_get(_map, 5, 5) != 4) array_push(_fails, "transparent stamp cell overwrote the map");
        }
        scr_te_map_fill_rect(_map, 2, 10, 4, 11, 2, undefined);
        if (scr_gk_map_get(_map, 3, 11) != 2 || scr_gk_map_get(_map, 5, 11) != 0) array_push(_fails, "rect fill wrong");

        // Enemies: per-room limit.
        scr_gk_animset_define("te_walker", 16);
        var _e = 0;
        var _added = 0;
        while (_e < GK_ENEMIES_PER_ROOM + 2) {
            if (scr_te_map_add_enemy(_map, 16, _e, 2, "te_walker", 2) >= 0) _added += 1;
            _e += 1;
        }
        if (_added != GK_ENEMIES_PER_ROOM) array_push(_fails, "enemy room limit not enforced (" + string(_added) + ")");
        if (scr_te_map_add_enemy(_map, 16, 25, 2, "te_walker", 9) < 0) array_push(_fails, "enemy refused in the empty room 1");
        if (_map.enemies[array_length(_map.enemies) - 1].speed != 4) array_push(_fails, "enemy speed not clamped");
        if (scr_te_map_enemy_at(_map, 16 + 3, 32 + 3, 16) != 1) array_push(_fails, "enemy hit test wrong");

        // Delete tile 2: cells of tile 2 -> 0, tiles 3 and 4 shift down.
        scr_gk_map_set(_map, 0, 15, 3);
        scr_gk_map_set(_map, 1, 15, 4);
        if (!scr_te_tileset_delete_tile(_ts, 2)) array_push(_fails, "tile 2 not deleted");
        if (array_length(_ts.tiles) != 4 || array_length(_ts.flags) != 4) array_push(_fails, "tile count after delete wrong");
        if (_ts.flags[1] != 0 || _ts.flags[2] != GK_FLAG_HAZARD || _ts.flags[3] != GK_FLAG_SOLID) array_push(_fails, "flags not shifted after delete");
        if (scr_gk_map_get(_map, 3, 11) != 0) array_push(_fails, "deleted tile still on the map");
        if (scr_gk_map_get(_map, 0, 15) != 2 || scr_gk_map_get(_map, 1, 15) != 3 || scr_gk_map_get(_map, 5, 5) != 3) array_push(_fails, "map not renumbered after delete");
        if (scr_gk_map_get(_map, 19, 0) != 1) array_push(_fails, "tile 1 changed by deleting tile 2");
        if (_meta != undefined && (_meta.cells[0] != 1 || _meta.cells[1] != 0 || _meta.cells[3] != 2)) array_push(_fails, "metatile not renumbered after delete");
        if (scr_te_tileset_delete_tile(_ts, 0)) array_push(_fails, "tile 0 deleted");

        // Resize rooms: keeps cells, drops enemies outside, clamps spawn.
        _map.spawn_x = 600;
        scr_te_map_resize(_map, 1, 2, 16);
        if (_map.width != 20 || _map.height != 32 || array_length(_map.cells) != 640) array_push(_fails, "map resize size wrong");
        if (scr_gk_map_get(_map, 19, 0) != 1 || scr_gk_map_get(_map, 0, 15) != 2) array_push(_fails, "map resize lost cells");
        if (array_length(_map.enemies) != GK_ENEMIES_PER_ROOM) array_push(_fails, "enemy outside the resized map kept");
        if (_map.spawn_x > 320 - 16) array_push(_fails, "spawn not clamped after resize");

        // Rename follows references.
        if (scr_te_asset_rename("te_tiles", "te_tiles_b") != "") array_push(_fails, "tileset rename failed");
        if (_map.tileset != "te_tiles_b") array_push(_fails, "map tileset not renamed");
        if (scr_te_asset_rename("te_walker", "te_runner") != "" || _map.enemies[0].animset != "te_runner") array_push(_fails, "enemy animset not renamed");
        if (scr_te_asset_rename("te_runner", "te_map") == "") array_push(_fails, "rename onto an existing name accepted");
        if (scr_te_maps_using_tileset("te_tiles_b") != 1) array_push(_fails, "maps using tileset count wrong");
        // te_runner has no frames yet, so the map must report a problem.
        if (scr_gk_map_problem(_map) == "") array_push(_fails, "map problem missed an animation set without frames");
    }

    // Animation frames.
    var _set = scr_gk_animset_define("te_hero", 24);
    var _frame = scr_te_animset_new_frame(_set, "run");
    var _sprite = scr_te_find("SPRITE", _frame);
    if (_frame != "te_hero_run_1" || _sprite == undefined || _sprite.height != 24 || array_length(_sprite.pixels) != 16 * 24) array_push(_fails, "new frame wrong (" + _frame + ")");
    if (_sprite != undefined) {
        _sprite.colour_r[0] = 3;
        var _frame2 = scr_te_animset_new_frame(_set, "idle");
        var _sprite2 = scr_te_find("SPRITE", _frame2);
        if (_sprite2 == undefined || _sprite2.colour_r[0] != 3) array_push(_fails, "new frame did not copy the set's colours");
    }
    if (array_length(scr_te_sprite_names_of_height(24)) != 2) array_push(_fails, "sprite list by height wrong");

    global.asset_list = _saved_assets;
    return _fails;
}
