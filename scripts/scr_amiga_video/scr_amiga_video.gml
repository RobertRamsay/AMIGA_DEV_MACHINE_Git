/// @desc -admvideo: plays a scripted showreel of the app for screen recording
/// (obj_video_director runs it). Each segment opens a screen, moves the mouse,
/// types, draws or plays music on a real-time timeline and shows a caption.
/// The director writes <data>/video_started.txt on its first frame and
/// <data>/video_marks.txt (segment start times in seconds) at the end, so the
/// recording can be cut and the FS-UAE clips put in at the right places.

/// The segments, in order: { name, secs, run } - run(t, first) every frame,
/// t = seconds since the segment started.
function scr_video_segments() {
    return [
        { name : "intro", secs : 8, run : scr_video_seg_intro },
        { name : "home", secs : 7, run : scr_video_seg_home },
        { name : "nodes", secs : 15, run : scr_video_seg_nodes },
        { name : "copper", secs : 7, run : scr_video_seg_copper },
        { name : "bitmap", secs : 6, run : scr_video_seg_bitmap },
        { name : "sprite", secs : 9, run : scr_video_seg_sprite },
        { name : "bob", secs : 5, run : scr_video_seg_bob },
        { name : "tiles", secs : 9, run : scr_video_seg_tiles },
        { name : "tracker", secs : 12, run : scr_video_seg_tracker },
        { name : "code", secs : 19, run : scr_video_seg_code },
        { name : "blaster", secs : 12, run : scr_video_seg_blaster },
        { name : "platformer", secs : 6, run : scr_video_seg_platformer },
        { name : "tour", secs : 6, run : scr_video_seg_tour },
        { name : "outro", secs : 7, run : scr_video_seg_outro }
    ];
}

/// Caption under the picture: _title big, _sub smaller ("" hides it).
function scr_video_caption(_title, _sub) {
    with (obj_video_director) {
        if (caption != _title || caption_sub != _sub) caption_since = get_timer();
        caption = _title;
        caption_sub = _sub;
    }
}

/// Puts the mouse at room position _x, _y.
function scr_video_mouse(_x, _y) {
    window_mouse_set(_x * window_get_width() / room_width, _y * window_get_height() / room_height);
}

/// Glides the mouse from (_x1,_y1) to (_x2,_y2) while _t runs from _t0 to _t1.
function scr_video_glide(_t, _t0, _t1, _x1, _y1, _x2, _y2) {
    if (_t < _t0 || _t > _t1 + 0.05) return;
    var _k = clamp((_t - _t0) / max(0.01, _t1 - _t0), 0, 1);
    _k = _k * _k * (3 - 2 * _k);
    scr_video_mouse(lerp(_x1, _x2, _k), lerp(_y1, _y2, _k));
}

/// True once, on the first frame at or after _at seconds (per segment).
function scr_video_at(_t, _at) {
    var _key = string(_at);
    var _done = global.video_fired;
    if (_t < _at || variable_struct_exists(_done, _key)) return false;
    _done[$ _key] = true;
    return true;
}

/// The first program node of _mnemonic (opcode) or macro _type, or noone.
function scr_video_node(_kind) {
    var _found = noone;
    with (obj_opcode_node) {
        var _match = is_macro ? macro_type == _kind : opcode_mnemonic == _kind;
        if (_match && (_found == noone || node_y < _found.node_y)) _found = id;
    }
    return _found;
}

/// Loads tutorial _number for the reel: no guide, nothing dirty.
function scr_video_tutorial(_number, _guide) {
    scr_amiga_showcase_tutorial(_number, "");
    if (!_guide) with (obj_tutorial_guide) instance_destroy();
    global.workspace_dirty = false;
}

function scr_video_seg_intro(_t, _first) {
    if (_first) {
        scr_video_mouse(1919, 1079);
        scr_video_caption("", "");
        with (obj_video_director) end_card = true;
    }
    // The title card, then the platformer program it can build.
    if (scr_video_at(_t, 4)) {
        with (obj_video_director) end_card = false;
        scr_video_tutorial(10, false);
        scr_video_mouse(1150, 150);
        scr_video_caption("Amiga programs, built from nodes", "Assembled with vasm, booted from a real disk image, played in FS-UAE");
    }
}

function scr_video_seg_home(_t, _first) {
    if (_first) {
        scr_tour_show("home");
        scr_video_caption("Start here: 17 tutorials", "From one node to a platformer, a tracker song and a shoot 'em up");
    }
    scr_video_glide(_t, 0.5, 3, 1700, 1000, 640, 420);
    scr_video_glide(_t, 3.5, 6, 640, 420, 1240, 640);
}

function scr_video_seg_nodes(_t, _first) {
    if (_first) {
        scr_tour_show("main");
        scr_video_tutorial(2, false);
        scr_video_caption("Build programs from 68000 instructions", "Drag nodes from the palette; INIT runs them top to bottom");
    }
    scr_video_glide(_t, 0.3, 2, 1150, 150, 140, 640);
    if (scr_video_at(_t, 2.6)) {
        global.palette_find = "M";
        scr_palette_find_scroll();
        scr_video_caption("Type to find an instruction", "M lights up every M..., MO narrows it to MOVE, MOVEQ, MOVEM...");
    }
    if (scr_video_at(_t, 3.6)) {
        global.palette_find = "MO";
        scr_palette_find_scroll();
    }
    var _move = scr_video_node("MOVE");
    if (_move != noone) {
        var _mx = _move.node_x + global.pan_x + _move.node_width / 2;
        var _my = _move.node_y + global.pan_y + 10;
        scr_video_glide(_t, 5.6, 7, 140, 640, _mx, _my);
        if (scr_video_at(_t, 7)) scr_video_caption("Hover a node: it explains itself", "Its values, its addressing modes and the hardware register, in plain English");
    }
    var _init = noone;
    with (obj_amiga_root_node) if (root_type == "INIT") _init = id;
    if (_init != noone && _move != noone) {
        var _ix = _init.node_x + global.pan_x + _init.node_width / 2;
        var _iy = _init.node_y + global.pan_y + _init.node_height / 2;
        scr_video_glide(_t, 11, 12, _move.node_x + global.pan_x + _move.node_width / 2, _move.node_y + global.pan_y + 10, _ix, _iy);
        if (scr_video_at(_t, 12)) scr_video_caption("Click INIT/BUILD - or press F5", "vasm assembles it, ADM writes a boot disk and FS-UAE runs it");
    }
}

function scr_video_seg_copper(_t, _first) {
    if (_first) {
        scr_video_tutorial(3, false);
        scr_video_mouse(1150, 150);
        scr_tour_show("cprbar");
        scr_video_caption("Copper rainbows", "COPPER BAR: colour bands timed to the raster beam");
    }
    scr_video_glide(_t, 1, 5.5, 700, 300, 1200, 700);
}

function scr_video_seg_bitmap(_t, _first) {
    if (_first) {
        scr_tour_show("main");
        scr_video_mouse(1150, 150);
        scr_amiga_showcase_tutorial(12, "BITMAP_DISPLAY");
        scr_video_caption("Paint 32-colour pictures", "Pencil, lines, circles, fills, gradients - or import PNG and IFF");
    }
    scr_video_glide(_t, 0.5, 5, 600, 300, 1100, 650);
}

/// SPR-EDIT on the STAR BLASTER ship, drawn again pixel by pixel.
function scr_video_seg_sprite(_t, _first) {
    if (_first) {
        scr_tour_show("main");
        scr_video_tutorial(17, false);
        scr_sprite_editor_open_on("Ship");
        global.video_sprite_target = array_create(16 * 16, 0);
        array_copy(global.video_sprite_target, 0, global.sprite_pixels, 0, 16 * 16);
        var _i = 0;
        while (_i < 16 * 16) {
            global.sprite_pixels[_i] = 0;
            _i += 1;
        }
        scr_video_caption("Draw hardware sprites", "SPR-EDIT: 16 pixels wide, 3 colours, frames and animation");
    }
    // The cells reveal row by row over 6 seconds; the mouse follows the pen.
    var _shown = clamp(floor((_t - 0.8) / 6 * 256), 0, 256);
    var _p = 0;
    var _last = -1;
    while (_p < _shown) {
        if (global.sprite_pixels[_p] != global.video_sprite_target[_p]) global.sprite_pixels[_p] = global.video_sprite_target[_p];
        if (global.video_sprite_target[_p] != 0) _last = _p;
        _p += 1;
    }
    if (_last >= 0 && _shown < 256) scr_video_mouse(398 + (_last mod 16) * 14 + 7, 220 + (_last div 16) * 14 + 7);
}

function scr_video_seg_bob(_t, _first) {
    if (_first) {
        with (obj_amiga_manager) if (global.sprite_editor_open) sprite_editor_commit_asset();
        scr_tour_show("main");
        scr_video_mouse(1150, 150);
        scr_amiga_showcase_tutorial(14, "DRAW_BOB");
        scr_video_caption("...and BOBs: blitter objects", "Any size, any colours, cookie-cut over the picture");
    }
    scr_video_glide(_t, 0.5, 4.5, 500, 300, 900, 600);
}

function scr_video_seg_tiles(_t, _first) {
    if (_first) {
        scr_tour_show("main");
        scr_video_tutorial(10, false);
        scr_video_mouse(1150, 150);
        scr_tour_show("tile:MAP");
        scr_video_caption("TILE-EDIT: tiles, maps and animations", "Paint rooms, set solid / hazard / pickup flags, place enemies");
    }
    if (scr_video_at(_t, 4.5)) scr_tour_show("tile:ANIMATIONS");
    scr_video_glide(_t, 0.5, 4, 700, 400, 1300, 600);
    scr_video_glide(_t, 5, 8.5, 1300, 600, 800, 500);
}

function scr_video_seg_tracker(_t, _first) {
    if (_first) {
        scr_tour_show("main");
        scr_video_tutorial(10, false);
        scr_video_mouse(1150, 150);
        scr_tour_show("tracker");
        with (obj_tracker_editor) scr_tracker_play(song, cur_pos, false, mute);
        scr_video_caption("Write the music in the TRACKER", "ProTracker style: 4 channels, 31 instruments, effects, built-in synth sounds");
    }
    if (scr_video_at(_t, 6)) scr_video_caption("This song - Pixel Hearts - is tutorial 16", "Built layer by layer, with SHOW ME at every step");
    if (scr_video_at(_t, 11.8)) scr_audio_preview_stop();
}

/// Types a short routine into tutorial 4's CODE block with the completion
/// and MODE lists, the way a user would.
function scr_video_seg_code(_t, _first) {
    if (_first) {
        scr_tour_show("main");
        scr_video_tutorial(4, false);
        scr_video_mouse(1700, 1000);
        var _node = scr_video_node("CODE");
        if (_node != noone) {
            var _ed = scr_code_editor_open(_node);
            with (_ed) {
                var _end = array_length(lines);
                lines[_end] = "";
                lines[_end + 1] = "; your own routine";
                lines[_end + 2] = "flash:";
                lines[_end + 3] = "";
                ed_set_caret(_end + 3, 0, false);
                ed_ensure_caret_visible();
                ed_modified();
            }
        }
        global.video_typed = 0;
        scr_video_caption("Or write raw 68000 assembly", "CODE blocks: syntax colours, live error checks, hover help");
    }
    if (!instance_exists(obj_code_editor)) return;
    // { at, act, arg }: "type" a string a character at a time, "pick" the
    // completion with that text, "step" the list to that text, "nl" newline.
    var _script = [
        [1.0, "type", "        mo"],
        [2.2, "pick", "MOVE"],
        [3.2, "pick", "W"],
        [4.2, "step", "#0"],
        [5.6, "pick", "#0"],
        [6.6, "step", "$DFF180"],
        [8.4, "pick", "$DFF180"],
        [9.0, "nl", ""],
        [9.4, "type", "        db"],
        [10.4, "pick", "DBRA"],
        [11.4, "pick", "d0"],
        [12.6, "pick", "flash"],
        [13.2, "nl", ""],
        [13.6, "type", "        rts"]
    ];
    if (scr_video_at(_t, 3.6)) scr_video_caption("Tab completes - then pick the addressing", "The MODE list shows every form the instruction accepts: Up / Down, Tab");
    if (scr_video_at(_t, 14.5)) scr_video_caption("F5 builds without leaving the editor", "vasm errors come back to the exact line");
    var _i = 0;
    while (_i < array_length(_script)) {
        var _s = _script[_i];
        if (_t >= _s[0]) {
            switch (_s[1]) {
                case "type":
                    // One character every 70 ms, autocomplete popping up as it would.
                    var _want = min(string_length(_s[2]), floor((_t - _s[0]) / 0.07) + 1);
                    var _key = "typed_" + string(_i);
                    var _have = variable_struct_exists(global.video_fired, _key) ? global.video_fired[$ _key] : 0;
                    with (obj_code_editor) {
                        while (_have < _want) {
                            _have += 1;
                            ed_type_text(string_char_at(_s[2], _have));
                            if (string_char_at(_s[2], _have) != " ") ed_ac_update(false);
                        }
                    }
                    global.video_fired[$ _key] = _have;
                    break;
                case "step":
                    // Walk the open list one entry every 0.2 s towards the
                    // target (the ghost text changes with it), until the next action.
                    var _until = _i + 1 < array_length(_script) ? _script[_i + 1][0] : 1000;
                    if (_t < _until) with (obj_code_editor) {
                        if (ac_open) {
                            var _goal = 0;
                            while (_goal < array_length(ac_items) && string_upper(ac_items[_goal].text) != string_upper(_s[2])) _goal += 1;
                            if (_goal < array_length(ac_items)) {
                                ac_index = min(_goal, floor((_t - _s[0]) / 0.2));
                                if (ac_index >= ac_scroll + ac_rows) ac_scroll = ac_index - ac_rows + 1;
                            }
                        }
                    }
                    break;
                case "pick":
                    if (scr_video_at(_t, _s[0])) {
                        with (obj_code_editor) {
                            if (!ac_open && _s[1] == "pick") ed_ac_update(true);
                            var _k = 0;
                            while (_k < array_length(ac_items)) {
                                if (string_upper(ac_items[_k].text) == string_upper(_s[2])) break;
                                _k += 1;
                            }
                            if (_k < array_length(ac_items)) ed_ac_accept(_k);
                        }
                    }
                    break;
                case "nl":
                    if (scr_video_at(_t, _s[0])) with (obj_code_editor) {
                        ac_close();
                        ed_newline();
                    }
                    break;
            }
        }
        _i += 1;
    }
}

function scr_video_seg_blaster(_t, _first) {
    if (_first) {
        with (obj_code_editor) ed_close(false);
        scr_tour_show("main");
        scr_video_tutorial(17, true);
        scr_video_mouse(1150, 150);
        scr_video_caption("Tutorial 17: STAR BLASTER", "A shoot 'em up in ten CODE blocks, with your own sprites and sound");
    }
    var _code = scr_video_node("CODE");
    if (_code != noone) scr_video_glide(_t, 1, 3.5, 1150, 150, _code.node_x + global.pan_x + 90, _code.node_y + global.pan_y + 10);
    if (scr_video_at(_t, 6)) {
        var _draw = noone;
        with (obj_opcode_node) if (is_macro && macro_type == "CODE" && macro_code_name == "Draw sprites") _draw = id;
        if (_draw != noone) scr_code_editor_open(_draw);
        scr_video_caption("spr_Ship: your SPR-EDIT sprite, by name", "Sprites, Copper list, joystick and collisions in plain 68000");
    }
}

function scr_video_seg_platformer(_t, _first) {
    if (_first) {
        with (obj_code_editor) ed_close(false);
        scr_tour_show("main");
        scr_video_tutorial(10, false);
        scr_video_mouse(1150, 150);
        scr_video_caption("Or snap a platformer together", "Game Kit nodes: screen, map, player, physics, enemies, animation");
    }
    scr_video_glide(_t, 0.5, 5, 1150, 150, 1000, 700);
}

function scr_video_seg_tour(_t, _first) {
    if (_first) {
        scr_video_mouse(1700, 1000);
        scr_tour_open();
        scr_video_caption("F1: a guided tour of every screen", "17 categories, step by step, or on auto-play");
    }
    if (scr_video_at(_t, 5.8)) with (obj_editor_tour) tour_finish();
}

function scr_video_seg_outro(_t, _first) {
    if (_first) {
        scr_tour_close_editors();
        scr_video_mouse(1919, 1079);
        scr_video_caption("", "");
        with (obj_video_director) end_card = true;
    }
}
