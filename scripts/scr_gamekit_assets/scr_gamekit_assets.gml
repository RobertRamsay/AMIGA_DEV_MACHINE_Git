/// @desc Game Kit data model: tilesets (with metatiles), tile maps and
/// player/enemy animation sets. Shared by the Tile & Map editor, the Game Kit
/// emitters (scr_gamekit_emit) and the tutorials. Assets live in
/// global.asset_list like every other asset, so they are plain JSON data.
///
/// TILESET { type "TILESET", name, tile_size (8|16|24|32), tiles[], flags[],
///           colour_r[16], colour_g[16], colour_b[16], metatiles[] }
///   tiles[i]   = array of tile_size*tile_size colour indices 0..15
///                (tile 0 is the empty tile: drawn as colour 0, no flags)
///   flags[i]   = GK_FLAG_* bits
///   colour_*   = 12-bit palette (0..15 per gun) for screen colours 0..15
///   metatiles  = [{ name, w, h, cells[] }]  w*h tile indices (w, h in tiles;
///                w*tile_size and h*tile_size at most 128) - stamps for the map
/// TILEMAP { type "TILEMAP", name, tileset, rooms_x, rooms_y, room_cols,
///           room_rows, width, height, cells[], spawn_x, spawn_y, enemies[] }
///   One room is one screen: room_cols = floor(320 / size), room_rows =
///   floor(256 / size) (24 px tiles: 13 x 10, a 312 x 240 playfield).
///   width = room_cols * rooms_x, height = room_rows * rooms_y (in tiles),
///   cells[] = width*height tile indices (row-major).
///   spawn_x/y = player start in map pixels (top-left of the 16 px sprite).
///   enemies[] = [{ x, y, animset, speed }] map pixels, ANIMSET name,
///               speed 1..4 px per frame. At most GK_ENEMIES_PER_ROOM a room.
/// ANIMSET { type "ANIMSET", name, height, states { idle, run, jump, fall } }
///   each state = { frames : [SPRITE asset names], rate : frames per second }
///   Frames are ordinary 16 px wide SPRITE assets (edit them in SPR-EDIT);
///   every frame of a set must have the set's height. Facing left is the
///   frame mirrored at build time. The sprite colours come from the first
///   idle frame.

#macro GK_FLAG_SOLID 1
#macro GK_FLAG_PLATFORM 2
#macro GK_FLAG_HAZARD 4
#macro GK_FLAG_COLLECT 8
#macro GK_FLAG_EXIT 16
#macro GK_MAX_TILES 256
#macro GK_MAX_ROOMS_X 8
#macro GK_MAX_ROOMS_Y 8
#macro GK_METATILE_MAX_PX 128
#macro GK_ENEMIES_PER_ROOM 6
#macro GK_ANIM_STATES ["idle", "run", "jump", "fall"]

/// Adds or replaces an asset by name (same rule as the other scr_asset_define_*).
function scr_gk_store_asset(_asset) {
    var _i = 0;
    while (_i < array_length(global.asset_list)) {
        if (global.asset_list[_i].name == _asset.name) {
            global.asset_list[_i] = _asset;
            return _asset;
        }
        _i += 1;
    }
    array_push(global.asset_list, _asset);
    return _asset;
}

function scr_gk_valid_tile_size(_size) {
    return _size == 8 || _size == 16 || _size == 24 || _size == 32;
}

/// Names of the assets of _type, in list order.
function scr_gk_asset_names(_type) {
    var _names = [];
    var _i = 0;
    while (_i < array_length(global.asset_list)) {
        if (global.asset_list[_i].type == _type) array_push(_names, global.asset_list[_i].name);
        _i += 1;
    }
    return _names;
}

/// New tileset with the empty tile 0 and a default 16-colour palette.
function scr_gk_tileset_define(_name, _tile_size) {
    if (!scr_gk_valid_tile_size(_tile_size)) _tile_size = 16;
    var _tileset = {
        type : "TILESET",
        name : _name,
        tile_size : _tile_size,
        tiles : [array_create(_tile_size * _tile_size, 0)],
        flags : [0],
        colour_r : [0, 15, 0, 0, 15, 15, 0, 8, 4, 12, 6, 15, 2, 10, 13, 15],
        colour_g : [0, 15, 0, 9, 15, 6, 12, 5, 4, 12, 3, 12, 6, 10, 8, 15],
        colour_b : [0, 15, 8, 15, 0, 0, 3, 2, 4, 12, 1, 8, 2, 10, 4, 15],
        metatiles : []
    };
    return scr_gk_store_asset(_tileset);
}

/// Appends an empty tile; returns its index or -1 when the set is full.
function scr_gk_tileset_add_tile(_tileset) {
    if (array_length(_tileset.tiles) >= GK_MAX_TILES) return -1;
    array_push(_tileset.tiles, array_create(_tileset.tile_size * _tileset.tile_size, 0));
    array_push(_tileset.flags, 0);
    return array_length(_tileset.tiles) - 1;
}

function scr_gk_tile_get(_tileset, _tile, _px, _py) {
    var _size = _tileset.tile_size;
    if (_tile < 0 || _tile >= array_length(_tileset.tiles) || _px < 0 || _py < 0 || _px >= _size || _py >= _size) return 0;
    return _tileset.tiles[_tile][_py * _size + _px];
}

function scr_gk_tile_set(_tileset, _tile, _px, _py, _colour) {
    var _size = _tileset.tile_size;
    if (_tile <= 0 || _tile >= array_length(_tileset.tiles) || _px < 0 || _py < 0 || _px >= _size || _py >= _size) return;
    _tileset.tiles[_tile][_py * _size + _px] = clamp(_colour, 0, 15);
}

/// Adds a metatile (w x h tiles, all empty); returns it or undefined when too big.
function scr_gk_metatile_add(_tileset, _name, _w, _h) {
    var _max = GK_METATILE_MAX_PX div _tileset.tile_size;
    if (_w < 1 || _h < 1 || _w > _max || _h > _max) return undefined;
    var _meta = { name : _name, w : _w, h : _h, cells : array_create(_w * _h, 0) };
    array_push(_tileset.metatiles, _meta);
    return _meta;
}

/// Room size in tiles for a tile size: one room is one 320 x 256 screen.
function scr_gk_room_cols(_tile_size) { return 320 div _tile_size; }
function scr_gk_room_rows(_tile_size) { return 256 div _tile_size; }

/// New empty map on _tileset_name, rooms_x x rooms_y screens.
function scr_gk_map_define(_name, _tileset_name, _rooms_x, _rooms_y) {
    var _tileset = scr_asset_find_by_name(_tileset_name);
    var _size = (_tileset != undefined && _tileset.type == "TILESET") ? _tileset.tile_size : 16;
    _rooms_x = clamp(_rooms_x, 1, GK_MAX_ROOMS_X);
    _rooms_y = clamp(_rooms_y, 1, GK_MAX_ROOMS_Y);
    var _cols = scr_gk_room_cols(_size);
    var _rows = scr_gk_room_rows(_size);
    var _map = {
        type : "TILEMAP",
        name : _name,
        tileset : _tileset_name,
        rooms_x : _rooms_x,
        rooms_y : _rooms_y,
        room_cols : _cols,
        room_rows : _rows,
        width : _cols * _rooms_x,
        height : _rows * _rooms_y,
        cells : array_create(_cols * _rooms_x * _rows * _rooms_y, 0),
        spawn_x : 32,
        spawn_y : 32,
        enemies : []
    };
    return scr_gk_store_asset(_map);
}

function scr_gk_map_get(_map, _col, _row) {
    if (_col < 0 || _row < 0 || _col >= _map.width || _row >= _map.height) return 0;
    return _map.cells[_row * _map.width + _col];
}

function scr_gk_map_set(_map, _col, _row, _tile) {
    if (_col < 0 || _row < 0 || _col >= _map.width || _row >= _map.height) return;
    _map.cells[_row * _map.width + _col] = clamp(_tile, 0, GK_MAX_TILES - 1);
}

/// Stamps metatile _meta with its top-left tile at (_col, _row); clipped at the map edge.
/// Empty (0) cells of the metatile leave the map unchanged when _keep_under is true.
function scr_gk_map_stamp(_map, _meta, _col, _row, _keep_under) {
    var _y = 0;
    while (_y < _meta.h) {
        var _x = 0;
        while (_x < _meta.w) {
            var _tile = _meta.cells[_y * _meta.w + _x];
            if (_tile != 0 || !_keep_under) scr_gk_map_set(_map, _col + _x, _row + _y, _tile);
            _x += 1;
        }
        _y += 1;
    }
}

/// Changes the number of rooms, keeping the existing cells where they still fit.
function scr_gk_map_resize(_map, _rooms_x, _rooms_y) {
    _rooms_x = clamp(_rooms_x, 1, GK_MAX_ROOMS_X);
    _rooms_y = clamp(_rooms_y, 1, GK_MAX_ROOMS_Y);
    var _width = _map.room_cols * _rooms_x;
    var _height = _map.room_rows * _rooms_y;
    var _cells = array_create(_width * _height, 0);
    var _row = 0;
    while (_row < min(_height, _map.height)) {
        var _col = 0;
        while (_col < min(_width, _map.width)) {
            _cells[_row * _width + _col] = _map.cells[_row * _map.width + _col];
            _col += 1;
        }
        _row += 1;
    }
    _map.rooms_x = _rooms_x;
    _map.rooms_y = _rooms_y;
    _map.width = _width;
    _map.height = _height;
    _map.cells = _cells;
}

/// New animation set with empty states (fill frames with SPRITE asset names).
function scr_gk_animset_define(_name, _height) {
    var _set = {
        type : "ANIMSET",
        name : _name,
        height : clamp(_height, 1, 64),
        states : {
            idle : { frames : [], rate : 6 },
            run : { frames : [], rate : 12 },
            jump : { frames : [], rate : 10 },
            fall : { frames : [], rate : 10 }
        }
    };
    return scr_gk_store_asset(_set);
}

/// "" when every state has at least one frame of the right size, else the problem.
function scr_gk_animset_problem(_set) {
    if (_set == undefined || _set.type != "ANIMSET") return "animation set not found";
    var _states = GK_ANIM_STATES;
    var _s = 0;
    while (_s < array_length(_states)) {
        var _state = _set.states[$ _states[_s]];
        if (!is_struct(_state) || !is_array(_state.frames) || array_length(_state.frames) == 0) {
            return "'" + _set.name + "' has no " + _states[_s] + " frames";
        }
        var _f = 0;
        while (_f < array_length(_state.frames)) {
            var _sprite = scr_asset_find_by_name(_state.frames[_f]);
            if (_sprite == undefined || _sprite.type != "SPRITE") return "'" + _set.name + "' " + _states[_s] + " frame '" + _state.frames[_f] + "' is not a sprite";
            if (_sprite.height != _set.height) return "'" + _set.name + "' frame '" + _state.frames[_f] + "' is " + string(_sprite.height) + " high, the set is " + string(_set.height);
            _f += 1;
        }
        _s += 1;
    }
    return "";
}

/// "" when the map, its tileset and its enemies can be built, else the problem.
function scr_gk_map_problem(_map) {
    if (_map == undefined || _map.type != "TILEMAP") return "map not found";
    var _tileset = scr_asset_find_by_name(_map.tileset);
    if (_tileset == undefined || _tileset.type != "TILESET") return "map '" + _map.name + "' uses missing tileset '" + _map.tileset + "'";
    if (_tileset.tile_size * _map.room_cols > 320 || _map.room_cols != scr_gk_room_cols(_tileset.tile_size)) return "map '" + _map.name + "' room size does not match its tileset's tile size";
    if (array_length(_map.cells) != _map.width * _map.height) return "map '" + _map.name + "' cells are damaged";
    var _per_room = array_create(_map.rooms_x * _map.rooms_y, 0);
    var _e = 0;
    while (_e < array_length(_map.enemies)) {
        var _enemy = _map.enemies[_e];
        var _problem = scr_gk_animset_problem(scr_asset_find_by_name(_enemy.animset));
        if (_problem != "") return "enemy " + string(_e + 1) + ": " + _problem;
        var _room = clamp(_enemy.x div (_map.room_cols * _tileset.tile_size), 0, _map.rooms_x - 1)
            + clamp(_enemy.y div (_map.room_rows * _tileset.tile_size), 0, _map.rooms_y - 1) * _map.rooms_x;
        _per_room[_room] += 1;
        if (_per_room[_room] > GK_ENEMIES_PER_ROOM) return "more than " + string(GK_ENEMIES_PER_ROOM) + " enemies in one room of '" + _map.name + "'";
        _e += 1;
    }
    return "";
}
