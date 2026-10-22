/// Tutorial 17: STAR BLASTER, a vertical shoot 'em up written in CODE blocks.
/// The assembly lives in datafiles/tutorials/shmup/*.s (one file per block,
/// so it can be assembled and tested on its own); the sprites are SPR-EDIT
/// assets the code uses by name (spr_Ship ... see scr_amiga_code_sprites_text).

/// The four sprites: rows of 16 characters, "." = see-through, 1-3 = colours.
/// SPR-EDIT gives each channel pair its colours from the shared palette
/// (17-19 for channels 0-1, 21-23 for 2-3), so the ship and its shots sit on
/// channel 0, the enemy and its explosion on channel 2, and those palette
/// entries are set to their colours: the editor shows what the game plays.
function scr_tb_shmup_sprites() {
    var _defs = [
        ["Ship", 0, ["459", "BCE", "3DF"], [
            ".......33.......",
            "......3223......",
            "......2222......",
            ".....122221.....",
            ".....122221.....",
            "....11222211....",
            "...1122332211...",
            "..112223322211..",
            ".11222222222211.",
            "1112222222222111",
            "11.1122222211.11",
            "1...11222211...1",
            ".....112211.....",
            "......3..3......",
            ".....3....3.....",
            "................"]],
        ["Shot", 0, ["459", "BCE", "3DF"], [
            ".......33.......",
            ".......33.......",
            ".......33.......",
            ".......22.......",
            ".......22.......",
            ".......11.......",
            "................",
            "................"]],
        ["Enemy", 2, ["806", "F52", "FE3"], [
            "..1..........1..",
            "..11........11..",
            "...11.2222.11...",
            "....12222221....",
            "...1223333221...",
            "..122332233221..",
            ".12233222233221.",
            "1122332112332211",
            "1122332112332211",
            ".12233222233221.",
            "..122332233221..",
            "...1223333221...",
            "....12222221....",
            "...11.2222.11...",
            "..11........11..",
            "..1..........1.."]],
        ["Boom", 2, ["806", "F52", "FE3"], [
            ".......1........",
            "..1....2....1...",
            "...2..121..2....",
            "....2.232.2.....",
            ".1...23332...1..",
            "..2.2333332.2...",
            "...233333332....",
            "1223333333333221",
            "...233333332....",
            "..2.2333332.2...",
            ".1...23332...1..",
            "....2.232.2.....",
            "...2..121..2....",
            "..1....2....1...",
            ".......1........",
            "................"]]
    ];
    var _hex = "0123456789ABCDEF";
    var _palette = scr_amiga_get_shared_bitmap_palette();
    var _d = 0;
    while (_d < array_length(_defs)) {
        var _rows = _defs[_d][3];
        var _h = array_length(_rows);
        var _pixels = array_create(16 * _h, 0);
        var _y = 0;
        while (_y < _h) {
            var _x = 0;
            while (_x < 16) {
                var _c = string_char_at(_rows[_y], _x + 1);
                _pixels[_y * 16 + _x] = _c == "." ? 0 : real(_c);
                _x += 1;
            }
            _y += 1;
        }
        var _r = [0, 0, 0];
        var _g = [0, 0, 0];
        var _b = [0, 0, 0];
        var _k = 0;
        while (_k < 3) {
            var _rgb = _defs[_d][2][_k];
            _r[_k] = string_pos(string_char_at(_rgb, 1), _hex) - 1;
            _g[_k] = string_pos(string_char_at(_rgb, 2), _hex) - 1;
            _b[_k] = string_pos(string_char_at(_rgb, 3), _hex) - 1;
            _k += 1;
        }
        scr_asset_define_sprite(_defs[_d][0], _defs[_d][1], _h, $40000, _pixels, _r, _g, _b);
        var _base = 17 + (_defs[_d][1] div 2) * 4;
        array_copy(_palette.colour_r, _base, _r, 0, 3);
        array_copy(_palette.colour_g, _base, _g, 0, 3);
        array_copy(_palette.colour_b, _base, _b, 0, 3);
        _d += 1;
    }
    scr_amiga_commit_shared_bitmap_palette(_palette.colour_r, _palette.colour_g, _palette.colour_b);
}

/// The text of an included file (working_directory), "" if missing.
function scr_tb_read_text(_path) {
    var _full = working_directory + _path;
    if (!file_exists(_full)) return "";
    var _buffer = buffer_load(_full);
    if (_buffer < 0) return "";
    var _text = buffer_read(_buffer, buffer_text);
    buffer_delete(_buffer);
    return string_replace_all(_text, "\r", "");
}

/// A named, labelled CODE block from tutorials/shmup/<_file>.
function scr_tb_shmup_block(_chain, _file, _name, _label) {
    var _code = scr_tb_macro(_chain, "CODE");
    _code.macro_code_name = _name;
    _code.macro_code_text = scr_tb_read_text("tutorials/shmup/" + _file);
    _code.node_label = _label;
    return _code;
}

/// A PLAY SFX node with a label followed by RTS: code can BSR to it.
function scr_tb_sfx_subroutine(_chain, _label, _sample) {
    var _sfx = scr_tb_macro(_chain, "PLAY_SFX");
    _sfx.macro_asset_name = _sample;
    _sfx.macro_sfx_channel = -1;
    _sfx.macro_sfx_volume = -1;
    _sfx.node_label = _label;
    scr_tb_op(_chain, "RTS", "", "", 0, "", 0);
}

/// 17: STAR BLASTER. INIT column: music, then the game's blocks in the order
/// they run each frame, ending with BRA frame. ORG column: the subroutines
/// (two sound effects, the helpers) and the data.
function scr_tutorial_build_17(_chain) {
    scr_tb_shmup_sprites();
    scr_tb_sfx("Laser", 2200, "laser");
    scr_tb_sfx("Bang", 6000, "boom");
    var _music = scr_tb_hook_song("BlasterTune");
    if (_music != "") {
        var _play = scr_tb_macro(_chain, "PLAY_MOD");
        _play.macro_asset_name = _music;
        _play.macro_music_pos = 0;
    }
    scr_tb_shmup_block(_chain, "1_setup.s", "Screen setup", "setup");
    scr_tb_shmup_block(_chain, "2_frame.s", "Wait frame", "frame");
    scr_tb_shmup_block(_chain, "3_stars.s", "Stars", "stars");
    scr_tb_shmup_block(_chain, "4_ship.s", "Ship", "ship");
    scr_tb_shmup_block(_chain, "5_shots.s", "Shots", "fire_shots");
    scr_tb_shmup_block(_chain, "6_enemies.s", "Enemies", "move_enemies");
    scr_tb_shmup_block(_chain, "7_hits.s", "Collisions", "hits");
    scr_tb_shmup_block(_chain, "8_draw.s", "Draw sprites", "draw");
    scr_tb_op(_chain, "BRA", "W", "LABEL", "frame", "", 0);

    var _org = scr_tb_org(_chain);
    scr_tb_sfx_subroutine(_org, "sfx_shoot", "Laser");
    scr_tb_sfx_subroutine(_org, "sfx_boom", "Bang");
    scr_tb_shmup_block(_org, "9_subs.s", "Subroutines", "");
    scr_tb_shmup_block(_org, "10_data.s", "Data", "");
}
