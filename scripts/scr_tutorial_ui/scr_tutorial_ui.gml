/// @desc Opening page (obj_tutorial_home) and tutorial guide panel
/// (obj_tutorial_guide): globals, settings.ini persistence, open helpers and
/// the small drawing helpers both objects share.
///
/// settings.ini:  [ui] show_home = 1/0      (opening page at startup)
///                [tutorials] done_<id> = 1 (completed tutorials)

/// Called once from obj_amiga_manager Create. Creates every global the
/// opening page and the guide use and reads their settings.
function scr_tutorial_ui_init() {
    ini_open("settings.ini");
    global.tutorial_home_show_setting = ini_read_real("ui", "show_home", 1) != 0;
    ini_close();

    // Completed tutorials, keyed "done_<id>"; filled lazily from settings.ini.
    global.tutorial_done_cache = {};

    // Guide panel state that survives the guide being closed and reopened.
    global.tutorial_guide_collapsed = false;
}

/// True when the opening page should be shown at startup ([ui] show_home).
function scr_tutorial_home_show_at_startup() {
    return global.tutorial_home_show_setting;
}

/// Stores the "Show this page at startup" choice.
function scr_tutorial_home_set_show_at_startup(_show) {
    global.tutorial_home_show_setting = _show;
    ini_open("settings.ini");
    ini_write_real("ui", "show_home", _show ? 1 : 0);
    ini_close();
}

/// True when tutorial _id (1..10, the def's id) has been marked done.
function scr_tutorial_is_done(_id) {
    var _key = "done_" + string(_id);
    if (!variable_struct_exists(global.tutorial_done_cache, _key)) {
        ini_open("settings.ini");
        global.tutorial_done_cache[$ _key] = ini_read_real("tutorials", _key, 0) != 0;
        ini_close();
    }
    return global.tutorial_done_cache[$ _key];
}

/// Marks tutorial _id (1..10) as completed in settings.ini.
function scr_tutorial_mark_done(_id) {
    var _key = "done_" + string(_id);
    global.tutorial_done_cache[$ _key] = true;
    ini_open("settings.ini");
    ini_write_real("tutorials", _key, 1);
    ini_close();
}

/// Number of tutorials marked done.
function scr_tutorial_done_count() {
    var _defs = scr_tutorial_defs();
    var _count = 0;
    var _i = 0;
    while (_i < array_length(_defs)) {
        if (scr_tutorial_is_done(_defs[_i].id)) _count += 1;
        _i += 1;
    }
    return _count;
}

/// Opens (or brings back) the full-screen opening page. _at_startup = true
/// when shown after the splash: then it replaces the automatic autosave
/// recovery (CONTINUE LAST SESSION does it instead).
function scr_tutorial_home_open(_at_startup) {
    if (_at_startup) global.autosave_recovery_pending = false;
    var _home = instance_exists(obj_tutorial_home)
        ? instance_find(obj_tutorial_home, 0)
        : instance_create_depth(0, 0, -450000, obj_tutorial_home);
    _home.home_at_startup = _at_startup;
    _home.home_input_delay = 2;
    return _home;
}

/// Opens the guide panel for the loaded tutorial (global.tutorial_current).
function scr_tutorial_guide_open() {
    global.tutorial_guide_collapsed = false;
    if (instance_exists(obj_tutorial_guide)) {
        var _guide = instance_find(obj_tutorial_guide, 0);
        _guide.guide_input_delay = 2;
        _guide.guide_text_scroll = 0;
        return _guide;
    }
    return instance_create_depth(0, 0, -350000, obj_tutorial_guide);
}

/// True when the mouse is over the guide panel (or its collapsed tab).
function scr_tutorial_guide_mouse_over() {
    if (!instance_exists(obj_tutorial_guide)) return false;
    var _guide = instance_find(obj_tutorial_guide, 0);
    if (!_guide.guide_visible) return false;
    return point_in_rectangle(mouse_x, mouse_y, _guide.guide_hit_x1, _guide.guide_hit_y1, _guide.guide_hit_x2, _guide.guide_hit_y2);
}

/// Level badge colour.
function scr_tutorial_level_colour(_level) {
    switch (_level) {
        case "Beginner": return make_colour_rgb(40, 140, 75);
        case "Intermediate": return make_colour_rgb(190, 125, 25);
        case "Advanced": return make_colour_rgb(175, 45, 85);
    }
    return make_colour_rgb(70, 80, 100);
}

/// Flat ADM-style button: fill, white border, left/centred label.
function scr_tutorial_ui_draw_button(_x1, _y1, _x2, _y2, _text, _colour, _hover, _enabled) {
    scr_ui_button(_x1, _y1, _x2, _y2, _text, _colour, _hover, _enabled);
}

/// Word-wraps _text to _width pixels in the current font; returns an array
/// of lines (so callers can draw only the lines that fit, i.e. scroll).
function scr_tutorial_ui_wrap_lines(_text, _width) {
    var _lines = [];
    var _paragraphs = string_split(_text, "\n");
    var _p = 0;
    while (_p < array_length(_paragraphs)) {
        var _words = string_split(_paragraphs[_p], " ", true);
        var _line = "";
        var _w = 0;
        while (_w < array_length(_words)) {
            var _try = _line == "" ? _words[_w] : _line + " " + _words[_w];
            if (_line != "" && string_width(_try) > _width) {
                array_push(_lines, _line);
                _line = _words[_w];
            } else {
                _line = _try;
            }
            _w += 1;
        }
        array_push(_lines, _line);
        _p += 1;
    }
    return _lines;
}

/// A tick mark drawn with lines (the fonts have no check glyph).
function scr_tutorial_ui_draw_tick(_x, _y, _size, _colour) {
    draw_set_colour(_colour);
    draw_line_width(_x, _y + _size * 0.55, _x + _size * 0.38, _y + _size * 0.9, 3);
    draw_line_width(_x + _size * 0.38, _y + _size * 0.9, _x + _size, _y + _size * 0.1, 3);
}

/// Words in _text that name a node: upper-case words of 2+ letters (with
/// spaces kept between consecutive capitals, e.g. "READ JOYSTICK" ->
/// "READ_JOYSTICK"). Used by the guide to outline matching nodes.
function scr_tutorial_ui_node_keys(_text) {
    var _keys = [];
    var _words = [];
    var _word = "";
    var _len = string_length(_text);
    var _i = 1;
    while (_i <= _len + 1) {
        var _ch = _i <= _len ? string_char_at(_text, _i) : " ";
        var _code = ord(_ch);
        var _is_word_char = (_code >= 65 && _code <= 90) || (_code >= 48 && _code <= 57) || _ch == "_"
            || (_code >= 97 && _code <= 122);
        if (_is_word_char) {
            _word += _ch;
        } else {
            if (_word != "") array_push(_words, _word);
            // A space keeps a run of capital words together; anything else
            // (comma, full stop, dash, bracket) ends the run.
            if (_ch != " ") array_push(_words, "|");
            _word = "";
        }
        _i += 1;
    }

    var _run = "";
    var _w = 0;
    while (_w <= array_length(_words)) {
        var _candidate = _w < array_length(_words) ? _words[_w] : "|";
        var _is_caps = _candidate != "|" && string_length(_candidate) >= 2 && string_upper(_candidate) == _candidate
            && string_lettersdigits(_candidate) != string_digits(_candidate);
        if (_is_caps) {
            if (!array_contains(_keys, _candidate)) array_push(_keys, _candidate);
            _run = _run == "" ? _candidate : _run + "_" + _candidate;
            if (string_pos("_", _run) > 0 && !array_contains(_keys, _run)) array_push(_keys, _run);
        } else {
            _run = "";
        }
        _w += 1;
    }
    return _keys;
}
