/// @desc -admshowcase: saves a clean screenshot of every screen of the app to
/// <data>/showcase/ (splash, opening page, main screen, every editor and its
/// states, the tutorial guide, the tour) - material for videos and pages.
/// Runs on the editor tour's demo workspace plus generated bitmap / BOB art.

/// The shots, in order: { name, setup } - setup runs, then the screen is
/// saved a few frames later.
function scr_amiga_showcase_shots() {
    return [
        { name : "03_opening_page", setup : function() { scr_tutorial_home_open(true); } },
        { name : "04_main_screen_new_workspace", setup : function() { scr_tour_show("main"); } },
        { name : "05_main_screen_platformer_program", setup : function() {
            scr_tour_build_demo();
            scr_amiga_showcase_art();
        } },
        { name : "06_tutorial_step_guide", setup : function() { scr_tour_show("guide"); } },
        { name : "07_sprite_editor", setup : function() { scr_tour_show("sprite"); } },
        { name : "08_bitmap_editor", setup : function() { scr_tour_show("bitmap"); } },
        { name : "09_bob_editor", setup : function() { scr_tour_show("bob"); } },
        { name : "10_colour_picker", setup : function() { scr_tour_show("colour"); } },
        { name : "11_copper_bar_editor", setup : function() { scr_tour_show("cprbar"); } },
        { name : "12_code_editor", setup : function() { scr_tour_show("code"); } },
        { name : "13_code_editor_find", setup : function() { scr_tour_show("code:find"); } },
        { name : "14_sound_music_modules", setup : function() { scr_tour_show("audio:mod"); } },
        { name : "15_sound_samples_waveform", setup : function() { scr_tour_show("audio:sample"); } },
        { name : "15b_tracker", setup : function() { scr_tour_show("tracker"); } },
        { name : "16_tile_editor_tiles", setup : function() { scr_tour_show("tile:TILES"); } },
        { name : "17_tile_editor_metatiles", setup : function() { scr_tour_show("tile:METATILES"); } },
        { name : "18_tile_editor_map_start_room", setup : function() { scr_tour_show("tile:MAP"); } },
        { name : "19_tile_editor_map_staircase_room", setup : function() {
            scr_tour_show("tile:MAP");
            with (obj_tile_editor) {
                room_x = 2;
                room_y = 1;
            }
        } },
        { name : "20_tile_editor_animations", setup : function() { scr_tour_show("tile:ANIMATIONS"); } },
        { name : "21_editor_tour_categories", setup : function() {
            scr_tour_show("main");
            scr_tour_open();
        } },
        { name : "22_editor_tour_step_nodes", setup : function() { scr_amiga_showcase_tour_step("Addressing modes"); } },
        { name : "23_editor_tour_step_sprite", setup : function() { scr_amiga_showcase_tour_step("Frames"); } },
        { name : "24_editor_tour_step_map", setup : function() { scr_amiga_showcase_tour_step("Painting the map"); } },
        { name : "25_tutorials_page", setup : function() {
            with (obj_editor_tour) instance_destroy();
            scr_tour_show("main");
            scr_tutorial_home_open(true);
            with (obj_tutorial_home) {
                home_scroll = home_scroll_max;
                home_layout();
            }
        } },
        { name : "26_tutorial_11_macros", setup : function() { scr_amiga_showcase_tutorial(11, ""); } },
        { name : "27_tutorial_12_bitmap", setup : function() { scr_amiga_showcase_tutorial(12, ""); } },
        { name : "28_tutorial_12_edit_bitmap", setup : function() { scr_amiga_showcase_tutorial(12, "BITMAP_DISPLAY"); } },
        { name : "29_tutorial_13_sprites", setup : function() { scr_amiga_showcase_tutorial(13, ""); } },
        { name : "30_tutorial_13_edit_frames", setup : function() { scr_amiga_showcase_tutorial(13, "ANIM_SPR"); } },
        { name : "31_tutorial_14_bobs", setup : function() { scr_amiga_showcase_tutorial(14, ""); } },
        { name : "32_tutorial_14_edit_bob", setup : function() { scr_amiga_showcase_tutorial(14, "DRAW_BOB"); } },
        { name : "33_tutorial_15_music", setup : function() { scr_amiga_showcase_tutorial(15, ""); } },
        { name : "34_tutorial_15_edit_song", setup : function() {
            scr_amiga_showcase_tutorial(15, "");
            var _play = scr_tour_find_node("PLAY_MOD");
            if (_play != noone) scr_tracker_open_for_node(_play);
        } },
        { name : "35_tutorial_10_edit_map", setup : function() { scr_amiga_showcase_tutorial(10, "GK_MAP"); } },
        { name : "36_tutorial_16_step_echo", setup : function() {
            scr_amiga_showcase_tutorial(16, "");
            global.tutorial_step = 6;
        } },
        { name : "37_tutorial_16_show_me_fades", setup : function() { scr_amiga_showcase_song_step(5); } },
        { name : "39_init_build_hover", setup : function() {
            with (obj_tracker_editor) instance_destroy();
            scr_amiga_showcase_tutorial(1, "");
            with (obj_tutorial_guide) instance_destroy();
            // Put the mouse on INIT/BUILD: it pulses and the help panel says BUILD AND RUN.
            with (obj_amiga_root_node) {
                if (root_type == "INIT") {
                    var _mx = node_x + global.pan_x + node_width / 2;
                    var _my = node_y + global.pan_y + node_height / 2;
                    window_mouse_set(_mx * window_get_width() / room_width, _my * window_get_height() / room_height);
                }
            }
        } },
        { name : "40_hover_move_to_colour00", setup : function() { scr_amiga_showcase_hover_opcode(2, "MOVE"); } },
        { name : "41_hover_addq", setup : function() { scr_amiga_showcase_hover_opcode(2, "ADDQ"); } },
        { name : "42_hover_bra_loop", setup : function() { scr_amiga_showcase_hover_opcode(2, "BRA"); } },
        { name : "43_palette_find_n", setup : function() { scr_amiga_showcase_palette_find("N"); } },
        { name : "44_palette_find_no", setup : function() { scr_amiga_showcase_palette_find("NO"); } },
        { name : "45_palette_find_mo", setup : function() { scr_amiga_showcase_palette_find("MO"); } },
        { name : "38_tutorial_16_show_me_b_section", setup : function() { scr_amiga_showcase_song_step(8); } }
    ];
}

/// Tutorial 16 on guide step _step, with its SHOW ME pressed.
function scr_amiga_showcase_song_step(_step) {
    scr_amiga_showcase_tutorial(16, "");
    global.tutorial_step = _step;
    var _defs = scr_tutorial_defs();
    var _def = _defs[15].steps[_step];
    scr_tutorial_song_show(_def.song_stage, _def.hint);
}

/// Loads tutorial _number with its step guide; with _edit_type, presses the
/// EDIT button of the first node of that type.
function scr_amiga_showcase_tutorial(_number, _edit_type) {
    with (obj_editor_tour) instance_destroy();
    scr_tour_show("main");
    global.workspace_dirty = false;
    scr_tutorial_load(_number - 1);
    global.tutorial_step = 0;
    global.tutorial_guide_collapsed = false;
    scr_tutorial_guide_open();
    if (_edit_type != "") {
        var _node = scr_tour_find_node(_edit_type);
        if (_node != noone) scr_node_edit_open(_node);
    }
}

/// Loads tutorial _number without its guide and puts the mouse on the header
/// of its first _mnemonic node, so the panel shows that node's hover help.
function scr_amiga_showcase_hover_opcode(_number, _mnemonic) {
    with (obj_tracker_editor) instance_destroy();
    scr_amiga_showcase_tutorial(_number, "");
    with (obj_tutorial_guide) instance_destroy();
    var _found = noone;
    with (obj_opcode_node) {
        if (!is_macro && opcode_mnemonic == _mnemonic && (_found == noone || node_y < _found.node_y)) _found = id;
    }
    if (_found == noone) return;
    var _mx = _found.node_x + global.pan_x + _found.node_width / 2;
    var _my = _found.node_y + global.pan_y + 8;
    window_mouse_set(_mx * window_get_width() / room_width, _my * window_get_height() / room_height);
}

/// Mouse over the palette with _letters typed (type to find), on tutorial 2.
function scr_amiga_showcase_palette_find(_letters) {
    with (obj_tracker_editor) instance_destroy();
    scr_amiga_showcase_tutorial(2, "");
    with (obj_tutorial_guide) instance_destroy();
    global.palette_scroll_y = 0;
    window_mouse_set(268 * window_get_width() / room_width, 1060 * window_get_height() / room_height);
    global.palette_find = _letters;
    scr_palette_find_scroll();
}

/// Starts (or continues) the tour on the step titled _title.
function scr_amiga_showcase_tour_step(_title) {
    var _tour = instance_find(obj_editor_tour, 0);
    if (_tour == noone) return;
    if (_tour.tour_state != "run") _tour.tour_begin();
    var _i = 0;
    while (_i < array_length(_tour.tour_queue)) {
        if (_tour.tour_queue[_i].step.title == _title) {
            _tour.tour_index = _i;
            _tour.tour_enter();
            return;
        }
        _i += 1;
    }
}

/// A 32-colour sunset for the bitmap editor and a spaceship BOB.
function scr_amiga_showcase_art() {
    scr_amiga_art_sunset_bitmap();
    scr_asset_define_bob("TestBob", 32, 32, scr_amiga_art_ship_pixels(0));
}

/// TestBitmap: a sunset over the sea, palette 0..10 + a 16-colour sky (16..31).
/// Also the picture of tutorials 12 and 14.
function scr_amiga_art_sunset_bitmap() {
    var _r = array_create(32, 0);
    var _g = array_create(32, 0);
    var _b = array_create(32, 0);
    //            0  1   2   3   4  5  6  7  8  9  10
    var _base_r = [0, 15, 15, 15, 2, 3, 4, 0, 1, 2, 1];
    var _base_g = [0, 15, 14, 10, 1, 2, 3, 1, 2, 4, 3];
    var _base_b = [0, 15, 6, 3, 3, 5, 7, 6, 8, 10, 1];
    var _i = 0;
    while (_i < array_length(_base_r)) {
        _r[_i] = _base_r[_i];
        _g[_i] = _base_g[_i];
        _b[_i] = _base_b[_i];
        _i += 1;
    }
    // 16..31: the sky, night blue at the top to orange at the horizon.
    _i = 0;
    while (_i < 16) {
        var _t = _i / 15;
        _r[16 + _i] = round(lerp(0, 15, power(_t, 0.8)));
        _g[16 + _i] = round(lerp(1, 8, _t * _t));
        _b[16 + _i] = round(lerp(4, 3, _t) + 4 * sin(_t * pi));
        _i += 1;
    }

    var _horizon = 160;
    var _pixels = array_create(320 * 256, 0);
    var _y = 0;
    while (_y < 256) {
        var _x = 0;
        while (_x < 320) {
            var _c = 0;
            if (_y < _horizon) {
                var _band = _y / _horizon * 16;
                var _k = floor(_band);
                if (frac(_band) > 0.5 && ((_x + _y) mod 2) == 0) _k += 1;
                _c = 16 + clamp(_k, 0, 15);
                var _dx = _x - 160;
                var _dy = _y - 128;
                if (_dx * _dx + _dy * _dy < 38 * 38 && !(_y > 128 && (_y mod 6) < 2)) _c = _y < 118 ? 2 : 3;
                if (_y > _horizon - 40 + 14 * sin(_x * 0.031) + 7 * sin(_x * 0.083)) _c = 6;
                if (_y > _horizon - 22 + 10 * sin(_x * 0.047 + 1) + 5 * sin(_x * 0.13)) _c = 5;
                if (_y > _horizon - 8 + 4 * sin(_x * 0.09 + 2)) _c = 4;
            } else {
                var _depth = (_y - _horizon) / (256 - _horizon);
                _c = _depth < 0.25 ? 9 : (_depth < 0.6 ? 8 : 7);
                if ((_y mod 4) == 0 && ((_x div 8 + _y) mod 3) == 0) _c = 9;
                if (abs(_x - 160) < 38 * (1 - _depth * 0.7) && (_y mod 3) == 0) _c = (_y mod 6) == 0 ? 2 : 3;
            }
            _pixels[_y * 320 + _x] = _c;
            _x += 1;
        }
        _y += 1;
    }
    scr_asset_define_bitmap("TestBitmap", _pixels, _r, _g, _b);
}

/// A little spaceship, 32 x 32, colours from the sunset palette. _frame 0..3
/// flickers the engine flame (the frames of tutorial 14's ANIM BOB).
function scr_amiga_art_ship_pixels(_frame) {
    var _flame = [3, 1, 2, 0][_frame mod 4];      // frame 0 = the full flame
    var _bob = array_create(32 * 32, 0);
    var _y = 0;
    while (_y < 32) {
        var _x2 = 0;
        while (_x2 < 32) {
            var _cx = _x2 - 15.5;
            var _cy = _y - 15.5;
            var _c2 = 0;
            if (abs(_cx) < 4 && _cy > -14 && _cy < 10 - abs(_cx)) _c2 = 9;               // hull
            if (abs(_cx) < 2 && _cy > -10 && _cy < -4) _c2 = 1;                           // cockpit
            if (_cy > -2 && _cy < 8 && abs(_cx) < 4 + (_cy + 2) * 1.1 && abs(_cx) >= 4) _c2 = 5;   // wings
            if (_cy >= 8 && _cy < 11 + _flame && abs(_cx) < 2.5 - (_cy - 8) * 0.3) _c2 = ((_y + _frame) mod 2) == 0 ? 2 : 3;   // flame
            _bob[_y * 32 + _x2] = _c2;
            _x2 += 1;
        }
        _y += 1;
    }
    return _bob;
}

function scr_amiga_selftest_showcase_step() {
    var _dir = global.amiga_dev_data_path + "/showcase";
    // The start-up splash first, at a few points of its fade.
    if (global.selftest_stage == 0) {
        var _splash = [10, 40, 80, 120];
        var _s = 0;
        while (_s < array_length(_splash)) {
            if (global.selftest_timer == _splash[_s]) screen_save(_dir + "/01_splash_" + string(_s + 1) + ".png");
            _s += 1;
        }
        if (global.selftest_timer < 240) return;
        global.selftest_showcase_shots = scr_amiga_showcase_shots();
        global.selftest_showcase_index = 0;
        global.selftest_stage = 1;
        global.selftest_timer = 0;
    }

    var _shots = global.selftest_showcase_shots;
    if (global.selftest_showcase_index >= array_length(_shots)) {
        with (obj_editor_tour) tour_finish();
        scr_tour_close_editors();
        scr_amiga_selftest_note("showcase: " + string(array_length(_shots)) + " screens + splash saved to " + _dir);
        global.workspace_dirty = false;
        scr_amiga_selftest_finish(true);
        return;
    }
    var _shot = _shots[global.selftest_showcase_index];
    if (global.selftest_timer == 1) _shot.setup();
    if (global.selftest_timer == 24) {
        screen_save(_dir + "/" + _shot.name + ".png");
        global.selftest_showcase_index += 1;
        global.selftest_timer = 0;
    }
}
