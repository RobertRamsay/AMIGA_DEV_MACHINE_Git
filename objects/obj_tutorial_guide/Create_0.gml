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
guide_line_h = 16;
guide_title_line_h = 20;

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
    draw_set_font(font_Future);
    guide_title_line_h = string_height("Ag");
    guide_title_lines = scr_tutorial_ui_wrap_lines(guide_def.title, guide_x2 - guide_x1 - 24);
    draw_set_font(font_CyberVerse);
    guide_line_h = string_height("Ag");
    guide_step_title_lines = scr_tutorial_ui_wrap_lines(_step.title, guide_x2 - guide_x1 - 24);
    guide_text_lines = scr_tutorial_ui_wrap_lines(_step.text, guide_x2 - guide_x1 - 36);
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
        guide_hit_x1 = guide_x2 - 150;
        guide_hit_y1 = guide_y1;
        guide_hit_x2 = guide_x2;
        guide_hit_y2 = guide_y1 + 26;
        array_push(guide_controls, { action : "expand", x1 : guide_hit_x1, y1 : guide_hit_y1, x2 : guide_hit_x2, y2 : guide_hit_y2,
            label : "TUTORIAL " + _number + "  +", colour : make_colour_rgb(40, 90, 150), enabled : true });
        exit;
    }

    // Vertical flow.
    var _y = guide_y1 + 30;
    guide_title_y = _y + 4;
    _y = guide_title_y + array_length(guide_title_lines) * guide_title_line_h + 6;
    guide_info_y = _y;
    _y += guide_line_h + 10;
    guide_dots_y = _y;
    _y += 16;
    guide_step_title_y = _y;
    _y += array_length(guide_step_title_lines) * guide_line_h + 8;
    guide_text_y1 = _y;

    var _buttons_h = 3 * 26 + 2 * 6 + 12;
    var _text_full_h = array_length(guide_text_lines) * guide_line_h;
    guide_y2 = min(guide_max_y2, guide_text_y1 + _text_full_h + 14 + _buttons_h);
    guide_y2 = max(guide_y2, guide_y1 + 300);
    guide_text_y2 = guide_y2 - _buttons_h - 8;
    guide_text_rows = max(1, floor((guide_text_y2 - guide_text_y1) / guide_line_h));
    guide_text_scroll = clamp(guide_text_scroll, 0, max(0, array_length(guide_text_lines) - guide_text_rows));

    guide_hit_x1 = guide_x1;
    guide_hit_y1 = guide_y1;
    guide_hit_x2 = guide_x2;
    guide_hit_y2 = guide_y2;

    // Header buttons.
    array_push(guide_controls, { action : "collapse", x1 : guide_x2 - 54, y1 : guide_y1 + 4, x2 : guide_x2 - 32, y2 : guide_y1 + 24,
        label : "-", colour : make_colour_rgb(55, 65, 90), enabled : true });
    array_push(guide_controls, { action : "close", x1 : guide_x2 - 26, y1 : guide_y1 + 4, x2 : guide_x2 - 4, y2 : guide_y1 + 24,
        label : "X", colour : make_colour_rgb(150, 30, 30), enabled : true });

    // Bottom buttons.
    var _done = scr_tutorial_is_done(guide_def.id);
    var _last = global.tutorial_step >= guide_step_count - 1;
    var _bx1 = guide_x1 + 10;
    var _bx2 = guide_x2 - 10;
    var _bmid = (_bx1 + _bx2) div 2;
    var _by = guide_y2 - _buttons_h + 6;
    array_push(guide_controls, { action : "prev", x1 : _bx1, y1 : _by, x2 : _bmid - 4, y2 : _by + 26,
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
    array_push(guide_controls, { action : _next_action, x1 : _bmid + 4, y1 : _by, x2 : _bx2, y2 : _by + 26,
        label : _next_label, colour : _last ? make_colour_rgb(30, 120, 50) : make_colour_rgb(40, 90, 150), enabled : true });
    _by += 32;
    array_push(guide_controls, { action : "build", x1 : _bx1, y1 : _by, x2 : _bmid - 4, y2 : _by + 26,
        label : "BUILD & RUN", colour : make_colour_rgb(30, 120, 50), enabled : true });
    array_push(guide_controls, { action : "done", x1 : _bmid + 4, y1 : _by, x2 : _bx2, y2 : _by + 26,
        label : _done ? "DONE" : "MARK DONE", colour : make_colour_rgb(25, 90, 50), enabled : !_done });
    _by += 32;
    array_push(guide_controls, { action : "all", x1 : _bx1, y1 : _by, x2 : _bx2, y2 : _by + 26,
        label : "ALL TUTORIALS", colour : make_colour_rgb(75, 65, 35), enabled : true });
};

guide_mark_done = function() {
    scr_tutorial_mark_done(guide_def.id);
    scr_set_status_message("Tutorial " + string(global.tutorial_current + 1) + " (" + guide_def.title + ") marked done.", make_colour_rgb(0, 255, 120));
};

guide_layout();
