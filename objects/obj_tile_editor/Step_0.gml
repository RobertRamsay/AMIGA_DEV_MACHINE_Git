te_refresh();
hover_text = "";
var _ctrl = keyboard_check(vk_control);
var _shift = keyboard_check(vk_shift);

// --- keyboard: dialog text field, Esc ---------------------------------------
if (dlg_kind != "") {
    if (dlg_has_name && keyboard_string != "") {
        var _typed = keyboard_string;
        var _t = 1;
        while (_t <= string_length(_typed)) {
            var _ch = string_char_at(_typed, _t);
            var _code = ord(_ch);
            var _ok = (_code >= 65 && _code <= 90) || (_code >= 97 && _code <= 122) || (_code >= 48 && _code <= 57) || _code == 95;
            if (_ok && string_length(dlg_name) < 32) dlg_name += _ch;
            _t += 1;
        }
        dlg_error = "";
    }
    keyboard_string = "";
    if (dlg_has_name && keyboard_check_pressed(vk_backspace) && string_length(dlg_name) > 0) {
        dlg_name = string_delete(dlg_name, string_length(dlg_name), 1);
        dlg_error = "";
    }
    if (keyboard_check_pressed(vk_escape)) {
        te_dialog_close();
        exit;
    }
    if (keyboard_check_pressed(vk_enter) && dlg_kind != "frame_pick") {
        te_dialog_commit();
        exit;
    }
} else if (keyboard_check_pressed(vk_escape)) {
    if (stroke_active || map_drag || meta_painting) {
        // Esc first cancels a line / rectangle being dragged.
        stroke_active = false;
        map_drag = false;
        meta_painting = false;
    } else {
        instance_destroy();
        exit;
    }
}

// --- keyboard shortcuts (no dialog) -----------------------------------------
if (dlg_kind == "") {
    var _undo = _ctrl && keyboard_check_pressed(ord("Z")) && !_shift;
    var _redo = _ctrl && (keyboard_check_pressed(ord("Y")) || (keyboard_check_pressed(ord("Z")) && _shift));
    if (tab == "TILES") {
        if (_undo) te_tile_undo(false);
        if (_redo) te_tile_undo(true);
        if (!_ctrl && !stroke_active) {
            if (keyboard_check_pressed(ord("D"))) tool = "DRAW";
            if (keyboard_check_pressed(ord("L"))) tool = "LINE";
            if (keyboard_check_pressed(ord("R"))) tool = "RECT";
            if (keyboard_check_pressed(ord("F"))) tool = "FILL";
            if (keyboard_check_pressed(ord("P")) && tool != "PICK") {
                tool_before_pick = tool;
                tool = "PICK";
            }
        }
    } else if (tab == "MAP") {
        if (_undo) te_map_undo(false);
        if (_redo) te_map_undo(true);
        var _kmap = te_map();
        if (_kmap != undefined && !map_drag) {
            var _room_index = room_y * _kmap.rooms_x + room_x;
            var _rooms = _kmap.rooms_x * _kmap.rooms_y;
            if (keyboard_check_pressed(vk_pageup)) _room_index = max(0, _room_index - 1);
            if (keyboard_check_pressed(vk_pagedown)) _room_index = min(_rooms - 1, _room_index + 1);
            room_x = _room_index mod _kmap.rooms_x;
            room_y = _room_index div _kmap.rooms_x;
            if (_ctrl) {
                if (keyboard_check_pressed(vk_left)) room_x = max(0, room_x - 1);
                if (keyboard_check_pressed(vk_right)) room_x = min(_kmap.rooms_x - 1, room_x + 1);
                if (keyboard_check_pressed(vk_up)) room_y = max(0, room_y - 1);
                if (keyboard_check_pressed(vk_down)) room_y = min(_kmap.rooms_y - 1, room_y + 1);
            } else {
                if (keyboard_check_pressed(ord("G"))) show_grid = !show_grid;
            }
            if (keyboard_check_pressed(vk_delete) && enemy_sel >= 0 && enemy_sel < array_length(_kmap.enemies)) {
                te_map_push_undo(_kmap);
                array_delete(_kmap.enemies, enemy_sel, 1);
                enemy_sel = -1;
                te_changed();
                scr_set_status_message("Enemy removed");
            }
        }
    }
}

var _mx = mouse_x;
var _my = mouse_y;
var _lp = mouse_check_button_pressed(mb_left);
var _rp = mouse_check_button_pressed(mb_right);
var _wheel = mouse_wheel_down() - mouse_wheel_up();

controls = te_controls(dlg_kind != "");
// The editor tour is presenting this screen: its input belongs to the tour.
if (instance_exists(obj_editor_tour)) exit;
var _clicked = "";
var _arg = "";
if (_lp) {
    var _i = 0;
    while (_i < array_length(controls)) {
        var _c = controls[_i];
        if (_c.enabled && point_in_rectangle(_mx, _my, _c.x1, _c.y1, _c.x2, _c.y2)) {
            _clicked = _c.id;
            _arg = _c.arg;
        }
        _i += 1;
    }
}

// --- dialog -------------------------------------------------------------------
if (dlg_kind != "") {
    switch (_clicked) {
        case "dlg_ok": te_dialog_commit(); break;
        case "dlg_cancel": te_dialog_close(); break;
        case "dlg_size": dlg_size = real(_arg); break;
        case "dlg_w_dn": dlg_w -= 1; break;
        case "dlg_w_up": dlg_w += 1; break;
        case "dlg_h_dn": dlg_h -= 1; break;
        case "dlg_h_up": dlg_h += 1; break;
        case "dlg_rx_dn": dlg_rx -= 1; break;
        case "dlg_rx_up": dlg_rx += 1; break;
        case "dlg_ry_dn": dlg_ry -= 1; break;
        case "dlg_ry_up": dlg_ry += 1; break;
        case "dlg_hgt_dn": dlg_height -= _shift ? 4 : 1; break;
        case "dlg_hgt_up": dlg_height += _shift ? 4 : 1; break;
        case "dlg_ts_prev":
        case "dlg_ts_next":
            var _n = array_length(ts_names);
            if (_n > 0) {
                var _at = 0;
                var _k = 0;
                while (_k < _n) {
                    if (ts_names[_k] == dlg_tileset) _at = _k;
                    _k += 1;
                }
                _at = (_at + (_clicked == "dlg_ts_next" ? 1 : -1) + _n) mod _n;
                dlg_tileset = ts_names[_at];
            }
            break;
    }
    dlg_height = clamp(dlg_height, 8, 32);
    dlg_rx = clamp(dlg_rx, 1, GK_MAX_ROOMS_X);
    dlg_ry = clamp(dlg_ry, 1, GK_MAX_ROOMS_Y);
    dlg_w = max(1, dlg_w);
    dlg_h = max(1, dlg_h);

    if (dlg_kind == "frame_pick") {
        var _lx = dlg_x + 20;
        var _ly = dlg_y + 70;
        var _rows = 9;
        if (point_in_rectangle(_mx, _my, _lx, _ly, _lx + dlg_w_px - 40, _ly + _rows * row_h - 1)) {
            if (_wheel != 0) dlg_scroll = clamp(dlg_scroll + _wheel, 0, max(0, array_length(dlg_list) - _rows));
            var _row = (_my - _ly) div row_h + dlg_scroll;
            if (_lp && _row < array_length(dlg_list)) {
                var _pset = te_animset();
                if (_pset != undefined && is_struct(_pset.states[$ dlg_state])) {
                    array_push(_pset.states[$ dlg_state].frames, dlg_list[_row]);
                    anim_state = dlg_state;
                    anim_frame = array_length(_pset.states[$ dlg_state].frames) - 1;
                    te_changed();
                    scr_set_status_message("Added " + dlg_list[_row] + " to " + anim_name + " " + dlg_state, c_lime);
                }
                te_dialog_close();
            }
        }
    }
    exit;
}

// --- buttons ------------------------------------------------------------------
var _ts = te_tileset();
switch (_clicked) {
    case "close":
        instance_destroy();
        exit;

    case "tab":
        tab = _arg;
        stroke_active = false;
        map_drag = false;
        meta_painting = false;
        break;

    // Tilesets
    case "ts_new":
        dlg_size = 16;
        te_dialog_open("ts_new", "NEW TILESET", true, scr_te_unique_name("tiles"));
        break;
    case "ts_rename":
        te_dialog_open("ts_rename", "RENAME TILESET", true, ts_name);
        break;
    case "ts_delete":
        var _users = scr_te_maps_using_tileset(ts_name);
        if (show_question("Delete the tileset " + ts_name + "?"
            + (_users > 0 ? "\n" + string(_users) + " map(s) use it and will not build until they get a tileset again." : ""))) {
            scr_te_asset_delete(ts_name);
            scr_set_status_message("Deleted tileset " + ts_name, c_yellow);
            tile_undo = {};
            atlas_full = true;
            ts_name = "";
            te_changed();
            te_refresh();
        }
        mouse_clear(mb_left);
        break;

    // Tiles
    case "tile_add":
        if (_ts != undefined) {
            var _new = scr_gk_tileset_add_tile(_ts);
            if (_new >= 0) {
                tile_sel = _new;
                te_tile_changed(_new);
            }
        }
        break;
    case "tile_dup":
        if (_ts != undefined) {
            var _dup = scr_te_tileset_duplicate_tile(_ts, tile_sel);
            if (_dup >= 0) {
                scr_set_status_message("Tile " + string(tile_sel) + " copied to tile " + string(_dup));
                tile_sel = _dup;
                te_tile_changed(_dup);
            }
        }
        break;
    case "tile_clear":
        if (_ts != undefined && tile_sel > 0) {
            te_tile_push_undo(_ts);
            array_copy(_ts.tiles[tile_sel], 0, array_create(_ts.tile_size * _ts.tile_size, 0), 0, _ts.tile_size * _ts.tile_size);
            te_tile_changed(tile_sel);
        }
        break;
    case "tile_delete":
        if (_ts != undefined && tile_sel > 0) {
            if (show_question("Delete tile " + string(tile_sel) + " of " + ts_name + "?\n"
                + "Maps and metatiles that use it show the empty tile there instead; later tiles move down by one.")) {
                var _deleted = tile_sel;
                scr_te_tileset_delete_tile(_ts, _deleted);
                tile_undo = {};
                tile_sel = min(_deleted, array_length(_ts.tiles) - 1);
                te_tileset_changed();
                scr_set_status_message("Deleted tile " + string(_deleted) + " of " + ts_name, c_yellow);
            }
            mouse_clear(mb_left);
        }
        break;
    case "tile_prev": tile_sel = max(0, tile_sel - 1); break;
    case "tile_next": if (_ts != undefined) tile_sel = min(array_length(_ts.tiles) - 1, tile_sel + 1); break;
    case "tile_undo": te_tile_undo(false); break;
    case "tile_redo": te_tile_undo(true); break;
    case "tool":
        if (_arg == "PICK" && tool != "PICK") tool_before_pick = tool;
        tool = _arg;
        stroke_active = false;
        break;
    case "rgb_dn":
    case "rgb_up":
        if (_ts != undefined) {
            var _gun = (_arg == "R") ? _ts.colour_r : ((_arg == "G") ? _ts.colour_g : _ts.colour_b);
            _gun[pal_sel] = clamp(_gun[pal_sel] + (_clicked == "rgb_up" ? 1 : -1), 0, 15);
            te_tileset_changed();
        }
        break;
    case "flag":
        if (_ts != undefined && tile_sel > 0 && tile_sel < array_length(_ts.flags)) {
            _ts.flags[tile_sel] = _ts.flags[tile_sel] ^ flag_bits[real(_arg)];
            te_changed();
        }
        break;

    // Metatiles
    case "meta_new":
        if (_ts != undefined) {
            var _mmax = scr_te_metatile_max_tiles(_ts.tile_size);
            dlg_w = min(2, _mmax);
            dlg_h = min(2, _mmax);
            var _base = "meta";
            var _mn = 1;
            while (scr_te_metatile_index(_ts, _base + string(_mn)) >= 0 || scr_asset_find_by_name(_base + string(_mn)) != undefined) _mn += 1;
            te_dialog_open("meta_new", "NEW METATILE", true, _base + string(_mn));
        }
        break;
    case "meta_rename":
        te_dialog_open("meta_rename", "RENAME METATILE", true, meta_name);
        break;
    case "meta_resize":
        var _rmeta = te_meta(_ts, meta_name);
        if (_rmeta != undefined) {
            dlg_w = _rmeta.w;
            dlg_h = _rmeta.h;
            te_dialog_open("meta_resize", "RESIZE METATILE " + meta_name, false, meta_name);
        }
        break;
    case "meta_delete":
        if (_ts != undefined && show_question("Delete the metatile " + meta_name + "?\nTiles already stamped on maps stay.")) {
            var _di = scr_te_metatile_index(_ts, meta_name);
            if (_di >= 0) array_delete(_ts.metatiles, _di, 1);
            scr_set_status_message("Deleted metatile " + meta_name, c_yellow);
            meta_name = "";
            te_changed();
            te_refresh();
        }
        mouse_clear(mb_left);
        break;

    // Maps
    case "map_new":
        dlg_tileset = (ts_name != "") ? ts_name : (array_length(ts_names) > 0 ? ts_names[0] : "");
        dlg_rx = 1;
        dlg_ry = 1;
        te_dialog_open("map_new", "NEW MAP", true, scr_te_unique_name("level"));
        break;
    case "map_rename":
        te_dialog_open("map_rename", "RENAME MAP", true, map_name);
        break;
    case "map_resize":
        var _zmap = te_map();
        if (_zmap != undefined) {
            dlg_rx = _zmap.rooms_x;
            dlg_ry = _zmap.rooms_y;
            te_dialog_open("map_resize", "RESIZE MAP " + map_name, false, map_name);
        }
        break;
    case "map_delete":
        if (show_question("Delete the map " + map_name + "?")) {
            scr_te_asset_delete(map_name);
            scr_set_status_message("Deleted map " + map_name, c_yellow);
            map_name = "";
            te_changed();
            te_refresh();
        }
        mouse_clear(mb_left);
        break;
    case "room_left": room_x -= 1; enemy_sel = -1; break;
    case "room_right": room_x += 1; enemy_sel = -1; break;
    case "room_up": room_y -= 1; enemy_sel = -1; break;
    case "room_down": room_y += 1; enemy_sel = -1; break;
    case "map_tool": map_tool = _arg; map_drag = false; break;
    case "grid": show_grid = !show_grid; break;
    case "flags": show_flags = !show_flags; break;
    case "map_undo": te_map_undo(false); break;
    case "map_redo": te_map_undo(true); break;
    case "en_anim_prev":
    case "en_anim_next":
        var _an = array_length(anim_names);
        if (_an > 0) {
            var _aat = 0;
            var _ak = 0;
            while (_ak < _an) {
                if (anim_names[_ak] == enemy_animset) _aat = _ak;
                _ak += 1;
            }
            enemy_animset = anim_names[(_aat + (_clicked == "en_anim_next" ? 1 : -1) + _an) mod _an];
            var _amap = te_map();
            if (_amap != undefined && enemy_sel >= 0 && enemy_sel < array_length(_amap.enemies)) {
                te_map_push_undo(_amap);
                _amap.enemies[enemy_sel].animset = enemy_animset;
                te_changed();
            }
        }
        break;
    case "en_speed_dn":
    case "en_speed_up":
        enemy_speed = clamp(enemy_speed + (_clicked == "en_speed_up" ? 1 : -1), 1, 4);
        var _smap = te_map();
        if (_smap != undefined && enemy_sel >= 0 && enemy_sel < array_length(_smap.enemies)) {
            te_map_push_undo(_smap);
            _smap.enemies[enemy_sel].speed = enemy_speed;
            te_changed();
        }
        break;
    case "en_delete":
        var _dmap = te_map();
        if (_dmap != undefined && enemy_sel >= 0 && enemy_sel < array_length(_dmap.enemies)) {
            te_map_push_undo(_dmap);
            array_delete(_dmap.enemies, enemy_sel, 1);
            enemy_sel = -1;
            te_changed();
            scr_set_status_message("Enemy removed");
        }
        break;

    // Animation sets
    case "anim_new":
        dlg_height = 24;
        te_dialog_open("anim_new", "NEW ANIMATION SET", true, scr_te_unique_name("hero"));
        break;
    case "anim_rename":
        te_dialog_open("anim_rename", "RENAME ANIMATION SET", true, anim_name);
        break;
    case "anim_delete":
        if (show_question("Delete the animation set " + anim_name + "?\nIts SPRITE frames are kept.")) {
            scr_te_asset_delete(anim_name);
            scr_set_status_message("Deleted animation set " + anim_name, c_yellow);
            anim_name = "";
            te_changed();
            te_refresh();
        }
        mouse_clear(mb_left);
        break;
    case "rate_dn":
    case "rate_up":
        var _rset = te_animset();
        if (_rset != undefined && is_struct(_rset.states[$ _arg])) {
            var _rstate = _rset.states[$ _arg];
            _rstate.rate = clamp(_rstate.rate + (_clicked == "rate_up" ? 1 : -1) * (_shift ? 5 : 1), 1, 50);
            te_changed();
        }
        break;
    case "frame_add":
        var _fset = te_animset();
        if (_fset != undefined) {
            dlg_state = _arg;
            dlg_list = scr_te_sprite_names_of_height(_fset.height);
            te_dialog_open("frame_pick", "ADD " + string_upper(_arg) + " FRAME (SPRITES " + string(_fset.height) + " PX HIGH)", false, "");
        }
        break;
    case "frame_new":
        var _nset = te_animset();
        if (_nset != undefined) {
            var _frame_name = scr_te_animset_new_frame(_nset, _arg);
            if (_frame_name != "") {
                anim_state = _arg;
                anim_frame = array_length(_nset.states[$ _arg].frames) - 1;
                with (obj_amiga_manager) {
                    if (variable_instance_exists(id, "sprite_editor_rebuild_assets")) sprite_editor_rebuild_assets();
                }
                te_changed();
                scr_set_status_message("Created sprite " + _frame_name + " - draw it in SPR-EDIT", c_lime);
            }
        }
        break;
    case "frame_remove":
    case "frame_left":
    case "frame_right":
        var _eset = te_animset();
        if (_eset != undefined && anim_state == _arg && is_struct(_eset.states[$ _arg])) {
            var _frames = _eset.states[$ _arg].frames;
            if (anim_frame >= 0 && anim_frame < array_length(_frames)) {
                if (_clicked == "frame_remove") {
                    array_delete(_frames, anim_frame, 1);
                    anim_frame = min(anim_frame, array_length(_frames) - 1);
                } else {
                    var _to = anim_frame + (_clicked == "frame_right" ? 1 : -1);
                    if (_to >= 0 && _to < array_length(_frames)) {
                        var _swap = _frames[_to];
                        _frames[_to] = _frames[anim_frame];
                        _frames[anim_frame] = _swap;
                        anim_frame = _to;
                    }
                }
                te_changed();
            }
        }
        break;
}
if (_clicked != "") {
    te_refresh();
    exit;
}

// --- lists ----------------------------------------------------------------------
var _lists = te_lists();
var _l = 0;
while (_l < array_length(_lists)) {
    var _list = _lists[_l];
    var _lh = _list.rows * row_h;
    if (point_in_rectangle(_mx, _my, _list.x, _list.y, _list.x + _list.w, _list.y + _lh - 1)) {
        var _max_scroll = max(0, array_length(_list.names) - _list.rows);
        if (_wheel != 0) list_scroll[$ _list.id] = clamp(list_scroll[$ _list.id] + _wheel, 0, _max_scroll);
        var _row = (_my - _list.y) div row_h + list_scroll[$ _list.id];
        if (_lp && _row < array_length(_list.names)) {
            var _pick = _list.names[_row];
            switch (_list.id) {
                case "ts":
                    if (ts_name != _pick) {
                        ts_name = _pick;
                        tile_sel = 1;
                        grid_scroll.tiles = 0;
                        grid_scroll.mpick = 0;
                        stroke_active = false;
                    }
                    break;
                case "meta": meta_name = _pick; break;
                case "map":
                    if (map_name != _pick) {
                        map_name = _pick;
                        room_x = 0;
                        room_y = 0;
                        enemy_sel = -1;
                        grid_scroll.picker = 0;
                    }
                    break;
                case "mmeta":
                    map_meta = _pick;
                    map_brush = "META";
                    if (map_tool != "PAINT" && map_tool != "RECT") map_tool = "PAINT";
                    break;
                case "anim": anim_name = _pick; anim_frame = -1; break;
            }
            te_refresh();
            exit;
        }
    }
    list_scroll[$ _list.id] = clamp(list_scroll[$ _list.id], 0, max(0, array_length(_list.names) - _list.rows));
    _l += 1;
}

// --- tile grids -------------------------------------------------------------------
var _grids = te_grids();
var _g = 0;
while (_g < array_length(_grids)) {
    var _grid = _grids[_g];
    var _gts = (_grid.id == "picker") ? te_map_tileset() : _ts;
    if (_gts != undefined) {
        var _cols = max(1, _grid.w div grid_cell);
        var _total_rows = ceil(array_length(_gts.tiles) / _cols);
        var _vis_rows = _grid.h div grid_cell;
        if (point_in_rectangle(_mx, _my, _grid.x, _grid.y, _grid.x + _grid.w - 1, _grid.y + _grid.h - 1) && _wheel != 0) {
            grid_scroll[$ _grid.id] += _wheel;
        }
        grid_scroll[$ _grid.id] = clamp(grid_scroll[$ _grid.id], 0, max(0, _total_rows - _vis_rows));
        var _hit = te_grid_hit(_grid, _gts, _mx, _my);
        if (_hit >= 0) {
            hover_text = "Tile " + string(_hit) + (_hit == 0 ? " (empty)" : "");
            if (_lp) {
                switch (_grid.id) {
                    case "tiles": tile_sel = _hit; stroke_active = false; break;
                    case "mpick": meta_tile = _hit; break;
                    case "picker":
                        map_tile = _hit;
                        map_brush = "TILE";
                        if (map_tool != "PAINT" && map_tool != "RECT") map_tool = "PAINT";
                        break;
                }
                exit;
            }
        }
    }
    _g += 1;
}

// --- tab areas ----------------------------------------------------------------------
switch (tab) {
    case "TILES":
        if (_ts == undefined) {
            stroke_active = false;
            break;
        }
        var _size = _ts.tile_size;
        var _zoom = te_pix_zoom(_size);

        // Palette swatches: click selects the paint colour.
        var _p = 0;
        while (_p < 16) {
            var _sx = tools_x + (_p mod 8) * 52;
            var _sy = content_y + 110 + (_p div 8) * 52;
            if (point_in_rectangle(_mx, _my, _sx, _sy, _sx + 45, _sy + 45)) {
                hover_text = "Colour " + string(_p) + (_p == 0 ? " (background / transparent)" : "");
                if (_lp) pal_sel = _p;
            }
            _p += 1;
        }
        // R / G / B bars: click or drag sets 0..15.
        var _guns = [_ts.colour_r, _ts.colour_g, _ts.colour_b];
        var _gi = 0;
        while (_gi < 3) {
            var _bx = tools_x + 60;
            var _by = content_y + 252 + _gi * 30;
            if (mouse_check_button(mb_left) && !stroke_active && point_in_rectangle(_mx, _my, _bx, _by, _bx + 16 * 18 - 1, _by + 23)) {
                var _value = clamp((_mx - _bx) div 18, 0, 15);
                if (_guns[_gi][pal_sel] != _value) {
                    _guns[_gi][pal_sel] = _value;
                    te_tileset_changed();
                }
            }
            _gi += 1;
        }

        // Pixel editor.
        var _inside = point_in_rectangle(_mx, _my, pix_x, pix_y, pix_x + _size * _zoom - 1, pix_y + _size * _zoom - 1);
        var _px = clamp((_mx - pix_x) div _zoom, 0, _size - 1);
        var _py = clamp((_my - pix_y) div _zoom, 0, _size - 1);
        if (_inside) hover_text = "Tile " + string(tile_sel) + "  x " + string(_px) + "  y " + string(_py) + "  colour " + string(scr_gk_tile_get(_ts, tile_sel, _px, _py));
        if (tile_sel >= array_length(_ts.tiles)) stroke_active = false;

        if (!stroke_active) {
            if ((_lp || _rp) && _inside) {
                if (tool == "PICK") {
                    pal_sel = scr_gk_tile_get(_ts, tile_sel, _px, _py);
                    tool = tool_before_pick;
                } else if (tile_sel == 0) {
                    scr_set_status_message("Tile 0 is the empty tile: it is always colour 0 and cannot be painted", c_yellow);
                } else {
                    te_tile_push_undo(_ts);
                    stroke_active = true;
                    stroke_button = _lp ? mb_left : mb_right;
                    stroke_colour = _lp ? pal_sel : 0;
                    stroke_x0 = _px;
                    stroke_y0 = _py;
                    stroke_x1 = _px;
                    stroke_y1 = _py;
                    if (tool == "DRAW") {
                        scr_gk_tile_set(_ts, tile_sel, _px, _py, stroke_colour);
                        te_tile_changed(tile_sel);
                    } else if (tool == "FILL") {
                        scr_te_tile_fill(_ts, tile_sel, _px, _py, stroke_colour);
                        te_tile_changed(tile_sel);
                        stroke_active = false;
                    }
                }
            }
        } else if (mouse_check_button(stroke_button)) {
            if (tool == "DRAW" && (_px != stroke_x1 || _py != stroke_y1)) {
                scr_te_tile_line(_ts, tile_sel, stroke_x1, stroke_y1, _px, _py, stroke_colour);
                te_tile_changed(tile_sel);
            }
            stroke_x1 = _px;
            stroke_y1 = _py;
        } else {
            if (tool == "LINE") {
                scr_te_tile_line(_ts, tile_sel, stroke_x0, stroke_y0, stroke_x1, stroke_y1, stroke_colour);
                te_tile_changed(tile_sel);
            } else if (tool == "RECT") {
                scr_te_tile_rect(_ts, tile_sel, stroke_x0, stroke_y0, stroke_x1, stroke_y1, stroke_colour, _shift);
                te_tile_changed(tile_sel);
            }
            stroke_active = false;
        }
        break;

    case "METATILES":
        var _meta = te_meta(_ts, meta_name);
        if (_ts == undefined || _meta == undefined) {
            meta_painting = false;
            break;
        }
        var _cell = te_meta_cell(_meta, _ts.tile_size);
        var _mc = (_mx - pix_x) div _cell;
        var _mr = (_my - pix_y) div _cell;
        var _in_meta = _mx >= pix_x && _my >= pix_y && _mc < _meta.w && _mr < _meta.h;
        if (_in_meta) hover_text = "Cell " + string(_mc) + "," + string(_mr) + "  tile " + string(_meta.cells[_mr * _meta.w + _mc]);
        if (!meta_painting && (_lp || _rp) && _in_meta) {
            meta_painting = true;
            meta_paint_button = _lp ? mb_left : mb_right;
        }
        if (meta_painting) {
            if (!mouse_check_button(meta_paint_button)) {
                meta_painting = false;
            } else if (_in_meta) {
                var _mval = (meta_paint_button == mb_left) ? meta_tile : 0;
                if (_meta.cells[_mr * _meta.w + _mc] != _mval) {
                    _meta.cells[_mr * _meta.w + _mc] = _mval;
                    te_changed();
                }
            }
        }
        break;

    case "MAP":
        var _map = te_map();
        var _mts = te_map_tileset();
        if (_map == undefined || _mts == undefined || _mts.tile_size * _map.room_cols > 320) {
            map_drag = false;
            break;
        }
        var _msize = _mts.tile_size;
        var _cs = te_view_cell(_msize);
        var _c0 = room_x * _map.room_cols;
        var _r0 = room_y * _map.room_rows;

        // Room navigator.
        var _geom = te_nav_geom(_map);
        if (_lp && point_in_rectangle(_mx, _my, _geom[0], _geom[1], _geom[0] + _geom[2] * _map.rooms_x - 1, _geom[1] + _geom[3] * _map.rooms_y - 1)) {
            room_x = clamp(floor((_mx - _geom[0]) / _geom[2]), 0, _map.rooms_x - 1);
            room_y = clamp(floor((_my - _geom[1]) / _geom[3]), 0, _map.rooms_y - 1);
            enemy_sel = -1;
            exit;
        }

        var _vc = floor((_mx - view_x) / _cs);
        var _vr = floor((_my - view_y) / _cs);
        var _in_view = _mx >= view_x && _my >= view_y && _vc < _map.room_cols && _vr < _map.room_rows;
        _vc = clamp(_vc, 0, _map.room_cols - 1);
        _vr = clamp(_vr, 0, _map.room_rows - 1);
        var _col = _c0 + _vc;
        var _row = _r0 + _vr;
        if (_in_view) {
            var _ht = scr_gk_map_get(_map, _col, _row);
            hover_text = "Cell " + string(_col) + "," + string(_row) + "  (" + string(_col * _msize) + "," + string(_row * _msize) + " px)  tile " + string(_ht);
        }

        if (!map_drag) {
            if ((_lp || _rp) && _in_view) {
                switch (map_tool) {
                    case "PAINT":
                        te_map_push_undo(_map);
                        map_drag = true;
                        map_drag_button = _lp ? mb_left : mb_right;
                        map_last_c = _col;
                        map_last_r = _row;
                        if (_rp) {
                            scr_gk_map_set(_map, _col, _row, 0);
                        } else if (map_brush == "META") {
                            var _bmeta = te_meta(_mts, map_meta);
                            if (_bmeta != undefined) scr_te_map_stamp_clipped(_map, _bmeta, _col, _row, _c0, _r0, _c0 + _map.room_cols - 1, _r0 + _map.room_rows - 1, true);
                        } else {
                            scr_gk_map_set(_map, _col, _row, map_tile);
                        }
                        overview_dirty = true;
                        te_changed();
                        break;
                    case "RECT":
                        map_drag = true;
                        map_drag_button = _lp ? mb_left : mb_right;
                        rect_c0 = _col;
                        rect_r0 = _row;
                        rect_c1 = _col;
                        rect_r1 = _row;
                        break;
                    case "SPAWN":
                        if (_lp) {
                            te_map_push_undo(_map);
                            _map.spawn_x = _col * _msize;
                            _map.spawn_y = _row * _msize;
                            te_changed();
                            scr_set_status_message("Player start at " + string(_map.spawn_x) + "," + string(_map.spawn_y));
                        }
                        break;
                    case "ENEMY":
                        var _hit_enemy = -1;
                        var _mpx = _c0 * _msize + (_mx - view_x) / view_zoom;
                        var _mpy = _r0 * _msize + (_my - view_y) / view_zoom;
                        var _e = array_length(_map.enemies) - 1;
                        while (_e >= 0) {
                            var _en = _map.enemies[_e];
                            var _eh = te_enemy_height(_en.animset);
                            if (_mpx >= _en.x && _mpx < _en.x + 16 && _mpy >= _en.y && _mpy < _en.y + _eh) {
                                _hit_enemy = _e;
                                break;
                            }
                            _e -= 1;
                        }
                        if (_hit_enemy >= 0) {
                            if (_rp) {
                                te_map_push_undo(_map);
                                array_delete(_map.enemies, _hit_enemy, 1);
                                enemy_sel = -1;
                                te_changed();
                                scr_set_status_message("Enemy removed");
                            } else {
                                enemy_sel = _hit_enemy;
                                enemy_animset = _map.enemies[_hit_enemy].animset;
                                enemy_speed = _map.enemies[_hit_enemy].speed;
                            }
                        } else if (_lp) {
                            if (enemy_animset == "") {
                                scr_set_status_message("Make an animation set first (ANIMATIONS tab)", c_yellow);
                            } else {
                                te_map_push_undo(_map);
                                var _added = scr_te_map_add_enemy(_map, _msize, _col, _row, enemy_animset, enemy_speed);
                                if (_added < 0) {
                                    array_pop(map_undo);
                                    scr_set_status_message("This room already has " + string(GK_ENEMIES_PER_ROOM) + " enemies", c_yellow);
                                } else {
                                    enemy_sel = _added;
                                    te_changed();
                                }
                            }
                        } else {
                            enemy_sel = -1;
                        }
                        break;
                }
            }
        } else if (mouse_check_button(map_drag_button)) {
            if (map_tool == "PAINT") {
                if ((_col != map_last_c || _row != map_last_r) && (map_drag_button == mb_right || map_brush == "TILE")) {
                    // Walk from the last cell so fast strokes leave no gaps.
                    var _pval = (map_drag_button == mb_right) ? 0 : map_tile;
                    var _steps = max(abs(_col - map_last_c), abs(_row - map_last_r));
                    var _s = 1;
                    while (_s <= _steps) {
                        scr_gk_map_set(_map, round(lerp(map_last_c, _col, _s / _steps)), round(lerp(map_last_r, _row, _s / _steps)), _pval);
                        _s += 1;
                    }
                    overview_dirty = true;
                    te_changed();
                }
                map_last_c = _col;
                map_last_r = _row;
            } else if (map_tool == "RECT") {
                rect_c1 = _col;
                rect_r1 = _row;
            }
        } else {
            if (map_tool == "RECT") {
                te_map_push_undo(_map);
                var _rmeta2 = (map_drag_button == mb_left && map_brush == "META") ? te_meta(_mts, map_meta) : undefined;
                scr_te_map_fill_rect(_map, rect_c0, rect_r0, rect_c1, rect_r1, (map_drag_button == mb_left) ? map_tile : 0, _rmeta2);
                overview_dirty = true;
                te_changed();
            }
            map_drag = false;
        }
        break;

    case "ANIMATIONS":
        var _set = te_animset();
        if (_set == undefined || !_lp) break;
        var _states = GK_ANIM_STATES;
        var _sh = clamp(_set.height, 1, 64) * 2 + 8;
        var _si = 0;
        while (_si < 4) {
            var _state = _set.states[$ _states[_si]];
            var _ty = content_y + 10 + _si * anim_row_h + 68;
            if (is_struct(_state) && _my >= _ty && _my < _ty + _sh && _mx >= anim_x) {
                var _f = (_mx - anim_x) div 40;
                if (_f < array_length(_state.frames) && anim_x + _f * 40 + 40 < anim_preview_x - 20) {
                    anim_state = _states[_si];
                    anim_frame = _f;
                }
            }
            _si += 1;
        }
        break;
}
