// obj_course - the 68K course screen (scr_course). Three views:
//   "map"    the 100 lessons and 5 exams in five rows; each one unlocks the next
//   "lesson" the code editor (course mode) on the left, the lesson on the right:
//            explanation, task, quiz, RUN TESTS and the results
//   "exam"   30-50 multiple-choice questions, then the score
// Created by scr_course_open(); depth -350000 (the editor draws over the left part).

depth = -350000;

items = scr_course_items();
view = "map";
current = -1;               // index into items of the open lesson / exam
editor = noone;
job = undefined;            // scr_course_assemble job of the last RUN TESTS
mouse_block = true;         // ignore the click that opened the course

// ---- geometry (room 1920 x 1080) ----
panel_x1 = 40;
panel_y1 = 24;
panel_x2 = room_width - 40;
panel_y2 = room_height - 24;
title_h = 60;
// map
tile_w = 80;
tile_h = 76;
tile_gap = 6;
map_x0 = 60;
map_y0 = 112;
map_row_h = 122;
map_hover = -1;
map_buttons = [];
// lesson column beside the editor
editor_x2 = 1184;
col_x1 = 1196;
col_x2 = panel_x2;
col_head_y2 = panel_y1 + 76;
content_y1 = col_head_y2 + 8;
results_y1 = 700;
results_y2 = 1000;
content_y2 = results_y1 - 8;
buttons_y1 = 1008;
buttons_y2 = panel_y2 - 6;
content_scroll = 0;
content_h = 0;
content_rows = [];
content_dirty = true;
results_scroll = 0;
results_rows = [];
result_selected = -1;
lesson_buttons = [];
lesson_hover = "";
quiz_choice = [];           // per question: the option chosen last (-1 none)
quiz_tried = [];            // per question: struct of wrong options tried
fail_runs = 0;
show_hint = false;
show_solution = false;
lesson_message = "";
lesson_message_colour = c_white;
// exam
exam_order = [];            // question indices in the order asked
exam_option_order = [];     // per asked question: option indices in the order shown
exam_answers = [];          // per asked question: shown option chosen (-1 none)
exam_pos = 0;
exam_finished = false;
exam_score = 0;
exam_buttons = [];
exam_hover = "";
exam_review_scroll = 0;

col_bg = make_colour_rgb(14, 18, 30);
col_edge = make_colour_rgb(70, 90, 140);
col_band = make_colour_rgb(26, 34, 58);
col_text = make_colour_rgb(220, 222, 232);
col_dim = make_colour_rgb(130, 140, 170);
col_head = make_colour_rgb(255, 200, 90);
col_code_bg = make_colour_rgb(10, 13, 22);
col_ok = make_colour_rgb(90, 220, 120);
col_bad = make_colour_rgb(255, 95, 95);
col_locked = make_colour_rgb(32, 36, 50);
col_open = make_colour_rgb(30, 70, 120);
col_done = make_colour_rgb(30, 100, 55);
col_exam = make_colour_rgb(120, 85, 20);

// ---------------------------------------------------------------- opening items

/// Opens lesson / exam _index (_force: even if locked - the editor tour).
open_item = function(_index, _force = false) {
    if (_index < 0 || _index >= array_length(items) || (!_force && !scr_course_unlocked(_index))) return;
    close_editor();
    current = _index;
    var _item = items[_index];
    if (_item.kind == "exam") {
        exam_start();
        view = "exam";
        return;
    }
    view = "lesson";
    job_drop();
    global.code_editor_build_errors = [];
    fail_runs = 0;
    show_hint = false;
    show_solution = false;
    content_scroll = 0;
    results_scroll = 0;
    result_selected = -1;
    lesson_message = scr_course_is_done(_item) ? "Lesson passed - you can carry on, or practise here." : "";
    lesson_message_colour = col_ok;
    quiz_choice = array_create(array_length(_item.quiz), -1);
    quiz_tried = [];
    for (var _q = 0; _q < array_length(_item.quiz); _q += 1) array_push(quiz_tried, {});
    content_dirty = true;
    var _title = scr_course_item_label(_item) + ": " + string_upper(_item.title);
    editor = scr_code_editor_open_course(scr_course_load_code(_item), _title, editor_x2);
};

/// Forgets the test job (freeing its simulator if it was mid-test).
job_drop = function() {
    if (job != undefined && job.state == "testing" && is_struct(job.cpu)) scr_m68k_free(job.cpu);
    job = undefined;
};

close_editor = function() {
    if (instance_exists(editor)) with (editor) ed_close(true);
    editor = noone;
};

back_to_map = function() {
    close_editor();
    view = "map";
    current = -1;
    job_drop();
    global.code_editor_build_errors = [];
    mouse_block = true;
};

close_course = function() {
    close_editor();
    instance_destroy();
};

// ---------------------------------------------------------------- lesson

/// Called by the editor whenever its text is committed.
lesson_save_code = function(_text) {
    if (current < 0 || items[current].kind != "lesson") return;
    scr_course_save_code(items[current], _text);
};

/// F5 / RUN TESTS: assemble the editor's code, then run the tests.
lesson_run_tests = function() {
    if (view != "lesson" || current < 0) return;
    if (job != undefined && (job.state == "assembling" || job.state == "testing")) return;
    var _code = scr_course_load_code(items[current]);
    if (instance_exists(editor)) _code = editor.ed_text();
    job = scr_course_assemble(items[current], _code);
    results_scroll = 0;
    result_selected = -1;
    lesson_message = "Assembling...";
    lesson_message_colour = col_dim;
};

lesson_quiz_done = function() {
    var _item = items[current];
    for (var _q = 0; _q < array_length(_item.quiz); _q += 1) {
        if (quiz_choice[_q] != _item.quiz[_q].answer) return false;
    }
    return true;
};

/// Marks the lesson passed once the tests (if any) and the quiz are done.
lesson_check_pass = function() {
    var _item = items[current];
    var _tests_ok = array_length(_item.tests) == 0 || (job != undefined && job.state == "tested" && job.passed);
    if (!_tests_ok || !lesson_quiz_done()) return false;
    if (!scr_course_is_done(_item)) {
        scr_course_mark_done(_item);
        lesson_message = "LESSON PASSED! " + (current + 1 < array_length(items) ? scr_course_item_label(items[current + 1]) + " is open: press NEXT." : "");
        lesson_message_colour = col_ok;
    }
    return true;
};

lesson_next = function() {
    if (current + 1 < array_length(items) && scr_course_is_done(items[current])) open_item(current + 1);
};

/// One wrapped paragraph as text rows.
content_add_text = function(_s, _colour, _w, _th) {
    draw_set_font(UI_FONT_GUIDE);
    var _lines = scr_tutorial_ui_wrap_lines(_s, _w);
    for (var _i = 0; _i < array_length(_lines); _i += 1) array_push(content_rows, { kind : "text", text : _lines[_i], h : _th, colour : _colour, q : -1, o : -1 });
};

/// A text section: paragraphs, "## " headings and indented code lines.
content_add_block = function(_text, _w, _th, _ch) {
    var _lines = string_split(_text, "\n");
    var _para = "";
    for (var _i = 0; _i <= array_length(_lines); _i += 1) {
        var _l = _i < array_length(_lines) ? _lines[_i] : "";
        var _is_code = _i < array_length(_lines) && (string_char_at(_l, 1) == "\t" || string_copy(_l, 1, 4) == "    ");
        var _is_head = _i < array_length(_lines) && string_copy(_l, 1, 3) == "## ";
        if (_para != "" && (string_trim(_l) == "" || _is_code || _is_head || _i == array_length(_lines))) {
            content_add_text(_para, col_text, _w, _th);
            array_push(content_rows, { kind : "gap", text : "", h : 8, colour : 0, q : -1, o : -1 });
            _para = "";
        }
        if (_i == array_length(_lines)) break;
        if (_is_head) {
            array_push(content_rows, { kind : "head", text : string_upper(string_delete(_l, 1, 3)), h : _th + 4, colour : col_head, q : -1, o : -1 });
        } else if (_is_code) {
            var _code = string_replace_all(_l, "\t", "    ");
            if (string_copy(_code, 1, 4) == "    ") _code = string_delete(_code, 1, 4);
            array_push(content_rows, { kind : "code", text : _code, h : _ch, colour : col_text, q : -1, o : -1 });
            var _next = _i + 1 < array_length(_lines) ? _lines[_i + 1] : "";
            if (!(string_char_at(_next, 1) == "\t" || string_copy(_next, 1, 4) == "    ")) {
                array_push(content_rows, { kind : "gap", text : "", h : 8, colour : 0, q : -1, o : -1 });
            }
        } else if (string_trim(_l) != "") {
            _para += (_para == "" ? "" : " ") + string_trim(_l);
        }
    }
};

/// Rebuilds content_rows: the explanation, task, quiz, hint and solution as
/// rows of one wrapped line each { kind, text, h, colour, q, o }.
lesson_layout_content = function() {
    content_dirty = false;
    content_rows = [];
    var _item = items[current];
    var _w = col_x2 - col_x1 - 44;
    draw_set_font(UI_FONT_GUIDE);
    var _th = string_height("Ag") + 3;
    var _code_font = scr_code_editor_font_ensure(global.code_editor_font_pref_size);
    draw_set_font(_code_font);
    var _ch = string_height("Ag") + 2;
    content_add_block(_item.text, _w, _th, _ch);
    if (_item.task != "") {
        array_push(content_rows, { kind : "head", text : "YOUR TASK", h : _th + 4, colour : make_colour_rgb(120, 220, 255), q : -1, o : -1 });
        content_add_block(_item.task, _w, _th, _ch);
    }
    if (array_length(_item.tests) > 0) {
        array_push(content_rows, { kind : "head", text : "TESTS", h : _th + 4, colour : make_colour_rgb(120, 220, 255), q : -1, o : -1 });
        for (var _t = 0; _t < array_length(_item.tests); _t += 1) content_add_text("- " + _item.tests[_t].name, col_dim, _w, _th);
        array_push(content_rows, { kind : "gap", text : "", h : 8, colour : 0, q : -1, o : -1 });
    }
    for (var _q = 0; _q < array_length(_item.quiz); _q += 1) {
        var _qq = _item.quiz[_q];
        array_push(content_rows, { kind : "head", text : "QUESTION " + string(_q + 1), h : _th + 4, colour : make_colour_rgb(200, 160, 255), q : -1, o : -1 });
        content_add_text(_qq.question, col_text, _w, _th);
        for (var _cl = 0; _cl < array_length(_qq.code); _cl += 1) {
            array_push(content_rows, { kind : "code", text : _qq.code[_cl], h : _ch, colour : col_text, q : -1, o : -1 });
        }
        if (array_length(_qq.code) > 0) array_push(content_rows, { kind : "gap", text : "", h : 6, colour : 0, q : -1, o : -1 });
        for (var _o = 0; _o < array_length(_qq.options); _o += 1) {
            draw_set_font(UI_FONT_GUIDE);
            var _ol = scr_tutorial_ui_wrap_lines(chr(ord("A") + _o) + ")  " + _qq.options[_o], _w - 24);
            array_push(content_rows, { kind : "option", text : _ol, h : array_length(_ol) * _th + 10, colour : col_text, q : _q, o : _o });
            array_push(content_rows, { kind : "gap", text : "", h : 4, colour : 0, q : -1, o : -1 });
        }
        if (_qq.why != "" && quiz_choice[_q] == _qq.answer) content_add_text(_qq.why, col_ok, _w, _th);
        array_push(content_rows, { kind : "gap", text : "", h : 8, colour : 0, q : -1, o : -1 });
    }
    if (show_hint && _item.hint != "") {
        array_push(content_rows, { kind : "head", text : "HINT", h : _th + 4, colour : col_head, q : -1, o : -1 });
        content_add_block(_item.hint, _w, _th, _ch);
    }
    if (show_solution && _item.solution != "") {
        array_push(content_rows, { kind : "head", text : "ONE WAY TO DO IT", h : _th + 4, colour : col_head, q : -1, o : -1 });
        var _sl = string_split(_item.solution, "\n");
        for (var _s = 0; _s < array_length(_sl); _s += 1) {
            array_push(content_rows, { kind : "code", text : string_replace_all(_sl[_s], "\t", "    "), h : _ch, colour : col_text, q : -1, o : -1 });
        }
    }
    content_h = 0;
    for (var _r = 0; _r < array_length(content_rows); _r += 1) content_h += content_rows[_r].h;
    draw_set_font(UI_FONT);
};

/// The buttons under the lesson column.
lesson_layout_buttons = function() {
    lesson_buttons = [];
    var _item = items[current];
    var _x = col_x1 + 8;
    var _w = (col_x2 - col_x1 - 16 - 4 * 8) / 5;
    var _defs = [
        { id : "run", label : array_length(_item.tests) > 0 ? "RUN TESTS (F5)" : "ASSEMBLE (F5)", colour : make_colour_rgb(35, 95, 58), on : true },
        { id : "hint", label : "HINT", colour : make_colour_rgb(110, 85, 30), on : _item.hint != "" && fail_runs >= 1 },
        { id : "solution", label : "SOLUTION", colour : make_colour_rgb(110, 60, 30), on : _item.solution != "" && (fail_runs >= 3 || scr_course_is_done(_item)) },
        { id : "next", label : "NEXT >", colour : make_colour_rgb(40, 80, 150), on : scr_course_is_done(_item) && current + 1 < array_length(items) },
        { id : "map", label : "MAP", colour : make_colour_rgb(110, 42, 48), on : true },
    ];
    for (var _i = 0; _i < array_length(_defs); _i += 1) {
        var _d = _defs[_i];
        array_push(lesson_buttons, { id : _d.id, label : _d.label, colour : _d.colour, on : _d.on,
            x1 : round(_x), y1 : buttons_y1, x2 : round(_x + _w), y2 : buttons_y2 });
        _x += _w + 8;
    }
};

lesson_button_action = function(_id) {
    switch (_id) {
        case "run":
            if (instance_exists(editor)) with (editor) ed_commit();
            lesson_run_tests();
            break;
        case "hint":
            show_hint = !show_hint;
            content_dirty = true;
            if (show_hint) content_scroll = 1000000;
            break;
        case "solution":
            show_solution = !show_solution;
            content_dirty = true;
            if (show_solution) content_scroll = 1000000;
            break;
        case "next": lesson_next(); break;
        case "map": back_to_map(); break;
    }
};

/// Rows for the results box: { text, colour, test } (test = index into job.results).
lesson_layout_results = function() {
    results_rows = [];
    if (job == undefined) return;
    draw_set_font(UI_FONT_GUIDE);
    var _w = col_x2 - col_x1 - 60;
    if (job.state == "asm_failed" || job.state == "error") {
        for (var _e = 0; _e < array_length(job.errors); _e += 1) {
            var _err = job.errors[_e];
            var _lines = scr_tutorial_ui_wrap_lines((_err.line >= 0 ? "Line " + string(_err.line + 1) + ": " : "") + _err.message, _w);
            for (var _l = 0; _l < array_length(_lines); _l += 1) array_push(results_rows, { text : _lines[_l], colour : col_bad, test : -1, mark : _l == 0 ? "x" : "" });
        }
        return;
    }
    for (var _i = 0; _i < array_length(job.results); _i += 1) {
        var _r = job.results[_i];
        array_push(results_rows, { text : _r.name, colour : _r.ok ? col_ok : col_bad, test : _i, mark : _r.ok ? "tick" : "x" });
        for (var _p = 0; _p < array_length(_r.problems); _p += 1) {
            var _pl = scr_tutorial_ui_wrap_lines(_r.problems[_p], _w - 20);
            for (var _k = 0; _k < array_length(_pl); _k += 1) array_push(results_rows, { text : "    " + _pl[_k], colour : col_dim, test : _i, mark : "" });
        }
    }
    if (job.state == "testing") array_push(results_rows, { text : "Running test " + string(job.test_index + 1) + " of " + string(array_length(job.item.tests)) + "...", colour : col_dim, test : -1, mark : "" });
};

// ---------------------------------------------------------------- exam

exam_start = function() {
    var _item = items[current];
    var _n = array_length(_item.quiz);
    exam_order = array_create(_n, 0);
    for (var _i = 0; _i < _n; _i += 1) exam_order[_i] = _i;
    array_shuffle_ext(exam_order);
    exam_option_order = [];
    for (var _j = 0; _j < _n; _j += 1) {
        var _q = _item.quiz[exam_order[_j]];
        var _oo = array_create(array_length(_q.options), 0);
        for (var _k = 0; _k < array_length(_oo); _k += 1) _oo[_k] = _k;
        array_shuffle_ext(_oo);
        array_push(exam_option_order, _oo);
    }
    exam_answers = array_create(_n, -1);
    exam_pos = 0;
    exam_finished = false;
    exam_score = 0;
    exam_review_scroll = 0;
};

exam_all_answered = function() {
    for (var _i = 0; _i < array_length(exam_answers); _i += 1) if (exam_answers[_i] < 0) return false;
    return true;
};

exam_finish = function() {
    var _item = items[current];
    var _right = 0;
    for (var _i = 0; _i < array_length(exam_order); _i += 1) {
        var _q = _item.quiz[exam_order[_i]];
        if (exam_answers[_i] >= 0 && exam_option_order[_i][exam_answers[_i]] == _q.answer) _right += 1;
    }
    exam_score = array_length(exam_order) > 0 ? round(_right * 100 / array_length(exam_order)) : 0;
    exam_finished = true;
    exam_review_scroll = 0;
    if (exam_score >= _item.pass) scr_course_mark_done(_item);
};

exam_choose = function(_shown) {
    if (exam_finished || _shown < 0 || _shown >= array_length(exam_option_order[exam_pos])) return;
    exam_answers[exam_pos] = _shown;
};

// ---------------------------------------------------------------- layouts shared by Step and Draw

map_layout = function() {
    map_buttons = [];
    draw_set_font(UI_FONT);
    var _labels = [["continue", scr_course_done_count() == 0 ? "START (ENTER)" : "CONTINUE (ENTER)", make_colour_rgb(35, 95, 58)],
        ["reset", "RESET PROGRESS", make_colour_rgb(70, 60, 50)], ["close", "CLOSE (ESC)", make_colour_rgb(110, 42, 48)]];
    var _x = panel_x2 - 12;
    for (var _i = array_length(_labels) - 1; _i >= 0; _i -= 1) {
        var _w = string_width(_labels[_i][1]) + 32;
        array_push(map_buttons, { id : _labels[_i][0], label : _labels[_i][1], colour : _labels[_i][2], x1 : _x - _w, y1 : panel_y1 + 14, x2 : _x, y2 : panel_y1 + title_h - 12 });
        _x -= _w + 10;
    }
};

/// Option boxes, question dots and navigation (or the result buttons).
exam_layout = function() {
    exam_buttons = [];
    var _item = items[current];
    var _bx1 = panel_x1 + 60;
    var _bx2 = panel_x2 - 60;
    if (!exam_finished) {
        var _oo = exam_option_order[exam_pos];
        for (var _o = 0; _o < array_length(_oo); _o += 1) {
            var _y = 380 + _o * 96;
            array_push(exam_buttons, { id : "opt" + string(_o), label : "", on : true, x1 : _bx1, y1 : _y, x2 : _bx2, y2 : _y + 84 });
        }
        var _n = array_length(exam_order);
        var _dw = min(32, floor((_bx2 - _bx1) / max(1, _n)));
        for (var _d = 0; _d < _n; _d += 1) {
            var _dx = _bx1 + _d * _dw;
            array_push(exam_buttons, { id : "dot" + string(_d), label : "", on : true, x1 : _dx, y1 : 800, x2 : _dx + _dw - 4, y2 : 828 });
        }
        var _w = 220;
        array_push(exam_buttons, { id : "prev", label : "< PREV", on : exam_pos > 0, x1 : _bx1, y1 : 960, x2 : _bx1 + _w, y2 : 1012 });
        array_push(exam_buttons, { id : "next", label : "NEXT >", on : exam_pos < _n - 1, x1 : _bx1 + _w + 16, y1 : 960, x2 : _bx1 + _w * 2 + 16, y2 : 1012 });
        array_push(exam_buttons, { id : "finish", label : "FINISH EXAM", on : exam_all_answered(), x1 : _bx2 - _w * 2 - 16, y1 : 960, x2 : _bx2 - _w - 16, y2 : 1012 });
        array_push(exam_buttons, { id : "map", label : "MAP (ESC)", on : true, x1 : _bx2 - _w, y1 : 960, x2 : _bx2, y2 : 1012 });
    } else {
        var _w2 = 260;
        var _passed = exam_score >= _item.pass;
        array_push(exam_buttons, { id : "retry", label : "TAKE IT AGAIN", on : true, x1 : _bx1, y1 : 980, x2 : _bx1 + _w2, y2 : 1030 });
        array_push(exam_buttons, { id : "map", label : "MAP", on : true, x1 : _bx1 + _w2 + 16, y1 : 980, x2 : _bx1 + _w2 * 2 + 16, y2 : 1030 });
        if (_passed && current + 1 < array_length(items)) {
            array_push(exam_buttons, { id : "continue", label : scr_course_item_label(items[current + 1]) + " >", on : true, x1 : _bx2 - _w2, y1 : 980, x2 : _bx2, y2 : 1030 });
        }
    }
};
