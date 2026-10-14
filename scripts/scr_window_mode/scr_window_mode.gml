/// Window mode: FULL SCREEN or a resizable window (toolbar WINDOWED /
/// FULL SCREEN button, F11). The room is always 1920x1080: GameMaker scales
/// it to the window keeping the aspect ratio (letterboxed), and the GUI layer
/// is pinned to the same size so Draw GUI positions and mouse_x / mouse_y
/// stay in room coordinates in both modes.
///
/// FULL SCREEN is a borderless window covering the display, not GameMaker's
/// window_set_fullscreen: that one is minimised as soon as another window
/// (FS-UAE, a file dialog, the taskbar) takes the focus.
///
/// settings.ini: [ui] window_mode = "fullscreen" | "windowed",
///               [ui] window_w / window_h (last windowed size).

#macro WINDOW_MIN_W 960
#macro WINDOW_MIN_H 540

global.window_is_fullscreen = true;

/// Applies the saved mode at startup. Self tests (-adm... parameters) always
/// run full screen so their screenshots have the usual size.
function scr_window_mode_init() {
    display_set_gui_size(room_width, room_height);
    window_set_min_width(WINDOW_MIN_W);
    window_set_min_height(WINDOW_MIN_H);

    var _fullscreen = true;
    ini_open("settings.ini");
    _fullscreen = ini_read_string("ui", "window_mode", "fullscreen") != "windowed";
    ini_close();

    var _i = 0;
    while (_i < parameter_count()) {
        if (string_copy(string_lower(parameter_string(_i)), 1, 4) == "-adm") _fullscreen = true;
        _i += 1;
    }
    scr_window_apply(_fullscreen);
}

/// Switches to full screen (true) or to a centred resizable window (false).
/// _remember saves the current window size first (when leaving a window
/// the user had; not at startup, where the window is still the default).
function scr_window_apply(_fullscreen, _remember = false) {
    if (_fullscreen) {
        // Remember the windowed size for next time.
        if (_remember && !global.window_is_fullscreen && window_get_width() >= WINDOW_MIN_W) {
            ini_open("settings.ini");
            ini_write_real("ui", "window_w", window_get_width());
            ini_write_real("ui", "window_h", window_get_height());
            ini_close();
        }
        window_set_showborder(false);
        window_set_position(0, 0);
        window_set_size(display_get_width(), display_get_height());
    } else {
        window_set_showborder(true);
        ini_open("settings.ini");
        var _w = ini_read_real("ui", "window_w", 0);
        var _h = ini_read_real("ui", "window_h", 0);
        ini_close();
        // Default: 80% of the display, 16:9.
        if (_w < WINDOW_MIN_W || _h < WINDOW_MIN_H) {
            _w = round(display_get_width() * 0.8);
            _h = round(_w * 9 / 16);
        }
        _w = min(_w, display_get_width());
        _h = min(_h, display_get_height() - 60);
        window_set_size(_w, _h);
        window_center();
    }
    global.window_is_fullscreen = _fullscreen;
    display_set_gui_size(room_width, room_height);
}

/// Toolbar button / F11: flips the mode and saves it.
function scr_window_toggle() {
    var _fullscreen = !global.window_is_fullscreen;
    scr_window_apply(_fullscreen, true);
    ini_open("settings.ini");
    ini_write_string("ui", "window_mode", _fullscreen ? "fullscreen" : "windowed");
    ini_close();
    scr_set_status_message(_fullscreen ? "Full screen (F11 for a window)." : "Windowed - drag the edges to resize (F11 for full screen).",
        make_colour_rgb(0, 255, 255));
}
