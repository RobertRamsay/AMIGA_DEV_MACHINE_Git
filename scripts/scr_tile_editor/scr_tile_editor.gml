/// @desc Helpers for the TILES & MAPS window (obj_tile_editor). Everything
/// here is plain data work on the Game Kit assets (see scr_gamekit_assets):
/// no drawing, no instance state, so scr_tile_editor_selftest can check it.
/// Assets are always passed in freshly looked up by name; nothing here keeps
/// a struct between calls.

/// @desc scr_tile_editor_open()
/// Opens the TILES & MAPS window (once). Returns its instance id.
function scr_tile_editor_open() {
    if (instance_exists(obj_tile_editor)) return instance_find(obj_tile_editor, 0);
    return instance_create_depth(0, 0, -400000, obj_tile_editor);
}

/// The asset called _name when it has type _type, else undefined.
function scr_te_find(_type, _name) {
    if (!is_string(_name) || _name == "") return undefined;
    var _asset = scr_asset_find_by_name(_name);
    if (!is_struct(_asset) || _asset[$ "type"] != _type) return undefined;
    return _asset;
}

/// True for an assembler-label-safe name: a letter, then letters, digits or _.
function scr_te_name_is_valid(_name) {
    if (!is_string(_name)) return false;
    var _length = string_length(_name);
    if (_length < 1 || _length > 32) return false;
    var _i = 1;
    while (_i <= _length) {
        var _code = ord(string_char_at(_name, _i));
        var _letter = (_code >= 65 && _code <= 90) || (_code >= 97 && _code <= 122);
        var _digit = _code >= 48 && _code <= 57;
        if (_i == 1 && !_letter) return false;
        if (!_letter && !_digit && _code != 95) return false;
        _i += 1;
    }
    return true;
}

/// "" when _name can name an asset (renaming _old, or "" for a new one), else why not.
function scr_te_name_error(_name, _old) {
    if (!scr_te_name_is_valid(_name)) return "Names must start with a letter and use only letters, digits and _";
    if (_name != _old && scr_asset_find_by_name(_name) != undefined) return "An asset called " + _name + " already exists";
    return "";
}

/// _base, or _base2, _base3 ... whichever is not an asset name yet.
function scr_te_unique_name(_base) {
    if (scr_asset_find_by_name(_base) == undefined) return _base;
    var _n = 2;
    while (scr_asset_find_by_name(_base + string(_n)) != undefined) _n += 1;
    return _base + string(_n);
}

/// Index of the metatile called _name in _tileset, or -1.
function scr_te_metatile_index(_tileset, _name) {
    if (!is_struct(_tileset)) return -1;
    var _i = 0;
    while (_i < array_length(_tileset.metatiles)) {
        if (_tileset.metatiles[_i].name == _name) return _i;
        _i += 1;
    }
    return -1;
}

/// "" when _name can name a metatile of _tileset (renaming _old), else why not.
function scr_te_metatile_name_error(_tileset, _name, _old) {
    if (!scr_te_name_is_valid(_name)) return "Names must start with a letter and use only letters, digits and _";
    if (_name != _old && scr_te_metatile_index(_tileset, _name) != -1) return "This tileset already has a metatile called " + _name;
    if (_name != _old && scr_asset_find_by_name(_name) != undefined) return "An asset called " + _name + " already exists";
    return "";
}

/// Largest metatile side in tiles for a tile size (128 px limit).
function scr_te_metatile_max_tiles(_tile_size) {
    return max(1, GK_METATILE_MAX_PX div max(1, _tile_size));
}

/// Resizes a metatile to _w x _h tiles keeping the overlapping cells.
/// Returns false (and changes nothing) when the size is not allowed.
function scr_te_metatile_resize(_meta, _w, _h, _tile_size) {
    var _max = scr_te_metatile_max_tiles(_tile_size);
    if (_w < 1 || _h < 1 || _w > _max || _h > _max) return false;
    var _cells = array_create(_w * _h, 0);
    var _y = 0;
    while (_y < min(_h, _meta.h)) {
        var _x = 0;
        while (_x < min(_w, _meta.w)) {
            _cells[_y * _w + _x] = _meta.cells[_y * _meta.w + _x];
            _x += 1;
        }
        _y += 1;
    }
    _meta.w = _w;
    _meta.h = _h;
    _meta.cells = _cells;
    return true;
}

/// Renumbers tile indices in a cell array after tile _index was deleted:
/// cells that showed it become 0, later tiles shift down by one.
function scr_te_renumber_cells(_cells, _index) {
    var _i = 0;
    var _n = array_length(_cells);
    while (_i < _n) {
        var _t = _cells[_i];
        if (_t == _index) _cells[_i] = 0;
        else if (_t > _index) _cells[_i] = _t - 1;
        _i += 1;
    }
}

/// Deletes tile _index (> 0) of _tileset and renumbers its metatiles and
/// every TILEMAP that uses it, so no map ends up pointing at the wrong tile.
/// Returns true when a tile was deleted.
function scr_te_tileset_delete_tile(_tileset, _index) {
    if (!is_struct(_tileset) || _index <= 0 || _index >= array_length(_tileset.tiles)) return false;
    array_delete(_tileset.tiles, _index, 1);
    array_delete(_tileset.flags, _index, 1);
    var _m = 0;
    while (_m < array_length(_tileset.metatiles)) {
        scr_te_renumber_cells(_tileset.metatiles[_m].cells, _index);
        _m += 1;
    }
    var _a = 0;
    while (_a < array_length(global.asset_list)) {
        var _asset = global.asset_list[_a];
        if (_asset[$ "type"] == "TILEMAP" && _asset.tileset == _tileset.name) scr_te_renumber_cells(_asset.cells, _index);
        _a += 1;
    }
    return true;
}

/// Appends a copy of tile _index (pixels and flags); returns the new index or -1.
function scr_te_tileset_duplicate_tile(_tileset, _index) {
    if (_index < 0 || _index >= array_length(_tileset.tiles)) return -1;
    var _new = scr_gk_tileset_add_tile(_tileset);
    if (_new < 0) return -1;
    array_copy(_tileset.tiles[_new], 0, _tileset.tiles[_index], 0, array_length(_tileset.tiles[_index]));
    _tileset.flags[_new] = (_index == 0) ? 0 : _tileset.flags[_index];
    return _new;
}

/// Number of TILEMAP assets drawn with the tileset called _name.
function scr_te_maps_using_tileset(_name) {
    var _count = 0;
    var _a = 0;
    while (_a < array_length(global.asset_list)) {
        var _asset = global.asset_list[_a];
        if (_asset[$ "type"] == "TILEMAP" && _asset.tileset == _name) _count += 1;
        _a += 1;
    }
    return _count;
}

/// Removes the asset called _name. Returns true when one was removed.
function scr_te_asset_delete(_name) {
    var _i = 0;
    while (_i < array_length(global.asset_list)) {
        if (global.asset_list[_i].name == _name) {
            array_delete(global.asset_list, _i, 1);
            return true;
        }
        _i += 1;
    }
    return false;
}

/// Renames an asset and follows the name everywhere the Game Kit keeps it:
/// maps' tileset, enemies' animset and Game Kit node parameters.
/// Returns "" or the error. _new must already have passed scr_te_name_error.
function scr_te_asset_rename(_old, _new) {
    if (_old == _new) return "";
    var _error = scr_te_name_error(_new, _old);
    if (_error != "") return _error;
    var _asset = scr_asset_find_by_name(_old);
    if (_asset == undefined) return "Asset " + _old + " not found";
    _asset.name = _new;
    var _a = 0;
    while (_a < array_length(global.asset_list)) {
        var _other = global.asset_list[_a];
        if (_other[$ "type"] == "TILEMAP") {
            if (_other.tileset == _old) _other.tileset = _new;
            var _e = 0;
            while (_e < array_length(_other.enemies)) {
                if (_other.enemies[_e].animset == _old) _other.enemies[_e].animset = _new;
                _e += 1;
            }
        }
        _a += 1;
    }
    with (obj_opcode_node) {
        if (variable_instance_exists(id, "macro_param_text_a") && macro_param_text_a == _old) macro_param_text_a = _new;
        if (variable_instance_exists(id, "macro_param_text_b") && macro_param_text_b == _old) macro_param_text_b = _new;
    }
    return "";
}

// --- pixel operations on one tile (colours 0..15) --------------------------

/// Bresenham line of colour _c in tile _tile of _tileset (tile 0 is locked).
function scr_te_tile_line(_tileset, _tile, _x0, _y0, _x1, _y1, _c) {
    var _dx = abs(_x1 - _x0), _sx = _x0 < _x1 ? 1 : -1;
    var _dy = -abs(_y1 - _y0), _sy = _y0 < _y1 ? 1 : -1;
    var _err = _dx + _dy;
    repeat (256) {
        scr_gk_tile_set(_tileset, _tile, _x0, _y0, _c);
        if (_x0 == _x1 && _y0 == _y1) break;
        var _e2 = 2 * _err;
        if (_e2 >= _dy) { _err += _dy; _x0 += _sx; }
        if (_e2 <= _dx) { _err += _dx; _y0 += _sy; }
    }
}

/// Rectangle outline (or filled) between two corners.
function scr_te_tile_rect(_tileset, _tile, _x0, _y0, _x1, _y1, _c, _filled) {
    var _l = min(_x0, _x1), _r = max(_x0, _x1);
    var _t = min(_y0, _y1), _b = max(_y0, _y1);
    var _y = _t;
    while (_y <= _b) {
        var _x = _l;
        while (_x <= _r) {
            if (_filled || _x == _l || _x == _r || _y == _t || _y == _b) scr_gk_tile_set(_tileset, _tile, _x, _y, _c);
            _x += 1;
        }
        _y += 1;
    }
}

/// 4-way flood fill from (_x, _y) with colour _c.
function scr_te_tile_fill(_tileset, _tile, _x, _y, _c) {
    var _size = _tileset.tile_size;
    if (_tile <= 0 || _tile >= array_length(_tileset.tiles) || _x < 0 || _y < 0 || _x >= _size || _y >= _size) return;
    var _pixels = _tileset.tiles[_tile];
    var _target = _pixels[_y * _size + _x];
    _c = clamp(_c, 0, 15);
    if (_target == _c) return;
    var _queue = [_y * _size + _x];
    _pixels[_y * _size + _x] = _c;
    var _head = 0;
    while (_head < array_length(_queue)) {
        var _p = _queue[_head];
        _head += 1;
        var _px = _p mod _size;
        var _py = _p div _size;
        if (_px > 0 && _pixels[_p - 1] == _target) { _pixels[_p - 1] = _c; array_push(_queue, _p - 1); }
        if (_px < _size - 1 && _pixels[_p + 1] == _target) { _pixels[_p + 1] = _c; array_push(_queue, _p + 1); }
        if (_py > 0 && _pixels[_p - _size] == _target) { _pixels[_p - _size] = _c; array_push(_queue, _p - _size); }
        if (_py < _size - 1 && _pixels[_p + _size] == _target) { _pixels[_p + _size] = _c; array_push(_queue, _p + _size); }
    }
}

// --- maps ---------------------------------------------------------------------

/// Stamps a metatile with its top-left at (_col, _row), clipped to the cell
/// rectangle _c0.._c1, _r0.._r1 (inclusive; normally the current room).
/// Empty (0) metatile cells leave the map unchanged when _keep_under is true.
function scr_te_map_stamp_clipped(_map, _meta, _col, _row, _c0, _r0, _c1, _r1, _keep_under) {
    var _y = 0;
    while (_y < _meta.h) {
        var _x = 0;
        while (_x < _meta.w) {
            var _cx = _col + _x;
            var _cy = _row + _y;
            var _tile = _meta.cells[_y * _meta.w + _x];
            if (_cx >= _c0 && _cx <= _c1 && _cy >= _r0 && _cy <= _r1 && (_tile != 0 || !_keep_under)) scr_gk_map_set(_map, _cx, _cy, _tile);
            _x += 1;
        }
        _y += 1;
    }
}

/// Fills the cell rectangle between two corners with _tile, or, when _meta
/// is a metatile, with the metatile repeated from the first corner.
function scr_te_map_fill_rect(_map, _c0, _r0, _c1, _r1, _tile, _meta) {
    var _l = max(0, min(_c0, _c1)), _r = min(_map.width - 1, max(_c0, _c1));
    var _t = max(0, min(_r0, _r1)), _b = min(_map.height - 1, max(_r0, _r1));
    var _y = _t;
    while (_y <= _b) {
        var _x = _l;
        while (_x <= _r) {
            var _value = _tile;
            if (is_struct(_meta)) _value = _meta.cells[((_y - _t) mod _meta.h) * _meta.w + ((_x - _l) mod _meta.w)];
            scr_gk_map_set(_map, _x, _y, _value);
            _x += 1;
        }
        _y += 1;
    }
}

/// Room index (row-major) holding map pixel (_px, _py).
function scr_te_map_room_of(_map, _tile_size, _px, _py) {
    var _rx = clamp(floor(_px / (_map.room_cols * _tile_size)), 0, _map.rooms_x - 1);
    var _ry = clamp(floor(_py / (_map.room_rows * _tile_size)), 0, _map.rooms_y - 1);
    return _rx + _ry * _map.rooms_x;
}

/// Number of enemies in room _room.
function scr_te_map_room_enemies(_map, _tile_size, _room) {
    var _count = 0;
    var _e = 0;
    while (_e < array_length(_map.enemies)) {
        if (scr_te_map_room_of(_map, _tile_size, _map.enemies[_e].x, _map.enemies[_e].y) == _room) _count += 1;
        _e += 1;
    }
    return _count;
}

/// Adds an enemy at the top-left of cell (_col, _row). Returns its index,
/// or -1 when that room already has GK_ENEMIES_PER_ROOM enemies.
function scr_te_map_add_enemy(_map, _tile_size, _col, _row, _animset, _speed) {
    var _x = clamp(_col, 0, _map.width - 1) * _tile_size;
    var _y = clamp(_row, 0, _map.height - 1) * _tile_size;
    if (scr_te_map_room_enemies(_map, _tile_size, scr_te_map_room_of(_map, _tile_size, _x, _y)) >= GK_ENEMIES_PER_ROOM) return -1;
    array_push(_map.enemies, { x : _x, y : _y, animset : _animset, speed : clamp(round(_speed), 1, 4) });
    return array_length(_map.enemies) - 1;
}

/// Index of the topmost enemy whose 16 x _h marker covers map pixel (_px, _py), or -1.
function scr_te_map_enemy_at(_map, _px, _py, _h) {
    var _e = array_length(_map.enemies) - 1;
    while (_e >= 0) {
        var _enemy = _map.enemies[_e];
        if (_px >= _enemy.x && _px < _enemy.x + 16 && _py >= _enemy.y && _py < _enemy.y + _h) return _e;
        _e -= 1;
    }
    return -1;
}

/// Changes the number of rooms keeping the cells that still fit, drops
/// enemies that fall outside and pulls the spawn point back inside.
function scr_te_map_resize(_map, _rooms_x, _rooms_y, _tile_size) {
    scr_gk_map_resize(_map, _rooms_x, _rooms_y);
    var _w = _map.width * _tile_size;
    var _h = _map.height * _tile_size;
    var _e = array_length(_map.enemies) - 1;
    while (_e >= 0) {
        if (_map.enemies[_e].x >= _w || _map.enemies[_e].y >= _h) array_delete(_map.enemies, _e, 1);
        _e -= 1;
    }
    _map.spawn_x = clamp(_map.spawn_x, 0, max(0, _w - 16));
    _map.spawn_y = clamp(_map.spawn_y, 0, max(0, _h - _tile_size));
}

// --- animation sets -----------------------------------------------------------

/// The 3 sprite colours a new frame of _set gets: those of its first frame, else a default.
function scr_te_animset_colours(_set) {
    var _states = GK_ANIM_STATES;
    var _s = 0;
    while (_s < array_length(_states)) {
        var _state = _set.states[$ _states[_s]];
        if (is_struct(_state)) {
            var _f = 0;
            while (_f < array_length(_state.frames)) {
                var _sprite = scr_te_find("SPRITE", _state.frames[_f]);
                if (_sprite != undefined) return [_sprite.colour_r, _sprite.colour_g, _sprite.colour_b];
                _f += 1;
            }
        }
        _s += 1;
    }
    return [[15, 15, 2], [9, 12, 2], [4, 9, 3]];
}

/// Creates a blank SPRITE <set>_<state>_<n> of the set's height, appends it
/// to the state and returns its name ("" when the set or state is missing).
function scr_te_animset_new_frame(_set, _state_name) {
    var _state = _set.states[$ _state_name];
    if (!is_struct(_state)) return "";
    var _n = array_length(_state.frames) + 1;
    var _name = _set.name + "_" + _state_name + "_" + string(_n);
    while (scr_asset_find_by_name(_name) != undefined) {
        _n += 1;
        _name = _set.name + "_" + _state_name + "_" + string(_n);
    }
    var _colours = scr_te_animset_colours(_set);
    scr_asset_define_sprite(_name, 0, _set.height, 262144, array_create(16 * _set.height, 0), _colours[0], _colours[1], _colours[2]);
    array_push(_state.frames, _name);
    return _name;
}

/// SPRITE asset names whose height is _height.
function scr_te_sprite_names_of_height(_height) {
    var _names = [];
    var _a = 0;
    while (_a < array_length(global.asset_list)) {
        var _asset = global.asset_list[_a];
        if (_asset[$ "type"] == "SPRITE" && _asset.height == _height) array_push(_names, _asset.name);
        _a += 1;
    }
    return _names;
}

/// 12-bit palette entry _i of _tileset as a GameMaker colour.
function scr_te_palette_colour(_tileset, _i) {
    return make_colour_rgb(_tileset.colour_r[_i] * 17, _tileset.colour_g[_i] * 17, _tileset.colour_b[_i] * 17);
}
