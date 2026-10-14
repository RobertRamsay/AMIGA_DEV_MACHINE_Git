/// @desc Game Kit nodes -> assembler. Every node saves the registers, sets
/// its parameters and JSRs into datafiles/gamekit/gamekit.s (included once by
/// the build footer), whose layouts the bake functions below write:
///   __gkmap_<name>, __gkts_<name>, __gkanim_<name>, __gksfx_<uid>_<a|b>.
/// Parameters (generic node fields):
///   GK_MAP      macro_asset_name = TILEMAP
///   GK_PLAYER   macro_asset_name = ANIMSET
///   GK_PHYSICS  param_a run speed, param_b jump power, param_c gravity (1/16 px
///               per frame), text_a = jump sound (SAMPLE, "" = none)
///   GK_EVENTS   text_a = pickup sound, text_b = hurt sound, param_a = 1 when the
///               exit needs every pickup first

#macro GK_NODE_TYPES ["GK_SCREEN", "GK_MAP", "GK_PLAYER", "GK_WAIT", "GK_INPUT", "GK_PHYSICS", "GK_EVENTS", "GK_ENEMIES", "GK_ANIMATE", "GK_DRAW"]

function scr_gk_is_node_type(_type) {
    return array_contains(GK_NODE_TYPES, _type);
}

/// Toolbar / header label for a Game Kit node type.
function scr_gk_node_label(_type) {
    switch (_type) {
        case "GK_SCREEN": return "GAME SCREEN";
        case "GK_MAP": return "DRAW MAP";
        case "GK_PLAYER": return "PLAYER";
        case "GK_WAIT": return "WAIT FRAME";
        case "GK_INPUT": return "READ JOYSTICK";
        case "GK_PHYSICS": return "PHYSICS";
        case "GK_EVENTS": return "TILE EVENTS";
        case "GK_ENEMIES": return "ENEMIES";
        case "GK_ANIMATE": return "ANIMATE";
        case "GK_DRAW": return "DRAW SPRITES";
    }
    return _type;
}

/// Starting values for a new Game Kit node.
function scr_gk_node_init(_node, _type) {
    _node.is_macro = true;
    _node.macro_type = _type;
    _node.node_height = scr_macro_node_height(_type);
    if (_type == "GK_MAP") {
        var _maps = scr_gk_asset_names("TILEMAP");
        _node.macro_asset_name = array_length(_maps) > 0 ? _maps[0] : "";
    } else if (_type == "GK_PLAYER") {
        var _sets = scr_gk_asset_names("ANIMSET");
        _node.macro_asset_name = array_length(_sets) > 0 ? _sets[0] : "";
    } else if (_type == "GK_PHYSICS") {
        _node.macro_param_a = 24;
        _node.macro_param_b = 80;
        _node.macro_param_c = 5;
        _node.macro_param_text_a = "";
    } else if (_type == "GK_EVENTS") {
        _node.macro_param_a = 0;
        _node.macro_param_text_a = "";
        _node.macro_param_text_b = "";
    }
}

/// Labels for baked data.
function scr_gk_map_label(_name) { return "__gkmap_" + scr_amiga_label_safe(_name); }
function scr_gk_tileset_label(_name) { return "__gkts_" + scr_amiga_label_safe(_name); }
function scr_gk_anim_label(_name) { return "__gkanim_" + scr_amiga_label_safe(_name); }
function scr_gk_sfx_label(_node, _slot) { return "__gksfx_" + string(floor(_node.uid)) + "_" + _slot; }

/// "MOVEM, <body>, JSR, MOVEM" wrapper every Game Kit node uses.
function scr_gk_call(_node, _comment, _body, _routine) {
    var _s = "";
    if (_node.node_label != "") _s += _node.node_label + ":\n";
    _s += "\tMOVEM.L D0-D7/A0-A6,-(SP)\t; " + _comment + "\n";
    _s += _body;
    _s += "\tJSR " + _routine + "\n";
    _s += "\tMOVEM.L (SP)+,D0-D7/A0-A6";
    return _s;
}

/// A sound field: LEA of the node's sfx structure into _reg, or a cleared register.
function scr_gk_sfx_operand(_node, _slot, _sample_name, _reg) {
    if (_sample_name == "") return "\tSUBA.L " + _reg + "," + _reg + "\n";
    return "\tLEA " + scr_gk_sfx_label(_node, _slot) + "," + _reg + "\n";
}

function scr_gk_sample_ok(_name) {
    if (_name == "") return true;
    var _asset = scr_asset_find_by_name(_name);
    return _asset != undefined && _asset.type == "SAMPLE";
}

/// Emits one Game Kit node. Returns { text, is_valid }.
function scr_emit_macro_gamekit(_node) {
    var _t = _node.macro_type;
    switch (_t) {
        case "GK_SCREEN":
            return { text : scr_gk_call(_node, "GAME SCREEN", "", "gk_screen"), is_valid : true };

        case "GK_MAP":
            var _map = scr_asset_find_by_name(_node.macro_asset_name);
            var _problem = scr_gk_map_problem(_map);
            if (_node.macro_asset_name == "") _problem = "no map chosen - make one in TILE-EDIT";
            if (_problem != "") return { text : "; ERROR: DRAW MAP: " + _problem, is_valid : false };
            return { text : scr_gk_call(_node, "DRAW MAP " + _node.macro_asset_name, "\tLEA " + scr_gk_map_label(_node.macro_asset_name) + ",A0\n", "gk_map"), is_valid : true };

        case "GK_PLAYER":
            var _set = scr_asset_find_by_name(_node.macro_asset_name);
            var _set_problem = scr_gk_animset_problem(_set);
            if (_node.macro_asset_name == "") _set_problem = "no animation set chosen - make one in TILE-EDIT";
            if (_set_problem != "") return { text : "; ERROR: PLAYER: " + _set_problem, is_valid : false };
            return { text : scr_gk_call(_node, "PLAYER " + _node.macro_asset_name, "\tLEA " + scr_gk_anim_label(_node.macro_asset_name) + ",A0\n", "gk_player"), is_valid : true };

        case "GK_WAIT":
            return { text : scr_gk_call(_node, "WAIT FRAME", "", "gk_wait_frame"), is_valid : true };

        case "GK_INPUT":
            return { text : scr_gk_call(_node, "READ JOYSTICK", "", "gk_read_input"), is_valid : true };

        case "GK_PHYSICS":
            if (!scr_gk_sample_ok(_node.macro_param_text_a)) return { text : "; ERROR: PHYSICS: jump sound '" + _node.macro_param_text_a + "' is not a sample", is_valid : false };
            var _body = "\tMOVE.W #" + string(clamp(_node.macro_param_a, 4, 96)) + ",gk_speed\n"
                + "\tMOVE.W #" + string(clamp(_node.macro_param_b, 16, 160)) + ",gk_jumpv\n"
                + "\tMOVE.W #" + string(clamp(_node.macro_param_c, 1, 16)) + ",gk_grav\n"
                + scr_gk_sfx_operand(_node, "a", _node.macro_param_text_a, "A0")
                + "\tMOVE.L A0,gk_sfx_jump\n";
            return { text : scr_gk_call(_node, "PHYSICS", _body, "gk_physics"), is_valid : true };

        case "GK_EVENTS":
            if (!scr_gk_sample_ok(_node.macro_param_text_a)) return { text : "; ERROR: TILE EVENTS: pickup sound '" + _node.macro_param_text_a + "' is not a sample", is_valid : false };
            if (!scr_gk_sample_ok(_node.macro_param_text_b)) return { text : "; ERROR: TILE EVENTS: hurt sound '" + _node.macro_param_text_b + "' is not a sample", is_valid : false };
            var _ev = scr_gk_sfx_operand(_node, "a", _node.macro_param_text_a, "A0")
                + scr_gk_sfx_operand(_node, "b", _node.macro_param_text_b, "A1")
                + "\tMOVEQ #" + string(_node.macro_param_a != 0 ? 1 : 0) + ",D0\n";
            return { text : scr_gk_call(_node, "TILE EVENTS", _ev, "gk_events"), is_valid : true };

        case "GK_ENEMIES":
            return { text : scr_gk_call(_node, "ENEMIES", "", "gk_enemies"), is_valid : true };

        case "GK_ANIMATE":
            return { text : scr_gk_call(_node, "ANIMATE", "", "gk_animate"), is_valid : true };

        case "GK_DRAW":
            return { text : scr_gk_call(_node, "DRAW SPRITES", "", "gk_draw_sprites"), is_valid : true };
    }
    return { text : "; ERROR: unknown Game Kit node " + _t, is_valid : false };
}

/// Adds the Game Kit needs of _node_array to _scan (maps, tilesets, animation
/// sets, sound references). Sound samples go into _scan.samples so the audio
/// footer INCBINs them.
function scr_gk_scan(_node_array, _scan) {
    _scan.uses_gamekit = false;
    _scan.gk_maps = [];
    _scan.gk_tilesets = [];
    _scan.gk_anims = [];
    _scan.gk_sfx_refs = [];         // { node, slot, sample }
    var _i = 0;
    while (_i < array_length(_node_array)) {
        var _node = _node_array[_i];
        if (_node.is_macro && scr_gk_is_node_type(_node.macro_type)) {
            _scan.uses_gamekit = true;
            if (_node.macro_type == "GK_MAP") {
                var _map = scr_asset_find_by_name(_node.macro_asset_name);
                if (_map != undefined && _map.type == "TILEMAP") {
                    if (!array_contains(_scan.gk_maps, _map.name)) array_push(_scan.gk_maps, _map.name);
                    if (!array_contains(_scan.gk_tilesets, _map.tileset)) array_push(_scan.gk_tilesets, _map.tileset);
                    var _e = 0;
                    while (_e < array_length(_map.enemies)) {
                        if (!array_contains(_scan.gk_anims, _map.enemies[_e].animset)) array_push(_scan.gk_anims, _map.enemies[_e].animset);
                        _e += 1;
                    }
                }
            }
            if (_node.macro_type == "GK_PLAYER" && !array_contains(_scan.gk_anims, _node.macro_asset_name)) array_push(_scan.gk_anims, _node.macro_asset_name);
            var _refs = [];
            if (_node.macro_type == "GK_PHYSICS") _refs = [["a", _node.macro_param_text_a]];
            if (_node.macro_type == "GK_EVENTS") _refs = [["a", _node.macro_param_text_a], ["b", _node.macro_param_text_b]];
            var _r = 0;
            while (_r < array_length(_refs)) {
                var _sample = _refs[_r][1];
                if (_sample != "") {
                    array_push(_scan.gk_sfx_refs, { node : _node, slot : _refs[_r][0], sample : _sample });
                    if (!array_contains(_scan.samples, _sample)) array_push(_scan.samples, _sample);
                    _scan.uses_audio = true;
                }
                _r += 1;
            }
        }
        _i += 1;
    }
}

/// 12-bit colour word from 0..15 guns.
function scr_gk_rgb12(_r, _g, _b) {
    return (clamp(_r, 0, 15) << 8) | (clamp(_g, 0, 15) << 4) | clamp(_b, 0, 15);
}

/// DC.x lines of _values, _per_line a line.
function scr_gk_dc_lines(_size, _values, _per_line) {
    var _s = "";
    var _count = array_length(_values);
    var _i = 0;
    while (_i < _count) {
        _s += "\tDC." + _size + " ";
        var _j = 0;
        while (_j < _per_line && _i < _count) {
            if (_j > 0) _s += ",";
            _s += string(_values[_i]);
            _i += 1;
            _j += 1;
        }
        _s += "\n";
    }
    return _s;
}

function scr_gk_bake_tileset(_tileset) {
    var _label = scr_gk_tileset_label(_tileset.name);
    var _size = _tileset.tile_size;
    var _count = array_length(_tileset.tiles);
    var _row_bytes = _size div 8;
    var _tile_bytes = _size * _row_bytes * 4;
    var _s = "\tCNOP 0,4\n" + _label + ":\n";
    _s += "\tDC.W " + string(_size) + "," + string(_count) + "," + string(_tile_bytes) + "\n";
    var _palette = array_create(16, 0);
    var _c = 0;
    while (_c < 16) {
        _palette[_c] = scr_gk_rgb12(_tileset.colour_r[_c], _tileset.colour_g[_c], _tileset.colour_b[_c]);
        _c += 1;
    }
    _s += scr_gk_dc_lines("W", _palette, 16);
    _s += "\tDC.L " + _label + "_flags," + _label + "_gfx\n";
    _s += _label + "_flags:\n";
    var _flags = array_create(256, 0);
    var _f = 1;
    while (_f < _count) {
        _flags[_f] = _tileset.flags[_f] & 31;
        _f += 1;
    }
    _s += scr_gk_dc_lines("B", _flags, 32);
    _s += "\tEVEN\n" + _label + "_gfx:\n";
    var _t = 0;
    while (_t < _count) {
        var _pixels = _tileset.tiles[_t];
        var _bytes = array_create(_tile_bytes, 0);
        var _k = 0;
        var _plane = 0;
        while (_plane < 4) {
            var _y = 0;
            while (_y < _size) {
                var _b = 0;
                while (_b < _row_bytes) {
                    var _value = 0;
                    var _bit = 0;
                    while (_bit < 8) {
                        var _pix = (_t == 0) ? 0 : _pixels[_y * _size + _b * 8 + _bit];
                        if ((_pix & (1 << _plane)) != 0) _value |= 128 >> _bit;
                        _bit += 1;
                    }
                    _bytes[_k] = _value;
                    _k += 1;
                    _b += 1;
                }
                _y += 1;
            }
            _plane += 1;
        }
        _s += scr_gk_dc_lines("B", _bytes, 32);
        _t += 1;
    }
    _s += "\tEVEN\n";
    return _s;
}

function scr_gk_bake_map(_map) {
    var _tileset = scr_asset_find_by_name(_map.tileset);
    var _label = scr_gk_map_label(_map.name);
    var _size = _tileset.tile_size;
    var _s = "\tCNOP 0,4\n" + _label + ":\n";
    _s += "\tDC.W " + string(_size) + "," + string(_map.room_cols) + "," + string(_map.room_rows) + ","
        + string(_map.rooms_x) + "," + string(_map.rooms_y) + "," + string(_map.width) + "," + string(_map.height) + ","
        + string(clamp(_map.spawn_x, 0, _map.width * _size - 16)) + "," + string(clamp(_map.spawn_y, 0, _map.height * _size - 8)) + "\n";
    _s += "\tDC.L " + scr_gk_tileset_label(_map.tileset) + "," + _label + "_cells," + _label + "_enemies\n";
    _s += _label + "_enemies:\n\tDC.W " + string(array_length(_map.enemies)) + "\n";
    var _e = 0;
    while (_e < array_length(_map.enemies)) {
        var _enemy = _map.enemies[_e];
        _s += "\tDC.W " + string(_enemy.x) + "," + string(_enemy.y) + "," + string(clamp(_enemy.speed, 1, 4)) + "\n";
        _s += "\tDC.L " + scr_gk_anim_label(_enemy.animset) + "\n";
        _e += 1;
    }
    var _tile_count = array_length(_tileset.tiles);
    var _cells = array_create(array_length(_map.cells), 0);
    var _c = 0;
    while (_c < array_length(_map.cells)) {
        var _tile = _map.cells[_c];
        _cells[_c] = (_tile >= 0 && _tile < _tile_count) ? _tile : 0;
        _c += 1;
    }
    _s += _label + "_cells:\n" + scr_gk_dc_lines("B", _cells, 40) + "\tEVEN\n";
    return _s;
}

/// DATA,DATB words of one sprite frame, mirrored when _left.
function scr_gk_sprite_words(_sprite, _height, _left) {
    var _words = [];
    var _y = 0;
    while (_y < _height) {
        var _a = 0;
        var _b = 0;
        var _x = 0;
        while (_x < 16) {
            var _src_x = _left ? 15 - _x : _x;
            var _pix = _sprite.pixels[_y * 16 + _src_x];
            if ((_pix & 1) != 0) _a |= 1 << (15 - _x);
            if ((_pix & 2) != 0) _b |= 1 << (15 - _x);
            _x += 1;
        }
        array_push(_words, _a, _b);
        _y += 1;
    }
    return _words;
}

function scr_gk_bake_animset(_set) {
    var _label = scr_gk_anim_label(_set.name);
    var _states = GK_ANIM_STATES;
    var _first = scr_asset_find_by_name(_set.states.idle.frames[0]);
    var _s = "\tCNOP 0,4\n" + _label + ":\n";
    _s += "\tDC.W " + string(_set.height) + ","
        + string(scr_gk_rgb12(_first.colour_r[0], _first.colour_g[0], _first.colour_b[0])) + ","
        + string(scr_gk_rgb12(_first.colour_r[1], _first.colour_g[1], _first.colour_b[1])) + ","
        + string(scr_gk_rgb12(_first.colour_r[2], _first.colour_g[2], _first.colour_b[2])) + "\n";
    var _i = 0;
    while (_i < 4) {
        var _state = _set.states[$ _states[_i]];
        _s += "\tDC.W " + string(array_length(_state.frames)) + "," + string(clamp(_state.rate, 1, 50)) + "\n";
        _s += "\tDC.L " + _label + "_" + _states[_i] + "_r," + _label + "_" + _states[_i] + "_l\n";
        _i += 1;
    }
    _i = 0;
    while (_i < 4) {
        var _frames = _set.states[$ _states[_i]].frames;
        var _side = 0;
        while (_side < 2) {
            _s += _label + "_" + _states[_i] + (_side == 0 ? "_r" : "_l") + ":\n";
            var _f = 0;
            while (_f < array_length(_frames)) {
                var _sprite = scr_asset_find_by_name(_frames[_f]);
                _s += scr_gk_dc_lines("W", scr_gk_sprite_words(_sprite, _set.height, _side == 1), 16);
                _f += 1;
            }
            _side += 1;
        }
        _i += 1;
    }
    return _s;
}

/// Runtime + data appended after the nodes (after the audio runtime, which it
/// may call). Returns { ok, text, error }.
function scr_gk_footer_text(_scan) {
    var _result = { ok : true, text : "", error : "" };
    if (!_scan.uses_gamekit) return _result;

    var _t = "\n; ==== Amiga Dev Machine Game Kit runtime ====\n";
    _t += "\tSECTION adm_gamekit,CODE\n";
    _t += "\tINCLUDE \"" + string_replace_all(working_directory + "gamekit/gamekit.s", "\\", "/") + "\"\n";
    _t += "\n\tSECTION adm_gkdata,DATA_C\n";

    var _i = 0;
    while (_i < array_length(_scan.gk_tilesets)) {
        var _tileset = scr_asset_find_by_name(_scan.gk_tilesets[_i]);
        if (_tileset == undefined || _tileset.type != "TILESET") {
            _result.ok = false;
            _result.error = "tileset '" + _scan.gk_tilesets[_i] + "' not found";
            return _result;
        }
        _t += scr_gk_bake_tileset(_tileset);
        _i += 1;
    }
    _i = 0;
    while (_i < array_length(_scan.gk_maps)) {
        _t += scr_gk_bake_map(scr_asset_find_by_name(_scan.gk_maps[_i]));
        _i += 1;
    }
    _i = 0;
    while (_i < array_length(_scan.gk_anims)) {
        var _set = scr_asset_find_by_name(_scan.gk_anims[_i]);
        var _problem = scr_gk_animset_problem(_set);
        if (_problem != "") {
            _result.ok = false;
            _result.error = _problem;
            return _result;
        }
        _t += scr_gk_bake_animset(_set);
        _i += 1;
    }
    _result.text = _t + "\tEVEN\n";
    return _result;
}

/// ptplayer sfx structures for the Game Kit's sound fields (in the audio data section).
function scr_gk_sfx_structs_text(_scan) {
    var _t = "";
    var _i = 0;
    while (_i < array_length(_scan.gk_sfx_refs)) {
        var _ref = _scan.gk_sfx_refs[_i];
        var _asset = scr_asset_find_by_name(_ref.sample);
        _t += "\tCNOP 0,2\n" + scr_gk_sfx_label(_ref.node, _ref.slot) + ":\n";
        _t += "\tDC.L __smp_" + scr_amiga_label_safe(_ref.sample) + "\n";
        _t += "\tDC.W " + string(min(1 + (_asset.length div 2), 65535)) + "," + string(clamp(_asset.period, 124, 65535)) + "," + string(clamp(_asset.volume, 0, 64)) + "\n";
        _t += "\tDC.B -1,64\n";
        _i += 1;
    }
    return _t;
}

/// Short label for the left palette (80 px buttons).
function scr_gk_palette_label(_type) {
    switch (_type) {
        case "GK_SCREEN": return "SCREEN";
        case "GK_MAP": return "MAP";
        case "GK_PLAYER": return "PLAYER";
        case "GK_WAIT": return "WAIT FRM";
        case "GK_INPUT": return "JOYSTICK";
        case "GK_PHYSICS": return "PHYSICS";
        case "GK_EVENTS": return "EVENTS";
        case "GK_ENEMIES": return "ENEMIES";
        case "GK_ANIMATE": return "ANIMATE";
        case "GK_DRAW": return "SPRITES";
    }
    return _type;
}
