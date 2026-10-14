/// @description Tutorial guide panel (non-modal, over the code preview)
// Shows the steps of the loaded tutorial (global.tutorial_current /
// global.tutorial_step). Step builds guide_controls (rectangles + action)
// which Draw reuses. Ignores input while a modal editor or the opening page
// is open. scr_tutorial_guide_mouse_over() reports the guide_hit_* rectangle.
depth = -350000;

guide_input_delay = 2;
guide_text_scroll = 0;              // first visible line of the step text
guide_visible = true;
guide_controls = [];
guide_hover = -1;

// Panel geometry: over the top of the COMPILED PROGRAM PREVIEW panel
// (x 1560..1910), leaving the lower part of the preview visible.
guide_x1 = 1564;
guide_x2 = 1906;
guide_y1 = 64;
guide_max_y2 = 620;
guide_y2 = guide_max_y2;
guide_hit_x1 = guide_x1;
guide_hit_y1 = guide_y1;
guide_hit_x2 = guide_x2;
guide_hit_y2 = guide_y2;

// Layout results (filled by guide_layout).
guide_def = undefined;
guide_step_count = 0;
guide_title_lines = [];
guide_step_title_lines = [];
guide_text_lines = [];
guide_title_y = 0;
guide_info_y = 0;
guide_dots_y = 0;
guide_step_title_y = 0;
guide_text_y1 = 0;
guide_text_y2 = 0;
guide_text_rows = 0;
guide_pad = 10;                     // inner padding of the panel

// Line heights: body text and buttons in the walkthrough font, headings in
// the title font.
draw_set_font(UI_FONT_GUIDE);
guide_line_h = string_height("Ag");
draw_set_font(UI_FONT_TITLE);
guide_title_line_h = string_height("Ag");
guide_header_h = max(guide_title_line_h, guide_line_h) + 10;
guide_button_h = scr_tutorial_ui_button_h();
guide_badge_h = guide_line_h + 6;

// Text and highlight cache, rebuilt when the tutorial or step changes.
guide_cache_key = "";
guide_node_keys = [];

/// Rebuilds the wrapped text and highlight keys for the current step.
guide_refresh_cache = function() {
    var _key = string(global.tutorial_current) + ":" + string(global.tutorial_step);
    if (_key == guide_cache_key) exit;
    guide_cache_key = _key;
    guide_text_scroll = 0;
    var _step = guide_def.steps[global.tutorial_step];
    var _inner_w = guide_x2 - guide_x1 - guide_pad * 2;
    draw_set_font(UI_FONT_TITLE);
    guide_title_lines = scr_tutorial_ui_wrap_lines(guide_def.title, _inner_w);
    guide_step_title_lines = scr_tutorial_ui_wrap_lines(_step.title, _inner_w);
    // The step text leaves room for its scroll bar.
    draw_set_font(UI_FONT_GUIDE);
    guide_text_lines = scr_tutorial_ui_wrap_lines(_step.text, _inner_w - 12);
    guide_node_keys = scr_tutorial_ui_node_keys(_step.title + ". " + _step.text);
};

/// Lays out the panel (or the collapsed tab) and its buttons.
guide_layout = function() {
    guide_controls = [];
    var _defs = scr_tutorial_defs();
    guide_visible = global.tutorial_current >= 0 && global.tutorial_current < array_length(_defs);
    if (!guide_visible) exit;

    guide_def = _defs[global.tutorial_current];
    guide_step_count = array_length(guide_def.steps);
    global.tutorial_step = clamp(global.tutorial_step, 0, max(0, guide_step_count - 1));
    guide_refresh_cache();

    var _number = string(global.tutorial_current + 1);

    if (global.tutorial_guide_collapsed) {
        // A slim tab at the panel's top-right corner; it stops short of the
        // preview's COLLAPSE ALL button below it.
        draw_set_font(UI_FONT_GUIDE);
        var _tab_label = "TUTORIAL " + _number + "  +";
        guide_hit_x1 = guide_x2 - (string_width(_tab_label) + 32);
        guide_hit_y1 = guide_y1 - 2;
        guide_hit_x2 = guide_x2;
        guide_hit_y2 = guide_y1 + 22;
        array_push(guide_controls, { action : "expand", x1 : guide_hit_x1, y1 : guide_hit_y1, x2 : guide_hit_x2, y2 : guide_hit_y2,
            label : _tab_label, colour : make_colour_rgb(40, 90, 150), enabled : true });
        exit;
    }

    // Vertical flow: header band, title, level + step row, step bar, step
    // title, step text, three rows of buttons.
    var _gap = 8;
    var _y = guide_y1 + guide_header_h + 2 + _gap;
    guide_title_y = _y;
    _y += array_length(guide_title_lines) * guide_title_line_h + _gap;
    guide_info_y = _y;
    _y += guide_badge_h + _gap + 2;
    guide_dots_y = _y;
    _y += 6 + _gap + 4;
    guide_step_title_y = _y;
    _y += array_length(guide_step_title_lines) * guide_title_line_h + 6;
    guide_text_y1 = _y;

    var _button_gap = 6;
    // A step with a song_stage (tutorial 16) gets a SHOW ME row on top.
    var _step_def = guide_def.steps[global.tutorial_step];
    var _show_me = variable_struct_exists(_step_def, "song_stage");
    var _button_rows = _show_me ? 4 : 3;
    var _buttons_h = _button_rows * guide_button_h + (_button_rows - 1) * _button_gap + guide_pad;
    var _text_full_h = array_length(guide_text_lines) * guide_line_h;
    // At least four lines of text, so the buttons stay put on short steps.
    var _text_h = clamp(_text_full_h, guide_line_h * 4, guide_max_y2 - _buttons_h - _gap - guide_text_y1);
    guide_y2 = guide_text_y1 + _text_h + _gap + _buttons_h;
    guide_text_y2 = guide_text_y1 + _text_h;
    guide_text_rows = max(1, floor(_text_h / guide_line_h));
    guide_text_scroll = clamp(guide_text_scroll, 0, max(0, array_length(guide_text_lines) - guide_text_rows));

    guide_hit_x1 = guide_x1;
    guide_hit_y1 = guide_y1;
    guide_hit_x2 = guide_x2;
    guide_hit_y2 = guide_y2;

    // Header buttons, square, centred in the header band.
    var _hs = guide_header_h - 8;
    var _hy1 = guide_y1 + 4;
    array_push(guide_controls, { action : "collapse", x1 : guide_x2 - 6 - _hs * 2 - 4, y1 : _hy1, x2 : guide_x2 - 6 - _hs - 4, y2 : _hy1 + _hs,
        label : "-", colour : make_colour_rgb(55, 65, 90), enabled : true });
    array_push(guide_controls, { action : "close", x1 : guide_x2 - 6 - _hs, y1 : _hy1, x2 : guide_x2 - 6, y2 : _hy1 + _hs,
        label : "X", colour : make_colour_rgb(150, 30, 30), enabled : true });

    // Bottom buttons.
    var _done = scr_tutorial_is_done(guide_def.id);
    var _last = global.tutorial_step >= guide_step_count - 1;
    var _bx1 = guide_x1 + guide_pad;
    var _bx2 = guide_x2 - guide_pad;
    var _bmid = (_bx1 + _bx2) div 2;
    var _bh = guide_button_h;
    var _by = guide_y2 - guide_pad - _button_rows * _bh - (_button_rows - 1) * _button_gap;
    if (_show_me) {
        array_push(guide_controls, { action : "showme", x1 : _bx1, y1 : _by, x2 : _bx2, y2 : _by + _bh,
            label : "SHOW ME IN THE TRACKER", colour : make_colour_rgb(25, 95, 100), enabled : true });
        _by += _bh + _button_gap;
    }
    array_push(guide_controls, { action : "prev", x1 : _bx1, y1 : _by, x2 : _bmid - 3, y2 : _by + _bh,
        label : "< PREV", colour : make_colour_rgb(45, 65, 85), enabled : global.tutorial_step > 0 });
    var _next_action = "next", _next_label = "NEXT >";
    if (_last) {
        if (!_done) {
            _next_action = "finish"; _next_label = "FINISH";
        } else if (global.tutorial_current + 1 < array_length(_defs)) {
            _next_action = "next_tutorial"; _next_label = "NEXT TUTORIAL >";
        } else {
            _next_action = "all"; _next_label = "ALL TUTORIALS";
        }
    }
    array_push(guide_controls, { action : _next_action, x1 : _bmid + 3, y1 : _by, x2 : _bx2, y2 : _by + _bh,
        label : _next_label, colour : _last ? make_colour_rgb(30, 120, 50) : make_colour_rgb(40, 90, 150), enabled : true });
    _by += _bh + _button_gap;
    array_push(guide_controls, { action : "build", x1 : _bx1, y1 : _by, x2 : _bmid - 3, y2 : _by + _bh,
        label : "BUILD & RUN", colour : make_colour_rgb(30, 120, 50), enabled : true });
    array_push(guide_controls, { action : "done", x1 : _bmid + 3, y1 : _by, x2 : _bx2, y2 : _by + _bh,
        label : _done ? "DONE" : "MARK DONE", colour : make_colour_rgb(25, 90, 50), enabled : !_done });
    _by += _bh + _button_gap;
    array_push(guide_controls, { action : "all", x1 : _bx1, y1 : _by, x2 : _bx2, y2 : _by + _bh,
        label : "ALL TUTORIALS", colour : make_colour_rgb(75, 65, 35), enabled : true });
};

guide_mark_done = function() {
    scr_tutorial_mark_done(guide_def.id);
    scr_set_status_message("Tutorial " + string(global.tutorial_current + 1) + " (" + guide_def.title + ") marked done.", make_colour_rgb(0, 255, 120));
};

guide_layout();
