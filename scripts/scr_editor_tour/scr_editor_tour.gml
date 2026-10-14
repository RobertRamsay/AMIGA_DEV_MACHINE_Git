/// @desc Editor tour: a guided walkthrough of the whole editor suite.
/// obj_editor_tour shows a category picker (any categories, or all), then
/// walks through the steps of the chosen ones: each step opens the editor it
/// is about (scr_tour_show) and highlights a live rectangle of the real UI
/// (step.rect()). PREV / NEXT / SKIP CATEGORY / AUTO with a delay in seconds
/// ([tour] delay in settings.ini).
///
/// The tour runs on a demo workspace (tutorial 10 plus a column of classic
/// nodes, scr_tour_build_demo). The user's workspace is saved to a stash file
/// first and loaded back when the tour ends; autosave is off meanwhile.
///
/// Category: { id, title, summary, steps[] }
/// Step:     { title, text, show, rect }   show = scr_tour_show() view id,
///           rect = function returning [x1, y1, x2, y2] (room coordinates)
///           or undefined (no highlight).
///
/// Categories live in scr_editor_tour_steps.

function scr_tour_init() {
    ini_open("settings.ini");
    global.tour_delay_seconds = clamp(ini_read_real("tour", "delay", 6), 1, 60);
    ini_close();
    global.tour_categories_cache = undefined;
    // True for a few frames after the demo is built: the graph runs its Step
    // once (preview, column links, operand rows) before the tour takes over.
    global.tour_settling = false;
}

function scr_tour_set_delay(_seconds) {
    global.tour_delay_seconds = clamp(round(_seconds), 1, 60);
    ini_open("settings.ini");
    ini_write_real("tour", "delay", global.tour_delay_seconds);
    ini_close();
}

/// Opens the tour's category picker; returns the instance.
function scr_tour_open() {
    if (instance_exists(obj_editor_tour)) return instance_find(obj_editor_tour, 0);
    return instance_create_depth(0, 0, -900000, obj_editor_tour);
}

function scr_tour_active() {
    return instance_exists(obj_editor_tour);
}

// ---------------------------------------------------------------------------
// The user's workspace is put aside while the tour shows its demo.

function scr_tour_stash_workspace() {
    // The recovery file gets the latest work first, in case the app dies
    // mid-tour (that clears the dirty flag, so remember it beforehand).
    var _dirty = global.workspace_dirty;
    if (_dirty) scr_write_temp_autosave();
    var _stash = {
        path : global.amiga_dev_data_path + "/tour_stash_workspace.json",
        dirty : _dirty,
        tutorial : global.tutorial_current,
        tutorial_step : global.tutorial_step,
        undo : global.undo_stack,
        redo : global.redo_stack,
        pan_x : global.pan_x,
        pan_y : global.pan_y
    };
    scr_save_workspace_to_path(_stash.path, false);
    return _stash;
}

function scr_tour_restore_workspace(_stash) {
    scr_tour_close_editors();
    if (file_exists(_stash.path)) {
        try {
            scr_load_workspace_from_path(_stash.path);
            file_delete(_stash.path);
        } catch (_error) {
            show_debug_message("Tour: workspace restore failed: " + string(_error));
            scr_set_status_message("The tour could not put your workspace back - it is in " + _stash.path, c_red);
        }
    }
    global.tutorial_current = _stash.tutorial;
    global.tutorial_step = _stash.tutorial_step;
    global.undo_stack = _stash.undo;
    global.redo_stack = _stash.redo;
    global.pan_x = _stash.pan_x;
    global.pan_y = _stash.pan_y;
    global.workspace_dirty = _stash.dirty;
    global.autosave_due_time = _stash.dirty ? current_time + global.autosave_delay_ms : -1;
    if (global.tutorial_current >= 0) scr_tutorial_guide_open();
}

// ---------------------------------------------------------------------------
// Rectangles.

function scr_tour_rect(_x1, _y1, _x2, _y2) {
    return [min(_x1, _x2), min(_y1, _y2), max(_x1, _x2), max(_y1, _y2)];
}

/// First demo node of macro type _type (or opcode mnemonic when _opcode), or noone.
function scr_tour_find_node(_type, _opcode = false) {
    var _found = noone;
    var _best_y = 1000000000;
    with (obj_opcode_node) {
        var _match = _opcode ? (!is_macro && opcode_mnemonic == _type) : (is_macro && macro_type == _type);
        if (_match && node_y < _best_y) {
            _found = id;
            _best_y = node_y;
        }
    }
    return _found;
}

/// Screen rectangle of a node; _dy1/_dy2 select a band inside it (offsets from
/// the node's top; _dy2 < 0 means the bottom).
function scr_tour_node_rect(_node, _dy1 = 0, _dy2 = -1) {
    if (_node == noone || !instance_exists(_node)) return undefined;
    var _x = _node.node_x + global.pan_x;
    var _y = _node.node_y + global.pan_y;
    var _bottom = _dy2 < 0 ? _node.node_height : _dy2;
    return [_x, _y + _dy1, _x + _node.node_width, _y + _bottom];
}

function scr_tour_root_rect(_root_type) {
    var _rect = undefined;
    with (obj_amiga_root_node) {
        if (root_type == _root_type && _rect == undefined) {
            _rect = [node_x + global.pan_x, node_y + global.pan_y, node_x + global.pan_x + node_width, node_y + global.pan_y + node_height];
        }
    }
    return _rect;
}

/// Bounding box of a whole column: a root and every node connected to it.
function scr_tour_column_rect(_root_type) {
    var _rect = scr_tour_root_rect(_root_type);
    if (_rect == undefined) return undefined;
    var _uid = -1;
    with (obj_amiga_root_node) if (root_type == _root_type && _uid == -1) _uid = uid;
    with (obj_opcode_node) {
        if (is_connected && root_uid == _uid) {
            _rect[0] = min(_rect[0], node_x + global.pan_x);
            _rect[2] = max(_rect[2], node_x + global.pan_x + node_width);
            _rect[3] = max(_rect[3], node_y + global.pan_y + node_height);
        }
    }
    return _rect;
}

/// Toolbar button at (_x, _y) of the manager's top strip.
function scr_tour_toolbar_rect(_x, _y) {
    var _m = obj_amiga_manager;
    return [_x, _y, _x + _m.top_ui_button_width, _y + _m.top_ui_button_height];
}

function scr_tour_rect_union(_a, _b) {
    if (_a == undefined) return _b;
    if (_b == undefined) return _a;
    return [min(_a[0], _b[0]), min(_a[1], _b[1]), max(_a[2], _b[2]), max(_a[3], _b[3])];
}

// ---------------------------------------------------------------------------
// Panel placement: next to the highlight, never on top of it when avoidable.

function scr_tour_overlap(_ax1, _ay1, _ax2, _ay2, _r) {
    if (_r == undefined) return 0;
    var _w = min(_ax2, _r[2]) - max(_ax1, _r[0]);
    var _h = min(_ay2, _r[3]) - max(_ay1, _r[1]);
    return (_w > 0 && _h > 0) ? _w * _h : 0;
}

/// Top-left of a _w x _h panel placed beside rectangle _r, and clear of
/// _avoid (an open editor window) when there is room. Returns [x, y].
function scr_tour_place_panel(_w, _h, _r, _avoid = undefined) {
    var _margin = 12;
    var _rw = room_width;
    var _rh = room_height;
    var _candidates = [];
    if (_r != undefined) {
        array_push(_candidates, [_r[0], _r[3] + 20]);                  // below
        array_push(_candidates, [_r[0], _r[1] - 20 - _h]);             // above
        array_push(_candidates, [_r[2] + 20, _r[1]]);                  // right
        array_push(_candidates, [_r[0] - 20 - _w, _r[1]]);             // left
        array_push(_candidates, [_r[2] - _w, _r[3] + 20]);             // below, right-aligned
        array_push(_candidates, [_r[2] - _w, _r[1] - 20 - _h]);        // above, right-aligned
    }
    array_push(_candidates, [(_rw - _w) div 2, _rh - _h - 70]);        // bottom centre
    array_push(_candidates, [_rw - _w - _margin, _rh - _h - 70]);
    array_push(_candidates, [_margin, _rh - _h - 70]);
    array_push(_candidates, [_rw - _w - _margin, 90]);
    array_push(_candidates, [_margin, 90]);
    array_push(_candidates, [(_rw - _w) div 2, 90]);

    if (_avoid != undefined) {
        // Beside the editor window, level with the highlight.
        var _ry = _r != undefined ? _r[1] : _avoid[1];
        array_push(_candidates, [_avoid[2] + 20, _ry]);
        array_push(_candidates, [_avoid[0] - 20 - _w, _ry]);
        var _c = 0;
        while (_c < array_length(_candidates)) {
            var _cx = clamp(_candidates[_c][0], _margin, _rw - _w - _margin);
            var _cy = clamp(_candidates[_c][1], _margin, _rh - _h - _margin);
            if (scr_tour_overlap(_cx, _cy, _cx + _w, _cy + _h, _r) == 0 && scr_tour_overlap(_cx, _cy, _cx + _w, _cy + _h, _avoid) == 0) return [_cx, _cy];
            _c += 1;
        }
    }

    var _best = undefined;
    var _best_overlap = infinity;
    var _i = 0;
    while (_i < array_length(_candidates)) {
        var _x = clamp(_candidates[_i][0], _margin, _rw - _w - _margin);
        var _y = clamp(_candidates[_i][1], _margin, _rh - _h - _margin);
        var _overlap = scr_tour_overlap(_x, _y, _x + _w, _y + _h, _r);
        if (_overlap == 0) return [_x, _y];
        if (_overlap < _best_overlap) {
            _best_overlap = _overlap;
            _best = [_x, _y];
        }
        _i += 1;
    }
    return _best;
}
