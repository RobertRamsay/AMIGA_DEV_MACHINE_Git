/// @desc Node graphs and assets for the tutorials (see scr_tutorials).
/// Everything is generated: tile art for 8/16/24/32 px tilesets, metatiles up
/// to 128 x 128, maps, a hero and an enemy with four frames in every animation
/// state, (tutorial 10) a short ProTracker tune and three sound effects, and
/// for the classic-hardware tutorials 11-15 bitmaps, a 4-frame sprite bird, a
/// 4-frame BOB ship and a song written with the TRACKER's song model.
/// The user can repaint and re-tune all of it afterwards.

// Tile indices every tutorial tileset shares.
#macro TB_T_GROUND 1
#macro TB_T_BRICK 2
#macro TB_T_PLAT 3
#macro TB_T_SPIKE 4
#macro TB_T_GEM 5
#macro TB_T_DOOR 6
#macro TB_T_CLOUD 7
#macro TB_T_DIRT 8

/// Builds tutorial _number (1..10) into the cleared workspace. Returns true on success.
function scr_tutorial_build(_number) {
    var _init = scr_tutorial_make_init();
    if (_init == noone) return false;
    var _chain = { root : _init, y : _init.node_y + _init.node_height };

    switch (_number) {
        case 1: scr_tutorial_build_1(_chain); break;
        case 2: scr_tutorial_build_2(_chain); break;
        case 3: scr_tutorial_build_3(_chain); break;
        case 4: scr_tutorial_build_4(_chain); break;
        case 5: scr_tutorial_build_5(_chain); break;
        case 6: scr_tutorial_build_6(_chain); break;
        case 7: scr_tutorial_build_7(_chain); break;
        case 8: scr_tutorial_build_8(_chain); break;
        case 9: scr_tutorial_build_9(_chain); break;
        case 10: scr_tutorial_build_10(_chain); break;
        case 11: scr_tutorial_build_11(_chain); break;
        case 12: scr_tutorial_build_12(_chain); break;
        case 13: scr_tutorial_build_13(_chain); break;
        case 14: scr_tutorial_build_14(_chain); break;
        case 15: scr_tutorial_build_15(_chain); break;
        default: return false;
    }
    return true;
}

/// Fresh INIT root at the usual place; returns it.
function scr_tutorial_make_init() {
    var _init_x = (room_width / 2) - 80;
    var _init_y = room_height / 4;
    var _init = instance_create_layer(_init_x, _init_y, "Instances", obj_amiga_root_node);
    _init.root_type = "INIT";
    _init.node_x = scr_snap_to_grid(_init_x, global.grid_size);
    _init.node_y = scr_snap_to_grid(_init_y, global.grid_size);
    return _init;
}

// ---------------------------------------------------------------------------
// Node chain helpers: each new node goes under the previous one.

function scr_tb_place(_chain, _node) {
    _node.node_x = _chain.root.node_x;
    _node.node_y = _chain.y;
    _node.is_connected = true;
    _node.root_uid = _chain.root.uid;
    _chain.y += _node.node_height;
    return _node;
}

function scr_tb_macro(_chain, _type) {
    var _node = instance_create_layer(_chain.root.node_x, _chain.y, "Instances", obj_opcode_node);
    if (scr_gk_is_node_type(_type)) {
        scr_gk_node_init(_node, _type);
    } else {
        scr_macro_node_init(_node, _type);
    }
    if (_type == "SETBKG" || _type == "COPPER_BAR") _node.node_height = 100;
    return scr_tb_place(_chain, _node);
}

/// Opcode node; _mode_* "" leaves that operand at its default.
function scr_tb_op(_chain, _mnemonic, _size, _mode_src, _src, _mode_dst, _dst) {
    var _node = instance_create_layer(_chain.root.node_x, _chain.y, "Instances", obj_opcode_node);
    _node.opcode_mnemonic = _mnemonic;
    _node.opcode_size = _size != "" ? _size : scr_pick_default_size(global.opcode_map[$ _mnemonic].sizes);
    if (_mode_src != "") {
        _node.addressing_mode_src = _mode_src;
        if (_mode_src == "LABEL") _node.operand_label_src = _src; else _node.operand_src = _src;
    }
    if (_mode_dst != "") {
        _node.addressing_mode_dst = _mode_dst;
        if (_mode_dst == "LABEL") _node.operand_label_dst = _dst; else _node.operand_dst = _dst;
    }
    return scr_tb_place(_chain, _node);
}

/// Labels _first and closes the loop with BRA back to it.
function scr_tb_loop(_chain, _first, _label) {
    _first.node_label = _label;
    return scr_tb_op(_chain, "BRA", "W", "LABEL", _label, "", 0);
}

/// The Game Kit set-up every game tutorial starts with.
function scr_tb_gk_start(_chain, _map_name, _hero_name) {
    scr_tb_macro(_chain, "GK_SCREEN");
    var _map = scr_tb_macro(_chain, "GK_MAP");
    _map.macro_asset_name = _map_name;
    if (_hero_name != "") {
        var _player = scr_tb_macro(_chain, "GK_PLAYER");
        _player.macro_asset_name = _hero_name;
    }
}

// ---------------------------------------------------------------------------
// Tilesets: the same eight tiles drawn at any tile size.

function scr_tb_tileset(_name, _size) {
    var _ts = scr_gk_tileset_define(_name, _size);
    //              sky dirt dk  grass lt  brick mort plk pl2 spk sp2 gem  gm2 door gold cloud
    _ts.colour_r = [1,  8,   5,  3,    8,  11,   6,   13, 9,  13, 6,  2,   15, 4,   15,  9];
    _ts.colour_g = [3,  5,   3,  12,   15, 4,    5,   9,  6,  13, 6,  14,  15, 2,   12,  10];
    _ts.colour_b = [8,  2,   1,  2,    4,  2,    5,   4,  3,  14, 8,  15,  15, 1,   2,   15];
    var _flags = [0, GK_FLAG_SOLID, GK_FLAG_SOLID, GK_FLAG_PLATFORM, GK_FLAG_HAZARD, GK_FLAG_COLLECT, GK_FLAG_EXIT, 0, GK_FLAG_SOLID];
    var _kind = 1;
    while (_kind <= 8) {
        var _tile = scr_gk_tileset_add_tile(_ts);
        _ts.flags[_tile] = _flags[_kind];
        var _py = 0;
        while (_py < _size) {
            var _px = 0;
            while (_px < _size) {
                scr_gk_tile_set(_ts, _tile, _px, _py, scr_tb_tile_colour(_kind, _px, _py, _size));
                _px += 1;
            }
            _py += 1;
        }
        _kind += 1;
    }
    return _ts;
}

/// Colour of pixel (_x, _y) of tile _kind at tile size _s.
function scr_tb_tile_colour(_kind, _x, _y, _s) {
    var _c = (_s - 1) / 2;
    switch (_kind) {
        case TB_T_GROUND:
            var _grass = max(2, _s div 4);
            if (_y < _grass) return (_y == 0 || (_x + _y) mod 3 == 0) ? 4 : 3;
            if (_y == _grass) return (_x mod 4 < 2) ? 3 : 1;
            return ((_x * 5 + _y * 3) mod 7 == 0) ? 2 : 1;
        case TB_T_DIRT:
            return ((_x * 5 + _y * 3) mod 7 == 0) ? 2 : 1;
        case TB_T_BRICK:
            var _bh = max(2, _s div 4);
            var _bw = max(4, _s div 2);
            var _shift = ((_y div _bh) mod 2) * (_bw div 2);
            if (_y mod _bh == _bh - 1 || (_x + _shift) mod _bw == _bw - 1) return 6;
            return 5;
        case TB_T_PLAT:
            var _ph = max(2, _s div 4);
            if (_y < _ph) return (_y == _ph - 1 || _x mod max(4, _s div 2) == 0) ? 8 : 7;
            if (_y < _ph + max(1, _s div 4) && (_x == 1 || _x == _s - 2)) return 8;
            return 0;
        case TB_T_SPIKE:
            var _w = _s / 2;
            var _lx = _x mod (_s div 2);
            var _mid = (_w - 1) / 2;
            var _height = (1 - abs(_lx - _mid) / (_w / 2)) * _s * 0.9;
            if (_y == _s - 1) return 10;
            if ((_s - 1 - _y) < _height) return _lx <= _mid ? 9 : 10;
            return 0;
        case TB_T_GEM:
            var _d = abs(_x - _c) + abs(_y - _c) * 1.25;
            if (_d < _s * 0.4) return (_x < _c && _y < _c && _d > _s * 0.12) ? 12 : 11;
            return 0;
        case TB_T_DOOR:
            var _left = floor(_s * 0.15);
            var _right = ceil(_s * 0.85) - 1;
            if (_x < _left || _x > _right) return 0;
            var _arch = _s * 0.35;
            if (_y < _arch) {
                var _dx = (_x - _c) / ((_right - _left + 1) / 2);
                var _dy = (_arch - _y) / _arch;
                if (_dx * _dx + _dy * _dy > 1) return 0;
            }
            if (_x == _left || _x == _right || _y == _s - 1) return 14;
            if (_x == floor(_s * 0.68) && _y == floor(_s * 0.6)) return 14;
            return 13;
        case TB_T_CLOUD:
            var _ax = (_x - _s * 0.35) / (_s * 0.28);
            var _ay = (_y - _s * 0.55) / (_s * 0.22);
            var _bx = (_x - _s * 0.65) / (_s * 0.3);
            var _by = (_y - _s * 0.45) / (_s * 0.28);
            if (_ax * _ax + _ay * _ay <= 1 || _bx * _bx + _by * _by <= 1) return 15;
            return 0;
    }
    return 0;
}

/// Metatile of _w x _h tiles filled by the named recipe.
function scr_tb_metatile(_ts, _name, _w, _h, _recipe) {
    var _meta = scr_gk_metatile_add(_ts, _name, _w, _h);
    if (_meta == undefined) return undefined;
    var _row = 0;
    while (_row < _h) {
        var _col = 0;
        while (_col < _w) {
            var _tile = 0;
            switch (_recipe) {
                case "ledge": _tile = TB_T_PLAT; break;
                case "block": _tile = TB_T_BRICK; break;
                case "hill": _tile = _row == 0 ? TB_T_GROUND : TB_T_DIRT; break;
                case "clouds": _tile = (_row + _col) mod 2 == 0 ? TB_T_CLOUD : 0; break;
                case "pyramid":
                    // Steps one tile wide and two tiles high: every step is a jump.
                    var _half = 1 + (_row div 2);
                    _tile = (_col >= _w div 2 - _half && _col < _w div 2 + _half) ? TB_T_BRICK : 0;
                    break;
            }
            _meta.cells[_row * _w + _col] = _tile;
            _col += 1;
        }
        _row += 1;
    }
    return _meta;
}

function scr_tb_find_meta(_ts, _name) {
    var _i = 0;
    while (_i < array_length(_ts.metatiles)) {
        if (_ts.metatiles[_i].name == _name) return _ts.metatiles[_i];
        _i += 1;
    }
    return undefined;
}

// ---------------------------------------------------------------------------
// Map painting.

function scr_tb_fill(_map, _c0, _r0, _c1, _r1, _tile) {
    var _row = _r0;
    while (_row <= _r1) {
        var _col = _c0;
        while (_col <= _c1) {
            scr_gk_map_set(_map, _col, _row, _tile);
            _col += 1;
        }
        _row += 1;
    }
}

/// Grass on _row, dirt below down to _bottom, from column _c0 to _c1.
function scr_tb_ground(_map, _c0, _c1, _row, _bottom) {
    scr_tb_fill(_map, _c0, _row, _c1, _row, TB_T_GROUND);
    if (_bottom > _row) scr_tb_fill(_map, _c0, _row + 1, _c1, _bottom, TB_T_DIRT);
}

/// Player start standing in cell (_col, _row) (feet on the cell's bottom edge).
function scr_tb_spawn(_map, _size, _col, _row, _hero_h) {
    _map.spawn_x = _col * _size;
    _map.spawn_y = (_row + 1) * _size - _hero_h;
}

function scr_tb_enemy(_map, _size, _col, _row, _set_name, _h) {
    array_push(_map.enemies, { x : _col * _size, y : (_row + 1) * _size - _h, animset : _set_name, speed : 1 });
}

// ---------------------------------------------------------------------------
// Sprites: a hero and an enemy, four frames in every state.

function scr_tb_px(_canvas, _x, _y, _colour) {
    _x = round(_x);
    _y = round(_y);
    if (_x < 0 || _x > 15 || _y < 0 || _y >= _canvas.h) return;
    _canvas.p[_y * 16 + _x] = _colour;
}

function scr_tb_rect(_canvas, _x0, _y0, _x1, _y1, _colour) {
    var _y = _y0;
    while (_y <= _y1) {
        var _x = _x0;
        while (_x <= _x1) {
            scr_tb_px(_canvas, _x, _y, _colour);
            _x += 1;
        }
        _y += 1;
    }
}

/// Two pixels wide line (limbs).
function scr_tb_limb(_canvas, _x0, _y0, _x1, _y1, _colour) {
    var _steps = max(1, max(abs(_x1 - _x0), abs(_y1 - _y0)));
    var _i = 0;
    while (_i <= _steps) {
        var _x = lerp(_x0, _x1, _i / _steps);
        var _y = lerp(_y0, _y1, _i / _steps);
        scr_tb_px(_canvas, _x, _y, _colour);
        scr_tb_px(_canvas, _x + 1, _y, _colour);
        _i += 1;
    }
}

/// Hero frame _frame (0..3) of _state, 16 x _h, facing right.
/// Colours: 1 dark (hair, trousers, eye), 2 shirt, 3 skin.
function scr_tb_hero_pixels(_h, _state, _frame) {
    var _canvas = { h : _h, p : array_create(16 * _h, 0) };
    var _head = max(4, round(_h * 0.3));
    var _hip = round(_h * 0.62);
    var _arm = max(2, round(_h * 0.2));
    var _bob = 0;
    var _feet = [[5, _h - 1], [9, _h - 1]];
    var _hands = [[3, 0], [11, 0]];          // y relative to the shoulder

    switch (_state) {
        case "idle":
            _bob = [0, 0, 1, 1][_frame];
            _hands = [[3, _arm - _bob], [11, _arm - _bob]];
            break;
        case "run":
            _bob = [0, 1, 0, 1][_frame];
            _feet = [[[2, _h - 1], [5, _h - 1], [6, _h - 3], [8, _h - 2]][_frame], [[11, _h - 1], [9, _h - 3], [11, _h - 1], [7, _h - 1]][_frame]];
            _hands = [[[12, _arm - 1], [8, _arm], [2, _arm - 1], [6, _arm]][_frame], [[2, _arm - 1], [6, _arm], [12, _arm - 1], [9, _arm]][_frame]];
            break;
        case "jump":
            _feet = [[5, _h - 3 - (_frame mod 2)], [10, _h - 4 + (_frame div 2)]];
            _hands = [[3, -_arm + (_frame mod 2)], [12, -_arm - 1 + (_frame mod 2)]];
            break;
        case "fall":
            _feet = [[3, _h - 1 - (_frame mod 2)], [12, _h - 1 - ((_frame + 1) mod 2)]];
            _hands = [[1, -_arm div 2 + (_frame mod 2)], [14, -_arm div 2 + ((_frame + 1) mod 2)]];
            break;
    }

    var _top = _bob;
    var _shoulder = _top + _head + 1;
    // Legs, body, arms, head - later parts cover earlier ones.
    scr_tb_limb(_canvas, 5, _hip + 1, _feet[0][0], _feet[0][1], 1);
    scr_tb_limb(_canvas, 9, _hip + 1, _feet[1][0], _feet[1][1], 1);
    scr_tb_rect(_canvas, 5, _top + _head, 10, _hip, 2);
    scr_tb_rect(_canvas, 5, _hip, 10, _hip, 1);
    scr_tb_limb(_canvas, 4, _shoulder, _hands[0][0], _shoulder + _hands[0][1], 3);
    scr_tb_limb(_canvas, 10, _shoulder, _hands[1][0], _shoulder + _hands[1][1], 3);
    scr_tb_rect(_canvas, 5, _top, 10, _top + _head - 1, 3);
    scr_tb_rect(_canvas, 5, _top, 10, _top + max(0, _head div 4), 1);
    scr_tb_rect(_canvas, 5, _top, 5, _top + _head div 2, 1);
    scr_tb_px(_canvas, 9, _top + _head div 2, 1);
    return _canvas.p;
}

/// Slime enemy frame _frame (0..3), 16 x _h: squashes and stretches.
function scr_tb_slime_pixels(_h, _frame) {
    var _canvas = { h : _h, p : array_create(16 * _h, 0) };
    var _squash = [0, 1, 2, 1][_frame];
    var _rx = 6.5 + _squash * 0.5;
    var _ry = max(3, _h * 0.38 - _squash * 0.7);
    var _cy = _h - 0.5 - _ry;
    var _y = 0;
    while (_y < _h) {
        var _x = 0;
        while (_x < 16) {
            var _dx = (_x - 7.5) / _rx;
            var _dy = (_y - _cy) / _ry;
            var _d = _dx * _dx + _dy * _dy;
            if (_d <= 1) scr_tb_px(_canvas, _x, _y, _d > 0.72 ? 1 : 2);
            _x += 1;
        }
        _y += 1;
    }
    var _eye = round(_cy - _ry * 0.3);
    scr_tb_rect(_canvas, 4, _eye - 1, 6, _eye, 3);
    scr_tb_rect(_canvas, 9, _eye - 1, 11, _eye, 3);
    scr_tb_px(_canvas, 6, _eye, 1);
    scr_tb_px(_canvas, 11, _eye, 1);
    return _canvas.p;
}

/// The hero: 16 SPRITE assets "<name>_<state>_<n>" and the ANIMSET <name>.
function scr_tb_hero(_name, _h) {
    var _set = scr_gk_animset_define(_name, _h);
    var _states = GK_ANIM_STATES;
    var _s = 0;
    while (_s < array_length(_states)) {
        var _frames = [];
        var _f = 0;
        while (_f < 4) {
            var _sprite_name = _name + "_" + _states[_s] + "_" + string(_f);
            scr_asset_define_sprite(_sprite_name, 0, _h, 262144, scr_tb_hero_pixels(_h, _states[_s], _f), [2, 13, 15], [2, 3, 11], [4, 2, 8]);
            array_push(_frames, _sprite_name);
            _f += 1;
        }
        _set.states[$ _states[_s]].frames = _frames;
        _s += 1;
    }
    return _set;
}

/// The enemy: 4 SPRITE frames shared by its four states (it only walks).
function scr_tb_slime(_name, _h) {
    var _set = scr_gk_animset_define(_name, _h);
    var _frames = [];
    var _f = 0;
    while (_f < 4) {
        var _sprite_name = _name + "_" + string(_f);
        scr_asset_define_sprite(_sprite_name, 2, _h, 262144, scr_tb_slime_pixels(_h, _f), [2, 9, 15], [1, 3, 15], [3, 12, 15]);
        array_push(_frames, _sprite_name);
        _f += 1;
    }
    var _states = GK_ANIM_STATES;
    var _s = 0;
    while (_s < array_length(_states)) {
        _set.states[$ _states[_s]].frames = [_frames[0], _frames[1], _frames[2], _frames[3]];
        _s += 1;
    }
    _set.states.run.rate = 8;
    return _set;
}

// ---------------------------------------------------------------------------
// Sound: three effects and a short 4-channel tune, all synthesised.

function scr_tb_sample(_name, _length, _kind) {
    _length = _length - (_length mod 2);
    var _buffer = buffer_create(_length, buffer_fixed, 1);
    var _phase = 0;
    var _seed = 12345;
    var _held = 0;
    var _i = 0;
    while (_i < _length) {
        var _t = _i / _length;
        var _v = 0;
        switch (_kind) {
            case "jump":
                _phase += 1 / (36 - 26 * _t);
                _v = (frac(_phase) < 0.5 ? 80 : -80) * (1 - _t);
                break;
            case "pickup":
                _phase += 1 / (_t < 0.4 ? 9 : 6);
                _v = (frac(_phase) < 0.5 ? 70 : -70) * (1 - _t * 0.8);
                break;
            case "hurt":
                if (_i mod (1 + _i div 300) == 0) {
                    _seed = (_seed * 1103515245 + 12345) mod 2147483648;
                    _held = ((_seed div 65536) mod 256) - 128;
                }
                _v = _held * (1 - _t);
                break;
            case "drum":
                if (_i mod (1 + _i div 250) == 0) {
                    _seed = (_seed * 1103515245 + 12345) mod 2147483648;
                    _held = ((_seed div 65536) mod 256) - 128;
                }
                _phase += 1 / (20 + 60 * _t);
                _v = (_held * 0.5 + sin(_phase * 2 * pi) * 70) * power(1 - _t, 2);
                break;
            case "lead":
                _v = _i < _length / 2 ? 60 : -60;
                break;
            case "bass":
                _v = (_t < 0.5 ? (_t * 4 - 1) : (3 - _t * 4)) * 100;
                break;
        }
        buffer_write(_buffer, buffer_s8, clamp(round(_v), -127, 127));
        _i += 1;
    }
    return _buffer;
}

function scr_tb_sfx(_name, _length, _kind) {
    var _buffer = scr_tb_sample(_name, _length, _kind);
    var _size = buffer_get_size(_buffer);
    scr_audio_define_sample(_name, buffer_base64_encode(_buffer, 0, _size), _size, 322, 64, false, 0, 0, "tutorial");
    buffer_delete(_buffer);
}

function scr_tb_u16(_buffer, _at, _value) {
    buffer_poke(_buffer, _at, buffer_u8, (_value div 256) mod 256);
    buffer_poke(_buffer, _at + 1, buffer_u8, _value mod 256);
}

function scr_tb_mod_note(_buffer, _pattern, _row, _channel, _sample, _period) {
    var _at = 1084 + _pattern * 1024 + _row * 16 + _channel * 4;
    buffer_poke(_buffer, _at, buffer_u8, (_sample & $F0) | ((_period >> 8) & $0F));
    buffer_poke(_buffer, _at + 1, buffer_u8, _period & $FF);
    buffer_poke(_buffer, _at + 2, buffer_u8, (_sample & $0F) << 4);
    buffer_poke(_buffer, _at + 3, buffer_u8, 0);
}

/// A 2-pattern M.K. module: lead, bass and drum. Returns the MOD asset name.
function scr_tb_tune(_name) {
    var _samples = [scr_tb_sample("lead", 32, "lead"), scr_tb_sample("bass", 64, "bass"), scr_tb_sample("drum", 2400, "drum")];
    var _loops = [true, true, false];
    var _volumes = [36, 56, 64];
    var _patterns = 2;
    var _data_size = 0;
    var _s = 0;
    while (_s < 3) {
        _data_size += buffer_get_size(_samples[_s]);
        _s += 1;
    }
    var _length = 1084 + _patterns * 1024 + _data_size;
    var _buffer = buffer_create(_length, buffer_fixed, 1);
    buffer_fill(_buffer, 0, buffer_u8, 0, _length);

    var _title = "adm tutorial tune";
    var _c = 0;
    while (_c < string_length(_title)) {
        buffer_poke(_buffer, _c, buffer_u8, ord(string_char_at(_title, _c + 1)));
        _c += 1;
    }
    // 31 sample headers; unused ones keep a 1-word repeat as ProTracker writes them.
    _s = 0;
    while (_s < 31) {
        var _at = 20 + _s * 30;
        if (_s < 3) {
            var _words = buffer_get_size(_samples[_s]) div 2;
            var _sname = ["lead", "bass", "drum"][_s];
            _c = 0;
            while (_c < string_length(_sname)) {
                buffer_poke(_buffer, _at + _c, buffer_u8, ord(string_char_at(_sname, _c + 1)));
                _c += 1;
            }
            scr_tb_u16(_buffer, _at + 22, _words);
            buffer_poke(_buffer, _at + 25, buffer_u8, _volumes[_s]);
            scr_tb_u16(_buffer, _at + 28, _loops[_s] ? _words : 1);
        } else {
            scr_tb_u16(_buffer, _at + 28, 1);
        }
        _s += 1;
    }
    buffer_poke(_buffer, 950, buffer_u8, 4);
    buffer_poke(_buffer, 951, buffer_u8, 127);
    var _order = [0, 1, 0, 1];
    var _o = 0;
    while (_o < 4) {
        buffer_poke(_buffer, 952 + _o, buffer_u8, _order[_o]);
        _o += 1;
    }
    buffer_poke(_buffer, 1080, buffer_u8, ord("M"));
    buffer_poke(_buffer, 1081, buffer_u8, ord("."));
    buffer_poke(_buffer, 1082, buffer_u8, ord("K"));
    buffer_poke(_buffer, 1083, buffer_u8, ord("."));

    // Periods: octave 1, 2, 3 of C D E F G A B.
    var _C1 = 856, _F1 = 640, _G1 = 570, _A1 = 508;
    var _C2 = 428, _D2 = 381, _E2 = 339, _F2 = 320, _G2 = 285, _A2 = 254, _B2 = 226;
    var _C3 = 214, _D3 = 190, _E3 = 170, _F3 = 160, _G3 = 143, _A3 = 127;
    var _melody = [
        [_C3, _E3, _G3, _E3, _D3, _F3, _A3, _F3, _E3, _G3, _C3, _G3, _D3, _B2, _G2, _B2,
         _C3, _E3, _G3, _A3, _G3, _E3, _D3, _C3, _A2, _C3, _E3, _C3, _G2, _B2, _D3, _B2],
        [_A2, _C3, _E3, _C3, _F2, _A2, _C3, _A2, _G2, _B2, _D3, _B2, _C3, _E3, _G3, _E3,
         _A3, _G3, _E3, _C3, _F3, _E3, _D3, _A2, _G2, _B2, _D3, _G3, _E3, _D3, _C3, _C3]
    ];
    var _bass = [
        [_C1, _C1, _G1, _G1, _F1, _F1, _G1, _G1, _C1, _C1, _A1, _A1, _F1, _F1, _G1, _G1],
        [_A1, _A1, _F1, _F1, _G1, _G1, _C1, _C1, _A1, _A1, _F1, _F1, _G1, _G1, _C1, _C1]
    ];
    var _p = 0;
    while (_p < _patterns) {
        var _row = 0;
        while (_row < 64) {
            if (_row mod 2 == 0) scr_tb_mod_note(_buffer, _p, _row, 0, 1, _melody[_p][_row div 2]);
            if (_row mod 4 == 0) scr_tb_mod_note(_buffer, _p, _row, 1, 2, _bass[_p][_row div 4]);
            if (_row mod 8 == 0 || _row mod 16 == 14) scr_tb_mod_note(_buffer, _p, _row, 2, 3, _C2);
            _row += 1;
        }
        _p += 1;
    }

    var _write_at = 1084 + _patterns * 1024;
    _s = 0;
    while (_s < 3) {
        var _size = buffer_get_size(_samples[_s]);
        buffer_copy(_samples[_s], 0, _size, _buffer, _write_at);
        _write_at += _size;
        buffer_delete(_samples[_s]);
        _s += 1;
    }

    var _info = scr_audio_mod_info(_buffer);
    if (_info.ok) {
        scr_audio_define_mod(_name, scr_audio_buffer_b64(_buffer, _length), _length, _info.title, _info.positions, _info.patterns, _info.samples_used, "tutorial");
    } else {
        show_debug_message("[tutorial] generated MOD rejected: " + _info.err);
        _name = "";
    }
    buffer_delete(_buffer);
    return _name;
}

// ---------------------------------------------------------------------------
// The tutorials.

/// 1: SETBKG and an endless loop.
function scr_tutorial_build_1(_chain) {
    var _bkg = scr_tb_macro(_chain, "SETBKG");
    _bkg.macro_asset_name = "05C";
    var _nop = scr_tb_op(_chain, "NOP", "", "", 0, "", 0);
    scr_tb_loop(_chain, _nop, "forever");
}

/// 2: count in D0 and write it to COLOR00.
function scr_tutorial_build_2(_chain) {
    scr_tb_op(_chain, "MOVEQ", "", "#imm", 0, "Dn", 0);
    var _move = scr_tb_op(_chain, "MOVE", "W", "Dn", 0, "abs.L", $DFF180);
    scr_tb_op(_chain, "ADDQ", "W", "#imm", 1, "Dn", 0);
    scr_tb_loop(_chain, _move, "cycle");
}

/// 3: a Copper gradient.
function scr_tutorial_build_3(_chain) {
    var _bar = scr_tb_macro(_chain, "COPPER_BAR");
    _bar.macro_cprbar_band_count = 8;
    _bar.macro_cprbar_target_register = 0;
    _bar.macro_cprbar_equidistant = true;
    _bar.macro_cprbar_vp_start = 44;
    _bar.macro_cprbar_vp_end = 300;
    var _sunset = ["014", "026", "238", "538", "947", "C64", "F93", "FD7"];
    var _b = 0;
    while (_b < 8) {
        _bar.macro_cprbar_bands[_b] = _sunset[_b];
        _b += 1;
    }
    var _nop = scr_tb_op(_chain, "NOP", "", "", 0, "", 0);
    scr_tb_loop(_chain, _nop, "forever");
}

/// 4: a CODE block that slides a raster bar down the screen.
function scr_tutorial_build_4(_chain) {
    var _code = scr_tb_macro(_chain, "CODE");
    _code.macro_code_text = scr_tb_raster_code_text();
    _code.macro_code_name = "Raster bar";
}

/// Tutorial 4's CODE block (also the editor tour's demo code).
function scr_tb_raster_code_text() {
    return "; A raster bar: COLOR00 changes on two scanlines every frame.\n"
        + "; Ctrl+Space completes, hover a word for help, F5 builds and runs.\n"
        + "\tlea\tCUSTOM,a6\n"
        + "\tmoveq\t#0,d2\t\t; bar position (0..179)\n"
        + "rb_frame:\n"
        + ".top\tmove.l\tVPOSR(a6),d0\t; wait for raster line 16\n"
        + "\tand.l\t#$1ff00,d0\n"
        + "\tcmp.l\t#$01000,d0\n"
        + "\tbne.s\t.top\n"
        + "\tmove.w\t#$004,COLOR00(a6)\t; dark blue sky\n"
        + "\tmove.w\td2,d1\n"
        + "\tadd.w\t#$40,d1\t\t; the line the bar starts on\n"
        + ".bar\tmove.w\tVHPOSR(a6),d0\n"
        + "\tlsr.w\t#8,d0\n"
        + "\tcmp.b\td1,d0\n"
        + "\tbne.s\t.bar\n"
        + "\tmove.w\t#$fd0,COLOR00(a6)\t; yellow bar\n"
        + "\taddq.w\t#8,d1\t\t; 8 lines high\n"
        + ".bar2\tmove.w\tVHPOSR(a6),d0\n"
        + "\tlsr.w\t#8,d0\n"
        + "\tcmp.b\td1,d0\n"
        + "\tbne.s\t.bar2\n"
        + "\tmove.w\t#$004,COLOR00(a6)\n"
        + "\taddq.w\t#1,d2\t\t; move down one line per frame\n"
        + "\tcmp.w\t#180,d2\n"
        + "\tbne.s\trb_frame\n"
        + "\tmoveq\t#0,d2\n"
        + "\tbra.s\trb_frame\n";
}

/// 5: an 8 x 8 tile map on the Game Kit screen.
function scr_tutorial_build_5(_chain) {
    var _s = 8;
    var _ts = scr_tb_tileset("Tiles8", _s);
    var _clouds = scr_tb_metatile(_ts, "clouds", 4, 2, "clouds");
    var _block = scr_tb_metatile(_ts, "block4", 4, 4, "block");
    var _map = scr_gk_map_define("Meadow", "Tiles8", 1, 1);
    scr_tb_ground(_map, 0, 39, 28, 31);
    scr_tb_fill(_map, 6, 20, 9, 27, TB_T_BRICK);
    scr_gk_map_stamp(_map, _block, 30, 24, false);
    scr_gk_map_stamp(_map, _block, 30, 20, false);
    scr_tb_fill(_map, 14, 18, 24, 18, TB_T_PLAT);
    scr_tb_fill(_map, 12, 27, 13, 27, TB_T_SPIKE);
    scr_gk_map_set(_map, 16, 17, TB_T_GEM);
    scr_gk_map_set(_map, 19, 17, TB_T_GEM);
    scr_gk_map_set(_map, 22, 17, TB_T_GEM);
    scr_gk_map_set(_map, 36, 27, TB_T_DOOR);
    scr_gk_map_stamp(_map, _clouds, 4, 3, true);
    scr_gk_map_stamp(_map, _clouds, 20, 6, true);
    scr_gk_map_stamp(_map, _clouds, 33, 2, true);
    scr_tb_spawn(_map, _s, 2, 27, 16);

    scr_tb_gk_start(_chain, "Meadow", "");
    var _wait = scr_tb_macro(_chain, "GK_WAIT");
    scr_tb_loop(_chain, _wait, "gameloop");
}

/// 6: the hero on a 16 x 16 map, idling.
function scr_tutorial_build_6(_chain) {
    var _s = 16;
    scr_tb_tileset("Tiles16", _s);
    scr_tb_hero("Hero", 16);
    var _map = scr_gk_map_define("Garden", "Tiles16", 1, 1);
    scr_tb_ground(_map, 0, 19, 14, 15);
    scr_tb_fill(_map, 13, 11, 15, 13, TB_T_BRICK);
    scr_gk_map_set(_map, 9, 13, TB_T_GEM);
    scr_gk_map_set(_map, 17, 13, TB_T_DOOR);
    scr_gk_map_set(_map, 3, 3, TB_T_CLOUD);
    scr_gk_map_set(_map, 4, 3, TB_T_CLOUD);
    scr_gk_map_set(_map, 12, 5, TB_T_CLOUD);
    scr_tb_spawn(_map, _s, 4, 13, 16);

    scr_tb_gk_start(_chain, "Garden", "Hero");
    var _wait = scr_tb_macro(_chain, "GK_WAIT");
    scr_tb_macro(_chain, "GK_ANIMATE");
    scr_tb_macro(_chain, "GK_DRAW");
    scr_tb_loop(_chain, _wait, "gameloop");
}

/// 7: joystick and physics on a 32 x 32 map.
function scr_tutorial_build_7(_chain) {
    var _s = 32;
    var _ts = scr_tb_tileset("Tiles32", _s);
    var _step = scr_tb_metatile(_ts, "step2", 2, 1, "block");
    scr_tb_hero("Hero", 24);
    var _map = scr_gk_map_define("Hills", "Tiles32", 1, 1);
    scr_tb_ground(_map, 0, 9, 7, 7);
    scr_tb_fill(_map, 0, 0, 0, 6, TB_T_BRICK);
    scr_tb_fill(_map, 9, 0, 9, 6, TB_T_BRICK);
    scr_gk_map_stamp(_map, _step, 6, 6, false);
    scr_gk_map_set(_map, 8, 6, TB_T_BRICK);
    scr_gk_map_set(_map, 8, 5, TB_T_BRICK);
    scr_tb_fill(_map, 2, 4, 4, 4, TB_T_PLAT);
    scr_gk_map_set(_map, 3, 1, TB_T_CLOUD);
    scr_gk_map_set(_map, 6, 2, TB_T_CLOUD);
    scr_tb_spawn(_map, _s, 2, 6, 24);

    scr_tb_gk_start(_chain, "Hills", "Hero");
    var _wait = scr_tb_macro(_chain, "GK_WAIT");
    scr_tb_macro(_chain, "GK_INPUT");
    scr_tb_macro(_chain, "GK_PHYSICS");
    scr_tb_macro(_chain, "GK_ANIMATE");
    scr_tb_macro(_chain, "GK_DRAW");
    scr_tb_loop(_chain, _wait, "gameloop");
}

/// 8: jumping up one-way metatile ledges, 16 x 16 tiles.
function scr_tutorial_build_8(_chain) {
    var _s = 16;
    var _ts = scr_tb_tileset("Tiles16", _s);
    var _ledge = scr_tb_metatile(_ts, "ledge4", 4, 1, "ledge");
    var _block = scr_tb_metatile(_ts, "block2", 2, 2, "block");
    scr_tb_metatile(_ts, "hill64", 4, 4, "hill");
    scr_tb_hero("Hero", 16);
    var _map = scr_gk_map_define("Tower", "Tiles16", 1, 1);
    scr_tb_ground(_map, 0, 19, 14, 15);
    scr_tb_fill(_map, 0, 0, 0, 13, TB_T_BRICK);
    scr_tb_fill(_map, 19, 0, 19, 13, TB_T_BRICK);
    scr_gk_map_stamp(_map, _block, 15, 12, false);
    scr_gk_map_stamp(_map, _ledge, 3, 12, false);
    scr_gk_map_stamp(_map, _ledge, 8, 10, false);
    scr_gk_map_stamp(_map, _ledge, 13, 8, false);
    scr_gk_map_stamp(_map, _ledge, 8, 6, false);
    scr_gk_map_stamp(_map, _ledge, 3, 4, false);
    scr_gk_map_set(_map, 4, 3, TB_T_GEM);
    scr_gk_map_set(_map, 14, 2, TB_T_CLOUD);
    scr_tb_spawn(_map, _s, 2, 13, 16);

    scr_tb_gk_start(_chain, "Tower", "Hero");
    var _wait = scr_tb_macro(_chain, "GK_WAIT");
    scr_tb_macro(_chain, "GK_INPUT");
    var _physics = scr_tb_macro(_chain, "GK_PHYSICS");
    _physics.macro_param_a = 24;
    _physics.macro_param_b = 80;
    _physics.macro_param_c = 5;
    scr_tb_macro(_chain, "GK_ANIMATE");
    scr_tb_macro(_chain, "GK_DRAW");
    scr_tb_loop(_chain, _wait, "gameloop");
}

/// 9: two 24 x 24 rooms with gems, spikes and enemies.
function scr_tutorial_build_9(_chain) {
    var _s = 24;
    var _ts = scr_tb_tileset("Tiles24", _s);
    scr_tb_metatile(_ts, "ledge3", 3, 1, "ledge");
    scr_tb_hero("Hero", 24);
    scr_tb_slime("Slime", 16);
    var _map = scr_gk_map_define("Caves", "Tiles24", 2, 1);
    scr_tb_ground(_map, 0, 25, 9, 9);
    scr_tb_fill(_map, 17, 9, 18, 9, 0);                 // a pit: falling out respawns
    scr_tb_fill(_map, 0, 0, 0, 8, TB_T_BRICK);
    scr_tb_fill(_map, 25, 0, 25, 8, TB_T_BRICK);
    var _ledge = scr_tb_find_meta(_ts, "ledge3");
    scr_gk_map_stamp(_map, _ledge, 3, 7, false);
    scr_gk_map_stamp(_map, _ledge, 7, 5, false);
    scr_gk_map_stamp(_map, _ledge, 19, 7, false);
    var _gems = [[4, 6], [8, 4], [11, 8], [20, 6], [23, 8]];
    var _g = 0;
    while (_g < array_length(_gems)) {
        scr_gk_map_set(_map, _gems[_g][0], _gems[_g][1], TB_T_GEM);
        _g += 1;
    }
    scr_gk_map_set(_map, 6, 8, TB_T_SPIKE);
    scr_gk_map_set(_map, 14, 8, TB_T_SPIKE);
    scr_gk_map_set(_map, 3, 2, TB_T_CLOUD);
    scr_gk_map_set(_map, 16, 1, TB_T_CLOUD);
    scr_tb_spawn(_map, _s, 2, 8, 24);
    scr_tb_enemy(_map, _s, 10, 8, "Slime", 16);
    scr_tb_enemy(_map, _s, 15, 8, "Slime", 16);
    scr_tb_enemy(_map, _s, 22, 8, "Slime", 16);

    scr_tb_gk_start(_chain, "Caves", "Hero");
    var _wait = scr_tb_macro(_chain, "GK_WAIT");
    scr_tb_macro(_chain, "GK_INPUT");
    var _physics = scr_tb_macro(_chain, "GK_PHYSICS");
    _physics.macro_param_b = 96;                       // 24 px tiles: jump two tiles
    scr_tb_macro(_chain, "GK_EVENTS");
    scr_tb_macro(_chain, "GK_ENEMIES");
    scr_tb_macro(_chain, "GK_ANIMATE");
    scr_tb_macro(_chain, "GK_DRAW");
    scr_tb_loop(_chain, _wait, "gameloop");
}

/// 10: the complete game - six rooms, 64 and 128 px metatiles, music, sounds, exit.
function scr_tutorial_build_10(_chain) {
    var _s = 16;
    var _ts = scr_tb_tileset("Tiles16", _s);
    var _ledge = scr_tb_metatile(_ts, "ledge4", 4, 1, "ledge");
    var _hill = scr_tb_metatile(_ts, "hill64", 4, 4, "hill");
    var _pyramid = scr_tb_metatile(_ts, "pyramid128", 8, 8, "pyramid");
    scr_tb_metatile(_ts, "clouds64", 4, 4, "clouds");
    scr_tb_hero("Hero", 16);
    scr_tb_slime("Slime", 16);
    var _music = scr_tb_tune("TutorialTune");
    scr_tb_sfx("Jump", 2400, "jump");
    scr_tb_sfx("Pickup", 2600, "pickup");
    scr_tb_sfx("Hurt", 4000, "hurt");

    // 3 x 2 rooms of 20 x 16 tiles: a 60 x 32 map.
    var _map = scr_gk_map_define("Adventure", "Tiles16", 3, 2);
    scr_tb_ground(_map, 0, 59, 14, 15);                 // floor of the top rooms
    scr_tb_ground(_map, 0, 59, 30, 31);                 // floor of the bottom rooms
    scr_tb_fill(_map, 0, 0, 0, 31, TB_T_BRICK);
    scr_tb_fill(_map, 59, 0, 59, 31, TB_T_BRICK);

    // Room (0,0): start, a ledge onto a hill, a gap down into room (0,1).
    scr_gk_map_stamp(_map, _ledge, 4, 12, false);
    scr_gk_map_stamp(_map, _hill, 8, 10, false);
    scr_tb_fill(_map, 18, 14, 19, 15, 0);
    scr_gk_map_set(_map, 15, 13, TB_T_SPIKE);
    // Room (1,0): a 128 x 128 pyramid.
    scr_gk_map_stamp(_map, _pyramid, 26, 6, false);
    scr_gk_map_set(_map, 22, 13, TB_T_SPIKE);
    // Room (0,1): another pyramid to climb for a gem.
    scr_gk_map_stamp(_map, _pyramid, 1, 22, false);
    // Room (1,1): a pit, a ledge and a hill.
    scr_tb_fill(_map, 26, 30, 27, 31, 0);
    scr_gk_map_set(_map, 24, 29, TB_T_SPIKE);
    scr_gk_map_stamp(_map, _ledge, 34, 28, false);
    scr_gk_map_stamp(_map, _hill, 30, 26, false);
    // Room (2,1): a staircase of ledges up through a one-way trapdoor into room (2,0).
    var _stairs = [[42, 28], [47, 26], [42, 24], [47, 22], [42, 20], [47, 18], [44, 16]];
    var _st = 0;
    while (_st < array_length(_stairs)) {
        scr_gk_map_stamp(_map, _ledge, _stairs[_st][0], _stairs[_st][1], false);
        _st += 1;
    }
    scr_tb_fill(_map, 44, 14, 47, 14, TB_T_PLAT);
    scr_tb_fill(_map, 44, 15, 47, 15, 0);
    // Room (2,0): a last ledge and the exit door.
    scr_gk_map_stamp(_map, _ledge, 49, 11, false);
    scr_gk_map_set(_map, 57, 13, TB_T_DOOR);

    var _gems = [[9, 9], [13, 13], [29, 5], [4, 21], [31, 25], [37, 29], [50, 10], [52, 13]];
    var _g = 0;
    while (_g < array_length(_gems)) {
        scr_gk_map_set(_map, _gems[_g][0], _gems[_g][1], TB_T_GEM);
        _g += 1;
    }
    var _sky = [[3, 3], [12, 2], [25, 3], [36, 2], [45, 4], [55, 2]];
    _g = 0;
    while (_g < array_length(_sky)) {
        scr_gk_map_set(_map, _sky[_g][0], _sky[_g][1], TB_T_CLOUD);
        _g += 1;
    }
    scr_tb_spawn(_map, _s, 2, 13, 16);
    scr_tb_enemy(_map, _s, 14, 13, "Slime", 16);        // between the hill and the gap, away from the start
    scr_tb_enemy(_map, _s, 36, 13, "Slime", 16);
    scr_tb_enemy(_map, _s, 13, 29, "Slime", 16);
    scr_tb_enemy(_map, _s, 22, 29, "Slime", 16);
    scr_tb_enemy(_map, _s, 54, 13, "Slime", 16);

    if (_music != "") {
        var _play = scr_tb_macro(_chain, "PLAY_MOD");
        _play.macro_asset_name = _music;
    }
    scr_tb_gk_start(_chain, "Adventure", "Hero");
    var _wait = scr_tb_macro(_chain, "GK_WAIT");
    scr_tb_macro(_chain, "GK_INPUT");
    var _physics = scr_tb_macro(_chain, "GK_PHYSICS");
    _physics.macro_param_text_a = "Jump";
    var _events = scr_tb_macro(_chain, "GK_EVENTS");
    _events.macro_param_text_a = "Pickup";
    _events.macro_param_text_b = "Hurt";
    _events.macro_param_a = 1;
    scr_tb_macro(_chain, "GK_ENEMIES");
    scr_tb_macro(_chain, "GK_ANIMATE");
    scr_tb_macro(_chain, "GK_DRAW");
    scr_tb_loop(_chain, _wait, "gameloop");
}

// ---------------------------------------------------------------------------
// Classic hardware tutorials (11-15): macros, bitmaps, sprites, BOBs, sound.

/// An ORG root to the right of _chain's root (room for its nodes' labels),
/// continuing it; returns its chain.
function scr_tb_org(_chain) {
    var _org = instance_create_layer(_chain.root.node_x + 320, _chain.root.node_y, "Instances", obj_amiga_root_node);
    _org.root_type = "ORG";
    _org.node_x = scr_snap_to_grid(_chain.root.node_x + 320, global.grid_size);
    _org.node_y = _chain.root.node_y;
    _org.continues_from_root_uid = _chain.root.uid;
    return { root : _org, y : _org.node_y + _org.node_height };
}

/// Index of asset _name among the assets of _type (the frame numbers ANIM
/// BOB / ANIM SPR count), or 0.
function scr_tb_frame_index(_type, _name) {
    var _count = 0;
    var _i = 0;
    while (_i < array_length(global.asset_list)) {
        if (global.asset_list[_i].type == _type) {
            if (global.asset_list[_i].name == _name) return _count;
            _count += 1;
        }
        _i += 1;
    }
    return 0;
}

/// TestBitmap for tutorial 13: a moonlit sky over hills, colours 0-14, and
/// the bird's sprite colours in 17-19 (sprite channels 0 / 1 read them).
function scr_tb_night_bitmap() {
    //          0  1  2  3  4  5  6  7  8  9  10 11 12 13 14  15 16 17  18  19
    var _r = [0, 0, 0, 0, 1, 1, 2, 2, 3, 15, 12, 15, 1, 0, 15, 0, 0, 14, 15, 15];
    var _g = [0, 0, 1, 1, 1, 2, 2, 3, 4, 15, 12, 15, 2, 1, 13, 0, 0, 4,  10, 15];
    var _b = [1, 2, 3, 4, 5, 5, 6, 6, 7, 13, 10, 15, 3, 2, 5,  0, 0, 0,  0,  15];
    var _cr = array_create(32, 0);
    var _cg = array_create(32, 0);
    var _cb = array_create(32, 0);
    var _i = 0;
    while (_i < array_length(_r)) {
        _cr[_i] = _r[_i];
        _cg[_i] = _g[_i];
        _cb[_i] = _b[_i];
        _i += 1;
    }
    // 90 stars scattered by a fixed pseudo-random sequence.
    var _star = array_create(320 * 256, false);
    var _seed = 2024;
    var _s = 0;
    while (_s < 90) {
        _seed = (_seed * 1103515245 + 12345) mod 2147483648;
        var _sx = (_seed div 65536) mod 320;
        _seed = (_seed * 1103515245 + 12345) mod 2147483648;
        var _sy = (_seed div 65536) mod 150;
        _star[_sy * 320 + _sx] = true;
        _s += 1;
    }
    var _pixels = array_create(320 * 256, 0);
    var _y = 0;
    while (_y < 256) {
        var _x = 0;
        while (_x < 320) {
            // Sky: eight dithered bands, darkest at the top.
            var _band = _y / 200 * 8;
            var _k = floor(_band);
            if (frac(_band) > 0.5 && ((_x + _y) mod 2) == 0) _k += 1;
            var _c = 1 + clamp(_k, 0, 7);
            // Stars in the upper sky.
            if (_star[_y * 320 + _x]) _c = 11;
            // The moon, with a shaded crescent.
            var _mx = _x - 250;
            var _my = _y - 56;
            if (_mx * _mx + _my * _my < 22 * 22) _c = (_mx + 8) * (_mx + 8) + (_my - 6) * (_my - 6) < 18 * 18 ? 9 : 10;
            // Far and near hills.
            if (_y > 178 + 16 * sin(_x * 0.021) + 7 * sin(_x * 0.057 + 2)) _c = 12;
            if (_y > 210 + 11 * sin(_x * 0.034 + 1) + 4 * sin(_x * 0.11)) _c = 13;
            _pixels[_y * 320 + _x] = _c;
            _x += 1;
        }
        _y += 1;
    }
    scr_asset_define_bitmap("TestBitmap", _pixels, _cr, _cg, _cb);
}

/// Bird sprite frame _frame (0..3: wings up, level, down, level), 16 x 16.
/// Colours: 1 body, 2 wing, 3 eye and beak.
function scr_tb_bird_pixels(_frame) {
    var _canvas = { h : 16, p : array_create(16 * 16, 0) };
    var _tip = [2, 7, 13, 7][_frame];
    // Wing behind the body: from the shoulder out to the tip.
    scr_tb_limb(_canvas, 7, 8, 4, _tip, 2);
    scr_tb_limb(_canvas, 8, 8, 6, _tip, 2);
    scr_tb_limb(_canvas, 6, 8, 3, _tip, 2);
    // Body and tail.
    var _y = 0;
    while (_y < 16) {
        var _x = 0;
        while (_x < 16) {
            var _dx = (_x - 8) / 5.5;
            var _dy = (_y - 9) / 2.6;
            if (_dx * _dx + _dy * _dy <= 1) scr_tb_px(_canvas, _x, _y, 1);
            _x += 1;
        }
        _y += 1;
    }
    scr_tb_rect(_canvas, 1, 8, 3, 9, 1);
    scr_tb_px(_canvas, 0, 7, 1);
    // Head, eye, beak.
    scr_tb_rect(_canvas, 11, 5, 13, 8, 1);
    scr_tb_px(_canvas, 12, 6, 3);
    scr_tb_rect(_canvas, 14, 7, 15, 7, 3);
    // The near wing again in front for the downstroke.
    if (_frame == 2) scr_tb_limb(_canvas, 8, 9, 7, _tip, 2);
    return _canvas.p;
}

/// The song of tutorial 15, written with the TRACKER's song model
/// (scr_tracker_song): its starter kit - 1 pulse lead, 2 bass, 3 organ,
/// 4 kick, 5 snare, 6 hi-hat - and two patterns of Am F C G / F G Em Am.
/// Returns the MOD asset name, or "" when it could not be saved.
function scr_tb_tracker_song(_name) {
    var _song = scr_tracker_song_new();
    _song.title = "adm chiptune";
    array_push(_song.patterns, scr_tracker_pattern_empty());
    _song.order = [0, 1];
    var _periods = scr_audio_note_periods();
    // Chords as note numbers in octave 1 (0 = C, 9 = A ...): root, third, fifth.
    var _chords = [
        [[9, 12, 16], [5, 9, 12], [0, 4, 7], [7, 11, 14]],
        [[5, 9, 12], [7, 11, 14], [4, 7, 11], [9, 12, 16]]
    ];
    var _arp = [0, 1, 2, 1, 0, 1, 2, 2];
    var _p = 0;
    while (_p < 2) {
        var _cells = _song.patterns[_p];
        var _row = 0;
        while (_row < 64) {
            var _chord = _chords[_p][_row div 16];
            var _at = 0;
            // Lead arpeggio, an octave up in the second pattern's last bar.
            if (_row mod 2 == 0) {
                var _note = clamp(_chord[_arp[(_row div 2) mod 8]] + 12 + ((_p == 1 && _row >= 48) ? 12 : 0), 0, 35);
                _at = scr_tracker_cell_at(_row, 0);
                _cells[@ _at] = _periods[_note];
                _cells[@ _at + 1] = 1;
            }
            // Bass on the root.
            if (_row mod 4 == 0) {
                _at = scr_tracker_cell_at(_row, 1);
                _cells[@ _at] = _periods[clamp(_chord[0] + 12, 0, 35)];
                _cells[@ _at + 1] = 2;
            }
            // Drums: kick on the beat, snare on the back beat, hi-hat between.
            _at = scr_tracker_cell_at(_row, 2);
            if (_row mod 8 == 0) {
                _cells[@ _at] = _periods[12];
                _cells[@ _at + 1] = 4;
            } else if (_row mod 8 == 4) {
                _cells[@ _at] = _periods[12];
                _cells[@ _at + 1] = 5;
            }
            if (_row mod 4 == 2) {
                _at = scr_tracker_cell_at(_row, 3);
                _cells[@ _at] = _periods[12];
                _cells[@ _at + 1] = 6;
            }
            _row += 1;
        }
        _p += 1;
    }
    var _error = scr_tracker_song_save(_song, _name);
    if (_error != "") {
        show_debug_message("[tutorial] tracker song not saved: " + _error);
        return "";
    }
    return _name;
}

/// 11: how macros work - SETBKG and COPPER BAR in INIT, the loop in an ORG column.
function scr_tutorial_build_11(_chain) {
    var _bkg = scr_tb_macro(_chain, "SETBKG");
    _bkg.macro_asset_name = "112";
    var _bar = scr_tb_macro(_chain, "COPPER_BAR");
    _bar.macro_cprbar_band_count = 6;
    _bar.macro_cprbar_target_register = 0;
    _bar.macro_cprbar_equidistant = true;
    _bar.macro_cprbar_vp_start = 44;
    _bar.macro_cprbar_vp_end = 300;
    var _rainbow = ["E22", "F82", "FE3", "3C4", "38E", "84C"];
    var _b = 0;
    while (_b < 6) {
        _bar.macro_cprbar_bands[_b] = _rainbow[_b];
        _b += 1;
    }
    var _org = scr_tb_org(_chain);
    var _nop = scr_tb_op(_org, "NOP", "", "", 0, "", 0);
    scr_tb_loop(_org, _nop, "forever");
}

/// 12: a 32-colour bitmap picture.
function scr_tutorial_build_12(_chain) {
    scr_amiga_art_sunset_bitmap();
    var _show = scr_tb_macro(_chain, "BITMAP_DISPLAY");
    _show.macro_asset_name = "TestBitmap";
    var _nop = scr_tb_op(_chain, "NOP", "", "", 0, "", 0);
    scr_tb_loop(_chain, _nop, "forever");
}

/// 13: a flapping hardware-sprite bird over a night sky.
function scr_tutorial_build_13(_chain) {
    scr_tb_night_bitmap();
    var _f = 0;
    while (_f < 4) {
        scr_asset_define_sprite("Bird_" + string(_f), 0, 16, 262144, scr_tb_bird_pixels(_f), [14, 15, 15], [4, 10, 15], [0, 0, 15]);
        _f += 1;
    }
    var _first = scr_tb_frame_index("SPRITE", "Bird_0");
    var _show = scr_tb_macro(_chain, "SPRITE_BITMAP_TEST");
    _show.macro_asset_name = "Bird_0";
    _show.macro_object_id = 0;
    var _org = scr_tb_org(_chain);
    var _move = scr_tb_macro(_org, "MOVE_SPR");
    _move.macro_object_id = 0;
    _move.macro_speed_x = 2;
    _move.macro_speed_y = 1;
    var _anim = scr_tb_macro(_org, "ANIM_SPR");
    _anim.macro_object_id = 0;
    _anim.macro_anim_rate = 10;
    _anim.macro_anim_start = _first;
    _anim.macro_anim_end = _first + 3;
    _anim.macro_anim_loop = true;
    scr_tb_loop(_org, _move, "fly");
}

/// 14: a BOB spaceship over the sunset, restored and redrawn every frame.
function scr_tutorial_build_14(_chain) {
    scr_amiga_art_sunset_bitmap();
    var _f = 0;
    while (_f < 4) {
        scr_asset_define_bob("Ship_" + string(_f), 32, 32, scr_amiga_art_ship_pixels(_f));
        _f += 1;
    }
    global.current_bob_asset_name = "Ship_0";
    var _first = scr_tb_frame_index("BOB", "Ship_0");
    var _get = scr_tb_macro(_chain, "GET_BITMAP_BOB");
    _get.macro_asset_name = "Ship_0";
    _get.macro_object_id = 0;
    var _org = scr_tb_org(_chain);
    var _draw = scr_tb_macro(_org, "DRAW_BOB");
    _draw.macro_asset_name = "Ship_0";
    _draw.macro_object_id = 0;
    var _replace = scr_tb_macro(_org, "REPLACE_BITMAP_BOB");
    _replace.macro_asset_name = "Ship_0";
    _replace.macro_object_id = 0;
    var _move = scr_tb_macro(_org, "MOVE_BOB");
    _move.macro_object_id = 0;
    _move.macro_speed_x = 2;
    _move.macro_speed_y = 0;
    var _anim = scr_tb_macro(_org, "ANIM_BOB");
    _anim.macro_object_id = 0;
    _anim.macro_anim_rate = 12;
    _anim.macro_anim_start = _first;
    _anim.macro_anim_end = _first + 3;
    _anim.macro_anim_loop = true;
    scr_tb_loop(_org, _draw, "bobloop");
}

/// 15: music from the TRACKER, and a sound effect on the fire button.
function scr_tutorial_build_15(_chain) {
    var _music = scr_tb_tracker_song("Chiptune");
    scr_tb_sfx("Zap", 2400, "jump");
    if (_music != "") {
        var _play = scr_tb_macro(_chain, "PLAY_MOD");
        _play.macro_asset_name = _music;
        _play.macro_music_pos = 0;
    }
    var _bkg = scr_tb_macro(_chain, "SETBKG");
    _bkg.macro_asset_name = "024";
    var _org = scr_tb_org(_chain);
    var _press = scr_tb_macro(_org, "CODE");
    _press.macro_code_name = "Wait for fire";
    _press.macro_code_text = "; Wait for the fire button of the joystick in port 2\n"
        + "; (right Ctrl in FS-UAE). CIA-A port A bit 7 is 0 while it is held.\n"
        + "fire_down:\n"
        + "\tbtst\t#7,$bfe001\n"
        + "\tbne.s\tfire_down\n"
        + "\tmove.w\t#$f80,$dff180\t; orange flash (COLOR00)\n";
    var _sfx = scr_tb_macro(_org, "PLAY_SFX");
    _sfx.macro_asset_name = "Zap";
    _sfx.macro_sfx_channel = -1;
    _sfx.macro_sfx_volume = -1;
    var _release = scr_tb_macro(_org, "CODE");
    _release.macro_code_name = "Wait for release";
    _release.macro_code_text = "; Wait until fire is let go, then back to blue.\n"
        + "fire_up:\n"
        + "\tbtst\t#7,$bfe001\n"
        + "\tbeq.s\tfire_up\n"
        + "\tmove.w\t#$024,$dff180\n";
    scr_tb_loop(_org, _press, "shoot");
}
