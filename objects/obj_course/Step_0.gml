// obj_course Step - map, lesson and exam input; runs the lesson tests a slice per frame.

// ---- the lesson's assemble / test job (keeps running whatever the view) ----
if (job != undefined) {
    var _was = job.state;
    if (job.state == "assembling") scr_course_job_poll(job);
    if (job.state == "assembled") {
        scr_course_tests_begin(job);
        lesson_message = array_length(job.item.tests) > 0 ? "Running the tests..." : "Assembled OK: " + string(job.code_size) + " bytes.";
        lesson_message_colour = col_dim;
    }
    if (job.state == "testing") scr_course_tests_step(job, 12);
    if (job.state != _was && view == "lesson") {
        if (job.state == "asm_failed" || job.state == "error") {
            fail_runs += 1;
            lesson_message = job.message;
            lesson_message_colour = col_bad;
        } else if (job.state == "tested") {
            if (array_length(job.item.tests) > 0) {
                if (job.passed) {
                    lesson_message = job.message + (lesson_quiz_done() ? "" : " Now answer the questions.");
                    lesson_message_colour = col_ok;
                } else {
                    fail_runs += 1;
                    lesson_message = job.message;
                    lesson_message_colour = col_bad;
                }
            }
            lesson_check_pass();
            for (var _r = 0; _r < array_length(job.results); _r += 1) {
                if (!job.results[_r].ok) {
                    result_selected = _r;
                    break;
                }
            }
            if (result_selected < 0 && array_length(job.results) > 0) result_selected = 0;
        }
    }
}

// The editor closed itself (Esc, MAP / CLOSE): back to the map.
if (view == "lesson" && !instance_exists(editor)) {
    back_to_map();
    exit;       // the Esc that closed the editor must not close the course too
}

// Layout shared with Draw (and the tour), before the tour guard.
if (view == "map") map_layout();
if (view == "exam") exam_layout();
if (view == "lesson") {
    if (content_dirty) lesson_layout_content();
    lesson_layout_buttons();
    lesson_layout_results();
}

// The editor tour is presenting this screen: its input belongs to the tour.
if (instance_exists(obj_editor_tour)) exit;

var _mx = mouse_x;
var _my = mouse_y;
var _mp = mouse_check_button_pressed(mb_left);
if (mouse_block) {
    if (!mouse_check_button(mb_left)) mouse_block = false;
    _mp = false;
}
var _wheel = mouse_wheel_down() - mouse_wheel_up();

// ================================================================= map
if (view == "map") {
    if (keyboard_check_pressed(vk_escape)) {
        close_course();
        exit;
    }
    map_hover = -1;
    for (var _i = 0; _i < array_length(items); _i += 1) {
        var _row = _i div 21;
        var _col = _i mod 21;
        var _tx = map_x0 + _col * (tile_w + tile_gap);
        var _ty = map_y0 + _row * map_row_h + 26;
        if (_mx >= _tx && _mx < _tx + tile_w && _my >= _ty && _my < _ty + tile_h) map_hover = _i;
    }
    if (_mp && map_hover >= 0 && scr_course_unlocked(map_hover)) {
        open_item(map_hover);
        exit;
    }
    if (keyboard_check_pressed(vk_enter)) {
        open_item(scr_course_next_index());
        exit;
    }
    if (_mp) {
        for (var _b = 0; _b < array_length(map_buttons); _b += 1) {
            var _mb = map_buttons[_b];
            if (_mx >= _mb.x1 && _mx < _mb.x2 && _my >= _mb.y1 && _my < _mb.y2) {
                switch (_mb.id) {
                    case "continue": open_item(scr_course_next_index()); break;
                    case "close": close_course(); break;
                    case "reset":
                        if (show_question("Forget every lesson and exam you have passed? Your saved code stays.")) scr_course_reset_progress();
                        mouse_block = true;
                        break;
                }
                exit;
            }
        }
    }
    exit;
}

// ================================================================= lesson
if (view == "lesson") {
    // wheel: content or results
    if (_wheel != 0 && _mx >= col_x1 && _mx < col_x2) {
        if (_my >= content_y1 && _my < content_y2) content_scroll += _wheel * 48;
        if (_my >= results_y1 && _my < results_y2) results_scroll += _wheel * 3;
    }
    content_scroll = clamp(content_scroll, 0, max(0, content_h - (content_y2 - content_y1 - 16)));
    var _res_rows_vis = max(1, floor((results_y2 - results_y1 - 34 - 70) / 22));
    results_scroll = clamp(results_scroll, 0, max(0, array_length(results_rows) - _res_rows_vis));

    lesson_hover = "";
    for (var _lb = 0; _lb < array_length(lesson_buttons); _lb += 1) {
        var _bt = lesson_buttons[_lb];
        if (_mx >= _bt.x1 && _mx < _bt.x2 && _my >= _bt.y1 && _my < _bt.y2) lesson_hover = _bt.id;
    }
    if (_mp && lesson_hover != "") {
        for (var _lb2 = 0; _lb2 < array_length(lesson_buttons); _lb2 += 1) {
            if (lesson_buttons[_lb2].id == lesson_hover && lesson_buttons[_lb2].on) lesson_button_action(lesson_hover);
        }
        exit;
    }

    // quiz options in the content column
    if (_mp && _mx >= col_x1 && _mx < col_x2 && _my >= content_y1 && _my < content_y2) {
        var _y = content_y1 + 8 - content_scroll;
        for (var _c = 0; _c < array_length(content_rows); _c += 1) {
            var _row_c = content_rows[_c];
            if (_row_c.kind == "option" && _my >= _y && _my < _y + _row_c.h) {
                var _item = items[current];
                var _qq = _item.quiz[_row_c.q];
                if (quiz_choice[_row_c.q] != _qq.answer) {
                    quiz_choice[_row_c.q] = _row_c.o;
                    if (_row_c.o != _qq.answer) quiz_tried[_row_c.q][$ string(_row_c.o)] = true;
                    content_dirty = true;
                    lesson_check_pass();
                }
                break;
            }
            _y += _row_c.h;
        }
    }

    // a test row selects that test's registers
    if (_mp && _mx >= col_x1 && _mx < col_x2 && _my >= results_y1 + 34 && _my < results_y2 - 70) {
        var _ri = results_scroll + floor((_my - results_y1 - 34) / 22);
        if (_ri >= 0 && _ri < array_length(results_rows) && results_rows[_ri].test >= 0) result_selected = results_rows[_ri].test;
    }
    exit;
}

// ================================================================= exam
if (view == "exam") {
    var _item_e = items[current];
    if (keyboard_check_pressed(vk_escape)) {
        back_to_map();
        exit;
    }
    if (!exam_finished) {
        for (var _k = 0; _k < 4; _k += 1) {
            if (keyboard_check_pressed(ord("1") + _k) || keyboard_check_pressed(ord("A") + _k)) exam_choose(_k);
        }
        if (keyboard_check_pressed(vk_right) || keyboard_check_pressed(vk_enter)) exam_pos = min(exam_pos + 1, array_length(exam_order) - 1);
        if (keyboard_check_pressed(vk_left)) exam_pos = max(exam_pos - 1, 0);
    } else if (_wheel != 0) {
        exam_review_scroll = max(0, exam_review_scroll + _wheel * 48);
    }
    exam_hover = "";
    for (var _eb = 0; _eb < array_length(exam_buttons); _eb += 1) {
        var _b2 = exam_buttons[_eb];
        if (_mx >= _b2.x1 && _mx < _b2.x2 && _my >= _b2.y1 && _my < _b2.y2) exam_hover = _b2.id;
    }
    if (_mp && exam_hover != "") {
        var _on = true;
        for (var _eb2 = 0; _eb2 < array_length(exam_buttons); _eb2 += 1) if (exam_buttons[_eb2].id == exam_hover) _on = exam_buttons[_eb2].on;
        if (!_on) exit;
        if (string_copy(exam_hover, 1, 3) == "opt") exam_choose(real(string_delete(exam_hover, 1, 3)));
        else if (string_copy(exam_hover, 1, 3) == "dot") exam_pos = real(string_delete(exam_hover, 1, 3));
        else switch (exam_hover) {
            case "prev": exam_pos = max(exam_pos - 1, 0); break;
            case "next": exam_pos = min(exam_pos + 1, array_length(exam_order) - 1); break;
            case "finish": exam_finish(); break;
            case "retry": exam_start(); break;
            case "map": back_to_map(); break;
            case "continue": open_item(current + 1); break;
        }
    }
    exit;
}
