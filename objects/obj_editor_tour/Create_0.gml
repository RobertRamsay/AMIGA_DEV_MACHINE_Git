/// @description Editor tour (see scr_editor_tour)
// States: "menu" (choose categories), "run" (walk the steps), "done".
// Modal: listed in scr_amiga_modal_open, and every editor's Step yields to
// it, so its clicks and keys never reach the screen underneath.
depth = -900000;

tour_categories = scr_tour_categories();
tour_selected = array_create(array_length(tour_categories), true);
tour_state = "menu";
tour_queue = [];                // { category_index, step_index, step }
tour_index = 0;
tour_auto = false;
tour_step_started = current_time;
tour_stash = undefined;         // the user's workspace while the demo runs
tour_input_delay = 2;
tour_controls = [];             // { x1, y1, x2, y2, action, label, colour, enabled, kind, value }
tour_hover = -1;
tour_panel = [0, 0, 0, 0];
tour_rect = undefined;          // highlighted region of the current step
tour_header = "";
tour_title = "";
tour_lines = [];
tour_settle = 0;                // frames left in which the graph may run its Step

tour_line_h = 17;
tour_panel_w = 540;

/// Steps of the selected categories, in order.
tour_build_queue = function() {
    tour_queue = [];
    var _c = 0;
    while (_c < array_length(tour_categories)) {
        if (tour_selected[_c]) {
            var _steps = tour_categories[_c].steps;
            var _s = 0;
            while (_s < array_length(_steps)) {
                array_push(tour_queue, { category_index : _c, step_index : _s, step : _steps[_s] });
                _s += 1;
            }
        }
        _c += 1;
    }
};

tour_selected_step_count = function() {
    var _n = 0;
    var _c = 0;
    while (_c < array_length(tour_categories)) {
        if (tour_selected[_c]) _n += array_length(tour_categories[_c].steps);
        _c += 1;
    }
    return _n;
};

tour_begin = function() {
    tour_build_queue();
    if (array_length(tour_queue) == 0) {
        scr_set_status_message("Tick at least one category to start the tour.", c_orange);
        return;
    }
    if (tour_stash == undefined) {
        tour_stash = scr_tour_stash_workspace();
        scr_tour_build_demo();
        tour_settle = 3;
        global.tour_settling = true;
    }
    tour_state = "run";
    tour_index = 0;
    tour_enter();
};

tour_enter = function() {
    var _step = tour_queue[tour_index].step;
    scr_tour_show(_step.show);
    tour_step_started = current_time;
};

tour_next = function() {
    if (tour_index < array_length(tour_queue) - 1) {
        tour_index += 1;
        tour_enter();
    } else {
        tour_state = "done";
        tour_auto = false;
        scr_tour_show("main");
    }
};

tour_prev = function() {
    if (tour_index > 0) {
        tour_index -= 1;
        tour_enter();
    }
};

tour_skip_category = function() {
    var _category = tour_queue[tour_index].category_index;
    while (tour_index < array_length(tour_queue) && tour_queue[tour_index].category_index == _category) tour_index += 1;
    if (tour_index >= array_length(tour_queue)) {
        tour_index = array_length(tour_queue) - 1;
        tour_state = "done";
        tour_auto = false;
        scr_tour_show("main");
    } else {
        tour_enter();
    }
};

/// Ends the tour: the user's workspace comes back.
tour_finish = function() {
    if (tour_stash != undefined) {
        var _stash = tour_stash;
        tour_stash = undefined;
        scr_tour_restore_workspace(_stash);
        scr_set_status_message("Tour finished - your workspace is back as it was.", make_colour_rgb(0, 255, 255));
    }
    instance_destroy();
};

tour_action = function(_control) {
    switch (_control.action) {
        case "toggle": tour_selected[_control.value] = !tour_selected[_control.value]; break;
        case "all": tour_selected = array_create(array_length(tour_categories), true); break;
        case "none": tour_selected = array_create(array_length(tour_categories), false); break;
        case "start": tour_begin(); break;
        case "close": tour_finish(); break;
        case "next": tour_next(); break;
        case "prev": tour_prev(); break;
        case "skip": tour_skip_category(); break;
        case "auto":
            tour_auto = !tour_auto;
            tour_step_started = current_time;
            break;
        case "slower": scr_tour_set_delay(global.tour_delay_seconds + 1); break;
        case "faster": scr_tour_set_delay(global.tour_delay_seconds - 1); break;
        case "menu":
            tour_state = "menu";
            tour_auto = false;
            scr_tour_show("main");
            break;
    }
};

tour_add_control = function(_x1, _y1, _x2, _y2, _action, _label, _colour, _enabled = true, _kind = "button", _value = 0) {
    array_push(tour_controls, { x1 : _x1, y1 : _y1, x2 : _x2, y2 : _y2, action : _action, label : _label, colour : _colour, enabled : _enabled, kind : _kind, value : _value });
};

/// Panel, text and controls for the current state (Step calls it each frame;
/// Draw reuses the result).
tour_layout = function() {
    tour_controls = [];
    draw_set_font(UI_FONT_GUIDE);
    var _blue = make_colour_rgb(40, 80, 150);
    var _green = make_colour_rgb(30, 120, 60);
    var _grey = make_colour_rgb(70, 74, 90);
    var _red = make_colour_rgb(140, 45, 50);
    var _orange = make_colour_rgb(160, 95, 25);

    if (tour_state == "menu") {
        tour_rect = undefined;
        // Two columns of category rows, numbered down the left column first.
        var _w = 1240;
        var _row_h = 56;
        var _count = array_length(tour_categories);
        var _rows = ceil(_count / 2);
        var _h = 130 + _rows * _row_h + 120;
        var _x1 = (room_width - _w) div 2;
        var _y1 = max(20, (room_height - _h) div 2);
        tour_panel = [_x1, _y1, _x1 + _w, _y1 + _h];
        var _list_y = _y1 + 130;
        var _col_w = (_w - 50) div 2;
        var _c = 0;
        while (_c < _count) {
            var _rx = _x1 + 20 + (_c div _rows) * (_col_w + 10);
            var _ry = _list_y + (_c mod _rows) * _row_h;
            tour_add_control(_rx, _ry, _rx + _col_w, _ry + _row_h - 6, "toggle", tour_categories[_c].title, _grey, true, "row", _c);
            _c += 1;
        }
        var _by = _list_y + _rows * _row_h + 14;
        tour_add_control(_x1 + 20, _by, _x1 + 120, _by + 30, "all", "ALL", _blue);
        tour_add_control(_x1 + 130, _by, _x1 + 230, _by + 30, "none", "NONE", _blue);
        tour_add_control(_x1 + 300, _by, _x1 + 480, _by + 30, "auto", tour_auto ? "AUTO-PLAY: ON" : "AUTO-PLAY: OFF", tour_auto ? _green : _grey);
        tour_add_control(_x1 + 490, _by, _x1 + 520, _by + 30, "faster", "-", _grey);
        tour_add_control(_x1 + 525, _by, _x1 + 625, _by + 30, "", string(global.tour_delay_seconds) + " s / step", _grey, false, "label");
        tour_add_control(_x1 + 630, _by, _x1 + 660, _by + 30, "slower", "+", _grey);
        var _steps = tour_selected_step_count();
        var _by2 = _by + 50;
        tour_add_control(_x1 + 20, _by2, _x1 + _w - 200, _by2 + 40, "start", _steps > 0 ? "START TOUR  (" + string(_steps) + " steps)" : "TICK A CATEGORY TO START", _green, _steps > 0);
        tour_add_control(_x1 + _w - 180, _by2, _x1 + _w - 20, _by2 + 40, "close", "CLOSE", _red);
        return;
    }

    if (tour_state == "done") {
        tour_rect = undefined;
        var _dw = 560;
        tour_header = "EDITOR TOUR";
        tour_title = "That's the tour!";
        tour_lines = scr_tutorial_ui_wrap_lines("You've seen " + string(array_length(tour_queue)) + " steps. END TOUR puts your own workspace back exactly as it was; CATEGORIES picks more to see. The TUTORIALS page builds real programs step by step.", _dw - 40);
        var _dh = 100 + array_length(tour_lines) * tour_line_h + 70;
        var _dx = (room_width - _dw) div 2;
        var _dy = (room_height - _dh) div 2;
        tour_panel = [_dx, _dy, _dx + _dw, _dy + _dh];
        tour_add_control(_dx + 20, _dy + _dh - 50, _dx + 200, _dy + _dh - 16, "menu", "CATEGORIES", _blue);
        tour_add_control(_dx + _dw - 200, _dy + _dh - 50, _dx + _dw - 20, _dy + _dh - 16, "close", "END TOUR", _green);
        return;
    }

    // Running: the step's panel sits beside its highlight.
    var _entry = tour_queue[tour_index];
    var _step = _entry.step;
    var _category = tour_categories[_entry.category_index];
    tour_rect = is_callable(_step.rect) ? _step.rect() : undefined;
    if (tour_rect != undefined) {
        // Keep the outline on screen.
        tour_rect = [clamp(tour_rect[0], 0, room_width), clamp(tour_rect[1], 0, room_height), clamp(tour_rect[2], 0, room_width), clamp(tour_rect[3], 0, room_height)];
        if (tour_rect[2] - tour_rect[0] < 2 || tour_rect[3] - tour_rect[1] < 2) tour_rect = undefined;
    }
    var _cat_steps = array_length(_category.steps);
    tour_header = string_upper(_category.title) + "   " + string(_entry.step_index + 1) + "/" + string(_cat_steps) + "   (" + string(tour_index + 1) + " of " + string(array_length(tour_queue)) + ")";
    tour_title = _step.title;
    tour_lines = scr_tutorial_ui_wrap_lines(_step.text, tour_panel_w - 40);
    var _ph = 100 + array_length(tour_lines) * tour_line_h + 96;
    var _pos = scr_tour_place_panel(tour_panel_w, _ph, tour_rect, scr_tour_editor_panel_rect());
    var _px = _pos[0];
    var _py = _pos[1];
    tour_panel = [_px, _py, _px + tour_panel_w, _py + _ph];
    var _row1 = _py + _ph - 86;
    var _row2 = _py + _ph - 46;
    var _last = tour_index >= array_length(tour_queue) - 1;
    tour_add_control(_px + 20, _row1, _px + 150, _row1 + 32, "prev", "< PREV", _blue, tour_index > 0);
    tour_add_control(_px + 160, _row1, _px + 330, _row1 + 32, "next", _last ? "FINISH >" : "NEXT >", _green);
    tour_add_control(_px + 340, _row1, _px + tour_panel_w - 20, _row1 + 32, "skip", "SKIP CATEGORY >>", _orange);
    tour_add_control(_px + 20, _row2, _px + 190, _row2 + 32, "auto", tour_auto ? "AUTO: ON" : "AUTO: OFF", tour_auto ? _green : _grey);
    tour_add_control(_px + 200, _row2, _px + 232, _row2 + 32, "faster", "-", _grey);
    tour_add_control(_px + 236, _row2, _px + 330, _row2 + 32, "", string(global.tour_delay_seconds) + " s", _grey, false, "label");
    tour_add_control(_px + 334, _row2, _px + 366, _row2 + 32, "slower", "+", _grey);
    tour_add_control(_px + tour_panel_w - 170, _row2, _px + tour_panel_w - 20, _row2 + 32, "close", "END TOUR", _red);
};
