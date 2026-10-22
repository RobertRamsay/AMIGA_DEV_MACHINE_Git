/// @description Opening page: start options + tutorial list (full-screen modal)
// Opened with scr_tutorial_home_open(_at_startup). Step lays out every
// clickable control in home_controls (rectangles + action) that Draw reuses,
// so hit testing and drawing can never disagree.
depth = -450000;

home_at_startup = false;
home_input_delay = 2;               // frames before clicks count (the click that opened it)
home_scroll = 0;
home_scroll_max = 0;
home_controls = [];
home_hover = -1;                    // index into home_controls

// Geometry (room 1920 x 1080). The start column and the card list share
// their top and bottom edges.
home_left_x = 40;
home_left_w = 400;
home_list_x = 480;
home_list_w = 1400;
home_list_top = 176;
home_list_bottom = 1060;
home_card_cols = 2;
home_card_gap_x = 64;                // room for the MORE indicator between the columns
home_card_gap_y = 12;
home_card_w = (home_list_w - home_card_gap_x * (home_card_cols - 1)) div home_card_cols;
home_pad = 12;                      // inner padding of cards and panels
home_button_pad = 9;                // vertical padding of the start buttons

// Line heights of the page's fonts (body / headings / chips).
draw_set_font(UI_FONT_GUIDE);
home_text_h = string_height("Ag");
draw_set_font(UI_FONT_TITLE);
home_title_h = string_height("Ag");
draw_set_font(UI_FONT_SMALL);
home_chip_h = string_height("Ag") + 6;
home_button_h = scr_tutorial_ui_button_h();
home_badge_h = max(home_title_h, home_text_h) + 6;

// Card contents, top to bottom: title row, two lines of summary, two rows of
// feature chips (the START button sits beside them). The cards share the
// list height between them but never get smaller than their contents.
home_card_min_h = home_pad + home_badge_h + 8 + home_text_h * 2 + 10 + home_chip_h * 2 + 4 + home_pad;
home_card_h = home_card_min_h;

home_col_panel = make_colour_rgb(18, 22, 30);
home_col_card = make_colour_rgb(16, 20, 34);
home_col_card_hover = make_colour_rgb(30, 38, 62);
home_col_button = make_colour_rgb(45, 65, 85);
home_col_dim = make_colour_rgb(150, 160, 175);

/// Closes the page and swallows the click / Esc that closed it, so nothing
/// behind it reacts in the same frame.
home_close = function() {
    mouse_clear(mb_left);
    keyboard_clear(vk_escape);
    instance_destroy();
};

/// Forgets the loaded tutorial (another workspace replaced it).
home_forget_tutorial = function() {
    global.tutorial_current = -1;
    global.tutorial_step = 0;
    with (obj_tutorial_guide) instance_destroy();
};

home_confirm_replace = function(_what) {
    if (!global.workspace_dirty) return true;
    return show_question(_what + "? Unsaved changes in the current workspace will be replaced.");
};

home_action_continue = function() {
    if (!file_exists(global.autosave_workspace_path)) exit;
    if (!home_at_startup && !home_confirm_replace("Load the last session")) exit;
    try {
        scr_load_workspace_from_path(global.autosave_workspace_path);
        home_forget_tutorial();
        global.undo_stack = [];
        global.redo_stack = [];
        scr_set_status_message("Previous session loaded.", make_colour_rgb(0, 255, 255));
    } catch (_load_error) {
        show_debug_message("Temporary autosave load failed: " + string(_load_error));
        scr_set_status_message("Previous temporary session could not be loaded.", c_red);
    }
    home_close();
};

home_action_new = function() {
    if (!home_at_startup) {
        if (!home_confirm_replace("Start a new empty workspace")) exit;
        scr_tutorial_reset_workspace();
        scr_tutorial_make_init();
        home_forget_tutorial();
        global.workspace_dirty = false;
        global.autosave_due_time = -1;
        global.undo_stack = [];
        global.redo_stack = [];
        scr_set_status_message("New empty workspace.", make_colour_rgb(0, 255, 255));
    }
    home_close();
};

home_action_open = function() {
    var _path = get_open_filename("Workspace JSON|*.json", "");
    if (_path == "") exit;
    if (!home_confirm_replace("Open " + filename_name(_path))) exit;
    try {
        scr_load_workspace_from_path(_path);
        home_forget_tutorial();
        global.undo_stack = [];
        global.redo_stack = [];
        scr_set_status_message("Workspace loaded: " + _path, make_colour_rgb(0, 255, 255));
    } catch (_open_error) {
        show_debug_message("Workspace load failed: " + string(_open_error));
        scr_set_status_message("Workspace could not be loaded: " + _path, c_red);
    }
    home_close();
};

home_action_tutorial = function(_index) {
    if (scr_tutorial_load(_index)) {
        home_close();
        scr_tutorial_guide_open();
    }
};

/// Rebuilds home_controls for the current state and scroll position.
/// Each control: { kind, action, index, x1, y1, x2, y2, label, sub }.
home_layout = function() {
    home_controls = [];

    // Start column: a heading line and a description in each button.
    var _bx1 = home_left_x;
    var _bx2 = home_left_x + home_left_w;
    var _by = home_list_top;
    var _bh = home_button_pad * 2 + home_title_h + 3 + home_text_h;
    var _start = [];
    if (file_exists(global.autosave_workspace_path)) {
        array_push(_start, { action : "continue", label : "CONTINUE LAST SESSION", sub : "Reload the work you had open last time" });
    }
    if (!home_at_startup) {
        array_push(_start, { action : "close", label : "BACK TO WORKSPACE", sub : "Close this page and carry on" });
    }
    array_push(_start, { action : "new", label : "NEW EMPTY WORKSPACE", sub : "Start from a blank INIT block" });
    array_push(_start, { action : "open", label : "OPEN WORKSPACE...", sub : "Load a saved workspace (.json)" });
    array_push(_start, { action : "tour", label : "EDITOR TOUR", sub : "A guided walk through every panel and editor" });
    array_push(_start, { action : "course", label : "68K COURSE", sub : "100 lessons and 5 exams: learn 68000 assembler" });
    var _s = 0;
    while (_s < array_length(_start)) {
        var _b = _start[_s];
        array_push(home_controls, { kind : "start", action : _b.action, index : -1,
            x1 : _bx1, y1 : _by, x2 : _bx2, y2 : _by + _bh, label : _b.label, sub : _b.sub });
        _by += _bh + 8;
        _s += 1;
    }
    // The check box row: box plus label, as wide as the label.
    draw_set_font(UI_FONT_GUIDE);
    var _check_label = "Show this page at startup";
    var _check_h = max(18, home_text_h);
    array_push(home_controls, { kind : "check", action : "show_home", index : -1,
        x1 : _bx1, y1 : _by + 4, x2 : _bx1 + _check_h + 10 + string_width(_check_label) + 4, y2 : _by + 4 + _check_h,
        label : _check_label, sub : "" });
    home_left_bottom = _by + 4 + _check_h;

    // Tutorial cards, numbered top to bottom in two columns.
    var _defs = scr_tutorial_defs();
    var _count = array_length(_defs);
    var _rows = ceil(_count / home_card_cols);
    var _fill_h = floor((home_list_bottom - home_list_top - max(0, _rows - 1) * home_card_gap_y) / max(1, _rows));
    home_card_h = max(home_card_min_h, _fill_h);
    var _content_h = _rows * home_card_h + max(0, _rows - 1) * home_card_gap_y;
    home_scroll_max = max(0, _content_h - (home_list_bottom - home_list_top));
    home_scroll = clamp(home_scroll, 0, home_scroll_max);
    var _i = 0;
    while (_i < _count) {
        var _col = _i div _rows;
        var _row = _i mod _rows;
        var _cx = home_list_x + _col * (home_card_w + home_card_gap_x);
        var _cy = home_list_top + _row * (home_card_h + home_card_gap_y) - home_scroll;
        array_push(home_controls, { kind : "card", action : "tutorial", index : _i,
            x1 : _cx, y1 : _cy, x2 : _cx + home_card_w, y2 : _cy + home_card_h, label : "", sub : "" });
        _i += 1;
    }

    // MORE indicators in the gap between the columns: more cards below
    // (bottom) or above (top). Clicking one scrolls two rows.
    var _gap_x1 = home_list_x + home_card_w;
    var _gap_x2 = _gap_x1 + home_card_gap_x;
    if (home_scroll < home_scroll_max) {
        array_push(home_controls, { kind : "more", action : "more_down", index : -1,
            x1 : _gap_x1 + 4, y1 : home_list_bottom - 148, x2 : _gap_x2 - 4, y2 : home_list_bottom, label : "MORE", sub : "" });
    }
    if (home_scroll > 0) {
        array_push(home_controls, { kind : "more", action : "more_up", index : -1,
            x1 : _gap_x1 + 4, y1 : home_list_top, x2 : _gap_x2 - 4, y2 : home_list_top + 148, label : "MORE", sub : "" });
    }

    // Close box (top right).
    array_push(home_controls, { kind : "closebox", action : "close", index : -1,
        x1 : 1864, y1 : 20, x2 : 1892, y2 : 48, label : "X", sub : "" });
};

home_left_bottom = 0;
home_layout();
