/// @description TILES & MAPS window: tilesets, metatiles, tile maps, animation sets
// Full-screen modal editor for the Game Kit assets (scr_gamekit_assets).
// Every asset is looked up by name each Step (te_tileset / te_map /
// te_animset); the editor never keeps an asset struct between frames except
// as a cache key. Clickable buttons come from one list (te_controls) that
// Step (hit testing) and Draw both use, so they can never disagree.
depth = -400000;

// --- layout ---------------------------------------------------------------
panel_x = 16;
panel_y = 16;
panel_w = 1888;
panel_h = 1048;
header_h = 28;
content_y = panel_y + 72;          // top of the tab content
col_a_x = panel_x + 12;            // left column (lists)
col_a_w = 300;
row_h = 22;
grid_cell = 36;                    // tile grid cells (32 px tile + gap)

// TILES tab
pix_x = panel_x + 340;             // pixel editor box
pix_y = content_y + 10;
pix_box = 760;
tools_x = panel_x + 1130;          // right column of TILES / METATILES

// MAP tab
view_x = panel_x + 330;            // room view (one 320 x 256 screen)
view_y = content_y + 10;
view_zoom = 3;
map_col_x = panel_x + 1320;        // right column of MAP
map_col_w = 556;
nav_x = col_a_x;                   // room navigator
nav_y = content_y + 384;
nav_w = 300;
nav_h = 240;

// ANIMATIONS tab
anim_x = panel_x + 340;
anim_row_h = 214;
anim_preview_x = panel_x + 1500;

// --- state ----------------------------------------------------------------
tab = "TILES";                     // TILES, METATILES, MAP, ANIMATIONS
tab_ids = ["TILES", "METATILES", "MAP", "ANIMATIONS"];

ts_names = [];
map_names = [];
anim_names = [];
ts_name = "";
tile_sel = 1;
pal_sel = 1;
tool = "DRAW";                     // DRAW, LINE, RECT, FILL, PICK
tool_before_pick = "DRAW";
stroke_active = false;
stroke_button = mb_left;
stroke_colour = 1;
stroke_x0 = 0;
stroke_y0 = 0;
stroke_x1 = 0;
stroke_y1 = 0;
tile_undo = {};                    // "<tileset>#<tile>" -> { undo[], redo[] }
tile_undo_max = 16;

meta_name = "";
meta_tile = 1;                     // tile painted into metatiles
meta_painting = false;
meta_paint_button = mb_left;

map_name = "";
room_x = 0;
room_y = 0;
map_tool = "PAINT";                // PAINT, RECT, SPAWN, ENEMY
map_brush = "TILE";                // TILE or META
map_tile = 1;
map_meta = "";
show_grid = true;
show_flags = false;
map_drag = false;
map_drag_button = mb_left;
map_last_c = -1;
map_last_r = -1;
rect_c0 = 0;
rect_r0 = 0;
rect_c1 = 0;
rect_r1 = 0;
enemy_sel = -1;
enemy_animset = "";
enemy_speed = 2;
map_undo = [];
map_redo = [];
map_undo_name = "";
map_undo_max = 12;
hover_text = "";

anim_name = "";
anim_state = "idle";
anim_frame = -1;

list_scroll = { ts : 0, meta : 0, map : 0, anim : 0, mmeta : 0 };
grid_scroll = { tiles : 0, mpick : 0, picker : 0 };

// Modal dialog for NEW / RENAME / RESIZE / ADD FRAME ("" = none).
dlg_kind = "";
dlg_title = "";
dlg_has_name = false;
dlg_name = "";
dlg_old = "";
dlg_error = "";
dlg_size = 16;
dlg_w = 2;
dlg_h = 2;
dlg_tileset = "";
dlg_rx = 1;
dlg_ry = 1;
dlg_height = 24;
dlg_state = "idle";
dlg_list = [];
dlg_scroll = 0;
dlg_x = 630;
dlg_y = 330;
dlg_w_px = 660;
dlg_h_px = 340;

controls = [];

// --- caches (rebuilt in Draw; surfaces can be lost at any time) -----------
atlas_name = "";
atlas_ref = undefined;             // cache key only, never edited through
atlas_size = 0;
atlas_buffer = -1;
atlas_surface = -1;
atlas_full = true;
atlas_dirty_tiles = [];
atlas_upload = false;
atlas_avg = array_create(GK_MAX_TILES, $FF000000);
atlas_pal = array_create(16, $FF000000);

overview_buffer = -1;
overview_surface = -1;
overview_w = 0;
overview_h = 0;
overview_name = "";
overview_ref = undefined;
overview_dirty = true;
overview_timer = 0;
overview_upload = false;

sprite_cache = {};                 // sprite name -> { ref, surf }

flag_bits = [GK_FLAG_SOLID, GK_FLAG_PLATFORM, GK_FLAG_HAZARD, GK_FLAG_COLLECT, GK_FLAG_EXIT];
flag_labels = ["SOLID", "PLATFORM", "HAZARD", "COLLECT", "EXIT"];
flag_colours = [c_fuchsia, c_aqua, c_red, c_yellow, c_lime];

// --- lookups ------------------------------------------------------------------
te_tileset = function() { return scr_te_find("TILESET", ts_name); };
te_map = function() { return scr_te_find("TILEMAP", map_name); };
te_animset = function() { return scr_te_find("ANIMSET", anim_name); };
te_map_tileset = function() {
    var _map = te_map();
    return (_map == undefined) ? undefined : scr_te_find("TILESET", _map.tileset);
};
te_meta = function(_ts, _name) {
    var _i = scr_te_metatile_index(_ts, _name);
    return (_i < 0) ? undefined : _ts.metatiles[_i];
};
te_meta_names = function(_ts) {
    var _names = [];
    if (_ts == undefined) return _names;
    var _i = 0;
    while (_i < array_length(_ts.metatiles)) {
        array_push(_names, _ts.metatiles[_i].name);
        _i += 1;
    }
    return _names;
};

/// Rebuilds the name lists and keeps every selection valid.
te_refresh = function() {
    ts_names = scr_gk_asset_names("TILESET");
    map_names = scr_gk_asset_names("TILEMAP");
    anim_names = scr_gk_asset_names("ANIMSET");
    if (!array_contains(ts_names, ts_name)) {
        ts_name = array_length(ts_names) > 0 ? ts_names[0] : "";
        tile_sel = 1;
    }
    if (!array_contains(map_names, map_name)) {
        map_name = array_length(map_names) > 0 ? map_names[0] : "";
        room_x = 0;
        room_y = 0;
        enemy_sel = -1;
    }
    if (!array_contains(anim_names, anim_name)) {
        anim_name = array_length(anim_names) > 0 ? anim_names[0] : "";
        anim_frame = -1;
    }
    if (!array_contains(anim_names, enemy_animset)) enemy_animset = array_length(anim_names) > 0 ? anim_names[0] : "";

    var _ts = te_tileset();
    if (_ts != undefined) {
        tile_sel = clamp(tile_sel, 0, array_length(_ts.tiles) - 1);
        meta_tile = clamp(meta_tile, 0, array_length(_ts.tiles) - 1);
        if (scr_te_metatile_index(_ts, meta_name) < 0) meta_name = array_length(_ts.metatiles) > 0 ? _ts.metatiles[0].name : "";
    } else {
        meta_name = "";
    }
    var _map = te_map();
    if (_map != undefined) {
        room_x = clamp(room_x, 0, _map.rooms_x - 1);
        room_y = clamp(room_y, 0, _map.rooms_y - 1);
        if (enemy_sel >= array_length(_map.enemies)) enemy_sel = -1;
        var _mts = scr_te_find("TILESET", _map.tileset);
        if (_mts != undefined) {
            map_tile = clamp(map_tile, 0, array_length(_mts.tiles) - 1);
            if (scr_te_metatile_index(_mts, map_meta) < 0) {
                map_meta = array_length(_mts.metatiles) > 0 ? _mts.metatiles[0].name : "";
                if (map_meta == "") map_brush = "TILE";
            }
        }
        if (map_undo_name != map_name) {
            map_undo = [];
            map_redo = [];
            map_undo_name = map_name;
        }
    }
    var _set = te_animset();
    if (_set != undefined) {
        var _state = _set.states[$ anim_state];
        if (!is_struct(_state) || anim_frame >= array_length(_state.frames)) anim_frame = -1;
    }
};

// --- edits ----------------------------------------------------------------------
te_changed = function() { scr_mark_workspace_dirty(); };

te_tile_changed = function(_t) {
    array_push(atlas_dirty_tiles, _t);
    overview_dirty = true;
    scr_mark_workspace_dirty();
};

te_tileset_changed = function() {
    atlas_full = true;
    overview_dirty = true;
    scr_mark_workspace_dirty();
};

te_copy_array = function(_src) {
    var _out = array_create(array_length(_src), 0);
    array_copy(_out, 0, _src, 0, array_length(_src));
    return _out;
};

/// Saves the selected tile's pixels before an edit (Ctrl+Z restores them).
te_tile_push_undo = function(_ts) {
    if (tile_sel <= 0 || tile_sel >= array_length(_ts.tiles)) return;
    var _key = ts_name + "#" + string(tile_sel);
    var _entry = tile_undo[$ _key];
    if (_entry == undefined) _entry = { undo : [], redo : [] };
    array_push(_entry.undo, te_copy_array(_ts.tiles[tile_sel]));
    if (array_length(_entry.undo) > tile_undo_max) array_delete(_entry.undo, 0, 1);
    _entry.redo = [];
    tile_undo[$ _key] = _entry;
};

/// Tile undo (_redo false) or redo (_redo true) for the selected tile.
te_tile_undo = function(_redo) {
    var _ts = te_tileset();
    if (_ts == undefined || tile_sel <= 0 || tile_sel >= array_length(_ts.tiles)) return;
    var _entry = tile_undo[$ ts_name + "#" + string(tile_sel)];
    if (_entry == undefined) return;
    var _from = _redo ? _entry.redo : _entry.undo;
    var _to = _redo ? _entry.undo : _entry.redo;
    if (array_length(_from) == 0) return;
    var _pixels = array_pop(_from);
    if (array_length(_pixels) != array_length(_ts.tiles[tile_sel])) return;
    array_push(_to, te_copy_array(_ts.tiles[tile_sel]));
    array_copy(_ts.tiles[tile_sel], 0, _pixels, 0, array_length(_pixels));
    te_tile_changed(tile_sel);
    scr_set_status_message((_redo ? "Redo" : "Undo") + " tile " + string(tile_sel));
};

/// Saves the map's cells, enemies and spawn before an edit.
te_map_push_undo = function(_map) {
    array_push(map_undo, { cells : te_copy_array(_map.cells), enemies : variable_clone(_map.enemies),
        spawn_x : _map.spawn_x, spawn_y : _map.spawn_y, width : _map.width, height : _map.height });
    if (array_length(map_undo) > map_undo_max) array_delete(map_undo, 0, 1);
    map_redo = [];
    map_undo_name = map_name;
};

te_map_undo = function(_redo) {
    var _map = te_map();
    if (_map == undefined) return;
    var _from = _redo ? map_redo : map_undo;
    var _to = _redo ? map_undo : map_redo;
    if (array_length(_from) == 0) return;
    var _snap = array_pop(_from);
    if (_snap.width != _map.width || _snap.height != _map.height) return;
    array_push(_to, { cells : te_copy_array(_map.cells), enemies : variable_clone(_map.enemies),
        spawn_x : _map.spawn_x, spawn_y : _map.spawn_y, width : _map.width, height : _map.height });
    _map.cells = _snap.cells;
    _map.enemies = _snap.enemies;
    _map.spawn_x = _snap.spawn_x;
    _map.spawn_y = _snap.spawn_y;
    enemy_sel = -1;
    overview_dirty = true;
    scr_mark_workspace_dirty();
    scr_set_status_message((_redo ? "Redo" : "Undo") + " map edit");
};

// --- dialog -------------------------------------------------------------------
te_dialog_open = function(_kind, _title, _has_name, _name) {
    dlg_kind = _kind;
    dlg_title = _title;
    dlg_has_name = _has_name;
    dlg_name = _name;
    dlg_old = _name;
    dlg_error = "";
    dlg_scroll = 0;
    keyboard_string = "";
    stroke_active = false;
    map_drag = false;
    meta_painting = false;
};

te_dialog_close = function() {
    dlg_kind = "";
    dlg_error = "";
    keyboard_string = "";
};

// --- layout helpers -----------------------------------------------------------

/// Lists of the current tab: { id, x, y, w, rows, names, selected, title }.
te_lists = function() {
    var _list = [];
    var _ax = col_a_x;
    var _cy = content_y;
    switch (tab) {
        case "TILES":
            array_push(_list, { id : "ts", x : _ax, y : _cy + 24, w : col_a_w, rows : 8, names : ts_names, selected : ts_name, title : "TILESETS" });
            break;
        case "METATILES":
            array_push(_list, { id : "ts", x : _ax, y : _cy + 24, w : col_a_w, rows : 8, names : ts_names, selected : ts_name, title : "TILESETS" });
            array_push(_list, { id : "meta", x : _ax, y : _cy + 274, w : col_a_w, rows : 12, names : te_meta_names(te_tileset()), selected : meta_name, title : "METATILES" });
            break;
        case "MAP":
            array_push(_list, { id : "map", x : _ax, y : _cy + 24, w : col_a_w, rows : 8, names : map_names, selected : map_name, title : "MAPS" });
            if (te_map() == undefined) break;
            array_push(_list, { id : "mmeta", x : map_col_x, y : _cy + 452, w : map_col_w, rows : 5, names : te_meta_names(te_map_tileset()),
                selected : map_brush == "META" ? map_meta : "", title : "METATILE BRUSH" });
            break;
        case "ANIMATIONS":
            array_push(_list, { id : "anim", x : _ax, y : _cy + 24, w : col_a_w, rows : 12, names : anim_names, selected : anim_name, title : "ANIMATION SETS" });
            break;
    }
    return _list;
};

/// Tile grids of the current tab: { id, x, y, w, h, selected }.
te_grids = function() {
    var _grids = [];
    switch (tab) {
        case "TILES":
            array_push(_grids, { id : "tiles", x : col_a_x, y : content_y + 274, w : col_a_w, h : 540, selected : tile_sel });
            break;
        case "METATILES":
            array_push(_grids, { id : "mpick", x : tools_x, y : content_y + 40, w : 740, h : 612, selected : meta_tile });
            break;
        case "MAP":
            if (te_map() == undefined) break;
            array_push(_grids, { id : "picker", x : map_col_x, y : content_y + 104, w : map_col_w, h : 288, selected : map_brush == "TILE" ? map_tile : -1 });
            break;
    }
    return _grids;
};

/// Tile index under room point (_mx, _my) in grid _g of _ts, or -1.
te_grid_hit = function(_g, _ts, _mx, _my) {
    if (_ts == undefined || !point_in_rectangle(_mx, _my, _g.x, _g.y, _g.x + _g.w - 1, _g.y + _g.h - 1)) return -1;
    var _cols = max(1, _g.w div grid_cell);
    var _c = (_mx - _g.x) div grid_cell;
    var _r = (_my - _g.y) div grid_cell + grid_scroll[$ _g.id];
    if (_c >= _cols) return -1;
    var _t = _r * _cols + _c;
    return (_t < array_length(_ts.tiles)) ? _t : -1;
};

/// Pixel editor zoom for a tile size.
te_pix_zoom = function(_size) { return min(64, pix_box div max(1, _size)); };

/// Metatile editor cell size (screen px per tile) for _meta of _size px tiles.
te_meta_cell = function(_meta, _size) {
    var _zoom = clamp(min(pix_box div (_meta.w * _size), pix_box div (_meta.h * _size)), 1, 16);
    return _zoom * _size;
};

/// Button helper.
te_btn = function(_list, _id, _x1, _y1, _w, _h, _label, _on, _enabled, _arg = "") {
    array_push(_list, { id : _id, x1 : _x1, y1 : _y1, x2 : _x1 + _w, y2 : _y1 + _h, label : _label, on : _on, enabled : _enabled, arg : _arg });
};

/// Every clickable button of the window (only the dialog's while one is open).
te_controls = function(_dialog) {
    var _list = [];
    var _cy = content_y;
    var _ax = col_a_x;

    if (_dialog) {
        var _dx = dlg_x + 20;
        var _dy = dlg_y + 110;
        switch (dlg_kind) {
            case "ts_new":
                var _sizes = [8, 16, 24, 32];
                var _s = 0;
                while (_s < 4) {
                    te_btn(_list, "dlg_size", _dx + 130 + _s * 70, _dy, 62, 26, string(_sizes[_s]), dlg_size == _sizes[_s], true, string(_sizes[_s]));
                    _s += 1;
                }
                break;
            case "meta_new":
            case "meta_resize":
                var _mts = te_tileset();
                var _max = scr_te_metatile_max_tiles(_mts == undefined ? 16 : _mts.tile_size);
                te_btn(_list, "dlg_w_dn", _dx + 130, _dy, 26, 26, "<", false, dlg_w > 1);
                te_btn(_list, "dlg_w_up", _dx + 210, _dy, 26, 26, ">", false, dlg_w < _max);
                te_btn(_list, "dlg_h_dn", _dx + 130, _dy + 34, 26, 26, "<", false, dlg_h > 1);
                te_btn(_list, "dlg_h_up", _dx + 210, _dy + 34, 26, 26, ">", false, dlg_h < _max);
                break;
            case "map_new":
                te_btn(_list, "dlg_ts_prev", _dx + 130, _dy, 26, 26, "<", false, array_length(ts_names) > 1);
                te_btn(_list, "dlg_ts_next", _dx + 420, _dy, 26, 26, ">", false, array_length(ts_names) > 1);
                _dy += 34;
                te_btn(_list, "dlg_rx_dn", _dx + 130, _dy, 26, 26, "<", false, dlg_rx > 1);
                te_btn(_list, "dlg_rx_up", _dx + 210, _dy, 26, 26, ">", false, dlg_rx < GK_MAX_ROOMS_X);
                te_btn(_list, "dlg_ry_dn", _dx + 130, _dy + 34, 26, 26, "<", false, dlg_ry > 1);
                te_btn(_list, "dlg_ry_up", _dx + 210, _dy + 34, 26, 26, ">", false, dlg_ry < GK_MAX_ROOMS_Y);
                break;
            case "map_resize":
                te_btn(_list, "dlg_rx_dn", _dx + 130, _dy, 26, 26, "<", false, dlg_rx > 1);
                te_btn(_list, "dlg_rx_up", _dx + 210, _dy, 26, 26, ">", false, dlg_rx < GK_MAX_ROOMS_X);
                te_btn(_list, "dlg_ry_dn", _dx + 130, _dy + 34, 26, 26, "<", false, dlg_ry > 1);
                te_btn(_list, "dlg_ry_up", _dx + 210, _dy + 34, 26, 26, ">", false, dlg_ry < GK_MAX_ROOMS_Y);
                break;
            case "anim_new":
                te_btn(_list, "dlg_hgt_dn", _dx + 130, _dy, 26, 26, "<", false, dlg_height > 8);
                te_btn(_list, "dlg_hgt_up", _dx + 210, _dy, 26, 26, ">", false, dlg_height < 32);
                break;
        }
        var _by = dlg_y + dlg_h_px - 44;
        if (dlg_kind != "frame_pick") te_btn(_list, "dlg_ok", dlg_x + dlg_w_px - 236, _by, 104, 30, "OK", false, true);
        te_btn(_list, "dlg_cancel", dlg_x + dlg_w_px - 124, _by, 104, 30, dlg_kind == "frame_pick" ? "CLOSE" : "CANCEL", false, true);
        return _list;
    }

    te_btn(_list, "close", panel_x + panel_w - 26, panel_y + 4, 20, 20, "X", false, true);
    var _t = 0;
    while (_t < array_length(tab_ids)) {
        te_btn(_list, "tab", panel_x + 12 + _t * 196, panel_y + 36, 188, 28, tab_ids[_t], tab == tab_ids[_t], true, tab_ids[_t]);
        _t += 1;
    }

    var _ts = te_tileset();
    var _has_ts = _ts != undefined;
    switch (tab) {
        case "TILES":
            te_btn(_list, "ts_new", _ax, _cy + 208, 96, 26, "NEW", false, true);
            te_btn(_list, "ts_rename", _ax + 102, _cy + 208, 96, 26, "RENAME", false, _has_ts);
            te_btn(_list, "ts_delete", _ax + 204, _cy + 208, 96, 26, "DELETE", false, _has_ts);
            var _gy = _cy + 274 + 540 + 8;
            var _count = _has_ts ? array_length(_ts.tiles) : 0;
            te_btn(_list, "tile_add", _ax, _gy, 147, 26, "ADD TILE", false, _has_ts && _count < GK_MAX_TILES);
            te_btn(_list, "tile_dup", _ax + 153, _gy, 147, 26, "DUPLICATE", false, _has_ts && _count < GK_MAX_TILES);
            te_btn(_list, "tile_clear", _ax, _gy + 32, 147, 26, "CLEAR", false, _has_ts && tile_sel > 0);
            te_btn(_list, "tile_delete", _ax + 153, _gy + 32, 147, 26, "DELETE TILE", false, _has_ts && tile_sel > 0);
            if (!_has_ts) break;

            var _tools = ["DRAW", "LINE", "RECT", "FILL", "PICK"];
            var _i = 0;
            while (_i < 5) {
                te_btn(_list, "tool", tools_x + _i * 116, _cy + 10, 110, 28, _tools[_i], tool == _tools[_i], _has_ts, _tools[_i]);
                _i += 1;
            }
            te_btn(_list, "tile_undo", tools_x, _cy + 46, 110, 26, "UNDO", false, _has_ts && tile_sel > 0);
            te_btn(_list, "tile_redo", tools_x + 116, _cy + 46, 110, 26, "REDO", false, _has_ts && tile_sel > 0);
            te_btn(_list, "tile_prev", tools_x + 348, _cy + 46, 110, 26, "< TILE", false, _has_ts && tile_sel > 0);
            te_btn(_list, "tile_next", tools_x + 464, _cy + 46, 110, 26, "TILE >", false, _has_ts && tile_sel < _count - 1);
            var _rgb = ["R", "G", "B"];
            _i = 0;
            while (_i < 3) {
                var _ry = _cy + 252 + _i * 30;
                te_btn(_list, "rgb_dn", tools_x + 30, _ry, 24, 24, "<", false, _has_ts, _rgb[_i]);
                te_btn(_list, "rgb_up", tools_x + 360, _ry, 24, 24, ">", false, _has_ts, _rgb[_i]);
                _i += 1;
            }
            _i = 0;
            while (_i < 5) {
                var _flag_on = _has_ts && tile_sel > 0 && tile_sel < _count && (_ts.flags[tile_sel] & flag_bits[_i]) != 0;
                te_btn(_list, "flag", tools_x + _i * 146, _cy + 376, 140, 28, flag_labels[_i], _flag_on, _has_ts && tile_sel > 0, string(_i));
                _i += 1;
            }
            break;

        case "METATILES":
            var _meta_ok = _has_ts && scr_te_metatile_index(_ts, meta_name) >= 0;
            var _my = _cy + 274 + 12 * row_h + 8;
            te_btn(_list, "meta_new", _ax, _my, 147, 26, "NEW", false, _has_ts);
            te_btn(_list, "meta_rename", _ax + 153, _my, 147, 26, "RENAME", false, _meta_ok);
            te_btn(_list, "meta_resize", _ax, _my + 32, 147, 26, "RESIZE", false, _meta_ok);
            te_btn(_list, "meta_delete", _ax + 153, _my + 32, 147, 26, "DELETE", false, _meta_ok);
            break;

        case "MAP":
            var _map = te_map();
            var _has_map = _map != undefined;
            te_btn(_list, "map_new", _ax, _cy + 208, 96, 26, "NEW", false, true);
            te_btn(_list, "map_rename", _ax + 102, _cy + 208, 96, 26, "RENAME", false, _has_map);
            te_btn(_list, "map_delete", _ax + 204, _cy + 208, 96, 26, "DELETE", false, _has_map);
            te_btn(_list, "map_resize", _ax, _cy + 240, 147, 26, "RESIZE ROOMS", false, _has_map);
            if (!_has_map) break;
            var _nb = nav_y + nav_h + 8;
            te_btn(_list, "room_left", _ax, _nb, 70, 26, "<", false, _has_map && room_x > 0);
            te_btn(_list, "room_up", _ax + 76, _nb, 70, 26, "^", false, _has_map && room_y > 0);
            te_btn(_list, "room_down", _ax + 152, _nb, 70, 26, "v", false, _has_map && room_y < _map.rooms_y - 1);
            te_btn(_list, "room_right", _ax + 228, _nb, 72, 26, ">", false, _has_map && room_x < _map.rooms_x - 1);

            var _mtools = ["PAINT", "RECT", "SPAWN", "ENEMY"];
            var _k = 0;
            while (_k < 4) {
                te_btn(_list, "map_tool", map_col_x + _k * 140, _cy + 10, 134, 28, _mtools[_k], map_tool == _mtools[_k], _has_map, _mtools[_k]);
                _k += 1;
            }
            te_btn(_list, "grid", map_col_x, _cy + 46, 134, 26, "GRID " + (show_grid ? "ON" : "OFF"), show_grid, true);
            te_btn(_list, "flags", map_col_x + 140, _cy + 46, 134, 26, "FLAGS " + (show_flags ? "ON" : "OFF"), show_flags, true);
            te_btn(_list, "map_undo", map_col_x + 280, _cy + 46, 134, 26, "UNDO", false, array_length(map_undo) > 0);
            te_btn(_list, "map_redo", map_col_x + 420, _cy + 46, 134, 26, "REDO", false, array_length(map_redo) > 0);

            var _ey = _cy + 452 + 5 * row_h + 52;
            var _sel_ok = _has_map && enemy_sel >= 0 && enemy_sel < array_length(_map.enemies);
            te_btn(_list, "en_anim_prev", map_col_x + 120, _ey, 26, 26, "<", false, array_length(anim_names) > 1);
            te_btn(_list, "en_anim_next", map_col_x + 420, _ey, 26, 26, ">", false, array_length(anim_names) > 1);
            te_btn(_list, "en_speed_dn", map_col_x + 120, _ey + 34, 26, 26, "<", false, enemy_speed > 1);
            te_btn(_list, "en_speed_up", map_col_x + 220, _ey + 34, 26, 26, ">", false, enemy_speed < 4);
            te_btn(_list, "en_delete", map_col_x + 300, _ey + 34, 146, 26, "DELETE ENEMY", false, _sel_ok);
            break;

        case "ANIMATIONS":
            var _set = te_animset();
            var _has_set = _set != undefined;
            var _ly = _cy + 24 + 12 * row_h + 8;
            te_btn(_list, "anim_new", _ax, _ly, 96, 26, "NEW", false, true);
            te_btn(_list, "anim_rename", _ax + 102, _ly, 96, 26, "RENAME", false, _has_set);
            te_btn(_list, "anim_delete", _ax + 204, _ly, 96, 26, "DELETE", false, _has_set);
            if (_has_set) {
                var _states = GK_ANIM_STATES;
                var _s2 = 0;
                while (_s2 < 4) {
                    var _st = _states[_s2];
                    var _y0 = _cy + 10 + _s2 * anim_row_h;
                    var _state = _set.states[$ _st];
                    var _nf = is_struct(_state) ? array_length(_state.frames) : 0;
                    var _rate = is_struct(_state) ? _state.rate : 0;
                    var _sel_here = anim_state == _st && anim_frame >= 0 && anim_frame < _nf;
                    te_btn(_list, "rate_dn", anim_x + 130, _y0, 26, 26, "<", false, is_struct(_state) && _rate > 1, _st);
                    te_btn(_list, "rate_up", anim_x + 260, _y0, 26, 26, ">", false, is_struct(_state) && _rate < 50, _st);
                    te_btn(_list, "frame_add", anim_x, _y0 + 32, 124, 26, "ADD FRAME", false, is_struct(_state), _st);
                    te_btn(_list, "frame_new", anim_x + 130, _y0 + 32, 124, 26, "NEW FRAME", false, is_struct(_state), _st);
                    te_btn(_list, "frame_remove", anim_x + 260, _y0 + 32, 110, 26, "REMOVE", false, _sel_here, _st);
                    te_btn(_list, "frame_left", anim_x + 376, _y0 + 32, 40, 26, "<", false, _sel_here && anim_frame > 0, _st);
                    te_btn(_list, "frame_right", anim_x + 422, _y0 + 32, 40, 26, ">", false, _sel_here && anim_frame < _nf - 1, _st);
                    _s2 += 1;
                }
            }
            break;
    }
    return _list;
};

/// Room view cell size (screen px per tile).
te_view_cell = function(_size) { return _size * view_zoom; };

// --- render caches ---------------------------------------------------------------

/// Makes atlas_surface show _ts: tiles in a 16 x 16 grid of tile_size cells,
/// in the tileset's real palette. Returns false when nothing can be drawn.
te_atlas_prepare = function(_ts) {
    if (_ts == undefined) return false;
    var _size = _ts.tile_size;
    var _side = 16 * _size;
    if (_ts.name != atlas_name || _ts != atlas_ref || _size != atlas_size) atlas_full = true;
    if (!buffer_exists(atlas_buffer) || _size != atlas_size) {
        if (buffer_exists(atlas_buffer)) buffer_delete(atlas_buffer);
        atlas_buffer = buffer_create(_side * _side * 4, buffer_fixed, 1);
        atlas_full = true;
    }
    if (atlas_full) {
        var _p = 0;
        while (_p < 16) {
            atlas_pal[_p] = (_ts.colour_r[_p] * 17) | ((_ts.colour_g[_p] * 17) << 8) | ((_ts.colour_b[_p] * 17) << 16) | $FF000000;
            _p += 1;
        }
        buffer_fill(atlas_buffer, 0, buffer_u32, $FFFF00FF, _side * _side * 4);
        var _t = 0;
        while (_t < array_length(_ts.tiles)) {
            te_atlas_write_tile(_ts, _t);
            _t += 1;
        }
        atlas_dirty_tiles = [];
        atlas_full = false;
        atlas_name = _ts.name;
        atlas_ref = _ts;
        atlas_size = _size;
        atlas_upload = true;
        overview_dirty = true;
    } else if (array_length(atlas_dirty_tiles) > 0) {
        var _d = 0;
        while (_d < array_length(atlas_dirty_tiles)) {
            if (atlas_dirty_tiles[_d] < array_length(_ts.tiles)) te_atlas_write_tile(_ts, atlas_dirty_tiles[_d]);
            _d += 1;
        }
        atlas_dirty_tiles = [];
        atlas_upload = true;
    }
    if (surface_exists(atlas_surface) && surface_get_width(atlas_surface) != _side) surface_free(atlas_surface);
    if (!surface_exists(atlas_surface)) {
        atlas_surface = surface_create(_side, _side);
        atlas_upload = true;
    }
    if (atlas_upload) {
        buffer_set_surface(atlas_buffer, atlas_surface, 0);
        atlas_upload = false;
    }
    return true;
};

te_atlas_write_tile = function(_ts, _t) {
    var _size = _ts.tile_size;
    var _side = 16 * _size;
    var _ox = (_t mod 16) * _size;
    var _oy = (_t div 16) * _size;
    var _pixels = _ts.tiles[_t];
    var _sr = 0, _sg = 0, _sb = 0;
    var _y = 0;
    while (_y < _size) {
        var _row = ((_oy + _y) * _side + _ox) * 4;
        var _x = 0;
        while (_x < _size) {
            var _c = clamp(_pixels[_y * _size + _x], 0, 15);
            buffer_poke(atlas_buffer, _row + _x * 4, buffer_u32, atlas_pal[_c]);
            _sr += _ts.colour_r[_c];
            _sg += _ts.colour_g[_c];
            _sb += _ts.colour_b[_c];
            _x += 1;
        }
        _y += 1;
    }
    var _n = _size * _size * 15;
    atlas_avg[_t] = (round(_sr * 255 / _n)) | (round(_sg * 255 / _n) << 8) | (round(_sb * 255 / _n) << 16) | $FF000000;
};

/// Draws tile _t of the atlas (call te_atlas_prepare first) at _scale.
te_draw_tile = function(_ts, _t, _x, _y, _scale) {
    var _size = _ts.tile_size;
    if (_t < 0 || _t >= array_length(_ts.tiles) || !surface_exists(atlas_surface)) {
        draw_set_colour(c_fuchsia);
        draw_rectangle(_x, _y, _x + _size * _scale - 1, _y + _size * _scale - 1, false);
        return;
    }
    draw_surface_part_ext(atlas_surface, (_t mod 16) * _size, (_t div 16) * _size, _size, _size, _x, _y, _scale, _scale, c_white, draw_get_alpha());
};

/// Keeps overview_surface (one pixel per map cell, the tile's average colour) current.
te_overview_prepare = function(_map) {
    var _force = (_map.name != overview_name || _map != overview_ref || _map.width != overview_w || _map.height != overview_h);
    if (_force) {
        if (buffer_exists(overview_buffer)) buffer_delete(overview_buffer);
        overview_buffer = buffer_create(_map.width * _map.height * 4, buffer_fixed, 1);
        if (surface_exists(overview_surface)) surface_free(overview_surface);
        overview_w = _map.width;
        overview_h = _map.height;
        overview_name = _map.name;
        overview_ref = _map;
        overview_dirty = true;
        overview_timer = 0;
    }
    if (overview_dirty && overview_timer <= 0) {
        var _n = _map.width * _map.height;
        var _cells = _map.cells;
        if (array_length(_cells) >= _n) {
            var _i = 0;
            while (_i < _n) {
                var _t = _cells[_i];
                buffer_poke(overview_buffer, _i * 4, buffer_u32, (_t >= 0 && _t < GK_MAX_TILES) ? atlas_avg[_t] : $FFFF00FF);
                _i += 1;
            }
        }
        overview_dirty = false;
        overview_timer = 8;
        overview_upload = true;
    }
    overview_timer -= 1;
    if (!surface_exists(overview_surface)) {
        overview_surface = surface_create(max(1, overview_w), max(1, overview_h));
        overview_upload = true;
    }
    if (overview_upload) {
        buffer_set_surface(overview_buffer, overview_surface, 0);
        overview_upload = false;
    }
};

/// A 16 x height surface of SPRITE _name in its own 3 colours (-1 when missing).
te_sprite_surface = function(_name) {
    var _sprite = scr_te_find("SPRITE", _name);
    if (_sprite == undefined) return -1;
    var _entry = sprite_cache[$ _name];
    if (_entry == undefined || _entry.ref != _sprite || !surface_exists(_entry.surf)) {
        if (_entry != undefined && surface_exists(_entry.surf)) surface_free(_entry.surf);
        var _h = clamp(_sprite.height, 1, 64);
        var _buffer = buffer_create(16 * _h * 4, buffer_fixed, 1);
        var _pal = [0,
            (_sprite.colour_r[0] * 17) | ((_sprite.colour_g[0] * 17) << 8) | ((_sprite.colour_b[0] * 17) << 16) | $FF000000,
            (_sprite.colour_r[1] * 17) | ((_sprite.colour_g[1] * 17) << 8) | ((_sprite.colour_b[1] * 17) << 16) | $FF000000,
            (_sprite.colour_r[2] * 17) | ((_sprite.colour_g[2] * 17) << 8) | ((_sprite.colour_b[2] * 17) << 16) | $FF000000];
        var _i = 0;
        var _n = min(16 * _h, array_length(_sprite.pixels));
        while (_i < 16 * _h) {
            var _v = (_i < _n) ? clamp(_sprite.pixels[_i], 0, 3) : 0;
            buffer_poke(_buffer, _i * 4, buffer_u32, _pal[_v]);
            _i += 1;
        }
        var _surf = surface_create(16, _h);
        buffer_set_surface(_buffer, _surf, 0);
        buffer_delete(_buffer);
        _entry = { ref : _sprite, surf : _surf };
        sprite_cache[$ _name] = _entry;
    }
    return _entry.surf;
};

/// Room navigator geometry for _map: [x, y, room_w, room_h] (rooms keep 320:256).
te_nav_geom = function(_map) {
    var _rw = min(nav_w / _map.rooms_x, (nav_h / _map.rooms_y) * 1.25);
    var _rh = _rw * 0.8;
    return [nav_x + (nav_w - _rw * _map.rooms_x) / 2, nav_y + (nav_h - _rh * _map.rooms_y) / 2, _rw, _rh];
};

/// Height of the marker drawn for an enemy using ANIMSET _name.
te_enemy_height = function(_name) {
    var _set = scr_te_find("ANIMSET", _name);
    return (_set == undefined) ? 16 : clamp(_set.height, 8, 64);
};

/// Applies the open dialog (NEW / RENAME / RESIZE). Leaves it open with
/// dlg_error set when the input is not acceptable.
te_dialog_commit = function() {
    var _name = dlg_name;
    switch (dlg_kind) {
        case "ts_new":
            dlg_error = scr_te_name_error(_name, "");
            if (dlg_error != "") return;
            var _new_ts = scr_gk_tileset_define(_name, dlg_size);
            scr_gk_tileset_add_tile(_new_ts);
            ts_name = _name;
            tile_sel = 1;
            grid_scroll.tiles = 0;
            scr_set_status_message("New tileset " + _name + " (" + string(dlg_size) + " px tiles)", c_lime);
            break;

        case "ts_rename":
        case "map_rename":
        case "anim_rename":
            if (_name != dlg_old) {
                dlg_error = scr_te_asset_rename(dlg_old, _name);
                if (dlg_error != "") return;
                if (dlg_kind == "ts_rename") {
                    ts_name = _name;
                    tile_undo = {};
                    atlas_full = true;
                } else if (dlg_kind == "map_rename") {
                    map_name = _name;
                    map_undo_name = _name;
                } else {
                    anim_name = _name;
                    if (enemy_animset == dlg_old) enemy_animset = _name;
                }
                scr_set_status_message("Renamed " + dlg_old + " to " + _name, c_lime);
            }
            break;

        case "meta_new":
            var _mts = te_tileset();
            if (_mts == undefined) break;
            dlg_error = scr_te_metatile_name_error(_mts, _name, "");
            if (dlg_error != "") return;
            if (scr_gk_metatile_add(_mts, _name, dlg_w, dlg_h) == undefined) {
                dlg_error = "Metatiles are at most " + string(GK_METATILE_MAX_PX) + " x " + string(GK_METATILE_MAX_PX) + " px";
                return;
            }
            meta_name = _name;
            scr_set_status_message("New metatile " + _name, c_lime);
            break;

        case "meta_rename":
            var _rts = te_tileset();
            if (_rts == undefined) break;
            var _ri = scr_te_metatile_index(_rts, dlg_old);
            if (_ri < 0) break;
            if (_name != dlg_old) {
                dlg_error = scr_te_metatile_name_error(_rts, _name, dlg_old);
                if (dlg_error != "") return;
                _rts.metatiles[_ri].name = _name;
                meta_name = _name;
                if (map_meta == dlg_old) map_meta = _name;
                scr_set_status_message("Renamed metatile " + dlg_old + " to " + _name, c_lime);
            }
            break;

        case "meta_resize":
            var _zts = te_tileset();
            if (_zts == undefined) break;
            var _zmeta = te_meta(_zts, meta_name);
            if (_zmeta == undefined) break;
            if (!scr_te_metatile_resize(_zmeta, dlg_w, dlg_h, _zts.tile_size)) {
                dlg_error = "Metatiles are at most " + string(GK_METATILE_MAX_PX) + " x " + string(GK_METATILE_MAX_PX) + " px";
                return;
            }
            scr_set_status_message("Metatile " + meta_name + " is now " + string(dlg_w) + " x " + string(dlg_h) + " tiles", c_lime);
            break;

        case "map_new":
            if (scr_te_find("TILESET", dlg_tileset) == undefined) {
                dlg_error = "Make a tileset first (TILES tab)";
                return;
            }
            dlg_error = scr_te_name_error(_name, "");
            if (dlg_error != "") return;
            scr_gk_map_define(_name, dlg_tileset, dlg_rx, dlg_ry);
            map_name = _name;
            room_x = 0;
            room_y = 0;
            enemy_sel = -1;
            scr_set_status_message("New map " + _name + " (" + string(dlg_rx) + " x " + string(dlg_ry) + " rooms)", c_lime);
            break;

        case "map_resize":
            var _map = te_map();
            if (_map == undefined) break;
            var _mts2 = scr_te_find("TILESET", _map.tileset);
            var _size = (_mts2 != undefined) ? _mts2.tile_size : 320 div max(1, _map.room_cols);
            scr_te_map_resize(_map, dlg_rx, dlg_ry, _size);
            map_undo = [];
            map_redo = [];
            enemy_sel = -1;
            room_x = clamp(room_x, 0, _map.rooms_x - 1);
            room_y = clamp(room_y, 0, _map.rooms_y - 1);
            overview_dirty = true;
            scr_set_status_message("Map " + map_name + " is now " + string(_map.rooms_x) + " x " + string(_map.rooms_y) + " rooms", c_lime);
            break;

        case "anim_new":
            dlg_error = scr_te_name_error(_name, "");
            if (dlg_error != "") return;
            scr_gk_animset_define(_name, dlg_height);
            anim_name = _name;
            anim_frame = -1;
            scr_set_status_message("New animation set " + _name + " (" + string(dlg_height) + " px high)", c_lime);
            break;
    }
    te_changed();
    te_dialog_close();
    te_refresh();
};

te_refresh();
keyboard_string = "";
